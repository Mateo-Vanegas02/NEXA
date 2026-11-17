import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/providers.dart';
import 'package:nexa_mobile/core/push/aviso_push.dart';
import 'package:nexa_mobile/core/push/eventos_vistos.dart';
import 'package:nexa_mobile/core/network/token_storage.dart';
import 'package:nexa_mobile/core/push/dispositivos_repository.dart';
import 'package:nexa_mobile/core/push/servicio_push.dart';
import 'package:nexa_mobile/features/auth/domain/auth.dart';
import 'package:nexa_mobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:nexa_mobile/features/viajes/presentation/controllers/avisos_push_controller.dart';

import '../helpers.dart';

Future<void> _esperar() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('AvisoPush', () {
    test('lee los datos del servidor', () {
      final a = AvisoPush.desdeDatos({
        'eventoId': 'e1',
        'tipo': 'SOLICITUD_NUEVA',
        'servicioId': 's1',
        'titulo': 'Nueva solicitud · Ganas \$6.964',
        'cuerpo': 'A 700 m',
        'canal': 'nexa_solicitudes',
      });
      expect(a.tipo, TipoAviso.solicitudNueva);
      expect(a.esSolicitud, isTrue);
      expect(a.servicioId, 's1');
      expect(a.datos['titulo'], 'Nueva solicitud · Ganas \$6.964');
    });

    test('un tipo desconocido no rompe y sin eventoId se arma uno', () {
      final a = AvisoPush.desdeDatos({'tipo': 'NUEVO_TIPO', 'servicioId': 'x'});
      expect(a.tipo, TipoAviso.otro);
      expect(a.eventoId, isNotEmpty);
      expect(a.datos.containsKey('titulo'), isFalse);
    });

    test('el id de la notificación es estable por solicitud', () {
      AvisoPush de(String tipo, String evento) => AvisoPush.desdeDatos({
        'tipo': tipo,
        'eventoId': evento,
        'servicioId': 'abc123',
      });
      final nueva = de('SOLICITUD_NUEVA', 'e1');
      expect(de('SOLICITUD_EXTRA', 'e2').idNotificacion, nueva.idNotificacion);
      expect(
        de('SOLICITUD_RETIRADA', 'e3').idNotificacion,
        nueva.idNotificacion,
      );
      expect(nueva.idNotificacion, AvisoPush.idPara('abc123'));
      expect(nueva.idNotificacion, isNot(75415));
      expect(nueva.idNotificacion, greaterThanOrEqualTo(0));
    });

    test('ida y vuelta por el payload de la notificación local', () {
      final a = AvisoPush.desdeDatos({
        'tipo': 'SOLICITUD_EXTRA',
        'eventoId': 'e9',
        'servicioId': 's9',
      });
      final b = AvisoPush.desdeDatos(a.datos, accion: AccionAviso.aceptar);
      expect(b.tipo, a.tipo);
      expect(b.eventoId, a.eventoId);
      expect(b.accion, AccionAviso.aceptar);
    });

    test('cada aviso abre la pantalla de su rol', () {
      AvisoPush de(String tipo) => AvisoPush.desdeDatos({'tipo': tipo});
      expect(de('VIAJE_ACEPTADO').rutaAlTocar(Rol.pasajero), '/p/viaje');
      expect(de('CONDUCTOR_LLEGO').rutaAlTocar(Rol.pasajero), '/p/viaje');
      expect(de('VIAJE_FINALIZADO').rutaAlTocar(Rol.pasajero), '/p/viaje');
      expect(de('SIN_CONDUCTORES').rutaAlTocar(Rol.pasajero), '/p/viaje');
      expect(de('VIAJE_CANCELADO').rutaAlTocar(Rol.pasajero), '/p/inicio');
      expect(de('SOLICITUD_NUEVA').rutaAlTocar(Rol.conductor), '/c/inicio');
      expect(de('VIAJE_CANCELADO').rutaAlTocar(Rol.conductor), '/c/inicio');
    });

    test('aviso fuera de orden o de viaje ya cerrado no reabre pantallas', () {
      final aceptado = AvisoPush.desdeDatos({
        'tipo': 'VIAJE_ACEPTADO',
        'eventoId': 's1:aceptado',
        'servicioId': 's1',
      });
      final finalizado = AvisoPush.desdeDatos({
        'tipo': 'VIAJE_FINALIZADO',
        'eventoId': 's1:finalizado',
        'servicioId': 's1',
      });
      expect(aceptado.rutaConViajeVigente(Rol.pasajero, 's2'), '/p/inicio');
      expect(finalizado.rutaConViajeVigente(Rol.pasajero, null), '/p/inicio');
      expect(aceptado.rutaConViajeVigente(Rol.pasajero, 's1'), '/p/viaje');
    });

    test('ignora repetidos tras reiniciar y vence a las 48 horas', () async {
      final store = MemorySecureStore();
      var ahora = DateTime(2026, 11, 17);
      EventosVistos crear() => EventosVistos(store, reloj: () => ahora);
      expect(await crear().reservar('recibido:a'), isTrue);
      expect(await crear().reservar('recibido:a'), isFalse);
      // Recibir y tocar son acciones distintas.
      expect(await crear().reservar('tocado:a'), isTrue);
      expect(await crear().reservar('tocado:a'), isFalse);
      ahora = ahora.add(const Duration(hours: 49));
      expect(await crear().reservar('recibido:a'), isTrue);
    });
  });

  group('AvisosPushController', () {
    late PushEnMemoria push;
    late DispositivosEnMemoria dispositivos;
    late ProviderContainer c;

    setUp(() {
      push = PushEnMemoria();
      dispositivos = DispositivosEnMemoria();
      c = ProviderContainer(
        overrides: [
          ...overridesTest(),
          servicioPushProvider.overrideWithValue(push),
          dispositivosRepositoryProvider.overrideWithValue(dispositivos),
        ],
      );
      addTearDown(c.dispose);
      c.listen(avisosPushProvider, (_, _) {});
    });

    test(
      'registra el teléfono al iniciar sesión y al rotar el token',
      () async {
        await c.read(sesionProvider.notifier).iniciar();
        await _esperar();
        expect(dispositivos.tokens, isEmpty);
        await c.read(sesionProvider.notifier).login('ana@x.co', '123456');
        await _esperar();
        expect(dispositivos.tokens, {'token-prueba'});
        push.renovarToken('token-2');
        await _esperar();
        expect(dispositivos.tokens, contains('token-2'));
      },
    );

    test('quita el teléfono antes de cerrar sesión', () async {
      await c.read(sesionProvider.notifier).iniciar();
      await c.read(sesionProvider.notifier).login('ana@x.co', '123456');
      await _esperar();
      await c.read(sesionProvider.notifier).logout();
      expect(dispositivos.tokens, isEmpty);
      expect(c.read(sesionProvider).autenticado, isFalse);
    });

    test('una solicitud retirada quita su notificación una sola vez', () async {
      await c.read(sesionProvider.notifier).iniciar();
      await c.read(sesionProvider.notifier).login('ana@x.co', '123456');
      await _esperar();
      final retiro = AvisoPush.desdeDatos({
        'tipo': 'SOLICITUD_RETIRADA',
        'eventoId': 'r1',
        'servicioId': 's1',
      });
      push
        ..recibir(retiro)
        ..recibir(retiro);
      await _esperar();
      expect(push.quitadas, [AvisoPush.idPara('s1')]);
    });
  });

  test('sin Firebase el controlador no hace nada', () async {
    final c = ProviderContainer(overrides: overridesTest());
    addTearDown(c.dispose);
    expect(c.read(avisosPushProvider), isNull);
    await c.read(sesionProvider.notifier).iniciar();
    await c.read(sesionProvider.notifier).login('ana@x.co', '123456');
    await c.read(sesionProvider.notifier).logout();
    expect(c.read(sesionProvider).autenticado, isFalse);
  });
}
