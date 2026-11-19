import 'package:posfrontend/core/auth/session_store.dart';
import 'package:posfrontend/core/auth/terminal_identity.dart';
import 'package:posfrontend/core/auth/token_storage.dart';
import 'package:posfrontend/core/di/injection.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/notifications/data/notification_store.dart';
import 'package:posfrontend/shared/services/fcm_service.dart';

/// Ends the signed-in session in one place.
///
/// Every sign-out path (drawer, settings, the 401 redirect, the splash's
/// discard) used to repeat the same three lines, and each of them forgot that
/// a device also carries *notification* state: the FCM token still pointed at
/// the old shop and the persisted history kept showing its stock alerts after
/// a different shop signed in. Keeping the teardown here means a new step
/// cannot be added to one path and missed by the others.
///
/// [notifyServer] is false when the session is already known to be dead (a
/// 401, or a launch probe the server rejected). In that case calling
/// `/auth/logout` would only produce another 401; the local cleanup below is
/// what matters.
Future<void> endSession({bool notifyServer = true}) async {
  final fcm = getIt<FcmService>();

  if (notifyServer) {
    try {
      // Piggy-backs on the existing logout request: the server deactivates
      // this device's push token in the same round trip instead of leaving it
      // as a live target for the shop the user just left. Time-boxed because
      // a sign-out must not wait on a slow backend.
      //
      // Both identifiers travel: the token may be missing when FCM never
      // initialised, and the device label may be missing on tokens registered
      // by older builds. Either one is enough for the server to find the row.
      final deviceId = await TerminalIdentity.label();
      await ApiClient.instance
          .post(
            '/auth/logout',
            data: {'fcm_token': ?fcm.token, 'device_id': deviceId},
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Logout is local-first: the token and history go even if the server
      // never hears about it.
    }
  }

  // History goes before the token, so an app killed mid-sign-out cannot leave
  // a valid token next to the old shop's alerts. `SessionStore.clear()` runs
  // the same clear again as part of the canonical teardown; doing it here
  // first is only about ordering.
  await NotificationStore.instance.clear();

  // Clear the bearer token before deleting the FCM token: once the session is
  // gone, a token refresh that lands during the delete cannot re-register the
  // device as signed in.
  await TokenStorage.clearToken();
  await fcm.clearForLogout();
  // Also clears the persisted notification history (before the cached
  // profile is removed, so an interrupted sign-out can still be cleaned up
  // by the next sign-in's shop-change check) and wipes the offline cache.
  await SessionStore.clear();
}
