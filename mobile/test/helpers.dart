import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nexa_mobile/app.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexa_mobile/core/geocoding/geocoding_service.dart';
import 'package:nexa_mobile/core/l10n/gen/app_localizations.dart';
import 'package:nexa_mobile/core/network/token_storage.dart';
import 'package:nexa_mobile/core/permisos/permisos_dispositivo.dart';
import 'package:nexa_mobile/core/providers.dart';
import 'package:nexa_mobile/core/utils/mi_posicion.dart';
import 'package:nexa_mobile/core/theme/app_theme.dart';
import 'package:nexa_mobile/core/widgets/mapa_nexa.dart';

/// Tamaños de prueba: móvil pequeño, móvil base y tablet.
const List<Size> kTamanos = [Size(360, 640), Size(390, 844), Size(800, 1280)];

void usarTamano(WidgetTester t, Size s, {double textScale = 1}) {
  t.view.physicalSize = s;
  t.view.devicePixelRatio = 1;
  t.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
    t.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

Future<void> iniciarFormatos() => initializeDateFormatting('es_CO');

/// Overrides comunes: memoria en vez de secure storage, mocks, sin mapa ni GPS.
List<Override> overridesTest({
  SecureStore? store,
  Duration splash = Duration.zero,
  GeocodingService? geocoding,
  Future<LatLng?> Function()? miPosicion,
}) => [
  secureStoreProvider.overrideWithValue(store ?? MemorySecureStore()),
  useMocksProvider.overrideWithValue(true),
  splashMinimoProvider.overrideWithValue(splash),
  geocodingProvider.overrideWithValue(geocoding ?? GeocodingFalso()),
  mapasHabilitadosProvider.overrideWithValue(false),
  ubicacionProvider.overrideWith((ref) async => kCentroPorDefecto),
  // Sin GPS real en los tests (evita el canal de la plataforma).
  miPosicionProvider.overrideWithValue(miPosicion ?? () async => null),
  // Permisos ya concedidos: las pantallas de permisos tienen sus propias pruebas.
  permisosProvider.overrideWithValue(PermisosFijos(EstadoUbicacion.siempre)),
];

/// Monta [child] dentro de MaterialApp con localización y tema de NEXA.
Widget envolver(
  Widget child, {
  List<Override> overrides = const [],
  GeocodingService? geocoding,
}) => ProviderScope(
  overrides: [
    ...overridesTest(geocoding: geocoding),
    ...overrides,
  ],
  child: MaterialApp(
    theme: AppTheme.dark,
    locale: const Locale('es', 'CO'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  ),
);

/// App completa (con router) para pruebas de navegación.
Widget appCompleta({List<Override> overrides = const []}) => ProviderScope(
  overrides: [...overridesTest(), ...overrides],
  child: const NexaApp(),
);

/// Adaptador HTTP falso: responde según `METHOD path`.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respuestas);
  final Map<String, (int, Object?)> respuestas;
  final List<RequestOptions> llamadas = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    llamadas.add(options);
    final r = respuestas['${options.method} ${options.uri.path}'];
    final headers = {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    };
    if (r == null) {
      return ResponseBody.fromString(
        jsonEncode({'error': 'no mock'}),
        404,
        headers: headers,
      );
    }
    return ResponseBody.fromString(jsonEncode(r.$2), r.$1, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

/// JWT de prueba (sin firma real).
String jwtFalso(Map<String, Object?> payload) {
  String b(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${b({'alg': 'none'})}.${b(payload)}.firma';
}

/// Geocodificación sin red: un único resultado fijo cerca de Cartagena.
class GeocodingFalso implements GeocodingService {
  final List<String> consultas = [];

  @override
  Future<List<Lugar>> buscar(String consulta, {LatLng? cerca}) async {
    consultas.add(consulta);
    if (consulta.trim().length < 3) return const [];
    return [
      const Lugar(
        nombre: 'Centro Comercial Plaza',
        detalle: 'Cartagena, Bolívar',
        punto: LatLng(10.4236, -75.5390),
      ),
    ];
  }

  @override
  Future<String?> nombreDe(LatLng punto) async => 'Calle de prueba 1-23';
}
