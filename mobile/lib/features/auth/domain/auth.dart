import '../../../core/utils/selector_imagen.dart';
import '../../viajes/domain/servicio.dart';

enum Rol {
  pasajero,
  conductor,

  /// Administrador: en la app solo ve el panel de satisfacción (redes neuronales).
  admin;

  static Rol? desdeAuthorities(Iterable<Object?> roles) {
    for (final r in roles) {
      final s = r.toString().toUpperCase();
      if (s.contains('CONDUCTOR')) return Rol.conductor;
      if (s.contains('PASAJERO')) return Rol.pasajero;
      if (s.contains('ADMIN')) return Rol.admin;
    }
    return null;
  }
}

class Sesion {
  const Sesion({
    required this.token,
    required this.rol,
    required this.email,
    this.userId,
  });

  final String token;
  final Rol rol;
  final String email;
  final String? userId;
}

class RegistroPasajero {
  const RegistroPasajero({
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.password,
  });

  final String nombre;
  final String email;
  final String telefono;
  final String password;
}

/// Solicitud de registro de un conductor: datos, vehículo, documentos y sus fotos.
/// Queda PENDIENTE hasta que un administrador la apruebe; no inicia sesión.
class RegistroConductor {
  const RegistroConductor({
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.password,
    required this.licencia,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.color,
    required this.tarjetaPropiedad,
    required this.soat,
    required this.tecnomecanica,
    required this.fotoLicencia,
    required this.fotoTarjetaPropiedad,
    required this.fotoSoat,
    required this.fotoTecnomecanica,
  });

  final String nombre;
  final String email;
  final String telefono;
  final String password;
  final String licencia;
  final String placa;
  final String marca;
  final String modelo;
  final String color;
  final String tarjetaPropiedad;
  final String soat;
  final String tecnomecanica;
  final ArchivoImagen fotoLicencia;
  final ArchivoImagen fotoTarjetaPropiedad;
  final ArchivoImagen fotoSoat;
  final ArchivoImagen fotoTecnomecanica;
}

abstract interface class AuthRepository {
  Future<Sesion> login(String email, String password, {Rol? rol});

  /// Crea una cuenta de pasajero y deja la sesión iniciada.
  Future<Sesion> registrarPasajero(RegistroPasajero datos);

  /// Envía la solicitud de un conductor (datos + 4 fotos). No inicia sesión:
  /// el administrador debe aprobarla antes.
  Future<void> registrarConductor(RegistroConductor datos);

  /// Recupera la sesión guardada (si el token sigue vigente).
  Future<Sesion?> restaurar();

  Future<void> logout();

  /// Estado de aprobación del admin para conductores.
  Future<EstadoAprobacion> estadoAprobacion();
}
