import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/store.dart';
import 'widgets.dart';
import 'dashboard.dart';
import 'events.dart';
import 'devices.dart';
import 'reports.dart';
import 'alerts.dart';
import 'profile.dart';

class CrowlyShell extends StatefulWidget {
  const CrowlyShell({super.key, required this.store, required this.onLogout});
  final CrowlyStore store;
  final Future<void> Function() onLogout;
  @override
  State<CrowlyShell> createState() => _CrowlyShellState();
}

class _CrowlyShellState extends State<CrowlyShell> {
  int tab = 0;
  void _tabRequested() {
    if (mounted) setState(() => tab = rootTab.value);
  }

  @override
  void initState() {
    super.initState();
    rootTab.value = 0;
    rootTab.addListener(_tabRequested);
  }

  @override
  void dispose() {
    rootTab.removeListener(_tabRequested);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final store = widget.store;
      return AppFrame(
        store: store,
        tab: tab,
        onTab: (v) {
          rootTab.value = v;
        },
        onProfile: () => profile(context),
        body: store.accountLoaded && !store.hasAccess && store.error == null
            ? EmptyState(title: 'Conta sem acesso', description: 'Peça ao administrador para cadastrar sua conta. Se você é o primeiro admin, aplique a configuração indicada no guia.', action:'Sair da conta', onAction: () => unawaited(widget.onLogout()), icon: Icons.lock_outline)
            : store.loading && store.data.isEmpty
            ? const LoadingEvents()
            : store.error != null
            ? EmptyState(
                title: 'Não foi possível carregar',
                description: store.error!,
                action: 'Tentar novamente',
                onAction: () => unawaited(store.load()),
                icon: Icons.cloud_off,
              )
            : RefreshIndicator(
                onRefresh: store.load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: switch (tab) {
                    0 => Dashboard(
                      store: store,
                      onEvents: () {
                        rootTab.value = 1;
                      },
                      onAlerts: () {
                        rootTab.value = 4;
                      },
                    ),
                    1 => EventsPage(store: store),
                    2 => DevicesPage(
                      store: store,
                      onEvents: () {
                        rootTab.value = 1;
                      },
                    ),
                    3 => !store.isAdmin ? const AdminOnly() : ReportsPage(
                      store: store,
                      onEvents: () {
                        rootTab.value = 1;
                      },
                    ),
                    _ => AlertsPage(store: store),
                  },
                ),
              ),
      );
    },
  );
  Future<void> profile(BuildContext context) => Navigator.push<void>(context,
    MaterialPageRoute(builder: (_) => ProfilePage(store: widget.store, onLogout: widget.onLogout)));

}

class AppFrame extends StatelessWidget {
  const AppFrame({
    super.key,
    required this.store,
    required this.tab,
    required this.body,
    this.onTab,
    this.onProfile,
    this.mapNavigation = false,
    this.back = false,
  });
  final CrowlyStore store;
  final int tab;
  final Widget body;
  final ValueChanged<int>? onTab;
  final VoidCallback? onProfile;
  final bool mapNavigation, back;
  @override
  Widget build(BuildContext context) {
    final indices = (mapNavigation ? [0, 1, 2, 4] : [0, 1, 2, 3, 4]).where((i) => i != 3 || store.isAdmin).toList();
    const labels = ['Home', 'Eventos', 'Dispositivos', 'Relatórios', 'Alertas'];
    const icons = [
      Icons.home_outlined,
      Icons.calendar_month_outlined,
      Icons.smartphone_outlined,
      Icons.bar_chart_rounded,
      Icons.notifications_none_rounded,
    ];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Row(
                    children: [
                      if (back)
                        IconButton(
                          tooltip: 'Voltar',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 40,
                          ),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        ),
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Brand(),
                          ),
                        ),
                      ),
                      if (store.demo)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Pill('DEMO'),
                        ),
                      circle(
                        Icons.notifications_none_rounded,
                        'Alertas',
                        () => openPage(
                          context,
                          store,
                          4,
                          () => AlertsPage(store: store),
                        ),
                      ),
                      const SizedBox(width: 8),
                      circle(
                        Icons.person_outline,
                        'Perfil',
                        onProfile ?? () => Navigator.push<void>(context, MaterialPageRoute(builder: (_) => ProfilePage(store: store, onLogout: store.onLogout))),
                      ),
                    ],
                  ),
                ),
                Expanded(child: tab == 3 && !store.isAdmin ? const AdminOnly() : body),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: C.nav,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: indices
                          .map(
                            (i) => Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  if (onTab != null) {
                                    onTab!(i);
                                  } else {
                                    Navigator.popUntil(
                                      context,
                                      (r) => r.isFirst,
                                    );
                                    rootTab.value = i;
                                  }
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: i == tab
                                            ? C.violet
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        boxShadow: i == tab
                                            ? [
                                                BoxShadow(
                                                  color: C.violet.withOpacity(
                                                    .4,
                                                  ),
                                                  blurRadius: 10,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Icon(
                                        icons[i],
                                        size: 19,
                                        color: i == tab
                                            ? Colors.white
                                            : C.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      labels[i],
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: i == tab
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget circle(IconData icon, String label, VoidCallback onPressed) =>
      SizedBox.square(
        dimension: 34,
        child: IconButton(
          tooltip: label,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: C.nav,
            side: const BorderSide(color: C.violet, width: .6),
          ),
          icon: Icon(icon, size: 17),
        ),
      );
}

// Subpages can request a main tab without retaining a second shell.
final rootTab = ValueNotifier<int>(0);
void openPage(
  BuildContext context,
  CrowlyStore store,
  int tab,
  Widget Function() builder, {
  bool map = false,
}) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => AnimatedBuilder(
        animation: store,
        builder: (context, _) => AppFrame(
          store: store,
          tab: tab,
          back: true,
          mapNavigation: map,
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: builder(),
          ),
        ),
      ),
    ),
  );
}

class LoadingEvents extends StatelessWidget {
  const LoadingEvents({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        const SizedBox(height: 35),
        const CircularProgressIndicator(color: C.violet, strokeWidth: 2),
        const SizedBox(height: 15),
        const Text('Carregando eventos...', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 20),
        Panel(
          child: Column(
            children: [
              Container(height: 14, width: 110, color: C.raised),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: List.generate(
                  28,
                  (_) => Container(
                    decoration: BoxDecoration(
                      color: C.raised,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            children: [
              Container(height: 12, color: C.raised),
              const SizedBox(height: 10),
              Container(height: 12, color: C.raised),
            ],
          ),
        ),
      ],
    ),
  );
}
