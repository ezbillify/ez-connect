sealed class AppError implements Exception {
  final String message;
  final dynamic originalError;

  const AppError(this.message, [this.originalError]);

  @override
  String toString() => message;
}

class NetworkError extends AppError {
  const NetworkError([String? message, dynamic originalError])
      : super(message ?? 'Network connection failed. Please check your internet connection.', originalError);
}

class MaxProductsError extends AppError {
  const MaxProductsError()
      : super('Maximum of 3 active products allowed. Please deactivate an existing product first.');
}

class ValidationError extends AppError {
  const ValidationError(String message) : super(message);
}

class NotFoundError extends AppError {
  const NotFoundError(String resource)
      : super('$resource not found');
}

class DatabaseError extends AppError {
  const DatabaseError([String? message, dynamic originalError])
      : super(message ?? 'Database operation failed', originalError);
}

class OfflineError extends AppError {
  const OfflineError()
      : super('You are offline. Changes will sync when connection is restored.');
}
