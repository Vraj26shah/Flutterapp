import 'package:shopsphere/core/error/failures.dart';

/// A minimal Either-style result: [Ok] on success, [Err] with a [Failure].
///
/// Being `sealed`, callers can exhaustively `switch` on it.
sealed class Result<T> {
  const Result();

  R fold<R>(R Function(Failure failure) onErr, R Function(T data) onOk) =>
      switch (this) {
        Ok<T>(:final data) => onOk(data),
        Err<T>(:final failure) => onErr(failure),
      };

  bool get isOk => this is Ok<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.data);

  final T data;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
