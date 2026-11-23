import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/features/viajes/domain/agrupar_viajes.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';

Servicio _viaje(
  String id,
  String destino, {
  Coordenada? punto,
  EstadoServicio estado = EstadoServicio.finalizado,
}) =>
    Servicio(id: id, estado: estado, destino: destino, ubicacionDestino: punto);

void main() {
  const plaza = Coordenada(latitud: 10.4201, longitud: -75.5202);
  const plazaOtraPuerta = Coordenada(latitud: 10.4203, longitud: -75.5199);
  const uni = Coordenada(latitud: 10.39, longitud: -75.48);

  test('sin repetir destino y en el orden del historial', () {
    final r = destinosRecientes([
      _viaje('1', 'C.C. Plaza', punto: plaza),
      _viaje('2', 'C.C. Plaza (entrada 2)', punto: plazaOtraPuerta),
      _viaje('3', 'Universidad', punto: uni),
    ]);
    expect(r.map((s) => s.id), ['1', '3']);
  });

  test('omite el viaje activo y corta en el máximo', () {
    final r = destinosRecientes([
      _viaje('a', 'Activo', punto: uni, estado: EstadoServicio.enCurso),
      for (var i = 0; i < 5; i++)
        _viaje(
          'v$i',
          'Destino $i',
          punto: Coordenada(latitud: 10.3 + i / 100, longitud: -75.5),
        ),
    ]);
    expect(r.map((s) => s.id), ['v0', 'v1', 'v2']);
  });

  test('sin coordenadas agrupa por nombre', () {
    final r = destinosRecientes([
      _viaje('1', 'Bocagrande'),
      _viaje('2', ' bocagrande '),
      _viaje('3', ''),
    ]);
    expect(r.map((s) => s.id), ['1']);
  });

  test('omite los destinos fuera de Cartagena (no se pueden pedir)', () {
    final r = destinosRecientes([
      _viaje(
        't',
        'Turbaco',
        punto: const Coordenada(latitud: 10.3325, longitud: -75.4142),
      ),
      _viaje('p', 'C.C. Plaza', punto: plaza),
    ]);
    expect(r.map((s) => s.id), ['p']);
  });
}
