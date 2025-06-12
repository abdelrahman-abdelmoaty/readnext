import 'package:flutter_test/flutter_test.dart';

// Helper class to test validation methods without Firebase initialization
class AuthValidationHelper {
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Name is required';
    }

    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }
}

void main() {
  group('Authentication Validation Tests', () {
    group('Email Validation', () {
      test('should return null for valid email', () {
        expect(AuthValidationHelper.validateEmail('test@example.com'), isNull);
        expect(
          AuthValidationHelper.validateEmail('user.name@domain.co.uk'),
          isNull,
        );
        expect(AuthValidationHelper.validateEmail('test123@gmail.com'), isNull);
        expect(
          AuthValidationHelper.validateEmail('user+tag@example.org'),
          isNull,
        );
      });

      test('should return error for invalid email', () {
        expect(AuthValidationHelper.validateEmail(''), isNotNull);
        expect(AuthValidationHelper.validateEmail('   '), isNotNull);
        expect(AuthValidationHelper.validateEmail('invalid-email'), isNotNull);
        expect(AuthValidationHelper.validateEmail('test@'), isNotNull);
        expect(AuthValidationHelper.validateEmail('@domain.com'), isNotNull);
        expect(
          AuthValidationHelper.validateEmail('test.domain.com'),
          isNotNull,
        );
        expect(AuthValidationHelper.validateEmail('test@domain'), isNotNull);
      });

      test('should return error for null email', () {
        expect(AuthValidationHelper.validateEmail(null), isNotNull);
      });
    });

    group('Password Validation', () {
      test('should return null for valid password', () {
        expect(AuthValidationHelper.validatePassword('Password123'), isNull);
        expect(AuthValidationHelper.validatePassword('MySecure1Pass'), isNull);
        expect(AuthValidationHelper.validatePassword('Test1234'), isNull);
        expect(
          AuthValidationHelper.validatePassword('Complex9Password'),
          isNull,
        );
      });

      test('should return error for invalid password', () {
        expect(AuthValidationHelper.validatePassword(''), isNotNull);
        expect(AuthValidationHelper.validatePassword('short'), isNotNull);
        expect(
          AuthValidationHelper.validatePassword('nouppercase1'),
          isNotNull,
        );
        expect(
          AuthValidationHelper.validatePassword('NOLOWERCASE1'),
          isNotNull,
        );
        expect(AuthValidationHelper.validatePassword('NoNumbers'), isNotNull);
        expect(AuthValidationHelper.validatePassword('1234567'), isNotNull);
        expect(AuthValidationHelper.validatePassword('Short1'), isNotNull);
      });

      test('should return error for null password', () {
        expect(AuthValidationHelper.validatePassword(null), isNotNull);
      });
    });

    group('Name Validation', () {
      test('should return null for valid name', () {
        expect(AuthValidationHelper.validateName('John Doe'), isNull);
        expect(AuthValidationHelper.validateName('Alice'), isNull);
        expect(AuthValidationHelper.validateName('Bob Smith Jr.'), isNull);
        expect(AuthValidationHelper.validateName('María García'), isNull);
        expect(AuthValidationHelper.validateName('李小明'), isNull);
      });

      test('should return error for invalid name', () {
        expect(AuthValidationHelper.validateName(''), isNotNull);
        expect(AuthValidationHelper.validateName('   '), isNotNull);
        expect(AuthValidationHelper.validateName('A'), isNotNull);
        expect(AuthValidationHelper.validateName(' '), isNotNull);
      });

      test('should return error for null name', () {
        expect(AuthValidationHelper.validateName(null), isNotNull);
      });
    });
  });
}
