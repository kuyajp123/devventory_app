import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:devventory_app/features/auth/auth_controller.dart';
import 'package:devventory_app/features/auth/email_validation.dart';
import 'package:devventory_app/features/auth/presentation/reset_password_dialog.dart';
import 'package:devventory_app/shared/presentation/companion_layout.dart';
import 'package:devventory_app/shared/presentation/companion_hero.dart';
import 'package:devventory_app/shared/presentation/soft_card.dart';

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
          const CompanionHero(
            eyebrow: 'DESKTOP COMPANION',
            title: 'Your workspace.\nWithin reach.',
            message: 'A little closer to everything you’re building.',
          ),
          const SizedBox(height: 28),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Welcome back', style: text.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Sign in with the account you use for Cloud Sync on Devventory desktop.',
                ),
                const SizedBox(height: 28),
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
                            hintText: 'you@example.com',
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                              size: 20,
                            ),
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
                            hintText: 'Your desktop password',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              tooltip: _obscure
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ActionButton(
                          label: 'Sign in',
                          busy: auth.busy,
                          onPressed: _submit,
                          icon: Icons.arrow_forward_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
                if (auth.error != null)
                  StatusNotice(auth.error!, isError: true),
                if (auth.notice != null) StatusNotice(auth.notice!),
                const SizedBox(height: 12),
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
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'New to Devventory?',
            style: text.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your account and set up Cloud Sync in the desktop app first. '
            'Your files and secrets stay on your computer.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
