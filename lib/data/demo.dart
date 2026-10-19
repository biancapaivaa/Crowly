import '../core/models.dart';

Map<String, List<CrowlyRow>> demoData() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day, 18);
  CrowlyRow event(
    String id,
    String title,
    String status,
    DateTime date, {
    int people = 0,
    int entries = 0,
    int exits = 0,
  }) => {
    'id': id,
    'title': title,
    'location': 'Parque Olímpico - Rio de Janeiro',
    'status': status,
    'starts_at': date.toIso8601String(),
    'ends_at': date.add(const Duration(hours: 8)).toIso8601String(),
    'capacity': 18000,
    'people': people,
    'entries': entries,
    'exits': exits,
    'image_url': null,
  };
  final events = [
    event(
      'live',
      'Rock in Rio 2026',
      'live',
      start,
      people: 12400,
      entries: 14230,
      exits: 1830,
    ),
    event(
      'future',
      'Lollapalooza 2026',
      'scheduled',
      start.add(const Duration(days: 7)),
    ),
    event(
      'past',
      'The Town Club',
      'ended',
      start.subtract(const Duration(days: 30)),
      people: 0,
      entries: 98200,
      exits: 96800,
    ),
    event(
      'past2',
      'Taubaté Expo Agro',
      'ended',
      start.subtract(const Duration(days: 45)),
      entries: 19400,
      exits: 19400,
    ),
  ];
  final areas = <CrowlyRow>[];
  final devices = <CrowlyRow>[];
  final alerts = <CrowlyRow>[];
  final samples = <CrowlyRow>[];
  final reports = <CrowlyRow>[];
  for (final e in events) {
    final id = e.text('id');
    const names = [
      'Palco Principal',
      'Área VIP',
      'Entrada',
      'Alimentação',
      'Bar',
      'Banheiros',
      'Saída',
    ];
    const capacities = [7300, 2200, 1300, 2300, 1500, 1700, 1700];
    const people = [6643, 1826, 200, 1794, 1125, 280, 120];
    for (var i = 0; i < names.length; i++) {
      areas.add({
        'id': '$id-area-$i',
        'event_id': id,
        'name': names[i],
        'capacity': capacities[i],
        'people': people[i],
        'sensor_count': i == 0 ? 8 : 3,
        'position': i,
      });
    }
    const groups = ['counter', 'queue', 'button', 'environment'];
    const deviceNames = [
      ['Entrada Principal', 'Palco Sunset', 'VIP Lounge', 'Bar Central'],
      ['Bar 2', 'Bilheteria', 'Banheiro'],
      ['Área B', 'Palco'],
      ['Área VIP', 'Palco'],
    ];
    const values = [
      ['1.2k', '180', '45', '64'],
      ['45', '12', '8'],
      ['Suporte', 'Emergência'],
      ['29°C', '26°C'],
    ];
    for (var g = 0; g < groups.length; g++) {
      for (var j = 0; j < deviceNames[g].length; j++) {
        devices.add({
          'id': '$id-device-$g-$j',
          'event_id': id,
          'name': deviceNames[g][j],
          'kind': groups[g],
          'status': g == 0 && j == 0 ? 'offline' : 'online',
          'battery': g == 0 && j == 0 ? 45 : 90,
          'reading': values[g][j],
          'last_seen': now
              .subtract(Duration(minutes: j == 0 ? 15 : 1))
              .toIso8601String(),
        });
      }
    }
    const titles = [
      'Superlotação - Palco Sunset',
      'Fila acima do limite - Bar 2',
      'Alerta de suporte - Área B',
      'Temperatura elevada - VIP Lounge',
      'Sensor offline - Entrada 3',
      'Bateria fraca - Sensor 12',
    ];
    const descriptions = [
      '92% Ocupação',
      '45 pessoas',
      'Equipe acionada',
      '29°C',
      'Sem sinal',
      'Bateria 10%',
    ];
    const severities = ['emergency', 'high', 'medium', 'high', 'medium', 'low'];
    const states = [
      'open',
      'reviewing',
      'resolved',
      'open',
      'reviewing',
      'resolved',
    ];
    for (var i = 0; i < titles.length; i++) {
      alerts.add({
        'id': '$id-alert-$i',
        'event_id': id,
        'title': titles[i],
        'description': descriptions[i],
        'severity': severities[i],
        'status': states[i],
        'created_at': now
            .subtract(Duration(minutes: [1, 12, 20, 35, 60, 120][i]))
            .toIso8601String(),
      });
    }
    for (var i = 0; i < 7; i++) {
      samples.add({
        'id': '$id-sample-$i',
        'event_id': id,
        'recorded_at': DateTime(
          start.year,
          start.month,
          start.day,
          10 + i * 2,
        ).toIso8601String(),
        'entries': [120, 420, 320, 750, 640, 980, 880][i],
        'exits': [80, 200, 380, 500, 620, 750, 920][i],
        'occupancy': [25, 40, 35, 63, 54, 87, 72][i],
      });
    }
    if (e.text('status') == 'ended') {
      reports.add({
        'id': '$id-report',
        'event_id': id,
        'total_entries': e.integer('entries'),
        'total_exits': e.integer('exits'),
        'peak_occupancy': 87,
        'average_occupancy': 62,
        'temperature': 28,
        'humidity': 65,
        'created_at': now.toIso8601String(),
      });
    }
  }
  return {
    'events': events,
    'areas': areas,
    'devices': devices,
    'alerts': alerts,
    'samples': samples,
    'reports': reports,
    'commands': [],
  };
}
