import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../core/widgets/mapa_nexa.dart';
import '../../domain/servicio.dart';

/// Cuánto costaría hoy ir desde aquí a [destino], según el servidor
/// (`POST /pasajero/cotizar`): la app no calcula precios. Se guarda 5 min
/// para no volver a cotizar al regresar al inicio. null si no hay GPS (el
/// precio desde el centro por defecto engañaría) o si la cotización falla.
final precioHoyProvider = FutureProvider.autoDispose
    .family<double?, Coordenada>((ref, destino) async {
      final enlace = ref.keepAlive();
      final vence = Timer(const Duration(minutes: 5), enlace.close);
      ref.onDispose(vence.cancel);
      final origen = await ref.watch(ubicacionProvider.future);
      if (origen == kCentroPorDefecto) return null;
      try {
        final c = await ref
            .read(pasajeroRepositoryProvider)
            .cotizar(
              Coordenada(latitud: origen.latitude, longitud: origen.longitude),
              destino,
            );
        return c.precio > 0 ? c.precio : null;
      } on Object {
        return null;
      }
    });
