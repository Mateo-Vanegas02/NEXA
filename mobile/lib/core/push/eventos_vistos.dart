import 'dart:convert';

import '../network/token_storage.dart';

/// Ids de push procesados, compartidos por la app y el receptor de segundo plano.
/// Se conservan 48 horas para que un toque tras reiniciar no repita una acción.
class EventosVistos {
  EventosVistos(this._store, {DateTime Function()? reloj})
    : _reloj = reloj ?? DateTime.now;

  static const vigencia = Duration(hours: 48);
  static const maximo = 256;
  static const _clave = 'push_eventos_vistos';
  final SecureStore _store;
  final DateTime Function() _reloj;
  Future<void> _cola = Future<void>.value();

  /// Reserva el id antes de producir efectos. Devuelve false si ya se procesó.
  Future<bool> reservar(String id) {
    final resultado = _cola.then((_) async {
      if (id.isEmpty) return false;
      final ahora = _reloj().millisecondsSinceEpoch;
      final limite = ahora - vigencia.inMilliseconds;
      final vistos = <String, int>{};
      try {
        final crudo = await _store.read(_clave);
        if (crudo != null) {
          for (final entrada
              in (jsonDecode(crudo) as Map<String, dynamic>).entries) {
            final fecha = entrada.value;
            if (fecha is int && fecha > limite && fecha <= ahora) {
              vistos[entrada.key] = fecha;
            }
          }
        }
      } on Object {
        // Un almacén ilegible no impide que llegue un aviso nuevo.
      }
      final nuevo = !vistos.containsKey(id);
      if (nuevo) vistos[id] = ahora;
      final recientes = vistos.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      await _store.write(
        _clave,
        jsonEncode({for (final e in recientes.take(maximo)) e.key: e.value}),
      );
      return nuevo;
    });
    _cola = resultado.then<void>((_) {}, onError: (Object _) {});
    return resultado;
  }

  Future<void> vaciar() => _store.delete(_clave);
}
