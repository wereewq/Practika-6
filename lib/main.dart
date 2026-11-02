import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/router.dart';
import 'repositories/api_author_repository.dart';
import 'repositories/api_book_repository.dart';
import 'repositories/api_genre_repository.dart';
import 'repositories/api_publisher_repository.dart';
import 'repositories/api_reader_repository.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';
import 'state/auth_notifier.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/genre_list_notifier.dart';
import 'state/publisher_list_notifier.dart';
import 'state/reader_list_notifier.dart';
import 'widgets/inactivity_watcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();
  runApp(LibraryApp(prefs: prefs));
}

class LibraryApp extends StatefulWidget {
  final SharedPreferences prefs;
  final Dio? dio;

  const LibraryApp({super.key, required this.prefs, this.dio});

  @override
  State<LibraryApp> createState() => _LibraryAppState();
}

class _LibraryAppState extends State<LibraryApp> {
  late final AuthNotifier _authNotifier;
  late final Dio _dio;

  @override
  void initState() {
    super.initState();
    _dio =
        widget.dio ??
        buildDio(
          tokenProvider: () => _authNotifier.accessToken,
          onRefreshToken: () => _authNotifier.refreshTokens(),
          onForceLogout: () => _authNotifier.logout(),
        );
    _authNotifier = AuthNotifier(widget.prefs, _dio);
    _authNotifier.restore();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authNotifier),
        Provider<Dio>.value(value: _dio),
        ProxyProvider<Dio, BookRepository>(
          update: (_, client, _) => ApiBookRepository(client),
        ),
        ProxyProvider<Dio, AuthorRepository>(
          update: (_, client, _) => ApiAuthorRepository(client),
        ),
        ProxyProvider<Dio, GenreRepository>(
          update: (_, client, _) => ApiGenreRepository(client),
        ),
        ProxyProvider<Dio, PublisherRepository>(
          update: (_, client, _) => ApiPublisherRepository(client),
        ),
        ProxyProvider<Dio, ReaderRepository>(
          update: (_, client, _) => ApiReaderRepository(client),
        ),
        ChangeNotifierProxyProvider<BookRepository, BookListNotifier>(
          create: (ctx) => BookListNotifier(ctx.read<BookRepository>()),
          update: (_, repo, notifier) => notifier ?? BookListNotifier(repo),
        ),
        ChangeNotifierProxyProvider<AuthorRepository, AuthorListNotifier>(
          create: (ctx) => AuthorListNotifier(ctx.read<AuthorRepository>()),
          update: (_, repo, notifier) => notifier ?? AuthorListNotifier(repo),
        ),
        ChangeNotifierProxyProvider<GenreRepository, GenreListNotifier>(
          create: (ctx) => GenreListNotifier(ctx.read<GenreRepository>()),
          update: (_, repo, notifier) => notifier ?? GenreListNotifier(repo),
        ),
        ChangeNotifierProxyProvider<PublisherRepository, PublisherListNotifier>(
          create: (ctx) =>
              PublisherListNotifier(ctx.read<PublisherRepository>()),
          update: (_, repo, notifier) =>
              notifier ?? PublisherListNotifier(repo),
        ),
        ChangeNotifierProxyProvider<ReaderRepository, ReaderListNotifier>(
          create: (ctx) => ReaderListNotifier(ctx.read<ReaderRepository>()),
          update: (_, repo, notifier) => notifier ?? ReaderListNotifier(repo),
        ),
      ],
      child: InactivityWatcher(
        timeout: const Duration(minutes: 3),
        onTimeout: () => _authNotifier.logout(),
        child: MaterialApp.router(
          title: 'Библиотечная система',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
          routerConfig: createRouter(_authNotifier),
        ),
      ),
    );
  }
}
