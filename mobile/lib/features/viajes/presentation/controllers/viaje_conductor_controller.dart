import '../../../../core/config/env.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/mapa/polyline.dart';
import '../../../../core/mapa/reglas_ruta.dart';
import '../../../../core/providers.dart';
import '../../../../core/segundo_plano/modo_segundo_plano.dart';
import '../../../../core/sin_conexion/reglas_sin_conexion.dart';
import '../../../../core/utils/mi_posicion.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../niveles/presentation/controllers/niveles_controller.dart';
import '../../domain/opcion_ruta.dart';
import '../../domain/servicio.dart';
import '../../domain/viajes_repository.dart';
import 'sin_conexion_controller.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Fase visible del viaje del conductor (la deduce el estado y `fechaLlegada`).
enum FaseConductor { aRecoger, enElPunto, enViaje }

/// Qué pasa con la ruta cuando el conductor toma otra calle (rediseño 2026).
enum EstadoDesvio { ninguno, buscando, opciones, sinOpciones }

class ConductorState {
  const ConductorState({
    this.aprobacion = EstadoAprobacion.pendiente,
    this.enLinea = false,
    this.solicitudes = const [],
    this.activo,
    this.posicion,
    this.pasajero,
    this.terminado,
    this.desgloseTerminado,
    this.pasajeroCancelo = false,
    this.copiaDe,
    this.desvio = EstadoDesvio.ninguno,
    this.rutasOfrecidas = const [],
    this.rutaPropia,
    this.rutaPropiaFase,
  });

  final EstadoAprobacion aprobacion;
  final bool enLinea;
  final List<Servicio> solicitudes;
  final Servicio? activo;

  /// Posición propia con la fase, distancia y ETA que calcula el servidor.
  final PosicionViaje? posicion;

  /// Dónde está el pasajero mientras el conductor va a recogerlo.
  final PosicionPasajero? pasajero;

  /// Viaje recién finalizado, hasta que el conductor cierra el resumen.
  final Servicio? terminado;
  final DesgloseConductor? desgloseTerminado;

  /// El pasajero canceló el viaje que tenía activo el conductor.
  final bool pasajeroCancelo;

  /// Sin señal al abrir: el viaje sale de la copia guardada a esta hora.
  final DateTime? copiaDe;

  /// Desvío de la ruta y las rutas que ofreció el servidor para elegir.
  final EstadoDesvio desvio;
  final List<OpcionRuta> rutasOfrecidas;

  /// Ruta que eligió el conductor (o la que el servidor dio hasta el
  /// pasajero), válida solo en la fase [rutaPropiaFase].
  final List<LatLng>? rutaPropia;
  final FaseConductor? rutaPropiaFase;

  /// La ruta que se dibuja y contra la que se mide el desvío: la elegida en
  /// esta fase o, en viaje, la del servidor. Yendo a recoger sin ruta propia
  /// no hay (la del servidor es la del viaje, no la de la recogida).
  List<LatLng>? get rutaVigente {
    final f = fase;
    if (f == null) return null;
    final propia = rutaPropia;
    if (propia != null && rutaPropiaFase == f) return propia;
    if (f != FaseConductor.enViaje) return null;
    final delServidor = rutaDe(activo?.rutaGeometria);
    return delServidor.length >= 2 ? delServidor : null;
  }

  FaseConductor? get fase {
    final a = activo;
    if (a == null) return null;
    if (a.estado == EstadoServicio.enCurso) return FaseConductor.enViaje;
    return a.fechaLlegada == null
        ? FaseConductor.aRecoger
        : FaseConductor.enElPunto;
  }

