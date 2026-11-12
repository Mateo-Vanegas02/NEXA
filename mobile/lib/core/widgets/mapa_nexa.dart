import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../config/env.dart';
import '../l10n/gen/app_localizations.dart';
import '../rumbo/orientacion_mapa.dart';
import '../rumbo/reglas_rumbo.dart';
import '../theme/tokens.dart';

/// Centro por defecto (Cartagena, igual que la web) cuando no hay GPS.
const LatLng kCentroPorDefecto = LatLng(10.4055, -75.5037);

/// En tests se sobrescribe con `false` para no descargar teselas.
final mapasHabilitadosProvider = Provider<bool>((ref) => true);

/// Ubicación actual; si no hay permiso o GPS, usa [kCentroPorDefecto].
///
/// No pide el permiso: lo piden las pantallas de permisos (N02 / E01) con su
/// explicación; después se invalida este provider para centrar el mapa.
final ubicacionProvider = FutureProvider<LatLng>((ref) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return kCentroPorDefecto;
    final permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      return kCentroPorDefecto;
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)),
    );
    return LatLng(p.latitude, p.longitude);
  } on Object {
    return kCentroPorDefecto;
  }
});

/// Mueve la cámara del mapa desde la pantalla (p. ej. al elegir un lugar).
class MapaNexaController {
  ml.MapLibreMapController? _ml;

  Future<void> mover(LatLng p, double zoom) async {
    await _ml?.animateCamera(ml.CameraUpdate.newLatLngZoom(_aMl(p), zoom));
  }
}

ml.LatLng _aMl(LatLng p) => ml.LatLng(p.latitude, p.longitude);

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// Mapa vectorial de OpenFreeMap dibujado con MapLibre (sin API key): origen,
/// destino, ruta por calles y conductor.
///
/// La ruta es [ruta] (el trazado que calculó el servidor con OSRM); sin ella,
/// la línea recta origen→destino.
///
/// Orientación (fase 4): con [orientable] muestra el botón de brújula (norte
/// arriba ↔ girar con el teléfono); con [navegacion] sigue a [conductor] de
/// cerca, inclinado y girando con su avance. El rumbo lo da
/// `orientacionMapaProvider`; el mapa solo lo aplica.
class MapaNexa extends ConsumerStatefulWidget {
  const MapaNexa({
    required this.centro,
    this.origen,
    this.destino,
    this.ruta,
    this.conductor,
    this.etiquetaRuta,
    this.zoom = 14,
    this.onTap,
    this.controller,
    this.orientable = false,
    this.navegacion = false,
    this.encuadrarRuta = false,
    this.brujulaArriba = Sp.md,
    super.key,
  });

  final LatLng centro;
  final LatLng? origen;
  final LatLng? destino;

  /// Trazado por calles; null o vacío = línea recta origen→destino.
  final List<LatLng>? ruta;

  /// Posición (aproximada) de la moto del conductor.
  final LatLng? conductor;

  /// Texto sobre el mapa, p. ej. "12 min · 4,2 km".
  final String? etiquetaRuta;
  final double zoom;
  final void Function(LatLng)? onTap;
  final MapaNexaController? controller;

  /// Muestra el botón de brújula.
  final bool orientable;

  /// Modo navegación: el mapa sigue a [conductor] y gira con su rumbo.
  final bool navegacion;

  /// Al cambiar la ruta, la cámara la muestra completa.
  final bool encuadrarRuta;

  /// Distancia del botón de brújula al borde superior (para no tapar otros
  /// botones de la pantalla).
  final double brujulaArriba;

  /// Acercamiento e inclinación del modo navegación.
  static const zoomNavegacion = 17.0;
  static const inclinacionNavegacion = 50.0;

  @override
  ConsumerState<MapaNexa> createState() => _MapaNexaState();
}

class _MapaNexaState extends ConsumerState<MapaNexa> {
  ml.MapLibreMapController? _ml;
  bool _estiloListo = false;
  Future<void> _cola = Future.value();

  ml.Line? _linea;
  List<LatLng> _lineaPuntos = const [];
  ml.Circle? _origen;
  LatLng? _origenEn;
  ml.Circle? _destino;
  LatLng? _destinoEn;
  ml.Symbol? _moto;
  (LatLng, String, double)? _motoEn;
  ModoOrientacion _modoAplicado = ModoOrientacion.norte;

