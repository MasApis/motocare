import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/chat_prompt_builder.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_shapes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../data/models/chat_message_model.dart';

/// Widget bubble chat sesuai docs/design/chat_bot_ai_asisten_motor/
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    if (message.isUser) {
      return _buildUserBubble(context, timeStr);
    } else if (message.status == ChatMessageStatus.error) {
      return _buildErrorBubble(context, timeStr);
    } else {
      return _buildAiBubble(context, timeStr);
    }
  }

  /// Bubble pesan dari pengguna (rata kanan, warna primary)
  Widget _buildUserBubble(BuildContext context, String timeStr) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.sm,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppShapes.radiusMd),
            topRight: Radius.circular(4.0),
            bottomLeft: Radius.circular(AppShapes.radiusMd),
            bottomRight: Radius.circular(AppShapes.radiusMd),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: AppTypography.bodyMd(color: AppColors.onPrimary),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: AppTypography.labelCaps(
                    color: AppColors.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Symbols.done_all,
                  size: 14,
                  color: AppColors.onPrimary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Bubble pesan balasan MotoAI (rata kiri, avatar, title analisa, disclaimer)
  Widget _buildAiBubble(BuildContext context, String timeStr) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar MotoAI
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
          // Konten Balasan
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4.0),
                  topRight: Radius.circular(AppShapes.radiusMd),
                  bottomLeft: Radius.circular(AppShapes.radiusMd),
                  bottomRight: Radius.circular(AppShapes.radiusMd),
                ),
                border: Border.all(
                  color: AppColors.borderSlate.withValues(alpha: 0.6),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Analisa MotoAI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Symbols.build_circle,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Analisa MotoAI',
                            style: AppTypography.labelMd(
                              color: AppColors.primary,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        timeStr,
                        style: AppTypography.labelCaps(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16, color: AppColors.outlineVariant),
                  // Teks Jawaban Diagnosa
                  Text(
                    message.text,
                    style: AppTypography.bodyMd(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Box Pengingat / Disclaimer Wajib (SPEC F7)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: AppShapes.roundedSm,
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Symbols.info,
                          size: 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            ChatPromptBuilder.disclaimerText,
                            style: AppTypography.bodySm(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bubble pesan error yang ramah (saat jaringan offline atau API gagal)
  Widget _buildErrorBubble(BuildContext context, String timeStr) {
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
              color: AppColors.errorContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Symbols.error,
              size: 20,
              color: AppColors.error,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4.0),
                  topRight: Radius.circular(AppShapes.radiusMd),
                  bottomLeft: Radius.circular(AppShapes.radiusMd),
                  bottomRight: Radius.circular(AppShapes.radiusMd),
                ),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Symbols.warning,
                            size: 16,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Gagal Memproses',
                            style: AppTypography.labelMd(
                              color: AppColors.error,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        timeStr,
                        style: AppTypography.labelCaps(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message.text,
                    style: AppTypography.bodyMd(color: AppColors.onSurface),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
