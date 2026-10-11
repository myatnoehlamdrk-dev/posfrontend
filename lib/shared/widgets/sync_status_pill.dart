import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:posfrontend/core/local/sync_manager.dart';
import 'package:posfrontend/core/network/connectivity.dart';
import 'package:posfrontend/core/offline/offline_writes_flag.dart';
import 'package:posfrontend/core/offline/outbox_queue.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';

/// A small floating pill showing sync status in the top-right corner.
///
/// Replaces the full-width [SyncStatusBanner] with a minimal indicator that:
/// - Uses minimal vertical space (~28dp height)
/// - Floats at top-right, below status bar
/// - Shows state at a glance with color + icon + short label
/// - Expands on tap to show details (timestamp, queue counts)
class SyncStatusPill extends StatefulWidget {
  const SyncStatusPill({super.key});

  @override
  State<SyncStatusPill> createState() => _SyncStatusPillState();
}

class _SyncStatusPillState extends State<SyncStatusPill> {
  OverlayEntry? _overlayEntry;
  bool _expanded = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
    if (_expanded) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildOverlay(),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 36, // below pill
      right: 8,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => _toggleExpanded(),
          behavior: HitTestBehavior.translucent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: _buildDetailLines(),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDetailLines() {
    final connectivity = ConnectivityService.instance;
    final sync = SyncManager.instance;
    final outbox = OutboxQueue.instance;

    final online = connectivity.isOnline.value;
    final syncState = sync.state.value;
    final pending = outbox.pendingCount.value;
    final failed = outbox.failedCount.value;
    final lastSynced = sync.lastSyncedAt.value;

    final lines = <Widget>[];

    // Main status
    final (mainLabel, mainIcon, mainColor) = _getStatus(online, syncState, pending, failed);
    lines.add(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(mainIcon, size: 16, color: mainColor),
          const SizedBox(width: 8),
          Text(
            mainLabel,
            style: TextStyle(color: mainColor, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );

    // Last synced time
    if (lastSynced != null && (online || !online && syncState != SyncState.syncing)) {
      lines.add(const SizedBox(height: 8));
      lines.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              'Last synced: ${DateFormat.Hm().format(lastSynced.toLocal())}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Queued writes
    if (pending > 0) {
      lines.add(const SizedBox(height: 6));
      lines.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pending_actions, size: 14, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              '$pending sale${pending > 1 ? 's' : ''} queued',
              style: const TextStyle(color: Colors.amber, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Failed writes
    if (failed > 0) {
      lines.add(const SizedBox(height: 6));
      lines.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              '$failed failed',
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return lines;
  }

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

        // Hide when fully synced and no queue
        if (online &&
            syncState == SyncState.idle &&
            pending == 0 &&
            failed == 0) {
          return const SizedBox.shrink();
        }

        final (label, icon, color) = _getStatus(online, syncState, pending, failed);

        return Positioned(
          top: MediaQuery.of(context).padding.top + 4,
          right: 8,
          child: GestureDetector(
            onTap: _toggleExpanded,
            onLongPress: _toggleExpanded,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_expanded) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_up, size: 13, color: Colors.white),
                  ] else ...[
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 13, color: Colors.white.withValues(alpha: 0.7)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  (String, IconData, Color) _getStatus(
    bool online,
    SyncState syncState,
    int pending,
    int failed,
  ) {
    if (!online) {
      return ('Offline', Icons.cloud_off, const Color(0xFFB26A00));
    }
    if (syncState == SyncState.syncing) {
      return ('Syncing', Icons.sync, Colors.blueAccent);
    }
    if (syncState == SyncState.failed) {
      return ('Refresh failed', Icons.sync_problem, Colors.redAccent);
    }
    if (failed > 0) {
      return ('$failed failed', Icons.error_outline, Colors.redAccent);
    }
    if (pending > 0) {
      return ('$pending queued', Icons.pending_actions, Colors.amber);
    }
    return ('Online', Icons.cloud_done, Colors.green);
  }
}