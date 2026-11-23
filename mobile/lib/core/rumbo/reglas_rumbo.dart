import 'dart:math' as math;

/// Lectura de un sensor de 3 ejes en el sistema del teléfono (Android:
/// x a la derecha, y hacia arriba de la pantalla, z saliendo de ella).
typedef Vector3 = ({double x, double y, double z});

/// De dónde sale el rumbo que se pinta.
enum FuenteRumbo {
  /// Sin rumbo fiable: el mapa queda con el norte arriba.
  ninguna,

  /// Brújula + giroscopio (quieto, caminando o a poca velocidad).
  sensores,

  /// Dirección de avance del GPS (en marcha: sobre una moto la brújula se
  /// confunde con el motor y el metal).
  gps,
}

/// Cómo está la brújula.
enum EstadoBrujula {
  /// Aún no hay lecturas.
  sinDatos,
  ok,

  /// El campo magnético medido no es el de la Tierra (imán, metal, sin
  /// calibrar): pedir el «8» y no usarla.
  interferencia,

  /// El teléfono no tiene magnetómetro.
  sinSensor,
}

/// Movimiento según el GPS (de `Position` de geolocator).
class MovimientoGps {
  const MovimientoGps({
    required this.rumbo,
    required this.velocidad,
    required this.en,
    this.precisionRumbo,
  });

  /// Grados desde el norte, en sentido horario.
  final double rumbo;

  /// m/s.
  final double velocidad;

  /// Precisión del rumbo en grados (null si el GPS no la da).
  final double? precisionRumbo;
  final DateTime en;
}

/// Reglas puras del rumbo y del giro del mapa (sin sensores ni Flutter), así
/// se prueban sin teléfono. Los ángulos van en grados desde el norte, sentido
/// horario, en [0, 360).
abstract final class ReglasRumbo {
  /// Desde esta velocidad manda el rumbo del GPS (≈ 8 km/h).
  static const velocidadGps = 8 / 3.6;

  /// Un rumbo GPS de hace más de esto ya no sirve.
  static const vigenciaGps = Duration(seconds: 5);

  /// Con una precisión de rumbo peor que esta, el GPS no se usa.
  static const precisionGpsMaxima = 45.0;

  /// Campo magnético terrestre válido (µT): fuera de esto hay interferencia.
  static const campoMinimo = 20.0;
  static const campoMaximo = 70.0;

  /// Se gira el mapa solo si el rumbo cambió más que esto…
  static const cambioMinimo = 2.0;

  /// …o esto con «reducir movimiento» (menos giros, sin animación).
  static const cambioMinimoSinAnimacion = 15.0;

  /// Máximo ~30 actualizaciones por segundo (fluido sin gastar de más).
  static const intervaloMinimo = Duration(milliseconds: 33);

  /// Con giroscopio, en cuánto tiempo la brújula corrige su deriva (filtro
  /// complementario): el giroscopio sigue los giros rápidos al instante y la
  /// brújula lleva el rumbo a su valor real en ~medio segundo, sea cual sea el
  /// ritmo de las lecturas.
  static const correccionBrujula = Duration(milliseconds: 500);

  /// Sin giroscopio solo se suaviza la brújula.
  static const pesoBrujulaSola = 0.2;

  static double normalizar(double grados) {
    final g = grados % 360;
    return g < 0 ? g + 360 : g;
  }

  /// Diferencia más corta de [desde] a [hasta], en (-180, 180].
  static double diferencia(double desde, double hasta) {
    final d = normalizar(hasta - desde);
    return d > 180 ? d - 360 : d;
  }

  /// Rumbo de la parte de arriba del teléfono según la brújula, compensando
  /// la inclinación con la gravedad (el mismo cálculo que
  /// `SensorManager.getRotationMatrix` + `getOrientation` de Android).
  /// Null si los vectores no sirven (caída libre, teléfono casi vertical…).
  static double? rumboBrujula(Vector3 gravedad, Vector3 magnetico) {
    final (ax, ay, az) = (gravedad.x, gravedad.y, gravedad.z);
    final (ex, ey, ez) = (magnetico.x, magnetico.y, magnetico.z);
    // H = E × A: apunta al este.
    var hx = ey * az - ez * ay;
    var hy = ez * ax - ex * az;
    var hz = ex * ay - ey * ax;
    final normaH = math.sqrt(hx * hx + hy * hy + hz * hz);
    final normaA = math.sqrt(ax * ax + ay * ay + az * az);
    if (normaH < 0.1 || normaA < 0.1) return null;
    hx /= normaH;
    hy /= normaH;
    hz /= normaH;
    final nx = ax / normaA;
    final nz = az / normaA;
    // M = A × H: apunta al norte.
    final my = nz * hx - nx * hz;
    return normalizar(math.atan2(hy, my) * 180 / math.pi);
  }

  static EstadoBrujula estadoCampo(Vector3 magnetico) {
    final m = math.sqrt(
      magnetico.x * magnetico.x +
          magnetico.y * magnetico.y +
          magnetico.z * magnetico.z,
    );
    return m >= campoMinimo && m <= campoMaximo
        ? EstadoBrujula.ok
        : EstadoBrujula.interferencia;
  }

