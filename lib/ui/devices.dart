import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';
import '../data/store.dart';
import 'widgets.dart';
import 'shell.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key, required this.store, required this.onEvents});
  final CrowlyStore store;
  final VoidCallback onEvents;
  @override
  Widget build(BuildContext context) {
    final event = store.activeEvent;
    if (event == null) {
      return EmptyState(
        title: 'Nenhum evento ativo',
        description:
            'Os dispositivos aparecerão aqui quando houver um evento em andamento.',
        action: 'Ver eventos futuros',
        onAction: onEvents,
        icon: Icons.monitor_heart_outlined,
      );
    }
    final devices = store.forEvent('devices', event.text('id'));
    final online = devices.where((d) => d.text('status') == 'online').length;
    const groups = {
      'counter': 'Contadores de pessoas',
      'queue': 'Sensores de fila',
      'button': 'Botões de alerta',
      'environment': 'Monitoramento ambiental',
    };
    const icons = {
      'counter': Icons.groups_outlined,
      'queue': Icons.queue_outlined,
      'button': Icons.warning_amber,
      'environment': Icons.thermostat_outlined,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Metrics([
          Metric('Total', '${devices.length}'),
          Metric('Ativos', '$online'),
          Metric('Alertas', '${devices.length - online}'),
        ]),
        if (devices.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 45),
            child: Text(
              'Nenhum dispositivo cadastrado. Cadastre os sensores no backend para receber leituras.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        for (final group in groups.entries)
          if (devices.any((d) => d.text('kind') == group.key)) ...[
            Section(
              group.value,
              trailing: Icon(icons[group.key], color: C.violet, size: 21),
            ),
            ...devices
                .where((d) => d.text('kind') == group.key)
                .map(
                  (device) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Panel(
                      onTap: () => openPage(
                        context,
                        store,
                        2,
                        () => DeviceDetail(
                          store: store,
                          deviceId: device.text('id'),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: device.text('status') == 'online'
                                ? C.green
                                : C.red,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              device.text('name'),
                              style: const TextStyle(color: Colors.white, 
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (device.text('status') != 'online')
                            const Padding(
                              padding: EdgeInsets.only(right: 5),
                              child: Pill('Offline', color: C.red),
                            ),
                          Pill(
                            device.text('reading', '—'),
                            color: group.key == 'environment'
                                ? C.green
                                : C.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
      ],
    );
  }
}

class DeviceDetail extends StatelessWidget {
  const DeviceDetail({super.key, required this.store, required this.deviceId});
  final CrowlyStore store;
  final String deviceId;
  @override
  Widget build(BuildContext context) {
    final matches = store
        .rows('devices')
        .where((d) => d.text('id') == deviceId);
    if (matches.isEmpty) return const Text('Dispositivo não encontrado.');
    final d = matches.first;
    final online = d.text('status') == 'online';
    final commands = store
        .rows('commands')
        .where((c) => c.text('device_id') == deviceId)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Section('DISPOSITIVO'),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                const {
                      'counter': 'CONTADOR DE PESSOAS',
                      'queue': 'SENSOR DE FILA',
                      'button': 'BOTÃO DE ALERTA',
                      'environment': 'SENSOR AMBIENTAL',
                    }[d.text('kind')] ??
                    'DISPOSITIVO',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                d.text('name'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          border: online ? C.green : C.pink,
          child: Center(
            child: Column(
              children: [
                Pill(
                  online ? '• ONLINE' : '• OFFLINE',
                  color: online ? C.green : C.pink,
                ),
                const SizedBox(height: 14),
                Text(
                  'Este dispositivo está ${online ? 'online' : 'offline'}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 7),
                Text(
                  'Última comunicação: ${relativeTime(d['last_seen'] as String?)}',
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            children: [
              KeyValue('Bateria', '${d.integer('battery')}%'),
              KeyValue(
                'Intensidade do Sinal',
                online ? 'Conectado' : 'Sem sinal',
              ),
              KeyValue('Última Leitura', d.text('reading', '—')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => runAction(
              context,
              () => store.command(
                d.text('event_id'),
                'restart',
                deviceId: deviceId,
              ),
              success: store.demo
                  ? 'Reinício simulado registrado na fila local.'
                  : 'Solicitação enviada. Aguardando confirmação do dispositivo.',
            ),
            child: const Text('Reiniciar remotamente'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => reportProblem(context, d),
            child: const Text('Reportar problema'),
          ),
        ),
        if (commands.isNotEmpty) ...[
          const Section('Solicitações'),
          ...commands.map(
            (c) => Panel(
              child: KeyValue(
                c.text('kind') == 'restart'
                    ? 'Reinício remoto'
                    : 'Problema reportado',
                c.text('status') == 'queued' ? 'Na fila' : c.text('status'),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> reportProblem(BuildContext context, CrowlyRow d) async {
    final note = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reportar problema'),
        content: TextField(
          controller: note,
          maxLines: 3,
          maxLength: 1000,
          decoration: const InputDecoration(hintText: 'Descreva o problema'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, note.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    // Disposed after the dialog route has finished its transition.
    Future<void>.delayed(const Duration(seconds: 1), note.dispose);
    if (value != null && value.isNotEmpty && context.mounted) {
      await runAction(
        context,
        () => store.command(
          d.text('event_id'),
          'issue',
          deviceId: deviceId,
          note: value,
        ),
        success: 'Problema registrado.',
      );
    }
  }
}
