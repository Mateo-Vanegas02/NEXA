import '../../../core/errors/app_exception.dart';
import '../../../core/network/token_storage.dart';
import '../../viajes/domain/servicio.dart';
import '../domain/auth.dart';

/// Repositorio simulado. Reglas de demo (no hay credenciales reales):
/// - correo que contiene "conductor" → conductor aprobado;
/// - correo que contiene "pendiente" → conductor pendiente de aprobación;
/// - correo que contiene "admin" → administrador;
/// - cualquier otro → pasajero. La contraseña debe tener al menos 6 caracteres.
/// Las cuentas creadas con el registro exigen su propia contraseña.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._tokens);

  final TokenStorage _tokens;
  Sesion? _actual;

  /// Cuentas creadas con el registro del mock (correo → contraseña).
  final Map<String, String> _registrados = {};

  /// Conductores registrados en el mock: quedan pendientes de aprobación.
  final Map<String, String> _conductoresPendientes = {};

  @override
  Future<Sesion> login(String email, String password, {Rol? rol}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final e = email.trim().toLowerCase();
    if (_conductoresPendientes[e] == password) {
      throw const AppException(
        ErrorKind.prohibido,
        'Tu cuenta está pendiente de aprobación. Podrás iniciar sesión cuando te aprueben.',
        statusCode: 403,
      );
    }
    final clave = _registrados[e];
    if (clave != null ? clave != password : password.length < 6) {
      throw const AppException(
        ErrorKind.noAutenticado,
        'Credenciales inválidas.',
        statusCode: 401,
      );
    }
    final rolElegido =
        rol ??
        (e.contains('admin')
            ? Rol.admin
            : e.contains('conductor') || e.contains('pendiente')
            ? Rol.conductor
            : Rol.pasajero);
    return _crear(e, rolElegido);
  }

  @override
  Future<Sesion> registrarPasajero(RegistroPasajero datos) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final email = datos.email.trim().toLowerCase();
    if (_registrados.containsKey(email)) {
      throw const AppException(
        ErrorKind.validacion,
        'Ya existe una cuenta con ese correo.',
        statusCode: 400,
      );
    }
    _registrados[email] = datos.password;
    return _crear(email, Rol.pasajero);
  }

  @override
  Future<void> registrarConductor(RegistroConductor datos) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final email = datos.email.trim().toLowerCase();
    if (_registrados.containsKey(email) ||
        _conductoresPendientes.containsKey(email)) {
      throw const AppException(
        ErrorKind.validacion,
        'Ya existe una cuenta con ese correo.',
        statusCode: 409,
      );
    }
    _conductoresPendientes[email] = datos.password;
  }

  Future<Sesion> _crear(String email, Rol rol) async {
    final s = Sesion(
      token: 'mock-token-${rol.name}:$email',
      rol: rol,
      email: email,
      userId: 'mock-${rol.name}',
    );
    _actual = s;
    await _tokens.guardar(s.token);
    return s;
  }

  @override
  Future<Sesion?> restaurar() async {
    final t = await _tokens.leer();
    if (t == null || !t.startsWith('mock-token-')) return null;
    final resto = t.substring('mock-token-'.length);
    final i = resto.indexOf(':');
    if (i < 0) return null;
    final rol = Rol.values.byName(resto.substring(0, i));
    return _actual = Sesion(
      token: t,
      rol: rol,
      email: resto.substring(i + 1),
      userId: 'mock-${rol.name}',
    );
  }

  @override
  Future<void> logout() async {
    _actual = null;
    await _tokens.borrar();
  }

  @override
  Future<EstadoAprobacion> estadoAprobacion() async =>
      (_actual?.email.contains('pendiente') ?? false)
      ? EstadoAprobacion.pendiente
      : EstadoAprobacion.aprobado;
}
