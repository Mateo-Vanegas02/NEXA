/**
 * NEXA | Animación fluida de un vehículo a lo largo de una ruta (JavaScript plano).
 *
 * Por qué existe: la simulación anterior avanzaba por VÉRTICE de la ruta con setInterval a
 * 100 ms, así que la velocidad dependía de qué tan juntos estaban los puntos (tirones) y se
 * veía a ~10 fps. Aquí se avanza por DISTANCIA real, con requestAnimationFrame (~60 fps),
 * arranque y frenado suaves, giro suavizado y un temporizador de respaldo para que la llegada
 * ocurra a tiempo aunque la pestaña esté oculta (el navegador pausa requestAnimationFrame).
 *
 * Las posiciones son pares [latitud, longitud]; las distancias, en metros.
 * Sin dependencias: sirve en el navegador (window.RutaAnimada) y en Node (pruebas).
 */
(function (raiz, fabrica) {
  const api = fabrica();
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else raiz.RutaAnimada = api;
})(typeof window !== 'undefined' ? window : globalThis, function () {
  'use strict';

  const RADIO_TIERRA_M = 6371000;
  const ANTICIPACION_M = 12; // mira un poco adelante para que el giro sea estable en curvas
  const CONSTANTE_GIRO_MS = 140; // cuanto menor, más rápido gira hacia el rumbo objetivo
  const aRad = (g) => (g * Math.PI) / 180;
  const aGrados = (r) => (r * 180) / Math.PI;

  function distanciaMetros(a, b) {
    const dLat = aRad(b[0] - a[0]);
    const dLng = aRad(b[1] - a[1]);
    const h = Math.sin(dLat / 2) ** 2 + Math.cos(aRad(a[0])) * Math.cos(aRad(b[0])) * Math.sin(dLng / 2) ** 2;
    return 2 * RADIO_TIERRA_M * Math.asin(Math.min(1, Math.sqrt(h)));
  }

  /** Rumbo de a hacia b en grados (0 = norte, 90 = este). */
  function rumbo(a, b) {
    const lat1 = aRad(a[0]);
    const lat2 = aRad(b[0]);
    const dLng = aRad(b[1] - a[1]);
    const y = Math.sin(dLng) * Math.cos(lat2);
    const x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLng);
    return (aGrados(Math.atan2(y, x)) + 360) % 360;
  }

  function distanciasAcumuladas(ruta) {
    const acum = [0];
    for (let i = 1; i < ruta.length; i++) acum.push(acum[i - 1] + distanciaMetros(ruta[i - 1], ruta[i]));
    return acum;
  }

  /** Posición y rumbo a `distancia` metros del inicio (búsqueda binaria del tramo). */
  function puntoEnDistancia(ruta, acum, distancia) {
    if (ruta.length === 0) return { posicion: null, rumbo: 0 };
    if (ruta.length === 1) return { posicion: ruta[0], rumbo: 0 };
    const d = Math.min(Math.max(distancia, 0), acum[acum.length - 1]);
    let bajo = 0;
    let alto = acum.length - 1;
    while (alto - bajo > 1) {
      const medio = (bajo + alto) >> 1;
      if (acum[medio] <= d) bajo = medio;
      else alto = medio;
    }
    const largo = acum[alto] - acum[bajo];
    const t = largo === 0 ? 0 : (d - acum[bajo]) / largo;
    const a = ruta[bajo];
    const b = ruta[alto];
    return { posicion: [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t], rumbo: rumbo(a, b) };
  }

  /** Acerca `actual` a `objetivo` por el camino angular más corto. */
  function suavizarAngulo(actual, objetivo, factor) {
    const diferencia = ((objetivo - actual + 540) % 360) - 180;
    return (actual + diferencia * factor + 360) % 360;
  }

  /** Arranque y frenado suaves. t ∈ [0, 1]. */
  function suavizadoEntradaSalida(t) {
    const x = Math.min(Math.max(t, 0), 1);
    return x < 0.5 ? 4 * x ** 3 : 1 - (-2 * x + 2) ** 3 / 2;
  }

  /** Estado en el instante `t` (ms). Función pura: velocidad constante en distancia. */
  function calcularFrame(ruta, acum, t, duracionMs) {
    const total = acum[acum.length - 1] || 0;
    const progreso = duracionMs <= 0 ? 1 : Math.min(Math.max(t / duracionMs, 0), 1);
    const fraccion = suavizadoEntradaSalida(progreso);
    const recorrido = total * fraccion;
    const actual = puntoEnDistancia(ruta, acum, recorrido);
    const adelante = puntoEnDistancia(ruta, acum, Math.min(recorrido + ANTICIPACION_M, total));
    return {
      posicion: actual.posicion,
      rumbo: adelante.rumbo || actual.rumbo,
      progreso, // tiempo transcurrido, 0..1
      progresoDistancia: fraccion, // fracción de la ruta recorrida, 0..1
      terminado: progreso >= 1,
    };
  }

  /**
   * Anima sobre `ruta` durante `duracionMs`. Llama onFrame(frame) en cada cuadro y onFin() una
   * sola vez al llegar. Devuelve { cancelar() }.
   * Los relojes se pueden inyectar (opciones raf, caf, setTimeoutFn, clearTimeoutFn, ahora)
   * para probarla sin navegador.
   */
  function animar(ruta, opciones) {
    const o = opciones || {};
    const duracionMs = o.duracionMs == null ? 10000 : o.duracionMs;
    const raf = o.raf || ((f) => requestAnimationFrame(f));
    const caf = o.caf || ((id) => cancelAnimationFrame(id));
    const poner = o.setTimeoutFn || ((f, ms) => setTimeout(f, ms));
    const quitar = o.clearTimeoutFn || ((id) => clearTimeout(id));
    if (!ruta || ruta.length < 2) {
      if (o.onFin) o.onFin();
      return { cancelar() {} };
    }
    const acum = distanciasAcumuladas(ruta);
    let cuadro = 0;
    let inicio = null;
    let anterior = null;
    let rumboSuave = null;
    let terminada = false;
    let respaldo = null;

    function terminar() {
      if (terminada) return;
      terminada = true;
      quitar(respaldo);
      caf(cuadro);
      const final = calcularFrame(ruta, acum, duracionMs, duracionMs);
      final.rumbo = rumboSuave == null ? final.rumbo : rumboSuave;
      if (o.onFrame) o.onFrame(final);
      if (o.onFin) o.onFin();
    }

    respaldo = poner(terminar, duracionMs + 60);

    function paso(ahora) {
      if (terminada) return;
      if (inicio === null) {
        inicio = ahora;
        anterior = ahora;
      }
      const frame = calcularFrame(ruta, acum, ahora - inicio, duracionMs);
      const dt = ahora - anterior;
      anterior = ahora;
      // Giro suavizado independiente de los fps: factor = 1 - e^(-dt/τ)
      rumboSuave =
        rumboSuave === null ? frame.rumbo : suavizarAngulo(rumboSuave, frame.rumbo, 1 - Math.exp(-dt / CONSTANTE_GIRO_MS));
      frame.rumbo = rumboSuave;
      if (frame.terminado) {
        terminar();
        return;
      }
      if (o.onFrame) o.onFrame(frame);
      cuadro = raf(paso);
    }

    cuadro = raf(paso);
    return {
      cancelar() {
        // Cancelar no debe avisar la llegada.
        terminada = true;
        quitar(respaldo);
        caf(cuadro);
      },
    };
  }

  return {
    distanciaMetros,
    rumbo,
    distanciasAcumuladas,
    puntoEnDistancia,
    suavizarAngulo,
    suavizadoEntradaSalida,
    calcularFrame,
    animar,
  };
});
