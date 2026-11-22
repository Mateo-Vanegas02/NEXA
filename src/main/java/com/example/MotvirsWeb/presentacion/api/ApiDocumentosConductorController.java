package com.example.MotvirsWeb.presentacion.api;

import com.example.MotvirsWeb.aplicacion.servicio.DocumentosConductorService;
import com.example.MotvirsWeb.aplicacion.util.UsuarioContextHelper;
import com.example.MotvirsWeb.dominio.modelo.DocumentoConductor;
import com.example.MotvirsWeb.dominio.regla.VigenciaDocumento;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Clock;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;

/**
 * Los documentos del conductor autenticado con su vigencia (para el perfil de la app). Sin el archivo ni el número
 * declarado: solo qué documento es y cuándo vence.
 */
@RestController
@RequestMapping("/api/conductor")
public class ApiDocumentosConductorController {

    public record MiDocumento(String id, String tipo, String vehiculoId, LocalDate venceEl, String vigencia,
                              Long diasRestantes) {
    }

    private final DocumentosConductorService documentos;
    private final UsuarioContextHelper usuarioContext;
    private final Clock clock;

    public ApiDocumentosConductorController(DocumentosConductorService documentos,
                                            UsuarioContextHelper usuarioContext, Clock clock) {
        this.documentos = documentos;
        this.usuarioContext = usuarioContext;
        this.clock = clock;
    }

    @GetMapping("/documentos")
    public List<MiDocumento> misDocumentos() {
        String conductorId = usuarioContext.getConductorAutenticado().getIdString();
        LocalDate hoy = LocalDate.now(clock);
        return documentos.listarPorConductor(conductorId).stream()
                .sorted(Comparator.comparing(DocumentoConductor::getTipo))
                .map(d -> new MiDocumento(d.getId(), d.getTipo().name(), d.getVehiculoId(), d.getVenceEl(),
                        VigenciaDocumento.de(d.getTipo(), d.getVenceEl(), hoy).name(),
                        VigenciaDocumento.diasRestantes(d.getVenceEl(), hoy)))
                .toList();
    }
}
