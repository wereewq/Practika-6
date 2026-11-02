import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/publisher.dart';
import '../repositories/publisher_repository.dart';
import '../state/publisher_list_notifier.dart';

class PublisherFormScreen extends StatefulWidget {
  final int? id;

  const PublisherFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<PublisherFormScreen> createState() => _PublisherFormScreenState();
}

class _PublisherFormScreenState extends State<PublisherFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _websiteController;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _cityController = TextEditingController();
    _websiteController = TextEditingController();
    _loadPublisher();
  }

  Future<void> _loadPublisher() async {
    if (widget.isEditing) {
      final repo = context.read<PublisherRepository>();
      final publisher = await repo.findById(widget.id!);
      if (publisher != null) {
        _nameController.text = publisher.name;
        _cityController.text = publisher.city;
        _websiteController.text = publisher.website;
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
        content: const Text('Данные издательства не сохранены. Выйти?'),
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

    final pub = Publisher(
      id: widget.id ?? 0,
      name: _nameController.text.trim(),
      city: _cityController.text.trim(),
      website: _websiteController.text.trim(),
    );

    try {
      final repo = context.read<PublisherRepository>();
      final pubNotifier = context.read<PublisherListNotifier>();
      if (widget.isEditing) {
        await repo.update(pub);
      } else {
        await repo.create(pub);
      }
      _isDirty = false;
      await pubNotifier.load();
      if (!mounted) return;
      context.go('/publishers');
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
    _nameController.dispose();
    _cityController.dispose();
    _websiteController.dispose();
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
          context.go('/publishers');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditing
                ? 'Редактирование издательства'
                : 'Новое издательство',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) context.go('/publishers');
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
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название издательства *',
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
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'Город *',
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
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Веб-сайт *',
                        border: OutlineInputBorder(),
                        hintText: 'https://example.com',
                      ),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([
                        V.required(),
                        V.length(min: 4, max: 150),
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
                            : 'Создать издательство',
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
