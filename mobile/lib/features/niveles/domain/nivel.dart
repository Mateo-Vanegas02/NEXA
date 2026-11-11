import 'package:freezed_annotation/freezed_annotation.dart';

part 'nivel.freezed.dart';
part 'nivel.g.dart';

@freezed
abstract class Beneficio with _$Beneficio {
  const factory Beneficio({
    required String clave,
    required String titulo,
    @Default('') String descripcion,
    @Default(0) int nivelRequerido,
    @Default(false) bool activo,
  }) = _Beneficio;

  factory Beneficio.fromJson(Map<String, dynamic> json) =>
      _$BeneficioFromJson(json);
}

/// Un escalón de la escalera de niveles (modelo v2.3: niveles numerados desde 1,
/// sin nombres como "Plata" u "Oro").
@freezed
abstract class NivelInfo with _$NivelInfo {
  const NivelInfo._();

  const factory NivelInfo({
    required int nivel,
    required int xp,

    /// Descuento en los viajes del pasajero (fracción: 0,03 = 3 %). Solo pasajeros.
    double? descuento,
    @Default(<Beneficio>[]) List<Beneficio> beneficios,

    /// Comisión del conductor en este nivel (fracción). Solo conductores.
    double? comision,
  }) = _NivelInfo;

  factory NivelInfo.fromJson(Map<String, dynamic> json) =>
      _$NivelInfoFromJson(json);

  /// Texto del nivel para frases como «Nivel 3».
  String get nombre => '$nivel';
}

@freezed
abstract class Requisito with _$Requisito {
  const factory Requisito({
    required String texto,
    @Default(false) bool cumplido,
  }) = _Requisito;

  factory Requisito.fromJson(Map<String, dynamic> json) =>
      _$RequisitoFromJson(json);
}

@freezed
abstract class ConductorInfo with _$ConductorInfo {
  const factory ConductorInfo({
    required double comisionActual,
    double? comisionSiguiente,
    double? calificacion,
    @Default(0) double aceptacion,
    @Default(0) double cancelacion,
    @Default(<Requisito>[]) List<Requisito> requisitosSiguiente,
    @Default(false) bool bloqueadoPorCalidad,
  }) = _ConductorInfo;

  factory ConductorInfo.fromJson(Map<String, dynamic> json) =>
      _$ConductorInfoFromJson(json);
}

/// Respuesta de `GET /api/niveles/me` (modelo v2.3).
///
/// Pasajero: niveles desde 1 y sin techo; descuento de `min(1 % · nivel, 5 %)`
/// desde el nivel 2 y prioridad de recogida de 15/25/35/45 s (niveles 2–5).
/// Conductor: niveles 1–5 por XP de 90 días más requisitos de calidad; la
/// comisión baja de 20 % a 15 %.
@freezed
abstract class NivelEstado with _$NivelEstado {
  const NivelEstado._();

  const factory NivelEstado({
    required String usuarioId,
    required String rol,
    required int nivel,
    @Default(0) int xpActual,
    @Default(0) int xpNivelActual,
    int? xpSiguienteNivel,
    @Default(0) int xpFaltante,
    @Default(0) double progreso,

    /// Descuento actual del pasajero (fracción). 0 para conductores.
    @Default(0) double descuento,

    /// Segundos de ventaja de recogida que da el nivel (pasajero).
    @Default(0) int prioridadSegundos,
    @Default(<NivelInfo>[]) List<NivelInfo> niveles,
    @Default(<Beneficio>[]) List<Beneficio> beneficiosActivos,
    ConductorInfo? conductor,
  }) = _NivelEstado;

  factory NivelEstado.fromJson(Map<String, dynamic> json) =>
      _$NivelEstadoFromJson(json);

  bool get esNivelMaximo => xpSiguienteNivel == null;

  /// Texto del nivel actual para frases como «Nivel 3».
  String get nombre => '$nivel';

  /// Texto del nivel siguiente (`null` en el máximo).
  String? get nombreSiguiente => esNivelMaximo ? null : '${nivel + 1}';
}
