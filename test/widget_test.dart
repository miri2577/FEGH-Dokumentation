// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:eingliederungshilfe_flutter/main.dart';
import 'package:eingliederungshilfe_flutter/services/security_service.dart';

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final mockSecurityStatus = SecurityStatus();
    await tester.pumpWidget(EingliederungshilfeApp(securityStatus: mockSecurityStatus));

    // Verify that the app loads and shows loading indicator initially
    expect(find.text('Eingliederungshilfe wird geladen...'), findsOneWidget);
  });
}
