import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/providers.dart';
import '../../../../core/sin_conexion/conexion.dart';
import '../../../../core/sin_conexion/reglas_sin_conexion.dart';
import '../../domain/servicio.dart';

/// Lo que espera en el teléfono para enviarse.
class EstadoSinConexion {
  const EstadoSinConexion({
    this.pendientes = const [],
    this.puntos = 0,
    this.rechazo,
  });

  /// Acciones en cola (en orden).
  final List<AccionPendiente> pendientes;

  /// Posiciones de GPS guardadas sin enviar.
  final int puntos;

  /// El servidor dijo que una acción ya no aplicaba (gana el servidor).
  final String? rechazo;

  bool tienePendiente(String servicioId, TipoPendiente tipo) => pendientes.any(
    (a) => a.servicioId == servicioId && a.tipo == tipo,
  );

  bool get hayAlgo => pendientes.isNotEmpty || puntos > 0;
}

/// Cola de lo hecho sin señal (fase 5). Envía primero las posiciones (así el
/// servidor ya sabe dónde terminó el viaje) y después las acciones en orden,
/// cada una con su llave de idempotencia. Se dispara al volver la señal y en
/// cada ciclo del panel del conductor.
class SinConexionController extends Notifier<EstadoSinConexion> {
  bool _enviando = false;

  @override
  EstadoSinConexion build() {
    ref.listen(conexionProvider.select((e) => e.conRed), (antes, ahora) {
      if (ahora && antes == false) unawaited(enviar());
    });
    unawaited(_refrescar());
    return const EstadoSinConexion();
  }

  Future<void> _refrescar({String? rechazo}) async {
    final almacen = ref.read(almacenSinConexionProvider);
    final cola = await almacen.cola();
    final puntos = await almacen.puntos(limite: ReglasSinConexion.maxPuntos);
    state = EstadoSinConexion(
      pendientes: cola,
      puntos: puntos.length,
      rechazo: rechazo ?? state.rechazo,
    );
  }

  Future<void> encolar(AccionPendiente accion) async {
    await ref.read(almacenSinConexionProvider).encolar(accion);
    await _refrescar();
  }

  Future<void> guardarPunto(double latitud, double longitud) async {
    await ref
        .read(almacenSinConexionProvider)
        .guardarPunto(
          PuntoGuardado(
            latitud: latitud,
            longitud: longitud,
            tomadoEn: DateTime.now(),
          ),
        );
    await _refrescar();
  }

  /// Envía lo pendiente. true si la cola quedó vacía.
  Future<bool> enviar() async {
    if (_enviando) return false;
    final almacen = ref.read(almacenSinConexionProvider);
    final repo = ref.read(conductorRepositoryProvider);
    _enviando = true;
    String? rechazo;
    try {
      // 1. Posiciones, de las más viejas a las más nuevas.
      while (true) {
        final puntos = await almacen.puntos();
        if (puntos.isEmpty) break;
        try {
          await repo.reportarLote(puntos);
        } on Object catch (e) {
          if (ReglasSinConexion.resultado(e) == ResultadoEnvio.reintentar) {
            return false;
          }
          // Rechazadas (p. ej. fuera de la tolerancia): no se reintentan.
        }
        await almacen.quitarPuntos([for (final p in puntos) ?p.id]);
      }
      // 2. Acciones, en el orden en que se hicieron.
      for (final a in await almacen.cola()) {
        Object? error;
        try {
          await _hacer(a);
        } on Object catch (e) {
          error = e;
        }
        switch (ReglasSinConexion.resultado(error)) {
          case ResultadoEnvio.enviada:
            await almacen.quitar(a.llave);
          case ResultadoEnvio.rechazada:
            await almacen.quitar(a.llave);
            rechazo = _textoRechazo(a, AppException.from(error!).mensaje);
          case ResultadoEnvio.reintentar:
            await almacen.sumarIntento(a.llave);
            return false;
        }
      }
      return true;
    } finally {
      _enviando = false;
      await _refrescar(rechazo: rechazo);
    }
  }

  Future<void> _hacer(AccionPendiente a) {
    final repo = ref.read(conductorRepositoryProvider);
    return switch (a.tipo) {
      TipoPendiente.llegue => repo.llegue(
        a.servicioId,
        Coordenada(latitud: a.latitud ?? 0, longitud: a.longitud ?? 0),
        llave: a.llave,
        ocurridoEn: a.ocurridoEn,
      ),
      TipoPendiente.iniciar => repo.iniciar(
        a.servicioId,
        llave: a.llave,
        ocurridoEn: a.ocurridoEn,
      ),
      TipoPendiente.finalizar => repo.finalizar(
        a.servicioId,
        llave: a.llave,
        ocurridoEn: a.ocurridoEn,
      ),
    };
  }

  static String _textoRechazo(AccionPendiente a, String motivo) {
    final l = lookupAppLocalizations(const Locale('es'));
    final accion = switch (a.tipo) {
      TipoPendiente.llegue => l.pendienteLlegue,
      TipoPendiente.iniciar => l.pendienteIniciar,
      TipoPendiente.finalizar => l.pendienteFinalizar,
    };
    return l.sinConexionRechazo(accion, motivo);
  }

  /// La pantalla ya mostró el rechazo.
  void descartarRechazo() => state = EstadoSinConexion(
    pendientes: state.pendientes,
    puntos: state.puntos,
  );

  @visibleForTesting
  bool get enviando => _enviando;
}

final sinConexionProvider =
    NotifierProvider<SinConexionController, EstadoSinConexion>(
      SinConexionController.new,
    );
