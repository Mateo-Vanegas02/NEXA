import '../../features/auth/domain/auth.dart';

/// Eventos que manda el servidor por push (`docs/AVISOS_PUSH.md` en `main`).
enum TipoAviso {
  solicitudNueva('SOLICITUD_NUEVA'),
  solicitudExtra('SOLICITUD_EXTRA'),
  solicitudRetirada('SOLICITUD_RETIRADA'),
  viajeAceptado('VIAJE_ACEPTADO'),
  conductorLlego('CONDUCTOR_LLEGO'),
  viajeFinalizado('VIAJE_FINALIZADO'),
  viajeCancelado('VIAJE_CANCELADO'),
  sinConductores('SIN_CONDUCTORES'),
  solicitudVencida('SOLICITUD_VENCIDA'),
  otro('');

  const TipoAviso(this.codigo);
  final String codigo;

  static TipoAviso de(String? codigo) => values.firstWhere(
    (t) => t.codigo == codigo && t != otro,
    orElse: () => otro,
  );
}

/// Botones de la notificación de una solicitud.
abstract final class AccionAviso {
  static const ver = 'ver';
  static const aceptar = 'aceptar';
}

/// Un aviso push ya leído. Solo trae ids y el texto que armó el servidor para
/// este usuario; el detalle se pide a la API.
class AvisoPush {
  const AvisoPush({
    required this.tipo,
    required this.eventoId,
    this.servicioId,
    this.titulo,
    this.cuerpo,
    this.accion,
  });

  /// Lee los `data` de FCM (o el payload de una notificación local).
  factory AvisoPush.desdeDatos(Map<String, dynamic> datos, {String? accion}) {
    String? texto(String k) {
      final v = datos[k];
      return v == null || '$v'.isEmpty ? null : '$v';
    }

    final tipo = TipoAviso.de(texto('tipo'));
    return AvisoPush(
      tipo: tipo,
      eventoId: texto('eventoId') ?? '${tipo.codigo}:${texto('servicioId')}',
      servicioId: texto('servicioId'),
      titulo: texto('titulo'),
      cuerpo: texto('cuerpo'),
      accion: accion,
    );
  }

  final TipoAviso tipo;
  final String eventoId;
  final String? servicioId;
  final String? titulo;
  final String? cuerpo;

  /// Botón tocado en la notificación ([AccionAviso]); null si se tocó el aviso.
  final String? accion;

  bool get esSolicitud =>
      tipo == TipoAviso.solicitudNueva || tipo == TipoAviso.solicitudExtra;

  /// Para guardar en la notificación local y leerlo al tocarla.
  Map<String, String> get datos => {
    'tipo': tipo.codigo,
    'eventoId': eventoId,
    'servicioId': ?servicioId,
    'titulo': ?titulo,
    'cuerpo': ?cuerpo,
  };

  /// Id estable de la notificación de un viaje: el aviso nuevo de una misma
  /// solicitud reemplaza al anterior y el retiro la quita.
  int get idNotificacion => idPara(servicioId ?? eventoId);

  /// FNV-1a de 31 bits (igual en cualquier isolate y en cada arranque).
  static int idPara(String texto) {
    var h = 0x811c9dc5;
    for (final c in texto.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0x7fffffff;
    }
    // Lejos del id de la notificación fija del GPS (75415).
    return h == 75415 ? h + 1 : h;
  }

  AvisoPush conAccion(String? accion) => AvisoPush(
    tipo: tipo,
    eventoId: eventoId,
    servicioId: servicioId,
    titulo: titulo,
    cuerpo: cuerpo,
    accion: accion,
  );

  /// Pantalla que se abre al tocar el aviso.
  String rutaAlTocar(Rol rol) => switch (rol) {
    Rol.conductor => '/c/inicio',
    Rol.admin => '/a/satisfaccion',
    Rol.pasajero => switch (tipo) {
      TipoAviso.viajeAceptado ||
      TipoAviso.conductorLlego ||
      TipoAviso.viajeFinalizado ||
      TipoAviso.sinConductores => '/p/viaje',
      _ => '/p/inicio',
    },
  };

  /// Un aviso viejo no vuelve a abrir un viaje distinto o ya cerrado.
  String rutaConViajeVigente(Rol rol, String? viajeVigenteId) {
    final ruta = rutaAlTocar(rol);
    if (rol == Rol.pasajero &&
        ruta == '/p/viaje' &&
        (viajeVigenteId == null || viajeVigenteId != servicioId)) {
      return '/p/inicio';
    }
    return ruta;
  }
}
