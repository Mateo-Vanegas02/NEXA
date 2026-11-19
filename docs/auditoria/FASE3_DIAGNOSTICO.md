# Fase 3: diagnóstico del entorno

Fecha: 2026-11-16. Rama de trabajo: `codex/fase-3-validacion`, basada en `codex/fase-2-integridad`; `main` permanece en `cdc989f`. Al comenzar, el árbol estaba limpio. PR #2 y #3 son borradores; ningún cambio de esta fase se fusionó en `main`.

Java 21, Maven 3.9.9, Node 24.12 y Python 3.14 están disponibles. No hay Docker, Podman, `mongod`, `mongosh`, Database Tools, `git-filter-repo` ni Gitleaks preinstalados. Gitleaks 8.30.1 se descargó de la publicación oficial y se verificó con SHA-256; el ejecutable y los informes redactados están fuera del repositorio. GitHub Actions sí ofrece Docker y ejecutó Testcontainers. La suite Java inicial pasó con 565 pruebas; la suite JavaScript de fase 2 había pasado 123 pruebas.

Compass está instalado, pero la revisión automática del entorno rechazó su control por interfaz. No se pudo identificar su conexión ni verificar si apunta a desarrollo o producción. No se encontró una URI de MongoDB autorizada en las variables del proceso. Por ello no se consultaron datos reales, no se respaldó ninguna base, no se aplicaron índices y no se hicieron migraciones. La ausencia de acceso no demuestra ausencia de duplicados.

Riesgos prioritarios: identidad ambigua por correo compartido; índices efectivos desconocidos en producción; transiciones de viaje que usan lectura seguida de `save`; posible material publicado mediante Power BI; configuración cliente Firebase en la historia de la rama `app`. Los resultados de MongoDB de esta fase proceden exclusivamente de un contenedor aislado con datos sintéticos.
