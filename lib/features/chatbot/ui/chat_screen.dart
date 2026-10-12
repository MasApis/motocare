import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_shapes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../vehicles/providers/vehicle_providers.dart';
import '../providers/chat_providers.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_bar.dart';

/// Layar Chatbot Diagnosa (F7) sesuai docs/design/chat_bot_ai_asisten_motor/
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    this.showBackButton = false,
  });

  final bool showBackButton;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final activeVehicle = ref.watch(selectedVehicleProvider);
    final vehicleDisplayName = activeVehicle?.displayName ?? 'Motor Matic';

    // Auto-scroll saat ada pesan baru atau loading
    ref.listen<ChatState>(chatNotifierProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.isLoading != next.isLoading) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        automaticallyImplyLeading: widget.showBackButton,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Symbols.smart_toy,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'MotoAI',
                        style: AppTypography.headlineSm(),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.statusSafeBg,
                          borderRadius: AppShapes.roundedFull,
                        ),
                        child: Text(
                          'Online',
                          style: AppTypography.labelCaps(
                            color: AppColors.statusSafeText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Spesialis $vehicleDisplayName',
                    style: AppTypography.bodySm(
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (chatState.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Symbols.refresh),
              tooltip: 'Mulai Obrolan Baru',
              onPressed: () {
                ref.read(chatNotifierProvider.notifier).clearHistory();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Banner motor aktif
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            color: AppColors.surfaceContainerLow,
            child: Row(
              children: [
                const Icon(
                  Symbols.two_wheeler,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Konteks: $vehicleDisplayName (${activeVehicle?.currentKm ?? 0} km)',
                    style: AppTypography.labelMd(color: AppColors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Pesan validasi jika ada
          if (chatState.validationError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              color: AppColors.errorContainer,
              child: Row(
                children: [
                  const Icon(Symbols.error, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatState.validationError!,
                      style: AppTypography.bodySm(color: AppColors.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),

          // Daftar Pesan
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildEmptyState(vehicleDisplayName)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.xs,
                    ),
                    itemCount: chatState.messages.length +
                        (chatState.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < chatState.messages.length) {
                        return ChatBubble(
                          message: chatState.messages[index],
                        );
                      }
                      // Indikator Loading / Mengetik
                      return _buildLoadingBubble();
                    },
                  ),
          ),

          // Input Bar Bawah
          ChatInputBar(
            isLoading: chatState.isLoading,
            onSend: (text) {
              ref.read(chatNotifierProvider.notifier).sendMessage(text);
            },
          ),
        ],
      ),
    );
  }

  /// Tampilan pengantar awal sebelum ada obrolan
  Widget _buildEmptyState(String vehicleDisplayName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Symbols.smart_toy,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Selamat Datang di MotoAI!',
            style: AppTypography.headlineSm(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Saya siap membantu mendiagnosa keluhan motor matic $vehicleDisplayName Anda.',
            style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppShapes.roundedDefault,
              border: Border.all(color: AppColors.borderSlate),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Symbols.lightbulb,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Contoh Pertanyaan:',
                      style: AppTypography.labelMd(color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildExampleChip(
                  'Tarikan awal gredek dan getar saat gas dibuka pelan.',
                ),
                _buildExampleChip(
                  'Ada suara decit di area CVT saat motor melaju.',
                ),
                _buildExampleChip(
                  'Kapan waktu ideal servis besar dan ganti v-belt?',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        onTap: () {
          ref.read(chatNotifierProvider.notifier).sendMessage(text);
        },
        borderRadius: AppShapes.roundedSm,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: AppShapes.roundedSm,
          ),
          child: Row(
            children: [
              const Icon(
                Symbols.arrow_forward_ios,
                size: 12,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: AppTypography.bodySm(color: AppColors.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bubble animasi indikator mengetik / menganalisa
  Widget _buildLoadingBubble() {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(top: 2, right: AppSpacing.xs),
            decoration: const BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Symbols.smart_toy,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppShapes.roundedDefault,
              border: Border.all(color: AppColors.borderSlate),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'MotoAI sedang menganalisa...',
                  style: AppTypography.bodySm(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
