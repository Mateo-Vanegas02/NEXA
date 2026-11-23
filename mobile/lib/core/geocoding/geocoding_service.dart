import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../mapa/zona_servicio.dart';

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
  /// Busca [consulta] solo dentro de la zona de servicio (Cartagena). [cerca]
  /// es la posición del usuario (la pantalla muestra a cuántos km queda cada
  /// lugar).
  Future<List<Lugar>> buscar(String consulta, {LatLng? cerca});

  /// Nombre legible de un punto del mapa, o `null` si no se encuentra.
  Future<String?> nombreDe(LatLng punto);
}

/// Implementación con Nominatim (OpenStreetMap): gratuita y sin API key.
///
/// Política de uso: https://operations.osmfoundation.org/policies/nominatim/
/// (máx. 1 petición/segundo, User-Agent identificable y sin autocompletar: la
/// app busca solo al tocar «Buscar»). Pide solo el rectángulo de la zona
/// (`bounded=1`, filtro estricto) y descarta lo que quede fuera del polígono.
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
          // Más de los que se muestran: el polígono descarta los del borde.
          'limit': 10,
          'countrycodes': 'co',
          'addressdetails': 0,
          // Solo el rectángulo de Cartagena: con bounded=1 es un filtro, no
          // una preferencia (antes salían lugares de otras ciudades).
          'viewbox':
              '${ZonaServicio.oeste},${ZonaServicio.norte},'
              '${ZonaServicio.este},${ZonaServicio.sur}',
          'bounded': 1,
        },
      );
      return filtrarEnZona([
        for (final e in r.data ?? const <dynamic>[])
          if (e is Map<String, dynamic>) _aLugar(e),
      ]);
    } on DioException {
      return const [];
    }
  }

  /// Deja solo los lugares dentro de la zona (el rectángulo deja pasar, p. ej.,
  /// Turbaco), sin repetir el mismo lugar, en el orden de relevancia del
  /// buscador y como mucho [maximo].
  static List<Lugar> filtrarEnZona(List<Lugar> lugares, {int maximo = 6}) {
    final vistos = <String>{};
    final enZona = [
      for (final l in lugares)
        if (ZonaServicio.contiene(l.punto) &&
            vistos.add(
              '${l.nombre.toLowerCase()}|'
              '${l.punto.latitude.toStringAsFixed(4)},'
              '${l.punto.longitude.toStringAsFixed(4)}',
            ))
          l,
    ];
    return enZona.take(maximo).toList();
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
