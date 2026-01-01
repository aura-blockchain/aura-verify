// Basic smoke test for AuraVerifyBusiness app
//
// This test verifies that the app can be instantiated and built without errors.

import 'package:flutter_test/flutter_test.dart';
import 'package:aura_verify_business/app/app.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AuraVerifyBusinessApp());

    // Verify that the app starts successfully
    // (expect some widget to exist - we just verify no crash)
    expect(find.byType(AuraVerifyBusinessApp), findsOneWidget);
  });
}
