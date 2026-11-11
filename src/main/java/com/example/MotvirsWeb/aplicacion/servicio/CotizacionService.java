package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.aplicacion.puerto.ProveedorRutas;
import com.example.MotvirsWeb.dominio.modelo.Pasajero;
import com.example.MotvirsWeb.dominio.regla.ModeloTarifa;
import com.example.MotvirsWeb.dominio.regla.ModeloTarifa.Cobro;
import com.example.MotvirsWeb.dominio.regla.PuntoGeo;
import com.example.MotvirsWeb.dominio.regla.Ruta;
import com.example.MotvirsWeb.dominio.regla.ZonaServicio;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

/**
 * Cotiza un viaje en el servidor: valida la zona de Cartagena, calcula la distancia con el
 * proveedor de rutas y fija el precio con {@link ModeloTarifa}. El cliente nunca decide el
 * precio ni la distancia: solo envía los dos puntos.
 */
@Service
@RequiredArgsConstructor
public class CotizacionService {

    /** Ruta cobrada y cobro resultante (con la comisión mínima, el peor caso para el margen). */
    public record Cotizacion(Ruta ruta, Cobro cobro) {
    }

    private final ZonaServicio zona;
    private final ProveedorRutas rutas;
    private final ModeloTarifa tarifa;

    public Cotizacion cotizar(Pasajero pasajero, PuntoGeo origen, PuntoGeo destino) {
        Ruta ruta = rutas.calcular(origen, destino);
        ZonaServicio.Resultado resultado = zona.evaluar(origen, destino, ruta.distanciaKm());
        if (resultado != ZonaServicio.Resultado.VALIDO) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, mensaje(resultado));
        }
        if (ruta.distanciaKm() <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "El origen y el destino son el mismo punto");
        }
        Cobro cobro = tarifa.cotizar(ruta.distanciaKm(), Math.max(1, pasajero.getNivel()));
        return new Cotizacion(ruta, cobro);
    }

    private String mensaje(ZonaServicio.Resultado r) {
        return switch (r) {
            case ORIGEN_FUERA_DE_ZONA -> "El origen está fuera de la zona de servicio de Cartagena";
            case DESTINO_FUERA_DE_ZONA -> "El destino está fuera de la zona de servicio de Cartagena";
            case DISTANCIA_EXCEDIDA -> "El viaje supera la distancia máxima de "
                    + Math.round(zona.distanciaMaxKm()) + " km";
            case VALIDO -> "";
        };
    }
}
