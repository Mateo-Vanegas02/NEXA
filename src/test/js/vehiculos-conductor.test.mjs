import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const V = createRequire(import.meta.url)('../../main/resources/static/js/vehiculos-conductor.js');

test('estadoDe distingue en servicio, activo e inactivo', () => {
  assert.equal(V.estadoDe({ activo: true, enServicio: true }), 'EN_SERVICIO');
  assert.equal(V.estadoDe({ activo: true, enServicio: false }), 'ACTIVO');
  assert.equal(V.estadoDe({ activo: false, enServicio: false }), 'INACTIVO');
});

test('descripcion une marca, modelo y color sin dejar huecos', () => {
  assert.equal(V.descripcion({ marca: 'Bajaj', modelo: 'Boxer 150', color: 'Negro' }), 'Bajaj Boxer 150 · Negro');
  assert.equal(V.descripcion({ marca: 'Yamaha', modelo: null, color: '' }), 'Yamaha');
  assert.equal(V.descripcion({}), '');
});

test('validarFormulario detecta problemas y acepta uno correcto', async () => {
  const { createRequire } = await import('node:module');
  const V = createRequire(import.meta.url)('../../main/resources/static/js/vehiculos-conductor.js');
  const ok = { placa: 'ABC12D', marca: 'Bajaj', modelo: 'Boxer', color: 'Negro', tarjetaPropiedad: '1234567', soat: '7654321', tecnomecanica: '1112223' };
  const fotos = [1, 2, 3].map(n => ({ nombre: 'f' + n, tamano: 1000 }));
  assert.equal(V.validarFormulario(ok, fotos), '');
  assert.match(V.validarFormulario({ ...ok, placa: '12' }, fotos), /placa/);
  assert.match(V.validarFormulario({ ...ok, soat: 'abc' }, fotos), /dígitos/);
  assert.match(V.validarFormulario(ok, fotos.slice(0, 2)), /foto/);
  assert.match(V.validarFormulario(ok, [{ nombre: 'a', tamano: 6 * 1024 * 1024 }, ...fotos.slice(1)]), /5 MB/);
  assert.equal(V.estadoDe({ activo: false, verificado: false }), 'EN_REVISION');
});
