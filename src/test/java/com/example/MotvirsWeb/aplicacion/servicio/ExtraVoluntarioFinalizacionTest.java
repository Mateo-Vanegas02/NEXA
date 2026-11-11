package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.Servicio.DesgloseTarifa;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/** El extra voluntario va completo al conductor y no toca lo que gana la plataforma. */
class ExtraVoluntarioFinalizacionTest {

    private DesgloseTarifa desglose() {
        DesgloseTarifa d = new DesgloseTarifa();
        d.setTotalPasajero(9000);
        d.setGananciaConductor(7200);
        d.setIngresoPlataforma(1800);
        d.setComisionMonto(1800);
        return d;
    }

    @Test
    void sumaAlTotalYALaGananciaSinTocarLaPlataforma() {
        DesgloseTarifa d = desglose();

        NivelesService.conExtraVoluntario(d, 1500);

        assertEquals(1500, d.getExtraVoluntario());
        assertEquals(10500, d.getTotalPasajero());
        assertEquals(8700, d.getGananciaConductor());
        assertEquals(1800, d.getIngresoPlataforma(), "la plataforma ni gana ni pierde");
        assertEquals(1800, d.getComisionMonto(), "sin comisión sobre el extra");
    }

    @Test
    void sinExtraNoCambiaNada() {
        DesgloseTarifa d = desglose();

        NivelesService.conExtraVoluntario(d, 0);

        assertEquals(0, d.getExtraVoluntario());
        assertEquals(9000, d.getTotalPasajero());
        assertEquals(7200, d.getGananciaConductor());
    }
}
