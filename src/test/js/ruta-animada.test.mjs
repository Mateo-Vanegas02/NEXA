// Pruebas de la animación de rutas (JavaScript plano). Se ejecutan con:  node --test src/test/js
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { describe, it } from 'node:test';

const require = createRequire(import.meta.url);
const R = require('../../main/resources/static/js/ruta-animada.js');

// Vértices MUY desiguales: tres pegados y un tramo largo. Si se avanzara por vértice se notaría el tirón.
const RUTA = [
  [0, 0],
  [0, 0.0001],
  [0, 0.0002],
  [0, 0.0003],
  [0, 0.02],
];
const ACUM = R.distanciasAcumuladas(RUTA);
const TOTAL = ACUM[ACUM.length - 1];

/** Relojes falsos: raf y setTimeout controlados a mano. */
function relojes() {
  let ahora = 0;
  let siguiente = 1;
  const cuadros = new Map();
  const temporizadores = new Map();
  return {
    opciones: {
      raf: (f) => {
        const id = siguiente++;
        cuadros.set(id, f);
        return id;
      },
      caf: (id) => cuadros.delete(id),
      setTimeoutFn: (f, ms) => {
        const id = siguiente++;
        temporizadores.set(id, { f, en: ahora + ms });
        return id;
      },
      clearTimeoutFn: (id) => temporizadores.delete(id),
    },
    /** Avanza el tiempo; `conCuadros=false` simula una pestaña oculta (sin rAF). */
    avanzar(ms, { conCuadros = true, paso = 16 } = {}) {
      const fin = ahora + ms;
      while (ahora < fin) {
        ahora = Math.min(ahora + paso, fin);
        if (conCuadros) {
          const pendientes = [...cuadros.entries()];
          cuadros.clear();
          for (const [, f] of pendientes) f(ahora);
        }
        for (const [id, t] of [...temporizadores.entries()]) {
          if (t.en <= ahora) {
            temporizadores.delete(id);
            t.f();
          }
        }
      }
    },
  };
}

describe('geometría', () => {
  it('distancia: ~111 km por grado de latitud y 0 entre el mismo punto', () => {
    const d = R.distanciaMetros([0, 0], [1, 0]);
    assert.ok(d > 111000 && d < 111400);
    assert.equal(R.distanciaMetros([10, -75], [10, -75]), 0);
  });

  it('rumbo: norte 0, este 90, sur 180, oeste 270', () => {
    assert.ok(Math.abs(R.rumbo([0, 0], [1, 0]) - 0) < 0.1);
    assert.ok(Math.abs(R.rumbo([0, 0], [0, 1]) - 90) < 0.1);
    assert.ok(Math.abs(R.rumbo([0, 0], [-1, 0]) - 180) < 0.1);
    assert.ok(Math.abs(R.rumbo([0, 0], [0, -1]) - 270) < 0.1);
  });

  it('suavizarAngulo toma el camino más corto (350° → 10° pasa por 0°)', () => {
    assert.ok(Math.abs(R.suavizarAngulo(350, 10, 0.5) - 0) < 1e-9);
    assert.ok(Math.abs(R.suavizarAngulo(10, 350, 0.5) - 0) < 1e-9);
  });

  it('suavizado: extremos exactos y monótono', () => {
    assert.equal(R.suavizadoEntradaSalida(0), 0);
    assert.equal(R.suavizadoEntradaSalida(1), 1);
    let previo = -1;
    for (let t = 0; t <= 1; t += 0.05) {
      const v = R.suavizadoEntradaSalida(t);
      assert.ok(v >= previo);
      previo = v;
    }
  });

  it('puntoEnDistancia recorre por distancia, no por vértice', () => {
    const { posicion } = R.puntoEnDistancia(RUTA, ACUM, TOTAL / 2);
    assert.ok(Math.abs(posicion[1] - 0.01) < 1e-4); // por vértices estaría en 0.0001
    assert.deepEqual(R.puntoEnDistancia(RUTA, ACUM, -5).posicion, [0, 0]);
    assert.deepEqual(R.puntoEnDistancia(RUTA, ACUM, 1e9).posicion, [0, 0.02]);
    assert.equal(R.puntoEnDistancia([], [], 5).posicion, null);
  });
});

