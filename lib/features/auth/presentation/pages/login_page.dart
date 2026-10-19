import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopsphere/core/di/injection.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shopsphere/features/auth/presentation/bloc/login_cubit.dart';
import 'package:shopsphere/features/auth/presentation/widgets/brand_logo.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({this.message, super.key});

  /// Optional notice (e.g. "session expired") from AuthBloc.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginCubit>(),
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 840;
            final form = _LoginForm(message: message);
            if (!wide) return SafeArea(child: form);
            return Row(
              children: [
                const Expanded(child: _HeroPanel()),
                Expanded(child: SafeArea(child: form)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl * 1.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandLogo(size: 72, onDark: true),
            const SizedBox(height: Spacing.xl),
            Text(
              'Everything you love,\nin one sphere.',
              style: text.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'Browse 190+ products across 24 categories.',
              style: text.titleMedium?.copyWith(color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({this.message});

  final String? message;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<LoginCubit>().submit(
      username: _username.text,
      password: _password.text,
    );
  }

  void _fillDemo() {
    setState(() {
      _username.text = 'emilys';
      _password.text = 'emilyspass';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state.status == LoginStatus.success) {
          context.read<AuthBloc>().add(const AuthLoggedIn());
        }
      },
      builder: (context, state) {
        final failure = state.status == LoginStatus.failure
            ? state.failure
            : null;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: BrandLogo(),
                      ),
                      const SizedBox(height: Spacing.xl),
                      Text(
                        'Welcome back',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        'Sign in to continue shopping',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacing.xl),
                      if (widget.message != null && failure == null)
                        _Notice(
                          icon: Icons.info_outline_rounded,
                          text: widget.message!,
                          color: scheme.primary,
                        ),
                      if (failure != null)
                        _Notice(
                          icon: failure is InvalidCredentialsFailure
                              ? Icons.error_outline_rounded
                              : Icons.wifi_off_rounded,
                          text: failure.message,
                          color: scheme.error,
                        ),
                      TextFormField(
                        controller: _username,
                        enabled: !state.isSubmitting,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: LoginValidators.username,
                        onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                      const SizedBox(height: Spacing.lg),
                      TextFormField(
                        controller: _password,
                        focusNode: _passwordFocus,
                        enabled: !state.isSubmitting,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? 'Show password'
                                : 'Hide password',
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: LoginValidators.password,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: Spacing.xl),
                      FilledButton(
                        onPressed: state.isSubmitting ? null : _submit,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: state.isSubmitting
                              ? SizedBox.square(
                                  key: const ValueKey('loading'),
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: scheme.onPrimary,
                                    semanticsLabel: 'Signing in',
                                  ),
                                )
                              : const Text('Sign in', key: ValueKey('label')),
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),
                      Center(
                        child: TextButton.icon(
                          onPressed: state.isSubmitting ? null : _fillDemo,
                          icon: const Icon(Icons.bolt_rounded),
                          label: const Text('Use demo account (emilys)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.lg),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(text, style: TextStyle(color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
