import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../domain/zonas_documentos.dart';

/// Zonas con más solicitudes; se refrescan cada [intervalo] mientras el
/// conductor en línea las ve. Si falla, el mapa queda sin zonas.
class ZonasDemandaController extends AsyncNotifier<List<ZonaDemanda>> {
  static const intervalo = Duration(minutes: 2);
  Timer? _timer;

  @override
  Future<List<ZonaDemanda>> build() async {
    _timer?.cancel();
    _timer = Timer.periodic(intervalo, (_) => _refrescar());
    ref.onCancel(() => _timer?.cancel());
    ref.onResume(() {
      _timer?.cancel();
      _timer = Timer.periodic(intervalo, (_) => _refrescar());
    });
    ref.onDispose(() => _timer?.cancel());
    try {
      return await ref.read(zonasDocumentosRepositoryProvider).zonas();
    } on Object {
      return const [];
    }
  }

  Future<void> _refrescar() async {
    try {
      state = AsyncData(
        await ref.read(zonasDocumentosRepositoryProvider).zonas(),
      );
    } on Object {
      // Se reintenta en el siguiente ciclo.
    }
  }
}

final zonasDemandaProvider =
    AsyncNotifierProvider.autoDispose<
      ZonasDemandaController,
      List<ZonaDemanda>
    >(ZonasDemandaController.new);

/// Documentos del conductor con su vencimiento (perfil).
final misDocumentosProvider = FutureProvider.autoDispose<List<MiDocumento>>(
  (ref) => ref.watch(zonasDocumentosRepositoryProvider).misDocumentos(),
);
