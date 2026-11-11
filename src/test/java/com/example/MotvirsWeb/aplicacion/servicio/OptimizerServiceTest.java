package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.presentacion.dto.OptimizerResponseDto;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import static org.junit.jupiter.api.Assertions.*;

@org.junit.jupiter.api.Tag("requiere-mongo")
@SpringBootTest
public class OptimizerServiceTest {

    @Autowired
    private OptimizerService optimizerService;

    @Test
    public void testOptimizarJornadaMaximoRendimiento() {
        // Ejecutar optimización con meta = 0 (Modo máximo rendimiento)
        // 8 horas de jornada laboral, presupuesto de gasolina $30,000, aversión al riesgo moderada k = 0.5
        OptimizerResponseDto response = optimizerService.optimizarJornada(0, 8.0, 30000.0, 0.5);

        assertNotNull(response);
        assertTrue(response.factible(), "El plan de máximo rendimiento debería ser factible.");
        assertTrue(response.x1() >= 10, "Debe cumplir la cobertura mínima de 10 viajes cortos.");
        assertTrue(response.beneficioEsperado() > 0, "El beneficio esperado debe ser positivo.");
        assertTrue(response.tiempoTotal() <= 480.0, "No debe exceder el tiempo máximo de 480 minutos.");
        assertTrue(response.costoGasolina() <= 30000.0, "No debe exceder el presupuesto de gasolina.");
        System.out.println("TEST MAX RENDIMIENTO: " + response);
    }

    @Test
    public void testOptimizarJornadaConMetaFactible() {
        // Ejecutar optimización con meta de ingresos factible de $120,000 COP
        OptimizerResponseDto response = optimizerService.optimizarJornada(120000, 8.0, 30000.0, 0.5);

        assertNotNull(response);
        assertTrue(response.factible(), "Una meta de $120,000 COP debería ser factible en 8 horas.");
        assertTrue(response.beneficioEsperado() >= 120000.0, "El beneficio esperado debe cumplir o superar la meta.");
        assertTrue(response.tiempoTotal() <= 480.0, "El tiempo de trabajo no debe exceder las 8 horas.");
        System.out.println("TEST META FACTIBLE: " + response);
    }

    @Test
    public void testOptimizarJornadaConMetaInviable() {
        // Ejecutar optimización con una meta inviable de $500,000 COP (Físicamente imposible en 8h)
        OptimizerResponseDto response = optimizerService.optimizarJornada(500000, 8.0, 30000.0, 0.5);

        assertNotNull(response);
        // Debe retornar factible = false debido a que no se puede cumplir la meta
        assertFalse(response.factible(), "Una meta de $500,000 COP debe ser inviable.");
        
        // Sin embargo, el fallback debe devolver el plan de máximo beneficio posible real
        assertTrue(response.x1() >= 10, "El plan de fallback debe ser físicamente válido.");
        assertTrue(response.beneficioEsperado() > 0, "El beneficio de fallback debe ser positivo.");
        assertTrue(response.beneficioEsperado() < 500000.0, "El beneficio esperado real será menor que la meta imposible.");
        assertTrue(response.mensaje().contains("La meta diaria de"), "Debe contener el mensaje de advertencia del fallback.");
        System.out.println("TEST FALLBACK INVIABLE: " + response);
    }
}
