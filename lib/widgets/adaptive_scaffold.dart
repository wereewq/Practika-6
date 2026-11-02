import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/breakpoints.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const AdaptiveScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final size = screenSizeOf(context);

    final destinations = [
      const NavigationRailDestination(icon: Icon(Icons.menu_book), label: Text('Книги')),
      if (auth.has(Role.librarian)) ...[
        const NavigationRailDestination(icon: Icon(Icons.people), label: Text('Авторы')),
        const NavigationRailDestination(icon: Icon(Icons.category), label: Text('Жанры')),
        const NavigationRailDestination(icon: Icon(Icons.business), label: Text('Издательства')),
        const NavigationRailDestination(icon: Icon(Icons.badge), label: Text('Читатели')),
      ],
      if (auth.role == Role.reader)
        const NavigationRailDestination(icon: Icon(Icons.bookmark), label: Text('Мои книги')),
      if (auth.has(Role.admin))
        const NavigationRailDestination(icon: Icon(Icons.admin_panel_settings), label: Text('Админ')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Библиотечная система'),
        actions: [
          if (auth.isAuthenticated) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  '${auth.user?.fullName} (${auth.role.title})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Выйти',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex.clamp(0, destinations.length - 1),
            extended: size == ScreenSize.expanded,
            destinations: destinations,
            onDestinationSelected: (idx) {
              final routes = [
                '/books',
                if (auth.has(Role.librarian)) ...['/authors', '/genres', '/publishers', '/readers'],
                if (auth.role == Role.reader) '/my-loans',
                if (auth.has(Role.admin)) '/admin/users',
              ];
              if (idx < routes.length) context.go(routes[idx]);
            },
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
