import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/client.dart';
import 'package:fegh_billing/fegh_billing.dart';
import '../services/rechnung_service.dart';
import '../utils/responsive_utils.dart';
import 'wirkungsmessung/ziel_liste_screen.dart';

class CreateClientScreen extends StatefulWidget {
  final Client? client;

  const CreateClientScreen({super.key, this.client});

  @override
  State<CreateClientScreen> createState() => _CreateClientScreenState();
}

class _CreateClientScreenState extends State<CreateClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _klientenIdController;
  late TextEditingController _vornameController;
  late TextEditingController _nachnameController;
  late TextEditingController _fachleistungsstundenController;
  late TextEditingController _kalkulationsfaktorOverrideController;
  late TextEditingController _stundensatzOverrideController;
  late TextEditingController _bewilligungsbescheidController;
  late TextEditingController _leistungstypController;
  // Map<empfaengerId, Controller> fuer Fallnummern pro Kostentraeger
  final Map<String, TextEditingController> _fallnummerControllers = {};
  List<RechnungEmpfaenger> _alleEmpfaenger = [];
  final _rechnungService = RechnungService();

  String _selectedEingliederung = '';
  String _selectedKostentraeger = '';
  String? _selectedRechtsgrundlage;
  HilfeTyp _selectedHilfeTyp = HilfeTyp.eingliederungshilfe;
  FachleistungsIntervall _selectedIntervall = FachleistungsIntervall.monatlich;

  DateTime? _selectedGeburtsdatum;
  DateTime? _selectedBetreuungSeit;
  DateTime? _selectedKostenuebernahmeVon;
  DateTime? _selectedKostenuebernahmeBis;

  String? _selectedVertreter1Id;
  String? _selectedVertreter2Id;
  List<String> _selectedTibZiele = [];
  List<TextEditingController> _individuelleTibZieleControllers = [];

  static const List<String> eingliederungsarten = [
    '', // Leere Option als erste Option
    'Berufliche Reha',
    'Soziale Teilhabe',
    'Medizinische Reha',
    'Teilhabe Arbeit',
    'Teilhabe Bildung',
    'Sonstige'
  ];

  static const List<Map<String, String>> rechtsgrundlagen = [
    {'gruppe': 'SGB IX (Eingliederungshilfe)', 'wert': '§ 99 SGB IX – Leistungsberechtigter Personenkreis'},
    {'gruppe': 'SGB IX (Eingliederungshilfe)', 'wert': '§ 102 SGB IX – Aufgabe der Eingliederungshilfe'},
    {'gruppe': 'SGB IX (Eingliederungshilfe)', 'wert': '§ 111 SGB IX – Leistungen zur Sozialen Teilhabe'},
    {'gruppe': 'SGB IX (Eingliederungshilfe)', 'wert': '§ 112 SGB IX – Leistungen zur Teilhabe an Bildung'},
    {'gruppe': 'SGB IX (Eingliederungshilfe)', 'wert': '§ 113 SGB IX – Heilpädagogische Leistungen'},
    {'gruppe': 'SGB IX (Eingliederungshilfe)', 'wert': '§ 116 SGB IX – Assistenzleistungen'},
    {'gruppe': 'SGB IX (Eingliederungshilfe)', 'wert': '§ 78 SGB IX – Teilhabe am Arbeitsleben'},
    {'gruppe': 'SGB VIII (Jugendhilfe)', 'wert': '§ 35a SGB VIII – Eingliederungshilfe (seelische Behinderung)'},
    {'gruppe': 'SGB VIII (Jugendhilfe)', 'wert': '§ 27 SGB VIII – Hilfe zur Erziehung'},
    {'gruppe': 'SGB VIII (Jugendhilfe)', 'wert': '§ 30 SGB VIII – Erziehungsbeistand'},
    {'gruppe': 'SGB VIII (Jugendhilfe)', 'wert': '§ 31 SGB VIII – SPFH'},
    {'gruppe': 'SGB XII (Sozialhilfe)', 'wert': '§ 67 SGB XII – Personen in besonderen Lebenslagen'},
  ];

  @override
  void initState() {
    super.initState();

    // Controller initialisieren
    _nameController = TextEditingController(text: widget.client?.name ?? '');
    _klientenIdController = TextEditingController(text: widget.client?.klientenId ?? '');
    _vornameController = TextEditingController(text: widget.client?.vorname ?? '');
    _nachnameController = TextEditingController(text: widget.client?.nachname ?? '');
    _fachleistungsstundenController = TextEditingController(
      text: widget.client?.fachleistungsstunden?.toString() ?? '120'
    );
    _kalkulationsfaktorOverrideController = TextEditingController(
      text: widget.client?.kalkulationsfaktorOverride?.toStringAsFixed(2) ?? '',
    );
    _stundensatzOverrideController = TextEditingController(
      text: widget.client?.stundensatzOverride?.toStringAsFixed(2) ?? '',
    );
    _bewilligungsbescheidController = TextEditingController(
      text: widget.client?.bewilligungsbescheidRef ?? '',
    );
    _leistungstypController = TextEditingController(
      text: widget.client?.leistungstypSchluessel ?? '',
    );
    // Fallnummer-Controller fuer bereits vorhandene Eintraege
    widget.client?.kostentraegerFallnummern?.forEach((empfId, nr) {
      _fallnummerControllers[empfId] = TextEditingController(text: nr);
    });

    // Listener für automatische Name-Aktualisierung
    _vornameController.addListener(_updateFullName);
    _nachnameController.addListener(_updateFullName);

    // Dropdowns initialisieren - KEINE automatischen Standardwerte setzen
    final clientEingliederung = widget.client?.eingliederung ?? '';
    _selectedEingliederung = eingliederungsarten.contains(clientEingliederung)
        ? clientEingliederung
        : ''; // Leer lassen statt automatischen Standardwert

    // Neue Felder initialisieren
    _selectedHilfeTyp = widget.client?.hilfeTyp ?? HilfeTyp.eingliederungshilfe;
    _selectedIntervall = widget.client?.fachleistungsIntervall ?? FachleistungsIntervall.monatlich;
    // Validierung gegen Liste - schuetzt DropdownButton vor Assertion
    final storedKt = widget.client?.kostenuebernahme ?? '';
    _selectedKostentraeger = Kostentraeger.alleGruppiert
            .any((e) => e['wert'] == storedKt)
        ? storedKt
        : '';
    _selectedGeburtsdatum = widget.client?.geburtsdatum;
    _selectedBetreuungSeit = widget.client?.betreuungSeit;
    _selectedKostenuebernahmeVon = widget.client?.kostenuebernahmeVon;
    _selectedKostenuebernahmeBis = widget.client?.kostenuebernahmeBis;
    // Vertreter-IDs werden gegen Mitarbeiter-Liste validiert im Build
    // (AppProvider ist erst dort verfuegbar)
    _selectedVertreter1Id = widget.client?.vertreter1Id;
    _selectedVertreter2Id = widget.client?.vertreter2Id;
    _selectedTibZiele = widget.client?.tibZiele ?? [];
    // Nur uebernehmen, wenn Wert in aktueller Liste vorhanden
    // (schuetzt vor DropdownButton-Assertion bei Legacy-Daten)
    final storedRg = widget.client?.rechtsgrundlage;
    _selectedRechtsgrundlage = rechtsgrundlagen.any((e) => e['wert'] == storedRg)
        ? storedRg
        : null;

    // Individuelle TIB-Ziele Controller initialisieren
    final individuelleTibZiele = widget.client?.individuelleTibZiele ?? [];
    _individuelleTibZieleControllers = individuelleTibZiele.map((ziel) => TextEditingController(text: ziel)).toList();

    _loadEmpfaenger();
  }

  Future<void> _loadEmpfaenger() async {
    final liste = await _rechnungService.loadEmpfaenger();
    if (!mounted) return;
    setState(() => _alleEmpfaenger = liste);
  }

  void _fallnummerHinzufuegen() {
    // Finde einen Empfaenger ohne bisherigen Eintrag
    final zugeordnet = _fallnummerControllers.keys.toSet();
    final frei = _alleEmpfaenger.where((e) => !zugeordnet.contains(e.id)).toList();
    if (frei.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alle vorhandenen Empfaenger sind bereits zugeordnet')),
      );
      return;
    }
    setState(() {
      _fallnummerControllers[frei.first.id] = TextEditingController();
    });
  }

  void _fallnummerEntfernen(String empfId) {
    setState(() {
      _fallnummerControllers[empfId]?.dispose();
      _fallnummerControllers.remove(empfId);
    });
  }

  void _fallnummerEmpfaengerAendern(String altId, String neuId) {
    if (altId == neuId) return;
    if (_fallnummerControllers.containsKey(neuId)) return; // schon belegt
    setState(() {
      final ctrl = _fallnummerControllers.remove(altId);
      if (ctrl != null) _fallnummerControllers[neuId] = ctrl;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _klientenIdController.dispose();
    _vornameController.dispose();
    _nachnameController.dispose();
    _fachleistungsstundenController.dispose();
    _kalkulationsfaktorOverrideController.dispose();
    _stundensatzOverrideController.dispose();
    _bewilligungsbescheidController.dispose();
    _leistungstypController.dispose();
    for (final c in _fallnummerControllers.values) {
      c.dispose();
    }
    for (var controller in _individuelleTibZieleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateFullName() {
    if (_vornameController.text.isNotEmpty && _nachnameController.text.isNotEmpty) {
      setState(() {
        _nameController.text = '${_vornameController.text} ${_nachnameController.text}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client == null ? 'Neuer Klient' : 'Klient bearbeiten'),
        actions: [
          TextButton(
            onPressed: () => _saveClient(context),
            child: const Text('Speichern'),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: ResponsiveUtils.getScreenPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grunddaten Sektion
                  Text(
                    'Grunddaten',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildGrunddatenCard(),

                  const SizedBox(height: 24),

                  // Betreuung Sektion
                  Text(
                    'Betreuung',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBetreuungCard(),

                  const SizedBox(height: 24),

                  // Fachleistungsstunden Sektion
                  Text(
                    'Fachleistungsstunden',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFachleistungCard(),

                  const SizedBox(height: 24),

                  // Vertreter Sektion
                  Text(
                    'Vertreter',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildVertreterCard(appProvider),

                  const SizedBox(height: 24),

                  // Teilhabeziele Sektion
                  Text(
                    'Teilhabeziele & Wirkungsmessung',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTibZieleCard(),

                  const SizedBox(height: 100), // Space for navigation
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrunddatenCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Vollständiger Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                helperText: 'Wird automatisch aus Vor- und Nachnamen generiert',
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _klientenIdController,
              decoration: const InputDecoration(
                labelText: 'Klienten-ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
                hintText: 'z.B. KL-001',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vornameController,
              decoration: const InputDecoration(
                labelText: 'Vorname',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte Vorname eingeben';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nachnameController,
              decoration: const InputDecoration(
                labelText: 'Nachname',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte Nachname eingeben';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedEingliederung.isEmpty ? null : _selectedEingliederung,
              decoration: const InputDecoration(
                labelText: 'Eingliederungsart',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: eingliederungsarten.map((String value) {
                return DropdownMenuItem<String>(
                  value: value.isEmpty ? null : value,
                  child: Text(value.isEmpty ? 'Bitte auswählen' : value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedEingliederung = value ?? '';
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRechtsgrundlage,
              decoration: const InputDecoration(
                labelText: 'Rechtsgrundlage / Paragraph',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.gavel),
                hintText: 'Bitte auswählen',
              ),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Keine Angabe'),
                ),
                ...(() {
                  String? currentGruppe;
                  final items = <DropdownMenuItem<String>>[];
                  for (final entry in rechtsgrundlagen) {
                    if (entry['gruppe'] != currentGruppe) {
                      currentGruppe = entry['gruppe'];
                      items.add(DropdownMenuItem<String>(
                        enabled: false,
                        value: 'header_$currentGruppe',
                        child: Text(
                          currentGruppe!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ));
                    }
                    items.add(DropdownMenuItem<String>(
                      value: entry['wert'],
                      child: Text(
                        entry['wert']!,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ));
                  }
                  return items;
                })(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRechtsgrundlage = value;
                });
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context, 'geburtsdatum'),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Geburtsdatum',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake),
                ),
                child: Text(
                  _selectedGeburtsdatum != null
                      ? '${_selectedGeburtsdatum!.day}.${_selectedGeburtsdatum!.month}.${_selectedGeburtsdatum!.year}'
                      : 'Datum auswählen',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBetreuungCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InkWell(
              onTap: () => _selectDate(context, 'betreuung_seit'),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Betreuung seit',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event_available),
                ),
                child: Text(
                  _selectedBetreuungSeit != null
                      ? '${_selectedBetreuungSeit!.day}.${_selectedBetreuungSeit!.month}.${_selectedBetreuungSeit!.year}'
                      : 'Datum auswählen',
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedKostentraeger.isEmpty ? null : _selectedKostentraeger,
              decoration: const InputDecoration(
                labelText: 'Kostenträger',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
                hintText: 'Bitte auswählen',
              ),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Keine Angabe'),
                ),
                ...(() {
                  String? currentGruppe;
                  final items = <DropdownMenuItem<String>>[];
                  for (final entry in Kostentraeger.alleGruppiert) {
                    if (entry['gruppe'] != currentGruppe) {
                      currentGruppe = entry['gruppe'];
                      items.add(DropdownMenuItem<String>(
                        enabled: false,
                        value: 'header_$currentGruppe',
                        child: Text(
                          currentGruppe!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ));
                    }
                    items.add(DropdownMenuItem<String>(
                      value: entry['wert'],
                      child: Text(
                        entry['wert']!,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ));
                  }
                  return items;
                })(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedKostentraeger = value ?? '';
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, 'kostenuebernahme_von'),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Von',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.date_range),
                      ),
                      child: Text(
                        _selectedKostenuebernahmeVon != null
                            ? '${_selectedKostenuebernahmeVon!.day}.${_selectedKostenuebernahmeVon!.month}.${_selectedKostenuebernahmeVon!.year}'
                            : 'Datum auswählen',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, 'kostenuebernahme_bis'),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Bis',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.date_range),
                      ),
                      child: Text(
                        _selectedKostenuebernahmeBis != null
                            ? '${_selectedKostenuebernahmeBis!.day}.${_selectedKostenuebernahmeBis!.month}.${_selectedKostenuebernahmeBis!.year}'
                            : 'Datum auswählen',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFachleistungCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_klientenIdController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Klienten-ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  child: Text(_klientenIdController.text),
                ),
              ),
            TextFormField(
              controller: _fachleistungsstundenController,
              decoration: const InputDecoration(
                labelText: 'Fachleistungsstunden',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
                suffixText: 'Stunden',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final stunden = int.tryParse(value);
                  if (stunden == null || stunden <= 0) {
                    return 'Bitte gültige Stundenzahl eingeben';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FachleistungsIntervall>(
              value: _selectedIntervall,
              decoration: const InputDecoration(
                labelText: 'Intervall',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
              ),
              items: FachleistungsIntervall.values.map((intervall) {
                return DropdownMenuItem<FachleistungsIntervall>(
                  value: intervall,
                  child: Text(switch (intervall) {
                    FachleistungsIntervall.woechentlich => 'Wöchentlich',
                    FachleistungsIntervall.monatlich => 'Monatlich',
                    FachleistungsIntervall.jaehrlich => 'Jährlich',
                  }),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedIntervall = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<HilfeTyp>(
              value: _selectedHilfeTyp,
              decoration: const InputDecoration(
                labelText: 'Hilfe-Typ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.help_outline),
              ),
              items: HilfeTyp.values.map((typ) {
                return DropdownMenuItem<HilfeTyp>(
                  value: typ,
                  child: Text(typ == HilfeTyp.eingliederungshilfe ? 'Eingliederungshilfe' : 'Familienhilfe'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedHilfeTyp = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Klient-spezifische Kalkulation (optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
            ),
            TextFormField(
              controller: _kalkulationsfaktorOverrideController,
              decoration: const InputDecoration(
                labelText: 'Kalkulationsfaktor (leer = global)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calculate),
                hintText: 'z.B. 1.25',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final v = double.tryParse(value.trim().replaceAll(',', '.'));
                  if (v == null || v <= 0) {
                    return 'Bitte gültigen Faktor eingeben';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stundensatzOverrideController,
              decoration: const InputDecoration(
                labelText: 'Stundensatz EUR (leer = global)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.euro),
                hintText: 'z.B. 65.00 - aus §125-Verguetungsvereinbarung',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final v = double.tryParse(value.trim().replaceAll(',', '.'));
                  if (v == null || v <= 0) {
                    return 'Bitte gültigen Stundensatz eingeben';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Abrechnungs-Stammdaten (fuer Rechnung)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _leistungstypController,
              decoration: const InputDecoration(
                labelText: 'Leistungstyp-Schluessel (nach Rahmenvertrag)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
                hintText: 'z.B. B5.01 ABW Erwachsene',
                helperText: 'Schluessel aus Landesrahmenvertrag - erscheint auf XRechnung',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bewilligungsbescheidController,
              decoration: const InputDecoration(
                labelText: 'Bewilligungsbescheid-Referenz',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                hintText: 'Geschaeftszeichen / Bescheid-Nr.',
                helperText: 'Hilft dem Sozialamt, die Rechnung zuzuordnen',
              ),
            ),
            const SizedBox(height: 16),
            _buildFallnummerListe(),
          ],
        ),
      ),
    );
  }

  Widget _buildFallnummerListe() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Aktenzeichen pro Kostentraeger',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: _alleEmpfaenger.isEmpty ? null : _fallnummerHinzufuegen,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Hinzufuegen'),
            ),
          ],
        ),
        if (_alleEmpfaenger.isEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zuerst Rechnungsempfaenger anlegen (Berichte > Rechnungen > Empfaenger)',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        else if (_fallnummerControllers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Fallback: das allgemeine Klienten-ID-Feld wird als Aktenzeichen verwendet.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          )
        else
          ..._fallnummerControllers.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: e.key,
                        decoration: const InputDecoration(
                          labelText: 'Kostentraeger',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _alleEmpfaenger
                            .map((emp) => DropdownMenuItem(
                                  value: emp.id,
                                  child: Text(emp.name, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) _fallnummerEmpfaengerAendern(e.key, v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: e.value,
                        decoration: const InputDecoration(
                          labelText: 'Aktenzeichen',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                      onPressed: () => _fallnummerEntfernen(e.key),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildVertreterCard(AppProvider appProvider) {
    final mitarbeiter = appProvider.mitarbeiter;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String?>(
              value: mitarbeiter.any((m) => m.id == _selectedVertreter1Id)
                  ? _selectedVertreter1Id
                  : null,
              decoration: const InputDecoration(
                labelText: 'Vertreter 1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Keine Auswahl'),
                ),
                ...mitarbeiter.toSet().map((m) {
                  return DropdownMenuItem<String?>(
                    value: m.id,
                    child: Text('${m.vorname} ${m.name} (Team ${m.teamNummer})'),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedVertreter1Id = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: mitarbeiter.any((m) => m.id == _selectedVertreter2Id)
                  ? _selectedVertreter2Id
                  : null,
              decoration: const InputDecoration(
                labelText: 'Vertreter 2',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Keine Auswahl'),
                ),
                ...mitarbeiter.toSet().map((m) {
                  return DropdownMenuItem<String?>(
                    value: m.id,
                    child: Text('${m.vorname} ${m.name} (Team ${m.teamNummer})'),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedVertreter2Id = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTibZieleCard() {
    final isEditingExisting = widget.client != null;
    final legacyVorhanden = _individuelleTibZieleControllers.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teilhabeziele',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Teilhabeziele werden strukturiert nach SMART-Kriterien erfasst und mit GAS-Messungen (Goal Attainment Scaling) dokumentiert.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            if (!isEditingExisting)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Klient zuerst speichern. Danach koennen Teilhabeziele '
                        'ueber die Aktion "Teilhabeziele & Wirkung" im Klienten-Menue '
                        'angelegt werden.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () async {
                  if (widget.client == null) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ZielListeScreen(
                        client: widget.client!,
                        bewertetVon: context.read<AppProvider>().settings.userName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.track_changes),
                label: const Text('Teilhabeziele verwalten'),
              ),

            if (legacyVorhanden) ...[
              const SizedBox(height: 16),
              const Divider(),
              Text(
                'Alte TIB-Ziele (Freitext) - bitte uebernehmen',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Diese Freitext-Ziele stammen aus der alten Struktur. Sie werden '
                'beim naechsten Oeffnen von "Teilhabeziele" zur Uebernahme angeboten.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              ..._individuelleTibZieleControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'Altes TIB-Ziel ${index + 1}',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.history),
                          ),
                          maxLines: 2,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeIndividuelleTibZiel(index),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  void _removeIndividuelleTibZiel(int index) {
    setState(() {
      _individuelleTibZieleControllers[index].dispose();
      _individuelleTibZieleControllers.removeAt(index);
    });
  }

  double? _parseOptionalDouble(String text) {
    final trimmed = text.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  List<String>? _getIndividuelleTibZiele() {
    final ziele = _individuelleTibZieleControllers
        .map((controller) => controller.text.trim())
        .where((ziel) => ziel.isNotEmpty)
        .toList();
    return ziele.isNotEmpty ? ziele : null;
  }

  Map<String, String>? _buildFallnummerMap() {
    final map = <String, String>{};
    _fallnummerControllers.forEach((empfId, ctrl) {
      final v = ctrl.text.trim();
      if (v.isNotEmpty) map[empfId] = v;
    });
    return map.isEmpty ? null : map;
  }

  Future<void> _selectDate(BuildContext context, String field) async {
    final initialDate = _getDateForField(field) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _setDateForField(field, picked);
      });
    }
  }

  DateTime? _getDateForField(String field) {
    switch (field) {
      case 'geburtsdatum':
        return _selectedGeburtsdatum;
      case 'betreuung_seit':
        return _selectedBetreuungSeit;
      case 'kostenuebernahme_von':
        return _selectedKostenuebernahmeVon;
      case 'kostenuebernahme_bis':
        return _selectedKostenuebernahmeBis;
      default:
        return null;
    }
  }

  void _setDateForField(String field, DateTime date) {
    switch (field) {
      case 'geburtsdatum':
        _selectedGeburtsdatum = date;
        break;
      case 'betreuung_seit':
        _selectedBetreuungSeit = date;
        break;
      case 'kostenuebernahme_von':
        _selectedKostenuebernahmeVon = date;
        break;
      case 'kostenuebernahme_bis':
        _selectedKostenuebernahmeBis = date;
        break;
    }
  }

  Future<void> _saveClient(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);

    try {
      final client = Client.create(
        klientenId: _klientenIdController.text.trim().isNotEmpty ? _klientenIdController.text.trim() : null,
        name: _nameController.text.trim(),
        vorname: _vornameController.text.trim(),
        nachname: _nachnameController.text.trim(),
        berufsgruppe: null, // Berufsgruppe entfernt
        eingliederung: _selectedEingliederung.isEmpty ? null : _selectedEingliederung,
        geburtsdatum: _selectedGeburtsdatum,
        betreuungSeit: _selectedBetreuungSeit,
        kostenuebernahme: _selectedKostentraeger.isEmpty ? null : _selectedKostentraeger,
        kostenuebernahmeVon: _selectedKostenuebernahmeVon,
        kostenuebernahmeBis: _selectedKostenuebernahmeBis,
        fachleistungsstunden: int.tryParse(_fachleistungsstundenController.text),
        fachleistungsIntervall: _selectedIntervall,
        hilfeTyp: _selectedHilfeTyp,
        icfBereiche: null, // Für später implementieren
        verbrauchteStunden: widget.client?.verbrauchteStunden ?? 0.0,
        kalkulationsfaktorOverride: _parseOptionalDouble(_kalkulationsfaktorOverrideController.text),
        stundensatzOverride: _parseOptionalDouble(_stundensatzOverrideController.text),
        vertreter1Id: _selectedVertreter1Id,
        vertreter2Id: _selectedVertreter2Id,
        tibZiele: _selectedTibZiele.isNotEmpty ? _selectedTibZiele : null,
        individuelleTibZiele: _getIndividuelleTibZiele(),
        rechtsgrundlage: _selectedRechtsgrundlage,
        bewilligungsbescheidRef: _bewilligungsbescheidController.text.trim().isEmpty
            ? null
            : _bewilligungsbescheidController.text.trim(),
        leistungstypSchluessel: _leistungstypController.text.trim().isEmpty
            ? null
            : _leistungstypController.text.trim(),
        kostentraegerFallnummern: _buildFallnummerMap(),
      );

      bool success;
      if (widget.client == null) {
        success = await appProvider.addClient(client);
      } else {
        final updatedClient = widget.client!.copyWith(
          klientenId: _klientenIdController.text.trim().isNotEmpty ? _klientenIdController.text.trim() : null,
          name: _nameController.text.trim(),
          vorname: _vornameController.text.trim(),
          nachname: _nachnameController.text.trim(),
          berufsgruppe: null, // Berufsgruppe entfernt
          eingliederung: _selectedEingliederung.isEmpty ? null : _selectedEingliederung,
          geburtsdatum: _selectedGeburtsdatum,
          betreuungSeit: _selectedBetreuungSeit,
          kostenuebernahme: _selectedKostentraeger.isEmpty ? null : _selectedKostentraeger,
          kostenuebernahmeVon: _selectedKostenuebernahmeVon,
          kostenuebernahmeBis: _selectedKostenuebernahmeBis,
          fachleistungsstunden: int.tryParse(_fachleistungsstundenController.text),
          fachleistungsIntervall: _selectedIntervall,
          hilfeTyp: _selectedHilfeTyp,
          kalkulationsfaktorOverride: _parseOptionalDouble(_kalkulationsfaktorOverrideController.text),
          stundensatzOverride: _parseOptionalDouble(_stundensatzOverrideController.text),
          vertreter1Id: _selectedVertreter1Id,
          vertreter2Id: _selectedVertreter2Id,
          tibZiele: _selectedTibZiele.isNotEmpty ? _selectedTibZiele : null,
          individuelleTibZiele: _getIndividuelleTibZiele(),
          rechtsgrundlage: _selectedRechtsgrundlage,
          bewilligungsbescheidRef: _bewilligungsbescheidController.text.trim().isEmpty
              ? null
              : _bewilligungsbescheidController.text.trim(),
          leistungstypSchluessel: _leistungstypController.text.trim().isEmpty
              ? null
              : _leistungstypController.text.trim(),
          kostentraegerFallnummern: _buildFallnummerMap(),
        );
        success = await appProvider.updateClient(updatedClient);
      }

      if (success && context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.client == null
                ? 'Klient erfolgreich erstellt'
                : 'Klient erfolgreich aktualisiert'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}