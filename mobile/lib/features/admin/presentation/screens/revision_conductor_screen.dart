import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../../satisfaccion/presentation/widgets/satisfaccion_widgets.dart';
import '../../../viajes/presentation/widgets/piezas_viaje.dart';
import '../../domain/admin.dart';
import '../controllers/admin_controller.dart';

/// Expediente de un conductor (rediseño 2026): sus datos, la moto y los
/// cuatro documentos con el número que declaró; desde aquí se aprueba, se
/// pide información o se rechaza. La regla de aprobar con una verificación
/// exitosa la aplica el servidor.
class RevisionConductorScreen extends ConsumerStatefulWidget {
  const RevisionConductorScreen({required this.conductor, super.key});
  final ConductorRevision conductor;

  @override
  ConsumerState<RevisionConductorScreen> createState() =>
      _RevisionConductorScreenState();
}

class _RevisionConductorScreenState
    extends ConsumerState<RevisionConductorScreen> {
  bool _enviando = false;

  ConductorRevision get _c => widget.conductor;

  bool get _decidible =>
      _c.estado == EstadoRevision.pendiente ||
      _c.estado == EstadoRevision.enRevision;

  Future<void> _hacer(Future<void> Function() accion, String hecho) async {
    final mensajes = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _enviando = true);
    try {
      await accion();
      ref.invalidate(conductoresRevisionProvider);
      ref.invalidate(operacionProvider);
      mensajes.showSnackBar(SnackBar(content: Text(hecho)));
      nav.maybePop();
    } on Object catch (e) {
      mensajes.showSnackBar(
        SnackBar(content: Text(AppException.from(e).mensaje)),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _aprobar(bool verificado) async {
    final l = AppLocalizations.of(context);
    final r = await showDialog<(bool, String)>(
      context: context,
      builder: (_) => _DialogoDecision(
        titulo: l.revisionAprobarTitulo(_c.nombre),
        textoBoton: l.revisionAprobar,
        motivoObligatorio: false,
        // Sin verificación previa, el admin confirma que revisó los
        // documentos: queda como verificación manual en la auditoría.
        casilla: verificado ? null : l.revisionConfirmoDocumentos,
      ),
    );
    if (r == null) return;
    final (casilla, motivo) = r;
    await _hacer(
      () => ref
          .read(adminRepositoryProvider)
          .decidir(
            _c.email,
            aprobar: true,
            motivo: motivo.isEmpty ? l.revisionNotaManual : motivo,
            marcarVerificado: !verificado && casilla,
          ),
      l.revisionAprobado,
    );
  }

  Future<void> _rechazar() async {
    final l = AppLocalizations.of(context);
    final r = await showDialog<(bool, String)>(
      context: context,
      builder: (_) => _DialogoDecision(
        titulo: l.revisionRechazarTitulo(_c.nombre),
        textoBoton: l.revisionRechazar,
        motivoObligatorio: true,
        peligro: true,
      ),
    );
    if (r == null) return;
    await _hacer(
      () => ref
          .read(adminRepositoryProvider)
          .decidir(_c.email, aprobar: false, motivo: r.$2),
      l.revisionRechazado,
    );
  }

  Future<void> _pedirInfo() async {
    final l = AppLocalizations.of(context);
    final r = await showDialog<(bool, String)>(
      context: context,
      builder: (_) => _DialogoDecision(
        titulo: l.revisionPedirInfo,
        textoBoton: l.enviar,
        motivoObligatorio: true,
        etiquetaMotivo: l.revisionQueFalta,
      ),
    );
    if (r == null) return;
    await _hacer(
      () => ref.read(adminRepositoryProvider).pedirInformacion(_c.email, r.$2),
      l.revisionInfoPedida,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final exp = ref.watch(expedienteProvider(_c.email));
    final nombre = _c.nombre.isEmpty ? _c.email : _c.nombre;
    return Scaffold(
      body: FondoNexa(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.gutter,
              0,
              context.gutter,
              Sp.xl,
            ),
            children: [
              ContenidoCentrado(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EncabezadoSat(
                      etiqueta: l.adminConductores,
                      titulo: l.revisionTitulo,
                      atras: true,
                    ),
                    const SizedBox(height: Sp.md),
                    TarjetaSat(
                      child: Row(
                        children: [
                          AvatarIniciales(nombre: nombre, diametro: 56),
                          const SizedBox(width: Sp.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nombre, style: NexaTexto.subtitulo),
                                Text(
                                  [_c.email, ?_c.telefono].join(' · '),
                                  style: NexaTexto.pequeno.copyWith(
                                    color: NexaColors.muted,
                                  ),
                                ),
                                if ((_c.revisionMensaje ?? '').isNotEmpty)
                                  Text(
                                    l.revisionPedido(_c.revisionMensaje!),
                                    style: NexaTexto.pequeno.copyWith(
                                      color: NexaColors.gold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Sp.md),
                    ...exp.when(
                      loading: () => [
                        const SizedBox(height: 300, child: CargandoSkeleton()),
                      ],
                      error: (e, _) => [
                        SizedBox(
                          height: 260,
                          child: EstadoError(
                            mensaje: AppException.from(e).mensaje,
                            onReintentar: () =>
                                ref.invalidate(expedienteProvider(_c.email)),
                          ),
                        ),
                      ],
                      data: (x) => [
                        for (final v in x.vehiculos) ...[
                          TarjetaSat(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.two_wheeler,
                                  color: NexaColors.cyan,
                                  size: 28,
                                ),
                                const SizedBox(width: Sp.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        [
                                          v.marca,
                                          v.modelo,
                                        ].where((e) => e.isNotEmpty).join(' '),
                                        style: NexaTexto.subtitulo.copyWith(
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        v.color,
                                        style: NexaTexto.pequeno.copyWith(
                                          color: NexaColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PlacaMoto(placa: v.placa),
                              ],
                            ),
                          ),
                          const SizedBox(height: Sp.md),
                        ],
                        _EstadoVerificacion(verificado: x.verificado),
                        const SizedBox(height: Sp.md),
                        Text(
                          l.revisionDocumentos.toUpperCase(),
                          style: NexaTexto.etiqueta.copyWith(
                            color: NexaColors.tenue,
                          ),
                        ),
                        const SizedBox(height: Sp.sm),
                        if (x.documentos.isEmpty)
                          TarjetaSat(child: Text(l.revisionSinDocumentos))
                        else
                          _Documentos(documentos: x.documentos),
                        if (_decidible) ...[
                          const SizedBox(height: Sp.xl),
                          NexaButton(
                            label: l.revisionAprobar,
                            icon: Icons.check,
                            cargando: _enviando,
                            onPressed: _enviando
                                ? null
                                : () => _aprobar(x.verificado),
                          ),
                          const SizedBox(height: Sp.sm),
                          NexaButton(
                            label: l.revisionPedirInfo,
                            variant: NexaButtonVariant.secundario,
                            onPressed: _enviando ? null : _pedirInfo,
                          ),
                          const SizedBox(height: Sp.sm),
                          NexaButton(
                            label: l.revisionRechazar,
                            variant: NexaButtonVariant.peligro,
                            onPressed: _enviando ? null : _rechazar,
                          ),
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
    );
  }
}

class _EstadoVerificacion extends StatelessWidget {
  const _EstadoVerificacion({required this.verificado});
  final bool verificado;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = verificado ? NexaColors.ok : NexaColors.gold;
    return Container(
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Rad.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            verificado ? Icons.verified_outlined : Icons.info_outline,
            color: color,
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Text(
              verificado ? l.revisionVerificado : l.revisionSinVerificar,
              style: NexaTexto.pequeno.copyWith(color: NexaColors.texto),
            ),
          ),
        ],
      ),
    );
  }
}

String _tipo(AppLocalizations l, String t) => switch (t) {
  'LICENCIA' => l.tipoLicencia,
  'TARJETA_PROPIEDAD' => l.tipoTarjetaPropiedad,
  'SOAT' => l.tipoSoat,
  'TECNOMECANICA' => l.tipoTecnomecanica,
  _ => t,
};

/// Los documentos en cuadrícula; tocar uno lo abre a pantalla completa.
class _Documentos extends StatelessWidget {
  const _Documentos({required this.documentos});
  final List<DocumentoRevision> documentos;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final ancho = (c.maxWidth - Sp.md) / 2;
      return Wrap(
        spacing: Sp.md,
        runSpacing: Sp.md,
        children: [
          for (final d in documentos)
            SizedBox(width: ancho, child: _Documento(doc: d)),
        ],
      );
    },
  );
}

class _Documento extends ConsumerWidget {
  const _Documento({required this.doc});
  final DocumentoRevision doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bytes = doc.esImagen
        ? ref.watch(archivoDocumentoProvider(doc.id)).value
        : null;
    final hayImagen = bytes != null && bytes.isNotEmpty;
    return TarjetaSat(
      padding: const EdgeInsets.all(Sp.sm),
      semantica: '${_tipo(l, doc.tipo)}. ${doc.numeroDeclarado ?? ''}',
      onTap: !hayImagen
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                fullscreenDialog: true,
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(_tipo(l, doc.tipo))),
                  body: InteractiveViewer(
                    maxScale: 5,
                    child: Center(child: Image.memory(bytes)),
                  ),
                ),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Rad.sm),
              child: hayImagen
                  ? Image.memory(bytes, fit: BoxFit.cover)
                  : const ColoredBox(
                      color: NexaColors.raised,
                      child: Center(
                        child: Icon(
                          Icons.description_outlined,
                          color: NexaColors.muted,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: Sp.sm),
          Text(
            _tipo(l, doc.tipo),
            style: NexaTexto.subtitulo.copyWith(fontSize: 14),
          ),
          if ((doc.numeroDeclarado ?? '').isNotEmpty)
            Text(
              l.revisionNumero(doc.numeroDeclarado!),
              style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
            ),
        ],
      ),
    );
  }
}

/// Confirma una decisión con su motivo (y, al aprobar sin verificación, la
/// casilla de que se revisaron los documentos). Devuelve (casilla, motivo).
class _DialogoDecision extends StatefulWidget {
  const _DialogoDecision({
    required this.titulo,
    required this.textoBoton,
    required this.motivoObligatorio,
    this.casilla,
    this.peligro = false,
    this.etiquetaMotivo,
  });

  final String titulo;
  final String textoBoton;
  final bool motivoObligatorio;
  final String? casilla;
  final bool peligro;
  final String? etiquetaMotivo;

  @override
  State<_DialogoDecision> createState() => _DialogoDecisionState();
}

class _DialogoDecisionState extends State<_DialogoDecision> {
  final _motivo = TextEditingController();
  bool _marcada = false;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  bool get _listo =>
      (!widget.motivoObligatorio || _motivo.text.trim().length >= 3) &&
      (widget.casilla == null || _marcada);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _motivo,
            maxLength: 300,
            maxLines: 3,
            minLines: 1,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText:
                  widget.etiquetaMotivo ??
                  (widget.motivoObligatorio
                      ? l.revisionMotivo
                      : l.revisionNotaOpcional),
            ),
          ),
          if (widget.casilla != null)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _marcada,
              onChanged: (v) => setState(() => _marcada = v ?? false),
              title: Text(widget.casilla!, style: NexaTexto.pequeno),
              controlAffinity: ListTileControlAffinity.leading,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancelar),
        ),
        FilledButton(
          style: widget.peligro
              ? FilledButton.styleFrom(backgroundColor: NexaColors.error)
              : null,
          onPressed: _listo
              ? () => Navigator.pop(context, (_marcada, _motivo.text.trim()))
              : null,
          child: Text(widget.textoBoton),
        ),
      ],
    );
  }
}
