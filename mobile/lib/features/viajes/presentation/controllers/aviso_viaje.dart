import '../../../../core/l10n/gen/app_localizations.dart';
import '../../domain/servicio.dart';
import 'viaje_conductor_controller.dart';

/// Texto de la notificación fija mientras hay un viaje. Sale solo de lo que
/// entrega el servidor (fase, ETA y distancia de `PosicionViaje`); la app no
/// calcula nada.
class AvisoViaje {
  const AvisoViaje(this.titulo, this.texto);
  final String titulo;
  final String texto;

  @override
  bool operator ==(Object other) =>
      other is AvisoViaje && other.titulo == titulo && other.texto == texto;

  @override
  int get hashCode => Object.hash(titulo, texto);
}

abstract final class TextosAvisoViaje {
  /// «650 m» o «2,3 km».
  static String distancia(double km) => km < 1
      ? '${(km * 100).round() * 10} m'
      : '${km.toStringAsFixed(1).replaceAll('.', ',')} km';

  static String _primerNombre(String? nombre, String siNoHay) {
    final limpio = nombre?.trim() ?? '';
    return limpio.isEmpty ? siNoHay : limpio.split(RegExp(r'\s+')).first;
  }

  /// Conductor: «Recoge a Laura · 3 min · 650 m», «Esperando a Laura» o
  /// «Llevando a Laura · 8 min · 2,3 km». Null sin viaje (queda «En línea»).
  static AvisoViaje? conductor(AppLocalizations l, ConductorState s) {
    final viaje = s.activo;
    final fase = s.fase;
    if (viaje == null || fase == null) return null;
    final nombre = _primerNombre(viaje.pasajero?.nombre, l.avisoElPasajero);
    final pos = s.posicion;
    final eta = [
      if (pos?.etaMinutos case final minutos?) l.minutosValor(minutos),
      if (pos?.distanciaRestanteKm case final km?) distancia(km),
    ].join(' · ');
    return switch (fase) {
      FaseConductor.aRecoger => AvisoViaje(
        l.avisoRecoger(nombre),
        eta.isEmpty ? viaje.origen : eta,
      ),
      FaseConductor.enElPunto => AvisoViaje(
        l.avisoEsperando(nombre),
        l.avisoEnElPunto,
      ),
      FaseConductor.enViaje => AvisoViaje(
        l.avisoLlevando(nombre),
        eta.isEmpty ? viaje.destino : eta,
      ),
    };
  }

  /// Pasajero buscando conductor («Buscando conductor · Hacia Bazurto») o con
  /// el conductor en camino («Carlos va por ti · Llega en 3 min · KZT 38F»).
  /// Null en cualquier otro estado.
  static AvisoViaje? pasajero(
    AppLocalizations l,
    Servicio? viaje,
    PosicionViaje? posicionConductor,
  ) {
    if (viaje?.estado == EstadoServicio.solicitado) {
      return AvisoViaje(
        l.avisoBuscandoTitulo,
        viaje!.destino.trim().isEmpty
            ? l.avisoBuscandoTexto
            : l.avisoBuscandoHacia(viaje.destino.trim()),
      );
    }
    if (viaje == null || viaje.estado != EstadoServicio.aceptado) return null;
    final c = viaje.conductor;
    final nombre = _primerNombre(c?.nombre, l.avisoTuConductor);
    final partes = [
      if (posicionConductor?.etaMinutos case final minutos?)
        l.avisoLlegaEn(minutos),
      if ((c?.placa ?? '').trim().isNotEmpty) c!.placa!.trim(),
    ];
    return AvisoViaje(
      l.avisoConductorVa(nombre),
      partes.isEmpty ? viaje.origen : partes.join(' · '),
    );
  }
}
