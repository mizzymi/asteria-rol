import 'package:flutter/material.dart';

import 'screens/character_selection_screen.dart';
import 'screens/master_screen.dart';
import 'services/app_mode_service.dart';
import 'services/character_storage_service.dart';
import 'services/campaign_storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CharacterStorageService.init();
  await CampaignStorageService.init();

  final lastMode = await AppModeService.getLastMode();
  runApp(AsteriaRoleApp(initialMode: lastMode));
}

class AsteriaRoleApp extends StatelessWidget {
  final AsteriaAppMode initialMode;
  const AsteriaRoleApp({super.key, required this.initialMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: initialMode == AsteriaAppMode.master
          ? const MasterScreen()
          : const CharacterSelectionScreen(),
    );
  }
}
