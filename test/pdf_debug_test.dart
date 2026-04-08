import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  test('Debug: Fill specific fields and verify', () {
    final bytes = File('/Users/mirkorichter/Desktop/Flutter Projekt aktuell/fls/eingliederungshilfe_flutter/assets/informationsbericht_101.pdf').readAsBytesSync();
    final doc = PdfDocument(inputBytes: bytes);
    final form = doc.form;

    print('=== Total fields: ${form.fields.count} ===');

    // Build field map
    final fieldMap = <String, PdfField>{};
    for (int i = 0; i < form.fields.count; i++) {
      final name = form.fields[i].name;
      if (name != null) fieldMap[name] = form.fields[i];
    }

    // Test 1: Set a specific text field
    final testField = fieldMap['IB_S1_06_02'];
    print('Field IB_S1_06_02: type=${testField?.runtimeType}, exists=${testField != null}');
    if (testField is PdfTextBoxField) {
      print('  Before: text="${testField.text}"');
      testField.text = 'TESTVALUE_123';
      print('  After: text="${testField.text}"');
    }

    // Test 2: Set Familienname
    final famField = fieldMap['IB_S1_20_02'];
    print('Field IB_S1_20_02: type=${famField?.runtimeType}');
    if (famField is PdfTextBoxField) {
      print('  Before: text="${famField.text}"');
      famField.text = 'Mustermann';
      print('  After: text="${famField.text}"');
    }

    // Test 3: Set Vorname
    final vorField = fieldMap['IB_S1_21_02'];
    print('Field IB_S1_21_02: type=${vorField?.runtimeType}');
    if (vorField is PdfTextBoxField) {
      print('  Before: text="${vorField.text}"');
      vorField.text = 'Max';
      print('  After: text="${vorField.text}"');
    }

    // Test 4: ComboBox
    final combo = fieldMap['IB_S1_02_02'];
    print('Field IB_S1_02_02: type=${combo?.runtimeType}');
    if (combo is PdfComboBoxField) {
      print('  Before: selectedIndex=${combo.selectedIndex}');
      combo.selectedIndex = 2;
      print('  After: selectedIndex=${combo.selectedIndex}');
    }

    // Test 5: Allgemeine Infos
    final allgField = fieldMap['IB_S2_05_01'];
    print('Field IB_S2_05_01: type=${allgField?.runtimeType}');
    if (allgField is PdfTextBoxField) {
      print('  Before: text="${allgField.text}", multiline=${allgField.multiline}');
      allgField.text = 'Dies ist ein Testtext fuer allgemeine Informationen.';
      print('  After: text="${allgField.text}"');
    }

    // Save WITHOUT flatten
    final outNoFlat = doc.saveSync();
    File('/tmp/pdf_debug_no_flatten.pdf').writeAsBytesSync(outNoFlat);
    print('\nSaved without flatten: /tmp/pdf_debug_no_flatten.pdf (${outNoFlat.length} bytes)');

    doc.dispose();

    // Now try again WITH flatten
    final bytes2 = File('/Users/mirkorichter/Desktop/Flutter Projekt aktuell/fls/eingliederungshilfe_flutter/assets/informationsbericht_101.pdf').readAsBytesSync();
    final doc2 = PdfDocument(inputBytes: bytes2);
    final form2 = doc2.form;

    final fieldMap2 = <String, PdfField>{};
    for (int i = 0; i < form2.fields.count; i++) {
      final name = form2.fields[i].name;
      if (name != null) fieldMap2[name] = form2.fields[i];
    }

    (fieldMap2['IB_S1_06_02'] as PdfTextBoxField).text = 'TESTVALUE_123';
    (fieldMap2['IB_S1_20_02'] as PdfTextBoxField).text = 'Mustermann';
    (fieldMap2['IB_S1_21_02'] as PdfTextBoxField).text = 'Max';
    (fieldMap2['IB_S1_02_02'] as PdfComboBoxField).selectedIndex = 2;
    (fieldMap2['IB_S2_05_01'] as PdfTextBoxField).text = 'Testtext allgemeine Informationen.';

    form2.flattenAllFields();
    final outFlat = doc2.saveSync();
    File('/tmp/pdf_debug_flatten.pdf').writeAsBytesSync(outFlat);
    print('Saved with flatten: /tmp/pdf_debug_flatten.pdf (${outFlat.length} bytes)');

    doc2.dispose();

    // Now re-read the non-flattened version to verify the values persisted
    print('\n=== Re-reading non-flattened PDF to verify ===');
    final reBytes = File('/tmp/pdf_debug_no_flatten.pdf').readAsBytesSync();
    final reDoc = PdfDocument(inputBytes: reBytes);
    final reForm = reDoc.form;
    for (int i = 0; i < reForm.fields.count; i++) {
      final field = reForm.fields[i];
      if (field is PdfTextBoxField && field.text.isNotEmpty && !field.text.startsWith('Land ') && !field.text.startsWith('Teilhabe')) {
        if (field.text.contains('TEST') || field.text.contains('Muster') || field.text == 'Max') {
          print('  FOUND: ${field.name} = "${field.text}"');
        }
      }
      if (field is PdfComboBoxField && field.selectedIndex > 0) {
        print('  FOUND COMBO: ${field.name} = index ${field.selectedIndex} = "${field.items[field.selectedIndex].text}"');
      }
    }
    reDoc.dispose();
  });

  test('Debug: Check if form is read-only or has flags', () {
    final bytes = File('/Users/mirkorichter/Desktop/Flutter Projekt aktuell/fls/eingliederungshilfe_flutter/assets/informationsbericht_101.pdf').readAsBytesSync();
    final doc = PdfDocument(inputBytes: bytes);
    final form = doc.form;

    print('=== Form properties ===');
    print('readOnly: ${form.readOnly}');

    // Check individual field flags
    for (int i = 0; i < form.fields.count; i++) {
      final field = form.fields[i];
      if (field is PdfTextBoxField) {
        if (field.name == 'IB_S1_06_02' || field.name == 'IB_S1_20_02' || field.name == 'IB_S2_05_01') {
          print('Field ${field.name}: readOnly=${field.readOnly}, text="${field.text}"');
        }
      }
    }

    doc.dispose();
  });

  test('Debug: Try alternative approach - set text and check page annotations', () {
    final bytes = File('/Users/mirkorichter/Desktop/Flutter Projekt aktuell/fls/eingliederungshilfe_flutter/assets/informationsbericht_101.pdf').readAsBytesSync();
    final doc = PdfDocument(inputBytes: bytes);

    print('Pages: ${doc.pages.count}');

    // Check annotations on each page
    for (int p = 0; p < doc.pages.count; p++) {
      final page = doc.pages[p];
      print('Page $p: annotations=${page.annotations.count}');
      for (int a = 0; a < page.annotations.count; a++) {
        final ann = page.annotations[a];
        print('  Ann[$a]: type=${ann.runtimeType}');
      }
    }

    doc.dispose();
  });
}
