import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';

class BookDetailScreen extends StatelessWidget {
  final int bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<BookRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Книга #$bookId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/books'),
        ),
      ),
      body: FutureBuilder<Book?>(
        future: repo.findById(bookId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final book = snapshot.data;
          if (book == null) {
            return const Center(child: Text('Книга не найдена'));
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
                        book.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.qr_code),
                        title: const Text('ISBN'),
                        subtitle: Text(book.isbn),
                      ),
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Год издания'),
                        subtitle: Text('${book.year}'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.menu_book),
                        title: const Text('Количество страниц'),
                        subtitle: Text('${book.pages}'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.inventory),
                        title: const Text('Экземпляры в наличии'),
                        subtitle: Text(
                          '${book.copiesAvailable} из ${book.copiesTotal}',
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text('Статус записи'),
                        subtitle: Text(
                          book.isDeleted
                              ? 'Удалена (${book.deletedAt})'
                              : 'Активна',
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
