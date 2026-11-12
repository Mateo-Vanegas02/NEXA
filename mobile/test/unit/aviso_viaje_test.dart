import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/l10n/gen/app_localizations.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';
import 'package:nexa_mobile/features/viajes/presentation/controllers/aviso_viaje.dart';
import 'package:nexa_mobile/features/viajes/presentation/controllers/viaje_conductor_controller.dart';

void main() {
  final l = lookupAppLocalizations(const Locale('es'));
  const viaje = Servicio(
    id: 'v1',
    estado: EstadoServicio.aceptado,
    pasajero: Participante(nombre: 'Laura Díaz'),
    conductor: Participante(nombre: 'Carlos Pérez', placa: 'KZT 38F'),
    origen: 'Cl 45 # 12-30',
    destino: 'C.C. Unicentro',
  );
  PosicionViaje pos(double km, int min) => PosicionViaje(
    fase: '',
    latitud: 0,
    longitud: 0,
    distanciaRestanteKm: km,
    etaMinutos: min,
  );
  ConductorState estado(Servicio v, [PosicionViaje? p]) => ConductorState(
    aprobacion: EstadoAprobacion.aprobado,
    activo: v,
    posicion: p,
  );

  test('distancias cortas en metros y largas en km', () {
    expect(TextosAvisoViaje.distancia(0.648), '650 m');
    expect(TextosAvisoViaje.distancia(2.31), '2,3 km');
  });

  test('el conductor ve a quién recoge, la espera y a quién lleva', () {
    expect(
      TextosAvisoViaje.conductor(l, estado(viaje, pos(0.65, 3))),
      const AvisoViaje('Recoge a Laura', '3 min · 650 m'),
    );
    expect(
      TextosAvisoViaje.conductor(
        l,
        estado(viaje.copyWith(fechaLlegada: DateTime(2026))),
      ),
      const AvisoViaje('Esperando a Laura', 'Estás en el punto de recogida'),
    );
    expect(
      TextosAvisoViaje.conductor(
        l,
        estado(viaje.copyWith(estado: EstadoServicio.enCurso), pos(2.3, 0)),
      ),
      const AvisoViaje('Llevando a Laura', '1 min · 2,3 km'),
    );
    expect(
      TextosAvisoViaje.conductor(
        l,
        estado(viaje.copyWith(estado: EstadoServicio.enCurso)),
      ),
      const AvisoViaje('Llevando a Laura', 'C.C. Unicentro'),
      reason: 'sin datos del servidor, el destino',
    );
  });

  test('sin viaje no hay texto propio (queda «En línea»)', () {
    expect(
      TextosAvisoViaje.conductor(
        l,
        const ConductorState(aprobacion: EstadoAprobacion.aprobado),
      ),
      isNull,
    );
  });

  test('el pasajero ve quién va por él, cuándo llega y la placa', () {
    expect(
      TextosAvisoViaje.pasajero(l, viaje, pos(1.2, 4)),
      const AvisoViaje('Carlos va por ti', 'Llega en 4 min · KZT 38F'),
    );
    expect(
      TextosAvisoViaje.pasajero(
        l,
        viaje.copyWith(conductor: const Participante()),
        null,
      ),
      const AvisoViaje('Tu conductor va por ti', 'Cl 45 # 12-30'),
    );
    expect(
      TextosAvisoViaje.pasajero(
        l,
        viaje.copyWith(estado: EstadoServicio.enCurso),
        null,
      ),
      isNull,
    );
  });
}
