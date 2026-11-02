import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Доступ ограничен (403)')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gpp_bad_rounded, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Недостаточно прав', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Ваша роль не позволяет просматривать данный раздел системы.'),
              const SizedBox(height: 20),
              FilledButton(onPressed: () => context.go('/books'), child: const Text('Вернуться в каталог')),
            ],
          ),
        ),
      ),
    );
  }
}
