// Données statiques Chroniques Oubliées Fantasy v2

// ── Peuples ───────────────────────────────────────────────────────────────────

class PeupleData {
  final String nom;
  final String bonus;
  final String malus;
  final String profitsTypiques;

  const PeupleData({
    required this.nom,
    required this.bonus,
    required this.malus,
    required this.profitsTypiques,
  });

  String get description {
    final parts = <String>[];
    parts.add('✦ Bonus : $bonus');
    if (malus.isNotEmpty && malus != 'Aucun') parts.add('✧ Malus : $malus');
    if (profitsTypiques.isNotEmpty) parts.add('⚔ Profils : $profitsTypiques');
    return parts.join('\n');
  }
}

const kPeuples = <PeupleData>[
  PeupleData(
    nom: 'Demi-elfe',
    bonus: '+1 PER ou CHA',
    malus: '-1 FOR ou CON',
    profitsTypiques: 'Barde, Prêtre',
  ),
  PeupleData(
    nom: 'Demi-orc',
    bonus: '+1 FOR ou CON',
    malus: '-1 CHA ou INT',
    profitsTypiques: 'Barbare, Guerrier',
  ),
  PeupleData(
    nom: 'Elfe haut',
    bonus: '+1 INT ou CHA',
    malus: '-1 FOR',
    profitsTypiques: 'Barde, Magicien, Ensorceleur',
  ),
  PeupleData(
    nom: 'Elfe sylvain',
    bonus: '+1 AGI ou PER',
    malus: '-1 FOR',
    profitsTypiques: 'Druide, Rôdeur',
  ),
  PeupleData(
    nom: 'Gnome',
    bonus: '+1 INT ou PER',
    malus: '-1 FOR',
    profitsTypiques: 'Forgesort, Arquebusier',
  ),
  PeupleData(
    nom: 'Halfelin',
    bonus: '+1 AGI ou VOL',
    malus: '-1 FOR',
    profitsTypiques: 'Voleur, Rôdeur',
  ),
  PeupleData(
    nom: 'Humain',
    bonus: '+1 à l\'une des deux plus faibles carac.',
    malus: 'Aucun',
    profitsTypiques: 'Tous les profils',
  ),
  PeupleData(
    nom: 'Nain',
    bonus: '+1 CON ou VOL',
    malus: '-1 AGI',
    profitsTypiques: 'Guerrier, Prêtre',
  ),
];

PeupleData? getPeupleData(String nom) {
  try {
    return kPeuples.firstWhere((p) => p.nom == nom);
  } catch (_) {
    return null;
  }
}

// ── Choix raciaux ─────────────────────────────────────────────────────────────

/// Représente les choix de bonus/malus raciaux d'un peuple.
/// - [bonusOptions] : list de caracs parmi lesquelles choisir (+1). Vide = pas de bonus.
/// - [bonusSpecial] : true si Humain (bonus vers l'une des 2 plus faibles carac).
/// - [malusFixed] : carac fixe pour le malus (-1). Null si pas de malus fixe.
/// - [malusOptions] : list de caracs parmi lesquelles choisir (-1). Vide = malus fixe seul.
class RacialChoiceData {
  final List<String> bonusOptions;
  final bool bonusSpecial; // Humain only
  final String? malusFixed;
  final List<String> malusOptions;

  const RacialChoiceData({
    this.bonusOptions = const [],
    this.bonusSpecial = false,
    this.malusFixed,
    this.malusOptions = const [],
  });

  bool get hasMalus => malusFixed != null || malusOptions.isNotEmpty;
  bool get malusIsChoice => malusOptions.isNotEmpty;
}

const kPeupleRacial = <String, RacialChoiceData>{
  'Demi-elfe': RacialChoiceData(
    bonusOptions: ['PER', 'CHA'],
    malusOptions: ['FOR', 'CON'],
  ),
  'Demi-orc': RacialChoiceData(
    bonusOptions: ['FOR', 'CON'],
    malusOptions: ['CHA', 'INT'],
  ),
  'Elfe haut': RacialChoiceData(
    bonusOptions: ['INT', 'CHA'],
    malusFixed: 'FOR',
  ),
  'Elfe sylvain': RacialChoiceData(
    bonusOptions: ['AGI', 'PER'],
    malusFixed: 'FOR',
  ),
  'Gnome': RacialChoiceData(
    bonusOptions: ['INT', 'PER'],
    malusFixed: 'FOR',
  ),
  'Halfelin': RacialChoiceData(
    bonusOptions: ['AGI', 'VOL'],
    malusFixed: 'FOR',
  ),
  'Humain': RacialChoiceData(
    bonusSpecial: true,
  ),
  'Nain': RacialChoiceData(
    bonusOptions: ['CON', 'VOL'],
    malusFixed: 'AGI',
  ),
};

