import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elderly_companion/core/theme/app_dimens.dart';
import 'package:elderly_companion/core/theme/app_motion.dart';
import 'package:elderly_companion/core/widgets/app_card.dart';

/// A row-shaped placeholder (leading circle + two lines) for lists whose
/// first load takes long enough to be worth more than a spinner — a
/// same-shaped skeleton tells the user what's *about* to appear, which a
/// centred spinner doesn't.
///
/// The shimmer sweep is purely decorative, so it's the first thing to drop
/// under [AppMotion.reduced] — the skeleton shape alone still communicates
/// "loading" without it.
class SkeletonCard extends ConsumerStatefulWidget {
  const SkeletonCard({super.key});

  @override
  ConsumerState<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends ConsumerState<SkeletonCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  // AppMotion.reduced() reads MediaQuery, which can't be touched from
  // initState() — didChangeDependencies is the first safe point, guarded so
  // a later dependency change doesn't spin up a second controller.
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    if (!AppMotion.reduced(context, ref)) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = scheme.surface;

    Widget bar({required double width, required double height}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: base, borderRadius: AppRadius.smallAll),
      );
    }

    final content = AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: base, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(width: double.infinity, height: 16),
                const SizedBox(height: AppSpacing.sm),
                bar(width: 140, height: 12),
              ],
            ),
          ),
        ],
      ),
    );

    final controller = _controller;
    if (controller == null) return content;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Sweeps a soft highlight band left-to-right and loops — a wide
        // gradient with a narrow bright stop so it reads as a pass of light
        // rather than a flashing block.
        final t = controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 - t * 2, 0),
              end: Alignment(1 - t * 2, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: content,
    );
  }
}

/// A column of [count] [SkeletonCard]s standing in for a list mid-load.
class SkeletonList extends StatelessWidget {
  const SkeletonList({this.count = 4, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: AppSpacing.screen,
      itemCount: count,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => const SkeletonCard(),
    );
  }
}
