import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// No description provided for @appNombre.
  ///
  /// In es, this message translates to:
  /// **'NEXA'**
  String get appNombre;

  /// No description provided for @reintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get reintentar;

  /// No description provided for @cancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancelar;

  /// No description provided for @continuar.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continuar;

  /// No description provided for @omitir.
  ///
  /// In es, this message translates to:
  /// **'Omitir'**
  String get omitir;

  /// No description provided for @empezar.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get empezar;

  /// No description provided for @guardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get guardar;

  /// No description provided for @cerrarSesion.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get cerrarSesion;

  /// No description provided for @cargando.
  ///
  /// In es, this message translates to:
  /// **'Cargando…'**
  String get cargando;

  /// No description provided for @errorGenerico.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal'**
  String get errorGenerico;

  /// No description provided for @vacioHistorial.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes viajes'**
  String get vacioHistorial;

  /// No description provided for @vacioHistorialDetalle.
  ///
  /// In es, this message translates to:
  /// **'Cuando completes un viaje aparecerá aquí.'**
  String get vacioHistorialDetalle;

  /// No description provided for @onb1Titulo.
  ///
  /// In es, this message translates to:
  /// **'Pide tu mototaxi'**
  String get onb1Titulo;

  /// No description provided for @onb1Texto.
  ///
  /// In es, this message translates to:
  /// **'Solicita un viaje en segundos y sigue a tu conductor en el mapa.'**
  String get onb1Texto;

  /// No description provided for @onb2Titulo.
  ///
  /// In es, this message translates to:
  /// **'Sube de nivel'**
  String get onb2Titulo;

  /// No description provided for @onb2Texto.
  ///
  /// In es, this message translates to:
  /// **'Cada viaje te da XP. Desbloquea descuentos, prioridad y más beneficios.'**
  String get onb2Texto;

  /// No description provided for @onb3Titulo.
  ///
  /// In es, this message translates to:
  /// **'Viaja con confianza'**
  String get onb3Titulo;

  /// No description provided for @onb3Texto.
  ///
  /// In es, this message translates to:
  /// **'Conductores verificados, tarifa clara y calificaciones en cada viaje.'**
  String get onb3Texto;

  /// No description provided for @loginTitulo.
  ///
  /// In es, this message translates to:
  /// **'Hola de nuevo'**
  String get loginTitulo;

  /// No description provided for @loginSubtitulo.
  ///
  /// In es, this message translates to:
  /// **'Entra para pedir o recibir viajes.'**
  String get loginSubtitulo;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get email;

  /// No description provided for @password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get password;

  /// No description provided for @confirmarPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get confirmarPassword;

  /// No description provided for @ingresar.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get ingresar;

  /// No description provided for @noTienesCuenta.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get noTienesCuenta;

  /// No description provided for @yaTienesCuenta.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Inicia sesión'**
  String get yaTienesCuenta;

  /// No description provided for @registroTitulo.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta'**
  String get registroTitulo;

  /// No description provided for @soy.
  ///
  /// In es, this message translates to:
  /// **'Quiero usar NEXA como'**
  String get soy;

  /// No description provided for @rolPasajero.
  ///
  /// In es, this message translates to:
  /// **'Pasajero'**
  String get rolPasajero;

  /// No description provided for @rolConductor.
  ///
  /// In es, this message translates to:
  /// **'Conductor'**
  String get rolConductor;

  /// No description provided for @nombreCompleto.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get nombreCompleto;

  /// No description provided for @telefono.
  ///
  /// In es, this message translates to:
  /// **'Teléfono (10 dígitos, empieza con 3)'**
  String get telefono;

  /// No description provided for @crearCuenta.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get crearCuenta;

  /// No description provided for @campoRequerido.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get campoRequerido;

  /// No description provided for @emailInvalido.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico inválido'**
  String get emailInvalido;

  /// No description provided for @passwordCorta.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 8 caracteres'**
  String get passwordCorta;

  /// No description provided for @passwordNoCoincide.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get passwordNoCoincide;

  /// No description provided for @telefonoInvalido.
  ///
  /// In es, this message translates to:
  /// **'Teléfono colombiano inválido'**
  String get telefonoInvalido;

  /// No description provided for @registroConductorWeb.
  ///
  /// In es, this message translates to:
  /// **'El registro de conductores requiere verificación de documentos. Completa el registro en la web de NEXA; la app solo permite crear cuentas de pasajero por ahora.'**
  String get registroConductorWeb;

  /// No description provided for @navInicio.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navInicio;

  /// No description provided for @navViajes.
  ///
  /// In es, this message translates to:
  /// **'Viajes'**
  String get navViajes;

  /// No description provided for @navNiveles.
  ///
  /// In es, this message translates to:
  /// **'Niveles'**
  String get navNiveles;

  /// No description provided for @navPerfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navPerfil;

  /// No description provided for @navGanancias.
  ///
  /// In es, this message translates to:
  /// **'Ganancias'**
  String get navGanancias;

  /// No description provided for @navSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get navSolicitudes;

  /// No description provided for @adondeVas.
  ///
  /// In es, this message translates to:
  /// **'¿A dónde vas?'**
  String get adondeVas;

  /// No description provided for @destinoHint.
  ///
  /// In es, this message translates to:
  /// **'Toca el mapa para elegir el destino'**
  String get destinoHint;

  /// No description provided for @origenActual.
  ///
  /// In es, this message translates to:
  /// **'Tu ubicación'**
  String get origenActual;

  /// No description provided for @nombreDestino.
  ///
  /// In es, this message translates to:
  /// **'Nombre del destino'**
  String get nombreDestino;

  /// No description provided for @solicitarViaje.
  ///
  /// In es, this message translates to:
  /// **'Solicitar viaje'**
  String get solicitarViaje;

  /// No description provided for @estimadoTarifa.
  ///
  /// In es, this message translates to:
  /// **'Estimado de tarifa'**
  String get estimadoTarifa;

  /// No description provided for @distancia.
  ///
  /// In es, this message translates to:
  /// **'Distancia'**
  String get distancia;

  /// No description provided for @tarifaBase.
  ///
  /// In es, this message translates to:
  /// **'Tarifa'**
  String get tarifaBase;

  /// No description provided for @total.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @metodoPago.
  ///
  /// In es, this message translates to:
  /// **'Método de pago'**
  String get metodoPago;

  /// No description provided for @efectivo.
  ///
  /// In es, this message translates to:
  /// **'Efectivo'**
  String get efectivo;

  /// No description provided for @tarifaEstimadaAviso.
  ///
  /// In es, this message translates to:
  /// **'Estimado. El total final lo calcula NEXA al finalizar el viaje.'**
  String get tarifaEstimadaAviso;

  /// No description provided for @buscandoConductor.
  ///
  /// In es, this message translates to:
  /// **'Buscando conductor…'**
  String get buscandoConductor;

  /// No description provided for @conductorEnCamino.
  ///
  /// In es, this message translates to:
  /// **'Tu conductor va en camino'**
  String get conductorEnCamino;

  /// No description provided for @enViaje.
  ///
  /// In es, this message translates to:
  /// **'Viaje en curso'**
  String get enViaje;

  /// No description provided for @viajeFinalizado.
  ///
  /// In es, this message translates to:
  /// **'Viaje finalizado'**
  String get viajeFinalizado;

  /// No description provided for @viajeCancelado.
  ///
  /// In es, this message translates to:
  /// **'Viaje cancelado'**
  String get viajeCancelado;

  /// No description provided for @cancelarViaje.
  ///
  /// In es, this message translates to:
  /// **'Cancelar viaje'**
  String get cancelarViaje;

  /// No description provided for @calificaTuViaje.
  ///
  /// In es, this message translates to:
  /// **'Califica tu viaje'**
  String get calificaTuViaje;

  /// No description provided for @comentarios.
  ///
  /// In es, this message translates to:
  /// **'Comentarios (opcional)'**
  String get comentarios;

  /// No description provided for @enviarCalificacion.
  ///
  /// In es, this message translates to:
  /// **'Enviar calificación'**
  String get enviarCalificacion;

  /// No description provided for @gracias.
  ///
  /// In es, this message translates to:
  /// **'¡Gracias por calificar!'**
  String get gracias;

  /// No description provided for @historial.
  ///
  /// In es, this message translates to:
  /// **'Historial de viajes'**
  String get historial;

  /// No description provided for @perfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get perfil;

  /// No description provided for @estado_SOLICITADO.
  ///
  /// In es, this message translates to:
  /// **'Solicitado'**
  String get estado_SOLICITADO;

  /// No description provided for @estado_ACEPTADO.
  ///
  /// In es, this message translates to:
  /// **'Aceptado'**
  String get estado_ACEPTADO;

  /// No description provided for @estado_EN_CURSO.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get estado_EN_CURSO;

  /// No description provided for @estado_FINALIZADO.
  ///
  /// In es, this message translates to:
  /// **'Finalizado'**
  String get estado_FINALIZADO;

  /// No description provided for @estado_CANCELADO.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get estado_CANCELADO;

  /// No description provided for @nivelesTitulo.
  ///
  /// In es, this message translates to:
  /// **'Tus niveles'**
  String get nivelesTitulo;

  /// No description provided for @nivelActual.
  ///
  /// In es, this message translates to:
  /// **'Nivel {nombre}'**
  String nivelActual(String nombre);

  /// No description provided for @xpProgreso.
  ///
  /// In es, this message translates to:
  /// **'{actual} / {meta} XP'**
  String xpProgreso(int actual, int meta);

  /// No description provided for @nivelMaximo.
  ///
  /// In es, this message translates to:
  /// **'Nivel máximo alcanzado'**
  String get nivelMaximo;

  /// No description provided for @faltanXp.
  ///
  /// In es, this message translates to:
  /// **'Te faltan {xp} XP para el nivel {siguiente}'**
  String faltanXp(int xp, String siguiente);

  /// No description provided for @beneficios.
  ///
  /// In es, this message translates to:
  /// **'Beneficios'**
  String get beneficios;

  /// No description provided for @beneficioBloqueado.
  ///
  /// In es, this message translates to:
  /// **'Se desbloquea en nivel {nivel}'**
  String beneficioBloqueado(int nivel);

  /// No description provided for @xpGanado.
  ///
  /// In es, this message translates to:
  /// **'Ganaste {n} XP'**
  String xpGanado(int n);

  /// No description provided for @subisteNivel.
  ///
  /// In es, this message translates to:
  /// **'¡Subiste de nivel!'**
  String get subisteNivel;

  /// No description provided for @ahoraEres.
  ///
  /// In es, this message translates to:
  /// **'Subiste al nivel {nombre}'**
  String ahoraEres(String nombre);

  /// No description provided for @genial.
  ///
  /// In es, this message translates to:
  /// **'¡Genial!'**
  String get genial;

  /// No description provided for @barraNivelSemantica.
  ///
  /// In es, this message translates to:
  /// **'Nivel {nombre}, {porcentaje} por ciento hacia el siguiente nivel'**
  String barraNivelSemantica(String nombre, int porcentaje);

  /// No description provided for @enLinea.
  ///
  /// In es, this message translates to:
  /// **'En línea'**
  String get enLinea;

  /// No description provided for @fueraDeLinea.
  ///
  /// In es, this message translates to:
  /// **'Fuera de línea'**
  String get fueraDeLinea;

  /// No description provided for @estasEnLinea.
  ///
  /// In es, this message translates to:
  /// **'Recibes solicitudes de viaje'**
  String get estasEnLinea;

  /// No description provided for @estasFueraDeLinea.
  ///
  /// In es, this message translates to:
  /// **'Conéctate para recibir solicitudes'**
  String get estasFueraDeLinea;

  /// No description provided for @solicitudesEntrantes.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes entrantes'**
  String get solicitudesEntrantes;

  /// No description provided for @sinSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes por ahora'**
  String get sinSolicitudes;

  /// No description provided for @aceptar.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get aceptar;

  /// No description provided for @rechazar.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get rechazar;

  /// No description provided for @yendoAPasajero.
  ///
  /// In es, this message translates to:
  /// **'En camino al pasajero'**
  String get yendoAPasajero;

  /// No description provided for @iniciarViaje.
  ///
  /// In es, this message translates to:
  /// **'Pasajero recogido'**
  String get iniciarViaje;

  /// No description provided for @finalizarViaje.
  ///
  /// In es, this message translates to:
  /// **'Completar viaje'**
  String get finalizarViaje;

  /// No description provided for @viajeActivo.
  ///
  /// In es, this message translates to:
  /// **'Viaje activo'**
  String get viajeActivo;

  /// No description provided for @gananciasTitulo.
  ///
  /// In es, this message translates to:
  /// **'Ganancias'**
  String get gananciasTitulo;

  /// No description provided for @gananciaTotal.
  ///
  /// In es, this message translates to:
  /// **'Total ganado'**
  String get gananciaTotal;

  /// No description provided for @comisionActual.
  ///
  /// In es, this message translates to:
  /// **'Comisión actual'**
  String get comisionActual;

  /// No description provided for @comisionSiguiente.
  ///
  /// In es, this message translates to:
  /// **'Comisión siguiente nivel'**
  String get comisionSiguiente;

  /// No description provided for @requisitosCalidad.
  ///
  /// In es, this message translates to:
  /// **'Requisitos de calidad'**
  String get requisitosCalidad;

  /// No description provided for @bloqueadoCalidad.
  ///
  /// In es, this message translates to:
  /// **'Tienes los XP necesarios, pero te falta cumplir la calidad.'**
  String get bloqueadoCalidad;

  /// No description provided for @calificacion.
  ///
  /// In es, this message translates to:
  /// **'Calificación'**
  String get calificacion;

  /// No description provided for @aceptacion.
  ///
  /// In es, this message translates to:
  /// **'Aceptación'**
  String get aceptacion;

  /// No description provided for @cancelacion.
  ///
  /// In es, this message translates to:
  /// **'Cancelación'**
  String get cancelacion;

  /// No description provided for @pendienteTitulo.
  ///
  /// In es, this message translates to:
  /// **'Cuenta en revisión'**
  String get pendienteTitulo;

  /// No description provided for @pendienteTexto.
  ///
  /// In es, this message translates to:
  /// **'Un administrador está verificando tus documentos. Te avisaremos cuando tu cuenta esté aprobada; mientras tanto no puedes recibir viajes.'**
  String get pendienteTexto;

  /// No description provided for @rechazadoTexto.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud fue rechazada. Contacta a soporte de NEXA.'**
  String get rechazadoTexto;

  /// No description provided for @conductorNoSoportado.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta de conductor aún no puede iniciar sesión desde la app (pendiente en el backend).'**
  String get conductorNoSoportado;

  /// No description provided for @iniciarSesion.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get iniciarSesion;

  /// No description provided for @solicitaAhora.
  ///
  /// In es, this message translates to:
  /// **'Solicita ahora'**
  String get solicitaAhora;

  /// No description provided for @registrate.
  ///
  /// In es, this message translates to:
  /// **'Regístrate'**
  String get registrate;

  /// No description provided for @homeBadge.
  ///
  /// In es, this message translates to:
  /// **'Servicio de MotoTaxis'**
  String get homeBadge;

  /// No description provided for @homeHero.
  ///
  /// In es, this message translates to:
  /// **'Conecta con el movimiento'**
  String get homeHero;

  /// No description provided for @homeSubtitulo.
  ///
  /// In es, this message translates to:
  /// **'¡Tu destino te espera! Viajes rápidos, seguros y accesibles en dos ruedas.'**
  String get homeSubtitulo;

  /// No description provided for @servicios.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get servicios;

  /// No description provided for @serviciosSub.
  ///
  /// In es, this message translates to:
  /// **'Todo lo que puedes hacer en NEXA'**
  String get serviciosSub;

  /// No description provided for @svcReservaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Reserva de viajes'**
  String get svcReservaTitulo;

  /// No description provided for @svcReservaTexto.
  ///
  /// In es, this message translates to:
  /// **'Elige destino y tipo de moto en segundos.'**
  String get svcReservaTexto;

  /// No description provided for @svcRastreoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Rastreo en vivo'**
  String get svcRastreoTitulo;

  /// No description provided for @svcRastreoTexto.
  ///
  /// In es, this message translates to:
  /// **'Sigue a tu conductor en tiempo real.'**
  String get svcRastreoTexto;

  /// No description provided for @svcCalifTitulo.
  ///
  /// In es, this message translates to:
  /// **'Calificaciones'**
  String get svcCalifTitulo;

  /// No description provided for @svcCalifTexto.
  ///
  /// In es, this message translates to:
  /// **'Califica y comenta cada viaje.'**
  String get svcCalifTexto;

  /// No description provided for @svcPagosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Pagos seguros'**
  String get svcPagosTitulo;

  /// No description provided for @svcPagosTexto.
  ///
  /// In es, this message translates to:
  /// **'Efectivo, tarjeta o billetera digital.'**
  String get svcPagosTexto;

  /// No description provided for @abrirMenu.
  ///
  /// In es, this message translates to:
  /// **'Abrir menú'**
  String get abrirMenu;

  /// No description provided for @saludoManana.
  ///
  /// In es, this message translates to:
  /// **'Buenos días'**
  String get saludoManana;

  /// No description provided for @saludoTarde.
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes'**
  String get saludoTarde;

  /// No description provided for @saludoNoche.
  ///
  /// In es, this message translates to:
  /// **'Buenas noches'**
  String get saludoNoche;

  /// No description provided for @buscadorHint.
  ///
  /// In es, this message translates to:
  /// **'¿A dónde vas hoy?'**
  String get buscadorHint;

  /// No description provided for @ahora.
  ///
  /// In es, this message translates to:
  /// **'Ahora'**
  String get ahora;

  /// No description provided for @pedirViaje.
  ///
  /// In es, this message translates to:
  /// **'Pedir viaje'**
  String get pedirViaje;

  /// No description provided for @historialCorto.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get historialCorto;

  /// No description provided for @viajesRecientes.
  ///
  /// In es, this message translates to:
  /// **'Viajes recientes'**
  String get viajesRecientes;

  /// No description provided for @verTodo.
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get verTodo;

  /// No description provided for @viajesCantidad.
  ///
  /// In es, this message translates to:
  /// **'{n} viajes'**
  String viajesCantidad(int n);

  /// No description provided for @notificaciones.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificaciones;

  /// No description provided for @sinNotificaciones.
  ///
  /// In es, this message translates to:
  /// **'No tienes notificaciones nuevas'**
  String get sinNotificaciones;

  /// No description provided for @aDondeVamos.
  ///
  /// In es, this message translates to:
  /// **'¿A dónde vamos?'**
  String get aDondeVamos;

  /// No description provided for @origen.
  ///
  /// In es, this message translates to:
  /// **'Origen'**
  String get origen;

  /// No description provided for @miUbicacion.
  ///
  /// In es, this message translates to:
  /// **'Mi ubicación'**
  String get miUbicacion;

  /// No description provided for @destino.
  ///
  /// In es, this message translates to:
  /// **'Destino'**
  String get destino;

  /// No description provided for @tiempoEstimado.
  ///
  /// In es, this message translates to:
  /// **'Tiempo est.'**
  String get tiempoEstimado;

  /// No description provided for @minutosValor.
  ///
  /// In es, this message translates to:
  /// **'{n} min'**
  String minutosValor(int n);

  /// No description provided for @precioSugerido.
  ///
  /// In es, this message translates to:
  /// **'Precio sugerido · ajustable'**
  String get precioSugerido;

  /// No description provided for @aumentarPrecio.
  ///
  /// In es, this message translates to:
  /// **'Aumentar precio'**
  String get aumentarPrecio;

  /// No description provided for @disminuirPrecio.
  ///
  /// In es, this message translates to:
  /// **'Disminuir precio'**
  String get disminuirPrecio;

  /// No description provided for @cambiar.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get cambiar;

  /// No description provided for @volver.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get volver;

  /// No description provided for @centrarUbicacion.
  ///
  /// In es, this message translates to:
  /// **'Centrar en mi ubicación'**
  String get centrarUbicacion;

  /// No description provided for @editarDestino.
  ///
  /// In es, this message translates to:
  /// **'Editar destino'**
  String get editarDestino;

  /// No description provided for @viajeEnCursoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Viaje en curso'**
  String get viajeEnCursoTitulo;

  /// No description provided for @llegadaEstimada.
  ///
  /// In es, this message translates to:
  /// **'Llegada estimada {hora}'**
  String llegadaEstimada(String hora);

  /// No description provided for @paso_solicitado.
  ///
  /// In es, this message translates to:
  /// **'Solicitado'**
  String get paso_solicitado;

  /// No description provided for @paso_aceptado.
  ///
  /// In es, this message translates to:
  /// **'Aceptado'**
  String get paso_aceptado;

  /// No description provided for @paso_en_curso.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get paso_en_curso;

  /// No description provided for @paso_finalizado.
  ///
  /// In es, this message translates to:
  /// **'Finalizado'**
  String get paso_finalizado;

  /// No description provided for @placa.
  ///
  /// In es, this message translates to:
  /// **'Placa'**
  String get placa;

  /// No description provided for @viajesCantidadCorto.
  ///
  /// In es, this message translates to:
  /// **'{n} viajes'**
  String viajesCantidadCorto(int n);

  /// No description provided for @llamar.
  ///
  /// In es, this message translates to:
  /// **'Llamar'**
  String get llamar;

  /// No description provided for @mensaje.
  ///
  /// In es, this message translates to:
  /// **'Mensaje'**
  String get mensaje;

  /// No description provided for @compartir.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get compartir;

  /// No description provided for @compartirTexto.
  ///
  /// In es, this message translates to:
  /// **'Voy en un viaje NEXA hacia {destino}. Conductor: {conductor}.'**
  String compartirTexto(String destino, String conductor);

  /// No description provided for @asistenciaRuta.
  ///
  /// In es, this message translates to:
  /// **'Asistencia en ruta (SOS)'**
  String get asistenciaRuta;

  /// No description provided for @sosTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Necesitas ayuda?'**
  String get sosTitulo;

  /// No description provided for @sosTexto.
  ///
  /// In es, this message translates to:
  /// **'Llamaremos a la línea de emergencias 123.'**
  String get sosTexto;

  /// No description provided for @noDisponible.
  ///
  /// In es, this message translates to:
  /// **'No disponible para este conductor'**
  String get noDisponible;

  /// No description provided for @viajeFinalizadoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Viaje finalizado'**
  String get viajeFinalizadoTitulo;

  /// No description provided for @llegasteDestino.
  ///
  /// In es, this message translates to:
  /// **'¡Llegaste a tu destino!'**
  String get llegasteDestino;

  /// No description provided for @duracionMin.
  ///
  /// In es, this message translates to:
  /// **'{n} min'**
  String duracionMin(int n);

  /// No description provided for @calificaExperiencia.
  ///
  /// In es, this message translates to:
  /// **'Califica tu experiencia'**
  String get calificaExperiencia;

  /// No description provided for @comoCalificarias.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo calificarías a {nombre}?'**
  String comoCalificarias(String nombre);

  /// No description provided for @calif1.
  ///
  /// In es, this message translates to:
  /// **'Muy malo'**
  String get calif1;

  /// No description provided for @calif2.
  ///
  /// In es, this message translates to:
  /// **'Malo'**
  String get calif2;

  /// No description provided for @calif3.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get calif3;

  /// No description provided for @calif4.
  ///
  /// In es, this message translates to:
  /// **'Bueno'**
  String get calif4;

  /// No description provided for @calif5.
  ///
  /// In es, this message translates to:
  /// **'Muy bueno'**
  String get calif5;

  /// No description provided for @califDe5.
  ///
  /// In es, this message translates to:
  /// **'{texto} - {n} de 5'**
  String califDe5(String texto, int n);

  /// No description provided for @etiquetaSegura.
  ///
  /// In es, this message translates to:
  /// **'Conducción segura'**
  String get etiquetaSegura;

  /// No description provided for @etiquetaPuntual.
  ///
  /// In es, this message translates to:
  /// **'Puntual'**
  String get etiquetaPuntual;

  /// No description provided for @etiquetaAmable.
  ///
  /// In es, this message translates to:
  /// **'Amable'**
  String get etiquetaAmable;

  /// No description provided for @etiquetaMoto.
  ///
  /// In es, this message translates to:
  /// **'Moto en buen estado'**
  String get etiquetaMoto;

  /// No description provided for @etiquetaCasco.
  ///
  /// In es, this message translates to:
  /// **'Casco limpio'**
  String get etiquetaCasco;

  /// No description provided for @comentarioHint.
  ///
  /// In es, this message translates to:
  /// **'Déjanos un comentario opcional…'**
  String get comentarioHint;

  /// No description provided for @omitirPorAhora.
  ///
  /// In es, this message translates to:
  /// **'Omitir por ahora'**
  String get omitirPorAhora;

  /// No description provided for @cerrar.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get cerrar;

  /// No description provided for @tuConductor.
  ///
  /// In es, this message translates to:
  /// **'Tu conductor'**
  String get tuConductor;

  /// No description provided for @metodoTarjeta.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta'**
  String get metodoTarjeta;

  /// No description provided for @metodoBilletera.
  ///
  /// In es, this message translates to:
  /// **'Billetera digital'**
  String get metodoBilletera;

  /// No description provided for @verDesglose.
  ///
  /// In es, this message translates to:
  /// **'Ver desglose'**
  String get verDesglose;

  /// No description provided for @destinoSeleccionado.
  ///
  /// In es, this message translates to:
  /// **'Destino seleccionado'**
  String get destinoSeleccionado;

  /// No description provided for @nombreInvalido.
  ///
  /// In es, this message translates to:
  /// **'Solo letras y espacios (3 a 100 caracteres)'**
  String get nombreInvalido;

  /// No description provided for @passwordDebil.
  ///
  /// In es, this message translates to:
  /// **'Debe incluir mayúscula, minúscula y número'**
  String get passwordDebil;

  /// No description provided for @bienvenidaTitulo.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido a NEXA!'**
  String get bienvenidaTitulo;

  /// No description provided for @bienvenidaNombre.
  ///
  /// In es, this message translates to:
  /// **'¡Hola, {nombre}!'**
  String bienvenidaNombre(String nombre);

  /// No description provided for @bienvenidaPasajero.
  ///
  /// In es, this message translates to:
  /// **'Pide tu mototaxi, sigue tu viaje y sube de nivel con cada recorrido.'**
  String get bienvenidaPasajero;

  /// No description provided for @bienvenidaConductor.
  ///
  /// In es, this message translates to:
  /// **'Conéctate para recibir solicitudes y mejora tu comisión con cada viaje.'**
  String get bienvenidaConductor;

  /// No description provided for @vamos.
  ///
  /// In es, this message translates to:
  /// **'¡Vamos!'**
  String get vamos;

  /// No description provided for @cancelarViajeTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar el viaje?'**
  String get cancelarViajeTitulo;

  /// No description provided for @cancelarViajeTexto.
  ///
  /// In es, this message translates to:
  /// **'Tu conductor dejará de ir hacia ti.'**
  String get cancelarViajeTexto;

  /// No description provided for @mantenerViaje.
  ///
  /// In es, this message translates to:
  /// **'Mantener viaje'**
  String get mantenerViaje;

  /// No description provided for @cuentaYaExiste.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una cuenta con ese correo.'**
  String get cuentaYaExiste;

  /// No description provided for @puntoEnMapa.
  ///
  /// In es, this message translates to:
  /// **'Punto en el mapa'**
  String get puntoEnMapa;

  /// No description provided for @sinResultados.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados. Toca el mapa para elegir el punto.'**
  String get sinResultados;

  /// No description provided for @usarMiUbicacion.
  ///
  /// In es, this message translates to:
  /// **'Usar mi ubicación'**
  String get usarMiUbicacion;

  /// No description provided for @borrar.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get borrar;

  /// No description provided for @origenHint.
  ///
  /// In es, this message translates to:
  /// **'Busca el origen o toca el mapa'**
  String get origenHint;

  /// No description provided for @buscandoLugares.
  ///
  /// In es, this message translates to:
  /// **'Buscando…'**
  String get buscandoLugares;

  /// No description provided for @editarPerfil.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get editarPerfil;

  /// No description provided for @perfilActualizado.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado'**
  String get perfilActualizado;

  /// No description provided for @cambiarFoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get cambiarFoto;

  /// No description provided for @tomarFoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get tomarFoto;

  /// No description provided for @elegirGaleria.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get elegirGaleria;

  /// No description provided for @quitarFoto.
  ///
  /// In es, this message translates to:
  /// **'Quitar foto'**
  String get quitarFoto;

  /// No description provided for @fotoActualizada.
  ///
  /// In es, this message translates to:
  /// **'Foto actualizada'**
  String get fotoActualizada;

  /// No description provided for @fotoQuitada.
  ///
  /// In es, this message translates to:
  /// **'Foto eliminada'**
  String get fotoQuitada;

  /// No description provided for @registroConductorTitulo.
  ///
  /// In es, this message translates to:
  /// **'Registro de conductor'**
  String get registroConductorTitulo;

  /// No description provided for @registroConductorIntro.
  ///
  /// In es, this message translates to:
  /// **'Completa tus datos y fotografía tus documentos. Un administrador los revisará y, cuando te aprueben, podrás iniciar sesión.'**
  String get registroConductorIntro;

  /// No description provided for @registroConductorBoton.
  ///
  /// In es, this message translates to:
  /// **'Registrarme como conductor'**
  String get registroConductorBoton;

  /// No description provided for @seccionDatos.
  ///
  /// In es, this message translates to:
  /// **'Tus datos'**
  String get seccionDatos;

  /// No description provided for @seccionVehiculo.
  ///
  /// In es, this message translates to:
  /// **'Tu moto'**
  String get seccionVehiculo;

  /// No description provided for @seccionDocumentos.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get seccionDocumentos;

  /// No description provided for @licencia.
  ///
  /// In es, this message translates to:
  /// **'Número de licencia de conducción'**
  String get licencia;

  /// No description provided for @tarjetaPropiedad.
  ///
  /// In es, this message translates to:
  /// **'Número de tarjeta de propiedad'**
  String get tarjetaPropiedad;

  /// No description provided for @soat.
  ///
  /// In es, this message translates to:
  /// **'Número de SOAT (12 dígitos)'**
  String get soat;

  /// No description provided for @tecnomecanica.
  ///
  /// In es, this message translates to:
  /// **'Número de tecnomecánica'**
  String get tecnomecanica;

  /// No description provided for @marca.
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get marca;

  /// No description provided for @modelo.
  ///
  /// In es, this message translates to:
  /// **'Modelo'**
  String get modelo;

  /// No description provided for @color.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @docLicencia.
  ///
  /// In es, this message translates to:
  /// **'Foto de la licencia'**
  String get docLicencia;

  /// No description provided for @docTarjeta.
  ///
  /// In es, this message translates to:
  /// **'Foto de la tarjeta de propiedad'**
  String get docTarjeta;

  /// No description provided for @docSoat.
  ///
  /// In es, this message translates to:
  /// **'Foto del SOAT'**
  String get docSoat;

  /// No description provided for @docTecno.
  ///
  /// In es, this message translates to:
  /// **'Foto de la tecnomecánica'**
  String get docTecno;

  /// No description provided for @agregarFoto.
  ///
  /// In es, this message translates to:
  /// **'Agregar foto'**
  String get agregarFoto;

  /// No description provided for @fotoLista.
  ///
  /// In es, this message translates to:
  /// **'Foto lista · toca para cambiarla'**
  String get fotoLista;

  /// No description provided for @faltaFoto.
  ///
  /// In es, this message translates to:
  /// **'Adjunta la foto de este documento'**
  String get faltaFoto;

  /// No description provided for @enviarSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Enviar solicitud'**
  String get enviarSolicitud;

  /// No description provided for @yaTengoCuenta.
  ///
  /// In es, this message translates to:
  /// **'Ya tengo cuenta'**
  String get yaTengoCuenta;

  /// No description provided for @pasoDe.
  ///
  /// In es, this message translates to:
  /// **'Paso {n} de {total}'**
  String pasoDe(int n, int total);

  /// No description provided for @registroPaso1Sub.
  ///
  /// In es, this message translates to:
  /// **'Empecemos con tus datos básicos.'**
  String get registroPaso1Sub;

  /// No description provided for @registroPaso2Titulo.
  ///
  /// In es, this message translates to:
  /// **'Elige tu contraseña'**
  String get registroPaso2Titulo;

  /// No description provided for @registroPaso2Sub.
  ///
  /// In es, this message translates to:
  /// **'La usarás para entrar a tu cuenta.'**
  String get registroPaso2Sub;

  /// No description provided for @docsTitulo.
  ///
  /// In es, this message translates to:
  /// **'Tus documentos'**
  String get docsTitulo;

  /// No description provided for @docsListos.
  ///
  /// In es, this message translates to:
  /// **'{n} de {total} listos'**
  String docsListos(int n, int total);

  /// No description provided for @docsFaltan.
  ///
  /// In es, this message translates to:
  /// **'Faltan {n} para enviar tu solicitud.'**
  String docsFaltan(int n);

  /// No description provided for @docsCompletos.
  ///
  /// In es, this message translates to:
  /// **'Todo listo para enviar tu solicitud.'**
  String get docsCompletos;

  /// No description provided for @pedirNexa.
  ///
  /// In es, this message translates to:
  /// **'Pedir NEXA · {precio}'**
  String pedirNexa(String precio);

  /// No description provided for @pedirNexaSinPrecio.
  ///
  /// In es, this message translates to:
  /// **'Pedir NEXA'**
  String get pedirNexaSinPrecio;

  /// No description provided for @tuRuta.
  ///
  /// In es, this message translates to:
  /// **'Tu ruta'**
  String get tuRuta;

  /// No description provided for @fijarEnMapa.
  ///
  /// In es, this message translates to:
  /// **'Fijar en el mapa'**
  String get fijarEnMapa;

  /// No description provided for @resultadosCerca.
  ///
  /// In es, this message translates to:
  /// **'Resultados cerca de ti'**
  String get resultadosCerca;

  /// No description provided for @buscarLugarHint.
  ///
  /// In es, this message translates to:
  /// **'Busca una dirección o un lugar'**
  String get buscarLugarHint;

  /// No description provided for @tocaMapaDestino.
  ///
  /// In es, this message translates to:
  /// **'Toca el mapa para fijar tu destino'**
  String get tocaMapaDestino;

  /// No description provided for @tocaMapaOrigen.
  ///
  /// In es, this message translates to:
  /// **'Toca el mapa para fijar tu origen'**
  String get tocaMapaOrigen;

  /// No description provided for @nuevaSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Nueva solicitud'**
  String get nuevaSolicitud;

  /// No description provided for @faseARecoger.
  ///
  /// In es, this message translates to:
  /// **'A recoger'**
  String get faseARecoger;

  /// No description provided for @faseEnPunto.
  ///
  /// In es, this message translates to:
  /// **'En el punto'**
  String get faseEnPunto;

  /// No description provided for @faseEnViaje.
  ///
  /// In es, this message translates to:
  /// **'En viaje'**
  String get faseEnViaje;

  /// No description provided for @conectarme.
  ///
  /// In es, this message translates to:
  /// **'Conectarme'**
  String get conectarme;

  /// No description provided for @desconectarme.
  ///
  /// In es, this message translates to:
  /// **'Desconectarme'**
  String get desconectarme;

  /// No description provided for @buscandoSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Buscando solicitudes…'**
  String get buscandoSolicitudes;

  /// No description provided for @gananciaPorViaje.
  ///
  /// In es, this message translates to:
  /// **'Ganancia por viaje'**
  String get gananciaPorViaje;

  /// No description provided for @estasAqui.
  ///
  /// In es, this message translates to:
  /// **'Estás aquí'**
  String get estasAqui;

  /// No description provided for @inactividadNota.
  ///
  /// In es, this message translates to:
  /// **'Si pasas 90 días sin viajar bajas un nivel.'**
  String get inactividadNota;

  /// No description provided for @statViajes.
  ///
  /// In es, this message translates to:
  /// **'viajes'**
  String get statViajes;

  /// No description provided for @statCalificacion.
  ///
  /// In es, this message translates to:
  /// **'calificación'**
  String get statCalificacion;

  /// No description provided for @statNivel.
  ///
  /// In es, this message translates to:
  /// **'nivel'**
  String get statNivel;

  /// No description provided for @editarPerfilSub.
  ///
  /// In es, this message translates to:
  /// **'Nombre y celular'**
  String get editarPerfilSub;

  /// No description provided for @ofertaAhora.
  ///
  /// In es, this message translates to:
  /// **'Tu oferta ahora'**
  String get ofertaAhora;

  /// No description provided for @ocultarDesglose.
  ///
  /// In es, this message translates to:
  /// **'Ocultar desglose'**
  String get ocultarDesglose;

  /// No description provided for @ahorroNivel.
  ///
  /// In es, this message translates to:
  /// **'Tu nivel ahorra {monto}'**
  String ahorroNivel(String monto);

  /// No description provided for @motoNexa.
  ///
  /// In es, this message translates to:
  /// **'Moto NEXA'**
  String get motoNexa;

  /// No description provided for @nivelDescuento.
  ///
  /// In es, this message translates to:
  /// **'Nivel {nivel} · {pct} % de descuento'**
  String nivelDescuento(String nivel, int pct);

  /// No description provided for @solicitudEnviada.
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada'**
  String get solicitudEnviada;

  /// No description provided for @solicitudEnviadaMsg.
  ///
  /// In es, this message translates to:
  /// **'Un administrador revisará tus documentos. Podrás iniciar sesión cuando te aprueben.'**
  String get solicitudEnviadaMsg;

  /// No description provided for @errorFoto.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer la foto. Intenta de nuevo.'**
  String get errorFoto;

  /// No description provided for @licenciaInvalida.
  ///
  /// In es, this message translates to:
  /// **'Debe tener entre 6 y 15 dígitos'**
  String get licenciaInvalida;

  /// No description provided for @tarjetaInvalida.
  ///
  /// In es, this message translates to:
  /// **'Debe tener entre 8 y 15 dígitos'**
  String get tarjetaInvalida;

  /// No description provided for @soatInvalido.
  ///
  /// In es, this message translates to:
  /// **'Debe tener 12 dígitos'**
  String get soatInvalido;

  /// No description provided for @tecnoInvalida.
  ///
  /// In es, this message translates to:
  /// **'Debe tener entre 6 y 15 dígitos'**
  String get tecnoInvalida;

  /// No description provided for @placaInvalida.
  ///
  /// In es, this message translates to:
  /// **'La placa debe tener 6 caracteres (ej: ABC123)'**
  String get placaInvalida;

  /// No description provided for @textoInvalido.
  ///
  /// In es, this message translates to:
  /// **'Valor no válido'**
  String get textoInvalido;

  /// No description provided for @regPlaca.
  ///
  /// In es, this message translates to:
  /// **'Placa (ej: ABC123)'**
  String get regPlaca;

  /// No description provided for @descuentoNivel.
  ///
  /// In es, this message translates to:
  /// **'Descuento por nivel'**
  String get descuentoNivel;

  /// No description provided for @cargoPendiente.
  ///
  /// In es, this message translates to:
  /// **'Cargo pendiente por cancelación'**
  String get cargoPendiente;

  /// No description provided for @aceptoCargo.
  ///
  /// In es, this message translates to:
  /// **'Acepto que este cargo se cobre con mi viaje'**
  String get aceptoCargo;

  /// No description provided for @cotizando.
  ///
  /// In es, this message translates to:
  /// **'Calculando el precio…'**
  String get cotizando;

  /// No description provided for @tarifaServidorAviso.
  ///
  /// In es, this message translates to:
  /// **'Precio calculado por NEXA según la ruta por calles. Lo pagas al terminar el viaje.'**
  String get tarifaServidorAviso;

  /// No description provided for @recargoEspera.
  ///
  /// In es, this message translates to:
  /// **'Recargo por espera'**
  String get recargoEspera;

  /// No description provided for @extraVoluntario.
  ///
  /// In es, this message translates to:
  /// **'Extra voluntario'**
  String get extraVoluntario;

  /// No description provided for @extraTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Tarda en llegar un conductor?'**
  String get extraTitulo;

  /// No description provided for @extraTexto.
  ///
  /// In es, this message translates to:
  /// **'Suma un extra voluntario para que tu solicitud llegue antes a los conductores.'**
  String get extraTexto;

  /// No description provided for @deudaAnterior.
  ///
  /// In es, this message translates to:
  /// **'Cargo anterior'**
  String get deudaAnterior;

  /// No description provided for @errorCotizar.
  ///
  /// In es, this message translates to:
  /// **'No se pudo calcular el precio. Intenta de nuevo.'**
  String get errorCotizar;

  /// No description provided for @llegueAlPunto.
  ///
  /// In es, this message translates to:
  /// **'Llegué al punto de recogida'**
  String get llegueAlPunto;

  /// No description provided for @esperandoPasajero.
  ///
  /// In es, this message translates to:
  /// **'Esperando al pasajero'**
  String get esperandoPasajero;

  /// No description provided for @distanciaPasajero.
  ///
  /// In es, this message translates to:
  /// **'Distancia del pasajero a la recogida'**
  String get distanciaPasajero;

  /// No description provided for @cobraAlPasajero.
  ///
  /// In es, this message translates to:
  /// **'Cobra al pasajero'**
  String get cobraAlPasajero;

  /// No description provided for @viajeTerminado.
  ///
  /// In es, this message translates to:
  /// **'Viaje finalizado'**
  String get viajeTerminado;

  /// No description provided for @finalizarAntesTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Finalizar antes del destino?'**
  String get finalizarAntesTitulo;

  /// No description provided for @finalizarAntesTexto.
  ///
  /// In es, this message translates to:
  /// **'Aún no llegas al destino. Si finalizas ahora, el cobro será según lo recorrido.'**
  String get finalizarAntesTexto;

  /// No description provided for @finalizarDeTodosModos.
  ///
  /// In es, this message translates to:
  /// **'Finalizar de todos modos'**
  String get finalizarDeTodosModos;

  /// No description provided for @cancelarViajeConductorTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar este viaje?'**
  String get cancelarViajeConductorTitulo;

  /// No description provided for @cancelarViajeConductorTexto.
  ///
  /// In es, this message translates to:
  /// **'El pasajero será avisado de la cancelación.'**
  String get cancelarViajeConductorTexto;

  /// No description provided for @pasajeroCancelo.
  ///
  /// In es, this message translates to:
  /// **'El pasajero canceló el viaje.'**
  String get pasajeroCancelo;

  /// No description provided for @saldoConNexa.
  ///
  /// In es, this message translates to:
  /// **'Saldo con NEXA'**
  String get saldoConNexa;

  /// No description provided for @cobradoEfectivo.
  ///
  /// In es, this message translates to:
  /// **'Cobrado en efectivo'**
  String get cobradoEfectivo;

  /// No description provided for @gananciaPeriodo.
  ///
  /// In es, this message translates to:
  /// **'Ganado'**
  String get gananciaPeriodo;

  /// No description provided for @cargosAFavor.
  ///
  /// In es, this message translates to:
  /// **'Cargos a tu favor'**
  String get cargosAFavor;

  /// No description provided for @viajesPeriodo.
  ///
  /// In es, this message translates to:
  /// **'Viajes'**
  String get viajesPeriodo;

  /// No description provided for @debesANexa.
  ///
  /// In es, this message translates to:
  /// **'Debes a NEXA'**
  String get debesANexa;

  /// No description provided for @nexaTeDebe.
  ///
  /// In es, this message translates to:
  /// **'NEXA te debe'**
  String get nexaTeDebe;

  /// No description provided for @sinUbicacion.
  ///
  /// In es, this message translates to:
  /// **'No pudimos obtener tu ubicación. Activa el GPS e inténtalo de nuevo.'**
  String get sinUbicacion;

  /// No description provided for @ultimos30Dias.
  ///
  /// In es, this message translates to:
  /// **'Últimos 30 días'**
  String get ultimos30Dias;

  /// No description provided for @listo.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get listo;

  /// No description provided for @ventajasActuales.
  ///
  /// In es, this message translates to:
  /// **'Tus ventajas actuales'**
  String get ventajasActuales;

  /// No description provided for @descuentoViajes.
  ///
  /// In es, this message translates to:
  /// **'Descuento en tus viajes'**
  String get descuentoViajes;

  /// No description provided for @prioridadRecogida.
  ///
  /// In es, this message translates to:
  /// **'Prioridad de recogida'**
  String get prioridadRecogida;

  /// No description provided for @sinVentajas.
  ///
  /// In es, this message translates to:
  /// **'Sube de nivel para ganar descuento y prioridad en tus viajes.'**
  String get sinVentajas;

  /// No description provided for @adminRol.
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get adminRol;

  /// No description provided for @adminConductores.
  ///
  /// In es, this message translates to:
  /// **'Conductores'**
  String get adminConductores;

  /// No description provided for @adminProximamente.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get adminProximamente;

  /// No description provided for @adminProximamenteDetalle.
  ///
  /// In es, this message translates to:
  /// **'Por ahora esta sección está en la web del administrador.'**
  String get adminProximamenteDetalle;

  /// No description provided for @satEyebrow.
  ///
  /// In es, this message translates to:
  /// **'Admin · Redes neuronales'**
  String get satEyebrow;

  /// No description provided for @satTitulo.
  ///
  /// In es, this message translates to:
  /// **'Satisfacción'**
  String get satTitulo;

  /// No description provided for @satVerModelo.
  ///
  /// In es, this message translates to:
  /// **'Ver el modelo'**
  String get satVerModelo;

  /// No description provided for @satPeriodo7.
  ///
  /// In es, this message translates to:
  /// **'7 días'**
  String get satPeriodo7;

  /// No description provided for @satPeriodo30.
  ///
  /// In es, this message translates to:
  /// **'30 días'**
  String get satPeriodo30;

  /// No description provided for @satPeriodo90.
  ///
  /// In es, this message translates to:
  /// **'90 días'**
  String get satPeriodo90;

  /// No description provided for @satPeriodoRango.
  ///
  /// In es, this message translates to:
  /// **'Rango'**
  String get satPeriodoRango;

  /// No description provided for @satDemoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Modo demo.'**
  String get satDemoTitulo;

  /// No description provided for @satDemoTexto.
  ///
  /// In es, this message translates to:
  /// **'Las predicciones usan datos sintéticos hasta tener 300 calificaciones por lado. Las cifras de satisfacción sí son reales.'**
  String get satDemoTexto;

  /// No description provided for @satDemoFactores.
  ///
  /// In es, this message translates to:
  /// **'La importancia de los factores sale del modelo de demostración. Las curvas usan las calificaciones reales.'**
  String get satDemoFactores;

  /// No description provided for @satPasajerosSatisfechos.
  ///
  /// In es, this message translates to:
  /// **'Pasajeros satisfechos'**
  String get satPasajerosSatisfechos;

  /// No description provided for @satConductoresSatisfechos.
  ///
  /// In es, this message translates to:
  /// **'Conductores satisfechos'**
  String get satConductoresSatisfechos;

  /// No description provided for @satSinCalificaciones.
  ///
  /// In es, this message translates to:
  /// **'Sin calificaciones'**
  String get satSinCalificaciones;

  /// No description provided for @satVariacion.
  ///
  /// In es, this message translates to:
  /// **'{valor} pts vs. período anterior'**
  String satVariacion(String valor);

  /// No description provided for @satCalifica.
  ///
  /// In es, this message translates to:
  /// **'Califica el {pct}'**
  String satCalifica(String pct);

  /// No description provided for @satTendencia.
  ///
  /// In es, this message translates to:
  /// **'Tendencia semanal'**
  String get satTendencia;

  /// No description provided for @satSemanticaTendencia.
  ///
  /// In es, this message translates to:
  /// **'Tendencia semanal. Última semana: pasajeros {pasajero}, conductores {conductor}.'**
  String satSemanticaTendencia(String pasajero, String conductor);

  /// No description provided for @satPasajero.
  ///
  /// In es, this message translates to:
  /// **'Pasajero'**
  String get satPasajero;

  /// No description provided for @satConductor.
  ///
  /// In es, this message translates to:
  /// **'Conductor'**
  String get satConductor;

  /// No description provided for @satViajesRiesgo.
  ///
  /// In es, this message translates to:
  /// **'Viajes en riesgo'**
  String get satViajesRiesgo;

  /// No description provided for @satViajesRiesgoDetalle.
  ///
  /// In es, this message translates to:
  /// **'Sin calificar, probable \"no\"'**
  String get satViajesRiesgoDetalle;

  /// No description provided for @satFactores.
  ///
  /// In es, this message translates to:
  /// **'Factores'**
  String get satFactores;

  /// No description provided for @satLoQueMasPesa.
  ///
  /// In es, this message translates to:
  /// **'Lo que más pesa: {factor}'**
  String satLoQueMasPesa(String factor);

  /// No description provided for @satQuePesaMas.
  ///
  /// In es, this message translates to:
  /// **'Qué pesa más'**
  String get satQuePesaMas;

  /// No description provided for @satQuePesaMasDetalle.
  ///
  /// In es, this message translates to:
  /// **'Cuánto empeora la predicción si se quita cada factor'**
  String get satQuePesaMasDetalle;

  /// No description provided for @satOtrosFactores.
  ///
  /// In es, this message translates to:
  /// **'+ {cantidad} factores más con menos del {peso}'**
  String satOtrosFactores(String cantidad, String peso);

  /// No description provided for @satComoCambia.
  ///
  /// In es, this message translates to:
  /// **'Cómo cambia la satisfacción'**
  String get satComoCambia;

  /// No description provided for @satPorTramoPasajero.
  ///
  /// In es, this message translates to:
  /// **'% de pasajeros satisfechos por tramo'**
  String get satPorTramoPasajero;

  /// No description provided for @satPorTramoConductor.
  ///
  /// In es, this message translates to:
  /// **'% de conductores satisfechos por tramo'**
  String get satPorTramoConductor;

  /// No description provided for @satRiesgoIntro.
  ///
  /// In es, this message translates to:
  /// **'Viajes sin calificar donde la red predice que la persona no quedó satisfecha. Ordenados por probabilidad.'**
  String get satRiesgoIntro;

  /// No description provided for @satTodos.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get satTodos;

  /// No description provided for @satConteo.
  ///
  /// In es, this message translates to:
  /// **'{etiqueta} · {n}'**
  String satConteo(String etiqueta, String n);

  /// No description provided for @satViajeTitulo.
  ///
  /// In es, this message translates to:
  /// **'Viaje #{id} · {fecha}'**
  String satViajeTitulo(String id, String fecha);

  /// No description provided for @satRuta.
  ///
  /// In es, this message translates to:
  /// **'{origen} → {destino} · {km} km'**
  String satRuta(String origen, String destino, String km);

  /// No description provided for @satProbNo.
  ///
  /// In es, this message translates to:
  /// **'prob. de \"no\"'**
  String get satProbNo;

  /// No description provided for @satUmbral.
  ///
  /// In es, this message translates to:
  /// **'Umbral de alerta: {pct} · se ajusta en el modelo'**
  String satUmbral(String pct);

  /// No description provided for @satSinRiesgo.
  ///
  /// In es, this message translates to:
  /// **'No hay viajes en riesgo'**
  String get satSinRiesgo;

  /// No description provided for @satSinRiesgoDetalle.
  ///
  /// In es, this message translates to:
  /// **'Ningún viaje sin calificar supera el umbral de alerta.'**
  String get satSinRiesgoDetalle;

  /// No description provided for @satModeloEyebrow.
  ///
  /// In es, this message translates to:
  /// **'Red neuronal'**
  String get satModeloEyebrow;

  /// No description provided for @satModelo.
  ///
  /// In es, this message translates to:
  /// **'Modelo'**
  String get satModelo;

  /// No description provided for @satVersionTitulo.
  ///
  /// In es, this message translates to:
  /// **'Versión {version} · TensorFlow'**
  String satVersionTitulo(String version);

  /// No description provided for @satDemo.
  ///
  /// In es, this message translates to:
  /// **'Demo'**
  String get satDemo;

  /// No description provided for @satEntrenadoInfo.
  ///
  /// In es, this message translates to:
  /// **'Entrenado el {fecha} · {viajes} viajes · {variables} variables'**
  String satEntrenadoInfo(String fecha, String viajes, String variables);

  /// No description provided for @satRed.
  ///
  /// In es, this message translates to:
  /// **'Red'**
  String get satRed;

  /// No description provided for @satRegresion.
  ///
  /// In es, this message translates to:
  /// **'Regresión'**
  String get satRegresion;

  /// No description provided for @satResultado.
  ///
  /// In es, this message translates to:
  /// **'Resultado'**
  String get satResultado;

  /// No description provided for @satSupera.
  ///
  /// In es, this message translates to:
  /// **'Supera'**
  String get satSupera;

  /// No description provided for @satNoSupera.
  ///
  /// In es, this message translates to:
  /// **'No supera'**
  String get satNoSupera;

  /// No description provided for @satMetricaNota.
  ///
  /// In es, this message translates to:
  /// **'PR-AUC sobre el 15 % de viajes más recientes. Mientras la red no supere a la regresión, el panel lo advierte.'**
  String get satMetricaNota;

  /// No description provided for @satEntrenarAhora.
  ///
  /// In es, this message translates to:
  /// **'Entrenar ahora'**
  String get satEntrenarAhora;

  /// No description provided for @satEntrenarDemoNota.
  ///
  /// In es, this message translates to:
  /// **'Sin datos suficientes: se entrena con datos sintéticos (demo).'**
  String get satEntrenarDemoNota;

  /// No description provided for @satEntrenamientoEnCurso.
  ///
  /// In es, this message translates to:
  /// **'Hay un entrenamiento en curso'**
  String get satEntrenamientoEnCurso;

  /// No description provided for @satVer.
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get satVer;

  /// No description provided for @satProgramado.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento programado'**
  String get satProgramado;

  /// No description provided for @satCambiar.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get satCambiar;

  /// No description provided for @satSinProgramar.
  ///
  /// In es, this message translates to:
  /// **'Sin programar: la red solo se entrena cuando lo pidas.'**
  String get satSinProgramar;

  /// No description provided for @satProxima.
  ///
  /// In es, this message translates to:
  /// **'Próximo: {fecha}'**
  String satProxima(String fecha);

  /// No description provided for @satProximaDatosNuevos.
  ///
  /// In es, this message translates to:
  /// **'Próximo: {fecha} · solo si hay {n} viajes nuevos calificados'**
  String satProximaDatosNuevos(String fecha, String n);

  /// No description provided for @satTodosLosDias.
  ///
  /// In es, this message translates to:
  /// **'Todos los días · {hora}'**
  String satTodosLosDias(String hora);

  /// No description provided for @satCadaHorasValor.
  ///
  /// In es, this message translates to:
  /// **'Cada {horas} h'**
  String satCadaHorasValor(String horas);

  /// No description provided for @satHistorial.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get satHistorial;

  /// No description provided for @satManual.
  ///
  /// In es, this message translates to:
  /// **'Manual'**
  String get satManual;

  /// No description provided for @satProgramadoCorto.
  ///
  /// In es, this message translates to:
  /// **'Programado'**
  String get satProgramadoCorto;

  /// No description provided for @satEstPublicado.
  ///
  /// In es, this message translates to:
  /// **'Publicado'**
  String get satEstPublicado;

  /// No description provided for @satEstPublicadoDemo.
  ///
  /// In es, this message translates to:
  /// **'Publicado (demo)'**
  String get satEstPublicadoDemo;

  /// No description provided for @satEstSinPublicar.
  ///
  /// In es, this message translates to:
  /// **'Guardado sin publicar'**
  String get satEstSinPublicar;

  /// No description provided for @satEstSinDatosNuevos.
  ///
  /// In es, this message translates to:
  /// **'Sin datos nuevos'**
  String get satEstSinDatosNuevos;

  /// No description provided for @satEstFaltanDatos.
  ///
  /// In es, this message translates to:
  /// **'Faltan datos'**
  String get satEstFaltanDatos;

  /// No description provided for @satEstFallido.
  ///
  /// In es, this message translates to:
  /// **'Falló'**
  String get satEstFallido;

  /// No description provided for @satEstCancelado.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get satEstCancelado;

  /// No description provided for @satEstEnCurso.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get satEstEnCurso;

  /// No description provided for @satProgramarTitulo.
  ///
  /// In es, this message translates to:
  /// **'Programar entrenamiento'**
  String get satProgramarTitulo;

  /// No description provided for @satProgramarDetalle.
  ///
  /// In es, this message translates to:
  /// **'La red se entrena en la nube y se publica sola si cumple las condiciones.'**
  String get satProgramarDetalle;

  /// No description provided for @satFrecuencia.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia'**
  String get satFrecuencia;

  /// No description provided for @satDiaria.
  ///
  /// In es, this message translates to:
  /// **'Diario'**
  String get satDiaria;

  /// No description provided for @satSemanal.
  ///
  /// In es, this message translates to:
  /// **'Semanal'**
  String get satSemanal;

  /// No description provided for @satCadaHoras.
  ///
  /// In es, this message translates to:
  /// **'Cada N horas'**
  String get satCadaHoras;

  /// No description provided for @satDias.
  ///
  /// In es, this message translates to:
  /// **'Días'**
  String get satDias;

  /// No description provided for @satDiaLun.
  ///
  /// In es, this message translates to:
  /// **'L'**
  String get satDiaLun;

  /// No description provided for @satDiaMar.
  ///
  /// In es, this message translates to:
  /// **'M'**
  String get satDiaMar;

  /// No description provided for @satDiaMie.
  ///
  /// In es, this message translates to:
  /// **'X'**
  String get satDiaMie;

  /// No description provided for @satDiaJue.
  ///
  /// In es, this message translates to:
  /// **'J'**
  String get satDiaJue;

  /// No description provided for @satDiaVie.
  ///
  /// In es, this message translates to:
  /// **'V'**
  String get satDiaVie;

  /// No description provided for @satDiaSab.
  ///
  /// In es, this message translates to:
  /// **'S'**
  String get satDiaSab;

  /// No description provided for @satDiaDom.
  ///
  /// In es, this message translates to:
  /// **'D'**
  String get satDiaDom;

  /// No description provided for @satHoraBogota.
  ///
  /// In es, this message translates to:
  /// **'Hora (Bogotá)'**
  String get satHoraBogota;

  /// No description provided for @satIntervalo.
  ///
  /// In es, this message translates to:
  /// **'Intervalo'**
  String get satIntervalo;

  /// No description provided for @satSoloDatosNuevos.
  ///
  /// In es, this message translates to:
  /// **'Solo con datos nuevos'**
  String get satSoloDatosNuevos;

  /// No description provided for @satSoloDatosNuevosDetalle.
  ///
  /// In es, this message translates to:
  /// **'Al menos {n} viajes calificados desde el último'**
  String satSoloDatosNuevosDetalle(String n);

  /// No description provided for @satPublicarSiMejora.
  ///
  /// In es, this message translates to:
  /// **'Publicar solo si mejora'**
  String get satPublicarSiMejora;

  /// No description provided for @satPublicarSiMejoraDetalle.
  ///
  /// In es, this message translates to:
  /// **'Si no supera a la versión actual, se guarda sin usarla'**
  String get satPublicarSiMejoraDetalle;

  /// No description provided for @satProgramacionInvalida.
  ///
  /// In es, this message translates to:
  /// **'Elige al menos un día.'**
  String get satProgramacionInvalida;

  /// No description provided for @satGuardarProgramacion.
  ///
  /// In es, this message translates to:
  /// **'Guardar programación'**
  String get satGuardarProgramacion;

  /// No description provided for @satProgramacionGuardada.
  ///
  /// In es, this message translates to:
  /// **'Programación guardada'**
  String get satProgramacionGuardada;

  /// No description provided for @satEntrenandoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Entrenando'**
  String get satEntrenandoTitulo;

  /// No description provided for @satEntrenamientoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento'**
  String get satEntrenamientoTitulo;

  /// No description provided for @satEntrenandoRed.
  ///
  /// In es, this message translates to:
  /// **'Entrenando la red'**
  String get satEntrenandoRed;

  /// No description provided for @satEnCola.
  ///
  /// In es, this message translates to:
  /// **'En cola…'**
  String get satEnCola;

  /// No description provided for @satEpoca.
  ///
  /// In es, this message translates to:
  /// **'Época {epoca} de {epocas}'**
  String satEpoca(String epoca, String epocas);

  /// No description provided for @satPasoExportar.
  ///
  /// In es, this message translates to:
  /// **'Exportar viajes'**
  String get satPasoExportar;

  /// No description provided for @satPasoEntrenar.
  ///
  /// In es, this message translates to:
  /// **'Entrenar la red'**
  String get satPasoEntrenar;

  /// No description provided for @satPasoEntrenarDetalle.
  ///
  /// In es, this message translates to:
  /// **'TensorFlow · dos salidas'**
  String get satPasoEntrenarDetalle;

  /// No description provided for @satPasoComparar.
  ///
  /// In es, this message translates to:
  /// **'Comparar con la regresión'**
  String get satPasoComparar;

  /// No description provided for @satPasoPublicar.
  ///
  /// In es, this message translates to:
  /// **'Publicar para la app'**
  String get satPasoPublicar;

  /// No description provided for @satPuedesSalir.
  ///
  /// In es, this message translates to:
  /// **'Puedes salir de esta pantalla: el entrenamiento sigue en la nube. El panel muestra la versión actual hasta que se publique la nueva.'**
  String get satPuedesSalir;

  /// No description provided for @satCancelarEntrenamiento.
  ///
  /// In es, this message translates to:
  /// **'Cancelar entrenamiento'**
  String get satCancelarEntrenamiento;

  /// No description provided for @satVolverPanel.
  ///
  /// In es, this message translates to:
  /// **'Volver al modelo'**
  String get satVolverPanel;

  /// No description provided for @satFinPublicado.
  ///
  /// In es, this message translates to:
  /// **'Nueva versión publicada'**
  String get satFinPublicado;

  /// No description provided for @satFinSinPublicar.
  ///
  /// In es, this message translates to:
  /// **'Se guardó sin publicar'**
  String get satFinSinPublicar;

  /// No description provided for @satFinSinPublicarDetalle.
  ///
  /// In es, this message translates to:
  /// **'No superó a la versión actual.'**
  String get satFinSinPublicarDetalle;

  /// No description provided for @satFinSinDatosNuevos.
  ///
  /// In es, this message translates to:
  /// **'No había datos nuevos'**
  String get satFinSinDatosNuevos;

  /// No description provided for @satFinFallido.
  ///
  /// In es, this message translates to:
  /// **'El entrenamiento falló'**
  String get satFinFallido;

  /// No description provided for @satFinCancelado.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento cancelado'**
  String get satFinCancelado;

  /// No description provided for @satSinDatosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay datos para entrenar'**
  String get satSinDatosTitulo;

  /// No description provided for @satMinimoDatos.
  ///
  /// In es, this message translates to:
  /// **'La red necesita al menos {calificaciones} calificaciones y {no} \"no\" por lado. Mientras tanto se muestran las cifras reales y el modelo de demostración.'**
  String satMinimoDatos(String calificaciones, String no);

  /// No description provided for @satProgresoDatos.
  ///
  /// In es, this message translates to:
  /// **'Progreso de los datos'**
  String get satProgresoDatos;

  /// No description provided for @satCalifPasajeros.
  ///
  /// In es, this message translates to:
  /// **'Calificaciones de pasajeros'**
  String get satCalifPasajeros;

  /// No description provided for @satNoPasajeros.
  ///
  /// In es, this message translates to:
  /// **'\"No\" de pasajeros'**
  String get satNoPasajeros;

  /// No description provided for @satCalifConductores.
  ///
  /// In es, this message translates to:
  /// **'Calificaciones de conductores'**
  String get satCalifConductores;

  /// No description provided for @satNoConductores.
  ///
  /// In es, this message translates to:
  /// **'\"No\" de conductores'**
  String get satNoConductores;

  /// No description provided for @satConteoDe.
  ///
  /// In es, this message translates to:
  /// **'{actual} / {meta}'**
  String satConteoDe(String actual, String meta);

  /// No description provided for @satConsejoConductores.
  ///
  /// In es, this message translates to:
  /// **'Los conductores califican poco. Pedirles la nota al cerrar el viaje acelera el entrenamiento.'**
  String get satConsejoConductores;

  /// No description provided for @satEntrenarNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Entrenar ahora (no disponible)'**
  String get satEntrenarNoDisponible;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
