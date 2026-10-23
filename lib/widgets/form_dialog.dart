import 'package:flutter/material.dart';

/// A bounded, scrollable form without AlertDialog's intrinsic layout pass.
/// Keyboard animation changes the available height repeatedly; laying out a
/// large dropdown form twice per frame makes that animation unnecessarily costly.
class FormDialog extends StatelessWidget {
  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final Color? backgroundColor;
  final ShapeBorder? shape;
  const FormDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.backgroundColor,
    this.shape,
  });

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: backgroundColor,
    shape: shape,
    child: SizedBox(
      width: 420,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              namesRoute: true,
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.headlineSmall!,
                child: title,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(child: SingleChildScrollView(child: content)),
            const SizedBox(height: 24),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              overflowSpacing: 8,
              children: actions,
            ),
          ],
        ),
      ),
    ),
  );
}
