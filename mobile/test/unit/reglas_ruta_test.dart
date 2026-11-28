import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexa_mobile/core/mapa/estilo_mapa.dart';
import 'package:nexa_mobile/core/mapa/reglas_ruta.dart';
import 'package:nexa_mobile/core/providers.dart';
import 'package:nexa_mobile/core/network/token_storage.dart';

/// Ruta recta hacia el este por el paralelo 10.4 (≈1,1 km).
const _ruta = [LatLng(10.4, -75.50), LatLng(10.4, -75.49)];

void main() {
  group('ReglasRuta', () {
    test('el círculo de una ola queda a su radio y cerrado', () {
      const centro = LatLng(10.4055, -75.5503);
      const metros = 2500.0;
      final c = ReglasRuta.circulo(centro, metros, lados: 36);
      expect(c, hasLength(37));
      expect(c.first.latitude, closeTo(c.last.latitude, 1e-12));
      expect(c.first.longitude, closeTo(c.last.longitude, 1e-12));
      // Sobre la esfera; con el elipsoide (Vincenty) difiere menos del 1 %.
      const d = Distance();
      for (final p in c) {
        expect(d.as(LengthUnit.Meter, centro, p), closeTo(metros, 25));
      }
      // Empieza al norte y gira en el sentido del reloj (luego al este).
      expect(c.first.latitude, greaterThan(centro.latitude));
      expect(c[9].longitude, greaterThan(centro.longitude));
    });

    test('proyecta sobre el tramo y mide la distancia en metros', () {
      // ≈ 55 m al norte de la mitad de la ruta.
      final p = ReglasRuta.proyectar(_ruta, const LatLng(10.4005, -75.495))!;
      expect(p.tramo, 0);
      expect(p.punto.latitude, closeTo(10.4, 1e-9));
      expect(p.punto.longitude, closeTo(-75.495, 1e-9));
      expect(p.metros, closeTo(55.3, 1));
    });

    test('sin ruta no hay proyección y la distancia es infinita', () {
      expect(ReglasRuta.proyectar(const [], const LatLng(10, -75)), isNull);
      expect(
        ReglasRuta.distanciaA(const [LatLng(10, -75)], const LatLng(10, -75)),
        double.infinity,
      );
    });

    test('divide la ruta donde va la moto: lo recorrido y lo que falta', () {
      final d = ReglasRuta.dividir(_ruta, const LatLng(10.4, -75.495));
      expect(d.recorrido.first, _ruta.first);
      expect(d.falta.last, _ruta.last);
      expect(d.recorrido.last, d.falta.first);
      expect(d.recorrido.last.longitude, closeTo(-75.495, 1e-9));
    });

    test('interpola posiciones y rumbos por el camino corto', () {
      final m = ReglasRuta.interpolar(
        const LatLng(10, -75),
        const LatLng(11, -74),
        0.5,
      );
      expect(m.latitude, closeTo(10.5, 1e-9));
      expect(m.longitude, closeTo(-74.5, 1e-9));
      expect(ReglasRuta.interpolarRumbo(350, 10, 0.5), closeTo(0, 1e-9));
      expect(ReglasRuta.interpolarRumbo(10, 350, 0.5), closeTo(0, 1e-9));
      expect(ReglasRuta.interpolarRumbo(90, 180, 2), closeTo(180, 1e-9));
    });
  });

  group('DetectorDesvio', () {
    final t0 = DateTime(2026, 11, 22, 10);
    const fuera = LatLng(10.401, -75.495); // ≈ 110 m de la ruta
    const dentro = LatLng(10.4001, -75.495); // ≈ 11 m

    test('una sola lectura fuera es ruido; dos seguidas, desvío', () {
      final d = DetectorDesvio();
      expect(d.registrar(_ruta, fuera, t0), isFalse);
      expect(
        d.registrar(_ruta, fuera, t0.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('volver a la ruta reinicia la cuenta', () {
      final d = DetectorDesvio();
      expect(d.registrar(_ruta, fuera, t0), isFalse);
      expect(d.registrar(_ruta, dentro, t0), isFalse);
      expect(d.registrar(_ruta, fuera, t0), isFalse);
    });

    test('no repite el aviso antes de la espera', () {
      final d = DetectorDesvio();
      d
        ..registrar(_ruta, fuera, t0)
        ..registrar(_ruta, fuera, t0);
      final pronto = t0.add(const Duration(seconds: 10));
      expect(d.registrar(_ruta, fuera, pronto), isFalse);
      expect(d.registrar(_ruta, fuera, pronto), isFalse);
      final luego = t0.add(ReglasRuta.esperaEntreAvisos);
      expect(d.registrar(_ruta, fuera, luego), isTrue);
    });

    test('sin ruta nunca avisa', () {
      final d = DetectorDesvio();
      expect(d.registrar(const [], fuera, t0), isFalse);
      expect(d.registrar(const [], fuera, t0), isFalse);
    });
  });

  group('Estilo del mapa', () {
    test('automático: oscuro de noche y claro de día', () {
      expect(
        ReglasEstiloMapa.oscuro(
          EstiloMapa.automatico,
          DateTime(2026, 1, 1, 19),
        ),
        isTrue,
      );
      expect(
        ReglasEstiloMapa.oscuro(EstiloMapa.automatico, DateTime(2026, 1, 1, 5)),
        isTrue,
      );
      expect(
        ReglasEstiloMapa.oscuro(
          EstiloMapa.automatico,
          DateTime(2026, 1, 1, 12),
        ),
        isFalse,
      );
      expect(
        ReglasEstiloMapa.oscuro(EstiloMapa.claro, DateTime(2026)),
        isFalse,
      );
      expect(
        ReglasEstiloMapa.oscuro(EstiloMapa.oscuro, DateTime(2026, 1, 1, 12)),
        isTrue,
      );
    });

    test('lee lo guardado y descarta valores desconocidos', () {
      expect(ReglasEstiloMapa.leer('claro'), EstiloMapa.claro);
      expect(ReglasEstiloMapa.leer('rosa'), isNull);
      expect(ReglasEstiloMapa.leer(null), isNull);
    });

    test('la elección se guarda y se recupera', () async {
      final store = MemorySecureStore();
      final c1 = ProviderContainer(
        overrides: [secureStoreProvider.overrideWithValue(store)],
      );
      addTearDown(c1.dispose);
      await c1.read(estiloMapaProvider.notifier).elegir(EstiloMapa.claro);
      expect(c1.read(estiloMapaProvider), EstiloMapa.claro);

      final c2 = ProviderContainer(
        overrides: [secureStoreProvider.overrideWithValue(store)],
      );
      addTearDown(c2.dispose);
      expect(c2.read(estiloMapaProvider), EstiloMapa.automatico);
      await Future<void>.delayed(Duration.zero);
      expect(c2.read(estiloMapaProvider), EstiloMapa.claro);
    });
  });
}
