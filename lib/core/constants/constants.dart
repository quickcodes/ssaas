class Constants {
  /// Application display name
  static const String appName = 'SSAAS';

  /// Current application version (e.g. 1.0.0)
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;
  static const String fullVersion = '$appVersion+$appBuildNumber';

  /// Dev-only flag for company creation.
  /// When true: The "Create Company" button appears on the Login screen and
  /// opens the dedicated company creation screen.
  /// When false (default): General users have no option to create companies in the app.
  static const bool isAdmin = true;

  /// Threshold / buffer cap for waiving minor pending due amounts (in ₹).
  /// If the remaining due amount is strictly less than this buffer amount,
  /// it is automatically waived and marked as "Received" / settled.
  static const double dueBufferAmount = 5.0;

  /// Business Onboarding, Subscription & Support Contact Details
  static const String contactPerson = 'Dhruv Soni';
  static const String contactPhone = '9009395674';
  static const String contactPhoneFormatted = '+91 9009395674';
}
