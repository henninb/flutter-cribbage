import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/game/engine/game_engine.dart';
import 'src/services/game_persistence.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final persistence = SharedPrefsPersistence(prefs);
  final engine = GameEngine(persistence: persistence);
  engine.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: engine,
      child: const CribbageApp(),
    ),
  );
}
