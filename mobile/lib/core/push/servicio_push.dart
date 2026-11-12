import 'dart:async';

import 'aviso_push.dart';

/// Avisos push del teléfono (FCM). La implementación real está en
/// `push_firebase.dart`; las pruebas usan [PushEnMemoria] y, sin Firebase,
/// queda [PushInactivo] (la app funciona igual con el sondeo).
abstract class ServicioPush {
  /// false si Firebase no arrancó (sin `google-services.json`, pruebas…).
  bool get activo;

  /// Token del teléfono para el servidor (`PUT /api/dispositivos`).
  Future<String?> token();

  /// FCM rotó el token: hay que volver a registrarlo.
  Stream<String> get tokenRenovado;

  /// Avisos que llegan con la app a la vista (no se muestran en la bandeja).
  Stream<AvisoPush> get recibidos;

  /// El usuario tocó un aviso (o uno de sus botones) con la app viva.
  Stream<AvisoPush> get tocados;

  /// El aviso que abrió la app cuando estaba cerrada (una sola vez).
  Future<AvisoPush?> tocadoAlAbrir();

  /// Quita la notificación local de una solicitud (retirada o ya aceptada).
  Future<void> quitarNotificacion(int id);
}

class PushInactivo implements ServicioPush {
  const PushInactivo();

  @override
  bool get activo => false;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRenovado => const Stream.empty();

  @override
  Stream<AvisoPush> get recibidos => const Stream.empty();

  @override
  Stream<AvisoPush> get tocados => const Stream.empty();

  @override
  Future<AvisoPush?> tocadoAlAbrir() async => null;

  @override
  Future<void> quitarNotificacion(int id) async {}
}

/// Para pruebas: se le inyectan avisos y toques a mano.
class PushEnMemoria implements ServicioPush {
  PushEnMemoria({this.tokenActual = 'token-prueba', this.alAbrir});

  String? tokenActual;
  AvisoPush? alAbrir;
  final quitadas = <int>[];

  final _token = StreamController<String>.broadcast();
  final _recibidos = StreamController<AvisoPush>.broadcast();
  final _tocados = StreamController<AvisoPush>.broadcast();

  void renovarToken(String nuevo) {
    tokenActual = nuevo;
    _token.add(nuevo);
  }

  void recibir(AvisoPush a) => _recibidos.add(a);
  void tocar(AvisoPush a) => _tocados.add(a);

  @override
  bool get activo => true;

  @override
  Future<String?> token() async => tokenActual;

  @override
  Stream<String> get tokenRenovado => _token.stream;

  @override
  Stream<AvisoPush> get recibidos => _recibidos.stream;

  @override
  Stream<AvisoPush> get tocados => _tocados.stream;

  @override
  Future<AvisoPush?> tocadoAlAbrir() async {
    final a = alAbrir;
    alAbrir = null;
    return a;
  }

  @override
  Future<void> quitarNotificacion(int id) async => quitadas.add(id);
}
