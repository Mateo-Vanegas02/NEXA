import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexa_mobile/core/errors/app_exception.dart';
import 'package:nexa_mobile/core/network/api_client.dart';
import 'package:nexa_mobile/core/network/token_storage.dart';
import 'package:nexa_mobile/core/providers.dart';
import 'package:nexa_mobile/core/sin_conexion/almacen_sin_conexion.dart';
import 'package:nexa_mobile/core/sin_conexion/reglas_sin_conexion.dart';
import 'package:nexa_mobile/features/viajes/presentation/controllers/sin_conexion_controller.dart';
import 'package:nexa_mobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:nexa_mobile/features/viajes/data/viajes_repository_impl.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';
import 'package:nexa_mobile/features/viajes/domain/viajes_repository.dart';
import 'package:nexa_mobile/features/viajes/presentation/controllers/viaje_conductor_controller.dart';

import '../helpers.dart';

const _o = Coordenada(latitud: 10.40, longitud: -75.50);
const _d = Coordenada(latitud: 10.42, longitud: -75.52);

/// Lado del conductor contra el backend real (HTTP simulado).
void main() {
  late TokenStorage tokens;

  ApiConductorRepository repo(FakeAdapter a) => ApiConductorRepository(
    crearDio(tokens: tokens, baseUrl: 'http://test', onSesionExpirada: () {})
      ..httpClientAdapter = a,
  );

  setUp(() => tokens = TokenStorage(MemorySecureStore()));

  group('ApiConductorRepository', () {
    test(
      'reportar posición envía disponible y lee la fase del servidor',
      () async {
        final a = FakeAdapter({
          'POST /api/conductor/ubicacion': (
            200,
            {
              'servicioId': 's1',
              'fase': 'EN_CURSO',
              'latitud': 10.41,
              'longitud': -75.51,
              'distanciaRestanteKm': 2.5,
              'etaMinutos': 7,
              'en': 1,
            },
          ),
        });
        final p = await repo(a).reportarUbicacion(_o, disponible: false);
        expect(p?.fase, 'EN_CURSO');
        expect(p?.etaMinutos, 7);
        expect(a.llamadas.single.data, {
          'latitud': 10.40,
          'longitud': -75.50,
          'disponible': false,
        });
      },
    );

    test('sin viaje que seguir (204) devuelve null', () async {
      final p = await repo(
        FakeAdapter({'POST /api/conductor/ubicacion': (204, null)}),
      ).reportarUbicacion(_o, disponible: true);
      expect(p, isNull);
    });

    test('viaje-activo retoma el viaje o devuelve null en 204', () async {
      final con = await repo(
        FakeAdapter({
          'GET /api/conductor/viaje-activo': (
            200,
            {'id': 's1', 'estado': 'ACEPTADO', 'tarifa': 9000},
          ),
        }),
      ).viajeActivo();
      expect(con?.estado, EstadoServicio.aceptado);
      final sin = await repo(
        FakeAdapter({'GET /api/conductor/viaje-activo': (204, null)}),
      ).viajeActivo();
      expect(sin, isNull);
    });

    test('la posición del pasajero trae la distancia a la recogida', () async {
      final p = await repo(
        FakeAdapter({
          'GET /api/conductor/pasajero-ubicacion/s1': (
            200,
            {
              'latitud': 10.40,
              'longitud': -75.50,
              'haceSegundos': 3,
              'distanciaRecogidaMetros': 120,
            },
          ),
        }),
      ).ubicacionPasajero('s1');
      expect(p?.distanciaRecogidaMetros, 120);
    });

    test('«Llegué» envía la posición y el servidor la verifica (409 si está lejos)', () async {
      final a = FakeAdapter({
        'POST /api/conductor/llegue/s1': (
          409,
          {'error': 'Aún estás a 300 m del punto de recogida'},
        ),
      });
      await expectLater(
        repo(a).llegue('s1', _o),
        throwsA(
          isA<AppException>()
              .having((e) => e.statusCode, 'status', 409)
              .having((e) => e.mensaje, 'mensaje', contains('300 m')),
        ),
      );
      expect(a.llamadas.single.data, {'latitud': 10.40, 'longitud': -75.50});
    });

    test('aceptar una solicitud que otro ya tomó devuelve 409', () async {
      await expectLater(
        repo(
          FakeAdapter({
            'POST /api/conductor/aceptar-servicio/s1': (
              409,
              {'error': 'La solicitud ya fue tomada por otro conductor'},
            ),
          }),
        ).aceptar('s1'),
        throwsA(isA<AppException>().having((e) => e.statusCode, 's', 409)),
      );
    });

    test('aceptar lee la respuesta real {mensaje, servicioId}', () async {
      final s = await repo(
        FakeAdapter({
          'POST /api/conductor/aceptar-servicio/s1': (
            200,
            {'mensaje': 'Servicio aceptado con éxito', 'servicioId': 's1'},
          ),
          'GET /api/conductor/viaje-activo': (
            200,
            {'id': 's1', 'estado': 'ACEPTADO', 'origen': 'A', 'destino': 'B'},
          ),
        }),
      ).aceptar('s1');
      expect(s.id, 's1');
      expect(s.estado, EstadoServicio.aceptado);
    });

    test(
      'al finalizar el viaje ya no está activo: se toma del historial',
      () async {
        final s = await repo(
          FakeAdapter({
            'POST /api/conductor/finalizar-servicio/s1': (
              200,
              {'mensaje': 'Servicio finalizado con éxito.', 'servicioId': 's1'},
            ),
            'GET /api/conductor/viaje-activo': (204, null),
            'GET /api/conductor/historial': (
              200,
              [
                {'id': 's0', 'estado': 'FINALIZADO'},
                {'id': 's1', 'estado': 'FINALIZADO', 'tarifa': 7000},
              ],
            ),
          }),
        ).finalizar('s1');
        expect(s.estado, EstadoServicio.finalizado);
        expect(s.tarifa, 7000);
      },
    );

    test('el saldo es la vista del conductor, sin comisión', () async {
      final s = await repo(
        FakeAdapter({
          'GET /api/conductor/saldo': (
            200,
            {
              'dias': 30,
              'viajes': 12,
              'cobradoEfectivo': 240000,
              'ganado': 192000,
              'cargosAFavor': 3000,
              'saldoConNexa': 48000,
            },
          ),
        }),
      ).saldo();
      expect(s.viajes, 12);
      expect(s.saldoConNexa, 48000);
    });

    test('el desglose del conductor solo trae lo que debe ver', () async {
      final d = await repo(
        FakeAdapter({
          'GET /api/niveles/viajes/s1/desglose': (
            200,
            {
              'recargoEspera': 500,
              'extraVoluntario': 1000,
              'gananciaConductor': 7500,
              'cobrarAlPasajero': 12000,
            },
          ),
        }),
      ).desglose('s1');
      expect(d.cobrarAlPasajero, 12000);
    });
  });

  group('ConductorController con el backend real', () {
    ProviderContainer contenedor(_Repo falso, {LatLng? gps}) {
      final c = ProviderContainer(
        overrides: [
          ...overridesTest(miPosicion: gps == null ? null : () async => gps),
          conductorRepositoryProvider.overrideWithValue(falso),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test(
      'en línea reporta su posición y pide solicitudes con sus coordenadas',
      () async {
        final falso = _Repo(disponibles: [_solicitud('a'), _solicitud('b')]);
        final c = contenedor(falso, gps: const LatLng(10.40, -75.50));
        await c.read(sesionProvider.notifier).login('conductor@x.co', '123456');
        await c.read(conductorProvider.future);

        await c.read(conductorProvider.notifier).alternarLinea();

        expect(falso.reportes, [(_o, true)]);
        expect(falso.coordsDisponibles, [(10.40, -75.50)]);
        expect(
          c.read(conductorProvider).requireValue.solicitudes,
          hasLength(2),
        );
        await c.read(conductorProvider.notifier).alternarLinea();
        // Al desconectarse avisa que ya no está disponible.
        expect(falso.reportes.last, (_o, false));
      },
    );

    test(
      'si otro conductor la tomó (409), la solicitud sale de la lista',
      () async {
        final falso = _Repo(
          disponibles: [_solicitud('a'), _solicitud('b')],
          falloAceptar: const AppException(
            ErrorKind.validacion,
            'La solicitud ya fue tomada por otro conductor',
            statusCode: 409,
          ),
        );
        final c = contenedor(falso, gps: const LatLng(10.40, -75.50));
        await c.read(sesionProvider.notifier).login('conductor@x.co', '123456');
        await c.read(conductorProvider.future);
        final ctrl = c.read(conductorProvider.notifier);
        await ctrl.alternarLinea();

        await expectLater(
          ctrl.aceptar(_solicitud('a')),
          throwsA(isA<AppException>()),
        );

        final ids = c
            .read(conductorProvider)
            .requireValue
            .solicitudes
            .map((s) => s.id);
        expect(ids, ['b']);
        await ctrl.alternarLinea();
      },
    );

    test('sin señal, «Iniciar» queda en cola, avanza en el teléfono y se envía '
        'después con la misma llave y su hora', () async {
      final falso = _Repo(
        activo: _viaje(EstadoServicio.aceptado)
            .copyWith(fechaLlegada: DateTime(2026, 11, 13, 9)),
      );
      final c = contenedor(falso, gps: const LatLng(10.40, -75.50));
      await c.read(sesionProvider.notifier).login('conductor@x.co', '123456');
      await c.read(conductorProvider.future);
      final ctrl = c.read(conductorProvider.notifier);

      falso.sinRed = true;
      await ctrl.avanzar();

      expect(
        c.read(conductorProvider).requireValue.fase,
        FaseConductor.enViaje,
      );
      final cola = c.read(sinConexionProvider).pendientes;
      expect(cola.single.tipo, TipoPendiente.iniciar);
      expect(falso.llaves, isEmpty);

      // Sin señal el ciclo guarda la posición para el recorrido real.
      await ctrl.sondear();
      expect(c.read(sinConexionProvider).puntos, 1);

      falso.sinRed = false;
      await ctrl.sondear();

      expect(falso.lotes.single, hasLength(1));
      expect(falso.llaves.single, cola.single.llave);
      expect(falso.horas.single, cola.single.ocurridoEn);
      expect(c.read(sinConexionProvider).hayAlgo, isFalse);
      expect(falso.activo?.estado, EstadoServicio.enCurso);
    });

    test(
      'sin señal al abrir, el viaje sale de la copia del teléfono',
      () async {
        final falso = _Repo(activo: _viaje(EstadoServicio.aceptado));
        final almacen = AlmacenEnMemoria();
        final c = ProviderContainer(
          overrides: [
            ...overridesTest(),
            conductorRepositoryProvider.overrideWithValue(falso),
            almacenSinConexionProvider.overrideWithValue(almacen),
          ],
        );
        addTearDown(c.dispose);
        await c.read(sesionProvider.notifier).login('conductor@x.co', '123456');
        await c.read(conductorProvider.future);
        await Future<void>.delayed(Duration.zero);
        expect(await almacen.instantanea('conductor'), isNotNull);

        falso.sinRed = true;
        c.invalidate(conductorProvider);
        final estado = await c.read(conductorProvider.future);
        expect(estado.activo?.id, 'v1');
        expect(estado.copiaDe, isNotNull);
      },
    );

    test('«Llegué» sin GPS explica por qué no puede continuar', () async {
      final falso = _Repo(activo: _viaje(EstadoServicio.aceptado));
      final c = contenedor(falso);
      await c.read(sesionProvider.notifier).login('conductor@x.co', '123456');
      final estado = await c.read(conductorProvider.future);
      expect(estado.fase, FaseConductor.aRecoger);

      await expectLater(
        c.read(conductorProvider.notifier).avanzar(),
        throwsA(
          isA<AppException>().having(
            (e) => e.mensaje,
            'mensaje',
            contains('ubicación'),
          ),
        ),
      );
      expect(falso.llegadas, isEmpty);
    });

    test(
      'con viaje activo toma ETA y la posición del pasajero del servidor',
      () async {
        final falso = _Repo(
          activo: _viaje(EstadoServicio.aceptado),
          posicion: const PosicionViaje(
            fase: 'ACEPTADO',
            latitud: 10.41,
            longitud: -75.51,
            distanciaRestanteKm: 1.1,
            etaMinutos: 3,
          ),
          pasajero: const PosicionPasajero(
            latitud: 10.40,
            longitud: -75.50,
            haceSegundos: 2,
            distanciaRecogidaMetros: 80,
          ),
        );
        final c = contenedor(falso, gps: const LatLng(10.40, -75.50));
        await c.read(sesionProvider.notifier).login('conductor@x.co', '123456');
        await c.read(conductorProvider.future);

        await c.read(conductorProvider.notifier).sondear();

        final s = c.read(conductorProvider).requireValue;
        expect(s.posicion?.etaMinutos, 3);
        expect(s.pasajero?.distanciaRecogidaMetros, 80);
        expect(
          falso.reportes.last.$2,
          false,
          reason: 'en viaje no recibe más solicitudes',
        );
      },
    );

    test(
      'si el pasajero cancela, el viaje se cierra y el conductor es avisado',
      () async {
        final falso = _Repo(activo: _viaje(EstadoServicio.aceptado));
        final c = contenedor(falso, gps: const LatLng(10.40, -75.50));
        await c.read(sesionProvider.notifier).login('conductor@x.co', '123456');
        await c.read(conductorProvider.future);
        falso.activo = null; // el servidor responde 204: ya no hay viaje

        await c.read(conductorProvider.notifier).sondear();

        final s = c.read(conductorProvider).requireValue;
        expect(s.activo, isNull);
        expect(s.pasajeroCancelo, isTrue);
      },
    );

    test('finalizar muestra el resumen con lo que debe cobrar', () async {
      final falso = _Repo(
        activo: _viaje(EstadoServicio.enCurso),
        desglose: const DesgloseConductor(
          gananciaConductor: 7000,
          cobrarAlPasajero: 9000,
        ),
      );
      final c = contenedor(falso, gps: const LatLng(10.40, -75.50));
      await c.read(sesionProvider.notifier).login('conductor@x.co', '123456');
      await c.read(conductorProvider.future);

      await c.read(conductorProvider.notifier).avanzar();

      final s = c.read(conductorProvider).requireValue;
      expect(s.activo, isNull);
      expect(s.terminado?.estado, EstadoServicio.finalizado);
      expect(s.desgloseTerminado?.cobrarAlPasajero, 9000);
      c.read(conductorProvider.notifier).cerrarResumen();
      expect(c.read(conductorProvider).requireValue.terminado, isNull);
    });
  });
}

Servicio _solicitud(String id) => Servicio(
  id: id,
  estado: EstadoServicio.solicitado,
  ubicacionOrigen: _o,
  ubicacionDestino: _d,
  tarifa: 9000,
);

Servicio _viaje(EstadoServicio e) => Servicio(
  id: 'v1',
  estado: e,
  ubicacionOrigen: _o,
  ubicacionDestino: _d,
  tarifa: 9000,
);

/// Repositorio del conductor controlado por cada test.
class _Repo implements ConductorRepository {
  _Repo({
    List<Servicio> disponibles = const [],
    this.activo,
    this.posicion,
    this.pasajero,
    this.falloAceptar,
    this._desglose,
  }) : _lista = disponibles;

  final List<Servicio> _lista;
  Servicio? activo;
  final PosicionViaje? posicion;
  final PosicionPasajero? pasajero;
  final AppException? falloAceptar;
  final DesgloseConductor? _desglose;

  final List<(Coordenada, bool)> reportes = [];
  final List<(double?, double?)> coordsDisponibles = [];
  final List<String> llegadas = [];

  /// Simula estar sin señal: las peticiones no llegan al servidor.
  bool sinRed = false;
  final List<String?> llaves = [];
  final List<DateTime?> horas = [];
  final List<List<PuntoGuardado>> lotes = [];

  void _red() {
    if (sinRed) {
      throw const AppException(ErrorKind.red, 'Sin conexión con el servidor.');
    }
  }

  @override
  Future<PosicionViaje?> reportarUbicacion(
    Coordenada p, {
    required bool disponible,
  }) async {
    _red();
    reportes.add((p, disponible));
    return activo == null ? null : posicion;
  }

  @override
  Future<void> reportarLote(List<PuntoGuardado> puntos) async {
    _red();
    lotes.add(puntos);
  }

  @override
  Future<Servicio?> viajeActivo() async {
    _red();
    return activo;
  }

  @override
  Future<PosicionPasajero?> ubicacionPasajero(String id) async => pasajero;
  @override
  @override
  Future<List<Servicio>> disponibles({double? lat, double? lng}) async {
    coordsDisponibles.add((lat, lng));
    return _lista;
  }

  @override
  Future<Servicio> aceptar(String id) async {
    if (falloAceptar != null) throw falloAceptar!;
    return activo = _viaje(EstadoServicio.aceptado);
  }

  @override
  Future<Servicio> llegue(
    String id,
    Coordenada posicion, {
    String? llave,
    DateTime? ocurridoEn,
  }) async {
    _red();
    llaves.add(llave);
    horas.add(ocurridoEn);
    llegadas.add(id);
    return activo = activo!.copyWith(fechaLlegada: DateTime(2026));
  }

  @override
  Future<Servicio> iniciar(
    String id, {
    String? llave,
    DateTime? ocurridoEn,
  }) async {
    _red();
    llaves.add(llave);
    horas.add(ocurridoEn);
    return activo = activo!.copyWith(estado: EstadoServicio.enCurso);
  }

  @override
  Future<Servicio> finalizar(
    String id, {
    String? llave,
    DateTime? ocurridoEn,
  }) async {
    _red();
    llaves.add(llave);
    horas.add(ocurridoEn);
    final fin = activo!.copyWith(estado: EstadoServicio.finalizado);
    activo = null;
    return fin;
  }

  @override
  Future<Servicio> cancelar(String id) async {
    final c = activo!.copyWith(estado: EstadoServicio.cancelado);
    activo = null;
    return c;
  }

  @override
  Future<List<Servicio>> enCurso() async => [?activo];
  @override
  Future<List<Servicio>> historial() async => const [];
  @override
  Future<List<Ingreso>> ingresos({String? periodo}) async => const [];
  @override
  Future<SaldoConductor> saldo({int dias = 30}) async => const SaldoConductor();
  @override
  Future<DesgloseConductor> desglose(String id) async =>
      _desglose ?? const DesgloseConductor();
}
