import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/admin.dart';

typedef _Json = Map<String, dynamic>;

/// Contra el backend Java (`/api/admin/**`, solo ROLE_ADMIN).
class ApiAdminRepository implements AdminRepository {
  ApiAdminRepository(this._dio);
  final Dio _dio;

  Future<T> _guard<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<OperacionAdmin> operacion() => _guard(() async {
    final r = await _dio.get<_Json>('/admin/operacion');
    return OperacionAdmin.fromJson(r.data ?? const {});
  });

  @override
  Future<List<ConductorRevision>> conductores(EstadoRevision estado) =>
      _guard(() async {
        final r = await _dio.get<List<dynamic>>(
          '/admin/conductores',
          queryParameters: {'estado': estado.api},
        );
        return [
          for (final e in r.data ?? const [])
            ConductorRevision.fromJson(e as _Json),
        ];
      });

  @override
  Future<ExpedienteConductor> expediente(String email) => _guard(() async {
    final q = {'email': email};
    final docs = _dio.get<List<dynamic>>(
      '/admin/verificacion/documentos',
      queryParameters: q,
    );
    final motos = _dio.get<List<dynamic>>(
      '/admin/verificacion/vehiculos',
      queryParameters: q,
    );
    final estado = _dio.get<_Json>(
      '/admin/verificacion/estado',
      queryParameters: q,
    );
    final ultima = (await estado).data?['ultimaVerificacion'] as _Json?;
    return ExpedienteConductor(
      documentos: [
        for (final e in (await docs).data ?? const [])
          DocumentoRevision.fromJson(e as _Json),
      ],
      vehiculos: [
        for (final e in (await motos).data ?? const [])
          VehiculoRevision.fromJson(e as _Json),
      ],
      verificado: ultima?['resultado'] == 'VERIFIED',
    );
  });

  @override
  Future<Uint8List> archivo(String documentoId) => _guard(() async {
    final r = await _dio.get<List<int>>(
      '/admin/verificacion/documentos/$documentoId/archivo',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(r.data ?? const []);
  });

  @override
  Future<void> decidir(
    String email, {
    required bool aprobar,
    required String motivo,
    bool marcarVerificado = false,
  }) => _guard(() async {
    // El servidor solo aprueba con una verificación VERIFIED: la del admin
    // que revisó los documentos queda en la auditoría como manual.
    if (aprobar && marcarVerificado) {
      await _dio.post<_Json>(
        '/admin/verificacion/manual',
        data: {'email': email, 'resultado': 'VERIFIED', 'nota': motivo},
      );
    }
    await _dio.post<_Json>(
      '/admin/verificacion/decision',
      data: {'email': email, 'aprobar': aprobar, 'motivo': motivo},
    );
  });

  @override
  Future<void> pedirInformacion(String email, String mensaje) =>
      _guard(() async {
        await _dio.post<_Json>(
          '/admin/verificacion/solicitar-info',
          data: {'email': email, 'mensaje': mensaje},
        );
      });
}

/// Modo demostración y pruebas.
class MockAdminRepository implements AdminRepository {
  MockAdminRepository();

  final _pendientes = <ConductorRevision>[
    ConductorRevision(
      email: 'andres@nexa.co',
      nombre: 'Andrés Quintero',
      telefono: '3001234567',
      fechaRegistro: DateTime(2026, 11, 20, 9, 30),
      estado: EstadoRevision.pendiente,
    ),
    ConductorRevision(
      email: 'luisa@nexa.co',
      nombre: 'Luisa Márquez',
      telefono: '3109876543',
      fechaRegistro: DateTime(2026, 11, 21, 16, 5),
      estado: EstadoRevision.pendiente,
    ),
  ];

  @override
  Future<OperacionAdmin> operacion() async => OperacionAdmin(
    viajesHoy: 46,
    finalizadosHoy: 38,
    canceladosHoy: 3,
    enCurso: 4,
    yendoARecoger: 2,
    solicitudesAbiertas: 1,
    conductoresEnLinea: 12,
    conductoresDisponibles: 6,
    conductoresPendientes: _pendientes.length,
    flota: const [
      PosicionFlota(latitud: 10.4236, longitud: -75.5253),
      PosicionFlota(latitud: 10.4180, longitud: -75.5400, disponible: false),
      PosicionFlota(latitud: 10.4010, longitud: -75.5120),
      PosicionFlota(latitud: 10.3990, longitud: -75.5520, disponible: false),
      PosicionFlota(latitud: 10.4320, longitud: -75.5370),
    ],
    alertas: [
      const AlertaAdmin(
        tipo: TipoAlerta.solicitudSinConductor,
        texto: 'Solicitud desde Bocagrande sin conductor hace 6 min',
        servicioId: 's9',
        minutos: 6,
      ),
      if (_pendientes.isNotEmpty)
        AlertaAdmin(
          tipo: TipoAlerta.conductoresPorAprobar,
          texto: '${_pendientes.length} conductores esperan aprobación',
        ),
    ],
  );

  @override
  Future<List<ConductorRevision>> conductores(EstadoRevision estado) async =>
      estado == EstadoRevision.pendiente ? List.of(_pendientes) : const [];

  @override
  Future<ExpedienteConductor> expediente(String email) async =>
      ExpedienteConductor(
        documentos: [
          for (final (i, t) in const [
            'LICENCIA',
            'TARJETA_PROPIEDAD',
            'SOAT',
            'TECNOMECANICA',
          ].indexed)
            DocumentoRevision(
              id: 'd$i',
              tipo: t,
              numeroDeclarado: '10${i}2345678',
              contentType: 'image/jpeg',
            ),
        ],
        vehiculos: const [
          VehiculoRevision(
            id: 'v1',
            placa: 'DTE54H',
            marca: 'Honda',
            modelo: 'CB 190',
            color: 'Azul',
          ),
        ],
      );

  @override
  Future<Uint8List> archivo(String documentoId) async => Uint8List(0);

  @override
  Future<void> decidir(
    String email, {
    required bool aprobar,
    required String motivo,
    bool marcarVerificado = false,
  }) async => _pendientes.removeWhere((c) => c.email == email);

  @override
  Future<void> pedirInformacion(String email, String mensaje) async =>
      _pendientes.removeWhere((c) => c.email == email);
}
