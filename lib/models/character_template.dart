import 'dart:convert';

enum CreatureType {
  vivant('Vivant'),
  humanoide('Humanoïde'),
  nonVivant('Non-Vivant');

  const CreatureType(this.label);
  final String label;

  static CreatureType fromString(String? s) {
    return CreatureType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => CreatureType.vivant,
    );
  }
}

enum CreatureTaille {
  petite('Petite'),
  moyenne('Moyenne'),
  grande('Grande'),
  enorme('Énorme'),
  colossale('Colossale');

  const CreatureTaille(this.label);
  final String label;

  static CreatureTaille fromString(String? s) {
    return CreatureTaille.values.firstWhere(
      (e) => e.name == s,
      orElse: () => CreatureTaille.moyenne,
    );
  }
}

enum CreatureArchetype {
  inferieur('Inférieur'),
  standard('Standard'),
  puissant('Puissant');

  const CreatureArchetype(this.label);
  final String label;

  static CreatureArchetype fromString(String? s) {
    return CreatureArchetype.values.firstWhere(
      (e) => e.name == s,
      orElse: () => CreatureArchetype.standard,
    );
  }
}

/// An attack entry for a creature template.
class TemplateAttack {
  final String name;
  final int bonusAtk;
  final int nbAttacks;
  final String dm;

  const TemplateAttack({
    required this.name,
    this.bonusAtk = 0,
    this.nbAttacks = 1,
    this.dm = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'bonusAtk': bonusAtk,
        'nbAttacks': nbAttacks,
        'dm': dm,
      };

  factory TemplateAttack.fromJson(Map<String, dynamic> j) => TemplateAttack(
        name: j['name'] as String? ?? '',
        bonusAtk: j['bonusAtk'] as int? ?? 0,
        nbAttacks: j['nbAttacks'] as int? ?? 1,
        dm: j['dm'] as String? ?? '',
      );

  TemplateAttack copyWith({
    String? name,
    int? bonusAtk,
    int? nbAttacks,
    String? dm,
  }) =>
      TemplateAttack(
        name: name ?? this.name,
        bonusAtk: bonusAtk ?? this.bonusAtk,
        nbAttacks: nbAttacks ?? this.nbAttacks,
        dm: dm ?? this.dm,
      );
}

/// A capacity / special ability for a creature template.
/// [actionType] ∈ {"A", "M", "L", "*"} (Action, Mouvement, Libre, Passive)
class TemplateCapacity {
  final String name;
  final String description;
  final String actionType; // "A", "M", "L", "*"
  final String dm;

  const TemplateCapacity({
    required this.name,
    this.description = '',
    this.actionType = '',
    this.dm = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'actionType': actionType,
        'dm': dm,
      };

  factory TemplateCapacity.fromJson(Map<String, dynamic> j) => TemplateCapacity(
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        actionType: j['actionType'] as String? ?? '',
        dm: j['dm'] as String? ?? '',
      );

  TemplateCapacity copyWith({
    String? name,
    String? description,
    String? actionType,
    String? dm,
  }) =>
      TemplateCapacity(
        name: name ?? this.name,
        description: description ?? this.description,
        actionType: actionType ?? this.actionType,
        dm: dm ?? this.dm,
      );
}

class CharacterTemplate {
  final int? id;
  final String name;
  final bool isAlly;
  final int baseInitiative;
  final int maxHp;
  final int def;
  final String vitesse;
  final String? imageUrl;

  // Extended creature fields
  final int? nc;
  final CreatureType creatureType;
  final CreatureTaille taille;
  final CreatureArchetype archetype;

  // Stats
  final int forVal;
  final int agiVal;
  final int conVal;
  final int intVal;
  final int perVal;
  final int chaVal;
  final int volVal;

  /// Set of stat keys that are "supérieures" (e.g. {'for', 'agi'}).
  /// A superior stat grants a bonus d20 roll (keep best of 2).
  final Set<String> superiorStats;

  // Attacks & capacities (serialised as JSON in DB)
  final List<TemplateAttack> attacks;
  final List<TemplateCapacity> capacities;

