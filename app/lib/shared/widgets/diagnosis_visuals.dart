import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/measurement/domain/entities/penetrometer_type.dart';

/// Cor associada à faixa de diagnóstico (mesmos limiares dos controllers).
Color diagnosisColor(double coefficient) {
  if (coefficient < 10) return AppColors.diagAdequate;
  if (coefficient <= 20) return AppColors.diagModerate;
  if (coefficient <= 30) return AppColors.diagHigh;
  if (coefficient <= 40) return AppColors.diagCompacted;
  return AppColors.diagExtreme;
}

/// Ícone por tipo de penetrômetro.
IconData typeIcon(PenetrometerType type) =>
    type == PenetrometerType.impact ? Icons.hardware : Icons.compress;
