import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/factores_calificacion.dart';
import '../../domain/servicio.dart';
import '../controllers/viaje_conductor_controller.dart';
import '../widgets/calificacion_widgets.dart';
import '../widgets/piezas_viaje.dart';

/// El conductor califica a la pasajera (diseño C07): opcional, con estrellas,
/// factores del conductor y comentario. Ella no ve lo que marque.
class CalificarPasajeroScreen extends ConsumerStatefulWidget {
  const CalificarPasajeroScreen({required this.servicio, super.key});
  final Servicio servicio;

  @override
  ConsumerState<CalificarPasajeroScreen> createState() =>
      _CalificarPasajeroScreenState();
}

class _CalificarPasajeroScreenState
    extends ConsumerState<CalificarPasajeroScreen> {
  final _comentario = TextEditingController();
  final Set<String> _factores = {};
  double _estrellas = 5;
  bool _enviando = false;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  void _salir() =>
      context.canPop() ? context.pop() : context.go('/c/inicio');

  Future<void> _enviar() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _enviando = true);
    try {
      await ref
          .read(conductorProvider.notifier)
          .calificarPasajero(
            widget.servicio.id,
            _estrellas,
            _comentario.text.trim(),
            factores: FactoresCalificacion.validos(
              _estrellas,
              _factores,
              conductor: true,
            ),
          );
      messenger.showSnackBar(SnackBar(content: Text(l.gracias)));
      if (mounted) _salir();
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppException.from(e).mensaje)),
      );
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final nombreCompleto = widget.servicio.pasajero?.nombre ?? '';
    final nombre = nombreCompleto.isEmpty
        ? l.rolPasajero
        : nombreCompleto.split(' ').first;
    final n = _estrellas.round();
    final bien = FactoresCalificacion.satisfecho(_estrellas);
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(context.gutter),
            child: ContenidoCentrado(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: BotonAhoraNo(onTap: _enviando ? null : _salir),
                  ),
                  const SizedBox(height: Sp.lg),
                  Center(
                    child: AvatarIniciales(
                      nombre: nombreCompleto.isEmpty ? '?' : nombreCompleto,
                      dorado: true,
                    ),
                  ),
                  const SizedBox(height: Sp.lg),
                  Text(
                    l.comoTeFueCon(nombre),
                    textAlign: TextAlign.center,
                    style: NexaTexto.titulo,
                  ),
                  const SizedBox(height: Sp.xs),
                  Text(
                    l.calificarOpcionalConductor(nombre),
                    textAlign: TextAlign.center,
                    style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
                  ),
                  const SizedBox(height: Sp.lg),
                  EstrellasGrandes(
                    valor: n,
                    onChanged: (v) => setState(() => _estrellas = v.toDouble()),
                  ),
                  const SizedBox(height: Sp.sm),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      switch (n) {
                        1 => l.calif1,
                        2 => l.calif2,
                        3 => l.calif3,
                        4 => l.calif4,
                        _ => l.calif5,
                      },
                      textAlign: TextAlign.center,
                      style: NexaTexto.subtitulo.copyWith(
                        color: bien ? NexaColors.cyan : NexaColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: Sp.lg),
                  NexaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              bien ? l.queEstuvoBien : l.queFallo,
                              style: NexaTexto.subtitulo.copyWith(fontSize: 16),
                            ),
                            Text(
                              l.puedesMarcarVarios,
                              style: NexaTexto.pequeno.copyWith(
                                color: NexaColors.tenue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Sp.md),
                        Wrap(
                          spacing: Sp.sm,
                          runSpacing: Sp.sm,
                          children: [
                            for (final f in FactoresCalificacion.paraNota(
                              _estrellas,
                              conductor: true,
                            ))
                              ChipFactor(
                                texto: textoFactorConductor(l, f.codigo),
                                elegido: _factores.contains(f.codigo),
                                positivo: f.positivo,
                                onTap: () => setState(
                                  () => _factores.contains(f.codigo)
                                      ? _factores.remove(f.codigo)
                                      : _factores.add(f.codigo),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Sp.md),
                  TextField(
                    controller: _comentario,
                    maxLength: 250,
                    maxLines: 4,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: l.comentarioOpcional,
                    ),
                  ),
                  const SizedBox(height: Sp.md),
                  NexaButton(
                    label: l.enviarCalificacion,
                    cargando: _enviando,
                    onPressed: _enviar,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
