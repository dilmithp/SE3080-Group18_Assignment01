import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/theme/app_motion.dart';

/// Wraps one item in a list/grid so it fades and slides gently into place
/// on first appearance, staggered by [index] — the sequence [AppMotion]
/// specifies, not a one-off tween invented per screen.
///
/// Skips the animation entirely (renders [child] immediately) when
/// [AppMotion.reduced] says to — a reduced-motion or Simplified Mode user
/// should see the list appear instantly, not a slower version of the same
/// effect.
///
/// Runs once per mount: reordering the same list (a resort, a live update)
/// does not replay the entrance, since these wrap stable list items rather
/// than being keyed to content — only a fresh screen/first load triggers it.
class StaggeredEntrance extends ConsumerStatefulWidget {
  const StaggeredEntrance({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  @override
  ConsumerState<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends ConsumerState<StaggeredEntrance> {
  bool _visible = false;
  bool _skip = false;

  // Guards one-time setup: AppMotion.reduced() reads MediaQuery, which
  // asserts if touched from initState() (an inherited-widget lookup isn't
  // allowed until the widget is actually in the tree) — didChangeDependencies
  // is the first safe place, but it can also fire again later if MediaQuery
  // itself changes, so this flag keeps the stagger timer from restarting.
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    _skip = AppMotion.reduced(context, ref);
    if (_skip) {
      _visible = true;
      return;
    }
    Future.delayed(AppMotion.staggerDelayFor(widget.index), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_skip) return widget.child;
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: AppMotion.standard,
      curve: AppMotion.enter,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        duration: AppMotion.standard,
        curve: AppMotion.enter,
        child: widget.child,
      ),
    );
  }
}
