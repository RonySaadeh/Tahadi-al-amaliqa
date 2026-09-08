/// Pure form-validation helpers. Return `null` when valid, or an error
/// message key/string to show under the field otherwise.
class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'required';
    if (!_emailPattern.hasMatch(value.trim())) return 'invalidEmail';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'required';
    if (value.length < 8) return 'passwordTooShort';
    return null;
  }

  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) return 'required';
    if (value.trim().length < 2) return 'nameTooShort';
    if (value.trim().length > 24) return 'nameTooLong';
    return null;
  }

  static String? categoryName(String? value) {
    if (value == null || value.trim().isEmpty) return 'required';
    if (value.trim().length > 30) return 'nameTooLong';
    return null;
  }

  static String? questionText(String? value) {
    if (value == null || value.trim().isEmpty) return 'required';
    if (value.trim().length > 240) return 'textTooLong';
    return null;
  }
}
