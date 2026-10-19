import 'package:flutter_test/flutter_test.dart';
import 'package:crowly/core/models.dart';
import 'package:crowly/data/store.dart';

void main() {
  test('ocupação trata capacidade zero e limita barra em cem por cento', () {
    expect(occupancy({'capacity': 0, 'people': 10}), 0);
    expect(occupancy({'capacity': 100, 'people': 250}), 100);
    expect(occupancy({'capacity': 200, 'people': 100}), 50);
  });
  test('encerramento gera um relatório e remove evento ativo', () async {
    final store = CrowlyStore(demo: true);
    final event = store.activeEvent!;
    expect(store.forEvent('reports', event.text('id')), isEmpty);
    await store.eventStatus(event, 'ended');
    expect(store.activeEvent, isNull);
    expect(store.forEvent('reports', event.text('id')), hasLength(1));
    await store.eventStatus(event, 'ended');
    expect(store.forEvent('reports', event.text('id')), hasLength(1));
    store.dispose();
  });
  test(
    'comando não altera falsamente o estado de dispositivo offline',
    () async {
      final store = CrowlyStore(demo: true);
      final d = store.rows('devices').first;
      await store.command(
        d.text('event_id'),
        'restart',
        deviceId: d.text('id'),
      );
      expect(d.text('status'), 'offline');
      expect(store.rows('commands').single.text('status'), 'queued');
      store.dispose();
    },
  );
  test(
    'criação mantém horário final e dados sem leituras fabricadas',
    () async {
      final store = CrowlyStore(demo: true);
      final start = DateTime(2026, 11, 30, 18), end = DateTime(2026, 12, 1, 2);
      await store.createEvent(
        title: 'Festival novo',
        location: 'Arena',
        start: start,
        end: end,
        capacity: 500,
      );
      final event = store.rows('events').last;
      expect(event.date('starts_at'), start);
      expect(event.date('ends_at'), end);
      expect(event.text('status'), 'scheduled');
      expect(store.forEvent('samples', event.text('id')), isEmpty);
      store.dispose();
    },
  );
}
