/// Base interface for all use cases
/// 
/// Type [T] represents the return type
/// Type [Params] represents the input parameters
abstract class UseCase<T, Params> {
  Future<T> call(Params params);
}

/// Use case with no parameters
abstract class NoParamsUseCase<T> {
  Future<T> call();
}

/// Use case with no return value (void)
abstract class VoidUseCase<Params> {
  Future<void> call(Params params);
}

/// Use case with no parameters and no return value
abstract class SimpleUseCase {
  Future<void> call();
}

/// Stream-based use case for reactive operations
abstract class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

/// Stream-based use case with no parameters
abstract class NoParamsStreamUseCase<T> {
  Stream<T> call();
}