  const CharacterTemplate({
    this.id,
    required this.name,
    required this.isAlly,
    required this.baseInitiative,
    required this.maxHp,
    this.def = 10,
    this.vitesse = '9m',
    this.imageUrl,
    this.nc,
    this.creatureType = CreatureType.vivant,
    this.taille = CreatureTaille.moyenne,
    this.archetype = CreatureArchetype.standard,
    this.forVal = 0,
    this.agiVal = 0,
    this.conVal = 0,
    this.intVal = 0,
    this.perVal = 0,
    this.chaVal = 0,
    this.volVal = 0,
    this.superiorStats = const {},
    this.attacks = const [],
    this.capacities = const [],
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'is_ally': isAlly ? 1 : 0,
        'base_initiative': baseInitiative,
        'max_hp': maxHp,
        'def': def,
        'vitesse': vitesse,
        'image_url': imageUrl,
        'nc': nc,
        'creature_type': creatureType.name,
        'taille': taille.name,
        'archetype': archetype.name,
        'for_val': forVal,
        'agi_val': agiVal,
        'con_val': conVal,
        'int_val': intVal,
        'per_val': perVal,
        'cha_val': chaVal,
        'vol_val': volVal,
        'attacks_json': jsonEncode(attacks.map((a) => a.toJson()).toList()),
        'capacities_json':
            jsonEncode(capacities.map((c) => c.toJson()).toList()),
        'superior_stats_json': jsonEncode(superiorStats.toList()),
      };

  factory CharacterTemplate.fromMap(Map<String, dynamic> map) {
    List<TemplateAttack> attacks = [];
    List<TemplateCapacity> capacities = [];
    Set<String> superiorStats = {};
    try {
      final atkRaw = map['attacks_json'] as String?;
      if (atkRaw != null && atkRaw.isNotEmpty) {
        attacks = (jsonDecode(atkRaw) as List)
            .map((e) => TemplateAttack.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    try {
      final capRaw = map['capacities_json'] as String?;
      if (capRaw != null && capRaw.isNotEmpty) {
        capacities = (jsonDecode(capRaw) as List)
            .map((e) => TemplateCapacity.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    try {
      final supRaw = map['superior_stats_json'] as String?;
      if (supRaw != null && supRaw.isNotEmpty) {
        superiorStats =
            Set<String>.from((jsonDecode(supRaw) as List).cast<String>());
      }
    } catch (_) {}

    return CharacterTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      isAlly: (map['is_ally'] as int) == 1,
      baseInitiative: map['base_initiative'] as int,
      maxHp: map['max_hp'] as int,
      def: (map['def'] as int?) ?? 10,
      vitesse: (map['vitesse'] as String?) ?? '9m',
      imageUrl: map['image_url'] as String?,
      nc: map['nc'] as int?,
      creatureType: CreatureType.fromString(map['creature_type'] as String?),
      taille: CreatureTaille.fromString(map['taille'] as String?),
      archetype: CreatureArchetype.fromString(map['archetype'] as String?),
      forVal: (map['for_val'] as int?) ?? 0,
      agiVal: (map['agi_val'] as int?) ?? 0,
      conVal: (map['con_val'] as int?) ?? 0,
      intVal: (map['int_val'] as int?) ?? 0,
      perVal: (map['per_val'] as int?) ?? 0,
      chaVal: (map['cha_val'] as int?) ?? 0,
      volVal: (map['vol_val'] as int?) ?? 0,
      superiorStats: superiorStats,
      attacks: attacks,
      capacities: capacities,
    );
  }

  CharacterTemplate copyWith({
    int? id,
    String? name,
    bool? isAlly,
    int? baseInitiative,
    int? maxHp,
    int? def,
    String? vitesse,
    String? imageUrl,
    bool clearImageUrl = false,
    Object? nc = _sentinel,
    CreatureType? creatureType,
    CreatureTaille? taille,
    CreatureArchetype? archetype,
    int? forVal,
    int? agiVal,
    int? conVal,
    int? intVal,
    int? perVal,
    int? chaVal,
    int? volVal,
    List<TemplateAttack>? attacks,
    List<TemplateCapacity>? capacities,
    Set<String>? superiorStats,
  }) =>
      CharacterTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        isAlly: isAlly ?? this.isAlly,
        baseInitiative: baseInitiative ?? this.baseInitiative,
        maxHp: maxHp ?? this.maxHp,
        def: def ?? this.def,
        vitesse: vitesse ?? this.vitesse,
        imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
        nc: nc == _sentinel ? this.nc : nc as int?,
        creatureType: creatureType ?? this.creatureType,
        taille: taille ?? this.taille,
        archetype: archetype ?? this.archetype,
        forVal: forVal ?? this.forVal,
        agiVal: agiVal ?? this.agiVal,
        conVal: conVal ?? this.conVal,
        intVal: intVal ?? this.intVal,
        perVal: perVal ?? this.perVal,
        chaVal: chaVal ?? this.chaVal,
        volVal: volVal ?? this.volVal,
        superiorStats: superiorStats ?? this.superiorStats,
        attacks: attacks ?? this.attacks,
        capacities: capacities ?? this.capacities,
      );
}

const _sentinel = Object();
