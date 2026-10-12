import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:motocare/core/chat_prompt_builder.dart';
import 'package:motocare/features/chatbot/data/chat_repository.dart';
import 'package:motocare/features/chatbot/providers/chat_providers.dart';
import 'package:motocare/features/chatbot/ui/chat_screen.dart';

/// Fake ChatRepository untuk pengujian widget
class FakeChatRepository implements ChatRepository {
  FakeChatRepository({this.shouldThrow = false, this.reply = 'Dugaan CVT gredek karena roller aus.'});

  bool shouldThrow;
  String reply;

  @override
  Future<String> sendMessage({
    required String systemInstruction,
    required List<({String role, String text})> history,
    required String userMessage,
  }) async {
    if (shouldThrow) {
      throw const ChatException(
        'Koneksi internet terputus. Mohon periksa sambungan internet Anda dan coba lagi.',
      );
    }
    return reply;
  }
}

void main() {
  testWidgets('ChatScreen menampilkan empty state dan contoh pertanyaan awal',
      (WidgetTester tester) async {
    final fakeRepo = FakeChatRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    expect(find.text('Selamat Datang di MotoAI!'), findsOneWidget);
    expect(find.text('Contoh Pertanyaan:'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Mengirim pertanyaan menampilkan bubble user dan balasan AI beserta disclaimer',
      (WidgetTester tester) async {
    final fakeRepo = FakeChatRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    final inputFinder = find.byType(TextField);
    await tester.enterText(inputFinder, 'Tarikan motor saya berat');
    await tester.pump();

    // Tekan kirim
    final sendButtonFinder = find.byTooltip('Kirim Pertanyaan');
    expect(sendButtonFinder, findsOneWidget);
    await tester.tap(sendButtonFinder);

    // Pump untuk state loading
    await tester.pump();
    expect(find.text('Tarikan motor saya berat'), findsOneWidget);

    // Pump dan settle untuk menerima respon AI
    await tester.pumpAndSettle();

    // Verifikasi bubble AI dan disclaimer
    expect(find.text('Dugaan CVT gredek karena roller aus.'), findsOneWidget);
    expect(find.text('Analisa MotoAI'), findsOneWidget);
    expect(find.text(ChatPromptBuilder.disclaimerText), findsOneWidget);
  });

  testWidgets('Menampilkan bubble pesan error ramah saat terjadi kendala jaringan',
      (WidgetTester tester) async {
    final fakeRepo = FakeChatRepository(shouldThrow: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    final inputFinder = find.byType(TextField);
    await tester.enterText(inputFinder, 'Kenapa motor mati mendadak?');
    await tester.pump();

    final sendButtonFinder = find.byTooltip('Kirim Pertanyaan');
    await tester.tap(sendButtonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Gagal Memproses'), findsOneWidget);
    expect(
      find.text('Koneksi internet terputus. Mohon periksa sambungan internet Anda dan coba lagi.'),
      findsOneWidget,
    );
  });

  testWidgets('Tombol kirim nonaktif saat input kosong dan tombol refresh membersihkan riwayat obrolan',
      (WidgetTester tester) async {
    final fakeRepo = FakeChatRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    // Tombol kirim nonaktif saat input kosong
    final sendButtonFinder = find.widgetWithIcon(IconButton, Symbols.send);
    final iconButton = tester.widget<IconButton>(sendButtonFinder);
    expect(iconButton.onPressed, isNull);

    // Ketik pesan dan kirim
    final inputFinder = find.byType(TextField);
    await tester.enterText(inputFinder, 'V-belt bunyi decit');
    await tester.pump();

    final activeIconButton = tester.widget<IconButton>(sendButtonFinder);
    expect(activeIconButton.onPressed, isNotNull);

    await tester.tap(sendButtonFinder);
    await tester.pumpAndSettle();

    // Pesan muncul dan tombol refresh/mulai obrolan baru terlihat
    expect(find.text('V-belt bunyi decit'), findsOneWidget);
    final refreshButtonFinder = find.byTooltip('Mulai Obrolan Baru');
    expect(refreshButtonFinder, findsOneWidget);

    // Tekan tombol refresh
    await tester.tap(refreshButtonFinder);
    await tester.pumpAndSettle();

    // Riwayat kembali kosong (empty state)
    expect(find.text('Selamat Datang di MotoAI!'), findsOneWidget);
    expect(find.text('V-belt bunyi decit'), findsNothing);
  });
}
