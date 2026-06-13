import 'package:flutter/material.dart';

/// Paleta do Design System, derivada do ícone do app
/// (verde vegetação, azul céu, marrom solo, prata do penetrômetro).
abstract final class AppColors {
  // Marca
  static const Color green = Color(0xFF2E7D32); // primária (vegetação)
  static const Color greenLight = Color(0xFF4CAF50);
  static const Color blue = Color(0xFF1565C0); // secundária (céu/dados)
  static const Color blueLight = Color(0xFF42A5F5);
  static const Color soil = Color(0xFF6D4C2F); // solo
  static const Color soilDark = Color(0xFF4E3620);

  // Semânticas
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1565C0);

  // Diagnóstico (faixas de compactação)
  static const Color diagAdequate = Color(0xFF2E7D32); // adequado
  static const Color diagModerate = Color(0xFF689F38); // moderada
  static const Color diagHigh = Color(0xFFF59E0B); // alta
  static const Color diagCompacted = Color(0xFFEF6C00); // compactado
  static const Color diagExtreme = Color(0xFFD32F2F); // extremo
}
