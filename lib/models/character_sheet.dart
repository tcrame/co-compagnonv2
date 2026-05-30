import 'dart:convert';

import '../constants/cof2_data.dart';

class CharacterSheet {
  final int? id;
  final String name;
  final int level;
  final String race;
  final String profile;
  final DateTime createdAt;

  // ── Caractéristiques ───────────────────────────────────────────────────────
  final String statPreset; // 'polyvalent' | 'expert' | 'specialiste' | ''
  final int agiVal;
  final int agiRacial;
  final int agiBonus;
  final int conVal;
  final int conRacial;
  final int conBonus;
  final int forVal;
  final int forRacial;
  final int forBonus;
  final int perVal;
  final int perRacial;
  final int perBonus;
  final int chaVal;
  final int chaRacial;
  final int chaBonus;
  final int intVal;
  final int intRacial;
  final int intBonus;
  final int volVal;
  final int volRacial;
  final int volBonus;

  // ── Attaque ────────────────────────────────────────────────────────────────
  // attContactBase / attDistanceBase / attMagiqueBase = level (calculé)
  final int attContactBonus;
  final int attContactMalus;

  final int attDistanceBonus;
  final int attDistanceMalus;

  final int attMagiqueBonus;
  final int attMagiqueMalus;

  // ── Initiative ─────────────────────────────────────────────────────────────
  final int initBase;
  final int initBonus;
  final int initMalus;

  // ── Vitalité (PV) ──────────────────────────────────────────────────────────
  final String pvDv;
  final int pvBase;
  final int pvBonus;
  final int pvActuel;

  // ── Récupération (DR) ──────────────────────────────────────────────────────
  final int drBase;
  final int drBonus;
  final int drActuel;

  // ── Défense ────────────────────────────────────────────────────────────────
  final int defBase;
  final int defBonus;
  final int defMalus;

  // ── Réduction des Dégâts (RD) ─────────────────────────────────────────────
  final int rdBase;
  final int rdBonus;
  final int rdMalus;

  // ── Ressources ─────────────────────────────────────────────────────────────
  final int pmBase;
  final int pmBonus;
  final int pmActuel;

  final int pcBase;
  final int pcBonus;
  final int pcActuel;

  // ── Encombrement ───────────────────────────────────────────────────────────
  final int encArmure;
  final int encAutre;

  // ── Points de compétence ───────────────────────────────────────────────────
  final int pointsCompetence;

  // ── Monnaie ────────────────────────────────────────────────────────────────
  final int monnaiePC; // pièces de cuivre
  final int monnaiePA; // pièces d'argent  (1 PA = 10 PC)
  final int monnaiePO; // pièces d'or       (1 PO = 10 PA)
  final int monnaiePP; // pièces de platine (1 PP = 10 PO)

  // ── Notes par onglet ───────────────────────────────────────────────────────
  final String description;
  final String notesCombat;
  final String notesInventaire;
  final String notesVoies;
  final String notesEffets;

  /// JSON-encoded Map<String, int> of bonuses from equipped/activated items
  final String equipmentBonusesJson;

  /// ID of the voie de peuple currently assigned to this character.
  /// Empty string means no voie de peuple has been chosen yet.
  /// Special value 'peuple_voie-du-mage' means the character replaced their
  /// peuple voie with the Voie du Mage (Mage family profiles only).
  final String voiePeupleId;

  /// When voiePeupleId == 'peuple_voie-du-mage', holds the original peuple voie
  /// ID that was replaced (e.g. 'peuple_voie-du-nain'). Empty otherwise.
  final String voiePeupleOrigineId;

  /// Whether the Mage character has already claimed their one free rang 2
  /// from their original peuple voie (heritage bonus).
  final bool voieMageRang2Pris;

