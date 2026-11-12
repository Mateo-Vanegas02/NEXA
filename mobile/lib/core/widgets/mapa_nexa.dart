import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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

/// Equivale a `invert(100%) hue-rotate(180deg)`: oscurece el mapa conservando
/// el tono de calles y agua.
const ColorFilter _filtroOscuro = ColorFilter.matrix(<double>[
  0.574, -1.43, -0.144, 0, 255, //
  -0.426, -0.43, -0.144, 0, 255, //
  -0.426, -1.43, 0.856, 0, 255, //
  0, 0, 0, 1, 0, //
]);

/// Mapa OpenStreetMap (sin API key) con origen, destino, ruta y conductor.
///
/// La ruta es la línea recta origen→destino: no hay servicio de rutas sin API key
/// (ver docs/PENDIENTES_BACKEND.md).
///
/// Orientación (fase 4): con [orientable] muestra el botón de brújula (norte
/// arriba ↔ girar con el teléfono); con [navegacion] gira con el avance del
/// conductor y sigue a [conductor] de cerca. El rumbo lo da
/// `orientacionMapaProvider`; el mapa solo lo aplica.
class MapaNexa extends ConsumerStatefulWidget {
  const MapaNexa({
    required this.centro,
    this.origen,
    this.destino,
    this.conductor,
    this.etiquetaRuta,
    this.zoom = 14,
    this.onTap,
    this.controller,
    this.orientable = false,
    this.navegacion = false,
    this.brujulaArriba = Sp.md,
    super.key,
  });

  final LatLng centro;
  final LatLng? origen;
  final LatLng? destino;

  /// Posición (aproximada) de la moto del conductor.
  final LatLng? conductor;

  /// Texto sobre la ruta, p. ej. "12 min · 4,2 km".
  final String? etiquetaRuta;
  final double zoom;
  final void Function(LatLng)? onTap;
  final MapController? controller;

  /// Muestra el botón de brújula.
  final bool orientable;

  /// Modo navegación: el mapa sigue a [conductor] y gira con su rumbo.
  final bool navegacion;

  /// Distancia del botón de brújula al borde superior (para no tapar otros
  /// botones de la pantalla).
  final double brujulaArriba;

  /// Acercamiento del modo navegación.
  static const zoomNavegacion = 17.0;

  @override
  ConsumerState<MapaNexa> createState() => _MapaNexaState();
}

class _MapaNexaState extends ConsumerState<MapaNexa> {
  late final MapController _ctrl = widget.controller ?? MapController();
  bool _listo = false;

  bool get _usaOrientacion => widget.orientable || widget.navegacion;

  @override
  void didUpdateWidget(MapaNexa anterior) {
    super.didUpdateWidget(anterior);
    if (!_usaOrientacion) return;
    final e = ref.read(orientacionMapaProvider);
    if (widget.navegacion != anterior.navegacion ||
        (widget.navegacion && widget.conductor != anterior.conductor)) {
      _aplicar(e);
    }
  }

  void _aplicar(EstadoOrientacion e) {
    if (!_listo || !mounted) return;
    final rotacion = e.orientado ? e.rotacionMapa : 0.0;
    final seguir = widget.conductor;
    if (widget.navegacion && seguir != null) {
      _ctrl.moveAndRotate(seguir, MapaNexa.zoomNavegacion, rotacion);
    } else {
      _ctrl.rotate(rotacion);
    }
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
    final o = widget.origen;
    final d = widget.destino;
    final tieneRuta = o != null && d != null;
    final mapa = FlutterMap(
      mapController: _ctrl,
      options: MapOptions(
        initialCenter: widget.navegacion
            ? (widget.conductor ?? widget.centro)
            : widget.centro,
        initialZoom: widget.navegacion ? MapaNexa.zoomNavegacion : widget.zoom,
        onMapReady: () {
          _listo = true;
          final e = orientacion;
          if (e != null) _aplicar(e);
        },
        // Sin giro con dos dedos: el mapa solo gira con la brújula o en
        // navegación, y la aguja siempre dice dónde está el norte.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: widget.onTap == null ? null : (_, p) => widget.onTap!(p),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.nexa.nexa_mobile',
          // En tema oscuro se invierte el color de los mosaicos (sin servicio externo).
          tileBuilder: Theme.of(context).brightness == Brightness.dark
              ? (_, tile, _) =>
                    ColorFiltered(colorFilter: _filtroOscuro, child: tile)
              : null,
        ),
        if (tieneRuta)
          PolylineLayer(
            polylines: [
              Polyline(points: [o, d], strokeWidth: 5, color: NexaColors.cyan),
            ],
          ),
        MarkerLayer(
          // Los pines quedan derechos aunque el mapa gire.
          rotate: true,
          markers: [
            if (o != null)
              Marker(
                point: o,
                width: 28,
                height: 28,
                child: const _Pin(color: NexaColors.brand),
              ),
            if (d != null)
              Marker(
                point: d,
                width: 28,
                height: 28,
                child: const _Pin(color: NexaColors.cyan),
              ),
            if (tieneRuta && widget.etiquetaRuta != null)
              Marker(
                point: LatLng(
                  (o.latitude + d.latitude) / 2,
                  (o.longitude + d.longitude) / 2,
                ),
                width: 150,
                height: 36,
                child: _Etiqueta(texto: widget.etiquetaRuta!),
              ),
            if (widget.conductor != null)
              Marker(
                point: widget.conductor!,
                width: 44,
                height: 44,
                child: widget.navegacion && orientacion?.rumbo != null
                    ? _Flecha(
                        angulo: ReglasRumbo.anguloEnPantalla(
                          orientacion!.rumbo!,
                          orientacion.rotacionMapa,
                        ),
                      )
                    : const _Moto(),
              ),
          ],
        ),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [TextSourceAttribution('© OpenStreetMap')],
        ),
      ],
    );
    if (orientacion == null) return mapa;
    return Stack(
      children: [
        Positioned.fill(child: mapa),
        if (widget.orientable)
          Positioned(
            top: widget.brujulaArriba,
            right: Sp.md,
            child: SafeArea(child: BotonBrujula(estado: orientacion)),
          ),
        if (orientacion.orientado &&
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

class _Pin extends StatelessWidget {
  const _Pin({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
    ),
  );
}

class _Moto extends StatelessWidget {
  const _Moto();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: NexaColors.brand, width: 2),
      boxShadow: NexaShadows.card,
    ),
    child: const Icon(Icons.two_wheeler, color: NexaColors.brand, size: 24),
  );
}

/// La moto en modo navegación: una flecha que apunta hacia donde avanza.
class _Flecha extends StatelessWidget {
  const _Flecha({required this.angulo});

  /// Grados en pantalla (0 = arriba, horario).
  final double angulo;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: NexaColors.cyan,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: NexaShadows.card,
    ),
    child: Transform.rotate(
      angle: angulo * math.pi / 180,
      child: const Icon(Icons.navigation, color: Colors.white, size: 24),
    ),
  );
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
