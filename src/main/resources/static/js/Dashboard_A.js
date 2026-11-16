// Variable global para el gráfico de registros
let registrosChart;
let stompClient = null;

document.addEventListener("DOMContentLoaded", () => {
    initDashboard();
    setupEventListeners();
    setupInitialToggleLogic();
    initNotificationSettings(); // Configuración de notificaciones
    connectAdminWebSocket();

    // 1. CONFIGURACIÓN DEL TOGGLE NOTIFICACIONES
    const notifToggle = document.getElementById('notif');
    if (notifToggle) {
        notifToggle.addEventListener('change', function () {
            const isEnabled = this.checked;
            const csrfToken = document.querySelector('input[name="_csrf"]')?.value;

            // FormData para enviar al backend
            const formData = new FormData();
            formData.append('habilitado', isEnabled);

            fetch('/admin/config/notificaciones', {
                method: 'POST',
                headers: { 'X-CSRF-TOKEN': csrfToken },
                body: formData
            })
                .then(res => res.json())
                .then(data => {
                    if (data.success) showToast('Configuración guardada', data.message, 'success');
                    else {
                        showToast('Error', 'No se pudo guardar la configuración', 'error');
                        this.checked = !isEnabled; // Revertir visualmente
                    }
                })
                .catch(() => {
                    showToast('Error de conexión', 'Verifica tu internet', 'error');
                    this.checked = !isEnabled;
                });
        });
    }

    // 2. INICIAR WEBSOCKET PARA ADMIN
    connectAdminWebSocket();
});


// Lógica del Modal Manual
window.openPermissionsModal = function () {
    const modal = document.getElementById('permissionsModal');
    if (modal) {
        modal.style.display = 'flex';
        setTimeout(() => modal.classList.add('active'), 10);
    }
}

window.closePermissionsModal = function () {
    const modal = document.getElementById('permissionsModal');
    if (modal) {
        modal.classList.remove('active');
        setTimeout(() => modal.style.display = 'none', 300);
    }
}

// WebSocket Admin
function connectAdminWebSocket() {
    const socket = new SockJS('/ws');
    const stompClient = Stomp.over(socket);
    stompClient.debug = null; // Desactivar logs ruidosos en consola

    stompClient.connect({}, function () {
        // Suscripción al canal de registros
        stompClient.subscribe('/topic/admin/registros', function (message) {

            // VERIFICACIÓN: Solo mostrar si el switch está activo visualmente
            const toggle = document.getElementById('notif');
            if (toggle && toggle.checked) {
                const data = JSON.parse(message.body);
                showToast(
                    'Nuevo Usuario Registrado',
                    `${data.email} (${data.rol})`,
                    'success'
                );

                // Opcional: Recargar contadores si estás en la vista 'home'
                if (typeof fetchDashboardData === 'function') fetchDashboardData();
            }
        });
    });
}

// Función Toast Genérica
function showToast(title, message, type) {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.innerHTML = `
        <i class="fas ${type === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle'}"></i>
        <div class="toast-content">
            <h4>${title}</h4>
            <p>${message}</p>
        </div>
    `;
    document.body.appendChild(toast);

    // Auto remover después de 4 segundos
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(100%)';
        setTimeout(() => toast.remove(), 300);
    }, 4000);
}

// --- FUNCIONES DE INICIALIZACIÓN ---

function initDashboard() {
    // Configurar nombre de usuario y sus iniciales para el modo colapsado
    const userNameSpan = document.querySelector(".sidebar-header .logo-text");
    if (userNameSpan) {
        const nombreUsuario = userNameSpan.textContent.trim() || "Administrador";
        const iniciales = nombreUsuario.split(' ').map(n => n[0]).join('').toUpperCase();
        userNameSpan.dataset.nombre = nombreUsuario;
        userNameSpan.dataset.initiales = iniciales;
    }

    // Configurar sección activa al cargar la página (usa el hash o 'home' por defecto)
    const currentSection = window.location.hash.substring(1) || 'home';
    showSection(currentSection);
}

function setupEventListeners() {
    document.addEventListener('click', (e) => {
        const modal = document.getElementById("infoModal");
        // Cerrar modal al hacer clic fuera
        if (e.target === modal && modal) closeModal();
    });

    document.addEventListener('keydown', (e) => {
        // Cerrar modal con ESC
        if (e.key === 'Escape') closeModal();
    });

    // --- Lógica del Botón de Hamburguesa (Móvil) ---
    const sidebar = document.getElementById('sidebar');
    const toggleMobileButtons = document.querySelectorAll('.menu-toggle-btn');

    toggleMobileButtons.forEach(button => {
        button.addEventListener('click', () => {
            if (sidebar && window.innerWidth <= 992) {
                // SOLO en móvil, alternamos la clase 'active' para abrir/cerrar el overlay.
                sidebar.classList.toggle('active');
            }
        });
    });

    // --- Lógica para el cierre automático del sidebar en móvil al hacer clic en un ítem ---
    document.querySelectorAll('.sidebar ul li').forEach(item => {
        item.addEventListener('click', () => {
            if (sidebar && window.innerWidth <= 992) {
                sidebar.classList.remove('active');
                sidebar.classList.remove('collapsed');
            }
        });
    });
}

function setupInitialToggleLogic() {
    // Maneja el toggle de ESCRITORIO (las flechas)
    const toggleDesktop = document.querySelector('.sidebar-header .toggle-btn');

    if (toggleDesktop) {
        toggleDesktop.addEventListener('click', () => {
            // Llama a la función que gestiona el colapso/expansión del sidebar
            toggleSidebarDesktop();
        });
    }
}


// --- FUNCIONES DE NAVEGACIÓN Y TOGGLE ---

function toggleSidebarDesktop() {
    const sidebar = document.getElementById("sidebar");
    if (!sidebar) return;

    const icon = sidebar.querySelector(".toggle-btn i");
    const userName = document.querySelector(".sidebar-header .logo-text");
    const mainContent = document.querySelector(".main");

    // 1. Alterna la clase 'collapsed' en el sidebar
    sidebar.classList.toggle("collapsed");

    // 2. Ajusta el ícono y el nombre de usuario
    if (icon && userName) {
        icon.classList.toggle("fa-angle-double-left");
        icon.classList.toggle("fa-angle-double-right");

        userName.textContent = sidebar.classList.contains("collapsed")
            ? userName.dataset.initiales || "ADM"
            : userName.dataset.nombre || "Administrador";
    }

    // 3. Aplica la clase 'collapsed' al main content (para ajustar el margen en desktop)
    if (mainContent) {
        mainContent.classList.toggle('collapsed', sidebar.classList.contains("collapsed"));
    }
}
// Asegura que window.toggleSidebar apunte a la función correcta (para el onclick en HTML)
window.toggleSidebar = toggleSidebarDesktop;


