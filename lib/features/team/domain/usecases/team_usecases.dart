import 'package:posfrontend/core/base/use_case.dart';
import 'package:posfrontend/features/team/domain/entities/shop_member.dart';
import 'package:posfrontend/features/team/domain/repositories/team_repository.dart';

class GetTeamMembersUseCase extends UseCase<TeamSnapshot, TeamQueryParams> {
  final TeamRepository _repository;

  GetTeamMembersUseCase(this._repository);

  @override
  Future<TeamSnapshot> call(TeamQueryParams params) =>
      _repository.getMembers(query: params.query);
}

class ApproveMemberUseCase extends UseCase<ShopMember, ApproveMemberParams> {
  final TeamRepository _repository;

  ApproveMemberUseCase(this._repository);

  @override
  Future<ShopMember> call(ApproveMemberParams params) => _repository.approve(
    userId: params.userId,
    role: params.role,
  );
}

class RejectMemberUseCase extends UseCase<void, MemberIdParams> {
  final TeamRepository _repository;

  RejectMemberUseCase(this._repository);

  @override
  Future<void> call(MemberIdParams params) => _repository.reject(params.userId);
}

class UpdateMemberUseCase extends UseCase<ShopMember, UpdateMemberParams> {
  final TeamRepository _repository;

  UpdateMemberUseCase(this._repository);

  @override
  Future<ShopMember> call(UpdateMemberParams params) => _repository.update(
    userId: params.userId,
    role: params.role,
    activeStatus: params.activeStatus,
  );
}

class RemoveMemberUseCase extends UseCase<void, MemberIdParams> {
  final TeamRepository _repository;

  RemoveMemberUseCase(this._repository);

  @override
  Future<void> call(MemberIdParams params) => _repository.remove(params.userId);
}

class TeamQueryParams {
  final String? query;

  const TeamQueryParams({this.query});
}

class ApproveMemberParams {
  final String userId;
  final String role;

  const ApproveMemberParams({required this.userId, required this.role});
}

class UpdateMemberParams {
  final String userId;
  final String? role;
  final bool? activeStatus;

  const UpdateMemberParams({
    required this.userId,
    this.role,
    this.activeStatus,
  });
}

class MemberIdParams {
  final String userId;

  const MemberIdParams({required this.userId});
}
