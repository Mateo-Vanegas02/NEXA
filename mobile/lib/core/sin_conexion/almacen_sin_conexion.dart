import 'reglas_sin_conexion.dart';

/// Lo que el teléfono guarda para aguantar sin señal (fase 5): la cola de
/// acciones, los puntos de GPS y la última copia del viaje. Nada de tarifas,
/// comisión, deuda ni calificaciones ajenas: el servidor sigue decidiendo.
abstract class AlmacenSinConexion {
  Future<void> encolar(AccionPendiente accion);

  /// En el orden en que se hicieron.
  Future<List<AccionPendiente>> cola();
  Future<void> quitar(String llave);
  Future<void> sumarIntento(String llave);

  Future<void> guardarPunto(PuntoGuardado punto);

  /// Los más viejos primero.
  Future<List<PuntoGuardado>> puntos({
    int limite = ReglasSinConexion.puntosPorLote,
  });
  Future<void> quitarPuntos(List<int> ids);

  /// Copia del viaje (JSON de la vista que entregó el servidor) por rol.
  Future<void> guardarInstantanea(String clave, String json);
  Future<({String json, DateTime en})?> instantanea(String clave);
  Future<void> borrarInstantanea(String clave);

  /// Al cerrar sesión: no queda nada de la cuenta en el teléfono.
  Future<void> vaciar();
}

/// Pruebas, modo demostración y respaldo si la base no abre.
class AlmacenEnMemoria implements AlmacenSinConexion {
  final List<AccionPendiente> _cola = [];
  final List<PuntoGuardado> _puntos = [];
  final Map<String, ({String json, DateTime en})> _copias = {};
  int _siguiente = 1;

  @override
  Future<void> encolar(AccionPendiente accion) async {
    if (_cola.any((a) => a.llave == accion.llave)) return;
    _cola.add(accion);
  }

  @override
  Future<List<AccionPendiente>> cola() async => List.of(_cola);

  @override
  Future<void> quitar(String llave) async =>
      _cola.removeWhere((a) => a.llave == llave);

  @override
  Future<void> sumarIntento(String llave) async {
    final i = _cola.indexWhere((a) => a.llave == llave);
    if (i < 0) return;
    final a = _cola[i];
    _cola[i] = AccionPendiente(
      llave: a.llave,
      tipo: a.tipo,
      servicioId: a.servicioId,
      ocurridoEn: a.ocurridoEn,
      latitud: a.latitud,
      longitud: a.longitud,
      intentos: a.intentos + 1,
    );
  }

  @override
  Future<void> guardarPunto(PuntoGuardado punto) async {
    _puntos.add(
      PuntoGuardado(
        id: _siguiente++,
        latitud: punto.latitud,
        longitud: punto.longitud,
        tomadoEn: punto.tomadoEn,
      ),
    );
    if (_puntos.length > ReglasSinConexion.maxPuntos) _puntos.removeAt(0);
  }

  @override
  Future<List<PuntoGuardado>> puntos({
    int limite = ReglasSinConexion.puntosPorLote,
  }) async => _puntos.take(limite).toList();

  @override
  Future<void> quitarPuntos(List<int> ids) async =>
      _puntos.removeWhere((p) => ids.contains(p.id));

  @override
  Future<void> guardarInstantanea(String clave, String json) async =>
      _copias[clave] = (json: json, en: DateTime.now());

  @override
  Future<({String json, DateTime en})?> instantanea(String clave) async =>
      _copias[clave];

  @override
  Future<void> borrarInstantanea(String clave) async => _copias.remove(clave);

  @override
  Future<void> vaciar() async {
    _cola.clear();
    _puntos.clear();
    _copias.clear();
  }
}
