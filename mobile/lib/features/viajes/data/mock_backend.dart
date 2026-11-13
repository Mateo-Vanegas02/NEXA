import 'dart:math' as math;

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/geo.dart';
import '../../niveles/domain/nivel.dart';
import '../../niveles/domain/niveles_repository.dart';
import '../../../core/sin_conexion/reglas_sin_conexion.dart';
import '../domain/perfil_pasajero.dart';
import '../domain/servicio.dart';
import '../domain/viajes_repository.dart';

/// XP para llegar al nivel [n] del pasajero (modelo v2.3): 10·round(270·(n−1)^1,5 / 10).
int _xpPasajeroParaNivel(int n) =>
    n <= 1 ? 0 : 10 * (270 * math.pow(n - 1, 1.5) / 10).round();

/// XP de 90 días para llegar al nivel [n] del conductor (1–5): 400·(n−1)².
int _xpConductorParaNivel(int n) => 400 * (n - 1) * (n - 1);

/// Comisión del conductor por nivel (1–5).
const List<double> _comisiones = [0.20, 0.19, 0.18, 0.16, 0.15];

/// Descuento del pasajero: min(1 % · nivel, 5 %) desde el nivel 2.
double _descuentoPasajero(int n) => n < 2 ? 0 : math.min(0.01 * n, 0.05);

/// Segundos de prioridad de recogida del pasajero (niveles 2–5).
int _prioridadPasajero(int n) => switch (n) {
  2 => 15,
  3 => 25,
  4 => 35,
  >= 5 => 45,
  _ => 0,
};

/// Estado en memoria compartido por los repositorios mock (pasajero, conductor, niveles).
/// Simula el ciclo SOLICITADO → ACEPTADO → EN_CURSO → FINALIZADO del backend.
class MockBackend {
  MockBackend({
    DateTime Function()? reloj,
    this.xpPasajero = 0,
    this.xpConductor = 0,
  }) : _reloj = reloj ?? DateTime.now {
    _sembrarSolicitudes();
    _sembrarHistorial();
  }

  final DateTime Function() _reloj;
  final List<Servicio> servicios = [];
  int xpPasajero;
  int xpConductor;
  int _seq = 0;
  final Map<String, DateTime> _creados = {};

  /// Viajes que pertenecen al pasajero de la sesión (semilla + solicitados).
  final Set<String> _propios = {};

  static const _pasajeroDemo = Participante(id: 'p1', nombre: 'Laura Gómez');
  static const _conductorDemo = Participante(
    id: 'c1',
    nombre: 'Carlos Mendoza',
    telefono: '3001234567',
    calificacion: 4.8,
    viajes: 320,
    vehiculo: 'Yamaha FZ 2.0 · Negra',
    placa: 'ABC 12D',
  );

  void _sembrarSolicitudes() {
    final nombres = ['Marta Ríos', 'Andrés Polo'];
    final destinos = ['Centro Comercial Caribe Plaza', 'Castillo San Felipe'];
    final km = [3.2, 5.1];
    for (var i = 0; i < 2; i++) {
      servicios.add(
        Servicio(
          id: 'sol-${++_seq}',
          estado: EstadoServicio.solicitado,
          pasajero: Participante(id: 'px$i', nombre: nombres[i]),
          origen: 'Bocagrande',
          destino: destinos[i],
          distanciaKM: km[i],
          ubicacionOrigen: const Coordenada(
            latitud: 10.4055,
            longitud: -75.5503,
          ),
          ubicacionDestino: const Coordenada(
            latitud: 10.4236,
            longitud: -75.5390,
          ),
          fechaHora: _reloj(),
          tarifa: _tarifa(km[i]),
          metodoPago: 'efectivo',
          nivelPasajero: i + 1,
        ),
      );
    }
  }

