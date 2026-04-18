import 'package:fegh_billing/fegh_billing.dart';
import 'package:flutter/material.dart';
import '../../services/rechnung_service.dart';

/// Editor fuer einen Rechnungsempfaenger (Kostentraeger) mit Leitweg-ID.
class EmpfaengerEditorScreen extends StatefulWidget {
  final RechnungEmpfaenger? existing;

  const EmpfaengerEditorScreen({super.key, this.existing});

  @override
  State<EmpfaengerEditorScreen> createState() => _EmpfaengerEditorScreenState();
}

class _EmpfaengerEditorScreenState extends State<EmpfaengerEditorScreen> {
  final _service = RechnungService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _abteilung;
  late TextEditingController _leitwegId;
  late TextEditingController _strasse;
  late TextEditingController _plz;
  late TextEditingController _ort;
  late TextEditingController _land;
  late TextEditingController _ansprechpartner;
  late TextEditingController _email;
  late TextEditingController _telefon;
  late TextEditingController _ustId;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _abteilung = TextEditingController(text: e?.abteilung ?? '');
    _leitwegId = TextEditingController(text: e?.leitwegId ?? '');
    _strasse = TextEditingController(text: e?.strasse ?? '');
    _plz = TextEditingController(text: e?.plz ?? '');
    _ort = TextEditingController(text: e?.ort ?? '');
    _land = TextEditingController(text: e?.land ?? 'DE');
    _ansprechpartner = TextEditingController(text: e?.ansprechpartner ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _telefon = TextEditingController(text: e?.telefon ?? '');
    _ustId = TextEditingController(text: e?.umsatzsteuerId ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _abteilung.dispose();
    _leitwegId.dispose();
    _strasse.dispose();
    _plz.dispose();
    _ort.dispose();
    _land.dispose();
    _ansprechpartner.dispose();
    _email.dispose();
    _telefon.dispose();
    _ustId.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final e = _isEdit
        ? widget.existing!.copyWith(
            name: _name.text.trim(),
            abteilung: _abteilung.text.trim().isEmpty ? null : _abteilung.text.trim(),
            leitwegId: _leitwegId.text.trim(),
            strasse: _strasse.text.trim(),
            plz: _plz.text.trim(),
            ort: _ort.text.trim(),
            land: _land.text.trim().isEmpty ? 'DE' : _land.text.trim(),
            ansprechpartner: _ansprechpartner.text.trim().isEmpty ? null : _ansprechpartner.text.trim(),
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
            telefon: _telefon.text.trim().isEmpty ? null : _telefon.text.trim(),
            umsatzsteuerId: _ustId.text.trim().isEmpty ? null : _ustId.text.trim(),
          )
        : RechnungEmpfaenger.create(
            name: _name.text.trim(),
            abteilung: _abteilung.text.trim().isEmpty ? null : _abteilung.text.trim(),
            leitwegId: _leitwegId.text.trim(),
            strasse: _strasse.text.trim(),
            plz: _plz.text.trim(),
            ort: _ort.text.trim(),
            land: _land.text.trim().isEmpty ? 'DE' : _land.text.trim(),
            ansprechpartner: _ansprechpartner.text.trim().isEmpty ? null : _ansprechpartner.text.trim(),
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
            telefon: _telefon.text.trim().isEmpty ? null : _telefon.text.trim(),
            umsatzsteuerId: _ustId.text.trim().isEmpty ? null : _ustId.text.trim(),
          );
    if (_isEdit) {
      await _service.updateEmpfaenger(e);
    } else {
      await _service.addEmpfaenger(e);
    }
    if (!mounted) return;
    Navigator.pop(context, e);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Empfaenger bearbeiten' : 'Neuer Rechnungsempfaenger'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Speichern'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoBox(
              'Die Leitweg-ID ist Pflicht fuer XRechnung und eindeutig pro Behoerde. '
              'Sie ist beim jeweiligen Kostentraeger zu erfragen (Format z.B. "05314-11001001-01" fuer Berlin).',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'z.B. Sozialamt Friedrichshain-Kreuzberg',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _abteilung,
              decoration: const InputDecoration(
                labelText: 'Abteilung (optional)',
                hintText: 'z.B. Teilhabefachdienst',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _leitwegId,
              decoration: const InputDecoration(
                labelText: 'Leitweg-ID *',
                hintText: '05314-11001001-01',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
                helperText: 'Pflicht fuer XRechnung. Vom Kostentraeger anfordern.',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Pflichtfeld';
                final pattern = RegExp(r'^\d{2,12}(-[A-Za-z0-9]{1,30})?(-\d{1,3})?$');
                if (!pattern.hasMatch(v.trim())) return 'Format unguelig (z.B. NNNNN-xxxxxxx-NN)';
                return null;
              },
            ),
            const Divider(height: 32),
            TextFormField(
              controller: _strasse,
              decoration: const InputDecoration(
                labelText: 'Strasse und Hausnummer *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _plz,
                    decoration: const InputDecoration(
                      labelText: 'PLZ *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _ort,
                    decoration: const InputDecoration(
                      labelText: 'Ort *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _land,
                    decoration: const InputDecoration(
                      labelText: 'Land',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            TextFormField(
              controller: _ansprechpartner,
              decoration: const InputDecoration(
                labelText: 'Ansprechpartner:in',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'E-Mail',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefon,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ustId,
              decoration: const InputDecoration(
                labelText: 'USt-ID (falls vorhanden)',
                hintText: 'z.B. DE123456789',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(_isEdit ? 'Aenderungen speichern' : 'Empfaenger anlegen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
