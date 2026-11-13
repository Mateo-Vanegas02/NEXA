import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../config/env.dart';
import '../l10n/gen/app_localizations.dart';
import '../mapa/imagenes_marcadores.dart';
import '../mapa/reglas_marcadores.dart';
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
/// Marcadores «Quién es quién» (prototipo M01–M05): personita = pasajero
/// (celeste si es quien mira, dorada si la ve el conductor), motico = moto
/// (siempre derecha; la proa del aro gira con su rumbo), pin cian = recogida
/// y cuadro blanco = destino. El pasajero propio lleva un haz con el rumbo del
/// teléfono y una marca en el aro que señala dónde está la moto.
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
    this.conductorSinSenal = false,
    this.motoPropia = false,
    this.pasajero,
    this.pasajeroPropio = true,
    this.pasajeroSinSenal = false,
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

  /// La última posición de la moto es vieja: se pinta gris.
  final bool conductorSinSenal;

  /// La moto es la de quien mira (panel del conductor): más grande.
  final bool motoPropia;

  /// Posición del pasajero (personita).
  final LatLng? pasajero;

  /// true = es quien mira (celeste, con haz y marca hacia la moto);
  /// false = la pasajera vista por el conductor (dorada, sin haz).
  final bool pasajeroPropio;

  /// La posición del pasajero ya venció: personita gris.
  final bool pasajeroSinSenal;

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
  final _simbolos = <String, ml.Symbol>{};
  final _firmas = <String, Object>{};
  bool _solapePermitido = false;
  LatLng? _motoAnterior;
  double? _rumboMoto;
  ModoOrientacion _modoAplicado = ModoOrientacion.norte;
  bool? _rumboPedido;

  /// El haz necesita el rumbo del teléfono aunque el mapa no gire.
  bool get _conHaz => widget.pasajero != null && widget.pasajeroPropio;

  bool get _usaOrientacion => widget.orientable || widget.navegacion || _conHaz;

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
    if (widget.conductor != anterior.conductor && widget.conductor != null) {
      final r = ReglasMarcadores.rumboDeAvance(
        _motoAnterior,
        widget.conductor!,
      );
      if (r != null || _motoAnterior == null) {
        if (r != null) _rumboMoto = r;
        _motoAnterior = widget.conductor;
      }
    }
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
    _lineaPuntos = const [];
    _simbolos.clear();
    _firmas.clear();
    _solapePermitido = false;
    for (final e in (await _imagenes()).entries) {
      await c.addImage(e.key, e.value);
    }
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
            lineWidth: 6,
            lineJoin: 'round',
          ),
        );
      }
      _lineaPuntos = puntos;
    }
    await _marcadores(c);
  }

  /// Dibuja (o mueve, o quita) cada marcador; solo toca los que cambiaron.
  Future<void> _marcadores(ml.MapLibreMapController c) async {
    if (!_estiloListo || !mounted) return;
    final o = _usaOrientacion
        ? ref.read(orientacionMapaProvider)
        : const EstadoOrientacion();
    final giroMapa = o.orientado ? o.rotacionMapa : 0.0;
    double enPantalla(double rumbo) =>
        ReglasRumbo.anguloEnPantalla(rumbo, giroMapa);

    final recogida = widget.origen;
    await _simbolo(
      c,
      'recogida',
      recogida == null
          ? null
          : _op(recogida, ImagenMarcador.recogida, z: 5, ancla: 'bottom'),
    );
    final destino = widget.destino;
    await _simbolo(
      c,
      'destino',
      destino == null ? null : _op(destino, ImagenMarcador.destino, z: 5),
    );

    final pasajero = widget.pasajero;
    final moto = widget.conductor;
    final propio = widget.pasajeroPropio;
    final rumboTel = o.rumbo;
    await _simbolo(
      c,
      'haz',
      pasajero == null || !propio || rumboTel == null
          ? null
          : _op(
              pasajero,
              ImagenMarcador.hazCielo,
              z: 1,
              giro: enPantalla(rumboTel),
            ),
    );
    await _simbolo(
      c,
      'persona',
      pasajero == null
          ? null
          : _op(
              pasajero,
              widget.pasajeroSinSenal
                  ? ImagenMarcador.personaGris
                  : propio
                  ? ImagenMarcador.personaCielo
                  : ImagenMarcador.personaOro,
              z: 3,
            ),
    );
    await _simbolo(
      c,
      'marca',
      pasajero == null || moto == null || !propio
          ? null
          : _op(
              pasajero,
              ImagenMarcador.marcaHacia,
              z: 4,
              giro: enPantalla(ReglasMarcadores.rumboEntre(pasajero, moto)),
            ),
    );

    final gris = widget.conductorSinSenal;
    await _simbolo(
      c,
      'moto',
      moto == null
          ? null
          : _op(
              moto,
              gris
                  ? ImagenMarcador.motoGris
                  : widget.motoPropia
                  ? ImagenMarcador.motoPropia
                  : ImagenMarcador.moto,
              z: 7,
            ),
    );
    // En navegación manda la brújula/GPS del propio conductor; si no, el
    // avance entre posiciones.
    final rumboMoto = widget.navegacion && o.rumbo != null
        ? o.rumbo
        : _rumboMoto;
    await _simbolo(
      c,
      'proa',
      moto == null || rumboMoto == null
          ? null
          : _op(
              moto,
              gris ? ImagenMarcador.proaGris : ImagenMarcador.proa,
              z: 8,
              giro: enPantalla(rumboMoto),
              tam: widget.motoPropia && !gris ? 0.6 : 0.5,
            ),
    );
  }

  ml.SymbolOptions _op(
    LatLng en,
    String imagen, {
    required int z,
    double giro = 0,
    String ancla = 'center',
    double tam = 1 / kEscalaMarcador,
  }) => ml.SymbolOptions(
    geometry: _aMl(en),
    iconImage: imagen,
    iconSize: tam,
    iconRotate: giro,
    iconAnchor: ancla,
    zIndex: z,
  );

  Future<void> _simbolo(
    ml.MapLibreMapController c,
    String clave,
    ml.SymbolOptions? op,
  ) async {
    final actual = _simbolos[clave];
    if (op == null) {
      _firmas.remove(clave);
      if (actual != null) {
        _simbolos.remove(clave);
        await c.removeSymbol(actual);
      }
      return;
    }
    // Giros de menos de un grado no se reenvían al mapa nativo.
    final firma = (
      op.geometry,
      op.iconImage,
      (op.iconRotate ?? 0).round(),
      op.iconSize,
    );
    if (actual != null && _firmas[clave] == firma) return;
    _firmas[clave] = firma;
    if (actual != null) {
      await c.updateSymbol(actual, op);
      return;
    }
    _simbolos[clave] = await c.addSymbol(op);
    if (!_solapePermitido) {
      // Los marcadores se encimen (haz bajo la personita, proa sobre la
      // moto) en vez de esconderse unos a otros.
      _solapePermitido = true;
      await c.symbolManager?.setIconAllowOverlap(true);
      await c.symbolManager?.setIconIgnorePlacement(true);
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
      ref.listen(orientacionMapaProvider, (_, e) {
        _aplicar(e);
        final c = _ml;
        if (c != null) _enCola(() => _marcadores(c));
      });
      if (_rumboPedido != _conHaz) {
        _rumboPedido = _conHaz;
        final quiere = _conHaz;
        final ctrl = ref.read(orientacionMapaProvider.notifier);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ctrl.pedirRumbo(quiere);
        });
      }
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

