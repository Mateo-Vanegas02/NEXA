/**
 * NEXA | Scroll Engine & Performance WebGL Emulation
 * Vanilla JS ES6+ | 60FPS Parallax & Storytelling
 */

class SurgeEngine {
    constructor() {
        this.DOM = {
            focalPoint: document.getElementById('focalPoint'),
            sections: document.querySelectorAll('.section'),
            motoSvg: document.querySelector('.nexa-moto'),
            parallaxFast: document.querySelectorAll('.parallax-fast'),
            parallaxSlow: document.querySelectorAll('.parallax-slow'),
            magneticBtns: document.querySelectorAll('.magnetic-btn'),
            hudDots: document.querySelectorAll('.hud-dot')
        };

        // Estado del Scroll (Lerp variables)
        this.state = {
            scrollY: window.scrollY,
            targetY: window.scrollY,
            progress: 0,
            maxScroll: Math.max(0, document.body.scrollHeight - window.innerHeight)
        };

        this.init();
    }

    init() {
        this.prepareTypography();
        this.setupIntersectionObservers();
        this.setupMagneticInteraction();

        // Iniciar Loop de Renderizado (requestAnimationFrame)
        this.renderLoop();

        // Listeners
        window.addEventListener('resize', () => {
            this.state.maxScroll = Math.max(0, document.body.scrollHeight - window.innerHeight);
        });

        // Capturar scroll pasivo
        window.addEventListener('scroll', () => {
            this.state.targetY = window.scrollY;
        }, { passive: true });
    }

    /**
     * 1. PREPARACIÓN TIPOGRÁFICA (Split Text Reveal)
     * Envuelve cada palabra en etiquetas para lograr el retraso escalonado (stagger).
     */
    prepareTypography() {
        const splitElements = document.querySelectorAll('.split-text');

        splitElements.forEach(el => {
            // Manejamos los <br> nativos
            const htmlContent = el.innerHTML.replace(/<br\s*\/?>/gi, ' <br> ');
            const words = htmlContent.split(' ');

            el.innerHTML = '';

            let delayIndex = 0;

            words.forEach((word) => {
                if (word.toLowerCase() === '<br>') {
                    el.appendChild(document.createElement('br'));
                    return;
                }

                if (word.trim() === '') return;

                const wrapper = document.createElement('span');
                wrapper.className = 'line-wrapper';

                const innerWord = document.createElement('span');
                innerWord.className = 'word-reveal';
                innerWord.innerText = word + '\u00A0'; // Non-breaking space
                innerWord.style.transitionDelay = `${delayIndex * 0.04}s`;

                wrapper.appendChild(innerWord);
                el.appendChild(wrapper);

                delayIndex++;
            });
        });
    }

