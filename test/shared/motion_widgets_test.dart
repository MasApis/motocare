import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/shared/widgets/app_entrance.dart';
import 'package:motocare/shared/widgets/app_pressable.dart';

void main() {
  Widget wrap(Widget child, {bool disableAnimations = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  double opacityOf(WidgetTester tester) => tester
      .widget<Opacity>(
        find.descendant(
          of: find.byType(AppEntrance),
          matching: find.byType(Opacity),
        ),
      )
      .opacity;

  group('AppEntrance', () {
    testWidgets('mulai transparan lalu tampil penuh setelah animasi', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const AppEntrance(child: Text('Kartu'))));
      expect(opacityOf(tester), 0);

      await tester.pumpAndSettle();
      expect(opacityOf(tester), 1);
      expect(find.text('Kartu'), findsOneWidget);
    });

    testWidgets('langsung tampil penuh jika animasi dimatikan di HP', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const AppEntrance(index: 3, child: Text('Kartu')),
          disableAnimations: true,
        ),
      );
      expect(opacityOf(tester), 1);
    });
  });

  group('AppPressable', () {
    testWidgets('mengecil saat ditekan dan tetap meneruskan ketukan', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        wrap(
          AppPressable(
            child: ElevatedButton(
              onPressed: () => tapped++,
              child: const Text('Simpan'),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Simpan')),
      );
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        lessThan(1),
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      expect(tapped, 1);
    });
  });
}
