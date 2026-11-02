import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/author.dart';
import '../repositories/author_repository.dart';

class AuthorDetailScreen extends StatelessWidget {
  final int authorId;

  const AuthorDetailScreen({super.key, required this.authorId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AuthorRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Автор #$authorId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/authors'),
        ),
      ),
      body: FutureBuilder<Author?>(
        future: repo.findById(authorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final author = snapshot.data;
          if (author == null) {
            return const Center(child: Text('Автор не найден'));
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
                        author.fullName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.public),
                        title: const Text('Страна'),
                        subtitle: Text(author.country),
                      ),
                      ListTile(
                        leading: const Icon(Icons.cake),
                        title: const Text('Год рождения'),
                        subtitle: Text('${author.birthYear}'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text('Статус записи'),
                        subtitle: Text(
                          author.isDeleted
                              ? 'Удалён (${author.deletedAt})'
                              : 'Активен',
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
