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

  testWidgets('student role opens student dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UpiConnectApp());
    await _openLogin(tester);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Halo, Candra'), findsOneWidget);
    expect(find.text('Profil Skill'), findsOneWidget);
  });

  testWidgets('lecturer role opens lecturer dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UpiConnectApp());
    await _openLogin(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Dosen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Dosen'), findsOneWidget);
    expect(find.text('Request Bimbingan Masuk'), findsOneWidget);
  });

  testWidgets('admin role opens admin dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const UpiConnectApp());
    await _openLogin(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Admin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Admin'), findsWidgets);
    expect(find.text('Rumah Prestasi UPI'), findsOneWidget);
  });

  testWidgets('student can request to join a team', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UpiConnectApp());
    await _openLogin(tester);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cari'));
    await tester.pumpAndSettle();
    final detailButton = find.text('Detail').first;
    await tester.ensureVisible(detailButton);
    await tester.tap(detailButton);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ajukan Bergabung'));
    await tester.tap(find.text('Ajukan Bergabung'));
    await tester.pumpAndSettle();

    expect(find.text('Berhasil'), findsOneWidget);
    await tester.tap(find.text('Oke'));
    await tester.pumpAndSettle();
    expect(find.text('Menunggu Persetujuan'), findsOneWidget);
  });
}

Future<void> _openLogin(WidgetTester tester) async {
  await tester.tap(find.text('Mulai'));
  await tester.pumpAndSettle();
}
