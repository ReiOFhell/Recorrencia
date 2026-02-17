abstract class AuthRepository {
  Future<void> signInWithEmail(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> consumeInvite(String token);
  bool get isAuthenticated;
}
