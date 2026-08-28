/// Shared API types used by both the REST client and the mock backend, so they
/// can reference each other without a circular import.
library;

/// Result of an OTP request (demo provider echoes the code for dev).
class OtpRequestResult {
  final bool ok;
  final String provider;
  final String? demoCode;
  const OtpRequestResult({required this.ok, required this.provider, this.demoCode});
}

/// Base API exception. `unauthenticated` marks 401/403 expiry so the app can
/// flush the session and redirect to /join (spec 13).
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool unauthenticated;
  const ApiException(this.message, {this.statusCode, this.unauthenticated = false});
  const ApiException.network(String m) : this(m);
  const ApiException.unauthenticated(int code)
      : this('Session expired', statusCode: code, unauthenticated: true);
  @override
  String toString() => message;
}

/// User-visible exception surfaced as friendly messages (validation, rate
/// limits, coverage gating) — a clear pre-submit error, never silent.
class ApiPublic implements Exception {
  final String message;
  const ApiPublic(this.message);
  @override
  String toString() => message;
}

/// True when an error is an auth-expiry (401/403) that should flush the session
/// per spec 13 ("on 401/403 flush session → /join").
bool isUnauthenticated(Object e) => e is ApiException && e.unauthenticated;
