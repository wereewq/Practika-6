import 'package:flutter_test/flutter_test.dart';
import 'package:books_store/core/validators.dart';
import 'package:books_store/models/book.dart';
import 'package:books_store/models/role.dart';
import 'package:books_store/models/app_user.dart';

void main() {
  group('1. Валидация полей ввода', () {
    test('Обязательное поле: пустая строка отклоняется', () {
      expect(V.required()(''), isNotNull);
      expect(V.required()('   '), isNotNull);
      expect(V.required()('Книга'), isNull);
    });

    test('Длина строки в диапазоне min/max', () {
      final lenVal = V.length(min: 2, max: 10);
      expect(lenVal('A'), isNotNull);
      expect(lenVal('Длинный текст названия'), isNotNull);
      expect(lenVal('Корректно'), isNull);
    });

    test('Числовой диапазон и положительные числа', () {
      final intVal = V.integer(min: 1450, max: 2100);
      expect(intVal('abc'), isNotNull);
      expect(intVal('1400'), isNotNull);
      expect(intVal('2026'), isNull);
      expect(V.positiveInteger()('0'), isNotNull);
      expect(V.positiveInteger()('15'), isNull);
    });

    test('Формат ISBN', () {
      expect(V.isbn()('978-5-17-080115-2'), isNull);
      expect(V.isbn()('не-isbn'), isNotNull);
    });

    test('Формат электронной почты', () {
      expect(V.email()('test@example.com'), isNull);
      expect(V.email()('invalid-email'), isNotNull);
    });
  });

  group('2. Разбор моделей данных', () {
    test('Book.fromJson разбирает плоские и вложенные структуры без сбоев', () {
      final book = Book.fromJson({
        'id': 1,
        'title': 'Тест',
        'isbn': '978-5-17-000000-0',
        'publisher': {'id': 5, 'name': 'Издатель'},
        'authors': [
          {'id': 10},
        ],
        'genres': [
          {'id': 20},
        ],
      });
      expect(book.id, 1);
      expect(book.publisherId, 5);
      expect(book.authorIds, [10]);
      expect(book.genreIds, [20]);
    });
  });

  group('3. Логика ролей и иерархия доступа', () {
    test('Иерархия уровней доступа: admin > librarian > reader', () {
      expect(Role.admin.level > Role.librarian.level, isTrue);
      expect(Role.librarian.level > Role.reader.level, isTrue);
    });

    test('Проверка прав пользователя: AppUser.role', () {
      const reader = AppUser(
        id: 1,
        username: 'r',
        fullName: 'Р',
        role: Role.reader,
      );
      const admin = AppUser(
        id: 2,
        username: 'a',
        fullName: 'А',
        role: Role.admin,
      );
      expect(reader.role.level >= Role.librarian.level, isFalse);
      expect(admin.role.level >= Role.librarian.level, isTrue);
    });
  });
}