describe('calcularFrame', () => {
  it('empieza en el origen y termina en el destino', () => {
    assert.deepEqual(R.calcularFrame(RUTA, ACUM, 0, 10000).posicion, [0, 0]);
    const fin = R.calcularFrame(RUTA, ACUM, 10000, 10000);
    assert.deepEqual(fin.posicion, [0, 0.02]);
    assert.equal(fin.terminado, true);
    assert.equal(fin.progresoDistancia, 1);
  });

  it('a mitad de tiempo lleva la mitad de los metros', () => {
    const f = R.calcularFrame(RUTA, ACUM, 5000, 10000);
    assert.ok(Math.abs(R.distanciaMetros(RUTA[0], f.posicion) - TOTAL / 2) < 1);
  });

  it('arranca suave y el avance nunca retrocede', () => {
    assert.ok(R.distanciaMetros(RUTA[0], R.calcularFrame(RUTA, ACUM, 500, 10000).posicion) < TOTAL * 0.01);
    let previo = -1;
    for (let t = 0; t <= 10000; t += 100) {
      const d = R.distanciaMetros(RUTA[0], R.calcularFrame(RUTA, ACUM, t, 10000).posicion);
      assert.ok(d >= previo - 1e-6);
      previo = d;
    }
  });

  it('el rumbo hacia el este es ~90°', () => {
    assert.ok(Math.abs(R.calcularFrame(RUTA, ACUM, 4000, 10000).rumbo - 90) < 1);
  });
});

describe('animar', () => {
  it('avanza, llega al destino y avisa una sola vez', () => {
    const r = relojes();
    const cuadros = [];
    let fines = 0;
    R.animar(RUTA, { duracionMs: 2000, ...r.opciones, onFrame: (f) => cuadros.push(f), onFin: () => fines++ });
    r.avanzar(1000);
    assert.ok(cuadros.length > 30, 'debe entregar muchos cuadros (≈60 fps)');
    assert.ok(cuadros.at(-1).progreso > 0.3 && cuadros.at(-1).progreso < 0.7);
    assert.equal(fines, 0);
    r.avanzar(1500);
    assert.equal(fines, 1);
    assert.deepEqual(cuadros.at(-1).posicion, [0, 0.02]);
    r.avanzar(3000);
    assert.equal(fines, 1);
  });

  it('llega a tiempo aunque no haya cuadros de animación (pestaña oculta)', () => {
    const r = relojes();
    let fines = 0;
    R.animar(RUTA, { duracionMs: 1000, ...r.opciones, onFin: () => fines++ });
    r.avanzar(500, { conCuadros: false });
    assert.equal(fines, 0);
    r.avanzar(700, { conCuadros: false });
    assert.equal(fines, 1);
  });

  it('cancelar no avisa la llegada', () => {
    const r = relojes();
    let fines = 0;
    const anim = R.animar(RUTA, { duracionMs: 1000, ...r.opciones, onFin: () => fines++ });
    r.avanzar(300);
    anim.cancelar();
    r.avanzar(3000);
    assert.equal(fines, 0);
  });

  it('el giro es suave: ningún cuadro gira más de 20° respecto al anterior en una curva de 90°', () => {
    const esquina = [[0, 0], [0, 0.01], [0.01, 0.01]]; // este y luego norte
    const r = relojes();
    const rumbos = [];
    R.animar(esquina, { duracionMs: 4000, ...r.opciones, onFrame: (f) => rumbos.push(f.rumbo) });
    r.avanzar(4500);
    let maxSalto = 0;
    for (let i = 1; i < rumbos.length; i++) {
      const dif = Math.abs(((rumbos[i] - rumbos[i - 1] + 540) % 360) - 180);
      maxSalto = Math.max(maxSalto, dif);
    }
    assert.ok(maxSalto < 20, `salto máximo ${maxSalto.toFixed(1)}°`);
  });

  it('una ruta de menos de 2 puntos termina de inmediato sin romper', () => {
    let fines = 0;
    R.animar([[1, 1]], { onFin: () => fines++ });
    assert.equal(fines, 1);
  });
});
