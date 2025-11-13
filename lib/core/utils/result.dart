import '../errors/app_error.dart';

sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}

extension ResultExtensions<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
    Success(data: final data) => data,
    _ => null,
  };

  AppError? get errorOrNull => switch (this) {
    Failure(error: final error) => error,
    _ => null,
  };

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(AppError error) onFailure,
  }) {
    return switch (this) {
      Success(data: final data) => onSuccess(data),
      Failure(error: final error) => onFailure(error),
    };
  }
}
