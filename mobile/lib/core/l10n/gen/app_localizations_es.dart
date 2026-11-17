// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appNombre => 'NEXA';

  @override
  String get reintentar => 'Reintentar';

  @override
  String get cancelar => 'Cancelar';

  @override
  String get continuar => 'Continuar';

  @override
  String get omitir => 'Omitir';

  @override
  String get empezar => 'Empezar';

  @override
  String get guardar => 'Guardar';

  @override
  String get cerrarSesion => 'Cerrar sesión';

  @override
  String get cargando => 'Cargando…';

  @override
  String get errorGenerico => 'Algo salió mal';

  @override
  String get vacioHistorial => 'Aún no tienes viajes';

  @override
  String get vacioHistorialDetalle =>
      'Cuando completes un viaje aparecerá aquí.';

  @override
  String get onb1Titulo => 'El precio, antes de pedir.';

  @override
  String get onb1Texto =>
      'Ves cuánto pagas y cuánto tarda. Sin regateo ni sorpresas al llegar.';

  @override
  String get onb2Titulo => 'Conductores con papeles al día.';

  @override
  String get onb2Texto =>
      'Una persona de NEXA revisa licencia, SOAT, tecnomecánica y tarjeta de propiedad antes del primer viaje.';

  @override
  String get onb3Titulo => 'Tu viaje, en vivo.';

  @override
  String get onb3Texto =>
      'Sigues la moto en el mapa, con la placa y los minutos que faltan.';

  @override
  String get loginTitulo => 'Hola de nuevo';

  @override
  String get loginSubtitulo => 'Entra con el correo de tu cuenta NEXA.';

  @override
  String get email => 'Correo';

  @override
  String get password => 'Contraseña';

  @override
  String get confirmarPassword => 'Confirmar contraseña';

  @override
  String get ingresar => 'Entrar';

  @override
  String get noTienesCuenta => '¿No tienes cuenta? Regístrate';

  @override
  String get noTienesCuentaPregunta => '¿No tienes cuenta?';

  @override
  String get yaTienesCuenta => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get registroTitulo => 'Crea tu cuenta';

  @override
  String get soy => 'Quiero usar NEXA como';

  @override
  String get rolPasajero => 'Pasajero';

  @override
  String get rolConductor => 'Conductor';

  @override
  String get rolAdmin => 'Administrador';

  @override
  String get loginCuenta => 'Tipo de cuenta';

  @override
  String get loginCuentaUnica => 'Cuenta única';

  @override
  String get nombreCompleto => 'Nombre completo';

  @override
  String get telefono => 'Teléfono (10 dígitos, empieza con 3)';

  @override
  String get crearCuenta => 'Crear cuenta';

  @override
  String get campoRequerido => 'Este campo es obligatorio';

  @override
  String get emailInvalido => 'Correo electrónico inválido';

  @override
  String get passwordCorta => 'Mínimo 8 caracteres';

  @override
  String get passwordNoCoincide => 'Las contraseñas no coinciden';

  @override
  String get telefonoInvalido => 'Teléfono colombiano inválido';

  @override
  String get registroConductorWeb =>
      'El registro de conductores requiere verificación de documentos. Completa el registro en la web de NEXA; la app solo permite crear cuentas de pasajero por ahora.';

  @override
  String get navInicio => 'Inicio';

  @override
  String get navViajes => 'Viajes';

  @override
  String get navNiveles => 'Niveles';

  @override
  String get navPerfil => 'Perfil';

  @override
  String get navGanancias => 'Ganancias';

  @override
  String get navSolicitudes => 'Solicitudes';

  @override
  String get adondeVas => '¿A dónde vas?';

  @override
  String get destinoHint => 'Toca el mapa para elegir el destino';

  @override
  String get origenActual => 'Tu ubicación';

  @override
  String get nombreDestino => 'Nombre del destino';

  @override
  String get solicitarViaje => 'Solicitar viaje';

  @override
  String get estimadoTarifa => 'Estimado de tarifa';

  @override
  String get distancia => 'Distancia';

  @override
  String get tarifaBase => 'Tarifa';

  @override
  String get total => 'Total';

  @override
  String get metodoPago => 'Método de pago';

  @override
  String get efectivo => 'Efectivo';

  @override
  String get tarifaEstimadaAviso =>
      'Estimado. El total final lo calcula NEXA al finalizar el viaje.';

  @override
  String get buscandoConductor => 'Buscando conductor…';

  @override
  String get conductorEnCamino => 'Tu conductor va en camino';

  @override
  String get enViaje => 'Viaje en curso';

  @override
  String get viajeFinalizado => 'Viaje finalizado';

  @override
  String get viajeCancelado => 'Viaje cancelado';

  @override
  String get cancelarViaje => 'Cancelar viaje';

  @override
  String get calificaTuViaje => 'Califica tu viaje';

  @override
  String get comentarios => 'Comentarios (opcional)';

  @override
  String get enviarCalificacion => 'Enviar calificación';

  @override
  String get gracias => '¡Gracias por calificar!';

  @override
  String get historial => 'Historial de viajes';

  @override
  String get perfil => 'Perfil';

  @override
  String get estado_SOLICITADO => 'Solicitado';

  @override
  String get estado_ACEPTADO => 'Aceptado';

  @override
  String get estado_EN_CURSO => 'En curso';

  @override
  String get estado_FINALIZADO => 'Finalizado';

  @override
  String get estado_CANCELADO => 'Cancelado';

  @override
  String get nivelesTitulo => 'Tus niveles';

  @override
  String nivelActual(String nombre) {
    return 'Nivel $nombre';
  }

  @override
  String xpProgreso(int actual, int meta) {
    return '$actual / $meta XP';
  }

  @override
  String get nivelMaximo => 'Nivel máximo alcanzado';

  @override
  String faltanXp(int xp, String siguiente) {
    return 'Te faltan $xp XP para el nivel $siguiente';
  }

  @override
  String get beneficios => 'Beneficios';

  @override
  String beneficioBloqueado(int nivel) {
    return 'Se desbloquea en nivel $nivel';
  }

  @override
  String xpGanado(int n) {
    return 'Ganaste $n XP';
  }

  @override
  String get subisteNivel => '¡Subiste de nivel!';

  @override
  String ahoraEres(String nombre) {
    return 'Subiste al nivel $nombre';
  }

  @override
  String get genial => '¡Genial!';

  @override
  String barraNivelSemantica(String nombre, int porcentaje) {
    return 'Nivel $nombre, $porcentaje por ciento hacia el siguiente nivel';
  }

  @override
  String get enLinea => 'En línea';

  @override
  String get fueraDeLinea => 'Fuera de línea';

  @override
  String get estasEnLinea =>
      'Mantén la app abierta: las solicitudes aparecen aquí con lo que cobras.';

  @override
  String get estasFueraDeLinea => 'Estás fuera de línea';

  @override
  String get solicitudesEntrantes => 'Solicitudes entrantes';

  @override
  String get sinSolicitudes => 'No hay solicitudes por ahora';

  @override
  String get aceptar => 'Aceptar';

  @override
  String get rechazar => 'Rechazar';

  @override
  String get yendoAPasajero => 'En camino al pasajero';

  @override
  String get iniciarViaje => 'Iniciar viaje';

  @override
  String get finalizarViaje => 'Finalizar viaje';

  @override
  String get viajeActivo => 'Viaje activo';

  @override
  String get gananciasTitulo => 'Ganancias';

  @override
  String get gananciaTotal => 'Total ganado';

  @override
  String get comisionActual => 'Comisión actual';

  @override
  String get comisionSiguiente => 'Comisión siguiente nivel';

  @override
  String get requisitosCalidad => 'Requisitos de calidad';

  @override
  String get bloqueadoCalidad =>
      'Tienes los XP necesarios, pero te falta cumplir la calidad.';

  @override
  String get calificacion => 'Calificación';

  @override
  String get aceptacion => 'Aceptación';

  @override
  String get cancelacion => 'Cancelación';

  @override
  String get pendienteTitulo => 'Cuenta en revisión';

  @override
  String get pendienteTexto =>
      'Un administrador está verificando tus documentos. Te avisaremos cuando tu cuenta esté aprobada; mientras tanto no puedes recibir viajes.';

  @override
  String get rechazadoTexto =>
      'Tu solicitud fue rechazada. Contacta a soporte de NEXA.';

  @override
  String get conductorNoSoportado =>
      'Tu cuenta de conductor aún no puede iniciar sesión desde la app (pendiente en el backend).';

  @override
  String get iniciarSesion => 'Iniciar sesión';

  @override
  String get solicitaAhora => 'Solicita ahora';

  @override
  String get registrate => 'Regístrate';

  @override
  String get homeBadge => 'Servicio de MotoTaxis';

  @override
  String get homeHero => 'Conecta con el movimiento';

  @override
  String get homeSubtitulo =>
      '¡Tu destino te espera! Viajes rápidos, seguros y accesibles en dos ruedas.';

  @override
  String get servicios => 'Servicios';

  @override
  String get serviciosSub => 'Todo lo que puedes hacer en NEXA';

  @override
  String get svcReservaTitulo => 'Reserva de viajes';

  @override
  String get svcReservaTexto => 'Elige destino y tipo de moto en segundos.';

  @override
  String get svcRastreoTitulo => 'Rastreo en vivo';

  @override
  String get svcRastreoTexto => 'Sigue a tu conductor en tiempo real.';

  @override
  String get svcCalifTitulo => 'Calificaciones';

  @override
  String get svcCalifTexto => 'Califica y comenta cada viaje.';

  @override
  String get svcPagosTitulo => 'Pagos seguros';

  @override
  String get svcPagosTexto => 'Efectivo, tarjeta o billetera digital.';

  @override
  String get abrirMenu => 'Abrir menú';

  @override
  String get saludoManana => 'Buenos días';

  @override
  String get saludoTarde => 'Buenas tardes';

  @override
  String get saludoNoche => 'Buenas noches';

  @override
  String get buscadorHint => '¿A dónde vas hoy?';

  @override
  String get ahora => 'Ahora';

  @override
  String get pedirViaje => 'Pedir viaje';

  @override
  String get historialCorto => 'Historial';

  @override
  String get viajesRecientes => 'Viajes recientes';

  @override
  String get verTodo => 'Ver todo';

  @override
  String viajesCantidad(int n) {
    return '$n viajes';
  }

  @override
  String get notificaciones => 'Notificaciones';

  @override
  String get sinNotificaciones => 'No tienes notificaciones nuevas';

  @override
  String get aDondeVamos => '¿A dónde vamos?';

  @override
  String get origen => 'Recogida';

  @override
  String get miUbicacion => 'Mi ubicación';

  @override
  String get destino => 'Destino';

  @override
  String get tiempoEstimado => 'Tiempo est.';

  @override
  String minutosValor(int n) {
    return '$n min';
  }

  @override
  String get precioSugerido => 'Precio sugerido · ajustable';

  @override
  String get aumentarPrecio => 'Aumentar precio';

  @override
  String get disminuirPrecio => 'Disminuir precio';

  @override
  String get cambiar => 'Cambiar';

  @override
  String get volver => 'Volver';

  @override
  String get centrarUbicacion => 'Centrar en mi ubicación';

  @override
  String get editarDestino => 'Editar destino';

  @override
  String get viajeEnCursoTitulo => 'Viaje en curso';

  @override
  String llegadaEstimada(String hora) {
    return 'Llegada estimada $hora';
  }

  @override
  String get paso_solicitado => 'Solicitado';

  @override
  String get paso_aceptado => 'Aceptado';

  @override
  String get paso_en_curso => 'En curso';

  @override
  String get paso_finalizado => 'Finalizado';

  @override
  String get placa => 'Placa';

  @override
  String viajesCantidadCorto(int n) {
    return '$n viajes';
  }

  @override
  String get llamar => 'Llamar';

  @override
  String get mensaje => 'Mensaje';

  @override
  String get compartir => 'Compartir';

  @override
  String compartirTexto(String destino, String conductor) {
    return 'Voy en un viaje NEXA hacia $destino. Conductor: $conductor.';
  }

  @override
  String get asistenciaRuta => 'Asistencia en ruta (SOS)';

  @override
  String get sosTitulo => '¿Necesitas ayuda?';

  @override
  String get sosTexto =>
      'Mantén presionado el botón y llamaremos a la línea de emergencias 123.';

  @override
  String get noDisponible => 'No disponible para este conductor';

  @override
  String get viajeFinalizadoTitulo => 'Viaje finalizado';

  @override
  String get llegasteDestino => '¡Llegaste a tu destino!';

  @override
  String duracionMin(int n) {
    return '$n min';
  }

  @override
  String get calificaExperiencia => 'Califica tu experiencia';

  @override
  String comoCalificarias(String nombre) {
    return '¿Cómo calificarías a $nombre?';
  }

  @override
  String get calif1 => 'Muy malo';

  @override
  String get calif2 => 'Malo';

  @override
  String get calif3 => 'Regular';

  @override
  String get calif4 => 'Bueno';

  @override
  String get calif5 => 'Excelente';

  @override
  String califDe5(String texto, int n) {
    return '$texto - $n de 5';
  }

  @override
  String get etiquetaSegura => 'Conducción segura';

  @override
  String get etiquetaPuntual => 'Puntual';

  @override
  String get etiquetaAmable => 'Amable';

  @override
  String get etiquetaMoto => 'Moto en buen estado';

  @override
  String get etiquetaCasco => 'Casco limpio';

  @override
  String get comentarioHint => 'Déjanos un comentario opcional…';

  @override
  String get omitirPorAhora => 'Omitir por ahora';

  @override
  String get cerrar => 'Cerrar';

  @override
  String get tuConductor => 'Tu conductor';

  @override
  String get metodoTarjeta => 'Tarjeta';

  @override
  String get metodoBilletera => 'Billetera digital';

  @override
  String get verDesglose => 'Ver desglose';

  @override
  String get destinoSeleccionado => 'Destino seleccionado';

  @override
  String get nombreInvalido => 'Solo letras y espacios (3 a 100 caracteres)';

  @override
  String get passwordDebil => 'Debe incluir mayúscula, minúscula y número';

  @override
  String get bienvenidaTitulo => '¡Bienvenido a NEXA!';

  @override
  String bienvenidaNombre(String nombre) {
    return '¡Hola, $nombre!';
  }

  @override
  String get bienvenidaPasajero =>
      'Pide tu mototaxi, sigue tu viaje y sube de nivel con cada recorrido.';

  @override
  String get bienvenidaConductor =>
      'Conéctate para recibir solicitudes y mejora tu comisión con cada viaje.';

  @override
  String get vamos => '¡Vamos!';

  @override
  String get cancelarViajeTitulo => '¿Cancelar el viaje?';

  @override
  String get cancelarViajeTexto => 'Tu conductor dejará de ir hacia ti.';

  @override
  String get mantenerViaje => 'Mantener viaje';

  @override
  String get cuentaYaExiste => 'Ya existe una cuenta con ese correo.';

  @override
  String get puntoEnMapa => 'Punto en el mapa';

  @override
  String get sinResultados =>
      'Sin resultados. Toca el mapa para elegir el punto.';

  @override
  String get usarMiUbicacion => 'Usar mi ubicación';

  @override
  String get borrar => 'Borrar';

  @override
  String get origenHint => 'Busca el origen o toca el mapa';

  @override
  String get buscandoLugares => 'Buscando…';

  @override
  String get editarPerfil => 'Editar perfil';

  @override
  String get perfilActualizado => 'Perfil actualizado';

  @override
  String get cambiarFoto => 'Cambiar foto';

  @override
  String get tomarFoto => 'Tomar foto';

  @override
  String get elegirGaleria => 'Elegir de la galería';

  @override
  String get quitarFoto => 'Quitar foto';

  @override
  String get fotoActualizada => 'Foto actualizada';

  @override
  String get fotoQuitada => 'Foto eliminada';

  @override
  String get registroConductorTitulo => 'Registro de conductor';

  @override
  String get registroConductorIntro =>
      'Completa tus datos y fotografía tus documentos. Un administrador los revisará y, cuando te aprueben, podrás iniciar sesión.';

  @override
  String get registroConductorBoton => 'Registrarme como conductor';

  @override
  String get seccionDatos => 'Tus datos';

  @override
  String get seccionVehiculo => 'Tu moto';

  @override
  String get seccionDocumentos => 'Documentos';

  @override
  String get licencia => 'Número de licencia de conducción';

  @override
  String get tarjetaPropiedad => 'Número de tarjeta de propiedad';

  @override
  String get soat => 'Número de SOAT (12 dígitos)';

  @override
  String get tecnomecanica => 'Número de tecnomecánica';

  @override
  String get marca => 'Marca';

  @override
  String get modelo => 'Modelo';

  @override
  String get color => 'Color';

  @override
  String get docLicencia => 'Foto de la licencia';

  @override
  String get docTarjeta => 'Foto de la tarjeta de propiedad';

  @override
  String get docSoat => 'Foto del SOAT';

  @override
  String get docTecno => 'Foto de la tecnomecánica';

  @override
  String get agregarFoto => 'Agregar foto';

  @override
  String get fotoLista => 'Foto lista · toca para cambiarla';

  @override
  String get faltaFoto => 'Adjunta la foto de este documento';

  @override
  String get enviarSolicitud => 'Enviar solicitud';

  @override
  String get yaTengoCuenta => 'Ya tengo cuenta';

  @override
  String pasoDe(int n, int total) {
    return 'Paso $n de $total';
  }

  @override
  String get registroPaso1Sub => '¿Cómo quieres usar NEXA?';

  @override
  String get rolViajar => 'Viajar';

  @override
  String get rolViajarSub => 'Pide motos y sube de nivel';

  @override
  String get rolConducir => 'Conducir';

  @override
  String get rolConducirSub => 'Gana con tu moto. Pide tus documentos.';

  @override
  String get registroPaso2Titulo => 'Elige tu contraseña';

  @override
  String get registroPaso2Sub => 'La usarás para entrar a tu cuenta.';

  @override
  String get docsTitulo => 'Tus documentos';

  @override
  String docsListos(int n, int total) {
    return '$n de $total listos';
  }

  @override
  String docsFaltan(int n) {
    return 'Faltan $n para enviar tu solicitud.';
  }

  @override
  String get docsCompletos => 'Todo listo para enviar tu solicitud.';

  @override
  String pedirNexa(String precio) {
    return 'Pedir NEXA · $precio';
  }

  @override
  String get pedirNexaSinPrecio => 'Pedir NEXA';

  @override
  String get tuRuta => 'Tu ruta';

  @override
  String get fijarEnMapa => 'Fijar en el mapa';

  @override
  String get resultadosCerca => 'Resultados';

  @override
  String get buscarLugarHint => 'Busca una dirección o un lugar';

  @override
  String get tocaMapaDestino => 'Toca el mapa para fijar tu destino';

  @override
  String get tocaMapaOrigen => 'Toca el mapa para fijar tu origen';

  @override
  String get nuevaSolicitud => 'Nueva solicitud';

  @override
  String get faseARecoger => 'A recoger';

  @override
  String get faseEnPunto => 'En el punto';

  @override
  String get faseEnViaje => 'En viaje';

  @override
  String get conectarme => 'Conectarme';

  @override
  String get desconectarme => 'Desconectarme';

  @override
  String get buscandoSolicitudes => 'Buscando solicitudes cerca de ti';

  @override
  String get gananciaPorViaje => 'Ganancia por viaje';

  @override
  String get estasAqui => 'Estás aquí';

  @override
  String get inactividadNota => 'Si pasas 90 días sin viajar bajas un nivel.';

  @override
  String get statViajes => 'viajes';

  @override
  String get statCalificacion => 'calificación';

  @override
  String get statNivel => 'nivel';

  @override
  String get editarPerfilSub => 'Nombre y celular';

  @override
  String get ofertaAhora => 'Tu oferta ahora';

  @override
  String get ocultarDesglose => 'Ocultar desglose';

  @override
  String ahorroNivel(String monto) {
    return 'Tu nivel te ahorra $monto en este viaje';
  }

  @override
  String get motoNexa => 'Moto NEXA';

  @override
  String nivelDescuento(String nivel, int pct) {
    return 'Nivel $nivel · $pct % de descuento';
  }

  @override
  String get solicitudEnviada => 'Solicitud enviada';

  @override
  String get solicitudEnviadaMsg =>
      'Un administrador revisará tus documentos. Podrás iniciar sesión cuando te aprueben.';

  @override
  String get errorFoto => 'No se pudo leer la foto. Intenta de nuevo.';

  @override
  String get licenciaInvalida => 'Debe tener entre 6 y 15 dígitos';

  @override
  String get tarjetaInvalida => 'Debe tener entre 8 y 15 dígitos';

  @override
  String get soatInvalido => 'Debe tener 12 dígitos';

  @override
  String get tecnoInvalida => 'Debe tener entre 6 y 15 dígitos';

  @override
  String get placaInvalida => 'La placa debe tener 6 caracteres (ej: ABC123)';

  @override
  String get textoInvalido => 'Valor no válido';

  @override
  String get regPlaca => 'Placa (ej: ABC123)';

  @override
  String get descuentoNivel => 'Descuento por nivel';

  @override
  String get cargoPendiente => 'Cargo pendiente por cancelación';

  @override
  String get aceptoCargo => 'Acepto que este cargo se cobre con mi viaje';

  @override
  String get cotizando => 'Calculando el precio…';

  @override
  String get tarifaServidorAviso =>
      'Precio calculado por NEXA según la ruta por calles. Lo pagas al terminar el viaje.';

  @override
  String get recargoEspera => 'Recargo por espera';

  @override
  String get extraVoluntario => 'Extra voluntario';

  @override
  String get extraTitulo => '¿Tarda en llegar un conductor?';

  @override
  String get extraTexto =>
      'Suma un extra voluntario para que tu solicitud llegue antes a los conductores.';

  @override
  String get deudaAnterior => 'Cargo anterior';

  @override
  String get errorCotizar => 'No se pudo calcular el precio. Intenta de nuevo.';

  @override
  String get llegueAlPunto => 'Llegué';

  @override
  String get esperandoPasajero => 'Esperando al pasajero';

  @override
  String get distanciaPasajero => 'Distancia del pasajero a la recogida';

  @override
  String get cobraAlPasajero => 'Cobra al pasajero';

  @override
  String get viajeTerminado => 'Viaje finalizado';

  @override
  String get finalizarAntesTitulo => '¿Finalizar antes del destino?';

  @override
  String get finalizarAntesTexto =>
      'Aún no llegas al destino. Si finalizas ahora, el cobro será según lo recorrido.';

  @override
  String get finalizarDeTodosModos => 'Finalizar de todos modos';

  @override
  String get cancelarViajeConductorTitulo => '¿Cancelar este viaje?';

  @override
  String get cancelarViajeConductorTexto =>
      'El pasajero será avisado de la cancelación.';

  @override
  String get pasajeroCancelo => 'El pasajero canceló el viaje.';

  @override
  String get saldoConNexa => 'Saldo con NEXA';

  @override
  String get cobradoEfectivo => 'Cobrado en efectivo';

  @override
  String get gananciaPeriodo => 'Ganado';

  @override
  String get cargosAFavor => 'Cargos a tu favor';

  @override
  String get viajesPeriodo => 'Viajes';

  @override
  String get debesANexa => 'Debes a NEXA';

  @override
  String get nexaTeDebe => 'NEXA te debe';

  @override
  String get sinUbicacion =>
      'No pudimos obtener tu ubicación. Activa el GPS e inténtalo de nuevo.';

  @override
  String get ultimos30Dias => 'Últimos 30 días';

  @override
  String get listo => 'Listo';

  @override
  String get ventajasActuales => 'Tus ventajas actuales';

  @override
  String get descuentoViajes => 'Descuento en tus viajes';

  @override
  String get prioridadRecogida => 'Prioridad de recogida';

  @override
  String get sinVentajas =>
      'Sube de nivel para ganar descuento y prioridad en tus viajes.';

  @override
  String get adminRol => 'Administrador';

  @override
  String get adminConductores => 'Conductores';

  @override
  String get adminProximamente => 'Próximamente';

  @override
  String get adminProximamenteDetalle =>
      'Por ahora esta sección está en la web del administrador.';

  @override
  String get satEyebrow => 'Admin · Redes neuronales';

  @override
  String get satTitulo => 'Satisfacción';

  @override
  String get satVerModelo => 'Ver el modelo';

  @override
  String get satPeriodo7 => '7 días';

  @override
  String get satPeriodo30 => '30 días';

  @override
  String get satPeriodo90 => '90 días';

  @override
  String get satPeriodoRango => 'Rango';

  @override
  String get satSinModeloTitulo => 'Sin modelo todavía.';

  @override
  String get satSinModeloTexto =>
      'Las cifras de satisfacción son reales. Los factores y los viajes en riesgo aparecen después del primer entrenamiento con viajes reales.';

  @override
  String get satSinModeloFactores =>
      'Aún no hay un modelo entrenado con viajes reales: entrénalo en Modelo. Las curvas usan las calificaciones reales.';

  @override
  String get satPasajerosSatisfechos => 'Pasajeros satisfechos';

  @override
  String get satConductoresSatisfechos => 'Conductores satisfechos';

  @override
  String get satSinCalificaciones => 'Sin calificaciones';

  @override
  String satVariacion(String valor) {
    return '$valor pts vs. período anterior';
  }

  @override
  String satCalifica(String pct) {
    return 'Califica el $pct';
  }

  @override
  String get satTendencia => 'Tendencia';

  @override
  String satSemanticaTendencia(String pasajero, String conductor) {
    return 'Tendencia semanal. Última semana: pasajeros $pasajero, conductores $conductor.';
  }

  @override
  String get satPasajero => 'Pasajero';

  @override
  String get satConductor => 'Conductor';

  @override
  String get satViajesRiesgo => 'Viajes en riesgo';

  @override
  String get satViajesRiesgoDetalle => 'Sin calificar, probable \"no\"';

  @override
  String get satFactores => 'Factores';

  @override
  String satLoQueMasPesa(String factor) {
    return 'Lo que más pesa: $factor';
  }

  @override
  String get satQuePesaMas => 'Qué pesa más';

  @override
  String get satQuePesaMasDetalle =>
      'Cuánto empeora la predicción si se quita cada factor';

  @override
  String satOtrosFactores(String cantidad, String peso) {
    return '+ $cantidad factores más con menos del $peso';
  }

  @override
  String get satComoCambia => 'Cómo cambia la satisfacción';

  @override
  String get satPorTramoPasajero => '% de pasajeros satisfechos por tramo';

  @override
  String get satPorTramoConductor => '% de conductores satisfechos por tramo';

  @override
  String get satRiesgoIntro =>
      'Viajes sin calificar donde la red predice que la persona no quedó satisfecha. Ordenados por probabilidad.';

  @override
  String get satTodos => 'Todos';

  @override
  String satConteo(String etiqueta, String n) {
    return '$etiqueta · $n';
  }

  @override
  String satViajeTitulo(String id, String fecha) {
    return 'Viaje #$id · $fecha';
  }

  @override
  String satRuta(String origen, String destino, String km) {
    return '$origen → $destino · $km km';
  }

  @override
  String get satProbNo => 'prob. de \"no\"';

  @override
  String satUmbral(String pct) {
    return 'Umbral de alerta: $pct · se ajusta en el modelo';
  }

  @override
  String get satSinRiesgo => 'No hay viajes en riesgo';

  @override
  String get satSinRiesgoDetalle =>
      'Ningún viaje sin calificar supera el umbral de alerta.';

  @override
  String get satModeloEyebrow => 'Red neuronal';

  @override
  String get satModelo => 'Modelo';

  @override
  String satVersionTitulo(String version) {
    return 'Versión $version · TensorFlow';
  }

  @override
  String satEntrenadoInfo(String fecha, String viajes, String variables) {
    return 'Entrenado el $fecha · $viajes viajes · $variables variables';
  }

  @override
  String get satRed => 'Red';

  @override
  String get satRegresion => 'Regresión';

  @override
  String get satResultado => 'Resultado';

  @override
  String get satSupera => 'Supera';

  @override
  String get satNoSupera => 'No supera';

  @override
  String get satMetricaNota =>
      'PR-AUC sobre el 15 % de viajes más recientes. Mientras la red no supere a la regresión, el panel lo advierte.';

  @override
  String get satEntrenarAhora => 'Entrenar ahora';

  @override
  String get satEntrenarFaltanDatos =>
      'Se podrá entrenar cuando haya suficientes calificaciones reales.';

  @override
  String get satEntrenamientoEnCurso => 'Hay un entrenamiento en curso';

  @override
  String get satVer => 'Ver';

  @override
  String get satProgramado => 'Entrenamiento programado';

  @override
  String get satCambiar => 'Cambiar';

  @override
  String get satSinProgramar =>
      'Sin programar: la red solo se entrena cuando lo pidas.';

  @override
  String satProxima(String fecha) {
    return 'Próximo: $fecha';
  }

  @override
  String satProximaDatosNuevos(String fecha, String n) {
    return 'Próximo: $fecha · solo si hay $n viajes nuevos calificados';
  }

  @override
  String satTodosLosDias(String hora) {
    return 'Todos los días · $hora';
  }

  @override
  String satCadaHorasValor(String horas) {
    return 'Cada $horas h';
  }

  @override
  String get satHistorial => 'Historial';

  @override
  String get satManual => 'Manual';

  @override
  String get satProgramadoCorto => 'Programado';

  @override
  String get satEstPublicado => 'Publicado';

  @override
  String get satEstSinPublicar => 'Guardado sin publicar';

  @override
  String get satEstSinDatosNuevos => 'Sin datos nuevos';

  @override
  String get satEstFaltanDatos => 'Faltan datos';

  @override
  String get satEstFallido => 'Falló';

  @override
  String get satEstCancelado => 'Cancelado';

  @override
  String get satEstEnCurso => 'En curso';

  @override
  String get satProgramarTitulo => 'Programar entrenamiento';

  @override
  String get satProgramarDetalle =>
      'La red se entrena en la nube y se publica sola si cumple las condiciones.';

  @override
  String get satFrecuencia => 'Frecuencia';

  @override
  String get satDiaria => 'Diario';

  @override
  String get satSemanal => 'Semanal';

  @override
  String get satCadaHoras => 'Cada N horas';

  @override
  String get satDias => 'Días';

  @override
  String get satDiaLun => 'L';

  @override
  String get satDiaMar => 'M';

  @override
  String get satDiaMie => 'X';

  @override
  String get satDiaJue => 'J';

  @override
  String get satDiaVie => 'V';

  @override
  String get satDiaSab => 'S';

  @override
  String get satDiaDom => 'D';

  @override
  String get satHoraBogota => 'Hora (Bogotá)';

  @override
  String get satIntervalo => 'Intervalo';

  @override
  String get satSoloDatosNuevos => 'Solo con datos nuevos';

  @override
  String satSoloDatosNuevosDetalle(String n) {
    return 'Al menos $n viajes calificados desde el último';
  }

  @override
  String get satPublicarSiMejora => 'Publicar solo si mejora';

  @override
  String get satPublicarSiMejoraDetalle =>
      'Si no supera a la versión actual, se guarda sin usarla';

  @override
  String get satProgramacionInvalida => 'Elige al menos un día.';

  @override
  String get satGuardarProgramacion => 'Guardar programación';

  @override
  String get satProgramacionGuardada => 'Programación guardada';

  @override
  String get satEntrenandoTitulo => 'Entrenando';

  @override
  String get satEntrenamientoTitulo => 'Entrenamiento';

  @override
  String get satEntrenandoRed => 'Entrenando la red';

  @override
  String get satEnCola => 'En cola…';

  @override
  String satEpoca(String epoca, String epocas) {
    return 'Época $epoca de $epocas';
  }

  @override
  String get satPasoExportar => 'Exportar viajes';

  @override
  String get satPasoEntrenar => 'Entrenar la red';

  @override
  String get satPasoEntrenarDetalle => 'TensorFlow · dos salidas';

  @override
  String get satPasoComparar => 'Comparar con la regresión';

  @override
  String get satPasoPublicar => 'Publicar para la app';

  @override
  String get satPuedesSalir =>
      'Puedes salir de esta pantalla: el entrenamiento sigue en la nube. El panel muestra la versión actual hasta que se publique la nueva.';

  @override
  String get satCancelarEntrenamiento => 'Cancelar entrenamiento';

  @override
  String get satVolverPanel => 'Volver al modelo';

  @override
  String get satFinPublicado => 'Nueva versión publicada';

  @override
  String get satFinSinPublicar => 'Se guardó sin publicar';

  @override
  String get satFinSinPublicarDetalle => 'No superó a la versión actual.';

  @override
  String get satFinSinDatosNuevos => 'No había datos nuevos';

  @override
  String get satFinFallido => 'El entrenamiento falló';

  @override
  String get satFinCancelado => 'Entrenamiento cancelado';

  @override
  String get satSinDatosTitulo => 'Aún no hay datos para entrenar';

  @override
  String satMinimoDatos(String calificaciones, String no) {
    return 'La red necesita al menos $calificaciones calificaciones y $no \"no\" por lado. Mientras tanto se muestran las cifras reales de satisfacción.';
  }

  @override
  String get satProgresoDatos => 'Progreso de los datos';

  @override
  String get satCalifPasajeros => 'Calificaciones de pasajeros';

  @override
  String get satNoPasajeros => '\"No\" de pasajeros';

  @override
  String get satCalifConductores => 'Calificaciones de conductores';

  @override
  String get satNoConductores => '\"No\" de conductores';

  @override
  String satConteoDe(String actual, String meta) {
    return '$actual / $meta';
  }

  @override
  String get satConsejoConductores =>
      'Los conductores califican poco. Pedirles la nota al cerrar el viaje acelera el entrenamiento.';

  @override
  String get satEntrenarNoDisponible => 'Entrenar ahora (no disponible)';

  @override
  String get notiCanalSolicitudes => 'Solicitudes de viaje';

  @override
  String get notiCanalSolicitudesDesc =>
      'Nuevas solicitudes cerca de ti mientras estás en línea';

  @override
  String get notiCanalViaje => 'Tu viaje';

  @override
  String get notiCanalViajeDesc =>
      'Conductor en camino, llegada al punto y fin del viaje';

  @override
  String get notiCanalCuenta => 'Tu cuenta';

  @override
  String get notiCanalCuentaDesc => 'Cargos pendientes, nivel y saldo con NEXA';

  @override
  String get permAhoraNo => 'Ahora no';

  @override
  String get permNotiTitulo => 'Te avisamos lo importante del viaje';

  @override
  String get permNotiTexto =>
      'Aunque la app esté cerrada o el teléfono bloqueado.';

  @override
  String get permNotiAcepta => 'Cuando un conductor acepta';

  @override
  String get permNotiAceptaSub => 'Quién va por ti y en qué moto';

  @override
  String get permNotiLlega => 'Cuando llega a tu punto';

  @override
  String get permNotiLlegaSub => 'Con la placa para reconocerlo';

  @override
  String get permNotiCargos => 'Cargos o saldos pendientes';

  @override
  String get permNotiCargosSub => 'Sin sorpresas en tu próximo viaje';

  @override
  String get permNotiSolicitudes => 'Solicitudes cerca de ti';

  @override
  String get permNotiSolicitudesSub => 'Con lo que ganas y la distancia';

  @override
  String get permNotiCancela => 'Si el pasajero cancela';

  @override
  String get permNotiCancelaSub => 'Para que no vayas en vano';

  @override
  String get permNotiPermitir => 'Permitir notificaciones';

  @override
  String get permUbicTitulo => 'Usamos tu ubicación para recogerte';

  @override
  String get permUbicTexto =>
      'Solo mientras usas la app. Sin ella no podemos pedir tu viaje.';

  @override
  String get permUbicTituloConductor => 'Tu ubicación te trae los viajes';

  @override
  String get permUbicTextoConductor =>
      'Las solicitudes se reparten por cercanía: sin ubicación no puedes ponerte en línea.';

  @override
  String get permUbicPunto => 'Punto de recogida exacto';

  @override
  String get permUbicPuntoSub => 'Lo ajustas hasta 300 m de ti';

  @override
  String get permUbicEncuentra => 'El conductor te encuentra';

  @override
  String get permUbicEncuentraSub => 'Ve dónde estás mientras llega';

  @override
  String get permUbicOla => 'Primero las solicitudes cercanas';

  @override
  String get permUbicOlaSub => 'Te llegan antes las de tu zona';

  @override
  String get permUbicLlegada => 'Tiempo de llegada real';

  @override
  String get permUbicLlegadaSub => 'El pasajero ve cuánto te falta';

  @override
  String get permUbicPermitir => 'Permitir al usar la app';

  @override
  String get perm2PlanoTitulo => 'Recibe viajes con la pantalla apagada';

  @override
  String get perm2PlanoTexto =>
      'NEXA usa tu ubicación en segundo plano solo mientras estás en línea o en un viaje, para que no pierdas tu lugar en la ola.';

  @override
  String get perm2PlanoElige => 'En la pantalla siguiente, elige';

  @override
  String get perm2PlanoSiempre => 'Permitir todo el tiempo';

  @override
  String get perm2PlanoAlUsar => 'Permitir solo con la app en uso';

  @override
  String get perm2PlanoNo => 'No permitir';

  @override
  String get perm2PlanoMarca => 'Mi teléfono cierra la app';

  @override
  String get perm2PlanoContinuar => 'Continuar';

  @override
  String get perm2PlanoSin => 'Seguir sin segundo plano';

  @override
  String get permBateriaTitulo => 'Evita que tu teléfono cierre NEXA';

  @override
  String get permBateriaTexto =>
      'Algunas marcas apagan las apps en segundo plano para ahorrar batería. Elige la tuya.';

  @override
  String get permBateriaAbrir => 'Abrir ajustes de NEXA';

  @override
  String get permBateriaOtra => 'Otra marca';

  @override
  String get permBatSamsung1 => 'Ajustes → Apps → NEXA → Batería';

  @override
  String get permBatSamsung2 => 'Elige «Sin restricciones»';

  @override
  String get permBatSamsung3 =>
      'Ajustes → Batería → Límites de uso en segundo plano';

  @override
  String get permBatSamsung4 => 'Quita NEXA de «Apps en suspensión»';

  @override
  String get permBatXiaomi1 => 'Ajustes → Apps → Administrar apps → NEXA';

  @override
  String get permBatXiaomi2 => 'Ahorro de batería → «Sin restricciones»';

  @override
  String get permBatXiaomi3 => 'Activa «Inicio automático»';

  @override
  String get permBatXiaomi4 =>
      'En recientes, deja presionado NEXA y toca el candado';

  @override
  String get permBatMotorola1 => 'Ajustes → Apps → NEXA';

  @override
  String get permBatMotorola2 => 'Batería de la app → «Sin restricciones»';

  @override
  String get permBatMotorola3 => 'Activa «Permitir uso en segundo plano»';

  @override
  String get permBatMotorola4 => 'Vuelve a NEXA y ponte en línea';

  @override
  String get permBatHuawei1 => 'Ajustes → Batería → Inicio de apps';

  @override
  String get permBatHuawei2 =>
      'Busca NEXA y desactiva «Gestionar automáticamente»';

  @override
  String get permBatHuawei3 =>
      'Activa inicio automático, secundario y en segundo plano';

  @override
  String get permBatHuawei4 => 'Vuelve a NEXA y ponte en línea';

  @override
  String get permBatOtra1 => 'Ajustes → Apps → NEXA → Batería';

  @override
  String get permBatOtra2 => 'Elige «Sin restricciones» o «No optimizar»';

  @override
  String get permBatOtra3 => 'Permite el uso en segundo plano';

  @override
  String get permBatOtra4 => 'Vuelve a NEXA y ponte en línea';

  @override
  String get permSinUbicTitulo => 'Sin tu ubicación no podemos pedir el viaje';

  @override
  String get permSinUbicTexto =>
      'La usamos para fijar el punto de recogida y para que el conductor te encuentre. Nunca la compartimos fuera del viaje.';

  @override
  String get permSinUbicTituloConductor =>
      'Sin tu ubicación no puedes ponerte en línea';

  @override
  String get permSinUbicTextoConductor =>
      'La usamos para repartir las solicitudes por cercanía y para que el pasajero vea dónde vienes. Solo mientras estás en línea o en un viaje.';

  @override
  String get permSinUbicPasos => 'Si ya la negaste';

  @override
  String get permSinUbicPaso1 => 'Abre los ajustes de NEXA';

  @override
  String get permSinUbicPaso2 => 'Toca Permisos → Ubicación';

  @override
  String get permSinUbicPaso3 => 'Elige «Permitir mientras se usa la app»';

  @override
  String get permSinUbicPermitir => 'Permitir ubicación';

  @override
  String get permSinUbicAjustes => 'Abrir ajustes';

  @override
  String get segPlanoCanal => 'Ubicación de NEXA';

  @override
  String get segPlanoEnLineaTitulo => 'En línea';

  @override
  String get segPlanoEnLineaTexto => 'Buscando solicitudes cerca de ti';

  @override
  String get segPlanoViajeTitulo => 'Viaje en curso';

  @override
  String get segPlanoViajeTexto => 'Compartiendo tu ubicación con el pasajero';

  @override
  String get segPlanoPasajeroTitulo => 'Tu conductor va en camino';

  @override
  String get segPlanoPasajeroTexto =>
      'Compartimos tu ubicación para que te encuentre';

  @override
  String avisoRecoger(String nombre) {
    return 'Recoge a $nombre';
  }

  @override
  String avisoEsperando(String nombre) {
    return 'Esperando a $nombre';
  }

  @override
  String get avisoEnElPunto => 'Estás en el punto de recogida';

  @override
  String avisoLlevando(String nombre) {
    return 'Llevando a $nombre';
  }

  @override
  String avisoEtaDistancia(int minutos, String distancia) {
    return '$minutos min · $distancia';
  }

  @override
  String avisoConductorVa(String nombre) {
    return '$nombre va por ti';
  }

  @override
  String avisoLlegaEn(int minutos) {
    return 'Llega en $minutos min';
  }

  @override
  String get avisoElPasajero => 'el pasajero';

  @override
  String get avisoTuConductor => 'Tu conductor';

  @override
  String get avisoAbrir => 'Abrir';

  @override
  String get pushVer => 'Ver';

  @override
  String get pushAceptar => 'Aceptar';

  @override
  String get pushSolicitudNoDisponible =>
      'Esa solicitud ya no está disponible.';

  @override
  String get mapaGirarConTelefono => 'Girar el mapa con el teléfono';

  @override
  String get mapaVolverNorte => 'Volver al norte';

  @override
  String get mapaCalibrarBrujula =>
      'Mueve el teléfono en forma de 8 para calibrar la brújula. Mientras, el norte queda arriba.';

  @override
  String get mapaSinBrujula =>
      'Tu teléfono no tiene brújula: el mapa gira solo cuando vas en marcha.';

  @override
  String get navegacionActivar => 'Navegar';

  @override
  String get navegacionSalir => 'Salir';

  @override
  String get avisoBuscandoTitulo => 'Buscando conductor';

  @override
  String get avisoBuscandoTexto => 'Te avisamos apenas un conductor acepte';

  @override
  String avisoBuscandoHacia(String destino) {
    return 'Hacia $destino';
  }

  @override
  String get sinConexionBanda => 'Sin conexión · reintentando';

  @override
  String get pendienteLlegue => 'Llegué';

  @override
  String get pendienteIniciar => 'Iniciar viaje';

  @override
  String get pendienteFinalizar => 'Finalizar viaje';

  @override
  String get pendienteDeEnviar =>
      'Pendiente de enviar: se registrará con su hora al volver la señal';

  @override
  String get finalPendienteTexto =>
      'Viaje finalizado sin señal. El cobro final aparecerá al volver la conexión.';

  @override
  String get copiaDelViaje => 'Sin señal: mostramos la última copia del viaje';

  @override
  String sinConexionUltimoDato(int minutos) {
    return 'último dato hace $minutos min';
  }

  @override
  String sinConexionRechazo(String accion, String motivo) {
    return 'No se registró «$accion»: $motivo';
  }

  @override
  String get faseAceptado => 'Aceptado';

  @override
  String get faseEnCamino => 'En camino';

  @override
  String get faseEnElPunto => 'En el punto';

  @override
  String llegaEnMin(int min) {
    return 'Llega en $min min';
  }

  @override
  String vaHaciaTuPunto(String nombre) {
    return '$nombre va hacia tu punto de recogida';
  }

  @override
  String estaEnTuPunto(String nombre) {
    return '$nombre está en tu punto';
  }

  @override
  String llegasEnMinHora(int min, String hora) {
    return 'Llegas en $min min · $hora';
  }

  @override
  String vasHacia(String destino) {
    return 'Vas hacia $destino';
  }

  @override
  String get ladoDeFrente => 'Lo tienes de frente';

  @override
  String get ladoDerecha => 'Viene por tu derecha';

  @override
  String get ladoIzquierda => 'Viene por tu izquierda';

  @override
  String get ladoDetras => 'Viene por detrás de ti';

  @override
  String get buscaEstaPlaca => 'Busca esta placa';

  @override
  String get esperaSinCosto => 'Espera sin costo';

  @override
  String get esperaSinCostoTexto =>
      'Después se cobra un recargo por minuto, con un tope.';

  @override
  String get buscandoTuConductor => 'Buscando tu conductor';

  @override
  String get buscandoTexto =>
      'Avisamos a los conductores cerca de ti. Si nadie acepta, ampliamos el radio.';

  @override
  String avisamosA(int n) {
    return 'Avisamos a $n conductores cerca de ti. Si nadie acepta, ampliamos el radio.';
  }

  @override
  String get llegarMasRapido => '¿Quieres llegar más rápido?';

  @override
  String get llegarMasRapidoTexto =>
      'Suma un extra para el conductor: tu solicitud se adelanta una ola.';

  @override
  String topeExtra(String valor) {
    return 'Tope $valor';
  }

  @override
  String get totalConExtra => 'Total con extra';

  @override
  String get cancelarSolicitud => 'Cancelar solicitud';

  @override
  String get pagasEnEfectivo => 'Pagas en efectivo';

  @override
  String pagasEnEfectivoExtra(String extra) {
    return 'Pagas en efectivo · incluye $extra extra';
  }

  @override
  String kmRecorridos(String km) {
    return '$km km recorridos';
  }

  @override
  String kmPorRecorrer(String km) {
    return '$km km por recorrer';
  }

  @override
  String get compartirViaje => 'Compartir viaje';

  @override
  String get sos => 'SOS';

  @override
  String nivelViajes(int nivel, String viajes) {
    return 'Nivel $nivel · $viajes';
  }

  @override
  String get nivelPalabra => 'Nivel';

  @override
  String porKm(String valor) {
    return '$valor por km';
  }

  @override
  String get extra => 'extra';

  @override
  String get ahoraNo => 'Ahora no';

  @override
  String pasajeraNivel(int n) {
    return 'pasajero nivel $n';
  }

  @override
  String get cobra => 'Cobra';

  @override
  String esperandoA(String nombre) {
    return 'Esperando a $nombre';
  }

  @override
  String get esperaConductorTexto =>
      'Tras unos minutos de espera, el servidor suma un recargo por minuto a tu favor.';

  @override
  String get finalizarLejosAviso =>
      'Si finalizas lejos del destino, se cobra según lo recorrido.';

  @override
  String cobraAEnEfectivo(String nombre) {
    return 'Cobra a $nombre en efectivo';
  }

  @override
  String get tuGanancia => 'Tu ganancia';

  @override
  String get incluyeExtra => 'Incluye extra voluntario';

  @override
  String get conectateTexto =>
      'Activa «En línea» arriba para recibir solicitudes.';

  @override
  String get factor_ACEPTACION_LENTA => 'Tardaron en aceptar';

  @override
  String get factor_LLEGADA_TARDE => 'Tardó en llegar a recogerme';

  @override
  String get factor_DEJO_ANTES_DEL_DESTINO => 'Me dejó antes del destino';

  @override
  String get factor_PRECIO => 'El precio o el cobro';

  @override
  String get factor_RUTA_LARGA => 'La ruta fue más larga';

  @override
  String get factor_CONDUCCION => 'La forma de conducir';

  @override
  String get factor_ACEPTACION_RAPIDA => 'Aceptaron rápido';

  @override
  String get factor_LLEGO_A_TIEMPO => 'Llegó a tiempo';

  @override
  String get factor_BUEN_PRECIO => 'Buen precio';

  @override
  String get factor_BUENA_RUTA => 'Buena ruta';

  @override
  String get factor_CONDUCCION_SEGURA => 'Conducción segura';

  @override
  String get factor_AMABLE => 'Amable';

  @override
  String get queEstuvoBien => '¿Qué estuvo bien?';

  @override
  String get queFallo => '¿Qué falló?';

  @override
  String get puedesMarcarVarios => 'Puedes marcar varios';

  @override
  String comoTeFueCon(String nombre) {
    return '¿Cómo te fue con $nombre?';
  }

  @override
  String get calificarOpcional =>
      'Calificar es opcional · solo tú ves lo que marcas';

  @override
  String get llegaste => '¡Llegaste!';

  @override
  String calificarA(String nombre) {
    return 'Calificar a $nombre';
  }

  @override
  String get totalPagado => 'Total pagado';

  @override
  String get enEfectivo => 'En efectivo';

  @override
  String descuentoNivelN(int n) {
    return 'Descuento nivel $n';
  }

  @override
  String extraPara(String nombre) {
    return 'Extra para $nombre';
  }

  @override
  String get comentarioOpcional => 'Cuéntanos algo más (opcional)';

  @override
  String get excelente => 'Excelente';

  @override
  String nivelFaltan(int nivel, int xp, int siguiente) {
    return 'Nivel $nivel · te faltan $xp XP para el $siguiente';
  }

  @override
  String get navActividad => 'Actividad';

  @override
  String estrellasDe5(int n) {
    return '$n de 5 estrellas';
  }

  @override
  String get tramoHoy => 'Hoy';

  @override
  String get tramoSemana => 'Esta semana';

  @override
  String get tramoAntes => 'Antes';

  @override
  String get filtroTodos => 'Todos';

  @override
  String get filtroCompletados => 'Completados';

  @override
  String get filtroCancelados => 'Cancelados';

  @override
  String get viajesN => 'viajes';

  @override
  String get gastadoEsteMes => 'este mes';

  @override
  String get buscaUnDestino => 'Busca un destino';

  @override
  String get tuNivel => 'Tu nivel';

  @override
  String get tuNivelSub => 'Se calcula con tu XP de los últimos 90 días';

  @override
  String get nivelesSub => 'Viaja, suma XP y desbloquea beneficios';

  @override
  String get seccionCuenta => 'Cuenta';

  @override
  String get ultimosViajes => 'Últimos viajes';

  @override
  String get planeaTuViaje => 'Planea tu viaje';

  @override
  String get pagasAlLlegar => 'Pagas al conductor al llegar';

  @override
  String llegasALas(String hora) {
    return 'llegas $hora';
  }

  @override
  String get lema => 'Tu ciudad, a tu ritmo.';

  @override
  String get ciudadPais => 'Cartagena · Colombia';

  @override
  String get factor_ESPERA_EN_EL_PUNTO => 'Me hizo esperar en el punto';

  @override
  String get factor_PUNTO_DIFICIL => 'El punto de recogida era difícil';

  @override
  String get factor_PAGO => 'Problemas con el pago o el recargo';

  @override
  String get factor_TRATO => 'El trato';

  @override
  String get factor_LISTO_A_TIEMPO => 'Estaba listo a tiempo';

  @override
  String get factor_PUNTO_CLARO => 'Punto de recogida claro';

  @override
  String get factor_PAGO_SIN_PROBLEMAS => 'Pagó sin problemas';

  @override
  String calificarOpcionalConductor(String nombre) {
    return 'Calificar es opcional · $nombre no verá lo que marques';
  }

  @override
  String get calificar => 'Calificar';

  @override
  String ganasMonto(String monto) {
    return 'Ganas $monto';
  }

  @override
  String olaDe(int ola, int total) {
    return 'Ola $ola de $total';
  }

  @override
  String olaDeRadio(int ola, int total, String km) {
    return 'Ola $ola de $total · radio $km km';
  }

  @override
  String get nadieAcepto => 'Nadie aceptó todavía';

  @override
  String nadieAceptoTexto(int n, String km) {
    return 'Avisamos a $n conductores en $km km. A esta hora hay poca oferta cerca de ti.';
  }

  @override
  String get cancelarSinCargo => 'Cancelar sin cargo';

  @override
  String get calibraBrujula => 'Calibra la brújula';

  @override
  String get calibraBrujulaTexto =>
      'El metal y los imanes cercanos desvían el rumbo. Mueve el teléfono dibujando un 8 en el aire, 3 veces.';

  @override
  String get precisionRumbo => 'Precisión del rumbo';

  @override
  String get precisionBaja => 'Baja';

  @override
  String get precisionMedia => 'Media';

  @override
  String get precisionAlta => 'Alta';

  @override
  String get calibraBrujulaNota =>
      'Si no mejora, NEXA usa la dirección en la que te mueves.';

  @override
  String get navGiraDerecha => 'Gira a la derecha';

  @override
  String get navGiraIzquierda => 'Gira a la izquierda';

  @override
  String get navLigeraDerecha => 'Ligeramente a la derecha';

  @override
  String get navLigeraIzquierda => 'Ligeramente a la izquierda';

  @override
  String get navDaLaVuelta => 'Da la vuelta';

  @override
  String get navSigueRecto => 'Sigue derecho';

  @override
  String navLlegasA(String lugar) {
    return 'Llegas a $lugar';
  }

  @override
  String navHaciaPunto(String nombre) {
    return 'Hacia el punto de $nombre';
  }

  @override
  String get navVuelveARuta => 'Vuelve a la ruta';

  @override
  String get navLuego => 'Luego';

  @override
  String get sinConexionGuardamos =>
      'Sigue el viaje: guardamos todo en tu teléfono';

  @override
  String get ayer => 'Ayer';

  @override
  String get sinNotificacionesDetalle =>
      'Aquí verás los avisos de tus viajes: cuando te aceptan, cuando llega tu conductor y cuando termina.';

  @override
  String get notificacionesSub => 'Avisos de tus viajes';

  @override
  String get splashFirma => 'una app de';

  @override
  String get onb4Titulo => 'Cada viaje te sube de nivel.';

  @override
  String get onb4Texto =>
      'Ganas XP y pagas hasta 5 % menos. Desde el nivel 2 te recogen primero.';

  @override
  String onbPaso(int n, int total) {
    return '$n DE $total';
  }

  @override
  String onbPaginaSemantica(int n, int total) {
    return 'Página $n de $total';
  }

  @override
  String get onbArtePrecio => 'Precio claro';

  @override
  String get onbArtePrecioDetalle => 'antes de pedir';

  @override
  String get onbArteTu => 'Tú';

  @override
  String get onbArteEnVivo => 'En vivo';

  @override
  String onbArteDescuento(int n) {
    return '−$n %';
  }

  @override
  String get onbDocLicencia => 'Licencia';

  @override
  String get onbDocSoat => 'SOAT';

  @override
  String get onbDocTecno => 'Tecnomecánica';

  @override
  String get onbDocTarjeta => 'Tarjeta de propiedad';

  @override
  String get satNotas => 'notas';

  @override
  String get satRedTitulo => 'Así decide la red';

  @override
  String satRedNota(int n) {
    return 'Cada viaje entra con sus $n variables y sale como dos probabilidades de no quedar satisfecho: la del pasajero y la del conductor.';
  }

  @override
  String get satRedEntrenando =>
      'Entrenando: las señales doradas son los ajustes que viajan hacia atrás.';

  @override
  String satRedVariables(int n) {
    return '$n variables';
  }

  @override
  String satRedSemantica(int n) {
    return 'Esquema de la red neuronal: $n variables de entrada, dos capas comunes y una rama para cada lado.';
  }

  @override
  String get nivelesRuta => 'Tu ruta';

  @override
  String get nivelesRutaPasajero =>
      'Cada parada está a su distancia real en XP. Debajo, el descuento de ese nivel.';

  @override
  String get nivelesRutaConductor =>
      'Cada parada está a su distancia real en XP. Debajo, la comisión de NEXA en ese nivel.';

  @override
  String get deslizaAceptar => 'Desliza para aceptar';

  @override
  String solicitudSegundos(int n) {
    return '$n s';
  }

  @override
  String get solicitudSigue => 'Sigue disponible';

  @override
  String llegueFaltan(String distancia) {
    return 'Faltan $distancia para poder marcar que llegaste';
  }

  @override
  String get llegueEnPunto =>
      'Estás en el punto: ya puedes marcar que llegaste';

  @override
  String get sosManten => 'Mantén presionado para llamar';

  @override
  String get sosSuelta => 'Sigue presionando · suelta para cancelar';

  @override
  String sosLlamarSemantica(String numero) {
    return 'Llamar a emergencias $numero';
  }

  @override
  String get satPorDia => 'Por día';

  @override
  String get satPorSemana => 'Por semana';

  @override
  String get satPorMes => 'Por mes';

  @override
  String get satUnaNota => '1 nota';

  @override
  String satVariasNotas(String n) {
    return '$n notas';
  }

  @override
  String get satTramosDias => 'días';

  @override
  String get satTramosSemanas => 'semanas';

  @override
  String get satTramosMeses => 'meses';

  @override
  String satPocosTramos(String tramos) {
    return 'Aún no hay datos para ver una tendencia: hacen falta notas en al menos dos $tramos del período.';
  }

  @override
  String satPuntoDebil(String n) {
    return 'Punto hueco: menos de $n notas, tómalo con cuidado.';
  }

  @override
  String satSemanticaSerie(
    String agrupacion,
    String tramo,
    String pasajero,
    String conductor,
  ) {
    return 'Satisfacción $agrupacion. Último tramo con notas, $tramo: pasajeros $pasajero, conductores $conductor.';
  }
}
