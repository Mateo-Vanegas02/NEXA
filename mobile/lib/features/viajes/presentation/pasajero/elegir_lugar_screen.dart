import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/geocoding/geocoding_service.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/resaltar.dart';
import '../../../../core/widgets/nexa_icono_app.dart';

/// Lo que devuelve [ElegirLugarScreen]: un lugar buscado, o la petición de
/// fijar el punto en el mapa o de usar la ubicación actual (solo en el origen).
class ResultadoLugar {
  const ResultadoLugar({
    this.lugar,
    this.fijarEnMapa = false,
    this.miUbicacion = false,
  });

  final Lugar? lugar;
  final bool fijarEnMapa;
  final bool miUbicacion;
}

/// Pantalla "Tu ruta": busca direcciones mientras se escribe y devuelve el lugar
/// elegido con `Navigator.pop`. Máx. 1 petición cada 700 ms (política de Nominatim).
class ElegirLugarScreen extends ConsumerStatefulWidget {
  const ElegirLugarScreen({
    required this.esOrigen,
    required this.cerca,
    this.origenTexto = '',
    this.destinoTexto = '',
    super.key,
  });

  /// `true` edita el origen; `false`, el destino.
  final bool esOrigen;

  /// Punto cercano al que se prioriza la búsqueda.
  final LatLng cerca;

  /// Texto actual del otro extremo de la ruta (solo se muestra).
  final String origenTexto;
  final String destinoTexto;

  @override
  ConsumerState<ElegirLugarScreen> createState() => _ElegirLugarScreenState();
}

