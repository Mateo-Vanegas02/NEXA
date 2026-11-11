import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/perfil_pasajero.dart';
import '../domain/servicio.dart';
import '../domain/viajes_repository.dart';

typedef _Json = Map<String, dynamic>;

/// Ejecuta una llamada Dio y traduce cualquier fallo a [AppException].
Future<T> _guard<T>(Future<T> Function() f) async {
  try {
    return await f();
  } catch (e) {
    throw AppException.from(e);
  }
}

List<Servicio> _lista(Object? data) => (data as List<dynamic>? ?? [])
    .map((e) => Servicio.fromJson(e as _Json))
    .toList();

class ApiPasajeroRepository implements PasajeroRepository {
  ApiPasajeroRepository(this._dio);
  final Dio _dio;

  @override
  Future<PerfilPasajero> perfil() => _guard(() async {
    final r = await _dio.get<_Json>('/pasajero/perfil');
    return PerfilPasajero.fromBackend(r.data!);
  });

  @override
  Future<Servicio> solicitar(SolicitudViaje s) => _guard(() async {
    final r = await _dio.post<_Json>(
      '/pasajero/solicitar-viaje',
      data: s.toJson(),
    );
    return Servicio.fromJson(r.data!);
  });

  @override
  Future<Cotizacion> cotizar(Coordenada origen, Coordenada destino) =>
      _guard(() async {
        final r = await _dio.post<_Json>(
          '/pasajero/cotizar',
          data: {
            'ubicacionOrigen': origen.toJson(),
            'ubicacionDestino': destino.toJson(),
          },
        );
        return Cotizacion.fromJson(r.data!);
      });

  @override
  Future<Servicio> cancelar(String id) => _guard(() async {
    final r = await _dio.post<_Json>('/pasajero/cancelar-viaje/$id');
    return Servicio.fromJson(r.data!);
  });

  @override
  Future<void> subirExtra(String id, int incremento) => _guard(() async {
    await _dio.post<Object?>(
      '/pasajero/subir-oferta/$id',
      data: {'incremento': incremento},
    );
  });

  @override
  Future<PosicionViaje?> posicionConductor(String id) => _guard(() async {
    final r = await _dio.get<Object?>('/pasajero/posicion-conductor/$id');
    final datos = r.data;
    // 204: el conductor aún no reporta posición (o ya venció).
    if (r.statusCode == 204 || datos is! _Json) return null;
    return PosicionViaje.fromJson(datos);
  });

  @override
  Future<void> reportarUbicacion(String id, Coordenada posicion) =>
      _guard(() async {
        await _dio.post<Object?>(
          '/pasajero/ubicacion/$id',
          data: posicion.toJson(),
        );
      });

  @override
  Future<List<Servicio>> historial() => _guard(() async {
    final r = await _dio.get<List<dynamic>>('/pasajero/historial');
    return _lista(r.data);
  });

  @override
  Future<Servicio> detalle(String id) => _guard(() async {
    final r = await _dio.get<_Json>('/pasajero/servicios/$id');
    return Servicio.fromJson(r.data!);
  });

  @override
  Future<Servicio> calificar(
    String id,
    double calificacion,
    String comentarios,
  ) => _guard(() async {
    final r = await _dio.post<_Json>(
      '/pasajero/calificar-servicio/$id',
      data: {'calificacion': calificacion, 'comentarios': comentarios},
    );
    return Servicio.fromJson(r.data!);
  });

  @override
  Future<DesglosePasajero> desglose(String id) => _guard(() async {
    final r = await _dio.get<_Json>('/niveles/viajes/$id/desglose');
    return DesglosePasajero.fromJson(r.data!);
  });
}

class ApiConductorRepository implements ConductorRepository {
  ApiConductorRepository(this._dio);
  final Dio _dio;

  Future<Servicio> _accion(String ruta, String id) => _guard(() async {
    final r = await _dio.post<_Json>('/conductor/$ruta/$id');
    return Servicio.fromJson(r.data!);
  });

  @override
  Future<List<Servicio>> disponibles({double? lat, double? lng}) =>
      _guard(() async {
        final r = await _dio.get<List<dynamic>>(
          '/conductor/servicios-disponibles',
          queryParameters: {'lat': ?lat, 'lng': ?lng},
        );
        return _lista(r.data);
      });

  @override
  Future<PosicionViaje?> reportarUbicacion(
    Coordenada posicion, {
    required bool disponible,
  }) => _guard(() async {
    final r = await _dio.post<Object?>(
      '/conductor/ubicacion',
      data: {...posicion.toJson(), 'disponible': disponible},
    );
    // 204: no tiene un viaje que seguir (solo se registró su posición).
    final datos = r.data;
    if (r.statusCode == 204 || datos is! _Json) return null;
    return PosicionViaje.fromJson(datos);
  });

  @override
  Future<Servicio?> viajeActivo() => _guard(() async {
    final r = await _dio.get<Object?>('/conductor/viaje-activo');
    final datos = r.data;
    if (r.statusCode == 204 || datos is! _Json) return null;
    return Servicio.fromJson(datos);
  });

  @override
  Future<PosicionPasajero?> ubicacionPasajero(String id) => _guard(() async {
    final r = await _dio.get<Object?>('/conductor/pasajero-ubicacion/$id');
    final datos = r.data;
    if (r.statusCode == 204 || datos is! _Json) return null;
    return PosicionPasajero.fromJson(datos);
  });

  @override
  Future<Servicio> llegue(String id, Coordenada posicion) => _guard(() async {
    final r = await _dio.post<_Json>(
      '/conductor/llegue/$id',
      data: posicion.toJson(),
    );
    return Servicio.fromJson(r.data!);
  });

  @override
  Future<SaldoConductor> saldo({int dias = 30}) => _guard(() async {
    final r = await _dio.get<_Json>(
      '/conductor/saldo',
      queryParameters: {'dias': dias},
    );
    return SaldoConductor.fromJson(r.data!);
  });

  @override
  Future<Servicio> aceptar(String id) => _accion('aceptar-servicio', id);
  @override
  Future<Servicio> iniciar(String id) => _accion('iniciar-servicio', id);
  @override
  Future<Servicio> finalizar(String id) => _accion('finalizar-servicio', id);
  @override
  Future<Servicio> cancelar(String id) => _accion('cancelar-servicio', id);

  @override
  Future<List<Servicio>> enCurso() => _guard(() async {
    final r = await _dio.get<List<dynamic>>('/conductor/servicios-en-curso');
    return _lista(r.data);
  });

  @override
  Future<List<Servicio>> historial() => _guard(() async {
    final r = await _dio.get<List<dynamic>>('/conductor/historial');
    return _lista(r.data);
  });

  @override
  Future<List<Ingreso>> ingresos({String? periodo}) => _guard(() async {
    final r = await _dio.get<List<dynamic>>(
      '/conductor/ingresos',
      queryParameters: {'periodo': ?periodo},
    );
    return (r.data ?? []).map((e) => Ingreso.fromJson(e as _Json)).toList();
  });

  @override
  Future<DesgloseConductor> desglose(String id) => _guard(() async {
    final r = await _dio.get<_Json>('/niveles/viajes/$id/desglose');
    return DesgloseConductor.fromJson(r.data!);
  });
}
