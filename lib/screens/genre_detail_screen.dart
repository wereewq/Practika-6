import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/genre.dart';
import '../repositories/genre_repository.dart';

class GenreDetailScreen extends StatelessWidget {
  final int genreId;

  const GenreDetailScreen({super.key, required this.genreId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<GenreRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Жанр #$genreId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/genres'),
        ),
      ),
      body: FutureBuilder<Genre?>(
        future: repo.findById(genreId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final genre = snapshot.data;
          if (genre == null) return const Center(child: Text('Жанр не найден'));

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
                        genre.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        genre.description,
                        style: Theme.of(context).textTheme.bodyLarge,
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
