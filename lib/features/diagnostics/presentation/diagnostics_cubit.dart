import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopsphere/core/error/failures.dart';
import 'package:shopsphere/core/utils/result.dart';
import 'package:shopsphere/features/diagnostics/domain/diagnostics.dart';

final class DiagnosticsState extends Equatable {
  const DiagnosticsState({
    this.scenario,
    this.isRunning = false,
    this.message,
    this.failure,
  });

  final ErrorScenario? scenario;
  final bool isRunning;
  final String? message;
  final Failure? failure;

  @override
  List<Object?> get props => [scenario, isRunning, message, failure];
}

class DiagnosticsCubit extends Cubit<DiagnosticsState> {
  DiagnosticsCubit(this._run) : super(const DiagnosticsState());

  final RunScenarioUseCase _run;

  Future<void> run(ErrorScenario scenario) async {
    emit(DiagnosticsState(scenario: scenario, isRunning: true));
    final result = await _run(scenario);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final data) => DiagnosticsState(scenario: scenario, message: data),
      Err(:final failure) => DiagnosticsState(
        scenario: scenario,
        failure: failure,
      ),
    });
  }
}
