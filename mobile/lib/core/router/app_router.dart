import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/registro_conductor_screen.dart';
import '../../features/auth/presentation/screens/registro_screen.dart';
import '../../features/auth/presentation/screens/perfil_screen.dart';
import '../../features/auth/presentation/screens/portada_screen.dart';
import '../../features/auth/presentation/controllers/session_controller.dart';
import '../../features/niveles/presentation/widgets/celebracion_listener.dart';
import '../../features/niveles/presentation/screens/niveles_screen.dart';
import '../../features/viajes/presentation/conductor/inicio_conductor_screen.dart';
import '../../features/viajes/presentation/conductor/calificar_pasajero_screen.dart';
import '../../features/viajes/presentation/conductor/ganancias_screen.dart';
import '../../features/viajes/domain/servicio.dart';
import '../../features/avisos/notificaciones_screen.dart';
import '../../features/permisos/presentation/pantallas_permisos.dart';
import '../../features/admin/domain/admin.dart';
import '../../features/admin/presentation/screens/conductores_screen.dart';
import '../../features/admin/presentation/screens/operacion_screen.dart';
import '../../features/admin/presentation/screens/revision_conductor_screen.dart';
import '../../features/satisfaccion/presentation/admin_shell.dart';
import '../../features/satisfaccion/presentation/screens/entrenando_screen.dart';
import '../../features/satisfaccion/presentation/screens/factores_screen.dart';
import '../../features/satisfaccion/presentation/screens/modelo_screen.dart';
import '../../features/satisfaccion/presentation/screens/resumen_screen.dart';
import '../../features/satisfaccion/presentation/screens/riesgo_screen.dart';
import '../../features/viajes/presentation/pasajero/calificacion_screen.dart';
import '../../features/viajes/presentation/pasajero/historial_pasajero_screen.dart';
import '../../features/viajes/presentation/pasajero/inicio_pasajero_screen.dart';
import '../../features/viajes/presentation/pasajero/solicitar_viaje_screen.dart';
import '../../features/viajes/presentation/pasajero/viaje_en_curso_screen.dart';
import '../geocoding/geocoding_service.dart';
import '../l10n/gen/app_localizations.dart';
import '../theme/tokens.dart';
import '../widgets/nexa_diseno.dart';

const _publicas = {
  '/splash',
  '/onboarding',
  '/inicio',
  '/login',
  '/registro',
  '/registro/conductor',
};

String _inicio(Rol r) => switch (r) {
  Rol.pasajero => '/p/inicio',
  Rol.conductor => '/c/inicio',
  Rol.admin => '/a/inicio',
};

String _prefijo(Rol r) => switch (r) {
  Rol.pasajero => '/p/',
  Rol.conductor => '/c/',
  Rol.admin => '/a/',
};

