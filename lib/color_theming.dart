import 'package:flutter/material.dart';

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
