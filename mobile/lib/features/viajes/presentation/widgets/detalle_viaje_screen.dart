import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/mini_ruta.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/servicio.dart';
import 'calificacion_widgets.dart';

/// Desglose del cobro de un viaje para el pasajero (lo calcula el servidor).
final desglosePasajeroProvider = FutureProvider.autoDispose
    .family<DesglosePasajero, String>(
      (ref, id) => ref.watch(pasajeroRepositoryProvider).desglose(id),
    );

/// Desglose del cobro de un viaje para el conductor.
final desgloseConductorProvider = FutureProvider.autoDispose
    .family<DesgloseConductor, String>(
      (ref, id) => ref.watch(conductorRepositoryProvider).desglose(id),
    );

/// Abre el detalle de un viaje del historial (pasajero o [conductor]).
Future<void> abrirDetalleViaje(
  BuildContext context,
  Servicio servicio, {
  bool conductor = false,
}) => Navigator.of(context, rootNavigator: true).push(
  MaterialPageRoute<void>(
    builder: (_) =>
        DetalleViajeScreen(servicio: servicio, conductor: conductor),
  ),
);

/// Todo lo que pasó en un viaje terminado: la ruta, la línea de tiempo, con
/// quién fue, cuánto se pagó (con el desglose del servidor) y la calificación
/// que puso quien mira. Lo que ve cada rol lo decide el servidor.
class DetalleViajeScreen extends ConsumerWidget {
  const DetalleViajeScreen({
    required this.servicio,
    this.conductor = false,
    super.key,
  });

  final Servicio servicio;

  /// true = lo mira el conductor (su ganancia y su calificación al pasajero).
  final bool conductor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = servicio;
    final cancelado = s.estado == EstadoServicio.cancelado;
    final fecha = s.fechaHora;
    return Scaffold(
      backgroundColor: NexaColors.bg,
      appBar: AppBar(
        backgroundColor: NexaColors.bg,
        title: Text(l.detalleViaje),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            context.gutter,
            Sp.sm,
            context.gutter,
            Sp.xxl,
          ),
          children: [
            if ((s.rutaGeometria ?? '').isNotEmpty && !cancelado)
              SizedBox(
                height: 180,
                child: MiniRuta(
                  geometria: s.rutaGeometria,
                  corte: s.finalizadoAntesDelDestino ? s.fraccionCobrada : null,
                  radio: Rad.lg,
                ),
              ),
            const SizedBox(height: Sp.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          s.destino.isEmpty ? l.destino : s.destino,
                          style: NexaTexto.titulo.copyWith(
                            color: NexaColors.texto,
                          ),
                        ),
                      ),
                      if (fecha != null) ...[
                        const SizedBox(height: Sp.xs),
                        Text(
                          _capital(
                            DateFormat(
                              "EEEE d 'de' MMMM · h:mm a",
                              'es_CO',
                            ).format(fecha),
                          ),
                          style: NexaTexto.pequeno.copyWith(
                            color: NexaColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: Sp.sm),
                _Estado(estado: s.estado),
              ],
            ),
            const SizedBox(height: Sp.lg),
            _Recorrido(servicio: s),
            const SizedBox(height: Sp.md),
            _LineaTiempo(servicio: s, conductor: conductor),
            if ((conductor ? s.pasajero : s.conductor) != null) ...[
              const SizedBox(height: Sp.md),
              _Persona(servicio: s, conductor: conductor),
            ],
            if (!cancelado) ...[
              const SizedBox(height: Sp.md),
              conductor
                  ? _PagoConductor(servicio: s)
                  : _PagoPasajero(servicio: s),
              const SizedBox(height: Sp.md),
              _TuCalificacion(servicio: s, conductor: conductor),
            ],
          ],
        ),
      ),
    );
  }
}

String _capital(String t) =>
    t.isEmpty ? t : '${t[0].toUpperCase()}${t.substring(1)}';

String _hora(DateTime d) => DateFormat('h:mm a', 'es_CO').format(d);

