import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/session_controller.dart';
import '../config/env.dart';
import '../providers.dart';
import 'canal_tiempo_real.dart';

/// El canal en vivo con el servidor; null en modo demostración o pruebas.
final canalTiempoRealProvider = Provider<CanalTiempoReal?>((ref) {
  if (ref.watch(useMocksProvider)) return null;
  final canal = CanalTiempoReal(
    url: urlTiempoReal(Env.apiBaseUrl),
    token: () => ref.read(sesionProvider).sesion?.token,
  );
  ref.onDispose(canal.cerrar);
  return canal;
});