function showSection(sectionId) {
    if (!sectionId) return;

    // 1. Ocultar todas las secciones
    document.querySelectorAll(".section").forEach((section) => {
        section.classList.remove("active");
    });

    // 2. Mostrar la sección deseada
    const section = document.getElementById(sectionId);
    if (section) {
        section.classList.add("active");
        window.location.hash = sectionId;
        highlightActiveSidebarItem(sectionId);
    }
}

function highlightActiveSidebarItem(sectionId) {
    if (!sectionId) return;

    const sidebarItems = document.querySelectorAll("#sidebar li");
    if (!sidebarItems.length) return;

    sidebarItems.forEach(item => item.classList.remove("active"));

    // Busca el <li> que tiene el onclick con la función showSection('id')
    const activeItem = document.querySelector(`#sidebar li[onclick*="${sectionId}"]`);
    if (activeItem) activeItem.classList.add("active");
}


// --- FUNCIONES DE UTILIDAD (MODAL, TABLAS, TEMAS, ETC.) ---

function filterTable(status) {
    if (!status) return;

    const rows = document.querySelectorAll("#tabla-conductores tbody tr");
    const buttons = document.querySelectorAll(".btn-filter");

    if (!rows.length || !buttons.length) return;

    buttons.forEach(btn => btn.classList.remove("active"));

    const activeButton = document.querySelector(`.btn-filter[onclick*="${status}"]`);
    if (activeButton) activeButton.classList.add("active");

    rows.forEach(row => {
        const rowStatus = row.dataset.status;
        let shouldShow = false;

        switch (status) {
            case 'all': shouldShow = true; break;
            case 'pending': shouldShow = rowStatus === 'pendiente'; break;
            case 'review': shouldShow = rowStatus === 'en_revision'; break;
            case 'approved': shouldShow = rowStatus === 'aprobado'; break;
            case 'rejected': shouldShow = rowStatus === 'rechazado'; break;
            default: shouldShow = rowStatus === status;
        }

        row.style.display = shouldShow ? "" : "none";
    });
}

function openDriverModal(element) {
    const row = element && element.closest('tr');
    if (!row || !window.VerificacionConductor) return;
    window.VerificacionConductor.abrir({
        nombre: element.dataset.nombre || 'Sin nombre',
        email: element.dataset.email || '',
        telefono: element.dataset.telefono,
        licencia: element.dataset.licencia,
        soat: element.dataset.soat,
        tarjeta: element.dataset.tarjeta,
        estado: row.dataset.status,
        foto: element.dataset.foto || null,
    });
}

function closeModal() {
    const modal = document.getElementById("infoModal");
    if (modal) {
        modal.style.display = "none";
        document.body.style.overflow = "auto";
    }
}

async function fetchDashboardData() {
    try {
        const response = await fetch('/admin/dashboard/actualizar');
        if (!response.ok) throw new Error('Error en la respuesta del servidor');

        const data = await response.json();

        // Actualizar los contadores
        const pasajerosElement = document.getElementById("count-pasajeros");
        const conductoresElement = document.getElementById("count-conductores");
        const pendientesElement = document.getElementById("count-pendientes");

        if (pasajerosElement) pasajerosElement.textContent = data.pasajeros || 0;
        if (conductoresElement) conductoresElement.textContent = data.conductoresAprobados || 0;
        if (pendientesElement) pendientesElement.textContent = data.conductoresPendientes || 0;

        showToast('Datos actualizados correctamente', 'success');

    } catch (error) {
        console.error("Error al actualizar los datos:", error);
        showToast('Error al actualizar los datos', 'error');
    }
}

async function refreshValidationTable() {
    const btn = document.querySelector('.btn-refresh');
    if (btn) btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Cargando...';

    try {
        const response = await fetch('/admin/conductores/actualizar');
        if (!response.ok) throw new Error('Error al obtener datos');

        const conductores = await response.json();
        const tbody = document.querySelector("#tabla-conductores tbody");
        tbody.innerHTML = ''; // Limpiar tabla actual

        // 1. OBTENER EL TOKEN CSRF (IMPORTANTE)
        const csrfToken = document.querySelector('input[name="_csrf"]')?.value || '';

        if (conductores.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" class="no-data">No hay conductores registrados</td></tr>';
        } else {
            conductores.forEach(c => {
                let estadoClass = '';
                let estadoTexto = c.estadoValidacion;

                if (estadoTexto === 'APROBADO') estadoClass = 'status-approved';
                else if (estadoTexto === 'RECHAZADO') estadoClass = 'status-rejected';
                else if (estadoTexto === 'EN_REVISION') estadoClass = 'status-review';
                else estadoClass = 'status-pending';

                let accionesHtml = '';
                // Solo mostramos botones si no está finalizado
                if (estadoTexto !== 'APROBADO' && estadoTexto !== 'RECHAZADO') {
                    // 2. INYECTAMOS EL TOKEN EN LOS FORMULARIOS DINÁMICOS
                    accionesHtml = `
                        <div class="action-buttons">
                            <form action="/admin/aprobar-conductor" method="post" style="display:inline;">
                                <input type="hidden" name="_csrf" value="${csrfToken}">
                                <input type="hidden" name="email" value="${c.email}">
                                <button type="submit" class="btn-approve"><i class="fas fa-check"></i></button>
                            </form>
                            <form action="/admin/rechazar-conductor" method="post" style="display:inline;">
                                <input type="hidden" name="_csrf" value="${csrfToken}">
                                <input type="hidden" name="email" value="${c.email}">
                                <button type="submit" class="btn-reject"><i class="fas fa-times"></i></button>
                            </form>
                        </div>
                    `;
                } else {
                    accionesHtml = `<span class="no-actions">${estadoTexto}</span>`;
                }

                const tr = document.createElement('tr');
                tr.setAttribute('data-status', estadoTexto.toLowerCase());

                // Nota: Asegúrate de manejar los nulls en data attributes para evitar "null" en pantalla
                tr.innerHTML = `
                    <td class="clickable" onclick="openDriverModal(this)"
                        data-nombre="${c.nombre_y_Apellido || ''}"
                        data-email="${c.email}"
                        data-telefono="${c.ntelefono || ''}"
                        data-licencia="${c.licencia || ''}"
                        data-soat="${c.soat || 'No disponible'}"
                        data-tarjeta="${c.tarjeta_de_propiedad || 'No disponible'}">
                        ${c.nombre_y_Apellido || 'Sin Nombre'}
                    </td>
                    <td>${c.email}</td>
                    <td>${c.ntelefono || '-'}</td>
                    <td>${c.licencia || '-'}</td>
                    <td><span class="${estadoClass}">${estadoTexto}</span></td>
                    <td>${accionesHtml}</td>
                `;
                tbody.appendChild(tr);
            });
        }

        const activeFilter = document.querySelector('.btn-filter.active');
        if (activeFilter) {
            // Re-aplicar filtro visual simple si es necesario
            // filterTable('all');
            // O mejor, leer el filtro actual:
            const filterType = activeFilter.textContent.trim().toLowerCase();
            // (Esto requeriría ajustar tu lógica de filterTable, por ahora dejémoslo en all o null)
            filterTable('all');
        }

        showToast('Tabla actualizada', 'success');

    } catch (error) {
        console.error("Error:", error);
        showToast('Error al actualizar tabla', 'error');
    } finally {
        if (btn) btn.innerHTML = '<i class="fas fa-sync-alt"></i> Actualizar';
    }
}

