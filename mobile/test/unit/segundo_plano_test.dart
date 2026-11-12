import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/network/token_storage.dart';
import 'package:nexa_mobile/core/notificaciones/canales_notificacion.dart';
import 'package:nexa_mobile/core/notificaciones/notificaciones_locales.dart';
import 'package:nexa_mobile/core/permisos/permisos_dispositivo.dart';
import 'package:nexa_mobile/core/providers.dart';
import 'package:nexa_mobile/core/segundo_plano/modo_segundo_plano.dart';
import 'package:nexa_mobile/core/segundo_plano/rastreador_ubicacion.dart';
import 'package:nexa_mobile/features/auth/domain/auth.dart';
import 'package:nexa_mobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';
import 'package:nexa_mobile/features/viajes/presentation/controllers/segundo_plano_controller.dart';
import 'package:nexa_mobile/features/viajes/presentation/controllers/viaje_conductor_controller.dart';
import 'package:nexa_mobile/features/viajes/presentation/controllers/viaje_pasajero_controller.dart';

class _Sesion extends SesionController {
  _Sesion(this.rol);
  final Rol rol;
  @override
  SesionState build() => SesionState(
    sesion: Sesion(token: 't', rol: rol, email: 'a@nexa.co', userId: 'u'),
    inicializado: true,
  );
}

/// Conductor cuyo estado se cambia a mano en la prueba.
class _Conductor extends ConductorController {
  @override
  Future<ConductorState> build() async =>
      const ConductorState(aprobacion: EstadoAprobacion.aprobado);

  void poner(ConductorState s) => state = AsyncData(s);
}

class _Pasajero extends ViajePasajeroController {
  @override
  Future<Servicio?> build() async => null;

  void poner(Servicio? s) => state = AsyncData(s);
}

class _PrimerPlano extends PrimerPlano {
  @override
  bool build() => true;

  void poner(bool v) => state = v;
}

class _Avisos implements NotificacionesLocales {
  final List<String> mostrados = [];
  int cerrados = 0;
  @override
  bool get disponible => true;
  @override
  Future<void> inicializar(List<CanalNotificacion> canales) async {}
  @override
  Future<bool> permitidas() async => true;
  @override
  Future<bool> pedirPermiso() async => true;
  @override
  Future<void> mostrarViaje({
    required String titulo,
    required String texto,
    required String canal,
    required String abrir,
  }) async => mostrados.add('$titulo | $texto');
  @override
  Future<void> cerrarViaje() async => cerrados++;
}

const _viaje = Servicio(
  id: 'v1',
  estado: EstadoServicio.aceptado,
  origen: 'A',
  destino: 'B',
);

