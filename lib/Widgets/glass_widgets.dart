import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final List<Color>? gradientColors;
  final double borderWidth;
  final Color? borderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15,
    this.opacity = 0.1,
    this.borderRadius = 24,
    this.gradientColors,
    this.borderWidth = 1.0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? (isDark 
                  ? Colors.white.withOpacity(0.12) 
                  : Colors.black.withOpacity(0.08)),
              width: borderWidth,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors ?? [
                (isDark ? Colors.white : Colors.black).withOpacity(opacity),
                (isDark ? Colors.white : Colors.black).withOpacity(opacity * 0.5),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class StaggeredAnimation extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const StaggeredAnimation({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(delay: delay * index, duration: 600.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCirc);
  }
}
