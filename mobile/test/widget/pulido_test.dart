import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_mobile/features/auth/domain/auth.dart';
import 'package:nexa_mobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:nexa_mobile/features/auth/presentation/screens/portada_screen.dart';
import 'package:nexa_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:nexa_mobile/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:nexa_mobile/features/auth/presentation/screens/perfil_screen.dart';
import 'package:nexa_mobile/features/auth/presentation/screens/registro_conductor_screen.dart';
import 'package:nexa_mobile/features/auth/presentation/screens/registro_screen.dart';
import 'package:nexa_mobile/features/niveles/presentation/screens/niveles_screen.dart';
import 'package:nexa_mobile/features/viajes/domain/servicio.dart';
import 'package:nexa_mobile/features/viajes/presentation/conductor/ganancias_screen.dart';
import 'package:nexa_mobile/features/viajes/presentation/conductor/inicio_conductor_screen.dart';
import 'package:nexa_mobile/features/viajes/presentation/controllers/viaje_pasajero_controller.dart';
import 'package:nexa_mobile/features/viajes/presentation/pasajero/calificacion_screen.dart';
import 'package:nexa_mobile/features/viajes/presentation/pasajero/inicio_pasajero_screen.dart';
import 'package:nexa_mobile/features/viajes/presentation/pasajero/solicitar_viaje_screen.dart';
import 'package:nexa_mobile/features/viajes/presentation/pasajero/viaje_en_curso_screen.dart';
import 'package:nexa_mobile/features/viajes/presentation/widgets/solicitud_card.dart';
import 'package:nexa_mobile/features/viajes/presentation/widgets/viaje_activo_card.dart';
import 'package:nexa_mobile/features/viajes/presentation/controllers/viaje_conductor_controller.dart';

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

Override _sesion(Rol rol) => sesionProvider.overrideWith(() => _Sesion(rol));

class _ViajeFijo extends ViajePasajeroController {
  _ViajeFijo(this.estado);
  final EstadoServicio estado;

  @override
  Future<Servicio?> build() async => Servicio(
    id: 'v1',
    estado: estado,
    origen: 'Mi ubicación',
    destino: 'Centro Comercial Plaza de la Serrezuela, Cartagena',
    distanciaKM: 4.2,
    ubicacionOrigen: const Coordenada(latitud: 10.40, longitud: -75.50),
    ubicacionDestino: const Coordenada(latitud: 10.42, longitud: -75.52),
    tarifa: 8500,
    extraVoluntario: 1000,
    metodoPago: 'efectivo',
    xpGanadoPasajero: 18,
    conductor: const Participante(
      id: 'c1',
      nombre: 'Carlos Alberto Mendoza Villanueva',
      telefono: '3001234567',
      calificacion: 4.8,
      viajes: 320,
      vehiculo: 'Yamaha FZ 2.0 · Negra con detalles',
      placa: 'ABC 12D',
    ),
  );
}

Override _viaje(EstadoServicio e) =>
    viajePasajeroProvider.overrideWith(() => _ViajeFijo(e));

const _servicio = Servicio(
  id: 'v1',
  estado: EstadoServicio.aceptado,
  tarifa: 9000,
  extraVoluntario: 1000,
  origen: 'Bocagrande, Carrera 3 con Calle 8',
  destino: 'Centro Histórico, Plaza de los Coches',
  distanciaKM: 3.2,
  nivelPasajero: 3,
  pasajero: Participante(
    id: 'p1',
    nombre: 'Marta Lucía Ríos Hernández',
    telefono: '3009876543',
  ),
);

Future<void> _avanzar(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 200));
  }
}

/// Resume cada error de layout en una línea: cuánto se desborda y en qué archivo.
String _resumir(List<String> errores) => errores
    .map((e) {
      final lineas = e.split('\n');
      final cuanto = lineas.firstWhere(
        (l) => l.contains('overflowed'),
        orElse: () => lineas.first,
      );
      final donde = lineas
          .where((l) => l.contains('.dart:') && l.contains('lib/'))
          .take(1)
          .join();
      return '$cuanto -> ${donde.trim()}';
    })
    .toSet()
    .join('\n');

