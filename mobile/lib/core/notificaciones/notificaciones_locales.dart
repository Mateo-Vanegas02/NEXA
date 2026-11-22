import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'canales_notificacion.dart';

/// Notificaciones que muestra el propio teléfono: canales, permiso y la
/// notificación fija del viaje. Las de las solicitudes push las arma
/// `push_firebase.dart` con el mismo plugin y los mismos canales.
abstract class NotificacionesLocales {
  /// false donde el teléfono no puede mostrarlas (pruebas, otras plataformas):
  /// entonces no se ofrece la pantalla del permiso.
  bool get disponible;

  /// Crea los canales (Android 8+). Se puede llamar varias veces: Android no
  /// duplica un canal con el mismo id.
  Future<void> inicializar(List<CanalNotificacion> canales);

  /// Si la app puede mostrar notificaciones (Android 13+ pide permiso).
  Future<bool> permitidas();

  /// Muestra el cuadro del sistema para pedir el permiso. Devuelve si quedó
  /// concedido. No se llama al abrir la app: lo pide la pantalla N01.
  Future<bool> pedirPermiso();

  /// Cambia el texto de la notificación fija del GPS en segundo plano con los
  /// datos del viaje (p. ej. «Recoge a Laura · 3 min · 650 m») y un botón
  /// «Abrir». Solo mientras el servicio de ubicación está activo. Con
  /// [avance] (0–100) muestra la barra del viaje, también en la pantalla de
  /// bloqueo (sin datos sensibles: fase, minutos y distancia).
  Future<void> mostrarViaje({
    required String titulo,
    required String texto,
    required String canal,
    required String abrir,
    int? avance,
  });

  /// Quita la notificación del viaje (al apagarse el GPS en segundo plano).
  Future<void> cerrarViaje();
}

/// La notificación fija del servicio de ubicación es la de geolocator
/// (`GeolocatorLocationService`: id 75415, canal `geolocator_channel_01`).
/// Publicar con ese mismo id y canal reemplaza su texto sin crear otra
/// notificación ni reiniciar el servicio. Si geolocator cambia esos valores,
/// solo se pierde el texto del viaje (queda «Viaje en curso»).
abstract final class NotificacionFijaGps {
  static const id = 75415;
  static const canal = 'geolocator_channel_01';
}

/// Implementación con `flutter_local_notifications` (solo Android por ahora).
class NotificacionesAndroid implements NotificacionesLocales {
  NotificacionesAndroid({FlutterLocalNotificationsPlugin? plugin, this.alTocar})
    : plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// El plugin también lo usan los avisos push (solicitudes).
  final FlutterLocalNotificationsPlugin plugin;

  /// Toque en una notificación de la app (o en uno de sus botones) con la app
  /// viva. Si la notificación abrió la app, lo lee `PushFirebase.tocadoAlAbrir`.
  final void Function(NotificationResponse)? alTocar;

  FlutterLocalNotificationsPlugin get _plugin => plugin;

  @override
  bool get disponible => !kIsWeb && Platform.isAndroid;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> inicializar(List<CanalNotificacion> canales) async {
    if (kIsWeb || !Platform.isAndroid) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: alTocar,
    );
    final android = _android;
    if (android == null) return;
    for (final canal in canales) {
      await android.createNotificationChannel(canalAndroid(canal));
    }
  }

  @override
  Future<bool> permitidas() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    return await _android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<bool> pedirPermiso() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    return await _android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> mostrarViaje({
    required String titulo,
    required String texto,
    required String canal,
    required String abrir,
    int? avance,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;
    await _plugin.show(
      id: NotificacionFijaGps.id,
      title: titulo,
      body: texto,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          NotificacionFijaGps.canal,
          canal,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          silent: true,
          showWhen: false,
          category: AndroidNotificationCategory.navigation,
          visibility: NotificationVisibility.public,
          showProgress: avance != null,
          maxProgress: 100,
          progress: avance ?? 0,
          actions: [
            AndroidNotificationAction(
              'abrir',
              abrir,
              showsUserInterface: true,
              cancelNotification: false,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Future<void> cerrarViaje() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await _plugin.cancel(id: NotificacionFijaGps.id);
  }
}

/// Traduce un canal de NEXA al canal de Android.
@visibleForTesting
AndroidNotificationChannel canalAndroid(CanalNotificacion canal) =>
    AndroidNotificationChannel(
      canal.id,
      canal.nombre,
      description: canal.descripcion,
      importance: canal.prioridad == Prioridad.alta
          ? Importance.high
          : Importance.defaultImportance,
    );

/// Sustituto para pruebas y para plataformas sin notificaciones.
class NotificacionesInactivas implements NotificacionesLocales {
  const NotificacionesInactivas();

  @override
  bool get disponible => false;

  @override
  Future<void> inicializar(List<CanalNotificacion> canales) async {}

  @override
  Future<bool> permitidas() async => false;

  @override
  Future<bool> pedirPermiso() async => false;

  @override
  Future<void> mostrarViaje({
    required String titulo,
    required String texto,
    required String canal,
    required String abrir,
    int? avance,
  }) async {}

  @override
  Future<void> cerrarViaje() async {}
}