function changeTheme(theme) {
    const root = document.documentElement.style;
    const lightOption = document.querySelector('.theme-option.light');
    const darkOption = document.querySelector('.theme-option.dark');

    if (!lightOption || !darkOption) return;

    if (theme === 'light') {
        lightOption.classList.add('active');
        darkOption.classList.remove('active');

        // Tema claro
        root.setProperty('--bg-body', 'linear-gradient(to right, #e2e2e2, #c9d6ff)');
        root.setProperty('--bg-sidebar', 'linear-gradient(180deg, #00c4ff 0%, #004F78 100%)');
        root.setProperty('--bg-main', 'transparent');
        root.setProperty('--bg-card', '#fff');
        root.setProperty('--bg-table-header', '#f8f9fa');
        root.setProperty('--bg-modal', '#fff');
        root.setProperty('--bg-settings', '#fff');
        root.setProperty('--text-primary', '#333');
        root.setProperty('--text-secondary', '#666');
        root.setProperty('--text-light', '#f7f7f7');
        root.setProperty('--border', '#f0f8ff');
        root.setProperty('--shadow', 'rgba(0, 0, 0, 0.05)');
        root.setProperty('--shadow-hover', 'rgba(0, 196, 255, 0.2)');
    } else if (theme === 'dark') {
        darkOption.classList.add('active');
        lightOption.classList.remove('active');

        // Tema oscuro
        root.setProperty('--bg-body', 'linear-gradient(to right, #1a1a1a, #2d2d2d)');
        root.setProperty('--bg-sidebar', 'linear-gradient(180deg, #004F78 0%, #001a2e 100%)');
        root.setProperty('--bg-main', 'transparent');
        root.setProperty('--bg-card', '#2d2d2d');
        root.setProperty('--bg-table-header', '#1a1a1a');
        root.setProperty('--bg-modal', '#2d2d2d');
        root.setProperty('--bg-settings', '#2d2d2d');
        root.setProperty('--text-primary', '#f0f0f0');
        root.setProperty('--text-secondary', '#ccc');
        root.setProperty('--text-light', '#f0f0f0');
        root.setProperty('--border', '#444');
        root.setProperty('--shadow', 'rgba(0, 0, 0, 0.3)');
        root.setProperty('--shadow-hover', 'rgba(0, 196, 255, 0.3)');
    }
}

function showToast(message, type) {
    if (!message || !type) return;

    try {
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;

        toast.innerHTML = `
            <i class="fas ${type === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle'}"></i>
            <span>${message}</span>
        `;

        document.body.appendChild(toast);

        setTimeout(() => toast.classList.add('show'), 10);
        setTimeout(() => {
            toast.classList.remove('show');
            setTimeout(() => toast.remove(), 300);
        }, 3000);
    } catch (error) {
        console.error("Error al mostrar toast:", error);
    }
}
/* =================================== */
/* ===== LÓGICA DE ML DASHBOARD ===== */
/* =================================== */

let mlDataLoaded = false;
let isMlLoading = false; 

/* =================================== */
/* ===== LÓGICA DE NAVEGACIÓN (OVERRIDE) ===== */
/* =================================== */

// Guardamos la referencia a la función original si existe
const originalShowSection = window.showSection;

window.showSection = function (sectionId) {
    // 1. Ejecutar la lógica de cambio de sección
    if (typeof originalShowSection === 'function' && originalShowSection !== window.showSection) {
        originalShowSection(sectionId);
    } else {
        // Fallback: Lógica manual de cambio de sección
        document.querySelectorAll(".section").forEach((section) => {
            section.classList.remove("active");
        });
        const section = document.getElementById(sectionId);
        if (section) {
            section.classList.add("active");
            window.location.hash = sectionId;
            if (typeof highlightActiveSidebarItem === 'function') {
                highlightActiveSidebarItem(sectionId);
            }
        }
    }

    // 2. Lógica específica por sección
    if (sectionId === 'ml_dashboard' && !mlDataLoaded && !isMlLoading) {
        cargarDatosML(); 
    } else if (sectionId === 'notas') {
        cargarNotasAdmin();
    }
};

/* ================================================== */
/* ===== LÓGICA DE INTERPRETACIÓN DE ML (NUEVO) ===== */
/* ================================================== */

function analizarYMostrarInsights(arbolTexto) {
    if (!arbolTexto) return;

    // 1. Extraer Factor Principal (La Raíz)
    // Buscamos la primera línea que tenga lógica (ej: "duracion <= 5")
    const lineas = arbolTexto.split('\n').filter(l => l.trim() !== '' && !l.startsWith('J48') && !l.includes('---'));

    if (lineas.length > 0) {
        const primeraLinea = lineas[0];
        // Extraer nombre de la variable (ej: "duracion")
        const matchVariable = primeraLinea.match(/([a-zA-Z_]+)\s*[<=>]+/);

        if (matchVariable && matchVariable[1]) {
            const variableRaw = matchVariable[1];
            // Embellecer nombre
            let nombreBonito = variableRaw;
            if (variableRaw === 'duracion') nombreBonito = '⏱ Duración del Viaje';
            if (variableRaw === 'distancia') nombreBonito = '🛣 Distancia Recorrida';
            if (variableRaw === 'tarifa') nombreBonito = '💵 Costo del Viaje';

            document.getElementById('insight-factor-nombre').textContent = nombreBonito;
        }
    }

    // 2. Extraer Regla de Oro (Un camino a "SI")
    // Buscamos una línea simple que termine en ": si" para mostrarla como ejemplo
    const reglaPositiva = lineas.find(l => l.includes(': si'));

    if (reglaPositiva) {
        // Limpiamos el formato técnico "|   duracion <= 5: si (10.0)"
        let textoLimpio = reglaPositiva.trim()
            .replace(/\|\s*/g, '') // Quitar barras
            .replace(': si', '') // Quitar resultado
            .replace(/\(\d+\.?\d*\)/, '') // Quitar números
            .trim();

        // Traducir operadores
        textoLimpio = textoLimpio.replace('<=', 'menor o igual a');
        textoLimpio = textoLimpio.replace('>', 'mayor a');

        // Traducir variables
        textoLimpio = textoLimpio.replace('duracion', 'duración');
        textoLimpio = textoLimpio.replace('distancia', 'distancia');

        document.getElementById('insight-regla-texto').innerHTML =
            `Cuando <b>${textoLimpio}</b>, el cliente suele estar satisfecho.`;
    } else {
        document.getElementById('insight-regla-texto').textContent = "El modelo es complejo, revisa el árbol completo.";
    }
}

