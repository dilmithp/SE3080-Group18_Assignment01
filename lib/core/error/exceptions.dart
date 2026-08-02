/// Data-layer exceptions thrown by data sources. Repository implementations
/// catch these and map them to a [Failure] — see failures.dart. Nothing
/// above the `data/` layer should ever catch or throw these directly.
class ServerException implements Exception {
  const ServerException([this.message = 'Server error.']);
  final String message;
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'No network connection.']);
  final String message;
}

class AuthException implements Exception {
  const AuthException([this.message = 'Authentication failed.']);
  final String message;
}

class PermissionException implements Exception {
  const PermissionException([this.message = 'Permission denied.']);
  final String message;
}

class NotFoundException implements Exception {
  const NotFoundException([this.message = 'Not found.']);
  final String message;
}
