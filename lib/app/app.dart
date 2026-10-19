import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopsphere/app/app_shell.dart';
import 'package:shopsphere/core/di/injection.dart';
import 'package:shopsphere/core/network/connectivity_cubit.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/core/theme/theme_cubit.dart';
import 'package:shopsphere/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shopsphere/features/auth/presentation/pages/login_page.dart';
import 'package:shopsphere/features/auth/presentation/pages/splash_page.dart';
import 'package:shopsphere/features/cart/presentation/bloc/cart_bloc.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

class ShopSphereApp extends StatelessWidget {
  const ShopSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider(create: (_) => sl<CartBloc>()..add(const CartStarted())),
        BlocProvider(create: (_) => sl<ThemeCubit>()),
        BlocProvider(create: (_) => sl<ConnectivityCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) => MaterialApp(
          title: 'ShopSphere',
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

/// Routes between Splash, Login and the signed-in shell based on AuthBloc.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      // Only an active session ending (logout / expiry) wipes local data —
      // not the cold-start check, so the cart survives an app restart.
      listenWhen: (p, c) =>
          p.status == AuthStatus.authenticated &&
          c.status == AuthStatus.unauthenticated,
      listener: (context, state) {
        // Close any pushed routes (details, dialogs) and wipe the cart.
        _navigatorKey.currentState?.popUntil((r) => r.isFirst);
        context.read<CartBloc>().add(const CartCleared());
      },
      builder: (context, state) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: switch (state.status) {
          AuthStatus.unknown => const SplashPage(key: ValueKey('splash')),
          AuthStatus.unauthenticated => LoginPage(
            key: const ValueKey('login'),
            message: state.message,
          ),
          AuthStatus.authenticated => const AppShell(key: ValueKey('shell')),
        },
      ),
    );
  }
}
