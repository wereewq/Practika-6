import 'package:flutter_test/flutter_test.dart';
import 'package:books_store/models/app_user.dart';
import 'package:books_store/models/role.dart';

void main() {
  group('Тесты логики ролей и разграничения прав (ПР5)', () {
    test('1. Иерархия уровней ролей: admin > librarian > reader', () {
      expect(Role.admin.level > Role.librarian.level, isTrue);
      expect(Role.librarian.level > Role.reader.level, isTrue);
    });

    test('2. Администратор обладает правами всех младших ролей', () {
      const adminUser = AppUser(
        id: 1,
        username: 'adm',
        fullName: 'Админ',
        role: Role.admin,
      );
      expect(adminUser.role.level >= Role.reader.level, isTrue);
      expect(adminUser.role.level >= Role.librarian.level, isTrue);
      expect(adminUser.role.level >= Role.admin.level, isTrue);
    });

    test(
      '3. Читатель не имеет доступа к правам библиотекаря и администратора',
      () {
        const readerUser = AppUser(
          id: 3,
          username: 'rdr',
          fullName: 'Читатель',
          role: Role.reader,
        );
        expect(readerUser.role.level >= Role.librarian.level, isFalse);
        expect(readerUser.role.level >= Role.admin.level, isFalse);
      },
    );

    test('4. Парсинг строковых ролей из JSON', () {
      expect(Role.fromString('admin'), Role.admin);
      expect(Role.fromString('librarian'), Role.librarian);
      expect(Role.fromString('reader'), Role.reader);
      expect(Role.fromString('unknown'), Role.reader);
    });

    test(
      '5. Проверка сложности пароля (минимум 8 символов, цифра, спецсимвол)',
      () {
        bool isStrong(String p) =>
            p.length >= 8 &&
            RegExp(r'\d').hasMatch(p) &&
            RegExp(r'[!@#$%^&*]').hasMatch(p);

        expect(isStrong('pass'), isFalse);
        expect(isStrong('password123'), isFalse); // нет спецсимвола
        expect(isStrong('Password!'), isFalse); // нет цифры
        expect(isStrong('Password123!'), isTrue); // удовлетворяет всем условиям
      },
    );
  });
}
