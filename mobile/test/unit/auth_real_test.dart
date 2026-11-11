import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/errors/app_exception.dart';
import 'package:nexa_mobile/core/network/api_client.dart';
import 'package:nexa_mobile/core/network/token_storage.dart';
import 'package:nexa_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:nexa_mobile/features/auth/domain/auth.dart';

import '../helpers.dart';

/// Login de conductores y registro de pasajeros contra el backend real (HTTP simulado).
void main() {
  late TokenStorage tokens;

  Dio dioCon(Map<String, (int, Object?)> r, {FakeAdapter? adapter}) =>
      crearDio(tokens: tokens, baseUrl: 'http://test', onSesionExpirada: () {})
        ..httpClientAdapter = adapter ?? FakeAdapter(r);

  setUp(() => tokens = TokenStorage(MemorySecureStore()));

  const datos = RegistroPasajero(
    nombre: 'Ana Perez',
    email: 'ana@x.co',
    telefono: '3001234567',
    password: 'Clave123',
  );

  group('login de conductores', () {
    test('un conductor aprobado inicia sesión', () async {
      final jwt = jwtFalso({
        'sub': 'c@b.co',
        'roles': ['ROLE_CONDUCTOR'],
        'userId': 'u2',
      });
      final repo = ApiAuthRepository(
        dioCon({
          'POST /api/auth/login': (200, {'token': jwt}),
        }),
        tokens,
      );
      expect((await repo.login('c@b.co', 'x')).rol, Rol.conductor);
    });

    test('un conductor rechazado ve su estado y el motivo', () async {
      final repo = ApiAuthRepository(
        dioCon({
          'POST /api/auth/login': (
            403,
            {
              'error': 'Tu solicitud fue rechazada.',
              'estadoValidacion': 'RECHAZADO',
              'motivo': 'documentos ilegibles',
            },
          ),
        }),
        tokens,
      );
      await expectLater(
        repo.login('c@b.co', 'x'),
        throwsA(
          isA<AppException>()
              .having((e) => e.kind, 'kind', ErrorKind.prohibido)
              .having(
                (e) => e.mensaje,
                'mensaje',
                'Tu solicitud fue rechazada. Motivo: documentos ilegibles',
              ),
        ),
      );
      expect(await tokens.leer(), isNull);
    });

    test('un conductor pendiente sin motivo solo ve el mensaje', () async {
      final repo = ApiAuthRepository(
        dioCon({
          'POST /api/auth/login': (
            403,
            {
              'error': 'Tu cuenta está pendiente de aprobación.',
              'estadoValidacion': 'PENDIENTE',
            },
          ),
        }),
        tokens,
      );
      await expectLater(
        repo.login('c@b.co', 'x'),
        throwsA(
          isA<AppException>().having(
            (e) => e.mensaje,
            'mensaje',
            'Tu cuenta está pendiente de aprobación.',
          ),
        ),
      );
    });

    test(
      'un 403 sin estadoValidacion conserva el mensaje del servidor',
      () async {
        final repo = ApiAuthRepository(
          dioCon({
            'POST /api/auth/login': (403, {'error': 'Acceso denegado.'}),
          }),
          tokens,
        );
        await expectLater(
          repo.login('a@b.co', 'x'),
          throwsA(
            isA<AppException>().having(
              (e) => e.mensaje,
              'mensaje',
              'Acceso denegado.',
            ),
          ),
        );
      },
    );
  });

  group('registro de pasajeros', () {
    test('crea la cuenta sin token e inicia sesión', () async {
      final jwt = jwtFalso({
        'sub': 'ana@x.co',
        'roles': ['ROLE_PASAJERO'],
        'userId': 'u3',
      });
      final adapter = FakeAdapter({
        'POST /api/auth/registro/pasajero': (201, {'mensaje': 'ok'}),
        'POST /api/auth/login': (200, {'token': jwt}),
      });
      await tokens.guardar('token-viejo');
      final s = await ApiAuthRepository(
        dioCon(const {}, adapter: adapter),
        tokens,
      ).registrarPasajero(datos);

      expect(s.rol, Rol.pasajero);
      expect(await tokens.leer(), jwt);
      expect(adapter.llamadas.first.data, {
        'nombre': 'Ana Perez',
        'email': 'ana@x.co',
        'telefono': '3001234567',
        'password': 'Clave123',
      });
      expect(
        adapter.llamadas.first.headers.containsKey('Authorization'),
        isFalse,
        reason: 'el registro es público',
      );
    });

    test(
      'correo repetido: muestra el error del servidor y no inicia sesión',
      () async {
        final repo = ApiAuthRepository(
          dioCon({
            'POST /api/auth/registro/pasajero': (
              409,
              {'error': 'Ya existe un pasajero registrado con este email'},
            ),
          }),
          tokens,
        );
        await expectLater(
          repo.registrarPasajero(datos),
          throwsA(
            isA<AppException>()
                .having((e) => e.statusCode, 'status', 409)
                .having((e) => e.mensaje, 'mensaje', contains('Ya existe')),
          ),
        );
        expect(await tokens.leer(), isNull);
      },
    );

    test('datos inválidos del servidor llegan como validación', () async {
      final repo = ApiAuthRepository(
        dioCon({
          'POST /api/auth/registro/pasajero': (
            400,
            {'error': 'El teléfono debe tener entre 7 y 15 dígitos'},
          ),
        }),
        tokens,
      );
      await expectLater(
        repo.registrarPasajero(datos),
        throwsA(
          isA<AppException>().having(
            (e) => e.kind,
            'kind',
            ErrorKind.validacion,
          ),
        ),
      );
    });
  });
}
