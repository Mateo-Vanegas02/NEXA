import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/errors/app_exception.dart';
import 'package:nexa_mobile/core/network/api_client.dart';
import 'package:nexa_mobile/core/network/token_storage.dart';
import 'package:nexa_mobile/features/auth/data/perfil_repository_impl.dart';

import '../helpers.dart';

void main() {
  late TokenStorage tokens;

  Dio dioCon(FakeAdapter adapter) =>
      crearDio(tokens: tokens, baseUrl: 'http://test', onSesionExpirada: () {})
        ..httpClientAdapter = adapter;

  setUp(() => tokens = TokenStorage(MemorySecureStore()));

  const perfilJson = {
    'id': 'u1',
    'rol': 'PASAJERO',
    'nombre': 'Ana Perez',
    'email': 'ana@x.co',
    'telefono': '3001234567',
    'estadoValidacion': 'APROBADO',
    'tieneFoto': true,
  };

  group('ApiPerfilRepository', () {
    test('obtener lee GET /api/perfil con el token', () async {
      await tokens.guardar('abc');
      final adapter = FakeAdapter({'GET /api/perfil': (200, perfilJson)});
      final p = await ApiPerfilRepository(dioCon(adapter)).obtener();
      expect(p.nombre, 'Ana Perez');
      expect(p.telefono, '3001234567');
      expect(p.tieneFoto, isTrue);
      expect(adapter.llamadas.single.headers['Authorization'], 'Bearer abc');
    });

    test('actualizar envía solo nombre y teléfono', () async {
      final adapter = FakeAdapter({
        'PUT /api/perfil': (200, {...perfilJson, 'nombre': 'Ana Gomez'}),
      });
      final p = await ApiPerfilRepository(dioCon(adapter))
          .actualizar(nombre: 'Ana Gomez', telefono: '3001234567');
      expect(p.nombre, 'Ana Gomez');
      expect(adapter.llamadas.single.data, {
        'nombre': 'Ana Gomez',
        'telefono': '3001234567',
      });
    });

    test(
      'un 400 del servidor llega como AppException con su mensaje',
      () async {
        final repo = ApiPerfilRepository(
          dioCon(
            FakeAdapter({
              'PUT /api/perfil': (400, {'error': 'El nombre es obligatorio'}),
            }),
          ),
        );
        await expectLater(
          repo.actualizar(nombre: '', telefono: '3001234567'),
          throwsA(
            isA<AppException>().having(
              (e) => e.mensaje,
              'mensaje',
              'El nombre es obligatorio',
            ),
          ),
        );
      },
    );
  });

  test('MockPerfilRepository guarda los cambios en memoria', () async {
    final repo = MockPerfilRepository();
    final p = await repo.actualizar(
      nombre: 'Luis Mora',
      telefono: '3109876543',
    );
    expect(p.nombre, 'Luis Mora');
    expect((await repo.obtener()).telefono, '3109876543');
  });
}
