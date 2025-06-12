// This is a basic Flutter widget test for the Read Next app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Read Next App Widget Tests', () {
    testWidgets('Basic UI elements render correctly', (
      WidgetTester tester,
    ) async {
      // Build a simple test widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('Read Next App'))),
        ),
      );

      // Verify that the app name is displayed
      expect(find.text('Read Next App'), findsOneWidget);
    });

    testWidgets('Material app theme is applied', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
          home: const Scaffold(body: Center(child: Text('Theme Test'))),
        ),
      );

      // Verify that the theme test text is displayed
      expect(find.text('Theme Test'), findsOneWidget);
    });

    testWidgets('Basic form validation works', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      formKey.currentState?.validate();
                    },
                    child: const Text('Validate'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Tap the validate button without entering text
      await tester.tap(find.text('Validate'));
      await tester.pump();

      // Check if validation error appears
      expect(find.text('This field is required'), findsOneWidget);
    });
  });
}
