import 'package:dio/dio.dart';

import '../errors/failure.dart';
import '../storage/local_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.storage);
  final LocalStorage storage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = storage.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class DioClient {
  DioClient(this.storage, String baseUrl)
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(AuthInterceptor(storage));
  }

  final Dio dio;
  final LocalStorage storage;

  Failure failureFrom(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      final message = data is Map
          ? (data['message'] ?? data['error'] ?? 'Une erreur est survenue')
              .toString()
          : 'Connexion impossible. Vérifiez votre réseau.';
      if (status == 401) return AuthFailure(message);
      if (status == 404) return NotFoundFailure(message);
      if (status != null && status >= 400) {
        return ServerFailure(message, statusCode: status);
      }
      return NetworkFailure(message);
    }
    return UnknownFailure(error.toString());
  }
}
