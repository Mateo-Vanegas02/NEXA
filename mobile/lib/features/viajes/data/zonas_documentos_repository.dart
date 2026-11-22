import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/zonas_documentos.dart';

class ApiZonasDocumentosRepository implements ZonasDocumentosRepository {
  ApiZonasDocumentosRepository(this._dio);
  final Dio _dio;

  Future<List<T>> _lista<T>(
    String ruta,
    T Function(Map<String, dynamic>) leer,
  ) async {
    try {
      final r = await _dio.get<List<dynamic>>(ruta);
      return [for (final e in r.data ?? const []) leer(e as Map<String, dynamic>)];
    } catch (e) {
      final x = AppException.from(e);
      // Un servidor sin estas rutas todavía: se muestra como vacío.
      if (x.statusCode == 404 || x.statusCode == 405) return const [];
      throw x;
    }
  }

  @override
  Future<List<ZonaDemanda>> zonas() =>
      _lista('/conductor/zonas', ZonaDemanda.fromJson);

  @override
  Future<List<MiDocumento>> misDocumentos() =>
      _lista('/conductor/documentos', MiDocumento.fromJson);
}

class MockZonasDocumentosRepository implements ZonasDocumentosRepository {
  const MockZonasDocumentosRepository();

  @override
  Future<List<ZonaDemanda>> zonas() async => const [
    ZonaDemanda(latitud: 10.3975, longitud: -75.5525, solicitudes: 6, intensidad: 1),
    ZonaDemanda(latitud: 10.4225, longitud: -75.5475, solicitudes: 4, intensidad: 0.67),
    ZonaDemanda(latitud: 10.4125, longitud: -75.5375, solicitudes: 2, intensidad: 0.33),
  ];

  @override
  Future<List<MiDocumento>> misDocumentos() async {
    final hoy = DateTime.now();
    return [
      MiDocumento(
        id: 'd1',
        tipo: 'LICENCIA',
        venceEl: DateTime(hoy.year + 3, 5, 10),
        vigencia: Vigencia.vigente,
      ),
      MiDocumento(
        id: 'd2',
        tipo: 'SOAT',
        venceEl: hoy.add(const Duration(days: 18)),
        vigencia: Vigencia.porVencer,
        diasRestantes: 18,
      ),
      const MiDocumento(id: 'd3', tipo: 'TECNOMECANICA'),
      const MiDocumento(
        id: 'd4',
        tipo: 'TARJETA_PROPIEDAD',
        vigencia: Vigencia.noVence,
      ),
    ];
  }
}
