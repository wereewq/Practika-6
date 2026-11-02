import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/reader.dart';
import '../repositories/reader_repository.dart';

class ReaderDetailScreen extends StatelessWidget {
  final int readerId;

  const ReaderDetailScreen({super.key, required this.readerId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ReaderRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Читатель #$readerId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/readers'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/readers/$readerId/edit'),
          ),
        ],
      ),
      body: FutureBuilder<Reader?>(
        future: repo.findById(readerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reader = snapshot.data;
          if (reader == null) {
            return const Center(child: Text('Читатель не найден'));
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reader.fullName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email'),
                        subtitle: Text(reader.email),
                      ),
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: const Text('Телефон'),
                        subtitle: Text(reader.phone),
                      ),
                      const Divider(),
                      Text(
                        'Читательский билет (1-к-1)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      ListTile(
                        leading: const Icon(Icons.credit_card),
                        title: const Text('Номер билета'),
                        subtitle: Text(reader.card.cardNumber),
                        trailing: Chip(
                          label: Text(
                            reader.card.isActive ? 'Активен' : 'Заблокирован',
                          ),
                          backgroundColor: reader.card.isActive
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
