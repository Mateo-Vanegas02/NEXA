package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.Servicio;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class SatisfaccionClienteServiceTest {

    @Test
    void entrenaConLoQueRealmentePagoElPasajero() {
        Servicio s = new Servicio();
        s.setTarifa(9000);
        Servicio.DesgloseTarifa d = new Servicio.DesgloseTarifa();
        d.setTotalPasajero(7600);
        s.setDesglose(d);
        assertEquals(7600, SatisfaccionClienteService.tarifaPagada(s));
    }

    @Test
    void sinDesgloseUsaLaTarifaGuardada() {
        Servicio s = new Servicio();
        s.setTarifa(9000);
        assertEquals(9000, SatisfaccionClienteService.tarifaPagada(s));
    }
}
