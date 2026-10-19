import 'package:shopsphere/core/usecase/usecase.dart';
import 'package:shopsphere/core/utils/result.dart';

/// Failure scenarios from the assignment brief (section 4), reproducible
/// from inside the app so reviewers can see how each one is handled.
enum ErrorScenario {
  serverError('Server error', 'GET /http/500'),
  notFound('Not found', 'GET /http/404'),
  slowNetwork('Slow network', 'GET /products?delay=3000'),
  expiredSession('Expired session', 'Invalid tokens → /auth/me → refresh 403');

  const ErrorScenario(this.title, this.request);

  final String title;
  final String request;
}

abstract interface class DiagnosticsRepository {
  /// Runs the scenario; returns a success message or the mapped failure.
  Future<Result<String>> run(ErrorScenario scenario);
}

class RunScenarioUseCase implements UseCase<String, ErrorScenario> {
  const RunScenarioUseCase(this._repository);

  final DiagnosticsRepository _repository;

  @override
  Future<Result<String>> call(ErrorScenario params) => _repository.run(params);
}