  ConductorState copyWith({
    EstadoAprobacion? aprobacion,
    bool? enLinea,
    List<Servicio>? solicitudes,
    Servicio? activo,
    bool limpiarActivo = false,
    PosicionViaje? posicion,
    bool limpiarPosicion = false,
    PosicionPasajero? pasajero,
    bool limpiarPasajero = false,
    Servicio? terminado,
    DesgloseConductor? desgloseTerminado,
    bool limpiarTerminado = false,
    bool? pasajeroCancelo,
    DateTime? copiaDe,
    bool limpiarCopia = false,
    EstadoDesvio? desvio,
    List<OpcionRuta>? rutasOfrecidas,
    List<LatLng>? rutaPropia,
    FaseConductor? rutaPropiaFase,
  }) => ConductorState(
    aprobacion: aprobacion ?? this.aprobacion,
    enLinea: enLinea ?? this.enLinea,
    solicitudes: solicitudes ?? this.solicitudes,
    activo: limpiarActivo ? null : (activo ?? this.activo),
    posicion: limpiarPosicion ? null : (posicion ?? this.posicion),
    pasajero: limpiarPasajero ? null : (pasajero ?? this.pasajero),
    terminado: limpiarTerminado ? null : (terminado ?? this.terminado),
    desgloseTerminado: limpiarTerminado
        ? null
        : (desgloseTerminado ?? this.desgloseTerminado),
    pasajeroCancelo: pasajeroCancelo ?? this.pasajeroCancelo,
    copiaDe: limpiarCopia ? null : (copiaDe ?? this.copiaDe),
    // Sin viaje no hay ruta propia ni desvío.
    desvio: limpiarActivo
        ? EstadoDesvio.ninguno
        : (desvio ?? this.desvio),
    rutasOfrecidas: limpiarActivo
        ? const []
        : (rutasOfrecidas ?? this.rutasOfrecidas),
    rutaPropia: limpiarActivo ? null : (rutaPropia ?? this.rutaPropia),
    rutaPropiaFase: limpiarActivo
        ? null
        : (rutaPropiaFase ?? this.rutaPropiaFase),
  );
}

/// Panel del conductor: aprobación, conexión, solicitudes y viaje activo.
///
/// Mientras está en línea o tiene un viaje, cada 5 s:
/// - reporta su posición (`POST /conductor/ubicacion`): sin esto el servidor solo
///   le muestra las solicitudes de la última ola de despacho;
/// - en línea y libre, pide las solicitudes cercanas;
/// - con un viaje, refresca el viaje (detecta si el pasajero lo canceló), toma
///   la fase/ETA que calcula el servidor y, yendo a recoger, la posición del pasajero.
class ConductorController extends AsyncNotifier<ConductorState> {
  Timer? _timer;
  Timer? _timerPosicion;
  bool _sondeando = false;
  bool _reportando = false;
  int _ciclo = 0;
  final Set<String> _rechazadas = {};
  final _detector = DetectorDesvio();

  /// Viaje para el que ya se pidió la ruta hasta el pasajero.
  String? _rutaRecogidaPara;

  /// El servidor no tiene rutas en vivo (404): solo se avisa el desvío.
  bool _sinRutasEnServidor = false;

  /// Un paso propio (Llegué, Iniciar, Finalizar) va en camino: si el sondeo
  /// ve el viaje cerrado mientras tanto, no es que el pasajero cancelara.
  bool _avanzando = false;

  @override
  Future<ConductorState> build() async {
    ref.onDispose(_pararTimers);
    // Sin sesión (recién cerrada) no se consulta nada: respondería 401.
    if (sinSesionActiva(ref)) {
      return Completer<ConductorState>().future;
    }
    _guardarCopiaAlCambiar();
    try {
      final aprobacion = await ref
          .read(authRepositoryProvider)
          .estadoAprobacion();
      if (aprobacion != EstadoAprobacion.aprobado) {
        return ConductorState(aprobacion: aprobacion);
      }
      final activo = await _repo.viajeActivo();
      if (activo != null) _iniciarPolling();
      return ConductorState(aprobacion: aprobacion, activo: activo);
    } on Object catch (e) {
      // Sin señal al abrir: el viaje que tenía, desde la copia del teléfono.
      if (!ReglasSinConexion.esFaltaDeRed(e)) rethrow;
      final copia = await _leerCopia();
      if (copia == null) rethrow;
      _iniciarPolling();
      return ConductorState(
        aprobacion: EstadoAprobacion.aprobado,
        activo: copia.viaje,
        copiaDe: copia.en,
      );
    }
  }