/// Todas las pantallas rediseñadas, con la letra del sistema al máximo
/// (200 %) y en los tres tamaños de referencia: no debe haber desbordes.
void main() {
  setUpAll(iniciarFormatos);

  final pantallas = <String, (Widget, List<Override>)>{
    'onboarding': (const OnboardingScreen(), const []),
    'portada': (const PortadaScreen(), const []),
    'login': (const LoginScreen(), const []),
    'registro': (const RegistroScreen(), const []),
    'registro conductor': (const RegistroConductorScreen(), const []),
    'inicio pasajero': (const InicioPasajeroScreen(), [_sesion(Rol.pasajero)]),
    'confirmar viaje': (const SolicitarViajeScreen(), [_sesion(Rol.pasajero)]),
    'buscando conductor': (
      const ViajeEnCursoScreen(),
      [_sesion(Rol.pasajero), _viaje(EstadoServicio.solicitado)],
    ),
    'conductor en camino': (
      const ViajeEnCursoScreen(),
      [_sesion(Rol.pasajero), _viaje(EstadoServicio.aceptado)],
    ),
    'viaje en curso': (
      const ViajeEnCursoScreen(),
      [_sesion(Rol.pasajero), _viaje(EstadoServicio.enCurso)],
    ),
    'calificación': (
      const CalificacionScreen(),
      [_sesion(Rol.pasajero), _viaje(EstadoServicio.finalizado)],
    ),
    'niveles': (const NivelesScreen(), [_sesion(Rol.pasajero)]),
    'perfil': (const PerfilScreen(), [_sesion(Rol.pasajero)]),
    'panel conductor': (
      const InicioConductorScreen(),
      [_sesion(Rol.conductor)],
    ),
    'ganancias': (const GananciasScreen(), [_sesion(Rol.conductor)]),
    'solicitud entrante': (
      const Scaffold(
        body: SingleChildScrollView(child: SolicitudCard(servicio: _servicio)),
      ),
      [_sesion(Rol.conductor)],
    ),
    'viaje activo conductor': (
      const Scaffold(
        body: SingleChildScrollView(
          child: ViajeActivoCard(
            servicio: _servicio,
            fase: FaseConductor.aRecoger,
            posicion: PosicionViaje(
              fase: 'ACEPTADO',
              latitud: 10.41,
              longitud: -75.51,
              distanciaRestanteKm: 1.2,
              etaMinutos: 4,
            ),
            pasajero: PosicionPasajero(
              latitud: 10.4,
              longitud: -75.5,
              haceSegundos: 2,
              distanciaRecogidaMetros: 80,
            ),
          ),
        ),
      ),
      [_sesion(Rol.conductor)],
    ),
  };

  for (final tam in kTamanos) {
    for (final e in pantallas.entries) {
      testWidgets(
        '${e.key} a 200 % de letra (${tam.width.toInt()}x${tam.height.toInt()})',
        (t) async {
          usarTamano(t, tam, textScale: 2);
          final errores = <String>[];
          final previo = FlutterError.onError;
          FlutterError.onError = (d) =>
              errores.add(d.toString(minLevel: DiagnosticLevel.debug));
          try {
            await t.pumpWidget(envolver(e.value.$1, overrides: e.value.$2));
            await _avanzar(t);
            // Desmonta y deja correr los temporizadores pendientes.
            await t.pumpWidget(const SizedBox.shrink());
            await t.pump(const Duration(seconds: 5));
          } finally {
            FlutterError.onError = previo;
          }
          if (errores.isNotEmpty) fail('${e.key}: ${_resumir(errores)}');
        },
      );
    }
  }
}
