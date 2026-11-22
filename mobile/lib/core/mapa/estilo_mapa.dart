import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../providers.dart';

/// Estilo del mapa que elige cada persona (rediseño 2026), independiente del
/// tema de la app: el conductor pidió poder ponerlo claro a pleno sol.
enum EstiloMapa { oscuro, claro, automatico }

abstract final class ReglasEstiloMapa {
  static const clave = 'nexa.mapa.estilo';

  /// En automático el mapa es oscuro de 6 p. m. a 6 a. m.
  static const horaOscuro = 18;
  static const horaClaro = 6;

  static bool oscuro(EstiloMapa estilo, DateTime ahora) => switch (estilo) {
    EstiloMapa.oscuro => true,
    EstiloMapa.claro => false,
    EstiloMapa.automatico => ahora.hour < horaClaro || ahora.hour >= horaOscuro,
  };

  static String url({required bool oscuro}) =>
      oscuro ? Env.estiloMapaOscuro : Env.estiloMapaClaro;

  static EstiloMapa? leer(String? valor) {
    for (final e in EstiloMapa.values) {
      if (e.name == valor) return e;
    }
    return null;
  }
}

/// La elección se guarda en el teléfono; por defecto, automático.
class EstiloMapaController extends Notifier<EstiloMapa> {
  @override
  EstiloMapa build() {
    unawaited(_cargar());
    return EstiloMapa.automatico;
  }

  Future<void> _cargar() async {
    try {
      final guardado = ReglasEstiloMapa.leer(
        await ref.read(secureStoreProvider).read(ReglasEstiloMapa.clave),
      );
      if (guardado != null) state = guardado;
    } on Object {
      // Sin almacenamiento (o ya se cerró): se queda el automático.
    }
  }

  Future<void> elegir(EstiloMapa estilo) async {
    state = estilo;
    try {
      await ref
          .read(secureStoreProvider)
          .write(ReglasEstiloMapa.clave, estilo.name);
    } on Object {
      // Sin almacenamiento: vale para esta sesión.
    }
  }
}

final estiloMapaProvider = NotifierProvider<EstiloMapaController, EstiloMapa>(
  EstiloMapaController.new,
);
