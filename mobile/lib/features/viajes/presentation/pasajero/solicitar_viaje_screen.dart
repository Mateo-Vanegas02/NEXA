import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/geocoding/geocoding_service.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/nexa_texto.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/mapa/polyline.dart';
import '../../../../core/widgets/mapa_nexa.dart';
import '../../../../core/widgets/nexa_diseno.dart';
import '../../../../core/widgets/nexa_widgets.dart';
import '../../domain/estimado_tarifa.dart';
import '../../domain/servicio.dart';
import '../controllers/viaje_pasajero_controller.dart';
import '../widgets/desglose_card.dart';
import 'elegir_lugar_screen.dart';
import '../../../permisos/presentation/flujo_permisos.dart';

const _metodos = ['efectivo', 'tarjeta', 'billetera'];

enum _Campo { origen, destino }

/// Confirmar viaje: mapa con la ruta y hoja inferior con origen y destino (se
/// cambian en la pantalla "Tu ruta"), el precio dentro del botón y el desglose
/// bajo demanda. Con [destinoInicial] ya elegido, cotiza al abrir.
class SolicitarViajeScreen extends ConsumerStatefulWidget {
  const SolicitarViajeScreen({this.destinoInicial, super.key});

  final Lugar? destinoInicial;

  @override
  ConsumerState<SolicitarViajeScreen> createState() =>
      _SolicitarViajeScreenState();
}

class _SolicitarViajeScreenState extends ConsumerState<SolicitarViajeScreen> {
  final _mapa = MapaNexaController();

  /// `null` = ubicación actual (GPS).
  LatLng? _origen;
  LatLng? _destino;
  String _origenTxt = '';
  String _destinoTxt = '';

  /// Campo que recibirá el próximo toque en el mapa.
  _Campo? _fijando;
  String _metodo = _metodos.first;

  /// Origen con el que se pidió el último precio (evita cotizar dos veces
  /// cuando el GPS llega con la misma posición que ya se usó).
  LatLng? _origenCotizado;

