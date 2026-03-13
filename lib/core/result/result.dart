sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.message);
  final String message;
}

extension ResultExtension<T> on Result<T> {
  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
        Ok(:final value) => value,
        Err() => null,
      };

  String? get errorOrNull => switch (this) {
        Ok() => null,
        Err(:final message) => message,
      };

  R fold<R>({
    required R Function(T value) ok,
    required R Function(String message) err,
  }) =>
      switch (this) {
        Ok(:final value) => ok(value),
        Err(:final message) => err(message),
      };
}
