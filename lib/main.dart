import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart'; // Pour databaseFactory
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // Pour le Web

import 'app_theme.dart';
import 'providers/bestiary_provider.dart';
import 'providers/character_sheet_provider.dart';
import 'providers/combat_provider.dart';
import 'providers/session_provider.dart';
import 'screens/landing/landing_screen.dart';

void main() async {
  // 1. On s'assure que l'infrastructure Flutter est initialisée
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Configuration spécifique pour le Web
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;

    // 🛡️ LE FIX ULTIME : Capture les erreurs asynchrones de zone (micro-tâches/promesses)
    // qui échappent au framework classique et font crasher le plugin Google Sign-In.
    PlatformDispatcher.instance.onError = (error, stack) {
      if (error.toString().contains('Future already completed')) {
        // On étouffe silencieusement le doublon asynchrone interne de Google Web
        return true;
      }
      return false; // Laisse passer les autres vraies erreurs
    };
  }

  // 3. Lancement sans le mot-clé 'const' bloquant
  runApp(CoCompagnonApp());
}

class CoCompagnonApp extends StatelessWidget {
  const CoCompagnonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => CombatProvider()),
        ChangeNotifierProvider(create: (_) => BestiaryProvider()),
        ChangeNotifierProvider(create: (_) => CharacterSheetProvider()),
      ],
      child: MaterialApp(
        title: 'CO Compagnon V2',
        debugShowCheckedModeBanner: false,
        theme: buildDarkTheme(),
        home: const LandingScreen(),
      ),
    );
  }
}