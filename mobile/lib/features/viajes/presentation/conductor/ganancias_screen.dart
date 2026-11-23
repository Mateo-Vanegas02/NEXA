import '../../../../core/theme/theme_x.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../../../core/providers.dart';
import '../../domain/agrupar_viajes.dart';
import '../../domain/resumen_ganancias.dart';
import '../../domain/servicio.dart';
import '../widgets/detalle_viaje_screen.dart';
import '../controllers/viaje_conductor_controller.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Selector Hoy · Semana · 30 días (rediseño 2026).
class _SelectorPeriodo extends StatelessWidget {
  const _SelectorPeriodo({required this.actual, required this.onCambio});
  final PeriodoGanancias actual;
  final ValueChanged<PeriodoGanancias> onCambio;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(Sp.xs),
      decoration: BoxDecoration(
        color: NexaColors.card,
        borderRadius: BorderRadius.circular(Rad.lg),
        border: Border.all(color: NexaColors.line),
      ),
      child: Row(
        children: [
          for (final (p, texto) in [
            (PeriodoGanancias.hoy, l.periodoHoy),
            (PeriodoGanancias.semana, l.periodoSemana),
            (PeriodoGanancias.treinta, l.periodo30Dias),
          ])
            Expanded(
              child: Semantics(
                button: true,
                selected: p == actual,
                child: InkWell(
                  borderRadius: BorderRadius.circular(Rad.md),
                  onTap: () => onCambio(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    constraints: const BoxConstraints(minHeight: 40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Rad.md),
                      gradient: p == actual
                          ? const LinearGradient(
                              colors: [NexaColors.cyan, NexaColors.azul],
                            )
                          : null,
                    ),
                    child: Text(
                      texto,
                      style: NexaTexto.boton.copyWith(
                        fontSize: 14,
                        color: p == actual ? NexaColors.bg : NexaColors.muted,
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

/// Barras con etiqueta debajo; la más alta va en degradado y con su monto.
class _Barras extends StatelessWidget {
  const _Barras({required this.montos, required this.etiquetas});
  final List<double> montos;

  /// Una por barra ('' = sin etiqueta).
  final List<String> etiquetas;

  static const double _alto = 120;

  @override
  Widget build(BuildContext context) {
    final mayor = montos.fold<double>(0, (a, b) => b > a ? b : a);
    final iMayor = mayor <= 0 ? -1 : montos.indexOf(mayor);
    final finas = montos.length > 14;
    final compacto = NumberFormat.compactCurrency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    );
    return ExcludeSemantics(
      child: SizedBox(
        height: _alto + 40,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < montos.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: finas ? 1 : 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (i == iMayor && !finas)
                        FittedBox(
                          child: Text(
                            compacto.format(mayor),
                            style: NexaTexto.pequeno.copyWith(
                              color: NexaColors.cyan,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Container(
                        height: mayor <= 0
                            ? 4
                            : (montos[i] / mayor * _alto).clamp(4.0, _alto),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(finas ? 3 : 8),
                          color: i == iMayor
                              ? null
                              : NexaColors.cyan.withValues(alpha: 0.22),
                          gradient: i == iMayor
                              ? const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [NexaColors.cyan, NexaColors.azul],
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: Sp.xs),
                      SizedBox(
                        height: 16,
                        child: FittedBox(
                          child: Text(
                            etiquetas[i],
                            style: NexaTexto.pequeno.copyWith(
                              color: i == iMayor
                                  ? NexaColors.texto
                                  : NexaColors.tenue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Una cifra en tarjeta (cobrado / debes a NEXA).
class _Cifra extends StatelessWidget {
  const _Cifra({required this.titulo, required this.valor, this.color});
  final String titulo;
  final String valor;
  final Color? color;

  @override
  Widget build(BuildContext context) => NexaCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: NexaTexto.pequeno.copyWith(color: color ?? NexaColors.muted),
        ),
        const SizedBox(height: Sp.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            valor,
            style: NexaTexto.numeroMedio.copyWith(fontSize: 20),
          ),
        ),
      ],
    ),
  );
}

/// Ganancias del conductor (rediseño 2026): período, total, barras por día
/// (o por hora hoy), lo cobrado frente a lo que se debe a NEXA y los viajes.
/// Todas las cifras son las del servidor; aquí solo se agrupan.
class GananciasScreen extends ConsumerStatefulWidget {
  const GananciasScreen({super.key});

  @override
  ConsumerState<GananciasScreen> createState() => _GananciasScreenState();
}

class _GananciasScreenState extends ConsumerState<GananciasScreen> {
  PeriodoGanancias _periodo = PeriodoGanancias.semana;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ingresos = ref.watch(ingresosProvider);
    final saldo = ref.watch(saldoProvider(_periodo.dias)).value;
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          bottom: false,
          child: ingresos.when(
            loading: () => const CargandoSkeleton(),
            error: (e, _) => EstadoError(
              mensaje: AppException.from(e).mensaje,
              onReintentar: () => ref.invalidate(ingresosProvider),
            ),
            data: (todos) {
              final ahora = DateTime.now();
              final lista = ResumenGanancias.delPeriodo(todos, _periodo, ahora);
              final total = ResumenGanancias.total(lista);
              final dias = DateFormat('d MMM', 'es_CO');
              final rango = _periodo == PeriodoGanancias.hoy
                  ? DateFormat("EEEE d 'de' MMMM", 'es_CO').format(ahora)
                  : '${dias.format(ahora.subtract(Duration(days: _periodo.dias - 1)))} – ${dias.format(ahora)}';
              // Barras: por hora hoy (si el servidor envía la hora), por día
              // en la semana y en 30 días.
              List<double> montos;
              List<String> etiquetas;
              if (_periodo == PeriodoGanancias.hoy) {
                final h = ResumenGanancias.horasConActividad(
                  ResumenGanancias.porHora(lista, ahora),
                  ahora,
                );
                montos = h.montos;
                etiquetas = [
                  for (var i = 0; i < montos.length; i++) '${h.desde + i}h',
                ];
              } else {
                montos = ResumenGanancias.porDia(lista, _periodo.dias, ahora);
                final letra = DateFormat('EEEEE', 'es_CO');
                etiquetas = [
                  for (var i = 0; i < montos.length; i++)
                    _periodo == PeriodoGanancias.semana
                        ? letra
                              .format(
                                ahora.subtract(
                                  Duration(days: montos.length - 1 - i),
                                ),
                              )
                              .toUpperCase()
                        // En 30 días, una fecha por semana (la última es hoy).
                        : ((montos.length - 1 - i) % 7 == 0
                              ? '${ahora.subtract(Duration(days: montos.length - 1 - i)).day}'
                              : ''),
                ];
              }
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  context.gutter,
                  Sp.lg,
                  context.gutter,
                  Sp.xl + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  ContenidoCentrado(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.gananciasTitulo,
                          style: NexaTexto.titulo.copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: Sp.md),
                        _SelectorPeriodo(
                          actual: _periodo,
                          onCambio: (p) => setState(() => _periodo = p),
                        ),
                        const SizedBox(height: Sp.lg),
                        Text(
                          rango,
                          style: NexaTexto.pequeno.copyWith(
                            color: NexaColors.muted,
                          ),
                        ),
                        Semantics(
                          label: '${l.gananciaTotal}: ${Fmt.cop(total)}',
                          child: ExcludeSemantics(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                Fmt.cop(total),
                                style: NexaTexto.numero.copyWith(fontSize: 40),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          lista.isEmpty
                              ? l.viajesCuenta(0)
                              : l.viajesYPromedio(
                                  lista.length,
                                  Fmt.cop(total / lista.length),
                                ),
                          style: NexaTexto.pequeno.copyWith(
                            color: NexaColors.muted,
                          ),
                        ),
                        if (montos.isNotEmpty && total > 0) ...[
                          const SizedBox(height: Sp.md),
                          NexaCard(
                            child: _Barras(
                              montos: montos,
                              etiquetas: etiquetas,
                            ),
                          ),
                        ],
                        if (saldo != null) ...[
                          const SizedBox(height: Sp.md),
                          Row(
                            children: [
                              Expanded(
                                child: _Cifra(
                                  titulo: l.cobradoEfectivo,
                                  valor: Fmt.cop(saldo.cobradoEfectivo),
                                ),
                              ),
                              const SizedBox(width: Sp.md),
                              Expanded(
                                child: _Cifra(
                                  titulo: saldo.saldoConNexa >= 0
                                      ? l.debesANexa
                                      : l.nexaTeDebe,
                                  valor: Fmt.cop(saldo.saldoConNexa.abs()),
                                  color: saldo.saldoConNexa >= 0
                                      ? NexaColors.gold
                                      : NexaColors.ok,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: Sp.md),
                        if (lista.isEmpty)
                          SizedBox(
                            height: 200,
                            child: EstadoVacio(
                              titulo: l.vacioHistorial,
                              detalle: l.vacioHistorialDetalle,
                              icon: Icons.payments_outlined,
                            ),
                          )
                        else ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: Sp.xs,
                              top: Sp.sm,
                              bottom: Sp.sm,
                            ),
                            child: Text(
                              l.ultimosViajes.toUpperCase(),
                              style: NexaTexto.etiqueta.copyWith(
                                color: NexaColors.tenue,
                              ),
                            ),
                          ),
                          NexaCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Sp.lg,
                              vertical: Sp.xs,
                            ),
                            child: Column(
                              children: [
                                for (
                                  var k = 0;
                                  k < lista.length && k < 20;
                                  k++
                                ) ...[
                                  if (k > 0)
                                    Divider(
                                      height: 1,
                                      color: context.colors.outline.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  _FilaIngreso(
                                    descripcion: lista[k].descripcion,
                                    fecha: lista[k].fecha,
                                    monto: lista[k].monto,
                                    onTap: () =>
                                        _abrirDetalle(context, ref, lista[k]),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// «2026-11-22» → «22 nov» (o la hora si el servidor la envía).
String _fecha(String iso) {
  final f = DateTime.tryParse(iso);
  return f == null ? iso : DateFormat('EEE d MMM', 'es_CO').format(f);
}

/// Historial del conductor (para abrir el detalle de un ingreso).
final historialConductorProvider = FutureProvider.autoDispose<List<Servicio>>(
  (ref) => ref.watch(conductorRepositoryProvider).historial(),
);

/// Abre el detalle del viaje de un ingreso (lo busca en el historial).
Future<void> _abrirDetalle(
  BuildContext context,
  WidgetRef ref,
  Ingreso ingreso,
) async {
  final mensajero = ScaffoldMessenger.of(context);
  final l = AppLocalizations.of(context);
  try {
    final viajes = await ref.read(historialConductorProvider.future);
    final s = servicioDeIngreso(ingreso, viajes);
    if (s != null && context.mounted) {
      await abrirDetalleViaje(context, s, conductor: true);
      return;
    }
  } on Object catch (e) {
    debugPrint('Historial del conductor: $e');
  }
  mensajero.showSnackBar(SnackBar(content: Text(l.detalleNoEncontrado)));
}

class _FilaIngreso extends StatelessWidget {
  const _FilaIngreso({
    required this.descripcion,
    required this.fecha,
    required this.monto,
    this.onTap,
  });
  final String descripcion;
  final String fecha;
  final double monto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Rad.md),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: NexaColors.cyan.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.place_outlined, size: 18, color: context.acento),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descripcion,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  _fecha(fecha),
                  style: t.bodySmall?.copyWith(color: context.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: Sp.sm),
          Text(
            Fmt.cop(monto),
            style: t.titleSmall?.copyWith(
              color: NexaColors.ok,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
    );
  }
}
