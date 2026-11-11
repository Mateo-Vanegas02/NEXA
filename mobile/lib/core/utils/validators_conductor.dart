import '../l10n/gen/app_localizations.dart';
import 'validators.dart';

/// Validadores del registro de conductor. Reflejan `ConductorRegistroRequest`
/// del backend; el servidor sigue siendo la autoridad.

final _licenciaRegExp = RegExp(r'^\d{6,15}$');
final _tarjetaRegExp = RegExp(r'^\d{8,15}$');
final _soatRegExp = RegExp(r'^\d{12}$');
final _tecnoRegExp = RegExp(r'^\d{6,15}$');
final _placaRegExp = RegExp(r'^[A-Za-z]{3}[A-Za-z0-9]{3}$');
final _marcaRegExp = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s]+$');
final _modeloRegExp = RegExp(r'^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s-]+$');
final _colorRegExp = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');

String? _patron(
  AppLocalizations l,
  String? v,
  RegExp re,
  String mensaje, {
  int max = 1000,
}) {
  final r = validarRequerido(l, v);
  if (r != null) return r;
  final s = v!.trim();
  return (s.length <= max && re.hasMatch(s)) ? null : mensaje;
}

String? validarLicencia(AppLocalizations l, String? v) =>
    _patron(l, v, _licenciaRegExp, l.licenciaInvalida);

String? validarTarjetaPropiedad(AppLocalizations l, String? v) =>
    _patron(l, v, _tarjetaRegExp, l.tarjetaInvalida);

String? validarSoat(AppLocalizations l, String? v) =>
    _patron(l, v, _soatRegExp, l.soatInvalido);

String? validarTecnomecanica(AppLocalizations l, String? v) =>
    _patron(l, v, _tecnoRegExp, l.tecnoInvalida);

String? validarPlaca(AppLocalizations l, String? v) =>
    _patron(l, v, _placaRegExp, l.placaInvalida);

String? validarMarca(AppLocalizations l, String? v) =>
    _patron(l, v, _marcaRegExp, l.textoInvalido, max: 50);

String? validarModelo(AppLocalizations l, String? v) =>
    _patron(l, v, _modeloRegExp, l.textoInvalido, max: 50);

String? validarColor(AppLocalizations l, String? v) =>
    _patron(l, v, _colorRegExp, l.textoInvalido, max: 30);
