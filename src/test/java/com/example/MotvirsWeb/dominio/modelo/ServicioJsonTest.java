package com.example.MotvirsWeb.dominio.modelo;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** La app lee los ids del pasajero y del conductor como texto: un ObjectId saldría como objeto y rompería la lectura. */
class ServicioJsonTest {

    @Test
    void losIdsEmbebidosSalenComoTexto() throws Exception {
        ObjectId pasajero = new ObjectId();
        ObjectId conductor = new ObjectId();
        Servicio s = new Servicio();
        s.setId("s1");
        s.setPasajero(new Servicio.PasajeroEmbedded(pasajero, "Laura", "l@t.co"));
        Servicio.ConductorEmbedded c = new Servicio.ConductorEmbedded();
        c.setId(conductor);
        c.setNombre("Carlos");
        s.setConductor(c);

        JsonNode json = new ObjectMapper().registerModule(new JavaTimeModule()).valueToTree(s);

        assertTrue(json.at("/pasajero/id").isTextual());
        assertEquals(pasajero.toHexString(), json.at("/pasajero/id").asText());
        assertEquals(conductor.toHexString(), json.at("/conductor/id").asText());
    }
}
