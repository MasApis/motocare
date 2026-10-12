import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/chat_prompt_builder.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_shapes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';

/// Widget bar penginputan pesan chat diagnosa
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.isLoading,
  });

  final ValueChanged<String> onSend;
  final bool isLoading;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  late final TextEditingController _controller;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_updateCharCount);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateCharCount);
    _controller.dispose();
    super.dispose();
  }

  void _updateCharCount() {
    setState(() {
      _charCount = _controller.text.length;
    });
  }

  void _handleSend() {
    if (widget.isLoading) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isOverLimit = _charCount > ChatPromptBuilder.maxMessageLength;
    final canSend = _charCount > 0 && !isOverLimit && !widget.isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.borderSlate),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Counter karakter jika mendekati batas (di atas 200 karakter)
            if (_charCount > 200)
              Padding(
                padding: const EdgeInsets.only(
                  right: AppSpacing.sm,
                  bottom: 2,
                ),
                child: Text(
                  '$_charCount/${ChatPromptBuilder.maxMessageLength}',
                  style: AppTypography.labelCaps(
                    color: isOverLimit ? AppColors.error : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            // Bar Input & Tombol Kirim
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: AppShapes.roundedDefault,
                border: Border.all(
                  color: isOverLimit
                      ? AppColors.error
                      : AppColors.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !widget.isLoading,
                      maxLength: ChatPromptBuilder.maxMessageLength,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      style: AppTypography.bodyMd(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Tanyakan keluhan atau tips motor...',
                        hintStyle: AppTypography.bodyMd(
                          color: AppColors.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                  // Tombol Kirim berukuran sentuh >= 48x48dp
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    child: IconButton(
                      icon: widget.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(Symbols.send),
                      color: canSend ? AppColors.primary : AppColors.outline,
                      onPressed: canSend ? _handleSend : null,
                      tooltip: 'Kirim Pertanyaan',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
