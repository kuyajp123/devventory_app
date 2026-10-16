import 'package:flutter/material.dart';
import 'package:devventory_app/shared/cache/metadata_cache.dart';
import 'package:devventory_app/shared/presentation/companion_layout.dart';
import 'package:devventory_app/shared/presentation/soft_card.dart';

/// Mounted above all account routes, including the signed-out screen.
class CacheIdentityGate extends StatefulWidget {
  const CacheIdentityGate({
    super.key,
    required this.uid,
    required this.cache,
    required this.builder,
  });
  final String? uid;
  final MetadataCache cache;
  final Widget Function(CacheAccount?) builder;
  @override
  State<CacheIdentityGate> createState() => _CacheIdentityGateState();
}

class _CacheIdentityGateState extends State<CacheIdentityGate> {
  late Future<CacheAccount?> _account = widget.cache.activate(widget.uid);
  @override
  Widget build(BuildContext context) => FutureBuilder<CacheAccount?>(
    future: _account,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError &&
          (widget.uid == null || (snapshot.data?.valid ?? false))) {
        return widget.builder(snapshot.data);
      }
      final failed = snapshot.hasError;
      return CompanionLayout(
        child: SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                failed
                    ? 'Offline storage needs attention'
                    : 'Preparing private offline storage…',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              if (!failed)
                const Center(child: CircularProgressIndicator())
              else ...[
                const Text(
                  'The private metadata cache could not be prepared. Check available device storage and try again. Your previous account’s data will not be shown.',
                ),
                const SizedBox(height: 24),
                ActionButton(
                  label: 'Retry offline storage',
                  onPressed: () => setState(
                    () => _account = widget.cache.activate(widget.uid),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
