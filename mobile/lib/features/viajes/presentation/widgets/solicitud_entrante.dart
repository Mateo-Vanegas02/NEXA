import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/servicio.dart';
import 'solicitud_card.dart';

/// Solicitudes que el conductor ya vio a pantalla completa y mandó a la lista.
class SolicitudesVistasNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// Manda a la lista estas solicitudes (todas las que había al tocar).
  void ver(Iterable<String> ids) => state = {...state, ...ids};
}

final solicitudesVistasProvider =
    NotifierProvider<SolicitudesVistasNotifier, Set<String>>(
      SolicitudesVistasNotifier.new,
    );

/// Solicitud entrante a pantalla completa (propuesta «Estela»): el mapa queda a
/// la vista con la recogida y el destino, la tarjeta baja al borde inferior y
/// la cuenta regresiva de 45 s recorre el borde de la pantalla (cian; dorada al
/// final). «Ver en el mapa» la deja en la lista de la hoja.
class SolicitudEntrante extends ConsumerStatefulWidget {
  const SolicitudEntrante({
    required this.servicio,
    this.pendientes = const [],
    super.key,
  });
  final Servicio servicio;

  /// Todas las solicitudes abiertas: «Ver en el mapa» las deja en la lista.
  final List<String> pendientes;

  @override
  ConsumerState<SolicitudEntrante> createState() => _SolicitudEntranteState();
}

class _SolicitudEntranteState extends ConsumerState<SolicitudEntrante>
    with SingleTickerProviderStateMixin {
  /// Ventana de atención: corre una vez. Al acabar la solicitud sigue
  /// disponible (el servidor no la vence por conductor), solo deja de
  /// resaltarse.
  late final AnimationController _reloj = AnimationController(
    vsync: this,
    duration: SolicitudCard.ventana,
  )..forward();

  @override
  void dispose() {
    _reloj.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final alto = MediaQuery.sizeOf(context).height;
    return Positioned.fill(
      child: Stack(
        children: [
          // Sombra suave solo detrás de la tarjeta: el mapa sigue a la vista.
          Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              child: SizedBox(
                width: double.infinity,
                height: alto * 0.55,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        NexaColors.bg.withValues(alpha: 0),
                        NexaColors.bg.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // La cuenta regresiva en el borde de la pantalla. Los segundos
          // también van en la tarjeta (y para el lector de pantalla).
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  child: CustomPaint(painter: BordeCuenta(_reloj)),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                // Si no cabe (letra grande), se ve primero «Desliza para
                // aceptar» y el resto se desplaza hacia arriba.
                child: SingleChildScrollView(
                  reverse: true,
                  padding: const EdgeInsets.all(Sp.md),
                  child: Semantics(
                    scopesRoute: true,
                    namesRoute: true,
                    explicitChildNodes: true,
                    label: l.solicitudNueva,
                    child: SolicitudCard(
                      servicio: widget.servicio,
                      reloj: _reloj,
                      onVerEnMapa: () => ref
                          .read(solicitudesVistasProvider.notifier)
                          .ver([widget.servicio.id, ...widget.pendientes]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuenta regresiva alrededor de la pantalla: sale de arriba al centro, recorre
/// el borde en el sentido del reloj y se acorta hasta cero. Debajo queda la
/// pista apagada.
class BordeCuenta extends CustomPainter {
  BordeCuenta(this.reloj) : super(repaint: reloj);

  /// Avance de la ventana de atención (0 → 1).
  final Animation<double> reloj;

  static const double _trazo = 5;

  /// Cerca del redondeo de las pantallas actuales, para no cortarse en las
  /// esquinas.
  static const double _radio = 32;

  /// El borde completo, empezando arriba al centro y en el sentido del reloj.
  static Path camino(Size size) {
    const t = _trazo / 2;
    final w = size.width;
    final h = size.height;
    final r = math.max(0.0, math.min(_radio, math.min(w, h) / 2 - t));
    final esquina = Radius.circular(r);
    return Path()
      ..moveTo(w / 2, t)
      ..lineTo(w - t - r, t)
      ..arcToPoint(Offset(w - t, t + r), radius: esquina)
      ..lineTo(w - t, h - t - r)
      ..arcToPoint(Offset(w - t - r, h - t), radius: esquina)
      ..lineTo(t + r, h - t)
      ..arcToPoint(Offset(t, h - t - r), radius: esquina)
      ..lineTo(t, t + r)
      ..arcToPoint(Offset(t + r, t), radius: esquina)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final queda = 1 - reloj.value;
    final borde = camino(size);
    canvas.drawPath(
      borde,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _trazo
        ..color = NexaColors.line.withValues(alpha: 0.7),
    );
    if (queda <= 0) return;
    final color = SolicitudCard.colorCuenta(queda);
    for (final m in borde.computeMetrics()) {
      final largo = m.length * queda;
      final tramo = m.extractPath(0, largo);
      // Halo ancho y translúcido (sin desenfoque: se repinta en cada cuadro).
      canvas
        ..drawPath(
          tramo,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = _trazo * 3
            ..strokeCap = StrokeCap.round
            ..color = color.withValues(alpha: 0.18),
        )
        ..drawPath(
          tramo,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = _trazo
            ..strokeCap = StrokeCap.round
            ..color = color,
        );
      // La punta que se va apagando.
      final punta = m.getTangentForOffset(largo)?.position;
      if (punta != null) {
        canvas.drawCircle(
          punta,
          _trazo * 0.9,
          Paint()..color = NexaColors.texto,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BordeCuenta old) => old.reloj != reloj;
}
