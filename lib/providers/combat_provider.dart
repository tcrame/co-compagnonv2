import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/participant.dart';
import '../models/status_effect.dart';
import '../services/database_service.dart';
import '../services/remote_character_service.dart';

class CombatProvider extends ChangeNotifier {
  final _db = DatabaseService();
  final _rng = Random();
  final _remoteService = RemoteCharacterService();

  int? _sessionId;
  String _sessionCode = ""; // 💡 AJOUT : Mémorise le code de partage (ex: 'A4R9X2')
  String _sessionName = "Session de combat";
  List<Participant> _participants = [];
  List<Participant> _turnOrder = [];
  bool _combatStarted = false;
  int _turnCount = 0;
  int? _activeIndex;
  final Map<int, List<StatusEffect>> _statusEffects = {};

  List<Participant> get participants => _participants;
  List<Participant> get turnOrder => _turnOrder;
  String get sessionCode => _sessionCode;
  bool get combatStarted => _combatStarted;

  int? get sessionId => _sessionId;
  int get turnCount => _turnCount;
  int? get activeIndex => _activeIndex;

  Participant? get activeParticipant =>
      (_activeIndex != null && _activeIndex! < _turnOrder.length)
          ? _turnOrder[_activeIndex!]
          : null;

  List<StatusEffect> statusEffectsFor(int participantId) =>
      _statusEffects[participantId] ?? [];

  /// 🛰️ MÉTHODE INTERNE MODIFIÉE : Envoie la session via son code unique à 6 lettres
  void _syncToCloud() {
    if (_sessionId == null || _sessionCode.isEmpty) return;

    // On sélectionne la bonne liste source
    final listToSync = (_combatStarted && _turnOrder.isNotEmpty) ? _turnOrder : _participants;

    _remoteService.pushCombatSession(
      sessionCode: _sessionCode,
      sessionName: _sessionName,
      combatBlob: {
        'combatStarted': _combatStarted,
        'turnCount': _turnCount,
        'activeIndex': _activeIndex,
        'participants': listToSync.map((p) {
          final map = p.toMap();

          // 🎲 FIX : Si le combat est lancé, on injecte de force la valeur calculée (avec le dé)
          // pour que le Cloud reçoive le score final affiché à l'écran du MJ !
          if (_combatStarted) {
            map['rolled_initiative'] = p.rolledInitiative;
            map['rolledInitiative'] = p.rolledInitiative;
          } else {
            // Si le combat n'a pas commencé, le score temporaire est égal à l'initiative de base
            map['rolled_initiative'] = p.baseInitiative;
            map['rolledInitiative'] = p.baseInitiative;
          }

          final effects = _statusEffects[p.id!] ?? [];
          map['statusEffects'] = effects
              .map((e) => {
            'name': e.name,
            'description': e.description,
            'remainingTurns': e.remainingTurns,
          })
              .toList();
          return map;
        }).toList(),
      },
    );
  }

  Future<void> loadParticipants(int sessionId) async {
    _sessionId = sessionId;
    _participants = await _db.getParticipants(sessionId);
    _turnCount = await _db.getTurnCount(sessionId);

    // 💡 Récupération du nom ET du code de partage de la session depuis SQLite
    try {
      final sessions = await _db.getSessions();
      final current = sessions.firstWhere((s) => s.id == sessionId);
      _sessionName = current.name;
      _sessionCode = current.shareCode; // 💡 Stockage du code unique récupéré en local
    } catch (_) {
      _sessionName = "Table #$sessionId";
      _sessionCode = ""; // Sécurité en cas de crash
    }

    _statusEffects.clear();
    final effects = await _db.getStatusEffectsForSession(sessionId);
    for (final e in effects) {
      _statusEffects.putIfAbsent(e.participantId, () => []).add(e);
    }
    _combatStarted = false;
    _turnOrder = [];
    _activeIndex = null;
    notifyListeners();
    _syncToCloud();
  }

  Future<void> addParticipant(Participant participant) async {
    final saved = await _db.insertParticipant(participant);
    _participants.add(saved);

    if (_combatStarted) {
      final roll = _rng.nextInt(6) + 1;
      final withRoll = saved.copyWith(
        rolledInitiative: roll + saved.baseInitiative,
      );
      _turnOrder.add(withRoll);
      _turnOrder.sort((a, b) {
        final total = b.rolledInitiative!.compareTo(a.rolledInitiative!);
        if (total != 0) return total;
        final base = b.baseInitiative.compareTo(a.baseInitiative);
        if (base != 0) return base;
        final allyPriority = (b.isAlly ? 1 : 0).compareTo(a.isAlly ? 1 : 0);
        if (allyPriority != 0) return allyPriority;
        return _rng.nextBool() ? -1 : 1;
      });
    }

    notifyListeners();
    _syncToCloud();
  }

  Future<void> removeParticipant(int id) async {
    await _db.deleteParticipant(id);
    await _db.deleteStatusEffectsForParticipant(id);
    _participants.removeWhere((p) => p.id == id);
    _statusEffects.remove(id);
    if (_combatStarted) {
      _turnOrder.removeWhere((p) => p.id == id);
      if (_activeIndex != null && _activeIndex! >= _turnOrder.length) {
        _activeIndex = _turnOrder.isEmpty ? null : 0;
      }
    }
    notifyListeners();
    _syncToCloud();
  }

