import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mitarbeiter.dart';
import '../providers/app_provider.dart';
import '../utils/responsive_utils.dart';

class MitarbeiterScreen extends StatefulWidget {
  final Mitarbeiter? editMitarbeiter;

  const MitarbeiterScreen({super.key, this.editMitarbeiter});

  @override
  State<MitarbeiterScreen> createState() => _MitarbeiterScreenState();
}

class _MitarbeiterScreenState extends State<MitarbeiterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _vornameController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonController = TextEditingController();

  int _selectedTeam = 1;
  MitarbeiterBereich _selectedBereich = MitarbeiterBereich.eingliederungshilfe;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.editMitarbeiter != null) {
      _nameController.text = widget.editMitarbeiter!.name;
      _vornameController.text = widget.editMitarbeiter!.vorname;
      _emailController.text = widget.editMitarbeiter!.email;
      _telefonController.text = widget.editMitarbeiter!.telefon;
      _selectedTeam = widget.editMitarbeiter!.teamNummer ?? 1;
      _selectedBereich = widget.editMitarbeiter!.bereich ??
          MitarbeiterBereich.eingliederungshilfe;
      _isActive = widget.editMitarbeiter!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _vornameController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    super.dispose();
  }

  void _saveMitarbeiter() {
    if (_formKey.currentState!.validate()) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      if (widget.editMitarbeiter != null) {
        // Bearbeiten
        final updatedMitarbeiter = widget.editMitarbeiter!.copyWith(
          name: _nameController.text.trim(),
          vorname: _vornameController.text.trim(),
          email: _emailController.text.trim(),
          telefon: _telefonController.text.trim(),
          teamNummer: _selectedTeam,
          bereich: _selectedBereich,
          isActive: _isActive,
        );
        appProvider.updateMitarbeiter(updatedMitarbeiter);
      } else {
        // Neu erstellen
        final mitarbeiter = Mitarbeiter.create(
          name: _nameController.text.trim(),
          vorname: _vornameController.text.trim(),
          email: _emailController.text.trim(),
          telefon: _telefonController.text.trim(),
          teamNummer: _selectedTeam,
          bereich: _selectedBereich,
          isActive: _isActive,
        );
        appProvider.addMitarbeiter(mitarbeiter);
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editMitarbeiter != null
              ? 'Mitarbeiter aktualisiert'
              : 'Mitarbeiter erstellt'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editMitarbeiter != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Mitarbeiter bearbeiten' : 'Neuer Mitarbeiter'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _saveMitarbeiter,
            child: Text(
              isEditing ? 'Aktualisieren' : 'Erstellen',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ResponsiveUtils.adaptiveScaffoldBody(
        context: context,
        body: SingleChildScrollView(
          padding: ResponsiveUtils.getScreenPadding(context),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Persönliche Daten
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Persönliche Daten',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _vornameController,
                                decoration: const InputDecoration(
                                  labelText: 'Vorname',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Bitte Vorname eingeben';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nachname',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Bitte Nachname eingeben';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'E-Mail',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Bitte E-Mail eingeben';
                            }
                            if (!value.contains('@')) {
                              return 'Bitte gültige E-Mail eingeben';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _telefonController,
                          decoration: const InputDecoration(
                            labelText: 'Telefon',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Bitte Telefonnummer eingeben';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Arbeitsplatz-Daten
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arbeitsplatz',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _selectedTeam,
                                decoration: const InputDecoration(
                                  labelText: 'Team',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.group),
                                ),
                                items: List.generate(20, (index) => index + 1)
                                    .map((team) => DropdownMenuItem(
                                          value: team,
                                          child: Text('Team $team'),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedTeam = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<MitarbeiterBereich>(
                                value: _selectedBereich,
                                decoration: const InputDecoration(
                                  labelText: 'Bereich',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.work),
                                ),
                                items: MitarbeiterBereich.values
                                    .map((bereich) => DropdownMenuItem(
                                          value: bereich,
                                          child: Text(_getBereichDisplayName(bereich)),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedBereich = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        SwitchListTile(
                          title: const Text('Aktiv'),
                          subtitle: const Text('Mitarbeiter ist derzeit aktiv'),
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 100), // Space for potential floating action button
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getBereichDisplayName(MitarbeiterBereich bereich) {
    switch (bereich) {
      case MitarbeiterBereich.eingliederungshilfe:
        return 'Eingliederungshilfe';
      case MitarbeiterBereich.familienhilfe:
        return 'Familienhilfe';
      case MitarbeiterBereich.jugendhilfe:
        return 'Jugendhilfe';
      case MitarbeiterBereich.sozialhilfe:
        return 'Sozialhilfe';
      case MitarbeiterBereich.betreuung:
        return 'Betreuung';
      case MitarbeiterBereich.verwaltung:
        return 'Verwaltung';
    }
  }
}