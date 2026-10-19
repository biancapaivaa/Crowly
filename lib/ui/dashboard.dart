import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';
import '../data/store.dart';
import 'widgets.dart';
import 'shell.dart';
import 'alerts.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.store,
    required this.onEvents,
    required this.onAlerts,
  });
  final CrowlyStore store;
  final VoidCallback onEvents, onAlerts;
  @override
  Widget build(BuildContext context) {
    final event = store.activeEvent;
    if (event == null) {
      return EmptyState(
        title: 'Nenhum evento ativo',
        description: 'Escolha ou crie um evento para iniciar o monitoramento.',
        action: 'Ver eventos',
        onAction: onEvents,
        brand: true,
      );
    }
    final id = event.text('id');
    final samples = store.forEvent('samples', id);
    final latest = samples.isEmpty ? null : samples.last;
    final queues = store.forEvent('devices', id).where((d) => d.text('kind') == 'queue').toList();
    final areas = store.forEvent('areas', id);
    final alerts = store
        .forEvent('alerts', id)
        .where((a) => a.text('status') != 'resolved')
        .toList();
    final percent = event.number('capacity') == 0
        ? 0.0
        : event.number('people') / event.number('capacity');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (store.rows('events').where((e) => e.text('status') == 'live').length > 1) ...[
          DropdownButtonFormField<String>(
            key: ValueKey(id),
            initialValue: id,
            isExpanded: true,
            dropdownColor: C.raised,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Evento monitorado'),
            items: store.rows('events').where((e) => e.text('status') == 'live').map((e) => DropdownMenuItem(value: e.text('id'), child: Text(e.text('title'), overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (value) { if (value != null) store.selectEvent(value); },
          ),
          const SizedBox(height: 14),
        ],
        EventBanner(
          event: event,
          onTap: () => openPage(
            context,
            store,
            0,
            () => MapPage(store: store, event: event),
            map: true,
          ),
        ),
        const Section('Visão Geral'),
        Metrics([
          Metric(
            'Capacidade Máxima',
            count(event.integer('capacity')),
            icon: Icons.fullscreen,
          ),
          Metric(
            'Ocupação Atual',
            '${(percent * 100).round()}%',
            icon: Icons.monitor_heart_outlined,
            progress: percent,
          ),
          Metric(
            'Público Presente',
            compact(event.integer('people')),
            icon: Icons.groups_outlined,
          ),
        ]),
        const Section('Sensores ao vivo'),
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(latest == null ? 'Aguardando a primeira leitura do ESP32 para este evento.' : 'Última leitura: ${relativeTime(latest.text('recorded_at'))}'),
          if (latest != null) ...[
            const SizedBox(height: 12),
            Metrics([
              Metric('Temperatura', latest['temperature'] == null ? '—' : '${latest.number('temperature').toStringAsFixed(1)} °C', icon: Icons.thermostat_outlined),
              Metric('Umidade', latest['humidity'] == null ? '—' : '${latest.number('humidity').toStringAsFixed(1)}%', icon: Icons.water_drop_outlined),
            ]),
          ],
          if (queues.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Fila: ${queues.first.text('reading', 'Sem leitura')}'),
          ],
        ])),
        const Section('Horários de Maior Movimento'),
        Panel(child: DataChart(store.forEvent('samples', id), bars: true)),
        const Section('Áreas monitoradas'),
        Panel(
          child: Column(
            children: [
              ...areas
                  .take(4)
                  .map(
                    (a) => AreaProgress(
                      a,
                      onTap: () => openPage(
                        context,
                        store,
                        0,
                        () => MapPage(
                          store: store,
                          event: event,
                          initialArea: a.text('id'),
                        ),
                        map: true,
                      ),
                    ),
                  ),
              TextButton(
                onPressed: () => openPage(
                  context,
                  store,
                  0,
                  () => MapPage(store: store, event: event),
                  map: true,
                ),
                child: const Text(
                  'Ver todas as áreas',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        Section('Alertas ativos', trailing: Pill('${alerts.length} ativos')),
        if (alerts.isEmpty)
          const Panel(
            child: Text(
              'Nenhum alerta ativo',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ...alerts
            .take(3)
            .map(
              (a) => AlertTile(a, onTap: () => alertDetail(context, store, a)),
            ),
        if (alerts.length > 3)
          TextButton(
            onPressed: onAlerts,
            child: const Text('Ver todos os alertas'),
          ),
      ],
    );
  }
}

class EventBanner extends StatelessWidget {
  const EventBanner({super.key, required this.event, this.onTap});
  final CrowlyRow event;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final live = event.text('status') == 'live';
    return Panel(
      padding: 0,
      border: C.violet.withOpacity(.6),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 180),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF4C245A), C.background],
          ),
          image: event.text('image_url').startsWith('https://')
              ? DecorationImage(
                  image: NetworkImage(event.text('image_url')),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(.65),
                    BlendMode.darken,
                  ),
                  onError: (_, __) {},
                )
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Pill(
              live ? '• AO VIVO' : 'EVENTO AGENDADO',
              color: live ? C.pink : C.violet,
            ),
            const SizedBox(height: 12),
            Text(
              event.text('title'),
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              event.text('location'),
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
            const SizedBox(height: 15),
            if (live)
              Metrics([
                Metric('Pessoas', compact(event.integer('people'))),
                Metric(
                  'Ocupação',
                  '${event.number('capacity') == 0 ? 0 : (event.number('people') / event.number('capacity') * 100).round()}%',
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

class AreaProgress extends StatelessWidget {
  const AreaProgress(this.area, {super.key, this.onTap});
  final CrowlyRow area;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final value = occupancy(area);
    final high = value >= 70;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    area.text('name'),
                    style: const TextStyle(color: Colors.white, 
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${value.round()}%',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                const SizedBox(width: 7),
                Pill(high ? 'Alta' : 'Normal', color: high ? C.pink : C.violet),
              ],
            ),
            const SizedBox(height: 5),
            Progress(value / 100, color: high ? C.pink : C.violet),
          ],
        ),
      ),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    required this.store,
    required this.event,
    this.initialArea,
  });
  final CrowlyStore store;
  final CrowlyRow event;
  final String? initialArea;
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String? selected;
  final transform = TransformationController();
  @override
  void initState() {
    super.initState();
    selected = widget.initialArea;
    widget.store.selectedEventId = widget.event.text('id');
  }

  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  void zoom(double factor) {
    final m = transform.value.clone()..scale(factor);
    final scale = m.getMaxScaleOnAxis();
    if (scale >= 1 && scale <= 3) transform.value = m;
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final id = widget.event.text('id');
    final events = store.rows('events').where((r) => r.text('id') == id);
    final event = events.isNotEmpty ? events.first : widget.event;
    final areas = store.forEvent('areas', id)
      ..sort((a, b) => a.integer('position').compareTo(b.integer('position')));
    final matches = areas.where((a) => a.text('id') == selected);
    final area = matches.isEmpty ? null : matches.first;
    final alerts = store
        .forEvent('alerts', id)
        .where((a) => a.text('status') != 'resolved')
        .toList();
    Widget block(int index) {
      if (index >= areas.length) return const SizedBox();
      final a = areas[index];
      final value = occupancy(a);
      final active = selected == a.text('id');
      final color = active
          ? C.pink
          : index == 1
          ? C.violet
          : value > 85
          ? C.red
          : value >= 70
          ? C.yellow
          : C.green;
      return Expanded(
        child: Opacity(
          opacity: area == null || active ? 1 : .4,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Panel(
              padding: 5,
              color: color.withOpacity(.13),
              border: color,
              onTap: () => setState(() => selected = a.text('id')),
              child: Center(
                child: Text(
                  '${a.text('name')}${a.integer('capacity') > 0 ? ' (${value.round()}%)' : ''}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, 
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (area == null) ...[
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Pill(statusLabel(event.text('status')).toUpperCase()),
                    const SizedBox(width: 6),
                    if (event.text('status') == 'live')
                      const Pill('• AO VIVO', color: C.pink),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  event.text('title'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  dateLabel(event),
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
                Text(
                  event.text('location'),
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: [
                    OutlinedButton(
                      onPressed: () => runAction(context, store.load),
                      child: const Text('Atualizar'),
                    ),
                    OutlinedButton(
                      onPressed: () => openPage(
                        context,
                        store,
                        4,
                        () => AlertsPage(store: store, eventId: id),
                      ),
                      child: Text('Alertas (${alerts.length})'),
                    ),
                    OutlinedButton(
                      onPressed: event.text('status') != 'live'
                          ? null
                          : () async {
                              if (await confirm(
                                context,
                                'Encerrar evento?',
                                'O monitoramento será encerrado e o relatório será gerado.',
                              )) {
                                if (context.mounted) {
                                  await runAction(
                                    context,
                                    () => store.eventStatus(event, 'ended'),
                                    success: 'Evento encerrado.',
                                  );
                                }
                              }
                            },
                      child: const Text(
                        'Encerrar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        Panel(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      area == null
                          ? 'Mapa de Ocupação Real-Time'
                          : 'Mapa — Área Selecionada',
                      style: const TextStyle(color: Colors.white, 
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ampliar',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => zoom(1.2),
                    icon: const Icon(Icons.add, size: 16),
                  ),
                  IconButton(
                    tooltip: 'Reduzir',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => zoom(1 / 1.2),
                    icon: const Icon(Icons.remove, size: 16),
                  ),
                ],
              ),
              if (areas.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nenhuma área cadastrada para este evento.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              else
                SizedBox(
                  height: 205,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: InteractiveViewer(
                      transformationController: transform,
                      minScale: 1,
                      maxScale: 3,
                      child: Column(
                        children: [
                          Expanded(child: Row(children: [block(0), block(1)])),
                          Expanded(
                            child: Row(
                              children: [
                                block(2),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [block(3), block(5)],
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [block(4), block(6)],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (area == null)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 9,
                    children: [
                      Pill('Seguro <70%', color: C.green),
                      Pill('Atenção 70–85%', color: C.yellow),
                      Pill('Crítico >85%', color: C.red),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (area != null)
          Panel(
            border: C.violet,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        area.text('name'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Pill(
                      occupancy(area) > 85 ? 'Crítico' : 'Monitorando',
                      color: occupancy(area) > 85 ? C.red : C.green,
                    ),
                    IconButton(
                      tooltip: 'Fechar seleção',
                      onPressed: () => setState(() => selected = null),
                      icon: const Icon(Icons.close, size: 16),
                    ),
                  ],
                ),
                const Text(
                  'Monitoramento da área',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
                const Divider(height: 22),
                Row(
                  children: [
                    SizedBox.square(
                      dimension: 104,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.square(
                            dimension: 92,
                            child: CircularProgressIndicator(
                              value: occupancy(area) / 100,
                              strokeWidth: 7,
                              backgroundColor: C.nav,
                              color: occupancy(area) > 85 ? C.red : C.violet,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${occupancy(area).round()}%',
                                style: const TextStyle(color: Colors.white, 
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Ocupação',
                                style: TextStyle(fontSize: 10, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        children: [
                          KeyValue(
                            'Pessoas no local',
                            count(area.integer('people')),
                          ),
                          KeyValue(
                            'Capacidade Max',
                            count(area.integer('capacity')),
                          ),
                          KeyValue(
                            'Sensores ativos',
                            '${area.integer('sensor_count')}',
                            color: C.green,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Metrics([
                  Metric('Entradas', count(event.integer('entries'))),
                  Metric('Saídas', count(event.integer('exits'))),
                ]),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Histórico • ${area.text('name')}'),
                          content: const Text(
                            'O histórico por área depende de leituras enviadas pelos sensores. O total do evento está disponível em Relatórios.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Fechar'),
                            ),
                          ],
                        ),
                      ),
                      child: const Text('Ver histórico'),
                    ),
                    FilledButton(
                      onPressed: () => runAction(
                        context,
                        () => store.command(
                          id,
                          'dispatch',
                          areaId: area.text('id'),
                        ),
                        success: store.demo
                            ? 'Acionamento registrado na demonstração.'
                            : 'Solicitação enviada à fila de operações.',
                      ),
                      child: const Text('Acionar equipe'),
                    ),
                  ],
                ),
              ],
            ),
          )
        else ...[
          Metrics([
            Metric('Público total', count(event.integer('people'))),
            Metric('Entradas', count(event.integer('entries')), color: C.green),
            Metric('Saídas', count(event.integer('exits')), color: C.pink),
          ]),
          const SizedBox(height: 8),
          Metrics([
            Metric(
              'Capacidade',
              '${event.number('capacity') == 0 ? 0 : (event.number('people') / event.number('capacity') * 100).round()}%',
            ),
            Metric(
              'Em atenção',
              '${areas.where((a) => occupancy(a) >= 70).length} áreas',
              color: C.yellow,
            ),
            Metric('Alertas', '${alerts.length} ativos', color: C.red),
          ]),
          Section(
            'Alertas recentes',
            trailing: Pill('${alerts.length} ativos'),
          ),
          ...alerts
              .take(2)
              .map(
                (a) =>
                    AlertTile(a, onTap: () => alertDetail(context, store, a)),
              ),
        ],
      ],
    );
  }
}
