import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:devventory_app/features/auth/auth_controller.dart';
import 'package:devventory_app/features/auth/email_validation.dart';
import 'package:devventory_app/features/auth/presentation/reset_password_dialog.dart';
import 'package:devventory_app/shared/presentation/companion_layout.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.controller});
  final AuthController controller;
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  Future<void> _submit() async {
    if (widget.controller.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await widget.controller.signIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    _password.clear();
    if (widget.controller.session != null) TextInput.finishAutofillContext();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.controller;
    final text = Theme.of(context).textTheme;
    return CompanionLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'DESKTOP COMPANION',
            style: text.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Text('Your workspace.\nWithin reach.', style: text.headlineLarge),
          const SizedBox(height: 16),
          Text(
            'Sign in with the account you use for Cloud Sync on Devventory desktop.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 32),
          AutofillGroup(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('email'),
                    controller: _email,
                    enabled: !auth.busy,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const Key('password'),
                    controller: _password,
                    enabled: !auth.busy,
                    obscureText: _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your password.'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ActionButton(
                    label: 'Sign in',
                    busy: auth.busy,
                    onPressed: _submit,
                    icon: Icons.arrow_forward,
                  ),
                ],
              ),
            ),
          ),
          if (auth.error != null) StatusNotice(auth.error!, isError: true),
          if (auth.notice != null) StatusNotice(auth.notice!),
          const SizedBox(height: 8),
          TextButton(
            onPressed: auth.busy
                ? null
                : () => showDialog<void>(
                    context: context,
                    builder: (_) => ResetPasswordDialog(
                      controller: auth,
                      email: _email.text.trim(),
                    ),
                  ),
            child: const Text('Forgot password?'),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text('New to Devventory?', style: text.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Create your account and set up Cloud Sync in the desktop app first. '
            'Your files and secrets stay on your computer.',
          ),
        ],
      ),
    );
  }
}
