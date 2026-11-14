import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/core/network/token_storage.dart';
import 'package:nexa_mobile/core/providers.dart';
import 'package:nexa_mobile/core/widgets/nexa_widgets.dart';
import 'package:nexa_mobile/features/auth/data/auth_repository_mock.dart';
import 'package:nexa_mobile/features/auth/domain/auth.dart';
import 'package:nexa_mobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:nexa_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:nexa_mobile/features/auth/presentation/screens/perfil_screen.dart';
import 'package:nexa_mobile/features/auth/presentation/screens/registro_screen.dart';
import 'package:nexa_mobile/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:nexa_mobile/features/niveles/domain/nivel.dart';
import 'package:nexa_mobile/features/niveles/presentation/screens/niveles_screen.dart';
import 'package:nexa_mobile/features/niveles/presentation/widgets/level_progress_bar.dart';
import 'package:nexa_mobile/core/widgets/nexa_popup.dart';
import 'package:nexa_mobile/features/niveles/presentation/widgets/celebracion_listener.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';
import 'package:nexa_mobile/features/viajes/presentation/conductor/ganancias_screen.dart';
import 'package:nexa_mobile/features/viajes/presentation/conductor/inicio_conductor_screen.dart';
import 'package:nexa_mobile/features/viajes/presentation/controllers/viaje_pasajero_controller.dart';
import 'package:nexa_mobile/features/viajes/presentation/pasajero/calificacion_screen.dart';
import 'package:nexa_mobile/features/viajes/presentation/pasajero/historial_pasajero_screen.dart';
import 'package:nexa_mobile/features/viajes/presentation/pasajero/inicio_pasajero_screen.dart';
import 'package:nexa_mobile/features/viajes/presentation/pasajero/solicitar_viaje_screen.dart';
import 'package:nexa_mobile/features/viajes/presentation/pasajero/viaje_en_curso_screen.dart';

import '../helpers.dart';

class _SesionFija extends SesionController {
  _SesionFija(this.sesion, {this.bienvenida = false});
  final Sesion sesion;
  final bool bienvenida;

  @override
  SesionState build() =>
      SesionState(sesion: sesion, inicializado: true, bienvenida: bienvenida);
}

Override _sesion(Rol rol, [String email = 'demo@nexa.co']) =>
    sesionProvider.overrideWith(
      () => _SesionFija(
        Sesion(token: 't', rol: rol, email: email, userId: 'u-${rol.name}'),
      ),
    );

/// Viaje fijo (sin polling) para probar seguimiento y calificación.
class _ViajeFijo extends ViajePasajeroController {
  _ViajeFijo(this.servicio);
  final Servicio servicio;

  @override
  Future<Servicio?> build() async => servicio;
}

Servicio _servicio(EstadoServicio estado) => Servicio(
  id: 'v1',
  estado: estado,
  origen: 'Mi ubicación',
  destino: 'Centro Comercial Plaza',
  distanciaKM: 4.2,
  ubicacionOrigen: const Coordenada(latitud: 10.40, longitud: -75.50),
  ubicacionDestino: const Coordenada(latitud: 10.42, longitud: -75.52),
  tarifa: 8500,
  metodoPago: 'efectivo',
  conductor: const Participante(
    id: 'c1',
    nombre: 'Carlos Mendoza',
    telefono: '3001234567',
    calificacion: 4.8,
    viajes: 320,
    vehiculo: 'Yamaha FZ 2.0 · Negra',
    placa: 'ABC 12D',
  ),
);

Override _viaje(EstadoServicio estado) =>
    viajePasajeroProvider.overrideWith(() => _ViajeFijo(_servicio(estado)));

/// Avanza el reloj sin `pumpAndSettle` (los skeletons animan para siempre).
Future<void> _cargar(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 200));
  }
}

void _sinErroresDeLayout(WidgetTester t) {
  final e = t.takeException();
  if (e != null) {
    fail(
      'overflow o excepción de layout: '
      '${e is FlutterError ? e.toStringDeep() : e}',
    );
  }
}

const _nivel = NivelEstado(
  usuarioId: 'u',
  rol: 'pasajero',
  nivel: 2,
  xpActual: 290,
  xpNivelActual: 270,
  xpSiguienteNivel: 760,
  xpFaltante: 470,
  progreso: 0.08,
);

