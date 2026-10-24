class AuthenticationRequiredException implements Exception {
  const AuthenticationRequiredException();

  @override
  String toString() => 'Sign in to use Latyr.';
}
