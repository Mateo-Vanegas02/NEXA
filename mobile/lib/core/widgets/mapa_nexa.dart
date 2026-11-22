import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../l10n/gen/app_localizations.dart';
import '../mapa/estilo_mapa.dart';
import '../mapa/imagenes_marcadores.dart';
import '../mapa/reglas_marcadores.dart';
import '../mapa/reglas_ruta.dart';
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
/// (celeste si es quien mira, dorada si la ve el conductor), moto vista desde
/// arriba (siempre derecha; la proa del aro gira con su rumbo), pin cian =
/// recogida y bandera a cuadros = destino. El pasajero propio lleva un haz con
/// el rumbo del teléfono y una marca en el aro que señala dónde está la moto.
///
/// La ruta es [ruta] (el trazado que calculó el servidor con OSRM); sin ella,
/// la línea recta origen→destino. Rediseño 2026:
/// - el estilo (claro, oscuro o automático) lo elige cada persona en el botón
///   de capas, sin depender del tema de la app (`estiloMapaProvider`);
/// - la ruta lleva borde y, con [progreso], lo recorrido se apaga;
/// - la moto se desliza entre un dato y el siguiente en vez de saltar;
/// - con [encuadre], la cámara sigue esos puntos (p. ej. la moto y el destino)
///   hasta que la persona mueve el mapa; «Recentrar» la devuelve.
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
    this.progreso = false,
    this.alternativas = const [],
    this.encuadre,
    this.margenInferior = 360,
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

  /// Muestra el botón de brújula y el de capas (estilo del mapa).
  final bool orientable;

  /// Modo navegación: el mapa sigue a [conductor] y gira con su rumbo.
  final bool navegacion;

  /// Al cambiar la ruta, la cámara la muestra completa.
  final bool encuadrarRuta;

  /// Distancia del botón de brújula al borde superior (para no tapar otros
  /// botones de la pantalla).
  final double brujulaArriba;

  /// La moto va por la ruta: lo que ya recorrió se pinta apagado.
  final bool progreso;

  /// Otras rutas posibles (al desviarse), en gris debajo de la principal.
  final List<List<LatLng>> alternativas;

  /// Puntos que la cámara mantiene a la vista (null = la cámara no se mueve
  /// sola). Se ignora en [navegacion].
  final List<LatLng>? encuadre;

  /// Espacio que tapa la hoja inferior, para encuadrar por encima de ella.
  final double margenInferior;

  /// Acercamiento e inclinación del modo navegación.
  static const zoomNavegacion = 17.0;
  static const inclinacionNavegacion = 50.0;

  /// Tras mover el mapa con el dedo, la cámara deja de seguir este tiempo.
  static const pausaTrasGesto = Duration(seconds: 15);

  @override
  ConsumerState<MapaNexa> createState() => _MapaNexaState();
}

class _MapaNexaState extends ConsumerState<MapaNexa> {
  ml.MapLibreMapController? _ml;

  /// Densidad de la pantalla (px por dp), para el tamaño de los marcadores.
  double _densidad = 2.625;
  bool _estiloListo = false;
  bool _oscuro = true;
  Future<void> _cola = Future.value();

  /// Líneas dibujadas por clave (alternativas, recorrido, borde, ruta), en el
  /// orden en que se apilan.
  final _lineas = <String, ml.Line>{};
  final _lineasPuntos = <String, List<LatLng>>{};
  String _estructuraLineas = '';
  final _simbolos = <String, ml.Symbol>{};
  final _firmas = <String, Object>{};
  bool _solapePermitido = false;
  LatLng? _motoAnterior;
  double? _rumboMoto;
  ModoOrientacion _modoAplicado = ModoOrientacion.norte;
  bool? _rumboPedido;

  // Moto que se desliza entre un dato y el siguiente.
  LatLng? _motoVista;
  LatLng? _motoDesde;
  LatLng? _motoHacia;
  DateTime _animInicio = DateTime.now();
  Duration _animDuracion = Duration.zero;
  DateTime? _ultimoDatoMoto;
  Timer? _animTimer;
  bool _moviendoMoto = false;

