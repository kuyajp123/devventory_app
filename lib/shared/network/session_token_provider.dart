/// Tokens stay in the authentication SDK, never in metadata repositories/cache.
abstract interface class SessionTokenProvider {
  String? get userId;
  Future<String?> idToken({bool forceRefresh = false});
}
