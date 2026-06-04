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

  testWidgets('login screen offers NIM password and Google login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UpiConnectApp());
    await _openLogin(tester);

    expect(find.text('NIM / NIDN'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login menggunakan Google'), findsOneWidget);
    expect(find.text('Daftar sekarang'), findsOneWidget);
  });

  testWidgets('registration screen requests UPI account and academic data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UpiConnectApp());
    await _openLogin(tester);

    await tester.scrollUntilVisible(
      find.text('Daftar sekarang'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Daftar sekarang'));
    await tester.pumpAndSettle();

    expect(find.text('Buat akun baru'), findsOneWidget);
    expect(find.text('Email UPI'), findsOneWidget);
    expect(find.text('NIM / NIDN'), findsOneWidget);
    expect(find.text('Nama lengkap'), findsOneWidget);
    expect(find.text('Fakultas'), findsOneWidget);
    expect(find.text('Daftar Sekarang'), findsOneWidget);
  });
}

Future<void> _openLogin(WidgetTester tester) async {
  await tester.tap(find.text('Mulai'));
  await tester.pumpAndSettle();
}
