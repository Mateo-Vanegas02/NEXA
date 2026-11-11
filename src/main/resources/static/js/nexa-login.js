/**
 * Lógica de UI para NEXA Login
 * Implementado en Vanilla JS (ES6+) con optimización de performance.
 */

function togglePassword(inputId, btn) {
    const input = document.getElementById(inputId);
    if (!input) return;
    const icon = btn.querySelector('i');
    if (input.type === 'password') {
        input.type = 'text';
        icon.className = 'fas fa-eye-slash';
    } else {
        input.type = 'password';
        icon.className = 'fas fa-eye';
    }
}

document.addEventListener('DOMContentLoaded', () => {
    // Referencias a los nodos DOM
    const loginForm = document.getElementById('loginForm');
    const showcasePanel = document.querySelector('.showcase-panel');
    const ctaButton = document.querySelector('.cta-button');
    const btnText = document.querySelector('.btn-text');
    const btnGlow = document.querySelector('.btn-glow');
    
    const inputs = document.querySelectorAll('.input-group input');
    
    // 1. Micro-interacción: Estado Reactivo de los Inputs
    // El showcase de la motocicleta no se interrumpe, manteniendo su "crucero" mientras el usuario teclea.
    inputs.forEach(input => {
        input.addEventListener('input', () => {
            const group = input.closest('.input-group');
            const border = group.querySelector('.focus-border');
            
            if (input.value.length > 0) {
                // Estado: Input con contenido (Cyan Brillante)
                border.style.background = 'var(--accent-orange)';
                border.style.boxShadow = '0 -2px 15px rgba(0, 196, 255, 0.6)';
            } else {
                // Estado: Input vacío (Gradiente Default)
                border.style.background = 'var(--accent-gradient)';
                border.style.boxShadow = '0 -2px 10px rgba(0, 196, 255, 0.2)';
            }
        });
    });

    // 2. Control de Acción Principal: Submit del Formulario
    if (loginForm) {
        loginForm.addEventListener('submit', (e) => {
            e.preventDefault(); 
            
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            
            // Validación básica front-end
            if (username && password) {
                
                // --- INICIO EFECTO ACELERACIÓN (Hardware Accelerated) ---
                // Añade la clase que duplica la velocidad del parallax y de las ruedas (`.accelerating`)
                if (showcasePanel) {
                    showcasePanel.classList.add('accelerating');
                }
                
                // Transición del CTA Button a estado "Loading"
                if(btnText) btnText.textContent = 'Autenticando...';
                if(btnText) btnText.style.color = 'var(--bg-base)';
                if(ctaButton) ctaButton.style.background = 'var(--accent-gradient)';
                if(ctaButton) ctaButton.style.border = 'none';
                if(btnGlow) btnGlow.style.display = 'none'; // Desactivamos el glow del hover
                
                // Retraso para que el usuario pueda ver la animación de aceleración
                setTimeout(() => {
                    // Enviar la petición real al backend de Spring Boot
                    loginForm.submit();
                }, 1000);
            }
        });
    }
});
