package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.presentacion.dto.OptimizerResponseDto;
import com.google.ortools.Loader;
import com.google.ortools.sat.*;
import org.springframework.stereotype.Service;

/**
 * Servicio encargado de resolver la optimización de la jornada diaria del conductor.
 * Utiliza Google OR-Tools (Solver CP-SAT) para resolver el modelo matemático No Lineal Entero Mixto (MINLP)
 * de Selección de Cartera de Markowitz (Media-Varianza).
 */
@Service
public class OptimizerService {

    static {
        // Carga las bibliotecas dinámicas nativas de C++ (DLL en Windows, SO en Linux) del Solver de Google
        try {
            Loader.loadNativeLibraries();
        } catch (Exception e) {
            System.err.println("WARN: No se pudieron precargar las librerías nativas de Google OR-Tools: " + e.getMessage());
        }
    }

    /**
     * Resuelve el modelo de optimización.
     * Incorpora una lógica de fallback: si la meta de ingresos es inviable,
     * recalcula el plan de máximo beneficio posible y advierte del límite real.
     */
    public OptimizerResponseDto optimizarJornada(double metaIngreso, double horasJornada, double presupuestoGasolina, double riskAversion) {
        // Intentamos resolver con la restricción de meta activa
        OptimizerResponseDto resultado = resolverCpSat(metaIngreso, horasJornada, presupuestoGasolina, riskAversion, true);

        // Fallback: Si no es factible con la meta activa, y la meta es mayor a cero,
        // removemos la restricción de meta para encontrar la solución óptima absoluta del día
        if (!resultado.factible() && metaIngreso > 0) {
            OptimizerResponseDto fallback = resolverCpSat(0, horasJornada, presupuestoGasolina, riskAversion, false);
            if (fallback.factible()) {
                String mensajeInviable = String.format(
                    "La meta diaria de $%,.0f COP excede tu capacidad de tiempo o combustible. " +
                    "Te recomendamos este plan óptimo alternativo con el que puedes lograr hasta $%,.0f COP netos.",
                    metaIngreso, fallback.beneficioEsperado()
                );
                return new OptimizerResponseDto(
                    false, fallback.x1(), fallback.x2(), fallback.x3(),
                    fallback.beneficioEsperado(), fallback.riesgoDiario(), fallback.utilidadAjustada(),
                    fallback.tiempoTotal(), fallback.costoGasolina(), mensajeInviable
                );
            }
        }

        return resultado;
    }

