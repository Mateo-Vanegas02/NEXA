package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.servicio.DocumentosConductorService.ArchivoSubido;
import com.example.MotvirsWeb.aplicacion.verificacion.EntradaInvalidaException;
import com.example.MotvirsWeb.aplicacion.verificacion.ValidadorEntradas;
import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Vehiculo;
import com.example.MotvirsWeb.dominio.repositorio.ServicioRepository;
import com.example.MotvirsWeb.dominio.repositorio.UsuarioRepository;
import com.example.MotvirsWeb.dominio.repositorio.VehiculoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;

/**
 * Vehículos del conductor. Solo uno puede estar activo para dar servicio y lo elige el propio
 * conductor; al elegir otro, el anterior queda inactivo. No se cambia con un viaje en curso.
 */
@Service
@RequiredArgsConstructor
public class VehiculoConductorService {

    private final VehiculoRepository vehiculoRepository;
    private final ServicioRepository servicioRepository;
    private final UsuarioRepository usuarioRepository;
    private final DocumentosConductorService documentos;

    private static final int MAX_VEHICULOS = 5;

    /** Datos del vehículo nuevo; los números se contrastan con las fotos que sube el conductor. */
    public record NuevoVehiculo(String placa, String marca, String modelo, String color,
            long tarjetaPropiedad, long soat, long tecnomecanica, List<ArchivoSubido> fotos) {
    }

    /** Lo que ve el conductor de cada vehículo suyo. */
    public record VehiculoResumen(String id, String placa, String marca, String modelo, String color,
            boolean activo, boolean enServicio, LocalDate fechaRegistro, boolean verificado) {
    }

    public List<VehiculoResumen> listar(Conductor conductor) {
        boolean enViaje = tieneViajeEnCurso(conductor);
        return vehiculoRepository.findByConductorAsignado(conductor).stream()
                .sorted(Comparator.comparing(Vehiculo::getFechaRegistro,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .map(v -> resumen(v, enViaje))
                .toList();
    }

    /** Deja activo solo el vehículo elegido. 404 si no es suyo, 409 si está en un viaje. */
    public VehiculoResumen activar(Conductor conductor, String vehiculoId) {
        List<Vehiculo> suyos = vehiculoRepository.findByConductorAsignado(conductor);
        Vehiculo elegido = suyos.stream().filter(v -> v.getId().equals(vehiculoId)).findFirst()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Vehículo no encontrado"));
        if (!elegido.estaVerificado()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Este vehículo está en revisión: podrás usarlo cuando NEXA lo apruebe");
        }
        if (tieneViajeEnCurso(conductor)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "No puedes cambiar de vehículo con un viaje en curso");
        }
        for (Vehiculo v : suyos) {
            boolean debeEstarActivo = v.getId().equals(elegido.getId());
            if (v.isActivo() != debeEstarActivo) {
                v.setActivo(debeEstarActivo);
                vehiculoRepository.save(v);
            }
        }
        return resumen(elegido, false);
    }

    /**
     * Agrega un vehículo con sus fotos. Nace inactivo y pendiente de revisión: no se puede usar hasta que
     * un administrador lo apruebe. Si algo falla se deshace lo creado.
     */
    public VehiculoResumen agregar(Conductor conductor, NuevoVehiculo n) {
        String placa;
        try {
            placa = ValidadorEntradas.placa(n.placa());
        } catch (EntradaInvalidaException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
        }
        String marca = texto(n.marca(), "marca");
        String modelo = texto(n.modelo(), "modelo");
        String color = texto(n.color(), "color");
        if (n.tarjetaPropiedad() <= 0 || n.soat() <= 0 || n.tecnomecanica() <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Los números de los documentos son obligatorios");
        }
        if (vehiculoRepository.findByConductorAsignado(conductor).size() >= MAX_VEHICULOS) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Puedes tener máximo " + MAX_VEHICULOS + " vehículos");
        }
        if (vehiculoRepository.findByPlaca(placa).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "La placa " + placa + " ya está registrada en el sistema");
        }
        List<ArchivoSubido> fotos = n.fotos().stream().map(f -> new ArchivoSubido(f.tipo(), switch (f.tipo()) {
            case TARJETA_PROPIEDAD -> String.valueOf(n.tarjetaPropiedad());
            case SOAT -> String.valueOf(n.soat());
            default -> String.valueOf(n.tecnomecanica());
        }, f.nombreOriginal(), f.tamano(), f.abridor())).toList();
        try {
            documentos.validarVehiculo(fotos);
        } catch (DocumentoInvalidoException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
        }

        Vehiculo vehiculo = vehiculoRepository.save(Vehiculo.builder()
                .placa(placa).marca(marca).modelo(modelo).color(color)
                .tecnomecanicaId(n.tecnomecanica())
                .conductorAsignado(conductor)
                .activo(false).verificado(false)
                .fechaRegistro(LocalDate.now())
                .build());
        try {
            conductor.agregarVehiculo(vehiculo);
            usuarioRepository.save(conductor);
            documentos.guardarTodos(conductor.getIdString(), vehiculo.getId(), fotos);
            return resumen(vehiculo, false);
        } catch (RuntimeException e) {
            vehiculoRepository.deleteById(vehiculo.getId());
            if (conductor.getVehiculos() != null) {
                conductor.getVehiculos().removeIf(id -> id.toString().equals(vehiculo.getId()));
                usuarioRepository.save(conductor);
            }
            throw e;
        }
    }

    /** El admin aprueba el vehículo agregado: desde ahí el conductor puede activarlo. */
    public void aprobar(String vehiculoId) {
        Vehiculo v = vehiculoRepository.findById(vehiculoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Vehículo no encontrado"));
        v.setVerificado(true);
        vehiculoRepository.save(v);
    }

    private static String texto(String raw, String campo) {
        String v = raw == null ? "" : raw.trim();
        if (v.length() < 2 || v.length() > 50) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "La " + campo + " debe tener entre 2 y 50 caracteres");
        }
        return v;
    }

    private boolean tieneViajeEnCurso(Conductor conductor) {
        return !servicioRepository.findByConductorIdAndEstado(conductor.getId(), EstadoServicio.ACEPTADO).isEmpty()
                || !servicioRepository.findByConductorIdAndEstado(conductor.getId(), EstadoServicio.EN_CURSO).isEmpty();
    }

    private static VehiculoResumen resumen(Vehiculo v, boolean conductorEnViaje) {
        return new VehiculoResumen(v.getId(), v.getPlaca(), v.getMarca(), v.getModelo(), v.getColor(),
                v.isActivo(), v.isActivo() && conductorEnViaje, v.getFechaRegistro(), v.estaVerificado());
    }
}
