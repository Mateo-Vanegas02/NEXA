// Registro de conductor: valida, reduce y previsualiza las fotos de los documentos antes de enviar.
// Las fotos se reducen en el navegador (lado mayor 1600 px, JPEG ~500 KB) para ahorrar espacio en la base de datos.
// El servidor vuelve a validar tamaño (máx. 5 MB) y tipo real; esto solo evita subir archivos pesados o inválidos.
(function () {
    'use strict';

    var MAX_BYTES_SERVIDOR = 5 * 1024 * 1024;
    var MAX_ORIGINAL = 25 * 1024 * 1024; // límite de lo que se intenta reducir en el navegador
    var MAX_LADO = 1600;
    var OBJETIVO_BYTES = 500 * 1024;
    var CALIDAD_INICIAL = 0.82;
    var CALIDAD_MINIMA = 0.5;
    var TIPOS = ['image/jpeg', 'image/png', 'image/webp'];
    var puedeReducir = typeof createImageBitmap === 'function' && typeof DataTransfer === 'function';

    function formatoTamano(bytes) {
        if (bytes >= 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1).replace('.', ',') + ' MB';
        return Math.max(1, Math.round(bytes / 1024)) + ' KB';
    }

    function validarOriginal(archivo) {
        if (TIPOS.indexOf(archivo.type) === -1) return 'La foto debe ser JPG, PNG o WebP.';
        if (archivo.size > MAX_ORIGINAL) return 'La foto pesa demasiado (máx. 25 MB).';
        return '';
    }

    function aBlob(canvas, calidad) {
        return new Promise(function (resolve) { canvas.toBlob(resolve, 'image/jpeg', calidad); });
    }

    // Devuelve un File JPEG reducido, o el original si ya es pequeño o no se pudo reducir.
    async function reducir(archivo) {
        if (!puedeReducir) return archivo;
        var bmp;
        try {
            bmp = await createImageBitmap(archivo, { imageOrientation: 'from-image' });
        } catch (e) {
            return archivo;
        }
        var escala = Math.min(1, MAX_LADO / Math.max(bmp.width, bmp.height));
        var ancho = Math.max(1, Math.round(bmp.width * escala));
        var alto = Math.max(1, Math.round(bmp.height * escala));
        var canvas = document.createElement('canvas');
        canvas.width = ancho;
        canvas.height = alto;
        var ctx = canvas.getContext('2d');
        if (!ctx) { if (bmp.close) bmp.close(); return archivo; }
        ctx.fillStyle = '#ffffff'; // los PNG con transparencia no deben quedar negros al pasar a JPEG
        ctx.fillRect(0, 0, ancho, alto);
        ctx.drawImage(bmp, 0, 0, ancho, alto);
        if (bmp.close) bmp.close();

        var calidad = CALIDAD_INICIAL;
        var blob = await aBlob(canvas, calidad);
        while (blob && blob.size > OBJETIVO_BYTES && calidad - 0.1 >= CALIDAD_MINIMA) {
            calidad -= 0.1;
            blob = await aBlob(canvas, calidad);
        }
        if (!blob || blob.size >= archivo.size) return archivo;
        var base = archivo.name.replace(/\.[^.]+$/, '') || 'documento';
        return new File([blob], base + '.jpg', { type: 'image/jpeg', lastModified: Date.now() });
    }

    function limpiarVista(contenedor, urlAnterior) {
        if (urlAnterior) URL.revokeObjectURL(urlAnterior);
        contenedor.replaceChildren();
        contenedor.hidden = true;
    }

    function mostrarEstado(contenedor, texto) {
        contenedor.replaceChildren();
        var p = document.createElement('span');
        p.textContent = texto;
        contenedor.append(p);
        contenedor.hidden = false;
    }

    function mostrarVista(contenedor, archivo, originalBytes) {
        contenedor.replaceChildren();
        var url = URL.createObjectURL(archivo);
        var img = document.createElement('img');
        img.src = url;
        img.alt = 'Vista previa de la foto seleccionada';
        img.width = 96;
        img.height = 96;
        var info = document.createElement('span');
        var tamano = formatoTamano(archivo.size);
        info.textContent = archivo.name + ' · ' + (archivo.size < originalBytes
            ? formatoTamano(originalBytes) + ' → ' + tamano : tamano);
        contenedor.append(img, info);
        contenedor.hidden = false;
        return url;
    }

    var pendientes = 0;
    var form = document.getElementById('formConductor');
    if (form) {
        form.addEventListener('submit', function (e) {
            if (pendientes > 0) e.preventDefault(); // todavía se está reduciendo una foto
        });
    }

    document.querySelectorAll('[data-doc]').forEach(function (doc) {
        var input = doc.querySelector('input[data-foto]');
        var vista = doc.querySelector('[data-vista]');
        if (!input || !vista) return;
        var url = '';

        input.addEventListener('change', async function () {
            var original = input.files && input.files[0];
            limpiarVista(vista, url);
            url = '';
            input.setCustomValidity('');
            if (!original) return;

            var error = validarOriginal(original);
            if (error) {
                input.setCustomValidity(error);
                input.reportValidity();
                input.value = '';
                return;
            }

            pendientes++;
            input.setCustomValidity('Espera a que termine de procesarse la foto.');
            mostrarEstado(vista, 'Reduciendo la foto…');
            try {
                var final = await reducir(original);
                if (final.size > MAX_BYTES_SERVIDOR) {
                    input.setCustomValidity('La foto pesa más de 5 MB.');
                    input.reportValidity();
                    input.value = '';
                    limpiarVista(vista, '');
                    return;
                }
                if (final !== original) {
                    var dt = new DataTransfer();
                    dt.items.add(final);
                    input.files = dt.files;
                }
                input.setCustomValidity('');
                url = mostrarVista(vista, final, original.size);
            } catch (e) {
                input.setCustomValidity('No se pudo procesar la foto. Prueba con otra.');
                input.reportValidity();
                input.value = '';
                limpiarVista(vista, '');
            } finally {
                pendientes--;
            }
        });
    });
})();
