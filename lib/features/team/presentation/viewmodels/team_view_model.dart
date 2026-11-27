import 'package:posfrontend/core/base/base_view_model.dart';
import 'package:posfrontend/features/team/domain/entities/shop_member.dart';
import 'package:posfrontend/features/team/domain/usecases/team_usecases.dart';

/// State for the Team & Access screen.
///
/// The actor's `isOwner` is injected by the screen from the cached session
/// rather than fetched: it only decides which actions are offered, and the
/// backend independently enforces the same rule. Hiding a button is a courtesy,
/// not the permission check.
class TeamViewModel extends BaseViewModel {
  final GetTeamMembersUseCase _getMembers;
  final ApproveMemberUseCase _approve;
  final RejectMemberUseCase _reject;
  final UpdateMemberUseCase _update;
  final RemoveMemberUseCase _remove;

  final bool isOwner;

  TeamViewModel({
    required GetTeamMembersUseCase getMembers,
    required ApproveMemberUseCase approve,
    required RejectMemberUseCase reject,
    required UpdateMemberUseCase update,
    required RemoveMemberUseCase remove,
    this.isOwner = false,
  }) : _getMembers = getMembers,
       _approve = approve,
       _reject = reject,
       _update = update,
       _remove = remove;

  TeamSnapshot? _snapshot;
  TeamSnapshot? get snapshot => _snapshot;

  String _query = '';
  String get query => _query;

  void setQuery(String value) => _query = value;

  Future<void> load() async {
    final result = await runAsync(
      (_) => _getMembers(const TeamQueryParams()),
      showLoading: _snapshot == null,
    );
    if (result != null) _snapshot = result;
  }

  Future<bool> approve(String userId, String role) => _mutate(() async {
    await _approve(ApproveMemberParams(userId: userId, role: role));
  });

  Future<bool> reject(String userId) => _mutate(() async {
    await _reject(MemberIdParams(userId: userId));
  });

  Future<bool> changeRole(String userId, String role) => _mutate(() async {
    await _update(UpdateMemberParams(userId: userId, role: role));
  });

  Future<bool> setActive(String userId, bool active) => _mutate(() async {
    await _update(UpdateMemberParams(userId: userId, activeStatus: active));
  });

  Future<bool> remove(String userId) => _mutate(() async {
    await _remove(MemberIdParams(userId: userId));
  });

  /// Runs one decision and refreshes the list. Refetching rather than editing
  /// the local list matters: the server may have changed another member in the
  /// meantime, and a stale row that still says "pending" is worse than a
  /// short spinner.
  Future<bool> _mutate(Future<void> Function() action) async {
    final ok = await runAsync((_) async {
      await action();
      return true;
    });
    if (ok != true) return false;

    await load();
    return true;
  }
}
