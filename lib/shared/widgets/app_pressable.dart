import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Memberi efek mengecil sedikit saat widget ditekan (desain: active:scale-[0.98]).
/// Tidak menangkap ketukan, jadi onTap/onPressed milik child tetap berjalan.
class AppPressable extends StatefulWidget {
  const AppPressable({super.key, required this.child});

  final Widget child;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReduced(context);
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed && !reduced ? AppMotion.pressedScale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        child: widget.child,
      ),
    );
  }
}
