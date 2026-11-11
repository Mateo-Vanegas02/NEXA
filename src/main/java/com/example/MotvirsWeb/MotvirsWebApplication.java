package com.example.MotvirsWeb;

import com.example.MotvirsWeb.infraestructura.config.ZonaHorariaNegocio;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class MotvirsWebApplication {

	public static void main(String[] args) {
		// Antes de Spring: todas las fechas (LocalDateTime.now() y el reloj de niveles) en la zona del negocio.
		ZonaHorariaNegocio.aplicar();
		SpringApplication.run(MotvirsWebApplication.class, args);
	}

}
