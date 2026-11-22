import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/geocoding/geocoding_service.dart';
import '../../../../core/providers.dart';

/// Atajos del pasajero en la búsqueda (rediseño 2026). Se guardan solo en el
/// teléfono: el servidor no necesita saber dónde vive nadie.
enum AtajoLugar { casa, universidad }

class LugaresGuardadosController extends Notifier<Map<AtajoLugar, Lugar>> {
  static const clave = 'nexa.lugares';

  @override
  Map<AtajoLugar, Lugar> build() {
    _cargar();
    return const {};
  }

  Future<void> _cargar() async {
    final crudo = await ref.read(secureStoreProvider).read(clave);
    final leidos = leer(crudo);
    if (leidos.isNotEmpty) state = leidos;
  }

  Future<void> guardar(AtajoLugar atajo, Lugar lugar) async {
    state = {...state, atajo: lugar};
    await ref.read(secureStoreProvider).write(clave, escribir(state));
  }

  Future<void> borrar(AtajoLugar atajo) async {
    state = {...state}..remove(atajo);
    await ref.read(secureStoreProvider).write(clave, escribir(state));
  }

  static String escribir(Map<AtajoLugar, Lugar> m) => jsonEncode({
    for (final e in m.entries)
      e.key.name: {
        'nombre': e.value.nombre,
        'detalle': e.value.detalle,
        'lat': e.value.punto.latitude,
        'lng': e.value.punto.longitude,
      },
  });

  static Map<AtajoLugar, Lugar> leer(String? crudo) {
    if (crudo == null || crudo.isEmpty) return const {};
    try {
      final j = jsonDecode(crudo) as Map<String, dynamic>;
      return {
        for (final a in AtajoLugar.values)
          if (j[a.name] case final Map<String, dynamic> l)
            a: Lugar(
              nombre: l['nombre'] as String? ?? '',
              detalle: l['detalle'] as String? ?? '',
              punto: LatLng(
                (l['lat'] as num).toDouble(),
                (l['lng'] as num).toDouble(),
              ),
            ),
      };
    } on Object {
      return const {};
    }
  }
}

final lugaresGuardadosProvider =
    NotifierProvider<LugaresGuardadosController, Map<AtajoLugar, Lugar>>(
      LugaresGuardadosController.new,
    );