/// Lógica de redirección (guards por rol), separada para poder probarla.
String? redirigir(SesionState s, String ubicacion) {
  if (!s.inicializado) return ubicacion == '/splash' ? null : '/splash';
  final sesion = s.sesion;
  if (sesion == null) {
    if (ubicacion == '/splash') {
      return s.onboardingVisto ? '/inicio' : '/onboarding';
    }
    if (ubicacion == '/onboarding' && s.onboardingVisto) return '/inicio';
    return _publicas.contains(ubicacion) ? null : '/inicio';
  }
  if (_publicas.contains(ubicacion)) return _inicio(sesion.rol);
  // Pantallas de permisos comunes a todos los roles (N01, N02, E01)
  if (ubicacion.startsWith('/permisos/')) return null;
  // Bandeja de avisos (N08), de cualquier rol.
  if (ubicacion == '/notificaciones') return null;
  return ubicacion.startsWith(_prefijo(sesion.rol))
      ? null
      : _inicio(sesion.rol);
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sesionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) =>
        redirigir(ref.read(sesionProvider), state.uri.path),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      // Portada pública para quien ya vio la bienvenida y no tiene sesión.
      GoRoute(path: '/inicio', builder: (_, _) => const PortadaScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/registro', builder: (_, _) => const RegistroScreen()),
      GoRoute(
        path: '/registro/conductor',
        builder: (_, _) => const RegistroConductorScreen(),
      ),
      GoRoute(
        path: '/permisos/notificaciones',
        builder: (_, _) => const PermisoNotificacionesScreen(),
      ),
      GoRoute(
        path: '/permisos/ubicacion',
        builder: (_, _) => const PermisoUbicacionScreen(),
      ),
      GoRoute(
        path: '/permisos/sin-ubicacion',
        builder: (_, _) => const SinUbicacionScreen(),
      ),
      GoRoute(
        path: '/c/permisos/segundo-plano',
        builder: (_, _) => const SegundoPlanoScreen(),
      ),
      GoRoute(
        path: '/c/permisos/bateria',
        builder: (_, _) => const GuiaBateriaScreen(),
      ),
      GoRoute(
        path: '/notificaciones',
        builder: (_, _) => const NotificacionesScreen(),
      ),
      GoRoute(path: '/p/viaje', builder: (_, _) => const ViajeEnCursoScreen()),
      GoRoute(
        path: '/p/calificar',
        builder: (_, _) => const CalificacionScreen(),
      ),
      GoRoute(
        path: '/c/calificar',
        builder: (_, state) => state.extra is Servicio
            ? CalificarPasajeroScreen(servicio: state.extra! as Servicio)
            : const InicioConductorScreen(),
      ),
      GoRoute(
        path: '/p/pedir',
        // El destino ya elegido en el inicio llega como `extra`.
        builder: (_, state) => SolicitarViajeScreen(
          destinoInicial: state.extra is Lugar ? state.extra! as Lugar : null,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _Shell(shell: shell, rol: Rol.pasajero),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/p/inicio',
                builder: (_, _) => const InicioPasajeroScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/p/viajes',
                builder: (_, _) => const HistorialPasajeroScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/p/niveles',
                builder: (_, _) => const NivelesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/p/perfil',
                builder: (_, _) => const PerfilScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _Shell(shell: shell, rol: Rol.conductor),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/c/inicio',
                builder: (_, _) => const InicioConductorScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/c/ganancias',
                builder: (_, _) => const GananciasScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/c/niveles',
                builder: (_, _) => const NivelesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/c/perfil',
                builder: (_, _) => const PerfilScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/a/conductores/revision',
        builder: (_, state) => state.extra is ConductorRevision
            ? RevisionConductorScreen(
                conductor: state.extra! as ConductorRevision,
              )
            : const ConductoresScreen(),
      ),
      GoRoute(
        path: '/a/satisfaccion/factores',
        builder: (_, _) => const FactoresScreen(),
      ),
      GoRoute(
        path: '/a/satisfaccion/riesgo',
        builder: (_, _) => const RiesgoScreen(),
      ),
      GoRoute(
        path: '/a/satisfaccion/modelo',
        builder: (_, _) => const ModeloScreen(),
      ),
      GoRoute(
        path: '/a/satisfaccion/entrenamiento/:id',
        builder: (_, state) =>
            EntrenandoScreen(id: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AdminShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/a/inicio',
                builder: (_, _) => const OperacionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/a/satisfaccion',
                builder: (_, _) => const ResumenScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/a/conductores',
                builder: (_, _) => const ConductoresScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/a/perfil',
                builder: (_, _) => const AdminPerfilScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Pestañas de pasajero y conductor: la barra flotante del rediseño (P01/C01).
class _Shell extends StatelessWidget {
  const _Shell({required this.shell, required this.rol});
  final StatefulNavigationShell shell;
  final Rol rol;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = rol == Rol.pasajero
        ? [
            NexaItemBarra(icono: Icons.home_outlined, etiqueta: l.navInicio),
            NexaItemBarra(icono: Icons.schedule, etiqueta: l.navActividad),
            NexaItemBarra(icono: Icons.star_outline, etiqueta: l.navNiveles),
            NexaItemBarra(icono: Icons.person_outline, etiqueta: l.navPerfil),
          ]
        : [
            NexaItemBarra(icono: Icons.home_outlined, etiqueta: l.navInicio),
            NexaItemBarra(
              icono: Icons.account_balance_wallet_outlined,
              etiqueta: l.navGanancias,
            ),
            NexaItemBarra(icono: Icons.star_outline, etiqueta: l.navNiveles),
            NexaItemBarra(icono: Icons.person_outline, etiqueta: l.navPerfil),
          ];
    return CelebracionListener(
      child: Scaffold(
        extendBody: true,
        body: shell,
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.md),
          child: NexaBarraFlotante(
            indice: shell.currentIndex,
            onSeleccion: (i) =>
                shell.goBranch(i, initialLocation: i == shell.currentIndex),
            items: items,
          ),
        ),
      ),
    );
  }
}
