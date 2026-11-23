import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexa_mobile/core/geocoding/geocoding_service.dart';

/// Responde como Nominatim y guarda la última petición.
class _Nominatim extends Interceptor {
  _Nominatim(this.respuesta);
  final List<Map<String, Object>> respuesta;
  Map<String, dynamic>? parametros;

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    parametros = o.queryParameters;
    h.resolve(Response(requestOptions: o, data: respuesta, statusCode: 200));
  }
}

Map<String, Object> _lugar(String nombre, double lat, double lon) => {
  'name': nombre,
  'display_name': '$nombre, Bolívar, Colombia',
  'lat': '$lat',
  'lon': '$lon',
};

void main() {
  test('pide solo el rectángulo de Cartagena como filtro estricto', () async {
    final falso = _Nominatim([]);
    final geo = NominatimGeocoding(Dio()..interceptors.add(falso));
    await geo.buscar('Unicentro', cerca: const LatLng(10.40, -75.50));
    final p = falso.parametros!;
    expect(p['bounded'], 1, reason: 'sin bounded el viewbox solo ordena');
    expect(p['viewbox'], '-75.575,10.56,-75.395,10.265');
    expect(p['countrycodes'], 'co');
  });

  test(
    'descarta lo que queda fuera de la zona aunque esté en el rectángulo',
    () async {
      final geo = NominatimGeocoding(
        Dio()
          ..interceptors.add(
            _Nominatim([
              _lugar('Parque de Turbaco', 10.3325, -75.4142),
              _lugar('C.C. Caribe Plaza', 10.4136, -75.5307),
              _lugar('C.C. Caribe Plaza', 10.4136, -75.5307),
              _lugar('Playa Blanca', 10.2300, -75.6000),
              _lugar('Bocagrande', 10.3997, -75.5580),
            ]),
          ),
      );
      final r = await geo.buscar('plaza');
      expect(r.map((l) => l.nombre), ['C.C. Caribe Plaza', 'Bocagrande']);
    },
  );

  test('como mucho 6 resultados', () {
    final muchos = [
      for (var i = 0; i < 10; i++)
        Lugar(
          nombre: 'Lugar $i',
          detalle: '',
          punto: LatLng(10.40 + i / 1000, -75.53),
        ),
    ];
    expect(NominatimGeocoding.filtrarEnZona(muchos), hasLength(6));
  });
}
