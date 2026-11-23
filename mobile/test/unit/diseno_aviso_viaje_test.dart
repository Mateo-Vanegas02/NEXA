import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/l10n/gen/app_localizations.dart';
import 'package:nexa_mobile/core/push/aviso_push.dart';
import 'package:nexa_mobile/core/push/diseno_aviso_viaje.dart';
import 'package:nexa_mobile/core/theme/tokens.dart';

void main() {
  final l = lookupAppLocalizations(const Locale('es'));

  AvisoPush aviso(String tipo, [Map<String, String> mas = const {}]) =>
      AvisoPush.desdeDatos({
        'tipo': tipo,
        'eventoId': '$tipo:v1',
        'servicioId': 'v1',
        'titulo': 'Título del servidor',
        'cuerpo': 'Texto del servidor',
        ...mas,
      });

  const conductor = {
    'conductor': 'carlos quintero',
    'vehiculo': 'Honda R2S azul',
    'placa': 'DTE54H',
    'calificacion': '4,3',
    'destino': 'Torres de La Plazuela',
  };

  test('aceptado: quién va, su moto, placa y nota, con la etapa', () {
    final d = disenoAvisoViaje(aviso('VIAJE_ACEPTADO', conductor), l);
    expect(d.titulo, 'Carlos va por ti');
    expect(d.texto, 'Honda R2S azul · Placa DTE54H · ★ 4,3');
    expect(d.lineas, ['Torres de La Plazuela']);
    expect(d.avance, 25);
    expect(d.color, NexaColors.cyan);
    expect(d.accion, 'Ver viaje');
  });

  test('las etapas avanzan la barra y cambian de color', () {
    expect(disenoAvisoViaje(aviso('CONDUCTOR_LLEGO', conductor), l).avance, 50);
    expect(
      disenoAvisoViaje(aviso('CONDUCTOR_LLEGO', conductor), l).color,
      NexaColors.gold,
    );
    final iniciado = disenoAvisoViaje(aviso('VIAJE_INICIADO', conductor), l);
    expect(iniciado.titulo, 'Vas camino a Torres de La Plazuela');
    expect(iniciado.avance, 75);
    final fin = disenoAvisoViaje(
      aviso('VIAJE_FINALIZADO', {...conductor, 'total': r'$4.400'}),
      l,
    );
    expect(fin.texto, startsWith(r'$4.400 · '));
    expect(fin.avance, 100);
    expect(fin.accion, 'Calificar');
  });

  test('buscando: fija, barra en movimiento y la ola', () {
    final d = disenoAvisoViaje(
      aviso('BUSQUEDA_AMPLIADA', {'ola': '2', 'olas': '4', 'radio': '2,5 km'}),
      l,
    );
    expect(d.texto, 'Ola 2 de 4 · radio de 2,5 km');
    expect(d.buscando, isTrue);
    expect(d.fija, isTrue);
    expect(d.silenciosa, isTrue);
    expect(aviso('BUSQUEDA_AMPLIADA').esDeBusqueda, isTrue);
  });

  test('un servidor viejo sin datos usa su propio texto', () {
    final d = disenoAvisoViaje(aviso('VIAJE_ACEPTADO'), l);
    expect(d.titulo, 'Título del servidor');
    expect(d.texto, 'Texto del servidor');
    final c = disenoAvisoViaje(aviso('VIAJE_CANCELADO'), l);
    expect(c.color, NexaColors.error);
  });

  test('los datos extra viajan en el payload de la notificación', () {
    final a = aviso('VIAJE_ACEPTADO', conductor);
    expect(a.datos['placa'], 'DTE54H');
    expect(AvisoPush.desdeDatos(a.datos).extra['conductor'], 'carlos quintero');
  });
}