  static const _claveCopia = 'conductor';

  /// Guarda en el teléfono el viaje activo cada vez que cambia de paso (no en
  /// cada sondeo) y lo borra al terminar.
  void _guardarCopiaAlCambiar() {
    listenSelf((antes, ahora) {
      final a = antes?.value?.activo;
      final n = ahora.value?.activo;
      if (a?.id == n?.id &&
          a?.estado == n?.estado &&
          a?.fechaLlegada == n?.fechaLlegada) {
        return;
      }
      final almacen = ref.read(almacenSinConexionProvider);
      unawaited(
        (n == null
                ? almacen.borrarInstantanea(_claveCopia)
                : almacen.guardarInstantanea(
                    _claveCopia,
                    jsonEncode(n.toJson()),
                  ))
            .catchError((Object _) {}),
      );
    });
  }

  Future<({Servicio viaje, DateTime en})?> _leerCopia() async {
    try {
      final c = await ref
          .read(almacenSinConexionProvider)
          .instantanea(_claveCopia);
      if (c == null) return null;
      final datos = jsonDecode(c.json);
      if (datos is! Map<String, dynamic>) return null;
      return (viaje: Servicio.fromJson(datos), en: c.en);
    } on Object {
      return null;
    }
  }

  ConductorRepository get _repo => ref.read(conductorRepositoryProvider);

  ConductorState get _s => state.requireValue;

