import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'state/progress_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(store: ProgressStore(prefs: prefs)));
}

/// By default Flutter only lets touch drag scroll views, so the swipe feed
/// would not work with a mouse or trackpad (web and desktop).
class _DragEverywhereScrollBehavior extends MaterialScrollBehavior {
  const _DragEverywhereScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.store});

  /// Injected by tests; defaults to an in-memory store.
  final ProgressStore? store;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ProgressStore _store = widget.store ?? ProgressStore();

  @override
  void dispose() {
    if (widget.store == null) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProgressScope(
      store: _store,
      child: MaterialApp(
        title: '아는척',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        scrollBehavior: const _DragEverywhereScrollBehavior(),
        home: const HomeScreen(),
      ),
    );
  }
}
