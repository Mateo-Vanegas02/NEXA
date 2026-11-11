// Pruebas de las funciones puras del perfil (iniciales, validación, encuadre de la foto).
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { describe, it } from 'node:test';

const require = createRequire(import.meta.url);
const P = require('../../main/resources/static/js/perfil.js');

describe('iniciales', () => {
  it('usa las dos primeras palabras', () => assert.equal(P.iniciales('Laura Gómez Díaz'), 'LG'));
  it('con una sola palabra usa una letra', () => assert.equal(P.iniciales('ana'), 'A'));
  it('sin nombre devuelve ?', () => { assert.equal(P.iniciales(''), '?'); assert.equal(P.iniciales(null), '?'); });
  it('ignora espacios de más', () => assert.equal(P.iniciales('  ana   pérez '), 'AP'));
});

describe('validarDatos', () => {
  it('acepta datos válidos', () => assert.equal(P.validarDatos('Ana Pérez', '3114567890'), ''));
  it('rechaza nombre corto, vacío o con números', () => {
    assert.notEqual(P.validarDatos('', '3114567890'), '');
    assert.notEqual(P.validarDatos('Al', '3114567890'), '');
    assert.notEqual(P.validarDatos('Ana 2', '3114567890'), '');
  });
  it('rechaza teléfonos que no son celulares colombianos', () => {
    assert.notEqual(P.validarDatos('Ana Pérez', '2114567890'), '');
    assert.notEqual(P.validarDatos('Ana Pérez', '311456789'), '');
    assert.notEqual(P.validarDatos('Ana Pérez', '31145678901'), '');
  });
});

describe('encuadre de la foto', () => {
  it('la escala base cubre el cuadrado en foto horizontal y vertical', () => {
    assert.equal(P.escala(400, 200, 240, 1), 1.2);   // el alto manda
    assert.equal(P.escala(200, 400, 240, 1), 1.2);   // el ancho manda
    assert.equal(P.escala(400, 200, 240, 2), 2.4);
  });
  it('limita el desplazamiento para no dejar bordes vacíos', () => {
    const esc = P.escala(400, 200, 240, 1); // imagen escalada 480x240
    assert.deepEqual(P.limitarDesplazamiento(50, 50, 400, 200, 240, esc), { x: 0, y: 0 });
    assert.deepEqual(P.limitarDesplazamiento(-999, -999, 400, 200, 240, esc), { x: -240, y: 0 });
    assert.deepEqual(P.limitarDesplazamiento(-100, 0, 400, 200, 240, esc), { x: -100, y: 0 });
  });
});

describe('formatoTamano', () => {
  it('KB y MB', () => {
    assert.equal(P.formatoTamano(140 * 1024), '140 KB');
    assert.equal(P.formatoTamano(3.2 * 1024 * 1024), '3,2 MB');
  });
});
