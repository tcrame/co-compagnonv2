import 'package:flutter/foundation.dart';

import '../models/combat_session.dart';
import '../services/database_service.dart';

class SessionProvider extends ChangeNotifier {
  final _db = DatabaseService();

  List<CombatSession> _sessions = [];
  bool _loading = false;

  List<CombatSession> get sessions => _sessions;
  bool get loading => _loading;

  Future<void> loadSessions() async {
    _loading = true;
    notifyListeners();
    _sessions = await _db.getSessions();
    _loading = false;
    notifyListeners();
  }

  Future<CombatSession> createSession(String name) async {
    final session = await _db.insertSession(CombatSession(
      name: name,
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
