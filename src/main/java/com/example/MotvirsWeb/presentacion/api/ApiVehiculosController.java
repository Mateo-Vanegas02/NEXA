package com.example.MotvirsWeb.presentacion.api;

import com.example.MotvirsWeb.aplicacion.servicio.VehiculoConductorService;
import com.example.MotvirsWeb.aplicacion.servicio.VehiculoConductorService.VehiculoResumen;
import com.example.MotvirsWeb.aplicacion.util.UsuarioContextHelper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import com.example.MotvirsWeb.aplicacion.servicio.DocumentosConductorService;
import com.example.MotvirsWeb.dominio.modelo.TipoDocumento;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

/** Vehículos del conductor autenticado (ruta bajo /api/conductor: solo rol CONDUCTOR). */
@RestController
@RequestMapping("/api/conductor/vehiculos")
@RequiredArgsConstructor
public class ApiVehiculosController {

    private final VehiculoConductorService vehiculos;
    private final UsuarioContextHelper usuarioContext;

    @GetMapping
    public List<VehiculoResumen> listar() {
        return vehiculos.listar(usuarioContext.getConductorAutenticado());
    }

    @PostMapping(consumes = org.springframework.http.MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> agregar(@RequestParam String placa, @RequestParam String marca,
            @RequestParam String modelo, @RequestParam String color,
            @RequestParam long tarjetaPropiedad, @RequestParam long soat, @RequestParam long tecnomecanica,
            @RequestParam MultipartFile fotoTarjetaPropiedad, @RequestParam MultipartFile fotoSoat,
            @RequestParam MultipartFile fotoTecnomecanica) {
        try {
            var fotos = List.of(foto(TipoDocumento.TARJETA_PROPIEDAD, fotoTarjetaPropiedad),
                    foto(TipoDocumento.SOAT, fotoSoat), foto(TipoDocumento.TECNOMECANICA, fotoTecnomecanica));
            var creado = vehiculos.agregar(usuarioContext.getConductorAutenticado(),
                    new VehiculoConductorService.NuevoVehiculo(placa, marca, modelo, color,
                            tarjetaPropiedad, soat, tecnomecanica, fotos));
            return ResponseEntity.status(201).body(creado);
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason()));
        }
    }

    private static DocumentosConductorService.ArchivoSubido foto(TipoDocumento tipo, MultipartFile f) {
        return new DocumentosConductorService.ArchivoSubido(tipo, null, f.getOriginalFilename(), f.getSize(), f::getInputStream);
    }

    @PutMapping("/{id}/activar")
    public ResponseEntity<?> activar(@PathVariable String id) {
        try {
            return ResponseEntity.ok(vehiculos.activar(usuarioContext.getConductorAutenticado(), id));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason()));
        }
    }
}
