import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/perfil_pasajero.dart';
import '../domain/servicio.dart';
import '../../../core/sin_conexion/reglas_sin_conexion.dart';
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

/// Lee una lista de viajes. Un viaje que no se puede leer (un campo con un
/// formato que la app no espera) se salta en vez de tumbar la lista entera:
/// si no, el error hace que Riverpod reintente la petición una y otra vez.
/// En debug se registra qué falló, sin los datos del viaje.
List<Servicio> _lista(Object? data) {
  final viajes = <Servicio>[];
  for (final e in data as List<dynamic>? ?? const []) {
    try {
      viajes.add(Servicio.fromJson(e as _Json));
    } on Object catch (error) {
      final id = e is Map ? e['id'] : null;
      debugPrint('Viaje $id sin leer: ${error.runtimeType}: $error');
    }
  }
  return viajes;
}

/// ¿La respuesta es un viaje? Varias acciones solo devuelven
/// `{mensaje, servicioId}` y el viaje hay que pedirlo aparte.
@visibleForTesting
bool esServicio(Map<String, dynamic>? datos) =>
    datos != null && datos['id'] is String && datos['estado'] is String;

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
    // El servidor responde {mensaje, servicioId, desglose}, no el viaje: el
    // detalle se pide aparte (ya pasa por la vista del pasajero).
    final datos = r.data!;
    if (esServicio(datos)) return Servicio.fromJson(datos);
    final id = datos['servicioId'];
    if (id is! String || id.isEmpty || id == 'null-id') {
      throw const AppException(
        ErrorKind.desconocido,
        'El servidor no devolvió el viaje creado.',
      );
    }
    return _detalle(id);
  });

  @override
  Future<String?> viajeAbiertoId() => _guard(() async {
    final pendiente = await _dio.get<_Json>('/pasajero/solicitud-activa');
    final p = pendiente.data;
    if (p != null && p['activa'] == true && p['servicioId'] is String) {
      return p['servicioId'] as String;
    }
    final enCamino = await _dio.get<_Json>('/pasajero/viaje-en-camino');
    final c = enCamino.data;
    if (c != null && c['activo'] == true && c['id'] is String) {
      return c['id'] as String;
    }
    return null;
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
    // Responde {mensaje, servicioId, cargoCancelacion}: el viaje se pide aparte.
    final datos = r.data;
    if (esServicio(datos)) return Servicio.fromJson(datos!);
    return _detalle(id);
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
  Future<Servicio> detalle(String id) => _guard(() => _detalle(id));

  Future<Servicio> _detalle(String id) async {
    final r = await _dio.get<_Json>('/pasajero/servicios/$id');
    return Servicio.fromJson(r.data!);
  }

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

  /// Las acciones responden `{mensaje, servicioId, …}`, no el viaje: se
  /// busca después (el activo si sigue en marcha; si no, en el historial).
  Future<Servicio> _accion(
    String ruta,
    String id, {
    String? llave,
    DateTime? ocurridoEn,
  }) => _guard(() async {
    final r = await _dio.post<_Json>(
      '/conductor/$ruta/$id',
      data: ocurridoEn == null ? null : _hora(ocurridoEn),
      options: _conLlave(llave),
    );
    final datos = r.data;
    if (esServicio(datos)) return Servicio.fromJson(datos!);
    return _viajeTrasAccion(id);
  });

  Future<Servicio> _viajeTrasAccion(String id) async {
    final activo = await _dio.get<Object?>('/conductor/viaje-activo');
    final a = activo.data;
    if (activo.statusCode != 204 && a is _Json && a['id'] == id) {
      return Servicio.fromJson(a);
    }
    final r = await _dio.get<List<dynamic>>('/conductor/historial');
    final viaje = _lista(r.data).where((s) => s.id == id).firstOrNull;
    if (viaje != null) return viaje;
    throw const AppException(
      ErrorKind.noEncontrado,
      'No encontramos el viaje. Actualiza para verlo.',
    );
  }

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
  Future<Servicio> llegue(
    String id,
    Coordenada posicion, {
    String? llave,
    DateTime? ocurridoEn,
  }) => _guard(() async {
    final r = await _dio.post<_Json>(
      '/conductor/llegue/$id',
      data: {...posicion.toJson(), ...?_horaSiHay(ocurridoEn)},
      options: _conLlave(llave),
    );
    final datos = r.data;
    if (esServicio(datos)) return Servicio.fromJson(datos!);
    return _viajeTrasAccion(id);
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
  Future<Servicio> iniciar(String id, {String? llave, DateTime? ocurridoEn}) =>
      _accion(
        'iniciar-servicio',
        id,
        llave: llave,
        ocurridoEn: ocurridoEn,
      );
  @override
  Future<Servicio> finalizar(
    String id, {
    String? llave,
    DateTime? ocurridoEn,
  }) => _accion(
    'finalizar-servicio',
    id,
    llave: llave,
    ocurridoEn: ocurridoEn,
  );

  @override
  Future<void> reportarLote(List<PuntoGuardado> puntos) => _guard(() async {
    await _dio.post<Object?>(
      '/conductor/ubicacion/lote',
      data: {'puntos': [for (final p in puntos) p.toJson()]},
    );
  });

  static Options? _conLlave(String? llave) =>
      llave == null ? null : Options(headers: {'Idempotency-Key': llave});

  static Map<String, String> _hora(DateTime en) => {
    'ocurridoEn': en.toUtc().toIso8601String(),
  };

  static Map<String, String>? _horaSiHay(DateTime? en) =>
      en == null ? null : _hora(en);
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
