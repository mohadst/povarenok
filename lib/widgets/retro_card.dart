import 'package:flutter/material.dart';
import '../theme/retro_colors.dart';

class RetroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const RetroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: RetroColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RetroColors.cocoa.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}