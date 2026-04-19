// Legacy API service — now wraps FirestoreService for backward compatibility.
// Kept so that any stray references still compile.
// All real logic lives in FirestoreService.

// Custom exception for API errors (kept for compatibility)
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;

  ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'ApiException: $statusCode - $message';
}