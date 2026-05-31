import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/participant.dart';
import '../models/status_effect.dart';
import '../services/database_service.dart';

class CombatProvider extends ChangeNotifier {
  final _db = DatabaseService();
  final _rng = Random();

  int? _sessionId;
  List<Participant> _participants = [];
  List<Participant> _turnOrder = [];
  bool _combatStarted = false;
  int _turnCount = 0;
  int? _activeIndex; // index in _turnOrder of the current active participant
  // participantId → list of active status effects
  final Map<int, List<StatusEffect>> _statusEffects = {};

  List<Participant> get participants => _participants;
  List<Participant> get turnOrder => _turnOrder;
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

  Future<void> loadParticipants(int sessionId) async {
    _sessionId = sessionId;
    _participants = await _db.getParticipants(sessionId);
    _turnCount = await _db.getTurnCount(sessionId);
    _statusEffects.clear();
    final effects = await _db.getStatusEffectsForSession(sessionId);
    for (final e in effects) {
      _statusEffects.putIfAbsent(e.participantId, () => []).add(e);
    }
    _combatStarted = false;
    _turnOrder = [];
    _activeIndex = null;
    notifyListeners();
  }

  Future<void> addParticipant(Participant participant) async {
    final saved = await _db.insertParticipant(participant);
    _participants.add(saved);

    if (_combatStarted) {
      final roll = _rng.nextInt(6) + 1;
      final withRoll = saved.copyWith(rolledInitiative: roll + saved.baseInitiative);
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
  }

  Future<void> removeParticipant(int id) async {
    await _db.deleteParticipant(id);
    await _db.deleteStatusEffectsForParticipant(id);
    _participants.removeWhere((p) => p.id == id);
    _statusEffects.remove(id);
    if (_combatStarted) {
      _turnOrder.removeWhere((p) => p.id == id);
      // Reset active index if it's now out of bounds
      if (_activeIndex != null && _activeIndex! >= _turnOrder.length) {
        _activeIndex = _turnOrder.isEmpty ? null : 0;
      }
    }
    notifyListeners();
  }

  /// Roll 1d6 for each participant and sort by total initiative.
  /// Also increments turn counter and decrements status effect durations.
  Future<void> rollInitiative() async {
    _turnCount++;
    if (_sessionId != null) {
      await _db.updateTurnCount(_sessionId!, _turnCount);
    }

    // Decrement status effects; remove expired ones
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
            await _db.updateStatusEffectTurns(updated.id!, updated.remainingTurns);
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
  }

  /// Start tracking the active turn — sets the first participant as active.
  void startActiveTurn() {
    if (_turnOrder.isEmpty) return;
    _activeIndex = 0;
    notifyListeners();
  }

  /// Move to the next participant. Wraps around to index 0.
  void nextActiveTurn() {
    if (_turnOrder.isEmpty) return;
    _activeIndex = ((_activeIndex ?? -1) + 1) % _turnOrder.length;
    notifyListeners();
  }

  /// Move to the previous participant. Wraps around.
  void prevActiveTurn() {
    if (_turnOrder.isEmpty) return;
    _activeIndex = ((_activeIndex ?? 0) - 1 + _turnOrder.length) % _turnOrder.length;
    notifyListeners();
  }

  /// Stop tracking the active turn.
  void stopActiveTurn() {
    _activeIndex = null;
    notifyListeners();
  }

  Future<void> addStatusEffect(StatusEffect effect) async {
    final saved = await _db.insertStatusEffect(effect);
    _statusEffects.putIfAbsent(effect.participantId, () => []).add(saved);
    notifyListeners();
  }

  Future<void> removeStatusEffect(StatusEffect effect) async {
    if (effect.id != null) await _db.deleteStatusEffect(effect.id!);
    _statusEffects[effect.participantId]?.removeWhere((e) => e.id == effect.id);
    notifyListeners();
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
      if (idx != -1) list[idx] = list[idx].copyWith(imageUrl: imageUrl, clearImageUrl: imageUrl == null);
    }

    updateList(_participants);
    updateList(_turnOrder);
    notifyListeners();
  }

  Future<void> _updateHp(int participantId, int delta) async {
    final idx = _turnOrder.indexWhere((p) => p.id == participantId);
    if (idx == -1) return;

    final p = _turnOrder[idx];
    final newHp = (p.currentHp + delta).clamp(0, p.maxHp);
    await _db.updateParticipantHp(participantId, newHp);

    _turnOrder[idx] = p.copyWith(currentHp: newHp);

    final pIdx = _participants.indexWhere((p) => p.id == participantId);
    if (pIdx != -1) {
      _participants[pIdx] = _participants[pIdx].copyWith(currentHp: newHp);
    }

    notifyListeners();
  }

  Future<void> resetSession() async {
    if (_sessionId == null) return;
    await _db.resetAllHp(_sessionId!);
    await loadParticipants(_sessionId!);
  }
}
