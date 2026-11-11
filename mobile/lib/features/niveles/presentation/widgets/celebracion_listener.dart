import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/nexa_popup.dart';
import '../../../auth/domain/auth.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../viajes/presentation/controllers/viaje_pasajero_controller.dart';
import '../controllers/niveles_controller.dart';

/// Escucha los eventos que se celebran con UI de marca:
/// - popup de bienvenida tras iniciar sesión o registrarse;
/// - toast "+N XP" al completar un viaje;
/// - popup animado de subida de nivel (una sola vez por nivel).
/// Cada evento se consume al mostrarse.
class CelebracionListener extends ConsumerStatefulWidget {
  const CelebracionListener({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<CelebracionListener> createState() =>
      _CelebracionListenerState();
}

class _CelebracionListenerState extends ConsumerState<CelebracionListener> {
  @override
  void initState() {
    super.initState();
    // El estado puede venir ya marcado cuando el shell se monta tras el login.
    WidgetsBinding.instance.addPostFrameCallback((_) => _revisarBienvenida());
  }

  Future<void> _revisarBienvenida() async {
    if (!mounted) return;
    final estado = ref.read(sesionProvider);
    final sesion = estado.sesion;
    if (!estado.bienvenida || sesion == null) return;
    ref.read(sesionProvider.notifier).consumirBienvenida();

    final l = AppLocalizations.of(context);
    final esConductor = sesion.rol == Rol.conductor;
    var nombre = sesion.email.split('@').first;
    if (!esConductor) {
      try {
        final perfil = await ref.read(perfilPasajeroProvider.future);
        nombre = perfil.nombre.split(' ').first;
      } on Object {
        // Sin perfil: se usa el correo.
      }
    }
    if (!mounted) return;
    await mostrarNexaPopup<void>(
      context,
      titulo: l.bienvenidaTitulo,
      mensaje:
          '${l.bienvenidaNombre(nombre)}\n'
          '${esConductor ? l.bienvenidaConductor : l.bienvenidaPasajero}',
      tipo: NexaPopupTipo.exito,
      acciones: [NexaPopupAccion(etiqueta: l.vamos)],
    );
  }

  void _celebrar(Celebracion c) {
    ref.read(celebracionProvider.notifier).consumir();
    final l = AppLocalizations.of(context);
    if (c.xp > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.bolt, color: NexaColors.gold),
              const SizedBox(width: Sp.sm),
              Text(l.xpGanado(c.xp)),
            ],
          ),
        ),
      );
    }
    final nuevo = c.nivelNuevo;
    if (nuevo != null) {
      mostrarNexaPopup<void>(
        context,
        titulo: l.subisteNivel,
        mensaje: l.ahoraEres(nuevo.nombre),
        tipo: NexaPopupTipo.exito,
        hero: InsigniaNivel(nivel: nuevo.nivel),
        acciones: [NexaPopupAccion(etiqueta: l.genial)],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(celebracionProvider, (_, c) {
        if (c != null) _celebrar(c);
      })
      ..listen(sesionProvider.select((s) => s.bienvenida), (_, b) {
        if (b) _revisarBienvenida();
      });
    return widget.child;
  }
}

/// Insignia circular del nivel (trofeo con el color del nivel).
class InsigniaNivel extends StatelessWidget {
  const InsigniaNivel({required this.nivel, this.tamano = 88, super.key});

  final int nivel;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final color = kColoresNivel[nivel.clamp(0, kColoresNivel.length - 1)];
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 24),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(Icons.emoji_events, color: color, size: tamano * 0.55),
    );
  }
}