// Simulador Local (Aproximación simple basada en lógica JS para feedback instantáneo)
function simularPrediccionLocal() {
    // NOTA: Esto es una simulación visual.
    // En producción, idealmente llamarías a un endpoint /api/ml/predecir.
    // Pero para "jugar" con el dashboard, podemos replicar una lógica simple aquí o llamar al backend.

    const btn = document.querySelector('.btn-simular');
    const resultDiv = document.getElementById('sim-resultado');

    // Efecto visual
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
    resultDiv.textContent = '...';

    const duracion = parseFloat(document.getElementById('sim-duracion').value) || 0;
    const tarifa = parseFloat(document.getElementById('sim-tarifa').value) || 0;

    // Simulamos un delay de red
    setTimeout(() => {
        btn.innerHTML = '<i class="fas fa-magic"></i> Predecir';

        // Lógica MOCKUP basada en lo que suele salir (puedes ajustarla o conectar al backend real)
        // Ejemplo: Si es muy caro y corto -> No satisfecho
        let satisfecho = true;

        // Regla inventada para el ejemplo visual (La real la tiene el J48)
        if (tarifa > 20000 && duracion < 10) satisfecho = false;

        if (satisfecho) {
            resultDiv.textContent = "PREDICCIÓN: SATISFECHO 😊";
            resultDiv.className = "sim-result si";
        } else {
            resultDiv.textContent = "PREDICCIÓN: NO SATISFECHO 😠";
            resultDiv.className = "sim-result no";
        }
    }, 800);
}


/**
 * Carga los datos del modelo (GET /api/admin/ml/resultado)
 * y actualiza la UI. Muestra el loader durante la petición.
 */
async function cargarDatosML() {
    if (isMlLoading) return; // Evita llamadas duplicadas
    isMlLoading = true;
    mlDataLoaded = false; // Forzamos a false hasta que sea exitoso

    // 1. Obtener referencias a elementos de la UI (Loader y Wrappers)
    const elLoader = document.getElementById("ml-loader");
    const elWrapper = document.getElementById("ml-content-wrapper");

    // Referencias a metadatos básicos
    const elInstancias = document.getElementById("ml-instancias");
    const elFecha = document.getElementById("ml-fecha-entrenamiento");
    const elArbol = document.getElementById("ml-arbol-texto");

    // 2. Mostrar loader, ocultar contenido
    if (elLoader) elLoader.style.display = 'flex';
    if (elWrapper) elWrapper.style.display = 'none';

    try {
        // --- USA LA RUTA SEGURA ---
        const response = await fetch('/api/admin/ml/resultado');

        if (response.ok) {
            const data = await response.json(); // Parsea el ModeloInfo completo

            // A. ACTUALIZAR METADATOS BÁSICOS
            const fecha = new Date(data.fechaEntrenamiento);
            if (elInstancias) elInstancias.textContent = `${data.instanciasUsadas} instancias`;
            if (elFecha) elFecha.textContent = `Entrenado el: ${fecha.toLocaleString()}`;
            if (elArbol) elArbol.textContent = data.arbolDecisionTexto; // El texto crudo

            // B. ACTUALIZAR TARJETAS DE INSIGHTS (Factor Principal y Regla de Oro)
            // Llamamos a la función auxiliar que creamos para leer el texto
            if (typeof analizarYMostrarInsights === 'function') {
                analizarYMostrarInsights(data.arbolDecisionTexto);
            }

            // C. ACTUALIZAR ESTADÍSTICAS COMPARATIVAS (La parte que estaba en 0)

            // Creamos un formateador para Pesos Colombianos
            const formatter = new Intl.NumberFormat('es-CO', {
                style: 'currency',
                currency: 'COP',
                maximumFractionDigits: 0
            });

            // --- LADO IZQUIERDO (SATISFACTORIOS) ---
            const countSi = document.getElementById('stat-count-si');
            const tarifaSi = document.getElementById('stat-tarifa-si');
            const distSi = document.getElementById('stat-distancia-si');

            if (countSi) countSi.textContent = data.totalSatisfactorios || 0;
            if (tarifaSi) tarifaSi.textContent = formatter.format(data.promedioTarifaSi || 0);
            // toFixed(1) para mostrar solo 1 decimal en km
            if (distSi) distSi.textContent = (data.promedioDistanciaSi || 0).toFixed(1) + ' km';

            // --- LADO DERECHO (INSATISFACTORIOS) ---
            const countNo = document.getElementById('stat-count-no');
            const tarifaNo = document.getElementById('stat-tarifa-no');
            const distNo = document.getElementById('stat-distancia-no');

            if (countNo) countNo.textContent = data.totalInsatisfactorios || 0;
            if (tarifaNo) tarifaNo.textContent = formatter.format(data.promedioTarifaNo || 0);
            if (distNo) distNo.textContent = (data.promedioDistanciaNo || 0).toFixed(1) + ' km';

            mlDataLoaded = true; // ¡Éxito!

        } else {
            // Manejar errores de la API (ej: 404, 500)
            const errorTexto = await response.text();
            if (elArbol) elArbol.textContent = `Error ${response.status}: ${errorTexto}`;
            if (elInstancias) elInstancias.textContent = "Error";
            if (elFecha) elFecha.textContent = "No se pudo cargar";
            showToast('Error al cargar el modelo de ML', 'error');
        }
    } catch (error) {
        // Manejar errores de red (ej: fetch falló)
        console.error("Error fatal al cargar ML:", error);
        if (elArbol) elArbol.textContent = `Error de conexión: ${error.message}`;
        showToast('Error de conexión con el servidor de ML', 'error');
    } finally {
        // 3. Ocultar loader, mostrar contenido (SIEMPRE)
        isMlLoading = false;
        if (elLoader) elLoader.style.display = 'none';
        if (elWrapper) elWrapper.style.display = 'block'; // 'block' muestra el div
    }
}


