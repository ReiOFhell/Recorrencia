import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.client);

  final SupabaseClient client;

  Map<String, String> _authHeaders() {
    final token = client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw const AuthException('Sessão ausente. Faça login novamente.');
    }
    return {'Authorization': 'Bearer $token'};
  }

  @override
  Future<Map<String, dynamic>> ensureMembership({String? displayName, String? avatarUrl}) async {
    final response = await client.functions.invoke(
      'ensure_membership',
      body: {
        if (displayName != null) 'display_name': displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      },
      headers: _authHeaders(),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  bool get isAuthenticated => client.auth.currentSession?.accessToken != null;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUpWithEmail(String email, String password) async {
    await client.auth.signUp(email: email, password: password);
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
