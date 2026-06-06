import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../services/remote_character_service.dart';
import '../../widgets/participant_avatar.dart';

class SpectatorScreen extends StatefulWidget {
  final String initialShortCode;

  const SpectatorScreen({super.key, required this.initialShortCode});

  @override
  State<SpectatorScreen> createState() => _SpectatorScreenState();
}

class _SpectatorScreenState extends State<SpectatorScreen> {
  final RemoteCharacterService _remoteService = RemoteCharacterService();

  String _sessionName = "Session de combat";
  int _turnCount = 1;
  bool _combatStarted = false;
  int? _activeIndex; // 💡 Index du joueur actif reçu du cloud
  List<dynamic> _participants = [];

  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchSessionData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchSessionData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSessionData() async {
    final result = await _remoteService.getSpectatorSession(
      widget.initialShortCode,
    );

    if (!mounted) return;

    if (result == null || result['ok'] != true) {
      setState(() {
        if (_isLoading) {
          _errorMessage =
              result?['error'] ??
              "Impossible de charger la session.\nVérifiez le code.";
        }
        _isLoading = false;
      });
      return;
    }

    final session = result['session'] as Map<String, dynamic>? ?? {};
    final rawParticipants = session['participants'] as List<dynamic>? ?? [];

    final List<dynamic> sortedParticipants = List.from(rawParticipants);

    // 🎲 Tri par initiative uniquement si le combat n'est pas encore lancé par le MJ.
    // Si le combat a commencé, on garde strictement l'ordre du tableau envoyé par le MJ.
    if (!session['combatStarted']) {
      sortedParticipants.sort((a, b) {
        final int initA = a['rolledInitiative'] ?? 0;
        final int initB = b['rolledInitiative'] ?? 0;
        return initB.compareTo(initA);
      });
    }

    setState(() {
      _sessionName = session['name'] ?? "Combat en cours";
      _turnCount = session['turnCount'] ?? 1;
      _combatStarted = session['combatStarted'] ?? false;
      _activeIndex =
          session['activeIndex']; // 💡 Récupération de l'index du tour
      _participants = sortedParticipants;
      _errorMessage = null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _sessionName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _combatStarted ? 'Tour $_turnCount' : 'En attente du MJ...',
              style: TextStyle(
                fontSize: 12,
                color: _combatStarted ? Colors.amber.shade300 : Colors.white38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.sync,
              size: 16,
              color:
                  _isLoading
                      ? Colors.purple
                      : Colors.greenAccent.withAlpha(100),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _participants.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      );
    }

    if (_errorMessage != null && _participants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _fetchSessionData();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_participants.isEmpty) {
      return const Center(
        child: Text(
          "Aucun participant dans ce combat pour le moment.",
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _participants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = _participants[index];
        final bool isAlly = p['isAlly'] ?? false;
        final bool isAlive = p['isAlive'] ?? true;
        final Color factionColor =
            isAlly ? AppColors.allyPrimary : AppColors.enemyPrimary;

        // 💡 Détection de si c'est au tour de ce personnage de jouer
        final bool isActiveTurn = _combatStarted && _activeIndex == index;

        double hpPercent = 0.0;
        if (p['hpPercent'] != null) {
          hpPercent = (p['hpPercent'] as num).toDouble();
        } else if (p['maxHp'] != null && p['maxHp'] > 0) {
          hpPercent = (p['currentHp'] ?? 0) / p['maxHp'];
        }

        Color hpColor = Colors.green;
        try {
          hpColor = AppColors.hpColor((hpPercent * 100).toInt());
        } catch (_) {
          hpColor =
              hpPercent > 0.5
                  ? Colors.green
                  : (hpPercent > 0.2 ? Colors.orange : Colors.red);
        }

        return Opacity(
          opacity: isAlive ? 1.0 : 0.4,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            // 💡 Effet d'ombrage lumineux si c'est le tour du personnage (comme le MJ)
            decoration: BoxDecoration(
              color:
                  isActiveTurn
                      ? factionColor.withAlpha(50)
                      : factionColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActiveTurn ? factionColor : factionColor.withAlpha(50),
                width: isActiveTurn ? 2 : 1,
              ),
              boxShadow:
                  isActiveTurn
                      ? [
                        BoxShadow(
                          color: factionColor.withAlpha(80),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                      : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Badge d'index de l'ordre de jeu
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color:
                              isActiveTurn
                                  ? factionColor
                                  : factionColor.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActiveTurn ? Colors.white : factionColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      ParticipantAvatar(
                        name: p['name'] ?? '?',
                        isAlly: isAlly,
                        imageUrl: p['imageUrl'],
                        radius: 18,
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['name'] ?? 'Inconnu',
                              style: TextStyle(
                                // 💡 1. Remplacement du premier fontWeight erroné par fontSize
                                fontSize: isActiveTurn ? 16 : 15,
                                // 💡 2. Correction de withAlpha vers la nouvelle syntaxe Flutter
                                color:
                                    isActiveTurn
                                        ? Colors.white
                                        : Colors.white.withAlpha(220),
                                // 💡 3. Le vrai fontWeight reste ici
                                fontWeight:
                                    isActiveTurn
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                decoration:
                                    isAlive ? null : TextDecoration.lineThrough,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isAlly ? 'Aventurier' : 'Ennemi',
                              style: TextStyle(
                                fontSize: 11,
                                color: factionColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (isAlly && p['def'] != null)
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.shield,
                              color: Colors.grey.shade700,
                              size: 36,
                            ),
                            Text(
                              '${p['def']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        )
                      else if (!isAlly)
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.shield,
                              color: Colors.grey.shade900,
                              size: 36,
                            ),
                            const Text(
                              '?',
                              style: TextStyle(
                                color: Colors.white38,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(width: 12),

                      // 🎲 AFFICHAGE DE L'INITIATIVE
                      Column(
                        children: [
                          Text(
                            '${p['rolledInitiative'] ?? 0}',
                            style: TextStyle(
                              color: isActiveTurn ? Colors.white : factionColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const Text(
                            'init',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 📢 AJOUT : LIGNE DES ALTÉRATIONS D'ÉTAT POUR LE SPECTATEUR
                  if (p['statusEffects'] != null && (p['statusEffects'] as List).isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: (p['statusEffects'] as List).map((effect) {
                        // On essaie de récupérer la configuration (couleur/icône) par rapport au nom de l'état
                        // Si ton spectator_screen n'a pas accès à definitionFor, on applique des valeurs par défaut élégantes
                        final String effectName = effect['name'] ?? 'État';
                        final int turns = effect['remainingTurns'] ?? 1;

                        // Palette de couleurs générique et propre par défaut (Orange/Ambre pour les altérations)
                        final Color stateColor = Colors.amber.shade600;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: stateColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: stateColor.withAlpha(120)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 12, color: stateColor),
                              const SizedBox(width: 4),
                              Text(
                                effectName,
                                style: TextStyle(
                                    color: stateColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                                decoration: BoxDecoration(
                                  color: stateColor.withAlpha(50),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${turns}t',
                                  style: TextStyle(
                                      color: stateColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10), // Espacement entre les états et la barre de PV
                  ],

                  // 💚 BARRE DE PV (Inchangée, elle se retrouve juste en dessous)
                  Row(
                    children: [
                      Icon(isAlive ? Icons.favorite : Icons.heart_broken, size: 14, color: hpColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: hpPercent,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade900,
                            valueColor: AlwaysStoppedAnimation<Color>(hpColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isAlly && p['maxHp'] != null
                            ? '${p['currentHp']} / ${p['maxHp']}'
                            : _getHpLabel(hpPercent, isAlive),
                        style: TextStyle(color: hpColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getHpLabel(double percent, bool isAlive) {
    if (!isAlive) return "Mort";
    if (percent >= 1.0) return "Indemne";
    if (percent > 0.75) return "Égratigné";
    if (percent > 0.4) return "Blessé";
    if (percent > 0.15) return "Gravement Blessé";
    return "Agonisant";
  }
}
