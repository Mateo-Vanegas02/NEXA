import 'dart:convert';

import '../network/token_storage.dart';
import 'aviso_push.dart';

/// Un aviso guardado en la bandeja del teléfono (pantalla N08).
class AvisoGuardado {
  const AvisoGuardado({
    required this.eventoId,
    required this.tipo,
    required this.en,
    this.titulo,
    this.cuerpo,
    this.leido = false,
  });

  factory AvisoGuardado.desdeJson(Map<String, dynamic> j) => AvisoGuardado(
    eventoId: j['e'] as String? ?? '',
    tipo: TipoAviso.de(j['t'] as String?),
    en: DateTime.fromMillisecondsSinceEpoch((j['en'] as num?)?.toInt() ?? 0),
    titulo: j['ti'] as String?,
    cuerpo: j['c'] as String?,
    leido: j['l'] as bool? ?? false,
  );

  final String eventoId;
  final TipoAviso tipo;
  final DateTime en;
  final String? titulo;
  final String? cuerpo;
  final bool leido;

  Map<String, dynamic> aJson() => {
    'e': eventoId,
    't': tipo.codigo,
    'en': en.millisecondsSinceEpoch,
    'ti': ?titulo,
    'c': ?cuerpo,
    if (leido) 'l': true,
  };

  AvisoGuardado leida() => AvisoGuardado(
    eventoId: eventoId,
    tipo: tipo,
    en: en,
    titulo: titulo,
    cuerpo: cuerpo,
    leido: true,
  );
}

/// Reglas puras de la bandeja: qué se guarda y cuántos.
abstract final class ReglasBandeja {
  static const maximo = 40;

  /// Las solicitudes del conductor caducan en segundos: no van a la bandeja.
  static bool seGuarda(AvisoPush a) =>
      !a.esSolicitud &&
      a.tipo != TipoAviso.solicitudRetirada &&
      a.tipo != TipoAviso.otro &&
      (a.titulo != null || a.cuerpo != null);

  /// Agrega al inicio, sin repetir el evento y sin pasar del máximo.
  static List<AvisoGuardado> agregar(
    List<AvisoGuardado> lista,
    AvisoGuardado nuevo,
  ) {
    if (lista.any((a) => a.eventoId == nuevo.eventoId)) return lista;
    return [nuevo, ...lista].take(maximo).toList();
  }

  static int sinLeer(List<AvisoGuardado> lista) =>
      lista.where((a) => !a.leido).length;
}

/// La bandeja en el almacenamiento del teléfono. La usan la app y el isolate
/// que recibe los push con la app cerrada; se borra al cerrar sesión.
class BandejaAvisos {
  const BandejaAvisos(this._store);
  final SecureStore _store;
  static const _clave = 'bandeja_avisos';

  Future<List<AvisoGuardado>> leer() async {
    try {
      final crudo = await _store.read(_clave);
      if (crudo == null || crudo.isEmpty) return const [];
      return [
        for (final j in jsonDecode(crudo) as List<dynamic>)
          AvisoGuardado.desdeJson(j as Map<String, dynamic>),
      ];
    } on Object {
      return const [];
    }
  }

  Future<void> _guardar(List<AvisoGuardado> lista) =>
      _store.write(_clave, jsonEncode([for (final a in lista) a.aJson()]));

  Future<void> registrar(AvisoPush a, {DateTime? en}) async {
    if (!ReglasBandeja.seGuarda(a)) return;
    final lista = await leer();
    final nueva = ReglasBandeja.agregar(
      lista,
      AvisoGuardado(
        eventoId: a.eventoId,
        tipo: a.tipo,
        en: en ?? DateTime.now(),
        titulo: a.titulo,
        cuerpo: a.cuerpo,
      ),
    );
    if (!identical(nueva, lista)) await _guardar(nueva);
  }

  Future<void> marcarLeidas() async {
    final lista = await leer();
    if (ReglasBandeja.sinLeer(lista) == 0) return;
    await _guardar([for (final a in lista) a.leida()]);
  }

  Future<void> vaciar() => _store.delete(_clave);
}
