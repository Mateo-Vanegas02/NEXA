import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';

void main() {
  Map<String, dynamic> viaje(Object? idPasajero, {String? idString}) => {
    'id': 'v1',
    'estado': 'SOLICITADO',
    'origen': 'A',
    'destino': 'B',
    'pasajero': {'id': idPasajero, 'idString': ?idString, 'nombre': 'Laura'},
  };

  test('lee el id del pasajero como texto', () {
    final s = Servicio.fromJson(viaje('6a0a920b38c63b560305f1dd'));
    expect(s.pasajero?.id, '6a0a920b38c63b560305f1dd');
  });

  test('un id como objeto (servidor anterior) no impide leer el viaje', () {
    final objeto = {
      'timestamp': 1778000000,
      'date': '2026-11-12T20:17:51.000+00:00',
    };
    final s = Servicio.fromJson(viaje(objeto));
    expect(s.id, 'v1');
    expect(s.estado, EstadoServicio.solicitado);
    expect(s.pasajero?.id, isNull);
    expect(s.pasajero?.nombre, 'Laura');
  });

  test('si el id viene como objeto usa idString', () {
    final s = Servicio.fromJson(
      viaje({'timestamp': 1}, idString: '6a0a920b38c63b560305f1dd'),
    );
    expect(s.pasajero?.id, '6a0a920b38c63b560305f1dd');
  });
}
