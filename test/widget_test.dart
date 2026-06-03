import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_connect_plus/app.dart';

void main() {
  testWidgets('shows Prestify splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const UpiConnectApp());

    expect(find.text('Prestify'), findsOneWidget);
    expect(find.text('Prestasi Mahasiswa dalam Satu Platform'), findsOneWidget);
    expect(find.text('Temukan Tim, Bangun Prestasi.'), findsOneWidget);
    expect(find.text('Mulai'), findsOneWidget);
  });

  testWidgets('login screen explains verified automatic role access', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UpiConnectApp());
    await _openLogin(tester);

    expect(find.text('Akses Terverifikasi'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Login menggunakan Google'), findsOneWidget);
    expect(find.text('Email / NIM'), findsNothing);
    expect(find.text('Password'), findsNothing);
  });
}

Future<void> _openLogin(WidgetTester tester) async {
  await tester.tap(find.text('Mulai'));
  await tester.pumpAndSettle();
}
