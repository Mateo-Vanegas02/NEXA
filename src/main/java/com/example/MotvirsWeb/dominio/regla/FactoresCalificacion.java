package com.example.MotvirsWeb.dominio.regla;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Factores que el pasajero y el conductor pueden marcar al calificar (además de las estrellas y el comentario).
 * Salen de lo que encontró el modelo de satisfacción (TensorFlow): para el pasajero pesa sobre todo cuánto tardan en
 * aceptar y en llegar, y si lo dejaron antes del destino; para el conductor, cuánto lo hizo esperar el pasajero en el
 * punto y el cobro.
 *
 * <p>Con una nota de "no satisfecho" (menos de {@link #NOTA_SATISFECHO}) se marca qué falló; con una nota de
 * satisfecho, qué estuvo bien. Es el mismo corte que usa el modelo para su etiqueta, así un factor nunca contradice la
 * nota.
 *
 * <p>Los factores no son variables de entrada del modelo (nunca una calificación como entrada): sirven para comparar
 * lo que la gente marca con lo que el modelo calcula.
 */
public final class FactoresCalificacion {

    /** Nota desde la que un viaje cuenta como satisfecho (igual que {@code NOTA_SATISFECHO} del modelo). */
    public static final double NOTA_SATISFECHO = 4.0;

    /** Un factor del catálogo: código estable (es lo que se guarda), texto para la pantalla y si es positivo. */
    public record Factor(String codigo, String etiqueta, boolean positivo) {
    }

    /** Lo que el pasajero marca sobre el conductor y el viaje. */
    private static final List<Factor> DEL_PASAJERO = List.of(
            new Factor("ACEPTACION_LENTA", "Tardaron en aceptar", false),
            new Factor("LLEGADA_TARDE", "Tardó en llegar a recogerme", false),
            new Factor("DEJO_ANTES_DEL_DESTINO", "Me dejó antes del destino", false),
            new Factor("PRECIO", "El precio o el cobro", false),
            new Factor("RUTA_LARGA", "La ruta fue más larga", false),
            new Factor("CONDUCCION", "La forma de conducir", false),
            new Factor("ACEPTACION_RAPIDA", "Aceptaron rápido", true),
            new Factor("LLEGO_A_TIEMPO", "Llegó a tiempo", true),
            new Factor("BUEN_PRECIO", "Buen precio", true),
            new Factor("BUENA_RUTA", "Buena ruta", true),
            new Factor("CONDUCCION_SEGURA", "Conducción segura", true),
            new Factor("AMABLE", "Amable", true));

    /** Lo que el conductor marca sobre el pasajero. */
    private static final List<Factor> DEL_CONDUCTOR = List.of(
            new Factor("ESPERA_EN_EL_PUNTO", "Me hizo esperar en el punto", false),
            new Factor("PUNTO_DIFICIL", "El punto de recogida era difícil", false),
            new Factor("PAGO", "Problemas con el pago o el recargo", false),
            new Factor("TRATO", "El trato", false),
            new Factor("LISTO_A_TIEMPO", "Estaba listo a tiempo", true),
            new Factor("PUNTO_CLARO", "Punto de recogida claro", true),
            new Factor("PAGO_SIN_PROBLEMAS", "Pagó sin problemas", true),
            new Factor("AMABLE", "Amable", true));

    private FactoresCalificacion() {
    }

    /**
     * Catálogo de quien califica.
     *
     * @param rolQueCalifica {@code "pasajero"} o {@code "conductor"}
     * @throws IllegalArgumentException si el rol no es uno de esos dos
     */
    public static List<Factor> catalogo(String rolQueCalifica) {
        if ("pasajero".equals(rolQueCalifica)) {
            return DEL_PASAJERO;
        }
        if ("conductor".equals(rolQueCalifica)) {
            return DEL_CONDUCTOR;
        }
        throw new IllegalArgumentException("Rol inválido: " + rolQueCalifica);
    }

    /** Si la nota cuenta como satisfecho (entonces solo valen factores positivos). */
    public static boolean esSatisfecho(double nota) {
        return nota >= NOTA_SATISFECHO;
    }

    /**
     * Deja los factores elegidos listos para guardar: sin repetidos y en el orden del catálogo.
     *
     * @return lista vacía si no se eligió ninguno
     * @throws IllegalArgumentException si un código no existe para ese rol, si contradice la nota (un positivo con
     *         nota baja o al revés) o si hay factores sin nota
     */
    public static List<String> normalizar(String rolQueCalifica, Double nota, List<String> codigos) {
        List<Factor> catalogo = catalogo(rolQueCalifica);
        if (codigos == null || codigos.isEmpty()) {
            return List.of();
        }
        if (nota == null) {
            throw new IllegalArgumentException("Los factores necesitan una calificación");
        }
        Set<String> pedidos = new LinkedHashSet<>();
        for (String c : codigos) {
            if (c != null && !c.isBlank()) {
                pedidos.add(c.trim());
            }
        }
        boolean satisfecho = esSatisfecho(nota);
        List<String> salida = new ArrayList<>();
        for (Factor f : catalogo) {
            if (pedidos.remove(f.codigo())) {
                if (f.positivo() != satisfecho) {
                    throw new IllegalArgumentException("El factor «" + f.etiqueta() + "» no corresponde a "
                            + (satisfecho ? "una buena calificación" : "una calificación baja"));
                }
                salida.add(f.codigo());
            }
        }
        if (!pedidos.isEmpty()) {
            throw new IllegalArgumentException("Factor desconocido: " + pedidos.iterator().next());
        }
        return List.copyOf(salida);
    }
}
