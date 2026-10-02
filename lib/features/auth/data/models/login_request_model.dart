class LoginRequestModel {
  final String email;
  final String password;
  final String? deviceName;

  const LoginRequestModel({
    required this.email,
    required this.password,
    this.deviceName,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    // Names the resulting session. A POS till is shared hardware, so the label
    // is what lets an admin answer "which till is signed in right now" from
    // `GET /auth/sessions` and kill one device without touching the rest.
    if (deviceName != null) 'device_name': deviceName,
  };
}