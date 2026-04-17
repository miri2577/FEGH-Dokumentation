import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import '../models/informationsbericht.dart';

/// Spezieller Service: fuellt das offizielle Berliner Formular 101
/// (Informationsbericht) per Syncfusion-AcroForm-API aus.
///
/// Fuer alle anderen Reports (Arbeitszeit, FLS, Klienten) wird
/// [PdfReportService] genutzt - mit einheitlichem Hybrid-Design.
class PdfGeneratorService {
  static Future<Uint8List> generateInformationsberichtSyncfusion(
    Informationsbericht bericht,
  ) async {
    final df = DateFormat('dd.MM.yyyy');

    final templateBytes = await rootBundle.load('assets/informationsbericht_101.pdf');
    final doc = sf.PdfDocument(inputBytes: templateBytes.buffer.asUint8List());
    final form = doc.form;

    // Hilfs-Map fuer schnelleren Zugriff
    final fieldMap = <String, sf.PdfField>{};
    for (int i = 0; i < form.fields.count; i++) {
      final fname = form.fields[i].name;
      if (fname != null) fieldMap[fname] = form.fields[i];
    }

    void setText(String name, String? value) {
      if (value == null || value.isEmpty) return;
      final field = fieldMap[name];
      if (field is sf.PdfTextBoxField) {
        field.text = value;
        debugPrint('[SyncfusionPDF] setText: $name = "$value" (OK)');
      } else {
        debugPrint('[SyncfusionPDF] setText: $name = "$value" (FIELD NOT FOUND or wrong type: ${field?.runtimeType})');
      }
    }

    void setCombo(String name, String? value) {
      if (value == null || value.isEmpty) return;
      final field = fieldMap[name];
      if (field is sf.PdfComboBoxField) {
        for (int j = 0; j < field.items.count; j++) {
          final itemText = field.items[j].text.trim();
          if (itemText == value || itemText.contains(value) || value.contains(itemText)) {
            field.selectedIndex = j;
            return;
          }
        }
        debugPrint('[SyncfusionPDF] ComboBox-Wert nicht gefunden: $name = $value');
      }
    }

    void setCheck(String name, bool checked) {
      final field = fieldMap[name];
      if (field is sf.PdfCheckBoxField) {
        field.isChecked = checked;
      }
    }

    // --- Kopf: Bezirksauswahl ---
    setCombo('IB_S1_02_02', bericht.teilhabefachdienst);

    // --- Kopfdaten ---
    setText('IB_S1_06_02', bericht.idKostenuebernahme);
    if (bericht.berichtszeitraumVon != null) {
      setText('IB_S1_07_02', df.format(bericht.berichtszeitraumVon!));
    }
    if (bericht.berichtszeitraumBis != null) {
      setText('IB_S1_07_04', df.format(bericht.berichtszeitraumBis!));
    }
    setText('IB_S1_08_02', bericht.leistungstyp);
    setText('IB_S1_09_02', bericht.leistungserbringer);
    setText('IB_S1_10_02', bericht.emailTelNr);
    setText('IB_S1_12_02', bericht.strasse);
    setText('IB_S1_13_02', bericht.hausnummer);
    setText('IB_S1_14_02', bericht.weitererAdresshinweis);
    setText('IB_S1_15_02', bericht.postleitzahl);
    setText('IB_S1_16_02', bericht.ort);

    // --- 1. Persoenliche Daten ---
    setCombo('IB_S1_18_02', bericht.anrede);
    setCombo('IB_S1_19_02', bericht.titel);
    setText('IB_S1_20_02', bericht.familienname);
    setText('IB_S1_21_02', bericht.vorname);
    setText('IB_S1_22_02', bericht.geburtsname);
    if (bericht.geburtsdatum != null) {
      setText('IB_S1_23_02', df.format(bericht.geburtsdatum!));
    }
    setText('IB_S1_24_02', bericht.geburtsort);
    setCombo('IB_S1_25_02', bericht.geschlecht);
    setCombo('IB_S1_26_02', bericht.familienstand);
    setText('IB_S1_28_02', bericht.telefonFestnetz);
    setText('IB_S1_29_02', bericht.telefonMobil);
    setText('IB_S1_30_02', bericht.email);

    // --- Seiten-Header (Seite 2+) ---
    setText('IB_gesamt_02', bericht.vorname);
    setText('IB_gesamt_04', bericht.familienname);

    // --- 2. Allgemeine Informationen ---
    setText('IB_S2_05_01', bericht.allgemeineInformationen);

    // --- 3. Teilhabeziele (erstes Ziel - Template hat Platz fuer eins) ---
    if (bericht.teilhabeziele != null && bericht.teilhabeziele!.isNotEmpty) {
      final tz = bericht.teilhabeziele!.first;
      setText('IB_S3_02_02_a', tz.leitzielNr?.toString());
      setText('IB_S3_02_03_a', tz.leitzielText);
      setText('IB_S3_03_02_a', tz.teilhabezielNr?.toString());
      setText('IB_S3_03_04_a', tz.teilhabezielText);
      setText('IB_S3_04_02_a', tz.indikator);

      if (tz.zielerreichung != null) {
        setCheck('IB_S3_06_01_a', tz.zielerreichung == ZielerreichungStatus.vollErreicht);
        setCheck('IB_S3_07_01_a', tz.zielerreichung == ZielerreichungStatus.teilweiseErreicht);
        setCheck('IB_S3_08_01_a', tz.zielerreichung == ZielerreichungStatus.nichtErreicht);
        setCheck('IB_S3_09_01_a', tz.zielerreichung == ZielerreichungStatus.nichtBeurteilbar);
      }

      if (tz.abweichendeEinschaetzung != null) {
        setCheck('IB_S3_11_01_a', tz.abweichendeEinschaetzung == false);
        setCheck('IB_S3_11_03_a', tz.abweichendeEinschaetzung == true);
      }

      setText('IB_S3_14_01_a', tz.erlaeuterung);
    }

    // --- Weitere Anmerkungen ---
    setText('IB_S4_03_01', bericht.weitereAnmerkungen);

    // --- Nacht-Assistenz ---
    if (bericht.nachtAssistenz != null) {
      setCheck('IB_S4_05_01', bericht.nachtAssistenz == false);
      setCheck('IB_S4_05_03', bericht.nachtAssistenz == true);
    }

    // --- 4. Zusammenfassung ---
    setText('IB_S8_02_01', bericht.zusammenfassung);
    setText('IB_S8_05_01', bericht.zusammenfassung);

    // --- 5. Unterschriften ---
    setText('IB_S8_08_02', bericht.ortDatum);
    setText('IB_S8_08_01', bericht.leistungserbringerUnterschrift);

    // --- 6. Eintragungen ---
    setText('IB_S8_09_01', bericht.eintragungKlient);

    // Kein flattenAllFields() - das loescht die Feldwerte bei diesem PDF.
    // Felder bleiben als ausfuellbare Formularfelder erhalten.

    final bytes = Uint8List.fromList(doc.saveSync());
    doc.dispose();
    return bytes;
  }
}
