import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacén de pares clave/valor sensibles (token JWT, nivel visto).
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureStore implements SecureStore {
  const FlutterSecureStore([this._s = const FlutterSecureStorage()]);
  final FlutterSecureStorage _s;

  @override
  Future<String?> read(String key) => _s.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _s.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _s.delete(key: key);
}

/// Implementación en memoria para tests y modo mock.
class MemorySecureStore implements SecureStore {
  final Map<String, String> _m = {};
  @override
  Future<String?> read(String key) async => _m[key];
  @override
  Future<void> write(String key, String value) async => _m[key] = value;
  @override
  Future<void> delete(String key) async => _m.remove(key);
}

class TokenStorage {
  TokenStorage(this._store);
  final SecureStore _store;
  static const _kToken = 'jwt';

  Future<String?> leer() => _store.read(_kToken);
  Future<void> guardar(String token) => _store.write(_kToken, token);
  Future<void> borrar() => _store.delete(_kToken);
}
