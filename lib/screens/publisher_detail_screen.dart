import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/publisher.dart';
import '../repositories/publisher_repository.dart';

class PublisherDetailScreen extends StatelessWidget {
  final int publisherId;

  const PublisherDetailScreen({super.key, required this.publisherId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PublisherRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Издательство #$publisherId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/publishers'),
        ),
      ),
      body: FutureBuilder<Publisher?>(
        future: repo.findById(publisherId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final pub = snapshot.data;
          if (pub == null) {
            return const Center(child: Text('Издательство не найдено'));
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
                        pub.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.location_city),
                        title: const Text('Город'),
                        subtitle: Text(pub.city),
                      ),
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: const Text('Веб-сайт'),
                        subtitle: Text(pub.website),
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
