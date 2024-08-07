import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Color getMessageDecorationColor(BuildContext context, bool forAIMessage) {
  if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
    return (forAIMessage ? Colors.grey.shade800 : Colors.blue.shade800);
  } else {
    return (forAIMessage ? Colors.grey.shade200 : Colors.blue.shade200);
  }
}

Color getPrimaryDecorationColor(BuildContext context) {
  if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
    return Colors.blue.shade800;
  } else {
    return Colors.blue.shade200;
  }
}

Color getBackgroundDecorationColor(BuildContext context) {
  if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
    return Colors.grey.shade900;
  } else {
    return Colors.grey.shade200;
  }
}

bool isRunningOnDesktop() {
  return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
}

// This gets our documents directory which requires a little extra work on
// the desktop runners to add our application name to the stack in the path.
Future<String> getOurDocumentsDirectory() async {
  final directory = await getApplicationDocumentsDirectory();
  if (isRunningOnDesktop()) {
    return p.join(directory.path, 'Mindmeld');
  } else {
    return directory.path;
  }
}
