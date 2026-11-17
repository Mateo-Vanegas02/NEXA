package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.example.MotvirsWeb.dominio.repositorio.VehiculoRepository;
import org.springframework.security.core.userdetails.UserDetailsService;
import com.example.MotvirsWeb.aplicacion.puerto.NotificadorTiempoReal;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.modelo.Rol;
import com.example.MotvirsWeb.dominio.modelo.Usuario;

@Service
@RequiredArgsConstructor
public class AuthService {

    // Logger para registrar errores del socket sin detener la app
    private static final Logger logger = LoggerFactory.getLogger(AuthService.class);

    private final UsuarioRepository usuarioRepository;
    private final VehiculoRepository vehiculoRepository;
    private final PasswordEncoder passwordEncoder;
    private final UserDetailsService customUserDetailsService;
    private final NotificadorTiempoReal notificadorTiempoReal;

    /**
     * Registra un nuevo usuario en el sistema - Versión mejorada y optimizada
     */
    public Usuario registrarUsuario(String email, String password, Rol rol, String nombre) {
        // 1. Creación de la instancia (Factory)
        Usuario usuario = Usuario.crearUsuario(rol, email, usuarioRepository);

        // 2. Asignación de datos (Antes de guardar)
        usuario.setPassword(passwordEncoder.encode(password));

        // Campos específicos por tipo de usuario
        if (usuario instanceof Pasajero pasajero) {
            pasajero.setNombreCompleto(nombre);
        } else if (usuario instanceof Conductor conductor) {
            conductor.setNombre_y_Apellido(nombre);
        }

        Usuario usuarioGuardado = usuarioRepository.save(usuario);
        enviarNotificacionAdminSegura(usuarioGuardado);

        return usuarioGuardado;
    }

    public Pasajero registrarPasajero(String nombreCompleto, String email,
            String telefono, String password) {
        if (usuarioRepository.findByEmailAndRol(email, Rol.PASAJERO).isPresent()) {
            throw new IllegalStateException("Ya existe un pasajero registrado con este email: " + email);
        }

        Pasajero pasajero = Pasajero.builder()
                .email(email)
                .password(passwordEncoder.encode(password))
                .rol(Rol.PASAJERO)
                .estadoValidacion(EstadoValidacion.APROBADO)
                .nombreCompleto(nombreCompleto)
                .telefono(telefono)
                .build();

        Pasajero pasajeroGuardado;
        try {
            pasajeroGuardado = usuarioRepository.save(pasajero);
        } catch (DuplicateKeyException e) {
            throw new IllegalStateException("Ya existe una cuenta con esos datos", e);
        }
        enviarNotificacionAdminSegura(pasajeroGuardado);
        return pasajeroGuardado;
    }

    public Conductor registrarConductor(String nombre, String email, String password,
            String telefono, long licencia, Long soat, Long tarjetaPropiedad) {
        // Validaciones de unicidad
        if (usuarioRepository.findByEmailAndRol(email, Rol.CONDUCTOR).isPresent()) {
            throw new IllegalStateException("Ya existe un conductor registrado con este email: " + email);
        }

        // La licencia debe ser única entre conductores
        if (usuarioRepository.existsByRolAndLicencia(Rol.CONDUCTOR, licencia)) {
            throw new IllegalStateException("El número de licencia ya está registrado en el sistema");
        }

        // Validar que el SOAT sea único
        if (soat != null && usuarioRepository.existsByRolAndSoat(Rol.CONDUCTOR, soat)) {
            throw new IllegalStateException("El número SOAT ya está registrado en el sistema");
        }

        // Construcción del objeto
        Conductor conductor = Conductor.builder()
                .email(email)
                .password(passwordEncoder.encode(password))
                .rol(Rol.CONDUCTOR)
                .estadoValidacion(EstadoValidacion.PENDIENTE)
                .nombre_y_Apellido(nombre)
                .ntelefono(Long.parseLong(telefono))
                .licencia(licencia)
                .soat(soat)
                .tarjeta_de_propiedad(tarjetaPropiedad)
                .build();

        // Guardado en BD
        Conductor conductorGuardado;
        try {
            conductorGuardado = usuarioRepository.save(conductor);
        } catch (DuplicateKeyException e) {
            throw new IllegalStateException("Ya existe un conductor con esos datos", e);
        }

        // Notificación al Admin (Socket)
        enviarNotificacionAdminSegura(conductorGuardado);

        return conductorGuardado;
    }

    /**
     * Método auxiliar para manejar la notificación sin romper el flujo de registro
     * si el socket falla.
     */
    // Método seguro para sockets
    private void enviarNotificacionAdminSegura(Usuario usuario) {
        try {
            notificadorTiempoReal.notificarNuevoRegistroAdmin(usuario);
        } catch (Exception e) {
            logger.error("Error socket admin: {}", e.getMessage());
        }
    }

    public UserDetails autenticarUsuario(String email, String password) {
        try {
            UserDetails userDetails = customUserDetailsService.loadUserByUsername(email);

            if (!passwordEncoder.matches(password, userDetails.getPassword())) {
                throw new BadCredentialsException("Credenciales inválidas");
            }

            return userDetails;
        } catch (UsernameNotFoundException e) {
            throw new BadCredentialsException("Credenciales inválidas", e);
        }
    }
}
