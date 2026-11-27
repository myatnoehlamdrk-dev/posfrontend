import 'package:posfrontend/features/team/data/datasources/team_remote_data_source.dart';
import 'package:posfrontend/features/team/domain/entities/shop_member.dart';
import 'package:posfrontend/features/team/domain/repositories/team_repository.dart';

class TeamRepositoryImpl implements TeamRepository {
  final TeamRemoteDataSource _remoteDataSource;

  TeamRepositoryImpl({TeamRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? TeamRemoteDataSource();

  @override
  Future<TeamSnapshot> getMembers({String? query}) async {
    final result = await _remoteDataSource.getMembers(query: query);
    return result.toEntity();
  }

  @override
  Future<ShopMember> approve({
    required String userId,
    required String role,
  }) async {
    final result = await _remoteDataSource.approve(userId: userId, role: role);
    return result.toEntity();
  }

  @override
  Future<void> reject(String userId) => _remoteDataSource.reject(userId);

  @override
  Future<ShopMember> update({
    required String userId,
    String? role,
    bool? activeStatus,
  }) async {
    final result = await _remoteDataSource.update(
      userId: userId,
      role: role,
      activeStatus: activeStatus,
    );
    return result.toEntity();
  }

  @override
  Future<void> remove(String userId) => _remoteDataSource.remove(userId);
}
