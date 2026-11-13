import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/mapa/maniobra.dart';
import '../../../../core/mapa/reglas_marcadores.dart';
import '../../../../core/providers.dart';
import '../../../../core/rumbo/orientacion_mapa.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../controllers/viaje_conductor_controller.dart';

/// Tarjeta de navegación del conductor (diseño G01), solo en modo navegación.
///
/// En viaje: el siguiente giro sobre la ruta del servidor y «Luego · Llegas
/// a …». Yendo a recoger (la ruta del servidor es la del viaje, no la de la
/// recogida): una flecha hacia el punto según el rumbo del conductor y la
/// distancia que da el servidor.
class NavegacionConductor extends ConsumerWidget {
  const NavegacionConductor({
    required this.fase,
    required this.moto,
    required this.ruta,
    required this.recogida,
    required this.destino,
    required this.pasajero,
    this.restanteKm,
    super.key,
  });

  final FaseConductor fase;
  final LatLng moto;
  final List<LatLng> ruta;
  final LatLng recogida;
  final String destino;
  final String pasajero;

  /// Distancia que calcula el servidor (a la recogida o al destino).
  final double? restanteKm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rumbo = ref.watch(orientacionMapaProvider.select((o) => o.rumbo));
    final nombre = pasajero.split(' ').first;
    final IconData icono;
    double giroIcono = 0;
    final String distancia;
    final String instruccion;
    String? luego;
    if (fase == FaseConductor.enViaje) {
      final m = ReglasManiobra.siguiente(ruta, moto);
      if (m == null) {
        icono = Icons.alt_route;
        distancia = restanteKm == null
            ? '—'
            : ReglasManiobra.texto(restanteKm! * 1000);
        instruccion = l.navVuelveARuta;
      } else {
        icono = switch (m.giro) {
          Giro.derecha => Icons.turn_right,
          Giro.izquierda => Icons.turn_left,
          Giro.ligeraDerecha => Icons.turn_slight_right,
          Giro.ligeraIzquierda => Icons.turn_slight_left,
          Giro.vuelta => Icons.u_turn_left,
          Giro.recto => Icons.straight,
          Giro.llegada => Icons.flag_outlined,
        };
        distancia = ReglasManiobra.texto(m.metros);
        instruccion = switch (m.giro) {
          Giro.derecha => l.navGiraDerecha,
          Giro.izquierda => l.navGiraIzquierda,
          Giro.ligeraDerecha => l.navLigeraDerecha,
          Giro.ligeraIzquierda => l.navLigeraIzquierda,
          Giro.vuelta => l.navDaLaVuelta,
          Giro.recto => l.navSigueRecto,
          Giro.llegada => l.navLlegasA(destino),
        };
        if (m.giro != Giro.llegada) luego = l.navLlegasA(destino);
      }
    } else {
      // Hacia la recogida: la flecha apunta al punto respecto de su rumbo.
      icono = Icons.navigation;
      final hacia = ReglasMarcadores.rumboEntre(moto, recogida);
      giroIcono = rumbo == null
          ? 0
          : ReglasManiobra.cambioRumbo(rumbo, hacia) * math.pi / 180;
      distancia = restanteKm == null
          ? '—'
          : ReglasManiobra.texto(restanteKm! * 1000);
      instruccion = l.navHaciaPunto(nombre);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: true,
          label: '$distancia. $instruccion',
          child: ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.all(Sp.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Rad.lg),
                gradient: const LinearGradient(
                  colors: [NexaColors.cyan, Color(0xFF0091C2)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: NexaColors.bg.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(Rad.md),
                    ),
                    child: Transform.rotate(
                      angle: giroIcono,
                      child: Icon(icono, size: 32, color: NexaColors.bg),
                    ),
                  ),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          distancia,
                          style: NexaTexto.numeroMedio.copyWith(
                            color: NexaColors.bg,
                          ),
                        ),
                        Text(
                          instruccion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: NexaTexto.cuerpo.copyWith(
                            color: NexaColors.bg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (luego != null) ...[
          const SizedBox(height: Sp.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.md,
              vertical: Sp.sm,
            ),
            decoration: BoxDecoration(
              color: NexaColors.glass,
              borderRadius: BorderRadius.circular(Rad.pill),
              border: Border.all(color: NexaColors.line),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${l.navLuego}  ',
                    style: const TextStyle(color: NexaColors.muted),
                  ),
                  TextSpan(text: luego),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NexaTexto.pequeno.copyWith(color: NexaColors.texto),
            ),
          ),
        ],
        const SizedBox(height: Sp.sm),
        const _Velocidad(),
      ],
    );
  }
}

/// Velocidad del GPS (km/h), si el dato es reciente.
class _Velocidad extends ConsumerStatefulWidget {
  const _Velocidad();

  @override
  ConsumerState<_Velocidad> createState() => _VelocidadState();
}

class _VelocidadState extends ConsumerState<_Velocidad> {
  late final Timer _reloj = Timer.periodic(
    const Duration(seconds: 1),
    (_) => setState(() {}),
  );

  @override
  void dispose() {
    _reloj.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.read(rastreadorProvider).movimiento;
    if (m == null ||
        m.velocidad < 0 ||
        DateTime.now().difference(m.en) > const Duration(seconds: 5)) {
      return const SizedBox.shrink();
    }
    final kmh = (m.velocidad * 3.6).round();
    return Semantics(
      label: '$kmh km/h',
      child: ExcludeSemantics(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: NexaColors.glass,
            border: Border.all(color: NexaColors.line, width: 2),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$kmh', style: NexaTexto.subtitulo.copyWith(height: 1)),
              const Text(
                'km/h',
                style: TextStyle(fontSize: 10, color: NexaColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