  bool get _usaOrientacion => widget.orientable || widget.navegacion;

  /// Los cambios en el mapa nativo van en fila: así nunca se pisan.
  void _enCola(Future<void> Function() tarea) {
    _cola = _cola.then((_) => tarea()).catchError((Object e) {
      debugPrint('Mapa: $e');
    });
  }

  @override
  void didUpdateWidget(MapaNexa anterior) {
    super.didUpdateWidget(anterior);
    _enCola(_sincronizar);
    final cambioRuta =
        widget.origen != anterior.origen ||
        widget.destino != anterior.destino ||
        widget.ruta != anterior.ruta;
    if (widget.encuadrarRuta && cambioRuta) _enCola(_encuadrar);
    if (_usaOrientacion &&
        (widget.navegacion != anterior.navegacion ||
            (widget.navegacion && widget.conductor != anterior.conductor))) {
      _aplicar(ref.read(orientacionMapaProvider));
    }
  }

  List<LatLng> get _puntosRuta {
    final r = widget.ruta;
    if (r != null && r.length >= 2) return r;
    final o = widget.origen;
    final d = widget.destino;
    return o != null && d != null ? [o, d] : const [];
  }

  Future<void> _alCargarEstilo() async {
    final c = _ml;
    if (c == null) return;
    // Un estilo nuevo borra lo dibujado: se vuelve a crear.
    _linea = null;
    _origen = _destino = null;
    _moto = null;
    _lineaPuntos = const [];
    _origenEn = _destinoEn = null;
    _motoEn = null;
    await c.addImage(
      'nexa-moto',
      await _iconoPng(Icons.two_wheeler, NexaColors.brand, Colors.white),
    );
    await c.addImage(
      'nexa-flecha',
      await _iconoPng(Icons.navigation, Colors.white, NexaColors.cyan),
    );
    _estiloListo = true;
    await _sincronizar();
    if (widget.encuadrarRuta) await _encuadrar();
    if (_usaOrientacion) _aplicar(ref.read(orientacionMapaProvider));
  }

  /// Dibuja lo que cambió (ruta, pines, moto) sin rehacer lo demás.
  Future<void> _sincronizar() async {
    final c = _ml;
    if (c == null || !_estiloListo || !mounted) return;
    final puntos = _puntosRuta;
    if (!_mismos(puntos, _lineaPuntos)) {
      final vieja = _linea;
      _linea = null;
      if (vieja != null) await c.removeLine(vieja);
      if (puntos.length >= 2) {
        _linea = await c.addLine(
          ml.LineOptions(
            geometry: puntos.map(_aMl).toList(),
            lineColor: _hex(NexaColors.cyan),
            lineWidth: 5,
            lineJoin: 'round',
          ),
        );
      }
      _lineaPuntos = puntos;
    }
    if (widget.origen != _origenEn) {
      _origen = await _pin(c, _origen, widget.origen, NexaColors.brand);
      _origenEn = widget.origen;
    }
    if (widget.destino != _destinoEn) {
      _destino = await _pin(c, _destino, widget.destino, NexaColors.cyan);
      _destinoEn = widget.destino;
    }
    await _dibujarMoto(c);
  }

  Future<ml.Circle?> _pin(
    ml.MapLibreMapController c,
    ml.Circle? actual,
    LatLng? en,
    Color color,
  ) async {
    if (en == null) {
      if (actual != null) await c.removeCircle(actual);
      return null;
    }
    if (actual != null) {
      await c.updateCircle(actual, ml.CircleOptions(geometry: _aMl(en)));
      return actual;
    }
    return c.addCircle(
      ml.CircleOptions(
        geometry: _aMl(en),
        circleRadius: 9,
        circleColor: _hex(color),
        circleStrokeColor: '#ffffff',
        circleStrokeWidth: 3,
      ),
    );
  }

