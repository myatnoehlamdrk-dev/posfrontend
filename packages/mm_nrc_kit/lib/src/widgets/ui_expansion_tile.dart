import 'package:flutter/material.dart';

class UIExpansionTile extends StatelessWidget {
  const UIExpansionTile(
      {super.key,
      this.children = const <Widget>[],
      this.onExpansionChanged,
      required this.leadingTitle,
      required this.trailingTitle,
      this.backgroundColor,
      this.leadingTitleColor,
      this.leadingTitleFontSize,
      this.trailingTitleFontSize});

  final String leadingTitle;
  final String trailingTitle;
  final List<Widget> children;
  final void Function(bool)? onExpansionChanged;
  final Color? backgroundColor;
  final Color? leadingTitleColor;
  final double? leadingTitleFontSize;
  final double? trailingTitleFontSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return ExpansionTile(
          onExpansionChanged: onExpansionChanged,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
          tilePadding: const EdgeInsets.all(0),
          initiallyExpanded: false,
          backgroundColor: backgroundColor ?? Colors.white,
          collapsedBackgroundColor: backgroundColor ?? Colors.white,
          childrenPadding: const EdgeInsets.symmetric(horizontal: 0),
          title: Text(
            leadingTitle,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: leadingTitleFontSize ?? 16,
                color: leadingTitleColor ?? Colors.black),
          ),
          // Capped, not a bare Text: an unbounded trailing value like
          // `12/MAKANA(N)123456` claims its full natural width, and on a
          // phone-width card that pushes the row past the right edge.
          //
          // Deliberately not Flexible/Expanded -- ListTile lays [trailing] out
          // as a slot of its custom _ListTile render object rather than as a
          // child of a Flex, so a Flex parent widget there throws
          // "Incorrect use of ParentDataWidget". The slot does hand its child
          // a loose constraint bounded by the tile width, which is enough to
          // size against. 60% rather than 50%: a full NRC is ~126px at the
          // 14px the app passes in, so half of a 360px card's 248px usable
          // width (124px) would ellipsize the value that is the whole point of
          // the row. 60% leaves it intact at phone widths while still reserving
          // a share for the title, and only kicks in once the tile is narrow
          // enough that the two genuinely cannot coexist.
          trailing: LayoutBuilder(
            builder: (context, constraints) => ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.6),
              child: Text(
                trailingTitle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                    fontSize: trailingTitleFontSize ?? 16),
              ),
            ),
          ),
          children: children);
    });
  }
}
