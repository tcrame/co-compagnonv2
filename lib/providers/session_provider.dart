import 'package:flutter/foundation.dart';
import 'dart:math';

import '../models/combat_session.dart';
import '../services/database_service.dart';

class SessionProvider extends ChangeNotifier {
  final _db = DatabaseService();

  List<CombatSession> _sessions = [];
  bool _loading = false;

  List<CombatSession> get sessions => _sessions;
  bool get loading => _loading;

  /// 🎰 Méthode utilitaire pour fabriquer un jeton unique de 6 caractères
  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<void> loadSessions() async {
    _loading = true;
    notifyListeners();
    _sessions = await _db.getSessions();
    _loading = false;
    notifyListeners();
  }

  Future<CombatSession> createSession(String name) async {
    // 💡 On passe le jeton généré (ex: 'R8Y2W4') à la création
    final session = await _db.insertSession(CombatSession(
      name: name,
      shareCode: _generateRandomCode(),
      createdAt: DateTime.now(),
    ));
    _sessions.insert(0, session);
    notifyListeners();
    return session;
  }

  Future<void> deleteSession(int id) async {
    await _db.deleteSession(id);
    _sessions.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}