  void _sembrarHistorial() {
    final ahora = _reloj();
    final previos = [
      ('Casa', 'C.C. Plaza', 4.2, 8500.0, EstadoServicio.finalizado, 1),
      ('Universidad', 'Casa', 3.1, 6000.0, EstadoServicio.cancelado, 2),
    ];
    for (final (o, d, km, tarifa, estado, dias) in previos) {
      final s = Servicio(
        id: 'previo-${++_seq}',
        estado: estado,
        pasajero: _pasajeroDemo,
        conductor: _conductorDemo,
        origen: o,
        destino: d,
        distanciaKM: km,
        fechaHora: ahora.subtract(Duration(days: dias)),
        tarifa: tarifa,
        metodoPago: 'efectivo',
      );
      servicios.add(s);
      _propios.add(s.id);
    }
  }

  static double _tarifa(double km) => (3000 + 1200 * km).roundToDouble();

  /// Nivel del pasajero (desde 1, sin techo).
  int _nivelPasajero(int xp) {
    var n = 1;
    while (xp >= _xpPasajeroParaNivel(n + 1)) {
      n++;
    }
    return n;
  }

  /// Nivel del conductor (1–5).
  int _nivelConductor(int xp) {
    var n = 1;
    while (n < 5 && xp >= _xpConductorParaNivel(n + 1)) {
      n++;
    }
    return n;
  }

  double _comisionConductor() => _comisiones[_nivelConductor(xpConductor) - 1];

  int _xpViaje(double km) => math.min(90, 10 + (2 * km).round());

  void _reemplazar(Servicio s) {
    final i = servicios.indexWhere((e) => e.id == s.id);
    if (i >= 0) servicios[i] = s;
  }

  Servicio _buscar(String id) => servicios.firstWhere(
    (e) => e.id == id,
    orElse: () => throw const AppException(
      ErrorKind.noEncontrado,
      'Servicio no encontrado.',
      statusCode: 404,
    ),
  );

  /// El conductor simulado avanza el viaje del pasajero según el tiempo transcurrido.
  Servicio _avanzar(Servicio s) {
    final t = _creados[s.id];
    if (t == null || !s.estado.activo) return s;
    final seg = _reloj().difference(t).inSeconds;
    final EstadoServicio destino = seg >= 18
        ? EstadoServicio.finalizado
        : seg >= 10
        ? EstadoServicio.enCurso
        : seg >= 5
        ? EstadoServicio.aceptado
        : EstadoServicio.solicitado;
    var n = s;
    if (destino.index > s.estado.index) {
      n = s.copyWith(
        estado: destino,
        conductor: destino == EstadoServicio.solicitado ? null : _conductorDemo,
      );
      if (destino == EstadoServicio.finalizado) {
        final xp = _xpViaje(s.distanciaKM);
        xpPasajero += xp;
        n = n.copyWith(xpGanadoPasajero: xp);
      }
      _reemplazar(n);
    }
    return n;
  }

  // ---------------------------------------------------------------- pasajero
  /// Precio de demostración (el real lo cotiza el servidor).
  Cotizacion cotizar(Coordenada origen, Coordenada destino) {
    final km = estimarKm(origen, destino);
    final tarifa = _tarifa(km);
    return Cotizacion(
      distanciaKm: km,
      tarifa: tarifa,
      descuento: 0,
      precio: tarifa,
      totalAPagar: tarifa,
    );
  }

  Servicio subirExtra(String id, int incremento) {
    final s = _buscar(id);
    final nuevo = s.copyWith(extraVoluntario: s.extraVoluntario + incremento);
    _reemplazar(nuevo);
    return nuevo;
  }

  /// Posición simulada del conductor: del origen hacia el destino según el estado.
  PosicionViaje? posicionConductor(String id) {
    final s = _avanzar(_buscar(id));
    final o = s.ubicacionOrigen;
    final d = s.ubicacionDestino;
    if (o == null || d == null) return null;
    final (fase, f) = switch (s.estado) {
      EstadoServicio.aceptado => ('ACEPTADO', 0.0),
      EstadoServicio.enCurso => ('EN_CURSO', 0.5),
      _ => ('', -1.0),
    };
    if (f < 0) return null;
    final restante = s.distanciaKM * (1 - f);
    return PosicionViaje(
      fase: fase,
      latitud: o.latitud + (d.latitud - o.latitud) * f,
      longitud: o.longitud + (d.longitud - o.longitud) * f,
      distanciaRestanteKm: restante,
      etaMinutos: math.max(1, (restante / 21 * 60).round()),
    );
  }

