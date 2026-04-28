class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException(this.message);
}
