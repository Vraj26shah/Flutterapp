import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopsphere/core/di/injection.dart';
import 'package:shopsphere/core/theme/app_theme.dart';
import 'package:shopsphere/core/widgets/state_views.dart';
import 'package:shopsphere/features/diagnostics/domain/diagnostics.dart';
import 'package:shopsphere/features/diagnostics/presentation/diagnostics_cubit.dart';
import 'package:shopsphere/features/products/presentation/pages/product_details_page.dart';

/// "Error-handling playground": reproduces the brief's failure scenarios.
class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DiagnosticsCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Error-handling playground')),
        body: BlocBuilder<DiagnosticsCubit, DiagnosticsState>(
          builder: (context, state) {
            final cubit = context.read<DiagnosticsCubit>();
            return ListView(
              padding: const EdgeInsets.all(Spacing.lg),
              children: [
                Text(
                  'Each action calls a DummyJSON test endpoint through the '
                  'app\'s real network stack, so you can see how failures '
                  'are mapped and shown.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: Spacing.lg),
                Card(
                  child: Column(
                    children: [
                      for (final s in ErrorScenario.values)
                        ListTile(
                          leading: Icon(_iconFor(s)),
                          title: Text(s.title),
                          subtitle: Text(s.request),
                          trailing: const Icon(Icons.play_arrow_rounded),
                          enabled: !state.isRunning,
                          selected: s == state.scenario,
                          onTap: () => cubit.run(s),
                        ),
                      ListTile(
                        leading: const Icon(Icons.search_off_rounded),
                        title: const Text('Open product #9999'),
                        subtitle: const Text('GET /products/9999 → 404'),
                        trailing: const Icon(Icons.open_in_new_rounded),
                        enabled: !state.isRunning,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const ProductDetailsPage(productId: 9999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                SizedBox(height: 360, child: _Result(state: state)),
              ],
            );
          },
        ),
      ),
    );
  }

  static IconData _iconFor(ErrorScenario s) => switch (s) {
    ErrorScenario.serverError => Icons.cloud_off_rounded,
    ErrorScenario.notFound => Icons.link_off_rounded,
    ErrorScenario.slowNetwork => Icons.hourglass_bottom_rounded,
    ErrorScenario.expiredSession => Icons.lock_clock_rounded,
  };
}

class _Result extends StatelessWidget {
  const _Result({required this.state});

  final DiagnosticsState state;

  @override
  Widget build(BuildContext context) {
    if (state.scenario == null) return const SizedBox.shrink();
    if (state.isRunning) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: Spacing.lg),
            Text('Running “${state.scenario!.title}”…'),
          ],
        ),
      );
    }
    if (state.failure != null) {
      return ErrorView(
        failure: state.failure!,
        onRetry: () => context.read<DiagnosticsCubit>().run(state.scenario!),
      );
    }
    return EmptyView(
      icon: Icons.check_circle_outline_rounded,
      title: 'Success',
      message: state.message,
    );
  }
}
