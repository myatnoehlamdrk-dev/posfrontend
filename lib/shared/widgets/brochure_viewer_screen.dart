// The single import callers need for the client brochure viewer.
//
// `webview_flutter` ships no web implementation, and `dart:js_interop` only
// exists on web, so the two halves of the viewer are chosen at compile time
// instead of branched at runtime. `dart.library.io` is true on every native
// target (Android, iOS, desktop) and false on web, so:
//
//   * native -> brochure_viewer_native.dart (platform WebView)
//   * web    -> brochure_viewer_web.dart    (opens the bundled file in a tab)
//
// The half that is not chosen is never compiled, which is what keeps each
// platform's build free of the other one's imports -- and is why the web
// bundle cannot be broken by a package it has no use for.
export 'brochure_viewer_web.dart'
    if (dart.library.io) 'brochure_viewer_native.dart';
