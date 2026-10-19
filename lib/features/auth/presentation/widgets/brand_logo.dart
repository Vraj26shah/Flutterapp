import 'package:flutter/material.dart';
import 'package:shopsphere/core/theme/app_theme.dart';

/// The ShopSphere mark: a rounded tile with a shopping-bag glyph.
class BrandLogo extends StatelessWidget {
  const BrandLogo({this.size = 56, this.onDark = false, super.key});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ShopSphere logo',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: onDark
                ? [Colors.white, AppColors.accent]
                : [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(
          Icons.shopping_bag_rounded,
          size: size * 0.55,
          color: onDark ? AppColors.primary : Colors.white,
        ),
      ),
    );
  }
}
