import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'core/notificaciones/canales_notificacion.dart';
import 'core/notificaciones/notificaciones_locales.dart';
import 'core/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO');
  final notificaciones = await _prepararNotificaciones();
  runApp(
    ProviderScope(
      overrides: [notificacionesProvider.overrideWithValue(notificaciones)],
      child: const NexaApp(),
    ),
  );
}

/// Crea los canales de notificación al arrancar (no pide permisos). Si algo
/// falla la app abre igual, sin notificaciones del teléfono.
Future<NotificacionesLocales> _prepararNotificaciones() async {
  final notificaciones = NotificacionesAndroid();
  try {
    await notificaciones.inicializar(
      canalesNexa(lookupAppLocalizations(const Locale('es'))),
    );
    return notificaciones;
  } catch (e) {
    debugPrint('No se pudieron preparar las notificaciones: $e');
    return const NotificacionesInactivas();
  }
}
