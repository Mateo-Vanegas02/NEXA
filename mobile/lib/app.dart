import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/gen/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/viajes/presentation/controllers/avisos_push_controller.dart';
import 'features/viajes/presentation/controllers/segundo_plano_controller.dart';

class NexaApp extends ConsumerWidget {
  const NexaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Vive mientras la app esté abierta: prende o apaga el GPS en segundo plano.
    ref.watch(coordinadorSegundoPlanoProvider);
    // Avisos push: registra el teléfono y atiende los toques.
    ref.watch(avisosPushProvider);
    return _app(context, ref);
  }

  Widget _app(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'NEXA',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.dark,
    routerConfig: ref.watch(routerProvider),
    locale: const Locale('es', 'CO'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) {
      // Limita el escalado de texto a 1.3 (accesibilidad sin overflow).
      final mq = MediaQuery.of(context);
      return MediaQuery(
        data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3)),
        child: child!,
      );
    },
  );
}
