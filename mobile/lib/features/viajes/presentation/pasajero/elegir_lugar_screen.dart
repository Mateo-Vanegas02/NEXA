import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/geocoding/geocoding_service.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.dart';

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
    final t = context.textos;
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
                  IconButton(
                    tooltip: l.cancelar,
                    onPressed: _cerrar,
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(Sizes.touch),
                      side: BorderSide(
                        color: context.colors.outline.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l.tuRuta,
                      textAlign: TextAlign.center,
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: Sizes.touch),
                ],
              ),
              const SizedBox(height: Sp.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: NexaColors.card,
                  borderRadius: BorderRadius.circular(Rad.lg),
                  border: Border.all(
                    color: context.colors.outline.withValues(alpha: 0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Sp.lg,
                    vertical: Sp.sm,
                  ),
                  child: Column(
                    children: widget.esOrigen
                        ? [campo, _Union(), fijo]
                        : [fijo, _Union(), campo],
                  ),
                ),
              ),
              const SizedBox(height: Sp.md),
              Wrap(
                spacing: Sp.sm,
                runSpacing: Sp.sm,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.map_outlined, size: 18),
                    label: Text(l.fijarEnMapa),
                    onPressed: () =>
                        _cerrar(const ResultadoLugar(fijarEnMapa: true)),
                  ),
                  if (widget.esOrigen)
                    ActionChip(
                      avatar: const Icon(Icons.my_location, size: 18),
                      label: Text(l.usarMiUbicacion),
                      onPressed: () =>
                          _cerrar(const ResultadoLugar(miUbicacion: true)),
                    ),
                ],
              ),
              const SizedBox(height: Sp.lg),
              Text(
                l.resultadosCerca.toUpperCase(),
                style: t.labelSmall?.copyWith(
                  color: context.muted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
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
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: estado._resultados.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: context.colors.outline.withValues(alpha: 0.3),
      ),
      itemBuilder: (context, i) {
        final lugar = estado._resultados[i];
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
                    color: NexaColors.cyan.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(Rad.md),
                  ),
                  child: Icon(Icons.place_outlined, color: context.acento),
                ),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lugar.nombre,
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

class _Union extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 5),
      child: SizedBox(
        height: 12,
        child: VerticalDivider(
          width: 2,
          thickness: 2,
          color: NexaColors.cyan.withValues(alpha: 0.45),
        ),
      ),
    ),
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
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 56),
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
                etiqueta,
                style: context.textos.bodySmall?.copyWith(color: context.muted),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
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
                  esOrigen ? l.origen : l.destino,
                  style: context.textos.bodySmall?.copyWith(
                    color: context.muted,
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
