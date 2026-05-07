import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fixitlog/main.dart';

void main() {
  testWidgets('App launches and shows login page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify the app title is displayed
    expect(find.text('Fixit Log'), findsOneWidget);

    // Verify login form fields are present
    expect(find.byType(TextField), findsNWidgets(2));

    // Verify login button exists
    expect(find.text('Login'), findsOneWidget);

    // Verify register link exists
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('Login shows error when fields are empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Tap login with empty fields
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Should show error snackbar
    expect(find.text('Please enter both email and password!'), findsOneWidget);
  });
}