async function entrenarModeloML() {
    console.log("Iniciando entrenamiento...");

    const btn = document.getElementById("btn-entrenar-ml");
    const feedback = document.getElementById("ml-feedback");

    if (!btn || !feedback) return;

    // 1. Deshabilitar botón y mostrar "Iniciando..." DENTRO de la tarjeta
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Entrenando...';

    feedback.style.display = 'block';
    feedback.className = 'alert alert-success'; // Reutiliza tu clase de alerta
    feedback.innerHTML = '<i class="fas fa-check-circle"></i> Iniciando... El proceso puede tardar varios minutos.';

    try {
        // --- USA LA RUTA SEGURA ---
        const csrfToken = document.querySelector('input[name="_csrf"]')?.value || '';
        const response = await fetch('/api/admin/ml/entrenar', {
            method: 'POST',
            credentials: 'same-origin',
            headers: { 'X-CSRF-TOKEN': csrfToken }
        });

        if (response.ok) {
            // --- ¡ÉXITO! ---

            // 2. Ocultamos el feedback de "Iniciando..." de la tarjeta
            feedback.style.display = 'none';

            // 3. Mostramos el TOAST estilizado (lo que querías)
            showToast('Modelo re-entrenado con éxito', 'success');

            // 4. Recargamos los datos del modelo en la UI
            mlDataLoaded = false;
            await cargarDatosML();

        } else {
            // --- ERROR DE API ---
            // 5. Mostramos el error DENTRO de la tarjeta para que se quede fijo
            const errorTexto = await response.text();
            feedback.className = 'alert alert-error';
            feedback.innerHTML = `<i class="fas fa-exclamation-circle"></i> Error ${response.status}: ${errorTexto}`;
            showToast('Error durante el entrenamiento', 'error'); // Opcional: mostrar toast de error también
        }

    } catch (error) {
        // --- ERROR DE RED ---
        // 6. Mostramos el error DENTRO de la tarjeta
        console.error("Error fatal al entrenar:", error);
        feedback.className = 'alert alert-error';
        feedback.innerHTML = `<i class="fas fa-exclamation-circle"></i> Error de conexión: ${error.message}`;
        showToast('Error de conexión', 'error'); // Opcional
    } finally {
        // 7. Reactivar el botón (SIEMPRE)
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-play"></i> Entrenar Ahora';
    }
}
/* =================================== */
/* ===== LÓGICA MODAL CONFIRMACIÓN ===== */
/* =================================== */

const confirmModal = document.getElementById('confirm-modal');
const confirmBtnYes = document.getElementById('confirm-modal-btn-yes');
const confirmTitle = document.getElementById('confirm-modal-title');
const confirmMessage = document.getElementById('confirm-modal-message');

// Variable persistente para el callback de confirmación
let currentConfirmCallback = null;

/**
 * Abre el modal de confirmación genérico.
 * Soporta tanto una acción predefinida (string) como un callback dinámico (function).
 */
function openConfirmModal(title, message, actionOrCallback) {
    if (!confirmModal || !confirmBtnYes || !confirmTitle || !confirmMessage) {
        console.error("Elementos del modal de confirmación no encontrados");
        return;
    }

    // 1. Poblar el modal con el texto
    confirmTitle.textContent = title;
    confirmMessage.textContent = message;

    // 2. Limpiar estados anteriores
    currentConfirmCallback = null;
    confirmBtnYes.dataset.actionId = "";

    // 3. Determinar tipo de acción
    if (typeof actionOrCallback === 'function') {
        currentConfirmCallback = actionOrCallback;
    } else {
        confirmBtnYes.dataset.actionId = actionOrCallback;
    }

    // 4. Mostrar el modal
    confirmModal.style.display = 'flex';
    document.body.style.overflow = "hidden"; // Evita scroll de fondo
}

/**
 * Cierra el modal de confirmación.
 */
function closeConfirmModal() {
    if (!confirmModal) return;
    confirmModal.style.display = 'none';
    document.body.style.overflow = "auto"; // Restaura scroll
}

/**
 * Ejecuta la acción guardada en el botón 'Confirmar'.
 */
async function executeConfirmAction() {
    // Si hay un callback pendiente, lo ejecutamos primero
    if (currentConfirmCallback) {
        try {
            await currentConfirmCallback();
        } catch (error) {
            console.error("Error en el callback de confirmación:", error);
        }
    } else {
        // De lo contrario, usamos el switch tradicional por actionId
        const actionId = confirmBtnYes.dataset.actionId;

        switch (actionId) {
            case 'logout':
                const logoutForm = document.getElementById('logout-form');
                if (logoutForm) logoutForm.submit();
                break;
            // Otros cases se pueden añadir aquí
            default:
                if (actionId) console.warn("Acción de confirmación desconocida:", actionId);
        }
    }

    // Cierra el modal después de ejecutar la acción
    closeConfirmModal();
}

// --- Event Listeners Globales ---
// 1. Asignar el clic al botón de confirmación
if (confirmBtnYes) {
    confirmBtnYes.addEventListener('click', executeConfirmAction);
}

// 2. (Opcional) Cerrar modal si se hace clic fuera del contenido
if (confirmModal) {
    confirmModal.addEventListener('click', (e) => {
        // Si el clic fue en el overlay (fondo) y no en el contenido
        if (e.target === confirmModal) {
            closeConfirmModal();
        }
    });
}



/* ==========================================
   LÓGICA WEBSOCKET (ADAPTADA PARA ADMIN)
   ========================================== */

function connectAdminWebSocket() {
    const socket = new SockJS('/ws');
    stompClient = Stomp.over(socket);
    // stompClient.debug = null; // Descomentar para limpiar consola

    stompClient.connect({}, function (frame) {
        console.log('Admin conectado: ' + frame);

        stompClient.subscribe('/topic/admin/registros', function (message) {
            // Verificar si el switch "notif" está activado en el HTML
            const toggle = document.getElementById('notif');

            if (toggle && toggle.checked) {
                const data = JSON.parse(message.body);

                // Lógica personalizada del mensaje
                let titulo = "Nuevo Registro";
                let texto = `${data.email} (${data.rol})`;

                if (data.rol === 'CONDUCTOR') {
                    titulo = "Nuevo Conductor";
                    texto = `<strong>${data.email}</strong> espera validación.`;
                } else {
                    titulo = "Nuevo Pasajero";
                    texto = `<strong>${data.email}</strong> se ha unido.`;
                }

                // Mostrar el Toast visual
                showAdminToast(titulo, texto);

                // Recargar contadores si estamos en el dashboard
                if (typeof fetchDashboardData === 'function') fetchDashboardData();
                // Recargar tabla si estamos en validaciones
                if (typeof refreshValidationTable === 'function') refreshValidationTable();
            }
        });
    }, function (error) {
        console.error('Error WebSocket:', error);
        setTimeout(connectAdminWebSocket, 5000);
    });
}

function handleAdminNotification(data) {
    console.log("Notificación recibida:", data);

    // Personalizar mensaje según el tipo de notificación
    let titulo = "Nuevo Evento";
    let mensaje = "Tienes una nueva actualización.";

    if (data.tipo === "NUEVO_REGISTRO") {
        titulo = "Nuevo Registro";
        mensaje = `El usuario <strong>${data.email}</strong> se ha registrado como <strong>${data.rol}</strong>.`;
    }

    // Mostrar el Toast
    showAdminToast(titulo, mensaje);
}