  CharacterSheet({
    this.id,
    required this.name,
    this.level = 1,
    this.race = '',
    this.profile = '',
    DateTime? createdAt,
    // caracs
    this.statPreset = '',
    this.agiVal = 0, this.agiRacial = 0, this.agiBonus = 0,
    this.conVal = 0, this.conRacial = 0, this.conBonus = 0,
    this.forVal = 0, this.forRacial = 0, this.forBonus = 0,
    this.perVal = 0, this.perRacial = 0, this.perBonus = 0,
    this.chaVal = 0, this.chaRacial = 0, this.chaBonus = 0,
    this.intVal = 0, this.intRacial = 0, this.intBonus = 0,
    this.volVal = 0, this.volRacial = 0, this.volBonus = 0,
    // attaque
    this.attContactBonus = 0, this.attContactMalus = 0,
    this.attDistanceBonus = 0, this.attDistanceMalus = 0,
    this.attMagiqueBonus = 0, this.attMagiqueMalus = 0,
    // initiative
    this.initBase = 0, this.initBonus = 0, this.initMalus = 0,
    // PV
    this.pvDv = '1d8', this.pvBase = 0, this.pvBonus = 0, this.pvActuel = 0,
    // DR
    this.drBase = 0, this.drBonus = 0, this.drActuel = 0,
    // DEF
    this.defBase = 10, this.defBonus = 0, this.defMalus = 0,
    // RD
    this.rdBase = 0, this.rdBonus = 0, this.rdMalus = 0,
    // PM
    this.pmBase = 0, this.pmBonus = 0, this.pmActuel = 0,
    // PC
    this.pcBase = 0, this.pcBonus = 0, this.pcActuel = 0,
    // Encombrement
    this.encArmure = 0, this.encAutre = 0,
    // Points de compétence
    this.pointsCompetence = 0,
    // Monnaie
    this.monnaiePC = 0, this.monnaiePA = 0,
    this.monnaiePO = 0, this.monnaiePP = 0,
    // Notes
    this.description = '',
    this.notesCombat = '',
    this.notesInventaire = '',
    this.notesVoies = '',
    this.notesEffets = '',
    this.equipmentBonusesJson = '{}',
    this.voiePeupleId = '',
    this.voiePeupleOrigineId = '',
    this.voieMageRang2Pris = false,
  }) : createdAt = createdAt ?? DateTime.now();

  // ── Valeurs calculées ──────────────────────────────────────────────────────

