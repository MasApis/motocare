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

/// Validates odometer reading input according to docs/SPEC.md (F4 & 2.1).
///
/// Rules:
/// - Must not be empty/null.
/// - Must be a valid non-negative integer.
/// - New KM must not be lower than [currentKm].
String? validateOdometerInput(String? value, int currentKm) {
  if (value == null || value.trim().isEmpty) {
    return 'Kilometer tidak boleh kosong';
  }

  final cleaned = value.trim().replaceAll('.', '').replaceAll(',', '');
  final parsed = int.tryParse(cleaned);

  if (parsed == null) {
    return 'Kilometer harus berupa angka yang valid';
  }

  if (parsed < 0) {
    return 'Kilometer tidak boleh bernilai negatif';
  }

  if (parsed < currentKm) {
    return 'KM baru tidak boleh lebih kecil dari KM terakhir ($currentKm KM)';
  }

  return null;
}
