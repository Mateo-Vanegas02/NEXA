// Capturas de las pantallas para comparar con el Figma del rediseño.
//
// Solo corren con NEXA_CAPTURAS=1 (paso «Capturas» de la CI): cada pantalla se
// imprime en el log como PNG en base64 entre CAPTURA-INICIO y CAPTURA-FIN.
// Así se revisa el diseño sin subir artefactos.
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/router/app_router.dart';
import 'package:nexa_mobile/features/auth/domain/auth.dart';
import 'package:nexa_mobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:nexa_mobile/features/viajes/domain/oferta_activa.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';
import 'package:nexa_mobile/features/viajes/presentation/controllers/viaje_pasajero_controller.dart';

import '../helpers.dart';

final _activas = Platform.environment['NEXA_CAPTURAS'] == '1';
const _clave = ValueKey('captura');
const _tam = Size(402, 874);

class _SesionFija extends SesionController {
  _SesionFija(this.sesion);
  final Sesion? sesion;

  @override
  SesionState build() => SesionState(
    sesion: sesion,
    inicializado: true,
    onboardingVisto: sesion != null,
  );
}

Override _sesion(Rol? rol, [String email = 'demo@nexa.co']) =>
    sesionProvider.overrideWith(
      () => _SesionFija(
        rol == null
            ? null
            : Sesion(
                token: 't',
                rol: rol,
                email: email,
                userId: 'u-${rol.name}',
              ),
      ),
    );

class _ViajeFijo extends ViajePasajeroController {
  _ViajeFijo(this.servicio);
  final Servicio servicio;

  @override
  Future<Servicio?> build() async => servicio;
}

Servicio _servicio(EstadoServicio estado, {DateTime? llegada}) => Servicio(
  id: 'v1',
  estado: estado,
  origen: 'Bocagrande, Cra. 3 #6-120',
  destino: 'Centro Histórico',
  distanciaKM: 3.4,
  ubicacionOrigen: const Coordenada(latitud: 10.40, longitud: -75.55),
  ubicacionDestino: const Coordenada(latitud: 10.42, longitud: -75.548),
  tarifa: 6900,
  metodoPago: 'efectivo',
  fechaLlegada: llegada,
  conductor: const Participante(
    id: 'c1',
    nombre: 'Carlos Martínez',
    telefono: '3001234567',
    calificacion: 4.9,
    viajes: 1284,
    vehiculo: 'Yamaha NMAX · gris',
    placa: 'KZT 38F',
  ),
);

class _OfertaFija extends OfertaActivaNotifier {
  _OfertaFija(this.ola);
  final int ola;

  @override
  OfertaActiva? build() => OfertaActiva(
    servicioId: 'v1',
    topeExtra: 5000,
    despacho: AvisoDespacho(
      ola: ola,
      totalOlas: 4,
      conductoresAvisados: ola == 4 ? 12 : 6,
      radioKm: const [1.5, 2.5, 4.0, 6.0][ola - 1],
    ),
  );
}

Override _ola(int ola) =>
    ofertaActivaProvider.overrideWith(() => _OfertaFija(ola));

Override _viaje(Servicio s) =>
    viajePasajeroProvider.overrideWith(() => _ViajeFijo(s));

Future<void> _fuentes() async {
  for (final peso in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final f = FontLoader('Montserrat')
      ..addFont(rootBundle.load('assets/fonts/Montserrat-$peso.ttf'));
    await f.load();
  }
  final raiz = Platform.environment['FLUTTER_ROOT'] ?? '';
  final iconos = File(
    '$raiz/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (iconos.existsSync()) {
    final f = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(iconos.readAsBytesSync())));
    await f.load();
  }
}

