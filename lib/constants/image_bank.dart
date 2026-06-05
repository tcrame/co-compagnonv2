class ImageBankEntry {
  final String name;
  final String url;
  final String category;

  const ImageBankEntry({
    required this.name,
    required this.url,
    required this.category,
  });
}

const String _b = 'https://game-icons.net/icons/ffffff/transparent/1x1';

const List<ImageBankEntry> imageBank = [
  // ── Aventuriers ──────────────────────────────────────────────────────
  ImageBankEntry(name: 'Guerrier',    category: 'Aventuriers', url: '$_b/lorc/croc-sword.svg'), //
  ImageBankEntry(name: 'Barbare',     category: 'Aventuriers', url: '$_b/delapouite/barbarian.svg'), //
  ImageBankEntry(name: 'Archer',      category: 'Aventuriers', url: '$_b/lorc/striking-arrows.svg'), //
  ImageBankEntry(name: 'Mage',        category: 'Aventuriers', url: '$_b/lorc/wizard-staff.svg'), //
  ImageBankEntry(name: 'Voleur',      category: 'Aventuriers', url: '$_b/lorc/cloak-dagger.svg'), //
  ImageBankEntry(name: 'Clerc',       category: 'Aventuriers', url: '$_b/lorc/holy-grail.svg'), //
  ImageBankEntry(name: 'Paladin',     category: 'Aventuriers', url: '$_b/lorc/magic-shield.svg'), //
  ImageBankEntry(name: 'Druide',      category: 'Aventuriers', url: '$_b/lorc/witch-flight.svg'), //
  ImageBankEntry(name: 'Barde',       category: 'Aventuriers', url: '$_b/lorc/double-face-mask.svg'), //
  ImageBankEntry(name: 'Espion',      category: 'Aventuriers', url: '$_b/lorc/rogue.svg'), //
  ImageBankEntry(name: 'Nain',        category: 'Aventuriers', url: '$_b/delapouite/dwarf-face.svg'), //
  ImageBankEntry(name: 'Archer (arc)',category: 'Aventuriers', url: '$_b/lorc/bowman.svg'), //
  ImageBankEntry(name: 'Archer (alt)',category: 'Aventuriers', url: '$_b/delapouite/archer.svg'), //
  ImageBankEntry(name: 'Ninja',       category: 'Aventuriers', url: '$_b/lorc/ninja-mask.svg'), //
  ImageBankEntry(name: 'Backstab',    category: 'Aventuriers', url: '$_b/lorc/backstab.svg'), //
  ImageBankEntry(name: 'Moine',       category: 'Aventuriers', url: '$_b/lorc/monk.svg'),
  ImageBankEntry(name: 'Nécromancien',category: 'Aventuriers', url: '$_b/lorc/necromancer.svg'),
  ImageBankEntry(name: 'Chevalier',   category: 'Aventuriers', url: '$_b/delapouite/knight-helmet.svg'),
  ImageBankEntry(name: 'Elfe',        category: 'Aventuriers', url: '$_b/delapouite/elf-ear.svg'),

  // ── Humanoïdes ───────────────────────────────────────────────────────
  ImageBankEntry(name: 'Gobelin',     category: 'Humanoïdes', url: '$_b/delapouite/goblin-head.svg'), //
  ImageBankEntry(name: 'Orque',       category: 'Humanoïdes', url: '$_b/delapouite/orc-head.svg'), //
  ImageBankEntry(name: 'Troll',       category: 'Humanoïdes', url: '$_b/skoll/troll.svg'), //
  ImageBankEntry(name: 'Ogre',        category: 'Humanoïdes', url: '$_b/delapouite/ogre.svg'), //
  ImageBankEntry(name: 'Minotaure',   category: 'Humanoïdes', url: '$_b/lorc/minotaur.svg'), //
  ImageBankEntry(name: 'Cyclope',     category: 'Humanoïdes', url: '$_b/lorc/cyclops.svg'), //
  ImageBankEntry(name: 'Démon',       category: 'Humanoïdes', url: '$_b/lorc/evil-minion.svg'), //
  ImageBankEntry(name: 'Imp',         category: 'Humanoïdes', url: '$_b/lorc/imp.svg'), //
  ImageBankEntry(name: 'Djinn',       category: 'Humanoïdes', url: '$_b/delapouite/djinn.svg'), //
  ImageBankEntry(name: 'Sirène',      category: 'Humanoïdes', url: '$_b/delapouite/mermaid.svg'), //
  ImageBankEntry(name: 'Gnoll',       category: 'Humanoïdes', url: '$_b/delapouite/gnoll.svg'),
  ImageBankEntry(name: 'Lizardman',   category: 'Humanoïdes', url: '$_b/delapouite/lizardman.svg'),
  ImageBankEntry(name: 'Bandit',      category: 'Humanoïdes', url: '$_b/delapouite/robber-mask.svg'),
  ImageBankEntry(name: 'Sorcier',     category: 'Humanoïdes', url: '$_b/lorc/warlock-hood.svg'),
  ImageBankEntry(name: 'Cultiste',    category: 'Humanoïdes', url: '$_b/lorc/cultist.svg'),
  ImageBankEntry(name: 'Bourreau',    category: 'Humanoïdes', url: '$_b/delapouite/executioner-hood.svg'),

  // ── Morts-vivants ────────────────────────────────────────────────────
  ImageBankEntry(name: 'Squelette',   category: 'Morts-vivants', url: '$_b/skoll/skeleton.svg'), //
  ImageBankEntry(name: 'Fantôme',     category: 'Morts-vivants', url: '$_b/lorc/ghost.svg'), //
  ImageBankEntry(name: 'Zombie',      category: 'Morts-vivants', url: '$_b/delapouite/shambling-zombie.svg'), //
  ImageBankEntry(name: 'Vampire',     category: 'Morts-vivants', url: '$_b/delapouite/vampire-dracula.svg'), //
  ImageBankEntry(name: 'Loup-garou',  category: 'Morts-vivants', url: '$_b/lorc/werewolf.svg'), //
  ImageBankEntry(name: 'Mort-croisé', category: 'Morts-vivants', url: '$_b/lorc/skull-crossed-bones.svg'), //
  ImageBankEntry(name: 'Liche',       category: 'Morts-vivants', url: '$_b/lorc/lich.svg'),
  ImageBankEntry(name: 'Momie',       category: 'Morts-vivants', url: '$_b/delapouite/mummy-head.svg'),
  ImageBankEntry(name: 'Faucheuse',   category: 'Morts-vivants', url: '$_b/grim-reaper.svg'),

  // ── Créatures ────────────────────────────────────────────────────────
  ImageBankEntry(name: 'Dragon',      category: 'Créatures', url: '$_b/lorc/dragon-head.svg'), //
  ImageBankEntry(name: 'Hydre',       category: 'Créatures', url: '$_b/lorc/hydra.svg'), //
  ImageBankEntry(name: 'Serpent marin',category: 'Créatures', url: '$_b/lorc/sea-serpent.svg'), //
  ImageBankEntry(name: 'Loup',        category: 'Créatures', url: '$_b/lorc/wolf-head.svg'), //
  ImageBankEntry(name: 'Lion',        category: 'Créatures', url: '$_b/lorc/lion.svg'), //
  ImageBankEntry(name: 'Renard',      category: 'Créatures', url: '$_b/lorc/fox-head.svg'), //
  ImageBankEntry(name: 'Cheval',      category: 'Créatures', url: '$_b/lorc/horse-head.svg'), //
  ImageBankEntry(name: 'Ours',        category: 'Créatures', url: '$_b/delapouite/bear-head.svg'), //
  ImageBankEntry(name: 'Scorpion',    category: 'Créatures', url: '$_b/lorc/scorpion.svg'), //
  ImageBankEntry(name: 'Aigle',       category: 'Créatures', url: '$_b/lorc/eagle-emblem.svg'), //
  ImageBankEntry(name: 'Serpent',     category: 'Créatures', url: '$_b/lorc/snake.svg'), //
  ImageBankEntry(name: 'Griffes',     category: 'Créatures', url: '$_b/lorc/triple-claws.svg'), //
  ImageBankEntry(name: 'Araignée',    category: 'Créatures', url: '$_b/lorc/spider-alt.svg'),
  ImageBankEntry(name: 'Rat',         category: 'Créatures', url: '$_b/lorc/rat.svg'),
  ImageBankEntry(name: 'Gaulem',      category: 'Créatures', url: '$_b/lorc/golem.svg'),
  ImageBankEntry(name: 'Griffon',     category: 'Créatures', url: '$_b/lorc/griffin-shield.svg'),
  ImageBankEntry(name: 'Kraken',      category: 'Créatures', url: '$_b/lorc/kraken.svg'),
  ImageBankEntry(name: 'Chauve-souris', category: 'Créatures', url: '$_b/lorc/bat.svg'),
  ImageBankEntry(name: 'Phénix',      category: 'Créatures', url: '$_b/lorc/phoenix.svg'),
  ImageBankEntry(name: 'Pégase',      category: 'Créatures', url: '$_b/lorc/pegasus.svg'),
  ImageBankEntry(name: 'Insecte',     category: 'Créatures', url: '$_b/lorc/insect-jaws.svg'),
  ImageBankEntry(name: 'Crapaud',     category: 'Créatures', url: '$_b/delapouite/toad.svg'),
  ImageBankEntry(name: 'Dinosaure',   category: 'Créatures', url: '$_b/delapouite/dinosaur-bones.svg'),

  // ── Magie ────────────────────────────────────────────────────────────
  ImageBankEntry(name: 'Magie',       category: 'Magie', url: '$_b/lorc/magic-swirl.svg'), //
  ImageBankEntry(name: 'Cristal',     category: 'Magie', url: '$_b/lorc/crystal-ball.svg'), //
  ImageBankEntry(name: 'Portail',     category: 'Magie', url: '$_b/lorc/magic-portal.svg'), //
  ImageBankEntry(name: 'Vortex',      category: 'Magie', url: '$_b/lorc/vortex.svg'), //
  ImageBankEntry(name: 'Feu',         category: 'Magie', url: '$_b/lorc/fire-ring.svg'), //
  ImageBankEntry(name: 'Bombe feu',   category: 'Magie', url: '$_b/lorc/fire-bomb.svg'), //
  ImageBankEntry(name: 'Flèche feu',  category: 'Magie', url: '$_b/lorc/flaming-arrow.svg'), //
  ImageBankEntry(name: 'Glace',       category: 'Magie', url: '$_b/lorc/ice-bomb.svg'), //
  ImageBankEntry(name: 'Foudre',      category: 'Magie', url: '$_b/lorc/lightning-storm.svg'), //
  ImageBankEntry(name: 'Poison',      category: 'Magie', url: '$_b/lorc/poison-gas.svg'), //
  ImageBankEntry(name: 'Tornade',     category: 'Magie', url: '$_b/lorc/tornado.svg'), //
  ImageBankEntry(name: 'Aura',        category: 'Magie', url: '$_b/lorc/aura.svg'), //
  ImageBankEntry(name: 'Ange',        category: 'Magie', url: '$_b/lorc/angel-wings.svg'), //
  ImageBankEntry(name: 'Fée',         category: 'Magie', url: '$_b/lorc/fairy.svg'), //
  ImageBankEntry(name: 'Livre',       category: 'Magie', url: '$_b/lorc/open-book.svg'), //
  ImageBankEntry(name: 'Grimoire',    category: 'Magie', url: '$_b/lorc/book-cover.svg'), //
  ImageBankEntry(name: 'Main magique',category: 'Magie', url: '$_b/lorc/magic-palm.svg'), //
  ImageBankEntry(name: 'Potion',      category: 'Magie', url: '$_b/lorc/potion-ball.svg'), //
  ImageBankEntry(name: 'Télépathie',  category: 'Magie', url: '$_b/lorc/telepathy.svg'),
  ImageBankEntry(name: 'Résurrection',category: 'Magie', url: '$_b/lorc/resurrection.svg'),
  ImageBankEntry(name: 'Malédiction', category: 'Magie', url: '$_b/lorc/anarchy.svg'),

  // ── Armes & Équipement ───────────────────────────────────────────────
  ImageBankEntry(name: 'Épée croisée',category: 'Armes', url: '$_b/lorc/crossed-swords.svg'), //
  ImageBankEntry(name: 'Épée large',  category: 'Armes', url: '$_b/lorc/broadsword.svg'), //
  ImageBankEntry(name: 'Épée pelle',  category: 'Armes', url: '$_b/lorc/sword-spade.svg'), //
  ImageBankEntry(name: 'Hache',       category: 'Armes', url: '$_b/lorc/battle-axe.svg'), //
  ImageBankEntry(name: 'Hache guerre',category: 'Armes', url: '$_b/delapouite/war-axe.svg'), //
  ImageBankEntry(name: 'Hallebarde',  category: 'Armes', url: '$_b/lorc/halberd.svg'), //
  ImageBankEntry(name: 'Trident',     category: 'Armes', url: '$_b/lorc/trident.svg'), //
  ImageBankEntry(name: 'Trident feu', category: 'Armes', url: '$_b/lorc/flaming-trident.svg'), //
  ImageBankEntry(name: 'Masse',       category: 'Armes', url: '$_b/lorc/mace-head.svg'), //
  ImageBankEntry(name: 'Dague',       category: 'Armes', url: '$_b/lorc/broad-dagger.svg'), //
  ImageBankEntry(name: 'Flèches',     category: 'Armes', url: '$_b/lorc/arrow-flights.svg'), //
  ImageBankEntry(name: 'Bouclier',    category: 'Armes', url: '$_b/lorc/shield-reflect.svg'), //
  ImageBankEntry(name: 'Bouclier brisé', category: 'Armes', url: '$_b/lorc/broken-shield.svg'), //
  ImageBankEntry(name: 'Armure',      category: 'Armes', url: '$_b/lorc/spiked-armor.svg'), //
  ImageBankEntry(name: 'Bijou',       category: 'Armes', url: '$_b/lorc/gem-pendant.svg'), //
  ImageBankEntry(name: 'Arbalète',    category: 'Armes', url: '$_b/lorc/crossbow.svg'),
  ImageBankEntry(name: 'Bâton combat', category: 'Armes', url: '$_b/delapouite/quarterstaff.svg'),
  ImageBankEntry(name: 'Marteau',     category: 'Armes', url: '$_b/lorc/warhammer.svg'),
  ImageBankEntry(name: 'Fronde',      category: 'Armes', url: '$_b/whiplash.svg'),

  // ── États & Statuts (Nouveau !) ─────────────────────────────────────
  ImageBankEntry(name: 'Étourdi',     category: 'États', url: '$_b/lorc/daze.svg'),
  ImageBankEntry(name: 'Empoisonné',  category: 'États', url: '$_b/lorc/skull-mask.svg'),
  ImageBankEntry(name: 'Enflammé',    category: 'États', url: '$_b/lorc/lit-candle.svg'),
  ImageBankEntry(name: 'Gelé',        category: 'États', url: '$_b/lorc/frozen-orb.svg'),
  ImageBankEntry(name: 'Endormi',     category: 'États', url: '$_b/lorc/sleepy.svg'),
  ImageBankEntry(name: 'Invisible',   category: 'États', url: '$_b/lorc/ninja-head.svg'),
  ImageBankEntry(name: 'Effrayé',     category: 'États', url: '$_b/lorc/screaming.svg'),
  ImageBankEntry(name: 'Aveuglé',     category: 'États', url: '$_b/lorc/blindfold.svg'),
  ImageBankEntry(name: 'Béni',        category: 'États', url: '$_b/delapouite/bless.svg'),
  ImageBankEntry(name: 'Enragé',      category: 'États', url: '$_b/lorc/enrage.svg'),
  ImageBankEntry(name: 'Lévitation',  category: 'États', url: '$_b/lorc/levitation.svg'),
  ImageBankEntry(name: 'Saignement',  category: 'États', url: '$_b/lorc/dripping-blade.svg'),

  // ── Divers ───────────────────────────────────────────────────────────
  ImageBankEntry(name: 'Héros',       category: 'Divers', url: '$_b/lorc/crowned-heart.svg'), //
  ImageBankEntry(name: 'Citoyen',     category: 'Divers', url: '$_b/delapouite/person.svg'), //
  ImageBankEntry(name: 'Groupe',      category: 'Divers', url: '$_b/lorc/dark-squad.svg'), //
  ImageBankEntry(name: 'Château',     category: 'Divers', url: '$_b/lorc/castle.svg'), //
  ImageBankEntry(name: 'Feu de camp', category: 'Divers', url: '$_b/lorc/campfire.svg'), //
  ImageBankEntry(name: 'Sprint',      category: 'Divers', url: '$_b/lorc/sprint.svg'), //
  ImageBankEntry(name: 'Courir',      category: 'Divers', url: '$_b/lorc/run.svg'), //
  ImageBankEntry(name: 'Blessure',    category: 'Divers', url: '$_b/lorc/bleeding-wound.svg'), //
  ImageBankEntry(name: 'Coup',        category: 'Divers', url: '$_b/lorc/sword-wound.svg'), //
  ImageBankEntry(name: 'Tourbillon',  category: 'Divers', url: '$_b/lorc/swirl-string.svg'), //
  ImageBankEntry(name: 'Métamorphe',  category: 'Divers', url: '$_b/lorc/body-swapping.svg'), //
  ImageBankEntry(name: 'Trésor',      category: 'Divers', url: '$_b/lorc/chest.svg'),
  ImageBankEntry(name: 'Sacoche',     category: 'Divers', url: '$_b/lorc/knapsack.svg'),
  ImageBankEntry(name: 'Clé',         category: 'Divers', url: '$_b/lorc/old-key.svg'),
  ImageBankEntry(name: 'Pièces',      category: 'Divers', url: '$_b/lorc/coins.svg'),
  ImageBankEntry(name: 'Piège',       category: 'Divers', url: '$_b/lorc/bear-trap.svg'),
  ImageBankEntry(name: 'Potion Vie',  category: 'Divers', url: '$_b/lorc/health-potion.svg'),
  ImageBankEntry(name: 'Potion Mana', category: 'Divers', url: '$_b/lorc/mana-potion.svg'),
  ImageBankEntry(name: 'Parchemin',   category: 'Divers', url: '$_b/lorc/scroll-unfurled.svg'),
];

List<String> get imageBankCategories =>
    imageBank.map((e) => e.category).toSet().toList(); //

List<ImageBankEntry> imageBankForCategory(String category) =>
    imageBank.where((e) => e.category == category).toList(); //