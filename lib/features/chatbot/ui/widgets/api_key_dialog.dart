import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_shapes.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../providers/api_key_providers.dart';

/// Dialog untuk menempel, mengganti, atau menghapus kunci API Groq.
///
/// Kunci disimpan di perangkat (Android Keystore), tidak dikirim ke server
/// mana pun selain Groq saat chat dipakai.
class ApiKeyDialog extends ConsumerStatefulWidget {
  const ApiKeyDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const ApiKeyDialog(),
    );
  }

  @override
  ConsumerState<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends ConsumerState<ApiKeyDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(apiKeyProvider).key ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Kunci tidak boleh kosong.');
      return;
    }
    if (!value.startsWith('gsk_')) {
      setState(() => _error = 'Kunci Groq biasanya diawali "gsk_". Periksa kembali.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ref.read(apiKeyProvider.notifier).save(value);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunci tersimpan. Chat AI siap dipakai.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Kunci gagal disimpan. Coba lagi.';
      });
    }
  }

  Future<void> _remove() async {
    setState(() => _isSaving = true);
    await ref.read(apiKeyProvider.notifier).clear();
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kunci dihapus dari perangkat.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = ref.watch(apiKeyProvider).key?.isNotEmpty ?? false;

    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: AppShapes.roundedDefault),
      title: Row(
        children: [
          const Icon(Symbols.key, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text('Kunci API Groq', style: AppTypography.headlineSm()),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat AI memakai kunci Groq milik Anda sendiri, jadi kuota '
              'gratis Anda yang terpakai. Kunci disimpan hanya di HP ini.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Buat kunci gratis di console.groq.com/keys, lalu tempel di bawah.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _controller,
              label: 'Kunci API',
              hintText: 'gsk_...',
              obscureText: _obscure,
              errorText: _error,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Symbols.visibility : Symbols.visibility_off,
                  size: 20,
                ),
                tooltip: _obscure ? 'Tampilkan kunci' : 'Sembunyikan kunci',
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (hasKey)
          TextButton(
            onPressed: _isSaving ? null : _remove,
            child: Text(
              'Hapus kunci',
              style: AppTypography.labelMd(color: AppColors.error),
            ),
          ),
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Batal',
            style: AppTypography.labelMd(color: AppColors.onSurfaceVariant),
          ),
        ),
        SizedBox(
          width: 120,
          height: 44,
          child: AppButton(
            text: 'Simpan',
            isLoading: _isSaving,
            height: 44,
            onPressed: _save,
          ),
        ),
      ],
    );
  }
}