function initNotificationSettings() {
    const notifToggle = document.getElementById('notif');

    // 1. Cargar estado guardado (localStorage tiene prioridad visual)
    const savedState = localStorage.getItem('adminNotif');
    if (notifToggle && savedState !== null) {
        notifToggle.checked = (savedState === 'true');
    }

    // 2. Listener de cambio
    if (notifToggle) {
        notifToggle.addEventListener('change', function () {
            localStorage.setItem('adminNotif', this.checked);

            // Enviar preferencia al backend
            const csrfToken = document.querySelector('input[name="_csrf"]')?.value;
            const formData = new FormData();
            formData.append('habilitado', this.checked);

            fetch('/admin/config/notificaciones', {
                method: 'POST',
                headers: { 'X-CSRF-TOKEN': csrfToken },
                body: formData
            })
                .then(res => res.json())
                .then(data => {
                    if (data.success && this.checked) {
                        showAdminToast('Sistema', 'Notificaciones activadas');
                    }
                })
                .catch(e => console.error("Error guardando config:", e));
        });
    }
}

// --- TOAST VISUAL (Estilo del Conductor adaptado) ---
function showAdminToast(titulo, mensajeHTML) {
    // Limpiar toast anterior
    const existingToast = document.querySelector('.toast-notification');
    if (existingToast) existingToast.remove();

    const toast = document.createElement('div');
    toast.className = 'toast-notification'; // Usamos la clase del CSS nuevo
    toast.innerHTML = `
        <div class="toast-icon">
            <i class="fas fa-bell"></i>
        </div>
        <div class="toast-content">
            <h4>${titulo}</h4>
            <p>${mensajeHTML}</p>
        </div>
    `;

    document.body.appendChild(toast);

    // Animación entrada
    setTimeout(() => toast.classList.add('show'), 10);

    // Auto eliminar
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 400);
    }, 5000);
}

function actualizarPreferenciaBackend(estado) {
    // Esta función mantiene tu lógica actual de enviar el POST al backend
    // para que el servidor sepa la preferencia, aunque el JS ya filtra visualmente.
    const formData = new FormData();
    formData.append('activar', estado);

    fetch('/admin/config/notificaciones', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            // Asegúrate de incluir el token CSRF si Spring Security lo pide
            'X-CSRF-TOKEN': document.querySelector('input[name="_csrf"]')?.value
        },
        body: JSON.stringify({ activar: estado }) // O FormData según espere tu controller
    })
        .then(r => console.log("Preferencia actualizada en servidor"))
        .catch(e => console.error("Error actualizando preferencia", e));
}

// Asignar funciones al objeto 'window' para que los 'onclick' del HTML funcionen
window.openConfirmModal = openConfirmModal;
window.closeConfirmModal = closeConfirmModal;

// Asignar al objeto global 'window' para que los onclick() del HTML funcionen
window.cargarDatosML = cargarDatosML;
window.entrenarModeloML = entrenarModeloML;

// Asignar funciones al objeto window para que estén disponibles globalmente (si son usadas en HTML)
window.showSection = showSection;
window.filterTable = filterTable;
window.openDriverModal = openDriverModal;
window.closeModal = closeModal;
window.refreshValidationTable = refreshValidationTable;
window.changeTheme = changeTheme;
window.fetchDashboardData = fetchDashboardData;

/* =================================== */
/* ===== LÓGICA DEL CHATBOT ADMIN ===== */
/* =================================== */

function toggleChat() {
    const chatWidget = document.getElementById("chatWidget");
    const chatbotToggle = document.getElementById("chatbotToggle");
    if (chatWidget) {
        chatWidget.classList.toggle("open");
    }
    if (chatbotToggle) {
        chatbotToggle.classList.toggle("active");
    }
}

async function sendChatMessage() {
    const input = document.getElementById("chatInput");
    const message = input.value.trim();
    if (!message) return;

    appendChatMessage(message, "user");
    input.value = "";
    showTypingIndicator();

    try {
        const csrfToken = document.querySelector('input[name="_csrf"]')?.value || '';
        const response = await fetch("/api/admin/chat", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-TOKEN": csrfToken
            },
            body: JSON.stringify({ message: message })
        });

        if (!response.ok) throw new Error("Error en la red");

        const data = await response.json();
        removeTypingIndicator();
        appendChatMessage(data.response, "bot");
    } catch (error) {
        removeTypingIndicator();
        appendChatMessage("❌ Error de conexión. Por favor, intenta de nuevo.", "bot error");
        console.error("Error:", error);
    }
}

function appendChatMessage(text, sender) {
    const chatBody = document.getElementById("chatBody");
    if (!chatBody) return;

    const messageDiv = document.createElement("div");
    // sender is "user" or "bot"
    messageDiv.className = `chat-message ${sender}`;
    messageDiv.innerHTML = text.replace(/\n/g, '<br>');
    chatBody.appendChild(messageDiv);
    chatBody.scrollTop = chatBody.scrollHeight;
}

function showTypingIndicator() {
    const chatBody = document.getElementById("chatBody");
    if (!chatBody) return;

    const indicator = document.createElement("div");
    indicator.className = "chat-typing";
    indicator.id = "typingIndicator";
    indicator.innerHTML = '<span></span><span></span><span></span>';
    chatBody.appendChild(indicator);
    chatBody.scrollTop = chatBody.scrollHeight;
}

function removeTypingIndicator() {
    const indicator = document.getElementById("typingIndicator");
    if (indicator) indicator.remove();
}

// Permitir Enter para enviar mensaje
document.addEventListener("DOMContentLoaded", () => {
    const input = document.getElementById("chatInput");
    if (input) {
        input.addEventListener("keypress", function (e) {
            if (e.key === "Enter") {
                sendChatMessage();
            }
        });
    }
});

// --- Lógica del Tablero de Notas ---

