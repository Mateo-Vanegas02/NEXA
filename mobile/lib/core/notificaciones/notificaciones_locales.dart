import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'canales_notificacion.dart';

/// Notificaciones que muestra el propio teléfono (sin servidor). Por ahora
/// solo prepara los canales y el permiso; los avisos push llegan en un paso
/// posterior y se muestran por estos mismos canales.
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
}

/// Implementación con `flutter_local_notifications` (solo Android por ahora).
class NotificacionesAndroid implements NotificacionesLocales {
  NotificacionesAndroid([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

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
}
