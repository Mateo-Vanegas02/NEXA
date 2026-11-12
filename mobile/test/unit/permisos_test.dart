import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/network/token_storage.dart';
import 'package:nexa_mobile/core/notificaciones/canales_notificacion.dart';
import 'package:nexa_mobile/core/notificaciones/notificaciones_locales.dart';
import 'package:nexa_mobile/core/permisos/guia_permisos.dart';
import 'package:nexa_mobile/core/permisos/permisos_dispositivo.dart';
import 'package:nexa_mobile/features/auth/domain/auth.dart';

class _Notificaciones implements NotificacionesLocales {
  @override
  final bool disponible = true;
  bool concedidas = false;
  @override
  Future<void> inicializar(List<CanalNotificacion> canales) async {}
  @override
  Future<bool> permitidas() async => concedidas;
  @override
  Future<bool> pedirPermiso() async => concedidas = true;
}

EstadoPermisos _estado({
  bool disponibles = true,
  bool permitidas = false,
  EstadoUbicacion? ubicacion = EstadoUbicacion.sinPermiso,
  Set<PasoPermiso> vistos = const {},
}) => EstadoPermisos(
  notificacionesDisponibles: disponibles,
  notificacionesPermitidas: permitidas,
  ubicacion: ubicacion,
  vistos: vistos,
);

void main() {
  group('al entrar', () {
    test('primero las notificaciones, una sola vez', () {
      expect(
        ReglasPermisos.alEntrar(Rol.pasajero, _estado()),
        PasoPermiso.notificaciones,
      );
      expect(
        ReglasPermisos.alEntrar(
          Rol.pasajero,
          _estado(vistos: {PasoPermiso.notificaciones}),
        ),
        PasoPermiso.ubicacion,
        reason: 'después, la ubicación del pasajero',
      );
    });

    test('al conductor no se le pide la ubicación hasta que se conecta', () {
      expect(
        ReglasPermisos.alEntrar(
          Rol.conductor,
          _estado(vistos: {PasoPermiso.notificaciones}),
        ),
        isNull,
      );
    });

    test('no repite lo ya concedido ni lo ya visto', () {
      expect(
        ReglasPermisos.alEntrar(
          Rol.pasajero,
          _estado(permitidas: true, ubicacion: EstadoUbicacion.alUsar),
        ),
        isNull,
      );
      expect(
        ReglasPermisos.alEntrar(
          Rol.pasajero,
          _estado(vistos: {PasoPermiso.notificaciones, PasoPermiso.ubicacion}),
        ),
        isNull,
      );
    });

    test('sin notificaciones en el teléfono ni estado de ubicación, nada', () {
      expect(
        ReglasPermisos.alEntrar(
          Rol.pasajero,
          _estado(disponibles: false, ubicacion: null),
        ),
        isNull,
      );
    });
  });

  group('al usar la ubicación', () {
    test('pide la pantalla que toca según el permiso', () {
      expect(
        ReglasPermisos.paraUsarUbicacion(EstadoUbicacion.sinPermiso),
        PasoPermiso.ubicacion,
      );
      expect(
        ReglasPermisos.paraUsarUbicacion(EstadoUbicacion.denegadaSiempre),
        PasoPermiso.sinUbicacion,
      );
      expect(ReglasPermisos.paraUsarUbicacion(EstadoUbicacion.alUsar), isNull);
      expect(ReglasPermisos.paraUsarUbicacion(EstadoUbicacion.siempre), isNull);
      expect(ReglasPermisos.paraUsarUbicacion(null), isNull);
    });

    test('el segundo plano se explica solo la primera vez y con «al usar»', () {
      expect(
        ReglasPermisos.segundoPlano(_estado(ubicacion: EstadoUbicacion.alUsar)),
        PasoPermiso.segundoPlano,
      );
      expect(
        ReglasPermisos.segundoPlano(
          _estado(
            ubicacion: EstadoUbicacion.alUsar,
            vistos: {PasoPermiso.segundoPlano},
          ),
        ),
        isNull,
      );
      expect(
        ReglasPermisos.segundoPlano(
          _estado(ubicacion: EstadoUbicacion.siempre),
        ),
        isNull,
      );
    });
  });

  test('la guía recuerda lo visto y lee el teléfono', () async {
    final store = MemorySecureStore();
    final guia = GuiaPermisos(
      permisos: PermisosFijos(EstadoUbicacion.alUsar),
      notificaciones: _Notificaciones(),
      store: store,
    );
    var e = await guia.estado();
    expect(e.ubicacion, EstadoUbicacion.alUsar);
    expect(e.vistos, isEmpty);

    await guia.marcarVisto(PasoPermiso.notificaciones);
    e = await guia.estado();
    expect(e.vistos, {PasoPermiso.notificaciones});
  });

  test('si el plugin falla, la ubicación queda desconocida', () async {
    final guia = GuiaPermisos(
      permisos: _PermisosRotos(),
      notificaciones: const NotificacionesInactivas(),
      store: MemorySecureStore(),
    );
    final e = await guia.estado();
    expect(e.ubicacion, isNull);
    expect(e.notificacionesDisponibles, isFalse);
  });
}

class _PermisosRotos extends PermisosFijos {
  _PermisosRotos() : super(EstadoUbicacion.sinPermiso);
  @override
  Future<EstadoUbicacion> ubicacion() => throw Exception('sin plugin');
}
