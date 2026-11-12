import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/network/token_storage.dart';
import 'package:nexa_mobile/core/permisos/guia_permisos.dart';
import 'package:nexa_mobile/core/permisos/permisos_dispositivo.dart';
import 'package:nexa_mobile/features/auth/domain/auth.dart';
import 'package:nexa_mobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:nexa_mobile/features/permisos/presentation/pantallas_permisos.dart';

import '../helpers.dart';

class _Sesion extends SesionController {
  _Sesion(this.rol);
  final Rol rol;

  @override
  SesionState build() => SesionState(
    sesion: Sesion(token: 't', rol: rol, email: 'demo@nexa.co', userId: 'u'),
    inicializado: true,
  );
}

/// Abre [pantalla] encima de un botón y guarda con qué se cerró.
class _Lanzador extends StatefulWidget {
  const _Lanzador(this.pantalla);
  final Widget pantalla;

  @override
  State<_Lanzador> createState() => _LanzadorState();
}

class _LanzadorState extends State<_Lanzador> {
  Object? resultado = 'abierta';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        TextButton(
          onPressed: () async {
            final r = await Navigator.of(context)
                .push(MaterialPageRoute<bool>(builder: (_) => widget.pantalla));
            setState(() => resultado = r);
          },
          child: const Text('abrir'),
        ),
        Text('resultado: $resultado'),
      ],
    ),
  );
}

Future<void> _abrir(
  WidgetTester t,
  Widget pantalla, {
  PermisosDispositivo? permisos,
  SecureStore? store,
}) async {
  await t.pumpWidget(
    envolver(_Lanzador(pantalla), permisos: permisos, store: store),
  );
  await t.tap(find.text('abrir'));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(iniciarFormatos);

  final pantallas = <String, Widget>{
    'N01': const PermisoNotificacionesScreen(),
    'N02': const PermisoUbicacionScreen(),
    'N03': const SegundoPlanoScreen(),
    'N04': const GuiaBateriaScreen(),
    'E01': const SinUbicacionScreen(),
  };

  for (final rol in [Rol.pasajero, Rol.conductor]) {
    for (final tam in kTamanos) {
      for (final e in pantallas.entries) {
        testWidgets('${e.key} sin desbordes (${rol.name}, $tam)', (t) async {
          usarTamano(t, tam, textScale: tam.width < 400 ? 1.3 : 1);
          await t.pumpWidget(
            envolver(
              e.value,
              overrides: [sesionProvider.overrideWith(() => _Sesion(rol))],
            ),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('N02: al permitir se cierra con true y queda vista', (t) async {
    final store = MemorySecureStore();
    final permisos = PermisosFijos(
      EstadoUbicacion.sinPermiso,
      alPedir: EstadoUbicacion.alUsar,
    );
    await _abrir(
      t,
      const PermisoUbicacionScreen(),
      permisos: permisos,
      store: store,
    );
    await t.tap(find.text('Permitir al usar la app'));
    await t.pumpAndSettle();
    expect(find.text('resultado: true'), findsOneWidget);
    expect(
      await store.read('permiso_visto_${PasoPermiso.ubicacion.name}'),
      '1',
    );
  });

  testWidgets('N02: «Ahora no» se cierra con false sin pedir nada', (t) async {
    final permisos = PermisosFijos(
      EstadoUbicacion.sinPermiso,
      alPedir: EstadoUbicacion.alUsar,
    );
    await _abrir(t, const PermisoUbicacionScreen(), permisos: permisos);
    await t.tap(find.text('Ahora no'));
    await t.pumpAndSettle();
    expect(find.text('resultado: false'), findsOneWidget);
    expect(permisos.estado, EstadoUbicacion.sinPermiso);
  });

  testWidgets('E01: negada para siempre abre los ajustes del teléfono', (
    t,
  ) async {
    final permisos = PermisosFijos(EstadoUbicacion.denegadaSiempre);
    await _abrir(t, const SinUbicacionScreen(), permisos: permisos);
    await t.tap(find.text('Permitir ubicación'));
    await t.pumpAndSettle();
    expect(permisos.ajustesAbiertos, 1);
    // Sigue abierta hasta que vuelva de los ajustes con el permiso
    expect(find.text('Permitir ubicación'), findsOneWidget);
  });

  testWidgets('N03: seguir sin segundo plano también continúa', (t) async {
    await _abrir(t, const SegundoPlanoScreen());
    await t.tap(find.text('Seguir sin segundo plano'));
    await t.pumpAndSettle();
    expect(find.text('resultado: true'), findsOneWidget);
  });

  testWidgets('N04: cada marca muestra sus pasos', (t) async {
    await t.pumpWidget(envolver(const GuiaBateriaScreen()));
    await t.pumpAndSettle();
    await t.tap(find.text('Motorola'));
    await t.pumpAndSettle();
    expect(
      find.text('Batería de la app → «Sin restricciones»'),
      findsOneWidget,
    );
  });

  testWidgets('el conductor ve los textos de conductor', (t) async {
    await t.pumpWidget(
      envolver(
        const SinUbicacionScreen(),
        overrides: [sesionProvider.overrideWith(() => _Sesion(Rol.conductor))],
      ),
    );
    await t.pumpAndSettle();
    expect(
      find.text('Sin tu ubicación no puedes ponerte en línea'),
      findsOneWidget,
    );
  });
}
