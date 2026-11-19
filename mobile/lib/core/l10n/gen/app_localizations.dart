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
  /// **'El precio, antes de pedir.'**
  String get onb1Titulo;

  /// No description provided for @onb1Texto.
  ///
  /// In es, this message translates to:
  /// **'Ves cuánto pagas y cuánto tarda. Sin regateo ni sorpresas al llegar.'**
  String get onb1Texto;

  /// No description provided for @onb2Titulo.
  ///
  /// In es, this message translates to:
  /// **'Conductores con papeles al día.'**
  String get onb2Titulo;

  /// No description provided for @onb2Texto.
  ///
  /// In es, this message translates to:
  /// **'Una persona de NEXA revisa licencia, SOAT, tecnomecánica y tarjeta de propiedad antes del primer viaje.'**
  String get onb2Texto;

  /// No description provided for @onb3Titulo.
  ///
  /// In es, this message translates to:
  /// **'Tu viaje, en vivo.'**
  String get onb3Titulo;

  /// No description provided for @onb3Texto.
  ///
  /// In es, this message translates to:
  /// **'Sigues la moto en el mapa, con la placa y los minutos que faltan.'**
  String get onb3Texto;

  /// No description provided for @loginTitulo.
  ///
  /// In es, this message translates to:
  /// **'Hola de nuevo'**
  String get loginTitulo;

  /// No description provided for @loginSubtitulo.
  ///
  /// In es, this message translates to:
  /// **'Entra con el correo de tu cuenta NEXA.'**
  String get loginSubtitulo;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Correo'**
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
  /// **'Entrar'**
  String get ingresar;

  /// No description provided for @noTienesCuenta.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get noTienesCuenta;

  /// No description provided for @noTienesCuentaPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get noTienesCuentaPregunta;

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

  /// No description provided for @rolAdmin.
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get rolAdmin;

  /// No description provided for @loginCuenta.
  ///
  /// In es, this message translates to:
  /// **'Tipo de cuenta'**
  String get loginCuenta;

  /// No description provided for @loginCuentaUnica.
  ///
  /// In es, this message translates to:
  /// **'Cuenta única'**
  String get loginCuentaUnica;

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
  /// **'Mantén la app abierta: las solicitudes aparecen aquí con lo que cobras.'**
  String get estasEnLinea;

  /// No description provided for @estasFueraDeLinea.
  ///
  /// In es, this message translates to:
  /// **'Estás fuera de línea'**
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
  /// **'Iniciar viaje'**
  String get iniciarViaje;

  /// No description provided for @finalizarViaje.
  ///
  /// In es, this message translates to:
  /// **'Finalizar viaje'**
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
  /// **'Recogida'**
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
  /// **'Mantén presionado el botón y llamaremos a la línea de emergencias 123.'**
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
  /// **'Excelente'**
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
  /// **'¿Cómo quieres usar NEXA?'**
  String get registroPaso1Sub;

  /// No description provided for @rolViajar.
  ///
  /// In es, this message translates to:
  /// **'Viajar'**
  String get rolViajar;

  /// No description provided for @rolViajarSub.
  ///
  /// In es, this message translates to:
  /// **'Pide motos y sube de nivel'**
  String get rolViajarSub;

  /// No description provided for @rolConducir.
  ///
  /// In es, this message translates to:
  /// **'Conducir'**
  String get rolConducir;

  /// No description provided for @rolConducirSub.
  ///
  /// In es, this message translates to:
  /// **'Gana con tu moto. Pide tus documentos.'**
  String get rolConducirSub;

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
  /// **'Resultados'**
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
  /// **'Buscando solicitudes cerca de ti'**
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
  /// **'Tu nivel te ahorra {monto} en este viaje'**
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
  /// **'Llegué'**
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

  /// No description provided for @satSinModeloTitulo.
  ///
  /// In es, this message translates to:
  /// **'Sin modelo todavía.'**
  String get satSinModeloTitulo;

  /// No description provided for @satSinModeloTexto.
  ///
  /// In es, this message translates to:
  /// **'Las cifras de satisfacción son reales. Los factores y los viajes en riesgo aparecen después del primer entrenamiento con viajes reales.'**
  String get satSinModeloTexto;

  /// No description provided for @satSinModeloFactores.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay un modelo entrenado con viajes reales: entrénalo en Modelo. Las curvas usan las calificaciones reales.'**
  String get satSinModeloFactores;

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
  /// **'Tendencia'**
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

  /// No description provided for @satEntrenarFaltanDatos.
  ///
  /// In es, this message translates to:
  /// **'Se podrá entrenar cuando haya suficientes calificaciones reales.'**
  String get satEntrenarFaltanDatos;

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
  /// **'La red necesita al menos {calificaciones} calificaciones y {no} \"no\" por lado. Mientras tanto se muestran las cifras reales de satisfacción.'**
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

  /// No description provided for @notiCanalSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes de viaje'**
  String get notiCanalSolicitudes;

  /// No description provided for @notiCanalSolicitudesDesc.
  ///
  /// In es, this message translates to:
  /// **'Nuevas solicitudes cerca de ti mientras estás en línea'**
  String get notiCanalSolicitudesDesc;

  /// No description provided for @notiCanalViaje.
  ///
  /// In es, this message translates to:
  /// **'Tu viaje'**
  String get notiCanalViaje;

  /// No description provided for @notiCanalViajeDesc.
  ///
  /// In es, this message translates to:
  /// **'Conductor en camino, llegada al punto y fin del viaje'**
  String get notiCanalViajeDesc;

  /// No description provided for @notiCanalCuenta.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta'**
  String get notiCanalCuenta;

  /// No description provided for @notiCanalCuentaDesc.
  ///
  /// In es, this message translates to:
  /// **'Cargos pendientes, nivel y saldo con NEXA'**
  String get notiCanalCuentaDesc;

  /// No description provided for @permAhoraNo.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get permAhoraNo;

  /// No description provided for @permNotiTitulo.
  ///
  /// In es, this message translates to:
  /// **'Te avisamos lo importante del viaje'**
  String get permNotiTitulo;

  /// No description provided for @permNotiTexto.
  ///
  /// In es, this message translates to:
  /// **'Aunque la app esté cerrada o el teléfono bloqueado.'**
  String get permNotiTexto;

  /// No description provided for @permNotiAcepta.
  ///
  /// In es, this message translates to:
  /// **'Cuando un conductor acepta'**
  String get permNotiAcepta;

  /// No description provided for @permNotiAceptaSub.
  ///
  /// In es, this message translates to:
  /// **'Quién va por ti y en qué moto'**
  String get permNotiAceptaSub;

  /// No description provided for @permNotiLlega.
  ///
  /// In es, this message translates to:
  /// **'Cuando llega a tu punto'**
  String get permNotiLlega;

  /// No description provided for @permNotiLlegaSub.
  ///
  /// In es, this message translates to:
  /// **'Con la placa para reconocerlo'**
  String get permNotiLlegaSub;

  /// No description provided for @permNotiCargos.
  ///
  /// In es, this message translates to:
  /// **'Cargos o saldos pendientes'**
  String get permNotiCargos;

  /// No description provided for @permNotiCargosSub.
  ///
  /// In es, this message translates to:
  /// **'Sin sorpresas en tu próximo viaje'**
  String get permNotiCargosSub;

  /// No description provided for @permNotiSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes cerca de ti'**
  String get permNotiSolicitudes;

  /// No description provided for @permNotiSolicitudesSub.
  ///
  /// In es, this message translates to:
  /// **'Con lo que ganas y la distancia'**
  String get permNotiSolicitudesSub;

  /// No description provided for @permNotiCancela.
  ///
  /// In es, this message translates to:
  /// **'Si el pasajero cancela'**
  String get permNotiCancela;

  /// No description provided for @permNotiCancelaSub.
  ///
  /// In es, this message translates to:
  /// **'Para que no vayas en vano'**
  String get permNotiCancelaSub;

  /// No description provided for @permNotiPermitir.
  ///
  /// In es, this message translates to:
  /// **'Permitir notificaciones'**
  String get permNotiPermitir;

  /// No description provided for @permUbicTitulo.
  ///
  /// In es, this message translates to:
  /// **'Usamos tu ubicación para recogerte'**
  String get permUbicTitulo;

  /// No description provided for @permUbicTexto.
  ///
  /// In es, this message translates to:
  /// **'Solo mientras usas la app. Sin ella no podemos pedir tu viaje.'**
  String get permUbicTexto;

  /// No description provided for @permUbicTituloConductor.
  ///
  /// In es, this message translates to:
  /// **'Tu ubicación te trae los viajes'**
  String get permUbicTituloConductor;

  /// No description provided for @permUbicTextoConductor.
  ///
  /// In es, this message translates to:
  /// **'Las solicitudes se reparten por cercanía: sin ubicación no puedes ponerte en línea.'**
  String get permUbicTextoConductor;

  /// No description provided for @permUbicPunto.
  ///
  /// In es, this message translates to:
  /// **'Punto de recogida exacto'**
  String get permUbicPunto;

  /// No description provided for @permUbicPuntoSub.
  ///
  /// In es, this message translates to:
  /// **'Lo ajustas hasta 300 m de ti'**
  String get permUbicPuntoSub;

  /// No description provided for @permUbicEncuentra.
  ///
  /// In es, this message translates to:
  /// **'El conductor te encuentra'**
  String get permUbicEncuentra;

  /// No description provided for @permUbicEncuentraSub.
  ///
  /// In es, this message translates to:
  /// **'Ve dónde estás mientras llega'**
  String get permUbicEncuentraSub;

  /// No description provided for @permUbicOla.
  ///
  /// In es, this message translates to:
  /// **'Primero las solicitudes cercanas'**
  String get permUbicOla;

  /// No description provided for @permUbicOlaSub.
  ///
  /// In es, this message translates to:
  /// **'Te llegan antes las de tu zona'**
  String get permUbicOlaSub;

  /// No description provided for @permUbicLlegada.
  ///
  /// In es, this message translates to:
  /// **'Tiempo de llegada real'**
  String get permUbicLlegada;

  /// No description provided for @permUbicLlegadaSub.
  ///
  /// In es, this message translates to:
  /// **'El pasajero ve cuánto te falta'**
  String get permUbicLlegadaSub;

  /// No description provided for @permUbicPermitir.
  ///
  /// In es, this message translates to:
  /// **'Permitir al usar la app'**
  String get permUbicPermitir;

  /// No description provided for @perm2PlanoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Recibe viajes con la pantalla apagada'**
  String get perm2PlanoTitulo;

  /// No description provided for @perm2PlanoTexto.
  ///
  /// In es, this message translates to:
  /// **'NEXA usa tu ubicación en segundo plano solo mientras estás en línea o en un viaje, para que no pierdas tu lugar en la ola.'**
  String get perm2PlanoTexto;

  /// No description provided for @perm2PlanoElige.
  ///
  /// In es, this message translates to:
  /// **'En la pantalla siguiente, elige'**
  String get perm2PlanoElige;

  /// No description provided for @perm2PlanoSiempre.
  ///
  /// In es, this message translates to:
  /// **'Permitir todo el tiempo'**
  String get perm2PlanoSiempre;

  /// No description provided for @perm2PlanoAlUsar.
  ///
  /// In es, this message translates to:
  /// **'Permitir solo con la app en uso'**
  String get perm2PlanoAlUsar;

  /// No description provided for @perm2PlanoNo.
  ///
  /// In es, this message translates to:
  /// **'No permitir'**
  String get perm2PlanoNo;

  /// No description provided for @perm2PlanoMarca.
  ///
  /// In es, this message translates to:
  /// **'Mi teléfono cierra la app'**
  String get perm2PlanoMarca;

  /// No description provided for @perm2PlanoContinuar.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get perm2PlanoContinuar;

  /// No description provided for @perm2PlanoSin.
  ///
  /// In es, this message translates to:
  /// **'Seguir sin segundo plano'**
  String get perm2PlanoSin;

  /// No description provided for @permBateriaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Evita que tu teléfono cierre NEXA'**
  String get permBateriaTitulo;

  /// No description provided for @permBateriaTexto.
  ///
  /// In es, this message translates to:
  /// **'Algunas marcas apagan las apps en segundo plano para ahorrar batería. Elige la tuya.'**
  String get permBateriaTexto;

  /// No description provided for @permBateriaAbrir.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes de NEXA'**
  String get permBateriaAbrir;

  /// No description provided for @permBateriaOtra.
  ///
  /// In es, this message translates to:
  /// **'Otra marca'**
  String get permBateriaOtra;

  /// No description provided for @permBatSamsung1.
  ///
  /// In es, this message translates to:
  /// **'Ajustes → Apps → NEXA → Batería'**
  String get permBatSamsung1;

  /// No description provided for @permBatSamsung2.
  ///
  /// In es, this message translates to:
  /// **'Elige «Sin restricciones»'**
  String get permBatSamsung2;

  /// No description provided for @permBatSamsung3.
  ///
  /// In es, this message translates to:
  /// **'Ajustes → Batería → Límites de uso en segundo plano'**
  String get permBatSamsung3;

  /// No description provided for @permBatSamsung4.
  ///
  /// In es, this message translates to:
  /// **'Quita NEXA de «Apps en suspensión»'**
  String get permBatSamsung4;

  /// No description provided for @permBatXiaomi1.
  ///
  /// In es, this message translates to:
  /// **'Ajustes → Apps → Administrar apps → NEXA'**
  String get permBatXiaomi1;

  /// No description provided for @permBatXiaomi2.
  ///
  /// In es, this message translates to:
  /// **'Ahorro de batería → «Sin restricciones»'**
  String get permBatXiaomi2;

  /// No description provided for @permBatXiaomi3.
  ///
  /// In es, this message translates to:
  /// **'Activa «Inicio automático»'**
  String get permBatXiaomi3;

  /// No description provided for @permBatXiaomi4.
  ///
  /// In es, this message translates to:
  /// **'En recientes, deja presionado NEXA y toca el candado'**
  String get permBatXiaomi4;

  /// No description provided for @permBatMotorola1.
  ///
  /// In es, this message translates to:
  /// **'Ajustes → Apps → NEXA'**
  String get permBatMotorola1;

  /// No description provided for @permBatMotorola2.
  ///
  /// In es, this message translates to:
  /// **'Batería de la app → «Sin restricciones»'**
  String get permBatMotorola2;

  /// No description provided for @permBatMotorola3.
  ///
  /// In es, this message translates to:
  /// **'Activa «Permitir uso en segundo plano»'**
  String get permBatMotorola3;

  /// No description provided for @permBatMotorola4.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a NEXA y ponte en línea'**
  String get permBatMotorola4;

  /// No description provided for @permBatHuawei1.
  ///
  /// In es, this message translates to:
  /// **'Ajustes → Batería → Inicio de apps'**
  String get permBatHuawei1;

  /// No description provided for @permBatHuawei2.
  ///
  /// In es, this message translates to:
  /// **'Busca NEXA y desactiva «Gestionar automáticamente»'**
  String get permBatHuawei2;

  /// No description provided for @permBatHuawei3.
  ///
  /// In es, this message translates to:
  /// **'Activa inicio automático, secundario y en segundo plano'**
  String get permBatHuawei3;

  /// No description provided for @permBatHuawei4.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a NEXA y ponte en línea'**
  String get permBatHuawei4;

  /// No description provided for @permBatOtra1.
  ///
  /// In es, this message translates to:
  /// **'Ajustes → Apps → NEXA → Batería'**
  String get permBatOtra1;

  /// No description provided for @permBatOtra2.
  ///
  /// In es, this message translates to:
  /// **'Elige «Sin restricciones» o «No optimizar»'**
  String get permBatOtra2;

  /// No description provided for @permBatOtra3.
  ///
  /// In es, this message translates to:
  /// **'Permite el uso en segundo plano'**
  String get permBatOtra3;

  /// No description provided for @permBatOtra4.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a NEXA y ponte en línea'**
  String get permBatOtra4;

  /// No description provided for @permSinUbicTitulo.
  ///
  /// In es, this message translates to:
  /// **'Sin tu ubicación no podemos pedir el viaje'**
  String get permSinUbicTitulo;

  /// No description provided for @permSinUbicTexto.
  ///
  /// In es, this message translates to:
  /// **'La usamos para fijar el punto de recogida y para que el conductor te encuentre. Nunca la compartimos fuera del viaje.'**
  String get permSinUbicTexto;

  /// No description provided for @permSinUbicTituloConductor.
  ///
  /// In es, this message translates to:
  /// **'Sin tu ubicación no puedes ponerte en línea'**
  String get permSinUbicTituloConductor;

  /// No description provided for @permSinUbicTextoConductor.
  ///
  /// In es, this message translates to:
  /// **'La usamos para repartir las solicitudes por cercanía y para que el pasajero vea dónde vienes. Solo mientras estás en línea o en un viaje.'**
  String get permSinUbicTextoConductor;

  /// No description provided for @permSinUbicPasos.
  ///
  /// In es, this message translates to:
  /// **'Si ya la negaste'**
  String get permSinUbicPasos;

  /// No description provided for @permSinUbicPaso1.
  ///
  /// In es, this message translates to:
  /// **'Abre los ajustes de NEXA'**
  String get permSinUbicPaso1;

  /// No description provided for @permSinUbicPaso2.
  ///
  /// In es, this message translates to:
  /// **'Toca Permisos → Ubicación'**
  String get permSinUbicPaso2;

  /// No description provided for @permSinUbicPaso3.
  ///
  /// In es, this message translates to:
  /// **'Elige «Permitir mientras se usa la app»'**
  String get permSinUbicPaso3;

  /// No description provided for @permSinUbicPermitir.
  ///
  /// In es, this message translates to:
  /// **'Permitir ubicación'**
  String get permSinUbicPermitir;

  /// No description provided for @permSinUbicAjustes.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get permSinUbicAjustes;

  /// No description provided for @segPlanoCanal.
  ///
  /// In es, this message translates to:
  /// **'Ubicación de NEXA'**
  String get segPlanoCanal;

  /// No description provided for @segPlanoEnLineaTitulo.
  ///
  /// In es, this message translates to:
  /// **'En línea'**
  String get segPlanoEnLineaTitulo;

  /// No description provided for @segPlanoEnLineaTexto.
  ///
  /// In es, this message translates to:
  /// **'Buscando solicitudes cerca de ti'**
  String get segPlanoEnLineaTexto;

  /// No description provided for @segPlanoViajeTitulo.
  ///
  /// In es, this message translates to:
  /// **'Viaje en curso'**
  String get segPlanoViajeTitulo;

  /// No description provided for @segPlanoViajeTexto.
  ///
  /// In es, this message translates to:
  /// **'Compartiendo tu ubicación con el pasajero'**
  String get segPlanoViajeTexto;

  /// No description provided for @segPlanoPasajeroTitulo.
  ///
  /// In es, this message translates to:
  /// **'Tu conductor va en camino'**
  String get segPlanoPasajeroTitulo;

  /// No description provided for @segPlanoPasajeroTexto.
  ///
  /// In es, this message translates to:
  /// **'Compartimos tu ubicación para que te encuentre'**
  String get segPlanoPasajeroTexto;

  /// No description provided for @avisoRecoger.
  ///
  /// In es, this message translates to:
  /// **'Recoge a {nombre}'**
  String avisoRecoger(String nombre);

  /// No description provided for @avisoEsperando.
  ///
  /// In es, this message translates to:
  /// **'Esperando a {nombre}'**
  String avisoEsperando(String nombre);

  /// No description provided for @avisoEnElPunto.
  ///
  /// In es, this message translates to:
  /// **'Estás en el punto de recogida'**
  String get avisoEnElPunto;

  /// No description provided for @avisoLlevando.
  ///
  /// In es, this message translates to:
  /// **'Llevando a {nombre}'**
  String avisoLlevando(String nombre);

  /// No description provided for @avisoEtaDistancia.
  ///
  /// In es, this message translates to:
  /// **'{minutos} min · {distancia}'**
  String avisoEtaDistancia(int minutos, String distancia);

  /// No description provided for @avisoConductorVa.
  ///
  /// In es, this message translates to:
  /// **'{nombre} va por ti'**
  String avisoConductorVa(String nombre);

  /// No description provided for @avisoLlegaEn.
  ///
  /// In es, this message translates to:
  /// **'Llega en {minutos} min'**
  String avisoLlegaEn(int minutos);

  /// No description provided for @avisoElPasajero.
  ///
  /// In es, this message translates to:
  /// **'el pasajero'**
  String get avisoElPasajero;

  /// No description provided for @avisoTuConductor.
  ///
  /// In es, this message translates to:
  /// **'Tu conductor'**
  String get avisoTuConductor;

  /// No description provided for @avisoAbrir.
  ///
  /// In es, this message translates to:
  /// **'Abrir'**
  String get avisoAbrir;

  /// No description provided for @pushVer.
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get pushVer;

  /// No description provided for @pushAceptar.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get pushAceptar;

  /// No description provided for @pushSolicitudNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Esa solicitud ya no está disponible.'**
  String get pushSolicitudNoDisponible;

  /// No description provided for @mapaGirarConTelefono.
  ///
  /// In es, this message translates to:
  /// **'Girar el mapa con el teléfono'**
  String get mapaGirarConTelefono;

  /// No description provided for @mapaVolverNorte.
  ///
  /// In es, this message translates to:
  /// **'Volver al norte'**
  String get mapaVolverNorte;

  /// No description provided for @mapaCalibrarBrujula.
  ///
  /// In es, this message translates to:
  /// **'Mueve el teléfono en forma de 8 para calibrar la brújula. Mientras, el norte queda arriba.'**
  String get mapaCalibrarBrujula;

  /// No description provided for @mapaSinBrujula.
  ///
  /// In es, this message translates to:
  /// **'Tu teléfono no tiene brújula: el mapa gira solo cuando vas en marcha.'**
  String get mapaSinBrujula;

  /// No description provided for @navegacionActivar.
  ///
  /// In es, this message translates to:
  /// **'Navegar'**
  String get navegacionActivar;

  /// No description provided for @navegacionSalir.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get navegacionSalir;

  /// No description provided for @avisoBuscandoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Buscando conductor'**
  String get avisoBuscandoTitulo;

  /// No description provided for @avisoBuscandoTexto.
  ///
  /// In es, this message translates to:
  /// **'Te avisamos apenas un conductor acepte'**
  String get avisoBuscandoTexto;

  /// No description provided for @avisoBuscandoHacia.
  ///
  /// In es, this message translates to:
  /// **'Hacia {destino}'**
  String avisoBuscandoHacia(String destino);

  /// No description provided for @sinConexionBanda.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión · reintentando'**
  String get sinConexionBanda;

  /// No description provided for @pendienteLlegue.
  ///
  /// In es, this message translates to:
  /// **'Llegué'**
  String get pendienteLlegue;

  /// No description provided for @pendienteIniciar.
  ///
  /// In es, this message translates to:
  /// **'Iniciar viaje'**
  String get pendienteIniciar;

  /// No description provided for @pendienteFinalizar.
  ///
  /// In es, this message translates to:
  /// **'Finalizar viaje'**
  String get pendienteFinalizar;

  /// No description provided for @pendienteDeEnviar.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de enviar: se registrará con su hora al volver la señal'**
  String get pendienteDeEnviar;

  /// No description provided for @finalPendienteTexto.
  ///
  /// In es, this message translates to:
  /// **'Viaje finalizado sin señal. El cobro final aparecerá al volver la conexión.'**
  String get finalPendienteTexto;

  /// No description provided for @copiaDelViaje.
  ///
  /// In es, this message translates to:
  /// **'Sin señal: mostramos la última copia del viaje'**
  String get copiaDelViaje;

  /// No description provided for @sinConexionUltimoDato.
  ///
  /// In es, this message translates to:
  /// **'último dato hace {minutos} min'**
  String sinConexionUltimoDato(int minutos);

  /// No description provided for @sinConexionRechazo.
  ///
  /// In es, this message translates to:
  /// **'No se registró «{accion}»: {motivo}'**
  String sinConexionRechazo(String accion, String motivo);

  /// No description provided for @faseAceptado.
  ///
  /// In es, this message translates to:
  /// **'Aceptado'**
  String get faseAceptado;

  /// No description provided for @faseEnCamino.
  ///
  /// In es, this message translates to:
  /// **'En camino'**
  String get faseEnCamino;

  /// No description provided for @faseEnElPunto.
  ///
  /// In es, this message translates to:
  /// **'En el punto'**
  String get faseEnElPunto;

  /// No description provided for @llegaEnMin.
  ///
  /// In es, this message translates to:
  /// **'Llega en {min} min'**
  String llegaEnMin(int min);

  /// No description provided for @vaHaciaTuPunto.
  ///
  /// In es, this message translates to:
  /// **'{nombre} va hacia tu punto de recogida'**
  String vaHaciaTuPunto(String nombre);

  /// No description provided for @estaEnTuPunto.
  ///
  /// In es, this message translates to:
  /// **'{nombre} está en tu punto'**
  String estaEnTuPunto(String nombre);

  /// No description provided for @llegasEnMinHora.
  ///
  /// In es, this message translates to:
  /// **'Llegas en {min} min · {hora}'**
  String llegasEnMinHora(int min, String hora);

  /// No description provided for @vasHacia.
  ///
  /// In es, this message translates to:
  /// **'Vas hacia {destino}'**
  String vasHacia(String destino);

  /// No description provided for @ladoDeFrente.
  ///
  /// In es, this message translates to:
  /// **'Lo tienes de frente'**
  String get ladoDeFrente;

  /// No description provided for @ladoDerecha.
  ///
  /// In es, this message translates to:
  /// **'Viene por tu derecha'**
  String get ladoDerecha;

  /// No description provided for @ladoIzquierda.
  ///
  /// In es, this message translates to:
  /// **'Viene por tu izquierda'**
  String get ladoIzquierda;

  /// No description provided for @ladoDetras.
  ///
  /// In es, this message translates to:
  /// **'Viene por detrás de ti'**
  String get ladoDetras;

  /// No description provided for @buscaEstaPlaca.
  ///
  /// In es, this message translates to:
  /// **'Busca esta placa'**
  String get buscaEstaPlaca;

  /// No description provided for @esperaSinCosto.
  ///
  /// In es, this message translates to:
  /// **'Espera sin costo'**
  String get esperaSinCosto;

  /// No description provided for @esperaSinCostoTexto.
  ///
  /// In es, this message translates to:
  /// **'Después se cobra un recargo por minuto, con un tope.'**
  String get esperaSinCostoTexto;

  /// No description provided for @buscandoTuConductor.
  ///
  /// In es, this message translates to:
  /// **'Buscando tu conductor'**
  String get buscandoTuConductor;

  /// No description provided for @buscandoTexto.
  ///
  /// In es, this message translates to:
  /// **'Avisamos a los conductores cerca de ti. Si nadie acepta, ampliamos el radio.'**
  String get buscandoTexto;

  /// No description provided for @avisamosA.
  ///
  /// In es, this message translates to:
  /// **'Avisamos a {n} conductores cerca de ti. Si nadie acepta, ampliamos el radio.'**
  String avisamosA(int n);

  /// No description provided for @llegarMasRapido.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres llegar más rápido?'**
  String get llegarMasRapido;

  /// No description provided for @llegarMasRapidoTexto.
  ///
  /// In es, this message translates to:
  /// **'Suma un extra para el conductor: tu solicitud se adelanta una ola.'**
  String get llegarMasRapidoTexto;

  /// No description provided for @topeExtra.
  ///
  /// In es, this message translates to:
  /// **'Tope {valor}'**
  String topeExtra(String valor);

  /// No description provided for @totalConExtra.
  ///
  /// In es, this message translates to:
  /// **'Total con extra'**
  String get totalConExtra;

  /// No description provided for @cancelarSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Cancelar solicitud'**
  String get cancelarSolicitud;

  /// No description provided for @pagasEnEfectivo.
  ///
  /// In es, this message translates to:
  /// **'Pagas en efectivo'**
  String get pagasEnEfectivo;

  /// No description provided for @pagasEnEfectivoExtra.
  ///
  /// In es, this message translates to:
  /// **'Pagas en efectivo · incluye {extra} extra'**
  String pagasEnEfectivoExtra(String extra);

  /// No description provided for @kmRecorridos.
  ///
  /// In es, this message translates to:
  /// **'{km} km recorridos'**
  String kmRecorridos(String km);

  /// No description provided for @kmPorRecorrer.
  ///
  /// In es, this message translates to:
  /// **'{km} km por recorrer'**
  String kmPorRecorrer(String km);

  /// No description provided for @compartirViaje.
  ///
  /// In es, this message translates to:
  /// **'Compartir viaje'**
  String get compartirViaje;

  /// No description provided for @sos.
  ///
  /// In es, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @nivelViajes.
  ///
  /// In es, this message translates to:
  /// **'Nivel {nivel} · {viajes}'**
  String nivelViajes(int nivel, String viajes);

  /// No description provided for @nivelPalabra.
  ///
  /// In es, this message translates to:
  /// **'Nivel'**
  String get nivelPalabra;

  /// No description provided for @porKm.
  ///
  /// In es, this message translates to:
  /// **'{valor} por km'**
  String porKm(String valor);

  /// No description provided for @extra.
  ///
  /// In es, this message translates to:
  /// **'extra'**
  String get extra;

  /// No description provided for @ahoraNo.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get ahoraNo;

  /// No description provided for @pasajeraNivel.
  ///
  /// In es, this message translates to:
  /// **'pasajero nivel {n}'**
  String pasajeraNivel(int n);

  /// No description provided for @cobra.
  ///
  /// In es, this message translates to:
  /// **'Cobra'**
  String get cobra;

  /// No description provided for @esperandoA.
  ///
  /// In es, this message translates to:
  /// **'Esperando a {nombre}'**
  String esperandoA(String nombre);

  /// No description provided for @esperaConductorTexto.
  ///
  /// In es, this message translates to:
  /// **'Tras unos minutos de espera, el servidor suma un recargo por minuto a tu favor.'**
  String get esperaConductorTexto;

  /// No description provided for @finalizarLejosAviso.
  ///
  /// In es, this message translates to:
  /// **'Si finalizas lejos del destino, se cobra según lo recorrido.'**
  String get finalizarLejosAviso;

  /// No description provided for @cobraAEnEfectivo.
  ///
  /// In es, this message translates to:
  /// **'Cobra a {nombre} en efectivo'**
  String cobraAEnEfectivo(String nombre);

  /// No description provided for @tuGanancia.
  ///
  /// In es, this message translates to:
  /// **'Tu ganancia'**
  String get tuGanancia;

  /// No description provided for @incluyeExtra.
  ///
  /// In es, this message translates to:
  /// **'Incluye extra voluntario'**
  String get incluyeExtra;

  /// No description provided for @conectateTexto.
  ///
  /// In es, this message translates to:
  /// **'Activa «En línea» arriba para recibir solicitudes.'**
  String get conectateTexto;

  /// No description provided for @factor_ACEPTACION_LENTA.
  ///
  /// In es, this message translates to:
  /// **'Tardaron en aceptar'**
  String get factor_ACEPTACION_LENTA;

  /// No description provided for @factor_LLEGADA_TARDE.
  ///
  /// In es, this message translates to:
  /// **'Tardó en llegar a recogerme'**
  String get factor_LLEGADA_TARDE;

  /// No description provided for @factor_DEJO_ANTES_DEL_DESTINO.
  ///
  /// In es, this message translates to:
  /// **'Me dejó antes del destino'**
  String get factor_DEJO_ANTES_DEL_DESTINO;

  /// No description provided for @factor_PRECIO.
  ///
  /// In es, this message translates to:
  /// **'El precio o el cobro'**
  String get factor_PRECIO;

  /// No description provided for @factor_RUTA_LARGA.
  ///
  /// In es, this message translates to:
  /// **'La ruta fue más larga'**
  String get factor_RUTA_LARGA;

  /// No description provided for @factor_CONDUCCION.
  ///
  /// In es, this message translates to:
  /// **'La forma de conducir'**
  String get factor_CONDUCCION;

  /// No description provided for @factor_ACEPTACION_RAPIDA.
  ///
  /// In es, this message translates to:
  /// **'Aceptaron rápido'**
  String get factor_ACEPTACION_RAPIDA;

  /// No description provided for @factor_LLEGO_A_TIEMPO.
  ///
  /// In es, this message translates to:
  /// **'Llegó a tiempo'**
  String get factor_LLEGO_A_TIEMPO;

  /// No description provided for @factor_BUEN_PRECIO.
  ///
  /// In es, this message translates to:
  /// **'Buen precio'**
  String get factor_BUEN_PRECIO;

  /// No description provided for @factor_BUENA_RUTA.
  ///
  /// In es, this message translates to:
  /// **'Buena ruta'**
  String get factor_BUENA_RUTA;

  /// No description provided for @factor_CONDUCCION_SEGURA.
  ///
  /// In es, this message translates to:
  /// **'Conducción segura'**
  String get factor_CONDUCCION_SEGURA;

  /// No description provided for @factor_AMABLE.
  ///
  /// In es, this message translates to:
  /// **'Amable'**
  String get factor_AMABLE;

  /// No description provided for @queEstuvoBien.
  ///
  /// In es, this message translates to:
  /// **'¿Qué estuvo bien?'**
  String get queEstuvoBien;

  /// No description provided for @queFallo.
  ///
  /// In es, this message translates to:
  /// **'¿Qué falló?'**
  String get queFallo;

  /// No description provided for @puedesMarcarVarios.
  ///
  /// In es, this message translates to:
  /// **'Puedes marcar varios'**
  String get puedesMarcarVarios;

  /// No description provided for @comoTeFueCon.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te fue con {nombre}?'**
  String comoTeFueCon(String nombre);

  /// No description provided for @calificarOpcional.
  ///
  /// In es, this message translates to:
  /// **'Calificar es opcional · solo tú ves lo que marcas'**
  String get calificarOpcional;

  /// No description provided for @llegaste.
  ///
  /// In es, this message translates to:
  /// **'¡Llegaste!'**
  String get llegaste;

  /// No description provided for @calificarA.
  ///
  /// In es, this message translates to:
  /// **'Calificar a {nombre}'**
  String calificarA(String nombre);

  /// No description provided for @totalPagado.
  ///
  /// In es, this message translates to:
  /// **'Total pagado'**
  String get totalPagado;

  /// No description provided for @enEfectivo.
  ///
  /// In es, this message translates to:
  /// **'En efectivo'**
  String get enEfectivo;

  /// No description provided for @descuentoNivelN.
  ///
  /// In es, this message translates to:
  /// **'Descuento nivel {n}'**
  String descuentoNivelN(int n);

  /// No description provided for @extraPara.
  ///
  /// In es, this message translates to:
  /// **'Extra para {nombre}'**
  String extraPara(String nombre);

  /// No description provided for @comentarioOpcional.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos algo más (opcional)'**
  String get comentarioOpcional;

  /// No description provided for @excelente.
  ///
  /// In es, this message translates to:
  /// **'Excelente'**
  String get excelente;

  /// No description provided for @nivelFaltan.
  ///
  /// In es, this message translates to:
  /// **'Nivel {nivel} · te faltan {xp} XP para el {siguiente}'**
  String nivelFaltan(int nivel, int xp, int siguiente);

  /// No description provided for @navActividad.
  ///
  /// In es, this message translates to:
  /// **'Actividad'**
  String get navActividad;

  /// No description provided for @estrellasDe5.
  ///
  /// In es, this message translates to:
  /// **'{n} de 5 estrellas'**
  String estrellasDe5(int n);

  /// No description provided for @tramoHoy.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get tramoHoy;

  /// No description provided for @tramoSemana.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get tramoSemana;

  /// No description provided for @tramoAntes.
  ///
  /// In es, this message translates to:
  /// **'Antes'**
  String get tramoAntes;

  /// No description provided for @filtroTodos.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get filtroTodos;

  /// No description provided for @filtroCompletados.
  ///
  /// In es, this message translates to:
  /// **'Completados'**
  String get filtroCompletados;

  /// No description provided for @filtroCancelados.
  ///
  /// In es, this message translates to:
  /// **'Cancelados'**
  String get filtroCancelados;

  /// No description provided for @viajesN.
  ///
  /// In es, this message translates to:
  /// **'viajes'**
  String get viajesN;

  /// No description provided for @gastadoEsteMes.
  ///
  /// In es, this message translates to:
  /// **'este mes'**
  String get gastadoEsteMes;

  /// No description provided for @buscaUnDestino.
  ///
  /// In es, this message translates to:
  /// **'Busca un destino'**
  String get buscaUnDestino;

  /// No description provided for @tuNivel.
  ///
  /// In es, this message translates to:
  /// **'Tu nivel'**
  String get tuNivel;

  /// No description provided for @tuNivelSub.
  ///
  /// In es, this message translates to:
  /// **'Se calcula con tu XP de los últimos 90 días'**
  String get tuNivelSub;

  /// No description provided for @nivelesSub.
  ///
  /// In es, this message translates to:
  /// **'Viaja, suma XP y desbloquea beneficios'**
  String get nivelesSub;

  /// No description provided for @seccionCuenta.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get seccionCuenta;

  /// No description provided for @ultimosViajes.
  ///
  /// In es, this message translates to:
  /// **'Últimos viajes'**
  String get ultimosViajes;

  /// No description provided for @planeaTuViaje.
  ///
  /// In es, this message translates to:
  /// **'Planea tu viaje'**
  String get planeaTuViaje;

  /// No description provided for @pagasAlLlegar.
  ///
  /// In es, this message translates to:
  /// **'Pagas al conductor al llegar'**
  String get pagasAlLlegar;

  /// No description provided for @llegasALas.
  ///
  /// In es, this message translates to:
  /// **'llegas {hora}'**
  String llegasALas(String hora);

  /// No description provided for @lema.
  ///
  /// In es, this message translates to:
  /// **'Tu ciudad, a tu ritmo.'**
  String get lema;

  /// No description provided for @ciudadPais.
  ///
  /// In es, this message translates to:
  /// **'Cartagena · Colombia'**
  String get ciudadPais;

  /// No description provided for @factor_ESPERA_EN_EL_PUNTO.
  ///
  /// In es, this message translates to:
  /// **'Me hizo esperar en el punto'**
  String get factor_ESPERA_EN_EL_PUNTO;

  /// No description provided for @factor_PUNTO_DIFICIL.
  ///
  /// In es, this message translates to:
  /// **'El punto de recogida era difícil'**
  String get factor_PUNTO_DIFICIL;

  /// No description provided for @factor_PAGO.
  ///
  /// In es, this message translates to:
  /// **'Problemas con el pago o el recargo'**
  String get factor_PAGO;

  /// No description provided for @factor_TRATO.
  ///
  /// In es, this message translates to:
  /// **'El trato'**
  String get factor_TRATO;

  /// No description provided for @factor_LISTO_A_TIEMPO.
  ///
  /// In es, this message translates to:
  /// **'Estaba listo a tiempo'**
  String get factor_LISTO_A_TIEMPO;

  /// No description provided for @factor_PUNTO_CLARO.
  ///
  /// In es, this message translates to:
  /// **'Punto de recogida claro'**
  String get factor_PUNTO_CLARO;

  /// No description provided for @factor_PAGO_SIN_PROBLEMAS.
  ///
  /// In es, this message translates to:
  /// **'Pagó sin problemas'**
  String get factor_PAGO_SIN_PROBLEMAS;

  /// No description provided for @calificarOpcionalConductor.
  ///
  /// In es, this message translates to:
  /// **'Calificar es opcional · {nombre} no verá lo que marques'**
  String calificarOpcionalConductor(String nombre);

  /// No description provided for @calificar.
  ///
  /// In es, this message translates to:
  /// **'Calificar'**
  String get calificar;

  /// No description provided for @ganasMonto.
  ///
  /// In es, this message translates to:
  /// **'Ganas {monto}'**
  String ganasMonto(String monto);

  /// No description provided for @olaDe.
  ///
  /// In es, this message translates to:
  /// **'Ola {ola} de {total}'**
  String olaDe(int ola, int total);

  /// No description provided for @olaDeRadio.
  ///
  /// In es, this message translates to:
  /// **'Ola {ola} de {total} · radio {km} km'**
  String olaDeRadio(int ola, int total, String km);

  /// No description provided for @nadieAcepto.
  ///
  /// In es, this message translates to:
  /// **'Nadie aceptó todavía'**
  String get nadieAcepto;

  /// No description provided for @nadieAceptoTexto.
  ///
  /// In es, this message translates to:
  /// **'Avisamos a {n} conductores en {km} km. A esta hora hay poca oferta cerca de ti.'**
  String nadieAceptoTexto(int n, String km);

  /// No description provided for @cancelarSinCargo.
  ///
  /// In es, this message translates to:
  /// **'Cancelar sin cargo'**
  String get cancelarSinCargo;

  /// No description provided for @calibraBrujula.
  ///
  /// In es, this message translates to:
  /// **'Calibra la brújula'**
  String get calibraBrujula;

  /// No description provided for @calibraBrujulaTexto.
  ///
  /// In es, this message translates to:
  /// **'El metal y los imanes cercanos desvían el rumbo. Mueve el teléfono dibujando un 8 en el aire, 3 veces.'**
  String get calibraBrujulaTexto;

  /// No description provided for @precisionRumbo.
  ///
  /// In es, this message translates to:
  /// **'Precisión del rumbo'**
  String get precisionRumbo;

  /// No description provided for @precisionBaja.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get precisionBaja;

  /// No description provided for @precisionMedia.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get precisionMedia;

  /// No description provided for @precisionAlta.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get precisionAlta;

  /// No description provided for @calibraBrujulaNota.
  ///
  /// In es, this message translates to:
  /// **'Si no mejora, NEXA usa la dirección en la que te mueves.'**
  String get calibraBrujulaNota;

  /// No description provided for @navGiraDerecha.
  ///
  /// In es, this message translates to:
  /// **'Gira a la derecha'**
  String get navGiraDerecha;

  /// No description provided for @navGiraIzquierda.
  ///
  /// In es, this message translates to:
  /// **'Gira a la izquierda'**
  String get navGiraIzquierda;

  /// No description provided for @navLigeraDerecha.
  ///
  /// In es, this message translates to:
  /// **'Ligeramente a la derecha'**
  String get navLigeraDerecha;

  /// No description provided for @navLigeraIzquierda.
  ///
  /// In es, this message translates to:
  /// **'Ligeramente a la izquierda'**
  String get navLigeraIzquierda;

  /// No description provided for @navDaLaVuelta.
  ///
  /// In es, this message translates to:
  /// **'Da la vuelta'**
  String get navDaLaVuelta;

  /// No description provided for @navSigueRecto.
  ///
  /// In es, this message translates to:
  /// **'Sigue derecho'**
  String get navSigueRecto;

  /// No description provided for @navLlegasA.
  ///
  /// In es, this message translates to:
  /// **'Llegas a {lugar}'**
  String navLlegasA(String lugar);

  /// No description provided for @navHaciaPunto.
  ///
  /// In es, this message translates to:
  /// **'Hacia el punto de {nombre}'**
  String navHaciaPunto(String nombre);

  /// No description provided for @navVuelveARuta.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a la ruta'**
  String get navVuelveARuta;

  /// No description provided for @navLuego.
  ///
  /// In es, this message translates to:
  /// **'Luego'**
  String get navLuego;

  /// No description provided for @sinConexionGuardamos.
  ///
  /// In es, this message translates to:
  /// **'Sigue el viaje: guardamos todo en tu teléfono'**
  String get sinConexionGuardamos;

  /// No description provided for @ayer.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get ayer;

  /// No description provided for @sinNotificacionesDetalle.
  ///
  /// In es, this message translates to:
  /// **'Aquí verás los avisos de tus viajes: cuando te aceptan, cuando llega tu conductor y cuando termina.'**
  String get sinNotificacionesDetalle;

  /// No description provided for @notificacionesSub.
  ///
  /// In es, this message translates to:
  /// **'Avisos de tus viajes'**
  String get notificacionesSub;

  /// No description provided for @splashFirma.
  ///
  /// In es, this message translates to:
  /// **'una app de'**
  String get splashFirma;

  /// No description provided for @onb4Titulo.
  ///
  /// In es, this message translates to:
  /// **'Cada viaje te sube de nivel.'**
  String get onb4Titulo;

  /// No description provided for @onb4Texto.
  ///
  /// In es, this message translates to:
  /// **'Ganas XP y pagas hasta 5 % menos. Desde el nivel 2 te recogen primero.'**
  String get onb4Texto;

  /// No description provided for @onbPaso.
  ///
  /// In es, this message translates to:
  /// **'{n} DE {total}'**
  String onbPaso(int n, int total);

  /// No description provided for @onbPaginaSemantica.
  ///
  /// In es, this message translates to:
  /// **'Página {n} de {total}'**
  String onbPaginaSemantica(int n, int total);

  /// No description provided for @onbArtePrecio.
  ///
  /// In es, this message translates to:
  /// **'Precio claro'**
  String get onbArtePrecio;

  /// No description provided for @onbArtePrecioDetalle.
  ///
  /// In es, this message translates to:
  /// **'antes de pedir'**
  String get onbArtePrecioDetalle;

  /// No description provided for @onbArteTu.
  ///
  /// In es, this message translates to:
  /// **'Tú'**
  String get onbArteTu;

  /// No description provided for @onbArteEnVivo.
  ///
  /// In es, this message translates to:
  /// **'En vivo'**
  String get onbArteEnVivo;

  /// No description provided for @onbArteDescuento.
  ///
  /// In es, this message translates to:
  /// **'−{n} %'**
  String onbArteDescuento(int n);

  /// No description provided for @onbDocLicencia.
  ///
  /// In es, this message translates to:
  /// **'Licencia'**
  String get onbDocLicencia;

  /// No description provided for @onbDocSoat.
  ///
  /// In es, this message translates to:
  /// **'SOAT'**
  String get onbDocSoat;

  /// No description provided for @onbDocTecno.
  ///
  /// In es, this message translates to:
  /// **'Tecnomecánica'**
  String get onbDocTecno;

  /// No description provided for @onbDocTarjeta.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta de propiedad'**
  String get onbDocTarjeta;

  /// No description provided for @satNotas.
  ///
  /// In es, this message translates to:
  /// **'notas'**
  String get satNotas;

  /// No description provided for @satRedTitulo.
  ///
  /// In es, this message translates to:
  /// **'Así decide la red'**
  String get satRedTitulo;

  /// No description provided for @satRedNota.
  ///
  /// In es, this message translates to:
  /// **'Cada viaje entra con sus {n} variables y sale como dos probabilidades de no quedar satisfecho: la del pasajero y la del conductor.'**
  String satRedNota(int n);

  /// No description provided for @satRedEntrenando.
  ///
  /// In es, this message translates to:
  /// **'Entrenando: las señales doradas son los ajustes que viajan hacia atrás.'**
  String get satRedEntrenando;

  /// No description provided for @satRedVariables.
  ///
  /// In es, this message translates to:
  /// **'{n} variables'**
  String satRedVariables(int n);

  /// No description provided for @satRedSemantica.
  ///
  /// In es, this message translates to:
  /// **'Esquema de la red neuronal: {n} variables de entrada, dos capas comunes y una rama para cada lado.'**
  String satRedSemantica(int n);

  /// No description provided for @nivelesRuta.
  ///
  /// In es, this message translates to:
  /// **'Tu ruta'**
  String get nivelesRuta;

  /// No description provided for @nivelesRutaPasajero.
  ///
  /// In es, this message translates to:
  /// **'Cada parada está a su distancia real en XP. Debajo, el descuento de ese nivel.'**
  String get nivelesRutaPasajero;

  /// No description provided for @nivelesRutaConductor.
  ///
  /// In es, this message translates to:
  /// **'Cada parada está a su distancia real en XP. Debajo, la comisión de NEXA en ese nivel.'**
  String get nivelesRutaConductor;

  /// No description provided for @deslizaAceptar.
  ///
  /// In es, this message translates to:
  /// **'Desliza para aceptar'**
  String get deslizaAceptar;

  /// No description provided for @solicitudSegundos.
  ///
  /// In es, this message translates to:
  /// **'{n} s'**
  String solicitudSegundos(int n);

  /// No description provided for @solicitudSigue.
  ///
  /// In es, this message translates to:
  /// **'Sigue disponible'**
  String get solicitudSigue;

  /// No description provided for @llegueFaltan.
  ///
  /// In es, this message translates to:
  /// **'Faltan {distancia} para poder marcar que llegaste'**
  String llegueFaltan(String distancia);

  /// No description provided for @llegueEnPunto.
  ///
  /// In es, this message translates to:
  /// **'Estás en el punto: ya puedes marcar que llegaste'**
  String get llegueEnPunto;

  /// No description provided for @sosManten.
  ///
  /// In es, this message translates to:
  /// **'Mantén presionado para llamar'**
  String get sosManten;

  /// No description provided for @sosSuelta.
  ///
  /// In es, this message translates to:
  /// **'Sigue presionando · suelta para cancelar'**
  String get sosSuelta;

  /// No description provided for @sosLlamarSemantica.
  ///
  /// In es, this message translates to:
  /// **'Llamar a emergencias {numero}'**
  String sosLlamarSemantica(String numero);

  /// No description provided for @satPorDia.
  ///
  /// In es, this message translates to:
  /// **'Por día'**
  String get satPorDia;

  /// No description provided for @satPorSemana.
  ///
  /// In es, this message translates to:
  /// **'Por semana'**
  String get satPorSemana;

  /// No description provided for @satPorMes.
  ///
  /// In es, this message translates to:
  /// **'Por mes'**
  String get satPorMes;

  /// No description provided for @satUnaNota.
  ///
  /// In es, this message translates to:
  /// **'1 nota'**
  String get satUnaNota;

  /// No description provided for @satVariasNotas.
  ///
  /// In es, this message translates to:
  /// **'{n} notas'**
  String satVariasNotas(String n);

  /// No description provided for @satTramosDias.
  ///
  /// In es, this message translates to:
  /// **'días'**
  String get satTramosDias;

  /// No description provided for @satTramosSemanas.
  ///
  /// In es, this message translates to:
  /// **'semanas'**
  String get satTramosSemanas;

  /// No description provided for @satTramosMeses.
  ///
  /// In es, this message translates to:
  /// **'meses'**
  String get satTramosMeses;

  /// No description provided for @satPocosTramos.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay datos para ver una tendencia: hacen falta notas en al menos dos {tramos} del período.'**
  String satPocosTramos(String tramos);

  /// No description provided for @satPuntoDebil.
  ///
  /// In es, this message translates to:
  /// **'Punto hueco: menos de {n} notas, tómalo con cuidado.'**
  String satPuntoDebil(String n);

  /// No description provided for @satSemanticaSerie.
  ///
  /// In es, this message translates to:
  /// **'Satisfacción {agrupacion}. Último tramo con notas, {tramo}: pasajeros {pasajero}, conductores {conductor}.'**
  String satSemanticaSerie(
    String agrupacion,
    String tramo,
    String pasajero,
    String conductor,
  );
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
