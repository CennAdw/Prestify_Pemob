const String allowedEmailDomain = 'upi.edu';

bool isAllowedUpiEmail(String email) {
  final normalized = email.trim().toLowerCase();
  final parts = normalized.split('@');
  return parts.length == 2 &&
      parts.first.isNotEmpty &&
      parts.last == allowedEmailDomain;
}

String normalizeAcademicIdentifier(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), '');
}
