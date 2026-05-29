import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'providers/bestiary_provider.dart';
import 'providers/character_sheet_provider.dart';
import 'providers/combat_provider.dart';
import 'providers/session_provider.dart';
import 'screens/landing/landing_screen.dart';

void main() {
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
