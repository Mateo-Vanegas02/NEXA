import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/satisfaccion.dart';
import '../controllers/satisfaccion_controller.dart';
import '../widgets/satisfaccion_widgets.dart';

/// Hoja inferior "Programar entrenamiento" (diario, semanal o cada N horas).
Future<void> mostrarProgramar(BuildContext context, Programacion actual) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: fondoTarjeta(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Rad.sheet)),
      ),
      builder: (_) => ProgramarSheet(inicial: actual),
    );

/// Opciones de "Cada N horas" (el servidor admite de 1 a 168).
const kOpcionesHoras = [1, 3, 6, 12, 24, 48];

class ProgramarSheet extends ConsumerStatefulWidget {
  const ProgramarSheet({required this.inicial, super.key});

  final Programacion inicial;

  @override
  ConsumerState<ProgramarSheet> createState() => _ProgramarSheetState();
}

class _ProgramarSheetState extends ConsumerState<ProgramarSheet> {
  late Programacion _p = widget.inicial.copyWith(
    activa: true,
    cadaHoras: widget.inicial.cadaHoras ?? 6,
    dias: widget.inicial.dias.isEmpty
        ? const {DiaSemana.dom}
        : widget.inicial.dias,
  );
  bool _guardando = false;

  Future<void> _elegirHora() async {
    final partes = _p.hora.split(':');
    final elegida = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(partes.first) ?? 2,
        minute: int.tryParse(partes.last) ?? 0,
      ),
    );
    if (elegida == null || !mounted) return;
    String dos(int n) => n.toString().padLeft(2, '0');
    setState(
      () =>
          _p = _p.copyWith(hora: '${dos(elegida.hour)}:${dos(elegida.minute)}'),
    );
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(modeloProvider.notifier).guardarProgramacion(_p);
      if (!mounted) return;
      // maybePop: dentro de la hoja la cierra; fuera de ella no hace nada.
      await Navigator.of(context).maybePop();
      messenger.showSnackBar(
        SnackBar(content: Text(l.satProgramacionGuardada)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      messenger.showSnackBar(
        SnackBar(content: Text(AppException.from(e).mensaje)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.textos;
    final etiqueta = t.labelSmall?.copyWith(
      color: context.muted,
      fontWeight: FontWeight.w600,
    );
    final letras = [
      l.satDiaLun,
      l.satDiaMar,
      l.satDiaMie,
      l.satDiaJue,
      l.satDiaVie,
      l.satDiaSab,
      l.satDiaDom,
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.sm, Sp.xl, Sp.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: Sp.md),
                decoration: BoxDecoration(
                  color: NexaColors.line,
                  borderRadius: BorderRadius.circular(Rad.pill),
                ),
              ),
            ),
            Semantics(
              header: true,
              child: Text(
                l.satProgramarTitulo,
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: Sp.xs),
            Text(
              l.satProgramarDetalle,
              style: t.bodySmall?.copyWith(color: context.muted),
            ),
            const SizedBox(height: Sp.lg),
            Text(l.satFrecuencia, style: etiqueta),
            const SizedBox(height: Sp.sm),
            SelectorSegmentado<Frecuencia>(
              opciones: [
                (Frecuencia.diaria, l.satDiaria),
                (Frecuencia.semanal, l.satSemanal),
                (Frecuencia.cadaHoras, l.satCadaHoras),
              ],
              seleccion: _p.frecuencia,
              onSeleccion: (f) =>
                  setState(() => _p = _p.copyWith(frecuencia: f)),
            ),
            const SizedBox(height: Sp.lg),
            if (_p.frecuencia == Frecuencia.semanal) ...[
              Text(l.satDias, style: etiqueta),
              const SizedBox(height: Sp.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final d in DiaSemana.values)
                    _Dia(
                      letra: letras[d.index],
                      activo: _p.dias.contains(d),
                      onTap: () => setState(() {
                        final dias = {..._p.dias};
                        if (!dias.remove(d)) dias.add(d);
                        _p = _p.copyWith(dias: dias);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: Sp.lg),
            ],
            if (_p.frecuencia == Frecuencia.cadaHoras) ...[
              Text(l.satIntervalo, style: etiqueta),
              const SizedBox(height: Sp.sm),
              ChipsFiltro<int>(
                opciones: [
                  for (final h in kOpcionesHoras)
                    (h, l.satCadaHorasValor('$h')),
                ],
                seleccion: _p.cadaHoras ?? 6,
                onSeleccion: (h) =>
                    setState(() => _p = _p.copyWith(cadaHoras: h)),
              ),
              const SizedBox(height: Sp.lg),
            ] else ...[
              Text(l.satHoraBogota, style: etiqueta),
              const SizedBox(height: Sp.sm),
              Material(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Rad.md),
                  side: BorderSide(color: bordeSuave(context)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Rad.md),
                  onTap: _elegirHora,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Sp.md,
                      vertical: Sp.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _p.hora.replaceAll(':', ' : '),
                            style: t.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(Icons.schedule, color: context.acento),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Sp.lg),
            ],
            Divider(color: bordeSuave(context)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _p.soloConDatosNuevos,
              onChanged: (v) =>
                  setState(() => _p = _p.copyWith(soloConDatosNuevos: v)),
              title: Text(l.satSoloDatosNuevos, style: t.titleSmall),
              subtitle: Text(
                l.satSoloDatosNuevosDetalle('${_p.minimoViajesNuevos}'),
                style: t.bodySmall?.copyWith(color: context.muted),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _p.publicarSoloSiMejora,
              onChanged: (v) =>
                  setState(() => _p = _p.copyWith(publicarSoloSiMejora: v)),
              title: Text(l.satPublicarSiMejora, style: t.titleSmall),
              subtitle: Text(
                l.satPublicarSiMejoraDetalle,
                style: t.bodySmall?.copyWith(color: context.muted),
              ),
            ),
            if (!_p.esValida) ...[
              const SizedBox(height: Sp.sm),
              Text(
                l.satProgramacionInvalida,
                style: t.bodySmall?.copyWith(color: colorMalo(context)),
              ),
            ],
            const SizedBox(height: Sp.lg),
            NexaButton(
              label: l.satGuardarProgramacion,
              cargando: _guardando,
              onPressed: _p.esValida ? _guardar : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Dia extends StatelessWidget {
  const _Dia({required this.letra, required this.activo, required this.onTap});

  final String letra;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: activo,
    button: true,
    child: Material(
      color: activo
          ? context.acento
          : Theme.of(context).scaffoldBackgroundColor,
      shape: CircleBorder(
        side: BorderSide(color: activo ? context.acento : bordeSuave(context)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 40,
          child: Center(
            child: Text(
              letra,
              style: context.textos.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: activo ? context.colors.onPrimary : null,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
