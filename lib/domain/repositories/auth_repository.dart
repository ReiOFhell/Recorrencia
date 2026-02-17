abstract class AuthRepository {
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<Map<String, dynamic>> ensureMembership({String? displayName, String? avatarUrl});
  bool get isAuthenticated;
}
