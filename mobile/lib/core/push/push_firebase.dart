import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' show DartPluginRegistrant;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/gen/app_localizations.dart';
import '../notificaciones/canales_notificacion.dart';
import '../network/token_storage.dart';
import 'aviso_push.dart';
import 'bandeja_avisos.dart';
import 'eventos_vistos.dart';
import 'servicio_push.dart';

/// Cuánto se ve una solicitud en la bandeja: igual a `nexa.avisos.solicitud`
/// del servidor (el push tampoco se entrega después: `ttl`). Solo es visual.
const vigenciaSolicitud = Duration(seconds: 45);

/// Recibe los push con la app en segundo plano o cerrada (isolate aparte, sin
/// Riverpod). Solo las solicitudes llegan sin notificación (solo datos): aquí
/// se arma la notificación con «Ver» / «Aceptar» o se quita si se retiró. Los
/// avisos del viaje traen su propia notificación y los muestra Android.
@pragma('vm:entry-point')
Future<void> avisoEnSegundoPlano(RemoteMessage mensaje) async {
  final aviso = AvisoPush.desdeDatos(mensaje.data);
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  if (!await EventosVistos(const FlutterSecureStore())
      .reservar('recibido:${aviso.eventoId}')) {
    return;
  }
  // Los avisos del viaje ya traen su notificación: solo van a la bandeja.
  if (!aviso.esSolicitud && aviso.tipo != TipoAviso.solicitudRetirada) {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();
      await const BandejaAvisos(FlutterSecureStore()).registrar(aviso);
    } on Object catch (e) {
      debugPrint('Bandeja de avisos: $e');
    }
    return;
  }
  try {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await mostrarAvisoSolicitud(plugin, aviso);
  } catch (e, pila) {
    // Queda en el registro (logcat) con su causa en vez de un error genérico.
    debugPrint('Aviso ${aviso.tipo.codigo} en segundo plano falló: $e\n$pila');
  }
}

/// Muestra (o quita) la notificación de una solicitud. La usan el isolate de
/// segundo plano y la app abierta.
Future<void> mostrarAvisoSolicitud(
  FlutterLocalNotificationsPlugin plugin,
  AvisoPush aviso,
) async {
  if (kIsWeb || !Platform.isAndroid) return;
  if (aviso.tipo == TipoAviso.solicitudRetirada) {
    await plugin.cancel(id: aviso.idNotificacion);
    return;
  }
  if (!aviso.esSolicitud) return;
  final t = lookupAppLocalizations(const Locale('es'));
  await plugin.show(
    id: aviso.idNotificacion,
    title: aviso.titulo,
    body: aviso.cuerpo,
    payload: jsonEncode(aviso.datos),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        IdsCanal.solicitudes,
        t.notiCanalSolicitudes,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.recommendation,
        autoCancel: true,
        timeoutAfter: vigenciaSolicitud.inMilliseconds,
        // Cuenta regresiva hasta que vence.
        when: DateTime.now().add(vigenciaSolicitud).millisecondsSinceEpoch,
        usesChronometer: true,
        chronometerCountDown: true,
        styleInformation: BigTextStyleInformation(aviso.cuerpo ?? ''),
        actions: [
          AndroidNotificationAction(
            AccionAviso.ver,
            t.pushVer,
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            AccionAviso.aceptar,
            t.pushAceptar,
            showsUserInterface: true,
          ),
        ],
      ),
    ),
  );
}

/// Lee el aviso guardado en una notificación local tocada.
AvisoPush? avisoDeRespuesta(NotificationResponse r) {
  final payload = r.payload;
  if (payload == null || payload.isEmpty) return null;
  try {
    final datos = jsonDecode(payload);
    if (datos is! Map<String, dynamic>) return null;
    return AvisoPush.desdeDatos(datos, accion: r.actionId);
  } on FormatException {
    return null;
  }
}

/// FCM + notificaciones locales. Se crea en `main` después de
/// `Firebase.initializeApp`; [tocadosLocales] son los toques de las
/// notificaciones que arma la app (las solicitudes).
class PushFirebase implements ServicioPush {
  PushFirebase({
    required FlutterLocalNotificationsPlugin plugin,
    required Stream<AvisoPush> tocadosLocales,
    FirebaseMessaging? mensajeria,
  }) : _plugin = plugin,
       _tocadosLocales = tocadosLocales,
       _fcm = mensajeria ?? FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _plugin;
  final Stream<AvisoPush> _tocadosLocales;
  final FirebaseMessaging _fcm;

  /// Registra el receptor de segundo plano. Debe llamarse antes de `runApp`.
  static Future<bool> preparar() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(avisoEnSegundoPlano);
    return true;
  }

  @override
  bool get activo => true;

  @override
  Future<String?> token() => _fcm.getToken();

  @override
  Stream<String> get tokenRenovado => _fcm.onTokenRefresh;

  @override
  Stream<AvisoPush> get recibidos =>
      FirebaseMessaging.onMessage.map((m) => AvisoPush.desdeDatos(m.data));

  @override
  Stream<AvisoPush> get tocados {
    final sistema = FirebaseMessaging.onMessageOpenedApp.map(
      (m) => AvisoPush.desdeDatos(m.data),
    );
    final salida = StreamController<AvisoPush>();
    final subs = <StreamSubscription<AvisoPush>>[];
    salida
      ..onListen = () {
        subs
          ..add(sistema.listen(salida.add))
          ..add(_tocadosLocales.listen(salida.add));
      }
      ..onCancel = () async {
        for (final s in subs) {
          await s.cancel();
        }
      };
    return salida.stream;
  }

  @override
  Future<AvisoPush?> tocadoAlAbrir() async {
    final inicial = await _fcm.getInitialMessage();
    if (inicial != null) return AvisoPush.desdeDatos(inicial.data);
    final detalles = await _plugin.getNotificationAppLaunchDetails();
    final r = detalles?.notificationResponse;
    if (detalles?.didNotificationLaunchApp != true || r == null) return null;
    return avisoDeRespuesta(r);
  }

  @override
  Future<void> quitarNotificacion(int id) => _plugin.cancel(id: id);
}
