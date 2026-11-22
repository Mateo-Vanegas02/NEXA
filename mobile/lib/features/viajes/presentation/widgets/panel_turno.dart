import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/mi_posicion.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../../auth/presentation/controllers/perfil_controller.dart';
import '../../domain/resumen_ganancias.dart';
import '../controllers/viaje_conductor_controller.dart';

String _saludo(AppLocalizations l, int hora) {
  if (hora < 12) return l.saludoManana;
  if (hora < 19) return l.saludoTarde;
  return l.saludoNoche;
}

/// Hoja del conductor fuera de línea (rediseño 2026): saludo, deslizador
/// grande para conectarse y lo ganado hoy y en la semana.
class PanelFueraDeLinea extends ConsumerWidget {
  const PanelFueraDeLinea({required this.onConectar, super.key});

  final Future<void> Function() onConectar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final ahora = DateTime.now();
    final nombre = (ref.watch(perfilProvider).value?.nombre ?? '')
        .trim()
        .split(' ')
        .first;
    final todos = ref.watch(ingresosProvider).value ?? const [];
    final hoy = ResumenGanancias.delPeriodo(
      todos,
      PeriodoGanancias.hoy,
      ahora,
    );
    final semana = ResumenGanancias.delPeriodo(
      todos,
      PeriodoGanancias.semana,
      ahora,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          nombre.isEmpty
              ? _saludo(l, ahora.hour)
              : '${_saludo(l, ahora.hour)}, $nombre',
          style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
        ),
        Text(l.listoParaRodar, style: NexaTexto.titulo),
        const SizedBox(height: Sp.md),
        NexaDeslizar(texto: l.deslizaConectarte, onConfirmado: onConectar),
        const SizedBox(height: Sp.md),
        Row(
          children: [
            Expanded(
              child: _Cifra(
                titulo: l.periodoHoy,
                valor: Fmt.cop(ResumenGanancias.total(hoy)),
                detalle: l.viajesCuenta(hoy.length),
              ),
            ),
            const SizedBox(width: Sp.md),
            Expanded(
              child: _Cifra(
                titulo: l.ultimos7Dias,
                valor: Fmt.cop(ResumenGanancias.total(semana)),
                detalle: l.viajesCuenta(semana.length),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Hoja del conductor en línea sin viaje (rediseño 2026): lo ganado hoy, hora
/// por hora si el servidor envía la hora de cada viaje, y la señal del GPS.
class PanelEnLinea extends ConsumerWidget {
  const PanelEnLinea({required this.onDesconectar, super.key});

  final Future<void> Function() onDesconectar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final ahora = DateTime.now();
    final todos = ref.watch(ingresosProvider).value ?? const [];
    final hoy = ResumenGanancias.delPeriodo(
      todos,
      PeriodoGanancias.hoy,
      ahora,
    );
    final horas = ResumenGanancias.horasConActividad(
      ResumenGanancias.porHora(hoy, ahora),
      ahora,
    );
    final gps = ref.watch(posicionEnVivoProvider).value;
    final gpsVivo =
        gps != null &&
        ahora.difference(gps.en) < const Duration(seconds: 20);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.ganadoHoy,
                    style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Fmt.cop(ResumenGanancias.total(hoy)),
                      style: NexaTexto.numero.copyWith(fontSize: 36),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Sp.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l.viajesCuenta(hoy.length),
                  style: NexaTexto.subtitulo.copyWith(fontSize: 15),
                ),
                const SizedBox(height: Sp.xs),
                _ChipGps(vivo: gpsVivo),
              ],
            ),
          ],
        ),
        if (horas.montos.length > 1) ...[
          const SizedBox(height: Sp.md),
          _BarrasHoras(montos: horas.montos),
        ],
        const SizedBox(height: Sp.md),
        Row(
          children: [
            const _Pulso(),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Text(
                l.buscandoSolicitudes,
                style: NexaTexto.subtitulo.copyWith(fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: onDesconectar,
              child: Text(
                l.desconectarme,
                style: const TextStyle(color: NexaColors.muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.titulo,
    required this.valor,
    required this.detalle,
  });
  final String titulo;
  final String valor;
  final String detalle;

  @override
  Widget build(BuildContext context) => NexaCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: NexaTexto.pequeno.copyWith(color: NexaColors.muted)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(valor, style: NexaTexto.numeroMedio.copyWith(fontSize: 21)),
        ),
        Text(detalle, style: NexaTexto.pequeno.copyWith(color: NexaColors.ok)),
      ],
    ),
  );
}

class _ChipGps extends StatelessWidget {
  const _ChipGps({required this.vivo});
  final bool vivo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = vivo ? NexaColors.ok : NexaColors.gold;
    return Semantics(
      label: vivo ? l.gpsActivo : l.gpsSinSenal,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(Rad.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                vivo ? Icons.gps_fixed : Icons.gps_not_fixed,
                size: 14,
                color: color,
              ),
              const SizedBox(width: Sp.xs),
              Text(
                vivo ? l.gpsActivo : l.gpsSinSenal,
                style: NexaTexto.pequeno.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barras de lo ganado por hora hoy; la última (la hora actual) resaltada.
class _BarrasHoras extends StatelessWidget {
  const _BarrasHoras({required this.montos});
  final List<double> montos;

  @override
  Widget build(BuildContext context) {
    final mayor = montos.fold<double>(0, (a, b) => b > a ? b : a);
    return ExcludeSemantics(
      child: SizedBox(
        height: 44,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < montos.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    height: mayor <= 0
                        ? 4
                        : (montos[i] / mayor * 44).clamp(4.0, 44.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: i == montos.length - 1
                          ? null
                          : NexaColors.cyan.withValues(alpha: 0.22),
                      gradient: i == montos.length - 1
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [NexaColors.cyan, NexaColors.azul],
                            )
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Punto verde con halo: el conductor está disponible.
class _Pulso extends StatelessWidget {
  const _Pulso();

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: NexaColors.ok.withValues(alpha: 0.18),
    ),
    child: Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: NexaColors.ok,
      ),
    ),
  );
}
