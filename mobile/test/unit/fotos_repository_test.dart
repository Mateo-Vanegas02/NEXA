import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/errors/app_exception.dart';
import 'package:nexa_mobile/core/network/api_client.dart';
import 'package:nexa_mobile/core/network/token_storage.dart';
import 'package:nexa_mobile/core/utils/selector_imagen.dart';
import 'package:nexa_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:nexa_mobile/features/auth/data/auth_repository_mock.dart';
import 'package:nexa_mobile/features/auth/data/perfil_repository_impl.dart';
import 'package:nexa_mobile/features/auth/domain/auth.dart';

import '../helpers.dart';
import '../helpers_foto.dart';

/// Registro de conductor (multipart) y foto de perfil, con HTTP simulado.
void main() {
  late TokenStorage tokens;

  Dio dioCon(FakeAdapter adapter) =>
      crearDio(tokens: tokens, baseUrl: 'http://test', onSesionExpirada: () {})
        ..httpClientAdapter = adapter;

  setUp(() => tokens = TokenStorage(MemorySecureStore()));

  ArchivoImagen foto(String n) => ArchivoImagen(nombre: n, bytes: kPngMinimo);

  RegistroConductor registro() => RegistroConductor(
    nombre: 'Carlos Gomez',
    email: 'carlos@x.co',
    telefono: '3001234567',
    password: 'Clave123',
    licencia: '123456789',
    placa: 'ABC123',
    marca: 'Bajaj',
    modelo: 'Boxer',
    color: 'Negro',
    tarjetaPropiedad: '12345678',
    soat: '123456789012',
    tecnomecanica: '123456',
    fotoLicencia: foto('licencia.jpg'),
    fotoTarjetaPropiedad: foto('tarjeta.png'),
    fotoSoat: foto('soat.webp'),
    fotoTecnomecanica: foto('tecno.jpg'),
  );

  group('registro de conductor', () {
    test(
      'envía los 13 campos y las 4 fotos como multipart, sin token',
      () async {
        final adapter = FakeAdapter({
          'POST /api/auth/registro/conductor': (201, {'mensaje': 'ok'}),
        });
        await tokens.guardar('token-viejo');
        await ApiAuthRepository(
          dioCon(adapter),
          tokens,
        ).registrarConductor(registro());

        final llamada = adapter.llamadas.single;
        expect(llamada.headers.containsKey('Authorization'), isFalse);
        final form = llamada.data as FormData;
        final campos = {for (final c in form.fields) c.key: c.value};
        expect(campos['nombre'], 'Carlos Gomez');
        expect(campos['confirmPassword'], 'Clave123');
        expect(campos['placa'], 'ABC123');
        expect(campos['soat'], '123456789012');
        expect(campos.length, 13);
        final fotos = {for (final f in form.files) f.key: f.value};
        expect(
          fotos.keys,
          containsAll([
            'fotoLicencia',
            'fotoTarjetaPropiedad',
            'fotoSoat',
            'fotoTecnomecanica',
          ]),
        );
        expect(
          fotos['fotoTarjetaPropiedad']!.contentType.toString(),
          'image/png',
        );
        expect(fotos['fotoSoat']!.contentType.toString(), 'image/webp');
        expect(fotos['fotoLicencia']!.contentType.toString(), 'image/jpeg');
        // No inicia sesión: la cuenta queda pendiente.
        expect(await tokens.leer(), 'token-viejo');
      },
    );

    test(
      'un correo repetido (409) llega con el mensaje del servidor',
      () async {
        final repo = ApiAuthRepository(
          dioCon(
            FakeAdapter({
              'POST /api/auth/registro/conductor': (
                409,
                {'error': 'Ya existe un conductor con ese correo'},
              ),
            }),
          ),
          tokens,
        );
        await expectLater(
          repo.registrarConductor(registro()),
          throwsA(
            isA<AppException>()
                .having((e) => e.statusCode, 'status', 409)
                .having((e) => e.mensaje, 'mensaje', contains('Ya existe')),
          ),
        );
      },
    );

    test('una foto inválida (400) muestra el motivo', () async {
      final repo = ApiAuthRepository(
        dioCon(
          FakeAdapter({
            'POST /api/auth/registro/conductor': (
              400,
              {'error': 'La foto de la licencia no es una imagen válida'},
            ),
          }),
        ),
        tokens,
      );
      await expectLater(
        repo.registrarConductor(registro()),
        throwsA(
          isA<AppException>().having(
            (e) => e.kind,
            'kind',
            ErrorKind.validacion,
          ),
        ),
      );
    });

    test('el mock deja la cuenta pendiente y rechaza duplicados', () async {
      final repo = MockAuthRepository(tokens);
      await repo.registrarConductor(registro());
      await expectLater(
        repo.login('carlos@x.co', 'Clave123'),
        throwsA(
          isA<AppException>().having(
            (e) => e.mensaje,
            'mensaje',
            contains('pendiente'),
          ),
        ),
      );
      await expectLater(
        repo.registrarConductor(registro()),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('foto de perfil', () {
    const perfilConFoto = {
      'id': 'u1',
      'rol': 'PASAJERO',
      'nombre': 'Ana Perez',
      'email': 'ana@x.co',
      'tieneFoto': true,
    };

    test('subirFoto envía multipart a PUT /api/perfil/foto', () async {
      final adapter = FakeAdapter({
        'PUT /api/perfil/foto': (200, perfilConFoto),
      });
      final p = await ApiPerfilRepository(dioCon(adapter))
          .subirFoto(foto('yo.png'));
      expect(p.tieneFoto, isTrue);
      final form = adapter.llamadas.single.data as FormData;
      expect(form.files.single.key, 'foto');
      expect(form.files.single.value.filename, 'yo.png');
    });

    test('quitarFoto usa DELETE', () async {
      final adapter = FakeAdapter({
        'DELETE /api/perfil/foto': (
          200,
          {...perfilConFoto, 'tieneFoto': false},
        ),
      });
      final p = await ApiPerfilRepository(dioCon(adapter)).quitarFoto();
      expect(p.tieneFoto, isFalse);
    });

    test('foto demasiado pesada (413) llega como error', () async {
      final repo = ApiPerfilRepository(
        dioCon(
          FakeAdapter({
            'PUT /api/perfil/foto': (
              413,
              {'error': 'La foto debe pesar máximo 5 MB'},
            ),
          }),
        ),
      );
      await expectLater(
        repo.subirFoto(foto('yo.png')),
        throwsA(isA<AppException>()),
      );
    });

    test('descargarFoto devuelve bytes y null si no hay foto (404)', () async {
      final con = ApiPerfilRepository(
        dioCon(FakeAdapter({'GET /api/usuarios/u1/foto': (200, 'datos')})),
      );
      expect(await con.descargarFoto('u1'), isNotEmpty);
      final sin = ApiPerfilRepository(dioCon(FakeAdapter({})));
      expect(await sin.descargarFoto('u1'), isNull);
    });

    test('el mock guarda y quita la foto en memoria', () async {
      final repo = MockPerfilRepository();
      await repo.subirFoto(foto('yo.png'));
      expect(await repo.descargarFoto('mock'), kPngMinimo);
      expect((await repo.obtener()).tieneFoto, isTrue);
      await repo.quitarFoto();
      expect(await repo.descargarFoto('mock'), isNull);
    });
  });
}
