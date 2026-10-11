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

    // Verifikasi teks judul pratinjau di AppBar dan tab navigasi
    expect(find.text('MotoCare UI Preview'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Catat'), findsOneWidget);
  });
}