  /// Precio según el servidor para el origen y destino actuales.
  Cotizacion? _cot;
  bool _cotizando = false;
  String? _errorCot;
  bool _aceptaDeuda = false;
  bool _verDesglose = false;
  int _tokenCot = 0;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final inicial = widget.destinoInicial;
    if (inicial != null) {
      _destino = inicial.punto;
      _destinoTxt = inicial.nombre;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_cotizar());
      });
    }
  }

  @override
  void didUpdateWidget(SolicitarViajeScreen old) {
    super.didUpdateWidget(old);
    final nuevo = widget.destinoInicial;
    if (nuevo != null && nuevo != old.destinoInicial) {
      setState(() {
        _destino = nuevo.punto;
        _destinoTxt = nuevo.nombre;
      });
      _moverMapa(nuevo.punto);
      unawaited(_cotizar());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_origenTxt.isEmpty) {
      _origenTxt = AppLocalizations.of(context).miUbicacion;
    }
  }

  LatLng get _origenEfectivo =>
      _origen ?? ref.read(ubicacionProvider).value ?? kCentroPorDefecto;

  /// Pide al servidor el precio del viaje (valida la zona y calcula la ruta real).
  /// Se descartan las respuestas viejas si el usuario cambió el origen o el destino.
  Future<void> _cotizar() async {
    final destino = _destino;
    final token = ++_tokenCot;
    if (destino == null) {
      setState(() {
        _cot = null;
        _errorCot = null;
        _cotizando = false;
        _aceptaDeuda = false;
      });
      return;
    }
    final origen = _origenEfectivo;
    _origenCotizado = origen;
    setState(() {
      _cotizando = true;
      _errorCot = null;
      _cot = null;
      _aceptaDeuda = false;
    });
    try {
      final c = await ref
          .read(pasajeroRepositoryProvider)
          .cotizar(
            Coordenada(latitud: origen.latitude, longitud: origen.longitude),
            Coordenada(latitud: destino.latitude, longitud: destino.longitude),
          );
      if (mounted && token == _tokenCot) {
        setState(() {
          _cot = c;
          // Con un cargo pendiente el pasajero debe verlo antes de aceptarlo.
          _verDesglose = c.tieneDeuda;
        });
      }
    } on Object catch (e) {
      if (mounted && token == _tokenCot) {
        setState(() => _errorCot = AppException.from(e).mensaje);
      }
    } finally {
      if (mounted && token == _tokenCot) setState(() => _cotizando = false);
    }
  }

  void _moverMapa(LatLng p) {
    // Si el mapa aún no está listo (o está deshabilitado en tests), no hace nada.
    unawaited(_mapa.mover(p, 15));
  }

  Future<void> _elegir(_Campo campo) async {
    final r = await Navigator.of(context, rootNavigator: true)
        .push<ResultadoLugar>(
          MaterialPageRoute(
            builder: (_) => ElegirLugarScreen(
              esOrigen: campo == _Campo.origen,
              cerca: _origenEfectivo,
              origenTexto: _origenTxt,
              destinoTexto: _destinoTxt,
            ),
          ),
        );
    if (!mounted || r == null) return;
    if (r.miUbicacion) {
      _usarMiUbicacion();
    } else if (r.fijarEnMapa) {
      setState(() => _fijando = campo);
    } else if (r.lugar != null) {
      _aplicarLugar(campo, r.lugar!);
    }
  }

  void _aplicarLugar(_Campo campo, Lugar lugar) {
    setState(() {
      if (campo == _Campo.origen) {
        _origen = lugar.punto;
        _origenTxt = lugar.nombre;
      } else {
        _destino = lugar.punto;
        _destinoTxt = lugar.nombre;
      }
      _fijando = null;
    });
    _moverMapa(lugar.punto);
    unawaited(_cotizar());
  }

  Future<void> _alTocarMapa(LatLng p) async {
    final l = AppLocalizations.of(context);
    final campo = _fijando ?? _Campo.destino;
    setState(() {
      if (campo == _Campo.origen) {
        _origen = p;
        _origenTxt = l.puntoEnMapa;
      } else {
        _destino = p;
        _destinoTxt = l.puntoEnMapa;
      }
      _fijando = null;
    });
    unawaited(_cotizar());
    final nombre = await ref.read(geocodingProvider).nombreDe(p);
    if (!mounted || nombre == null) return;
    // Solo si el usuario no cambió ese punto mientras tanto.
    final vigente = campo == _Campo.origen ? _origen == p : _destino == p;
    if (vigente) {
      setState(() {
        if (campo == _Campo.origen) {
          _origenTxt = nombre;
        } else {
          _destinoTxt = nombre;
        }
      });
    }
  }

  void _usarMiUbicacion() {
    final l = AppLocalizations.of(context);
    setState(() {
      _origen = null;
      _origenTxt = l.miUbicacion;
      _fijando = null;
    });
    _moverMapa(_origenEfectivo);
    unawaited(_cotizar());
  }

  String _nombreMetodo(AppLocalizations l, String m) => switch (m) {
    'tarjeta' => l.metodoTarjeta,
    'billetera' => l.metodoBilletera,
    _ => l.efectivo,
  };

  Future<void> _elegirMetodo() async {
    final l = AppLocalizations.of(context);
    final elegido = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in _metodos)
              ListTile(
                minTileHeight: Sizes.touch,
                title: Text(_nombreMetodo(l, m)),
                trailing: m == _metodo ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(ctx).pop(m),
              ),
          ],
        ),
      ),
    );
    if (elegido != null) setState(() => _metodo = elegido);
  }

  Future<void> _solicitar() async {
    final destino = _destino;
    if (destino == null) return;
    // Sin permiso de ubicación no se puede pedir viaje: N02 o E01.
    if (!await asegurarUbicacion(context, ref) || !mounted) return;
    final origen = _origenEfectivo;
    final l = AppLocalizations.of(context);
    // El servidor exige que la recogida esté cerca del pasajero: se le envía el
    // GPS real (no el centro por defecto que se usa cuando no hay permiso).
    final gps = ref.read(ubicacionProvider).value;
    final conGps = gps != null && gps != kCentroPorDefecto;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await ref
          .read(viajePasajeroProvider.notifier)
          .solicitar(
            SolicitudViaje(
              origen: _origenTxt.trim().isEmpty ? l.miUbicacion : _origenTxt,
              destino: _destinoTxt.trim().isEmpty
                  ? l.destinoSeleccionado
                  : _destinoTxt,
              ubicacionOrigen: Coordenada(
                latitud: origen.latitude,
                longitud: origen.longitude,
              ),
              ubicacionDestino: Coordenada(
                latitud: destino.latitude,
                longitud: destino.longitude,
              ),
              ubicacionPasajero: conGps
                  ? Coordenada(latitud: gps.latitude, longitud: gps.longitude)
                  : null,
              metodoPago: _metodo,
              aceptaDeuda: _aceptaDeuda,
            ),
          );
      if (mounted) unawaited(context.push('/p/viaje'));
    } on Object catch (ex) {
      if (mounted) setState(() => _error = AppException.from(ex).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    ref.watch(ubicacionProvider); // repinta cuando llegue el GPS
    final origen = _origenEfectivo;
    // Si el GPS llega después de elegir el destino, el precio hay que recalcularlo.
    ref.listen(ubicacionProvider, (_, nuevo) {
      if (_origen == null &&
          _destino != null &&
          nuevo.value != _origenCotizado) {
        unawaited(_cotizar());
      }
    });
    final destino = _destino;
    final cot = _cot;
    final km = cot?.distanciaKm ?? 0.0;
    // La duración la da el servidor (OSRM); el estimado local solo si no vino.
    final minutos = (cot?.duracionMin ?? 0) > 0
        ? cot!.duracionMin.ceil()
        : minutosEstimados(km);
    final puedeSolicitar =
        cot != null && !_cotizando && (!cot.tieneDeuda || _aceptaDeuda);
    final kmTxt = NumberFormat('0.0', 'es_CO').format(km);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MapaNexa(
              controller: _mapa,
              centro: origen,
              origen: origen,
              destino: destino,
              ruta: rutaDe(cot?.rutaGeometria),
              encuadrarRuta: true,
              etiquetaRuta: cot == null ? null : '$minutos min · $kmTxt km',
              // El tiempo va sobre la línea y la bandera dice a qué hora
              // llegas (rediseño 2026).
              tiempoEnRuta: cot == null ? null : '$minutos min',
              etiquetaDestino: cot == null || destino == null
                  ? null
                  : AppLocalizations.of(context).destinoLlegas(
                      _destinoTxt.trim().isEmpty
                          ? AppLocalizations.of(context).destino
                          : _destinoTxt.trim(),
                      DateFormat('H:mm', 'es_CO').format(
                        DateTime.now().add(Duration(minutes: minutos)),
                      ),
                    ),
              onTap: _alTocarMapa,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Sp.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BotonRedondo(
                    icono: Icons.chevron_left,
                    tooltip: l.volver,
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/p/inicio'),
                  ),
                  const Spacer(),
                  _BotonRedondo(
                    icono: Icons.my_location,
                    tooltip: l.centrarUbicacion,
                    onTap: () => _moverMapa(origen),
                  ),
                ],
              ),
            ),
          ),
          if (_fijando != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: Sp.lg),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => setState(() => _fijando = null),
                    child: NexaChipCristal(
                      icono: Icons.touch_app_outlined,
                      texto: _fijando == _Campo.origen
                          ? l.tocaMapaOrigen
                          : l.tocaMapaDestino,
                    ),
                  ),
                ),
              ),
            ),
          NexaHojaArrastrable(
            inicial: 0.62,
            minimo: 0.3,
            children: [
              if (destino == null) ...[
                Text(
                  l.aDondeVamos,
                  style: context.textos.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Sp.md),
              ],
              if (cot != null) ...[
                _TarjetaPrecio(
                  detalle:
                      '$kmTxt km · ${l.minutosValor(minutos)} · '
                      '${l.llegasALas(DateFormat('H:mm', 'es_CO').format(DateTime.now().add(Duration(minutes: minutos))))}',
                  precio: Fmt.cop(cot.totalAPagar),
                  antes: cot.descuento > 0
                      ? Fmt.cop(cot.totalAPagar + cot.descuento)
                      : null,
                ),
                if (cot.descuento > 0) ...[
                  const SizedBox(height: Sp.md),
                  _BarraAhorro(texto: l.ahorroNivel(Fmt.cop(cot.descuento))),
                ],
                const SizedBox(height: Sp.md),
              ],
              NexaCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.md,
                  vertical: Sp.xs,
                ),
                child: Column(
                  children: [
                    _FilaRuta(
                      esOrigen: true,
                      etiqueta: l.origen,
                      texto: _origenTxt,
                      onTap: () => _elegir(_Campo.origen),
                    ),
                    const Divider(height: 1),
                    _FilaRuta(
                      esOrigen: false,
                      etiqueta: l.destino,
                      texto: _destinoTxt,
                      hint: l.buscadorHint,
                      onTap: () => _elegir(_Campo.destino),
                    ),
                  ],
                ),
              ),
              if (_cotizando) ...[
                const SizedBox(height: Sp.lg),
                Row(
                  children: [
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: Sp.md),
                    Expanded(child: Text(l.cotizando)),
                  ],
                ),
              ],
              if (_errorCot != null && destino != null) ...[
                const SizedBox(height: Sp.lg),
                NexaCard(
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: context.colors.error),
                      const SizedBox(width: Sp.md),
                      Expanded(
                        child: Text(
                          _errorCot!,
                          style: TextStyle(color: context.colors.error),
                        ),
                      ),
                      TextButton(
                        onPressed: _cotizar,
                        child: Text(l.reintentar),
                      ),
                    ],
                  ),
                ),
              ],
              if (cot != null) ...[
                const SizedBox(height: Sp.sm),
                Wrap(
                  spacing: Sp.sm,
                  runSpacing: Sp.sm,
                  children: [
                    ActionChip(
                      label: Text(
                        _verDesglose ? l.ocultarDesglose : l.verDesglose,
                      ),
                      avatar: Icon(
                        _verDesglose ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _verDesglose = !_verDesglose),
                    ),
                  ],
                ),
                if (_verDesglose) ...[
                  const SizedBox(height: Sp.md),
                  DesgloseCard(
                    titulo: l.estimadoTarifa,
                    filas: [
                      (l.tarifaBase, cot.tarifa),
                      if (cot.descuento > 0) (l.descuentoNivel, -cot.descuento),
                      if (cot.tieneDeuda)
                        (l.cargoPendiente, cot.deudaPendiente),
                    ],
                    total: cot.totalAPagar,
                    nota: l.tarifaServidorAviso,
                  ),
                ],
                if (cot.tieneDeuda)
                  // La hoja pinta su fondo con un DecoratedBox: el Material
                  // propio deja ver el efecto de toque del ListTile.
                  Material(
                    type: MaterialType.transparency,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _aceptaDeuda,
                      onChanged: (v) =>
                          setState(() => _aceptaDeuda = v ?? false),
                      title: Text(
                        '${l.aceptoCargo} (${Fmt.cop(cot.deudaPendiente)})',
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: Sp.md),
              NexaCard(
                onTap: _elegirMetodo,
                padding: const EdgeInsets.all(Sp.md),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: NexaColors.raised,
                        borderRadius: BorderRadius.circular(Rad.md),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: NexaColors.cyan,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nombreMetodo(l, _metodo),
                            style: NexaTexto.cuerpo.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            l.pagasAlLlegar,
                            style: NexaTexto.pequeno.copyWith(
                              color: NexaColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: l.cambiar,
                      child: const Icon(
                        Icons.chevron_right,
                        color: NexaColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: Sp.sm),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: TextStyle(color: context.colors.error),
                  ),
                ),
              ],
              const SizedBox(height: Sp.lg),
              NexaButton(
                label: cot == null
                    ? l.pedirNexaSinPrecio
                    : l.pedirNexa(Fmt.cop(cot.totalAPagar)),
                cargando: _cargando,
                onPressed: puedeSolicitar ? _solicitar : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Origen o destino de la ruta; al tocarlo se abre la pantalla "Tu ruta".
class _FilaRuta extends StatelessWidget {
  const _FilaRuta({
    required this.esOrigen,
    required this.etiqueta,
    required this.texto,
    required this.onTap,
    this.hint,
  });

  final bool esOrigen;
  final String etiqueta;
  final String texto;
  final String? hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vacio = texto.isEmpty;
    return Semantics(
      button: true,
      label: '$etiqueta: ${vacio ? (hint ?? '') : texto}',
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(Rad.md),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: NexaColors.raised,
                    borderRadius: BorderRadius.circular(Rad.sm + 2),
                  ),
                  child: Icon(
                    esOrigen ? Icons.my_location : Icons.place_outlined,
                    size: 18,
                    color: NexaColors.cyan,
                  ),
                ),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        vacio ? (hint ?? '') : texto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: NexaTexto.cuerpo.copyWith(
                          fontWeight: FontWeight.w600,
                          color: vacio ? context.muted : null,
                        ),
                      ),
                      Text(
                        etiqueta,
                        style: NexaTexto.pequeno.copyWith(
                          color: NexaColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opción única de vehículo con el precio que fijó el servidor (diseño P03).
/// [antes] tachado = el precio sin el descuento por nivel.
class _TarjetaPrecio extends StatelessWidget {
  const _TarjetaPrecio({
    required this.detalle,
    required this.precio,
    this.antes,
  });

  final String detalle;
  final String precio;
  final String? antes;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return NexaCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: NexaColors.raised,
              borderRadius: BorderRadius.circular(Rad.md),
              border: Border.all(color: NexaColors.cyan.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.two_wheeler, color: NexaColors.cyan),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.motoNexa, style: NexaTexto.subtitulo),
                Text(
                  detalle,
                  style: NexaTexto.pequeno.copyWith(color: NexaColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: Sp.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(precio, style: NexaTexto.numeroMedio),
              if (antes != null)
                Text(
                  antes!,
                  style: NexaTexto.pequeno.copyWith(
                    color: NexaColors.tenue,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: NexaColors.tenue,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Barra dorada con lo que ahorra el nivel en este viaje.
class _BarraAhorro extends StatelessWidget {
  const _BarraAhorro({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
    decoration: BoxDecoration(
      color: NexaColors.goldSuave,
      borderRadius: BorderRadius.circular(Rad.md),
      border: Border.all(color: NexaColors.gold.withValues(alpha: 0.45)),
    ),
    child: Row(
      children: [
        const Icon(Icons.bolt_rounded, size: 18, color: NexaColors.gold),
        const SizedBox(width: Sp.sm),
        Expanded(
          child: Text(
            texto,
            style: NexaTexto.pequeno.copyWith(
              color: NexaColors.gold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({
    required this.icono,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icono;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    icon: Icon(icono),
    style: IconButton.styleFrom(
      minimumSize: const Size(Sizes.touch, Sizes.touch),
      backgroundColor: NexaColors.glass,
      foregroundColor: NexaColors.texto,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.md),
        side: const BorderSide(color: NexaColors.line),
      ),
    ),
  );
}
