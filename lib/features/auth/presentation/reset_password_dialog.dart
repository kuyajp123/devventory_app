import 'package:flutter/material.dart';
import 'package:devventory_app/features/auth/auth_controller.dart';
import 'package:devventory_app/features/auth/email_validation.dart';
import 'package:devventory_app/shared/presentation/companion_layout.dart';

class ResetPasswordDialog extends StatefulWidget {
  const ResetPasswordDialog({
    super.key,
    required this.controller,
    required this.email,
  });
  final AuthController controller;
  final String email;
  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  bool _sent = false;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final auth = widget.controller;
      return PopScope(
        canPop: !auth.busy,
        child: AlertDialog(
          scrollable: true,
          title: const Text('Reset your password'),
          content: _sent
              ? const Text(
                  'If an account exists for that email, a password reset link has been sent. '
                  'Check your inbox and spam folder.',
                )
              : Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'We’ll send you a link to choose a new password.',
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const Key('reset-email'),
                        controller: _email,
                        enabled: !auth.busy,
                        validator: validateEmail,
                        autofocus: true,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                        ),
                      ),
                      if (auth.error != null)
                        StatusNotice(auth.error!, isError: true),
                    ],
                  ),
                ),
          actions: [
            TextButton(
              onPressed: auth.busy ? null : () => Navigator.of(context).pop(),
              child: Text(_sent ? 'Done' : 'Cancel'),
            ),
            if (!_sent)
              FilledButton(
                onPressed: auth.busy
                    ? null
                    : () async {
                        if (!_form.currentState!.validate()) return;
                        await auth.resetPassword(_email.text.trim());
                        if (mounted && auth.error == null) {
                          setState(() => _sent = true);
                        }
                      },
                child: Text(auth.busy ? 'Sending…' : 'Send reset link'),
              ),
          ],
        ),
      );
    },
  );
}
