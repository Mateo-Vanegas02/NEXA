# Fase 3.1 — secretos e historial

Se identificó el repositorio público `Frank923-coder/NEXA_Origin` mediante la conexión de GitHub, pero esta tanda no completó su escaneo histórico ni una verificación administrativa de credenciales. La fase 3 anterior ejecutó Gitleaks sobre referencias accesibles de NEXA y clasificó una coincidencia de configuración Firebase Android; no confirmó credenciales de servidor activas. Véanse `FASE3_SECRETOS.md` y `FASE3_LIMPIEZA_GIT.md` para la trazabilidad anterior.

Estado: exposición histórica concreta, vigencia y repositorios afectados pendientes de confirmar. No se rotaron ni revocaron credenciales; no se simuló filtrado de objetos ni se reescribió historial remoto. Toda rotación debe coordinarse con el despliegue. Una eventual limpieza remota requiere autorización específica para las referencias afectadas.

La [guía oficial de GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository) indica revocar o rotar primero los secretos confirmados. Una reescritura local con `git-filter-repo` exige inventariar referencias y PR afectados, coordinar clones y bifurcaciones, y solicitar a GitHub Support la limpieza de referencias internas y vistas en caché cuando corresponda. Esta fase no tiene aún un secreto de servidor confirmado que justifique esa operación.
