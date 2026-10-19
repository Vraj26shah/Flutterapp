/// Material 3 window-size classes used for responsive layouts.
enum WindowSize {
  /// < 600 dp — phones: 2-column grid + bottom navigation bar.
  compact,

  /// 600–1024 dp — small tablets / phone landscape: 3–4 columns + rail.
  medium,

  /// > 1024 dp — tablet landscape: master–detail.
  expanded;

  static WindowSize of(double width) {
    if (width < 600) return WindowSize.compact;
    if (width <= 1024) return WindowSize.medium;
    return WindowSize.expanded;
  }

  bool get isCompact => this == WindowSize.compact;
  bool get isExpanded => this == WindowSize.expanded;
}

/// Number of grid columns for a given available content width.
int gridColumnsFor(double width) {
  if (width < 600) return 2;
  if (width < 840) return 3;
  return 4;
}
