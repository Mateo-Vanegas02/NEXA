import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/mapa_nexa.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../../niveles/presentation/controllers/niveles_controller.dart';
import '../../../niveles/presentation/widgets/nivel_banner.dart';
import '../../domain/perfil_pasajero.dart';
import '../controllers/viaje_pasajero_controller.dart';
import '../widgets/estado_texto.dart';
import '../widgets/viaje_tile.dart';
import '../../../permisos/presentation/flujo_permisos.dart';
import 'elegir_lugar_screen.dart';

/// Inicio del pasajero: el mapa es la pantalla y una hoja inferior concentra la
/// acción (buscar destino), el nivel y los viajes recientes.
class InicioPasajeroScreen extends ConsumerWidget {
  const InicioPasajeroScreen({super.key});

  Future<void> _elegirDestino(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final cerca = ref.read(ubicacionProvider).value ?? kCentroPorDefecto;
    final r = await Navigator.of(context, rootNavigator: true)
        .push<ResultadoLugar>(
          MaterialPageRoute(
            builder: (_) => ElegirLugarScreen(
              esOrigen: false,
              cerca: cerca,
              origenTexto: l.miUbicacion,
            ),
          ),
        );
    if (!context.mounted || r == null) return;
    context.go('/p/pedir', extra: r.lugar);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final viaje = ref.watch(viajePasajeroProvider).value;
    final centro = ref.watch(ubicacionProvider).value ?? kCentroPorDefecto;
    return RevisionPermisos(
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: MapaNexa(
                centro: centro,
                pasajero: centro,
                orientable: true,
                // Debajo del encabezado.
                brujulaArriba: Sp.md + Sizes.boton + Sp.md,
              ),
            ),
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(Sp.md),
                child: _Encabezado(),
              ),
            ),
            NexaHojaArrastrable(
              inicial: 0.52,
              minimo: 0.3,
              children: [
                Text(l.buscadorHint, style: NexaTexto.titulo),
                const SizedBox(height: Sp.md),
                _Buscador(onTap: () => _elegirDestino(context, ref)),
                const SizedBox(height: Sp.md),
                const NivelBanner(rutaNiveles: '/p/niveles', irEnLugar: true),
                if (viaje != null) ...[
                  const SizedBox(height: Sp.md),
                  NexaCard(
                    onTap: () => context.push('/p/viaje'),
                    child: Row(
                      children: [
                        Icon(Icons.two_wheeler, color: context.acento),
                        const SizedBox(width: Sp.md),
                        Expanded(
                          child: Text(
                            '${l.viajeEnCursoTitulo}: '
                            '${estadoTexto(l, viaje.estado)}',
                            style: context.textos.titleSmall,
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: Sp.xl),
                const _ViajesRecientes(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _saludo(AppLocalizations l, int hora) {
  if (hora < 12) return l.saludoManana;
  if (hora < 19) return l.saludoTarde;
  return l.saludoNoche;
}

/// Saludo flotante sobre el mapa: avatar con anillo de nivel y campana.
class _Encabezado extends ConsumerWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final perfil = ref.watch(perfilPasajeroProvider);
    final historial = ref.watch(historialPasajeroProvider).value;
    final nivel = ref.watch(nivelProvider).value;
    final p = perfil.value;
    final viajes =
        p?.viajes ??
        historial?.where((s) => s.estado.name == 'finalizado').length;
    return Row(
      children: [
        Flexible(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: NexaColors.glass,
              borderRadius: BorderRadius.circular(Rad.pill),
              border: Border.all(color: NexaColors.line),
              boxShadow: NexaShadows.card,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Sp.sm, Sp.sm, Sp.xl, Sp.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NexaAvatarAnillo(
                    iniciales: p?.iniciales ?? '·',
                    progreso: nivel?.progreso ?? 0,
                    diametro: 46,
                  ),
                  const SizedBox(width: Sp.md),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _saludo(l, DateTime.now().hour),
                          style: context.textos.bodySmall?.copyWith(
                            color: context.muted,
                          ),
                        ),
                        Text(
                          p?.nombre ?? '',
                          style: context.textos.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (perfil.hasError)
                          Text(AppException.from(perfil.error!).mensaje)
                        else if (nivel == null)
                          _Reputacion(perfil: p, viajes: viajes),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: l.notificaciones,
          onPressed: () =>
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(l.sinNotificaciones))),
          icon: const Icon(Icons.notifications_none),
          style: IconButton.styleFrom(
            minimumSize: const Size.square(Sizes.touch),
            backgroundColor: NexaColors.glass,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Rad.md),
              side: const BorderSide(color: NexaColors.line),
            ),
          ),
        ),
      ],
    );
  }
}

class _Reputacion extends StatelessWidget {
  const _Reputacion({required this.perfil, required this.viajes});
  final PerfilPasajero? perfil;
  final int? viajes;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cal = perfil?.calificacion;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (cal != null) ...[
          const Icon(Icons.star, size: 16, color: NexaColors.gold),
          const SizedBox(width: Sp.xs),
          Text(
            cal.toStringAsFixed(1).replaceAll('.', ','),
            style: context.textos.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: Sp.sm),
        ],
        if (viajes != null)
          Flexible(
            child: Text(
              '· ${l.viajesCantidad(viajes!)}',
              style: context.textos.bodySmall?.copyWith(color: context.muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

/// Buscador grande «¿A dónde vas hoy?» con el contorno de neón del rediseño.
class _Buscador extends StatelessWidget {
  const _Buscador({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l.buscadorHint,
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(Rad.lg + 2),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: NexaColors.card,
              borderRadius: BorderRadius.circular(Rad.lg + 2),
              border: Border.all(
                color: NexaColors.cyan.withValues(alpha: 0.7),
                width: 1.5,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.lg,
                  vertical: Sp.sm,
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: context.acento, size: 22),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Text(
                        l.buscaUnDestino,
                        style: NexaTexto.cuerpo.copyWith(
                          color: NexaColors.muted,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Sp.md,
                        vertical: Sp.sm,
                      ),
                      decoration: BoxDecoration(
                        color: NexaColors.raised,
                        borderRadius: BorderRadius.circular(Rad.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, size: 14),
                          const SizedBox(width: Sp.xs),
                          Text(l.ahora, style: context.textos.labelMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ViajesRecientes extends ConsumerWidget {
  const _ViajesRecientes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final historial = ref.watch(historialPasajeroProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.viajesRecientes,
                style: context.textos.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/p/viajes'),
              child: Text(l.verTodo),
            ),
          ],
        ),
        const SizedBox(height: Sp.sm),
        historial.when(
          loading: () => const CargandoSkeleton(filas: 2),
          error: (e, _) => EstadoError(
            mensaje: AppException.from(e).mensaje,
            onReintentar: () => ref.invalidate(historialPasajeroProvider),
          ),
          data: (lista) {
            final recientes = lista.where((s) => !s.estado.activo).take(3);
            if (recientes.isEmpty) {
              return EstadoVacio(
                titulo: l.vacioHistorial,
                detalle: l.vacioHistorialDetalle,
                icon: Icons.history,
              );
            }
            return Column(
              children: [
                for (final s in recientes) ...[
                  ViajeTile(servicio: s),
                  const SizedBox(height: Sp.sm),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
