import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/freizeit_antrag.dart';
import '../providers/app_provider.dart';
import '../utils/responsive_utils.dart';

class FreizeitAntragScreen extends StatefulWidget {
  const FreizeitAntragScreen({super.key});

  @override
  State<FreizeitAntragScreen> createState() => _FreizeitAntragScreenState();
}

class _FreizeitAntragScreenState extends State<FreizeitAntragScreen> {
  final _formKey = GlobalKey<FormState>();
  final _grundController = TextEditingController();
  final _bemerkungController = TextEditingController();
  final _stundenController = TextEditingController();

  FreizeitTyp _selectedTyp = FreizeitTyp.urlaub;
  DateTime _vonDatum = DateTime.now();
  DateTime _bisDatum = DateTime.now();

  @override
  void dispose() {
    _grundController.dispose();
    _bemerkungController.dispose();
    _stundenController.dispose();
    super.dispose();
  }

  void _saveAntrag() {
    if (_formKey.currentState!.validate()) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      final antrag = FreizeitAntrag.create(
        mitarbeiterId: 'current_user', // TODO: Aktueller Benutzer
        typ: _selectedTyp,
        vonDatum: _vonDatum,
        bisDatum: _bisDatum,
        grund: _grundController.text.trim(),
        bemerkung: _bemerkungController.text.trim().isEmpty
            ? null
            : _bemerkungController.text.trim(),
        stunden: _selectedTyp == FreizeitTyp.freizeitausgleich
            ? double.tryParse(_stundenController.text)
            : null,
      );

      appProvider.addFreizeitAntrag(antrag);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Freizeit-Antrag erfolgreich eingereicht'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isVonDatum) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isVonDatum ? _vonDatum : _bisDatum,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isVonDatum) {
          _vonDatum = picked;
          if (_bisDatum.isBefore(_vonDatum)) {
            _bisDatum = _vonDatum;
          }
        } else {
          _bisDatum = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Freizeit beantragen'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _saveAntrag,
            child: Text(
              'Einreichen',
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
                // Typ-Auswahl
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Art der Freizeit',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<FreizeitTyp>(
                          value: _selectedTyp,
                          decoration: const InputDecoration(
                            labelText: 'Typ',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.event_available),
                          ),
                          items: FreizeitTyp.values.map((typ) {
                            return DropdownMenuItem(
                              value: typ,
                              child: Text(_getTypDisplayName(typ)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTyp = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Zeitraum
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zeitraum',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, true),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Von',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  child: Text(
                                    DateFormat('dd.MM.yyyy').format(_vonDatum),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, false),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Bis',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  child: Text(
                                    DateFormat('dd.MM.yyyy').format(_bisDatum),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_bisDatum.difference(_vonDatum).inDays + 1} Tag(e)',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Stunden für Freizeitausgleich
                        if (_selectedTyp == FreizeitTyp.freizeitausgleich) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _stundenController,
                            decoration: const InputDecoration(
                              labelText: 'Stunden',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.access_time),
                              suffixText: 'h',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_selectedTyp == FreizeitTyp.freizeitausgleich) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Bitte Stunden eingeben';
                                }
                                final stunden = double.tryParse(value);
                                if (stunden == null || stunden <= 0) {
                                  return 'Bitte gültige Stundenzahl eingeben';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Grund und Bemerkungen
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _grundController,
                          decoration: const InputDecoration(
                            labelText: 'Grund',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Bitte Grund eingeben';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _bemerkungController,
                          decoration: const InputDecoration(
                            labelText: 'Bemerkungen (optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 3,
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

  String _getTypDisplayName(FreizeitTyp typ) {
    switch (typ) {
      case FreizeitTyp.urlaub:
        return 'Urlaub';
      case FreizeitTyp.freizeitausgleich:
        return 'Freizeitausgleich';
      case FreizeitTyp.sonderurlaub:
        return 'Sonderurlaub';
      case FreizeitTyp.fortbildung:
        return 'Fortbildung';
      case FreizeitTyp.krankmeldung:
        return 'Krankmeldung';
      case FreizeitTyp.unbezahlt:
        return 'Unbezahlter Urlaub';
    }
  }
}