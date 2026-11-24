import 'package:flutter/material.dart';

/// Lightweight, fill-rate-friendly card surface for scrolling lists and dashboards.
/// Uses an opaque background and a crisp 1 px border with `Clip.none`, avoiding
/// expensive blurred `BoxShadow` convolutions and offscreen saveLayers.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final double? width;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      margin: margin,
      padding: padding,
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.10),
          width: borderWidth,
        ),
      ),
      child: child,
    );
  }
}
