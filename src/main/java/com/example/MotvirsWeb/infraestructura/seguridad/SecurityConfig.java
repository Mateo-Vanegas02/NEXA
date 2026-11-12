package com.example.MotvirsWeb.infraestructura.seguridad;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;

import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

        private final AuthenticationSuccessHandler authenticationSuccessHandler;
        private final org.springframework.security.web.authentication.AuthenticationFailureHandler authenticationFailureHandler;
        private final CustomUserDetailsService customUserDetailsService;
        private final SecurityExceptionHandler securityExceptionHandler;
        private final JwtAuthFilter jwtAuthFilter;
        private final RateLimitFilter rateLimitFilter;
        private final BloqueoCierreSesionFilter bloqueoCierreSesionFilter;

        @Bean
        public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
                http
                                // CSRF: /api/** solo se exime cuando se autentica con JWT (cabecera
                                // Bearer, que el navegador no envia solo). Con cookie de sesion
                                // (panel admin web) se exige el token CSRF.
                                .csrf(csrf -> csrf
                                                .ignoringRequestMatchers(SecurityConstants.WEBSOCKET_URLS)
                                                .ignoringRequestMatchers("/api/auth/login", "/api/auth/registro/**")
                                                .ignoringRequestMatchers(SecurityConfig::usaBearer)
                                                .ignoringRequestMatchers("/auth/**")
                                                .ignoringRequestMatchers("/public/**"))
                                .authorizeHttpRequests(auth -> auth
                                                .requestMatchers(SecurityConstants.STATIC_RESOURCES).permitAll()
                                                .requestMatchers(SecurityConstants.PUBLIC_URLS).permitAll()
                                                // API Específicas (Roles)
                                                .requestMatchers(SecurityConstants.API_PASAJERO_URLS)
                                                .hasRole("PASAJERO")
                                                .requestMatchers(SecurityConstants.API_CONDUCTOR_URLS)
                                                .hasRole("CONDUCTOR")
                                                // Web Específicas (Roles)
                                                .requestMatchers(SecurityConstants.PASAJERO_URLS).hasRole("PASAJERO")
                                                .requestMatchers(SecurityConstants.CONDUCTOR_URLS).hasRole("CONDUCTOR")
                                                .requestMatchers(SecurityConstants.ADMIN_URLS).hasRole("ADMIN")
                                                // General API (debe ir después de las específicas)
                                                .requestMatchers(SecurityConstants.API_NIVELES_PASAJERO_URLS).hasRole("PASAJERO")
                                                .requestMatchers(SecurityConstants.API_NIVELES_URLS).hasAnyRole("PASAJERO", "CONDUCTOR")
                                                .requestMatchers(SecurityConstants.API_PERFIL_URLS).hasAnyRole("PASAJERO", "CONDUCTOR")
                                                .requestMatchers(SecurityConstants.API_DISPOSITIVOS_URLS)
                                                .hasAnyRole("PASAJERO", "CONDUCTOR", "ADMIN")
                                                .requestMatchers(SecurityConstants.API_URLS).authenticated()
                                                .requestMatchers(SecurityConstants.SHARED_URLS)
                                                .hasAnyRole("CONDUCTOR", "PASAJERO", "ADMIN")
                                                .anyRequest().authenticated())
                                .formLogin(form -> form
                                                .loginPage("/auth/login")
                                                .loginProcessingUrl("/login")
                                                .successHandler(authenticationSuccessHandler)
                                                .failureHandler(authenticationFailureHandler)
                                                .permitAll())
                                .logout(logout -> logout
                                                .logoutUrl("/auth/logout")
                                                .logoutSuccessUrl("/auth/login?logout=true")
                                                .invalidateHttpSession(true)
                                                .deleteCookies("JSESSIONID")
                                                .permitAll())
                                .sessionManagement(session -> session
                                                .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)) // Cambiado
                                                                                                           // para
                                                                                                           // permitir
                                                                                                           // stateless
                                                                                                           // bajo
                                                                                                           // demanda
                                .exceptionHandling(ex -> ex
                                                .accessDeniedHandler(securityExceptionHandler)
                                                .authenticationEntryPoint(securityExceptionHandler))
                                .headers(h -> h
                                                .referrerPolicy(r -> r.policy(
                                                                ReferrerPolicyHeaderWriter.ReferrerPolicy.STRICT_ORIGIN_WHEN_CROSS_ORIGIN))
                                                .permissionsPolicy(pp -> pp
                                                                .policy("geolocation=(self), camera=(), microphone=(), payment=()")))
                                .addFilterBefore(rateLimitFilter, UsernamePasswordAuthenticationFilter.class)
                                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)
                                .addFilterBefore(bloqueoCierreSesionFilter,
                                                org.springframework.security.web.authentication.logout.LogoutFilter.class)
                                .userDetailsService(customUserDetailsService);

                return http.build();
        }

        private static boolean usaBearer(jakarta.servlet.http.HttpServletRequest request) {
                String auth = request.getHeader("Authorization");
                return auth != null && auth.startsWith("Bearer ") && request.getRequestURI().startsWith("/api/");
        }

        @Bean
        public static PasswordEncoder passwordEncoder() {
                return new BCryptPasswordEncoder();
        }

        @Bean
        public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
                return config.getAuthenticationManager();
        }
}
