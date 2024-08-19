import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'platform_and_theming.dart';
import 'mobile_mindmeld_app.dart';
import 'desktop_mindmeld_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // right away try to detect if we're running a desktop build and do a different
  // interface that's more specialized for desktops
  if (isRunningOnDesktop()) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(600, 420),
      size: Size(1024, 800),
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    runApp(MaterialApp(
        title: 'Mindmeld',
        theme: ThemeData(),
        darkTheme: ThemeData.dark(),
        home: const DesktopMindmeldApp()));
  } else {
    runApp(MaterialApp(
        title: 'Mindmeld',
        theme: ThemeData(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.system,
        home: const MobileMindmeldApp()));
  }
}
