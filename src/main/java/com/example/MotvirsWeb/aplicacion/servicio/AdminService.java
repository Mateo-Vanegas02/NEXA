package com.example.MotvirsWeb.aplicacion.servicio;

import com.example.MotvirsWeb.dominio.modelo.Conductor;
import com.example.MotvirsWeb.dominio.modelo.EstadoValidacion;
import com.example.MotvirsWeb.dominio.modelo.Usuario;
import java.util.List;
import java.util.Map;

public interface AdminService {
    Map<String, Object> obtenerResumenDashboard();

    List<Conductor> obtenerConductoresPorEstado(EstadoValidacion estado);

    void aprobarConductor(String email);

    void rechazarConductor(String email);

    Map<String, Object> obtenerEstadisticasAjax();

    List<Usuario> obtenerTodosLosConductores();

    void actualizarPreferenciaNotificaciones(String email, boolean habilitado);
}
