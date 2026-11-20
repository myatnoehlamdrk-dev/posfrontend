import 'package:flutter/material.dart';

/// The scrim layered over the full-bleed brand artwork on the auth panes.
///
/// The reset-password and create-shop panes both paint a bright illustration
/// edge to edge and then put white copy on it. One directional gradient only
/// fixes one side, which left each pane with bright corners: the reset pane
/// kept its top-right and bottom-right, the shop pane kept everything except
/// its left edge.
///
/// These five layers close all four sides. The corners pick up two directions
/// at once and end up darker than the edges, while the middle of the artwork
/// stays clear, so the image still reads as the illustration it is.
class BrandArtVeil extends StatelessWidget {
  const BrandArtVeil({super.key, this.intensity = 1.0});

  /// Scales every layer's alpha.
  ///
  /// `1.0` is the full scrim used on the reset and create-shop panes. A pane
  /// whose artwork is already soft only needs a little more contrast, so it
  /// passes a lower value instead of carrying its own hand-tuned gradients.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    Color ink(double alpha) =>
        Colors.black.withValues(alpha: alpha * intensity);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Top-left emphasis: the corner under the lockup should be the darkest
        // point on the pane rather than only as dark as the top edge.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.15,
              colors: [ink(0.30), ink(0.10), ink(0.0)],
              stops: const [0.0, 0.40, 0.85],
            ),
          ),
        ),
        // Top veil, falling away downward.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ink(0.50), ink(0.20), ink(0.0)],
              stops: const [0.0, 0.25, 0.60],
            ),
          ),
        ),
        // Left veil, falling away toward the middle of the artwork.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [ink(0.55), ink(0.25), ink(0.0)],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        // Right veil: the left and top veils are directional, so the right
        // edge and the bottom-right corner would otherwise stay untreated.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [ink(0.40), ink(0.12), ink(0.0)],
              stops: const [0.0, 0.30, 0.60],
            ),
          ),
        ),
        // Bottom veil, for the copy that sits low on the create-shop pane.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [ink(0.38), ink(0.10), ink(0.0)],
              stops: const [0.0, 0.28, 0.55],
            ),
          ),
        ),
      ],
    );
  }
}
