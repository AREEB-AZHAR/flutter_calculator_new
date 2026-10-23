import 'package:flutter/widgets.dart';

/// Main tabs have no inline editors. Their editors live on separate Navigator
/// routes, which still receive real keyboard insets. Keep cached pages at their
/// full size while the keyboard animates over a dialog or bottom sheet.
class KeyboardStablePage extends StatelessWidget {
  // Child identity is preserved across inset-only updates.
  final Widget child;
  const KeyboardStablePage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        viewInsets: media.viewInsets.copyWith(bottom: 0),
        padding: media.padding.copyWith(bottom: media.viewPadding.bottom),
      ),
      child: child,
    );
  }
}
