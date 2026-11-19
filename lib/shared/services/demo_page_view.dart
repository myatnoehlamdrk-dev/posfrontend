/// Hosts the animated demo page inside the Flutter web app.
///
/// The Get Started screen is a Flutter page on phone and desktop, but on the
/// web it is replaced by the animated landing page itself:
/// `web/demo/animate.html`, embedded in an iframe. This library resolves to a
/// web implementation and to an inert stub everywhere else, so the rest of the
/// app can import it without a platform check of its own.
library;

export 'demo_page_view_web.dart' if (dart.library.io) 'demo_page_view_io.dart';
