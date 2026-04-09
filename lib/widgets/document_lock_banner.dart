import 'package:flutter/material.dart';
import '../services/document_lock_service.dart';

/// Banner das angezeigt wird wenn ein Dokument von einem anderen User bearbeitet wird.
class DocumentLockBanner extends StatelessWidget {
  final DocumentLock lock;
  final VoidCallback? onForceEdit;
  final VoidCallback? onReadOnly;

  const DocumentLockBanner({
    super.key,
    required this.lock,
    this.onForceEdit,
    this.onReadOnly,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = lock.activeSince.inMinutes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_clock, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dokument wird bearbeitet',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${lock.user} bearbeitet dieses Dokument seit $minutes Minuten (${lock.device}).',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              if (onReadOnly != null)
                OutlinedButton.icon(
                  onPressed: onReadOnly,
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Nur lesen'),
                ),
              if (onForceEdit != null)
                TextButton.icon(
                  onPressed: onForceEdit,
                  icon: const Icon(Icons.edit, size: 16, color: Colors.red),
                  label: const Text('Trotzdem bearbeiten',
                      style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Wrapper der automatisch Lock prueft und Banner anzeigt.
class DocumentLockGuard extends StatefulWidget {
  final DocumentLockService lockService;
  final String documentPath;
  final Widget child;
  final Widget Function(BuildContext, bool isReadOnly)? builder;

  const DocumentLockGuard({
    super.key,
    required this.lockService,
    required this.documentPath,
    required this.child,
    this.builder,
  });

  @override
  State<DocumentLockGuard> createState() => _DocumentLockGuardState();
}

class _DocumentLockGuardState extends State<DocumentLockGuard> {
  DocumentLock? _activeLock;
  bool _isReadOnly = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  @override
  void dispose() {
    // Lock freigeben wenn wir bearbeitet haben
    if (!_isReadOnly && _activeLock == null) {
      widget.lockService.releaseLock(widget.documentPath);
    }
    super.dispose();
  }

  Future<void> _checkLock() async {
    final lock = await widget.lockService.checkLock(widget.documentPath);
    if (mounted) {
      setState(() {
        _activeLock = lock;
        _isChecking = false;
      });
      // Wenn kein Lock vorhanden, selbst locken
      if (lock == null) {
        await widget.lockService.acquireLock(widget.documentPath);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_activeLock != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: DocumentLockBanner(
              lock: _activeLock!,
              onReadOnly: () => setState(() => _isReadOnly = true),
              onForceEdit: () async {
                await widget.lockService.acquireLock(widget.documentPath);
                setState(() { _activeLock = null; _isReadOnly = false; });
              },
            ),
          ),
        Expanded(
          child: widget.builder != null
              ? widget.builder!(context, _isReadOnly || _activeLock != null)
              : AbsorbPointer(
                  absorbing: _isReadOnly,
                  child: widget.child,
                ),
        ),
      ],
    );
  }
}