  Servicio solicitar(SolicitudViaje s) {
    final km = estimarKm(s.ubicacionOrigen, s.ubicacionDestino);
    final nuevo = Servicio(
      id: 'viaje-${++_seq}',
      estado: EstadoServicio.solicitado,
      pasajero: _pasajeroDemo,
      origen: s.origen,
      destino: s.destino,
      distanciaKM: km,
      ubicacionOrigen: s.ubicacionOrigen,
      ubicacionDestino: s.ubicacionDestino,
      fechaHora: _reloj(),
      tarifa: _tarifa(km),
      metodoPago: s.metodoPago,
      nivelPasajero: _nivelPasajero(xpPasajero),
    );
    servicios.insert(0, nuevo);
    _creados[nuevo.id] = _reloj();
    _propios.add(nuevo.id);
    return nuevo;
  }

  List<Servicio> historialPasajero() => [
    for (final s in servicios)
      if (_propios.contains(s.id)) _avanzar(s),
  ];

  Servicio detallePasajero(String id) => _avanzar(_buscar(id));

  Servicio cancelarPasajero(String id) {
    final s = _buscar(id).copyWith(estado: EstadoServicio.cancelado);
    _reemplazar(s);
    return s;
  }

  Servicio calificar(String id, double cal, String comentarios) {
    final s = _buscar(id).copyWith(calificacionConductor: cal);
    _reemplazar(s);
    return s;
  }

  DesglosePasajero desglosePasajero(String id) {
    final s = _buscar(id);
    return DesglosePasajero(
      tarifa: s.tarifa,
      extraVoluntario: s.extraVoluntario,
      totalPasajero: s.tarifa + s.extraVoluntario,
      totalAPagar: s.tarifa + s.extraVoluntario,
    );
  }

  // --------------------------------------------------------------- conductor
  List<Servicio> disponibles() => [
    for (final s in servicios)
      if (s.estado == EstadoServicio.solicitado && !_propios.contains(s.id)) s,
  ];

  Servicio _transicion(String id, EstadoServicio e) {
    var s = _buscar(id).copyWith(estado: e, conductor: _conductorDemo);
    if (e == EstadoServicio.finalizado) {
      final xp = _xpViaje(s.distanciaKM);
      xpConductor += xp;
      s = s.copyWith(xpGanadoConductor: xp);
    }
    _reemplazar(s);
    return s;
  }

  Servicio aceptar(String id) => _transicion(id, EstadoServicio.aceptado);
  Servicio iniciar(String id) => _transicion(id, EstadoServicio.enCurso);
  Servicio finalizar(String id) => _transicion(id, EstadoServicio.finalizado);
  Servicio cancelarConductor(String id) {
    final s = _buscar(id)
        .copyWith(estado: EstadoServicio.solicitado, conductor: null);
    _reemplazar(s);
    return s;
  }

  List<Servicio> enCursoConductor() => [
    for (final s in servicios)
      if (s.conductor != null &&
          !_propios.contains(s.id) &&
          (s.estado == EstadoServicio.aceptado ||
              s.estado == EstadoServicio.enCurso))
        s,
  ];

  List<Servicio> historialConductor() => [
    for (final s in servicios)
      if (s.estado == EstadoServicio.finalizado && !_propios.contains(s.id)) s,
  ];

  DesgloseConductor desgloseConductor(String id) {
    final bruta = _buscar(id).tarifa;
    final c = _comisionConductor();
    return DesgloseConductor(
      gananciaConductor: bruta * (1 - c),
      cobrarAlPasajero: bruta,
    );
  }

  /// "Llegué" simulado: marca la llegada sin verificar la distancia.
  Servicio llegue(String id) {
    final s = _buscar(id).copyWith(fechaLlegada: _reloj());
    _reemplazar(s);
    return s;
  }

  Servicio? viajeActivoConductor() => enCursoConductor().firstOrNull;