  // Cámara que sigue y gesto del usuario.
  DateTime? _gesto;
  DateTime? _ultimoEncuadre;
  Timer? _finPausa;

  /// El haz necesita el rumbo del teléfono aunque el mapa no gire.
  bool get _conHaz => widget.pasajero != null && widget.pasajeroPropio;

  bool get _usaOrientacion => widget.orientable || widget.navegacion || _conHaz;

  bool get _enPausa {
    final g = _gesto;
    return g != null && DateTime.now().difference(g) < MapaNexa.pausaTrasGesto;
  }

  /// Los cambios en el mapa nativo van en fila: así nunca se pisan.
  void _enCola(Future<void> Function() tarea) {
    _cola = _cola.then((_) => tarea()).catchError((Object e) {
      debugPrint('Mapa: $e');
    });
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _finPausa?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(MapaNexa anterior) {
    super.didUpdateWidget(anterior);
    final moto = widget.conductor;
    if (moto != anterior.conductor && moto != null) {
      final r = ReglasMarcadores.rumboDeAvance(_motoAnterior, moto);
      if (r != null || _motoAnterior == null) {
        if (r != null) _rumboMoto = r;
        _motoAnterior = moto;
      }
      _deslizarMotoA(moto);
    } else if (moto == null) {
      _animTimer?.cancel();
      _motoVista = null;
    }
    _enCola(_sincronizar);
    final cambioRuta =
        widget.origen != anterior.origen ||
        widget.destino != anterior.destino ||
        widget.ruta != anterior.ruta;
    if (widget.encuadrarRuta && cambioRuta) _enCola(_encuadrar);
    if (_usaOrientacion &&
        (widget.navegacion != anterior.navegacion ||
            (widget.navegacion && moto != anterior.conductor))) {
      _aplicar(ref.read(orientacionMapaProvider));
    }
    if (!widget.navegacion && widget.encuadre != null) _seguir();
  }

  /// La moto llegó a otro punto: se anima desde donde se ve ahora hasta allí
  /// en lo que tardó el dato (entre 0,3 y 2,5 s). Con «reducir animaciones»
  /// salta.
  void _deslizarMotoA(LatLng destino) {
    // Sin mapa (pruebas) no hay nada que animar.
    if (!ref.read(mapasHabilitadosProvider)) {
      _motoVista = destino;
      return;
    }
    final ahora = DateTime.now();
    final previo = _ultimoDatoMoto;
    _ultimoDatoMoto = ahora;
    final desde = _motoVista;
    if (desde == null ||
        previo == null ||
        !mounted ||
        MediaQuery.disableAnimationsOf(context)) {
      _animTimer?.cancel();
      _motoVista = destino;
      return;
    }
    final ms = ahora.difference(previo).inMilliseconds.clamp(300, 2500);
    _motoDesde = desde;
    _motoHacia = destino;
    _animInicio = ahora;
    _animDuracion = Duration(milliseconds: ms);
    _animTimer?.cancel();
    _animTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      final avance =
          DateTime.now().difference(_animInicio).inMilliseconds /
          _animDuracion.inMilliseconds;
      _motoVista = ReglasRuta.interpolar(_motoDesde!, _motoHacia!, avance);
      if (avance >= 1) t.cancel();
      final c = _ml;
      // Si el mapa nativo va atrasado, se salta este cuadro.
      if (c == null || _moviendoMoto) return;
      _moviendoMoto = true;
      _enCola(() async {
        try {
          await _moto(c);
        } finally {
          _moviendoMoto = false;
        }
      });
    });
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
    _lineas.clear();
    _lineasPuntos.clear();
    _estructuraLineas = '';
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
    if (!widget.navegacion && widget.encuadre != null) {
      _ultimoEncuadre = null;
      _seguir();
    }
  }

  /// Dibuja lo que cambió (rutas, pines, moto) sin rehacer lo demás.
  Future<void> _sincronizar() async {
    final c = _ml;
    if (c == null || !_estiloListo || !mounted) return;
    await _rutas(c);
    await _marcadores(c);
  }

  /// La ruta principal con su borde, lo recorrido apagado y las alternativas
  /// debajo. Si cambia qué líneas hay, se rehacen todas para que se apilen en
  /// orden; si no, solo se mueven sus puntos.
  Future<void> _rutas(ml.MapLibreMapController c) async {
    final puntos = _puntosRuta;
    final moto = _motoVista ?? widget.conductor;
    var recorrido = const <LatLng>[];
    var falta = puntos;
    if (widget.progreso && moto != null && puntos.length >= 2) {
      final partes = ReglasRuta.dividir(puntos, moto);
      recorrido = partes.recorrido;
      falta = partes.falta;
    }
    final oscuro = _oscuro;
    final capas = <(String, List<LatLng>, ml.LineOptions)>[
      for (var i = 0; i < widget.alternativas.length; i++)
        if (widget.alternativas[i].length >= 2)
          (
            'alt$i',
            widget.alternativas[i],
            ml.LineOptions(
              lineColor: _hex(
                oscuro ? NexaColors.rutaAlterna : NexaColors.rutaAlternaClara,
              ),
              lineWidth: 5,
              lineOpacity: 0.9,
              lineJoin: 'round',
            ),
          ),
      if (recorrido.length >= 2)
        (
          'hecha',
          recorrido,
          ml.LineOptions(
            lineColor: _hex(
              oscuro ? NexaColors.rutaRecorrida : NexaColors.rutaRecorridaClara,
            ),
            lineWidth: 6,
            lineJoin: 'round',
          ),
        ),
      if (falta.length >= 2) ...[
        (
          'borde',
          falta,
          ml.LineOptions(
            lineColor: _hex(
              oscuro ? NexaColors.rutaBorde : NexaColors.rutaBordeClara,
            ),
            lineWidth: 10,
            lineJoin: 'round',
          ),
        ),
        (
          'ruta',
          falta,
          ml.LineOptions(
            lineColor: _hex(oscuro ? NexaColors.cyan : NexaColors.rutaClara),
            lineWidth: 6,
            lineJoin: 'round',
          ),
        ),
      ],
    ];
    final estructura = capas.map((e) => e.$1).join(',');
    if (estructura != _estructuraLineas) {
      for (final l in _lineas.values) {
        await c.removeLine(l);
      }
      _lineas.clear();
      _lineasPuntos.clear();
      _estructuraLineas = estructura;
    }
    for (final (clave, geo, op) in capas) {
      final actual = _lineas[clave];
      if (actual != null && _mismos(geo, _lineasPuntos[clave] ?? const [])) {
        continue;
      }
      final conGeo = op.copyWith(
        ml.LineOptions(geometry: geo.map(_aMl).toList()),
      );
      if (actual == null) {
        _lineas[clave] = await c.addLine(conGeo);
      } else {
        await c.updateLine(actual, conGeo);
      }
      _lineasPuntos[clave] = geo;
    }
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
    final moto = _motoVista ?? widget.conductor;
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
    await _moto(c, o: o);
  }

  /// La moto y su proa (también en cada cuadro de la animación).
  Future<void> _moto(ml.MapLibreMapController c, {EstadoOrientacion? o}) async {
    if (!_estiloListo || !mounted) return;
    final orient =
        o ??
        (_usaOrientacion
            ? ref.read(orientacionMapaProvider)
            : const EstadoOrientacion());
    final giroMapa = orient.orientado ? orient.rotacionMapa : 0.0;
    final moto = _motoVista ?? widget.conductor;
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
    final rumboMoto = widget.navegacion && orient.rumbo != null
        ? orient.rumbo
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
              giro: ReglasRumbo.anguloEnPantalla(rumboMoto, giroMapa),
              escala: widget.motoPropia && !gris ? 1.2 : 1,
            ),
    );
  }

  ml.SymbolOptions _op(
    LatLng en,
    String imagen, {
    required int z,
    double giro = 0,
    String ancla = 'center',
    double escala = 1,
  }) => ml.SymbolOptions(
    geometry: _aMl(en),
    iconImage: imagen,
    // MapLibre (Android) toma la imagen en píxeles físicos: se lleva a su
    // tamaño en dp con la densidad de la pantalla.
    iconSize: escala * _densidad / kEscalaMarcador,
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
    final puntos = _puntosRuta;
    if (puntos.length < 2) return;
    await _mostrar(puntos, duracion: null);
  }

  /// Lleva la cámara a [puntos] por encima de la hoja inferior.
  Future<void> _mostrar(List<LatLng> puntos, {Duration? duracion}) async {
    final c = _ml;
    if (c == null || !_estiloListo || puntos.isEmpty) return;
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
    // Puntos muy juntos (o uno solo): se centra con un acercamiento fijo.
    final ml.CameraUpdate cambio = (n - s).abs() < 0.0015 && (e - w).abs() < 0.0015
        ? ml.CameraUpdate.newLatLngZoom(
            ml.LatLng((n + s) / 2, (e + w) / 2),
            16,
          )
        : ml.CameraUpdate.newLatLngBounds(
            ml.LatLngBounds(
              southwest: ml.LatLng(s, w),
              northeast: ml.LatLng(n, e),
            ),
            left: 56,
            right: 56,
            top: 150,
            bottom: widget.margenInferior,
          );
    if (duracion == null || MediaQuery.disableAnimationsOf(context)) {
      await c.animateCamera(cambio);
    } else {
      await c.animateCamera(cambio, duration: duracion);
    }
  }

  /// Cámara que sigue: mantiene [MapaNexa.encuadre] a la vista, como mucho
  /// cada 1,5 s y nunca mientras la persona está moviendo el mapa.
  void _seguir({bool forzar = false}) {
    final puntos = widget.encuadre;
    if (puntos == null || puntos.isEmpty || widget.navegacion) return;
    if (!forzar && _enPausa) return;
    final ahora = DateTime.now();
    final ultimo = _ultimoEncuadre;
    if (!forzar &&
        ultimo != null &&
        ahora.difference(ultimo) < const Duration(milliseconds: 1500)) {
      return;
    }
    _ultimoEncuadre = ahora;
    _enCola(
      () => _mostrar(puntos, duracion: const Duration(milliseconds: 900)),
    );
  }

  void _alGesto() {
    if (widget.encuadre == null || widget.navegacion) return;
    final primera = !_enPausa;
    _gesto = DateTime.now();
    _finPausa?.cancel();
    _finPausa = Timer(MapaNexa.pausaTrasGesto, () {
      if (mounted) setState(() {});
    });
    if (primera) setState(() {});
  }

  void _recentrar() {
    setState(() => _gesto = null);
    _finPausa?.cancel();
    _seguir(forzar: true);
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
    // En navegación la cámara viaja con la moto el mismo tiempo que ella tarda
    // en deslizarse: se ven juntas, sin tirones.
    final duracion = widget.navegacion && _animDuracion > Duration.zero
        ? _animDuracion
        : const Duration(milliseconds: 250);
    _enCola(() async {
      if (sinAnimacion) {
        await c.moveCamera(cambio);
      } else {
        await c.animateCamera(cambio, duration: duracion);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    _densidad = MediaQuery.devicePixelRatioOf(context);
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
    // Estilo elegido por la persona (no el tema de la app).
    _oscuro = ReglasEstiloMapa.oscuro(
      ref.watch(estiloMapaProvider),
      DateTime.now(),
    );
    final estilo = ReglasEstiloMapa.url(oscuro: _oscuro);
    final inicio = widget.navegacion
        ? (widget.conductor ?? widget.centro)
        : widget.centro;
    final mapa = ml.MapLibreMap(
      // Otro estilo = otro mapa nativo (se redibuja todo al cargar).
      key: ValueKey(estilo),
      styleString: estilo,
      initialCameraPosition: ml.CameraPosition(
        target: _aMl(inicio),
        zoom: widget.navegacion ? MapaNexa.zoomNavegacion : widget.zoom,
      ),
      onMapCreated: (c) {
        _ml = c;
        _estiloListo = false;
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
    final botonesArriba = widget.brujulaArriba + Sizes.touch + 4 + Sp.sm;
    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            onPointerMove: (_) => _alGesto(),
            child: mapa,
          ),
        ),
        if (etiqueta != null)
          Positioned(
            top: Sp.md + Sizes.touch + Sp.sm,
            left: 0,
            right: 0,
            child: SafeArea(bottom: false, child: _Etiqueta(texto: etiqueta)),
          ),
        if (orientacion != null && widget.orientable) ...[
          Positioned(
            top: widget.brujulaArriba,
            right: Sp.md,
            child: SafeArea(child: BotonBrujula(estado: orientacion)),
          ),
          Positioned(
            top: botonesArriba,
            right: Sp.md,
            child: SafeArea(
              child: _BotonMapa(
                icono: Icons.layers_outlined,
                etiqueta: l.mapaCapas,
                onTap: () => mostrarCapasMapa(context),
              ),
            ),
          ),
        ],
        if (_enPausa && widget.encuadre != null && !widget.navegacion)
          Positioned(
            top: botonesArriba + Sizes.touch + 4 + Sp.sm,
            right: Sp.md,
            child: SafeArea(
              child: _BotonMapa(
                icono: Icons.center_focus_strong_outlined,
                etiqueta: l.mapaRecentrar,
                destacado: true,
                onTap: _recentrar,
              ),
            ),
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

/// Botón redondo de vidrio sobre el mapa (capas, recentrar).
class _BotonMapa extends StatelessWidget {
  const _BotonMapa({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
    this.destacado = false,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
  final bool destacado;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: etiqueta,
    child: Tooltip(
      message: etiqueta,
      child: Material(
        color: destacado ? NexaColors.cyan : NexaColors.glass,
        shape: CircleBorder(
          side: BorderSide(color: destacado ? NexaColors.cyan : NexaColors.line),
        ),
        elevation: 6,
        shadowColor: Colors.black,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: Sizes.touch + 4,
            child: Icon(
              icono,
              color: destacado ? NexaColors.bg : NexaColors.texto,
            ),
          ),
        ),
      ),
    ),
  );
}

/// «Capas del mapa»: estilo oscuro, claro o automático, con una miniatura de
/// cada uno. Solo cambia el mapa, no el tema de la app.
Future<void> mostrarCapasMapa(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _HojaCapas(),
    );

class _HojaCapas extends ConsumerWidget {
  const _HojaCapas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final actual = ref.watch(estiloMapaProvider);
    final opciones = [
      (EstiloMapa.oscuro, l.mapaOscuro, Icons.dark_mode_outlined),
      (EstiloMapa.claro, l.mapaClaro, Icons.light_mode_outlined),
      (EstiloMapa.automatico, l.mapaAutomatico, Icons.brightness_auto_outlined),
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: NexaColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Rad.sheet)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.md, Sp.xl, Sp.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NexaColors.tenue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: Sp.lg),
              Text(
                l.mapaEstilo,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Sp.xs),
              Text(
                l.mapaEstiloTexto,
                style: const TextStyle(color: NexaColors.muted, fontSize: 14),
              ),
              const SizedBox(height: Sp.lg),
              Row(
                children: [
                  for (final (estilo, nombre, icono) in opciones) ...[
                    if (estilo != EstiloMapa.oscuro)
                      const SizedBox(width: Sp.md),
                    Expanded(
                      child: _OpcionEstilo(
                        estilo: estilo,
                        nombre: nombre,
                        icono: icono,
                        elegido: estilo == actual,
                        onTap: () => ref
                            .read(estiloMapaProvider.notifier)
                            .elegir(estilo),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: Sp.md),
              Text(
                l.mapaAutomaticoTexto,
                style: const TextStyle(color: NexaColors.tenue, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcionEstilo extends StatelessWidget {
  const _OpcionEstilo({
    required this.estilo,
    required this.nombre,
    required this.icono,
    required this.elegido,
    required this.onTap,
  });

  final EstiloMapa estilo;
  final String nombre;
  final IconData icono;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: elegido,
    label: nombre,
    child: InkWell(
      borderRadius: BorderRadius.circular(Rad.lg),
      onTap: onTap,
      child: ExcludeSemantics(
        child: Column(
          children: [
            Container(
              height: 104,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Rad.lg),
                border: Border.all(
                  color: elegido ? NexaColors.cyan : NexaColors.line,
                  width: elegido ? 2.5 : 1,
                ),
                boxShadow: elegido ? NexaShadows.glow : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Rad.lg - 2),
                child: CustomPaint(
                  painter: _MiniMapaPainter(estilo: estilo),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            const SizedBox(height: Sp.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icono,
                  size: 16,
                  color: elegido ? NexaColors.cyan : NexaColors.muted,
                ),
                const SizedBox(width: Sp.xs),
                Flexible(
                  child: Text(
                    nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: elegido ? NexaColors.texto : NexaColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Miniatura de cada estilo: manzanas, una avenida, agua y una ruta. El
/// automático muestra mitad claro y mitad oscuro.
class _MiniMapaPainter extends CustomPainter {
  const _MiniMapaPainter({required this.estilo});
  final EstiloMapa estilo;

  @override
  void paint(Canvas canvas, Size size) {
    switch (estilo) {
      case EstiloMapa.oscuro:
        _pintar(canvas, size, oscuro: true);
      case EstiloMapa.claro:
        _pintar(canvas, size, oscuro: false);
      case EstiloMapa.automatico:
        _pintar(canvas, size, oscuro: false);
        canvas
          ..save()
          ..clipPath(
            Path()
              ..moveTo(size.width, 0)
              ..lineTo(size.width, size.height)
              ..lineTo(0, size.height)
              ..close(),
          );
        _pintar(canvas, size, oscuro: true);
        canvas.restore();
    }
  }

  void _pintar(Canvas c, Size s, {required bool oscuro}) {
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..color = oscuro ? NexaColors.mapaOscuroFondo : NexaColors.mapaClaroFondo,
    );
    c.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(s.width * 0.34, 0)
        ..quadraticBezierTo(s.width * 0.2, s.height * 0.3, 0, s.height * 0.42)
        ..close(),
      Paint()..color = oscuro ? NexaColors.bg : NexaColors.mapaClaroAgua,
    );
    final calle = Paint()
      ..color = oscuro ? NexaColors.mapaOscuroCalle : NexaColors.mapaClaroCalle
      ..strokeWidth = 3;
    for (var i = 1; i < 5; i++) {
      final x = s.width * i / 5;
      final y = s.height * i / 5;
      c
        ..drawLine(Offset(x, 0), Offset(x - 12, s.height), calle)
        ..drawLine(Offset(0, y), Offset(s.width, y - 10), calle);
    }
    c.drawLine(
      Offset(0, s.height * 0.86),
      Offset(s.width, s.height * 0.18),
      Paint()
        ..color = oscuro ? NexaColors.rutaAlterna : NexaColors.mapaClaroAvenida
        ..strokeWidth = 6,
    );
    c.drawPath(
      Path()
        ..moveTo(s.width * 0.2, s.height * 0.75)
        ..lineTo(s.width * 0.45, s.height * 0.72)
        ..lineTo(s.width * 0.5, s.height * 0.4)
        ..lineTo(s.width * 0.8, s.height * 0.35),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = oscuro ? NexaColors.cyan : NexaColors.rutaClara,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniMapaPainter oldDelegate) =>
      oldDelegate.estilo != estilo;
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
    final calibrar = aviso == AvisoOrientacion.calibrar;
    final texto = calibrar ? l.mapaCalibrarBrujula : l.mapaSinBrujula;
    return Semantics(
      liveRegion: true,
      button: calibrar,
      child: Material(
        color: NexaColors.glass,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rad.lg),
          side: BorderSide(color: NexaColors.gold.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Rad.lg),
          // Interferencia: abre la guía para calibrar (diseño G03).
          onTap: calibrar ? () => mostrarCalibrarBrujula(context) : null,
          child: Padding(
            padding: const EdgeInsets.all(Sp.md),
            child: Row(
              children: [
                Icon(
                  calibrar ? Icons.screen_rotation_alt : Icons.explore_off,
                  color: NexaColors.gold,
                ),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: Text(
                    texto,
                    style: const TextStyle(
                      color: NexaColors.texto,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (calibrar)
                  const Icon(Icons.chevron_right, color: NexaColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «Calibra la brújula» (G03): el ocho en el aire y qué tan fiable es el
/// rumbo ahora. Se cierra solo cuando la brújula vuelve a ser fiable.
Future<void> mostrarCalibrarBrujula(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _HojaCalibrar(),
    );

class _HojaCalibrar extends ConsumerWidget {
  const _HojaCalibrar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final aviso = ref.watch(orientacionMapaProvider.select((o) => o.aviso));
    final rumbo = ref.watch(orientacionMapaProvider.select((o) => o.rumbo));
    // Sin interferencia y con rumbo: alta; con interferencia: baja.
    final nivel = aviso == AvisoOrientacion.calibrar
        ? 1
        : rumbo == null
        ? 2
        : 3;
    final (texto, color) = switch (nivel) {
      1 => (l.precisionBaja, NexaColors.error),
      2 => (l.precisionMedia, NexaColors.gold),
      _ => (l.precisionAlta, NexaColors.ok),
    };
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: NexaColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Rad.sheet)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.md, Sp.xl, Sp.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NexaColors.tenue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: Sp.lg),
              Text(
                l.calibraBrujula,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Sp.sm),
              Text(
                l.calibraBrujulaTexto,
                style: const TextStyle(color: NexaColors.muted, fontSize: 15),
              ),
              const SizedBox(height: Sp.lg),
              Container(
                height: 170,
                decoration: BoxDecoration(
                  color: NexaColors.bg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(Rad.lg),
                  border: Border.all(color: NexaColors.line),
                ),
                child: const ExcludeSemantics(
                  child: CustomPaint(painter: _OchoPainter()),
                ),
              ),
              const SizedBox(height: Sp.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.precisionRumbo,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    texto,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: Sp.sm),
              Semantics(
                label: '${l.precisionRumbo}: $texto',
                child: Row(
                  children: [
                    for (var i = 1; i <= 3; i++) ...[
                      if (i > 1) const SizedBox(width: Sp.sm),
                      Expanded(
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: i <= nivel ? color : NexaColors.line,
                            borderRadius: BorderRadius.circular(Rad.pill),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Sp.md),
              Text(
                l.calibraBrujulaNota,
                style: const TextStyle(color: NexaColors.tenue, fontSize: 12),
              ),
              const SizedBox(height: Sp.lg),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(Sizes.boton),
                ),
                child: Text(l.listo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El ocho en el aire con el teléfono en un extremo.
class _OchoPainter extends CustomPainter {
  const _OchoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final a = size.width * 0.28;
    final camino = Path();
    for (var i = 0; i <= 120; i++) {
      final t = i / 120 * 2 * math.pi;
      // Lemniscata de Bernoulli.
      final d = 1 + math.pow(math.sin(t), 2);
      final p = Offset(
        c.dx + a * math.cos(t) / d,
        c.dy + a * math.sin(t) * math.cos(t) / d,
      );
      i == 0 ? camino.moveTo(p.dx, p.dy) : camino.lineTo(p.dx, p.dy);
    }
    canvas
      ..drawPath(
        camino,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..color = NexaColors.cyan.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawPath(
        camino,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = NexaColors.cyan,
      );
    final telefono = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: c.translate(a * 0.82, -a * 0.22),
        width: 30,
        height: 48,
      ),
      const Radius.circular(7),
    );
    canvas
      ..save()
      ..translate(telefono.center.dx, telefono.center.dy)
      ..rotate(0.4)
      ..translate(-telefono.center.dx, -telefono.center.dy)
      ..drawRRect(telefono, Paint()..color = NexaColors.navy)
      ..drawRRect(
        telefono,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = NexaColors.cyan,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
