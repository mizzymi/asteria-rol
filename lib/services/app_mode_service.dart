import 'package:shared_preferences/shared_preferences.dart';

enum AsteriaAppMode { player, master }

class AppModeService {
  static const _key = 'asteria_last_app_mode';

  static Future<AsteriaAppMode> getLastMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    return value == AsteriaAppMode.master.name
        ? AsteriaAppMode.master
        : AsteriaAppMode.player;
  }

  static Future<void> setMode(AsteriaAppMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}