  SaldoConductor saldoConductor() {
    final hechos = historialConductor();
    final bruto = hechos.fold<double>(0, (a, s) => a + s.tarifa);
    final c = _comisionConductor();
    return SaldoConductor(
      viajes: hechos.length,
      cobradoEfectivo: bruto,
      ganado: bruto * (1 - c),
      saldoConNexa: bruto * c,
    );
  }

  List<Ingreso> ingresos() => [
    for (final s in historialConductor())
      Ingreso(
        fecha: (s.fechaHora ?? _reloj()).toIso8601String().substring(0, 10),
        monto: s.tarifa * (1 - _comisionConductor()),
        montoBruto: s.tarifa,
        descripcion: 'Viaje con ${s.pasajero?.nombre ?? ''}',
      ),
  ];

  // ----------------------------------------------------------------- niveles
  NivelEstado niveles(String rol) {
    final esConductor = rol == 'conductor';
    final xp = esConductor ? xpConductor : xpPasajero;
    final n = esConductor ? _nivelConductor(xp) : _nivelPasajero(xp);
    final xpPara = esConductor ? _xpConductorParaNivel : _xpPasajeroParaNivel;
    final ultimo = esConductor && n >= 5;
    final sig = ultimo ? null : xpPara(n + 1);
    final actualXp = xpPara(n);
    final prog = sig == null ? 1.0 : (xp - actualXp) / (sig - actualXp);
    final base = esConductor
        ? const <Beneficio>[
            Beneficio(
              clave: 'COMISION',
              titulo: 'Comisión reducida',
              descripcion: 'Baja de 20 % a 15 % según tu nivel.',
              nivelRequerido: 2,
            ),
          ]
        : const <Beneficio>[
            Beneficio(
              clave: 'DESCUENTO',
              titulo: 'Descuento en tus viajes',
              descripcion: '1 % por nivel, hasta 5 %.',
              nivelRequerido: 2,
            ),
            Beneficio(
              clave: 'PRIORIDAD',
              titulo: 'Prioridad de recogida',
              descripcion: 'Tu solicitud llega antes a los conductores.',
              nivelRequerido: 2,
            ),
            Beneficio(
              clave: 'FAVORITOS',
              titulo: 'Conductores favoritos',
              descripcion: 'Guarda a los conductores que más te gustan.',
              nivelRequerido: 5,
            ),
          ];
    final maxNiveles = esConductor ? 5 : math.max(5, n + 1);
    return NivelEstado(
      usuarioId: esConductor ? 'mock-conductor' : 'mock-pasajero',
      rol: rol,
      nivel: n,
      xpActual: xp,
      xpNivelActual: actualXp,
      xpSiguienteNivel: sig,
      xpFaltante: sig == null ? 0 : sig - xp,
      progreso: prog,
      descuento: esConductor ? 0 : _descuentoPasajero(n),
      prioridadSegundos: esConductor ? 0 : _prioridadPasajero(n),
      niveles: [
        for (var i = 1; i <= maxNiveles; i++)
          NivelInfo(
            nivel: i,
            xp: xpPara(i),
            descuento: esConductor ? null : _descuentoPasajero(i),
            beneficios: [
              for (final b in base)
                if (b.nivelRequerido == i) b,
            ],
            comision: esConductor ? _comisiones[i - 1] : null,
          ),
      ],
      beneficiosActivos: [
        for (final b in base)
          if (n >= b.nivelRequerido) b.copyWith(activo: true),
      ],
      conductor: esConductor
          ? ConductorInfo(
              comisionActual: _comisiones[n - 1],
              comisionSiguiente: ultimo ? null : _comisiones[n],
              calificacion: 4.8,
              aceptacion: 0.9,
              cancelacion: 0.02,
              requisitosSiguiente: ultimo
                  ? const []
                  : [
                      Requisito(texto: 'Calificación ≥ 4.6', cumplido: n >= 2),
                      const Requisito(
                        texto: 'Cancelación ≤ 5 %',
                        cumplido: true,
                      ),
                    ],
            )
          : null,
    );
  }
}

class MockPasajeroRepository implements PasajeroRepository {
  MockPasajeroRepository(this._b);
  final MockBackend _b;

