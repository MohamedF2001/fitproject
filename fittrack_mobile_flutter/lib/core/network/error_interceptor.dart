import 'package:dio/dio.dart';
import '../errors/failure.dart';

class ErrorInterceptor extends Interceptor {
  ErrorInterceptor(this.onFailure);
  final Failure Function(Object error) onFailure;
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(err.copyWith(error: onFailure(err)));
  }
}
