import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:posfrontend/core/local/sync_manager.dart';
import 'package:posfrontend/core/network/connectivity.dart';
import 'package:posfrontend/core/offline/offline_writes_flag.dart';
import 'package:posfrontend/core/offline/outbox_queue.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';

/// The strip that tells the cashier what the data on screen actually is.
///
/// ## Why this exists
///
/// An offline cache is only honest if the UI says so. A catalog served from
/// a database looks exactly like a catalog served from the server, and a
/// cashier who believes stock is live when it is six hours old will sell
/// something that is not on the shelf. So whenever the app is not looking
/// at the real server, this banner is visible — with *when* the data was
/// last confirmed, not just that it is saved.
///
/// ## States
///
/// - **Offline** — amber strip: reads are coming from the local database.
///   The timestamp is the last successful sync under this session; when it
///   is missing (never synced) the strip says so without a time rather than
///   inventing one.
/// - **Syncing** — a refresh is running after a reconnect or resume. Shown
///   even while online, because until it finishes the cache may still be
///   what screens read.
/// - **Failed** — the app believed it was online but the refresh could not
///   reach the server. Distinct from offline on purpose: connectivity is
///   wrong, and the next trigger will try again.
/// - **Queued writes** — when [OfflineWrites] is enabled and there are
///   pending or failed outbox entries, the strip appends "N queued" or
///   "N failed" so a cashier can see that a sale is waiting to reach the
///   server.
/// - **Online and idle with no queued writes** — no strip at all (zero
///   height, not an invisible gap).
///
/// It sits above the navigator in `MaterialApp.builder` rather than in any
/// one screen or in `AppShell`, because the sale screen — the screen that
/// matters most when the internet drops — does not use `AppShell`, and a
/// status that disappears on some screens is a status nobody trusts.
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = ConnectivityService.instance;
    final sync = SyncManager.instance;
    final outbox = OutboxQueue.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([
        connectivity.isOnline,
        sync.state,
        sync.lastSyncedAt,
        if (OfflineWrites.enabled) ...[
          outbox.pendingCount,
          outbox.failedCount,
        ],
      ]),
      builder: (context, _) {
        final online = connectivity.isOnline.value;
        final syncState = sync.state.value;
        final pending = outbox.pendingCount.value;
        final failed = outbox.failedCount.value;

        if (online &&
            syncState == SyncState.idle &&
            pending == 0 &&
            failed == 0) {
          return const SizedBox.shrink();
        }

        final (message, icon) = switch ((online, syncState)) {
          (false, _) => (
            context.l10n.t('Offline — showing saved data'),
            Icons.cloud_off,
          ),
          (true, SyncState.syncing) => (context.l10n.t('Syncing…'), Icons.sync),
          (true, SyncState.failed) => (
            context.l10n.t('Refresh failed'),
            Icons.sync_problem,
          ),
          _ => (context.l10n.t('Waiting to sync'), Icons.cloud_upload),
        };

        final lastSynced = sync.lastSyncedAt.value;
        final time = (online && syncState != SyncState.syncing) || lastSynced == null
            ? ''
            : ' · ${DateFormat.Hm().format(lastSynced.toLocal())}';

        final pendingSuffix =
            pending > 0
                ? ' · ${context.l10n.t('{v1} queued').replaceAll('{v1}', '$pending')}'
                : '';
        final failedSuffix =
            failed > 0
                ? ' · ${context.l10n.t('{v1} failed').replaceAll('{v1}', '$failed')}'
                : '';

        return Material(
          color: const Color(0xFFB26A00),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$message$time$pendingSuffix$failedSuffix',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (syncState == SyncState.syncing)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
