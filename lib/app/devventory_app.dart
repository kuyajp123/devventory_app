import 'dart:async';

import 'package:flutter/material.dart';
import 'package:devventory_app/app/app_theme.dart';
import 'package:devventory_app/features/auth/index.dart';
import 'package:devventory_app/features/workspace/index.dart';
import 'package:devventory_app/shared/presentation/companion_layout.dart';
import 'package:devventory_app/shared/presentation/soft_card.dart';
import 'package:devventory_app/shared/presentation/venty_mascot.dart';

class DevventoryApp extends StatefulWidget {
  const DevventoryApp({
    super.key,
    required this.auth,
    required this.workspaces,
    this.textScaler,
  });
  final AuthRepository auth;
  final WorkspaceRepository workspaces;
  final TextScaler? textScaler;
  @override
  State<DevventoryApp> createState() => _DevventoryAppState();
}

class _DevventoryAppState extends State<DevventoryApp>
    with WidgetsBindingObserver {
  late final _auth = AuthController(widget.auth);
  int _refreshSignal = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _auth.session != null) {
      unawaited(_resume());
    }
  }

  Future<void> _resume() async {
    await _auth.refreshSession();
    if (mounted) setState(() => _refreshSignal++);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Devventory Mobile',
    debugShowCheckedModeBanner: false,
    theme: companionTheme(),
    builder: widget.textScaler == null
        ? null
        : (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: widget.textScaler),
            child: child!,
          ),
    home: ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        if (_auth.restoring || _auth.signingOut) {
          return CompanionLayout(
            child: SoftCard(
              child: Column(
                children: [
                  const VentyMascot(),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    _auth.signingOut
                        ? 'Signing out…'
                        : 'Restoring your session…',
                  ),
                ],
              ),
            ),
          );
        }
        if (_auth.session == null) return SignInPage(controller: _auth);
        if (_auth.needsVerification) return VerificationPage(controller: _auth);
        return WorkspacePage(
          key: ValueKey(_auth.session!.uid),
          repository: widget.workspaces,
          email: _auth.session!.email,
          onSignOut: _auth.busy ? null : _auth.signOut,
          onVerificationRequired: _auth.requireVerification,
          refreshSignal: _refreshSignal,
          sessionError: _auth.error,
        );
      },
    ),
  );
}
