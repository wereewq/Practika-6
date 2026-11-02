import 'package:flutter/material.dart';

class MyLoansScreen extends StatelessWidget {
  const MyLoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои книги и продление срока (Читатель)')),
      body: const Center(
        child: Text('Список книг, выданных текущему читателю.'),
      ),
    );
  }
}
