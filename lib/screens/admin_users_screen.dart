import 'package:flutter/material.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление пользователями и ролями (Администратор)')),
      body: const Center(
        child: Text('Экран доступен строго пользователям с ролью Администратора.'),
      ),
    );
  }
}