  Future<void> rollInitiative() async {
    _turnCount++;
    if (_sessionId != null) {
      await _db.updateTurnCount(_sessionId!, _turnCount);
    }

    for (final entry in _statusEffects.entries) {
      final toRemove = <StatusEffect>[];
      for (var i = 0; i < entry.value.length; i++) {
        final updated = entry.value[i].copyWith(
          remainingTurns: entry.value[i].remainingTurns - 1,
        );
        if (updated.remainingTurns <= 0) {
          toRemove.add(entry.value[i]);
          if (updated.id != null) await _db.deleteStatusEffect(updated.id!);
        } else {
          entry.value[i] = updated;
          if (updated.id != null) {
            await _db.updateStatusEffectTurns(
              updated.id!,
              updated.remainingTurns,
            );
          }
        }
      }
      entry.value.removeWhere((e) => toRemove.any((r) => r.id == e.id));
    }

    _turnOrder = _participants.map((p) {
      final roll = _rng.nextInt(6) + 1;
      return p.copyWith(rolledInitiative: roll + p.baseInitiative);
    }).toList();

    _turnOrder.sort((a, b) {
      final total = b.rolledInitiative!.compareTo(a.rolledInitiative!);
      if (total != 0) return total;
      final base = b.baseInitiative.compareTo(a.baseInitiative);
      if (base != 0) return base;
      final allyPriority = (b.isAlly ? 1 : 0).compareTo(a.isAlly ? 1 : 0);
      if (allyPriority != 0) return allyPriority;
      return _rng.nextBool() ? -1 : 1;
    });

    _combatStarted = true;
    _activeIndex = null;
    notifyListeners();
    _syncToCloud();
  }

  /// ⏪ AJOUT : Permet de revenir au tour de jeu précédent en cas d'erreur
  Future<void> decrementTurnCount() async {
    if (_turnCount <= 1) return; // Sécurité : on ne descend pas en dessous du tour 1

    _turnCount--;
    if (_sessionId != null) {
      await _db.updateTurnCount(_sessionId!, _turnCount);
    }

    // Note : On ne relance pas les dés automatiquement pour ne pas écraser
    // les initiatives actuelles du combat si le MJ voulait juste corriger le numéro du tour.

    notifyListeners();
    _syncToCloud(); // 🔄 Synchronisation immédiate pour les spectateurs
  }

  void startActiveTurn() {
    if (_turnOrder.isEmpty) return;
    _activeIndex = 0;
    notifyListeners();
    _syncToCloud();
  }

  void nextActiveTurn() {
    if (_turnOrder.isEmpty) return;
    _activeIndex = ((_activeIndex ?? -1) + 1) % _turnOrder.length;
    notifyListeners();
    _syncToCloud();
  }

  void prevActiveTurn() {
    if (_turnOrder.isEmpty) return;
    _activeIndex =
        ((_activeIndex ?? 0) - 1 + _turnOrder.length) % _turnOrder.length;
    notifyListeners();
    _syncToCloud();
  }

  void stopActiveTurn() {
    _activeIndex = null;
    notifyListeners();
    _syncToCloud();
  }

  Future<void> addStatusEffect(StatusEffect effect) async {
    final saved = await _db.insertStatusEffect(effect);
    _statusEffects.putIfAbsent(effect.participantId, () => []).add(saved);
    notifyListeners();
    _syncToCloud();
  }

  Future<void> removeStatusEffect(StatusEffect effect) async {
    if (effect.id != null) await _db.deleteStatusEffect(effect.id!);
    _statusEffects[effect.participantId]?.removeWhere((e) => e.id == effect.id);
    notifyListeners();
    _syncToCloud();
  }

  Future<void> applyDamage(int participantId, int amount) async {
    await _updateHp(participantId, -amount);
  }

  Future<void> applyHeal(int participantId, int amount) async {
    await _updateHp(participantId, amount);
  }

  Future<void> updateParticipantImage(int participantId, String? imageUrl) async {
    await _db.updateParticipantImage(participantId, imageUrl);

    void updateList(List<Participant> list) {
      final idx = list.indexWhere((p) => p.id == participantId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(
          imageUrl: imageUrl,
          clearImageUrl: imageUrl == null,
        );
      }
    }

    updateList(_participants);
    updateList(_turnOrder);
    notifyListeners();
    _syncToCloud();
  }

  Future<void> _updateHp(int participantId, int delta) async {
    final idx = _turnOrder.indexWhere((p) => p.id == participantId);

    if (idx == -1) {
      final pIdx = _participants.indexWhere((p) => p.id == participantId);
      if (pIdx != -1) {
        final p = _participants[pIdx];
        final newHp = (p.currentHp + delta).clamp(0, p.maxHp);
        await _db.updateParticipantHp(participantId, newHp);
        _participants[pIdx] = p.copyWith(currentHp: newHp);
        notifyListeners();
        _syncToCloud();
      }
      return;
    }

    final p = _turnOrder[idx];
    final newHp = (p.currentHp + delta).clamp(0, p.maxHp);
    await _db.updateParticipantHp(participantId, newHp);

    _turnOrder[idx] = p.copyWith(currentHp: newHp);

    final pIdx = _participants.indexWhere((p) => p.id == participantId);
    if (pIdx != -1) {
      _participants[pIdx] = _participants[pIdx].copyWith(currentHp: newHp);
    }

    notifyListeners();
    _syncToCloud();
  }

  Future<void> resetSession() async {
    if (_sessionId == null) return;
    await _db.resetAllHp(_sessionId!);
    await loadParticipants(_sessionId!);
  }
}