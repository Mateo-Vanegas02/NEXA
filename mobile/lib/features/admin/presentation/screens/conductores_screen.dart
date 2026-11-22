import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../../satisfaccion/presentation/widgets/satisfaccion_widgets.dart';
import '../../../viajes/presentation/widgets/piezas_viaje.dart';
import '../../domain/admin.dart';
import '../controllers/admin_controller.dart';

/// Conductores del admin (rediseño 2026): por estado de la revisión; tocar uno
/// abre su expediente para aprobarlo, pedir información o rechazarlo.
class ConductoresScreen extends ConsumerStatefulWidget {
  const ConductoresScreen({super.key});

  @override
  ConsumerState<ConductoresScreen> createState() => _ConductoresScreenState();
}

class _ConductoresScreenState extends ConsumerState<ConductoresScreen> {
  EstadoRevision _estado = EstadoRevision.pendiente;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lista = ref.watch(conductoresRevisionProvider(_estado));
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () =>
                ref.refresh(conductoresRevisionProvider(_estado).future),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                context.gutter,
                0,
                context.gutter,
                120 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                ContenidoCentrado(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EncabezadoSat(
                        etiqueta: l.adminRol,
                        titulo: l.adminConductores,
                      ),
                      const SizedBox(height: Sp.md),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final (e, texto) in [
                              (EstadoRevision.pendiente, l.revisionPendientes),
                              (EstadoRevision.enRevision, l.revisionEnRevision),
                              (EstadoRevision.aprobado, l.revisionAprobados),
                              (EstadoRevision.rechazado, l.revisionRechazados),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: Sp.sm),
                                child: ChoiceChip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(texto),
                                  selected: _estado == e,
                                  showCheckmark: false,
                                  onSelected: (_) =>
                                      setState(() => _estado = e),
                                  selectedColor: NexaColors.cyan,
                                  backgroundColor: NexaColors.card,
                                  side: const BorderSide(
                                    color: NexaColors.line,
                                  ),
                                  shape: const StadiumBorder(),
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _estado == e
                                        ? NexaColors.bg
                                        : NexaColors.texto,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Sp.md),
                      ...lista.when(
                        loading: () => [
                          const SizedBox(
                            height: 240,
                            child: CargandoSkeleton(),
                          ),
                        ],
                        error: (e, _) => [
                          SizedBox(
                            height: 260,
                            child: EstadoError(
                              mensaje: AppException.from(e).mensaje,
                              onReintentar: () => ref.invalidate(
                                conductoresRevisionProvider(_estado),
                              ),
                            ),
                          ),
                        ],
                        data: (cs) => cs.isEmpty
                            ? [
                                SizedBox(
                                  height: 240,
                                  child: EstadoVacio(
                                    titulo: l.revisionVacia,
                                    icon: Icons.verified_user_outlined,
                                  ),
                                ),
                              ]
                            : [
                                for (final c in cs) ...[
                                  _FilaConductor(conductor: c),
                                  const SizedBox(height: Sp.sm),
                                ],
                              ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaConductor extends StatelessWidget {
  const _FilaConductor({required this.conductor});
  final ConductorRevision conductor;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = conductor;
    final nombre = c.nombre.isEmpty ? c.email : c.nombre;
    final f = c.fechaRegistro;
    return TarjetaSat(
      onTap: () => context.push('/a/conductores/revision', extra: c),
      child: Row(
        children: [
          AvatarIniciales(nombre: nombre, diametro: 44),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: NexaTexto.subtitulo.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  c.email,
                  style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (f != null)
                  Text(
                    l.registradoEl(
                      DateFormat('d MMM, H:mm', 'es_CO').format(f),
                    ),
                    style: NexaTexto.pequeno.copyWith(color: NexaColors.tenue),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: NexaColors.muted),
        ],
      ),
    );
  }
}
