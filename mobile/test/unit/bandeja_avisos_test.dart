import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/network/token_storage.dart';
import 'package:nexa_mobile/core/push/aviso_push.dart';
import 'package:nexa_mobile/core/push/bandeja_avisos.dart';

AvisoPush _aviso(String tipo, String id) => AvisoPush.desdeDatos({
  'tipo': tipo,
  'eventoId': id,
  'titulo': 'Carlos llegó a tu punto',
  'cuerpo': 'Busca la placa KZT 38F',
});

void main() {
  test('las solicitudes no se guardan; los avisos del viaje sí', () {
    expect(ReglasBandeja.seGuarda(_aviso('SOLICITUD_NUEVA', 'a')), isFalse);
    expect(ReglasBandeja.seGuarda(_aviso('SOLICITUD_RETIRADA', 'b')), isFalse);
    expect(ReglasBandeja.seGuarda(_aviso('CONDUCTOR_LLEGO', 'c')), isTrue);
  });

  test('registrar no repite, guarda lo nuevo primero y marca leídas', () async {
    final b = BandejaAvisos(MemorySecureStore());
    await b.registrar(_aviso('VIAJE_ACEPTADO', '1'), en: DateTime(2026, 11, 13, 8));
    await b.registrar(_aviso('CONDUCTOR_LLEGO', '2'), en: DateTime(2026, 11, 13, 9));
    await b.registrar(_aviso('CONDUCTOR_LLEGO', '2'));
    final lista = await b.leer();
    expect(lista.map((a) => a.eventoId), ['2', '1']);
    expect(ReglasBandeja.sinLeer(lista), 2);
    await b.marcarLeidas();
    expect(ReglasBandeja.sinLeer(await b.leer()), 0);
  });

  test('no pasa del máximo', () {
    var lista = <AvisoGuardado>[];
    for (var i = 0; i < ReglasBandeja.maximo + 5; i++) {
      lista = ReglasBandeja.agregar(
        lista,
        AvisoGuardado(eventoId: '$i', tipo: TipoAviso.viajeFinalizado, en: DateTime(2026)),
      );
    }
    expect(lista, hasLength(ReglasBandeja.maximo));
    expect(lista.first.eventoId, '${ReglasBandeja.maximo + 4}');
  });
}
