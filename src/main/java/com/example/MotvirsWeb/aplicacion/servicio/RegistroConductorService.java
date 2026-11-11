package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.servicio.DocumentosConductorService.ArchivoSubido;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.Vehiculo;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.example.MotvirsWeb.dominio.repositorio.VehiculoRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

/**
 * Registro completo de un conductor: cuenta (pendiente de aprobación), su primer vehículo y las fotos de sus
 * documentos. Si algo falla a mitad de camino se deshace lo creado, para no dejar registros a medias.
 */
@Service
@RequiredArgsConstructor
public class RegistroConductorService {

    private static final Logger log = LoggerFactory.getLogger(RegistroConductorService.class);

    private final AuthService authService;
    private final UsuarioRepository usuarioRepository;
    private final VehiculoRepository vehiculoRepository;
    private final DocumentosConductorService documentos;

    public record Solicitud(String nombre, String email, String password, String telefono, long licencia,
                            String placa, String marca, String modelo, String color,
                            long tarjetaPropiedad, long soat, long tecnomecanica,
                            List<ArchivoSubido> fotos) {
    }

    public Conductor registrar(Solicitud s) {
        String placa = s.placa().toUpperCase();
        if (vehiculoRepository.findByPlaca(placa).isPresent()) {
            throw new IllegalStateException("La placa " + placa + " ya está registrada en el sistema");
        }
        // Antes de crear nada: las 4 fotos tienen que estar y ser válidas.
        documentos.validarConjunto(s.fotos());

        Conductor conductor = authService.registrarConductor(s.nombre(), s.email(), s.password(), s.telefono(),
                s.licencia(), s.soat(), s.tarjetaPropiedad());
        Vehiculo vehiculo = null;
        try {
            // Un conductor puede tener varios vehículos, pero solo uno activo a la vez: el primero nace activo.
            vehiculo = vehiculoRepository.save(Vehiculo.builder()
                    .placa(placa)
                    .marca(s.marca())
                    .modelo(s.modelo())
                    .color(s.color())
                    .tecnomecanicaId(s.tecnomecanica())
                    .conductorAsignado(conductor)
                    .activo(true)
                    .fechaRegistro(LocalDate.now())
                    .build());
            conductor.agregarVehiculo(vehiculo);
            conductor = (Conductor) usuarioRepository.save(conductor);

            List<ArchivoSubido> fotos = s.fotos().stream().map(f -> new ArchivoSubido(f.tipo(),
                    numeroDeclarado(f, s), f.nombreOriginal(), f.tamano(), f.abridor())).toList();
            documentos.guardarTodos(conductor.getIdString(), vehiculo.getId(), fotos);
            return conductor;
        } catch (RuntimeException e) {
            deshacer(conductor, vehiculo);
            throw e;
        }
    }

    /** El número que se contrastará con la foto: el del formulario según el tipo de documento. */
    private static String numeroDeclarado(ArchivoSubido f, Solicitud s) {
        return switch (f.tipo()) {
            case LICENCIA -> String.valueOf(s.licencia());
            case TARJETA_PROPIEDAD -> String.valueOf(s.tarjetaPropiedad());
            case SOAT -> String.valueOf(s.soat());
            case TECNOMECANICA -> String.valueOf(s.tecnomecanica());
        };
    }

    private void deshacer(Conductor conductor, Vehiculo vehiculo) {
        try {
            documentos.eliminarDeConductor(conductor.getIdString());
            if (vehiculo != null && vehiculo.getId() != null) {
                vehiculoRepository.deleteById(vehiculo.getId());
            }
            usuarioRepository.deleteById(conductor.getIdString());
        } catch (RuntimeException ex) {
            log.error("No se pudo deshacer un registro de conductor incompleto: {}", ex.getClass().getSimpleName());
        }
    }
}
