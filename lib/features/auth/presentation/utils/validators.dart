/// Email validation using regex
String? validateEmail(String? email) {
  if (email == null || email.isEmpty) {
    return 'Email is required';
  }

  const emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  final regExp = RegExp(emailRegex);

  if (!regExp.hasMatch(email)) {
    return 'Please enter a valid email';
  }

  return null;
}

/// Password validation
/// Requirements: 8+ chars, uppercase, number, special character
String? validatePassword(String? password) {
  if (password == null || password.isEmpty) {
    return 'Password is required';
  }

  if (password.length < 8) {
    return 'Password must be at least 8 characters';
  }

  if (!password.contains(RegExp(r'[A-Z]'))) {
    return 'Password must contain uppercase letter';
  }

  if (!password.contains(RegExp(r'[0-9]'))) {
    return 'Password must contain number';
  }

  if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
    return 'Password must contain special character (!@#\$%^&*)';
  }

  return null;
}

/// Validate password confirmation match
String? validatePasswordMatch(String? password, String? confirmPassword) {
  if (confirmPassword == null || confirmPassword.isEmpty) {
    return 'Please confirm password';
  }

  if (password != confirmPassword) {
    return 'Passwords do not match';
  }

  return null;
}

/// Validate all signup inputs
Map<String, String?> validateSignupInputs({
  required String email,
  required String password,
  required String confirmPassword,
}) {
  return {
    'email': validateEmail(email),
    'password': validatePassword(password),
    'confirmPassword': validatePasswordMatch(password, confirmPassword),
  };
}

/// Validate all login inputs
Map<String, String?> validateLoginInputs({
  required String email,
  required String password,
}) {
  return {
    'email': validateEmail(email),
    'password': password.isEmpty ? 'Password is required' : null,
  };
}

/// Check if all validations pass (no errors)
bool isValidationSuccessful(Map<String, String?> validations) {
  return validations.values.every((error) => error == null);
}
