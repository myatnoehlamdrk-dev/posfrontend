/// Opens the standalone animated demo page (`marketing/site/animate.html`).
///
/// The page is plain HTML kept beside this project, so it is never rendered by
/// Flutter: the app hands it to the platform browser instead. This is a demo
/// detour for the Get Started screen, not part of the onboarding flow.
library;

export 'demo_page_launcher_web.dart'
    if (dart.library.io) 'demo_page_launcher_io.dart';
