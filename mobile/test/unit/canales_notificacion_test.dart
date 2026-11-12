import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/l10n/gen/app_localizations.dart';
import 'package:nexa_mobile/core/notificaciones/canales_notificacion.dart';
import 'package:nexa_mobile/core/notificaciones/notificaciones_locales.dart';

void main() {
  final canales = canalesNexa(lookupAppLocalizations(const Locale('es')));

  test('los ids son los del servidor (docs/AVISOS_PUSH.md)', () {
    expect(canales.map((c) => c.id), [
      'nexa_solicitudes',
      'nexa_viaje',
      'nexa_cuenta',
    ]);
  });

  test('solicitudes y viaje interrumpen; la cuenta no', () {
    final porId = {for (final c in canales) c.id: c};
    expect(porId[IdsCanal.solicitudes]!.prioridad, Prioridad.alta);
    expect(porId[IdsCanal.viaje]!.prioridad, Prioridad.alta);
    expect(porId[IdsCanal.cuenta]!.prioridad, Prioridad.normal);
  });

  test('cada canal tiene nombre y descripción para los ajustes de Android', () {
    for (final c in canales) {
      expect(c.nombre, isNotEmpty);
      expect(c.descripcion, isNotEmpty);
    }
  });

  test('se traduce al canal de Android con su importancia', () {
    final android = canalAndroid(canales.first);
    expect(android.id, 'nexa_solicitudes');
    expect(android.name, 'Solicitudes de viaje');
    expect(android.importance, Importance.high);
    expect(canalAndroid(canales.last).importance, Importance.defaultImportance);
  });

  test('sin notificaciones del teléfono nada falla', () async {
    const inactivas = NotificacionesInactivas();
    await inactivas.inicializar(canales);
    expect(await inactivas.permitidas(), isFalse);
    expect(await inactivas.pedirPermiso(), isFalse);
  });
}
