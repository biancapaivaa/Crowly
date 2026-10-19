import 'package:intl/intl.dart';

typedef CrowlyRow = Map<String, dynamic>;

extension RowValues on CrowlyRow {
  String text(String key, [String fallback = '']) =>
      this[key]?.toString() ?? fallback;
  double number(String key) => (this[key] as num?)?.toDouble() ?? 0;
  int integer(String key) => number(key).toInt();
  DateTime date(String key) => DateTime.parse(text(key)).toLocal();
}

String count(num n) => NumberFormat.decimalPattern('pt_BR').format(n);
String compact(num n) =>
    n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : count(n);
String dateLabel(CrowlyRow event) =>
    DateFormat('dd/MM/yyyy • HH:mm', 'pt_BR').format(event.date('starts_at'));
double occupancy(CrowlyRow area) => area.number('capacity') <= 0
    ? 0
    : (area.number('people') / area.number('capacity') * 100)
          .clamp(0, 100)
          .toDouble();
String severityLabel(String value) =>
    const {
      'emergency': 'Emergência',
      'high': 'Alta',
      'medium': 'Média',
      'low': 'Baixa',
    }[value] ??
    value;
String statusLabel(String value) =>
    const {
      'open': 'Aberto',
      'reviewing': 'Em análise',
      'resolved': 'Resolvido',
      'scheduled': 'Agendado',
      'live': 'Em andamento',
      'ended': 'Encerrado',
      'cancelled': 'Cancelado',
    }[value] ??
    value;
String relativeTime(String? value) {
  final date = DateTime.tryParse(value ?? '');
  if (date == null) return 'Sem comunicação';
  final delta = DateTime.now().difference(date);
  if (delta.inMinutes < 1) return 'agora';
  if (delta.inMinutes < 60) return 'há ${delta.inMinutes} min';
  if (delta.inHours < 24) return 'há ${delta.inHours}h';
  return 'há ${delta.inDays} dias';
}
