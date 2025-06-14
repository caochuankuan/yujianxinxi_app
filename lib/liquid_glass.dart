import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidGlass extends StatelessWidget {
  final Widget? child;
  final double blur;
  final double opacity;
  final BorderRadius borderRadius;
  final Color tint;
  final bool isBlurEnabled;

  const LiquidGlass({
    super.key,
    this.child,
    this.blur = 40,
    this.opacity = 0.2,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.tint = Colors.white,
    this.isBlurEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: isBlurEnabled
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    colors: [
                      tint.withValues(alpha: opacity),
                      tint.withValues(alpha: opacity * 0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: child,
              ),
            )
          : Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: LinearGradient(
                  colors: [
                    tint.withValues(alpha: opacity + 0.5),
                    tint.withValues(alpha: opacity * 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 0.8,
                ),
              ),
              child: child,
            ),
    );
  }
}