    /**
     * 2. INTERSECTION OBSERVERS (Desencadenador de Eventos Visuales)
     */
    setupIntersectionObservers() {
        const options = {
            root: null,
            rootMargin: '-15% 0px -15% 0px',
            threshold: 0.3
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    // Revelar el texto
                    entry.target.classList.add('is-visible');

                    // Actualizar HUD Sidebar
                    this.updateHUD(entry.target.id);

                    // Lógica de Inversión (Theme Switch)
                    if (entry.target.classList.contains('light-theme')) {
                        document.body.classList.add('invert-mode');
                    } else {
                        document.body.classList.remove('invert-mode');
                    }
                }
            });
        }, options);

        this.DOM.sections.forEach(sec => observer.observe(sec));
    }

    updateHUD(activeId) {
        this.DOM.hudDots.forEach(dot => {
            if (dot.dataset.target === `#${activeId}`) {
                dot.classList.add('active');
            } else {
                dot.classList.remove('active');
            }
        });
    }

    /**
     * 3. MICRO-INTERACCIÓN MAGNÉTICA EN BOTONES
     */
    setupMagneticInteraction() {
        this.DOM.magneticBtns.forEach(btn => {
            const text = btn.querySelector('.btn-text');

            btn.addEventListener('mousemove', (e) => {
                const rect = btn.getBoundingClientRect();
                // Calcular distancia desde el centro del botón
                const x = e.clientX - rect.left - rect.width / 2;
                const y = e.clientY - rect.top - rect.height / 2;

                // Mover contenedor levemente
                btn.style.transform = `translate3d(${x * 0.25}px, ${y * 0.25}px, 0)`;
                // Mover texto con efecto parallax interno
                text.style.transform = `translate3d(${x * 0.4}px, ${y * 0.4}px, 0)`;
            });

            btn.addEventListener('mouseleave', () => {
                // Restaurar usando resorte CSS
                btn.style.transform = `translate3d(0, 0, 0)`;
                text.style.transform = `translate3d(0, 0, 0)`;
            });
        });
    }

    /**
     * 4. LERP MATEMÁTICO (Interpolación Lineal para Smoothness)
     */
    lerp(start, end, factor) {
        return start + (end - start) * factor;
    }

    /**
     * 5. MOTOR DE RENDERIZADO (60 FPS LOOP)
     * Aquí ocurre la magia visual dependiente del Scroll.
     */
    renderLoop() {
        // Interpolar Scroll Y real vs Objetivo para una inercia "Suave"
        this.state.scrollY = this.lerp(this.state.scrollY, this.state.targetY, 0.07);

        // Progreso Global del Scroll (De 0.0 a 1.0)
        this.state.progress = this.state.maxScroll > 0 ? (this.state.scrollY / this.state.maxScroll) : 0;

        /* --- EFECTO 1: Focal Point (Motocicleta) --- */
        // La moto se desplaza a la derecha, luego vuelve a la izquierda, gira y se aleja (Simulación 3D)

        // Movimiento Senoidal (Vaivén)
        const motoX = Math.sin(this.state.progress * Math.PI * 1.5) * 200;
        const motoY = Math.cos(this.state.progress * Math.PI) * -50;

        // Escala: Arranca grande, se reduce al final
        const motoScale = 1 - (this.state.progress * 0.35);

        // Rotación aerodinámica
        const motoRotate = this.state.progress * 25;

        this.DOM.focalPoint.style.transform = `translate(-50%, -50%) translate3d(${motoX}px, ${motoY}px, 0) scale(${motoScale}) rotateZ(${motoRotate}deg)`;

        // Interacción Dinámica de Luz (Rim Light reacciona a la velocidad del scroll)
        const speed = Math.abs(this.state.targetY - this.state.scrollY);
        const glowIntensity = Math.min(speed * 0.06, 6); // Cap a 6
        // Intensificamos el drop-shadow usando variables CSS (simulado por el SVG filter original o manipulando el CSS directo)
        // En nuestro caso el SVG ya tiene filtro estático, le aplicaremos un "brightness" o un "drop-shadow" de capa entera.
        this.DOM.motoSvg.style.filter = `drop-shadow(0 0 ${15 + glowIntensity * 5}px rgba(0, 196, 255, ${0.1 + glowIntensity * 0.1})) brightness(${1 + glowIntensity * 0.1})`;


        /* --- EFECTO 2: Text Parallax (Velocidades relativas) --- */
        this.DOM.sections.forEach((sec) => {
            const rect = sec.getBoundingClientRect();

            // Renderizamos solo si está en viewport
            if (rect.top < window.innerHeight && rect.bottom > 0) {
                // Distancia desde el centro de la pantalla
                const offset = (rect.top - window.innerHeight / 2) * 0.15;

                const fastTexts = sec.querySelectorAll('.parallax-fast');
                const slowTexts = sec.querySelectorAll('.parallax-slow');

                fastTexts.forEach(el => {
                    el.style.transform = `translate3d(0, ${offset * 0.7}px, 0)`;
                });

                slowTexts.forEach(el => {
                    el.style.transform = `translate3d(0, ${offset * 0.25}px, 0)`;
                });
            }
        });

        // Bucle Infinito
        requestAnimationFrame(this.renderLoop.bind(this));
    }
}

// Inicializar el Engine al cargar el DOM
document.addEventListener('DOMContentLoaded', () => {
    new SurgeEngine();
});