void main() {
  setUpAll(iniciarFormatos);

  for (final tam in kTamanos) {
    group('${tam.width.toInt()}x${tam.height.toInt()}', () {
      /// Monta la pantalla con textScale 1.3 y verifica que no haya overflow.
      Future<void> montar(
        WidgetTester t,
        Widget pantalla, {
        List<Override> overrides = const [],
        bool esperar = true,
      }) async {
        usarTamano(t, tam, textScale: 1.3);
        await t.pumpWidget(envolver(pantalla, overrides: overrides));
        if (esperar) {
          await _cargar(t);
        } else {
          await t.pump();
        }
        _sinErroresDeLayout(t);
      }

      testWidgets('bienvenida: mensaje y las dos salidas', (t) async {
        await montar(t, const OnboardingScreen());
        expect(find.text('El precio, antes de pedir.'), findsOneWidget);
        expect(find.text('Crear cuenta'), findsOneWidget);
        expect(find.text('Ya tengo cuenta'), findsOneWidget);
      });

      testWidgets('login: valida campos obligatorios', (t) async {
        await montar(t, const LoginScreen(), esperar: false);
        await t.tap(find.widgetWithText(FilledButton, 'Entrar'));
        await t.pump();
        expect(find.text('Este campo es obligatorio'), findsNWidgets(2));
        _sinErroresDeLayout(t);
      });

      testWidgets('registro: conductor muestra aviso', (t) async {
        await montar(t, const RegistroScreen(), esperar: false);
        await t.tap(find.text('Conducir'));
        await t.pump();
        expect(
          find.textContaining('Un administrador los revisará'),
          findsOneWidget,
        );
        expect(find.text('Registrarme como conductor'), findsOneWidget);
        _sinErroresDeLayout(t);
      });

      testWidgets('barra de nivel: textos y semántica', (t) async {
        await montar(
          t,
          const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: LevelProgressBar(estado: _nivel),
            ),
          ),
          esperar: false,
        );
        expect(find.text('Nivel 2'), findsOneWidget);
        expect(find.text('290 / 760 XP'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp('Nivel 2, 8 por ciento')),
          findsOneWidget,
        );
      });

      testWidgets('dashboard pasajero: saludo, buscador, nivel y recientes', (
        t,
      ) async {
        await montar(
          t,
          const InicioPasajeroScreen(),
          overrides: [_sesion(Rol.pasajero)],
        );
        expect(find.text('Frank Salcedo'), findsOneWidget);
        expect(find.text('¿A dónde vas hoy?'), findsOneWidget);
        expect(find.text('Ahora'), findsOneWidget);
        expect(find.byType(LevelProgressBar), findsOneWidget);
        expect(find.text('Viajes recientes'), findsOneWidget);
        expect(find.text('C.C. Plaza'), findsOneWidget);
      });

      testWidgets('pedir viaje: hoja inferior y botón inactivo sin destino', (
        t,
      ) async {
        await montar(
          t,
          const SolicitarViajeScreen(),
          overrides: [_sesion(Rol.pasajero)],
        );
        expect(find.text('¿A dónde vamos?'), findsOneWidget);
        expect(find.text('Mi ubicación'), findsOneWidget);
        expect(find.text('Efectivo'), findsOneWidget);
        final boton = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Pedir NEXA'),
        );
        expect(boton.onPressed, isNull);
      });

      testWidgets('viaje en curso: pasos, conductor, SOS y acciones', (
        t,
      ) async {
        await montar(
          t,
          const ViajeEnCursoScreen(),
          overrides: [_sesion(Rol.pasajero), _viaje(EstadoServicio.enCurso)],
        );
        expect(find.text('En viaje'.toUpperCase()), findsOneWidget);
        expect(find.text('Vas hacia Centro Comercial Plaza'), findsOneWidget);
        expect(find.text('Carlos Mendoza'), findsOneWidget);
        expect(find.text('ABC 12D'), findsOneWidget);
        expect(find.text('Compartir viaje'), findsOneWidget);
        expect(find.byTooltip('Asistencia en ruta (SOS)'), findsOneWidget);
        expect(find.textContaining('Llegas en'), findsOneWidget);
        // Regresión: la hoja inferior no debe tapar todo el mapa.
        expect(
          t.getTopLeft(find.text('Carlos Mendoza')).dy,
          greaterThan(tam.height * 0.3),
        );
      });

      testWidgets('buscando conductor: extra voluntario y cancelar', (t) async {
        await montar(
          t,
          const ViajeEnCursoScreen(),
          overrides: [_sesion(Rol.pasajero), _viaje(EstadoServicio.solicitado)],
        );
        expect(find.text('Buscando tu conductor'), findsOneWidget);
        expect(find.text('Total con extra'), findsOneWidget);
        expect(find.byType(ActionChip), findsNWidgets(3));
        expect(find.text('Cancelar solicitud'), findsOneWidget);
        expect(find.byTooltip('Asistencia en ruta (SOS)'), findsNothing);
      });

      testWidgets('conductor en camino: minutos, estado y cancelar', (t) async {
        await montar(
          t,
          const ViajeEnCursoScreen(),
          overrides: [_sesion(Rol.pasajero), _viaje(EstadoServicio.aceptado)],
        );
        expect(find.textContaining('Llega en'), findsOneWidget);
        expect(
          find.text('Carlos va hacia tu punto de recogida'),
          findsOneWidget,
        );
        expect(find.text('Cancelar viaje'), findsOneWidget);
        expect(find.byTooltip('Asistencia en ruta (SOS)'), findsOneWidget);
        expect(find.byType(ActionChip), findsNothing);
      });

      testWidgets('calificación: estrellas, etiquetas y omitir', (t) async {
        await montar(
          t,
          const CalificacionScreen(),
          overrides: [_sesion(Rol.pasajero), _viaje(EstadoServicio.finalizado)],
        );
        expect(find.text('¡Llegaste!'), findsOneWidget);
        expect(find.text('Total pagado'), findsOneWidget);
        await t.ensureVisible(find.text('Calificar a Carlos'));
        await t.tap(find.text('Calificar a Carlos'));
        await t.pump();
        expect(find.text('¿Cómo te fue con Carlos?'), findsOneWidget);
        expect(find.text('Excelente'), findsOneWidget);
        expect(find.text('¿Qué estuvo bien?'), findsOneWidget);
        expect(find.text('Conducción segura'), findsOneWidget);
        await t.tap(find.byTooltip('2'));
        await t.pump();
        expect(find.text('¿Qué falló?'), findsOneWidget);
        expect(find.text('Tardaron en aceptar'), findsOneWidget);
        expect(find.text('Conducción segura'), findsNothing);
        _sinErroresDeLayout(t);
        await _cargar(t);
      });

      testWidgets('historial muestra los viajes', (t) async {
        await montar(
          t,
          const HistorialPasajeroScreen(),
          overrides: [_sesion(Rol.pasajero)],
        );
        expect(find.text('Actividad'), findsWidgets);
        expect(find.text('Completados'), findsOneWidget);
      });

      testWidgets('dashboard conductor: en línea y solicitudes', (t) async {
        await montar(
          t,
          const InicioConductorScreen(),
          overrides: [_sesion(Rol.conductor, 'conductor@nexa.co')],
        );
        expect(find.byType(LevelProgressBar), findsOneWidget);
        expect(find.text('Fuera de línea'), findsOneWidget);
        expect(find.text('No hay solicitudes por ahora'), findsOneWidget);
      });

      testWidgets('conductor pendiente: estado bloqueado con explicación', (
        t,
      ) async {
        usarTamano(t, tam, textScale: 1.3);
        final repo = MockAuthRepository(TokenStorage(MemorySecureStore()));
        await t.runAsync(() => repo.login('pendiente@nexa.co', '123456'));
        await t.pumpWidget(
          envolver(
            const InicioConductorScreen(),
            overrides: [
              _sesion(Rol.conductor, 'pendiente@nexa.co'),
              authRepositoryProvider.overrideWithValue(repo),
            ],
          ),
        );
        await _cargar(t);
        _sinErroresDeLayout(t);
        expect(find.text('Cuenta en revisión'), findsOneWidget);
        expect(find.byType(LevelProgressBar), findsNothing);
      });

      testWidgets('niveles del pasajero: sin ventajas en el nivel 1', (
        t,
      ) async {
        await montar(
          t,
          const NivelesScreen(),
          overrides: [_sesion(Rol.pasajero)],
        );
        expect(find.text('Tus ventajas actuales'), findsOneWidget);
        expect(find.textContaining('Sube de nivel'), findsOneWidget);
        expect(find.textContaining('Días NEXA'), findsNothing);
        expect(find.textContaining('Créditos'), findsNothing);
      });

      testWidgets('ganancias y perfil se pintan sin overflow', (t) async {
        await montar(
          t,
          const GananciasScreen(),
          overrides: [_sesion(Rol.conductor, 'conductor@nexa.co')],
        );
        await montar(
          t,
          const PerfilScreen(),
          overrides: [_sesion(Rol.pasajero)],
        );
        expect(find.text('Cerrar sesión'), findsOneWidget);
      });
    });
  }

  testWidgets('estados compartidos: vacío y error con reintentar', (t) async {
    usarTamano(t, kTamanos.first, textScale: 1.3);
    var reintentos = 0;
    await t.pumpWidget(
      envolver(
        Scaffold(
          body: EstadoError(mensaje: 'Falló', onReintentar: () => reintentos++),
        ),
      ),
    );
    await t.tap(find.text('Reintentar'));
    expect(reintentos, 1);
    await t.pumpWidget(
      envolver(const Scaffold(body: EstadoVacio(titulo: 'Nada'))),
    );
    expect(find.text('Nada'), findsOneWidget);
    _sinErroresDeLayout(t);
  });

  testWidgets('popup de bienvenida tras iniciar sesión (una sola vez)', (
    t,
  ) async {
    usarTamano(t, kTamanos[1]);
    await t.pumpWidget(
      envolver(
        const CelebracionListener(child: Scaffold(body: SizedBox())),
        overrides: [
          sesionProvider.overrideWith(
            () => _SesionFija(
              const Sesion(
                token: 't',
                rol: Rol.conductor,
                email: 'conductor@nexa.co',
                userId: 'u',
              ),
              bienvenida: true,
            ),
          ),
        ],
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 1600));
    expect(find.text('¡Bienvenido a NEXA!'), findsOneWidget);
    expect(find.textContaining('¡Hola, conductor!'), findsOneWidget);
    await t.tap(find.text('¡Vamos!'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('¡Bienvenido a NEXA!'), findsNothing);
    _sinErroresDeLayout(t);
  });

  group('NexaPopup', () {
    Future<void> abrir(WidgetTester t, Size tam, {bool reducir = false}) async {
      usarTamano(t, tam, textScale: 1.3);
      late BuildContext ctx;
      await t.pumpWidget(
        envolver(
          Builder(
            builder: (c) {
              ctx = c;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      );
      unawaited(
        mostrarNexaPopup<bool>(
          ctx,
          titulo: 'Título de prueba',
          mensaje: 'Mensaje de prueba',
          tipo: NexaPopupTipo.exito,
          hero: const InsigniaNivel(nivel: 3),
          acciones: const [
            NexaPopupAccion(etiqueta: 'Aceptar', valor: true),
            NexaPopupAccion(etiqueta: 'Cancelar', valor: false),
          ],
        ),
      );
    }

    for (final tam in kTamanos) {
      testWidgets('animación de entrada y contenido en ${tam.width.toInt()}', (
        t,
      ) async {
        await abrir(t, tam);
        // Al inicio de la animación el contenido aún es casi transparente.
        await t.pump(const Duration(milliseconds: 30));
        final fade = t.widget<FadeTransition>(
          find
              .ancestor(
                of: find.text('Título de prueba'),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(fade.opacity.value, lessThan(0.5));
        await t.pump(const Duration(milliseconds: 1600));
        _sinErroresDeLayout(t);
        expect(find.text('Título de prueba'), findsOneWidget);
        expect(find.text('Mensaje de prueba'), findsOneWidget);
        expect(find.text('Aceptar'), findsOneWidget);
        // Cierra con la acción secundaria.
        await t.ensureVisible(find.text('Cancelar'));
        await t.tap(find.text('Cancelar'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 600));
        expect(find.text('Título de prueba'), findsNothing);
      });
    }
  });
}
