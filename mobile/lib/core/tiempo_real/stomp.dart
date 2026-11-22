/// Lo mínimo de STOMP 1.2 que usa la app: armar CONNECT y SUBSCRIBE y leer los
/// MESSAGE del servidor (Spring, broker simple). Sin dependencias.
class FrameStomp {
  const FrameStomp(this.comando, this.cabeceras, this.cuerpo);

  final String comando;
  final Map<String, String> cabeceras;
  final String cuerpo;

  /// Texto del frame, terminado en el carácter nulo.
  String codificar() {
    final b = StringBuffer(comando)..write('\n');
    cabeceras.forEach((k, v) => b.write('${_escapar(k)}:${_escapar(v)}\n'));
    b
      ..write('\n')
      ..write(cuerpo)
      ..write('\u0000');
    return b.toString();
  }

  static String _escapar(String s) => s
      .replaceAll(r'\', r'\\')
      .replaceAll('\n', r'\n')
      .replaceAll(':', r'\c')
      .replaceAll('\r', r'\r');

  static String _desescapar(String s) {
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c != r'\' || i + 1 >= s.length) {
        b.write(c);
        continue;
      }
      i++;
      b.write(switch (s[i]) {
        'n' => '\n',
        'c' => ':',
        'r' => '\r',
        _ => s[i],
      });
    }
    return b.toString();
  }

  /// Lee los frames de un mensaje del WebSocket (puede traer varios o solo
  /// latidos `\n`). Lo que no se entiende se ignora.
  static List<FrameStomp> leer(String datos) {
    final frames = <FrameStomp>[];
    for (final crudo in datos.split('\u0000')) {
      final texto = crudo.replaceAll('\r\n', '\n').replaceFirst(RegExp(r'^\n+'), '');
      if (texto.isEmpty) continue;
      final fin = texto.indexOf('\n\n');
      final cabeza = fin < 0 ? texto : texto.substring(0, fin);
      final cuerpo = fin < 0 ? '' : texto.substring(fin + 2);
      final lineas = cabeza.split('\n');
      final cabeceras = <String, String>{};
      for (final l in lineas.skip(1)) {
        final dos = l.indexOf(':');
        if (dos <= 0) continue;
        // En STOMP gana la primera aparición de una cabecera.
        cabeceras.putIfAbsent(
          _desescapar(l.substring(0, dos)),
          () => _desescapar(l.substring(dos + 1)),
        );
      }
      frames.add(FrameStomp(lineas.first.trim(), cabeceras, cuerpo));
    }
    return frames;
  }

  static FrameStomp connect({required String host, String? token}) =>
      FrameStomp('CONNECT', {
        'accept-version': '1.2',
        'host': host,
        'heart-beat': '0,0',
        if (token != null) 'Authorization': 'Bearer $token',
      }, '');

  static FrameStomp subscribe(String id, String destino) =>
      FrameStomp('SUBSCRIBE', {'id': id, 'destination': destino}, '');

  static FrameStomp unsubscribe(String id) =>
      FrameStomp('UNSUBSCRIBE', {'id': id}, '');
}
