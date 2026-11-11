import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Un lugar encontrado: nombre corto para mostrar y coordenadas.
class Lugar {
  const Lugar({
    required this.nombre,
    required this.detalle,
    required this.punto,
  });

  final String nombre;
  final String detalle;
  final LatLng punto;
}

/// Búsqueda de direcciones (geocodificación) y su inversa.
abstract interface class GeocodingService {
  /// Busca [consulta] priorizando resultados cercanos a [cerca].
  Future<List<Lugar>> buscar(String consulta, {LatLng? cerca});

  /// Nombre legible de un punto del mapa, o `null` si no se encuentra.
  Future<String?> nombreDe(LatLng punto);
}

/// Implementación con Nominatim (OpenStreetMap): gratuita y sin API key.
///
/// Política de uso: https://operations.osmfoundation.org/policies/nominatim/
/// (máx. 1 petición/segundo, User-Agent identificable; la app usa debounce).
/// Usa su propio [Dio]: nunca debe enviarse el token de NEXA a terceros.
class NominatimGeocoding implements GeocodingService {
  NominatimGeocoding([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://nominatim.openstreetmap.org',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: {
                'User-Agent': 'NEXA-Mobile/1.0 (com.nexa.nexa_mobile)',
                'Accept-Language': 'es',
              },
            ),
          );

  final Dio _dio;

  @override
  Future<List<Lugar>> buscar(String consulta, {LatLng? cerca}) async {
    final q = consulta.trim();
    if (q.length < 3) return const [];
    try {
      final r = await _dio.get<List<dynamic>>(
        '/search',
        queryParameters: {
          'format': 'jsonv2',
          'q': q,
          'limit': 5,
          'countrycodes': 'co',
          'addressdetails': 0,
          if (cerca != null)
            'viewbox':
                '${cerca.longitude - 0.6},${cerca.latitude + 0.6},'
                '${cerca.longitude + 0.6},${cerca.latitude - 0.6}',
        },
      );
      return [
        for (final e in r.data ?? const <dynamic>[])
          if (e is Map<String, dynamic>) _aLugar(e),
      ];
    } on DioException {
      return const [];
    }
  }

  @override
  Future<String?> nombreDe(LatLng punto) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': punto.latitude,
          'lon': punto.longitude,
          'zoom': 18,
        },
      );
      final nombre = r.data?['display_name'] as String?;
      return nombre == null ? null : _corto(nombre);
    } on DioException {
      return null;
    }
  }

  static Lugar _aLugar(Map<String, dynamic> e) {
    final completo = (e['display_name'] as String?) ?? '';
    final partes = completo.split(',').map((p) => p.trim()).toList();
    return Lugar(
      nombre: (e['name'] as String?)?.isNotEmpty ?? false
          ? e['name'] as String
          : (partes.isEmpty ? completo : partes.first),
      detalle: partes.length > 1 ? partes.skip(1).take(3).join(', ') : '',
      punto: LatLng(
        double.parse(e['lat'].toString()),
        double.parse(e['lon'].toString()),
      ),
    );
  }

  static String _corto(String displayName) =>
      displayName.split(',').map((p) => p.trim()).take(3).join(', ');
}

final geocodingProvider = Provider<GeocodingService>(
  (ref) => NominatimGeocoding(),
);
