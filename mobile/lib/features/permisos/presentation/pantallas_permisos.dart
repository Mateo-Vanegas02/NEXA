import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/permisos/guia_permisos.dart';
import '../../../core/permisos/permisos_dispositivo.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/mapa_nexa.dart';
import '../../../core/widgets/nexa_widgets.dart';
import '../../auth/domain/auth.dart';
import '../../auth/presentation/controllers/session_controller.dart';
import 'plantilla_permiso.dart';

/// Todas las pantallas de permisos se cierran con `true` si el permiso quedó
/// concedido (o el paso se completó) y `false` si no. Quien las abre decide
/// qué sigue (flujo_permisos.dart). Cada una se marca como vista.

Rol _rol(WidgetRef ref) => ref.read(sesionProvider).sesion?.rol ?? Rol.pasajero;

void _cerrar(BuildContext context, bool resultado) {
  final navegador = Navigator.of(context);
  if (navegador.canPop()) navegador.pop(resultado);
}

/// N01 · Permiso de notificaciones.
class PermisoNotificacionesScreen extends ConsumerStatefulWidget {
  const PermisoNotificacionesScreen({super.key});

  @override
  ConsumerState<PermisoNotificacionesScreen> createState() => _N01State();
}

class _N01State extends ConsumerState<PermisoNotificacionesScreen> {
  bool _cargando = false;

  Future<void> _terminar({required bool pedir}) async {
    setState(() => _cargando = true);
    var concedido = false;
    if (pedir) {
      try {
        concedido = await ref.read(notificacionesProvider).pedirPermiso();
      } on Object {
        concedido = false;
      }
    }
    await ref
        .read(guiaPermisosProvider)
        .marcarVisto(PasoPermiso.notificaciones);
    if (mounted) _cerrar(context, concedido);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final conductor = _rol(ref) == Rol.conductor;
    return PlantillaPermiso(
      icono: Icons.notifications_active_outlined,
      titulo: l.permNotiTitulo,
      texto: l.permNotiTexto,
      motivos: conductor
          ? [
              Motivo(
                Icons.two_wheeler,
                l.permNotiSolicitudes,
                l.permNotiSolicitudesSub,
              ),
              Motivo(
                Icons.cancel_outlined,
                l.permNotiCancela,
                l.permNotiCancelaSub,
              ),
              Motivo(
                Icons.payments_outlined,
                l.permNotiCargos,
                l.permNotiCargosSub,
              ),
            ]
          : [
              Motivo(Icons.two_wheeler, l.permNotiAcepta, l.permNotiAceptaSub),
              Motivo(Icons.place_outlined, l.permNotiLlega, l.permNotiLlegaSub),
              Motivo(
                Icons.payments_outlined,
                l.permNotiCargos,
                l.permNotiCargosSub,
              ),
            ],
      primario: l.permNotiPermitir,
      onPrimario: () => _terminar(pedir: true),
      secundario: l.permAhoraNo,
      onSecundario: () => _terminar(pedir: false),
      onAtras: () => _terminar(pedir: false),
      cargando: _cargando,
    );
  }
}

/// N02 · Ubicación «al usar la app» (pasajero o conductor).
class PermisoUbicacionScreen extends ConsumerStatefulWidget {
  const PermisoUbicacionScreen({super.key});

  @override
  ConsumerState<PermisoUbicacionScreen> createState() => _N02State();
}

class _N02State extends ConsumerState<PermisoUbicacionScreen> {
  bool _cargando = false;

  Future<void> _terminar({required bool pedir}) async {
    setState(() => _cargando = true);
    var estado = EstadoUbicacion.sinPermiso;
    try {
      final permisos = ref.read(permisosProvider);
      estado = pedir
          ? await permisos.pedirUbicacion()
          : await permisos.ubicacion();
    } on Object {
      estado = EstadoUbicacion.sinPermiso;
    }
    await ref.read(guiaPermisosProvider).marcarVisto(PasoPermiso.ubicacion);
    if (estado.concedida) ref.invalidate(ubicacionProvider);
    if (mounted) _cerrar(context, estado.concedida);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final conductor = _rol(ref) == Rol.conductor;
    return PlantillaPermiso(
      icono: Icons.my_location,
      titulo: conductor ? l.permUbicTituloConductor : l.permUbicTitulo,
      texto: conductor ? l.permUbicTextoConductor : l.permUbicTexto,
      motivos: conductor
          ? [
              Motivo(Icons.waves, l.permUbicOla, l.permUbicOlaSub),
              Motivo(Icons.schedule, l.permUbicLlegada, l.permUbicLlegadaSub),
            ]
          : [
              Motivo(Icons.adjust, l.permUbicPunto, l.permUbicPuntoSub),
              Motivo(
                Icons.two_wheeler,
                l.permUbicEncuentra,
                l.permUbicEncuentraSub,
              ),
            ],
      primario: l.permUbicPermitir,
      onPrimario: () => _terminar(pedir: true),
      secundario: l.permAhoraNo,
      onSecundario: () => _terminar(pedir: false),
      onAtras: () => _terminar(pedir: false),
      cargando: _cargando,
    );
  }
}

