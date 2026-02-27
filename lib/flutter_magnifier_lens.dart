library flutter_magnifier_lens;

import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A magnifying lens widget that applies optical refraction, aberration, and distortion.
class MagnifierLens extends StatefulWidget {
  final Widget child;
  
  /// The global key of the RepaintBoundary wrapping the content to magnify.
  final GlobalKey contentKey;

  /// Enable or disable the lens effect.
  final bool activated;

  /// The center position of the lens.
  final Offset lensPosition;

  /// The radius of the lens.
  final double lensRadius;

  /// The distortion factor of the lens.
  final double distortion;

  /// The magnification factor.
  final double magnification;

  /// The chromatic aberration strength.
  final double aberration;

  /// Toggle to show a border around the lens.
  final bool showBorder;

  /// The color of the border if shown.
  final Color borderColor;

  /// The width of the border if shown.
  final double borderWidth;

  /// Toggle to show a shadow below the lens.
  final bool showShadow;

  /// The color of the shadow if shown.
  final Color shadowColor;

  /// The blur radius of the shadow if shown.
  final double shadowBlurRadius;

  /// An optional transparent PNG overlay image over the lens effect.
  final ui.Image? overlayImage;

  const MagnifierLens({
    super.key,
    required this.child,
    required this.contentKey,
    this.activated = true,
    this.lensPosition = const Offset(200, 200),
    this.lensRadius = 100.0,
    this.distortion = 0.5,
    this.magnification = 1.5,
    this.aberration = 0.05,
    this.showBorder = true,
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.showShadow = true,
    this.shadowColor = Colors.black45,
    this.shadowBlurRadius = 15.0,
    this.overlayImage,
  });

  @override
  State<MagnifierLens> createState() => _MagnifierLensState();

  /// A utility function to quickly decode raw pixels to a ui.Image using decodeImageFromPixelsSync.
  static ui.Image decodeImageSync(
      Uint8List pixels, int width, int height, ui.PixelFormat format) {
    return ui.decodeImageFromPixelsSync(pixels, width, height, format);
  }
}

class _MagnifierLensState extends State<MagnifierLens> {
  ui.FragmentProgram? _program;
  ui.Image? _backgroundSnapshot;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('packages/flutter_magnifier_lens/shaders/lens.frag');
      if (mounted) {
        setState(() {
          _program = program;
        });
      }
    } catch (e) {
      debugPrint("Error loading shader: \$e");
    }
  }

  void _captureBackground() {
    if (!widget.activated) return;
    
    try {
      final rb = widget.contentKey.currentContext?.findRenderObject();
      if (rb is RenderRepaintBoundary) {
        if (!rb.hasSize || rb.paintBounds.isEmpty || rb.size.width <= 0 || rb.size.height <= 0) {
          return; // Prevent Impeller crashes when widget is not fully laid out or bounds are empty
        }
        
        final imageSync = rb.toImageSync();
        
        // Final sanity check before keeping the texture
        if (imageSync.width <= 0 || imageSync.height <= 0) {
          imageSync.dispose();
          return;
        }
        
        bool shouldUpdate = false;
        if (_backgroundSnapshot == null) {
          shouldUpdate = true;
        } else {
          try {
            shouldUpdate = !_backgroundSnapshot!.isCloneOf(imageSync);
          } catch (_) {
            shouldUpdate = true; // Fallback if isCloneOf is somehow unavailable
          }
        }

        if (shouldUpdate) {
          setState(() {
            _backgroundSnapshot?.dispose();
            _backgroundSnapshot = imageSync;
          });
        } else {
          imageSync.dispose();
        }
      }
    } catch (e) {
      debugPrint("Failed to capture background: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.activated) {
      return widget.child;
    }

    // Schedule background capture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureBackground();
    });

    return Stack(
      children: [
        widget.child,
        if (_backgroundSnapshot != null && _program != null)
          Positioned.fill(
            child: CustomPaint(
              painter: _LensPainter(
                program: _program!,
                backgroundImage: _backgroundSnapshot!,
                lensPosition: widget.lensPosition,
                lensRadius: widget.lensRadius,
                distortion: widget.distortion,
                magnification: widget.magnification,
                aberration: widget.aberration,
                showBorder: widget.showBorder,
                borderColor: widget.borderColor,
                borderWidth: widget.borderWidth,
                showShadow: widget.showShadow,
                shadowColor: widget.shadowColor,
                shadowBlurRadius: widget.shadowBlurRadius,
                overlayImage: widget.overlayImage,
              ),
              // We don't absorb pointers so the user can interact with the app
              // Usually the dragging is handled by a parent gesture detector
            ),
          ),
      ],
    );
  }
}

class _LensPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final ui.Image backgroundImage;
  final Offset lensPosition;
  final double lensRadius;
  final double distortion;
  final double magnification;
  final double aberration;
  final bool showBorder;
  final Color borderColor;
  final double borderWidth;
  final bool showShadow;
  final Color shadowColor;
  final double shadowBlurRadius;
  final ui.Image? overlayImage;

  _LensPainter({
    required this.program,
    required this.backgroundImage,
    required this.lensPosition,
    required this.lensRadius,
    required this.distortion,
    required this.magnification,
    required this.aberration,
    required this.showBorder,
    required this.borderColor,
    required this.borderWidth,
    required this.showShadow,
    required this.shadowColor,
    required this.shadowBlurRadius,
    this.overlayImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();

    // Uniforms
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, lensPosition.dx);
    shader.setFloat(3, lensPosition.dy);
    shader.setFloat(4, lensRadius);
    shader.setFloat(5, distortion);
    shader.setFloat(6, magnification);
    shader.setFloat(7, aberration);

    // Sampler
    shader.setImageSampler(0, backgroundImage);

    final paint = Paint()..shader = shader;

    // Draw Shadow
    if (showShadow) {
      final shadowPaint = Paint()
        ..color = shadowColor
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, shadowBlurRadius);
      canvas.drawCircle(lensPosition, lensRadius, shadowPaint);
    }

    // Draw the lens area using the shader
    // We can draw a circle where the lens is
    canvas.drawCircle(lensPosition, lensRadius, paint);

    // Draw border
    if (showBorder) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..isAntiAlias = true;
      canvas.drawCircle(lensPosition, lensRadius, borderPaint);
    }

    // Draw overlay image
    if (overlayImage != null) {
      // Scale and center the overlay image to fit the lens
      final srcRect = Rect.fromLTWH(0, 0, overlayImage!.width.toDouble(), overlayImage!.height.toDouble());
      final dstRect = Rect.fromCircle(center: lensPosition, radius: lensRadius);
      canvas.drawImageRect(overlayImage!, srcRect, dstRect, Paint());
    }
  }

  @override
  bool shouldRepaint(covariant _LensPainter oldDelegate) {
    return oldDelegate.backgroundImage != backgroundImage ||
        oldDelegate.lensPosition != lensPosition ||
        oldDelegate.lensRadius != lensRadius ||
        oldDelegate.distortion != distortion ||
        oldDelegate.magnification != magnification ||
        oldDelegate.aberration != aberration ||
        oldDelegate.showBorder != showBorder ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.showShadow != showShadow ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.shadowBlurRadius != shadowBlurRadius ||
        oldDelegate.overlayImage != overlayImage;
  }
}
