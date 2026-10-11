import 'package:flutter_test/flutter_test.dart';
import 'package:posfrontend/core/auth/session_store.dart';
import 'package:posfrontend/core/local/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'offline_cache_interceptor_test.dart' show FakeLocalStore;

/// The rules that keep one shop's cached responses off another shop's
/// screen on a shared device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLocalStore store;

  setUp(() {
    store = FakeLocalStore();
    LocalStore.instanceForTesting = store;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => LocalStore.instanceForTesting = null);

  Map<String, dynamic> profile(String shopId) => {
    'id': '1',
    'fullName': 'Cashier',
    'email': 'a@b.c',
    'shopId': shopId,
    'role': 'owner',
  };

  test('first login does not wipe (there is nothing to wipe)', () async {
    await SessionStore.save(profile('shop-a'), 'token');

    expect(store.wipes, 0);
  });

  test('re-login under the same shop keeps the cache', () async {
    await SessionStore.save(profile('shop-a'), 'token');
    await SessionStore.save(profile('shop-a'), 'token-2');

    expect(store.wipes, 0, reason: 'the catalog belongs to the shop, not the '
        'user; two cashiers of one shop share cached products');
  });

  test('login under a different shop wipes the cache', () async {
    await SessionStore.save(profile('shop-a'), 'token');
    await SessionStore.save(profile('shop-b'), 'token');

    expect(store.wipes, 1);
  });

  test('logout wipes the cache', () async {
    await SessionStore.save(profile('shop-a'), 'token');

    await SessionStore.clear();

    expect(store.wipes, 1);
  });

  test('currentShopId reads the session profile', () async {
    expect(await SessionStore.currentShopId(), isNull);

    await SessionStore.save(profile('shop-a'), 'token');
    expect(await SessionStore.currentShopId(), 'shop-a');

    await SessionStore.clear();
    expect(await SessionStore.currentShopId(), isNull);
  });
}
