class Constants {
  /// Application display name
  static const String appName = 'SSAAS';

  /// Dev-only flag for company creation.
  /// When true: The "Create Company" button appears on the Login screen and
  /// opens the dedicated company creation screen.
  /// When false (default): General users have no option to create companies in the app.
  static const bool isAdmin = false;

  /// Threshold / buffer cap for waiving minor pending due amounts (in ₹).
  /// If the remaining due amount is strictly less than this buffer amount,
  /// it is automatically waived and marked as "Received" / settled.
  static const double dueBufferAmount = 5.0;

  /// Business Onboarding, Subscription & Support Contact Details
  static const String contactPerson = 'Dhruv Soni';
  static const String contactPhone = '9009395674';
  static const String contactPhoneFormatted = '+91 9009395674';
}
