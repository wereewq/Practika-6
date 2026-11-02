import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/library_card.dart';
import '../models/reader.dart';
import '../repositories/reader_repository.dart';
import '../state/reader_list_notifier.dart';

class ReaderFormScreen extends StatefulWidget {
  final int? id;

  const ReaderFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<ReaderFormScreen> createState() => _ReaderFormScreenState();
}

class _ReaderFormScreenState extends State<ReaderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  late final TextEditingController _cardNumberController;
  bool _isCardActive = true;
  DateTime _cardIssuedAt = DateTime.now();
  DateTime _cardExpiresAt = DateTime.now().add(const Duration(days: 365));

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;
  Map<String, String> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _cardNumberController = TextEditingController(
      text: 'CARD-${DateTime.now().millisecondsSinceEpoch % 10000}',
    );

    _loadReader();
  }

  Future<void> _loadReader() async {
    if (widget.isEditing) {
      final repo = context.read<ReaderRepository>();
      final reader = await repo.findById(widget.id!);
      if (reader != null) {
        _fullNameController.text = reader.fullName;
        _emailController.text = reader.email;
        _phoneController.text = reader.phone;
        _cardNumberController.text = reader.card.cardNumber;
        _isCardActive = reader.card.isActive;
        _cardIssuedAt = reader.card.issuedAt;
        _cardExpiresAt = reader.card.expiresAt;
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
        content: const Text('Данные читателя не сохранены. Выйти?'),
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
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final card = LibraryCard(
      cardNumber: _cardNumberController.text.trim(),
      issuedAt: _cardIssuedAt,
      expiresAt: _cardExpiresAt,
      isActive: _isCardActive,
    );

    final reader = Reader(
      id: widget.id ?? 0,
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      card: card,
    );

    try {
      final repo = context.read<ReaderRepository>();
      final readerNotifier = context.read<ReaderListNotifier>();
      if (widget.isEditing) {
        await repo.update(reader);
      } else {
        await repo.create(reader);
      }
      _isDirty = false;
      await readerNotifier.load();
      if (!mounted) return;
      context.go('/readers');
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
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
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
          context.go('/readers');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditing ? 'Редактирование читателя' : 'Новый читатель',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) context.go('/readers');
              }
            },
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Персональные данные',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'ФИО читателя *',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([
                        V.required(),
                        V.length(min: 3, max: 150),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        _markDirty();
                        if (_serverErrors.containsKey('email')) {
                          setState(() => _serverErrors.remove('email'));
                        }
                      },
                      validator: (val) {
                        final local = V.combine([V.required(), V.email()])(val);
                        if (local != null) return local;
                        return _serverErrors['email'];
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Телефон *',
                        border: OutlineInputBorder(),
                        hintText: '+79991234567',
                      ),
                      onChanged: (_) => _markDirty(),
                      validator: V.combine([V.required(), V.phone()]),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.badge_outlined),
                                const SizedBox(width: 8),
                                Text(
                                  'Читательский билет (связь 1-к-1)',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            TextFormField(
                              controller: _cardNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Номер читательского билета *',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => _markDirty(),
                              validator: V.combine([
                                V.required(),
                                V.length(min: 4, max: 30),
                              ]),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              title: const Text('Статус билета активен'),
                              subtitle: Text(
                                _isCardActive
                                    ? 'Действителен'
                                    : 'Заблокирован / Приостановлен',
                              ),
                              value: _isCardActive,
                              onChanged: (val) {
                                _markDirty();
                                setState(() => _isCardActive = val);
                              },
                            ),
                          ],
                        ),
                      ),
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
                            : 'Зарегистрировать читателя',
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
