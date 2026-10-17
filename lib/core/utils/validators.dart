/// Reusable form validators.
///
/// Every method returns `null` when the value is valid (as required by
/// [FormFieldValidator]) or a human-readable message otherwise.
abstract final class AppValidators {
  static final RegExp _email = RegExp(
    r'^[\w.+-]+@[\w-]+\.[\w.-]{2,}$',
  );

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? name(String? value) {
    final missing = required(value, field: 'Full name');
    if (missing != null) return missing;
    if (value!.trim().length < 2) return 'Enter your full name';
    return null;
  }

  static String? email(String? value) {
    final missing = required(value, field: 'Email');
    if (missing != null) return missing;
    if (!_email.hasMatch(value!.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    final missing = required(value, field: 'Password');
    if (missing != null) return missing;
    if (value!.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final missing = required(value, field: 'Password');
    if (missing != null) return missing;
    if (value != original) return 'Passwords do not match';
    return null;
  }
}
