import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Acciones que salen de la app (teléfono, SMS, compartir). Se inyecta por
/// provider para poder sustituirla en los tests.
class AccionesExternas {
  const AccionesExternas();

  Future<bool> llamar(String telefono) =>
      launchUrl(Uri(scheme: 'tel', path: telefono));

  Future<bool> enviarSms(String telefono) =>
      launchUrl(Uri(scheme: 'sms', path: telefono));

  Future<void> compartir(String texto) =>
      SharePlus.instance.share(ShareParams(text: texto));
}

final accionesExternasProvider = Provider<AccionesExternas>(
  (ref) => const AccionesExternas(),
);

/// Línea nacional de emergencias de Colombia.
const String kLineaEmergencias = '123';
