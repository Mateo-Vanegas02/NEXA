import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'stomp.dart';

/// Conexión en vivo con el servidor (`/ws-app`, STOMP autenticado con el JWT;
/// rediseño 2026). Mantiene las suscripciones pedidas y las repite al
/// reconectar. Si no conecta, la app sigue con el sondeo: esto solo adelanta.
class CanalTiempoReal {
  CanalTiempoReal({
    required this.url,
    required this.token,
    Future<WebSocket> Function(String url, Map<String, dynamic> headers)?
    conectar,
  }) : _conectar =
           conectar ??
           ((u, h) => WebSocket.connect(u, headers: h)
               .timeout(const Duration(seconds: 10)));

  /// p. ej. `wss://servidor/ws-app`.
  final String url;
  final String? Function() token;
  final Future<WebSocket> Function(String, Map<String, dynamic>) _conectar;

  final _subs = <String, (String, void Function(Object?))>{};
  WebSocket? _ws;
  bool _conectado = false;
  bool _cerrado = false;
  int _siguiente = 0;
  int _intentos = 0;
  Timer? _reintento;

  bool get conectado => _conectado;

  /// Se suscribe a [destino]; [alLlegar] recibe el cuerpo JSON ya decodificado.
  /// Devuelve la función que cancela la suscripción.
  void Function() suscribir(String destino, void Function(Object?) alLlegar) {
    final id = 'sub-${_siguiente++}';
    _subs[id] = (destino, alLlegar);
    if (_conectado) _enviar(FrameStomp.subscribe(id, destino));
    _asegurar();
    return () {
      if (_subs.remove(id) != null && _conectado) {
        _enviar(FrameStomp.unsubscribe(id));
      }
      if (_subs.isEmpty) _soltar();
    };
  }

  void cerrar() {
    _cerrado = true;
    _subs.clear();
    _soltar();
  }

  void _asegurar() {
    if (_cerrado || _ws != null || _reintento != null) return;
    unawaited(_abrir());
  }

  Future<void> _abrir() async {
    final t = token();
    if (t == null) return;
    try {
      final ws = await _conectar(url, {'Authorization': 'Bearer $t'});
      if (_cerrado || _subs.isEmpty) {
        await ws.close();
        return;
      }
      _ws = ws..pingInterval = const Duration(seconds: 20);
      ws.listen(
        (d) => _recibir(d is String ? d : utf8.decode(d as List<int>)),
        onDone: _perdida,
        onError: (Object _) => _perdida(),
        cancelOnError: true,
      );
      _enviar(FrameStomp.connect(host: Uri.parse(url).host, token: t));
    } on Object {
      _perdida();
    }
  }

  void _recibir(String datos) {
    for (final f in FrameStomp.leer(datos)) {
      switch (f.comando) {
        case 'CONNECTED':
          _conectado = true;
          _intentos = 0;
          _subs.forEach((id, s) => _enviar(FrameStomp.subscribe(id, s.$1)));
        case 'MESSAGE':
          final s = _subs[f.cabeceras['subscription']];
          if (s == null) continue;
          Object? cuerpo;
          try {
            cuerpo = jsonDecode(f.cuerpo);
          } on FormatException {
            continue;
          }
          s.$2(cuerpo);
        case 'ERROR':
          // Token vencido o suscripción rechazada: se cierra y se reintenta.
          unawaited(_ws?.close());
      }
    }
  }

  void _enviar(FrameStomp f) => _ws?.add(f.codificar());

  void _perdida() {
    _conectado = false;
    _ws = null;
    if (_cerrado || _subs.isEmpty) return;
    // 2, 4, 8 … hasta 60 s entre intentos.
    final espera = Duration(seconds: (2 << _intentos.clamp(0, 5)).clamp(2, 60));
    _intentos++;
    _reintento = Timer(espera, () {
      _reintento = null;
      _asegurar();
    });
  }

  void _soltar() {
    _reintento?.cancel();
    _reintento = null;
    _conectado = false;
    final ws = _ws;
    _ws = null;
    unawaited(ws?.close());
  }
}

/// `https://servidor` → `wss://servidor/ws-app` (y http → ws).
String urlTiempoReal(String apiBase) {
  final u = Uri.parse(apiBase);
  return u
      .replace(
        scheme: u.scheme == 'https' ? 'wss' : 'ws',
        path: '/ws-app',
        query: null,
      )
      .toString();
}
