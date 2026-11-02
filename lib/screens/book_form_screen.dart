import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/author.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../repositories/author_repository.dart';
import '../repositories/book_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/publisher_repository.dart';
import '../state/book_list_notifier.dart';

class BookFormScreen extends StatefulWidget {
  final int? id;

  const BookFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _isbnController;
  late final TextEditingController _yearController;
  late final TextEditingController _pagesController;
  late final TextEditingController _copiesTotalController;
  late final TextEditingController _copiesAvailableController;

  int? _publisherId;
  List<int> _authorIds = [];
  List<int> _genreIds = [];

  List<Publisher> _publishers = [];
  List<Author> _authors = [];
  List<Genre> _genres = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;
  Map<String, String> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _isbnController = TextEditingController();
    _yearController = TextEditingController();
    _pagesController = TextEditingController();
    _copiesTotalController = TextEditingController(text: '1');
    _copiesAvailableController = TextEditingController(text: '1');

    _loadData();
  }

  Future<void> _loadData() async {
    final pubRepo = context.read<PublisherRepository>();
    final authRepo = context.read<AuthorRepository>();
    final genRepo = context.read<GenreRepository>();
    final bookRepo = context.read<BookRepository>();

    final pubs = await pubRepo.findAll();
    final auths = await authRepo.findAll();
    final gens = await genRepo.findAll();

    Book? existingBook;
    if (widget.isEditing) {
      existingBook = await bookRepo.findById(widget.id!);
      if (existingBook != null) {
        _titleController.text = existingBook.title;
        _isbnController.text = existingBook.isbn;
        _yearController.text = existingBook.year.toString();
        _pagesController.text = existingBook.pages.toString();
        _copiesTotalController.text = existingBook.copiesTotal.toString();
        _copiesAvailableController.text = existingBook.copiesAvailable
            .toString();
        _publisherId = existingBook.publisherId;
        _authorIds = [...existingBook.authorIds];
        _genreIds = [...existingBook.genreIds];
      }
    }

    if (mounted) {
      setState(() {
        _publishers = pubs;
        _authors = auths;
        _genres = gens;
        _isLoading = false;
      });
    }
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Несохранённые изменения'),
        content: const Text(
          'На форме есть несохранённые данные. Вы действительно хотите уйти?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Уйти'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;

    final totalCopies = int.parse(_copiesTotalController.text.trim());
    final availableCopies = int.parse(_copiesAvailableController.text.trim());

    if (availableCopies > totalCopies) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Доступных экземпляров не может быть больше общего количества',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final bookToSave = Book(
      id: widget.id ?? 0,
      title: _titleController.text.trim(),
      isbn: _isbnController.text.trim(),
      year: int.parse(_yearController.text.trim()),
      pages: int.parse(_pagesController.text.trim()),
      publisherId: _publisherId!,
      authorIds: _authorIds,
      genreIds: _genreIds,
      copiesTotal: totalCopies,
      copiesAvailable: availableCopies,
    );

    try {
      final repo = context.read<BookRepository>();
      final bookNotifier = context.read<BookListNotifier>();
      if (widget.isEditing) {
        await repo.update(bookToSave);
      } else {
        await repo.create(bookToSave);
      }
      _isDirty = false;
      await bookNotifier.load();
      if (!mounted) return;
      context.go('/books');
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _serverErrors = e.errors;
        _isSaving = false;
      });
      _formKey.currentState!.validate();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _isbnController.dispose();
    _yearController.dispose();
    _pagesController.dispose();
    _copiesTotalController.dispose();
    _copiesAvailableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.go('/books');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditing ? 'Редактирование книги' : 'Новая книга',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) context.go('/books');
              }
            },
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Название книги *',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([
                        V.required(),
                        V.length(min: 2, max: 200),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _isbnController,
                      decoration: const InputDecoration(
                        labelText: 'ISBN *',
                        border: OutlineInputBorder(),
                        hintText: '978-5-389-06256-6',
                      ),
                      onChanged: (_) {
                        _markDirty();
                        if (_serverErrors.containsKey('isbn')) {
                          setState(() => _serverErrors.remove('isbn'));
                        }
                      },
                      validator: (val) {
                        final local = V.combine([V.required(), V.isbn()])(val);
                        if (local != null) return local;
                        return _serverErrors['isbn'];
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _yearController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Год издания *',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _markDirty(),
                            validator: V.combine([
                              V.required(),
                              V.integer(min: 1450, max: 2100),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _pagesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Страниц *',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _markDirty(),
                            validator: V.combine([
                              V.required(),
                              V.positiveInteger(
                                'Количество страниц должно быть больше 0',
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _publisherId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Издательство (многие к одному) *',
                        border: OutlineInputBorder(),
                      ),
                      items: _publishers
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.name} (${p.city})'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        _markDirty();
                        setState(() => _publisherId = val);
                      },
                      validator: (v) =>
                          v == null ? 'Выберите издательство' : null,
                    ),
                    const SizedBox(height: 16),
                    FormField<List<int>>(
                      initialValue: _authorIds,
                      validator: (val) => (val == null || val.isEmpty)
                          ? 'Выберите хотя бы одного автора'
                          : null,
                      builder: (field) {
                        return InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Авторы (многие ко многим) *',
                            border: const OutlineInputBorder(),
                            errorText: field.errorText,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _authors.map((a) {
                              final selected = field.value!.contains(a.id);
                              return FilterChip(
                                label: Text(a.fullName),
                                selected: selected,
                                onSelected: (isSelected) {
                                  _markDirty();
                                  final next = [...field.value!];
                                  isSelected
                                      ? next.add(a.id)
                                      : next.remove(a.id);
                                  field.didChange(next);
                                  setState(() => _authorIds = next);
                                },
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    FormField<List<int>>(
                      initialValue: _genreIds,
                      validator: (val) => (val == null || val.isEmpty)
                          ? 'Выберите хотя бы один жанр'
                          : null,
                      builder: (field) {
                        return InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Жанры (многие ко многим) *',
                            border: const OutlineInputBorder(),
                            errorText: field.errorText,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _genres.map((g) {
                              final selected = field.value!.contains(g.id);
                              return FilterChip(
                                label: Text(g.name),
                                selected: selected,
                                onSelected: (isSelected) {
                                  _markDirty();
                                  final next = [...field.value!];
                                  isSelected
                                      ? next.add(g.id)
                                      : next.remove(g.id);
                                  field.didChange(next);
                                  setState(() => _genreIds = next);
                                },
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _copiesTotalController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Всего экземпляров *',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _markDirty(),
                            validator: V.combine([
                              V.required(),
                              V.integer(min: 0),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _copiesAvailableController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'В наличии *',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => _markDirty(),
                            validator: V.combine([
                              V.required(),
                              V.integer(min: 0),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        widget.isEditing
                            ? 'Сохранить изменения'
                            : 'Создать книгу',
                      ),
                      onPressed: _isSaving ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
