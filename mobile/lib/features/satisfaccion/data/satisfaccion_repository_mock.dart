import '../../../core/errors/app_exception.dart';
import '../domain/satisfaccion.dart';
import '../domain/satisfaccion_repository.dart';

/// Respuestas del contrato v0.1 con las mismas cifras del diseño de Figma.
/// Pasan por los mismos `fromJson` que la API real, así que también prueban
/// los parsers.
abstract final class FixturesSatisfaccion {
  static Json resumen({DateTime? desde, DateTime? hasta}) => {
    'desde': '2026-10-09',
    'hasta': '2026-11-08',
    'serie': serie(
      desde ?? DateTime(2026, 10, 9),
      hasta ?? DateTime(2026, 11, 8),
    ),
    'modo': 'real',
    'pasajero': {
      'satisfechosPct': 86.0,
      'variacionPts': 3.0,
      'tasaRespuestaPct': 62.0,
      'calificaciones': 112,
    },
    'conductor': {
      'satisfechosPct': 79.0,
      'variacionPts': -2.0,
      'tasaRespuestaPct': 41.0,
      'calificaciones': 34,
    },
    'tendencia': [
      for (final (i, p, c) in const [
        (38, 82.0, 80.0),
        (39, 83.0, 77.0),
        (40, 81.5, 81.0),
        (41, 84.0, 78.0),
        (42, 85.0, 76.5),
        (43, 84.5, 79.0),
        (44, 86.0, 77.0),
        (45, 85.0, 75.5),
      ])
        {'semana': '2026-W$i', 'pasajeroPct': p, 'conductorPct': c},
    ],
    'riesgoTotal': 7,
    'factorPrincipal': {
      'lado': 'pasajero',
      'etiqueta': 'Espera hasta que un conductor acepta',
    },
  };

  /// Serie del período como la arma la Lambda: por día hasta 14 días, por
  /// semana hasta 26 y por mes después. El tercer tramo no tiene notas y el
  /// segundo tiene pocas, para que se vean el hueco y el punto débil.
  static Json serie(DateTime desde, DateTime hasta) {
    final dias = hasta.difference(desde).inDays + 1;
    final agrupacion = dias <= 14
        ? 'dia'
        : dias <= 182
        ? 'semana'
        : 'mes';
    String dos(int n) => n.toString().padLeft(2, '0');
    String dia(DateTime d) => '${d.year}-${dos(d.month)}-${dos(d.day)}';
    final puntos = <Json>[];
    var d = DateTime(desde.year, desde.month, desde.day);
    var i = 0;
    while (!d.isAfter(hasta)) {
      final (clave, fin) = switch (agrupacion) {
        'dia' => (dia(d), d),
        'semana' => (
          '${d.year}-W${dos(_semanaIso(d))}',
          d.add(Duration(days: 7 - d.weekday)),
        ),
        _ => (
          '${d.year}-${dos(d.month)}',
          DateTime(d.year, d.month + 1, 0),
        ),
      };
      final hastaTramo = fin.isAfter(hasta) ? hasta : fin;
      final vacio = i == 2;
      final notas = i == 1 ? 3 : 40 + 7 * i;
      puntos.add({
        'clave': clave,
        'desde': dia(d),
        'hasta': dia(hastaTramo),
        'pasajeroPct': vacio ? null : 80.0 + (i * 7) % 9,
        'pasajeroNotas': vacio ? 0 : notas,
        'conductorPct': vacio ? null : 74.0 + (i * 5) % 8,
        'conductorNotas': vacio ? 0 : (notas / 3).round(),
      });
      d = hastaTramo.add(const Duration(days: 1));
      i++;
    }
    return {'agrupacion': agrupacion, 'minimoNotas': 10, 'puntos': puntos};
  }

  static int _semanaIso(DateTime d) {
    final jueves = d.add(Duration(days: 4 - d.weekday));
    final enero1 = DateTime(jueves.year);
    return 1 + jueves.difference(enero1).inDays ~/ 7;
  }

  static Json _curva(
    String variable,
    String etiqueta,
    List<(String, double, int)> tramos,
    String hallazgo,
  ) => {
    'variable': variable,
    'etiqueta': etiqueta,
    'tramos': [
      for (final (e, p, v) in tramos)
        {'etiqueta': e, 'satisfechosPct': p, 'viajes': v},
    ],
    'hallazgo': hallazgo,
  };

