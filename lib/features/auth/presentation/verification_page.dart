import 'package:flutter/material.dart';
import 'package:devventory_app/features/auth/auth_controller.dart';
import 'package:devventory_app/shared/presentation/companion_layout.dart';
import 'package:devventory_app/shared/presentation/companion_hero.dart';
import 'package:devventory_app/shared/presentation/soft_card.dart';

class VerificationPage extends StatelessWidget {
  const VerificationPage({super.key, required this.controller});
  final AuthController controller;
  @override
  Widget build(BuildContext context) => CompanionLayout(
    trailing: TextButton(
      onPressed: controller.busy ? null : controller.signOut,
      child: const Text('Sign out'),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CompanionHero(
          eyebrow: 'ONE LAST STEP',
          title: 'Verify your email',
          message: 'Let’s make sure it’s you before connecting your private workspace.',
          icon: Icons.mark_email_unread_rounded,
        ),
        const SizedBox(height: 28),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Check your inbox',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Open the verification link sent to ${controller.session?.email ?? 'your email address'}. Then come back here to continue.',
              ),
              const SizedBox(height: 24),
              ActionButton(
                label: "I've verified my email",
                busy: controller.busy,
                onPressed: controller.refreshSession,
                icon: Icons.check_circle_rounded,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: controller.busy
                    ? null
                    : controller.resendVerification,
                child: const Text('Resend verification email'),
              ),
              if (controller.error != null)
                StatusNotice(controller.error!, isError: true),
              if (controller.notice != null) StatusNotice(controller.notice!),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Can’t find the email? Check your spam folder or request another link. '
          'Verification does not create or replace a desktop workspace.',
        ),
      ],
    ),
  );
}