class _Estado extends StatelessWidget {
  const _Estado({required this.estado});
  final EstadoServicio estado;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (texto, color) = switch (estado) {
      EstadoServicio.finalizado => (l.detalleEstadoFinalizado, NexaColors.ok),
      EstadoServicio.cancelado => (l.detalleEstadoCancelado, NexaColors.error),
      _ => (l.detalleEstadoEnCurso, NexaColors.cyan),
    };
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.14),
        shape: StadiumBorder(
          side: BorderSide(color: color.withValues(alpha: 0.4)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
        child: Text(
          texto,
          style: NexaTexto.pequeno.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Sp.sm),
    child: Semantics(
      header: true,
      child: Text(
        texto.toUpperCase(),
        style: NexaTexto.etiqueta.copyWith(color: NexaColors.tenue),
      ),
    ),
  );
}

class _Recorrido extends StatelessWidget {
  const _Recorrido({required this.servicio});
  final Servicio servicio;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = servicio;
    final inicio = s.fechaInicio;
    final fin = s.fechaFinalizacion;
    final minutos = inicio != null && fin != null && fin.isAfter(inicio)
        ? fin.difference(inicio).inMinutes.clamp(1, 24 * 60)
        : null;
    final datos = [
      if (s.distanciaKM > 0)
        '${NumberFormat('0.0', 'es_CO').format(s.distanciaKM)} km',
      if (minutos != null) l.detalleDuracion(minutos),
    ];
    return NexaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Titulo(l.detalleRecorrido),
          _Punto(
            color: NexaColors.cyan,
            texto: s.origen.isEmpty ? l.miUbicacion : s.origen,
            linea: true,
          ),
          _Punto(
            color: NexaColors.gold,
            texto: s.destino.isEmpty ? l.destino : s.destino,
          ),
          if (datos.isNotEmpty) ...[
            const SizedBox(height: Sp.sm),
            Text(
              datos.join(' · '),
              style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({required this.color, required this.texto, this.linea = false});
  final Color color;
  final String texto;
  final bool linea;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 18,
          child: Column(
            children: [
              const SizedBox(height: 5),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (linea)
                Expanded(child: Container(width: 2, color: NexaColors.line)),
            ],
          ),
        ),
        const SizedBox(width: Sp.sm),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: linea ? Sp.md : 0),
            child: Text(
              texto,
              style: NexaTexto.cuerpo.copyWith(color: NexaColors.texto),
            ),
          ),
        ),
      ],
    ),
  );
}

