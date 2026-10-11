import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/main.dart';

void main() {
  testWidgets('Aplikasi MotoCare menampilkan layar awal dan judul dengan benar',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MotoCareApp(),
      ),
    );

    // Saat belum masuk, aplikasi otomatis menampilkan layar Login / Registrasi
    await tester.pumpAndSettle();
    expect(find.text('Selamat Datang\ndi MotoCare'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Daftar Akun'), findsOneWidget);
  });
}
