import 'package:flutter/material.dart';

/// Builds and lays out only sections near the viewport, rather than one tall
/// Column. Stateful sections can request automatic keep-alive when needed.
class LazySectionList extends StatelessWidget {
  final List<WidgetBuilder> sections;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;
  const LazySectionList({
    super.key,
    required this.sections,
    this.padding = EdgeInsets.zero,
    this.controller,
  });

  @override
  Widget build(BuildContext context) => ListView.builder(
    controller: controller,
    padding: padding,
    physics: const AlwaysScrollableScrollPhysics(),
    itemCount: sections.length,
    itemBuilder: (context, index) => sections[index](context),
  );
}

/// The sliver variant keeps headers and charts lazy inside a larger ledger list.
class LazySectionSliver extends StatelessWidget {
  final List<WidgetBuilder> sections;
  const LazySectionSliver({super.key, required this.sections});
  @override
  Widget build(BuildContext context) => SliverList.builder(
    itemCount: sections.length,
    itemBuilder: (context, index) => sections[index](context),
  );
}
