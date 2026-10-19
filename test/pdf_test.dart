import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:crowly/core/models.dart';
import 'package:crowly/data/store.dart';
import 'package:crowly/ui/reports.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('relatório gera um PDF real com os dados agregados', () async {
    await initializeDateFormatting('pt_BR');
    final store = CrowlyStore(demo: true);
    final event = store
        .rows('events')
        .firstWhere((e) => e.text('status') == 'ended');
    final bytes = await reportBytes(store, event);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
    store.dispose();
  });
}