/// E01 · Sin permiso de ubicación. Si el usuario vuelve de los ajustes con el
/// permiso concedido, la pantalla se cierra sola.
class SinUbicacionScreen extends ConsumerStatefulWidget {
  const SinUbicacionScreen({super.key});

  @override
  ConsumerState<SinUbicacionScreen> createState() => _E01State();
}

class _E01State extends ConsumerState<SinUbicacionScreen> {
  late final AppLifecycleListener _ciclo;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _ciclo = AppLifecycleListener(onResume: _revisar);
  }

  @override
  void dispose() {
    _ciclo.dispose();
    super.dispose();
  }

  Future<void> _revisar() async {
    try {
      final estado = await ref.read(permisosProvider).ubicacion();
      if (estado.concedida && mounted) {
        ref.invalidate(ubicacionProvider);
        _cerrar(context, true);
      }
    } on Object {
      // Sin plugin: se queda en la pantalla.
    }
  }

  Future<void> _permitir() async {
    setState(() => _cargando = true);
    final permisos = ref.read(permisosProvider);
    try {
      final actual = await permisos.ubicacion();
      if (actual == EstadoUbicacion.denegadaSiempre) {
        // El sistema ya no muestra su cuadro: solo queda la página de ajustes.
        await permisos.abrirAjustesApp();
      } else if ((await permisos.pedirUbicacion()).concedida) {
        ref.invalidate(ubicacionProvider);
        if (mounted) _cerrar(context, true);
        return;
      }
    } on Object {
      // Sin plugin: no hay nada que pedir.
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _ajustes() async {
    try {
      await ref.read(permisosProvider).abrirAjustesApp();
    } on Object {
      // Sin plugin.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final conductor = _rol(ref) == Rol.conductor;
    return PlantillaPermiso(
      icono: Icons.location_off_outlined,
      colorIcono: context.colors.error,
      titulo: conductor ? l.permSinUbicTituloConductor : l.permSinUbicTitulo,
      texto: conductor ? l.permSinUbicTextoConductor : l.permSinUbicTexto,
      contenido: PasosNumerados(
        titulo: l.permSinUbicPasos,
        pasos: [l.permSinUbicPaso1, l.permSinUbicPaso2, l.permSinUbicPaso3],
      ),
      primario: l.permSinUbicPermitir,
      onPrimario: _permitir,
      secundario: l.permSinUbicAjustes,
      onSecundario: _ajustes,
      cargando: _cargando,
    );
  }
}

/// N03 · Ubicación en segundo plano (solo conductor, la primera vez que se
/// pone en línea). Siempre se cierra con `true`: puede conducir sin ella.
class SegundoPlanoScreen extends ConsumerStatefulWidget {
  const SegundoPlanoScreen({super.key});

  @override
  ConsumerState<SegundoPlanoScreen> createState() => _N03State();
}

class _N03State extends ConsumerState<SegundoPlanoScreen> {
  bool _cargando = false;

  Future<void> _terminar({required bool pedir}) async {
    setState(() => _cargando = true);
    // Con «Seguir sin segundo plano» no se vuelve a ofrecer. Si pidió activarlo
    // pero no eligió «Permitir todo el tiempo», se ofrece otra vez la próxima
    // vez que se ponga en línea.
    var marcar = true;
    if (pedir) {
      try {
        final r = await ref.read(permisosProvider).pedirSegundoPlano();
        marcar = r == EstadoUbicacion.siempre;
      } on Object {
        // Sin plugin.
      }
    }
    if (marcar) {
      await ref
          .read(guiaPermisosProvider)
          .marcarVisto(PasoPermiso.segundoPlano);
    }
    if (mounted) _cerrar(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PlantillaPermiso(
      icono: Icons.phonelink_lock_outlined,
      titulo: l.perm2PlanoTitulo,
      texto: l.perm2PlanoTexto,
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NexaCard(
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.lg,
              vertical: Sp.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: Sp.sm, bottom: Sp.xs),
                  child: Text(
                    l.perm2PlanoElige.toUpperCase(),
                    style: context.textos.labelSmall?.copyWith(
                      color: context.muted,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _Opcion(texto: l.perm2PlanoSiempre, elegida: true),
                _Opcion(texto: l.perm2PlanoAlUsar),
                _Opcion(texto: l.perm2PlanoNo),
              ],
            ),
          ),
          const SizedBox(height: Sp.sm),
          TextButton.icon(
            onPressed: _cargando
                ? null
                : () => context.push(RutasPermisos.bateria),
            icon: const Icon(Icons.battery_alert_outlined),
            label: Text(l.perm2PlanoMarca),
          ),
        ],
      ),
      primario: l.perm2PlanoContinuar,
      onPrimario: () => _terminar(pedir: true),
      secundario: l.perm2PlanoSin,
      onSecundario: () => _terminar(pedir: false),
      onAtras: () => _terminar(pedir: false),
      cargando: _cargando,
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({required this.texto, this.elegida = false});
  final String texto;
  final bool elegida;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.sm),
      child: Row(
        children: [
          Icon(
            elegida ? Icons.radio_button_checked : Icons.radio_button_off,
            color: elegida ? context.acento : context.muted,
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Text(
              texto,
              style: elegida
                  ? const TextStyle(fontWeight: FontWeight.w600)
                  : TextStyle(color: context.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rutas que no están en [PasoPermiso] (no las decide la guía).
abstract final class RutasPermisos {
  static const bateria = '/c/permisos/bateria';
}

/// Marcas con guía propia; el resto usa la genérica.
enum MarcaTelefono { samsung, xiaomi, motorola, huawei, otra }

/// N04 · Guía para que el ahorro de batería no cierre NEXA.
class GuiaBateriaScreen extends ConsumerStatefulWidget {
  const GuiaBateriaScreen({super.key});

  @override
  ConsumerState<GuiaBateriaScreen> createState() => _N04State();
}

class _N04State extends ConsumerState<GuiaBateriaScreen> {
  MarcaTelefono _marca = MarcaTelefono.samsung;

  static String nombre(AppLocalizations l, MarcaTelefono m) => switch (m) {
    MarcaTelefono.samsung => 'Samsung',
    MarcaTelefono.xiaomi => 'Xiaomi',
    MarcaTelefono.motorola => 'Motorola',
    MarcaTelefono.huawei => 'Huawei',
    MarcaTelefono.otra => l.permBateriaOtra,
  };

  static List<String> pasos(AppLocalizations l, MarcaTelefono m) => switch (m) {
    MarcaTelefono.samsung => [
      l.permBatSamsung1,
      l.permBatSamsung2,
      l.permBatSamsung3,
      l.permBatSamsung4,
    ],
    MarcaTelefono.xiaomi => [
      l.permBatXiaomi1,
      l.permBatXiaomi2,
      l.permBatXiaomi3,
      l.permBatXiaomi4,
    ],
    MarcaTelefono.motorola => [
      l.permBatMotorola1,
      l.permBatMotorola2,
      l.permBatMotorola3,
      l.permBatMotorola4,
    ],
    MarcaTelefono.huawei => [
      l.permBatHuawei1,
      l.permBatHuawei2,
      l.permBatHuawei3,
      l.permBatHuawei4,
    ],
    MarcaTelefono.otra => [
      l.permBatOtra1,
      l.permBatOtra2,
      l.permBatOtra3,
      l.permBatOtra4,
    ],
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PlantillaPermiso(
      icono: Icons.battery_saver_outlined,
      titulo: l.permBateriaTitulo,
      texto: l.permBateriaTexto,
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Sp.sm,
            runSpacing: Sp.sm,
            children: [
              for (final m in MarcaTelefono.values)
                ChoiceChip(
                  label: Text(nombre(l, m)),
                  selected: _marca == m,
                  onSelected: (_) => setState(() => _marca = m),
                ),
            ],
          ),
          const SizedBox(height: Sp.lg),
          PasosNumerados(pasos: pasos(l, _marca)),
          const SizedBox(height: Sp.sm),
          TextButton.icon(
            onPressed: () async {
              try {
                await ref.read(permisosProvider).abrirAjustesApp();
              } on Object {
                // Sin plugin.
              }
            },
            icon: const Icon(Icons.settings_outlined),
            label: Text(l.permBateriaAbrir),
          ),
        ],
      ),
      primario: l.listo,
      onPrimario: () => _cerrar(context, true),
    );
  }
}
