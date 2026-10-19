import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/theme/app_theme.dart';

/// Screen configurations from the brief: phones, tablets, both orientations,
/// and system font scaled to 1.3×.
const phonePortrait = Size(360, 740);
const phoneLandscape = Size(740, 360);
const tabletPortrait = Size(800, 1280);
const tabletLandscape = Size(1280, 800);

const allSizes = {
  'phone portrait': phonePortrait,
  'phone landscape': phoneLandscape,
  'tablet portrait': tabletPortrait,
  'tablet landscape': tabletLandscape,
};

/// Pumps [child] inside a themed MaterialApp at [size] / [textScale].
Future<void> pumpAt(
  WidgetTester tester,
  Widget child, {
  Size size = phonePortrait,
  double textScale = 1,
  bool scaffold = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: scaffold ? Scaffold(body: child) : child,
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
}