RacialChoiceData? getRacialChoice(String peuple) => kPeupleRacial[peuple];

// ── Familles de profils ────────────────────────────────────────────────────────

class FamilleData {
  final String nom;
  final int pvFamille;
  final String dv;
  final String bonus;
  /// DR de base : 3 pour Mystiques, 2 pour les autres
  final int drFamille;
  /// PC de base : 3 pour Aventuriers, 2 pour les autres
  final int pcFamille;

  const FamilleData({
    required this.nom,
    required this.pvFamille,
    required this.dv,
    required this.bonus,
    required this.drFamille,
    required this.pcFamille,
  });

  String get description {
    final parts = <String>[];
    parts.add('❤ PV famille : $pvFamille (formule niv.1 : ${pvFamille * 2} + CON)');
    parts.add('🎲 Dé de récup. : $dv (DR = $drFamille + CON)');
    if (bonus.isNotEmpty && bonus != 'Aucun') parts.add('✦ Bonus : $bonus');
    if (pcFamille == 3) parts.add('🍀 PC = $pcFamille + CHA');
    return parts.join('\n');
  }
}

const kFamilles = <String, FamilleData>{
  'Aventurier': FamilleData(
    nom: 'Aventurier',
    pvFamille: 4,
    dv: 'd8',
    bonus: '+1 PC',
    drFamille: 2,
    pcFamille: 3,
  ),
  'Combattant': FamilleData(
    nom: 'Combattant',
    pvFamille: 5,
    dv: 'd10',
    bonus: 'Aucun',
    drFamille: 2,
    pcFamille: 2,
  ),
  'Mage': FamilleData(
    nom: 'Mage',
    pvFamille: 3,
    dv: 'd6',
    bonus: 'Capacité de rang 2 gratuite à la création',
    drFamille: 2,
    pcFamille: 2,
  ),
  'Mystique': FamilleData(
    nom: 'Mystique',
    pvFamille: 4,
    dv: 'd8',
    bonus: '+1 DR',
    drFamille: 3,
    pcFamille: 2,
  ),
};

// ── Profils ────────────────────────────────────────────────────────────────────

const kProfilFamille = <String, String>{
  'Arquebusier': 'Aventurier',
  'Barde': 'Aventurier',
  'Rôdeur': 'Aventurier',
  'Voleur': 'Aventurier',
  'Barbare': 'Combattant',
  'Chevalier': 'Combattant',
  'Guerrier': 'Combattant',
  'Ensorceleur': 'Mage',
  'Forgesort': 'Mage',
  'Magicien': 'Mage',
  'Sorcier': 'Mage',
  'Druide': 'Mystique',
  'Moine': 'Mystique',
  'Prêtre': 'Mystique',
};

const kProfilsParFamille = <String, List<String>>{
  'Aventurier': ['Arquebusier', 'Barde', 'Rôdeur', 'Voleur'],
  'Combattant': ['Barbare', 'Chevalier', 'Guerrier'],
  'Mage': ['Ensorceleur', 'Forgesort', 'Magicien', 'Sorcier'],
  'Mystique': ['Druide', 'Moine', 'Prêtre'],
};

final kTousProfils = kProfilsParFamille.values.expand((l) => l).toList();

String? getFamilleForProfil(String profil) => kProfilFamille[profil];

FamilleData? getFamilleData(String profil) {
  final famille = kProfilFamille[profil];
  if (famille == null) return null;
  return kFamilles[famille];
}

// ── Helpers famille pour calculs ──────────────────────────────────────────────

/// PV famille selon le profil (0 si inconnu)
int pvFamilleForProfil(String profil) =>
    getFamilleData(profil)?.pvFamille ?? 0;

/// DR de base selon le profil (3 si Mystique, 2 sinon, 0 si inconnu)
int drFamilleForProfil(String profil) =>
    getFamilleData(profil)?.drFamille ?? 0;

/// PC de base selon le profil (3 si Aventurier, 2 sinon, 0 si inconnu)
int pcFamilleForProfil(String profil) =>
    getFamilleData(profil)?.pcFamille ?? 0;

