import 'package:flutter/material.dart';

/// Builds and lays out only sections near the viewport, rather than one tall
/// Column. Stateful sections can request automatic keep-alive when needed.
class LazySectionList extends StatelessWidget {
  final List<WidgetBuilder> sections;
  final EdgeInsetsGeometry padding;
  const LazySectionList({
    super.key,
    required this.sections,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: padding,
    physics: const AlwaysScrollableScrollPhysics(),
    itemCount: sections.length,
    itemBuilder: (context, index) => sections[index](context),
  );
}