  /// Velocidad de giro del rumbo (grados/s) a partir del giroscopio (rad/s):
  /// la parte del giro alrededor del eje vertical (la gravedad). Girar a la
  /// izquierda (antihorario visto desde arriba) baja el rumbo.
  static double giroRumbo(Vector3 giroscopio, Vector3 gravedad) {
    final g = math.sqrt(
      gravedad.x * gravedad.x +
          gravedad.y * gravedad.y +
          gravedad.z * gravedad.z,
    );
    if (g < 0.1) return 0;
    final vertical =
        (giroscopio.x * gravedad.x +
            giroscopio.y * gravedad.y +
            giroscopio.z * gravedad.z) /
        g;
    return -vertical * 180 / math.pi;
  }

  /// ¿El GPS da un rumbo usable?
  static bool gpsUsable(MovimientoGps? m, DateTime ahora) {
    if (m == null) return false;
    if (ahora.difference(m.en) > vigenciaGps) return false;
    if (m.velocidad < velocidadGps || m.rumbo.isNaN) return false;
    final p = m.precisionRumbo;
    return p == null || p <= 0 || p <= precisionGpsMaxima;
  }

  /// En marcha manda el GPS; si no, la brújula si está bien; si no, ninguna
  /// (norte arriba).
  static FuenteRumbo elegirFuente({
    required MovimientoGps? gps,
    required EstadoBrujula brujula,
    required DateTime ahora,
  }) {
    if (gpsUsable(gps, ahora)) return FuenteRumbo.gps;
    return brujula == EstadoBrujula.ok
        ? FuenteRumbo.sensores
        : FuenteRumbo.ninguna;
  }

  /// ¿Vale la pena girar el mapa? Ahorra batería: solo con un cambio visible y
  /// no más de 15 veces por segundo.
  static bool debeActualizar({
    required double? anterior,
    required double? nuevo,
    required DateTime? anteriorEn,
    required DateTime ahora,
    bool sinAnimacion = false,
  }) {
    if (anterior == null || nuevo == null) return anterior != nuevo;
    if (anteriorEn != null && ahora.difference(anteriorEn) < intervaloMinimo) {
      return false;
    }
    final minimo = sinAnimacion ? cambioMinimoSinAnimacion : cambioMinimo;
    return diferencia(anterior, nuevo).abs() > minimo;
  }

  /// Giro en pantalla del norte (positivo = horario) cuando lo que está
  /// adelante queda arriba: el mapa (MapLibre, `bearing` = rumbo) se ve girado
  /// −rumbo. Lo usan la aguja de la brújula y la flecha de la moto.
  static double rotacionMapa(double rumbo) => normalizar(-rumbo);

  /// Ángulo en pantalla de una flecha que apunta a [rumbo] sobre un mapa
  /// girado [rotacion] (marcadores que no giran con el mapa).
  static double anguloEnPantalla(double rumbo, double rotacion) =>
      normalizar(rumbo + rotacion);
}

/// Mezcla brújula y giroscopio (filtro complementario). Guarda estado entre
/// lecturas; un objeto por sesión de orientación.
class FusionRumbo {
  double? _rumbo;
  DateTime? _ultimaEn;
  EstadoBrujula estado = EstadoBrujula.sinDatos;

  /// Rumbo suavizado de los sensores (null si la brújula aún no sirve).
  double? get rumbo => estado == EstadoBrujula.ok ? _rumbo : null;

  /// Una lectura con los últimos valores de cada sensor. [giroscopio] es null
  /// si el teléfono no lo tiene. [magnetico] null = sin magnetómetro.
  void actualizar({
    required Vector3? gravedad,
    required Vector3? magnetico,
    required Vector3? giroscopio,
    required DateTime ahora,
    bool sinMagnetometro = false,
  }) {
    if (sinMagnetometro) {
      estado = EstadoBrujula.sinSensor;
      _rumbo = null;
      return;
    }
    if (gravedad == null || magnetico == null) return;
    final dt = _ultimaEn == null
        ? 0.0
        : ahora.difference(_ultimaEn!).inMicroseconds / 1e6;
    _ultimaEn = ahora;
    estado = ReglasRumbo.estadoCampo(magnetico);
    final brujula = ReglasRumbo.rumboBrujula(gravedad, magnetico);
    if (brujula == null) return;
    final previo = _rumbo;
    if (previo == null) {
      _rumbo = brujula;
      return;
    }
    // Un salto largo (app pausada) no se integra.
    final paso = dt > 0.5 ? 0.0 : dt;
    final integrado = giroscopio == null
        ? previo
        : previo + ReglasRumbo.giroRumbo(giroscopio, gravedad) * paso;
    final tau = ReglasRumbo.correccionBrujula.inMicroseconds / 1e6;
    final peso = giroscopio == null || paso == 0
        ? ReglasRumbo.pesoBrujulaSola
        : paso / (tau + paso);
    _rumbo = ReglasRumbo.normalizar(
      integrado + peso * ReglasRumbo.diferencia(integrado, brujula),
    );
  }
}
