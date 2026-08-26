class RegisterRequest {
  final String fullName;
  final String email;
  final String password;
  final String? phone;
  final String? social;
  final String? role;
  final String? address;
  final String? nrc;
  final String? billingWay;
  final String? dob;
  final String? gender;
  final String? shopId;

  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    this.phone,
    this.social,
    this.role,
    this.address,
    this.nrc,
    this.billingWay,
    this.dob,
    this.gender,
    this.shopId,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phone': phone,
        'social': social,
        'role': role,
        'address': address,
        'nrc': nrc,
        'billingWay': billingWay,
        'dob': dob,
        'gender': gender,
        'shopId': shopId,
      };
}
