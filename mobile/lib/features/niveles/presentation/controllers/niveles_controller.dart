import '../../../../core/providers.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../domain/nivel.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Evento de celebración: XP ganado y/o subida de nivel (se consume una sola vez).
class Celebracion {
  const Celebracion({this.xp = 0, this.nivelNuevo});
  final int xp;
  final NivelEstado? nivelNuevo;
}

class CelebracionController extends Notifier<Celebracion?> {
  @override
  Celebracion? build() => null;

  void emitir(Celebracion c) => state = c;
  void consumir() => state = null;
}

final celebracionProvider =
    NotifierProvider<CelebracionController, Celebracion?>(
      CelebracionController.new,
    );

/// Estado de nivel/XP del usuario autenticado.
class NivelController extends AsyncNotifier<NivelEstado> {
  @override
  Future<NivelEstado> build() async {
    final sesion = ref.watch(sesionProvider).sesion;
    if (sesion == null) throw StateError('Sin sesión');
    final estado = await ref
        .read(nivelesRepositoryProvider)
        .me(sesion.rol.name);
    // Primer arranque: se registra el nivel actual como "ya visto".
    final store = ref.read(secureStoreProvider);
    final clave = 'nivel_visto_${sesion.userId ?? sesion.email}';
    if (await store.read(clave) == null) {
      await store.write(clave, '${estado.nivel}');
    }
    return estado;
  }

  Future<void> refrescar() async {
    final sesion = ref.read(sesionProvider).sesion;
    if (sesion == null) return;
    state = await AsyncValue.guard(
      () => ref.read(nivelesRepositoryProvider).me(sesion.rol.name),
    );
  }

  /// Llamar al completarse un viaje: refresca el nivel y emite "+N XP" y, solo
  /// la primera vez que se alcanza un nivel mayor, la animación de subida.
  Future<void> viajeCompletado(int xpGanado) async {
    final sesion = ref.read(sesionProvider).sesion;
    if (sesion == null) return;
    final store = ref.read(secureStoreProvider);
    final clave = 'nivel_visto_${sesion.userId ?? sesion.email}';
    await refrescar();
    final nuevo = state.value;
    if (nuevo == null) return;
    final visto = int.tryParse(await store.read(clave) ?? '');
    final subio = visto != null && nuevo.nivel > visto;
    if (visto == null || nuevo.nivel > visto) {
      await store.write(clave, '${nuevo.nivel}');
    }
    if (xpGanado > 0 || subio) {
      ref
          .read(celebracionProvider.notifier)
          .emitir(Celebracion(xp: xpGanado, nivelNuevo: subio ? nuevo : null));
    }
  }
}

final nivelProvider = AsyncNotifierProvider<NivelController, NivelEstado>(
  NivelController.new,
);