class _ElegirLugarScreenState extends ConsumerState<ElegirLugarScreen> {
  final _ctrl = TextEditingController();
  final _foco = FocusNode();
  Timer? _debounce;
  int _token = 0;
  List<Lugar> _resultados = const [];
  bool _buscando = false;
  bool _busquedaHecha = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _alEscribir(String texto) {
    setState(() {});
    _debounce?.cancel();
    if (texto.trim().length < 3) {
      _token++;
      setState(() {
        _resultados = const [];
        _buscando = false;
        _busquedaHecha = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 700), () => _buscar(texto));
  }

  Future<void> _buscar(String texto) async {
    final token = ++_token;
    setState(() => _buscando = true);
    final r = await ref
        .read(geocodingProvider)
        .buscar(texto, cerca: widget.cerca);
    if (!mounted || token != _token) return;
    setState(() {
      _resultados = r;
      _buscando = false;
      _busquedaHecha = true;
    });
  }

  void _cerrar([ResultadoLugar? r]) => Navigator.of(context).pop(r);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final otro = widget.esOrigen ? widget.destinoTexto : widget.origenTexto;
    final campo = _Campo(
      esOrigen: widget.esOrigen,
      controller: _ctrl,
      foco: _foco,
      hint: widget.esOrigen ? l.origenHint : l.buscarLugarHint,
      onChanged: _alEscribir,
      onBorrar: () {
        _ctrl.clear();
        _alEscribir('');
      },
    );
    final fijo = _Fijo(
      esOrigen: !widget.esOrigen,
      etiqueta: widget.esOrigen ? l.destino : l.origen,
      texto: otro,
    );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.sm, Sp.lg, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  NexaBotonAtras(onPressed: _cerrar, tooltip: l.cancelar),
                  const SizedBox(width: Sp.lg),
                  Expanded(
                    child: Text(l.planeaTuViaje, style: NexaTexto.subtitulo),
                  ),
                ],
              ),
              const SizedBox(height: Sp.lg),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: NexaColors.card,
                  borderRadius: BorderRadius.circular(Rad.lg),
                  border: Border.all(color: NexaColors.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Sp.md),
                  child: Column(
                    children: widget.esOrigen
                        ? [campo, const SizedBox(height: Sp.sm), fijo]
                        : [fijo, const SizedBox(height: Sp.sm), campo],
                  ),
                ),
              ),
              const SizedBox(height: Sp.md),
              Wrap(
                spacing: Sp.sm,
                runSpacing: Sp.sm,
                children: [
                  ActionChip(
                    avatar: const Icon(
                      Icons.my_location,
                      size: 16,
                      color: NexaColors.cyan,
                    ),
                    label: Text(l.fijarEnMapa),
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: NexaColors.line),
                    backgroundColor: NexaColors.card,
                    onPressed: () =>
                        _cerrar(const ResultadoLugar(fijarEnMapa: true)),
                  ),
                  if (widget.esOrigen)
                    ActionChip(
                      avatar: const Icon(
                        Icons.near_me_outlined,
                        size: 16,
                        color: NexaColors.cyan,
                      ),
                      label: Text(l.usarMiUbicacion),
                      shape: const StadiumBorder(),
                      side: const BorderSide(color: NexaColors.line),
                      backgroundColor: NexaColors.card,
                      onPressed: () =>
                          _cerrar(const ResultadoLugar(miUbicacion: true)),
                    ),
                ],
              ),
              const SizedBox(height: Sp.lg),
              Text(
                l.resultadosCerca.toUpperCase(),
                style: NexaTexto.etiqueta.copyWith(color: NexaColors.tenue),
              ),
              const SizedBox(height: Sp.xs),
              Expanded(child: _Lista(estado: this)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resultados, mensaje de "buscando" o de "sin resultados".
class _Lista extends StatelessWidget {
  const _Lista({required this.estado});
  final _ElegirLugarScreenState estado;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (estado._buscando) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: Sp.sm),
          child: Semantics(
            label: l.buscandoLugares,
            child: const LinearProgressIndicator(minHeight: 3),
          ),
        ),
      );
    }
    if (estado._resultados.isEmpty) {
      return estado._busquedaHecha
          ? Padding(
              padding: const EdgeInsets.only(top: Sp.sm),
              child: Text(
                l.sinResultados,
                style: context.textos.bodySmall?.copyWith(color: context.muted),
              ),
            )
          : const SizedBox.shrink();
    }
    const distancia = Distance();
    final km = NumberFormat('0.0', 'es_CO');
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: estado._resultados.length,
      separatorBuilder: (_, _) => const SizedBox(height: Sp.xs),
      itemBuilder: (context, i) {
        final lugar = estado._resultados[i];
        final lejos = distancia.as(
          LengthUnit.Kilometer,
          estado.widget.cerca,
          lugar.punto,
        );
        return InkWell(
          onTap: () => estado._cerrar(ResultadoLugar(lugar: lugar)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: NexaColors.raised,
                    borderRadius: BorderRadius.circular(Rad.md),
                  ),
                  child: const Icon(
                    Icons.place_outlined,
                    color: NexaColors.cyan,
                    size: 22,
                  ),
                ),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Lo que escribió, resaltado en cian (rediseño 2026).
                      Text.rich(
                        TextSpan(
                          children: [
                            for (final (t, coincide) in tramosResaltados(
                              lugar.nombre,
                              estado._ctrl.text,
                            ))
                              TextSpan(
                                text: t,
                                style: coincide
                                    ? const TextStyle(color: NexaColors.cyan)
                                    : null,
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textos.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (lugar.detalle.isNotEmpty)
                        Text(
                          lugar.detalle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textos.bodySmall?.copyWith(
                            color: context.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: Sp.sm),
                Text(
                  '${km.format(lejos)} km',
                  style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({required this.esOrigen});
  final bool esOrigen;

  @override
  Widget build(BuildContext context) => esOrigen
      ? Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
        )
      : Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: NexaColors.cyan,
            borderRadius: BorderRadius.circular(4),
            boxShadow: NexaShadows.glow,
          ),
        );
}

/// Recuadro de cada extremo; el que se edita lleva el borde cian.
class _Caja extends StatelessWidget {
  const _Caja({required this.activa, required this.child});
  final bool activa;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 60),
    padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
    decoration: BoxDecoration(
      color: activa ? NexaColors.bg : NexaColors.raised.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(Rad.md),
      border: Border.all(
        color: activa ? NexaColors.cyan : Colors.transparent,
        width: 1.5,
      ),
    ),
    child: child,
  );
}

/// El otro extremo de la ruta, solo lectura.
class _Fijo extends StatelessWidget {
  const _Fijo({
    required this.esOrigen,
    required this.etiqueta,
    required this.texto,
  });
  final bool esOrigen;
  final String etiqueta;
  final String texto;

  @override
  Widget build(BuildContext context) => _Caja(
    activa: false,
    child: Row(
      children: [
        _Punto(esOrigen: esOrigen),
        const SizedBox(width: Sp.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                etiqueta.toUpperCase(),
                style: NexaTexto.etiqueta.copyWith(
                  color: NexaColors.tenue,
                  fontSize: 10,
                ),
              ),
              Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textos.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Extremo que se está editando: campo de texto con foco.
class _Campo extends StatelessWidget {
  const _Campo({
    required this.esOrigen,
    required this.controller,
    required this.foco,
    required this.hint,
    required this.onChanged,
    required this.onBorrar,
  });

  final bool esOrigen;
  final TextEditingController controller;
  final FocusNode foco;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onBorrar;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Caja(
      activa: true,
      child: Row(
        children: [
          _Punto(esOrigen: esOrigen),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (esOrigen ? l.origen : l.destino).toUpperCase(),
                  style: NexaTexto.etiqueta.copyWith(
                    color: NexaColors.cyan,
                    fontSize: 10,
                  ),
                ),
                TextField(
                  controller: controller,
                  focusNode: foco,
                  autofocus: true,
                  onChanged: onChanged,
                  maxLength: 100,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: hint,
                    isDense: true,
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: Sp.xs),
                  ),
                  style: context.textos.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              tooltip: l.borrar,
              onPressed: onBorrar,
              icon: const Icon(Icons.close, size: 18),
            ),
        ],
      ),
    );
  }
}
