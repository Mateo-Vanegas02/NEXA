import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/errors/app_exception.dart';
import 'package:nexa_mobile/core/l10n/gen/app_localizations_es.dart';
import 'package:nexa_mobile/core/network/api_client.dart';
import 'package:nexa_mobile/core/network/token_storage.dart';
import 'package:nexa_mobile/core/providers.dart';
import 'package:nexa_mobile/core/router/app_router.dart';
import 'package:nexa_mobile/features/auth/domain/auth.dart';
import 'package:nexa_mobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:nexa_mobile/features/satisfaccion/data/satisfaccion_repository_impl.dart';
import 'package:nexa_mobile/features/satisfaccion/data/satisfaccion_repository_mock.dart';
import 'package:nexa_mobile/features/satisfaccion/domain/satisfaccion.dart';
import 'package:nexa_mobile/features/satisfaccion/presentation/controllers/satisfaccion_controller.dart';
import 'package:nexa_mobile/features/satisfaccion/presentation/screens/formato_sat.dart';

import '../helpers.dart';

final _hoy = DateTime(2026, 11, 8, 10);

/// Mock con menos de los mínimos de calificaciones reales.
class _SinDatos extends MockSatisfaccionRepository {
  _SinDatos() : super(retardo: Duration.zero);

  @override
  Future<ModeloInfo> modelo() async =>
      ModeloInfo.fromJson(FixturesSatisfaccion.modelo(datosSuficientes: false));
}

MockSatisfaccionRepository _mock() =>
    MockSatisfaccionRepository(reloj: () => _hoy, retardo: Duration.zero);