class _LineaTiempo extends StatelessWidget {
  const _LineaTiempo({required this.servicio, required this.conductor});
  final Servicio servicio;
  final bool conductor;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = servicio;
    final hitos = <(String, DateTime?, Color)>[
      (
        conductor ? l.detallePedidoConductor : l.detallePedido,
        s.fechaHora,
        NexaColors.muted,
      ),
      if (s.fechaAceptacion != null)
        (l.detalleAceptado, s.fechaAceptacion, NexaColors.cyan),
      if (s.fechaInicio != null)
        (l.detalleRecogida, s.fechaInicio, NexaColors.cyan),
      if (s.estado == EstadoServicio.cancelado)
        (l.detalleCancelado, s.fechaCancelacion, NexaColors.error)
      else if (s.fechaFinalizacion != null)
        (
          s.finalizadoAntesDelDestino
              ? l.detalleTerminoAntes
              : l.detalleLlegada,
          s.fechaFinalizacion,
          s.finalizadoAntesDelDestino ? NexaColors.gold : NexaColors.ok,
        ),
    ];
    return NexaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Titulo(l.detalleLineaTiempo),
          for (var i = 0; i < hitos.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 18,
                    child: Column(
                      children: [
                        const SizedBox(height: 5),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: hitos[i].$3,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (i < hitos.length - 1)
                          Expanded(
                            child: Container(width: 2, color: NexaColors.line),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < hitos.length - 1 ? Sp.md : 0,
                      ),
                      child: Text(
                        hitos[i].$1,
                        style: NexaTexto.cuerpo.copyWith(
                          color: NexaColors.texto,
                        ),
                      ),
                    ),
                  ),
                  if (hitos[i].$2 != null)
                    Text(
                      _hora(hitos[i].$2!),
                      style: NexaTexto.pequeno.copyWith(
                        color: NexaColors.muted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Persona extends StatelessWidget {
  const _Persona({required this.servicio, required this.conductor});
  final Servicio servicio;
  final bool conductor;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = (conductor ? servicio.pasajero : servicio.conductor)!;
    final detalle = conductor
        ? [
            if (servicio.nivelPasajero > 0)
              l.detalleNivel(servicio.nivelPasajero),
          ]
        : [
            if ((p.vehiculo ?? '').isNotEmpty) p.vehiculo!,
            if (p.calificacion != null)
              '★ ${NumberFormat('0.0', 'es_CO').format(p.calificacion)}',
          ];
    final nombre = p.nombre.isEmpty ? '—' : p.nombre;
    return NexaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Titulo(conductor ? l.detalleTuPasajero : l.detalleTuConductor),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: NexaColors.raised,
                child: Text(
                  nombre.characters.first.toUpperCase(),
                  style: NexaTexto.subtitulo.copyWith(color: NexaColors.cyan),
                ),
              ),
              const SizedBox(width: Sp.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: NexaTexto.subtitulo.copyWith(
                        color: NexaColors.texto,
                      ),
                    ),
                    if (detalle.isNotEmpty)
                      Text(
                        detalle.join(' · '),
                        style: NexaTexto.pequeno.copyWith(
                          color: NexaColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              if (!conductor && (p.placa ?? '').isNotEmpty)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: NexaColors.gold,
                    borderRadius: BorderRadius.circular(Rad.sm),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Sp.sm,
                      vertical: 2,
                    ),
                    child: Text(
                      p.placa!,
                      style: NexaTexto.placa.copyWith(
                        color: NexaColors.bg,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Una fila «concepto ……… valor».
class _Fila extends StatelessWidget {
  const _Fila(this.concepto, this.valor, {this.fuerte = false, this.color});
  final String concepto;
  final String valor;
  final bool fuerte;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            concepto,
            style: (fuerte ? NexaTexto.subtitulo : NexaTexto.cuerpo).copyWith(
              color: fuerte ? NexaColors.texto : NexaColors.muted,
            ),
          ),
        ),
        Text(
          valor,
          style: (fuerte ? NexaTexto.subtitulo : NexaTexto.cuerpo).copyWith(
            color: color ?? NexaColors.texto,
            fontWeight: fuerte ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _PagoPasajero extends ConsumerWidget {
  const _PagoPasajero({required this.servicio});
  final Servicio servicio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = servicio;
    final d = ref.watch(desglosePasajeroProvider(s.id));
    final codigo = (s.metodoPago ?? '').toLowerCase();
    final metodo = codigo.isEmpty || codigo == 'efectivo'
        ? l.efectivo
        : _capital(codigo);
    return NexaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Titulo('${l.detallePago} · $metodo'),
          ...switch (d) {
            AsyncData(:final value) => [
              _Fila(l.detalleTarifa, Fmt.cop(value.tarifa)),
              if (value.descuentoNivel > 0)
                _Fila(
                  l.descuentoNivel,
                  '−${Fmt.cop(value.descuentoNivel)}',
                  color: NexaColors.ok,
                ),
              if (value.recargoEspera > 0)
                _Fila(l.recargoEspera, Fmt.cop(value.recargoEspera)),
              if (value.extraVoluntario > 0)
                _Fila(l.extraVoluntario, Fmt.cop(value.extraVoluntario)),
              if (value.deudaAnterior > 0)
                _Fila(l.deudaAnterior, Fmt.cop(value.deudaAnterior)),
              const Divider(color: NexaColors.line),
              _Fila(
                l.totalPagado,
                Fmt.cop(
                  value.totalAPagar > 0
                      ? value.totalAPagar
                      : value.totalPasajero,
                ),
                fuerte: true,
              ),
            ],
            AsyncError() => [
              _Fila(
                l.totalPagado,
                Fmt.cop(s.tarifa + s.extraVoluntario + s.deudaCobrada),
                fuerte: true,
              ),
              Text(
                l.detalleDesgloseError,
                style: NexaTexto.pequeno.copyWith(color: NexaColors.tenue),
              ),
            ],
            _ => [
              _Fila(
                l.totalPagado,
                Fmt.cop(s.tarifa + s.extraVoluntario + s.deudaCobrada),
                fuerte: true,
              ),
            ],
          },
          if (s.xpGanadoPasajero > 0) ...[
            const SizedBox(height: Sp.sm),
            Text(
              l.detalleXp(s.xpGanadoPasajero),
              style: NexaTexto.pequeno.copyWith(
                color: NexaColors.cyan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PagoConductor extends ConsumerWidget {
  const _PagoConductor({required this.servicio});
  final Servicio servicio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = servicio;
    final d = ref.watch(desgloseConductorProvider(s.id)).value;
    final cobrado = d?.cobrarAlPasajero ?? s.tarifa;
    return NexaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Titulo(l.detallePago),
          _Fila(l.detalleCobrado, Fmt.cop(cobrado)),
          if (d != null) ...[
            if (d.recargoEspera > 0)
              _Fila(l.recargoEspera, Fmt.cop(d.recargoEspera)),
            if (d.extraVoluntario > 0)
              _Fila(l.extraVoluntario, Fmt.cop(d.extraVoluntario)),
            if (cobrado > d.gananciaConductor && d.gananciaConductor > 0)
              _Fila(
                l.detalleComision,
                '−${Fmt.cop(cobrado - d.gananciaConductor)}',
                color: NexaColors.gold,
              ),
            const Divider(color: NexaColors.line),
            _Fila(
              l.tuGanancia,
              Fmt.cop(d.gananciaConductor),
              fuerte: true,
              color: NexaColors.ok,
            ),
          ],
          if (s.xpGanadoConductor > 0) ...[
            const SizedBox(height: Sp.sm),
            Text(
              l.detalleXp(s.xpGanadoConductor),
              style: NexaTexto.pequeno.copyWith(
                color: NexaColors.cyan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TuCalificacion extends StatelessWidget {
  const _TuCalificacion({required this.servicio, required this.conductor});
  final Servicio servicio;
  final bool conductor;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = servicio;
    final nota = conductor ? s.calificacionPasajero : s.calificacionConductor;
    final comentario =
        (conductor ? s.comentariosPasajero : s.comentariosConductor) ?? '';
    final factores = conductor ? s.factoresPasajero : s.factoresConductor;
    return NexaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Titulo(l.detalleTuCalificacion),
          if (nota == null)
            Text(
              l.detalleSinCalificar,
              style: NexaTexto.cuerpo.copyWith(color: NexaColors.muted),
            )
          else ...[
            Semantics(
              label: l.detalleNotaSemantica(nota.round()),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        i <= nota.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: i <= nota.round()
                            ? NexaColors.gold
                            : NexaColors.tenue,
                        size: 28,
                      ),
                  ],
                ),
              ),
            ),
            if (factores.isNotEmpty) ...[
              const SizedBox(height: Sp.sm),
              Wrap(
                spacing: Sp.xs,
                runSpacing: Sp.xs,
                children: [
                  for (final f in factores)
                    Chip(
                      label: Text(
                        conductor
                            ? textoFactorConductor(l, f)
                            : textoFactor(l, f),
                      ),
                      backgroundColor: NexaColors.raised,
                      side: const BorderSide(color: NexaColors.line),
                      shape: const StadiumBorder(),
                      labelStyle: NexaTexto.pequeno.copyWith(
                        color: NexaColors.texto,
                      ),
                    ),
                ],
              ),
            ],
            if (comentario.trim().isNotEmpty) ...[
              const SizedBox(height: Sp.sm),
              Text(
                '«${comentario.trim()}»',
                style: NexaTexto.cuerpo.copyWith(
                  color: NexaColors.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
