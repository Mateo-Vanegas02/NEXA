import 'dart:convert';

/// Lee el payload de un JWT (sin validar firma: eso lo hace el backend).
Map<String, dynamic> decodificarJwt(String token) {
  final partes = token.split('.');
  if (partes.length != 3) throw const FormatException('JWT inválido');
  final json = utf8.decode(base64Url.decode(base64Url.normalize(partes[1])));
  return jsonDecode(json) as Map<String, dynamic>;
}
