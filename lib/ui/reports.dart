import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/models.dart';
import '../core/theme.dart';
import '../data/store.dart';
import 'widgets.dart';
import 'dashboard.dart';
import 'alerts.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key, required this.store, required this.onEvents});
  final CrowlyStore store;
  final VoidCallback onEvents;
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String? selected;
  @override
  Widget build(BuildContext context) {
    if (!widget.store.isAdmin) return const AdminOnly();
    final reports = widget.store.rows('reports');
    final ids = reports.map((r) => r.text('event_id')).toSet();
    final events = widget.store
        .rows('events')
        .where((e) => ids.contains(e.text('id')))
        .toList();
    if (events.isEmpty) {
      return EmptyState(
        title: 'Nenhum relatório disponível',
        description:
            'Os relatórios serão gerados após a realização de um evento.',
        action: 'Ver eventos passados',
        onAction: widget.onEvents,
        icon: Icons.bar_chart_rounded,
      );
    }
    if (!events.any((e) => e.text('id') == selected)) {
      selected = events.first.text('id');
    }
    final event = events.firstWhere((e) => e.text('id') == selected);
    final report = reports.firstWhere((r) => r.text('event_id') == selected);
    final average = reports.isEmpty
        ? 0
        : reports
                  .map((r) => r.number('average_occupancy'))
                  .reduce((a, b) => a + b) /
              reports.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: selected,
          decoration: const InputDecoration(labelText: 'Evento'),
          isExpanded: true,
          items: events
              .map(
                (e) => DropdownMenuItem(
                  value: e.text('id'),
                  child: Text(e.text('title'), overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => selected = v),
        ),
        const Section('Resumo'),
        Metric('Ingressos', compact(report.integer('total_entries'))),
        const SizedBox(height: 10),
        Metric('Ocupação', '${report.number('average_occupancy').round()}%'),
        const Section('Histórico'),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Últimos ${reports.length} eventos realizados',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              KeyValue('Média de ocupação', '${average.round()}%'),
            ],
          ),
        ),
        const Section('Fluxo por Área'),
        Panel(
          child: Column(
            children: widget.store
                .forEvent('areas', selected!)
                .take(5)
                .map((a) => AreaProgress(a))
                .toList(),
          ),
        ),
        const Section('Histórico de Movimentação'),
        Panel(child: DataChart(widget.store.forEvent('samples', selected!))),
        const Section('Capacidade e Ocupação'),
        Metrics([
          Metric(
            'Capacidade Máxima',
            count(event.integer('capacity')),
            icon: Icons.fullscreen,
          ),
          Metric(
            'Ocupação Média',
            '${report.number('average_occupancy').round()}%',
            icon: Icons.monitor_heart_outlined,
            progress: report.number('average_occupancy') / 100,
          ),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () =>
                runAction(context, () => exportReport(widget.store, event)),
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Relatório PDF'),
          ),
        ),
      ],
    );
  }
}

