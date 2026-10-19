import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/models.dart';
import '../core/theme.dart';
import '../data/store.dart';
import 'widgets.dart';
import 'shell.dart';
import 'dashboard.dart';
import 'reports.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key, required this.store});
  final CrowlyStore store;
  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final search = TextEditingController();
  int filter = 0;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final events =
        widget.store
            .rows('events')
            .where(
              (e) => '${e.text('title')} ${e.text('location')}'
                  .toLowerCase()
                  .contains(query),
            )
            .toList()
          ..sort((a, b) => a.text('starts_at').compareTo(b.text('starts_at')));
    final future = events
        .where((e) => ['live', 'scheduled'].contains(e.text('status')))
        .toList();
    final past = events
        .where((e) => ['ended', 'cancelled'].contains(e.text('status')))
        .toList()
        .reversed
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Buscar eventos...',
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpar busca',
                    onPressed: () => setState(search.clear),
                    icon: const Icon(Icons.close, size: 17),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilterStrip(
                labels: const ['Futuros', 'Passados', 'Calendário'],
                value: filter,
                onChanged: (v) {
                  if (v == 2) {
                    openPage(
                      context,
                      widget.store,
                      1,
                      () => CalendarPage(store: widget.store),
                    );
                  } else {
                    setState(() => filter = v);
                  }
                },
              ),
            ),
            IconButton(
              tooltip: 'Novo evento',
              onPressed: () => createEventDialog(context, widget.store),
              icon: const Icon(Icons.add_circle_outline, color: C.pink),
            ),
          ],
        ),
        if (events.isEmpty)
          EmptyState(
            title: query.isEmpty
                ? 'Nenhum evento encontrado'
                : 'Nenhum resultado encontrado',
            description: query.isEmpty
                ? 'Crie seu primeiro evento para começar.'
                : 'Tente buscar com outros termos ou verifique os filtros aplicados.',
            action: query.isEmpty ? 'Criar primeiro evento' : 'Limpar busca',
            onAction: () {
              if (query.isEmpty) {
                createEventDialog(context, widget.store);
              } else {
                setState(search.clear);
              }
            },
            brand: query.isEmpty,
            icon: Icons.search_off,
          ),
        if (filter == 0 && future.isNotEmpty) ...[
          const Section('Futuros'),
          ...future.map((e) => eventTile(context, e)),
        ],
        if (past.isNotEmpty) ...[
          const Section('Passados'),
          ...past.map((e) => eventTile(context, e)),
        ],
        if (filter == 1 && past.isEmpty && events.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Text(
              'Nenhum evento passado.',
              style: TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget eventTile(BuildContext context, CrowlyRow event) {
    final ended = event.text('status') == 'ended';
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Panel(
        padding: 12,
        onTap: () => openPage(
          context,
          widget.store,
          1,
          () => EventDetail(store: widget.store, eventId: event.text('id')),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 78,
              height: 83,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: const LinearGradient(
                  colors: [C.violet, C.nav, C.pink],
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: event.text('image_url').startsWith('https://')
                  ? Image.network(
                      event.text('image_url'),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.festival_outlined, size: 32),
                    )
                  : const Icon(
                      Icons.festival_outlined,
                      size: 32,
                      color: Colors.white70,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.text('title'),
                    style: const TextStyle(color: Colors.white, 
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  meta(Icons.calendar_today_outlined, dateLabel(event)),
                  meta(Icons.location_on_outlined, event.text('location')),
                  meta(
                    Icons.groups_outlined,
                    '${count(event.integer('capacity'))} pessoas',
                  ),
                  if (ended)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Pill('Ver dados', color: C.pink),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Pill(
                        event.text('status') == 'live'
                            ? '• AO VIVO'
                            : statusLabel(event.text('status')),
                        color: event.text('status') == 'live'
                            ? C.pink
                            : C.violet,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget meta(IconData icon, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 4),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 12, color: C.muted),
      const SizedBox(width: 5),
      Expanded(
        child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white)),
      ),
    ],
  ),
);

class EventDetail extends StatelessWidget {
  const EventDetail({super.key, required this.store, required this.eventId});
  final CrowlyStore store;
  final String eventId;
  @override
  Widget build(BuildContext context) {
    final matches = store.rows('events').where((e) => e.text('id') == eventId);
    if (matches.isEmpty) return const Text('Evento não encontrado.');
    final e = matches.first;
    if (e.text('status') == 'ended') return EventReport(store: store, event: e);
    final devices = store.forEvent('devices', eventId);
    final online = devices.where((d) => d.text('status') == 'online').length;
    final percent = devices.isEmpty ? 0.0 : online / devices.length;
    const kinds = {
      'counter': 'Contadores',
      'queue': 'Filas',
      'button': 'Alertas',
      'environment': 'Ambiental',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventBanner(event: e),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            children: [
              meta(
                Icons.calendar_today_outlined,
                '${dateLabel(e)} - ${DateFormat('HH:mm').format(e.date('ends_at'))}',
              ),
              meta(Icons.location_on_outlined, e.text('location')),
              meta(
                Icons.groups_outlined,
                'Capacidade Máxima: ${count(e.integer('capacity'))} pessoas',
              ),
            ],
          ),
        ),
        const Section('Dispositivos & Sensores'),
        Metrics(
          kinds.entries
              .map(
                (g) => Metric(
                  g.value,
                  '${devices.where((d) => d.text('kind') == g.key).length}',
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'PREPARAÇÃO DO EVENTO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Pill(
                    '${(percent * 100).toStringAsFixed(1)}% OK',
                    color: C.green,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Progress(percent, color: C.green),
              const SizedBox(height: 6),
              Text(
                '$online Online • ${devices.length - online} Offline',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              const SizedBox(height: 10),
              if (devices.isEmpty)
                const Text(
                  'Nenhum dispositivo cadastrado.',
                  style: TextStyle(color: Colors.white),
                ),
              ...devices
                  .where((d) => d.text('status') != 'online')
                  .take(4)
                  .map(
                    (d) => KeyValue(
                      d.text('name'),
                      d.text('status') == 'maintenance'
                          ? 'Em manutenção'
                          : 'Offline',
                      color: C.red,
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (e.text('status') == 'scheduled')
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                if (await confirm(
                  context,
                  'Iniciar monitoramento?',
                  'O evento ficará ao vivo para receber leituras e alertas.',
                )) {
                  if (context.mounted) {
                    await runAction(
                      context,
                      () => store.eventStatus(e, 'live'),
                      success: 'Monitoramento iniciado.',
                    );
                  }
                }
              },
              child: const Text('Iniciar Monitoramento'),
            ),
          ),
        if (e.text('status') == 'live')
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => openPage(
                context,
                store,
                0,
                () => MapPage(store: store, event: e),
                map: true,
              ),
              child: const Text('Acessar monitoramento'),
            ),
          ),
        if (e.text('status') == 'cancelled')
          const Pill('Evento cancelado', color: C.red),
      ],
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.store});
  final CrowlyStore store;
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime month;
  DateTime? selected;
  int mode = 0, status = 0;
  final search = TextEditingController();
  static const states = ['all', 'scheduled', 'live', 'ended', 'cancelled'];
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    month = DateTime(now.year, now.month);
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  bool onDay(CrowlyRow e, DateTime d) {
    final start = e.date('starts_at');
    final end = e.date('ends_at');
    return start.isBefore(DateTime(d.year, d.month, d.day + 1)) &&
        !end.isBefore(DateTime(d.year, d.month, d.day));
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.store
        .rows('events')
        .where(
          (e) =>
              (status == 0 || e.text('status') == states[status]) &&
              '${e.text('title')} ${e.text('location')}'.toLowerCase().contains(
                search.text.toLowerCase(),
              ),
        )
        .toList();
    final inMonth = events
        .where(
          (e) =>
              e
                  .date('starts_at')
                  .isBefore(DateTime(month.year, month.month + 1)) &&
              !e.date('ends_at').isBefore(month),
        )
        .toList();
    final selectedEvents = selected == null
        ? <CrowlyRow>[]
        : events.where((e) => onDay(e, selected!)).toList();
    final firstOffset = month.weekday % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final weekStart = (selected ?? DateTime.now()).subtract(
      Duration(days: (selected ?? DateTime.now()).weekday % 7),
    );
    final visibleDays = mode == 1 ? 7 : ((firstOffset + days + 6) ~/ 7) * 7;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Section('Calendário de eventos'),
        const Text(
          'Visualize e gerencie todos os eventos',
          style: TextStyle(fontSize: 11, color: Colors.white),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () => createEventDialog(context, widget.store),
          child: const Text('Novo evento'),
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Período anterior',
              onPressed: () => setState(() {
                if (mode == 1) {
                  selected = weekStart.subtract(const Duration(days: 7));
                  month = DateTime(selected!.year, selected!.month);
                } else {
                  month = DateTime(month.year, month.month - 1);
                  selected = null;
                }
              }),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy', 'pt_BR').format(month),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                selected = DateTime.now();
                month = DateTime(selected!.year, selected!.month);
              }),
              child: const Text('Hoje'),
            ),
            IconButton(
              tooltip: 'Próximo período',
              onPressed: () => setState(() {
                if (mode == 1) {
                  selected = weekStart.add(const Duration(days: 7));
                  month = DateTime(selected!.year, selected!.month);
                } else {
                  month = DateTime(month.year, month.month + 1);
                  selected = null;
                }
              }),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        FilterStrip(
          labels: const ['Mês', 'Semana', 'Lista'],
          value: mode,
          color: C.violet,
          onChanged: (v) => setState(() => mode = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Buscar por nome ou local',
            prefixIcon: Icon(Icons.search, size: 18),
          ),
        ),
        const SizedBox(height: 10),
        FilterStrip(
          labels: const [
            'Todos',
            'Agendados',
            'Em andamento',
            'Encerrados',
            'Cancelados',
          ],
          value: status,
          onChanged: (v) => setState(() => status = v),
        ),
        const SizedBox(height: 12),
        if (mode != 2)
          Panel(
            padding: 10,
            child: Column(
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          'Dom',
                          style: TextStyle(fontSize: 9, color: Colors.white),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Seg',
                          style: TextStyle(fontSize: 9, color: Colors.white),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Ter',
                          style: TextStyle(fontSize: 9, color: Colors.white),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Qua',
                          style: TextStyle(fontSize: 9, color: Colors.white),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Qui',
                          style: TextStyle(fontSize: 9, color: Colors.white),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Sex',
                          style: TextStyle(fontSize: 9, color: Colors.white),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Sáb',
                          style: TextStyle(fontSize: 9, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleDays,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 5,
                    childAspectRatio: .8,
                  ),
                  itemBuilder: (ctx, index) {
                    final day = mode == 1
                        ? weekStart.add(Duration(days: index))
                        : DateTime(
                            month.year,
                            month.month,
                            index - firstOffset + 1,
                          );
                    if (mode == 0 &&
                        (index < firstOffset || day.month != month.month)) {
                      return const SizedBox();
                    }
                    final matches = events.where((e) => onDay(e, day)).toList();
                    final active =
                        selected != null && DateUtils.isSameDay(day, selected);
                    return InkWell(
                      onTap: () => setState(() => selected = day),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: active ? C.violet : C.raised.withOpacity(.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                            if (matches.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Container(
                                width: 22,
                                height: 3,
                                color:
                                    matches.any(
                                      (e) => e.text('status') == 'live',
                                    )
                                    ? C.green
                                    : C.pink,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${matches.length}',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 7,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        if (inMonth.isEmpty && mode != 1)
          EmptyState(
            title: 'Nenhum evento encontrado',
            description: 'Não há eventos cadastrados para este período.',
            action: 'Criar primeiro evento',
            onAction: () => createEventDialog(context, widget.store),
            brand: true,
          ),
        if (mode == 2)
          ...inMonth.map((e) => calendarCard(context, e))
        else if (selected != null) ...[
          if (selectedEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Nenhum evento neste dia.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ...selectedEvents.map((e) => calendarCard(context, e)),
        ],
      ],
    );
  }

  Widget calendarCard(BuildContext context, CrowlyRow event) {
    final pct = event.number('capacity') == 0
        ? 0.0
        : event.number('people') / event.number('capacity');
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Panel(
        border: C.violet,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.text('title'),
                    style: const TextStyle(color: Colors.white, 
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Pill(
                  event.text('status') == 'live'
                      ? '• AO VIVO'
                      : statusLabel(event.text('status')),
                  color: C.pink,
                ),
              ],
            ),
            const SizedBox(height: 12),
            meta(Icons.calendar_today_outlined, dateLabel(event)),
            meta(Icons.location_on_outlined, event.text('location')),
            meta(
              Icons.groups_outlined,
              'Capacidade: ${count(event.integer('capacity'))} pessoas',
            ),
            KeyValue(
              'Ocupação atual',
              '${(pct * 100).round()}%',
              color: C.pink,
            ),
            Progress(pct, color: C.pink),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => openPage(
                    context,
                    widget.store,
                    1,
                    () => EventDetail(
                      store: widget.store,
                      eventId: event.text('id'),
                    ),
                  ),
                  child: const Text('Ver detalhes'),
                ),
                if (event.text('status') == 'live')
                  FilledButton(
                    onPressed: () => openPage(
                      context,
                      widget.store,
                      0,
                      () => MapPage(store: widget.store, event: event),
                      map: true,
                    ),
                    child: const Text('Acessar monitoramento'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> createEventDialog(BuildContext context, CrowlyStore store) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => CreateEventForm(store: store),
    );

class CreateEventForm extends StatefulWidget {
  const CreateEventForm({super.key, required this.store});
  final CrowlyStore store;
  @override
  State<CreateEventForm> createState() => _CreateEventFormState();
}

class _CreateEventFormState extends State<CreateEventForm> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(),
      location = TextEditingController(),
      capacity = TextEditingController();
  DateTime start = DateTime.now().add(const Duration(days: 1)),
      end = DateTime.now().add(const Duration(days: 1, hours: 8));
  bool busy = false;
  String? error;
  @override
  void dispose() {
    title.dispose();
    location.dispose();
    capacity.dispose();
    super.dispose();
  }

  Future<void> pick(bool isStart) async {
    final initial = isStart ? start : end;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      final value = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (isStart) {
        start = value;
        if (!end.isAfter(start)) end = start.add(const Duration(hours: 8));
      } else {
        end = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      8,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Novo evento', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            TextFormField(
              controller: title,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Nome do evento'),
              validator: (s) =>
                  s == null || s.trim().isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: location,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Local'),
              validator: (s) =>
                  s == null || s.trim().isEmpty ? 'Informe o local' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: capacity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacidade máxima'),
              validator: (s) => (int.tryParse(s ?? '') ?? 0) <= 0
                  ? 'Informe uma capacidade maior que zero'
                  : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: busy ? null : () => pick(true),
              child: Text(
                'Início: ${DateFormat('dd/MM/yyyy HH:mm').format(start)}',
              ),
            ),
            OutlinedButton(
              onPressed: busy ? null : () => pick(false),
              child: Text('Fim: ${DateFormat('dd/MM/yyyy HH:mm').format(end)}'),
            ),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        if (!end.isAfter(start)) {
                          setState(
                            () => error =
                                'O término precisa ser posterior ao início.',
                          );
                          return;
                        }
                        setState(() => busy = true);
                        try {
                          await widget.store.createEvent(
                            title: title.text.trim(),
                            location: location.text.trim(),
                            start: start,
                            end: end,
                            capacity: int.parse(capacity.text),
                          );
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (mounted) {
                            setState(
                              () =>
                                  error = 'Não foi possível criar o evento: $e',
                            );
                          }
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      },
                child: Text(busy ? 'Criando...' : 'Criar evento'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