  static Json factores(Lado lado) => lado == Lado.pasajero
      ? {
          'lado': 'pasajero',
          'modo': 'real',
          'version': 3,
          'importancia': [
            for (final (v, e, p) in const [
              (
                'espera_aceptacion_min',
                'Espera hasta que un conductor acepta',
                22.0,
              ),
              ('retraso_min', 'Retraso frente a lo estimado', 18.0),
              ('precio_km', 'Precio por kilómetro', 12.0),
              ('finalizado_antes', 'Finalizado antes del destino', 9.0),
              ('espera_conductor_min', 'Espera del conductor en el punto', 7.0),
            ])
              {'variable': v, 'etiqueta': e, 'pesoPct': p},
          ],
          'otrosFactores': {'cantidad': 20, 'pesoMaximoPct': 5.0},
          'curvas': [
            _curva(
              'espera_aceptacion_min',
              'Espera a aceptar',
              const [
                ('0–1 min', 93, 210),
                ('1–3 min', 88, 176),
                ('3–6 min', 77, 51),
                ('6+ min', 61, 41),
              ],
              'Si la espera pasa de 3 minutos, la satisfacción cae 16 puntos. 41 de 478 viajes están en ese tramo.',
            ),
            _curva(
              'retraso_min',
              'Retraso',
              const [
                ('A tiempo', 92, 244),
                ('1–5 min', 85, 139),
                ('5–10 min', 74, 63),
                ('10+ min', 59, 32),
              ],
              'Con más de 5 minutos de retraso la satisfacción baja 18 puntos.',
            ),
            _curva(
              'precio_km',
              r'$/km',
              const [
                (r'< $2.000', 90, 151),
                (r'$2.000–2.500', 87, 182),
                (r'$2.500–3.000', 81, 98),
                (r'> $3.000', 72, 47),
              ],
              r'Los viajes cortos, con más de $3.000 por km, son los peor calificados.',
            ),
          ],
        }
      : {
          'lado': 'conductor',
          'modo': 'real',
          'version': 3,
          'importancia': [
            for (final (v, e, p) in const [
              ('espera_conductor_min', 'Espera al pasajero en el punto', 24.0),
              ('distancia_recogida_km', 'Distancia hasta la recogida', 17.0),
              ('ganancia_minuto', 'Ganancia por minuto', 14.0),
              ('deuda_cobrada', 'Deuda cobrada con el viaje', 8.0),
              ('finalizado_antes', 'Finalizado antes del destino', 7.0),
            ])
              {'variable': v, 'etiqueta': e, 'pesoPct': p},
          ],
          'otrosFactores': {'cantidad': 20, 'pesoMaximoPct': 5.0},
          'curvas': [
            _curva(
              'espera_conductor_min',
              'Espera en el punto',
              const [
                ('0–2 min', 90, 198),
                ('2–5 min', 84, 160),
                ('5–8 min', 71, 78),
                ('8+ min', 58, 42),
              ],
              'Cuando el pasajero tarda más de 5 minutos, la satisfacción del conductor cae 13 puntos.',
            ),
            _curva(
              'distancia_recogida_km',
              'Recogida',
              const [
                ('< 1 km', 88, 190),
                ('1–2 km', 85, 151),
                ('2–3 km', 79, 89),
                ('3+ km', 66, 48),
              ],
              'Las recogidas a más de 3 km son las peor calificadas por los conductores.',
            ),
          ],
        };