  Future<void> _dibujarMoto(ml.MapLibreMapController c) async {
    final en = widget.conductor;
    final o = ref.read(orientacionMapaProvider);
    final flecha = widget.navegacion && o.rumbo != null;
    final icono = flecha ? 'nexa-flecha' : 'nexa-moto';
    // Con el mapa girado, la flecha se gira lo que falte para apuntar al rumbo.
    final giro = flecha
        ? ReglasRumbo.anguloEnPantalla(o.rumbo!, o.rotacionMapa)
        : 0.0;
    final nuevo = en == null ? null : (en, icono, giro);
    if (nuevo == _motoEn) return;
    _motoEn = nuevo;
    final actual = _moto;
    if (en == null) {
      _moto = null;
      if (actual != null) await c.removeSymbol(actual);
      return;
    }
    final opciones = ml.SymbolOptions(
      geometry: _aMl(en),
      iconImage: icono,
      iconSize: 0.5,
      iconRotate: giro,
      zIndex: 10,
    );
    if (actual != null) {
      await c.updateSymbol(actual, opciones);
    } else {
      _moto = await c.addSymbol(opciones);
    }
  }

  /// Muestra la ruta completa sobre la hoja inferior.
  Future<void> _encuadrar() async {
    final c = _ml;
    final puntos = _puntosRuta;
    if (c == null || !_estiloListo || puntos.length < 2) return;
    if (ref.read(orientacionMapaProvider).orientado) return;
    var s = puntos.first.latitude;
    var n = s;
    var w = puntos.first.longitude;
    var e = w;
    for (final p in puntos) {
      s = math.min(s, p.latitude);
      n = math.max(n, p.latitude);
      w = math.min(w, p.longitude);
      e = math.max(e, p.longitude);
    }
    await c.animateCamera(
      ml.CameraUpdate.newLatLngBounds(
        ml.LatLngBounds(southwest: ml.LatLng(s, w), northeast: ml.LatLng(n, e)),
        left: 48,
        right: 48,
        top: 140,
        bottom: 360,
      ),
    );
  }

  void _aplicar(EstadoOrientacion e) {
    final c = _ml;
    if (c == null || !_estiloListo || !mounted) return;
    final sinAnimacion = MediaQuery.disableAnimationsOf(context);
    final seguir = widget.conductor;
    final rumbo = e.orientado ? (e.rumbo ?? 0.0) : 0.0;
    final ml.CameraUpdate cambio;
    if (widget.navegacion && seguir != null) {
      cambio = ml.CameraUpdate.newCameraPosition(
        ml.CameraPosition(
          target: _aMl(seguir),
          zoom: MapaNexa.zoomNavegacion,
          bearing: rumbo,
          tilt: sinAnimacion ? 0 : MapaNexa.inclinacionNavegacion,
        ),
      );
    } else {
      if (!e.orientado && _modoAplicado == ModoOrientacion.norte) return;
      cambio = ml.CameraUpdate.bearingTo(rumbo);
      if (!e.orientado) {
        _enCola(() async => c.animateCamera(ml.CameraUpdate.tiltTo(0)));
      }
    }
    _modoAplicado = widget.navegacion ? ModoOrientacion.navegacion : e.modo;
    _enCola(() async {
      if (sinAnimacion) {
        await c.moveCamera(cambio);
      } else {
        await c.animateCamera(
          cambio,
          duration: const Duration(milliseconds: 250),
        );
      }
    });
    if (widget.navegacion) _enCola(() => _dibujarMoto(c));
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(mapasHabilitadosProvider)) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        alignment: Alignment.center,
        child: const Icon(Icons.map_outlined, size: 48),
      );
    }
    EstadoOrientacion? orientacion;
    if (_usaOrientacion) {
      orientacion = ref.watch(orientacionMapaProvider);
      ref.read(orientacionMapaProvider.notifier)
        ..sinAnimacion = MediaQuery.disableAnimationsOf(context)
        ..vertical = MediaQuery.orientationOf(context) == Orientation.portrait;
      ref.listen(orientacionMapaProvider, (_, e) => _aplicar(e));
    }
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final inicio = widget.navegacion
        ? (widget.conductor ?? widget.centro)
        : widget.centro;
    final mapa = ml.MapLibreMap(
      styleString: oscuro ? Env.estiloMapaOscuro : Env.estiloMapaClaro,
      initialCameraPosition: ml.CameraPosition(
        target: _aMl(inicio),
        zoom: widget.navegacion ? MapaNexa.zoomNavegacion : widget.zoom,
      ),
      onMapCreated: (c) {
        _ml = c;
        widget.controller?._ml = c;
      },
      onStyleLoadedCallback: () => _enCola(_alCargarEstilo),
      // El mapa solo gira con la brújula o en navegación, y solo la
      // navegación lo inclina: la aguja siempre dice dónde está el norte.
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      compassEnabled: false,
      attributionButtonPosition: ml.AttributionButtonPosition.bottomLeft,
      onMapClick: widget.onTap == null
          ? null
          : (_, p) => widget.onTap!(LatLng(p.latitude, p.longitude)),
    );
    final etiqueta = widget.etiquetaRuta;
    return Stack(
      children: [
        Positioned.fill(child: mapa),
        if (etiqueta != null)
          Positioned(
            top: Sp.md + Sizes.touch + Sp.sm,
            left: 0,
            right: 0,
            child: SafeArea(bottom: false, child: _Etiqueta(texto: etiqueta)),
          ),
        if (orientacion != null && widget.orientable)
          Positioned(
            top: widget.brujulaArriba,
            right: Sp.md,
            child: SafeArea(child: BotonBrujula(estado: orientacion)),
          ),
        if (orientacion != null &&
            orientacion.orientado &&
            orientacion.aviso != AvisoOrientacion.ninguno)
          Positioned(
            left: Sp.md,
            right: Sp.md,
            bottom: Sp.xl * 2,
            child: _AvisoOrientacion(aviso: orientacion.aviso),
          ),
      ],
    );
  }
}

