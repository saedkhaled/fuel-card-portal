import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'portal_theme.dart';

AnimationStyle portalSheetAnimation(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? AnimationStyle.noAnimation
    : const AnimationStyle(
        duration: Duration(milliseconds: 200),
        reverseDuration: Duration(milliseconds: 200),
      );

class PortalMark extends StatelessWidget {
  const PortalMark({super.key, this.size = 40});

  final double size;

  static final Uint8List? _artwork = _readArtwork();
  static bool get hasBrandArtwork => _artwork != null;

  static Uint8List? _readArtwork() {
    const artwork = String.fromEnvironment('PORTAL_LOGO_BASE64');
    try {
      return artwork.isEmpty ? null : base64Decode(artwork);
    } on FormatException {
      return null;
    }
  }

  Widget _fallback(double dimension) =>
      Icon(Icons.ev_station_outlined, color: portalNavy, size: dimension * .54);

  @override
  Widget build(BuildContext context) {
    final artwork = _artwork;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: portalGold),
        ),
        child: artwork == null
            ? _fallback(size)
            : Image.memory(
                artwork,
                width: size,
                height: size,
                errorBuilder: (_, _, _) => _fallback(size),
              ),
      ),
    );
  }
}

class PortalHeroSurface extends StatelessWidget {
  const PortalHeroSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [portalNavy, portalInk],
            ),
          ),
          child: CustomPaint(
            painter: _GoldLines(Directionality.of(context)),
            child: Padding(
              padding: padding,
              child: DefaultTextStyle(
                style: text.bodyMedium!.copyWith(color: Colors.white),
                child: IconTheme.merge(
                  data: const IconThemeData(color: portalGold),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoldLines extends CustomPainter {
  const _GoldLines(this.direction);

  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    if (direction == TextDirection.rtl) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    final paint = Paint()
      ..color = portalGold.withValues(alpha: .26)
      ..strokeWidth = 1;
    for (final fraction in [.63, .72, .81, .90]) {
      final x = size.width * fraction;
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height * .42, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GoldLines oldDelegate) =>
      direction != oldDelegate.direction;
}
