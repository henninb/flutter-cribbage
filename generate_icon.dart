import 'dart:io';
import 'dart:math' as math;

/// Simple SVG icon generator for Cribbage app
/// Creates a modern, eye-catching icon with cribbage theme
void main() {
  final iconSvg = generateCribbageIconSVG();

  // Save main icon
  File('assets/cribbage_icon.svg').writeAsStringSync(iconSvg);
  print('✓ Created assets/cribbage_icon.svg');

  // Save foreground (for adaptive icon)
  final foregroundSvg = generateCribbageIconForegroundSVG();
  File('assets/cribbage_icon_foreground.svg').writeAsStringSync(foregroundSvg);
  print('✓ Created assets/cribbage_icon_foreground.svg');

  print('\nNext steps:');
  print('1. Convert SVG to PNG (1024x1024) using an online tool or ImageMagick:');
  print('   - Visit https://svgtopng.com/ or use: convert -resize 1024x1024 assets/cribbage_icon.svg assets/cribbage_icon.png');
  print('2. Run: dart run flutter_launcher_icons');
  print('3. Rebuild your app to see the new icon!');
}

String generateCribbageIconSVG() {
  return '''<?xml version="1.0" encoding="UTF-8"?>
<svg width="1024" height="1024" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bgGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#1B5E20;stop-opacity:1" />
      <stop offset="50%" style="stop-color:#2E7D32;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#43A047;stop-opacity:1" />
    </linearGradient>
    <filter id="shadow">
      <feDropShadow dx="0" dy="8" stdDeviation="12" flood-opacity="0.5"/>
    </filter>
  </defs>

  <!-- Background with rounded corners -->
  <rect width="1024" height="1024" rx="180" fill="url(#bgGradient)"/>

  <!-- Decorative pegging holes pattern -->
  ${_generatePeggingHoles()}

  <!-- Playing Cards -->
  <g transform="translate(512, 380)">
    <!-- Left card (Ace of Spades) -->
    <g transform="translate(-160, 40) rotate(-18)">
      ${_generateCard('A♠', '#000000')}
    </g>

    <!-- Center card (5 of Hearts) -->
    <g transform="translate(0, -20)">
      ${_generateCard('5♥', '#C62828')}
    </g>

    <!-- Right card (Jack of Clubs) -->
    <g transform="translate(160, 40) rotate(18)">
      ${_generateCard('J♣', '#000000')}
    </g>
  </g>

  <!-- Cribbage Pegs -->
  <g transform="translate(512, 720)">
    ${_generatePeg(-90, '#C62828')}
    ${_generatePeg(-30, '#1565C0')}
    ${_generatePeg(30, '#F9A825')}
    ${_generatePeg(90, '#EF6C00')}
  </g>

  <!-- Border accent -->
  <rect width="1024" height="1024" rx="180" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="4"/>
</svg>''';
}

String generateCribbageIconForegroundSVG() {
  return '''<?xml version="1.0" encoding="UTF-8"?>
<svg width="1024" height="1024" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <filter id="shadow">
      <feDropShadow dx="0" dy="8" stdDeviation="12" flood-opacity="0.5"/>
    </filter>
  </defs>

  <!-- Playing Cards (foreground only) -->
  <g transform="translate(512, 420)">
    <!-- Left card -->
    <g transform="translate(-160, 40) rotate(-18)">
      ${_generateCard('A♠', '#000000')}
    </g>

    <!-- Center card -->
    <g transform="translate(0, -20)">
      ${_generateCard('5♥', '#C62828')}
    </g>

    <!-- Right card -->
    <g transform="translate(160, 40) rotate(18)">
      ${_generateCard('J♣', '#000000')}
    </g>
  </g>

  <!-- Cribbage Pegs -->
  <g transform="translate(512, 720)">
    ${_generatePeg(-90, '#C62828')}
    ${_generatePeg(-30, '#1565C0')}
    ${_generatePeg(30, '#F9A825')}
    ${_generatePeg(90, '#EF6C00')}
  </g>
</svg>''';
}

String _generateCard(String label, String color) {
  return '''
    <g filter="url(#shadow)">
      <rect x="-70" y="-100" width="140" height="200" rx="16" fill="white" stroke="#333" stroke-width="2"/>
      <text x="0" y="30" font-family="Arial, sans-serif" font-size="80" font-weight="bold"
            fill="$color" text-anchor="middle" dominant-baseline="middle">$label</text>
    </g>''';
}

String _generatePeg(double x, String color) {
  return '''
    <g transform="translate($x, 0)">
      <ellipse cx="0" cy="30" rx="16" ry="6" fill="rgba(0,0,0,0.3)"/>
      <rect x="-15" y="-30" width="30" height="60" rx="15" fill="$color" filter="url(#shadow)"/>
      <ellipse cx="0" cy="-25" rx="12" ry="8" fill="rgba(255,255,255,0.4)"/>
    </g>''';
}

String _generatePeggingHoles() {
  final buffer = StringBuffer();
  buffer.writeln('  <!-- Pegging holes pattern -->');
  buffer.writeln('  <g opacity="0.15">');

  // Grid pattern
  for (int row = 1; row <= 8; row++) {
    for (int col = 1; col <= 8; col++) {
      final x = 128 * col + (row % 2 == 0 ? 64 : 0);
      final y = 128 * row;
      buffer.writeln('    <circle cx="$x" cy="$y" r="12" fill="white"/>');
    }
  }

  // Border holes
  const borderHoles = 32;
  for (int i = 0; i < borderHoles; i++) {
    final angle = (2 * math.pi * i) / borderHoles;
    final x = 512 + 430 * math.cos(angle);
    final y = 512 + 430 * math.sin(angle);
    buffer.writeln('    <circle cx="$x" cy="$y" r="15" fill="white"/>');
  }

  buffer.writeln('  </g>');
  return buffer.toString();
}
