import 'package:go_router/go_router.dart';

import '../models/author_query.dart';
import '../models/book_query.dart';
import '../models/genre_query.dart';
import '../models/publisher_query.dart';
import '../models/reader_query.dart';
import '../models/role.dart';
import '../screens/admin_users_screen.dart';
import '../screens/author_detail_screen.dart';
import '../screens/author_form_screen.dart';
import '../screens/author_list_screen.dart';
import '../screens/book_detail_screen.dart';
import '../screens/book_form_screen.dart';
import '../screens/book_list_screen.dart';
import '../screens/forbidden_screen.dart';
import '../screens/genre_detail_screen.dart';
import '../screens/genre_form_screen.dart';
import '../screens/genre_list_screen.dart';
import '../screens/login_screen.dart';
import '../screens/my_loans_screen.dart';
import '../screens/publisher_detail_screen.dart';
import '../screens/publisher_form_screen.dart';
import '../screens/publisher_list_screen.dart';
import '../screens/reader_detail_screen.dart';
import '../screens/reader_form_screen.dart';
import '../screens/reader_list_screen.dart';
import '../screens/register_screen.dart';
import '../state/auth_notifier.dart';
import '../widgets/adaptive_scaffold.dart';

BookQuery parseBookQuery(Map<String, String> params) {
  final sortParam = params['sort'] ?? 'title,asc';
  final sortParts = sortParam.split(',');
  final sortField = sortParts.first;
  final sortAscending = sortParts.length > 1 ? sortParts[1] != 'desc' : true;

  return BookQuery(
    search: params['search'] ?? '',
    genreId: int.tryParse(params['genreId'] ?? ''),
    publisherId: int.tryParse(params['publisherId'] ?? ''),
    yearFrom: int.tryParse(params['yearFrom'] ?? ''),
    yearTo: int.tryParse(params['yearTo'] ?? ''),
    sortField: sortField,
    sortAscending: sortAscending,
    page: int.tryParse(params['page'] ?? '') ?? 1,
    size: int.tryParse(params['size'] ?? '') ?? 10,
    includeDeleted: params['includeDeleted'] == 'true',
  );
}

Map<String, String> bookQueryToParams(BookQuery q) {
  final map = <String, String>{};
  if (q.search.isNotEmpty) map['search'] = q.search;
  if (q.genreId != null) map['genreId'] = q.genreId.toString();
  if (q.publisherId != null) map['publisherId'] = q.publisherId.toString();
  if (q.yearFrom != null) map['yearFrom'] = q.yearFrom.toString();
  if (q.yearTo != null) map['yearTo'] = q.yearTo.toString();
  map['sort'] = '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}';
  if (q.page > 1) map['page'] = q.page.toString();
  if (q.size != 10) map['size'] = q.size.toString();
  if (q.includeDeleted) map['includeDeleted'] = 'true';
  return map;
}

AuthorQuery parseAuthorQuery(Map<String, String> params) {
  final sortParam = params['sort'] ?? 'lastName,asc';
  final sortParts = sortParam.split(',');
  final sortField = sortParts.first;
  final sortAscending = sortParts.length > 1 ? sortParts[1] != 'desc' : true;

  return AuthorQuery(
    search: params['search'] ?? '',
    country: params['country'],
    sortField: sortField,
    sortAscending: sortAscending,
    page: int.tryParse(params['page'] ?? '') ?? 1,
    size: int.tryParse(params['size'] ?? '') ?? 10,
    includeDeleted: params['includeDeleted'] == 'true',
  );
}

Map<String, String> authorQueryToParams(AuthorQuery q) {
  final map = <String, String>{};
  if (q.search.isNotEmpty) map['search'] = q.search;
  if (q.country != null && q.country!.isNotEmpty) map['country'] = q.country!;
  map['sort'] = '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}';
  if (q.page > 1) map['page'] = q.page.toString();
  if (q.size != 10) map['size'] = q.size.toString();
  if (q.includeDeleted) map['includeDeleted'] = 'true';
  return map;
}

GoRouter createRouter(AuthNotifier auth) {
  return GoRouter(
    initialLocation: '/books',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (loggedIn && isPublic) return '/books';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (c, s) => LoginScreen(from: s.uri.queryParameters['from']),
      ),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/forbidden', builder: (c, s) => const ForbiddenScreen()),
      ShellRoute(
        builder: (context, state, child) {
          final loc = state.uri.path;
          int idx = 0;
          if (loc.startsWith('/authors')) idx = 1;
          if (loc.startsWith('/genres')) idx = 2;
          if (loc.startsWith('/publishers')) idx = 3;
          if (loc.startsWith('/readers')) idx = 4;
          if (loc.startsWith('/my-loans')) idx = auth.has(Role.librarian) ? 5 : 1;
          if (loc.startsWith('/admin')) idx = auth.has(Role.librarian) ? 6 : 2;

          return AdaptiveScaffold(currentIndex: idx, child: child);
        },
        routes: [
          GoRoute(
            path: '/books',
            builder: (c, s) => BookListScreen(initialQuery: parseBookQuery(s.uri.queryParameters)),
            routes: [
              GoRoute(
                path: 'new',
                redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
                builder: (c, s) => const BookFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (c, s) => BookDetailScreen(bookId: int.tryParse(s.pathParameters['id'] ?? '') ?? 0),
                routes: [
                  GoRoute(
                    path: 'edit',
                    redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
                    builder: (c, s) => BookFormScreen(id: int.tryParse(s.pathParameters['id'] ?? '')),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/authors',
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
            builder: (c, s) => AuthorListScreen(initialQuery: parseAuthorQuery(s.uri.queryParameters)),
            routes: [
              GoRoute(path: 'new', builder: (c, s) => const AuthorFormScreen()),
              GoRoute(path: ':id', builder: (c, s) => AuthorDetailScreen(authorId: int.tryParse(s.pathParameters['id'] ?? '') ?? 0)),
            ],
          ),
          GoRoute(
            path: '/genres',
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
            builder: (c, s) => const GenreListScreen(initialQuery: GenreQuery()),
            routes: [
              GoRoute(path: 'new', builder: (c, s) => const GenreFormScreen()),
              GoRoute(path: ':id', builder: (c, s) => GenreDetailScreen(genreId: int.tryParse(s.pathParameters['id'] ?? '') ?? 0)),
            ],
          ),
          GoRoute(
            path: '/publishers',
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
            builder: (c, s) => const PublisherListScreen(initialQuery: PublisherQuery()),
            routes: [
              GoRoute(path: 'new', builder: (c, s) => const PublisherFormScreen()),
              GoRoute(path: ':id', builder: (c, s) => PublisherDetailScreen(publisherId: int.tryParse(s.pathParameters['id'] ?? '') ?? 0)),
            ],
          ),
          GoRoute(
            path: '/readers',
            redirect: (context, state) => auth.has(Role.librarian) ? null : '/forbidden',
            builder: (c, s) => const ReaderListScreen(initialQuery: ReaderQuery()),
            routes: [
              GoRoute(path: 'new', builder: (c, s) => const ReaderFormScreen()),
              GoRoute(path: ':id', builder: (c, s) => ReaderDetailScreen(readerId: int.tryParse(s.pathParameters['id'] ?? '') ?? 0)),
            ],
          ),
          GoRoute(path: '/my-loans', builder: (c, s) => const MyLoansScreen()),
          GoRoute(
            path: '/admin/users',
            redirect: (context, state) => auth.has(Role.admin) ? null : '/forbidden',
            builder: (c, s) => const AdminUsersScreen(),
          ),
        ],
      ),
    ],
  );
}
