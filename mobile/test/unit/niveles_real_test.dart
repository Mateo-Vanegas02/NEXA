import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/errors/app_exception.dart';
import 'package:nexa_mobile/core/network/api_client.dart';
import 'package:nexa_mobile/core/network/token_storage.dart';
import 'package:nexa_mobile/features/niveles/data/niveles_repository_impl.dart';
import 'package:nexa_mobile/features/niveles/domain/nivel.dart';

import '../helpers.dart';

/// `GET /api/niveles/me` con el formato real del modelo v2.3 (HTTP simulado).
void main() {
  late TokenStorage tokens;

  ApiNivelesRepository repo(FakeAdapter a) => ApiNivelesRepository(
    crearDio(tokens: tokens, baseUrl: 'http://test', onSesionExpirada: () {})
      ..httpClientAdapter = a,
  );

  setUp(() => tokens = TokenStorage(MemorySecureStore()));

  test(
    'pasajero: niveles desde 1, XP con decimales, descuento y prioridad',
    () async {
      final a = FakeAdapter({
        'GET /api/niveles/me': (
          200,
          {
            'usuarioId': 'u1',
            'rol': 'pasajero',
            'nivel': 3,
            'xpActual': 812.5,
            'xpNivelActual': 760.0,
            'xpSiguienteNivel': 1400.0,
            'xpFaltante': 587.5,
            'progreso': 0.08,
            'descuento': 0.03,
            'prioridadSegundos': 25,
            'niveles': [
              {
                'nivel': 2,
                'xp': 270.0,
                'descuento': 0.02,
                'beneficios': [
                  {
                    'clave': 'DESCUENTO',
                    'titulo': 'Descuento',
                    'descripcion': '2 %',
                    'nivelRequerido': 2,
                    'activo': true,
                  },
                ],
                'comision': null,
              },
            ],
            'beneficiosActivos': [
              {
                'clave': 'PRIORIDAD',
                'titulo': 'Prioridad de recogida',
                'descripcion': '25 s',
                'nivelRequerido': 3,
                'activo': true,
              },
            ],
            'conductor': null,
          },
        ),
      });
      final n = await repo(a).me('pasajero');

      expect(a.llamadas.single.queryParameters, {'rol': 'pasajero'});
      expect(n.nivel, 3);
      expect(n.nombre, '3');
      expect(n.nombreSiguiente, '4');
      expect(n.descuento, 0.03);
      expect(n.prioridadSegundos, 25);
      expect(n.xpActual, 812, reason: 'los decimales se truncan para mostrar');
      expect(n.niveles.single.descuento, 0.02);
      expect(n.niveles.single.beneficios.single.activo, isTrue);
      expect(n.beneficiosActivos.single.clave, 'PRIORIDAD');
      expect(n.esNivelMaximo, isFalse);
    },
  );

  test('conductor: comisión de 20 % a 15 % y requisitos de calidad', () async {
    final n = await repo(
      FakeAdapter({
        'GET /api/niveles/me': (
          200,
          {
            'usuarioId': 'c1',
            'rol': 'conductor',
            'nivel': 5,
            'xpActual': 7000.0,
            'xpNivelActual': 6400.0,
            'xpSiguienteNivel': null,
            'xpFaltante': 0.0,
            'progreso': 1.0,
            'descuento': 0.0,
            'prioridadSegundos': 0,
            'niveles': <Object>[],
            'beneficiosActivos': <Object>[],
            'conductor': {
              'comisionActual': 0.15,
              'comisionSiguiente': null,
              'calificacion': 4.9,
              'aceptacion': 0.95,
              'cancelacion': 0.01,
              'requisitosSiguiente': <Object>[],
              'bloqueadoPorCalidad': false,
            },
          },
        ),
      }),
    ).me('conductor');

    expect(n.esNivelMaximo, isTrue);
    expect(n.nombreSiguiente, isNull);
    expect(n.conductor?.comisionActual, 0.15);
    expect(n.conductor?.comisionSiguiente, isNull);
  });

  test('un error del servidor llega con su mensaje', () async {
    await expectLater(
      repo(
        FakeAdapter({
          'GET /api/niveles/me': (403, {'error': 'Acceso denegado'}),
        }),
      ).me('pasajero'),
      throwsA(isA<AppException>()),
    );
  });

  test('el modelo ya no tiene Días NEXA ni Créditos NEXA', () {
    const n = NivelEstado(usuarioId: 'u', rol: 'pasajero', nivel: 1);
    expect(n.toJson().keys, isNot(contains('diasNexa')));
    expect(n.toJson().keys, isNot(contains('saldoCreditos')));
    expect(n.toJson().keys, isNot(contains('usosRestantesMes')));
  });
}
