import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../providers/app_provider.dart';

class TeamKeyQrScanScreen extends StatefulWidget {
  const TeamKeyQrScanScreen({super.key});

  @override
  State<TeamKeyQrScanScreen> createState() => _TeamKeyQrScanScreenState();
}

class _TeamKeyQrScanScreenState extends State<TeamKeyQrScanScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team‑Key scannen')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              if (_handled) return;
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final raw = barcodes.first.rawValue;
              if (raw == null) return;
              _handled = true;
              await _applyQrPayload(context, raw);
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
                  'Scanne den Team‑Key QR‑Code aus der Personalverwaltung',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyQrPayload(BuildContext context, String payload) async {
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      if (map['type'] != 'egh-team-key') {
        throw Exception('Ungültiger QR‑Typ');
      }
      final keyB64 = map['key'] as String?;
      if (keyB64 == null) throw Exception('Key fehlt');
      final key = base64Decode(keyB64);
      if (key.length != 32) throw Exception('Ungültiger Key');

      final app = Provider.of<AppProvider>(context, listen: false);
      app.secureStorageService.cryptoStorage.setExternalMEK(key);

      // Optionale Felder: org, team, role, teams
      try {
        final org = (map['org'] as String?)?.trim();
        final team = (map['team'] as String?)?.trim();
        final role = (map['role'] as String?)?.trim().toLowerCase();
        final teams = (map['teams'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
        var settings = await app.secureStorageService.loadSettings();
        UserRole? parsedRole;
        if (role != null) {
          switch (role) {
            case 'org_admin': parsedRole = UserRole.orgAdmin; break;
            case 'pv_admin': parsedRole = UserRole.pvAdmin; break;
            case 'team_lead': parsedRole = UserRole.teamLead; break;
            case 'org_auditor': parsedRole = UserRole.orgAuditor; break;
            default: parsedRole = UserRole.teamMember;
          }
        }
        String teamId = settings.teamId;
        if (team != null && team.isNotEmpty) {
          teamId = team;
        } else if (teamId.isEmpty && teams.isNotEmpty) {
          teamId = teams.first;
        }
        final orgId = (org != null && org.isNotEmpty) ? org : settings.organizationId;
        final updated = settings.copyWith(
          organizationId: orgId,
          teamId: teamId,
          userRole: parsedRole,
        );
        await app.secureStorageService.saveSettings(updated);
      } catch (e) { if (kDebugMode) debugPrint("Fehler: $e"); }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Team‑Key angewendet. Jetzt synchronisieren.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ QR‑Fehler: $e'), backgroundColor: Colors.red),
      );
      Navigator.pop(context);
    }
  }
}
