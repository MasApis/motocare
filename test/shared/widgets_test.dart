import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/shared/theme/app_theme.dart';
import 'package:motocare/shared/widgets/app_bottom_nav_bar.dart';
import 'package:motocare/shared/widgets/app_button.dart';
import 'package:motocare/shared/widgets/app_card.dart';
import 'package:motocare/shared/widgets/app_progress_bar.dart';
import 'package:motocare/shared/widgets/app_status_badge.dart';
import 'package:motocare/shared/widgets/app_text_field.dart';

void main() {
  group('AppButton Widget Tests', () {
    testWidgets('AppButton menampilkan teks dan merespons tap ketika aktif',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Simpan Data',
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Simpan Data'), findsOneWidget);
      await tester.tap(find.text('Simpan Data'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('AppButton menampilkan loading indicator saat isLoading true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Simpan',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Simpan'), findsNothing);
    });

    testWidgets('AppButton tidak dapat ditekan ketika onPressed bernilai null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Nonaktif',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });

  group('AppStatusBadge Widget Tests', () {
    testWidgets('AppStatusBadge menampilkan label Aman, Peringatan, dan Batas Habis',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                AppStatusBadge.safe(),
                AppStatusBadge.warning(),
                AppStatusBadge.critical(),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Aman'), findsOneWidget);
      expect(find.text('Peringatan'), findsOneWidget);
      expect(find.text('Batas habis'), findsOneWidget);
    });

    testWidgets('AppStatusBadge mendukung label kustom', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppStatusBadge.safe(label: 'Masih Bagus'),
          ),
        ),
      );

      expect(find.text('Masih Bagus'), findsOneWidget);
    });
  });

  group('AppProgressBar Widget Tests', () {
    testWidgets('AppProgressBar menampilkan label kiri dan kanan dengan benar',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppProgressBar(
              percentageUsed: 0.85,
              status: AppStatusType.critical,
              leftLabel: '85% terpakai',
              rightLabel: 'Sisa 420 km',
            ),
          ),
        ),
      );

      expect(find.text('85% terpakai'), findsOneWidget);
      expect(find.text('Sisa 420 km'), findsOneWidget);
    });
  });

  group('AppTextField Widget Tests', () {
    testWidgets('AppTextField menampilkan label kapital, helper text, dan merespons ketikan',
        (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Nama Bengkel',
              hintText: 'Ketik nama bengkel',
              helperText: 'Bengkel resmi atau umum',
            ),
          ),
        ),
      );

      // Label dikonversi menjadi huruf kapital (label-caps)
      expect(find.text('NAMA BENGKEL'), findsOneWidget);
      expect(find.text('Ketik nama bengkel'), findsOneWidget);
      expect(find.text('Bengkel resmi atau umum'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Bengkel Jaya');
      expect(controller.text, 'Bengkel Jaya');
    });

    testWidgets('AppTextField menampilkan pesan error ketika errorText diisi',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppTextField(
              label: 'KM',
              errorText: 'KM tidak boleh kosong',
            ),
          ),
        ),
      );

      expect(find.text('KM tidak boleh kosong'), findsOneWidget);
    });
  });

  group('AppCard Widget Tests', () {
    testWidgets('AppCard membungkus widget anak dan merespons tap jika onTap disediakan',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppCard(
              onTap: () {
                tapped = true;
              },
              child: const Text('Isi Kartu'),
            ),
          ),
        ),
      );

      expect(find.text('Isi Kartu'), findsOneWidget);
      await tester.tap(find.text('Isi Kartu'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('AppBottomNavBar Widget Tests', () {
    testWidgets('AppBottomNavBar menampilkan 5 tab standar dan merespons tap',
        (tester) async {
      int selectedTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: AppBottomNavBar(
              currentIndex: selectedTab,
              onTap: (index) {
                selectedTab = index;
              },
            ),
          ),
        ),
      );

      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Catat'), findsOneWidget);
      expect(find.text('Servis'), findsOneWidget);
      expect(find.text('Chat AI'), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);

      // Tap tab Catat (index 1)
      await tester.tap(find.text('Catat'));
      await tester.pump();

      expect(selectedTab, 1);
    });
  });
}
