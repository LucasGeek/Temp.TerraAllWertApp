import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../../infra/graphql/mutations/auth_mutations.dart';
import '../models/auth_response.dart';
import '../models/user_dto.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> login({
    required String email,
    required String password,
  });

  Future<AuthResponse> refreshToken(String refreshToken);

  Future<void> logout();

  Future<UserDto?> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final GraphQLClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(loginMutation),
        variables: {
          'email': email,
          'password': password,
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return AuthResponse.fromJson(result.data!['login']);
  }

  @override
  Future<AuthResponse> refreshToken(String refreshToken) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(refreshTokenMutation),
        variables: {
          'refreshToken': refreshToken,
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return AuthResponse.fromJson(result.data!['refreshToken']);
  }

  @override
  Future<void> logout() async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(logoutMutation),
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
  }

  @override
  Future<UserDto?> getCurrentUser() async {
    final result = await _client.query(
      QueryOptions(
        document: gql(getCurrentUserQuery),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data?['me'] == null) {
      return null;
    }

    return UserDto.fromJson(result.data!['me']);
  }
}