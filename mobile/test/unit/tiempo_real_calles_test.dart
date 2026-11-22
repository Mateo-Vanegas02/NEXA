import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexa_mobile/core/mapa/maniobra.dart';
import 'package:nexa_mobile/core/tiempo_real/canal_tiempo_real.dart';
import 'package:nexa_mobile/core/tiempo_real/stomp.dart';
import 'package:nexa_mobile/features/viajes/domain/opcion_ruta.dart';
import 'package:nexa_mobile/features/viajes/domain/paso_ruta.dart';
import 'package:nexa_mobile/features/viajes/domain/zonas_documentos.dart';

void main() {
  group('STOMP', () {
    test('arma el CONNECT con el token y el SUBSCRIBE', () {
      final c = FrameStomp.connect(host: 'nexa.co', token: 'abc').codificar();
      expect(c, startsWith('CONNECT\n'));
      expect(c, contains('Authorization:Bearer abc'));
      expect(c, endsWith('\n\n\u0000'));
      expect(
        FrameStomp.subscribe('sub-0', '/topic/pasajero/p1').codificar(),
        'SUBSCRIBE\nid:sub-0\ndestination:/topic/pasajero/p1\n\n\u0000',
      );
    });

    test('lee varios frames, latidos y cabeceras escapadas', () {
      final datos =
          '\nCONNECTED\nversion:1.2\n\n\u0000'
          'MESSAGE\nsubscription:sub-1\ndestination:/topic/x\\cy\n'
          'content-type:application/json\n\n{"a":1}\u0000\n';
      final f = FrameStomp.leer(datos);
      expect(f.map((e) => e.comando), ['CONNECTED', 'MESSAGE']);
      expect(f[1].cabeceras['subscription'], 'sub-1');
      expect(f[1].cabeceras['destination'], '/topic/x:y');
      expect(f[1].cuerpo, '{"a":1}');
      expect(FrameStomp.leer('\n'), isEmpty);
    });

    test('la URL en vivo sale de la del servidor', () {
      expect(urlTiempoReal('https://18-227-59-40.sslip.io'),
          'wss://18-227-59-40.sslip.io/ws-app');
      expect(urlTiempoReal('http://10.0.2.2:8080'), 'ws://10.0.2.2:8080/ws-app');
    });
  });

  group('Calles en la maniobra', () {
    // Recto al este y luego giro al norte en (10.40, -75.49).
    const ruta = [
      LatLng(10.40, -75.50),
      LatLng(10.40, -75.49),
      LatLng(10.41, -75.49),
    ];
    const pasos = [
      PasoRuta(latitud: 10.40, longitud: -75.50, maniobra: 'depart', calle: 'Carrera 2'),
      PasoRuta(latitud: 10.40002, longitud: -75.49001, maniobra: 'turn', modificador: 'left', calle: 'Calle 30'),
      PasoRuta(latitud: 10.41, longitud: -75.49, maniobra: 'arrive'),
    ];

    test('la maniobra trae su punto y la calle sale del paso más cercano', () {
      final m = ReglasManiobra.siguiente(ruta, const LatLng(10.40, -75.499))!;
      expect(m.giro, Giro.izquierda);
      expect(m.punto, ruta[1]);
      expect(calleDeManiobra(pasos, m.punto!), 'Calle 30');
    });

    test('sin un paso cerca no hay calle', () {
      expect(calleDeManiobra(pasos, const LatLng(10.45, -75.45)), isNull);
      expect(calleDeManiobra(const [], ruta[1]), isNull);
    });

    test('las rutas en vivo y los documentos se leen del servidor', () {
      final o = OpcionRuta.fromJson({
        'indice': 0,
        'geometria': 'abc',
        'etiqueta': 'RAPIDA',
        'pasos': [
          {'latitud': 1, 'longitud': 2, 'maniobra': 'turn', 'calle': ' Calle 5 '},
        ],
      });
      expect(o.pasos.single.calle, 'Calle 5');
      final d = MiDocumento.fromJson({
        'id': 'x',
        'tipo': 'SOAT',
        'venceEl': '2026-12-01',
        'vigencia': 'POR_VENCER',
        'diasRestantes': 9,
      });
      expect(d.vigencia, Vigencia.porVencer);
      expect(d.venceEl, DateTime(2026, 12, 1));
      expect(leerVigencia('raro'), Vigencia.sinFecha);
    });
  });
}
