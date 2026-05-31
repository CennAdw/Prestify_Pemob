import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_connect_plus/app.dart';

void main() {
  testWidgets('shows UPI Connect splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const UpiConnectApp());

    expect(find.text('UPI Connect+'), findsOneWidget);
    expect(find.text('Rumah Prestasi UPI'), findsOneWidget);
    expect(find.text('Temukan Tim, Bangun Prestasi.'), findsOneWidget);
    expect(find.text('Mulai'), findsOneWidget);
  });

  testWidgets('login screen only offers student and lecturer roles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UpiConnectApp());
    await _openLogin(tester);

    expect(find.widgetWithText(ChoiceChip, 'Mahasiswa'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Dosen'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Admin'), findsNothing);
    expect(find.text('Akun Supabase Demo'), findsOneWidget);
  });
}

Future<void> _openLogin(WidgetTester tester) async {
  await tester.tap(find.text('Mulai'));
  await tester.pumpAndSettle();
}
