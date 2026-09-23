import 'package:flutter/foundation.dart';

/// Base Result class representing either a success ([Ok]) or a failure ([Error]),
/// following the official Flutter Architecture Result pattern.
@immutable
sealed class Result<T> {
  const Result();

  /// Creates a successful result with [value].
  const factory Result.ok(T value) = Ok<T>;

  /// Creates a failed result with [error].
  const factory Result.error(Exception error) = Error<T>;

  /// Returns true if this is an [Ok] result.
  bool get isOk => this is Ok<T>;

  /// Returns true if this is an [Error] result.
  bool get isError => this is Error<T>;

  /// Returns the underlying value if [Ok], or throws a [StateError].
  T get asOk {
    if (this is Ok<T>) {
      return (this as Ok<T>).value;
    }
    throw StateError('Cannot call asOk on a Result.error: ${(this as Error<T>).error}');
  }

  /// Returns the underlying error if [Error], or throws a [StateError].
  Exception get asError {
    if (this is Error<T>) {
      return (this as Error<T>).error;
    }
    throw StateError('Cannot call asError on a Result.ok');
  }

  /// Maps the value if [Ok], returns unchanged if [Error].
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Ok<T>(:final value) => Result.ok(transform(value)),
      Error<T>(:final error) => Result.error(error),
    };
  }
}

/// Represents a successful computation holding [value].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Ok<T> && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Result.ok($value)';
}

/// Represents a failed computation holding an [error].
final class Error<T> extends Result<T> {
  const Error(this.error);

  final Exception error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Error<T> && runtimeType == other.runtimeType && error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Result.error($error)';
}