bool _mismos(List<LatLng> a, List<LatLng> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Ícono redondo como imagen PNG para el mapa nativo (a 2×, se muestra a la
/// mitad con `iconSize: 0.5`).
Future<Uint8List> _iconoPng(IconData icono, Color color, Color fondo) async {
  const lado = 88.0;
  final grabadora = ui.PictureRecorder();
  final lienzo = Canvas(grabadora);
  const centro = Offset(lado / 2, lado / 2);
  lienzo
    ..drawCircle(centro, lado / 2 - 2, Paint()..color = const Color(0x55000000))
    ..drawCircle(centro, lado / 2 - 6, Paint()..color = Colors.white)
    ..drawCircle(centro, lado / 2 - 12, Paint()..color = fondo);
  final texto = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icono.codePoint),
      style: TextStyle(
        fontSize: 44,
        fontFamily: icono.fontFamily,
        package: icono.fontPackage,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  texto.paint(
    lienzo,
    Offset((lado - texto.width) / 2, (lado - texto.height) / 2),
  );
  final imagen = await grabadora.endRecording().toImage(
    lado.toInt(),
    lado.toInt(),
  );
  final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
  return datos!.buffer.asUint8List();
}

/// Brújula sobre el mapa: la aguja señala el norte; tocarla alterna entre
/// norte arriba y girar con el teléfono.
class BotonBrujula extends ConsumerWidget {
  const BotonBrujula({required this.estado, super.key});
  final EstadoOrientacion estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final activo = estado.modo == ModoOrientacion.brujula;
    // La aguja gira con el mapa para seguir apuntando al norte.
    final angulo = (estado.orientado ? estado.rotacionMapa : 0) * math.pi / 180;
    return Semantics(
      button: true,
      toggled: activo,
      label: activo ? l.mapaVolverNorte : l.mapaGirarConTelefono,
      child: Material(
        color: activo ? NexaColors.cyan : Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: estado.modo == ModoOrientacion.navegacion
              ? null
              : ref.read(orientacionMapaProvider.notifier).alternarBrujula,
          child: SizedBox.square(
            dimension: Sizes.touch,
            child: Transform.rotate(
              angle: angulo,
              child: Icon(
                Icons.navigation,
                color: activo ? Colors.white : NexaColors.brand,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvisoOrientacion extends StatelessWidget {
  const _AvisoOrientacion({required this.aviso});
  final AvisoOrientacion aviso;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final texto = aviso == AvisoOrientacion.calibrar
        ? l.mapaCalibrarBrujula
        : l.mapaSinBrujula;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Rad.md),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(Sp.md),
          child: Row(
            children: [
              Icon(
                aviso == AvisoOrientacion.calibrar
                    ? Icons.screen_rotation_alt
                    : Icons.explore_off,
                color: NexaColors.brand,
              ),
              const SizedBox(width: Sp.md),
              Expanded(
                child: Text(
                  texto,
                  style: const TextStyle(color: NexaColors.brand),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Rad.pill),
        boxShadow: NexaShadows.card,
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: NexaColors.brand,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        maxLines: 1,
      ),
    ),
  );
}
