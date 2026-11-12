import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/providers.dart';
import 'package:nexa_mobile/core/rumbo/orientacion_mapa.dart';
import 'package:nexa_mobile/core/rumbo/reglas_rumbo.dart';
import 'package:nexa_mobile/core/rumbo/sensores_movimiento.dart';
import 'package:nexa_mobile/core/segundo_plano/rastreador_ubicacion.dart';

/// Gravedad con el teléfono acostado, pantalla hacia arriba.
const Vector3 plano = (x: 0, y: 0, z: 9.8);

/// Campo terrestre (≈ 40 µT, inclinado hacia abajo) visto por un teléfono
/// acostado cuya parte de arriba apunta a [rumbo] grados.
Vector3 campoHacia(double rumbo) {
  final r = rumbo * math.pi / 180;
  // El norte, en ejes del teléfono: girar el vector (0, 1) por -rumbo.
  return (x: -20 * math.sin(r), y: 20 * math.cos(r), z: -35.0);
}

Future<void> _esperar() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('ReglasRumbo', () {
    test('normaliza y mide la diferencia más corta', () {
      expect(ReglasRumbo.normalizar(-10), 350);
      expect(ReglasRumbo.normalizar(725), 5);
      expect(ReglasRumbo.diferencia(350, 10), 20);
      expect(ReglasRumbo.diferencia(10, 350), -20);
      expect(ReglasRumbo.diferencia(0, 180), 180);
    });

    test('la brújula da el rumbo de la parte de arriba del teléfono', () {
      for (final r in [0.0, 45.0, 90.0, 180.0, 270.0, 315.0]) {
        expect(
          ReglasRumbo.rumboBrujula(plano, campoHacia(r)),
          closeTo(r, 0.5),
          reason: 'mirando a $r°',
        );
      }
    });

    test('compensa la inclinación del teléfono', () {
      // Mismo teléfono mirando al este, inclinado 40° sobre su eje x: los dos
      // vectores giran igual en los ejes del teléfono.
      const t = 40 * math.pi / 180;
      Vector3 inclinar(Vector3 v) => (
        x: v.x,
        y: v.y * math.cos(t) - v.z * math.sin(t),
        z: v.y * math.sin(t) + v.z * math.cos(t),
      );
      expect(
        ReglasRumbo.rumboBrujula(inclinar(plano), inclinar(campoHacia(90))),
        closeTo(90, 0.5),
      );
    });

    test('sin gravedad o sin campo no hay rumbo', () {
      expect(
        ReglasRumbo.rumboBrujula((x: 0, y: 0, z: 0), campoHacia(0)),
        isNull,
      );
      expect(ReglasRumbo.rumboBrujula(plano, (x: 0, y: 0, z: 0)), isNull);
    });

    test('detecta interferencia por la fuerza del campo', () {
      expect(ReglasRumbo.estadoCampo(campoHacia(0)), EstadoBrujula.ok);
      expect(
        ReglasRumbo.estadoCampo((x: 200, y: 0, z: 0)),
        EstadoBrujula.interferencia,
      );
      expect(
        ReglasRumbo.estadoCampo((x: 5, y: 0, z: 0)),
        EstadoBrujula.interferencia,
      );
    });

    test('girar a la izquierda baja el rumbo', () {
      // Giro antihorario visto desde arriba = +z con el teléfono acostado.
      expect(
        ReglasRumbo.giroRumbo((x: 0, y: 0, z: 1), plano),
        closeTo(-57.3, 0.1),
      );
    });

    test('en marcha manda el GPS; detenido, la brújula; sin nada, norte', () {
      final ahora = DateTime(2026, 11, 12, 10);
      MovimientoGps gps(double v, {Duration hace = Duration.zero, double? p}) =>
          MovimientoGps(
            rumbo: 30,
            velocidad: v,
            precisionRumbo: p,
            en: ahora.subtract(hace),
          );
      FuenteRumbo fuente(MovimientoGps? g, EstadoBrujula b) =>
          ReglasRumbo.elegirFuente(gps: g, brujula: b, ahora: ahora);

      expect(fuente(gps(5), EstadoBrujula.ok), FuenteRumbo.gps);
      expect(fuente(gps(1), EstadoBrujula.ok), FuenteRumbo.sensores);
      expect(
        fuente(gps(5, hace: const Duration(seconds: 6)), EstadoBrujula.ok),
        FuenteRumbo.sensores,
      );
      expect(fuente(gps(5, p: 90), EstadoBrujula.ok), FuenteRumbo.sensores);
      expect(fuente(gps(5, p: 10), EstadoBrujula.sinSensor), FuenteRumbo.gps);
      expect(fuente(null, EstadoBrujula.interferencia), FuenteRumbo.ninguna);
      expect(fuente(gps(1), EstadoBrujula.sinSensor), FuenteRumbo.ninguna);
    });

    test('solo gira el mapa con un cambio visible y a 15 por segundo', () {
      final t = DateTime(2026, 11, 12, 10);
      bool debe(double? a, double? b, {int ms = 100, bool sinAnim = false}) =>
          ReglasRumbo.debeActualizar(
            anterior: a,
            nuevo: b,
            anteriorEn: t,
            ahora: t.add(Duration(milliseconds: ms)),
            sinAnimacion: sinAnim,
          );
      expect(debe(10, 12), isFalse);
      expect(debe(10, 14), isTrue);
      expect(debe(359, 3), isTrue, reason: 'cruza el norte');
      expect(debe(10, 20, ms: 30), isFalse, reason: 'muy seguido');
      expect(debe(10, 20, sinAnim: true), isFalse);
      expect(debe(10, 30, sinAnim: true), isTrue);
      expect(debe(null, 30), isTrue);
      expect(debe(30, null), isTrue);
      expect(debe(null, null), isFalse);
    });

    test('rotación del mapa y flecha en pantalla', () {
      expect(ReglasRumbo.rotacionMapa(90), 270);
      expect(ReglasRumbo.rotacionMapa(0), 0);
      // Con el mapa girado al rumbo, la flecha apunta hacia arriba.
      expect(
        ReglasRumbo.anguloEnPantalla(90, ReglasRumbo.rotacionMapa(90)),
        0,
      );
      expect(ReglasRumbo.anguloEnPantalla(90, 0), 90);
    });
  });

  group('FusionRumbo', () {
    test('arranca con la brújula y sigue un giro con el giroscopio', () {
      final f = FusionRumbo();
      var t = DateTime(2026, 11, 12, 10);
      f.actualizar(
        gravedad: plano,
        magnetico: campoHacia(0),
        giroscopio: (x: 0, y: 0, z: 0),
        ahora: t,
      );
      expect(f.rumbo, closeTo(0, 0.5));
      // Gira a la derecha 90°/s durante 0,5 s; la brújula llega igual.
      for (var i = 1; i <= 10; i++) {
        t = t.add(const Duration(milliseconds: 50));
        f.actualizar(
          gravedad: plano,
          magnetico: campoHacia(9.0 * i * 0.5),
          giroscopio: (x: 0, y: 0, z: -math.pi / 2),
          ahora: t,
        );
      }
      expect(f.rumbo, closeTo(45, 3));
    });

    test('la brújula corrige la deriva del giroscopio', () {
      final f = FusionRumbo();
      var t = DateTime(2026, 11, 12, 10);
      for (var i = 0; i < 200; i++) {
        t = t.add(const Duration(milliseconds: 66));
        // Giroscopio con deriva; el teléfono en realidad está quieto al este.
        f.actualizar(
          gravedad: plano,
          magnetico: campoHacia(90),
          giroscopio: (x: 0, y: 0, z: -0.02),
          ahora: t,
        );
      }
      expect(f.rumbo, closeTo(90, 5));
    });

    test('con interferencia o sin magnetómetro no da rumbo', () {
      final f = FusionRumbo()
        ..actualizar(
          gravedad: plano,
          magnetico: (x: 300, y: 0, z: 0),
          giroscopio: null,
          ahora: DateTime(2026),
        );
      expect(f.estado, EstadoBrujula.interferencia);
      expect(f.rumbo, isNull);
      f.actualizar(
        gravedad: null,
        magnetico: null,
        giroscopio: null,
        ahora: DateTime(2026),
        sinMagnetometro: true,
      );
      expect(f.estado, EstadoBrujula.sinSensor);
    });
  });

  group('OrientacionMapaController', () {
    late SensoresEnMemoria sensores;
    late RastreadorEnMemoria rastreador;
    late ProviderContainer c;

    setUp(() {
      sensores = SensoresEnMemoria();
      rastreador = RastreadorEnMemoria();
      c = ProviderContainer(
        overrides: [
          sensoresProvider.overrideWithValue(sensores),
          rastreadorProvider.overrideWithValue(rastreador),
        ],
      );
      addTearDown(c.dispose);
      c.listen(orientacionMapaProvider, (_, _) {});
    });

    test('con norte arriba no usa los sensores', () {
      expect(c.read(orientacionMapaProvider).modo, ModoOrientacion.norte);
      expect(sensores.escuchando, isFalse);
    });

    test('la brújula gira el mapa y al volver al norte se apagan', () async {
      c.read(orientacionMapaProvider.notifier).alternarBrujula();
      expect(sensores.escuchando, isTrue);
      sensores.acel.add(plano);
      sensores.giro.add((x: 0, y: 0, z: 0));
      sensores.mag.add(campoHacia(90));
      await _esperar();
      final e = c.read(orientacionMapaProvider);
      expect(e.fuente, FuenteRumbo.sensores);
      expect(e.rumbo, closeTo(90, 1));
      expect(e.rotacionMapa, closeTo(270, 1));

      c.read(orientacionMapaProvider.notifier).alternarBrujula();
      expect(sensores.escuchando, isFalse);
      expect(c.read(orientacionMapaProvider).rumbo, isNull);
    });

    test('pide calibrar con interferencia y queda el norte', () async {
      c.read(orientacionMapaProvider.notifier).alternarBrujula();
      sensores.acel.add(plano);
      sensores.mag.add((x: 250, y: 0, z: 0));
      await _esperar();
      final e = c.read(orientacionMapaProvider);
      expect(e.aviso, AvisoOrientacion.calibrar);
      expect(e.rumbo, isNull);
    });

    test('sin magnetómetro avisa; en marcha usa el GPS', () async {
      c
          .read(orientacionMapaProvider.notifier)
          .cambiarModo(ModoOrientacion.navegacion);
      sensores.mag.addError(Exception('NO_SENSOR'));
      await _esperar();
      expect(c.read(orientacionMapaProvider).aviso, AvisoOrientacion.sinBrujula);

      rastreador.movimiento = MovimientoGps(
        rumbo: 200,
        velocidad: 6,
        en: DateTime.now(),
      );
      sensores.mag.addError(Exception('NO_SENSOR'));
      await _esperar();
      final e = c.read(orientacionMapaProvider);
      expect(e.fuente, FuenteRumbo.gps);
      expect(e.rumbo, 200);
      expect(e.aviso, AvisoOrientacion.ninguno);
    });

    test('en horizontal la brújula no cuenta', () async {
      c.read(orientacionMapaProvider.notifier)
        ..vertical = false
        ..alternarBrujula();
      sensores.acel.add(plano);
      sensores.mag.add(campoHacia(90));
      await _esperar();
      expect(c.read(orientacionMapaProvider).rumbo, isNull);
    });
  });
}
