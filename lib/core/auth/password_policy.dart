/// The password rule the API enforces on the endpoints covered here:
/// register (`min:6`) and forgot-password reset (`min:6`).
///
/// Profile's change-password is stricter at `min:8` and keeps its own check
/// in `profile_view_model.dart`.
///
/// Lives here rather than on a request model so presentation code can check it
/// without importing anything from the data layer. The server remains
/// authoritative; this only saves the round trip and gives the user feedback
/// before the tap rather than after it.
class PasswordPolicy {
  PasswordPolicy._();

  static const int minLength = 6;
}