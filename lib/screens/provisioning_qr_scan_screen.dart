import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Minimaler Scanner-Screen fuer Provisioning-QR-Codes.
///
/// Gibt den gescannten Rohstring via [Navigator.pop] zurueck. Die
/// Entschluesselung + Anwendung passiert im aufrufenden Screen
/// (Setup-Wizard), damit dieser Scanner auch fuer andere QR-Flows
/// wiederverwendbar bleibt.
class ProvisioningQrScanScreen extends StatefulWidget {
  const ProvisioningQrScanScreen({super.key});

  @override
  State<ProvisioningQrScanScreen> createState() =>
      _ProvisioningQrScanScreenState();
}

class _ProvisioningQrScanScreenState extends State<ProvisioningQrScanScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einladungscode scannen')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_handled) return;
              final raw = capture.barcodes.isEmpty
                  ? null
                  : capture.barcodes.first.rawValue;
              if (raw == null || raw.isEmpty) return;
              _handled = true;
              Navigator.of(context).pop<String>(raw);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Scanne den Einladungs-QR aus der FEGH-Verwaltung oder aus einer Doku-Admin-Instanz',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
