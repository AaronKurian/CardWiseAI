import 'dart:ui';

import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, this.child, this.visible = true});

  final Widget? child;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final overlay = Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ColoredBox(
            color: Colors.black.withValues(alpha: .48),
            child: const Center(
              child: SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (child == null) {
      return Stack(children: [overlay]);
    }

    return Stack(children: [child!, if (visible) overlay]);
  }
}
