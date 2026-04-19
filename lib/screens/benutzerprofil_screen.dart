import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mitarbeiter.dart';
import '../providers/app_provider.dart';
import '../utils/responsive_utils.dart';

class BenutzerprofilScreen extends StatefulWidget {
  const BenutzerprofilScreen({super.key});

  @override
  State<BenutzerprofilScreen> createState() => _BenutzerprofilScreenState();
}

class _BenutzerprofilScreenState extends State<BenutzerprofilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _vornameController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonController = TextEditingController();
  final _wochenstundenController = TextEditingController();
  final _urlaubstageController = TextEditingController();

  int _selectedTeam = 1;
  MitarbeiterBereich _selectedBereich = MitarbeiterBereich.eingliederungshilfe;
  Mitarbeiter? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    _currentUser = appProvider.currentUser;

    if (_currentUser != null) {
      _nameController.text = _currentUser!.name;
      _vornameController.text = _currentUser!.vorname;
      _emailController.text = _currentUser!.email;
      _telefonController.text = _currentUser!.telefon;
      _wochenstundenController.text = _currentUser!.wochenarbeitszeit.toString();
      _urlaubstageController.text = _currentUser!.urlaubstage.toString();
      _selectedTeam = _currentUser!.teamNummer ?? 1;
      _selectedBereich =
          _currentUser!.bereich ?? MitarbeiterBereich.eingliederungshilfe;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _vornameController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    _wochenstundenController.dispose();
    _urlaubstageController.dispose();
    super.dispose();
  }

  void _saveProfil() {
    if (_formKey.currentState!.validate()) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      if (_currentUser != null) {
        final updatedUser = _currentUser!.copyWith(
          name: _nameController.text.trim(),
          vorname: _vornameController.text.trim(),
          email: _emailController.text.trim(),
          telefon: _telefonController.text.trim(),
          teamNummer: _selectedTeam,
          bereich: _selectedBereich,
          wochenarbeitszeit: double.tryParse(_wochenstundenController.text) ?? 40.0,
          urlaubstage: int.tryParse(_urlaubstageController.text) ?? 30,
        );
        appProvider.updateCurrentUser(updatedUser);
      } else {
        final newUser = Mitarbeiter.create(
          name: _nameController.text.trim(),
          vorname: _vornameController.text.trim(),
          email: _emailController.text.trim(),
          telefon: _telefonController.text.trim(),
          teamNummer: _selectedTeam,
          bereich: _selectedBereich,
          wochenarbeitszeit: double.tryParse(_wochenstundenController.text) ?? 40.0,
          urlaubstage: int.tryParse(_urlaubstageController.text) ?? 30,
        );
        appProvider.createCurrentUser(newUser);
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Benutzerprofil aktualisiert'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mein Profil'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _saveProfil,
            child: Text(
              'Speichern',
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Persönliche Daten',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _vornameController,
                          decoration: const InputDecoration(
                            labelText: 'Vorname',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
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
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nachname',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Bitte Nachname eingeben';
                            }
                            return null;
                          },
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

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.work,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Arbeitsplatz',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        DropdownButtonFormField<int>(
                          value: _selectedTeam,
                          decoration: const InputDecoration(
                            labelText: 'Team',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.group),
                          ),
                          items: List.generate(20, (index) {
                            final teamNumber = index + 1;
                            return DropdownMenuItem(
                              value: teamNumber,
                              child: Text('Team $teamNumber'),
                            );
                          }),
                          onChanged: (value) {
                            setState(() {
                              _selectedTeam = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<MitarbeiterBereich>(
                          value: _selectedBereich,
                          decoration: const InputDecoration(
                            labelText: 'Abteilung',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
                          items: MitarbeiterBereich.values.map((bereich) {
                            return DropdownMenuItem(
                              value: bereich,
                              child: Text(_getBereichDisplayName(bereich)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedBereich = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Arbeitszeiten',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _wochenstundenController,
                          decoration: const InputDecoration(
                            labelText: 'Wochenarbeitszeit',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time),
                            suffixText: 'Stunden',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Bitte Wochenstunden eingeben';
                            }
                            final stunden = double.tryParse(value);
                            if (stunden == null || stunden <= 0 || stunden > 60) {
                              return 'Bitte gültige Stundenzahl eingeben (1-60)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _urlaubstageController,
                          decoration: const InputDecoration(
                            labelText: 'Urlaubstage pro Jahr',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.beach_access),
                            suffixText: 'Tage',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Bitte Urlaubstage eingeben';
                            }
                            final tage = int.tryParse(value);
                            if (tage == null || tage <= 0 || tage > 50) {
                              return 'Bitte gültige Anzahl eingeben (1-50)';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 100),
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