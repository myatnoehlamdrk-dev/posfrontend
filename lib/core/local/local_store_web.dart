import 'package:posfrontend/core/local/local_store.dart';

/// Creates the no-op store for the web build.
///
/// Offline support is deliberately not shipped on web: the browser build is
/// always-online, so it never reads a cache and never writes one. Returning
/// [NoopLocalStore] here keeps every call site — interceptor, sync manager,
/// session wipes — compiling and behaving like the pre-cache app.
LocalStore createPlatformStore() => NoopLocalStore();
