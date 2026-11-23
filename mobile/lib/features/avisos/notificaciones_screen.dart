import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/providers.dart';
import '../../core/push/aviso_push.dart';
import '../../core/push/bandeja_avisos.dart';
import '../../core/theme/nexa_texto.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/nexa_diseno.dart';
import '../../core/widgets/nexa_icono_app.dart';
import '../../core/widgets/nexa_widgets.dart';
import '../viajes/domain/agrupar_viajes.dart';

/// Avisos guardados en el teléfono.
/// Se vuelve a leer al volver a la app: los avisos que llegaron con la app
/// cerrada los guardó el receptor de segundo plano.
final bandejaProvider = FutureProvider.autoDispose<List<AvisoGuardado>>((ref) {
  ref.watch(primerPlanoProvider);
  return ref.watch(bandejaAvisosProvider).leer();
});

/// Avisos sin leer (punto en la campana).
final sinLeerProvider = Provider.autoDispose<int>(
  (ref) => ReglasBandeja.sinLeer(ref.watch(bandejaProvider).value ?? const []),
);

/// Notificaciones (diseño N08): los avisos que llegaron al teléfono, por día.
/// Al abrirla quedan como leídos.
class NotificacionesScreen extends ConsumerStatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  ConsumerState<NotificacionesScreen> createState() =>
      _NotificacionesScreenState();
}

class _NotificacionesScreenState extends ConsumerState<NotificacionesScreen> {
  late final Timer _lectura;

  @override
  void initState() {
    super.initState();
    // Se ven con su punto de «nuevo» y quedan leídas para la próxima vez.
    _lectura = Timer(const Duration(seconds: 2), () async {
      await ref.read(bandejaAvisosProvider).marcarLeidas();
      if (mounted) ref.invalidate(bandejaProvider);
    });
  }

  @override
  void dispose() {
    _lectura.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bandeja = ref.watch(bandejaProvider);
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(context.gutter),
            children: [
              ContenidoCentrado(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: NexaBotonAtras(
                        onPressed: () =>
                            context.canPop() ? context.pop() : context.go('/'),
                      ),
                    ),
                    const SizedBox(height: Sp.lg),
                    Text(
                      l.notificaciones,
                      style: NexaTexto.titulo.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: Sp.lg),
                    ...bandeja.when(
                      loading: () => const [CargandoSkeleton()],
                      error: (_, _) => [_vacio(l)],
                      data: (lista) =>
                          lista.isEmpty ? [_vacio(l)] : _grupos(l, lista),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vacio(AppLocalizations l) => SizedBox(
    height: 320,
    child: EstadoVacio(
      titulo: l.sinNotificaciones,
      detalle: l.sinNotificacionesDetalle,
      icon: Icons.notifications_none,
    ),
  );

  List<Widget> _grupos(AppLocalizations l, List<AvisoGuardado> lista) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    String tramo(DateTime f) {
      final d = DateTime(f.year, f.month, f.day);
      if (d == hoy) return l.tramoHoy;
      if (d == hoy.subtract(const Duration(days: 1))) return l.ayer;
      return tramoDe(f, ahora) == TramoFecha.semana
          ? l.tramoSemana
          : l.tramoAntes;
    }

    final out = <Widget>[];
    String? actual;
    for (final a in lista) {
      final t = tramo(a.en);
      if (t != actual) {
        actual = t;
        out.add(
          Padding(
            padding: const EdgeInsets.only(
              left: Sp.xs,
              top: Sp.sm,
              bottom: Sp.sm,
            ),
            child: Text(
              t.toUpperCase(),
              style: NexaTexto.etiqueta.copyWith(color: NexaColors.tenue),
            ),
          ),
        );
      }
      out
        ..add(_Aviso(aviso: a))
        ..add(const SizedBox(height: Sp.sm));
    }
    return out;
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.aviso});
  final AvisoGuardado aviso;

  @override
  Widget build(BuildContext context) {
    final (icono, color) = switch (aviso.tipo) {
      TipoAviso.conductorLlego => (Icons.place_outlined, NexaColors.cyan),
      TipoAviso.viajeAceptado => (Icons.two_wheeler, NexaColors.cyan),
      TipoAviso.viajeIniciado => (Icons.route_outlined, NexaColors.cyan),
      TipoAviso.viajeFinalizado => (Icons.check_rounded, NexaColors.ok),
      TipoAviso.viajeCancelado ||
      TipoAviso.solicitudVencida => (Icons.close_rounded, NexaColors.error),
      TipoAviso.sinConductores => (Icons.waves, NexaColors.gold),
      _ => (Icons.notifications_none, NexaColors.muted),
    };
    return Container(
      padding: const EdgeInsets.all(Sp.md + 2),
      decoration: BoxDecoration(
        color: NexaColors.card,
        borderRadius: BorderRadius.circular(Rad.lg),
        border: Border.all(
          color: aviso.leido
              ? NexaColors.line
              : NexaColors.cyan.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Rad.md),
            ),
            child: Icon(icono, size: 20, color: color),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (aviso.titulo != null)
                  Text(
                    aviso.titulo!,
                    style: NexaTexto.cuerpo.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (aviso.cuerpo != null)
                  Text(
                    aviso.cuerpo!,
                    style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Sp.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('H:mm', 'es_CO').format(aviso.en),
                style: NexaTexto.pequeno.copyWith(color: NexaColors.tenue),
              ),
              if (!aviso.leido) ...[
                const SizedBox(height: Sp.sm),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: NexaColors.cyan,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
