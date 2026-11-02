import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:books_store/core/validators.dart';
import 'package:books_store/models/role.dart';

void main() {
  group('Тестирование состояний виджетов интерфейса', () {
    // 1. Отображение состояния загрузки
    testWidgets('1. Отображение кругового индикатора загрузки', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // 2. Отображение пустого результата
    testWidgets('2. Отображение сообщения при пустом каталоге', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Книг по заданным критериям не найдено')),
          ),
        ),
      );
      expect(
        find.text('Книг по заданным критериям не найдено'),
        findsOneWidget,
      );
    });

    // 3. Отображение ошибки с кнопкой повтора
    testWidgets('3. Отображение сообщения об ошибке и кнопки повтора', (
      tester,
    ) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Сервер временно недоступен'),
                FilledButton(
                  onPressed: () => retried = true,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Сервер временно недоступен'), findsOneWidget);
      await tester.tap(find.text('Повторить'));
      await tester.pump();
      expect(retried, isTrue);
    });

    // 4. Срабатывание клиентской валидации формы
    testWidgets('4. Валидация формы выводит сообщение об обязательности поля', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(validator: V.required('Укажите название')),
                  ElevatedButton(
                    onPressed: () => formKey.currentState!.validate(),
                    child: const Text('Сохранить'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Сохранить'));
      await tester.pump();
      expect(find.text('Укажите название'), findsOneWidget);
    });

    // 5. Скрытие недоступного элемента при роли читателя
    testWidgets('5. Кнопка добавления скрыта для роли читателя', (
      tester,
    ) async {
      const userRole = Role.reader;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                if (userRole.level >= Role.librarian.level)
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Добавить книгу'),
                  ),
                const Text('Каталог'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Добавить книгу'), findsNothing);
      expect(find.text('Каталог'), findsOneWidget);
    });
  });
}
