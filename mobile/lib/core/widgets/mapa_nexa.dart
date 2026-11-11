import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../theme/tokens.dart';

/// Centro por defecto (Cartagena, igual que la web) cuando no hay GPS.
const LatLng kCentroPorDefecto = LatLng(10.4055, -75.5037);

/// En tests se sobrescribe con `false` para no descargar teselas.
final mapasHabilitadosProvider = Provider<bool>((ref) => true);

/// Ubicación actual; si falla el permiso o el GPS, usa [kCentroPorDefecto].
final ubicacionProvider = FutureProvider<LatLng>((ref) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return kCentroPorDefecto;
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
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
class MapaNexa extends ConsumerWidget {
  const MapaNexa({
    required this.centro,
    this.origen,
    this.destino,
    this.conductor,
    this.etiquetaRuta,
    this.zoom = 14,
    this.onTap,
    this.controller,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(mapasHabilitadosProvider)) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        alignment: Alignment.center,
        child: const Icon(Icons.map_outlined, size: 48),
      );
    }
    final o = origen;
    final d = destino;
    final tieneRuta = o != null && d != null;
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: centro,
        initialZoom: zoom,
        onTap: onTap == null ? null : (_, p) => onTap!(p),
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
          markers: [
            if (o != null)
              Marker(
                point: o,
                width: 28,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: NexaColors.brand,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            if (d != null)
              Marker(
                point: d,
                width: 28,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: NexaColors.cyan,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            if (tieneRuta && etiquetaRuta != null)
              Marker(
                point: LatLng(
                  (o.latitude + d.latitude) / 2,
                  (o.longitude + d.longitude) / 2,
                ),
                width: 150,
                height: 36,
                child: _Etiqueta(texto: etiquetaRuta!),
              ),
            if (conductor != null)
              Marker(
                point: conductor!,
                width: 44,
                height: 44,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: NexaColors.brand, width: 2),
                    boxShadow: NexaShadows.card,
                  ),
                  child: const Icon(
                    Icons.two_wheeler,
                    color: NexaColors.brand,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [TextSourceAttribution('© OpenStreetMap')],
        ),
      ],
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
