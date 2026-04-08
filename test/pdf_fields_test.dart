import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  test('Extract PDF form fields', () {
    final bytes = File('/Users/mirkorichter/Desktop/Flutter Projekt aktuell/fls/eingliederungshilfe_flutter/assets/informationsbericht_101.pdf').readAsBytesSync();
    final doc = PdfDocument(inputBytes: bytes);
    final form = doc.form;
    print('=== PDF Form Fields: ${form.fields.count} ===');
    for (int i = 0; i < form.fields.count; i++) {
      final field = form.fields[i];
      final type = field.runtimeType.toString();
      String info = 'Field[$i]: name="${field.name}", type=$type';
      if (field is PdfTextBoxField) {
        info += ', text="${field.text}", multiline=${field.multiline}';
      } else if (field is PdfComboBoxField) {
        info += ', selectedIndex=${field.selectedIndex}, items=[';
        for (int j = 0; j < field.items.count; j++) {
          info += '"${field.items[j].text}"';
          if (j < field.items.count - 1) info += ', ';
        }
        info += ']';
      } else if (field is PdfCheckBoxField) {
        info += ', isChecked=${field.isChecked}';
      }
      print(info);
    }
    doc.dispose();
  });

  test('Fill and save test PDF', () {
    final bytes = File('/Users/mirkorichter/Desktop/Flutter Projekt aktuell/fls/eingliederungshilfe_flutter/assets/informationsbericht_101.pdf').readAsBytesSync();
    final doc = PdfDocument(inputBytes: bytes);
    final form = doc.form;

    // Try to fill the first text field we find
    for (int i = 0; i < form.fields.count; i++) {
      final field = form.fields[i];
      if (field is PdfTextBoxField) {
        field.text = 'TEST_${field.name}';
        print('Set text field: ${field.name} = "TEST_${field.name}"');
      } else if (field is PdfComboBoxField && field.items.count > 1) {
        field.selectedIndex = 1;
        print('Set combo: ${field.name} to index 1 = "${field.items[1].text}"');
      } else if (field is PdfCheckBoxField) {
        field.isChecked = true;
        print('Checked: ${field.name}');
      }
    }

    // Save WITHOUT flattening first to see if fields are visible
    final outBytes = doc.saveSync();
    final outFile = File('/tmp/pdf_test_filled_not_flat.pdf');
    outFile.writeAsBytesSync(outBytes);
    print('Saved non-flattened to: ${outFile.path}');

    doc.dispose();

    // Now do another pass with flattening
    final bytes2 = File('/Users/mirkorichter/Desktop/Flutter Projekt aktuell/fls/eingliederungshilfe_flutter/assets/informationsbericht_101.pdf').readAsBytesSync();
    final doc2 = PdfDocument(inputBytes: bytes2);
    final form2 = doc2.form;

    for (int i = 0; i < form2.fields.count; i++) {
      final field = form2.fields[i];
      if (field is PdfTextBoxField) {
        field.text = 'TEST_${field.name}';
      } else if (field is PdfComboBoxField && field.items.count > 1) {
        field.selectedIndex = 1;
      } else if (field is PdfCheckBoxField) {
        field.isChecked = true;
      }
    }

    form2.flattenAllFields();
    final outBytes2 = doc2.saveSync();
    final outFile2 = File('/tmp/pdf_test_filled_flat.pdf');
    outFile2.writeAsBytesSync(outBytes2);
    print('Saved flattened to: ${outFile2.path}');

    doc2.dispose();
  });
}