  static Json riesgo(DateTime ahora) {
    String hace(int dias, int h, int m) => DateTime(
      ahora.year,
      ahora.month,
      ahora.day - dias,
      h,
      m,
    ).toIso8601String();
    Json viaje(
      String id,
      String fecha,
      String o,
      String d,
      double km,
      String lado,
      double p,
      List<(String, String)> motivos,
    ) => {
      'id': id,
      'fecha': fecha,
      'origen': o,
      'destino': d,
      'distanciaKm': km,
      'lado': lado,
      'probabilidadNo': p,
      'motivos': [
        for (final (t, s) in motivos) {'texto': t, 'severidad': s},
      ],
    };
    return {
      'umbral': 0.45,
      'modo': 'real',
      'total': 7,
      'viajes': [
        viaje(
          'A7F3',
          hace(0, 8, 12),
          'Bocagrande',
          'Manga',
          4.2,
          'pasajero',
          0.71,
          const [
            ('Esperó 7 min a que aceptaran', 'alta'),
            ('Llegó 9 min tarde', 'media'),
          ],
        ),
        viaje(
          'C219',
          hace(1, 19, 40),
          'El Bosque',
          'Centro',
          5.0,
          'conductor',
          0.64,
          const [
            ('Esperó 8 min en el punto', 'alta'),
            ('Recogida a 3,1 km', 'media'),
          ],
        ),
        viaje(
          '9B04',
          hace(1, 13, 5),
          'Crespo',
          'Pie de la Popa',
          3.4,
          'pasajero',
          0.52,
          const [('Finalizado antes del destino', 'media')],
        ),
        viaje(
          '5E61',
          hace(2, 17, 30),
          'Manga',
          'Bocagrande',
          3.8,
          'pasajero',
          0.48,
          const [(r'$/km alto: $2.900', 'media')],
        ),
        viaje(
          'D0A8',
          hace(3, 7, 50),
          'Manga',
          'Getsemaní',
          2.1,
          'pasajero',
          0.47,
          const [('Esperó 5 min a que aceptaran', 'media')],
        ),
        viaje(
          '71CE',
          hace(4, 21, 15),
          'Crespo',
          'Bocagrande',
          6.3,
          'conductor',
          0.46,
          const [('Recogida a 2,8 km', 'media')],
        ),
        viaje(
          'B3F9',
          hace(5, 12, 0),
          'Centro',
          'El Bosque',
          4.9,
          'pasajero',
          0.45,
          const [('Llegó 6 min tarde', 'media')],
        ),
      ],
    };
  }

  static Json modelo({bool datosSuficientes = true, int? version = 3}) => {
    'version': version,
    'entrenadoEn': version == null ? null : '2026-11-08T02:14:00-05:00',
    'viajes': version == null ? 0 : 478,
    'variables': 25,
    'modo': 'real',
    'metricas': {
      'pasajero': {'redPrAuc': 0.40, 'regresionPrAuc': 0.43, 'supera': false},
      'conductor': {'redPrAuc': 0.32, 'regresionPrAuc': 0.41, 'supera': false},
    },
    'datos': {
      'pasajero': datosSuficientes
          ? {'calificaciones': 412, 'no': 48}
          : {'calificaciones': 112, 'no': 9},
      'conductor': datosSuficientes
          ? {'calificaciones': 336, 'no': 41}
          : {'calificaciones': 34, 'no': 3},
      'minimos': {'calificaciones': 300, 'no': 30},
      'suficientes': datosSuficientes,
    },
    'programacion': {
      'activa': true,
      'frecuencia': 'semanal',
      'dias': ['DOM'],
      'hora': '02:00',
      'cadaHoras': null,
      'soloConDatosNuevos': true,
      'minimoViajesNuevos': 20,
      'publicarSoloSiMejora': true,
      'proxima': '2026-11-15T02:00:00-05:00',
    },
    'entrenamientoActivo': null,
    'historial': version == null
        ? <Json>[]
        : [
            {
              'id': 'e-20261108-0214',
              'fecha': '2026-11-08T02:14:00-05:00',
              'origen': 'programado',
              'version': 3,
              'estado': 'PUBLICADO',
              'modo': 'real',
            },
            {
              'id': 'e-20261107-2130',
              'fecha': '2026-11-07T21:30:00-05:00',
              'origen': 'manual',
              'version': 2,
              'estado': 'PUBLICADO',
              'modo': 'real',
            },
            {
              'id': 'e-20261107-1802',
              'fecha': '2026-11-07T18:02:00-05:00',
              'origen': 'manual',
              'version': null,
              'estado': 'DATOS_INSUFICIENTES',
              'modo': 'real',
            },
          ],
  };
}

/// Repositorio simulado (`USE_MOCKS=true`). El entrenamiento avanza un paso
/// cada vez que se consulta, para ver la pantalla "Entrenando" sin servidor.
class MockSatisfaccionRepository implements SatisfaccionRepository {
  MockSatisfaccionRepository({
    DateTime Function()? reloj,
    this.retardo = const Duration(milliseconds: 250),
  }) : _reloj = reloj ?? DateTime.now;

  final DateTime Function() _reloj;
  final Duration retardo;

  ModeloInfo _modelo = ModeloInfo.fromJson(FixturesSatisfaccion.modelo());
  String? _activoId;
  int _avance = 0;
  bool _cancelado = false;

  Future<void> _espera() => Future<void>.delayed(retardo);

