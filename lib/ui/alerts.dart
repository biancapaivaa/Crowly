import 'package:flutter/material.dart';

import '../core/models.dart';
import '../data/store.dart';
import 'widgets.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key, required this.store, this.eventId});
  final CrowlyStore store;
  final String? eventId;
  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  int filter = 0;
  String status = 'all';
  @override
  Widget build(BuildContext context) {
    final id = widget.eventId ?? widget.store.activeEvent?.text('id');
    final alerts = id == null
        ? <CrowlyRow>[]
        : widget.store.forEvent('alerts', id);
    alerts.sort((a, b) => b.text('created_at').compareTo(a.text('created_at')));
    const levels = ['emergency', 'high', 'medium', 'low'];
    final filtered = alerts
        .where(
          (a) =>
              (filter == 0 || a.text('severity') == levels[filter - 1]) &&
              (status == 'all' || a.text('status') == status),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FilterStrip(
                labels: const ['Todos', 'Emergência', 'Alta', 'Média', 'Baixa'],
                value: filter,
                onChanged: (v) => setState(() => filter = v),
              ),
            ),
            IconButton(
              tooltip: 'Filtrar por tratamento',
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ['all', 'open', 'reviewing', 'resolved']
                        .map(
                          (s) => RadioListTile<String>(
                            title: Text(
                              s == 'all' ? 'Todos os estados' : statusLabel(s),
                            ),
                            value: s,
                            groupValue: status,
                            onChanged: (v) {
                              setState(() => status = v!);
                              Navigator.pop(ctx);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              icon: const Icon(Icons.tune, size: 19),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Metrics(
          levels
              .map(
                (s) => Metric(
                  severityLabel(s),
                  '${alerts.where((a) => a.text('severity') == s).length}',
                  color: severityColor(s),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          EmptyState(
            title: 'Nenhum alerta encontrado',
            description:
                'Não há alertas para o evento e os filtros selecionados.',
            action: 'Limpar filtros',
            onAction: () => setState(() {
              filter = 0;
              status = 'all';
            }),
            icon: Icons.notifications_none,
          ),
        ...filtered.map(
          (a) => AlertTile(
            a,
            showStatus: true,
            onTap: () => alertDetail(context, widget.store, a),
          ),
        ),
      ],
    );
  }
}

Future<void> alertDetail(
  BuildContext context,
  CrowlyStore store,
  CrowlyRow alert,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (ctx) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pill(
            severityLabel(alert.text('severity')),
            color: severityColor(alert.text('severity')),
          ),
          const SizedBox(height: 14),
          Text(alert.text('title'), style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(alert.text('description')),
          KeyValue('Recebido', relativeTime(alert['created_at'] as String?)),
          KeyValue('Tratamento', statusLabel(alert.text('status'))),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: [
              OutlinedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await runAction(
                    context,
                    () => store.alertStatus(alert, 'reviewing'),
                    success: 'Alerta em análise.',
                  );
                },
                child: const Text('Analisar'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await runAction(
                    context,
                    () => store.alertStatus(alert, 'resolved'),
                    success: 'Alerta resolvido.',
                  );
                },
                child: const Text('Marcar resolvido'),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);
