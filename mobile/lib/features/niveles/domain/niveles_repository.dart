import 'nivel.dart';

abstract interface class NivelesRepository {
  /// `rol`: `pasajero` o `conductor`.
  Future<NivelEstado> me(String rol);
}
