import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexa_mobile/core/errors/app_exception.dart';
import 'package:nexa_mobile/core/network/api_client.dart';
import 'package:nexa_mobile/core/network/token_storage.dart';
import 'package:nexa_mobile/core/providers.dart';
import 'package:nexa_mobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:nexa_mobile/features/viajes/data/viajes_repository_impl.dart';
import 'package:nexa_mobile/features/viajes/domain/perfil_pasajero.dart';
import 'package:nexa_mobile/features/viajes/domain/oferta_activa.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';
import 'package:nexa_mobile/features/viajes/domain/viajes_repository.dart';
import 'package:nexa_mobile/features/viajes/presentation/controllers/viaje_pasajero_controller.dart';

import '../helpers.dart';

const _o = Coordenada(latitud: 10.40, longitud: -75.50);
const _d = Coordenada(latitud: 10.42, longitud: -75.52);

/// Ciclo del viaje del pasajero contra el backend real (HTTP simulado).
void main() {
  late TokenStorage tokens;

  ApiPasajeroRepository repo(FakeAdapter a) => ApiPasajeroRepository(
    crearDio(tokens: tokens, baseUrl: 'http://test', onSesionExpirada: () {})
      ..httpClientAdapter = a,
  );

  setUp(() => tokens = TokenStorage(MemorySecureStore()));

  group('ApiPasajeroRepository', () {
    test('un viaje que no se puede leer no tumba el historial', () async {
      final a = FakeAdapter({
        'GET /api/pasajero/historial': (
          200,
          [
            {'id': 'v1', 'estado': 'FINALIZADO', 'tarifa': 9000},
            {'id': 'v2', 'estado': 'ESTADO_NUEVO'},
            {'id': 'v3', 'estado': 'CANCELADO', 'distanciaKM': 'no es número'},
            {'id': 'v4', 'estado': 'CANCELADO'},
          ],
        ),
      });
      final viajes = await repo(a).historial();
      expect(viajes.map((v) => v.id), ['v1', 'v4']);
    });

    test('cotizar lee el precio que calcula el servidor', () async {
      final a = FakeAdapter({
        'POST /api/pasajero/cotizar': (
          200,
          {
            'distanciaKm': 4.63,
            'tarifa': 9000,
            'descuento': 90,
            'precio': 8910,
            'multiplicador': 1.0,
            'deudaPendiente': 3000,
            'totalAPagar': 11910,
          },
        ),
      });
      final c = await repo(a).cotizar(_o, _d);
      expect(c.distanciaKm, 4.63);
      expect(c.precio, 8910);
      expect(c.tieneDeuda, isTrue);
      expect(c.totalAPagar, 11910);
      expect(a.llamadas.single.data, {
        'ubicacionOrigen': {'latitud': 10.40, 'longitud': -75.50},
        'ubicacionDestino': {'latitud': 10.42, 'longitud': -75.52},
      });
    });

    test('fuera de la zona de servicio el servidor explica por qué', () async {
      final r = repo(
        FakeAdapter({
          'POST /api/pasajero/cotizar': (
            400,
            {'error': 'El servicio solo está disponible en Cartagena'},
          ),
        }),
      );
      await expectLater(
        r.cotizar(_o, _d),
        throwsA(
          isA<AppException>().having(
            (e) => e.mensaje,
            'mensaje',
            contains('Cartagena'),
          ),
        ),
      );
    });

    test(
      'solicitar no envía precio ni distancia: los calcula el servidor',
      () async {
        final a = FakeAdapter({
          'POST /api/pasajero/solicitar-viaje': (
            200,
            {'id': 's1', 'estado': 'SOLICITADO'},
          ),
        });
        final s = await repo(a).solicitar(
          const SolicitudViaje(
            origen: 'A',
            destino: 'B',
            ubicacionOrigen: _o,
            ubicacionDestino: _d,
            ubicacionPasajero: _o,
            aceptaDeuda: true,
          ),
        );
        expect(s.estado, EstadoServicio.solicitado);
        final cuerpo = a.llamadas.single.data as Map<String, dynamic>;
        expect(cuerpo.containsKey('tarifa'), isFalse);
        expect(cuerpo.containsKey('distanciaKM'), isFalse);
        expect(cuerpo.containsKey('upgrade'), isFalse);
        expect(cuerpo['aceptaDeuda'], isTrue);
        expect(cuerpo['ubicacionPasajero'], {
          'latitud': 10.40,
          'longitud': -75.50,
        });
      },
    );

    test(
      'solicitar lee la respuesta real {servicioId} y pide el viaje',
      () async {
        final a = FakeAdapter({
          'POST /api/pasajero/solicitar-viaje': (
            200,
            {
              'mensaje': 'Viaje solicitado con éxito. Esperando conductor...',
              'servicioId': 's9',
              'desglose': {'tarifa': 7000},
            },
          ),
          'GET /api/pasajero/servicios/s9': (
            200,
            {'id': 's9', 'estado': 'SOLICITADO', 'origen': 'A', 'destino': 'B'},
          ),
        });
        final s = await repo(a).solicitar(
          const SolicitudViaje(
            origen: 'A',
            destino: 'B',
            ubicacionOrigen: _o,
            ubicacionDestino: _d,
          ),
        );
        expect(s.id, 's9');
        expect(s.estado, EstadoServicio.solicitado);
      },
    );

    test(
      'retoma la solicitud que espera conductor o el viaje en camino',
      () async {
        expect(
          await repo(
            FakeAdapter({
              'GET /api/pasajero/solicitud-activa': (
                200,
                {'activa': true, 'servicioId': 's1', 'estado': 'SOLICITADO'},
              ),
            }),
          ).viajeAbiertoId(),
          's1',
        );
        expect(
          await repo(
            FakeAdapter({
              'GET /api/pasajero/solicitud-activa': (200, {'activa': false}),
              'GET /api/pasajero/viaje-en-camino': (
                200,
                {'activo': true, 'id': 's2', 'estado': 'ACEPTADO'},
              ),
            }),
          ).viajeAbiertoId(),
          's2',
        );
        expect(
          await repo(
            FakeAdapter({
              'GET /api/pasajero/solicitud-activa': (200, {'activa': false}),
              'GET /api/pasajero/viaje-en-camino': (200, {'activo': false}),
            }),
          ).viajeAbiertoId(),
          isNull,
        );
      },
    );

    test('402: falta aceptar el cargo pendiente', () async {
      final r = repo(
        FakeAdapter({
          'POST /api/pasajero/solicitar-viaje': (
            402,
            {'error': 'Tienes un cargo pendiente'},
          ),
        }),
      );
      await expectLater(
        r.solicitar(
          const SolicitudViaje(
            origen: 'A',
            destino: 'B',
            ubicacionOrigen: _o,
            ubicacionDestino: _d,
          ),
        ),
        throwsA(isA<AppException>().having((e) => e.statusCode, 'status', 402)),
      );
    });

    test(
      'la posición del conductor llega con ETA y distancia del servidor',
      () async {
        final p = await repo(
          FakeAdapter({
            'GET /api/pasajero/posicion-conductor/s1': (
              200,
              {
                'servicioId': 's1',
                'fase': 'ACEPTADO',
                'latitud': 10.41,
                'longitud': -75.51,
                'distanciaRestanteKm': 1.2,
                'etaMinutos': 4,
                'en': 123,
              },
            ),
          }),
        ).posicionConductor('s1');
        expect(p?.fase, 'ACEPTADO');
        expect(p?.etaMinutos, 4);
        expect(p?.distanciaRestanteKm, 1.2);
      },
    );

    test('una posición sin mediciones conserva la ubicación', () async {
      final p = await repo(
        FakeAdapter({
          'GET /api/pasajero/posicion-conductor/s1': (
            200,
            {'fase': 'EN_CURSO', 'latitud': 10.41, 'longitud': -75.51},
          ),
        }),
      ).posicionConductor('s1');
      expect(p?.latitud, 10.41);
      expect(p?.etaMinutos, isNull);
      expect(p?.distanciaRestanteKm, isNull);
    });

    test('sin posición (204) devuelve null', () async {
      final p = await repo(
        FakeAdapter({'GET /api/pasajero/posicion-conductor/s1': (204, null)}),
      ).posicionConductor('s1');
      expect(p, isNull);
    });

    test('reportar ubicación y subir extra usan sus rutas', () async {
      final a = FakeAdapter({
        'POST /api/pasajero/ubicacion/s1': (204, null),
        'POST /api/pasajero/subir-oferta/s1': (200, {'ok': true}),
      });
      final r = repo(a);
      await r.reportarUbicacion('s1', _o);
      await r.subirExtra('s1', 1000);
      expect(a.llamadas[0].data, {'latitud': 10.40, 'longitud': -75.50});
      expect(a.llamadas[1].data, {'incremento': 1000});
    });

    test('409: otro cambio ganó al extra voluntario', () async {
      final r = repo(
        FakeAdapter({
          'POST /api/pasajero/subir-oferta/s1': (
            409,
            {'error': 'El extra ya llegó al tope'},
          ),
        }),
      );
      await expectLater(
        r.subirExtra('s1', 500),
        throwsA(isA<AppException>().having((e) => e.statusCode, 'status', 409)),
      );
    });

    test('el desglose del pasajero usa los campos del modelo v2.3', () async {
      final d = await repo(
        FakeAdapter({
          'GET /api/niveles/viajes/s1/desglose': (
            200,
            {
              'tarifa': 9000,
              'descuentoNivel': 90,
              'recargoEspera': 500,
              'extraVoluntario': 1000,
              'totalPasajero': 10410,
              'deudaAnterior': 3000,
              'totalAPagar': 13410,
            },
          ),
        }),
      ).desglose('s1');
      expect(d.descuentoNivel, 90);
      expect(d.totalAPagar, 13410);
    });
  });

  group('ViajePasajeroController: seguimiento', () {
    test(
      'en cada ciclo trae la posición del conductor y reporta la del pasajero',
      () async {
        final falso = _RepoFalso();
        final c = ProviderContainer(
          overrides: [
            ...overridesTest(
              miPosicion: () async => const LatLng(10.40, -75.50),
            ),
            pasajeroRepositoryProvider.overrideWithValue(falso),
          ],
        );
        addTearDown(c.dispose);
        await c.read(sesionProvider.notifier).login('ana@x.co', '123456');
        expect(await c.read(viajePasajeroProvider.future), isNotNull);

        await c.read(viajePasajeroProvider.notifier).sondear();

        expect(c.read(posicionConductorProvider)?.etaMinutos, 4);
        expect(falso.reportes, [_o]);
        c.dispose();
      },
    );

    test(
      'mientras se busca conductor no pide posición ni reporta la del pasajero',
      () async {
        final falso = _RepoFalso(estado: EstadoServicio.solicitado);
        final c = ProviderContainer(
          overrides: [
            ...overridesTest(
              miPosicion: () async => const LatLng(10.40, -75.50),
            ),
            pasajeroRepositoryProvider.overrideWithValue(falso),
          ],
        );
        addTearDown(c.dispose);
        await c.read(sesionProvider.notifier).login('ana@x.co', '123456');
        await c.read(viajePasajeroProvider.future);

        await c.read(viajePasajeroProvider.notifier).sondear();

        expect(c.read(posicionConductorProvider), isNull);
        expect(falso.reportes, isEmpty);
        expect(falso.consultasPosicion, 0);
        c.dispose();
      },
    );

    test('subir el extra lo envía y refresca el viaje', () async {
      final falso = _RepoFalso(estado: EstadoServicio.solicitado);
      final c = ProviderContainer(
        overrides: [
          ...overridesTest(),
          pasajeroRepositoryProvider.overrideWithValue(falso),
        ],
      );
      addTearDown(c.dispose);
      await c.read(sesionProvider.notifier).login('ana@x.co', '123456');
      await c.read(viajePasajeroProvider.future);

      await c.read(viajePasajeroProvider.notifier).subirExtra(1000);

      expect(falso.extras, [1000]);
      expect(c.read(viajePasajeroProvider).value?.extraVoluntario, 1000);
      c.dispose();
    });
  });
}

