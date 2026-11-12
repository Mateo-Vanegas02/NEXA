import 'package:latlong2/latlong.dart';

/// Decodifica una polyline codificada (algoritmo de Google, la que entrega
/// OSRM con `geometries=polyline`, precisión 5). La ruta la calcula el
/// servidor; la app solo la dibuja. Un texto mal formado devuelve los puntos
/// leídos hasta ahí (nunca lanza).
List<LatLng> decodificarPolyline(String? codificada, {int precision = 5}) {
  if (codificada == null || codificada.isEmpty) return const [];
  final factor = _potencia10(precision);
  final puntos = <LatLng>[];
  var indice = 0;
  var lat = 0;
  var lng = 0;
  final texto = codificada.codeUnits;

  int? siguiente() {
    var resultado = 0;
    var corrimiento = 0;
    while (indice < texto.length) {
      final b = texto[indice++] - 63;
      if (b < 0) return null;
      resultado |= (b & 0x1f) << corrimiento;
      corrimiento += 5;
      if (b < 0x20) {
        return (resultado & 1) != 0 ? ~(resultado >> 1) : resultado >> 1;
      }
    }
    return null;
  }

  while (indice < texto.length) {
    final dLat = siguiente();
    final dLng = siguiente();
    if (dLat == null || dLng == null) break;
    lat += dLat;
    lng += dLng;
    final p = (lat / factor, lng / factor);
    if (p.$1.abs() > 90 || p.$2.abs() > 180) break;
    puntos.add(LatLng(p.$1, p.$2));
  }
  return puntos;
}

String? _ultimaCodificada;
List<LatLng> _ultimaRuta = const [];

/// Igual que [decodificarPolyline], pero devuelve la misma lista mientras el
/// trazado no cambie (el mapa no redibuja ni reencuadra en cada repintado).
List<LatLng> rutaDe(String? codificada) {
  if (codificada != _ultimaCodificada) {
    _ultimaCodificada = codificada;
    _ultimaRuta = decodificarPolyline(codificada);
  }
  return _ultimaRuta;
}

int _potencia10(int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}
