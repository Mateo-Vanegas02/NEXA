import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../domain/admin.dart';

/// Operación en vivo; se refresca sola cada [intervalo] mientras se ve.
class OperacionController extends AsyncNotifier<OperacionAdmin> {
  static const intervalo = Duration(seconds: 15);
  Timer? _timer;

  @override
  Future<OperacionAdmin> build() async {
    void iniciarSondeo() {
      _timer?.cancel();
      _timer = Timer.periodic(intervalo, (_) => refrescar());
    }

    iniciarSondeo();
    ref.onCancel(() => _timer?.cancel());
    ref.onResume(iniciarSondeo);
    ref.onDispose(() => _timer?.cancel());
    return ref.read(adminRepositoryProvider).operacion();
  }

  /// Sin pantalla de carga: si falla, se queda lo último que se vio.
  Future<void> refrescar() async {
    try {
      final o = await ref.read(adminRepositoryProvider).operacion();
      state = AsyncData(o);
    } on Object {
      // Se reintenta en el siguiente ciclo.
    }
  }
}

final operacionProvider =
    AsyncNotifierProvider.autoDispose<OperacionController, OperacionAdmin>(
      OperacionController.new,
    );

final conductoresRevisionProvider = FutureProvider.autoDispose
    .family<List<ConductorRevision>, EstadoRevision>(
      (ref, estado) => ref.watch(adminRepositoryProvider).conductores(estado),
    );

final expedienteProvider = FutureProvider.autoDispose
    .family<ExpedienteConductor, String>(
      (ref, email) => ref.watch(adminRepositoryProvider).expediente(email),
    );

final archivoDocumentoProvider = FutureProvider.autoDispose
    .family<Uint8List, String>(
      (ref, id) => ref.watch(adminRepositoryProvider).archivo(id),
    );
