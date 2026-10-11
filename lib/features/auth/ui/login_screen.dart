import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../../core/validators.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_shapes.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/auth_repository.dart';
import '../providers/auth_providers.dart';

/// Layar Login dan Daftar Akun (F1)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Hapus error sebelumnya
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isLogin) {
        await authRepo.signInWithEmailAndPassword(email, password);
      } else {
        await authRepo.createUserWithEmailAndPassword(email, password);
      }
      // Navigasi ditangani oleh router redirect (authStateProvider)
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(
        () => _errorMessage =
            'Terjadi kesalahan. Periksa koneksi internet dan coba lagi.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              // Header: logo + nama aplikasi
              _buildHeader(),
              const SizedBox(height: AppSpacing.lg),
              // Judul sambutan
              _buildWelcomeSection(),
              const SizedBox(height: AppSpacing.lg),
              // Tab Masuk / Daftar
              _buildTabSwitch(),
              const SizedBox(height: AppSpacing.lg),
              // Form Card
              _buildFormCard(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Symbols.two_wheeler,
            size: 20,
            color: AppColors.onPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'MotoCare',
          style: AppTypography.headlineSm(color: AppColors.primary).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selamat Datang\ndi MotoCare',
          style: AppTypography.headlineLg(),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Pantau kesehatan dan rawat motormu dengan cerdas & mandiri langsung dari smartphone.',
          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildTabSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: AppShapes.roundedFull,
      ),
      child: Row(
        children: [
          _buildTab(
            label: 'Masuk',
            icon: Symbols.login,
            isActive: _isLogin,
            onTap: () => setState(() {
              _isLogin = true;
              _errorMessage = null;
              _formKey.currentState?.reset();
            }),
          ),
          _buildTab(
            label: 'Daftar Akun',
            icon: Symbols.person_add,
            isActive: !_isLogin,
            onTap: () => setState(() {
              _isLogin = false;
              _errorMessage = null;
              _formKey.currentState?.reset();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: AppShapes.roundedFull,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? AppColors.onPrimary
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelMd(
                  color: isActive
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppShapes.roundedDefault,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error message banner
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm + 4),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: AppShapes.roundedSm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Symbols.error,
                      size: 20,
                      color: AppColors.onErrorContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style:
                            AppTypography.bodySm(color: AppColors.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            // Email field
            _buildLabel('Email'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: AppTypography.bodyMd(),
              validator: validateEmail,
              decoration: _inputDecoration(
                hint: 'nama@email.com',
                prefixIcon: Symbols.mail,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Password field
            _buildLabel('Kata Sandi'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction:
                  _isLogin ? TextInputAction.done : TextInputAction.next,
              style: AppTypography.bodyMd(),
              validator: validatePassword,
              onFieldSubmitted: _isLogin ? (_) => _submit() : null,
              decoration: _inputDecoration(
                hint: 'Masukkan kata sandi',
                prefixIcon: Symbols.key,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Symbols.visibility
                        : Symbols.visibility_off,
                    size: 20,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            // Confirm password (only for register)
            if (!_isLogin) ...[
              const SizedBox(height: AppSpacing.md),
              _buildLabel('Konfirmasi Kata Sandi'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                style: AppTypography.bodyMd(),
                validator: (value) =>
                    validateConfirmPassword(value, _passwordController.text),
                onFieldSubmitted: (_) => _submit(),
                decoration: _inputDecoration(
                  hint: 'Masukkan ulang kata sandi',
                  prefixIcon: Symbols.key,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Symbols.visibility
                          : Symbols.visibility_off,
                      size: 20,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            // Submit button
            AppButton(
              text: _isLogin ? 'Masuk ke Akun' : 'Daftar Akun',
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
              icon: Icon(
                _isLogin ? Symbols.arrow_forward : Symbols.person_add,
                size: 20,
                color: AppColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTypography.labelMd(),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMd(color: AppColors.outline),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Icon(prefixIcon, size: 20, color: AppColors.onSurfaceVariant),
      ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 48,
      ),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppShapes.radiusDefault),
        borderSide: const BorderSide(
          color: AppColors.outlineVariant,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppShapes.radiusDefault),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppShapes.radiusDefault),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppShapes.radiusDefault),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 2.0,
        ),
      ),
      errorStyle: AppTypography.bodySm(color: AppColors.error),
    );
  }
}
