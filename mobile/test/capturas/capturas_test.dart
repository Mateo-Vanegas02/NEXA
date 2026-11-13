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
            : Sesion(token: 't', rol: rol, email: email, userId: 'u-${rol.name}'),
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
  final bytes = await t.runAsync(() async {
    final img = await limite.toImage(pixelRatio: 1.5);
    final d = await img.toByteData(format: ui.ImageByteFormat.png);
    return d!.buffer.asUint8List();
  });
  print('CAPTURA-INICIO $nombre ${base64Encode(bytes!)} CAPTURA-FIN');
}

/// Abre la app en [ruta] con la sesión de [rol] y la captura.
Future<void> _pantalla(
  WidgetTester t,
  String nombre,
  String ruta, {
  Rol? rol,
  String email = 'demo@nexa.co',
  List<Override> extra = const [],
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
  ProviderScope.containerOf(ctx).read(routerProvider).go(ruta);
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
    ('P04', '/p/viaje', Rol.pasajero, '', [
      _viaje(_servicio(EstadoServicio.solicitado)),
    ]),
    ('P05', '/p/viaje', Rol.pasajero, '', [
      _viaje(_servicio(EstadoServicio.aceptado)),
    ]),
    ('P06', '/p/viaje', Rol.pasajero, '', [
      _viaje(_servicio(EstadoServicio.aceptado, llegada: DateTime.now())),
    ]),
    ('P07', '/p/viaje', Rol.pasajero, '', [
      _viaje(_servicio(EstadoServicio.enCurso, llegada: DateTime.now())),
    ]),
    ('P08', '/p/calificar', Rol.pasajero, '', [
      _viaje(_servicio(EstadoServicio.finalizado, llegada: DateTime.now())),
    ]),
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
      ),
      skip: !_activas,
    );
  }
}
