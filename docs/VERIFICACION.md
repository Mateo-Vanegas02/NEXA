# Verificación de conductores (placa y documento)

Objetivo: que el admin verifique placa y datos de un conductor contra una fuente oficial antes de aprobarlo. País: Colombia (fuente natural: RUNT). **Estado honesto: no existe una fuente gratuita, oficial y por consulta individual; hoy la verificación efectiva es manual asistida. Hay un adaptador listo para un proveedor de pago, sin probar contra el servicio real.**

## Fuentes evaluadas (consultadas el 2026-10-09)

| Fuente | Qué ofrece | Legalidad / límites | Veredicto |
|---|---|---|---|
| Consulta web del RUNT (runt.gov.co) | Placa, SOAT, tecnomecánica (requiere placa + documento del propietario) | Usa captcha; automatizarla evadiéndolo está prohibido y viola términos | **Descartada** para automatizar. Sí válida para que el admin consulte a mano. |
| Web service RUNT para entidades ([comunicado 021/2021](https://runt.gov.co/sites/default/files/Comunicado%20021%20de%202021_0.pdf), [instructivo de usuario empresarial](https://runt.gov.co/system/files/instructivos/RUNT2-IN-805%20Instructivo%20Registrar%20Usuario%20Funcionalidad%20Empresarial%20APP%20RUNT%20V3-empresa%20de%20transporte.pdf)) | Consulta de vehículos y conductores | Requiere convenio entre Ministerio de Transporte, Concesión RUNT y la entidad; no hay documentación pública ni precios | **Vía oficial recomendada a mediano plazo** (solicitar por el Centro de Contacto de la Concesión RUNT 2.0). No implementada: sin especificación. |
| datos.gov.co (Socrata/SODA) ([Crecimiento del parque automotor RUNT2.0](https://www.datos.gov.co/Transporte/CRECIMIENTO-DEL-PARQUE-AUTOMOTOR-RUNT2-0/u3vn-bdcy), [Actores RUNT](https://www.datos.gov.co/Transporte/ACTORES-RUNT-POR-MUNICIPIO-Y-DEPARTAMENTO-RUNT2-0/epfm-5fhb)) | Datos agregados (conteos por municipio/clase) y listado de actores (escuelas, CDA) | Gratis y abierto (CC BY-SA 4.0), pero **no contiene placas ni conductores individuales** | **Inútil** para verificar una placa o licencia. |
| Verifik ([docs RUNT por placa](https://docs.verifik.co/vehicle-validation/colombia/runt-vehicle-by-plate), [SOAT/RTM](https://docs.verifik.co/verifik-pt/vehicle-validation/colombia/vehicle-s-soat-and-rtm-by-plate-and-identification-document/)) | `GET api.verifik.co/v2/co/runt/vehicle-by-plate`, Bearer; datos del vehículo, SOAT, tecnomecánica | Proveedor comercial; la página dice que hay créditos gratuitos al crear cuenta, **sin precios ni límites publicados**; exige el documento del propietario; no verifica licencias de conducción en lo que se revisó | **Viable** como adaptador (implementado, sin probar). Revisar contrato, precio y tratamiento de datos. |
| [Fasecolda – consulta SOAT](https://web.fasecolda.com/SOAT/Consulta) | Validar vigencia de un SOAT | Página web, no API | Útil para revisión manual. |

No se encontró ninguna API gratuita con licencia de conducción. SIMIT, Fasecolda y otros proveedores no se evaluaron en profundidad.

## Arquitectura

`aplicacion/verificacion/DriverVerificationProvider` (`verifyPlate`, `verifyDriver`) devuelve `VerificationResult` con `VERIFIED | NOT_FOUND | MISMATCH | UNAVAILABLE` y datos mínimos (marca, modelo, SOAT/tecno vigentes). Implementaciones:

- `ManualVerificationProvider` (por defecto): siempre `UNAVAILABLE`; el admin revisa los datos y marca el resultado.
- `MockVerificationProvider`: determinista, para desarrollo. Placa que empieza por `XXX` → NOT_FOUND, `MMM` → MISMATCH, `UUU` → UNAVAILABLE, otra → VERIFIED. Documento que termina en `0000` → NOT_FOUND, `1111` → MISMATCH, `9999` → UNAVAILABLE.
- `RuntHttpVerificationProvider`: adaptador HTTP tipo Verifik, con timeout, límite de tasa, sin seguir redirecciones y errores genéricos. Solo verifica placa y necesita el documento del propietario (que la app no almacena: el admin lo escribe en el panel y no se persiste). `verifyDriver` devuelve UNAVAILABLE.

`VerificacionConductorService` aplica las reglas: verificar nunca cambia el estado; aprobar exige que la última verificación concluyente (no UNAVAILABLE) de la placa actual sea VERIFIED; rechazar exige motivo; cualquier fallo del proveedor se traduce a UNAVAILABLE. Los endpoints antiguos `/admin/aprobar-conductor`, `/admin/rechazar-conductor` y `/api/admin/*-conductor` ahora pasan por este servicio (misma regla y auditoría).

Auditoría: colección nueva `auditoria_verificacion` (conductor, acción, resultado, fuente, placa, documento enmascarado, admin, motivo, fecha). Solo se agregan registros.

## Endpoints (solo ROLE_ADMIN; `/api/admin/**` ya lo exige en `SecurityConfig`, más `@PreAuthorize`)
- `GET /api/admin/verificacion/estado?email=`
- `POST /api/admin/verificacion/verificar` `{email, ownerDocument?}` (máx. 20/min por admin → 429)
- `POST /api/admin/verificacion/manual` `{email, resultado: VERIFIED|NOT_FOUND|MISMATCH, nota}`
- `POST /api/admin/verificacion/decision` `{email, aprobar, motivo}`

No se tocaron `SecurityConstants`/`SecurityConfig`. Como `/api/**` no usa CSRF (usa sesión o JWT, igual que el resto de la API admin), no se añadió token.

## Activación y variables de entorno
| Variable | Valor |
|---|---|
| `VERIFICATION_PROVIDER` | `manual` (default), `mock`, `real` |
| `VERIFICATION_API_BASE_URL` | p. ej. la URL base del proveedor (solo `real`) |
| `VERIFICATION_API_KEY` | token del proveedor (solo `real`; nunca en el repo) |
| `VERIFICATION_TIMEOUT_MS` | 5000 |
| `VERIFICATION_MAX_PER_MINUTE` | 30 consultas externas |
| `VERIFICATION_REQUIRE_VERIFIED` | `true`; en `false` se permite aprobar sin verificación (no recomendado) |

`real` sin URL o clave degrada a `manual` con una advertencia en el log.

## Limitaciones (lo que NO se logró)
- No hay verificación automática gratuita; el adaptador real no se probó contra el servicio (no hay cuenta ni red en el entorno de desarrollo) y su mapeo de respuesta sale solo de la documentación pública.
- La licencia de conducción no se verifica automáticamente con ninguna fuente.
- La app no guarda cédula del conductor ni del propietario; solo licencia, SOAT y tarjeta de propiedad. Para consultar el RUNT por placa hay que digitar a mano la cédula del propietario.
- Límite de tasa en memoria (por instancia).
- No se pudo levantar la app ni correr pruebas con Spring completo ni MongoDB. La UI del dashboard no se probó en navegador; solo verificada la sintaxis del JS.

## Siguiente paso recomendado
1. Solicitar a la Concesión RUNT 2.0 el convenio y la especificación del web service (o negociar con un proveedor y revisar precio, contrato y tratamiento de datos).
2. Revisión legal (Ley 1581 de 2012): autorizaciones, política de tratamiento, encargados del tratamiento.
3. Capturar la cédula del conductor en el registro (con autorización) y añadir validación de licencia cuando haya fuente.
4. Probar el adaptador real con credenciales de prueba y ajustar el mapeo.
