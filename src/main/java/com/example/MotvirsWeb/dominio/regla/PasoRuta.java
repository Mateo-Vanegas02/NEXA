package com.example.MotvirsWeb.dominio.regla;

/**
 * Un paso de la ruta por calles (instrucción de OSRM): dónde ocurre la maniobra, qué maniobra es y la calle a la que
 * se entra. La app lo usa para decir «Gira a la derecha en Calle 30».
 *
 * @param latitud     punto de la maniobra
 * @param longitud    punto de la maniobra
 * @param maniobra    tipo de OSRM: depart, turn, continue, roundabout, arrive, ...
 * @param modificador left, right, slight left, straight, uturn, ...; vacío si no aplica
 * @param calle       nombre de la vía que sigue; vacío si OSRM no lo conoce
 * @param metros      longitud del tramo que empieza en esta maniobra
 */
public record PasoRuta(double latitud, double longitud, String maniobra, String modificador, String calle,
                       double metros) {
}
