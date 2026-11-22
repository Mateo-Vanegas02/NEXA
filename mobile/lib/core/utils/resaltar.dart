/// Parte un texto en tramos para resaltar lo que coincide con [consulta]
/// (sin distinguir mayúsculas ni tildes). true = el tramo coincide.
List<(String, bool)> tramosResaltados(String texto, String consulta) {
  final q = _plano(consulta.trim());
  if (q.isEmpty || texto.isEmpty) return [(texto, false)];
  final plano = _plano(texto);
  final r = <(String, bool)>[];
  var i = 0;
  while (i < texto.length) {
    final j = plano.indexOf(q, i);
    if (j < 0) {
      r.add((texto.substring(i), false));
      break;
    }
    if (j > i) r.add((texto.substring(i, j), false));
    r.add((texto.substring(j, j + q.length), true));
    i = j + q.length;
  }
  return r;
}

/// Minúsculas y sin tildes; conserva la longitud para cortar el original.
String _plano(String s) {
  const de = 'áàäâéèëêíìïîóòöôúùüûñ';
  const a = 'aaaaeeeeiiiioooouuuun';
  final b = StringBuffer();
  for (final c in s.toLowerCase().split('')) {
    final k = de.indexOf(c);
    b.write(k < 0 ? c : a[k]);
  }
  return b.toString();
}
