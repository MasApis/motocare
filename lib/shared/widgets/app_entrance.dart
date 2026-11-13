import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Membungkus widget agar muncul dengan efek memudar sambil naik sedikit.
/// [index] dipakai untuk membuat kartu muncul bergantian (stagger).
/// Jeda dibuat lewat Interval di satu AnimationController (tanpa Timer).
class AppEntrance extends StatefulWidget {
  const AppEntrance({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<AppEntrance> createState() => _AppEntranceState();
}

class _AppEntranceState extends State<AppEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final delay = AppMotion.stagger * widget.index;
    final total = delay + AppMotion.entrance;
    _controller = AnimationController(vsync: this, duration: total);
    final start = delay.inMicroseconds / total.inMicroseconds;
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: AppMotion.curve),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.isReduced(context)) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final t = _animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * AppMotion.entranceOffset),
            child: child,
          ),
        );
      },
    );
  }
}
