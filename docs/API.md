# API: contratos verificados

| Ruta | Autenticación | Resultado |
|---|---|---|
| `POST /api/auth/login` | Pública | `LoginResponse` con `token` JWT; 403 con `estadoValidacion` si un conductor no aprobado acredita su contraseña |
| `POST /api/auth/registro/pasajero` | Pública | 201 `{mensaje}`; 409 `{error,message}` ante conflicto |
| `POST /api/auth/registro/conductor` | Pública, multipart | 201 `{mensaje}`; 400 ante documento inválido; 409 ante conflicto |
| `POST /auth/forgot-password` | Sesión web pública | Redirige con mensaje uniforme para evitar enumeración |
| `POST /auth/reset-password` | Token de correo + formulario | Redirige a login tras consumo correcto del token |
| `POST /api/admin/ml/entrenar` | ADMIN | Entrena el modelo; con sesión web requiere CSRF |

`/api/**` usa Bearer cuando la petición viene de la app. La web utiliza sesión y CSRF en acciones que modifican estado. Los JWT se emiten por 24 h y aún no tienen revocación; ver `auditoria/DISENO_JWT.md`. La lista completa de controladores está en `src/main/java/com/example/MotvirsWeb/presentacion/` y las reglas de acceso en `SecurityConstants.java`. No se deben inferir rutas a partir de nombres de clases.
