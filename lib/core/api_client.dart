import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

Dio buildDio({
  String? Function()? tokenProvider,
  Future<void> Function()? onRefreshToken,
  VoidCallback? onForceLogout,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('--> ${options.method}${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;
        if (kDebugMode) {
          debugPrint('<-- $status${response.requestOptions.uri}');
        }
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final req = error.requestOptions;

        // Автоматический прозрачный Refresh токена при ошибке 401 (кроме запросов /auth/)
        if (status == 401 &&
            !req.path.contains('/auth/') &&
            onRefreshToken != null) {
          try {
            await onRefreshToken();
            final newToken = tokenProvider?.call();
            if (newToken != null) {
              req.headers['Authorization'] = 'Bearer $newToken';
              final response = await dio.fetch(req);
              return handler.resolve(response);
            }
          } catch (_) {
            onForceLogout?.call();
            return handler.reject(error);
          }
        }

        // Retry для GET запросов при сетевых таймаутах
        final isGet = req.method.toUpperCase() == 'GET';
        final isNetwork =
            error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout;

        int retryCount = req.extra['retryCount'] ?? 0;
        if (isGet && isNetwork && retryCount < 3) {
          retryCount++;
          req.extra['retryCount'] = retryCount;
          await Future.delayed(Duration(milliseconds: retryCount * 500));
          try {
            final response = await dio.fetch(req);
            return handler.resolve(response);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        }

        return handler.next(error);
      },
    ),
  );

  return dio;
}
