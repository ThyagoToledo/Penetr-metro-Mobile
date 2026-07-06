import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'diagnosis_visuals.dart';

/// Régua visual do diagnóstico: gradiente com as cinco faixas de compactação
/// e um marcador animado na posição do coeficiente (kgf/cm², limitado a 50).
class DiagnosisScaleBar extends StatelessWidget {
  const DiagnosisScaleBar({super.key, required this.coefficient});

  final double coefficient;

  static const double _maxScale = 50;
  static const double _markerSize = 16;

  @override
  Widget build(BuildContext context) {
    final fraction = (coefficient / _maxScale).clamp(0.0, 1.0);
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth - _markerSize;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _markerSize + 4,
              child: Stack(
                children: [
                  Positioned(
                    top: (_markerSize - 8) / 2 + 2,
                    left: _markerSize / 2,
                    right: _markerSize / 2,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.diagAdequate,
                            AppColors.diagModerate,
                            AppColors.diagHigh,
                            AppColors.diagCompacted,
                            AppColors.diagExtreme,
                          ],
                          stops: [0.1, 0.3, 0.5, 0.7, 0.9],
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    left: trackWidth * fraction,
                    top: 2,
                    child: Container(
                      width: _markerSize,
                      height: _markerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: diagnosisColor(coefficient),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2.5,
                        ),
                        boxShadow: const [
                          BoxShadow(blurRadius: 4, color: Colors.black26),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0', style: labelStyle),
                Text('10', style: labelStyle),
                Text('20', style: labelStyle),
                Text('30', style: labelStyle),
                Text('40', style: labelStyle),
                Text('50+', style: labelStyle),
              ],
            ),
          ],
        );
      },
    );
  }
}
