import 'package:flutter/material.dart';

import 'screens/character_selection_screen.dart';
import 'services/character_storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CharacterStorageService.init();

  runApp(const AsteriaRoleApp());
}

class AsteriaRoleApp extends StatelessWidget {
  const AsteriaRoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asteria Role Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const CharacterSelectionScreen(),
    );
  }
}
