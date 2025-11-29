// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

/// Simple SVG icon generator for Cribbage app
/// Creates a modern, eye-catching icon with cribbage theme
void main() {
  final iconSvg = generateCribbageIconSVG();

  File('assets/cribbage_icon.svg').writeAsStringSync(iconSvg);
  print('✓ Created assets/cribbage_icon.svg');

  final foregroundSvg = generateCribbageIconForegroundSVG();
  File('assets/cribbage_icon_foreground.svg').writeAsStringSync(foregroundSvg);
  print('✓ Created assets/cribbage_icon_foreground.svg');

  _writePngs();

  print('\nNext steps:');
  print('1. Run: dart run generate_icon.dart');
  print('2. Run: dart run flutter_launcher_icons');
  print('3. Rebuild your app to see the new icon!');
}

String generateCribbageIconSVG() {
  return _buildSvg(includeBackground: true);
}

String generateCribbageIconForegroundSVG() {
  return _buildSvg(includeBackground: false);
}

String _buildSvg({required bool includeBackground}) {
  final buffer = StringBuffer();
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln(
    '<svg width="1024" height="1024" viewBox="0 0 1024 1024" '
    'xmlns="http://www.w3.org/2000/svg">',
  );
  buffer.writeln(_defs());

  if (includeBackground) {
    buffer.writeln(
      '  <rect width="1024" height="1024" rx="220" '
      'fill="url(#feltGradient)"/>',
    );
  }

  buffer.writeln(_board());
  buffer.writeln(_cardStack());
  buffer.writeln(_pegCluster());

  if (includeBackground) {
    buffer.writeln(
      '  <rect width="1024" height="1024" rx="220" fill="none" '
      'stroke="rgba(255,255,255,0.16)" stroke-width="8"/>',
    );
  }

  buffer.writeln('</svg>');
  return buffer.toString();
}

String _defs() {
  return '''
  <defs>
    <linearGradient id="feltGradient" x1="15%" y1="5%" x2="85%" y2="95%">
      <stop offset="0%" stop-color="#0c3627"/>
      <stop offset="50%" stop-color="#0f5f43"/>
      <stop offset="100%" stop-color="#0d3f2f"/>
    </linearGradient>
    <linearGradient id="boardGradient" x1="0%" y1="0%" x2="100%" y2="85%">
      <stop offset="0%" stop-color="#e0b06d"/>
      <stop offset="100%" stop-color="#9c642d"/>
    </linearGradient>
    <linearGradient id="boardSheen" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="0.28"/>
      <stop offset="40%" stop-color="#ffffff" stop-opacity="0.12"/>
      <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
    </linearGradient>
    <linearGradient id="cardFace" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="100%" stop-color="#f2f2f7"/>
    </linearGradient>
    <linearGradient id="pegRed" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ff9a8b"/>
      <stop offset="100%" stop-color="#c62828"/>
    </linearGradient>
    <linearGradient id="pegBlue" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#7ab4ff"/>
      <stop offset="100%" stop-color="#1c4ba8"/>
    </linearGradient>
    <linearGradient id="pegGold" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffd68a"/>
      <stop offset="100%" stop-color="#c57a12"/>
    </linearGradient>
    <linearGradient id="pegGreen" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#9be6c3"/>
      <stop offset="100%" stop-color="#1f8a53"/>
    </linearGradient>
    <radialGradient id="holeGlow" cx="50%" cy="35%" r="70%">
      <stop offset="0%" stop-color="#f8e8cc" stop-opacity="0.7"/>
      <stop offset="100%" stop-color="#5a3518" stop-opacity="0"/>
    </radialGradient>
    <filter id="shadow">
      <feDropShadow dx="0" dy="12" stdDeviation="16" flood-opacity="0.35"/>
    </filter>
  </defs>''';
}

