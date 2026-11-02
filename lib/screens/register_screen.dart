import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/api_exceptions.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();

  Role _selectedRole = Role.reader;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _hasMinLen => _passwordController.text.length >= 8;
  bool get _hasDigit => RegExp(r'\d').hasMatch(_passwordController.text);
  bool get _hasSpecial =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_passwordController.text);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasMinLen || !_hasDigit || !_hasSpecial) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context.read<AuthNotifier>().register(
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
      );
      if (mounted) context.go('/books');
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Ошибка регистрации');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Регистрация пользователя',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.red.shade50,
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Логин *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().length < 3
                          ? 'Минимум 3 символа'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'ФИО *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().length < 2
                          ? 'Введите ФИО'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Role>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Роль для демонстрации *',
                        border: OutlineInputBorder(),
                      ),
                      items: Role.values
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.title),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedRole = v ?? Role.reader),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Пароль *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          !_hasMinLen || !_hasDigit || !_hasSpecial
                          ? 'Пароль не отвечает требованиям'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    // Визуальные индикаторы надежности пароля в реальном времени
                    Row(
                      children: [
                        Icon(
                          _hasMinLen
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 16,
                          color: _hasMinLen ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Длина не менее 8 символов',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          _hasDigit
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 16,
                          color: _hasDigit ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Минимум 1 цифра',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          _hasSpecial
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 16,
                          color: _hasSpecial ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Минимум 1 специальный символ (!@#\$%^&*)',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: const Text('Зарегистрироваться'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Уже есть аккаунт? Войти'),
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
