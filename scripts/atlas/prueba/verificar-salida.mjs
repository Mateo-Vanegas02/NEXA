// Verifica la salida de inspeccion-solo-lectura.js sobre los datos sintéticos (CI).
// Uso: node scripts/atlas/prueba/verificar-salida.mjs inspeccion.json
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const texto = readFileSync(process.argv[2], 'utf8');
const r = JSON.parse(texto.slice(texto.indexOf('{')));

// Ningún dato personal sembrado aparece en la salida
for (const prohibido of ['example.invalid', 'sintetico', '900001', '800001', '700001', 'token-sintetico']) {
  assert.ok(!texto.toLowerCase().includes(prohibido), `la salida no debe contener "${prohibido}"`);
}
assert.equal(r.soloLectura, true);
assert.equal(r.servidor.admiteTransacciones, true, 'el Mongo de prueba es replica set');

const e = r.usuarios.email;
assert.equal(e.duplicadosExactos.grupos, 1, 'mismo correo exacto en pasajero y conductor');
assert.equal(e.duplicadosNormalizados.grupos, 1);
assert.equal(e.duplicadosNormalizados.documentos, 3, 'normalizar une el correo con mayúsculas y espacio');
assert.equal(e.gruposQueCruzanRoles, 1);
assert.equal(e.conMayusculasOEspacios, 1);
assert.equal(r.usuarios.licencia.duplicadosMayoresQueCero.grupos, 1);
assert.equal(r.usuarios.licencia.tipos.string, 1, 'una licencia guardada como texto');
assert.equal(r.usuarios.soat.cero, 1);
assert.equal(r.usuarios.deuda.conDeuda, 1);
assert.equal(r.coherenciaDeuda.coherente, 1);

const s = r.servicios;
assert.equal(s.porEstado.SOLICITADO, 2);
assert.equal(s.abiertos.solicitadosDeMasDeUnDia, 1);
assert.equal(s.pasajerosConVariasSolicitudes, 1);
assert.equal(s.cargos.pagadosYCondonados, 1);
assert.equal(s.cargos.abiertos, 1);
assert.equal(s.tipos['pasajero._id'].string, 1, 'un id de pasajero guardado como texto');
assert.equal(s.tipos.fechaHora.string, 1, 'una fecha guardada como texto');
assert.ok(s.tipos.fechaHora.missing >= 1);
assert.ok(r.planes['S1 findByEstado(SOLICITADO)'].etapas.length > 0, 'hay plan de ejecución');
assert.equal(r.xp_eventos.duplicadosViajeRolMotivo.grupos, 1);
assert.equal(r.dispositivos.duplicadosDeToken.grupos, 0);
assert.ok(r.colecciones.Usuarios.indices.some((i) => i.nombre === '_id_'));

console.log('salida de la inspección verificada');
