import 'package:flutter/material.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/core/widgets/app_network_image.dart';

/// Swipeable image gallery with a page indicator.
class ImageCarousel extends StatefulWidget {
  const ImageCarousel({
    required this.images,
    this.heroTag,
    this.maxHeight = 360,
    super.key,
  });

  final List<String> images;

  /// Applied to the first image only, for the list → details animation.
  final String? heroTag;
  final double maxHeight;

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = widget.images.length;

    return ColoredBox(
      color: scheme.surfaceContainerLowest,
      child: SizedBox(
        height: widget.maxHeight,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: count,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) {
                Widget image = Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: AppNetworkImage(
                    url: widget.images[index],
                    fit: BoxFit.contain,
                    semanticLabel: 'Product image ${index + 1} of $count',
                  ),
                );
                if (index == 0 && widget.heroTag != null) {
                  image = Hero(tag: widget.heroTag!, child: image);
                }
                return image;
              },
            ),
            if (count > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: Spacing.md,
                child: Semantics(
                  label: 'Image ${_page + 1} of $count',
                  excludeSemantics: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < count; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _page ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? scheme.primary
                                : scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