Future<void> _avanzar(WidgetTester t, [int veces = 8]) async {
  for (var i = 0; i < veces; i++) {
    await t.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _capturar(WidgetTester t, String nombre) async {
  final limite = t.renderObject<RenderRepaintBoundary>(find.byKey(_clave));
  print('captura $nombre: renderizando');
  final bytes = await t.runAsync(() async {
    final img = await limite.toImage().timeout(const Duration(seconds: 30));
    final d = await img
        .toByteData(format: ui.ImageByteFormat.png)
        .timeout(const Duration(seconds: 30));
    return d!.buffer.asUint8List();
  });
  if (bytes == null) {
    print('captura $nombre: sin imagen');
    return;
  }
  // En trozos: el log de GitHub corta las líneas muy largas.
  final b64 = base64Encode(bytes);
  const trozo = 30000;
  final partes = (b64.length / trozo).ceil();
  for (var i = 0; i < partes; i++) {
    final fin = (i + 1) * trozo > b64.length ? b64.length : (i + 1) * trozo;
    print('CAPTURA $nombre $i/$partes ${b64.substring(i * trozo, fin)}');
  }
}

/// Abre la app en [ruta] con la sesión de [rol] y la captura.
Future<void> _pantalla(
  WidgetTester t,
  String nombre,
  String ruta, {
  Rol? rol,
  String email = 'demo@nexa.co',
  List<Override> extra = const [],
  Object? datos,
}) async {
  usarTamano(t, _tam);
  await t.pumpWidget(
    RepaintBoundary(
      key: _clave,
      child: appCompleta(overrides: [_sesion(rol, email), ...extra]),
    ),
  );
  await _avanzar(t, 4);
  final ctx = t.element(find.byType(Navigator).first);
  ProviderScope.containerOf(ctx).read(routerProvider).go(ruta, extra: datos);
  await _avanzar(t);
  t.takeException();
  await _capturar(t, nombre);
}

void main() {
  setUpAll(() async {
    await iniciarFormatos();
    await _fuentes();
  });

  final casos = <(String, String, Rol?, String, List<Override>)>[
    ('A02', '/onboarding', null, '', []),
    ('A03', '/login', null, '', []),
    ('A04', '/registro', null, '', []),
    ('P01', '/p/inicio', Rol.pasajero, '', []),
    ('P03', '/p/pedir', Rol.pasajero, '', []),
    (
      'P04',
      '/p/viaje',
      Rol.pasajero,
      '',
      [_viaje(_servicio(EstadoServicio.solicitado)), _ola(2)],
    ),
    (
      'E03',
      '/p/viaje',
      Rol.pasajero,
      '',
      [_viaje(_servicio(EstadoServicio.solicitado)), _ola(4)],
    ),
    (
      'P05',
      '/p/viaje',
      Rol.pasajero,
      '',
      [_viaje(_servicio(EstadoServicio.aceptado))],
    ),
    (
      'P06',
      '/p/viaje',
      Rol.pasajero,
      '',
      [_viaje(_servicio(EstadoServicio.aceptado, llegada: DateTime.now()))],
    ),
    (
      'P07',
      '/p/viaje',
      Rol.pasajero,
      '',
      [_viaje(_servicio(EstadoServicio.enCurso, llegada: DateTime.now()))],
    ),
    (
      'P08',
      '/p/calificar',
      Rol.pasajero,
      '',
      [_viaje(_servicio(EstadoServicio.finalizado, llegada: DateTime.now()))],
    ),
    ('P10', '/p/viajes', Rol.pasajero, '', []),
    ('P11', '/p/niveles', Rol.pasajero, '', []),
    ('P12', '/p/perfil', Rol.pasajero, '', []),
    ('C01', '/c/inicio', Rol.conductor, 'conductor@nexa.co', []),
    ('C08', '/c/ganancias', Rol.conductor, 'conductor@nexa.co', []),
    ('C09', '/c/niveles', Rol.conductor, 'conductor@nexa.co', []),
    ('C10', '/c/perfil', Rol.conductor, 'conductor@nexa.co', []),
    ('D01', '/a/satisfaccion', Rol.admin, 'admin@nexa.co', []),
    ('D02', '/a/satisfaccion/factores', Rol.admin, 'admin@nexa.co', []),
    ('D03', '/a/satisfaccion/riesgo', Rol.admin, 'admin@nexa.co', []),
    ('D04', '/a/satisfaccion/modelo', Rol.admin, 'admin@nexa.co', []),
    ('N08', '/notificaciones', Rol.pasajero, '', []),
    ('N01', '/permisos/notificaciones', Rol.pasajero, '', []),
    ('N02', '/permisos/ubicacion', Rol.pasajero, '', []),
    ('E01', '/permisos/sin-ubicacion', Rol.pasajero, '', []),
    (
      'N03',
      '/c/permisos/segundo-plano',
      Rol.conductor,
      'conductor@nexa.co',
      [],
    ),
    ('N04', '/c/permisos/bateria', Rol.conductor, 'conductor@nexa.co', []),
    ('C07', '/c/calificar', Rol.conductor, 'conductor@nexa.co', []),
  ];

  for (final (nombre, ruta, rol, email, extra) in casos) {
    testWidgets(
      'captura $nombre',
      (t) => _pantalla(
        t,
        nombre,
        ruta,
        rol: rol,
        email: email.isEmpty ? 'demo@nexa.co' : email,
        extra: extra,
        datos: nombre == 'C07'
            ? _servicio(EstadoServicio.finalizado).copyWith(
                pasajero: const Participante(id: 'p1', nombre: 'Laura Gómez'),
              )
            : null,
      ),
      skip: !_activas,
    );
  }
}
