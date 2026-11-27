import 'package:flutter/material.dart';
import 'package:posfrontend/core/di/injection.dart';
import 'package:posfrontend/shared/l10n/app_strings.dart';
import 'package:posfrontend/features/team/domain/entities/shop_member.dart';
import 'package:posfrontend/features/team/domain/usecases/team_usecases.dart';
import 'package:posfrontend/features/team/presentation/viewmodels/team_view_model.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/app_shell.dart';
import 'package:posfrontend/shared/widgets/refreshable_body.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';
import 'package:posfrontend/shared/widgets/auth_scope.dart';

/// Owner/manager screen for deciding who may use the shop.
///
/// Role is chosen at approval time, not at registration: a link request starts
/// as a cashier and the owner promotes it only after recognising the person.
/// The screen mirrors the backend's limits (a manager cannot touch a manager
/// or the owner, and cannot promote to manager) so those actions are not
/// offered, but the server remains the authority.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TeamViewModel _viewModel;
  bool _viewModelInitialized = false;
  int _tab = 0;

  static const List<String> _assignableRoles = ['cashier', 'manager', 'viewer'];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // AuthScope is an InheritedWidget, so it cannot be read from initState.
    // Build the owner-scoped view model on the first dependency pass instead;
    // later theme/locale changes do not need a fresh TeamViewModel.
    if (_viewModelInitialized) return;
    _viewModelInitialized = true;
    final user = AuthScope.userOf(context);
    _viewModel = TeamViewModel(
      getMembers: getIt<GetTeamMembersUseCase>(),
      approve: getIt<ApproveMemberUseCase>(),
      reject: getIt<RejectMemberUseCase>(),
      update: getIt<UpdateMemberUseCase>(),
      remove: getIt<RemoveMemberUseCase>(),
      isOwner: user?.isOwner ?? false,
    );
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  bool get _canManage =>
      (AuthScope.userOf(context)?.canManageTeam ?? false);

  Future<void> _refresh() => _viewModel.load();

  @override
  Widget build(BuildContext context) {
    return AppShell(
      active: DrawerDestination.setting,
      scaffoldKey: _scaffoldKey,
      backgroundColor: Colors.transparent,
      wrap: (_, shell) => shell,
      body: (context, isWide) => SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: context.l10n.t('Team & Access'),
              showBackButton: true,
              showMenuButton: false,
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  final snapshot = _viewModel.snapshot;
                  final pending = snapshot?.pending ?? const <ShopMember>[];
                  final members = snapshot?.members ?? const <ShopMember>[];

                  return RefreshableBody(
                    onRefresh: _refresh,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_canManage)
                            AppMessageBanner(
                              message: context.l10n.t(
                                'Only the shop owner or a manager can view this page.',
                              ),
                              kind: AppMessageKind.warning,
                            )
                          else ...[
                            if (_viewModel.hasError)
                              AppMessageBanner(
                                message: _viewModel.errorMessage!,
                                kind: AppMessageKind.error,
                                onAction: _refresh,
                                actionLabel: AppStrings.of(context).retry,
                              ),
                            _buildTabs(snapshot),
                            const SizedBox(height: 16),
                            Expanded(
                              child: snapshot == null
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _tab == 0
                                  ? _list(
                                      pending,
                                      empty: context.l10n.t(
                                        'No pending requests.',
                                      ),
                                      builder: _pendingCard,
                                    )
                                  : _list(
                                      members,
                                      empty: context.l10n.t('No members yet.'),
                                      builder: _memberCard,
                                    ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(TeamSnapshot? snapshot) {
    final p = context.palette;
    final pendingCount = snapshot?.pendingCount ?? 0;
    final activeCount = snapshot?.activeCount ?? 0;

    return Row(
      children: [
        _tabButton(0, 'Pending', pendingCount),
        const SizedBox(width: 8),
        _tabButton(1, 'Members', activeCount),
        const Spacer(),
        Text(
          context.l10n.t('Shop access is managed here.'),
          style: TextStyle(color: p.textMuted, fontSize: AppTypography.labelSmallSize),
        ),
      ],
    );
  }

  Widget _tabButton(int index, String label, int count) {
    final p = context.palette;
    final active = _tab == index;

    return InkWell(
      onTap: () => setState(() => _tab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? p.selectionTint : p.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? p.primary : p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.t(label),
              style: TextStyle(
                color: active ? p.primary : p.textSecondary,
                fontSize: AppTypography.bodySmallSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: active ? p.primary : p.chipBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: active ? p.accentText : p.textSecondary,
                  fontSize: AppTypography.labelSmallSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(
    List<ShopMember> members, {
    required String empty,
    required Widget Function(ShopMember) builder,
  }) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 48, color: context.palette.textMuted),
            const SizedBox(height: 12),
            Text(
              empty,
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: AppTypography.bodyMediumSize,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: members.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => builder(members[index]),
    );
  }

  Widget _pendingCard(ShopMember member) {
    final p = context.palette;
    String role = 'cashier';

    return StatefulBuilder(
      builder: (context, setCardState) {
        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _identity(member),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    context.l10n.t('Approve as'),
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: AppTypography.bodySmallSize,
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: role,
                    items: [
                      for (final item in _assignableRoles)
                        DropdownMenuItem<String>(
                          value: item,
                          child: Text(_roleLabel(item)),
                        ),
                    ],
                    onChanged: _viewModel.isLoading
                        ? null
                        : (value) => setCardState(() => role = value ?? 'cashier'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _viewModel.isLoading
                          ? null
                          : () => _approve(member, role),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(context.l10n.t('Approve')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _viewModel.isLoading
                          ? null
                          : () => _reject(member),
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(context.l10n.t('Decline')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _memberCard(ShopMember member) {
    final p = context.palette;
    final editable = member.isEditableBy(_viewModel.isOwner);
    final role = _assignableRoles.contains(member.role.toLowerCase())
        ? member.role.toLowerCase()
        : 'cashier';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _identity(member)),
              const SizedBox(width: 8),
              _chip(
                member.activeStatus
                    ? context.l10n.t('Active')
                    : context.l10n.t('Disabled'),
                active: member.activeStatus,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                context.l10n.t('Role'),
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: AppTypography.bodySmallSize,
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: role,
                items: [
                  for (final item in _assignableRoles)
                    DropdownMenuItem<String>(
                      value: item,
                      child: Text(_roleLabel(item)),
                    ),
                ],
                onChanged: !editable || _viewModel.isLoading
                    ? null
                    : (value) {
                        if (value != null && value != role) {
                          _changeRole(member, value);
                        }
                      },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: !editable || _viewModel.isLoading
                    ? null
                    : () => _setActive(member, !member.activeStatus),
                icon: Icon(
                  member.activeStatus ? Icons.person_off_outlined : Icons.person_outline,
                  size: 18,
                ),
                label: Text(
                  member.activeStatus
                      ? context.l10n.t('Disable')
                      : context.l10n.t('Enable'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: !editable || _viewModel.isLoading
                    ? null
                    : () => _remove(member),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(context.l10n.t('Remove')),
                style: TextButton.styleFrom(foregroundColor: AppColors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _identity(ShopMember member) {
    final p = context.palette;
    final initial = member.fullName.trim().isEmpty
        ? '?'
        : member.fullName.trim()[0].toUpperCase();

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: p.selectionTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                color: p.primary,
                fontWeight: FontWeight.w700,
                fontSize: AppTypography.bodyMediumSize,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.fullName,
                style: TextStyle(
                  color: p.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: AppTypography.bodyMediumSize,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                member.email,
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: AppTypography.labelSmallSize,
                ),
              ),
              if (member.joinedAt != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${context.l10n.t('Joined')}: ${member.joinedAt!.toLocal().toString().split(' ').first}',
                  style: TextStyle(
                    color: p.textMuted,
                    fontSize: AppTypography.labelSmallSize,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, {required bool active}) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: active ? p.successBg : p.warningBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? p.successFg : p.warningFg,
          fontSize: AppTypography.labelSmallSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(color: p.cardShadow, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  String _roleLabel(String role) {
    if (role.isEmpty) return 'Cashier';
    return role[0].toUpperCase() + role.substring(1);
  }

  Future<void> _approve(ShopMember member, String role) async {
    final ok = await _viewModel.approve(member.id, role);
    if (!mounted) return;
    if (ok) {
      showSuccessSnackBar(context, '${member.fullName} approved.');
    } else if (_viewModel.hasError) {
      showErrorSnackBar(context, _viewModel.errorMessage!);
    }
  }

  Future<void> _reject(ShopMember member) async {
    final confirmed = await _confirm(
      'Decline request?',
      '${member.fullName} will not be able to sign in to this shop.',
    );
    if (!confirmed || !mounted) return;

    final ok = await _viewModel.reject(member.id);
    if (!mounted) return;
    if (ok) {
      showSuccessSnackBar(context, 'Request declined.');
    } else if (_viewModel.hasError) {
      showErrorSnackBar(context, _viewModel.errorMessage!);
    }
  }

  Future<void> _changeRole(ShopMember member, String role) async {
    final ok = await _viewModel.changeRole(member.id, role);
    if (!mounted) return;
    if (ok) {
      showSuccessSnackBar(context, 'Role updated.');
    } else if (_viewModel.hasError) {
      showErrorSnackBar(context, _viewModel.errorMessage!);
    }
  }

  Future<void> _setActive(ShopMember member, bool active) async {
    final ok = await _viewModel.setActive(member.id, active);
    if (!mounted) return;
    if (ok) {
      showSuccessSnackBar(
        context,
        active ? 'Member enabled.' : 'Member disabled.',
      );
    } else if (_viewModel.hasError) {
      showErrorSnackBar(context, _viewModel.errorMessage!);
    }
  }

  Future<void> _remove(ShopMember member) async {
    final confirmed = await _confirm(
      'Remove member?',
      '${member.fullName} will lose access. Their sales history is kept.',
    );
    if (!confirmed || !mounted) return;

    final ok = await _viewModel.remove(member.id);
    if (!mounted) return;
    if (ok) {
      showSuccessSnackBar(context, 'Member removed.');
    } else if (_viewModel.hasError) {
      showErrorSnackBar(context, _viewModel.errorMessage!);
    }
  }

  Future<bool> _confirm(String title, String body) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.l10n.t(title)),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.l10n.t('Cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.red),
                child: Text(context.l10n.t('Confirm')),
              ),
            ],
          ),
        ) ??
        false;
  }
}
