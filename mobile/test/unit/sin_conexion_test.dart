import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/errors/app_exception.dart';
import 'package:nexa_mobile/core/sin_conexion/almacen_sin_conexion.dart';
import 'package:nexa_mobile/core/sin_conexion/reglas_sin_conexion.dart';

void main() {
  group('ReglasSinConexion', () {
    test('la llave es única y válida para el servidor', () {
      final a = ReglasSinConexion.nuevaLlave(Random(1));
      final b = ReglasSinConexion.nuevaLlave(Random(2));
      expect(a, matches(RegExp(r'^[0-9a-f]{24}$')));
      expect(a, isNot(b));
    });

    test('sin señal o con error del servidor se reintenta', () {
      expect(
        ReglasSinConexion.resultado(
          const AppException(ErrorKind.red, 'Sin conexión'),
        ),
        ResultadoEnvio.reintentar,
      );
      expect(
        ReglasSinConexion.resultado(
          const AppException(ErrorKind.servidor, 'x', statusCode: 503),
        ),
        ResultadoEnvio.reintentar,
      );
      expect(
        ReglasSinConexion.resultado(
          const AppException(
            ErrorKind.validacion,
            'Esta acción ya se está procesando',
            statusCode: 409,
          ),
        ),
        ResultadoEnvio.reintentar,
      );
    });

    test('si el servidor dice que ya no aplica, sale de la cola', () {
      for (final codigo in [400, 403, 404, 409, 422]) {
        expect(
          ReglasSinConexion.resultado(
            AppException(ErrorKind.validacion, 'No', statusCode: codigo),
          ),
          ResultadoEnvio.rechazada,
          reason: '$codigo',
        );
      }
      expect(ReglasSinConexion.resultado(null), ResultadoEnvio.enviada);
    });

    test('parte las posiciones en envíos', () {
      final l = ReglasSinConexion.lotes(List.generate(1100, (i) => i));
      expect(l.map((e) => e.length), [500, 500, 100]);
    });

    test('la posición viaja en UTC con su hora', () {
      final p = PuntoGuardado(
        latitud: 10.4,
        longitud: -75.5,
        tomadoEn: DateTime.utc(2026, 11, 13, 15),
      );
      expect(p.toJson()['ocurridoEn'], '2026-11-13T15:00:00.000Z');
    });
  });

  group('AlmacenEnMemoria', () {
    test('la cola guarda el orden y no duplica la misma llave', () async {
      final a = AlmacenEnMemoria();
      AccionPendiente accion(String llave, TipoPendiente t) => AccionPendiente(
        llave: llave,
        tipo: t,
        servicioId: 's1',
        ocurridoEn: DateTime(2026),
      );
      await a.encolar(accion('l1', TipoPendiente.llegue));
      await a.encolar(accion('l2', TipoPendiente.iniciar));
      await a.encolar(accion('l1', TipoPendiente.llegue));
      expect((await a.cola()).map((e) => e.llave), ['l1', 'l2']);
      await a.sumarIntento('l2');
      expect((await a.cola()).last.intentos, 1);
      await a.vaciar();
      expect(await a.cola(), isEmpty);
    });

    test('guarda solo los últimos puntos', () async {
      final a = AlmacenEnMemoria();
      for (var i = 0; i < ReglasSinConexion.maxPuntos + 5; i++) {
        await a.guardarPunto(
          PuntoGuardado(latitud: 0, longitud: 0, tomadoEn: DateTime(2026)),
        );
      }
      final todos = await a.puntos(limite: 5000);
      expect(todos, hasLength(ReglasSinConexion.maxPuntos));
      expect(todos.first.id, 6);
    });
  });
}
