/// The password rule the API enforces on every password-setting endpoint
/// (register, change password, forgot-password reset).
///
/// Lives here rather than on a request model so presentation code can check it
/// without importing anything from the data layer. The server remains
/// authoritative; this only saves the round trip and gives the user feedback
/// before the tap rather than after it.
class PasswordPolicy {
  PasswordPolicy._();

  static const int minLength = 6;
}