  /// Returns equipment bonus for the given stat key (0 if absent or JSON invalid)
  int _eb(String key) {
    try {
      final map = jsonDecode(equipmentBonusesJson) as Map<String, dynamic>;
      return (map[key] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  int get agiTotal => agiVal + agiRacial + agiBonus + _eb('agi');
  int get conTotal => conVal + conRacial + conBonus + _eb('con');
  int get forTotal => forVal + forRacial + forBonus + _eb('for');
  int get perTotal => perVal + perRacial + perBonus + _eb('per');
  int get chaTotal => chaVal + chaRacial + chaBonus + _eb('cha');
  int get intTotal => intVal + intRacial + intBonus + _eb('int');
  int get volTotal => volVal + volRacial + volBonus + _eb('vol');

  // Attaque : base = niveau + stat de la carac associée
  int get attContactBase => level + forTotal;
  int get attDistanceBase => level + agiTotal;
  int get attMagiqueBase => level + volTotal;

  int get attContactTotal => attContactBase + attContactBonus + _eb('att_contact') - attContactMalus;
  int get attDistanceTotal => attDistanceBase + attDistanceBonus + _eb('att_distance') - attDistanceMalus;
  int get attMagiqueTotal => attMagiqueBase + attMagiqueBonus + _eb('att_magique') - attMagiqueMalus;

  // Initiative : 10 + PER (+ bonus/malus manuels + équipement)
  int get initDerive => 10 + perTotal;
  int get initTotal => initDerive + initBonus + _eb('init') - initMalus;

  // Défense : 10 + AGI (+ bonus/malus manuels + armures équipées)
  int get defDerive => 10 + agiTotal;
  int get defTotal => defDerive + defBonus + _eb('def') - defMalus;

  int get rdTotal => rdBase + rdBonus + _eb('rd') - rdMalus;

  // PV : (2 × pvFamille) au niv.1, +pvFamille par niveau suivant, +CON par niveau
  // Formule : pvFamille × (NIV + 1) + NIV × CON
  int get pvDerive => pvFamilleForProfil(profile) * (level + 1) + level * conTotal;
  int get pvMax => pvDerive + pvBonus + _eb('pv');

  // DR : drFamille + CON (+ bonus manuel + équipement)
  int get drDerive => drFamilleForProfil(profile) + conTotal;
  int get drMax => drDerive + drBonus + _eb('dr');

  // DV : dé de récupération selon la famille
  String get dvDerive {
    final dv = getFamilleData(profile)?.dv;
    return dv ?? 'd8';
  }

  /// Valeur max du dé de récupération (pour Random().nextInt)
  int get dvMaxValue {
    switch (dvDerive) {
      case 'd6': return 6;
      case 'd10': return 10;
      case 'd12': return 12;
      default: return 8; // d8
    }
  }

  // PC : pcFamille + CHA (+ bonus manuel + équipement)
  int get pcDerive => pcFamilleForProfil(profile) + chaTotal;
  int get pcMax => pcDerive + pcBonus + _eb('pc');

  // PM : manuel (VOL + sorts appris — géré par l'utilisateur)
  int get pmMax => pmBase + pmBonus + _eb('pm');

  int get encTotal => encArmure + encAutre;

  // ── Sérialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'level': level,
    'race': race,
    'profile': profile,
    'stat_preset': statPreset,
    'created_at': createdAt.toIso8601String(),
    'agi_val': agiVal, 'agi_racial': agiRacial, 'agi_bonus': agiBonus,
    'con_val': conVal, 'con_racial': conRacial, 'con_bonus': conBonus,
    'for_val': forVal, 'for_racial': forRacial, 'for_bonus': forBonus,
    'per_val': perVal, 'per_racial': perRacial, 'per_bonus': perBonus,
    'cha_val': chaVal, 'cha_racial': chaRacial, 'cha_bonus': chaBonus,
    'int_val': intVal, 'int_racial': intRacial, 'int_bonus': intBonus,
    'vol_val': volVal, 'vol_racial': volRacial, 'vol_bonus': volBonus,
    'att_contact_bonus': attContactBonus, 'att_contact_malus': attContactMalus,
    'att_distance_bonus': attDistanceBonus, 'att_distance_malus': attDistanceMalus,
    'att_magique_bonus': attMagiqueBonus, 'att_magique_malus': attMagiqueMalus,
    'init_base': initBase, 'init_bonus': initBonus, 'init_malus': initMalus,
    'pv_dv': pvDv, 'pv_base': pvBase, 'pv_bonus': pvBonus, 'pv_actuel': pvActuel,
    'dr_base': drBase, 'dr_bonus': drBonus, 'dr_actuel': drActuel,
    'def_base': defBase, 'def_bonus': defBonus, 'def_malus': defMalus,
    'rd_base': rdBase, 'rd_bonus': rdBonus, 'rd_malus': rdMalus,
    'pm_base': pmBase, 'pm_bonus': pmBonus, 'pm_actuel': pmActuel,
    'pc_base': pcBase, 'pc_bonus': pcBonus, 'pc_actuel': pcActuel,
    'enc_armure': encArmure, 'enc_autre': encAutre,
    'points_competence': pointsCompetence,
    'monnaie_pc': monnaiePC, 'monnaie_pa': monnaiePA,
    'monnaie_po': monnaiePO, 'monnaie_pp': monnaiePP,
    'description': description,
    'notes_combat': notesCombat,
    'notes_inventaire': notesInventaire,
    'notes_voies': notesVoies,
    'notes_effets': notesEffets,
    'equipment_bonuses_json': equipmentBonusesJson,
    'voie_peuple_id': voiePeupleId,
    'voie_peuple_origine_id': voiePeupleOrigineId,
    'voie_mage_rang2_pris': voieMageRang2Pris ? 1 : 0,
  };

  factory CharacterSheet.fromMap(Map<String, dynamic> m) => CharacterSheet(
    id: m['id'] as int?,
    name: m['name'] as String,
    level: m['level'] as int? ?? 1,
    race: m['race'] as String? ?? '',
    profile: m['profile'] as String? ?? '',
    statPreset: m['stat_preset'] as String? ?? '',
    createdAt: DateTime.parse(m['created_at'] as String),
    agiVal: m['agi_val'] as int? ?? 0, agiRacial: m['agi_racial'] as int? ?? 0, agiBonus: m['agi_bonus'] as int? ?? 0,
    conVal: m['con_val'] as int? ?? 0, conRacial: m['con_racial'] as int? ?? 0, conBonus: m['con_bonus'] as int? ?? 0,
    forVal: m['for_val'] as int? ?? 0, forRacial: m['for_racial'] as int? ?? 0, forBonus: m['for_bonus'] as int? ?? 0,
    perVal: m['per_val'] as int? ?? 0, perRacial: m['per_racial'] as int? ?? 0, perBonus: m['per_bonus'] as int? ?? 0,
    chaVal: m['cha_val'] as int? ?? 0, chaRacial: m['cha_racial'] as int? ?? 0, chaBonus: m['cha_bonus'] as int? ?? 0,
    intVal: m['int_val'] as int? ?? 0, intRacial: m['int_racial'] as int? ?? 0, intBonus: m['int_bonus'] as int? ?? 0,
    volVal: m['vol_val'] as int? ?? 0, volRacial: m['vol_racial'] as int? ?? 0, volBonus: m['vol_bonus'] as int? ?? 0,
    attContactBonus: m['att_contact_bonus'] as int? ?? 0,
    attContactMalus: m['att_contact_malus'] as int? ?? 0,
    attDistanceBonus: m['att_distance_bonus'] as int? ?? 0,
    attDistanceMalus: m['att_distance_malus'] as int? ?? 0,
    attMagiqueBonus: m['att_magique_bonus'] as int? ?? 0,
    attMagiqueMalus: m['att_magique_malus'] as int? ?? 0,
    initBase: m['init_base'] as int? ?? 0,
    initBonus: m['init_bonus'] as int? ?? 0,
    initMalus: m['init_malus'] as int? ?? 0,
    pvDv: m['pv_dv'] as String? ?? '1d8',
    pvBase: m['pv_base'] as int? ?? 0,
    pvBonus: m['pv_bonus'] as int? ?? 0,
    pvActuel: m['pv_actuel'] as int? ?? 0,
    drBase: m['dr_base'] as int? ?? 0,
    drBonus: m['dr_bonus'] as int? ?? 0,
    drActuel: m['dr_actuel'] as int? ?? 0,
    defBase: m['def_base'] as int? ?? 10,
    defBonus: m['def_bonus'] as int? ?? 0,
    defMalus: m['def_malus'] as int? ?? 0,
    rdBase: m['rd_base'] as int? ?? 0,
    rdBonus: m['rd_bonus'] as int? ?? 0,
    rdMalus: m['rd_malus'] as int? ?? 0,
    pmBase: m['pm_base'] as int? ?? 0,
    pmBonus: m['pm_bonus'] as int? ?? 0,
    pmActuel: m['pm_actuel'] as int? ?? 0,
    pcBase: m['pc_base'] as int? ?? 0,
    pcBonus: m['pc_bonus'] as int? ?? 0,
    pcActuel: m['pc_actuel'] as int? ?? 0,
    encArmure: m['enc_armure'] as int? ?? 0,
    encAutre: m['enc_autre'] as int? ?? 0,
    pointsCompetence: m['points_competence'] as int? ?? 0,
    monnaiePC: m['monnaie_pc'] as int? ?? 0,
    monnaiePA: m['monnaie_pa'] as int? ?? 0,
    monnaiePO: m['monnaie_po'] as int? ?? 0,
    monnaiePP: m['monnaie_pp'] as int? ?? 0,
    description: m['description'] as String? ?? '',
    notesCombat: m['notes_combat'] as String? ?? '',
    notesInventaire: m['notes_inventaire'] as String? ?? '',
    notesVoies: m['notes_voies'] as String? ?? '',
    notesEffets: m['notes_effets'] as String? ?? '',
    equipmentBonusesJson: m['equipment_bonuses_json'] as String? ?? '{}',
    voiePeupleId: m['voie_peuple_id'] as String? ?? '',
    voiePeupleOrigineId: m['voie_peuple_origine_id'] as String? ?? '',
    voieMageRang2Pris: (m['voie_mage_rang2_pris'] as int? ?? 0) == 1,
  );

  CharacterSheet copyWith({
    int? id,
    String? name, int? level, String? race, String? profile, String? statPreset,
    int? agiVal, int? agiRacial, int? agiBonus,
    int? conVal, int? conRacial, int? conBonus,
    int? forVal, int? forRacial, int? forBonus,
    int? perVal, int? perRacial, int? perBonus,
    int? chaVal, int? chaRacial, int? chaBonus,
    int? intVal, int? intRacial, int? intBonus,
    int? volVal, int? volRacial, int? volBonus,
    int? attContactBonus, int? attContactMalus,
    int? attDistanceBonus, int? attDistanceMalus,
    int? attMagiqueBonus, int? attMagiqueMalus,
    int? initBase, int? initBonus, int? initMalus,
    String? pvDv, int? pvBase, int? pvBonus, int? pvActuel,
    int? drBase, int? drBonus, int? drActuel,
    int? defBase, int? defBonus, int? defMalus,
    int? rdBase, int? rdBonus, int? rdMalus,
    int? pmBase, int? pmBonus, int? pmActuel,
    int? pcBase, int? pcBonus, int? pcActuel,
    int? encArmure, int? encAutre,
    int? pointsCompetence,
    int? monnaiePC, int? monnaiePA, int? monnaiePO, int? monnaiePP,
    String? description,
    String? notesCombat, String? notesInventaire,
    String? notesVoies, String? notesEffets,
    String? equipmentBonusesJson,
    String? voiePeupleId,
    String? voiePeupleOrigineId,
    bool? voieMageRang2Pris,
  }) => CharacterSheet(
    id: id ?? this.id,
    name: name ?? this.name,
    level: level ?? this.level,
    race: race ?? this.race,
    profile: profile ?? this.profile,
    statPreset: statPreset ?? this.statPreset,
    createdAt: createdAt,
    agiVal: agiVal ?? this.agiVal, agiRacial: agiRacial ?? this.agiRacial, agiBonus: agiBonus ?? this.agiBonus,
    conVal: conVal ?? this.conVal, conRacial: conRacial ?? this.conRacial, conBonus: conBonus ?? this.conBonus,
    forVal: forVal ?? this.forVal, forRacial: forRacial ?? this.forRacial, forBonus: forBonus ?? this.forBonus,
    perVal: perVal ?? this.perVal, perRacial: perRacial ?? this.perRacial, perBonus: perBonus ?? this.perBonus,
    chaVal: chaVal ?? this.chaVal, chaRacial: chaRacial ?? this.chaRacial, chaBonus: chaBonus ?? this.chaBonus,
    intVal: intVal ?? this.intVal, intRacial: intRacial ?? this.intRacial, intBonus: intBonus ?? this.intBonus,
    volVal: volVal ?? this.volVal, volRacial: volRacial ?? this.volRacial, volBonus: volBonus ?? this.volBonus,
    attContactBonus: attContactBonus ?? this.attContactBonus,
    attContactMalus: attContactMalus ?? this.attContactMalus,
    attDistanceBonus: attDistanceBonus ?? this.attDistanceBonus,
    attDistanceMalus: attDistanceMalus ?? this.attDistanceMalus,
    attMagiqueBonus: attMagiqueBonus ?? this.attMagiqueBonus,
    attMagiqueMalus: attMagiqueMalus ?? this.attMagiqueMalus,
    initBase: initBase ?? this.initBase,
    initBonus: initBonus ?? this.initBonus,
    initMalus: initMalus ?? this.initMalus,
    pvDv: pvDv ?? this.pvDv,
    pvBase: pvBase ?? this.pvBase,
    pvBonus: pvBonus ?? this.pvBonus,
    pvActuel: pvActuel ?? this.pvActuel,
    drBase: drBase ?? this.drBase,
    drBonus: drBonus ?? this.drBonus,
    drActuel: drActuel ?? this.drActuel,
    defBase: defBase ?? this.defBase,
    defBonus: defBonus ?? this.defBonus,
    defMalus: defMalus ?? this.defMalus,
    rdBase: rdBase ?? this.rdBase,
    rdBonus: rdBonus ?? this.rdBonus,
    rdMalus: rdMalus ?? this.rdMalus,
    pmBase: pmBase ?? this.pmBase,
    pmBonus: pmBonus ?? this.pmBonus,
    pmActuel: pmActuel ?? this.pmActuel,
    pcBase: pcBase ?? this.pcBase,
    pcBonus: pcBonus ?? this.pcBonus,
    pcActuel: pcActuel ?? this.pcActuel,
    encArmure: encArmure ?? this.encArmure,
    encAutre: encAutre ?? this.encAutre,
    pointsCompetence: pointsCompetence ?? this.pointsCompetence,
    monnaiePC: monnaiePC ?? this.monnaiePC,
    monnaiePA: monnaiePA ?? this.monnaiePA,
    monnaiePO: monnaiePO ?? this.monnaiePO,
    monnaiePP: monnaiePP ?? this.monnaiePP,
    description: description ?? this.description,
    notesCombat: notesCombat ?? this.notesCombat,
    notesInventaire: notesInventaire ?? this.notesInventaire,
    notesVoies: notesVoies ?? this.notesVoies,
    notesEffets: notesEffets ?? this.notesEffets,
    equipmentBonusesJson: equipmentBonusesJson ?? this.equipmentBonusesJson,
    voiePeupleId: voiePeupleId ?? this.voiePeupleId,
    voiePeupleOrigineId: voiePeupleOrigineId ?? this.voiePeupleOrigineId,
    voieMageRang2Pris: voieMageRang2Pris ?? this.voieMageRang2Pris,
  );
}
