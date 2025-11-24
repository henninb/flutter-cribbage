import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Modern Cribbage App Icon Generator
/// Run this file to generate a 1024x1024 icon
void main() {
  runApp(const IconGeneratorApp());
}

class IconGeneratorApp extends StatelessWidget {
  const IconGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cribbage Icon Generator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const IconGeneratorScreen(),
    );
  }
}

class IconGeneratorScreen extends StatefulWidget {
  const IconGeneratorScreen({super.key});

  @override
  State<IconGeneratorScreen> createState() => _IconGeneratorScreenState();
}

class _IconGeneratorScreenState extends State<IconGeneratorScreen> {
  final GlobalKey _iconKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _saveIcon() async {
    setState(() {
      _isSaving = true;
    });

    try {
      RenderRepaintBoundary boundary =
          _iconKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to downloads or documents
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/cribbage_icon.png');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Icon saved to ${file.path}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving icon: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cribbage Icon Generator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Modern Cribbage App Icon',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Preview at smaller size
            Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const CribbageIcon(),
            ),
            const SizedBox(height: 40),
            // Full size icon (hidden)
            Offstage(
              child: RepaintBoundary(
                key: _iconKey,
                child: const SizedBox(
                  width: 1024,
                  height: 1024,
                  child: CribbageIcon(),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveIcon,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_isSaving ? 'Saving...' : 'Save Icon (1024x1024)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern Cribbage Icon Design
class CribbageIcon extends StatelessWidget {
  const CribbageIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B5E20), // Dark green
            Color(0xFF2E7D32), // Medium green
            Color(0xFF43A047), // Light green
          ],
        ),
        borderRadius: BorderRadius.circular(180),
      ),
      child: Stack(
        children: [
          // Cribbage board pegging holes pattern
          Positioned.fill(
            child: CustomPaint(
              painter: CribbageBoardPainter(),
            ),
          ),
          // Playing cards
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                // Three overlapping cards
                SizedBox(
                  height: 320,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Left card (rotated)
                      Transform.translate(
                        offset: const Offset(-80, 20),
                        child: Transform.rotate(
                          angle: -0.3,
                          child: _buildCard('A♠', Colors.black),
                        ),
                      ),
                      // Center card
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: _buildCard('5♥', Colors.red.shade800),
                      ),
                      // Right card (rotated)
                      Transform.translate(
                        offset: const Offset(80, 20),
                        child: Transform.rotate(
                          angle: 0.3,
                          child: _buildCard('J♣', Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Cribbage pegs
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPeg(Colors.red.shade700, 30),
                    const SizedBox(width: 20),
                    _buildPeg(Colors.blue.shade700, 30),
                    const SizedBox(width: 20),
                    _buildPeg(Colors.yellow.shade700, 30),
                    const SizedBox(width: 20),
                    _buildPeg(Colors.orange.shade700, 30),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String label, Color color) {
    return Container(
      width: 140,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildPeg(Color color, double size) {
    return Container(
      width: size,
      height: size * 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.8),
            color,
          ],
        ),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

/// Painter for cribbage board hole pattern
class CribbageBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Draw subtle pegging holes in a pattern
    const rows = 8;
    const cols = 8;
    final holeRadius = size.width * 0.012;
    final spacingX = size.width / (cols + 1);
    final spacingY = size.height / (rows + 1);

    for (int row = 1; row <= rows; row++) {
      for (int col = 1; col <= cols; col++) {
        // Create a zigzag pattern
        final x = spacingX * col + (row % 2 == 0 ? spacingX / 2 : 0);
        final y = spacingY * row;
        canvas.drawCircle(Offset(x, y), holeRadius, paint);
      }
    }

    // Draw border holes
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    const borderHoles = 24;
    final borderRadius = size.width * 0.015;
    for (int i = 0; i < borderHoles; i++) {
      final angle = (2 * math.pi * i) / borderHoles;
      final x = size.width / 2 + (size.width * 0.42) * math.cos(angle);
      final y = size.height / 2 + (size.height * 0.42) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), borderRadius, borderPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