String _board() {
  final buffer = StringBuffer();
  buffer.writeln(
    '  <g transform="translate(512 560) rotate(-14)" filter="url(#shadow)">',
  );
  buffer.writeln(
    '    <rect x="-330" y="-120" width="660" height="240" rx="62" '
    'fill="url(#boardGradient)" stroke="rgba(34,16,6,0.4)" stroke-width="6"/>',
  );
  buffer.writeln(
    '    <rect x="-330" y="-120" width="660" height="240" rx="62" '
    'fill="url(#boardSheen)"/>',
  );
  buffer.writeln(_pegHoleRow(-54));
  buffer.writeln(_pegHoleRow(0));
  buffer.writeln(_pegHoleRow(54));
  buffer.writeln(
    '    <rect x="-304" y="-92" width="608" height="20" rx="10" '
    'fill="rgba(255,255,255,0.08)"/>',
  );
  buffer.writeln(
    '    <rect x="-304" y="72" width="608" height="20" rx="10" '
    'fill="rgba(0,0,0,0.12)"/>',
  );
  buffer.writeln(
    '    <text x="250" y="18" font-family="Montserrat, Arial, sans-serif" '
    'font-size="64" font-weight="800" fill="#f7d561">15·2</text>',
  );
  buffer.writeln('  </g>');
  return buffer.toString();
}

String _pegHoleRow(double y) {
  const spacing = 70;
  const holes = 9;
  const start = -280;

  final buffer = StringBuffer();
  buffer.writeln('    <g transform="translate(0, $y)">');

  for (var i = 0; i < holes; i++) {
    final x = start + i * spacing;
    buffer.writeln(
      '      <circle cx="$x" cy="0" r="16" fill="#2e1a0d" opacity="0.92"/>',
    );
    buffer.writeln(
      '      <circle cx="$x" cy="-4" r="8" fill="url(#holeGlow)" '
      'opacity="0.75"/>',
    );
  }

  buffer.writeln('    </g>');
  return buffer.toString();
}

String _cardStack() {
  return '''
  <g transform="translate(430 360)">
    ${_card(x: -60, y: 30, rotation: -12, label: '5♥', color: '#d32f2f')}
    ${_card(x: 90, y: 80, rotation: 10, label: 'J♣', color: '#0d0d0d')}
  </g>''';
}

String _card({
  required double x,
  required double y,
  required double rotation,
  required String label,
  required String color,
}) {
  final rank = label.substring(0, label.length - 1);
  final suit = label.substring(label.length - 1);

  return '''
    <g transform="translate($x, $y) rotate($rotation)" filter="url(#shadow)">
      <rect x="-92" y="-128" width="184" height="256" rx="26"
fill="url(#cardFace)" stroke="rgba(0,0,0,0.08)" stroke-width="4"/>
      <rect x="-92" y="-128" width="184" height="256" rx="26" fill="white" opacity="0.08"/>
      <text x="-62" y="-80" font-family="Montserrat, Arial, sans-serif" font-size="46" font-weight="800"
            fill="$color" text-anchor="middle" dominant-baseline="middle">$rank</text>
      <text x="0" y="26" font-family="Montserrat, Arial, sans-serif" font-size="110" font-weight="800"
            fill="$color" text-anchor="middle" dominant-baseline="middle">$label</text>
      <text x="62" y="110" font-family="Montserrat, Arial, sans-serif" font-size="46" font-weight="800"
            fill="$color" text-anchor="middle" dominant-baseline="middle">$suit</text>
    </g>''';
}

String _pegCluster() {
  return '''
  <g transform="translate(512 648) rotate(-14)">
    ${_peg(x: -190, color: 'url(#pegRed)')}
    ${_peg(x: -110, color: 'url(#pegBlue)')}
    ${_peg(x: -30, color: 'url(#pegGold)')}
    ${_peg(x: 70, color: 'url(#pegGreen)')}
  </g>''';
}

String _peg({required double x, required String color}) {
  return '''
    <g transform="translate($x, 0)">
      <ellipse cx="0" cy="60" rx="20" ry="9" fill="rgba(0,0,0,0.28)"/>
      <rect x="-18" y="-56" width="36" height="112" rx="18" fill="$color"
            stroke="rgba(255,255,255,0.25)" stroke-width="3" filter="url(#shadow)"/>
      <ellipse cx="0" cy="-48" rx="12" ry="10" fill="rgba(255,255,255,0.42)"/>
    </g>''';
}