// Cargar notas desde el backend
async function cargarNotasAdmin() {
    try {
        const response = await fetch('/api/admin/notas');
        if (!response.ok) throw new Error('Error al cargar notas');

        const notas = await response.json();
        const container = document.getElementById('notas-container');
        container.innerHTML = '';

        if (notas.length === 0) {
            container.innerHTML = '<div class="no-data" style="grid-column: 1 / -1;">No tienes notas guardadas en tu tablero. ¡Crea una nueva!</div>';
            return;
        }

        notas.forEach(nota => {
            const fecha = new Date(nota.fechaCreacion).toLocaleString();

            const card = document.createElement('div');
            card.className = 'nota-card';
            card.innerHTML = `
                <div class="nota-header">
                    <h3 class="nota-title">${nota.titulo}</h3>
                    <div class="nota-actions">
                        <button class="nota-btn" onclick="editarNota('${nota.idString}', '${nota.titulo.replace(/'/g, "\\'")}', '${nota.contenido.replace(/'/g, "\\'").replace(/\n/g, "\\n")}')"><i class="fas fa-edit"></i></button>
                        <button class="nota-btn delete" onclick="confirmarEliminarNota('${nota.idString}')"><i class="fas fa-trash-alt"></i></button>
                    </div>
                </div>
                <div class="nota-content">${nota.contenido}</div>
                <div class="nota-footer">
                    <span><i class="far fa-clock"></i> ${fecha}</span>
                    <span style="opacity: 0.5;">ID: ${nota.idString.substring(0, 6)}...</span>
                </div>
            `;
            container.appendChild(card);
        });
    } catch (error) {
        console.error(error);
        showToast('Error', 'No se pudieron cargar las notas.', 'error');
    }
}

// Abrir modal para nueva nota
function openNotaModal() {
    document.getElementById('nota-id').value = '';
    document.getElementById('nota-titulo').value = '';
    document.getElementById('nota-contenido').value = '';
    document.getElementById('nota-modal-title').innerHTML = '<i class="fas fa-sticky-note"></i> Nueva Nota';
    document.getElementById('nota-titulo').disabled = false;
    document.getElementById('nota-modal').style.display = 'flex';
}

// Cerrar modal
function closeNotaModal() {
    document.getElementById('nota-modal').style.display = 'none';
}

// Editar nota (abre modal con datos llenos)
function editarNota(id, titulo, contenido) {
    document.getElementById('nota-id').value = id;
    document.getElementById('nota-titulo').value = titulo;
    document.getElementById('nota-titulo').disabled = false; // Permitimos editar el título ahora
    document.getElementById('nota-contenido').value = contenido;
    document.getElementById('nota-modal-title').innerHTML = '<i class="fas fa-edit"></i> Editar Nota';
    document.getElementById('nota-modal').style.display = 'flex';
}

