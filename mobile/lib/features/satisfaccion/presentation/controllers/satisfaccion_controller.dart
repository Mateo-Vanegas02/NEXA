import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/providers.dart';
import '../../domain/satisfaccion.dart';
import '../../domain/satisfaccion_repository.dart';

/// Reloj del panel (sobrescribible en tests).
final relojSatisfaccionProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Cada cuánto se consulta un entrenamiento en curso (sobrescribible en tests).
final intervaloSondeoProvider = Provider<Duration>(
  (ref) => Env.pollingInterval,
);

SatisfaccionRepository _repo(Ref ref) =>
    ref.read(satisfaccionRepositoryProvider);

// ───────────────────────────── Resumen ─────────────────────────────

enum TipoPeriodo { dias7, dias30, dias90, rango }

class Periodo {
  const Periodo(this.tipo, this.desde, this.hasta);

  /// Los últimos [dias] días, contando hoy.
  factory Periodo.ultimos(TipoPeriodo tipo, int dias, DateTime hoy) {
    final hasta = DateTime(hoy.year, hoy.month, hoy.day);
    return Periodo(tipo, hasta.subtract(Duration(days: dias - 1)), hasta);
  }

  final TipoPeriodo tipo;
  final DateTime desde;
  final DateTime hasta;
}

class PeriodoController extends Notifier<Periodo> {
  @override
  Periodo build() => Periodo.ultimos(
    TipoPeriodo.dias30,
    30,
    ref.read(relojSatisfaccionProvider)(),
  );

  void elegir(TipoPeriodo tipo) {
    final hoy = ref.read(relojSatisfaccionProvider)();
    state = switch (tipo) {
      TipoPeriodo.dias7 => Periodo.ultimos(tipo, 7, hoy),
      TipoPeriodo.dias30 => Periodo.ultimos(tipo, 30, hoy),
      TipoPeriodo.dias90 => Periodo.ultimos(tipo, 90, hoy),
      TipoPeriodo.rango => state,
    };
  }

  void rango(DateTime desde, DateTime hasta) =>
      state = Periodo(TipoPeriodo.rango, desde, hasta);
}

final periodoProvider = NotifierProvider<PeriodoController, Periodo>(
  PeriodoController.new,
);

final resumenProvider = FutureProvider<Resumen>((ref) {
  final p = ref.watch(periodoProvider);
  return _repo(ref).resumen(desde: p.desde, hasta: p.hasta);
});

// ───────────────────────────── Factores ─────────────────────────────

class LadoController extends Notifier<Lado> {
  @override
  Lado build() => Lado.pasajero;

  void elegir(Lado lado) => state = lado;
}

final ladoFactoresProvider = NotifierProvider<LadoController, Lado>(
  LadoController.new,
);

final factoresProvider = FutureProvider<Factores>(
  (ref) => _repo(ref).factores(ref.watch(ladoFactoresProvider)),
);

/// Curva elegida en "Cómo cambia la satisfacción"; vuelve a la primera al cambiar de lado.
class CurvaController extends Notifier<int> {
  @override
  int build() {
    ref.watch(ladoFactoresProvider);
    return 0;
  }

  void elegir(int i) => state = i;
}

final curvaSeleccionadaProvider = NotifierProvider<CurvaController, int>(
  CurvaController.new,
);

// ───────────────────────────── Viajes en riesgo ─────────────────────────────

/// Filtro de la lista: `null` = todos.
class FiltroRiesgoController extends Notifier<Lado?> {
  @override
  Lado? build() => null;

  void elegir(Lado? lado) => state = lado;
}

final filtroRiesgoProvider = NotifierProvider<FiltroRiesgoController, Lado?>(
  FiltroRiesgoController.new,
);

final riesgoProvider = FutureProvider<Riesgo>((ref) => _repo(ref).riesgo());

// ───────────────────────────── Modelo ─────────────────────────────

class ModeloController extends AsyncNotifier<ModeloInfo> {
  @override
  Future<ModeloInfo> build() => _repo(ref).modelo();

  Future<void> refrescar() async {
    state = await AsyncValue.guard(() => _repo(ref).modelo());
  }

  /// Lanza un entrenamiento con viajes reales y devuelve su id. Sin los
  /// mínimos de datos el servidor responde 422 (la pantalla deshabilita el botón).
  Future<String> entrenar() => _repo(ref).entrenar();

  Future<void> guardarProgramacion(Programacion p) async {
    final guardada = await _repo(ref).guardarProgramacion(p);
    final actual = state.value;
    if (actual != null) state = AsyncData(actual.conProgramacion(guardada));
  }

  Future<void> activarProgramacion(bool activa) async {
    final actual = state.value;
    if (actual == null) return;
    await guardarProgramacion(actual.programacion.copyWith(activa: activa));
  }
}

final modeloProvider = AsyncNotifierProvider<ModeloController, ModeloInfo>(
  ModeloController.new,
);

// ───────────────────────────── Entrenamiento en curso ─────────────────────────────

/// Sigue un entrenamiento con sondeo cada [intervaloSondeoProvider] mientras la
/// pantalla "Entrenando" está abierta (autoDispose: al salir se detiene).
class EntrenamientoController extends Notifier<AsyncValue<Entrenamiento>> {
  Timer? _timer;
  String? _id;
  bool _sondeando = false;

  @override
  AsyncValue<Entrenamiento> build() {
    ref.onDispose(_detener);
    return const AsyncLoading();
  }

  void seguir(String id) {
    if (_id == id && _timer != null) return;
    _id = id;
    unawaited(sondear());
    _timer?.cancel();
    _timer = Timer.periodic(
      ref.read(intervaloSondeoProvider),
      (_) => sondear(),
    );
  }

  void _detener() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> sondear() async {
    final id = _id;
    if (id == null || _sondeando) return;
    _sondeando = true;
    try {
      final e = await _repo(ref).entrenamiento(id);
      if (!ref.mounted) return;
      state = AsyncData(e);
      if (e.estado.esFinal) {
        _detener();
        // Ya hay versión nueva (o no): todo el panel vuelve a pedir sus datos.
        ref
          ..invalidate(modeloProvider)
          ..invalidate(resumenProvider)
          ..invalidate(factoresProvider)
          ..invalidate(riesgoProvider);
      }
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
    } finally {
      _sondeando = false;
    }
  }

  Future<void> cancelar() async {
    final id = _id;
    if (id == null) return;
    await _repo(ref).cancelarEntrenamiento(id);
    await sondear();
  }
}

final entrenamientoProvider =
    NotifierProvider.autoDispose<
      EntrenamientoController,
      AsyncValue<Entrenamiento>
    >(EntrenamientoController.new);
