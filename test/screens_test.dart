import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crowly/core/models.dart';
import 'package:crowly/core/theme.dart';
import 'package:crowly/data/store.dart';
import 'package:crowly/ui/alerts.dart';
import 'package:crowly/ui/dashboard.dart';
import 'package:crowly/ui/devices.dart';
import 'package:crowly/ui/events.dart';
import 'package:crowly/ui/reports.dart';
import 'package:crowly/ui/shell.dart';

void main() {
  testWidgets('telas principais e estados vazios cabem em 320 e 390 px', (
    tester,
  ) async {
    final store = CrowlyStore(demo: true);
    addTearDown(store.dispose);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final live = store.activeEvent!;
    final past = store
        .rows('events')
        .firstWhere((e) => e.text('status') == 'ended');
    final future = store
        .rows('events')
        .firstWhere((e) => e.text('status') == 'scheduled');
    final screens = <Widget Function()>[
      () => Dashboard(store: store, onEvents: () {}, onAlerts: () {}),
      () => MapPage(store: store, event: live),
      () => MapPage(
        store: store,
        event: live,
        initialArea: store.forEvent('areas', live.text('id')).first.text('id'),
      ),
      () => EventsPage(store: store),
      () => CalendarPage(store: store),
      () => EventDetail(store: store, eventId: future.text('id')),
      () => EventReport(store: store, event: past),
      () => DevicesPage(store: store, onEvents: () {}),
      () => DeviceDetail(
        store: store,
        deviceId: store.rows('devices').first.text('id'),
      ),
      () => ReportsPage(store: store, onEvents: () {}),
      () => AlertsPage(store: store),
    ];
    for (final width in [320.0, 390.0]) {
      tester.view.physicalSize = Size(width, 844);
      for (var i = 0; i < screens.length; i++) {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey('$width-$i'),
            theme: crowlyTheme(),
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [Locale('pt', 'BR')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: AppFrame(
              store: store,
              tab: 0,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: screens[i](),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Tela $i em $width px');
      }
    }
    for (final event in store.rows('events')) {
      event['status'] = 'scheduled';
    }
    store.data['reports'] = [];
    for (final screen in <Widget>[
      Dashboard(store: store, onEvents: () {}, onAlerts: () {}),
      DevicesPage(store: store, onEvents: () {}),
      ReportsPage(store: store, onEvents: () {}),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: crowlyTheme(),
          home: Scaffold(body: SingleChildScrollView(child: screen)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
