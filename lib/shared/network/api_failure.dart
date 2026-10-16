enum ApiFailureKind {
  unauthorized,
  verificationRequired,
  workspaceRequired,
  rateLimited,
  unavailable,
  offline,
  invalidResponse,
  forbidden,
  cancelled,
}

class ApiFailure implements Exception {
  const ApiFailure(this.kind, {this.retryAt});
  final ApiFailureKind kind;
  final DateTime? retryAt;

  String get message => switch (kind) {
    ApiFailureKind.unauthorized =>
      'Your session has expired. Sign in again to continue.',
    ApiFailureKind.verificationRequired =>
      'Verify your email before connecting to your workspace.',
    ApiFailureKind.workspaceRequired =>
      'Set up Cloud Sync on Devventory desktop first.',
    ApiFailureKind.rateLimited =>
      'Too many requests. Wait a moment before trying again.',
    ApiFailureKind.unavailable =>
      'Cloud Sync is temporarily unavailable. Please try again.',
    ApiFailureKind.offline =>
      'Cannot reach Cloud Sync. Check your connection and try again.',
    ApiFailureKind.invalidResponse => 'Cloud Sync returned an unsupported response. Try again or update the app.',
    ApiFailureKind.forbidden =>
      'This account cannot access this workspace. Check Cloud Sync on desktop.',
    ApiFailureKind.cancelled => 'The account changed. Please try again.',
  };
}
