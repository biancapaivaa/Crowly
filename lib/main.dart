import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'data/store.dart';
import 'ui/auth.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final name in ['Roboto', 'RobotoCondensed']) {
      final license = await rootBundle.loadString(
        'assets/fonts/${name}_LICENSE.txt',
      );
      yield LicenseEntryWithLineBreaks([name], license);
    }
  });
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  const demo = bool.fromEnvironment('DEMO_MODE');
  SupabaseClient? client;
  String? error;
  if (!demo && url.isNotEmpty && key.isNotEmpty) {
    try {
      await Supabase.initialize(url: url, anonKey: key);
      client = Supabase.instance.client;
    } catch (_) {
      error =
          'Não foi possível iniciar o Supabase. Confira a URL e a chave pública.';
    }
  }
  runApp(CrowlyApp(client: client, startDemo: demo, configurationError: error));
}

class CrowlyApp extends StatefulWidget {
  const CrowlyApp({
    super.key,
    this.client,
    this.startDemo = false,
    this.configurationError,
  });
  final SupabaseClient? client;
  final bool startDemo;
  final String? configurationError;
  @override
  State<CrowlyApp> createState() => _CrowlyAppState();
}

class _CrowlyAppState extends State<CrowlyApp> {
  final navigator = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? subscription;
  CrowlyStore? store;
  bool demo = false;
  bool recovering = false;
  @override
  void initState() {
    super.initState();
    demo = widget.startDemo;
    if (demo || widget.client?.auth.currentSession != null) _newStore();
    subscription = widget.client?.auth.onAuthStateChange.listen((state) {
      if (!mounted || demo) return;
      if (state.event == AuthChangeEvent.signedOut ||
          state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.passwordRecovery) {
        navigator.currentState?.popUntil((route) => route.isFirst);
      }
      setState(() {
        recovering =
            state.event == AuthChangeEvent.passwordRecovery ||
            (recovering && state.session != null);
        if (state.session == null) {
          store?.dispose();
          store = null;
          recovering = false;
        } else if (store == null) {
          _newStore();
        }
      });
    });
  }

  void _newStore() {
    store?.dispose();
    store = CrowlyStore(client: widget.client, demo: demo)..onLogout = _logout;
    unawaited(store!.connect());
  }

  void _demo() {
    setState(() {
      demo = true;
      recovering = false;
      _newStore();
    });
  }

  Future<void> _logout() async {
    navigator.currentState?.popUntil((route) => route.isFirst);
    if (!demo) await widget.client!.auth.signOut();
    if (mounted) {
      setState(() {
        demo = false;
        store?.dispose();
        store = null;
      });
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigator,
    title: 'CROWLY',
    debugShowCheckedModeBanner: false,
    theme: crowlyTheme(),
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: recovering
        ? PasswordRecovery(
            client: widget.client!,
            onDone: () => setState(() => recovering = false),
          )
        : store != null
        ? CrowlyShell(key: ObjectKey(store), store: store!, onLogout: _logout)
        : AuthScreen(
            client: widget.client,
            onDemo: _demo,
            configurationError: widget.configurationError,
          ),
  );
}
