import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/agrupar_viajes.dart';
import '../../domain/servicio.dart';
import '../controllers/viaje_pasajero_controller.dart';
import '../widgets/viaje_tile.dart';

enum _Filtro { todos, completados, cancelados }

/// Actividad del pasajero (diseño P10): resumen del mes, filtros y los viajes
/// agrupados por hoy, esta semana y antes.
class HistorialPasajeroScreen extends ConsumerStatefulWidget {
  const HistorialPasajeroScreen({super.key});

  @override
  ConsumerState<HistorialPasajeroScreen> createState() =>
      _HistorialPasajeroScreenState();
}

class _HistorialPasajeroScreenState
    extends ConsumerState<HistorialPasajeroScreen> {
  _Filtro _filtro = _Filtro.todos;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final historial = ref.watch(historialPasajeroProvider);
    final abajo = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: historial.when(
          loading: () => const CargandoSkeleton(),
          error: (e, _) => EstadoError(
            mensaje: AppException.from(e).mensaje,
            onReintentar: () => ref.invalidate(historialPasajeroProvider),
          ),
          data: (lista) {
            final ahora = DateTime.now();
            final cerrados = lista.where((s) => !s.estado.activo).toList();
            final filtrados = cerrados.where(
              (s) => switch (_filtro) {
                _Filtro.todos => true,
                _Filtro.completados => s.estado == EstadoServicio.finalizado,
                _Filtro.cancelados => s.estado == EstadoServicio.cancelado,
              },
            );
            final grupos = agruparPorTramo(filtrados.toList(), ahora);
            final delMes = cerrados.where(
              (s) =>
                  s.estado == EstadoServicio.finalizado &&
                  s.fechaHora != null &&
                  s.fechaHora!.year == ahora.year &&
                  s.fechaHora!.month == ahora.month,
            );
            final gastado = delMes.fold<double>(
              0,
              (a, s) => a + s.tarifa + s.extraVoluntario,
            );
            final kmMes = delMes.fold<double>(0, (a, s) => a + s.distanciaKM);
            return RefreshIndicator(
              onRefresh: () => ref.refresh(historialPasajeroProvider.future),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  context.gutter,
                  Sp.lg,
                  context.gutter,
                  Sp.xl + abajo,
                ),
                children: [
                  ContenidoCentrado(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.navActividad,
                          style: NexaTexto.titulo.copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: Sp.lg),
                        // Dos cifras del mes (rediseño 2026): lo gastado y
                        // lo recorrido, ambas con datos del servidor.
                        Row(
                          children: [
                            Expanded(
                              child: NexaCard(
                                child: _Cifra(
                                  titulo: l.esteMes,
                                  valor: Fmt.cop(gastado),
                                  texto: l.viajesCuenta(delMes.length),
                                  color: NexaColors.ok,
                                ),
                              ),
                            ),
                            const SizedBox(width: Sp.md),
                            Expanded(
                              child: NexaCard(
                                child: _Cifra(
                                  titulo: l.recorridoMes,
                                  valor:
                                      '${NumberFormat('0.#', 'es_CO').format(kmMes)} km',
                                  texto: l.enMoto,
                                  color: NexaColors.cyan,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Sp.lg),
                        // En una sola línea (se desliza si la letra es grande).
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                          children: [
                            for (final (f, texto) in [
                              (_Filtro.todos, l.filtroTodos),
                              (_Filtro.completados, l.filtroCompletados),
                              (_Filtro.cancelados, l.filtroCancelados),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: Sp.sm),
                                child: ChoiceChip(
                                visualDensity: VisualDensity.compact,
                                label: Text(texto),
                                selected: _filtro == f,
                                showCheckmark: false,
                                onSelected: (_) => setState(() => _filtro = f),
                                selectedColor: NexaColors.cyan,
                                backgroundColor: NexaColors.card,
                                side: const BorderSide(color: NexaColors.line),
                                shape: const StadiumBorder(),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _filtro == f
                                      ? NexaColors.bg
                                      : NexaColors.texto,
                                ),
                              ),
                              ),
                          ],
                          ),
                        ),
                        const SizedBox(height: Sp.lg),
                        if (grupos.isEmpty)
                          EstadoVacio(
                            titulo: l.vacioHistorial,
                            detalle: l.vacioHistorialDetalle,
                            icon: Icons.history,
                          ),
                        for (final g in grupos.entries) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: Sp.xs,
                              bottom: Sp.sm,
                              top: Sp.sm,
                            ),
                            child: Text(
                              switch (g.key) {
                                TramoFecha.hoy => l.tramoHoy,
                                TramoFecha.semana => l.tramoSemana,
                                TramoFecha.antes => l.tramoAntes,
                              }.toUpperCase(),
                              style: NexaTexto.etiqueta.copyWith(
                                color: NexaColors.tenue,
                              ),
                            ),
                          ),
                          for (final s in g.value) ...[
                            ViajeTile(servicio: s),
                            const SizedBox(height: Sp.sm),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.titulo,
    required this.valor,
    required this.texto,
    required this.color,
  });
  final String titulo;
  final String valor;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(titulo, style: NexaTexto.pequeno.copyWith(color: NexaColors.muted)),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(valor, style: NexaTexto.numeroMedio),
      ),
      Text(texto, style: NexaTexto.pequeno.copyWith(color: color)),
    ],
  );
}
