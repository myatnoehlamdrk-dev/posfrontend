import 'package:posfrontend/features/team/domain/entities/shop_member.dart';

abstract class TeamRepository {
  Future<TeamSnapshot> getMembers({String? query});

  Future<ShopMember> approve({
    required String userId,
    required String role,
  });

  Future<void> reject(String userId);

  Future<ShopMember> update({
    required String userId,
    String? role,
    bool? activeStatus,
  });

  Future<void> remove(String userId);
}
