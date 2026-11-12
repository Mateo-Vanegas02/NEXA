import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'core/notificaciones/canales_notificacion.dart';
import 'core/notificaciones/notificaciones_locales.dart';
import 'core/providers.dart';
import 'core/push/aviso_push.dart';
import 'core/push/push_firebase.dart';
import 'core/push/servicio_push.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO');
  final tocados = StreamController<AvisoPush>.broadcast();
  final notificaciones = await _prepararNotificaciones(tocados);
  final push = await _prepararPush(notificaciones, tocados.stream);
  runApp(
    ProviderScope(
      overrides: [
        notificacionesProvider.overrideWithValue(notificaciones),
        servicioPushProvider.overrideWithValue(push),
      ],
      child: const NexaApp(),
    ),
  );
}

/// Crea los canales de notificación al arrancar (no pide permisos). Si algo
/// falla la app abre igual, sin notificaciones del teléfono.
Future<NotificacionesLocales> _prepararNotificaciones(
  StreamController<AvisoPush> tocados,
) async {
  final notificaciones = NotificacionesAndroid(
    alTocar: (r) {
      final aviso = avisoDeRespuesta(r);
      if (aviso != null) tocados.add(aviso);
    },
  );
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

/// Arranca Firebase (avisos push). Si falla, la app sigue con el sondeo.
Future<ServicioPush> _prepararPush(
  NotificacionesLocales notificaciones,
  Stream<AvisoPush> tocados,
) async {
  if (notificaciones is! NotificacionesAndroid) return const PushInactivo();
  try {
    if (!await PushFirebase.preparar()) return const PushInactivo();
    return PushFirebase(plugin: notificaciones.plugin, tocadosLocales: tocados);
  } catch (e) {
    debugPrint('Push desactivado: $e');
    return const PushInactivo();
  }
}
