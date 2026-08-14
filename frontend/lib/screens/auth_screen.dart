import 'package:cardwise_ai/providers/app_providers.dart';
import 'package:cardwise_ai/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: LoadingOverlay(
        visible: auth.loading,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'CardWise',
                    style: Theme.of(context).textTheme.headlineLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ask before you pay. Track what CardWise helped you earn.',
                  ),
                  const SizedBox(height: 28),
                  if (_register) ...[
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 16),
                  if (auth.error != null)
                    Text(
                      auth.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  FilledButton(
                    onPressed: auth.loading
                        ? null
                        : () => auth.submit(
                            email: _email.text,
                            password: _password.text,
                            name: _name.text,
                            register: _register,
                          ),
                    child: Text(_register ? 'Create account' : 'Sign in'),
                  ),
                  TextButton(
                    style: ButtonStyle(
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      foregroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.pressed) ||
                            states.contains(WidgetState.hovered)) {
                          return Theme.of(context).colorScheme.primary;
                        }
                        return Colors.white70;
                      }),
                      textStyle: WidgetStateProperty.resolveWith((states) {
                        return TextStyle(
                          decoration:
                              states.contains(WidgetState.pressed) ||
                                  states.contains(WidgetState.hovered)
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        );
                      }),
                    ),
                    onPressed: auth.loading
                        ? null
                        : () => setState(() => _register = !_register),
                    child: Text(
                      _register
                          ? 'I already have an account'
                          : 'Create a new account',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