class EventReport extends StatelessWidget {
  const EventReport({super.key, required this.store, required this.event});
  final CrowlyStore store;
  final CrowlyRow event;
  @override
  Widget build(BuildContext context) {
    if (!store.isAdmin) return const AdminOnly();
    final id = event.text('id');
    final reports = store.forEvent('reports', id);
    if (reports.isEmpty) {
      return const Panel(
        child: Text('O relatório deste evento ainda não está disponível.'),
      );
    }
    final r = reports.first;
    final points = store.forEvent('samples', id)
      ..sort((a, b) => a.text('recorded_at').compareTo(b.text('recorded_at')));
    final alerts = store.forEvent('alerts', id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.text('title'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Metrics([
          Metric(
            'Público Total',
            compact(r.integer('total_entries')),
            icon: Icons.confirmation_number_outlined,
          ),
          Metric(
            'Pico Ocupação',
            '${r.number('peak_occupancy').round()}%',
            icon: Icons.groups_outlined,
          ),
          Metric(
            'Média Ocupação',
            '${r.number('average_occupancy').round()}%',
            icon: Icons.assessment_outlined,
          ),
        ]),
        const Section('Fluxo de Entradas / Saídas'),
        Panel(
          child: Metrics([
            Metric('Total Entradas', compact(r.integer('total_entries'))),
            Metric('Total Saídas', compact(r.integer('total_exits'))),
          ]),
        ),
        const Section('Ocupação ao longo do tempo'),
        Panel(child: DataChart(points, occupancyOnly: true)),
        const Section('Entradas e Saídas por Hora'),
        Panel(child: DataChart(points, bars: true)),
        const SizedBox(height: 16),
        Panel(
          child: Row(
            children: [
              const Icon(Icons.thermostat, color: C.violet, size: 20),
              Expanded(
                child: Text(
                  'Temp. Média ${r['temperature'] == null || r.number('temperature') == 0 ? '—' : '${r.number('temperature').round()}°C'}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
              const Icon(Icons.water_drop_outlined, color: C.pink, size: 20),
              Expanded(
                child: Text(
                  'Umidade ${r['humidity'] == null || r.number('humidity') == 0 ? '—' : '${r.number('humidity').round()}%'}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const Section('Alertas do Evento'),
        Metrics(
          ['emergency', 'high', 'medium', 'low']
              .map(
                (s) => Metric(
                  severityLabel(s),
                  '${alerts.where((a) => a.text('severity') == s).length}',
                  color: severityColor(s),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        ...alerts
            .take(3)
            .map(
              (a) => AlertTile(a, onTap: () => alertDetail(context, store, a)),
            ),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () =>
                  runAction(context, () => exportReport(store, event)),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
              label: const Text('Relatório PDF'),
            ),
            OutlinedButton.icon(
              onPressed: () => runAction(
                context,
                () => exportReport(store, event, share: true),
              ),
              icon: const Icon(Icons.share_outlined, size: 16),
              label: const Text('Partilhar'),
            ),
          ],
        ),
      ],
    );
  }
}

Future<Uint8List> reportBytes(CrowlyStore store, CrowlyRow event) async {
  if (!store.isAdmin) throw StateError('Relatórios são exclusivos do administrador.');
  final reports = store.forEvent('reports', event.text('id'));
  if (reports.isEmpty) throw StateError('Relatório não disponível');
  final report = reports.first;
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
  );
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Text(
          'CROWLY',
          style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
        pw.Text(event.text('title'), style: const pw.TextStyle(fontSize: 20)),
        pw.Text(event.text('location')),
        pw.Text(dateLabel(event).replaceAll('•', '-')),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headers: ['Indicador', 'Valor'],
          data: [
            ['Entradas', count(report.integer('total_entries'))],
            ['Saídas', count(report.integer('total_exits'))],
            ['Pico de ocupação', '${report.number('peak_occupancy').round()}%'],
            [
              'Ocupação média',
              '${report.number('average_occupancy').round()}%',
            ],
            ['Capacidade', count(event.integer('capacity'))],
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Áreas monitoradas',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Área', 'Pessoas', 'Ocupação'],
          data: store
              .forEvent('areas', event.text('id'))
              .map(
                (a) => [
                  a.text('name'),
                  count(a.integer('people')),
                  '${occupancy(a).round()}%',
                ],
              )
              .toList(),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Alertas',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        ...store
            .forEvent('alerts', event.text('id'))
            .map(
              (a) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  '${a.text('title')} - ${severityLabel(a.text('severity'))} - ${statusLabel(a.text('status'))}',
                ),
              ),
            ),
        if (store.demo)
          pw.Text('Dados de demonstração. Sem conexão com sensores reais.'),
      ],
    ),
  );
  return doc.save();
}

Future<void> exportReport(
  CrowlyStore store,
  CrowlyRow event, {
  bool share = false,
}) async {
  final bytes = await reportBytes(store, event);
  if (share) {
    await Printing.sharePdf(bytes: bytes, filename: 'crowly-relatorio.pdf');
  } else {
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'crowly-relatorio',
    );
  }
}