/// Repositorio con un único viaje activo para probar el controlador.
class _RepoFalso implements PasajeroRepository {
  _RepoFalso({this.estado = EstadoServicio.aceptado});

  final EstadoServicio estado;
  final List<Coordenada> reportes = [];
  final List<int> extras = [];
  int consultasPosicion = 0;
  double _extra = 0;

  Servicio get _s => Servicio(
    id: 's1',
    estado: estado,
    extraVoluntario: _extra,
    ubicacionOrigen: _o,
    ubicacionDestino: _d,
  );

  @override
  Future<List<Servicio>> historial() async => [_s];
  @override
  Future<Servicio> detalle(String id) async => _s;
  @override
  Future<String?> viajeAbiertoId() async => estado.activo ? 's1' : null;
  @override
  Future<OfertaActiva?> ofertaActiva() async => null;
  @override
  Future<PosicionViaje?> posicionConductor(String id) async {
    consultasPosicion++;
    return const PosicionViaje(
      fase: 'ACEPTADO',
      latitud: 10.41,
      longitud: -75.51,
      distanciaRestanteKm: 1.2,
      etaMinutos: 4,
    );
  }

  @override
  Future<void> reportarUbicacion(String id, Coordenada posicion) async =>
      reportes.add(posicion);
  @override
  Future<void> subirExtra(String id, int incremento) async {
    extras.add(incremento);
    _extra += incremento;
  }

  @override
  Future<PerfilPasajero> perfil() => throw UnimplementedError();
  @override
  Future<Cotizacion> cotizar(Coordenada origen, Coordenada destino) =>
      throw UnimplementedError();
  @override
  Future<Servicio> solicitar(SolicitudViaje solicitud) =>
      throw UnimplementedError();
  @override
  Future<Servicio> cancelar(String id) => throw UnimplementedError();
  @override
  Future<Servicio> calificar(
    String id,
    double c,
    String t, {
    List<String> factores = const [],
  }) => throw UnimplementedError();
  @override
  Future<DesglosePasajero> desglose(String id) => throw UnimplementedError();
}
