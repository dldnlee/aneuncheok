import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/root_shell.dart';
import 'social/social_repository.dart';
import 'social/social_store.dart';
import 'state/progress_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final progress = ProgressStore(prefs: prefs);
  runApp(
    MyApp(
      store: progress,
      social: SocialStore(
        progress: progress,
        // Simulated players. To go live, implement SocialRepository against a
        // real backend and pass it here instead.
        repository: DemoSocialRepository(prefs: prefs),
        prefs: prefs,
      ),
    ),
  );
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
  const MyApp({super.key, this.store, this.social});

  /// Injected by tests; defaults to an in-memory store.
  final ProgressStore? store;

  /// Injected by tests; defaults to a demo social store.
  final SocialStore? social;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ProgressStore _progress = widget.store ?? ProgressStore();
  late final SocialStore _social =
      widget.social ??
      SocialStore(progress: _progress, repository: DemoSocialRepository());

  @override
  void initState() {
    super.initState();
    // Load friends and rankings once at startup so the home screen can show
    // where the player stands.
    _social.refresh();
  }

  @override
  void dispose() {
    if (widget.social == null) _social.dispose();
    if (widget.store == null) _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProgressScope(
      store: _progress,
      child: SocialScope(
        store: _social,
        child: MaterialApp(
          title: '아는척',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          scrollBehavior: const _DragEverywhereScrollBehavior(),
          home: const RootShell(),
        ),
      ),
    );
  }
}
