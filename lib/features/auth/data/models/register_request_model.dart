class RegisterRequestModel {
  final String fullName;
  final String email;
  final String password;
  final String? phone;
  final String? social;
  final String? address;
  final String? nrc;
  final String? billingWay;
  final String? dob;
  final String? gender;
  final String? shopId;

  /// A shop to create alongside the account, pre-serialised by the repository.
  final Map<String, dynamic>? shop;

  const RegisterRequestModel({
    required this.fullName,
    required this.email,
    required this.password,
    this.phone,
    this.social,
    this.address,
    this.nrc,
    this.billingWay,
    this.dob,
    this.gender,
    this.shopId,
    this.shop,
  });

  // `role` is deliberately absent. Roles are assigned by the server: the
  // account that creates the shop becomes its owner, and a linked account
  // stays a cashier until the owner or a manager chooses otherwise at
  // approval. The backend ignores the field even if an older build sends it.
  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'password': password,
    'phone': phone,
    'social': social,
    'address': address,
    'nrc': nrc,
    'billingWay': billingWay,
    'dob': dob,
    'gender': gender,
    'shopId': shopId,
    'shop': shop,
  };
}
