# CSP progresiva (diseño, no activada)

Las plantillas Thymeleaf aún contienen scripts y estilos inline, manejadores `onclick`/`onchange` y atributos `style`. Un inventario estático de esta fase encontró 5 bloques de script, 3 de estilo, 75 manejadores y 121 estilos inline; verificar de nuevo antes de desplegar una política. Se concentran en paneles de conductor, pasajero y administrador. Hay recursos externos de Leaflet, Font Awesome, Google Fonts, mapa y Power BI; el JavaScript del pasajero consulta Nominatim, Photon y OSRM. La lista exacta de orígenes debe salir de las plantillas y de observación de red en cada entorno, no de una cabecera demasiado amplia.

## Secuencia propuesta

1. Mover manejadores y scripts inline a archivos locales con listeners, y estilos repetidos a CSS. Mantener las pruebas de paneles y mapas.
2. Definir una política por rutas con `default-src 'self'`, fuentes explícitas para `script-src`, `style-src`, `font-src`, `img-src`, `connect-src` y `frame-src`; usar nonce/hash donde haya inline que no pueda retirarse aún. Evitar `unsafe-inline` como política definitiva.
3. Activar primero `Content-Security-Policy-Report-Only` en pruebas, inspeccionar reportes sin guardar datos personales y verificar login, paneles, mapa, chat, ML, Power BI y recuperación. Ajustar orígenes concretos y pasar a enforcement en una etapa separada.

No se activó ninguna cabecera CSP en esta fase para evitar romper funcionalidades existentes.
