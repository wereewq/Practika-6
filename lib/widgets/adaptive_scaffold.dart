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
      const NavigationDestination(icon: Icon(Icons.menu_book), label: 'Книги'),
      if (auth.has(Role.librarian)) ...[
        const NavigationDestination(icon: Icon(Icons.people), label: 'Авторы'),
        const NavigationDestination(icon: Icon(Icons.category), label: 'Жанры'),
        const NavigationDestination(
          icon: Icon(Icons.business),
          label: 'Издательства',
        ),
        const NavigationDestination(icon: Icon(Icons.badge), label: 'Читатели'),
      ],
      if (auth.role == Role.reader)
        const NavigationDestination(
          icon: Icon(Icons.bookmark),
          label: 'Мои книги',
        ),
      if (auth.has(Role.admin))
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Админ',
        ),
    ];

    final railDestinations = destinations
        .map(
          (d) => NavigationRailDestination(icon: d.icon, label: Text(d.label)),
        )
        .toList();

    void onNavigate(int idx) {
      final routes = [
        '/books',
        if (auth.has(Role.librarian)) ...[
          '/authors',
          '/genres',
          '/publishers',
          '/readers',
        ],
        if (auth.role == Role.reader) '/my-loans',
        if (auth.has(Role.admin)) '/admin/users',
      ];
      if (idx < routes.length) context.go(routes[idx]);
    }

    final appBar = AppBar(
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
            tooltip: 'Выйти из системы',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ],
    );

    // Ограничение ширины для экранов 1920px
    final boundedContent = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: child,
      ),
    );

    // 360px: мобильная компоновка с нижней навигацией
    if (size == ScreenSize.compact) {
      return Scaffold(
        appBar: appBar,
        body: boundedContent,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex.clamp(0, destinations.length - 1),
          destinations: destinations,
          onDestinationSelected: onNavigate,
        ),
      );
    }

    // 768px, 1280px, 1920px: боковая панель навигации
    final isExpandedRail =
        size == ScreenSize.expanded || size == ScreenSize.ultra;

    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex.clamp(0, railDestinations.length - 1),
            extended: isExpandedRail,
            labelType: isExpandedRail
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: railDestinations,
            onDestinationSelected: onNavigate,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: boundedContent),
        ],
      ),
    );
  }
}
