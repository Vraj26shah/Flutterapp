import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsphere/core/theme/theme_cubit.dart';
import 'package:shopsphere/core/utils/breakpoints.dart';
import 'package:shopsphere/core/utils/debouncer.dart';
import 'package:shopsphere/core/utils/formatters.dart';

void main() {
  test('Debouncer only fires the last call after 400 ms', () {
    fakeAsync((async) {
      final debouncer = Debouncer();
      final calls = <String>[];

      debouncer.run(() => calls.add('p'));
      async.elapse(const Duration(milliseconds: 200));
      debouncer.run(() => calls.add('ph'));
      async.elapse(const Duration(milliseconds: 399));
      expect(calls, isEmpty);

      async.elapse(const Duration(milliseconds: 1));
      expect(calls, ['ph']);
    });
  });

  test('window size classes and grid columns follow the brief', () {
    expect(WindowSize.of(412), WindowSize.compact);
    expect(WindowSize.of(800), WindowSize.medium);
    expect(WindowSize.of(1024), WindowSize.medium);
    expect(WindowSize.of(1280), WindowSize.expanded);
    expect(gridColumnsFor(400), 2);
    expect(gridColumnsFor(720), 3);
    expect(gridColumnsFor(900), 4);
  });

  test('formatters', () {
    expect(formatPrice(12.5), r'$12.50');
    expect(formatPrice(30999.99), r'$30,999.99');
    expect(formatDate(DateTime(2026, 4, 30)), '30 Apr 2026');
  });

  test('ThemeCubit persists the chosen mode', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final cubit = ThemeCubit(prefs);
    expect(cubit.state, ThemeMode.system);
    await cubit.setMode(ThemeMode.dark);

    expect(ThemeCubit(prefs).state, ThemeMode.dark);
  });
}
