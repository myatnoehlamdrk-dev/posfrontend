import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/locale_notifier.dart';

/// Brand tokens for the in-app client brochure.
///
/// Fixed rather than pulled from the app theme: the brochure is brand artwork
/// (the same lavender/purple palette as the welcome screen) and has to look
/// the same wherever it is opened.
class BrochureSpec {
  static const purple = Color(0xFF7952DB);
  static const ink = Color(0xFF292536);
  static const muted = Color(0xFF81798C);
  static const border = Color(0xFFEAE5F1);
  static const pageBg = Color(0xFFFCFBFE);
  static const panelBg = Color(0xFFF5F1FD);

  static const englishAsset = 'assets/brochure/brochure_en.html';
  static const myanmarAsset = 'assets/brochure/brochure_mm.html';

  /// The bundled document for [lang], which is `en` or `my`.
  static String assetFor(String lang) =>
      lang == 'my' ? myanmarAsset : englishAsset;

  /// Screen title, in the language currently being read.
  static String titleFor(String lang) =>
      lang == 'my' ? 'စာရွက်စာတမ်း' : 'Brochure';

  /// The language the document should open in: the reader's own app language
  /// where the brochure exists in it.
  ///
  /// The brochure ships in English and Myanmar only, so a Thai or Japanese
  /// reader gets the English one -- the same fallback the app's own
  /// translations use, since English is the one set guaranteed complete.
  static String initialLang() =>
      LocaleNotifier.instance.language.code == 'my' ? 'my' : 'en';
}

/// Whether [text] carries Myanmar script.
///
/// The Latin faces used by this screen cannot shape Myanmar, so those runs
/// are set in the Noto face bundled with the app instead of relying on the
/// theme's fallback chain.
bool brochureHasMyanmar(String text) =>
    text.runes.any((r) => r >= 0x1000 && r <= 0x109F);

/// Text style for viewer chrome. `fontFamily` stays null for Latin so the
/// theme's own face still applies.
TextStyle brochureStyle(
  String text, {
  double fontSize = 12,
  FontWeight fontWeight = FontWeight.w600,
  Color color = BrochureSpec.ink,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    fontFamily: brochureHasMyanmar(text) ? 'NotoSansMyanmar' : null,
  );
}

/// The bar above the document: back, title, optional reload, and the
/// English / Myanmar switch that swaps which bundled file is shown.
class BrochureTopBar extends StatelessWidget {
  const BrochureTopBar({
    super.key,
    required this.title,
    required this.lang,
    required this.onLangChanged,
    this.onReload,
  });

  final String title;
  final String lang;
  final ValueChanged<String> onLangChanged;

  /// Shown only where reloading the document is meaningful -- the browser
  /// tab variant has nothing to reload.
  final VoidCallback? onReload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: BrochureSpec.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              final nav = Navigator.of(context);
              if (nav.canPop()) nav.pop();
            },
            icon: const Icon(Icons.arrow_back_rounded, color: BrochureSpec.ink),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: brochureStyle(
                title,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onReload != null)
            IconButton(
              onPressed: onReload,
              icon: const Icon(
                Icons.refresh_rounded,
                color: BrochureSpec.muted,
              ),
            ),
          const SizedBox(width: 4),
          BrochureLangToggle(lang: lang, onChanged: onLangChanged),
        ],
      ),
    );
  }
}

/// Compact two-state switch. Each label is shown in its own script, so a
/// reader can find their language without reading the other one.
class BrochureLangToggle extends StatelessWidget {
  const BrochureLangToggle({
    super.key,
    required this.lang,
    required this.onChanged,
  });

  final String lang;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: BrochureSpec.pageBg,
        border: Border.all(color: BrochureSpec.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option('en', 'English'),
          _option('my', 'မြန်မာ'),
        ],
      ),
    );
  }

  Widget _option(String value, String label) {
    final selected = lang == value;
    return Material(
      color: selected ? BrochureSpec.purple : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: () => onChanged(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: brochureStyle(
              label,
              fontSize: 11.5,
              color: selected ? Colors.white : BrochureSpec.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Centred "open it in the browser" card, used where an in-page document
/// surface is not available (the web build) or not reachable.
class BrochureOpenPanel extends StatelessWidget {
  const BrochureOpenPanel({
    super.key,
    required this.lang,
    required this.onOpen,
  });

  final String lang;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final english = lang != 'my';
    final title = english
        ? 'The brochure opens in your browser'
        : 'စာရွက်စာတမ်းကိုဘရောက်ဆာတွင်ဖွင့်ပါမည်';
    final body = english
        ? 'Tap the button to read the full smartpos. brochure in a new tab.'
        : 'အောက်ပါခလုတ်ကိုနှိပ်ပြီး smartpos. ၏စာရွက်စာတမ်းအပြည့်အဝကိုဖတ်ရှုနိုင်ပါတယ်။';
    final action = english ? 'Open the brochure' : 'စာရွက်စာတမ်းဖွင့်ရန်';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: BrochureSpec.panelBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 30,
                  color: BrochureSpec.purple,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: brochureStyle(
                  title,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onOpen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrochureSpec.purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
