import 'dart:io';

import 'package:flutter/material.dart';
import 'package:posfrontend/shared/widgets/brochure_viewer_chrome.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// The client brochure, read inside the app.
///
/// The bundled HTML is handed to the platform WebView, so the document is the
/// exact file the marketing build produces -- no re-layout, no font
/// substitution, and the language switch just swaps which asset is loaded.
///
/// Android/iOS only. The web build reads `brochure_viewer_screen.dart`
/// instead, which points at the browser-tab variant because
/// `webview_flutter` ships no web implementation.
class BrochureViewerScreen extends StatefulWidget {
  const BrochureViewerScreen({super.key});

  @override
  State<BrochureViewerScreen> createState() => _BrochureViewerScreenState();
}

class _BrochureViewerScreenState extends State<BrochureViewerScreen> {
  /// The platforms that actually have a WebView behind
  /// `webview_flutter`. Desktop runs of the app (a dev build, say) get a
  /// plain note rather than a controller with no platform to attach to.
  final bool _hasWebView = Platform.isAndroid || Platform.isIOS;

  String _lang = BrochureSpec.initialLang();
  WebViewController? _controller;

  /// 0..1 handed to the progress bar; 0 means nothing has been measured yet.
  double _progress = 0;

  /// Once the document has come up once, a later sub-resource error (a font,
  /// say) is not a reason to take the reading surface down.
  bool _loaded = false;

  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (!_hasWebView) return;

    _controller =
        WebViewController()
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (percent) => _apply(() => _progress = percent / 100),
              onPageFinished: (_) => _apply(() {
                _loaded = true;
                _progress = 1;
              }),
              onWebResourceError: (_) {
                if (_loaded) return;
                _apply(() => _failed = true);
              },
            ),
          )
          ..loadFlutterAsset(BrochureSpec.assetFor(_lang));
  }

  void _apply(VoidCallback change) {
    if (!mounted) return;
    setState(change);
  }

  void _selectLang(String lang) {
    if (lang == _lang) return;
    setState(() {
      _lang = lang;
      _progress = 0;
      _loaded = false;
      _failed = false;
    });
    _controller?.loadFlutterAsset(BrochureSpec.assetFor(lang));
  }

  void _retry() {
    setState(() {
      _progress = 0;
      _loaded = false;
      _failed = false;
    });
    _controller?.loadFlutterAsset(BrochureSpec.assetFor(_lang));
  }

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
              onLangChanged: _selectLang,
              onReload: _hasWebView ? _retry : null,
            ),
            if (_hasWebView && !_failed && _progress < 1)
              LinearProgressIndicator(
                value: _progress == 0 ? null : _progress,
                minHeight: 2,
                color: BrochureSpec.purple,
                backgroundColor: BrochureSpec.panelBg,
              ),
            if (!_hasWebView)
              const Expanded(child: _NoWebViewNote())
            else
              Expanded(
                // Stacked rather than swapped: taking the WebViewWidget out
                // of the tree to show an error and putting it back is the
                // path that historically re-creates the platform view, so the
                // document stays mounted underneath and the notice covers it.
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    WebViewWidget(controller: _controller!),
                    if (_failed)
                      ColoredBox(
                        color: BrochureSpec.pageBg,
                        child: _LoadFailed(onRetry: _retry, lang: _lang),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shown where there is no WebView to use at all.
class _NoWebViewNote extends StatelessWidget {
  const _NoWebViewNote();

  @override
  Widget build(BuildContext context) {
    const title = 'Brochure needs a browser';
    const body =
        'This build has no in-page document view. Run smartpos. on Android or '
        'open the web build to read the brochure.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.desktop_windows_rounded,
                size: 34,
                color: BrochureSpec.muted,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: brochureStyle(
                  title,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: brochureStyle(
                  body,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: BrochureSpec.muted,
                ).copyWith(height: 1.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Covers the document when it could not be loaded, and offers one way out.
class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.onRetry, required this.lang});

  final VoidCallback onRetry;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final english = lang != 'my';
    final title = english
        ? 'The brochure could not be loaded'
        : 'စာရွက်စာတမ်းဖွင့်၍မရပါ';
    final body = english
        ? 'Check the app is up to date, then try again.'
        : 'အက်ပ်အသစ်ရှိမရှိစစ်ဆေးပြီး ထပ်မံကြိုးစားကြည့်ပါ။';
    final action = english ? 'Try again' : 'ထပ်ကြိုးစားရန်';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 34,
                color: BrochureSpec.muted,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: brochureStyle(
                  title,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: brochureStyle(
                  body,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: BrochureSpec.muted,
                ).copyWith(height: 1.55),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrochureSpec.purple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  action,
                  style: brochureStyle(
                    action,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
