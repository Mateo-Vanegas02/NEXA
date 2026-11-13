import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ¿Hay señal con el servidor? Se deduce de las propias peticiones: una sin
/// respuesta la pone en «sin conexión» y cualquier respuesta (aunque sea un
/// error del servidor) la devuelve a «con conexión». Sin sondeos extra.
class EstadoRed {
  const EstadoRed({this.conRed = true, this.sinRedDesde, this.ultimoDato});

  final bool conRed;

  /// Desde cuándo no hay señal (null con señal).
  final DateTime? sinRedDesde;

  /// Hora de la última respuesta del servidor.
  final DateTime? ultimoDato;
}

class ConexionController extends Notifier<EstadoRed> {
  @override
  EstadoRed build() => const EstadoRed();

  /// Lo llama el cliente HTTP tras cada petición.
  void reportar({required bool hayRed}) {
    final ahora = DateTime.now();
    if (hayRed) {
      if (state.conRed && state.ultimoDato != null &&
          ahora.difference(state.ultimoDato!) < const Duration(seconds: 5)) {
        return; // Sin cambios visibles: no repinta en cada petición.
      }
      state = EstadoRed(ultimoDato: ahora);
    } else if (state.conRed) {
      state = EstadoRed(
        conRed: false,
        sinRedDesde: ahora,
        ultimoDato: state.ultimoDato,
      );
    }
  }
}

final conexionProvider = NotifierProvider<ConexionController, EstadoRed>(
  ConexionController.new,
);
