import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/brochure_viewer_chrome.dart';

/// The brochure on the web build.
///
/// `webview_flutter` has no web implementation, so there is no in-page
/// document surface to hand the HTML to here. The bundled file is opened in a
/// browser tab instead -- the same document, one tap away. This library is
/// only reached when `dart:io` is absent, i.e. on web, which is also why the
/// WebView implementation is never compiled into the web bundle.
class BrochureViewerScreen extends StatefulWidget {
  const BrochureViewerScreen({super.key});

  @override
  State<BrochureViewerScreen> createState() => _BrochureViewerScreenState();
}

class _BrochureViewerScreenState extends State<BrochureViewerScreen> {
  String _lang = BrochureSpec.initialLang();

  /// Called from a tap, so the browser treats it as a wanted popup rather
  /// than blocking an opener opened from the navigation itself.
  void _open() => openInNewTab(BrochureSpec.assetFor(_lang), '_blank');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrochureSpec.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            BrochureTopBar(
              title: BrochureSpec.titleFor(_lang),
              lang: _lang,
              onLangChanged: (lang) => setState(() => _lang = lang),
            ),
            Expanded(
              child: BrochureOpenPanel(lang: _lang, onOpen: _open),
            ),
          ],
        ),
      ),
    );
  }
}

@JS('window.open')
external void openInNewTab(String url, String target);
