import 'package:flutter/widgets.dart';

/// Retains page state while allowing microphone/playback to stop when hidden.
class PageActivity extends InheritedWidget {
  const PageActivity({super.key, required this.active, required super.child});

  final bool active;

  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PageActivity>()?.active ??
      true;

  @override
  bool updateShouldNotify(PageActivity oldWidget) => active != oldWidget.active;
}