// Guardar nota (Crear o Actualizar)
async function guardarNota() {
    const id = document.getElementById('nota-id').value;
    const titulo = document.getElementById('nota-titulo').value.trim();
    const contenido = document.getElementById('nota-contenido').value.trim();
    const csrfToken = document.querySelector('input[name="_csrf"]')?.value || '';

    if (!titulo || !contenido) {
        showToast('Advertencia', 'El título y el contenido son obligatorios.', 'error');
        return;
    }

    try {
        let response;
        if (id) {
            // Actualizar (PUT)
            response = await fetch(`/api/admin/notas/${id}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': csrfToken
                },
                body: JSON.stringify({ titulo, contenido })
            });
        } else {
            // Crear (POST)
            response = await fetch('/api/admin/notas', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': csrfToken
                },
                body: JSON.stringify({ titulo, contenido })
            });
        }

        if (!response.ok) throw new Error('Error al guardar la nota');

        closeNotaModal();
        cargarNotasAdmin();
        showToast('Éxito', 'Nota guardada correctamente', 'success');
    } catch (error) {
        console.error(error);
        showToast('Error', 'No se pudo guardar la nota', 'error');
    }
}

// Confirmar y eliminar nota
function confirmarEliminarNota(id) {
    openConfirmModal('Eliminar Nota', '¿Estás seguro de que deseas eliminar esta nota permanentemente?', async () => {
        const csrfToken = document.querySelector('input[name="_csrf"]')?.value || '';
        try {
            const response = await fetch(`/api/admin/notas/${id}`, {
                method: 'DELETE',
                headers: { 'X-CSRF-TOKEN': csrfToken }
            });
            if (!response.ok) throw new Error('Error al eliminar la nota');

            cargarNotasAdmin();
            showToast('Eliminado', 'La nota ha sido eliminada', 'success');
        } catch (error) {
            console.error(error);
            showToast('Error', 'No se pudo eliminar la nota', 'error');
        }
    });
}




// ─────────────── Verificación de conductores (admin) ───────────────
// Todo el texto del servidor se inserta con textContent (nunca innerHTML).
function vEl(tag, text, cls) {
    const e = document.createElement(tag);
    if (text !== undefined && text !== null) e.textContent = text;
    if (cls) e.className = cls;
    return e;
}

function pintarResumenDeudas(r) {
    const t = (id, v) => { const e = document.getElementById(id); if (e) e.textContent = v; };
    t('deudas-n', r.pasajerosConDeuda);
    t('deudas-n-pie', r.nuevasSemana ? r.nuevasSemana + ' nuevas esta semana' : 'Sin deudas nuevas esta semana');
    t('deudas-total', formatoPesos(r.totalPorCobrar));
    t('deudas-pagadas', r.pagadas30Dias);
    t('deudas-recaudado', formatoPesos(r.recaudado30Dias) + ' recaudado');
    t('mp-pendientes', r.pasajerosConDeuda);
    t('mp-confirmadas', r.pagadas30Dias);
    const badge = document.getElementById('deudas-badge');
    if (badge) { badge.textContent = r.pasajerosConDeuda; badge.hidden = !r.pasajerosConDeuda; }
}

function insignia(texto, cls) { return vEl('span', texto, 'estado-pill ' + cls); }

function pintarTablaDeudas() {
    const cuerpo = document.getElementById('deudas-cuerpo');
    const d = estadoDeudas.datos;
    if (!cuerpo || !d) return;
    const filas = [];
    const f0 = estadoDeudas.filtro;
    if (f0 === 'pendientes' || f0 === 'todas') d.pendientes.forEach(x => filas.push({ ...x, tipo: 'pendiente', orden: x.creadaEn }));
    if (f0 === 'pagadas' || f0 === 'todas') d.pagadas.forEach(x => filas.push({ ...x, tipo: 'pagada', orden: x.pagadaEn }));
    if (f0 === 'condonadas' || f0 === 'todas') (d.condonadas || []).forEach(x => filas.push({ ...x, tipo: 'condonada', orden: x.condonadaEn }));
    filas.sort((a, b) => ((a.tipo !== 'pendiente') - (b.tipo !== 'pendiente')) || String(b.orden).localeCompare(String(a.orden)));
    cuerpo.replaceChildren();
    if (!filas.length) {
        const tr = document.createElement('tr');
        const td = vEl('td', 'No hay deudas en esta vista', 'no-data');
        td.colSpan = 8; tr.appendChild(td); cuerpo.appendChild(tr);
        return;
    }
    filas.forEach(f => {
        const tr = document.createElement('tr');
        const resuelta = f.tipo !== 'pendiente';
        tr.appendChild(vEl('td', f.nombre || '—', 'deuda-nombre'));
        tr.appendChild(vEl('td', f.email || '—'));
        tr.appendChild(vEl('td', f.telefono || '—'));
        tr.appendChild(vEl('td', viajeCorto(f.servicioId)));
        tr.appendChild(vEl('td', fechaCorta(resuelta ? f.canceladoEn : f.creadaEn)));
        tr.appendChild(vEl('td', formatoPesos(f.monto), 'deuda-monto'));
        const est = document.createElement('td');
        est.appendChild(f.tipo === 'pagada' ? insignia('Pagada', 'estado-pill--verde')
            : f.tipo === 'condonada' ? insignia('Condonada', 'estado-pill--gris')
            : insignia('Deuda', 'estado-pill--ambar'));
        tr.appendChild(est);
        const acc = document.createElement('td');
        if (f.tipo === 'pagada') {
            acc.textContent = 'Pagada el ' + fechaCorta(f.pagadaEn);
        } else if (f.tipo === 'condonada') {
            acc.textContent = 'Condonada el ' + fechaCorta(f.condonadaEn) + ' por ' + (f.condonadaPor || '—');
            acc.title = 'Motivo: ' + (f.motivo || '—');
        } else {
            const btn = vEl('button', 'Confirmar pago', 'btn-approve');
            btn.type = 'button';
            btn.onclick = () => abrirPagoModal(f);
            const perdonar = vEl('button', 'Condonar', 'btn-cancel');
            perdonar.type = 'button';
            perdonar.onclick = () => abrirCondonarModal(f);
            acc.append(btn, ' ', perdonar);
        }
        tr.appendChild(acc);
        cuerpo.appendChild(tr);
    });
}

async function cargarDeudas() {
    const error = document.getElementById('deudas-error');
    if (error) error.style.display = 'none';
    try {
        const r = await fetch('/api/admin/deudas', { headers: { 'Accept': 'application/json' }, credentials: 'same-origin' });
        if (!r.ok) throw new Error('No se pudieron cargar las deudas');
        estadoDeudas.datos = await r.json();
        pintarResumenDeudas(estadoDeudas.datos.resumen);
        pintarTablaDeudas();
    } catch (e) {
        if (error) { error.textContent = e.message; error.style.display = 'block'; }
    }
}
window.cargarDeudas = cargarDeudas;

let deudaEnPago = null;
function abrirPagoModal(f) {
    deudaEnPago = f;
    const t = (id, v) => { document.getElementById(id).textContent = v; };
    t('pago-pregunta', `¿Confirmas que recibiste el pago de la deuda por cancelación de ${f.nombre}?`);
    t('pago-monto', formatoPesos(f.monto));
    t('pago-viaje', viajeCorto(f.servicioId) + ' · ' + fechaCorta(f.creadaEn));
    t('pago-email', f.email || '—');
    document.getElementById('pago-nota').value = '';
    document.getElementById('pago-error').style.display = 'none';
    document.getElementById('pago-modal').style.display = 'flex';
}
function cerrarPagoModal() {
    document.getElementById('pago-modal').style.display = 'none';
    deudaEnPago = null;
}

let deudaEnCondonacion = null;
function abrirCondonarModal(f) {
    deudaEnCondonacion = f;
    const t = (id, v) => { document.getElementById(id).textContent = v; };
    t('condonar-pregunta', `¿Condonas la deuda de ${f.nombre}? El pasajero no pagará y podrá volver a pedir viajes.`);
    t('condonar-monto', formatoPesos(f.monto));
    t('condonar-viaje', viajeCorto(f.servicioId) + ' · ' + fechaCorta(f.creadaEn));
    document.getElementById('condonar-motivo').value = '';
    document.getElementById('condonar-error').style.display = 'none';
    document.getElementById('condonar-modal').style.display = 'flex';
    document.getElementById('condonar-motivo').focus();
}
function cerrarCondonarModal() {
    document.getElementById('condonar-modal').style.display = 'none';
    deudaEnCondonacion = null;
}

document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('condonar-cancelar')?.addEventListener('click', cerrarCondonarModal);
    document.getElementById('condonar-confirmar')?.addEventListener('click', async () => {
        if (!deudaEnCondonacion) return;
        const err = document.getElementById('condonar-error');
        err.style.display = 'none';
        const motivo = document.getElementById('condonar-motivo').value.trim();
        if (motivo.length < 5) {
            err.textContent = 'Escribe el motivo de la condonación (mínimo 5 caracteres)';
            err.style.display = 'block';
            return;
        }
        const csrf = document.querySelector('input[name="_csrf"]');
        const res = await fetch('/api/admin/deudas/' + encodeURIComponent(deudaEnCondonacion.pasajeroId) + '/condonar', {
            method: 'POST', credentials: 'same-origin',
            headers: Object.assign({ 'Accept': 'application/json', 'Content-Type': 'application/json' },
                csrf && csrf.value ? { 'X-CSRF-TOKEN': csrf.value } : {}),
            body: JSON.stringify({ motivo })
        });
        if (!res.ok) {
            let msg = 'No se pudo condonar la deuda';
            try { msg = (await res.json()).error || msg; } catch (e) { /* sin cuerpo */ }
            err.textContent = msg; err.style.display = 'block';
            return;
        }
        cerrarCondonarModal();
        cargarDeudas();
    });
    document.getElementById('deudas-filtros')?.addEventListener('click', (e) => {
        const b = e.target.closest('button[data-filtro]');
        if (!b) return;
        document.querySelectorAll('#deudas-filtros .btn-filter').forEach(x => x.classList.toggle('active', x === b));
        estadoDeudas.filtro = b.dataset.filtro;
        pintarTablaDeudas();
    });
    document.getElementById('pago-cancelar')?.addEventListener('click', cerrarPagoModal);
    document.getElementById('pago-confirmar')?.addEventListener('click', async () => {
        if (!deudaEnPago) return;
        const err = document.getElementById('pago-error');
        err.style.display = 'none';
        const res = await fetch('/api/admin/deudas/' + encodeURIComponent(deudaEnPago.pasajeroId) + '/confirmar-pago', {
            method: 'POST', credentials: 'same-origin',
            headers: { 'Accept': 'application/json', 'Content-Type': 'application/json',
                'X-CSRF-TOKEN': document.querySelector('input[name="_csrf"]')?.value || '' },
            body: JSON.stringify({ metodo: document.getElementById('pago-metodo').value, nota: document.getElementById('pago-nota').value })
        });
        if (!res.ok) {
            let msg = 'No se pudo confirmar el pago';
            try { msg = (await res.json()).error || msg; } catch (e) { /* sin cuerpo */ }
            err.textContent = msg; err.style.display = 'block';
            return;
        }
        cerrarPagoModal();
        cargarDeudas();
    });
    cargarDeudas();   // deja listos el distintivo del menú y las cifras de Configuración
});
