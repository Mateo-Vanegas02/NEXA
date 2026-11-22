import 'package:latlong2/latlong.dart';

/// Una maniobra de la ruta con el nombre de la calle (OSRM, la envía el
/// servidor en `Servicio.pasosRuta` y en las rutas en vivo).
class PasoRuta {
  const PasoRuta({
    required this.latitud,
    required this.longitud,
    this.maniobra = '',
    this.modificador = '',
    this.calle = '',
    this.metros = 0,
  });

  factory PasoRuta.fromJson(Map<String, dynamic> j) => PasoRuta(
    latitud: (j['latitud'] as num?)?.toDouble() ?? 0,
    longitud: (j['longitud'] as num?)?.toDouble() ?? 0,
    maniobra: j['maniobra'] as String? ?? '',
    modificador: j['modificador'] as String? ?? '',
    calle: (j['calle'] as String? ?? '').trim(),
    metros: (j['metros'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'latitud': latitud,
    'longitud': longitud,
    'maniobra': maniobra,
    'modificador': modificador,
    'calle': calle,
    'metros': metros,
  };

  final double latitud;
  final double longitud;
  final String maniobra;
  final String modificador;
  final String calle;
  final double metros;

  LatLng get punto => LatLng(latitud, longitud);
}

/// Busca la calle de una maniobra: el paso del servidor más cercano al punto
/// del giro (a [radioMetros] o menos) que tenga nombre.
String? calleDeManiobra(
  List<PasoRuta> pasos,
  LatLng punto, {
  double radioMetros = 40,
}) {
  const d = Distance();
  String? mejor;
  var cerca = radioMetros;
  for (final p in pasos) {
    if (p.calle.isEmpty || p.maniobra == 'depart') continue;
    final m = d.as(LengthUnit.Meter, p.punto, punto);
    if (m <= cerca) {
      cerca = m;
      mejor = p.calle;
    }
  }
  return mejor;
}
