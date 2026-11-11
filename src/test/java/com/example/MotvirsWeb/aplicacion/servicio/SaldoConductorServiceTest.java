package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class SaldoConductorServiceTest {

    private static Servicio finalizado(double totalPasajero, double ganancia, double comision, long deudaCobrada) {
        Servicio s = new Servicio();
        s.setEstado(EstadoServicio.FINALIZADO);
        Servicio.DesgloseTarifa d = new Servicio.DesgloseTarifa();
        d.setTotalPasajero(totalPasajero);
        d.setGananciaConductor(ganancia);
        d.setComisionMonto(comision);
        s.setDesglose(d);
        s.setDeudaCobrada(deudaCobrada);
        return s;
    }

    private static Servicio canceladoConCargo(long cargo, boolean acreditado) {
        Servicio s = new Servicio();
        s.setEstado(EstadoServicio.CANCELADO);
        s.setCargoCancelacion(cargo);
        s.setCargoAcreditadoConductor(acreditado);
        return s;
    }

    @Test
    void elSaldoEsLoCobradoMenosLoQueLeCorresponde() {
        var saldo = SaldoConductorService.calcular(List.of(
                finalizado(10000, 8000, 2000, 0),
                finalizado(6000, 4800, 1200, 3000)), "c1", "Luis", 30);

        assertEquals(2, saldo.viajes());
        assertEquals(19000, saldo.cobradoEfectivo());   // 10.000 + 6.000 + 3.000 de deuda
        assertEquals(12800, saldo.ganado());
        assertEquals(3200, saldo.comisionNexa());
        assertEquals(3000, saldo.deudasCobradas());
        assertEquals(6200, saldo.saldoConNexa());       // comisión + deuda cobrada
    }

    @Test
    void losCargosReconocidosJueganAFavorDelConductor() {
        var saldo = SaldoConductorService.calcular(List.of(
                finalizado(10000, 8000, 2000, 0),
                canceladoConCargo(3000, true),
                canceladoConCargo(3000, false)), "c1", "Luis", 30);

        assertEquals(1, saldo.viajes());
        assertEquals(3000, saldo.cargosAFavor());
        assertEquals(-1000, saldo.saldoConNexa());      // NEXA le debe 1.000
    }

    @Test
    void sinViajesElSaldoEsCero() {
        var saldo = SaldoConductorService.calcular(List.of(), "c1", "Luis", 7);
        assertEquals(0, saldo.saldoConNexa());
        assertEquals(0, saldo.viajes());
        assertEquals(7, saldo.dias());
    }

    @Test
    void unViajeSinDesgloseNoCuenta() {
        Servicio sinDesglose = new Servicio();
        sinDesglose.setEstado(EstadoServicio.FINALIZADO);
        var saldo = SaldoConductorService.calcular(List.of(sinDesglose), "c1", "Luis", 30);
        assertEquals(0, saldo.viajes());
        assertEquals(0, saldo.saldoConNexa());
    }

    @Test
    void laVistaDelConductorNoSeparaComisionNiDeudaDePasajeros() {
        var completo = new SaldoConductorService.SaldoConductor("c1", "Luis", 30, 4, 40_000, 31_000, 6_000, 3_000,
                1_000, 8_000);
        var vista = SaldoConductorService.VistaConductor.de(completo);
        assertEquals(40_000, vista.cobradoEfectivo());
        assertEquals(31_000, vista.ganado());
        assertEquals(1_000, vista.cargosAFavor());
        assertEquals(8_000, vista.saldoConNexa());
        var campos = java.util.Arrays.stream(SaldoConductorService.VistaConductor.class.getRecordComponents())
                .map(java.lang.reflect.RecordComponent::getName).toList();
        assertFalse(campos.contains("comisionNexa"));
        assertFalse(campos.contains("deudasCobradas"));
    }
}
