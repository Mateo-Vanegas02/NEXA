# Dependencias del proyecto

Maven (`pom.xml`) es el gestor de dependencias de este proyecto Java; cumple el papel que `requirements.txt` cumple en Python. No existe `requirements.txt` porque no hay código Python en la aplicación.

- Java: 21
- Spring Boot: 3.4.4
- Instalar/actualizar: `./mvnw clean install`; ver árbol: `./mvnw dependency:tree`

| Grupo | Artefacto | Versión | Ámbito |
|---|---|---|---|
| org.springframework.boot | spring-boot-starter-data-mongodb | gestionada por Spring Boot 3.4.4 | compile |
| org.springframework.boot | spring-boot-starter-security | gestionada por Spring Boot 3.4.4 | compile |
| org.springframework.boot | spring-boot-starter-thymeleaf | gestionada por Spring Boot 3.4.4 | compile |
| org.springframework.boot | spring-boot-starter-web | gestionada por Spring Boot 3.4.4 | compile |
| org.thymeleaf.extras | thymeleaf-extras-springsecurity6 | gestionada por Spring Boot 3.4.4 | compile |
| org.springframework.boot | spring-boot-starter-validation | gestionada por Spring Boot 3.4.4 | compile |
| org.springframework.boot | spring-boot-starter-mail | gestionada por Spring Boot 3.4.4 | compile |
| org.projectlombok | lombok | gestionada por Spring Boot 3.4.4 | compile |
| org.springframework.boot | spring-boot-devtools | gestionada por Spring Boot 3.4.4 | runtime |
| org.springframework.boot | spring-boot-starter-test | gestionada por Spring Boot 3.4.4 | test |
| org.springframework.security | spring-security-test | gestionada por Spring Boot 3.4.4 | test |
| org.springframework.boot | spring-boot-starter-websocket | gestionada por Spring Boot 3.4.4 | compile |
| nz.ac.waikato.cms.weka | weka-stable | 3.8.6 | compile |
| io.jsonwebtoken | jjwt-api | 0.12.5 | compile |
| io.jsonwebtoken | jjwt-impl | 0.12.5 | runtime |
| io.jsonwebtoken | jjwt-jackson | 0.12.5 | runtime |
| org.springframework.ai | spring-ai-starter-model-google-genai | gestionada por Spring Boot 3.4.4 | compile |
| com.google.ortools | ortools-java | 9.8.3296 | compile |

## Variables de entorno

El equivalente a la configuración externa está en `.env.example` (plantilla) y `README.md`. Los secretos nunca se versionan.