  @override
  Future<PerfilPasajero> perfil() async => const PerfilPasajero(
    nombre: 'Frank Salcedo',
    calificacion: 4.9,
    viajes: 28,
  );

  Future<T> _t<T>(T Function() f) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return f();
  }

  @override
  Future<Cotizacion> cotizar(Coordenada origen, Coordenada destino) =>
      _t(() => _b.cotizar(origen, destino));
  @override
  Future<void> subirExtra(String id, int incremento) =>
      _t(() => _b.subirExtra(id, incremento));
  @override
  Future<PosicionViaje?> posicionConductor(String id) =>
      _t(() => _b.posicionConductor(id));
  @override
  Future<void> reportarUbicacion(String id, Coordenada posicion) async {}
  @override
  Future<Servicio> solicitar(SolicitudViaje solicitud) =>
      _t(() => _b.solicitar(solicitud));
  @override
  Future<Servicio> cancelar(String id) => _t(() => _b.cancelarPasajero(id));
  @override
  Future<List<Servicio>> historial() => _t(_b.historialPasajero);
  @override
  Future<Servicio> detalle(String id) => _t(() => _b.detallePasajero(id));
  @override
  Future<String?> viajeAbiertoId() => _t(
    () => _b.historialPasajero().where((s) => s.estado.activo).firstOrNull?.id,
  );
  @override
  Future<Servicio> calificar(
    String id,
    double calificacion,
    String comentarios, {
    List<String> factores = const [],
  }) => _t(() => _b.calificar(id, calificacion, comentarios));
  @override
  Future<DesglosePasajero> desglose(String id) =>
      _t(() => _b.desglosePasajero(id));
}

class MockConductorRepository implements ConductorRepository {
  MockConductorRepository(this._b);
  final MockBackend _b;

  Future<T> _t<T>(T Function() f) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return f();
  }

  @override
  Future<List<Servicio>> disponibles({double? lat, double? lng}) =>
      _t(_b.disponibles);
  @override
  Future<PosicionViaje?> reportarUbicacion(
    Coordenada posicion, {
    required bool disponible,
  }) async => null;
  @override
  Future<Servicio?> viajeActivo() => _t(_b.viajeActivoConductor);
  @override
  Future<PosicionPasajero?> ubicacionPasajero(String id) async => null;
  @override
  Future<Servicio> llegue(
    String id,
    Coordenada posicion, {
    String? llave,
    DateTime? ocurridoEn,
  }) => _t(() => _b.llegue(id));
  @override
  Future<void> reportarLote(List<PuntoGuardado> puntos) async {}
  @override
  Future<SaldoConductor> saldo({int dias = 30}) => _t(_b.saldoConductor);
  @override
  Future<Servicio> aceptar(String id) => _t(() => _b.aceptar(id));
  @override
  Future<Servicio> iniciar(String id, {String? llave, DateTime? ocurridoEn}) =>
      _t(() => _b.iniciar(id));
  @override
  Future<Servicio> finalizar(
    String id, {
    String? llave,
    DateTime? ocurridoEn,
  }) => _t(() => _b.finalizar(id));
  @override
  Future<Servicio> cancelar(String id) => _t(() => _b.cancelarConductor(id));
  @override
  Future<List<Servicio>> enCurso() => _t(_b.enCursoConductor);
  @override
  Future<List<Servicio>> historial() => _t(_b.historialConductor);
  @override
  Future<List<Ingreso>> ingresos({String? periodo}) => _t(_b.ingresos);
  @override
  Future<DesgloseConductor> desglose(String id) =>
      _t(() => _b.desgloseConductor(id));

  @override
  Future<void> calificar(
    String id,
    double calificacion,
    String comentarios, {
    List<String> factores = const [],
  }) async {}
}

class MockNivelesRepository implements NivelesRepository {
  MockNivelesRepository(this._b);
  final MockBackend _b;

  @override
  Future<NivelEstado> me(String rol) async => _b.niveles(rol);
}

/// Estimado local de distancia entre dos puntos (usado también por la UI).
double estimarKm(Coordenada a, Coordenada b) =>
    distanciaKm(a.latitud, a.longitud, b.latitud, b.longitud);
