import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:medical_intervention_app/main.dart'; // adapte si ton nom de projet est différent

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MedicalApp());

    // Comme il ne s'agit pas d'une app avec un compteur de base,
    // le test ci-dessous risque d'échouer sauf si tu as un texte '0' affiché.

    // Tu peux soit adapter le test à ton app,
    // soit simplement le supprimer s’il vient du template Flutter par défaut.

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
