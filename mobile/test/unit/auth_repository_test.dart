import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/errors/app_exception.dart';
import 'package:nexa_mobile/core/network/api_client.dart';
import 'package:nexa_mobile/core/network/token_storage.dart';
import 'package:nexa_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:nexa_mobile/features/auth/data/auth_repository_mock.dart';
import 'package:nexa_mobile/features/auth/domain/auth.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';

import '../helpers.dart';

void main() {
  late TokenStorage tokens;
  late bool expirada;

  Dio dioCon(Map<String, (int, Object?)> r) {
    final d = crearDio(
      tokens: tokens,
      baseUrl: 'http://test',
      onSesionExpirada: () => expirada = true,
    );
    d.httpClientAdapter = FakeAdapter(r);
    return d;
  }

  setUp(() {
    tokens = TokenStorage(MemorySecureStore());
    expirada = false;
  });

  group('ApiAuthRepository', () {
    test('login guarda el token y deduce el rol del JWT', () async {
      final jwt = jwtFalso({
        'sub': 'a@b.co',
        'roles': ['ROLE_PASAJERO'],
        'userId': 'u1',
      });
      final repo = ApiAuthRepository(
        dioCon({
          'POST /api/auth/login': (200, {'token': jwt}),
        }),
        tokens,
      );
      final s = await repo.login('a@b.co', 'x');
      expect(s.rol, Rol.pasajero);
      expect(s.userId, 'u1');
      expect(await tokens.leer(), jwt);
    });

    test('un conductor recibe el 403 del backend como AppException', () async {
      final repo = ApiAuthRepository(
        dioCon({
          'POST /api/auth/login': (403, {'error': 'Solo pasajeros'}),
        }),
        tokens,
      );
      await expectLater(
        repo.login('c@b.co', 'x'),
        throwsA(
          isA<AppException>().having(
            (e) => e.mensaje,
            'mensaje',
            'Solo pasajeros',
          ),
        ),
      );
      expect(expirada, isFalse, reason: 'el login es público');
    });

    test('restaurar descarta un token vencido', () async {
      await tokens.guardar(
        jwtFalso({
          'sub': 'a',
          'roles': ['ROLE_PASAJERO'],
          'exp': 1,
        }),
      );
      final repo = ApiAuthRepository(dioCon({}), tokens);
      expect(await repo.restaurar(), isNull);
      expect(await tokens.leer(), isNull);
    });

    test('restaurar acepta un token vigente', () async {
      final exp =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000;
      await tokens.guardar(
        jwtFalso({
          'sub': 'a@b.co',
          'roles': ['ROLE_CONDUCTOR'],
          'exp': exp,
        }),
      );
      final repo = ApiAuthRepository(dioCon({}), tokens);
      expect((await repo.restaurar())?.rol, Rol.conductor);
    });

    test('un 401 en ruta autenticada dispara el cierre de sesión', () async {
      final repo = ApiAuthRepository(
        dioCon({
          'GET /api/conductor/perfil': (401, {'error': 'vencida'}),
        }),
        tokens,
      );
      await expectLater(repo.estadoAprobacion(), throwsA(isA<AppException>()));
      expect(expirada, isTrue);
    });

    test('estadoAprobacion lee estadoValidacion', () async {
      final repo = ApiAuthRepository(
        dioCon({
          'GET /api/conductor/perfil': (200, {'estadoValidacion': 'APROBADO'}),
        }),
        tokens,
      );
      expect(await repo.estadoAprobacion(), EstadoAprobacion.aprobado);
    });

    test('el token viaja en Authorization', () async {
      await tokens.guardar('abc');
      final adapter = FakeAdapter({
        'GET /api/niveles/me': (200, <String, Object>{}),
      });
      final d = crearDio(
        tokens: tokens,
        baseUrl: 'http://test',
        onSesionExpirada: () {},
      )..httpClientAdapter = adapter;
      await d.get<Object?>('/niveles/me');
      expect(adapter.llamadas.single.headers['Authorization'], 'Bearer abc');
    });
  });

  group('MockAuthRepository', () {
    test('el correo decide el rol y la sesión se restaura', () async {
      final repo = MockAuthRepository(tokens);
      expect((await repo.login('ana@x.co', '123456')).rol, Rol.pasajero);
      expect((await repo.login('conductor@x.co', '123456')).rol, Rol.conductor);
      final nuevo = MockAuthRepository(tokens);
      expect((await nuevo.restaurar())?.rol, Rol.conductor);
      await nuevo.logout();
      expect(await MockAuthRepository(tokens).restaurar(), isNull);
    });

    test(
      'contraseña corta es rechazada; "pendiente" no está aprobado',
      () async {
        final repo = MockAuthRepository(tokens);
        await expectLater(
          repo.login('a@x.co', '123'),
          throwsA(isA<AppException>()),
        );
        await repo.login('pendiente@x.co', '123456');
        expect(await repo.estadoAprobacion(), EstadoAprobacion.pendiente);
      },
    );
  });
}
