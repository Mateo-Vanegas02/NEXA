package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.EstadoServicio;
import com.example.MotvirsWeb.dominio.modelo.Servicio;
import lombok.RequiredArgsConstructor;
import org.bson.types.ObjectId;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Saldo del conductor con NEXA. Como todo se paga en efectivo, el conductor recibe del pasajero el total del
 * viaje y se queda con su ganancia: la diferencia (la comisión, y la deuda que el pasajero pagó con ese viaje)
 * es de NEXA. A favor del conductor juegan los cargos de cancelación que se le reconocieron.
 *
 * <p>saldo = efectivo recibido − ganancia del conductor − cargos a su favor. Positivo: el conductor le debe a
 * NEXA. Negativo: NEXA le debe a él. No es una cuenta con movimientos: se calcula de los viajes del periodo.
 */
@Service
@RequiredArgsConstructor
public class SaldoConductorService {

    /** Tope de viajes que se leen de una vez (el servidor tiene poca memoria). */
    static final int MAX_SERVICIOS = 20000;

    public record SaldoConductor(String conductorId, String nombre, int dias, long viajes, long cobradoEfectivo,
            long ganado, long comisionNexa, long deudasCobradas, long cargosAFavor, long saldoConNexa) {
    }

    /**
     * Lo que ve el propio conductor: cuánto cobró, cuánto ganó y cuánto queda entre él y NEXA. No separa la comisión
     * ni la deuda de los pasajeros: el efectivo cobrado ya las incluye como un solo monto.
     */
    public record VistaConductor(int dias, long viajes, long cobradoEfectivo, long ganado, long cargosAFavor,
            long saldoConNexa) {
        public static VistaConductor de(SaldoConductor s) {
            return new VistaConductor(s.dias(), s.viajes(), s.cobradoEfectivo(), s.ganado(), s.cargosAFavor(),
                    s.saldoConNexa());
        }
    }

    private final MongoTemplate mongoTemplate;
    private final Clock clock;

    /** Saldo de un conductor en los últimos {@code dias}. */
    public SaldoConductor saldoDe(ObjectId conductorId, String nombre, int dias) {
        int d = acotarDias(dias);
        Query q = consulta(d).addCriteria(Criteria.where("conductor._id").is(conductorId));
        return calcular(mongoTemplate.find(q, Servicio.class), conductorId.toHexString(), nombre, d);
    }

    /** Saldo de todos los conductores con movimientos en el periodo, de mayor a menor deuda con NEXA. */
    public List<SaldoConductor> saldos(int dias) {
        int d = acotarDias(dias);
        Map<String, List<Servicio>> porConductor = new LinkedHashMap<>();
        for (Servicio s : mongoTemplate.find(consulta(d), Servicio.class)) {
            if (s.getConductor() != null && s.getConductor().getId() != null) {
                porConductor.computeIfAbsent(s.getConductor().getIdString(), k -> new ArrayList<>()).add(s);
            }
        }
        List<SaldoConductor> saldos = new ArrayList<>();
        porConductor.forEach((id, viajes) -> saldos.add(
                calcular(viajes, id, viajes.get(0).getConductor().getNombre(), d)));
        saldos.sort(Comparator.comparingLong(SaldoConductor::saldoConNexa).reversed());
        return saldos;
    }

    /** Cálculo puro sobre los viajes del conductor (probado sin base de datos). */
    static SaldoConductor calcular(List<Servicio> viajes, String conductorId, String nombre, int dias) {
        long cobrado = 0;
        long ganado = 0;
        long comision = 0;
        long deudas = 0;
        long cargos = 0;
        long cuantos = 0;
        for (Servicio s : viajes) {
            if (s.getEstado() == EstadoServicio.FINALIZADO && s.getDesglose() != null) {
                cuantos++;
                Servicio.DesgloseTarifa d = s.getDesglose();
                cobrado += Math.round(d.getTotalPasajero()) + Math.max(0, s.getDeudaCobrada());
                ganado += Math.round(d.getGananciaConductor());
                comision += Math.round(d.getComisionMonto());
                deudas += Math.max(0, s.getDeudaCobrada());
            } else if (s.getEstado() == EstadoServicio.CANCELADO && s.isCargoAcreditadoConductor()) {
                cargos += Math.max(0, s.getCargoCancelacion());
            }
        }
        return new SaldoConductor(conductorId, nombre, dias, cuantos, cobrado, ganado, comision, deudas, cargos,
                cobrado - ganado - cargos);
    }

    private Query consulta(int dias) {
        LocalDateTime desde = LocalDateTime.now(clock).minusDays(dias);
        Query q = Query.query(new Criteria().orOperator(
                Criteria.where("estado").is(EstadoServicio.FINALIZADO).and("fechaFinalizacion").gte(desde),
                Criteria.where("estado").is(EstadoServicio.CANCELADO).and("cargoAcreditadoConductor").is(true)
                        .and("fechaCancelacion").gte(desde)));
        q.fields().include("estado", "conductor", "desglose", "deudaCobrada", "cargoCancelacion",
                "cargoAcreditadoConductor");
        return q.limit(MAX_SERVICIOS);
    }

    private static int acotarDias(int dias) {
        return Math.max(1, Math.min(dias, 365));
    }
}