/// Las imágenes de los marcadores se dibujan una vez por proceso.
Future<Map<String, Uint8List>>? _cacheImagenes;
Future<Map<String, Uint8List>> _imagenes() =>
    _cacheImagenes ??= dibujarMarcadores();

/// Brújula sobre el mapa (diseño G01): disco de vidrio con la aguja roja al
/// norte; tocarla alterna entre norte arriba y girar con el teléfono.
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
        color: NexaColors.glass,
        shape: CircleBorder(
          side: BorderSide(
            color: activo ? NexaColors.cyan : NexaColors.line,
            width: activo ? 2 : 1,
          ),
        ),
        elevation: 6,
        shadowColor: Colors.black,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: estado.modo == ModoOrientacion.navegacion
              ? null
              : ref.read(orientacionMapaProvider.notifier).alternarBrujula,
          child: SizedBox.square(
            dimension: Sizes.touch + 4,
            child: Transform.rotate(
              angle: angulo,
              child: const CustomPaint(painter: _AgujaPainter()),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgujaPainter extends CustomPainter {
  const _AgujaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas
      ..drawPath(
        Path()
          ..moveTo(c.dx, c.dy - 17)
          ..lineTo(c.dx + 6, c.dy)
          ..lineTo(c.dx - 6, c.dy)
          ..close(),
        Paint()..color = NexaColors.error,
      )
      ..drawPath(
        Path()
          ..moveTo(c.dx, c.dy + 17)
          ..lineTo(c.dx - 6, c.dy)
          ..lineTo(c.dx + 6, c.dy)
          ..close(),
        Paint()..color = NexaColors.muted,
      );
    final n = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: NexaColors.texto,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    n.paint(canvas, Offset(c.dx - n.width / 2, c.dy - 26));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: NexaColors.glass,
          borderRadius: BorderRadius.circular(Rad.lg),
          border: Border.all(color: NexaColors.gold.withValues(alpha: 0.5)),
          boxShadow: NexaShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(Sp.md),
          child: Row(
            children: [
              Icon(
                aviso == AvisoOrientacion.calibrar
                    ? Icons.screen_rotation_alt
                    : Icons.explore_off,
                color: NexaColors.gold,
              ),
              const SizedBox(width: Sp.md),
              Expanded(
                child: Text(
                  texto,
                  style: const TextStyle(color: NexaColors.texto, fontSize: 13),
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
      padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 6),
      decoration: BoxDecoration(
        color: NexaColors.glass,
        borderRadius: BorderRadius.circular(Rad.pill),
        border: Border.all(color: NexaColors.line),
        boxShadow: NexaShadows.card,
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: NexaColors.texto,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        maxLines: 1,
      ),
    ),
  );
}