ProviderContainer _contenedor({MockSatisfaccionRepository? repo}) {
  final c = ProviderContainer(
    overrides: [
      ...overridesTest(),
      mockSatisfaccionProvider.overrideWithValue(repo ?? _mock()),
      relojSatisfaccionProvider.overrideWithValue(() => _hoy),
      intervaloSondeoProvider.overrideWithValue(
        const Duration(milliseconds: 10),
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUpAll(iniciarFormatos);

  group('modelos del contrato v0.1', () {
    test('resumen', () {
      final r = Resumen.fromJson(FixturesSatisfaccion.resumen());
      expect(r.sinModelo, isFalse);
      expect(r.pasajero.satisfechosPct, 86);
      expect(r.conductor.variacionPts, -2);
      expect(r.conductor.tasaRespuestaPct, 41);
      expect(r.tendencia, hasLength(8));
      expect(r.tendencia.first.semana, '2026-W38');
      expect(r.riesgoTotal, 7);
      expect(r.factorPrincipal, 'Espera hasta que un conductor acepta');
    });

    test('factores por lado', () {
      final p = Factores.fromJson(FixturesSatisfaccion.factores(Lado.pasajero));
      expect(p.lado, Lado.pasajero);
      expect(p.importancia.first.pesoPct, 22);
      expect(p.otrosCantidad, 20);
      expect(p.curvas.first.tramos.last.satisfechosPct, 61);
      final c = Factores.fromJson(
        FixturesSatisfaccion.factores(Lado.conductor),
      );
      expect(c.lado, Lado.conductor);
      expect(c.importancia.first.etiqueta, 'Espera al pasajero en el punto');
    });

    test('viajes en riesgo y conteo por lado', () {
      final r = Riesgo.fromJson(FixturesSatisfaccion.riesgo(_hoy));
      expect(r.umbral, 0.45);
      expect(r.cuantos(null), 7);
      expect(r.cuantos(Lado.pasajero), 5);
      expect(r.cuantos(Lado.conductor), 2);
      expect(r.viajes.first.motivos.first.severidad, Severidad.alta);
      expect(r.viajes.first.fecha, DateTime(2026, 11, 8, 8, 12));
    });

    test('modelo: métricas, datos, programación e historial', () {
      final m = ModeloInfo.fromJson(FixturesSatisfaccion.modelo());
      expect(m.version, 3);
      expect(m.pasajero.supera, isFalse);
      expect(m.conductor.regresionPrAuc, 0.41);
      expect(m.datos.suficientes, isTrue);
      expect(m.datos.minimoCalificaciones, 300);
      expect(m.programacion.frecuencia, Frecuencia.semanal);
      expect(m.programacion.dias, {DiaSemana.dom});
      expect(m.historial.last.estado, EstadoEntrenamiento.faltanDatos);
    });

    test('campos ausentes no rompen el parseo', () {
      final m = ModeloInfo.fromJson({});
      expect(m.version, isNull);
      expect(m.programacion.activa, isFalse);
      expect(Resumen.fromJson({}).tendencia, isEmpty);
      expect(
        Entrenamiento.fromJson({'estado': 'RARO'}).estado,
        EstadoEntrenamiento.fallido,
      );
    });
  });

  group('Programacion', () {
    test('toJson solo envía lo que aplica a la frecuencia', () {
      const p = Programacion.porDefecto;
      expect(p.toJson()['dias'], ['DOM']);
      expect(p.toJson()['cadaHoras'], isNull);
      final cada = p.copyWith(frecuencia: Frecuencia.cadaHoras, cadaHoras: 6);
      expect(cada.toJson()['frecuencia'], 'cada_horas');
      expect(cada.toJson()['dias'], isEmpty);
      expect(cada.toJson()['cadaHoras'], 6);
    });

    test('valida días y horas', () {
      const p = Programacion.porDefecto;
      expect(p.esValida, isTrue);
      expect(p.copyWith(dias: {}).esValida, isFalse);
      expect(
        p.copyWith(frecuencia: Frecuencia.cadaHoras, cadaHoras: 200).esValida,
        isFalse,
      );
      expect(
        p.copyWith(frecuencia: Frecuencia.diaria, dias: {}).esValida,
        isTrue,
      );
    });
  });

  group('FormatoSat', () {
    final l = AppLocalizationsEs();

    test('porcentajes, semanas y escala', () {
      expect(FormatoSat.pct(86), '86 %');
      expect(FormatoSat.pct(86.5), '86,5 %');
      expect(FormatoSat.probabilidad(0.71), '71 %');
      expect(FormatoSat.semana('2026-W44'), 'S44');
      // La escala empieza como mucho en 60 para que siempre se vea el rango.
      expect(FormatoSat.minimoEscala([82, 75.5, null]), 60);
      expect(FormatoSat.minimoEscala([58, 90]), 50);
      expect(FormatoSat.minimoEscala([40]), 30);
      expect(FormatoSat.minimoEscala([]), 60);
    });

    test('resumen de la programación', () {
      const p = Programacion.porDefecto;
      expect(FormatoSat.programacion(l, p), 'Domingos · 02:00');
      expect(
        FormatoSat.programacion(
          l,
          p.copyWith(dias: {DiaSemana.vie, DiaSemana.lun}),
        ),
        'Lun, Vie · 02:00',
      );
      expect(
        FormatoSat.programacion(l, p.copyWith(dias: {DiaSemana.mie})),
        'Miércoles · 02:00',
      );
      expect(
        FormatoSat.programacion(l, p.copyWith(frecuencia: Frecuencia.diaria)),
        'Todos los días · 02:00',
      );
      expect(
        FormatoSat.programacion(
          l,
          p.copyWith(frecuencia: Frecuencia.cadaHoras, cadaHoras: 6),
        ),
        'Cada 6 h',
      );
    });
  });

  group('rol admin', () {
    test('se reconoce en el JWT', () {
      expect(Rol.desdeAuthorities(['ROLE_ADMIN']), Rol.admin);
      expect(Rol.desdeAuthorities(['ROLE_PASAJERO']), Rol.pasajero);
    });

    test('solo ve sus rutas /a/', () {
      const admin = Sesion(token: 't', rol: Rol.admin, email: 'a');
      const s = SesionState(sesion: admin, inicializado: true);
      expect(redirigir(s, '/login'), '/a/satisfaccion');
      expect(redirigir(s, '/p/inicio'), '/a/satisfaccion');
      expect(redirigir(s, '/c/ganancias'), '/a/satisfaccion');
      expect(redirigir(s, '/a/satisfaccion/modelo'), isNull);
      const pasajero = Sesion(token: 't', rol: Rol.pasajero, email: 'a');
      expect(
        redirigir(
          const SesionState(sesion: pasajero, inicializado: true),
          '/a/satisfaccion',
        ),
        '/p/inicio',
      );
    });

    test('el mock entra como admin con un correo "admin"', () async {
      final c = _contenedor();
      await c.read(sesionProvider.notifier).login('admin@nexa.co', '123456');
      expect(c.read(sesionProvider).sesion?.rol, Rol.admin);
    });
  });

  group('ApiSatisfaccionRepository (HTTP simulado)', () {
    late TokenStorage tokens;
    var expirada = 0;

    ApiSatisfaccionRepository repo(FakeAdapter a) => ApiSatisfaccionRepository(
      crearDio(
        tokens: tokens,
        baseUrl: 'http://lambda',
        prefijo: '',
        onSesionExpirada: () => expirada++,
      )..httpClientAdapter = a,
    );

    setUp(() async {
      tokens = TokenStorage(MemorySecureStore());
      await tokens.guardar('jwt-admin');
      expirada = 0;
    });

    test('resumen con fechas y token del admin, sin el prefijo /api', () async {
      final a = FakeAdapter({
        'GET /resumen': (200, FixturesSatisfaccion.resumen()),
      });
      final r = await repo(a)
          .resumen(desde: DateTime(2026, 10, 9), hasta: DateTime(2026, 11, 8));
      expect(r.pasajero.satisfechosPct, 86);
      final pedido = a.llamadas.single;
      expect(
        pedido.uri.toString(),
        'http://lambda/resumen?desde=2026-10-09&hasta=2026-11-08',
      );
      expect(pedido.headers['Authorization'], 'Bearer jwt-admin');
    });

    test('entrenar, consultar, cancelar y programar', () async {
      final a = FakeAdapter({
        'POST /entrenamientos': (202, {'id': 'e-1'}),
        'GET /entrenamientos/e-1': (
          200,
          {
            'id': 'e-1',
            'estado': 'ENTRENANDO',
            'progresoPct': 62,
            'epoca': 31,
            'epocas': 50,
            'pasos': {
              'exportar': 'hecho',
              'entrenar': 'en_curso',
              'comparar': 'pendiente',
              'publicar': 'pendiente',
            },
          },
        ),
        'DELETE /entrenamientos/e-1': (204, null),
        'PUT /programacion': (
          200,
          {
            ...Programacion.porDefecto.toJson(),
            'activa': true,
            'proxima': '2026-11-15T02:00:00-05:00',
          },
        ),
      });
      final r = repo(a);
      expect(await r.entrenar(), 'e-1');
      expect(a.llamadas.first.uri.queryParameters, isEmpty);
      final e = await r.entrenamiento('e-1');
      expect(e.estado, EstadoEntrenamiento.entrenando);
      expect(e.pasos[PasoEntrenamiento.exportar], EstadoPaso.hecho);
      expect(e.pasos[PasoEntrenamiento.entrenar], EstadoPaso.enCurso);
      await r.cancelarEntrenamiento('e-1');
      final p = await r.guardarProgramacion(
        Programacion.porDefecto.copyWith(activa: true),
      );
      expect(p.proxima, isNotNull);
      expect(a.llamadas.last.data, isA<Map<String, dynamic>>());
    });

    test('datos insuficientes (422) llegan como AppException', () async {
      final a = FakeAdapter({
        'POST /entrenamientos': (
          422,
          {'error': 'datos_insuficientes', 'mensaje': 'Faltan datos'},
        ),
      });
      await expectLater(
        repo(a).entrenar(),
        throwsA(isA<AppException>().having((e) => e.statusCode, 'status', 422)),
      );
    });

    test('un 401 cierra la sesión', () async {
      final a = FakeAdapter({
        'GET /modelo': (401, {'error': 'token'}),
      });
      await expectLater(repo(a).modelo(), throwsA(isA<AppException>()));
      expect(expirada, 1);
    });

    test('sin URL configurada falla con un mensaje claro', () async {
      await expectLater(
        const SatisfaccionNoConfigurada().modelo(),
        throwsA(isA<AppException>()),
      );
      final c = ProviderContainer(
        overrides: [
          secureStoreProvider.overrideWithValue(MemorySecureStore()),
          useMocksProvider.overrideWithValue(false),
          satisfaccionUrlProvider.overrideWithValue(''),
        ],
      );
      addTearDown(c.dispose);
      expect(
        c.read(satisfaccionRepositoryProvider),
        isA<SatisfaccionNoConfigurada>(),
      );
    });
  });

  group('controladores', () {
    test('el período cambia el rango del resumen', () async {
      final c = _contenedor();
      final p = c.read(periodoProvider);
      expect(p.tipo, TipoPeriodo.dias30);
      expect(p.hasta, DateTime(2026, 11, 8));
      expect(p.desde, DateTime(2026, 10, 10));
      c.read(periodoProvider.notifier).elegir(TipoPeriodo.dias7);
      expect(c.read(periodoProvider).desde, DateTime(2026, 11, 2));
      expect((await c.read(resumenProvider.future)).riesgoTotal, 7);
    });

    test('al cambiar de lado vuelve a la primera curva', () async {
      final c = _contenedor();
      c.read(curvaSeleccionadaProvider.notifier).elegir(2);
      expect(c.read(curvaSeleccionadaProvider), 2);
      c.read(ladoFactoresProvider.notifier).elegir(Lado.conductor);
      expect(c.read(curvaSeleccionadaProvider), 0);
      expect((await c.read(factoresProvider.future)).lado, Lado.conductor);
    });

    test('entrena con datos reales; un segundo a la vez da 409', () async {
      final repo = _mock();
      final c = _contenedor(repo: repo);
      await c.read(modeloProvider.future);
      final id = await c.read(modeloProvider.notifier).entrenar();
      expect(id, startsWith('e-mock-'));
      // Un segundo entrenamiento mientras sigue el primero: 409.
      await expectLater(
        c.read(modeloProvider.notifier).entrenar(),
        throwsA(isA<AppException>().having((e) => e.statusCode, 's', 409)),
      );
    });

    test('el sondeo sigue el entrenamiento hasta publicar', () async {
      final c = _contenedor();
      await c.read(modeloProvider.future);
      final id = await c.read(modeloProvider.notifier).entrenar();
      final sub = c.listen(entrenamientoProvider, (_, _) {});
      addTearDown(sub.close);
      c.read(entrenamientoProvider.notifier).seguir(id);
      for (var i = 0; i < 100; i++) {
        final e = c.read(entrenamientoProvider).value;
        if (e != null && e.estado.esFinal) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(
        c.read(entrenamientoProvider).value?.estado,
        EstadoEntrenamiento.publicado,
      );
      final m = await c.read(modeloProvider.future);
      expect(m.version, 4);
      expect(m.historial.first.estado, EstadoEntrenamiento.publicado);
    });

    test(
      'sin datos suficientes no entrena (422), nunca con sintéticos',
      () async {
        final repo = _SinDatos();
        final c = _contenedor(repo: repo);
        await c.read(modeloProvider.future);
        await expectLater(
          c.read(modeloProvider.notifier).entrenar(),
          throwsA(isA<AppException>().having((e) => e.statusCode, 's', 422)),
        );
      },
    );

    test('cancelar detiene el entrenamiento', () async {
      final c = _contenedor();
      await c.read(modeloProvider.future);
      final id = await c.read(modeloProvider.notifier).entrenar();
      final sub = c.listen(entrenamientoProvider, (_, _) {});
      addTearDown(sub.close);
      c.read(entrenamientoProvider.notifier).seguir(id);
      await c.read(entrenamientoProvider.notifier).cancelar();
      // El sondeo en curso puede llegar antes; el siguiente ya ve la cancelación.
      for (var i = 0; i < 100; i++) {
        if (c.read(entrenamientoProvider).value?.estado ==
            EstadoEntrenamiento.cancelado) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(
        c.read(entrenamientoProvider).value?.estado,
        EstadoEntrenamiento.cancelado,
      );
    });

    test('guardar la programación actualiza el modelo', () async {
      final c = _contenedor();
      final m = await c.read(modeloProvider.future);
      await c
          .read(modeloProvider.notifier)
          .guardarProgramacion(
            m.programacion.copyWith(frecuencia: Frecuencia.diaria),
          );
      expect(
        c.read(modeloProvider).value?.programacion.frecuencia,
        Frecuencia.diaria,
      );
      await c.read(modeloProvider.notifier).activarProgramacion(false);
      expect(c.read(modeloProvider).value?.programacion.activa, isFalse);
    });
  });
}
