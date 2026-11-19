import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// The registered platform-view type for the embedded demo page.
const String _viewType = 'smartpos-animated-demo';

/// Whether the iframe factory has been registered. The registry rejects a
/// second registration under the same name, and this widget can be mounted
/// again after the user comes back from sign-in.
bool _factoryRegistered = false;

/// Embeds `web/demo/animate.html` full-screen.
///
/// The page is plain HTML, so Flutter cannot paint it; it is hosted in an
/// iframe that fills the screen instead. The page posts a message when its
/// "Get started" control is used, which is forwarded to [onGetStarted] so the
/// app can show its own sign-in screen rather than navigating inside the frame.
Widget buildDemoPageView({required VoidCallback onGetStarted}) {
  return _DemoPageView(onGetStarted: onGetStarted);
}

class _DemoPageView extends StatefulWidget {
  const _DemoPageView({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  State<_DemoPageView> createState() => _DemoPageViewState();
}

class _DemoPageViewState extends State<_DemoPageView> {
  JSFunction? _messageListener;

  @override
  void initState() {
    super.initState();
    _registerFactory();

    final listener = _handleMessage.toJS;
    _messageListener = listener;
    web.window.addEventListener('message', listener);
  }

  static void _registerFactory() {
    if (_factoryRegistered) return;
    _factoryRegistered = true;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = Uri.base.resolve('demo/animate.html').toString()
        ..title = 'SmartPOS animated demo'
        ..allow = 'fullscreen';
      iframe.style
        ..border = '0'
        ..width = '100%'
        ..height = '100%'
        ..display = 'block';
      return iframe;
    });
  }

  void _handleMessage(web.MessageEvent event) {
    final data = event.data.dartify();
    if (data is Map && data['type'] == 'smartpos:get-started') {
      widget.onGetStarted();
    }
  }

  @override
  void dispose() {
    final listener = _messageListener;
    if (listener != null) {
      web.window.removeEventListener('message', listener);
      _messageListener = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