void _writePngs() {
  const size = 1024;

  final background = _buildBackgroundPng(size);
  File('assets/cribbage_icon.png').writeAsBytesSync(img.encodePng(background));
  print('✓ Created assets/cribbage_icon.png');

  final foreground = _buildForegroundPng(size);
  File('assets/cribbage_icon_foreground.png').writeAsBytesSync(img.encodePng(foreground));
  print('✓ Created assets/cribbage_icon_foreground.png');
}

img.Image _buildBackgroundPng(int size) {
  final canvas = img.Image(width: size, height: size);
  const start = [11, 39, 64];
  const end = [15, 93, 95];

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final tx = x / (size - 1);
      final ty = y / (size - 1);
      final t = (tx + ty) / 2;
      final r = _lerp(start[0], end[0], t);
      final g = _lerp(start[1], end[1], t);
      final b = _lerp(start[2], end[2], t);
      canvas.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // Subtle vignette
  final cx = size / 2;
  final cy = size / 2;
  final maxDist = sqrt(cx * cx + cy * cy);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
      final factor = 1 - pow(dist / maxDist, 1.3);
      final darken = (1 - factor.clamp(0.0, 1.0)) * 0.2;
      final pixel = canvas.getPixel(x, y);
      final r = (img.getRed(pixel) * (1 - darken)).round();
      final g = (img.getGreen(pixel) * (1 - darken)).round();
      final b = (img.getBlue(pixel) * (1 - darken)).round();
      canvas.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  return canvas;
}

img.Image _buildForegroundPng(int size) {
  final canvas = img.Image(width: size, height: size);
  img.fill(canvas, img.getColor(0, 0, 0, 0));

  final centerX = size ~/ 2;
  final centerY = size ~/ 2;

  // Card shadow
  _drawRoundedRect(
    canvas,
    centerX - 240 + 12,
    centerY - 320 + 16,
    480,
    640,
    48,
    img.getColor(0, 0, 0, 80),
  );

  // Card face
  _drawRoundedRect(
    canvas,
    centerX - 240,
    centerY - 320,
    480,
    640,
    48,
    img.getColor(246, 246, 246),
  );

  // Accent stripe
  _drawRoundedRect(
    canvas,
    centerX - 240,
    centerY - 50,
    480,
    100,
    38,
    img.getColor(13, 130, 110),
  );

  // Suit markers
  img.fillCircle(canvas, centerX - 120, centerY - 160, 32, img.getColor(194, 24, 7));
  img.fillCircle(canvas, centerX + 120, centerY - 160, 32, img.getColor(15, 45, 80));

  // "500" text
  const textColor = 0xff0b2740;
  final text = '500';
  final font = img.arial48;
  final textWidth = text.length * font.fontWidth;
  final textHeight = font.fontHeight;
  final textX = centerX - (textWidth ~/ 2);
  final textY = centerY - (textHeight ~/ 2);
  img.drawString(canvas, font, textX, textY, text, color: textColor);

  // Corner pips for extra detail
  img.drawString(canvas, img.arial24, centerX - 205, centerY - 290, '5', color: textColor);
  img.drawString(canvas, img.arial24, centerX + 160, centerY + 230, '5', color: textColor);

  return canvas;
}

void _drawRoundedRect(
  img.Image canvas,
  int x,
  int y,
  int width,
  int height,
  int radius,
  int color,
) {
  final right = x + width;
  final bottom = y + height;
  img.fillRect(canvas, x + radius, y, right - radius, bottom, color: color);
  img.fillRect(canvas, x, y + radius, right, bottom - radius, color: color);

  // Corners
  img.fillCircle(canvas, x + radius, y + radius, radius, color);
  img.fillCircle(canvas, right - radius, y + radius, radius, color);
  img.fillCircle(canvas, x + radius, bottom - radius, radius, color);
  img.fillCircle(canvas, right - radius, bottom - radius, radius, color);
}

int _lerp(int a, int b, double t) => (a + (b - a) * t).round();
