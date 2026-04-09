import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/recovery_service.dart';
import '../../services/web_auth_service.dart';
import '../../services/audit_logger.dart';

/// Screen zum Generieren und Einloesen von Recovery-Tokens.
class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Generieren-Tab
  final _employeeIdController = TextEditingController();
  String? _generatedToken;
  String? _generatedPin;
  bool _isGenerating = false;

  // Einloesen-Tab
  final _tokenController = TextEditingController();
  final _pinController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isRecovering = false;
  String? _recoveryError;
  bool _recoverySuccess = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _employeeIdController.dispose();
    _tokenController.dispose();
    _pinController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _generateRecoveryToken() async {
    if (_employeeIdController.text.trim().isEmpty) return;
    setState(() => _isGenerating = true);
    try {
      final pin = List.generate(6, (_) => (DateTime.now().microsecond % 10)).join();
      final token = await RecoveryService.generateRecoveryToken(
        employeeId: _employeeIdController.text.trim(),
        pin: pin,
      );
      setState(() {
        _generatedToken = token;
        _generatedPin = pin;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _recoverPassword() async {
    if (_tokenController.text.trim().isEmpty ||
        _pinController.text.trim().isEmpty ||
        _newPasswordController.text.isEmpty) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _recoveryError = 'Passwoerter stimmen nicht ueberein');
      return;
    }

    setState(() { _isRecovering = true; _recoveryError = null; });
    try {
      final payload = await RecoveryService.decryptRecoveryToken(
        _tokenController.text.trim(),
        _pinController.text.trim(),
      );
      if (payload == null) {
        setState(() {
          _recoveryError = 'Ungueltiger Token oder PIN, oder Token abgelaufen';
          _isRecovering = false;
        });
        return;
      }

      // Token gueltig -- Passwort zuruecksetzen
      final authService = WebAuthService();
      final success = await authService.setPassword(_newPasswordController.text);
      if (success) {
        await AuditLogger.instance.logRecoveryUsed(payload['employeeId'] ?? 'unknown');
      }
      setState(() {
        _recoverySuccess = success;
        _recoveryError = success ? null : 'Passwort konnte nicht gesetzt werden';
        _isRecovering = false;
      });
    } catch (e) {
      setState(() { _recoveryError = 'Fehler: $e'; _isRecovering = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passwort-Recovery'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.key), text: 'Token erstellen'),
            Tab(icon: Icon(Icons.lock_open), text: 'Passwort zuruecksetzen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGenerateTab(theme),
          _buildRecoverTab(theme),
        ],
      ),
    );
  }

  Widget _buildGenerateTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recovery-Token generieren',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Erstellen Sie einen Recovery-Token fuer einen Mitarbeiter der sein Passwort vergessen hat. '
            'Der Token ist 24 Stunden gueltig.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _employeeIdController,
            decoration: const InputDecoration(
              labelText: 'Mitarbeiter-ID oder E-Mail',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isGenerating ? null : _generateRecoveryToken,
              icon: _isGenerating
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.key),
              label: Text(_isGenerating ? 'Generiere...' : 'Token generieren'),
            ),
          ),
          if (_generatedToken != null && _generatedPin != null) ...[
            const SizedBox(height: 24),
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 8),
                    Text('Recovery-Token erstellt!',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.key, color: theme.colorScheme.onErrorContainer),
                          const SizedBox(width: 8),
                          Text('PIN: $_generatedPin',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onErrorContainer,
                              letterSpacing: 4,
                            )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('PIN muendlich oder per SMS weitergeben',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _generatedToken!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Token kopiert')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Token kopieren'),
                    ),
                    const SizedBox(height: 8),
                    Text('Gueltig fuer 24 Stunden',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecoverTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Passwort zuruecksetzen',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Geben Sie den Recovery-Token und PIN ein um ein neues Passwort zu setzen.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'Recovery-Token',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.key),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            decoration: const InputDecoration(
              labelText: 'PIN (6-stellig)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.pin),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newPasswordController,
            decoration: const InputDecoration(
              labelText: 'Neues Passwort',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(
              labelText: 'Passwort bestaetigen',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
          ),
          if (_recoveryError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_recoveryError!, style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_recoverySuccess)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 32),
                  SizedBox(width: 12),
                  Expanded(child: Text('Passwort erfolgreich zurueckgesetzt! Sie koennen sich jetzt mit dem neuen Passwort anmelden.')),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isRecovering ? null : _recoverPassword,
                icon: _isRecovering
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.lock_open),
                label: Text(_isRecovering ? 'Pruefe...' : 'Passwort zuruecksetzen'),
              ),
            ),
        ],
      ),
    );
  }
}
