import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/mini_ruta.dart';
import '../../domain/servicio.dart';

/// Fila de viaje (diseño P10): icono, destino, «hora · km · conductor»,
/// estrellas que puso el pasajero y el precio. Cancelado en rojo.
class ViajeTile extends StatelessWidget {
  const ViajeTile({
    required this.servicio,
    this.onTap,
    this.enTarjeta = true,
    this.precioHoy,
    super.key,
  });

  final Servicio servicio;

  /// Precio aproximado de repetir el viaje hoy (cotizado por el servidor).
  /// Si llega, reemplaza al precio que se pagó.
  final double? precioHoy;
  final VoidCallback? onTap;

  /// false = sin marco (dentro de una tarjeta que agrupa varias filas).
  final bool enTarjeta;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = servicio;
    final cancelado = s.estado == EstadoServicio.cancelado;
    final f = s.fechaHora;
    final detalle = <String>[
      if (f != null) Fmt.fechaRelativa(f, DateTime.now()),
      if (s.distanciaKM > 0)
        '${NumberFormat('0.0', 'es_CO').format(s.distanciaKM)} km',
      if (!cancelado && s.conductor != null) _corto(s.conductor!.nombre),
    ].join(' · ');
    final estrellas = s.calificacionConductor?.round() ?? 0;
    final fila = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Rad.lg),
      child: Padding(
        padding: const EdgeInsets.all(Sp.md + 2),
        child: Row(
          children: [
            // Con trazado del servidor, la miniatura de la ruta (rediseño
            // 2026); si no, el icono.
            if (!cancelado && (s.rutaGeometria ?? '').isNotEmpty)
              SizedBox.square(
                dimension: 64,
                child: MiniRuta(geometria: s.rutaGeometria),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cancelado ? NexaColors.errorSuave : NexaColors.raised,
                  borderRadius: BorderRadius.circular(Rad.md),
                ),
                child: Icon(
                  cancelado
                      ? Icons.warning_amber_rounded
                      : Icons.place_outlined,
                  color: cancelado ? NexaColors.error : NexaColors.cyan,
                  size: 22,
                ),
              ),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.destino.isEmpty ? s.origen : s.destino,
                    style: NexaTexto.subtitulo.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (cancelado)
                    Text(
                      [
                        detalle,
                        l.estado_CANCELADO.toLowerCase(),
                      ].where((e) => e.isNotEmpty).join(' · '),
                      style: NexaTexto.pequeno.copyWith(
                        color: NexaColors.error,
                      ),
                    )
                  else
                    Text(
                      detalle,
                      style: NexaTexto.pequeno.copyWith(
                        color: NexaColors.muted,
                      ),
                      maxLines: 2,
                    ),
                  if (estrellas > 0)
                    Semantics(
                      label: l.estrellasDe5(estrellas),
                      child: ExcludeSemantics(
                        child: Row(
                          children: [
                            for (var i = 1; i <= 5; i++)
                              Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: i <= estrellas
                                    ? NexaColors.gold
                                    : NexaColors.line,
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Sp.sm),
            if (precioHoy != null)
              Semantics(
                label: l.precioHoySemantica(Fmt.cop(precioHoy!)),
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '≈ ${Fmt.cop(precioHoy!)}',
                        style: NexaTexto.cuerpo.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l.precioHoy,
                        style: NexaTexto.pequeno.copyWith(
                          color: NexaColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Text(
                cancelado ? '—' : Fmt.cop(s.tarifa + s.extraVoluntario),
                style: NexaTexto.cuerpo.copyWith(fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
    );
    if (!enTarjeta) return fila;
    return Material(
      color: NexaColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.lg),
        side: const BorderSide(color: NexaColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: fila,
    );
  }

  /// «Carlos Martínez» → «Carlos M.»
  static String _corto(String nombre) {
    final p = nombre.trim().split(RegExp(r'\s+'));
    if (p.length < 2) return nombre;
    return '${p.first} ${p[1][0]}.';
  }
}
