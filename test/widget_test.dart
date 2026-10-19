import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crowly/main.dart';

void main() {
  testWidgets('demo permite abrir seções e detalhe offline sem overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CrowlyApp(startDemo: true));
    await tester.pumpAndSettle();
    expect(find.text('Visão Geral'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Dispositivos').last);
    await tester.pumpAndSettle();
    expect(find.text('Contadores de pessoas'), findsOneWidget);
    await tester.tap(find.text('Entrada Principal'));
    await tester.pumpAndSettle();
    expect(find.text('Este dispositivo está offline'), findsOneWidget);
    await tester.tap(find.text('Reiniciar remotamente'));
    await tester.pumpAndSettle();
    expect(find.text('Na fila'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Eventos').last);
    await tester.pumpAndSettle();
    expect(find.text('Futuros'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('autenticação sem configuração oferece demo explicitamente', (
    tester,
  ) async {
    await tester.pumpWidget(const CrowlyApp());
    await tester.pumpAndSettle();
    expect(find.text('Bem-vindo de volta!'), findsOneWidget);
    await tester.ensureVisible(find.text('Explorar demonstração'));
    await tester.tap(find.text('Explorar demonstração'));
    await tester.pumpAndSettle();
    expect(find.text('Visão Geral'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
