import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:books_store/core/api_client.dart';
import 'package:books_store/core/api_exceptions.dart';
import 'package:books_store/models/book.dart';
import 'package:books_store/models/book_query.dart';
import 'package:books_store/repositories/api_book_repository.dart';

/// Мок-адаптер сетевого уровня Dio
class MockAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) {
      return handler!(options);
    }
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      error: 'Сетевой сбой',
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late MockAdapter mockAdapter;
  late ApiBookRepository repository;

  setUp(() {
    dio = buildDio();
    mockAdapter = MockAdapter();
    dio.httpClientAdapter = mockAdapter;
    repository = ApiBookRepository(dio);
  });

  group('ApiBookRepository - сетевые тесты', () {
    // 1. Успешное получение списка и разбор пагинации
    test('find() успешно парсит список книг и метаданные пагинации', () async {
      mockAdapter.handler = (options) {
        expect(options.path, '/books');
        expect(options.queryParameters['page'], 1);
        expect(options.queryParameters['size'], 10);

        final jsonResponse = {
          'items': [
            {
              'id': 1,
              'title': '1984',
              'isbn': '978-5-17-080115-2',
              'year': 1949,
              'pages': 320,
              'publisherId': 2,
              'authorIds': [3],
              'genreIds': [3],
              'copiesTotal': 10,
              'copiesAvailable': 8,
              'deletedAt': null,
            },
          ],
          'page': 1,
          'size': 10,
          'total': 1,
        };

        return ResponseBody.fromString(
          jsonEncode(jsonResponse),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final result = await repository.find(const BookQuery(page: 1, size: 10));

      expect(result.total, 1);
      expect(result.items.length, 1);
      expect(result.items.first.title, '1984');
      expect(result.items.first.isbn, '978-5-17-080115-2');
    });

    // 2. Разбор ошибки 422 Unprocessable Entity
    test(
      'create() при статусе 422 выбрасывает ValidationException с полями ошибок',
      () async {
        mockAdapter.handler = (options) {
          final errorPayload = {
            'message': 'Ошибка валидации',
            'errors': {
              'isbn': 'Книга с таким ISBN уже существует',
              'year': 'Год не может быть в будущем',
            },
          };

          return ResponseBody.fromString(
            jsonEncode(errorPayload),
            422,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        const newBook = Book(
          id: 0,
          title: 'Дубликат',
          isbn: '978-5-17-080115-2',
          year: 2099,
          pages: 100,
          publisherId: 1,
          authorIds: [1],
          genreIds: [1],
          copiesTotal: 1,
          copiesAvailable: 1,
        );

        try {
          await repository.create(newBook);
          fail('Ожидалось исключение ValidationException');
        } on ValidationException catch (e) {
          expect(e.message, 'Ошибка валидации');
          expect(e.errors['isbn'], 'Книга с таким ISBN уже существует');
          expect(e.errors['year'], 'Год не может быть в будущем');
        }
      },
    );

    // 3. Обработка недоступности сервера (Connection Error / CORS)
    test('find() при сбое подключения выбрасывает NetworkException', () async {
      mockAdapter.handler = (options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'Connection refused',
        );
      };

      expect(
        () => repository.find(const BookQuery()),
        throwsA(isA<NetworkException>()),
      );
    });

    // 4. Обработка конфликта 409 Conflict
    test(
      'softDelete() при статусе 409 выбрасывает ConflictException',
      () async {
        mockAdapter.handler = (options) {
          final payload = {
            'message': 'Книга выдана читателям и не может быть удалена',
          };
          return ResponseBody.fromString(
            jsonEncode(payload),
            409,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        expect(
          () => repository.softDelete(1),
          throwsA(isA<ConflictException>()),
        );
      },
    );

    // 5. Успешное создание записи через POST
    test(
      'create() отправляет данные на сервер и возвращает созданную книгу',
      () async {
        mockAdapter.handler = (options) {
          expect(options.method, 'POST');
          expect(options.path, '/books');

          final body = options.data as Map<String, dynamic>;
          expect(body['title'], 'Новая книга');

          final responsePayload = {...body, 'id': 42, 'deletedAt': null};

          return ResponseBody.fromString(
            jsonEncode(responsePayload),
            201,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        };

        const bookToCreate = Book(
          id: 0,
          title: 'Новая книга',
          isbn: '978-5-389-00000-0',
          year: 2026,
          pages: 250,
          publisherId: 1,
          authorIds: [1],
          genreIds: [1],
          copiesTotal: 5,
          copiesAvailable: 5,
        );

        final created = await repository.create(bookToCreate);

        expect(created.id, 42);
        expect(created.title, 'Новая книга');
        expect(created.year, 2026);
      },
    );
  });
}
