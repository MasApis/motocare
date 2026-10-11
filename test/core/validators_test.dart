import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/validators.dart';

void main() {
  group('validateEmail', () {
    test('mengembalikan error jika null', () {
      expect(validateEmail(null), 'Email tidak boleh kosong');
    });

    test('mengembalikan error jika string kosong', () {
      expect(validateEmail(''), 'Email tidak boleh kosong');
    });

    test('mengembalikan error jika hanya spasi', () {
      expect(validateEmail('   '), 'Email tidak boleh kosong');
    });

    test('mengembalikan error jika tidak ada @', () {
      expect(validateEmail('namaemail.com'), 'Format email tidak valid');
    });

    test('mengembalikan error jika tidak ada titik setelah @', () {
      expect(validateEmail('nama@emailcom'), 'Format email tidak valid');
    });

    test('mengembalikan error jika tidak ada domain setelah @', () {
      expect(validateEmail('nama@'), 'Format email tidak valid');
    });

    test('mengembalikan null (valid) untuk email normal', () {
      expect(validateEmail('user@example.com'), isNull);
    });

    test('mengembalikan null (valid) untuk email dengan subdomain', () {
      expect(validateEmail('user@mail.example.co.id'), isNull);
    });

    test('mengembalikan null (valid) untuk email dengan spasi di sekitarnya', () {
      expect(validateEmail(' user@example.com '), isNull);
    });
  });

  group('validatePassword', () {
    test('mengembalikan error jika null', () {
      expect(validatePassword(null), 'Kata sandi tidak boleh kosong');
    });

    test('mengembalikan error jika string kosong', () {
      expect(validatePassword(''), 'Kata sandi tidak boleh kosong');
    });

    test('mengembalikan error jika kurang dari 6 karakter', () {
      expect(validatePassword('abc'), 'Kata sandi minimal 6 karakter');
    });

    test('mengembalikan error jika tepat 5 karakter', () {
      expect(validatePassword('12345'), 'Kata sandi minimal 6 karakter');
    });

    test('mengembalikan null (valid) jika tepat 6 karakter', () {
      expect(validatePassword('123456'), isNull);
    });

    test('mengembalikan null (valid) jika lebih dari 6 karakter', () {
      expect(validatePassword('sandiaman123'), isNull);
    });
  });

  group('validateConfirmPassword', () {
    test('mengembalikan error jika null', () {
      expect(
        validateConfirmPassword(null, 'password'),
        'Konfirmasi kata sandi tidak boleh kosong',
      );
    });

    test('mengembalikan error jika string kosong', () {
      expect(
        validateConfirmPassword('', 'password'),
        'Konfirmasi kata sandi tidak boleh kosong',
      );
    });

    test('mengembalikan error jika tidak cocok', () {
      expect(
        validateConfirmPassword('passwordlain', 'password'),
        'Kata sandi tidak cocok',
      );
    });

    test('mengembalikan null (valid) jika cocok', () {
      expect(
        validateConfirmPassword('password123', 'password123'),
        isNull,
      );
    });

    test('mengembalikan error jika berbeda huruf besar/kecil', () {
      expect(
        validateConfirmPassword('Password', 'password'),
        'Kata sandi tidak cocok',
      );
    });
  });
}
