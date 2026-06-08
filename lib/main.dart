import 'package:flutter/foundation.dart'; // 💡 AJOUT : Requis pour kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart'; // 💡 AJOUT : Requis pour databaseFactory
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // 💡 AJOUT : Requis pour le Web

import 'app_theme.dart';
import 'providers/bestiary_provider.dart';
import 'providers/character_sheet_provider.dart';
import 'providers/combat_provider.dart';
import 'providers/session_provider.dart';
import 'screens/landing/landing_screen.dart';

void main() async {
  // 💡 Assure l'initialisation correcte des bindings Flutter avant de toucher aux plugins
  WidgetsFlutterBinding.ensureInitialized();

  // 🌐 FIX UNCAUGHT ERROR : On force la factory SQLite FFI Web globale avant le chargement des écrans
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  runApp(const CoCompagnonApp());
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