  void _iniciarPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(Env.pollingInterval, (_) => sondear());
    _timerPosicion?.cancel();
    _timerPosicion = Timer.periodic(
      Env.pollingPosicion,
      (_) => reportarPosicion(),
    );
  }

  void _pararTimers() {
    _timer?.cancel();
    _timer = null;
    _timerPosicion?.cancel();
    _timerPosicion = null;
  }

  Coordenada _coord(({double lat, double lng}) p) =>
      Coordenada(latitud: p.lat, longitud: p.lng);

  Future<({double lat, double lng})?> _gps() async {
    final p = await ref.read(miPosicionProvider)();
    return p == null ? null : (lat: p.latitude, lng: p.longitude);
  }

  Future<void> sondear() async {
    final actual = state.value;
    if (actual == null) return;
    if (!actual.enLinea && actual.activo == null) {
      _pararTimers();
      return;
    }
    if (_sondeando) return;
    // Pantalla apagada y sin viaje: cada 15 s en vez de cada 5 s.
    if (ReglasSegundoPlano.saltarCiclo(
      primerPlano: ref.read(primerPlanoProvider),
      conViaje: actual.activo != null,
      ciclo: _ciclo++,
    )) {
      return;
    }
    _sondeando = true;
    try {
      // Lo hecho sin señal va primero: hasta enviarlo, el viaje que se ve es el
      // del teléfono (si no, el servidor «desharía» el paso aún no enviado).
      final alDia = await ref.read(sinConexionProvider.notifier).enviar();
      final gps = await _gps();
      if (actual.activo != null) {
        await _sondearViaje(actual.activo!, gps, alDia: alDia);
      } else {
        PosicionViaje? aVer;
        if (gps != null) {
          aVer = await _repo.reportarUbicacion(_coord(gps), disponible: true);
        }
        // Si acaba de aceptar un viaje desde otro lado, el servidor ya lo sigue.
        if (aVer != null) {
          final activo = await _repo.viajeActivo();
          if (activo != null) {
            state = AsyncData(_s.copyWith(activo: activo));
            return;
          }
        }
        final solicitudes = (await _repo.disponibles(
          lat: gps?.lat,
          lng: gps?.lng,
        )).where((s) => !_rechazadas.contains(s.id)).toList();
        state = AsyncData(_s.copyWith(solicitudes: solicitudes));
      }
    } on Object {
      // Se reintenta en el siguiente ciclo.
    } finally {
      _sondeando = false;
    }
  }

  Future<void> _sondearViaje(
    Servicio activo,
    ({double lat, double lng})? gps, {
    bool alDia = true,
  }) async {
    PosicionViaje? posicion;
    if (gps != null) {
      try {
        posicion = await _repo.reportarUbicacion(
          _coord(gps),
          disponible: false,
        );
      } on Object catch (e) {
        // Sin señal: la posición se guarda con su hora para el recorrido real.
        if (ReglasSinConexion.esFaltaDeRed(e)) {
          await ref
              .read(sinConexionProvider.notifier)
              .guardarPunto(gps.lat, gps.lng);
        }
        rethrow;
      }
    }
    if (!alDia) {
      state = AsyncData(_s.copyWith(posicion: posicion));
      return;
    }
    final vigente = await _repo.viajeActivo();
    if (vigente == null) {
      // Un paso propio en marcha (p. ej. «Finalizar») también deja el viaje
      // sin activo: no es que el pasajero cancelara. Lo resuelve ese paso.
      if (_avanzando || state.value?.activo?.id != activo.id) return;
      // 204: el viaje ya no está activo (lo canceló el pasajero).
      _pararTimers();
      state = AsyncData(
        _s.copyWith(
          limpiarActivo: true,
          limpiarPosicion: true,
          limpiarPasajero: true,
          pasajeroCancelo: true,
        ),
      );
      return;
    }
    PosicionPasajero? pasajero;
    if (vigente.estado == EstadoServicio.aceptado) {
      pasajero = await _repo.ubicacionPasajero(vigente.id);
    }
    state = AsyncData(
      _s.copyWith(
        activo: vigente,
        limpiarCopia: true,
        posicion: posicion,
        limpiarPosicion: posicion == null,
        pasajero: pasajero,
        limpiarPasajero: pasajero == null,
      ),
    );
  }

  Future<void> alternarLinea() async {
    final enLinea = !_s.enLinea;
    state = AsyncData(_s.copyWith(enLinea: enLinea, pasajeroCancelo: false));
    if (enLinea) {
      _iniciarPolling();
      await sondear();
    } else {
      state = AsyncData(_s.copyWith(solicitudes: const []));
      if (_s.activo == null) _pararTimers();
      // Avisa al servidor para que deje de despacharle solicitudes.
      final gps = await _gps();
      if (gps != null) {
        try {
          await _repo.reportarUbicacion(_coord(gps), disponible: false);
        } on Object {
          // Sin conexión: el servidor lo da por desconectado a los 45 s.
        }
      }
    }
  }

  /// Acepta una solicitud. Si otro conductor la tomó (409) o ya no está en su
  /// ola (403), se quita de la lista y el error llega a la pantalla.
  Future<void> aceptar(Servicio s) => aceptarPorId(s.id);

  /// Igual que [aceptar], con solo el id (botón «Aceptar» de la notificación).
  /// Espera a que el panel termine de cargar si la app acaba de abrirse.
  Future<void> aceptarPorId(String id) async {
    await future;
    try {
      final nuevo = await _repo.aceptar(id);
      state = AsyncData(
        _s.copyWith(
          activo: nuevo,
          solicitudes: const [],
          pasajeroCancelo: false,
        ),
      );
      _iniciarPolling();
    } on Object catch (e) {
      final codigo = AppException.from(e).statusCode;
      if (codigo == 409 || codigo == 403 || codigo == 404) {
        state = AsyncData(
          _s.copyWith(
            solicitudes: [..._s.solicitudes.where((x) => x.id != id)],
          ),
        );
      }
      rethrow;
    }
  }

  /// El backend no tiene "rechazar": se oculta localmente (PENDIENTES_BACKEND.md).
  void rechazar(Servicio s) {
    _rechazadas.add(s.id);
    state = AsyncData(
      _s.copyWith(solicitudes: [..._s.solicitudes.where((e) => e.id != s.id)]),
    );
  }

  /// Avanza el viaje: "Llegué" → iniciar → finalizar. El servidor valida cada
  /// paso (llegada a ≤ 50 m de la recogida; sin "llegué" no deja iniciar).
  ///
  /// Sin señal, el paso se guarda en la cola del teléfono con su hora (y la
  /// posición, en «Llegué») y la pantalla avanza marcándolo «Pendiente de
  /// enviar»; al volver la señal se envía con la misma llave, así nunca se
  /// repite. Si el servidor dice que ya no aplica, gana el servidor.
  Future<void> avanzar() async {
    if (_avanzando) return;
    _avanzando = true;
    try {
      await _avanzar();
    } finally {
      _avanzando = false;
    }
  }

  Future<void> _avanzar() async {
    final activo = _s.activo;
    final fase = _s.fase;
    if (activo == null || fase == null) return;
    final llave = ReglasSinConexion.nuevaLlave();
    final ahora = DateTime.now();
    switch (fase) {
      case FaseConductor.aRecoger:
        final gps = await _gps();
        if (gps == null) {
          throw const AppException(
            ErrorKind.validacion,
            'No pudimos obtener tu ubicación. Activa el GPS e inténtalo de nuevo.',
          );
        }
        await _paso(
          () => _repo.llegue(
            activo.id,
            _coord(gps),
            llave: llave,
            ocurridoEn: ahora,
          ),
          AccionPendiente(
            llave: llave,
            tipo: TipoPendiente.llegue,
            servicioId: activo.id,
            ocurridoEn: ahora,
            latitud: gps.lat,
            longitud: gps.lng,
          ),
          enCola: () => activo.copyWith(fechaLlegada: ahora),
        );
      case FaseConductor.enElPunto:
        await _paso(
          () => _repo.iniciar(activo.id, llave: llave, ocurridoEn: ahora),
          AccionPendiente(
            llave: llave,
            tipo: TipoPendiente.iniciar,
            servicioId: activo.id,
            ocurridoEn: ahora,
          ),
          enCola: () => activo.copyWith(
            estado: EstadoServicio.enCurso,
            fechaInicio: ahora,
          ),
        );
      case FaseConductor.enViaje:
        Servicio fin;
        var enCola = false;
        try {
          fin = await _repo.finalizar(
            activo.id,
            llave: llave,
            ocurridoEn: ahora,
          );
        } on Object catch (e) {
          if (!ReglasSinConexion.esFaltaDeRed(e)) rethrow;
          await ref
              .read(sinConexionProvider.notifier)
              .encolar(
                AccionPendiente(
                  llave: llave,
                  tipo: TipoPendiente.finalizar,
                  servicioId: activo.id,
                  ocurridoEn: ahora,
                ),
              );
          // El cobro lo calcula el servidor al recibirlo: aquí solo se cierra.
          fin = activo.copyWith(estado: EstadoServicio.finalizado);
          enCola = true;
        }
        DesgloseConductor? desglose;
        if (!enCola) {
          try {
            desglose = await _repo.desglose(fin.id);
          } on Object {
            // El resumen se muestra igual con el total del viaje.
          }
        }
        state = AsyncData(
          _s.copyWith(
            limpiarActivo: true,
            limpiarPosicion: true,
            limpiarPasajero: true,
            terminado: fin,
            desgloseTerminado: desglose,
            pasajeroCancelo: false,
          ),
        );
        if (!_s.enLinea) _pararTimers();
        if (enCola) return;
        ref.invalidate(ingresosProvider);
        ref.invalidate(saldoProvider);
        await ref
            .read(nivelProvider.notifier)
            .viajeCompletado(fin.xpGanadoConductor);
    }
  }

  /// Un paso del viaje: en línea, lo que diga el servidor; sin señal, a la cola
  /// y el viaje avanza en el teléfono.
  Future<void> _paso(
    Future<Servicio> Function() enviar,
    AccionPendiente accion, {
    required Servicio Function() enCola,
  }) async {
    try {
      final nuevo = await enviar();
      state = AsyncData(_s.copyWith(activo: nuevo, limpiarCopia: true));
    } on Object catch (e) {
      if (!ReglasSinConexion.esFaltaDeRed(e)) rethrow;
      await ref.read(sinConexionProvider.notifier).encolar(accion);
      state = AsyncData(_s.copyWith(activo: enCola()));
    }
  }

  /// Con un viaje en marcha, cada [Env.pollingPosicion]: envía el último dato
  /// del GPS (sin pedirlo de nuevo) para que el pasajero vea la moto casi en
  /// vivo, y revisa si el conductor se salió de la ruta.
  Future<void> reportarPosicion() async {
    final actual = state.value;
    final activo = actual?.activo;
    if (actual == null || activo == null || _reportando) return;
    final rastreador = ref.read(rastreadorProvider);
    final p = rastreador.ultima;
    final en = rastreador.ultimaEn;
    if (p == null ||
        en == null ||
        DateTime.now().difference(en) > const Duration(seconds: 6)) {
      return;
    }
    _reportando = true;
    try {
      // El ciclo de 5 s también reporta: si está en curso, este se salta.
      if (!_sondeando) {
        final posicion = await _repo.reportarUbicacion(
          Coordenada(latitud: p.latitude, longitud: p.longitude),
          disponible: false,
        );
        final ahora = state.value;
        if (posicion != null && ahora?.activo?.id == activo.id) {
          state = AsyncData(ahora!.copyWith(posicion: posicion));
        }
      }
    } on Object {
      // Sin señal: el ciclo de 5 s guarda el punto para el recorrido real.
    } finally {
      _reportando = false;
    }
    revisarRuta(p);
  }

  /// Yendo a recoger pide una vez la ruta hasta el pasajero; en cualquier
  /// fase, si la moto se salió de la ruta, pide rutas nuevas.
  void revisarRuta(LatLng p) {
    final s = state.value;
    final a = s?.activo;
    if (s == null || a == null) return;
    if (s.fase == FaseConductor.aRecoger &&
        _rutaRecogidaPara != a.id &&
        !_sinRutasEnServidor) {
      _rutaRecogidaPara = a.id;
      unawaited(pedirRutas(desde: p, automatica: true));
      return;
    }
    if (s.desvio != EstadoDesvio.ninguno) return;
    final ruta = s.rutaVigente;
    if (ruta == null) return;
    if (_detector.registrar(ruta, p, DateTime.now())) {
      unawaited(pedirRutas(desde: p));
    }
  }

  /// Pide rutas desde donde va (al salirse de la ruta o con «Rutas»).
  /// [automatica]: la ruta hasta el pasajero; se toma la sugerida sin
  /// preguntar y sin avisos.
  Future<void> pedirRutas({LatLng? desde, bool automatica = false}) async {
    final a = state.value?.activo;
    if (a == null) return;
    EstadoDesvio fallo() =>
        automatica ? EstadoDesvio.ninguno : EstadoDesvio.sinOpciones;
    if (_sinRutasEnServidor) {
      if (!automatica) state = AsyncData(_s.copyWith(desvio: fallo()));
      return;
    }
    var origen = desde;
    if (origen == null) {
      final g = await _gps();
      if (g != null) origen = LatLng(g.lat, g.lng);
    }
    if (origen == null) {
      if (!automatica) state = AsyncData(_s.copyWith(desvio: fallo()));
      return;
    }
    if (!automatica) {
      state = AsyncData(_s.copyWith(desvio: EstadoDesvio.buscando));
    }
    try {
      final opciones = await _repo.rutasDesde(
        a.id,
        Coordenada(latitud: origen.latitude, longitud: origen.longitude),
      );
      final s = state.value;
      if (s == null || s.activo?.id != a.id) return;
      final validas = [
        for (final o in opciones)
          if (rutaDe(o.geometria).length >= 2) o,
      ];
      if (validas.isEmpty) {
        state = AsyncData(s.copyWith(desvio: fallo()));
      } else if (automatica) {
        state = AsyncData(
          s.copyWith(
            rutaPropia: rutaDe(validas.first.geometria),
            rutaPropiaFase: s.fase,
          ),
        );
        _detector.reiniciar();
      } else {
        state = AsyncData(
          s.copyWith(desvio: EstadoDesvio.opciones, rutasOfrecidas: validas),
        );
      }
    } on Object catch (e) {
      final codigo = AppException.from(e).statusCode;
      // El servidor aún no tiene rutas en vivo: desde aquí solo se avisa.
      if (codigo == 404 || codigo == 405) _sinRutasEnServidor = true;
      final s = state.value;
      if (s != null && s.activo?.id == a.id) {
        state = AsyncData(s.copyWith(desvio: fallo()));
      }
    }
  }

  /// Elige una de las rutas ofrecidas: se dibuja al instante y se avisa al
  /// servidor (con el viaje en curso, el pasajero la ve en su mapa).
  Future<void> elegirRuta(int indice) async {
    final s = state.value;
    final a = s?.activo;
    if (s == null || a == null || s.rutasOfrecidas.isEmpty) return;
    final op = s.rutasOfrecidas.firstWhere(
      (o) => o.indice == indice,
      orElse: () => s.rutasOfrecidas.first,
    );
    state = AsyncData(
      s.copyWith(
        desvio: EstadoDesvio.ninguno,
        rutasOfrecidas: const [],
        rutaPropia: rutaDe(op.geometria),
        rutaPropiaFase: s.fase,
      ),
    );
    _detector.reiniciar();
    try {
      await _repo.elegirRuta(a.id, op.indice);
    } on Object {
      // La ruta vale en el teléfono; el pasajero sigue viendo la anterior.
    }
  }

  /// Cierra el aviso de desvío o la lista de rutas sin elegir.
  void descartarRutas() => state = AsyncData(
    _s.copyWith(desvio: EstadoDesvio.ninguno, rutasOfrecidas: const []),
  );

  Future<void> cancelarActivo() async {
    final activo = _s.activo;
    if (activo == null) return;
    await _repo.cancelar(activo.id);
    state = AsyncData(
      _s.copyWith(
        limpiarActivo: true,
        limpiarPosicion: true,
        limpiarPasajero: true,
      ),
    );
    if (!_s.enLinea) _pararTimers();
  }

  void cerrarResumen() =>
      state = AsyncData(_s.copyWith(limpiarTerminado: true));

  void descartarAvisoCancelacion() =>
      state = AsyncData(_s.copyWith(pasajeroCancelo: false));

  /// Califica al pasajero del viaje [id] (opcional; diseño C07).
  Future<void> calificarPasajero(
    String id,
    double calificacion,
    String comentarios, {
    List<String> factores = const [],
  }) => _repo.calificar(id, calificacion, comentarios, factores: factores);
}

final conductorProvider =
    AsyncNotifierProvider<ConductorController, ConductorState>(
      ConductorController.new,
    );

final ingresosProvider = FutureProvider<List<Ingreso>>(
  (ref) => ref.watch(conductorRepositoryProvider).ingresos(),
);

/// Saldo con NEXA de los últimos 30 días (vista del conductor: sin comisión).
final saldoProvider = FutureProvider<SaldoConductor>(
  (ref) => ref.watch(conductorRepositoryProvider).saldo(),
);
