import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexa_mobile/core/providers.dart';
import 'package:nexa_mobile/core/router/app_router.dart';
import 'package:nexa_mobile/features/auth/domain/auth.dart';
import 'package:nexa_mobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:nexa_mobile/features/niveles/presentation/controllers/niveles_controller.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';
import 'package:nexa_mobile/features/viajes/presentation/controllers/viaje_conductor_controller.dart';
import 'package:nexa_mobile/features/viajes/presentation/controllers/viaje_pasajero_controller.dart';

import '../helpers.dart';

ProviderContainer _contenedor() {
  final c = ProviderContainer(overrides: overridesTest());
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('SesionController', () {
    test('inicia sin sesión, hace login y logout', () async {
      final c = _contenedor();
      await c.read(sesionProvider.notifier).iniciar();
      expect(c.read(sesionProvider).inicializado, isTrue);
      expect(c.read(sesionProvider).autenticado, isFalse);
      await c.read(sesionProvider.notifier).login('ana@x.co', '123456');
      expect(c.read(sesionProvider).sesion?.rol, Rol.pasajero);
      await c.read(sesionProvider.notifier).logout();
      expect(c.read(sesionProvider).autenticado, isFalse);
    });

    test('el splash se muestra al menos el tiempo mínimo', () async {
      final c = ProviderContainer(
        overrides: overridesTest(splash: const Duration(milliseconds: 300)),
      );
      addTearDown(c.dispose);
      final inicio = DateTime.now();
      final f = c.read(sesionProvider.notifier).iniciar();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(c.read(sesionProvider).inicializado, isFalse);
      await f;
      expect(c.read(sesionProvider).inicializado, isTrue);
      expect(
        DateTime.now().difference(inicio).inMilliseconds,
        greaterThanOrEqualTo(290),
      );
    });

    test('el onboarding queda marcado como visto', () async {
      final c = _contenedor();
      await c.read(sesionProvider.notifier).iniciar();
      expect(c.read(sesionProvider).onboardingVisto, isFalse);
      await c.read(sesionProvider.notifier).completarOnboarding();
      expect(c.read(sesionProvider).onboardingVisto, isTrue);
    });
  });

  group('redirigir (guards por rol)', () {
    const pasajero = Sesion(token: 't', rol: Rol.pasajero, email: 'a');
    const conductor = Sesion(token: 't', rol: Rol.conductor, email: 'a');

    test('antes de inicializar todo va al splash', () {
      expect(redirigir(const SesionState(), '/login'), '/splash');
      expect(redirigir(const SesionState(), '/splash'), isNull);
    });

    test('sin sesión: onboarding la primera vez y luego la home pública', () {
      const nuevo = SesionState(inicializado: true);
      expect(redirigir(nuevo, '/splash'), '/onboarding');
      const visto = SesionState(inicializado: true, onboardingVisto: true);
      expect(redirigir(visto, '/splash'), '/inicio');
      expect(redirigir(visto, '/p/inicio'), '/inicio');
      expect(redirigir(visto, '/registro'), isNull);
    });

    test('con sesión: cada rol solo ve lo suyo', () {
      const p = SesionState(sesion: pasajero, inicializado: true);
      const c = SesionState(sesion: conductor, inicializado: true);
      expect(redirigir(p, '/login'), '/p/inicio');
      expect(redirigir(p, '/c/inicio'), '/p/inicio');
      expect(redirigir(p, '/p/niveles'), isNull);
      expect(redirigir(c, '/splash'), '/c/inicio');
      expect(redirigir(c, '/p/viaje'), '/c/inicio');
      expect(redirigir(c, '/c/ganancias'), isNull);
    });
  });

  group('NivelController', () {
    test('emite "+N XP" y la subida de nivel una sola vez', () async {
      final c = _contenedor();
      await c.read(sesionProvider.notifier).login('ana@x.co', '123456');
      await c.read(nivelProvider.future);
      final backend = c.read(mockBackendProvider);

      // Sin cambio de nivel: solo XP.
      backend.xpPasajero = 50;
      await c.read(nivelProvider.notifier).viajeCompletado(20);
      var ev = c.read(celebracionProvider);
      expect(ev?.xp, 20);
      expect(ev?.nivelNuevo, isNull);
      c.read(celebracionProvider.notifier).consumir();

      // Cruza 270 XP: sube al nivel 2 (modelo v2.3).
      backend.xpPasajero = 290;
      await c.read(nivelProvider.notifier).viajeCompletado(20);
      ev = c.read(celebracionProvider);
      expect(ev?.nivelNuevo?.nombre, '2');
      c.read(celebracionProvider.notifier).consumir();

      // Mismo nivel otra vez: no repite la animación.
      await c.read(nivelProvider.notifier).viajeCompletado(10);
      ev = c.read(celebracionProvider);
      expect(ev?.nivelNuevo, isNull);
    });
  });

  group('Viaje del pasajero', () {
    test('solicitar y cancelar', () async {
      final c = _contenedor();
      await c.read(sesionProvider.notifier).login('ana@x.co', '123456');
      expect(await c.read(viajePasajeroProvider.future), isNull);
      await c
          .read(viajePasajeroProvider.notifier)
          .solicitar(
            const SolicitudViaje(
              origen: 'A',
              destino: 'B',
              ubicacionOrigen: Coordenada(latitud: 10.4, longitud: -75.5),
              ubicacionDestino: Coordenada(latitud: 10.41, longitud: -75.51),
            ),
          );
      expect(
        c.read(viajePasajeroProvider).value?.estado,
        EstadoServicio.solicitado,
      );
      await c.read(viajePasajeroProvider.notifier).cancelar();
      expect(c.read(viajePasajeroProvider).value, isNull);
    });
  });

  group('ConductorController', () {
    test('conductor pendiente queda bloqueado', () async {
      final c = _contenedor();
      await c.read(sesionProvider.notifier).login('pendiente@x.co', '123456');
      final s = await c.read(conductorProvider.future);
      expect(s.aprobacion, EstadoAprobacion.pendiente);
    });

    test('en línea recibe solicitudes, acepta y completa el viaje', () async {
      final c = ProviderContainer(
        overrides: overridesTest(
          miPosicion: () async => const LatLng(10.4, -75.5),
        ),
      );
      addTearDown(c.dispose);
      await c.read(sesionProvider.notifier).login('conductor@x.co', '123456');
      await c.read(conductorProvider.future);
      final ctrl = c.read(conductorProvider.notifier);
      await ctrl.alternarLinea();
      var s = c.read(conductorProvider).requireValue;
      expect(s.enLinea, isTrue);
      expect(s.solicitudes, isNotEmpty);

      ctrl.rechazar(s.solicitudes.first);
      s = c.read(conductorProvider).requireValue;
      expect(s.solicitudes, hasLength(1));

      await ctrl.aceptar(s.solicitudes.first);
      expect(
        c.read(conductorProvider).requireValue.activo?.estado,
        EstadoServicio.aceptado,
      );
      expect(
        c.read(conductorProvider).requireValue.fase,
        FaseConductor.aRecoger,
      );
      await ctrl.avanzar(); // «Llegué»
      expect(
        c.read(conductorProvider).requireValue.fase,
        FaseConductor.enElPunto,
      );
      await ctrl.avanzar(); // iniciar
      expect(
        c.read(conductorProvider).requireValue.activo?.estado,
        EstadoServicio.enCurso,
      );
      await ctrl.avanzar(); // finalizar
      expect(c.read(conductorProvider).requireValue.activo, isNull);
      expect(c.read(conductorProvider).requireValue.terminado, isNotNull);
      expect(c.read(celebracionProvider)?.xp, greaterThan(0));
      await ctrl.alternarLinea(); // detiene el polling
    });
  });
}
