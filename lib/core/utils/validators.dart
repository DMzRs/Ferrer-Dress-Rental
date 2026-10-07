/// Form field validation helpers.
class Validators {
  Validators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$',
  );

  /// Validates an email address field.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegExp.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  /// Validates a minimum-length password field.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  /// Validates a full name field.
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    if (value.trim().length < 3) return 'Please enter your complete name';
    return null;
  }

  /// Validates a phone number field.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) return 'Enter a valid phone number';
    return null;
  }

  /// Validates that a field is not empty.
  static String? notEmpty(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  /// Validates a positive numeric field.
  static String? positiveNumber(String? value, {String label = 'Amount'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return 'Enter a valid $label';
    return null;
  }
}
