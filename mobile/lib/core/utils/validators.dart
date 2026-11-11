import '../l10n/gen/app_localizations.dart';

/// Validadores de formularios. Reflejan las reglas del backend
/// (`ConductorRegistroRequest` / registro de pasajero): el servidor sigue siendo
/// la autoridad, esto solo evita viajes de red innecesarios.

final emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _nombreRegExp = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$');
final _telefonoRegExp = RegExp(r'^3\d{9}$');

String? validarRequerido(AppLocalizations l, String? v) =>
    (v == null || v.trim().isEmpty) ? l.campoRequerido : null;

String? validarEmail(AppLocalizations l, String? v) {
  final r = validarRequerido(l, v);
  if (r != null) return r;
  final s = v!.trim();
  return (s.length <= 100 && emailRegExp.hasMatch(s)) ? null : l.emailInvalido;
}

String? validarNombre(AppLocalizations l, String? v) {
  final r = validarRequerido(l, v);
  if (r != null) return r;
  final s = v!.trim();
  return (s.length >= 3 && s.length <= 100 && _nombreRegExp.hasMatch(s))
      ? null
      : l.nombreInvalido;
}

String? validarTelefono(AppLocalizations l, String? v) {
  final r = validarRequerido(l, v);
  if (r != null) return r;
  return _telefonoRegExp.hasMatch(v!.trim()) ? null : l.telefonoInvalido;
}

/// Mínimo 8 caracteres con mayúscula, minúscula y número.
String? validarPasswordNueva(AppLocalizations l, String? v) {
  final r = validarRequerido(l, v);
  if (r != null) return r;
  if (v!.length < 8) return l.passwordCorta;
  final fuerte =
      RegExp('[a-z]').hasMatch(v) &&
      RegExp('[A-Z]').hasMatch(v) &&
      RegExp(r'\d').hasMatch(v);
  return fuerte ? null : l.passwordDebil;
}

String? validarConfirmacion(AppLocalizations l, String? v, String original) =>
    v == original ? null : l.passwordNoCoincide;
