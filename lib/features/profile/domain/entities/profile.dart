import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String type;
  final String phone;
  final String social;
  final String image;
  final String imageDeleteUrl;
  final String role;
  final String address;
  final String status;
  final String nrcNo;
  final String billingWay;
  final String dateOfBirth;
  final String gender;
  final bool activeStatus;
  final String shopId;
  final String shopName;

  const ProfileEntity({
    required this.id,
    required this.fullName,
    required this.email,
    this.type = '',
    this.phone = '',
    this.social = '',
    this.image = '',
    this.imageDeleteUrl = '',
    this.role = '',
    this.address = '',
    this.status = '',
    this.nrcNo = '',
    this.billingWay = '',
    this.dateOfBirth = '',
    this.gender = '',
    this.activeStatus = true,
    this.shopId = '',
    this.shopName = '',
  });

  @override
  List<Object?> get props => [id];
}
