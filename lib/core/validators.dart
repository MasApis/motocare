// Pure input-validation helpers used by auth forms.
//
// All error messages are in Indonesian (id_ID).
// Each function returns `null` when the input is valid,
// or an error-message [String] when invalid.

/// Validates an email address.
///
/// Rules:
/// - Must not be empty/null.
/// - Must contain `@` followed by at least one `.` in the domain part.
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email tidak boleh kosong';
  }

  // Simple regex: local@domain with at least one dot after @.
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Format email tidak valid';
  }

  return null;
}

/// Validates a password.
///
/// Rules:
/// - Must not be empty/null.
/// - Must be at least 6 characters long.
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Kata sandi tidak boleh kosong';
  }

  if (value.length < 6) {
    return 'Kata sandi minimal 6 karakter';
  }

  return null;
}

/// Validates that a confirmation password matches the original [password].
///
/// Rules:
/// - Must not be empty/null.
/// - Must be identical to [password].
String? validateConfirmPassword(String? value, String password) {
  if (value == null || value.isEmpty) {
    return 'Konfirmasi kata sandi tidak boleh kosong';
  }

  if (value != password) {
    return 'Kata sandi tidak cocok';
  }

  return null;
}
