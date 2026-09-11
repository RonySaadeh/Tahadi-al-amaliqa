import 'package:flutter/material.dart';

import '../theme/app_breakpoints.dart';

/// Caps [child] to a legible reading width and centers it once the viewport
/// is wider than a phone — a no-op on any screen narrower than [maxWidth],
/// since a `ConstrainedBox` only ever shrinks, never stretches, its child.
///
/// Wrap list/form/stat content with this; leave full-bleed elements (arena
/// headers, duel backgrounds) unwrapped so they keep running edge-to-edge.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = AppBreakpoints.contentMaxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}
