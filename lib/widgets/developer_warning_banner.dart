import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../config/developer_mode.dart';

/// Warnung-Banner das angezeigt wird wenn der Entwicklermodus aktiv ist
class DeveloperWarningBanner extends StatelessWidget {
  const DeveloperWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!DeveloperMode.showDeveloperWarnings) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.red.shade600,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(
            Icons.warning,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '🛠️ ENTWICKLERMODUS - NICHT FÜR PRODUKTION VERWENDEN!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white, size: 20),
            onPressed: () => _showDeveloperInfo(context),
            tooltip: 'Entwickler-Informationen anzeigen',
          ),
        ],
      ),
    );
  }

  void _showDeveloperInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DeveloperInfoDialog(),
    );
  }
}

/// Dialog mit detaillierten Entwickler-Informationen
class DeveloperInfoDialog extends StatelessWidget {
  const DeveloperInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final checks = ProductionReadinessChecker.getSecurityChecklist();

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.developer_mode, color: Colors.orange),
          SizedBox(width: 8),
          Text('Entwicklermodus'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DeveloperMode.developmentInfo,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sicherheits-Checkliste für Release:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...checks.map((check) => _buildCheckItem(check)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ProductionReadinessChecker.isProductionReady()
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  border: Border.all(
                    color: ProductionReadinessChecker.isProductionReady()
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ProductionReadinessChecker.getReadinessReport(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ProductionReadinessChecker.isProductionReady()
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schließen'),
        ),
      ],
    );
  }

  Widget _buildCheckItem(SecurityCheckItem check) {
    Color color;
    IconData icon;

    if (!check.isCompliant) {
      switch (check.level) {
        case SecurityLevel.critical:
          color = Colors.red;
          icon = Icons.error;
          break;
        case SecurityLevel.important:
          color = Colors.orange;
          icon = Icons.warning;
          break;
        case SecurityLevel.recommended:
          color = Colors.blue;
          icon = Icons.info;
          break;
      }
    } else {
      color = Colors.green;
      icon = Icons.check_circle;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: check.isCompliant ? Colors.green.shade800 : color,
                  ),
                ),
                if (!check.isCompliant) ...[
                  Text(
                    check.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Startup-Warning Dialog das beim App-Start angezeigt wird
class DeveloperModeStartupWarning extends StatelessWidget {
  final VoidCallback onContinue;

  const DeveloperModeStartupWarning({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    if (!DeveloperMode.showDeveloperWarnings) {
      // Wenn nicht im Entwicklermodus, sofort weiter
      WidgetsBinding.instance.addPostFrameCallback((_) => onContinue());
      return const SizedBox.shrink();
    }

    // Im Debug-Modus für Tests automatisch weiterleiten nach kurzer Verzögerung
    if (DeveloperMode.isActive && kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          onContinue();
        });
      });
      return const SizedBox.shrink();
    }

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Entwicklermodus aktiv',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diese App läuft im Entwicklermodus mit reduzierten Sicherheitsfeatures.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text('⚠️  Keychain-Verschlüsselung ist deaktiviert'),
          Text('⚠️  Debug-Logs sind aktiviert'),
          Text('⚠️  Erweiterte Datei-Zugriffe sind erlaubt'),
          SizedBox(height: 16),
          Text(
            'WICHTIG: Vor Veröffentlichung muss der Entwicklermodus deaktiviert werden!',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onContinue();
          },
          child: const Text('Verstanden, weiter'),
        ),
      ],
    );
  }
}