Future<void> _esperar() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  group('reglas', () {
    test('el modo sale del estado del viaje', () {
      expect(
        ReglasSegundoPlano.conductor(enLinea: false, conViaje: false),
        ModoSegundoPlano.apagado,
      );
      expect(
        ReglasSegundoPlano.conductor(enLinea: true, conViaje: false),
        ModoSegundoPlano.enLinea,
      );
      expect(
        ReglasSegundoPlano.conductor(enLinea: false, conViaje: true),
        ModoSegundoPlano.enViaje,
      );
      expect(
        ReglasSegundoPlano.pasajero(conductorEnCamino: true),
        ModoSegundoPlano.pasajeroEnCamino,
      );
      expect(
        ReglasSegundoPlano.pasajero(conductorEnCamino: false),
        ModoSegundoPlano.apagado,
      );
    });

    test('en línea mantiene la posición vigente para el servidor (45 s)', () {
      final enLinea = ReglasSegundoPlano.ajustes(ModoSegundoPlano.enLinea)!;
      expect(enLinea.intervalo.inSeconds, lessThan(45));
      expect(enLinea.altaPrecision, isFalse);
      final viaje = ReglasSegundoPlano.ajustes(ModoSegundoPlano.enViaje)!;
      expect(viaje.intervalo, const Duration(seconds: 3));
      expect(viaje.altaPrecision, isTrue);
      expect(ReglasSegundoPlano.ajustes(ModoSegundoPlano.apagado), isNull);
    });

    test('con la pantalla apagada y sin viaje reporta 1 de cada 3 ciclos', () {
      final reportados = [
        for (var c = 0; c < 6; c++)
          !ReglasSegundoPlano.saltarCiclo(
            primerPlano: false,
            conViaje: false,
            ciclo: c,
          ),
      ];
      expect(reportados, [true, false, false, true, false, false]);
      expect(
        ReglasSegundoPlano.saltarCiclo(
          primerPlano: false,
          conViaje: true,
          ciclo: 1,
        ),
        isFalse,
        reason: 'en viaje nunca se salta',
      );
    });

    test('en segundo plano solo se puede apagar', () {
      expect(
        ReglasSegundoPlano.puedeCambiar(
          actual: ModoSegundoPlano.enLinea,
          nuevo: ModoSegundoPlano.enViaje,
          primerPlano: false,
        ),
        isFalse,
      );
      expect(
        ReglasSegundoPlano.puedeCambiar(
          actual: ModoSegundoPlano.enViaje,
          nuevo: ModoSegundoPlano.apagado,
          primerPlano: false,
        ),
        isTrue,
      );
    });

    test('una posición sirve si tiene menos de 20 s', () {
      final ahora = DateTime(2026, 11, 12, 10);
      expect(
        ReglasSegundoPlano.vigente(
          ahora.subtract(const Duration(seconds: 10)),
          ahora,
        ),
        isTrue,
      );
      expect(
        ReglasSegundoPlano.vigente(
          ahora.subtract(const Duration(seconds: 30)),
          ahora,
        ),
        isFalse,
      );
      expect(ReglasSegundoPlano.vigente(null, ahora), isFalse);
    });
  });

  group('coordinador', () {
    late RastreadorEnMemoria rastreador;
    late PermisosFijos permisos;
    late _Avisos avisos;

    ProviderContainer crear(Rol rol) {
      rastreador = RastreadorEnMemoria();
      permisos = PermisosFijos(EstadoUbicacion.siempre);
      avisos = _Avisos();
      final c = ProviderContainer(
        overrides: [
          sesionProvider.overrideWith(() => _Sesion(rol)),
          secureStoreProvider.overrideWithValue(MemorySecureStore()),
          useMocksProvider.overrideWithValue(true),
          rastreadorProvider.overrideWithValue(rastreador),
          permisosProvider.overrideWithValue(permisos),
          notificacionesProvider.overrideWithValue(avisos),
          primerPlanoProvider.overrideWith(_PrimerPlano.new),
          conductorProvider.overrideWith(_Conductor.new),
          viajePasajeroProvider.overrideWith(_Pasajero.new),
        ],
      );
      addTearDown(c.dispose);
      c.listen(coordinadorSegundoPlanoProvider, (_, _) {});
      return c;
    }

    test('el conductor: en línea, viaje y fuera de línea', () async {
      final c = crear(Rol.conductor);
      await c.read(conductorProvider.future);
      final ctrl = c.read(conductorProvider.notifier) as _Conductor;

      ctrl.poner(
        const ConductorState(
          aprobacion: EstadoAprobacion.aprobado,
          enLinea: true,
        ),
      );
      await _esperar();
      expect(c.read(coordinadorSegundoPlanoProvider), ModoSegundoPlano.enLinea);

      ctrl.poner(
        const ConductorState(
          aprobacion: EstadoAprobacion.aprobado,
          enLinea: true,
          activo: _viaje,
        ),
      );
      await _esperar();
      expect(rastreador.iniciados, [
        ModoSegundoPlano.enLinea,
        ModoSegundoPlano.enViaje,
      ]);

      ctrl.poner(const ConductorState(aprobacion: EstadoAprobacion.aprobado));
      await _esperar();
      expect(rastreador.activo, ModoSegundoPlano.apagado);
      expect(c.read(coordinadorSegundoPlanoProvider), ModoSegundoPlano.apagado);
    });

    test('la notificación fija muestra el viaje con los datos del servidor', () async {
      final c = crear(Rol.conductor);
      await c.read(conductorProvider.future);
      final ctrl = c.read(conductorProvider.notifier) as _Conductor;
      const conPasajero = Servicio(
        id: 'v1',
        estado: EstadoServicio.aceptado,
        pasajero: Participante(nombre: 'Laura Díaz'),
        origen: 'Cl 45',
        destino: 'Centro',
      );
      const posicion = PosicionViaje(
        fase: 'A_RECOGER',
        latitud: 10.4,
        longitud: -75.5,
        distanciaRestanteKm: 0.648,
        etaMinutos: 3,
      );
      ctrl.poner(
        const ConductorState(
          aprobacion: EstadoAprobacion.aprobado,
          activo: conPasajero,
          posicion: posicion,
        ),
      );
      await _esperar();
      expect(avisos.mostrados, ['Recoge a Laura | 3 min · 650 m']);

      // El mismo texto no se vuelve a publicar en cada sondeo.
      ctrl.poner(
        const ConductorState(
          aprobacion: EstadoAprobacion.aprobado,
          activo: conPasajero,
          posicion: posicion,
        ),
      );
      await _esperar();
      expect(avisos.mostrados, hasLength(1));

      ctrl.poner(const ConductorState(aprobacion: EstadoAprobacion.aprobado));
      await _esperar();
      expect(avisos.cerrados, 1);
    });

    test('sin permiso de ubicación no prende nada', () async {
      final c = crear(Rol.conductor);
      permisos.estado = EstadoUbicacion.sinPermiso;
      await c.read(conductorProvider.future);
      (c.read(conductorProvider.notifier) as _Conductor).poner(
        const ConductorState(
          aprobacion: EstadoAprobacion.aprobado,
          enLinea: true,
        ),
      );
      await _esperar();
      expect(rastreador.iniciados, isEmpty);
    });

    test('con la app oculta espera a volver para cambiar de modo', () async {
      final c = crear(Rol.conductor);
      await c.read(conductorProvider.future);
      final ctrl = c.read(conductorProvider.notifier) as _Conductor;
      final plano = c.read(primerPlanoProvider.notifier) as _PrimerPlano;
      ctrl.poner(
        const ConductorState(
          aprobacion: EstadoAprobacion.aprobado,
          enLinea: true,
        ),
      );
      await _esperar();

      plano.poner(false);
      ctrl.poner(
        const ConductorState(
          aprobacion: EstadoAprobacion.aprobado,
          enLinea: true,
          activo: _viaje,
        ),
      );
      await _esperar();
      expect(rastreador.activo, ModoSegundoPlano.enLinea);

      plano.poner(true);
      await _esperar();
      expect(rastreador.activo, ModoSegundoPlano.enViaje);
    });

    test('el pasajero solo mientras el conductor va en camino', () async {
      final c = crear(Rol.pasajero);
      await c.read(viajePasajeroProvider.future);
      final ctrl = c.read(viajePasajeroProvider.notifier) as _Pasajero;

      ctrl.poner(_viaje.copyWith(estado: EstadoServicio.solicitado));
      await _esperar();
      expect(rastreador.iniciados, isEmpty);

      ctrl.poner(_viaje);
      await _esperar();
      expect(rastreador.activo, ModoSegundoPlano.pasajeroEnCamino);

      ctrl.poner(_viaje.copyWith(estado: EstadoServicio.enCurso));
      await _esperar();
      expect(rastreador.activo, ModoSegundoPlano.apagado);
    });

    test('al cerrar sesión se apaga', () async {
      final c = crear(Rol.conductor);
      await c.read(conductorProvider.future);
      (c.read(conductorProvider.notifier) as _Conductor).poner(
        const ConductorState(
          aprobacion: EstadoAprobacion.aprobado,
          enLinea: true,
        ),
      );
      await _esperar();
      c.invalidate(coordinadorSegundoPlanoProvider);
      await _esperar();
      expect(rastreador.detenidos, greaterThan(0));
    });
  });
}
