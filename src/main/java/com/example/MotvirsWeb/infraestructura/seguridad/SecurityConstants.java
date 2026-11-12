package com.example.MotvirsWeb.infraestructura.seguridad;

public class SecurityConstants {

        public static final String[] PUBLIC_URLS = {
                        "/",
                        "/auth/**",
                        "/login",
                        "/api/auth/login",
                        "/api/auth/registro/**",
                        "/registro/**",
                        "/public/**"
        };

        public static final String[] STATIC_RESOURCES = {
                        "/css/**",
                        "/icon/**",
                        "/js/**",
                        "/img/**",
                        "/error/**",
                        "/favicon.ico"
        };

        public static final String[] PASAJERO_URLS = {
                        "/pasajero/**",
                        "/pasajero/panel**"
        };

        public static final String[] CONDUCTOR_URLS = {
                        "/conductor/**",
                        "/conductor/panel**"
        };

        public static final String[] ADMIN_URLS = {
                        "/admin/**",
                        "/api/admin/ml",
                        "/api/admin/**"
        };

        public static final String[] API_PASAJERO_URLS = {
                        "/api/pasajero/**"
        };

        public static final String[] API_CONDUCTOR_URLS = {
                        "/api/conductor/**"
        };

        /** Niveles: solo pasajero y conductor (el admin no participa del sistema). */
        public static final String[] API_NIVELES_URLS = {
                        "/api/niveles/me",
                        "/api/niveles/viajes/**"
        };

        /** Los conductores favoritos son un beneficio exclusivo del pasajero. */
        public static final String[] API_NIVELES_PASAJERO_URLS = {
                        "/api/niveles/favoritos/**"
        };

        /** Perfil y foto propia: solo pasajero y conductor (la foto de otros usuarios cae en la regla general /api/**). */
        public static final String[] API_PERFIL_URLS = {
                        "/api/perfil",
                        "/api/perfil/**"
        };

        // Tokens de FCM del teléfono (app móvil): cualquier rol con sesión
        public static final String[] API_DISPOSITIVOS_URLS = {
                        "/api/dispositivos"
        };

        public static final String[] SHARED_URLS = {
                        "/rating",
                        "/profile/**"
        };

        public static final String[] WEBSOCKET_URLS = {
                        "/ws/**",
                        "/topic/**"
        };

        public static final String[] API_URLS = {
                        "/api/**"
        };

        private SecurityConstants() {
                // Private constructor to prevent instantiation
        }
}
