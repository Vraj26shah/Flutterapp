import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/core/theme/theme_cubit.dart';
import 'package:shopsphere/core/widgets/shimmer_box.dart';
import 'package:shopsphere/core/widgets/state_views.dart';
import 'package:shopsphere/features/auth/domain/entities/user.dart';
import 'package:shopsphere/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shopsphere/features/diagnostics/presentation/diagnostics_page.dart';
import 'package:shopsphere/features/profile/presentation/bloc/profile_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final auth = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your session and cart on this device will be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) auth.add(const AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        // 401 that could not be recovered by the refresh interceptor.
        if (state is ProfileFailure && state.failure is UnauthorizedFailure) {
          context.read<AuthBloc>().add(
            AuthSessionExpired(state.failure.message),
          );
        }
      },
      builder: (context, state) {
        final body = switch (state) {
          ProfileLoading() => const _ProfileSkeleton(),
          ProfileFailure(:final failure) => ErrorView(
            failure: failure,
            onRetry: context.read<ProfileCubit>().load,
          ),
          ProfileLoaded(:final user) => RefreshIndicator(
            onRefresh: context.read<ProfileCubit>().load,
            child: _ProfileContent(
              user: user,
              onLogout: () => _confirmLogout(context),
            ),
          ),
        };
        return body;
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.user, required this.onLogout});

  final User user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Spacing.lg),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: scheme.surfaceContainerHighest,
                      foregroundImage: user.image.isEmpty
                          ? null
                          : CachedNetworkImageProvider(user.image),
                      child: Text(
                        user.firstName.isEmpty ? '?' : user.firstName[0],
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  user.fullName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                Text(
                  '@${user.username}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.mail_outline_rounded),
                        title: const Text('Email'),
                        subtitle: Text(user.email),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: const Text('Phone'),
                        subtitle: Text(user.phone ?? 'Not provided'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Appearance', style: theme.textTheme.titleMedium),
                        const SizedBox(height: Spacing.md),
                        BlocBuilder<ThemeCubit, ThemeMode>(
                          builder: (context, mode) =>
                              SegmentedButton<ThemeMode>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(
                                    value: ThemeMode.light,
                                    icon: Icon(Icons.light_mode_outlined),
                                    label: Text('Light'),
                                  ),
                                  ButtonSegment(
                                    value: ThemeMode.system,
                                    icon: Icon(Icons.brightness_auto_outlined),
                                    label: Text('Auto'),
                                  ),
                                  ButtonSegment(
                                    value: ThemeMode.dark,
                                    icon: Icon(Icons.dark_mode_outlined),
                                    label: Text('Dark'),
                                  ),
                                ],
                                selected: {mode},
                                onSelectionChanged: (s) =>
                                    context.read<ThemeCubit>().setMode(s.first),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Error-handling playground'),
                    subtitle: const Text('Reproduce 500, 404, slow & expired'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DiagnosticsPage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                OutlinedButton.icon(
                  onPressed: onLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(
                      color: scheme.error.withValues(alpha: 0.5),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(Spacing.xl),
      child: Column(
        children: [
          SizedBox(height: Spacing.lg),
          ShimmerBox(width: 112, height: 112, radius: 56),
          SizedBox(height: Spacing.lg),
          ShimmerBox(width: 180, height: 24),
          SizedBox(height: Spacing.sm),
          ShimmerBox(width: 100, height: 16),
          SizedBox(height: Spacing.xl),
          ShimmerBox(height: 130, radius: AppRadius.md),
        ],
      ),
    );
  }
}
