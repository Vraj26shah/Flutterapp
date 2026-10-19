import 'package:equatable/equatable.dart';
import 'package:shopsphere/core/utils/result.dart';

/// Base contract for every use case: one public `call` method.
abstract interface class UseCase<T, P> {
  Future<Result<T>> call(P params);
}

/// Parameter object for use cases that need no input.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
