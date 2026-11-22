import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/vehiculo.dart';

class ApiVehiculosRepository implements VehiculosRepository {
  ApiVehiculosRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<VehiculoConductor>> listar() async {
    try {
      final r = await _dio.get<List<dynamic>>('/conductor/vehiculos');
      return (r.data ?? const [])
          .map((e) => VehiculoConductor.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }
}

/// Modo demostración: una moto activa y verificada.
class MockVehiculosRepository implements VehiculosRepository {
  const MockVehiculosRepository();

  @override
  Future<List<VehiculoConductor>> listar() async => const [
    VehiculoConductor(
      id: 'v1',
      placa: 'KZT38F',
      marca: 'Yamaha',
      modelo: 'NMAX',
      color: 'Gris',
      activo: true,
      verificado: true,
    ),
  ];
}
