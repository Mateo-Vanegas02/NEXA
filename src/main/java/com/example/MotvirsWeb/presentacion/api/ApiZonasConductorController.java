package com.example.MotvirsWeb.presentacion.api;

import com.example.MotvirsWeb.aplicacion.servicio.ZonasDemandaService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Zonas con más solicitudes recientes para el mapa del conductor (solo ROLE_CONDUCTOR, por la ruta). */
@RestController
@RequestMapping("/api/conductor")
public class ApiZonasConductorController {

    private final ZonasDemandaService zonas;

    public ApiZonasConductorController(ZonasDemandaService zonas) {
        this.zonas = zonas;
    }

    @GetMapping("/zonas")
    public List<ZonasDemandaService.Zona> zonas() {
        return zonas.zonas();
    }
}
