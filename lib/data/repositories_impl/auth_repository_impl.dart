import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.client);

  final SupabaseClient client;

  Map<String, String> _authHeaders() {
    final token = client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw const AuthException('Sessão ausente. Faça login antes de consumir convite.');
    }
    return {'Authorization': 'Bearer $token'};
  }

  @override
  Future<void> consumeInvite(String token) async {
    await client.functions.invoke(
      'consume_invite_and_join',
      body: {'token': token},
      headers: _authHeaders(),
    );
  }

  @override
  bool get isAuthenticated => client.auth.currentSession?.accessToken != null;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.demoncorp.recorrencia://login-callback/',
    );
  }

  @override
  Future<void> signOut() async {
    await client.auth.signOut();
  }
}
