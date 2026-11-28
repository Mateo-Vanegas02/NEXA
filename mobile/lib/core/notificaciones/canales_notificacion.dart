import '../l10n/gen/app_localizations.dart';

/// Qué tanto interrumpe un canal (se traduce a la importancia de Android).
enum Prioridad { alta, normal }

/// Canal de notificación de Android. El usuario puede silenciar cada uno por
/// separado en los ajustes del sistema, así que los avisos del viaje no se
/// mezclan con los de la cuenta.
///
/// Los `id` son el contrato con el servidor (`NotificadorPush.Canal` en el
/// backend, `docs/AVISOS_PUSH.md`): no se cambian, porque Android guarda la
/// configuración de cada canal por su id.
class CanalNotificacion {
  const CanalNotificacion({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.prioridad,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final Prioridad prioridad;
}

/// Íconos de las notificaciones (recursos de Android, `res/drawable*`). Se piden
/// por nombre, así que `res/raw/keep.xml` evita que el release los quite.
abstract final class IconosAviso {
  /// Ícono pequeño (barra de estado y cabecera): la N de NEXA como una ruta.
  static const pequeno = 'ic_stat_nexa';

  /// Ícono grande de los avisos del viaje.
  static const grande = 'ic_aviso_nexa';
}

/// Ids de los canales, iguales a los del servidor.
abstract final class IdsCanal {
  static const solicitudes = 'nexa_solicitudes';
  static const viaje = 'nexa_viaje';
  static const cuenta = 'nexa_cuenta';
}

/// Los tres canales de la app con sus textos.
List<CanalNotificacion> canalesNexa(AppLocalizations t) => [
  CanalNotificacion(
    id: IdsCanal.solicitudes,
    nombre: t.notiCanalSolicitudes,
    descripcion: t.notiCanalSolicitudesDesc,
    prioridad: Prioridad.alta,
  ),
  CanalNotificacion(
    id: IdsCanal.viaje,
    nombre: t.notiCanalViaje,
    descripcion: t.notiCanalViajeDesc,
    prioridad: Prioridad.alta,
  ),
  CanalNotificacion(
    id: IdsCanal.cuenta,
    nombre: t.notiCanalCuenta,
    descripcion: t.notiCanalCuentaDesc,
    prioridad: Prioridad.normal,
  ),
];
