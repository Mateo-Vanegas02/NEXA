import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/permisos/guia_permisos.dart';
import '../../../core/providers.dart';
import '../../auth/presentation/controllers/session_controller.dart';

/// Recorridos por las pantallas de permisos. Las reglas (qué pantalla toca)
/// están en `ReglasPermisos`; aquí solo se abren en orden. Si no se puede leer
/// el estado del teléfono (pruebas, sin plugin) no se muestra nada y decide el
/// servidor como hasta ahora.

/// Al llegar al inicio tras iniciar sesión: N01 y, para el pasajero, N02
/// (si dice «Ahora no», E01).
Future<void> revisarPermisosAlEntrar(
  BuildContext context,
  WidgetRef ref,
) async {
  final rol = ref.read(sesionProvider).sesion?.rol;
  if (rol == null) return;
  final guia = ref.read(guiaPermisosProvider);
  // Cada pantalla se marca como vista: como mucho se recorren las dos.
  for (var i = 0; i < 2; i++) {
    final paso = ReglasPermisos.alEntrar(rol, await guia.estado());
    if (paso == null || !context.mounted) return;
    final concedido = await context.push<bool>(paso.ruta);
    if (!context.mounted) return;
    if (paso == PasoPermiso.ubicacion && concedido != true) {
      await context.push<bool>(PasoPermiso.sinUbicacion.ruta);
      return;
    }
  }
}

/// Antes de pedir viaje o ponerse en línea. Devuelve si se puede seguir.
Future<bool> asegurarUbicacion(BuildContext context, WidgetRef ref) async {
  final estado = await ref.read(guiaPermisosProvider).estado();
  if (estado.ubicacion == null) return true;
  final paso = ReglasPermisos.paraUsarUbicacion(estado.ubicacion);
  if (paso == null) return true;
  if (!context.mounted) return false;
  if (paso == PasoPermiso.ubicacion) {
    if (await context.push<bool>(paso.ruta) == true) return true;
    if (!context.mounted) return false;
  }
  return await context.push<bool>(PasoPermiso.sinUbicacion.ruta) == true;
}

/// Antes de ponerse en línea: ubicación obligatoria y, la primera vez, la
/// explicación del segundo plano (N03), que puede saltarse.
Future<bool> prepararConexion(BuildContext context, WidgetRef ref) async {
  if (!await asegurarUbicacion(context, ref)) return false;
  final paso = ReglasPermisos.segundoPlano(
    await ref.read(guiaPermisosProvider).estado(),
  );
  if (paso != null && context.mounted) await context.push<bool>(paso.ruta);
  return context.mounted;
}

/// Una sola revisión al entrar por cada apertura de la app.
class _RevisionAlEntrar {
  bool hecha = false;
}

final _revisionAlEntrarProvider = Provider<_RevisionAlEntrar>(
  (ref) => _RevisionAlEntrar(),
);

/// Envuelve el inicio de cada rol: al aparecer por primera vez muestra las
/// pantallas de permisos que tocan. No dibuja nada propio.
class RevisionPermisos extends ConsumerStatefulWidget {
  const RevisionPermisos({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<RevisionPermisos> createState() => _RevisionPermisosState();
}

class _RevisionPermisosState extends ConsumerState<RevisionPermisos> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final revision = ref.read(_revisionAlEntrarProvider);
      if (revision.hecha || !mounted) return;
      revision.hecha = true;
      try {
        await revisarPermisosAlEntrar(context, ref);
      } on Object {
        // Un permiso nunca impide usar la app.
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
