/* NEXA UI — comportamientos compartidos de las páginas públicas y de acceso (JS plano, sin dependencias). */
(function () {
  'use strict';

  /* Menú móvil */
  var toggle = document.querySelector('.nx-nav__toggle');
  var links = document.querySelector('.nx-nav__links');
  if (toggle && links) {
    toggle.addEventListener('click', function () {
      var abierto = links.classList.toggle('is-open');
      toggle.setAttribute('aria-expanded', String(abierto));
    });
    links.addEventListener('click', function (e) {
      if (e.target.closest('a')) {
        links.classList.remove('is-open');
        toggle.setAttribute('aria-expanded', 'false');
      }
    });
  }

  /* Enlace activo según la sección visible */
  var enlaces = [].slice.call(document.querySelectorAll('.nx-nav__links a[href^="#"]'));
  if (enlaces.length && 'IntersectionObserver' in window) {
    var porId = {};
    enlaces.forEach(function (a) { porId[a.getAttribute('href').slice(1)] = a; });
    var obs = new IntersectionObserver(function (entradas) {
      entradas.forEach(function (en) {
        if (!en.isIntersecting) return;
        enlaces.forEach(function (a) { a.classList.remove('active'); a.removeAttribute('aria-current'); });
        var a = porId[en.target.id];
        if (a) { a.classList.add('active'); a.setAttribute('aria-current', 'true'); }
      });
    }, { rootMargin: '-40% 0px -55% 0px' });
    Object.keys(porId).forEach(function (id) {
      var s = document.getElementById(id);
      if (s) obs.observe(s);
    });
  }

  /* Pestañas accesibles (role=tablist): flechas, Inicio y Fin; también abre una por #hash */
  document.querySelectorAll('[role="tablist"]').forEach(function (lista) {
    var tabs = [].slice.call(lista.querySelectorAll('[role="tab"]'));
    function activar(tab, enfocar) {
      tabs.forEach(function (t) {
        var activa = t === tab;
        t.setAttribute('aria-selected', String(activa));
        t.tabIndex = activa ? 0 : -1;
        var panel = document.getElementById(t.getAttribute('aria-controls'));
        if (panel) panel.hidden = !activa;
      });
      if (enfocar) tab.focus();
    }
    tabs.forEach(function (t, i) {
      t.addEventListener('click', function () { activar(t, false); });
      t.addEventListener('keydown', function (e) {
        var destino = null;
        if (e.key === 'ArrowRight') destino = tabs[(i + 1) % tabs.length];
        else if (e.key === 'ArrowLeft') destino = tabs[(i - 1 + tabs.length) % tabs.length];
        else if (e.key === 'Home') destino = tabs[0];
        else if (e.key === 'End') destino = tabs[tabs.length - 1];
        if (destino) { e.preventDefault(); activar(destino, true); }
      });
    });
    var porHash = tabs.filter(function (t) { return '#' + t.getAttribute('data-hash') === location.hash; })[0];
    if (porHash) activar(porHash, false);
  });

  /* Mostrar/ocultar contraseña */
  document.querySelectorAll('[data-toggle-password]').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var campo = document.getElementById(btn.getAttribute('data-toggle-password'));
      if (!campo) return;
      var visible = campo.type === 'text';
      campo.type = visible ? 'password' : 'text';
      btn.setAttribute('aria-pressed', String(!visible));
      btn.setAttribute('aria-label', visible ? 'Mostrar contraseña' : 'Ocultar contraseña');
    });
  });

  /* Velocímetro interactivo: cada número mueve la aguja y cambia el mensaje */
  var speedo = document.querySelector('[data-speedo]');
  if (speedo) {
    var ticks = [].slice.call(speedo.querySelectorAll('.nx-speedo__tick'));
    var aguja = speedo.querySelector('.nx-speedo__needle');
    var n = speedo.querySelector('[data-speedo-n]');
    var titulo = speedo.querySelector('[data-speedo-title]');
    var texto = speedo.querySelector('[data-speedo-text]');
    var elegir = function (tick) {
      ticks.forEach(function (t) { t.setAttribute('aria-pressed', String(t === tick)); });
      var x = parseFloat(tick.getAttribute('data-x'));
      var y = parseFloat(tick.getAttribute('data-y'));
      var angulo = Math.atan2((x - 50) * 3.2, -(y - 82) * 2.05) * 180 / Math.PI;
      aguja.style.transform = 'rotate(' + angulo + 'deg)';
      n.textContent = tick.textContent;
      titulo.textContent = tick.getAttribute('data-title');
      texto.textContent = tick.getAttribute('data-text');
    };
    ticks.forEach(function (t) {
      t.style.left = t.getAttribute('data-x') + '%';
      t.style.top = t.getAttribute('data-y') + '%';
      t.addEventListener('click', function () { elegir(t); });
    });
    if (ticks[0]) elegir(ticks[0]);
  }
})();
