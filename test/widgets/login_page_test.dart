import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/di/injection.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/auth/domain/usecases/auth_usecases.dart';
import 'package:shopsphere/features/auth/presentation/bloc/login_cubit.dart';
import 'package:shopsphere/features/auth/presentation/pages/login_page.dart';

import '../helpers/mocks.dart';

void main() {
  late MockLoginUseCase login;

  setUpAll(
    () => registerFallbackValue(const LoginParams(username: '', password: '')),
  );

  setUp(() {
    login = MockLoginUseCase();
    sl.registerFactory(() => LoginCubit(login));
  });

  tearDown(sl.reset);

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(theme: AppTheme.light(), home: const LoginPage()),
  );

  testWidgets('shows inline validation errors for empty fields', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Please enter your username'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
    verifyNever(() => login(any()));
  });

  testWidgets('shows the API message for invalid credentials', (tester) async {
    when(() => login(any()))
        .thenAnswer((_) async => const Err(InvalidCredentialsFailure()));
    await pump(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'emilys');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid username or password'), findsOneWidget);
  });

  testWidgets('password visibility toggle', (tester) async {
    await pump(tester);

    EditableText password() =>
        tester.widget<EditableText>(find.byType(EditableText).at(1));
    expect(password().obscureText, isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();

    expect(password().obscureText, isFalse);
  });

  testWidgets('has no overflow at 1.3× text scale on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 640),
          textScaler: TextScaler.linear(1.3),
        ),
        child: MaterialApp(theme: AppTheme.light(), home: const LoginPage()),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