    private OptimizerResponseDto resolverCpSat(double metaIngreso, double horasJornada, double presupuestoGasolina, double riskAversion, boolean aplicarMeta) {
        try {
            // Force strict static mathematical boundaries (Exactly 8 hours, Exactly $30,000 COP fuel)
            horasJornada = 8.0;
            presupuestoGasolina = 30000.0;

            CpModel model = new CpModel();

            // 1. VARIABLES DE DECISIÓN (Enteras No Negativas)
            // x1 (Viajes Cortos): Mínimo 10 por cobertura céntrica NEXA, máximo 15 por demanda local de la zona
            IntVar x1 = model.newIntVar(10, 15, "x1");
            // x2 (Viajes Medianos): De 0 a 10 viajes diarios según demanda de la plataforma
            IntVar x2 = model.newIntVar(0, 10, "x2");
            // x3 (Viajes Largos): De 0 a 5 viajes diarios según demanda intermunicipal o de larga distancia
            IntVar x3 = model.newIntVar(0, 5, "x3");

            // 2. RESTRICCIONES DE RECURSOS
            // Capacidad de Tiempo: 10*X1 + 25*X2 + 50*X3 <= horasJornada * 60 minutos
            long maxTiempoMinutos = (long) (horasJornada * 60);
            model.addLessOrEqual(
                LinearExpr.weightedSum(new IntVar[]{x1, x2, x3}, new long[]{10, 25, 50}),
                maxTiempoMinutos
            );

            // Presupuesto Gasolina: 500*X1 + 1200*X2 + 2500*X3 <= presupuestoGasolina
            model.addLessOrEqual(
                LinearExpr.weightedSum(new IntVar[]{x1, x2, x3}, new long[]{500, 1200, 2500}),
                (long) presupuestoGasolina
            );

            // 3. RESTRICCIÓN DE META DIARIA
            if (aplicarMeta && metaIngreso > 0) {
                // E(Z) = 4000*X1 + 8500*X2 + 16000*X3 >= metaIngreso
                model.addGreaterOrEqual(
                    LinearExpr.weightedSum(new IntVar[]{x1, x2, x3}, new long[]{4000, 8500, 16000}),
                    (long) metaIngreso
                );
            }

            // 4. REFORMULACIÓN CUADRÁTICA PARA LA DESVIACIÓN ESTÁNDAR (Linealización)
            // t = desviación estándar total (σ_Z)
            // tSq = t^2 (variable auxiliar)
            IntVar t = model.newIntVar(0, 100000, "t");
            IntVar tSq = model.newIntVar(0, 2000000000, "t_sq");

            // Restricción no lineal: tSq = t * t
            model.addMultiplicationEquality(tSq, t, t);

            // Relación de Varianza: tSq >= 250,000 * X1 + 1,440,000 * X2 + 9,000,000 * X3
            LinearExpr varianzaTotal = LinearExpr.weightedSum(
                new IntVar[]{x1, x2, x3},
                new long[]{250000, 1440000, 9000000}
            );
            model.addGreaterOrEqual(tSq, varianzaTotal);

            // 5. FUNCIÓN OBJETIVO
            if (aplicarMeta && metaIngreso > 0) {
                // Goal Mode: Minimize risk (volatility) to meet the income goal with least effort and maximum safety
                model.minimize(t);
            } else {
                // Maximum Performance Mode: Maximize net adjusted utility
                long kScale = Math.round(riskAversion * 10);
                LinearExpr objetivo = LinearExpr.newBuilder()
                    .addTerm(x1, 40000)
                    .addTerm(x2, 85000)
                    .addTerm(x3, 160000)
                    .addTerm(t, -kScale)
                    .build();
                model.maximize(objetivo);
            }

            // 6. SOLUCIÓN CON GOOGLE OR-TOOLS
            CpSolver solver = new CpSolver();
            solver.getParameters().setMaxTimeInSeconds(2.0); // Prevenir bloqueos de hilo
            CpSolverStatus status = solver.solve(model);

            if (status == CpSolverStatus.OPTIMAL || status == CpSolverStatus.FEASIBLE) {
                int optX1 = (int) solver.value(x1);
                int optX2 = (int) solver.value(x2);
                int optX3 = (int) solver.value(x3);
                double riesgoEstimado = solver.value(t);

                double beneficioEsperado = 4000 * optX1 + 8500 * optX2 + 16000 * optX3;
                double utilidadAjustada = beneficioEsperado - (riskAversion * riesgoEstimado);

                return new OptimizerResponseDto(
                    true, optX1, optX2, optX3, beneficioEsperado, riesgoEstimado, utilidadAjustada,
                    (10 * optX1 + 25 * optX2 + 50 * optX3),
                    (500 * optX1 + 1200 * optX2 + 2500 * optX3),
                    "¡Cálculo resuelto con éxito! Te presentamos tu plan de trabajo de máxima eficiencia."
                );
            } else {
                return new OptimizerResponseDto(false, 0, 0, 0, 0, 0, 0, 0, 0,
                    "La meta ingresada excede la capacidad física viable.");
            }
        } catch (Exception e) {
            System.err.println("ERROR: Fallo crítico al ejecutar el solver CP-SAT: " + e.getMessage());
            return new OptimizerResponseDto(false, 0, 0, 0, 0, 0, 0, 0, 0,
                "Error interno de inicialización del solucionador nativo de Google OR-Tools.");
        }
    }
}
