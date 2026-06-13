import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modo de tema selecionado (claro/escuro/sistema).
/// Em F7 será persistido em armazenamento seguro/preferências.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
