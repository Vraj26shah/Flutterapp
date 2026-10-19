import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/widgets/state_views.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('ErrorView shows a friendly message and a working Retry', (
    tester,
  ) async {
    var retried = 0;
    await tester.pumpWidget(
      wrap(ErrorView(failure: const ServerFailure(), onRetry: () => retried++)),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, 1);
  });

  testWidgets('ErrorView hides Retry for non-retryable failures', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(ErrorView(failure: const NotFoundFailure(), onRetry: () {})),
    );

    expect(find.text('Not found'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });
}
