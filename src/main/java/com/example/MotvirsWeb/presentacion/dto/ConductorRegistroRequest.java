package com.example.MotvirsWeb.presentacion.dto;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import com.example.MotvirsWeb.aplicacion.servicio.DocumentosConductorService;
import com.example.MotvirsWeb.aplicacion.servicio.RegistroConductorService;
import com.example.MotvirsWeb.dominio.modelo.TipoDocumento;
import lombok.Data;
import org.springframework.web.multipart.MultipartFile;

@Data
public class ConductorRegistroRequest {

    @NotBlank(message = "El nombre es obligatorio")
    @Size(min = 3, max = 100, message = "El nombre debe tener entre 3 y 100 caracteres")
    @Pattern(regexp = "^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\\s]+$", message = "El nombre solo puede contener letras y espacios")
    private String nombre;

    @NotBlank(message = "El email es obligatorio")
    @Email(message = "Formato de email inválido")
    @Size(max = 100, message = "El email no puede exceder 100 caracteres")
    private String email;

    @NotBlank(message = "El teléfono es obligatorio")
    @Pattern(regexp = "^3\\d{9}$", message = "El teléfono debe ser un número colombiano válido de 10 dígitos que empiece con 3 (ej: 3001234567)")
    private String telefono;

    @NotBlank(message = "La contraseña es obligatoria")
    @Size(min = 8, max = 100, message = "La contraseña debe tener al menos 8 caracteres")
    @Pattern(regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).+$", message = "La contraseña debe contener al menos una mayúscula, una minúscula y un número")
    private String password;

    @NotBlank(message = "Debe confirmar la contraseña")
    private String confirmPassword;

    @NotBlank(message = "El número de licencia es obligatorio")
    @Pattern(regexp = "^\\d{6,15}$", message = "La licencia debe ser un número de 6 a 15 dígitos")
    private String licencia;

    @NotBlank(message = "La placa del vehículo es obligatoria")
    @Pattern(regexp = "^[A-Za-z]{3}[A-Za-z0-9]{3}$", message = "La placa debe tener 6 caracteres (ej: ABC123)")
    private String placa;

    @NotBlank(message = "La marca del vehículo es obligatoria")
    @Size(min = 2, max = 50, message = "La marca debe tener entre 2 y 50 caracteres")
    @Pattern(regexp = "^[a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\\s]+$", message = "La marca contiene caracteres no válidos")
    private String marca;

    @NotBlank(message = "El modelo del vehículo es obligatorio")
    @Size(min = 1, max = 50, message = "El modelo no puede exceder 50 caracteres")
    @Pattern(regexp = "^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\\s-]+$", message = "El modelo contiene caracteres no válidos")
    private String modelo;

    @NotBlank(message = "El color del vehículo es obligatorio")
    @Size(max = 30, message = "El color no puede exceder 30 caracteres")
    @Pattern(regexp = "^[a-zA-ZáéíóúÁÉÍÓÚñÑ\\s]+$", message = "El color solo puede contener letras")
    private String color;

    @NotBlank(message = "La tarjeta de propiedad es obligatoria")
    @Pattern(regexp = "^\\d{8,15}$", message = "La tarjeta de propiedad debe ser un número de 8 a 15 dígitos")
    private String tarjetaPropiedad;

    @NotBlank(message = "El número SOAT es obligatorio")
    @Pattern(regexp = "^\\d{12}$", message = "El SOAT debe ser un número de 12 dígitos")
    private String soat;

    @NotBlank(message = "El número de tecnomecánica es obligatorio")
    @Pattern(regexp = "^\\d{6,15}$", message = "La tecnomecánica debe ser un número de 6 a 15 dígitos")
    private String tecnomecanica;

    // Fotos de los documentos: el administrador las contrasta con los números anteriores.
    // Tamaño y tipo real (JPG/PNG/WebP, máx. 5 MB) los valida DocumentosConductorService.
    @NotNull(message = "Adjunta la foto de la licencia de conducción")
    private MultipartFile fotoLicencia;

    @NotNull(message = "Adjunta la foto de la tarjeta de propiedad")
    private MultipartFile fotoTarjetaPropiedad;

    @NotNull(message = "Adjunta la foto del SOAT")
    private MultipartFile fotoSoat;

    @NotNull(message = "Adjunta la foto de la tecnomecánica")
    private MultipartFile fotoTecnomecanica;

    @AssertTrue(message = "Las contraseñas no coinciden")
    public boolean isPasswordMatch() {
        return password != null && password.equals(confirmPassword);
    }

    /** Convierte el formulario ya validado en la solicitud de la capa de aplicación (compartido por web y app móvil). */
    public RegistroConductorService.Solicitud aSolicitud() {
        java.util.List<DocumentosConductorService.ArchivoSubido> fotos = java.util.List.of(
                foto(TipoDocumento.LICENCIA, fotoLicencia),
                foto(TipoDocumento.TARJETA_PROPIEDAD, fotoTarjetaPropiedad),
                foto(TipoDocumento.SOAT, fotoSoat),
                foto(TipoDocumento.TECNOMECANICA, fotoTecnomecanica));
        return new RegistroConductorService.Solicitud(nombre, email, password, telefono,
                Long.parseLong(licencia), placa, marca, modelo, color, Long.parseLong(tarjetaPropiedad),
                Long.parseLong(soat), Long.parseLong(tecnomecanica), fotos);
    }

    private static DocumentosConductorService.ArchivoSubido foto(TipoDocumento tipo, MultipartFile f) {
        return new DocumentosConductorService.ArchivoSubido(tipo, null, f.getOriginalFilename(), f.getSize(),
                f::getInputStream);
    }
}
