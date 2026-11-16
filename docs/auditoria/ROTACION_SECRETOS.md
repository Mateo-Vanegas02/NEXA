# Rotación de secretos

No se imprimen ni se incluyen valores de secretos en este documento.

Si existieron credenciales reales en versiones históricas, el propietario debe:

1. Revocar y regenerar `JWT_SECRET`, credenciales MongoDB, SMTP, Gemini, Firebase, verificación externa y claves AWS/Azure afectadas.
2. Revisar los secretos configurados en GitHub Actions, el proveedor de despliegue y el gestor de secretos.
3. Crear un `.env` local desde `.env.example` sin subirlo al repositorio.
4. Invalidar sesiones/tokens emitidos con claves anteriores y rotar también credenciales SMTP o Firebase si fueron expuestas.
5. Revisar accesos y logs del periodo comprometido.

No se ejecutó ninguna rotación porque requiere autorización y acceso a infraestructura real.
