import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/author.dart';
import '../repositories/author_repository.dart';
import '../state/author_list_notifier.dart';

class AuthorFormScreen extends StatefulWidget {
  final int? id;

  const AuthorFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<AuthorFormScreen> createState() => _AuthorFormScreenState();
}

class _AuthorFormScreenState extends State<AuthorFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _countryController;
  late final TextEditingController _birthYearController;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _countryController = TextEditingController();
    _birthYearController = TextEditingController();

    _loadAuthor();
  }

  Future<void> _loadAuthor() async {
    if (widget.isEditing) {
      final repo = context.read<AuthorRepository>();
      final author = await repo.findById(widget.id!);
      if (author != null) {
        _firstNameController.text = author.firstName;
        _lastNameController.text = author.lastName;
        _countryController.text = author.country;
        _birthYearController.text = author.birthYear.toString();
      }
    }
    if (mounted) setState(() => _isLoading = false);
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
          'Данные автора не сохранены. Выйти без сохранения?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final author = Author(
      id: widget.id ?? 0,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      country: _countryController.text.trim(),
      birthYear: int.parse(_birthYearController.text.trim()),
    );

    try {
      final repo = context.read<AuthorRepository>();
      final authNotifier = context.read<AuthorListNotifier>();
      if (widget.isEditing) {
        await repo.update(author);
      } else {
        await repo.create(author);
      }
      _isDirty = false;
      await authNotifier.load();
      if (!mounted) return;
      context.go('/authors');
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _countryController.dispose();
    _birthYearController.dispose();
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
          context.go('/authors');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditing ? 'Редактирование автора' : 'Новый автор',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) context.go('/authors');
              }
            },
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Фамилия *',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([
                        V.required(),
                        V.length(min: 2, max: 100),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Имя *',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([
                        V.required(),
                        V.length(min: 2, max: 100),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Страна *',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([
                        V.required(),
                        V.length(min: 2, max: 100),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _birthYearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Год рождения *',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([
                        V.required(),
                        V.integer(min: 500, max: DateTime.now().year),
                      ]),
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
                            : 'Создать автора',
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