  @override
  Future<Resumen> resumen({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    await _espera();
    return Resumen.fromJson(
      FixturesSatisfaccion.resumen(desde: desde, hasta: hasta),
    );
  }

  @override
  Future<Factores> factores(Lado lado) async {
    await _espera();
    return Factores.fromJson(FixturesSatisfaccion.factores(lado));
  }

  @override
  Future<Riesgo> riesgo() async {
    await _espera();
    return Riesgo.fromJson(FixturesSatisfaccion.riesgo(_reloj()));
  }

  @override
  Future<ModeloInfo> modelo() async {
    await _espera();
    return _modelo;
  }

  @override
  Future<String> entrenar() async {
    await _espera();
    if (_activoId != null) {
      throw const AppException(
        ErrorKind.validacion,
        'Ya hay un entrenamiento en curso.',
        statusCode: 409,
      );
    }
    if (!(await modelo()).datos.suficientes) {
      throw const AppException(
        ErrorKind.validacion,
        'Aún no hay datos suficientes para entrenar.',
        statusCode: 422,
      );
    }
    _avance = 0;
    _cancelado = false;
    return _activoId = 'e-mock-${_reloj().millisecondsSinceEpoch}';
  }

  /// Secuencia simulada: exportar → entrenar (4 consultas) → comparar → publicar.
  static const _secuencia = [
    (EstadoEntrenamiento.exportando, 5, 0),
    (EstadoEntrenamiento.entrenando, 24, 12),
    (EstadoEntrenamiento.entrenando, 44, 22),
    (EstadoEntrenamiento.entrenando, 62, 31),
    (EstadoEntrenamiento.entrenando, 86, 43),
    (EstadoEntrenamiento.comparando, 94, 50),
    (EstadoEntrenamiento.publicando, 98, 50),
    (EstadoEntrenamiento.publicado, 100, 50),
  ];

  @override
  Future<Entrenamiento> entrenamiento(String id) async {
    await _espera();
    if (_cancelado) return _estado(id, EstadoEntrenamiento.cancelado, 0, null);
    final i = _avance.clamp(0, _secuencia.length - 1);
    _avance++;
    final (estado, pct, epoca) = _secuencia[i];
    if (estado == EstadoEntrenamiento.publicado && _activoId == id) {
      _publicar(id);
    }
    return _estado(id, estado, pct, epoca);
  }

  Entrenamiento _estado(
    String id,
    EstadoEntrenamiento estado,
    int pct,
    int? epoca,
  ) {
    String paso(int desde) {
      final orden = [
        EstadoEntrenamiento.exportando,
        EstadoEntrenamiento.entrenando,
        EstadoEntrenamiento.comparando,
        EstadoEntrenamiento.publicando,
      ];
      final actual = estado.esFinal ? orden.length : orden.indexOf(estado);
      if (estado == EstadoEntrenamiento.cancelado) return 'pendiente';
      if (actual > desde) return 'hecho';
      return actual == desde ? 'en_curso' : 'pendiente';
    }

    return Entrenamiento.fromJson({
      'id': id,
      'estado': estado.json,
      'progresoPct': pct,
      'epoca': epoca,
      'epocas': 50,
      'pasos': {
        'exportar': paso(0),
        'entrenar': paso(1),
        'comparar': paso(2),
        'publicar': paso(3),
      },
      'detalleExportar': '512 viajes completos · 34 descartados',
    });
  }

  void _publicar(String id) {
    _activoId = null;
    final v = (_modelo.version ?? 0) + 1;
    final j = FixturesSatisfaccion.modelo(version: v);
    final ahora = _reloj().toIso8601String();
    j['entrenadoEn'] = ahora;
    j['historial'] = [
      {
        'id': id,
        'fecha': ahora,
        'origen': 'manual',
        'version': v,
        'estado': 'PUBLICADO',
        'modo': 'real',
      },
      ...(j['historial'] as List<Object?>),
    ];
    _modelo = ModeloInfo.fromJson(j).conProgramacion(_modelo.programacion);
  }

  @override
  Future<void> cancelarEntrenamiento(String id) async {
    await _espera();
    if (_activoId == id) {
      _activoId = null;
      _cancelado = true;
    }
  }

  @override
  Future<Programacion> guardarProgramacion(Programacion p) async {
    await _espera();
    if (!p.esValida) {
      throw const AppException(
        ErrorKind.validacion,
        'Revisa la frecuencia, los días o las horas.',
        statusCode: 400,
      );
    }
    final guardada = Programacion.fromJson({
      ...p.toJson(),
      'proxima': p.activa ? '2026-11-15T02:00:00-05:00' : null,
    });
    _modelo = _modelo.conProgramacion(guardada);
    return guardada;
  }
}
