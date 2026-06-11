import 'voies_data.dart';

// ── AVENTURIERS ──────────────────────────────────────────────────────────────

const _voie_archer_arcanique = VoieCatalogue(
  id: 'prestige_archer-arcanique',
  nom: 'Voie de l\'Archer Arcanique',
  profil: 'Aventuriers',
  famille: 'Voies de prestige d\'aventurier',
  description: 'La magie mystérieuse et terrible de cette voie de prestige fait de votre archer ou de votre arbalétrier un chasseur implacable dont les traits deviennent mortels et impossibles à esquiver. Les capacités issues de cette voie peuvent être déclinées pour un arc ou pour une arbalète.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Flèche magique', description: 'Le personnage enchante ses flèches. S\'il obtient un résultat de 1 sur son dé de DM, il remplace ce résultat par le maximum du dé (exemple, 1 sur le d8 devient 8). Cet effet ne s\'applique pas aux dés bonus. Les DM de ses flèches sont considérés comme magiques.'),
    CapaciteCatalogue(rang: 5, nom: 'Flèche intangible', type: 'L', description: 'Le personnage enchante sa flèche pour lui permettre de passer au travers des obstacles physiques et des protections. Le joueur réalise un test d\'attaque normal, mais remplace la DEF par 10 + AGI de la cible pour fixer sa difficulté. De surcroît, il ignore toutes les pénalités de couverture. S\'il sait précisément où se situe sa cible, il peut même tirer à travers un mur ou une porte.'),
    CapaciteCatalogue(rang: 6, nom: 'Flèche chercheuse', type: 'L', description: 'Une fois par jour, l\'archer arcanique peut enchanter une flèche afin qu\'elle trouve sa cible de façon infaillible. Pour utiliser ce pouvoir, l\'archer arcanique doit avoir blessé ou vu directement la créature ciblée moins de 10 rounds (1 min) plus tôt. Il tire ensuite sa flèche en l\'air et celle-ci voyage aussi loin que nécessaire (y compris à travers les plans) pour trouver sa cible. L\'archer arcanique fait un test d\'attaque normal et obtient un bonus de +2d4° aux DM.'),
    CapaciteCatalogue(rang: 7, nom: 'Flèche élémentaire', type: 'L', description: 'Une fois par combat, le personnage enchante ses flèches et choisit une source de DM parmi poison, feu, froid, foudre et acide. Pendant tout le combat, il ajoute +1d4° aux DM de chacune des flèches qu\'il tire. Ce bonus aux DM ne peut pas se cumuler à un autre bonus magique élémentaire (arc de feu, sort élémentaire, etc.).'),
    CapaciteCatalogue(rang: 8, nom: 'Flèche tueuse', type: 'L', description: 'Le personnage fabrique et enchante une flèche particulière pour un ennemi unique dont il possède une relique (morceau de peau, griffe, poils, etc.). Il lui faut une journée complète pour créer la flèche et il ne peut en posséder plus d\'une à un moment donné (ni pour la même cible ni pour une autre). Lorsqu\'il utilise sa flèche contre l\'ennemi désigné, il touche automatiquement. Si la cible est d\'un niveau inférieur au sien, elle est immédiatement réduite à 0 PV, sinon elle a droit à un test de CON difficulté [10 + rang]. En cas de réussite, la flèche est tout de même un critique automatique.'),
  ],
);

const _voie_casse_cou = VoieCatalogue(
  id: 'prestige_casse-cou',
  nom: 'Voie du Casse-Cou',
  profil: 'Aventuriers',
  famille: 'Voies de prestige d\'aventurier',
  description: 'Avec cette voie, votre personnage sera toujours partant pour tenter les actions les plus risquées !',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Au pied du mur', description: 'Lorsque le personnage possède un nombre de PV inférieur ou égal à son niveau, il gagne un dé bonus à tous ses tests (attaque, caractéristique, etc.).'),
    CapaciteCatalogue(rang: 5, nom: 'Mouche du coche', description: 'Le personnage est toujours en mouvement, il gagne +1 en DEF, puis +1 supplémentaire au rang 7. De plus, s\'il sacrifie une action de mouvement, il gagne +2 en DEF supplémentaire jusqu\'à son prochain tour.'),
    CapaciteCatalogue(rang: 6, nom: 'L\'amour du risque', description: 'Rien de tel qu\'une question de vie ou de mort pour vous motiver ! Lorsqu\'il réalise une action dans un lieu dangereux (par exemple, au bord d\'un précipice ou d\'un lac de lave), le personnage gagne un dé bonus à tous ses tests (attaque, caractéristique, etc.). Ce bonus s\'applique également aux tests réalisés pour résister à la peur (permanent).'),
    CapaciteCatalogue(rang: 7, nom: 'Poussée d\'adrénaline', description: 'Une fois par round, en dépensant 1d4 PV, le personnage gagne une action de mouvement supplémentaire à son tour.'),
    CapaciteCatalogue(rang: 8, nom: 'Attaque kamikaze', type: 'L', description: 'Le personnage saute sur sa cible et l\'agrippe pour la larder de coups au corps à corps. La cible doit être de taille supérieure à la sienne. Le personnage réalise un test opposé d\'AGI contre la créature. En cas d\'échec, le personnage se retrouve renversé. En cas de réussite, il est perché sur la créature ce qui lui offre les bonus suivants selon la taille de la cible : Grande (+2 Att et DEF, +1d4° DM), Énorme (+3 Att et DEF, +1d4° DM), Colossale (+4 Att et DEF, +1d4° DM). Pour se débarrasser de lui, la créature doit utiliser une action d\'attaque et l\'emporter lors d\'un test opposé d\'AGI.'),
  ],
);

const _voie_chasseur_de_prime = VoieCatalogue(
  id: 'prestige_chasseur-de-prime',
  nom: 'Voie du Chasseur de Prime',
  profil: 'Aventuriers',
  famille: 'Voies de prestige d\'aventurier',
  description: 'Le chasseur de prime est un traqueur implacable et nul ne peut l\'arrêter lorsqu\'il a choisi sa cible.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Marque du chasseur', type: 'L', description: 'Le personnage désigne une proie soit en la voyant, soit en étant mandaté pour la traquer. Il obtient un bonus de +5 à tous les tests de compétence qu\'il réalise pour la retrouver (pistage, renseignement, discrétion, etc.) et +1d4° aux DM contre elle. Le personnage doit attendre d\'avoir terminé une récupération complète avant de changer de proie. Il ne peut marquer plus d\'une proie à la fois.'),
    CapaciteCatalogue(rang: 5, nom: 'Assommer', type: 'L', description: 'Sur un test d\'attaque au contact réussi avec une arme contondante ou le pommeau d\'une épée (dague, etc.), si la cible est de niveau (ou NC) inférieur au niveau du personnage et qu\'elle porte la marque du chasseur, elle est assommée pour 1d4° min. Sinon, elle est étourdie pour un round. La cible ne peut subir cet effet qu\'une seule fois par combat.'),
    CapaciteCatalogue(rang: 6, nom: 'Traqueur infatigable', description: 'Tant que vous traquez une créature que vous avez marquée, vous divisez par deux le temps nécessaire à une récupération (rapide ou complète). De plus, chaque jour durant lequel vous traquez la même proie, vous gagnez un bonus cumulatif de +1 en attaque et aux DM sur la première attaque que vous lui portez, pour un maximum égal à votre rang.'),
    CapaciteCatalogue(rang: 7, nom: 'Attaque invalidante', type: 'L', description: 'Vous portez une attaque qui a pour but de saper la volonté et les forces de votre adversaire. En cas de réussite, en plus des DM habituels, l\'attaque inflige un malus cumulatif de -1 à tous les tests et aux DM infligés par la cible pour le reste du combat, jusqu\'à un cumul maximal de -3.'),
    CapaciteCatalogue(rang: 8, nom: 'Instinct du traqueur', type: 'L', description: 'En se concentrant 1 min, le chasseur de prime peut déterminer dans quelle direction approximative se trouve la cible de sa marque du chasseur. Si la créature ciblée s\'approche à moins de 50 m, le personnage en est averti par un frisson dans le dos ou les poils de la nuque qui se hérissent…'),
  ],
);

const _voie_duelliste = VoieCatalogue(
  id: 'prestige_duelliste',
  nom: 'Voie du Duelliste',
  profil: 'Aventuriers',
  famille: 'Voies de prestige d\'aventurier',
  description: 'Jetez votre gant, provoquez en duel ce fat qui a manqué de courtoisie, montrez votre valeur face au comte de Perthuis… Les adeptes du bel art de l\'escrime aiment à se défier et à se mesurer à leur adversaire seul à seul.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Vive attaque', description: 'Lorsqu\'il utilise une dague, une épée courte, longue ou une rapière sur les attaques de sa main principale (ou encore sur une vivelame tenue à deux mains), le personnage peut ajouter son AGI en attaque au contact ou aux DM (au choix, mais pas les deux en même temps, sauf s\'il dispose d\'une autre capacité qui lui permet, par exemple attaque en finesse) au lieu de sa FOR.'),
    CapaciteCatalogue(rang: 5, nom: 'Défi', type: 'L', description: 'Une fois par combat, le personnage peut défier une cible humanoïde de son choix (portée 20 m). Il obtient +1d6 aux DM de chaque attaque au contact pour le reste du combat contre cette cible. S\'il attaque une autre cible, le défi prend fin.'),
    CapaciteCatalogue(rang: 6, nom: 'Juste toi et moi', description: 'À chaque round durant lequel il attaque la cible qu\'il a défiée, le personnage obtient un bonus de +2 en DEF contre toutes les attaques provenant d\'autres adversaires.'),
    CapaciteCatalogue(rang: 7, nom: 'Duel mental', description: 'Au début de son tour, le personnage peut faire un test opposé d\'INT contre un adversaire qu\'il a défié. S\'il l\'emporte, il obtient un dé bonus sur une attaque de son choix contre cet adversaire d\'ici la fin du round (à annoncer avant de lancer le dé). Si l\'adversaire l\'emporte d\'au moins 10 points, c\'est lui qui bénéficie d\'un dé bonus en attaque.'),
    CapaciteCatalogue(rang: 8, nom: 'Botte mortelle', description: 'Chaque fois que le personnage réussit une attaque contre l\'adversaire qu\'il a défié, en plus des DM habituels, il gagne 1 point de préparation sur cette créature (ceci est une action gratuite). Au moment de son choix, il peut utiliser une action limitée pour exécuter sa botte mortelle. S\'il réussit son attaque, il ajoute +1d4° DM par point de préparation. Il ne peut tenter qu\'une seule botte mortelle par combat, les points sont dépensés que l\'attaque soit un succès ou un échec.'),
  ],
);

const _voie_espion = VoieCatalogue(
  id: 'prestige_espion',
  nom: 'Voie de l\'Espion',
  profil: 'Aventuriers',
  famille: 'Voies de prestige d\'aventurier',
  description: 'Tout savoir, écouter aux portes ou se faufiler dans une foule, le métier d\'espion est riche en moments de tension et en jeux de pouvoir…',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Secrets d\'alcôves', description: 'Le personnage obtient un bonus de +5 pour tous les tests visant à trouver ou obtenir des informations secrètes ou sensibles, et +5 à tous les tests de perception auditive (PER). De plus, il est capable de suivre une conversation en lisant sur les lèvres en réussissant un test de PER dont la difficulté est égale à la distance entre sa cible et lui en mètres. Il obtient un bonus égal à son rang pour ce test.'),
    CapaciteCatalogue(rang: 5, nom: 'À la garde', description: 'Le personnage développe un sixième sens qui lui assure un coup d\'avance sur les gardes et autres forces adverses. Le MJ doit prévenir le joueur 1d4 rounds complets avant que des PNJ n\'interviennent sur le lieu où il opère. Il doit aussi indiquer la direction d\'où provient la menace. Cette capacité n\'est d\'aucune utilité contre une embuscade (des adversaires cachés et préparés à l\'arrivée des PJ).'),
    CapaciteCatalogue(rang: 6, nom: 'Mémoire eidétique', description: 'Le personnage a une parfaite mémoire de tout ce qu\'il a vu et entendu. Si le joueur le demande, le MJ doit lui rappeler tous les détails relatifs à un lieu qu\'il a visité ou à une conversation qu\'il a entendue. De plus, le personnage gagne un bonus de +5 à tous ses tests de connaissance (INT) et de recherche d\'indice basé sur l\'INT.'),
    CapaciteCatalogue(rang: 7, nom: 'Caméléon', description: 'Le personnage peut repérer des lieux, suivre des gens, infiltrer des endroits réservés (avec le costume adapté) sans aucun jet de dé tant qu\'il n\'entreprend aucune action qui pourrait sérieusement attirer l\'attention sur lui. Au prix d\'une action de mouvement et en réussissant un test de CHA difficulté 10, il disparaît dans une foule et échappe à d\'éventuels poursuivants. Autrement, s\'il attaque au round suivant, il obtient un dé bonus et peut effectuer une Attaque sournoise s\'il dispose de cette capacité. La difficulté du test de CHA initial peut être modulée selon la densité de la foule.'),
    CapaciteCatalogue(rang: 8, nom: 'Réseau', description: 'Grâce à son réseau de connaissances ou par l\'intermédiaire d\'autres espions, le personnage peut obtenir de nombreux avantages. Un test réussi de CHA difficulté 10 lui suffit pour obtenir une entrevue avec n\'importe quel personnage puissant à tout moment. Une fois par aventure, cela lui permet d\'obtenir un service, par exemple une lettre de recommandation, un renseignement réservé à l\'élite, des billets pour un bal privé ou même une escorte armée pour l\'aider à se rendre dans un endroit dangereux.'),
  ],
);

const _voie_flibustier = VoieCatalogue(
  id: 'prestige_flibustier',
  nom: 'Voie du Flibustier',
  profil: 'Aventuriers',
  famille: 'Voies de prestige d\'aventurier',
  description: 'Pirate, corsaire ou bandit des mers, le flibustier est un combattant impitoyable qui sait faire parler la poudre autant que le sabre.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Pied marin', description: 'Le personnage gagne un bonus de +5 sur tous les tests d\'AGI réalisés sur un bateau ou sur d\'autres supports mobiles (ce qui comprend les chariots, les cordages, les ponts de corde). Il ajoute son rang à tous les tests relatifs à la natation et à la navigation.'),
    CapaciteCatalogue(rang: 5, nom: 'Coup de crosse', type: 'G', description: 'Une fois par round, le personnage peut, au moment de son choix, accomplir une attaque au contact gratuite avec la crosse d\'une pétoire qu\'il tient en main. Il subit un dé malus pour le test d\'attaque et inflige [1d4°+FOR] DM. Si ce n\'est pas déjà le cas, il acquiert la maîtrise des armes à poudre.'),
    CapaciteCatalogue(rang: 6, nom: 'À l\'abordage', description: 'Le personnage sait s\'élancer vers ses ennemis et mettre du cœur dans sa première attaque au contact lors d\'un combat. Cette première attaque bénéficie d\'un dé bonus en attaque et de +1d4° aux DM. Il obtient aussi cet effet à chaque fois qu\'il peut se précipiter sur un adversaire depuis un contre-haut (balcon, lustre, table, etc.).'),
    CapaciteCatalogue(rang: 7, nom: 'Sabre au poing', type: 'A', description: 'Au prix d\'une action d\'attaque, le personnage peut tirer avec une arme à poudre d\'une main (même à bout portant sans malus) et porter une attaque de contact avec une seconde arme (tenue dans son autre main), sans pénalités.'),
    CapaciteCatalogue(rang: 8, nom: 'Pas de quartier', type: 'G', description: 'Pour le flibustier, il s\'agit de vaincre ou mourir. Sa férocité est légendaire : il peut tenter une action d\'attaque gratuite contre toute créature à son contact qui tente de s\'éloigner de lui. Pour cette attaque, il obtient un dé bonus en attaque et +1d4° aux DM. Il obtient les mêmes bonus à toutes ses attaques lorsqu\'il lui reste moins de [niveau] PV.'),
  ],
);

const _voie_heros = VoieCatalogue(
  id: 'prestige_heros',
  nom: 'Voie du Héros',
  profil: 'Aventuriers',
  famille: 'Voies de prestige d\'aventurier',
  description: 'Cette voie est destinée aux héros, aux vrais, ceux qui ne reculent jamais et défient la mort avec un sourire provocateur !',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Destin héroïque', description: 'Le personnage gagne 1 PC. Il gagne un PC supplémentaire au rang 6 et un dernier au rang 8. De plus, une fois par combat, vous pouvez donner un bonus de +1d4° à un compagnon en vue sur un test de votre choix.'),
    CapaciteCatalogue(rang: 5, nom: 'Homme/femme de la situation', description: 'Une fois par aventure, vous pouvez demander au MJ de vous donner une idée lumineuse ou de vous indiquer la moins mauvaise solution pour rattraper une situation ou limiter les dégâts.'),
    CapaciteCatalogue(rang: 6, nom: 'Héros célèbre', description: 'Votre réputation de héros vous précède et vous ouvre bien des portes. Vous obtenez un dé bonus à tous vos tests d\'interaction sociale et on vous accueille partout à bras ouverts. Choisissez entre « héros du peuple » et « héros du royaume » : vous gagnez ces avantages seulement dans le milieu correspondant. À partir du rang 8, vous êtes à la fois le héros du peuple et celui du royaume !'),
    CapaciteCatalogue(rang: 7, nom: 'Ténacité', description: 'Lorsque vous ratez un test d\'attaque contre une créature, vous bénéficiez d\'un dé bonus à votre prochain essai si vous utilisez la même action (même capacité). Ce bonus persiste tant que vous ratez, mais disparaît dès que l\'attaque est réussie.'),
    CapaciteCatalogue(rang: 8, nom: 'Meneur d\'hommes', type: 'L', description: 'Une fois par jour, le personnage peut haranguer ses compagnons, les motiver et les conseiller pour attaquer un adversaire particulier. Tous ses alliés bénéficient d\'un dé bonus une fois par round pour toute la scène à venir (un combat, un bal ou une réception, une scène de meurtre à étudier, etc.).'),
  ],
);

const _voie_maitre_poisons = VoieCatalogue(
  id: 'prestige_maitre-poisons',
  nom: 'Voie du Maître des Poisons',
  profil: 'Aventuriers',
  famille: 'Voies de prestige d\'aventurier',
  description: 'Le poison est l\'arme des lâches dit-on parfois. Il faut être un âne habillé de métal pour se persuader de telles sornettes ; pour vous, c\'est une arme efficace réservée à une élite d\'individus intelligents et sans scrupules…',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Connaissance du poison', description: 'Le personnage peut effectuer un test d\'INT difficulté 10 pour reconnaître, identifier ou détecter un poison. Il n\'a plus besoin de test d\'INT pour réussir à appliquer un poison sur une arme.'),
    CapaciteCatalogue(rang: 5, nom: 'Poison rapide', description: 'Le personnage sait fabriquer du poison « rapide » en petite quantité. Avant chaque combat, ses armes (trois au maximum) sont enduites de ce poison. La première attaque réussie provoque 3d4° DM supplémentaires. Si la victime réussit un test de CON difficulté [10 + INT], elle ne subit que la moitié des DM.'),
    CapaciteCatalogue(rang: 6, nom: 'Poison affaiblissant', description: 'Le personnage peut remplacer le poison rapide par un poison affaiblissant, les effets ne sont appliqués que sur la première attaque réussie avec cette arme. Si la victime rate un test de CON difficulté 12, elle est affaiblie pour le reste du combat.'),
    CapaciteCatalogue(rang: 7, nom: 'Résistance au poison', description: 'À force de manipuler les poisons, le personnage a développé des immunités. Lorsqu\'il est empoisonné, faites un test de CON difficulté 10. En cas de succès, il ne subit aucun effet ; s\'il rate, il subit la moitié des DM.'),
    CapaciteCatalogue(rang: 8, nom: 'Poisons virulents', description: 'Le personnage sait fabriquer en petites quantités les poisons « lent » et « mortel », il peut en utiliser [1 + INT] doses par jour (cumul des deux sortes de poisons). La difficulté de résistance à ces poisons est de [12 + INT].'),
  ],
);

const _voie_ombres = VoieCatalogue(
  id: 'prestige_ombres',
  nom: 'Voie des Ombres',
  profil: 'Aventuriers',
  famille: 'Voies de prestige d\'aventurier',
  description: 'Le maître des ombres est un adversaire redoutable, capable de s\'infiltrer n\'importe où, de surgir en un instant et de disparaître tout aussi vite. Il est de l\'étoffe dont on fait les histoires pour faire peur aux enfants.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Vision des ombres', description: 'Le personnage tisse un lien avec le demi-plan des ombres. Ses yeux deviennent violets et, désormais, il voit dans le noir même total comme s\'il s\'agissait de pénombre. Lorsqu\'il est dans la pénombre (mais pas dans le noir), il obtient un bonus de +5 à ses tests de discrétion et de PER basés sur la vue.'),
    CapaciteCatalogue(rang: 5, nom: 'Caméléon', type: 'L', description: 'Tant que le personnage reste immobile, il est totalement invisible.'),
    CapaciteCatalogue(rang: 6, nom: 'Ombre mouvante', type: 'M', description: 'Une fois par combat, le personnage peut disparaître dans les ombres et ne réapparaître qu\'au début de son prochain tour. Aucun adversaire ne peut l\'attaquer pendant qu\'il a disparu dans les ombres, mais il peut subir des DM de zone. Le personnage réapparaît à une distance maximale de 20 m de sa position initiale. S\'il attaque, il obtient un dé bonus et peut effectuer une Attaque sournoise s\'il dispose de cette capacité. (Si le personnage connaît déjà la capacité Disparition grâce à la voie de l\'assassin du voleur, il peut désormais l\'utiliser aussi souvent qu\'il le veut).'),
    CapaciteCatalogue(rang: 7, nom: 'Cape d\'ombre', type: 'L', description: 'Une fois par jour, le personnage s\'enveloppe d\'ombre pendant CHA minutes. Il gagne un dé bonus à tous les tests de discrétion et impose un dé malus à tous les tests d\'attaque à distance qui le prennent pour cible. S\'il tombe à 0 PV pendant la durée de la capacité, il peut choisir de disparaître dans son ombre et de réapparaître à 1d6 km dans la direction de son choix avec 1d4° PV, 1d6 minutes plus tard. (Si le personnage connaît déjà Manteau d\'ombre, il peut l\'utiliser une fois par combat).'),
    CapaciteCatalogue(rang: 8, nom: 'Passe-muraille', description: 'Désormais lorsqu\'il utilise la capacité Ombre mouvante, le personnage peut passer à travers un mur ou un obstacle. Il doit toujours se fondre dans une ombre et réapparaître dans une autre.'),
  ],
);

const _voie_pacte_feerique = VoieCatalogue(
  id: 'prestige_pacte-feerique',
  nom: 'Voie du Pacte Féérique',
  profil: 'Aventuriers',
  famille: 'Voies de prestige d\'aventurier',
  description: 'Vous avez toujours eu une affinité avec la nature, la forêt et les animaux. Vous avez passé un pacte avec les êtres de la forêt et juré de les protéger.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Amitié avec les animaux', type: 'L', description: 'Le personnage possède une affinité surnaturelle avec les animaux. Au prix d\'une action limitée, il peut faire un test opposé d\'attaque magique contre un animal ordinaire. S\'il l\'emporte, l\'animal est apaisé et il peut lui ordonner de partir. Si l\'animal possède un maître, le test d\'attaque magique doit être réalisé à la fois contre l\'animal et contre le maître. Cette capacité ne fonctionne pas contre les animaux magiques ou corrompus, mais elle affecte les animaux géants.'),
    CapaciteCatalogue(rang: 5, nom: 'Invisibilité', type: 'L', description: 'Le personnage apprend des fées la possibilité de laisser son image dans le royaume caché. Il se rend invisible pendant [1d6+CHA] minutes. Une fois qu\'il est invisible, personne ne peut plus détecter sa présence ou lui porter d\'attaque. Si le personnage attaque ou utilise une capacité limitée, il redevient visible. Le personnage doit terminer une récupération rapide avant de pouvoir à nouveau utiliser cette capacité.'),
    CapaciteCatalogue(rang: 6, nom: 'Compagnon féérique', description: 'Le personnage a adopté une fée, un farfadet ou un grig. S\'il est réduit à 0 PV, il disparaît dans le monde féérique et revient guéri au bout de 24 h. AGI +4*, CON +1, FOR -4, PER +2, CHA +2, VOL +2. DEF [12+rang], PV [Niveau x 2]. Un être féérique peut se rendre invisible (L).'),
    CapaciteCatalogue(rang: 7, nom: 'Pas brumeux', type: 'M', description: 'Une fois par round, le personnage peut utiliser une action de mouvement et sacrifier 1 PV pour faire un pas dans le monde féérique. Il en ressort à une distance de 20 m au maximum. Il peut franchir de cette façon n\'importe quel obstacle (même un mur de force), mais il doit obligatoirement voir l\'endroit où il va réapparaître.'),
    CapaciteCatalogue(rang: 8, nom: 'Pays des songes', type: 'L', description: 'Une fois par jour, en milieu naturel, le personnage franchit un portail étrange (un cercle de champignons, l\'entrée d\'une grotte, entre les racines d\'un arbre, etc.) et disparaît dans le monde féérique. Le portail disparaît à sa suite. Il en ressort 3d6 h plus tard au même endroit ou dans un rayon de 20 km avec ses PV à leur maximum.'),
  ],
);

const _voie_touche_a_tout = VoieCatalogue(
  id: 'prestige_touche-a-tout',
  nom: 'Voie du Touche à Tout',
  profil: 'Aventuriers',
  famille: 'Voies de prestige d\'aventurier',
  description: 'Destinée à celui qui recherche la polyvalence ultime et veut profiter d\'une liberté totale dans le choix de ses capacités.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Domaine de l\'aventure', description: 'Le personnage choisit une capacité de rang 1 ou 2 issue d\'une voie d\'aventurier.'),
    CapaciteCatalogue(rang: 5, nom: 'Domaine de la guerre', description: 'Le personnage choisit une capacité de rang 1 ou 2 issue d\'une voie de combattant.'),
    CapaciteCatalogue(rang: 6, nom: 'Domaine du mystique', description: 'Le personnage choisit une capacité de rang 1 ou 2 issue d\'une voie de mystique. S\'il s\'agit d\'un sort, il peut le lancer même si sa magie est égale à +0.'),
    CapaciteCatalogue(rang: 7, nom: 'Domaine de la magie', description: 'Le personnage choisit une capacité de rang 1 ou 2 issue d\'une voie de mage. S\'il s\'agit d\'un sort, il peut le lancer même si sa magie est égale à +0.'),
    CapaciteCatalogue(rang: 8, nom: 'Ultra polyvalent', description: 'Le personnage augmente la valeur de ses deux plus faibles caractéristiques de +1.'),
  ],
);

const _voie_tueur_gages = VoieCatalogue(
  id: 'prestige_tueur-gages',
  nom: 'Voie du Tueur à Gages',
  profil: 'Aventuriers',
  famille: 'Voies de prestige d\'aventurier',
  description: 'Une voie pour faire le sale boulot, tout simplement.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Faire taire', type: 'M', description: 'En réussissant un test d\'attaque au contact, le personnage porte une frappe sèche au larynx d\'un adversaire humanoïde : il lui inflige 1d4° DM et la cible est rendue muette. À la fin de son tour à chaque round suivant, elle peut faire un test de CON difficulté [10 + rang] pour retrouver l\'usage de la parole. Un lanceur de sort muet subit un dé malus à ses tests d\'attaque magique.'),
    CapaciteCatalogue(rang: 5, nom: 'Brise genou', type: 'M', description: 'En réussissant un test d\'attaque au contact, le personnage porte un coup puissant dans le genou d\'une créature humanoïde. Il inflige 1d4° DM et la cible est invalide pour le reste du combat. Si la cible est d\'un NC supérieur ou égal au rang atteint dans la voie, elle peut faire un test de CON difficulté [10 + rang] chaque round à la fin de son tour pour s\'en débarrasser.'),
    CapaciteCatalogue(rang: 6, nom: 'Ne me tourne pas le dos', type: 'G', description: 'Une fois par round, si une créature quitte le contact du personnage, le personnage peut lui porter une Attaque sournoise. S\'il ne dispose pas de cette capacité, il ajoute tout de même +1d4° aux DM s\'il réussit cette attaque.'),
    CapaciteCatalogue(rang: 7, nom: 'Égorger', type: 'A', description: 'Si le personnage réussit une attaque contre une créature humanoïde surprise dont le NC est inférieur à 4, elle meurt immédiatement. Si le personnage connaît l\'Attaque sournoise, le NC augmente de +1 par dé d\'attaque sournoise. Sinon cette attaque inflige des DM normaux.'),
    CapaciteCatalogue(rang: 8, nom: 'Un simple regard', type: 'G', description: 'S\'il réussit un test opposé d\'attaque magique contre une ou plusieurs cibles humanoïdes à 10 m, elles renoncent à l\'attaquer. En cas d\'échec, il ne peut plus tenter contre ces cibles durant ce combat. Obtient un dé bonus à toutes tentatives d\'intimidation/persuasion ensuite. Cesse s\'il attaque la cible.'),
  ],
);

// ── COMBATTANTS ──────────────────────────────────────────────────────────────

const _voie_arme_liee = VoieCatalogue(
  id: 'prestige_arme-liee',
  nom: 'Voie de l\'Arme Liée',
  profil: 'Combattants',
  famille: 'Voies de prestige de combattant',
  description: 'Certains héros tissent un lien particulier avec leur arme favorite. Cette compagne de tous les jours devient leur alliée la plus fidèle et un lien magique les unit progressivement. Le personnage choisit une arme et se lie avec l\'objet par un rituel informel qui dure 2d6 jours.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Fidèle', description: 'L\'arme est considérée comme magique et octroie au PJ un dé bonus en attaque une fois par combat. Si l\'arme est en vue et à moins de 10 m (ou sa portée dans le cas d\'une arme de lancer), il peut la faire revenir dans sa main en action gratuite. Si l\'arme est saisie par une autre créature, il doit emporter un test opposé de CHA contre la FOR de son adversaire pour la faire revenir dans sa main. Si elle n\'est pas en vue, il sait toujours dans quelle direction elle se trouve.'),
    CapaciteCatalogue(rang: 5, nom: 'Alliée loyale', description: 'Une fois par combat, lorsqu\'il obtient 1 au test d\'attaque avec son arme, le joueur peut le remplacer par la valeur 20.'),
    CapaciteCatalogue(rang: 6, nom: 'Arme dansante', type: 'M', description: 'Une fois par combat, le personnage peut demander à son arme de combattre pour lui. Elle attaque pendant [rang] rounds en utilisant la valeur d\'attaque magique du PJ et en infligeant ses DM de base (plus un éventuel bonus de magie si l\'arme est enchantée). S\'il sombre dans l\'inconscience, l\'arme continue à veiller sur lui et à attaquer tous les ennemis qui approchent de son corps, tant que la durée totale de la capacité n\'est pas atteinte. Ensuite elle devient inerte et tombe au sol.'),
    CapaciteCatalogue(rang: 7, nom: 'Aura élémentaire', type: 'A', description: 'Une fois par combat, le personnage imprègne son arme d\'une aura élémentaire pendant CON minutes. Cette aura lui offre un bonus de +1d4° aux DM qui prennent la forme de feu, d\'acide, de froid ou d\'électricité. L\'élément choisi reste toujours le même. Ce bonus aux DM ne peut pas se cumuler à un autre bonus magique élémentaire (arc de feu, sort élémentaire, etc.).'),
    CapaciteCatalogue(rang: 8, nom: 'Milles lames', type: 'L', description: 'Une fois par jour, le personnage fait couler son propre sang sur son arme : il sacrifie 2d4° PV et invoque les sœurs spirituelles de son arme. Pendant 5 rounds, tous les adversaires du personnage dans un rayon de 10 m autour de lui sont frappés par une arme translucide semblable à la sienne et subissent automatiquement 1d4° DM.'),
  ],
);

const _voie_armes_deux_mains = VoieCatalogue(
  id: 'prestige_armes-deux-mains',
  nom: 'Voie des Armes à Deux Mains',
  profil: 'Combattants',
  famille: 'Voies de prestige de combattant',
  description: 'Au même titre que d\'autres armes, une arme à deux mains permet au guerrier de développer un style de combat bien particulier afin d\'exploiter pleinement ses avantages : une allonge supérieure et une force d\'impact destructrice. Ne fonctionne pas avec les armes non létales ou à 1d6 DM.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Frappe massive', type: 'L', description: 'Le personnage fait une attaque au contact et inflige ses DM maximaux en cas de réussite (les dés bonus ne sont pas maximisés). De plus, la cible doit réussir un test opposé de FOR ou être renversée (rendement décroissant : la cible gagne +5 par nouvelle tentative durant le combat). Si la cible est immense, elle obtient un dé bonus au test de FOR.'),
    CapaciteCatalogue(rang: 5, nom: 'Gros monstre, grosse arme', description: 'Contre les créatures de taille grande et supérieure, les DM des armes à deux mains augmentent d\'une catégorie : d12 et 2d6 passent à 2d8, 1d8 et 1d10 passent à 1d12, 2d8 passent à 2d10.'),
    CapaciteCatalogue(rang: 6, nom: 'Tenir à distance', description: 'Lorsque le personnage tient une arme à deux mains, il gagne un bonus de +1 en DEF. Ce bonus passe à +2 au rang 8.'),
    CapaciteCatalogue(rang: 7, nom: 'Critique destructeur', description: 'Le personnage abaisse son seuil de critique avec toutes les armes à deux mains de 1 point. De plus, lorsqu\'il obtient un critique avec une arme à deux mains, le combattant obtient +2d4° aux DM en plus des effets du critique.'),
    CapaciteCatalogue(rang: 8, nom: 'Décapitation', description: 'Lorsque vous obtenez le résultat maximal sur un dé de DM d\'une attaque au contact (ex: 6 sur l\'un des d6 de l\'épée à deux mains), si la cible possède un NC inférieur ou égal à 5, elle est décapitée et morte. Si vous obtenez le max sur LES DEUX dés de DM, vous décapitez une cible d\'un NC inférieur à votre niveau. Une capacité maximisant les DM (comme Frappe massive) ne déclenche pas cet effet.'),
  ],
);

const _voie_chevalier_dragon = VoieCatalogue(
  id: 'prestige_chevalier-dragon',
  nom: 'Voie du Chevalier Dragon',
  profil: 'Cavalier',
  famille: 'Voies de prestige de combattant',
  description: 'Pour choisir cette voie, il faut avoir acquis la capacité Monture fantastique (rang 5 de la voie du cavalier) et choisi un drake au niveau 9.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Ordre du chevalier dragon', description: 'Le cavalier rejoint l\'ordre des chevaliers dragons. Lorsqu\'il porte les insignes de son ordre ou chevauche son drake, il gagne un bonus de +5 pour tous les tests de persuasion et d\'intimidation. Son drake obtient une réduction des DM contre le feu de 10.'),
    CapaciteCatalogue(rang: 5, nom: 'Résistance au feu', description: 'Le cavalier a appris à résister aux flammes. Il retranche 5 à tous les DM de feu subis (RD [feu] 5). Cette réduction passe à 10 une fois atteint le rang 7.'),
    CapaciteCatalogue(rang: 6, nom: 'Épée de feu', type: 'M', description: 'Le cavalier peut enflammer son épée pour [5 + CHA] rounds. Elle inflige dès lors +1d4° DM de feu.'),
    CapaciteCatalogue(rang: 7, nom: 'Monture puissante', description: 'Le drake atteint sa pleine maturité. DRAKE | AGI +0 | CON +6* | FOR +6 | PER +1 | INT -2 | CHA +0 | VOL +2 | DEF 22 | PV [10 + niveau × 6] | DM 2d4°+6.'),
    CapaciteCatalogue(rang: 8, nom: 'Souffle enflammé', type: 'A', description: 'Le drake est capable de cracher du feu au prix d\'une action d\'attaque une fois par combat. Cônes de 10 m de long sur 10 m de large : 8d4° DM de feu (ou moitié si test d\'AGI 12 réussi).'),
  ],
);

const _voie_colosse = VoieCatalogue(
  id: 'prestige_colosse',
  nom: 'Voie du Colosse',
  profil: 'Combattants',
  famille: 'Voies de prestige de combattant',
  description: 'Il est nécessaire d\'avoir au moins +3 en Force pour choisir cette voie.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Stature de géant', description: 'Le colosse est considéré comme faisant une taille de plus que sa taille réelle pour déterminer s\'il peut être affecté par les capacités spéciales des créatures (fauchage, agripper, etc.). De plus il inflige 1d6 DM à mains nues.'),
    CapaciteCatalogue(rang: 5, nom: 'Résistance colossale', description: 'Le colosse gagne immédiatement 5 PV supplémentaires, auxquels il ajoute sa CON.'),
    CapaciteCatalogue(rang: 6, nom: 'Force du titan', description: 'Le colosse augmente sa valeur de FOR de +1.'),
    CapaciteCatalogue(rang: 7, nom: 'Poigne de fer', description: 'Le colosse peut utiliser une arme à deux mains à une seule main (épée ou hache à deux mains). À deux mains, il peut utiliser une arme prévue pour une créature de taille grande qui inflige 2d8 DM au lieu de 2d6.'),
    CapaciteCatalogue(rang: 8, nom: 'Attaque monumentale', type: 'L', description: 'Une fois par combat, l\'attaque obtient un bonus de +5 pour toucher et un bonus aux DM de +1d4°/round de combat contre cette créature. Si la cible a un NC inférieur au niveau du colosse, elle est affaiblie pour 1 round pour chaque round de combat (maximum 5 rounds).'),
  ],
);

const _voie_combat_du_mal = VoieCatalogue(
  id: 'prestige_combat-du-mal',
  nom: 'Voie du Combat du Mal',
  profil: 'Combattants',
  famille: 'Voies de prestige de combattant',
  description: 'Cette voie est destinée au pourfendeur de créatures maléfiques, chasseur de sorcière et autre inquisiteur.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Juste courroux', type: 'G', description: 'Chaque fois que le personnage est victime d\'une Attaque sournoise ou d\'une Attaque mortelle, il peut riposter par une attaque au contact en action gratuite.'),
    CapaciteCatalogue(rang: 5, nom: 'Épée de lumière', type: 'M', description: 'L\'arme du personnage brille d\'une lumière magique (ou par hargne) et occasionne +1d4° DM supplémentaire aux morts-vivants, aux créatures démoniaques ou aux animaux corrompus par le mal.'),
    CapaciteCatalogue(rang: 6, nom: 'Sentir la corruption', type: 'L', description: 'Le personnage détecte si une source maléfique est présente dans un rayon de 20 m autour de lui (mais pas sa localisation exacte).'),
    CapaciteCatalogue(rang: 7, nom: 'Frappe suppressive', type: 'L', description: 'En plus d\'infliger des DM normaux, la cible doit faire un test opposé d\'attaque magique contre le personnage. En cas d\'échec, elle ne peut utiliser aucun pouvoir magique à son prochain tour.'),
    CapaciteCatalogue(rang: 8, nom: 'Résister à la corruption', description: 'Une fois par combat, le personnage résiste totalement à un sort ou un effet magique de son choix. De plus, il est immunisé aux effets de corruption provoqués par les créatures du mal.'),
  ],
);

const _voie_combattant_des_tunnels = VoieCatalogue(
  id: 'prestige_combattant-des-tunnels',
  nom: 'Voie du Combattant des Tunnels',
  profil: 'Combattants',
  famille: 'Voies de prestige de combattant',
  description: 'Le spécialiste de la survie dans l\'outre-monde et l\'élimination des hordes goblinoïdes.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Infravision', description: 'Le combattant devient capable de voir dans le noir à une distance de 10 m (ou augmente la portée de 10 m). De plus, il obtient +5 à tous les tests de survie et d\'orientation en milieu souterrain.'),
    CapaciteCatalogue(rang: 5, nom: 'Combat confiné', description: 'Le combattant des tunnels ne subit plus de dé malus en attaque avec une arme plus longue qu\'une dague en espace réduit. Il gagne +1 en DEF (+2 au rang 7) tant qu\'il tient une arme en main, même en dehors d\'un espace confiné.'),
    CapaciteCatalogue(rang: 6, nom: 'Briseur de hordes', type: 'G', description: 'Une fois par round, le personnage inflige automatiquement 1d4° DM à chaque adversaire à son contact dont le NC est inférieur ou égal à la moitié de son propre niveau.'),
    CapaciteCatalogue(rang: 7, nom: 'Tueur de nuées', description: 'Le combattant des tunnels inflige +1d4° DM aux créatures de tailles Petite ou inférieures (striges, kobolds, etc.) et aux nuées.'),
    CapaciteCatalogue(rang: 8, nom: 'Briseur de voûte', description: 'Une fois par combat, dans une cavité de moins de 6 m de hauteur, il fait s\'écrouler la voûte. 10x10 m face à lui : 4d4° DM. Zone devient terrain difficile, créatures à 0 PV sont ensevelies.'),
  ],
);

const _voie_danseur_de_guerre = VoieCatalogue(
  id: 'prestige_danseur-de-guerre',
  nom: 'Voie du Danseur de Guerre',
  profil: 'Combattants',
  famille: 'Voies de prestige de combattant',
  description: 'Le combattant ne doit pas porter d\'armure plus encombrante qu\'une chemise de mailles.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Vent des lames', description: 'Le personnage peut utiliser son AGI au choix en attaque au contact ou aux DM (mais pas les deux) avec dague, épée courte/longue/sabre ou lance.'),
    CapaciteCatalogue(rang: 5, nom: 'Pirouettes', description: 'Il gagne +1 en DEF (+2 au rang 8). De plus, bonus de +5 aux tests de danse et d\'acrobaties.'),
    CapaciteCatalogue(rang: 6, nom: 'Attaque en mouvement', type: 'G', description: 'À chaque fois qu\'il réalise une action limitée pour attaquer au contact, il peut se déplacer de 10 m avant ou après.'),
    CapaciteCatalogue(rang: 7, nom: 'Danse des lames', type: 'L', description: 'Pendant la transe, il peut réaliser une attaque gratuite supplémentaire à son tour chaque round avec un dé malus. Une blessure critique stoppe la transe.'),
    CapaciteCatalogue(rang: 8, nom: 'Volte-face', description: 'Pour chaque round où le PJ attaque une cible différente de celle du round précédent, il obtient un dé bonus en attaque et +1d4° aux DM sur sa première attaque.'),
  ],
);

const _voie_ecorcheur = VoieCatalogue(
  id: 'prestige_ecorcheur',
  nom: 'Voie de l\'Écorcheur',
  profil: 'Combattants',
  famille: 'Voies de prestige de combattant',
  description: 'Chevalier noir, barbare tendance gore ou simplement guerrier sadique, le combattant qui choisit la voie de l\'écorcheur soigne son apparence intimidante, toutefois ce n\'est que secondaire : ce qu\'il aime, c\'est le goût du sang.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Armes dentelées', description: 'Les armes et les lames du personnage sont dentelées, elles possèdent des formes torturées destinées à provoquer des blessures sanglantes. Le personnage obtient un bonus de +5 à tous ses tests d\'intimidation. De plus, lors d\'une attaque réussie, il provoque un effet de saignement qui inflige 1 DM par round à la victime pour le reste du combat. Pour stopper cette hémorragie, la victime doit recevoir des soins ou prendre une action limitée et réussir un test d\'AGI difficulté 10. Cet effet de saignement passe à 2 DM au rang 8 de la voie. Il ne se cumule pas.'),
    CapaciteCatalogue(rang: 5, nom: 'Armure à pointes', description: 'L\'armure et le bouclier du guerrier sont décorés de piques et de lames afin de blesser les créatures qui l\'attaquent. À chaque fois qu\'une créature attaque au contact le personnage avec des armes naturelles (mains nues, griffes, crocs) et qu\'elle touche au moins une Défense de 10, elle subit 1d4 DM. Ces DM passent à 1d4° au rang 7.'),
    CapaciteCatalogue(rang: 6, nom: 'Blessures affreuses', description: 'Les blessures infligées par les attaques au contact du personnage sont très longues à guérir. Les effets de soins ou de régénération sont divisés par 2 lorsqu\'il s\'agit de guérir ces DM.'),
    CapaciteCatalogue(rang: 7, nom: 'Hémorragie interne', description: 'Lorsque le personnage inflige un critique, la victime subit 1d4° DM supplémentaires à chaque round suivant pendant 3 rounds.'),
    CapaciteCatalogue(rang: 8, nom: 'Impitoyable', description: 'Lorsque l\'écorcheur rate une attaque, il inflige tout de même 1d4° DM à sa cible (de même nature que les DM habituels de son attaque).'),
  ],
);

const _voie_guerrier_mage = VoieCatalogue(
  id: 'prestige_guerrier-mage',
  nom: 'Voie du Guerrier-Mage',
  profil: 'Combattants',
  famille: 'Voies de prestige de combattant',
  description: 'Cette voie permet de lancer des sorts en armures, elle peut s\'avérer très utile pour un concept de chevalier de la mort (chevalier-sorcier).',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Magie en armure', description: 'Le personnage peut lancer des sorts profanes en armure sans surcoût si le bonus de DEF total des protections est <= rang - 2. (ex: rang 4 = armure de cuir, rang 8 = plaque). Les bonus magiques d\'armure ne comptent pas dans cette limite.'),
    CapaciteCatalogue(rang: 5, nom: 'Rituel de combat', description: 'Parmi les sorts infligeant des DM que connaît le personnage, il en choisit un qui lui coûte désormais 1 PM de moins à lancer.'),
    CapaciteCatalogue(rang: 6, nom: 'Déflexion arcanique', type: 'G', description: 'Dépense 1 PM pour obtenir +2 en DEF contre une attaque. Annonçable après le résultat pour le faire échouer (max 1 PM par attaque, mais utilisable plusieurs fois par round). À partir du rang 9, peut dépenser 3 PM pour +5 en DEF.'),
    CapaciteCatalogue(rang: 7, nom: 'Magie de combat', description: 'Lorsqu\'il utilise la Concentration (L) pour lancer un sort de rang 1 à 3, le combattant peut choisir de faire une attaque au contact gratuite au lieu de réduire son coût.'),
    CapaciteCatalogue(rang: 8, nom: 'Frappe des arcanes', type: 'G', description: 'Le personnage insuffle sa puissance magique dans une attaque au contact : il dépense 1 PM pour obtenir un dé bonus et +1d4° aux DM sur cette attaque.'),
  ],
);

const _voie_ours = VoieCatalogue(
  id: 'prestige_ours',
  nom: 'Voie de l\'Ours',
  profil: 'Combattants',
  famille: 'Voies de prestige de combattant',
  description: 'Les guerriers-ours adoptent la philosophie, les techniques de combat et parfois même la forme de leur animal totémique.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Caractère d\'ours', description: 'Le personnage gagne un bonus de +5 à tous les tests d\'intimidation. Une fois par combat, il peut pousser un terrible grondement en action gratuite. Tous les adversaires à son contact de NC inférieur à son niveau doivent réussir un test de VOL difficulté [6 + rang] ou s\'enfuir en courant pendant 1d4 rounds.'),
    CapaciteCatalogue(rang: 5, nom: 'Hibernation', description: 'Le personnage peut dormir sans interruption jusqu\'à 2 jours par rang. Durant cette période, il n\'a besoin ni d\'eau ni de nourriture et ne souffre pas plus du froid que de la chaleur ; il récupère normalement de ses blessures. Après avoir dormi plusieurs jours de suite, le personnage est capable de rester le même nombre de jours sans dormir.'),
    CapaciteCatalogue(rang: 6, nom: 'Métamorphose', type: 'L', description: 'Une fois par jour, le personnage peut prendre la forme d\'un ours (Taille grande, +6 FOR, +6 CON...) pendant [1d6+CON] minutes. Il ne doit pas porter d\'armure plus lourde que le cuir renforcé. Il conserve sa propre INT, mais a tendance à réagir comme l\'animal et ne peut plus utiliser ses capacités de profil. S\'il est réduit à 0 PV sous cette forme, il reprend forme humaine.'),
    CapaciteCatalogue(rang: 7, nom: 'Étreinte de l\'ours', type: 'L', description: 'Une fois par combat, le personnage peut se saisir d\'un adversaire dont la FOR est inférieure à la sienne et l\'écraser. Sur une attaque au contact réussie, il inflige [2d4°+FOR] DM et la cible est immobilisée. À son tour, la victime peut tenter de se libérer avec un test de FOR opposé. À chacun des tours suivants, tant que l\'étreinte est maintenue, le personnage inflige à nouveau des DM automatiquement. Utilisable sous forme d\'ours.'),
    CapaciteCatalogue(rang: 8, nom: 'Métamorphose supérieure', type: 'L', description: 'Les plus puissants guerriers-ours peuvent prendre la forme d\'un ours une fois par combat (nécessite de terminer une récupération rapide). Ces métamorphoses durent chaque fois jusqu\'à [1d6+CON] heures.'),
  ],
);

const _voie_porteur_bouclier = VoieCatalogue(
  id: 'prestige_porteur-bouclier',
  nom: 'Voie du Porteur de Bouclier',
  profil: 'Combattants',
  famille: 'Voies de prestige de combattant',
  description: 'Cette voie permet de devenir un expert du bouclier. Un guerrier ayant complété la voie du bouclier ou un chevalier celle de la guerre pourront trouver là une spécialisation toujours plus pointue dans le domaine défensif.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Parade au bouclier', type: 'G', description: 'Une fois par combat, le personnage peut parer une attaque au contact ou à distance qui le touche avec son bouclier (action gratuite). Il ne subit aucun DM sauf s\'il s\'agit d\'un critique (il ne peut pas le parer).'),
    CapaciteCatalogue(rang: 5, nom: 'Attaque au bouclier', type: 'G', description: 'Une fois par round, le personnage peut faire une attaque gratuite au bouclier. Il subit un dé malus en attaque et il inflige [1d4°+FOR] DM.'),
    CapaciteCatalogue(rang: 6, nom: 'Bousculade', description: 'Lorsque le personnage réussit son attaque au bouclier, il peut choisir de faire reculer sa cible de 2 m. Si la cible est d\'une taille supérieure à la sienne, il doit emporter un test opposé de FOR. De plus, le personnage augmente de +1 la DEF apportée par son bouclier. Ce bonus passe à +2 au rang 8 de la voie.'),
    CapaciteCatalogue(rang: 7, nom: 'Dévier les coups', type: 'G', description: 'Une fois par round, en action gratuite, le personnage retranche la valeur de DEF de son bouclier (bonus de magie inclus) aux DM subis d\'une attaque au contact ou à distance, sauf s\'il est surpris.'),
    CapaciteCatalogue(rang: 8, nom: 'Lancer de bouclier', type: 'A', description: 'Le personnage peut lancer son bouclier à une portée de 20 m par une action d\'attaque. S\'il réussit un test d\'attaque à distance, il inflige les DM d\'une Attaque au bouclier et la cible doit faire un test de FOR difficulté [10 + FOR du personnage] ou être renversée. Tant que le bouclier est à moins de 20 m du personnage, il peut le faire revenir à son bras (et l\'équiper) par une action de mouvement (M).'),
  ],
);

const _voie_tueur_geants = VoieCatalogue(
  id: 'prestige_tueur-geants',
  nom: 'Voie du Tueur de Géants',
  profil: 'Combattants',
  famille: 'Voies de prestige de combattant',
  description: 'Célèbres parmi les nains, les tueurs de géants sont une caste à part, des têtes brûlées qui se sont spécialisées dans les combats contre cet ennemi ancestral dans les montagnes.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Profil bas', description: 'Que ce soit pour approcher ou pour éviter les grandes créatures, le tueur de géants sait se faire tout petit. Il obtient un bonus de +5 à tous les tests de discrétion destinés à échapper à la perception des créatures de taille grande et supérieure.'),
    CapaciteCatalogue(rang: 5, nom: 'Ventre mou', description: 'Le personnage sait se placer de façon à atteindre les parties molles ou vitales en passant sous les grandes créatures. Il ignore la RD des créatures lorsqu\'elle est basée sur leur taille.'),
    CapaciteCatalogue(rang: 6, nom: 'Réduire la distance', description: 'Le personnage est passé maître dans l\'art de réduire la distance pour gêner les créatures avec une grande allonge. Il obtient +1 en DEF contre les créatures de taille grande, +2 contre les créatures énormes et +3 contre les créatures colossales.'),
    CapaciteCatalogue(rang: 7, nom: 'Pieds d\'argile', type: 'L', description: 'Le tueur de géants réalise une attaque aux jambes contre une créature de taille grande ou supérieure. En cas de réussite, il inflige ½ DM, mais la créature est ralentie au prochain round et invalide pour tout le reste du combat. En cas de réussite avec une marge d\'au moins 10 points, la cible est de plus renversée ! Une cible ne peut subir ces effets plus d\'une fois par combat (ralenti et invalide).'),
    CapaciteCatalogue(rang: 8, nom: 'Tueur de géants', description: 'Le personnage est habitué à combattre les géants et les énormes créatures. Il obtient +1d6 DM contre les créatures de taille grande, +1d4° DM contre les créatures de taille énorme et +2d4° DM contre celles de taille colossale.'),
  ],
);

// ── MYSTIQUES ────────────────────────────────────────────────────────────────

const _voie_armure_sacree = VoieCatalogue(
  id: 'prestige_armure-sacree',
  nom: 'Voie de l\'Armure Sacrée',
  profil: 'Mystiques',
  famille: 'Voies de prestige de mystique',
  description: 'Permet au personnage de revêtir une armure magique extraordinaire. Chaque armure est unique, n\'accepte qu\'un seul maître.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Armure de bronze', description: 'Le personnage acquiert son armure de bronze (cube de métal de 50 cm/10 kg portant son symbole). Sur un mot de commande, elle se déploie. Confère une RD 3 sans pénalité d\'encombrement.'),
    CapaciteCatalogue(rang: 5, nom: 'Pouvoir unique', type: 'L', description: 'Le personnage associe à son armure un sort de son choix de rang 1 à 4 de n\'importe quelle voie. Utilisations par combat : Rang 1 (4 fois), Rang 2 (3 fois), Rang 3 (2 fois), Rang 4 (1 fois).'),
    CapaciteCatalogue(rang: 6, nom: 'Armure d\'argent', description: 'L\'armure acquiert la couleur de l\'argent. Elle octroie une RD 5.'),
    CapaciteCatalogue(rang: 7, nom: 'Pouvoir puissant', type: 'L', description: 'Le personnage associe à son armure un sort de son choix de rang 4 à 8 de n\'importe quelle voie. Utilisations par jour : Rang 5 (3 fois), Rang 6 (2 fois), Rang 7 (1 fois).'),
    CapaciteCatalogue(rang: 8, nom: 'Armure d\'or', description: 'L\'armure acquiert la couleur de l\'or et elle octroie une RD 7.'),
  ],
);

const _voie_changeforme = VoieCatalogue(
  id: 'prestige_changeforme',
  nom: 'Voie du Changeforme',
  profil: 'Mystiques',
  famille: 'Voies de prestige de mystique',
  description: 'Le changeforme est un lanceur de sorts capable de prendre la forme d\'animaux.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Forme de voyage', type: 'A', description: 'Le personnage peut prendre la forme d\'un animal (chat, chien, chevreuil, saumon ou corbeau) pour PER minutes (ou PER heures avec le sort de druide).'),
    CapaciteCatalogue(rang: 5, nom: 'Transformation en animal', type: 'A', description: 'Le personnage fait l\'acquisition de la capacité de druide Forme animale (une seule catégorie). S\'il la possédait déjà, la transformation dure PER heures et il guérit de 3d4° PV à la fin.'),
    CapaciteCatalogue(rang: 6, nom: 'Transformation puissante', type: 'A', description: 'Le personnage conserve sa propre DEF et valeur d\'attaque magique sous forme animale. Peut prendre la forme d\'animaux géants (taille M max).'),
    CapaciteCatalogue(rang: 7, nom: 'Grande forme animale', type: 'A', description: 'Il peut prendre la forme d\'un animal de taille Grande (coût : 2 + NC PM).'),
    CapaciteCatalogue(rang: 8, nom: 'Forme animale énorme', type: 'A', description: 'Il peut prendre la forme d\'un animal de taille Énorme (éléphant, etc.).'),
  ],
);

const _voie_combat_mystique = VoieCatalogue(
  id: 'prestige_combat-mystique',
  nom: 'Voie du Combat Mystique',
  profil: 'Mystiques',
  famille: 'Voies de prestige de mystique',
  description: 'Cette voie est parfaitement adaptée au moine, mais elle fait de tout mystique un adepte des manœuvres martiales à grand spectacle.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Attaque étourdissante', type: 'L', description: 'Si le NC de la victime d\'une attaque à mains nues ou arme contondante est inférieur au rang de la voie, elle doit réussir un test de CON [10 + VOL] ou être étourdie 1 round.'),
    CapaciteCatalogue(rang: 5, nom: 'Frappe concentrée', type: 'A', description: 'Se concentre 1d4 rounds (RD 5). Au round suivant, l\'attaque touche automatiquement et triple les DM.'),
    CapaciteCatalogue(rang: 6, nom: 'Pression nerveuse', type: 'L', description: 'Une fois par combat, pince un nerf. Si NC cible < rang, paralysie pour VOL minutes (sinon 1 round).'),
    CapaciteCatalogue(rang: 7, nom: 'Paume mortelle', type: 'L', description: 'Une fois par jour, attaque à mains nues mortelle (test opposé d\'attaque magique).'),
    CapaciteCatalogue(rang: 8, nom: 'Main du tout-puissant', type: 'L', description: 'Une fois par jour, frappe le sol : onde 20 m de large/profondeur, tous renversés, [4d4° + VOL] DM.'),
  ],
);

const _voie_elementaire_air = VoieCatalogue(
  id: 'prestige_elementaire-air',
  nom: 'Voie Élémentaire de l\'Air',
  profil: 'Mystiques',
  famille: 'Voies de prestige de mystique',
  description: 'Les voies élémentaires ont tendance à changer profondément ceux qui les suivent, tant physiquement que mentalement. Dans le cas de l\'air, les cheveux deviennent blancs et la peau très pâle, tandis que le tempérament devient rêveur.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Bourrasque', type: 'A', description: 'Le personnage prend une grande inspiration et souffle une terrible bourrasque. Toutes les créatures face à lui dans un cône de 30 m doivent faire un test de FOR difficulté [10 + rang] ou être renversées et repoussées en arrière selon leur taille.'),
    CapaciteCatalogue(rang: 5, nom: 'Chevaucher les nuées', type: 'A', description: 'Le personnage et un compagnon supplémentaire par rang peuvent être transportés par les forces du vent sur une distance de 1 km au maximum à la vitesse de 100 m par round. Le personnage doit voir l\'endroit de destination.'),
    CapaciteCatalogue(rang: 6, nom: 'Mur de vent', type: 'A', description: 'Crée un mur de vent circulaire de 5 à 10 m de diamètre autour du personnage pendant CHA minutes. Il bloque les attaques à distance dans les deux sens et repousse ceux qui tentent de le franchir (test de FOR difficulté [10 + rang] pour passer).'),
    CapaciteCatalogue(rang: 7, nom: 'Cyclone', type: 'A', description: 'Invoque un violent maelström (portée 500 m, 20 m de diamètre). Les créatures dans la zone subissent 2d4° DM par round et doivent réussir un test de FOR difficulté 15 ou être renversées. Durée CHA minutes. Peut être déplacé de 10 m par action de mouvement.'),
    CapaciteCatalogue(rang: 8, nom: 'Forme élémentaire d\'air', type: 'A', description: 'Une fois par jour, le personnage peut se transformer en élémentaire d\'air (taille grand), pendant un maximum de CHA minutes. Ne peut pas parler, utilise uniquement les capacités de la voie, immunisé à la foudre. AGI +5*, Frappe [2d4°+4 de foudre].'),
  ],
);

const _voie_elementaire_eau = VoieCatalogue(
  id: 'prestige_elementaire-eau',
  nom: 'Voie Élémentaire de l\'Eau',
  profil: 'Mystiques',
  famille: 'Voies de prestige de mystique',
  description: 'Les voies élémentaires ont tendance à changer profondément ceux qui les suivent, tant physiquement que mentalement. Dans le cas de l\'eau, les cheveux semblent toujours mouillés et les yeux prennent une couleur délavée.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Brouillard', type: 'A', description: 'Lève un brouillard dense dans un rayon de 20 m. S\'il maintient sa concentration, il peut l\'augmenter de 20 m par round. Dure CHA minutes une fois la concentration cessée.'),
    CapaciteCatalogue(rang: 5, nom: 'Mur acide', type: 'A', description: 'Crée un mur d\'acide rectiligne de 20 m de long pour 4 m de haut. Toute créature qui le franchit subit [3d4° + CHA] DM d\'acide. Durée : CHA minutes.'),
    CapaciteCatalogue(rang: 6, nom: 'Armure d\'eau', type: 'A', description: 'Une couche d\'eau recouvre le personnage pendant CHA minutes, elle lui donne une RD 3 contre tous les DM physiques et RD 10 contre le feu et l\'acide. Le personnage est glissant et ne peut être saisi.'),
    CapaciteCatalogue(rang: 7, nom: 'Écartement des eaux', type: 'A', description: 'Peut stopper le cours d\'une rivière ou écarter les eaux d\'un lac sur 1 km maximum. Lui et ses compagnons peuvent traverser à pied sec pendant CHA heures.'),
    CapaciteCatalogue(rang: 8, nom: 'Forme élémentaire d\'eau', type: 'A', description: 'Une fois par jour, le personnage peut se transformer en élémentaire d\'eau (taille grand), pendant un maximum de CHA minutes. Ne peut pas parler, immunisé à l\'acide. AGI +3*, Frappe [2d4°+5 d\'acide].'),
  ],
);

const _voie_elementaire_terre = VoieCatalogue(
  id: 'prestige_elementaire-terre',
  nom: 'Voie Élémentaire de la Terre',
  profil: 'Mystiques',
  famille: 'Voies de prestige de mystique',
  description: 'Les voies élémentaires ont tendance à changer profondément ceux qui les suivent, tant physiquement que mentalement. Dans le cas de la terre, les cheveux deviennent gris, la peau terreuse, tandis que le tempérament devient plus introverti.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Mur de pierre', type: 'A', description: 'Invoque un mur de pierre parfaitement rectiligne de 20 m de long pour 4 m de haut (portée 20 m). Il a une durée d\'existence d\'INT heures (Solidité 30, RD 20, 30 cm d\'épaisseur).'),
    CapaciteCatalogue(rang: 5, nom: 'Litomorphose', type: 'A', description: 'Peut modeler la pierre par sa simple volonté (portée 10 m). Il affecte un volume maximal de 1 m³ par niveau et lui donne la forme qu\'il désire. La transformation dure INT heures.'),
    CapaciteCatalogue(rang: 6, nom: 'Pétrification', type: 'A', description: 'Test opposé d\'attaque magique (portée 20 m). En cas de réussite, la victime est changée en pierre (effet permanent, RD 30). Si son niveau est >= au lanceur, test de CON [10 + CHA] par round pour s\'en libérer.'),
    CapaciteCatalogue(rang: 7, nom: 'Séisme', type: 'A', description: 'Déclenche un tremblement de terre dans 100 m de rayon. Les bâtisses peuvent s\'effondrer, infligeant 4d6 DM aux occupants (la moitié si la bâtisse résiste). Sous terre, inflige 4d6 DM dans toute la zone.'),
    CapaciteCatalogue(rang: 8, nom: 'Forme élémentaire de terre', type: 'A', description: 'Une fois par jour, se transforme en élémentaire de terre (taille grand), pendant CHA minutes. Ne peut pas parler, utilise uniquement les capacités de la voie. FOR +6*, Coup de poing [2d4°+6].'),
  ],
);

const _voie_guerisseur = VoieCatalogue(
  id: 'prestige_guerisseur',
  nom: 'Voie du Guérisseur',
  profil: 'Mystiques',
  famille: 'Voies de prestige de mystique',
  description: 'Cette voie est destinée à ceux qui souhaitent prendre soin de la santé de leur prochain : prêtres, druides, et même moines.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Premiers soins', type: 'A', description: 'S\'utilise seulement sur une créature vivante à 0 PV. La cible touchée récupère immédiatement [3d4° + CHA] PV. Un patient ne peut bénéficier de cette capacité qu\'une seule fois par combat.'),
    CapaciteCatalogue(rang: 5, nom: 'Soins rapides', type: 'G', description: 'D\'un simple regard, le personnage soigne une cible (ou lui-même) à une portée de 20 m, elle récupère immédiatement [2d4° + CHA] PV.'),
    CapaciteCatalogue(rang: 6, nom: 'Rappel à la vie', type: 'L', description: 'Une fois par jour, le personnage peut rappeler à la vie un mort décédé depuis moins de [6 + CON] heures par un rituel de 30 min. Le personnage revient à la conscience avec 1d4° PV et il est affaibli pendant 24 h.'),
    CapaciteCatalogue(rang: 7, nom: 'Zone de vie', type: 'A', description: 'Enchante une zone de 10 m de rayon pour CHA rounds. Les créatures vivantes dans la zone récupèrent 2d4° PV à chaque round. Les morts-vivants et démons subissent des DM équivalents.'),
    CapaciteCatalogue(rang: 8, nom: 'Résurrection', type: 'L', description: 'Une fois par aventure, le personnage peut rappeler à la vie un personnage décédé depuis moins de [CHA] jours par un rituel de 7 h (nécessite une relique). Le personnage revient avec 1 PV, affaibli 7 jours (et perd 1 CON au-delà de la 1ère fois).'),
  ],
);

const _voie_maitre_nature = VoieCatalogue(
  id: 'prestige_maitre-nature',
  nom: 'Voie du Maître de la Nature',
  profil: 'Mystiques',
  famille: 'Voies de prestige de mystique',
  description: 'Les maîtres de la nature sont en communion avec la nature et les animaux se mettent à leur service.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Amitié animale', type: 'A', description: 'Test opposé d\'attaque magique (portée 10 m). L\'animal se met au service du personnage pendant PER heures. NC des animaux contrôlés <= rang. Affecte animaux géants (rang 6) et fantastiques (rang 8). Ne fonctionne pas en ville.'),
    CapaciteCatalogue(rang: 5, nom: 'Seigneur de la nature', description: 'Choisissez un milieu naturel de prédilection (puis un 2e au rang 7). Dans ce milieu, dé bonus à tous les tests et récupère 1d4° PV durant chaque récupération rapide.'),
    CapaciteCatalogue(rang: 6, nom: 'Invisibilité aux animaux', description: 'Dans un milieu de prédilection, le personnage est totalement indétectable par les animaux et insectes (même géants). Prend fin s\'il entreprend une action offensive.'),
    CapaciteCatalogue(rang: 7, nom: 'Monture géante', description: 'Le personnage obtient une monture géante adaptée à son milieu de prédilection (NC max = rang + PER). Elle peut attaquer 1 fois par round sur son ordre (action gratuite).'),
    CapaciteCatalogue(rang: 8, nom: 'Magie druidique innée', type: 'G', description: '3 fois par jour, dans un milieu de prédilection, le personnage peut lancer n\'importe quel sort de druide sans coût en PM (1 fois max par round).'),
  ],
);

const _voie_saisons = VoieCatalogue(
  id: 'prestige_saisons',
  nom: 'Voie des Saisons',
  profil: 'Mystiques',
  famille: 'Voies de prestige de mystique',
  description: 'Le personnage laisse les cycles naturels s\'emparer de son corps.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Vigueur du printemps', description: 'Le personnage gagne 2 DR supplémentaires et relance tous les 1 des DR.'),
    CapaciteCatalogue(rang: 5, nom: 'Flamme de l\'été', type: 'A', description: 'Lance un projectile de feu [2d4° + PER] DM (portée 30m). Divise les DM de feu subis par 2.'),
    CapaciteCatalogue(rang: 6, nom: 'Tourbillon d\'automne', type: 'A', description: 'Tourbillon 5 m diamètre (portée 10m) infligeant [3d4° + PER] DM par round (durée PER rounds).'),
    CapaciteCatalogue(rang: 7, nom: 'Frimas de l\'hiver', type: 'A', description: 'Lance un projectile de glace [4d4° + PER] DM. Cible ralentie sur échec test CON. Divise les DM de froid subis par 2.'),
    CapaciteCatalogue(rang: 8, nom: 'Contrôle climatique', type: 'A', description: 'Peut faire varier la météo d\'un palier de conditions. Au palier 6, appelle la foudre (4d4° DM).'),
  ],
);

const _voie_templier = VoieCatalogue(
  id: 'prestige_templier',
  nom: 'Voie du Templier',
  profil: 'Mystiques',
  famille: 'Voies de prestige de mystique',
  description: 'Le templier est un soldat de la foi. Il combat les forces du mal et concentre ses forces pour combattre les démons et les morts-vivants. Cette voie est obligatoirement utilisée avec le CHA.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Résistance au mal', type: 'M', description: 'Le personnage touche une cible volontaire (ou lui-même). Elle devient immunisée à toutes les capacités de drain, charme, domination, paralysie des morts-vivants pendant CHA minutes. Le personnage gagne +1 en DEF.'),
    CapaciteCatalogue(rang: 5, nom: 'Quête', type: 'L', description: 'Assigne une quête à une cible lors d\'un rituel de 10 min. La créature récupère 1 PC par jour si elle y travaille, mais est affaiblie après 24h si elle l\'abandonne. Alternativement, peut imposer un interdit.'),
    CapaciteCatalogue(rang: 6, nom: 'Résistance au mal supérieure', type: 'A', description: 'Permet à la cible visée de résister à la fois aux pouvoirs des morts-vivants et des démons. Le bonus de DEF permanent de Résistance au mal passe à +2.'),
    CapaciteCatalogue(rang: 7, nom: 'Châtiment du mal', type: 'L', description: 'Le personnage effectue une attaque contre un mort-vivant ou un démon. Il inflige le double des DM habituels (le triple en cas de critique). S\'il connaît Châtiment divin, il peut l\'appliquer simultanément.'),
    CapaciteCatalogue(rang: 8, nom: 'Forme d\'Ange', type: 'A', description: 'Une fois par jour, le personnage prend la forme d\'un ange pendant CHA minutes. Il peut voler de 30 m par action de mouvement et obtient une RD 10 contre les attaques des morts-vivants et des démons.'),
  ],
);

const _voie_vermines = VoieCatalogue(
  id: 'prestige_vermines',
  nom: 'Voie des Vermines',
  profil: 'Mystiques',
  famille: 'Voies de prestige de mystique',
  description: 'Pour ceux qui adorent les araignées et les scorpions.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Maître vermine', description: 'Le personnage communique avec les vermines géantes, qui le considèrent comme amical.'),
    CapaciteCatalogue(rang: 5, nom: 'Nuées de criquets', type: 'A', description: 'Libère une nuée (portée 20m) qui dévore la cible pendant [5 + CHA] rounds. 2 DM/tour et -3 à toutes actions.'),
    CapaciteCatalogue(rang: 6, nom: 'Compagnon vermine', description: 'Le personnage adopte un scorpion ou une araignée géante.'),
    CapaciteCatalogue(rang: 7, nom: 'Affinité au poison', type: 'L', description: 'Enduit son arme de poison (1 fois par combat) pour +1d4° DM. Divise DM/durée des poisons subis par 2.'),
    CapaciteCatalogue(rang: 8, nom: 'Vermine supérieure', description: 'Le compagnon gagne Étreinte du scorpion ou Toile d\'araignée et peut servir de monture.'),
  ],
);

// ── MAGES ────────────────────────────────────────────────────────────────────

const _voie_archimage = VoieCatalogue(
  id: 'prestige_archimage',
  nom: 'Voie de l\'Archimage',
  profil: 'Mages',
  famille: 'Voies de prestige de mage',
  description: 'La voie de l\'archimage est la voie par défaut des plus grands magiciens, elle est le prolongement direct de la voie de la magie universelle et leur ouvre un éventail de pouvoirs défensifs et offensifs importants.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Sceptre défensif', description: 'Lorsqu\'il tient son bâton en main, le personnage gagne un bonus de +1 en DEF et à tous les tests opposés de magie effectués pour résister à des sorts. Ce bonus passe à +2 au rang 6 et +3 au rang 8.'),
    CapaciteCatalogue(rang: 5, nom: 'Bâton magique', description: 'Le personnage choisit un sort de rang 1 de la famille des mages. Il est lié à son bâton et il peut l\'utiliser au prix d\'une action de mouvement sans dépense de mana. À partir du rang 7, il peut ajouter un sort de rang 2 qui ne coûte pas non plus de point de mana.'),
    CapaciteCatalogue(rang: 6, nom: 'Paralysie', type: 'L', description: 'Le lanceur de sort paralyse autant de créatures qu\'il le peut dans un rayon de 10 m autour de lui pendant [1d4°+ INT] rounds. Il doit maintenir sa concentration (M). La somme des NC ne doit pas dépasser son niveau. Les créatures de NC 4+ peuvent se libérer du sort (test de CON diff 15, action G).'),
    CapaciteCatalogue(rang: 7, nom: 'Barrière magique', type: 'L', description: 'Trace une ligne de 20 m max formant une frontière invisible (durée 24h). Toute créature tentant de la forcer fait un test opposé d\'attaque magique. En cas d\'échec, subit [5d4°°+ INT] DM et ne peut réessayer avant 1h. En cas de succès, franchit et subit la moitié des DM.'),
    CapaciteCatalogue(rang: 8, nom: 'Métamorphose d\'autrui', type: 'A', description: 'Test opposé d\'attaque magique (portée 20 m). Transforme la cible en un animal de taille petite ou inférieure (grenouille 1 PV, mouton 2 PV). Si réduit à 0 PV, retrouve sa forme et doit réussir test de CON diff 10 ou mourir. Durée selon NC (NC 0-1: permanent, NC 5+: 1d6 rounds, etc.).'),
  ],
);

const _voie_chaos = VoieCatalogue(
  id: 'prestige_chaos',
  nom: 'Voie du Chaos',
  profil: 'Mages',
  famille: 'Voies de prestige de mage',
  description: 'Parfois aussi appelée voie de l\'arc-en-ciel, cette voie manipule une énergie étrange et subtile dont les couleurs de l\'arc-en-ciel ne sont que la manifestation d\'une magie instable et étrange.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Arc-en-ciel', type: 'A', description: 'Test opposé d\'attaque magique (portée 10 m). Effet selon NC: NC 1 ou moins: inconscient 1d6 rounds. NC 2 ou 3: aveuglé 1d6 rounds. NC 4 et plus: affaibli 1d6 rounds. Sans effet si NC >= niveau du magicien.'),
    CapaciteCatalogue(rang: 5, nom: 'Mur arc-en-ciel', type: 'A', description: 'Crée un mur opaque (rectiligne jusqu\'à 5m haut x 3m long/rang, ou circulaire de diamètre/rang) pour INT minutes. Repousse violemment les créatures (2d4° mètres et DM) selon leur NC. Le magicien le traverse librement. Stoppe attaques magiques et projectiles.'),
    CapaciteCatalogue(rang: 6, nom: 'Pont arc-en-ciel', type: 'A', description: 'Crée un pont entre deux points en vue (INT heures). Alliés parcourent instantanément. Autres: test d\'INT [10+INT]. En cas d\'échec (1d6) : 1-2 projetée 3d4° DM de chute, 3-4 projetée dans le temps (1d4° min), 5-6 projetée dans l\'espace (1d4° km).'),
    CapaciteCatalogue(rang: 7, nom: 'Explosion multicolore', type: 'A', description: 'Mêmes effets que l\'arc-en-ciel dans une zone de 10 m de diamètre à une portée de 30 m.'),
    CapaciteCatalogue(rang: 8, nom: 'Sphère multicolore', type: 'A', description: 'Sphère immobile de 5 m de diamètre autour du mage (INT heures). Téléporte les créatures entrant (distance selon NC). Le mage et ses alliés entrent/sortent librement. Les créatures de NC >= niveau peuvent résister avec test INT.'),
  ],
);

const _voie_cristaux = VoieCatalogue(
  id: 'prestige_cristaux',
  nom: 'Voie des Cristaux',
  profil: 'Mages',
  famille: 'Voies de prestige de mage',
  description: 'L\'art de la taille et de l\'harmonisation des cristaux magiques. Un cristal tourne autour de la tête pour fonctionner. L\'activer/désactiver est une action (L). Fabriquer demande 1d6 jours et 500 pa.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Premier cristal', description: 'Le personnage apprend à créer le cristal de son choix parmi une liste d\'effets (Régénération, Bonus de carac, Résistance élémentaire...). Il ne peut activer qu\'un seul cristal à la fois.'),
    CapaciteCatalogue(rang: 5, nom: 'Second cristal', description: 'Le personnage apprend à créer un nouveau cristal de son choix. Il peut activer les effets de 2 cristaux simultanément.'),
    CapaciteCatalogue(rang: 6, nom: 'Troisième cristal', description: 'Le personnage apprend à créer deux nouveaux cristaux de son choix. Il peut activer les effets de 3 cristaux simultanément.'),
    CapaciteCatalogue(rang: 7, nom: 'Quatrième cristal', description: 'Le personnage apprend à créer deux nouveaux cristaux de son choix. Il peut activer les effets de 4 cristaux simultanément.'),
    CapaciteCatalogue(rang: 8, nom: 'Cinquième cristal', description: 'Le personnage apprend à créer trois nouveaux cristaux de son choix. Il peut activer les effets de 5 cristaux simultanément.'),
  ],
);

const _voie_elementaliste = VoieCatalogue(
  id: 'prestige_elementaliste',
  nom: 'Voie de l\'Élémentaliste',
  profil: 'Mages',
  famille: 'Voies de prestige de mage',
  description: 'Maîtres dans l\'art de manipuler les énergies élémentaires (foudre, acide, feu et froid).',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Élément de prédilection', description: 'Choisit un élément parmi feu, froid, électricité et acide. Lorsqu\'il utilise un sort de cet élément, il obtient +2 en attaque magique et augmente de +2 la difficulté de résistance adverse.'),
    CapaciteCatalogue(rang: 5, nom: 'Résistance élémentaire', description: 'Ne subit que la moitié des DM de son élément de prédilection. Peut transformer un sort élémentaire pour le remplacer par son élément de prédilection en action gratuite.'),
    CapaciteCatalogue(rang: 6, nom: 'Invocation d\'élémentaire', type: 'L', description: 'Une fois par combat, invoque un élémentaire de l\'élément de son choix (DEF 19, PV [Niveau x 5], DM 2d4°+6 + effet). Obéit pendant INT minutes.'),
    CapaciteCatalogue(rang: 7, nom: 'Élément puissant', description: 'Ajoute +1d4° aux DM de tous les sorts qui infligent des dommages de son élément de prédilection (sur les DM initiaux pour les sorts sur la durée).'),
    CapaciteCatalogue(rang: 8, nom: 'Métamorphose élémentaire', type: 'A', description: 'Prend une forme élémentaire de son choix pendant [5 + INT] minutes. RD 5, immunisé à la forme choisie, et obtient des capacités uniques selon l\'élément (Feu, Eau, Terre, Air).'),
  ],
);

const _voie_enchanteur = VoieCatalogue(
  id: 'prestige_enchanteur',
  nom: 'Voie de l\'Enchanteur',
  profil: 'Mages',
  famille: 'Voies de prestige de mage',
  description: 'Mages se spécialisant dans la fabrication d\'objets magiques. Requis au moins une voie de magie jusqu\'au rang 4.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Enchantement Rang 4', description: 'Le personnage peut enchanter des objets magiques dont le niveau de magie maximal est égal à 1 (rang atteint - 3).'),
    CapaciteCatalogue(rang: 5, nom: 'Enchantement Rang 5', description: 'Le personnage peut enchanter des objets magiques dont le niveau de magie maximal est égal à 2 (rang atteint - 3).'),
    CapaciteCatalogue(rang: 6, nom: 'Enchantement Rang 6', description: 'Le personnage peut enchanter des objets magiques dont le niveau de magie maximal est égal à 3 (rang atteint - 3).'),
    CapaciteCatalogue(rang: 7, nom: 'Enchantement Rang 7', description: 'Le personnage peut enchanter des objets magiques dont le niveau de magie maximal est égal à 4 (rang atteint - 3).'),
    CapaciteCatalogue(rang: 8, nom: 'Enchantement Rang 8', description: 'Le personnage peut enchanter des objets magiques dont le niveau de magie maximal est égal à 5 (rang atteint - 3).'),
  ],
);

const _voie_gel = VoieCatalogue(
  id: 'prestige_gel',
  nom: 'Voie du Gel',
  profil: 'Mages',
  famille: 'Voies de prestige de mage',
  description: 'Les sorciers et les sorcières des cimes ou des étendues glacées du grand nord sont des adversaires redoutables.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Verglas', type: 'A', description: 'Recouvre le sol de verglas glissant sur 10 m de diamètre (INT min). Test d\'AGI 10 pour rester debout, 15 pour se déplacer/combattre. Si renversée, test d\'AGI 15 et 1 round pour se relever.'),
    CapaciteCatalogue(rang: 5, nom: 'Cœur de glace', description: 'Divise par deux tous les DM de froid subis et immunise à la peur.'),
    CapaciteCatalogue(rang: 6, nom: 'Souffle glacial', type: 'A', description: 'Souffle un blizzard dans un cône de 20m. Les victimes subissent [4d4° + INT] DM et sont ralenties pour 1 round (test CON diff [10+INT] pour moitié DM et annuler le ralentissement).'),
    CapaciteCatalogue(rang: 7, nom: 'Présence glaciale', type: 'A', description: 'Transforme son corps en glace (durée [1d6+INT] minutes). Gagne +4 en DEF, immunisé au froid, divise DM de feu par deux. Créatures au contact subissent 1d4° DM. Peut marcher sur l\'eau en la gelant.'),
    CapaciteCatalogue(rang: 8, nom: 'Cryogénisation', type: 'A', description: 'Test opposé d\'attaque magique. La cible est congelée dans un énorme cristal de glace (détruit avec 50 DM). Sinon se brise selon le NC (valeur d\'INT en siècles à rounds). Si cible volontaire, durée = NC 1.'),
  ],
);

const _voie_invocation_majeure = VoieCatalogue(
  id: 'prestige_invocation-majeure',
  nom: 'Voie de l\'Invocation Majeure',
  profil: 'Mages',
  famille: 'Voies de prestige de mage',
  description: 'L\'invocation n\'est pas une magie d\'attaque, mais permet d\'obtenir des miracles. Tous les sorts de cette voie (actions limitées, 1 minute d\'incantation) bénéficient automatiquement de la Concentration (coût = rang - 2 PM).',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Monture fantôme', type: 'L', description: 'Conjure un cheval fantomatique (transporte 2 max) pour [1d4°+INT] heures. Rapide (10 km/h), ignore terrains difficiles. Rang 6: court sur l\'eau. Rang 8: vole.'),
    CapaciteCatalogue(rang: 5, nom: 'Manoir d\'outre-monde', type: 'L', description: 'Enchante une porte existante pour s\'ouvrir sur un manoir magique (durée 1h/niveau). Jusqu\'à 1 pièce/niveau (50m² max). Meublé, mais les objets disparaissent à la sortie. Si sort relancé, l\'ancien disparaît et éjecte les occupants (1d6 DM).'),
    CapaciteCatalogue(rang: 6, nom: 'Navire fantôme', type: 'L', description: 'Invoque un navire fantôme sans équipage (vitesse 20 km/h, max 100 pers.). Disparaît au prochain lever de soleil. Ne peut s\'éloigner d\'un jour des côtes. Rang 8: nef volante.'),
    CapaciteCatalogue(rang: 7, nom: 'Chasseur ailé', type: 'L', description: 'Invoque une créature ailée de grande taille pour 24h. Mission: trouver et rapporter une personne/objet. Traque de façon infaillible (25 km/h). Si échec, devient enragé et attaque l\'invocateur.'),
    CapaciteCatalogue(rang: 8, nom: 'Portail magique', type: 'L', description: 'Une fois par jour, fait apparaître un portail lumineux (max [5+INT] min) relié à un lieu choisi (en vue ou parfaitement connu jusqu\'à [niv x 10 km]). Peut être emprunté dans les deux sens.'),
  ],
);

const _voie_mage_guerre = VoieCatalogue(
  id: 'prestige_mage-guerre',
  nom: 'Voie du Mage de Guerre',
  profil: 'Mages',
  famille: 'Voies de prestige de mage',
  description: 'Requis : connaître au moins trois sorts qui infligent des DM directs (Projectile de mana, Explosion de feu, Foudre, etc.). Les mages de guerre sont de véritables machines à tuer.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Coup au but', type: 'G', description: 'Le personnage ou la cible (portée 10 m) bénéficie d\'un bonus de +10 sur son prochain test d\'attaque contre DEF. Lancé en action de mouvement (M), il coûte seulement 2 PM.'),
    CapaciteCatalogue(rang: 5, nom: 'Explosion différée', type: 'A', description: 'Invoque une bille de feu qui se positionne là où ordonné (max 50m, max 2 coudes à 90°). Explose si touchée, sur mot de commande, après délai fixé ou après INT min. Rayon 5 m, [4d4°+INT] DM (test AGI [10+INT] pour moitié).'),
    CapaciteCatalogue(rang: 6, nom: 'Aura du chef de guerre', type: 'A', description: 'Tous vos alliés dans un rayon de 20 m bénéficient d\'un bonus de +1 en DEF et aux DM pendant INT minutes. À partir du niveau 16, ce bonus passe à +2.'),
    CapaciteCatalogue(rang: 7, nom: 'Épargner les alliés', description: 'Lorsque vous lancez un sort de zone, vous pouvez dépenser 1 PM par allié présent dans la zone que vous souhaitez épargner de l\'effet.'),
    CapaciteCatalogue(rang: 8, nom: 'Vague de feu', type: 'L', description: 'Dresse un mur de feu (3m haut, 20m large, portée 10m). La vague s\'éloigne et parcourt 50 m en infligeant [5d4°+INT] DM (test AGI 15 pour moitié DM).'),
  ],
);

const _voie_magie_esprit = VoieCatalogue(
  id: 'prestige_magie-esprit',
  nom: 'Voie de la Magie de l\'Esprit',
  profil: 'Mages',
  famille: 'Voies de prestige de mage',
  description: 'L\'une des plus terribles magies, forçant le contrôle des pensées et du corps des adversaires.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Esprit impénétrable', type: 'A', description: 'Le personnage ou un allié est immunisé aux détections de mensonges/émotions/scrutation magique (INT heures). +5 aux tests pour cacher émotions et résister aux sorts mentaux.'),
    CapaciteCatalogue(rang: 5, nom: 'Lire les pensées', type: 'A', description: 'Test opposé d\'attaque magique (NC < niveau, portée 20 m). « Entend » les pensées de la cible pendant [1d6+INT] rounds. En combat, le lanceur gagne +3 DEF contre cette cible.'),
    CapaciteCatalogue(rang: 6, nom: 'Prison mentale', type: 'A', description: 'Une fois par combat. Test opposé d\'attaque magique (portée 20m). La cible est enfermée dans un labyrinthe mental. Durée selon NC (NC <= 1: INT jours; NC 4+: 1d6 rounds). Échec automatique si INT cible >= mage.'),
    CapaciteCatalogue(rang: 7, nom: 'Attaque mentale', type: 'A', description: 'Surcharge sensorielle. Test opposé d\'attaque magique. Inflige [5d4°+INT] DM. La cible fait test INT [10+INT]. Si échec : perte de conscience 1d6 rounds (si niv < mage) ou étourdie 1 round.'),
    CapaciteCatalogue(rang: 8, nom: 'Contrôle mental', type: 'A', description: 'Test opposé d\'attaque magique (portée 20m). Prend le contrôle des actions de la cible. Le corps du mage est inactif. Durée selon NC (1d6 rounds pour NC 4+). Échec si INT cible >= mage.'),
  ],
);

const _voie_magie_mots = VoieCatalogue(
  id: 'prestige_magie-mots',
  nom: 'Voie de la Magie des Mots',
  profil: 'Mages',
  famille: 'Voies de prestige de mage',
  description: 'Ceux qui sculptent le monde par la force de leur volonté verbale. Accessible aux bardes.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Chant fascinant', type: 'A', description: 'Fascine créatures humanoïdes et animaux (rayon 20m). NC affecté : 1 (+1 par rang acquis). Les victimes suivent le mage, s\'arrêtent si blessées. Doit maintenir le chant (M/round). Durée max [1d6+INT] min.'),
    CapaciteCatalogue(rang: 5, nom: 'Poids des mots', type: 'L', description: 'Déforme la réalité non encore révélée par un récit. Si le MJ refuse, aucun PM n\'est dépensé.'),
    CapaciteCatalogue(rang: 6, nom: 'Cri de la banshee', type: 'A', description: 'Une fois par jour, cri terrifiant. Rayon 10m. Test CON [10+INT] ou 6d4° DM. Les alliés ont +5 au test. Victimes réduites à 0 PV ont les cheveux qui blanchissent.'),
    CapaciteCatalogue(rang: 7, nom: 'Mot de mana', type: 'L', description: 'Cible portée 20m. Si PV max < 120 : aveuglée 1d4 rounds. Niveau 15+ (Mot d\'étourdissement) : PV max < 100 étourdie 1d4 rounds. Niveau 18+ (Mot de mort) : PV max < 80 meurt. 1/récup rapide.'),
    CapaciteCatalogue(rang: 8, nom: 'Souhait', type: 'L', description: 'Une fois/jour: duplique capacité de rang 1-5. Une fois/aventure: vœu libre (limites fixées par le MJ avec effets secondaires préjudiciables).'),
  ],
);

const _voie_magie_temps = VoieCatalogue(
  id: 'prestige_magie-temps',
  nom: 'Voie de la Magie du Temps',
  profil: 'Mages',
  famille: 'Voies de prestige de mage',
  description: 'Un art subtil et dangereux. Règle du Contretemps: sur échec critique 1, subit un effet secondaire (1d6).',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Fuite en avant', type: 'A', description: 'Se projette dans le futur. Test d\'attaque magique diff [10 + durée en min]. Disparaît et réapparaît à la fin. Si obstacle, subit 1d4° DM.'),
    CapaciteCatalogue(rang: 5, nom: 'Lenteur', type: 'A', description: 'Test opposé d\'attaque magique. Cible de niv >= ralentie 1d4 rounds (sinon 2d4). Si elle résiste, immunisée pour le combat.'),
    CapaciteCatalogue(rang: 6, nom: 'Décalage', type: 'A', description: 'Touche la cible + Test opposé d\'attaque magique. Envoie la cible 1d4° min dans le futur. Elle devient immatérielle et immobile.'),
    CapaciteCatalogue(rang: 7, nom: 'Enkystement lointain', type: 'A', description: 'Une fois par combat. Cible à 20m. Test opposé d\'attaque magique. Téléportée horizontalement de 2d4°x100 km (NC bas) à 2d4°x10 m (NC haut).'),
    CapaciteCatalogue(rang: 8, nom: 'Arrêt du temps', type: 'L', description: 'Arrête le temps pendant [1d4°+INT] rounds. Seul le mage peut agir/se déplacer. Tout contact direct ou magique avec un vivant annule le sort.'),
  ],
);

const _voie_maitre_sorts = VoieCatalogue(
  id: 'prestige_maitre-sorts',
  nom: 'Voie du Maître des Sorts',
  profil: 'Mages',
  famille: 'Voies de prestige de mage',
  description: 'Privilégie le nombre de sorts connus à la puissance, pour toujours avoir la bonne réponse.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Connaissance des arcanes inférieures', description: 'Le personnage apprend deux sorts de rang 1 de magie profane (mages ou barde) de son choix.'),
    CapaciteCatalogue(rang: 5, nom: 'Connaissance des arcanes mineures', description: 'Le personnage apprend deux sorts de rang 2 de magie profane (mages ou barde) de son choix.'),
    CapaciteCatalogue(rang: 6, nom: 'Connaissance des arcanes supérieures', description: 'Le personnage apprend deux sorts de rang 3 de magie profane (mages ou barde) de son choix.'),
    CapaciteCatalogue(rang: 7, nom: 'Connaissance des arcanes majeures', description: 'Le personnage apprend deux sorts de rang 4 de magie profane (mages ou barde) de son choix.'),
    CapaciteCatalogue(rang: 8, nom: 'Connaissance des arcanes suprêmes', description: 'Le personnage apprend deux sorts de rang 5 de magie profane (mages ou barde) de son choix.'),
  ],
);

const _voie_vision = VoieCatalogue(
  id: 'prestige_vision',
  nom: 'Voie de la Vision',
  profil: 'Mages',
  famille: 'Voies de prestige de mage',
  description: 'Voir et ne pas être vu. Requis : voie de la magie universelle, divination, illusions ou sombre magie.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Cécité', type: 'A', description: 'Test opposé d\'attaque magique (portée 20m). La cible est aveuglée (-5 Init, Att, DEF, -10 attaque à distance). Durée 1d6 rounds si NC < niv du lanceur, sinon 1 round.'),
    CapaciteCatalogue(rang: 5, nom: 'Œil magique', type: 'A', description: 'Détache son œil (vol 10m) pour explorer (durée INT min). DEF 20, 1 PV. Si détruit, le mage perd 1d6 PV (l\'œil repousse).'),
    CapaciteCatalogue(rang: 6, nom: 'Motif hypnotique', type: 'A', description: 'Crée un tableau hypnotique dans le ciel (portée 20m). Test INT diff [12+INT] ou la cible contemple le tableau. Affecte créatures de NC < rang. Durée INT min.'),
    CapaciteCatalogue(rang: 7, nom: 'Vision de la vérité', type: 'A', description: 'Voit à travers illusions et invisibilité (INT min). En action de mouvement, test opposé d\'attaque magique pour connaître le niveau, PV et pouvoirs d\'une créature (20m).'),
    CapaciteCatalogue(rang: 8, nom: 'Invisibilité supérieure', type: 'A', description: 'Au choix : invisibilité de zone (mage + INT alliés) pour [1d4°+INT] min, OU invisibilité supérieure sur soi-même (reste invisible même en attaquant, adversaires aveuglés).'),
  ],
);

const _voie_elementaire_feu = VoieCatalogue(
  id: 'prestige_elementaire-feu',
  nom: 'Voie Élémentaire du Feu',
  profil: 'Mystiques',
  famille: 'Voies de prestige de mystique',
  description: 'Les voies élémentaires ont tendance à changer profondément ceux qui les suivent, tant physiquement que mentalement. Dans le cas du feu, les cheveux deviennent roux, les ongles noircissent, tandis que le tempérament devient plus explosif.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Mur de feu', type: 'A', description: 'Le personnage peut créer un mur de feu rectiligne de 20 m de long pour 4 m de haut (portée 20 m, épaisseur 30 cm). Toute créature qui franchit le mur subit [2d4° + CHA] DM de feu. Le sort a une durée de CHA minutes.'),
    CapaciteCatalogue(rang: 5, nom: 'Tornade de feu', type: 'A', description: 'Le personnage invoque une colonne de feu (portée 20 m) qui inflige [4d4° + CHA] DM à la cible sur un test d\'attaque magique réussi contre DEF. Les DM sont doublés contre les morts-vivants et les démons.'),
    CapaciteCatalogue(rang: 6, nom: 'Insensible au feu', description: 'Le personnage devient insensible aux DM de feu et il divise par deux les DM de froid.'),
    CapaciteCatalogue(rang: 7, nom: 'Immolation', type: 'A', description: 'Le personnage s\'immole dans une aura de flammes vives pendant CHA minutes. Il est immunisé aux DM de feu et inflige 1d4° DM de feu à tout attaquant qui réussit à le blesser avec une arme, 2d4° s\'il s\'agit d\'une arme naturelle.'),
    CapaciteCatalogue(rang: 8, nom: 'Forme élémentaire de feu', type: 'A', description: 'Une fois par jour, le personnage peut se transformer en élémentaire de feu (taille grand), pendant un maximum de CHA minutes. Ne peut pas parler, utilise uniquement les capacités de la voie, profite en permanence de Insensible au feu et Immolation. AGI +3*, Frappe [2d4°+5 DM de feu].'),
  ],
);

// ── TOUT PROFIL ──────────────────────────────────────────────────────────────

const _voie_expert = VoieCatalogue(
  id: 'prestige_expert',
  nom: 'Voie de l\'Expert',
  profil: 'Tout profil',
  famille: 'Voies de prestige génériques',
  description: 'Prérequis : Avoir acquis le rang 2 dans au moins 3 voies du profil. Permet d\'acquérir les capacités des autres profils de sa famille.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Capacité de néophyte', description: 'Choisissez une capacité de rang 1 de n\'importe quelle voie issue d\'un profil de votre famille.'),
    CapaciteCatalogue(rang: 5, nom: 'Capacité d\'initié', description: 'Choisissez une capacité de rang 2 de n\'importe quelle voie issue d\'un profil de votre famille.'),
    CapaciteCatalogue(rang: 6, nom: 'Capacité de professionnel', description: 'Choisissez une capacité de rang 3 de n\'importe quelle voie issue d\'un profil de votre famille.'),
    CapaciteCatalogue(rang: 7, nom: 'Capacité d\'expert', description: 'Choisissez une capacité de rang 4 de n\'importe quelle voie issue d\'un profil de votre famille.'),
    CapaciteCatalogue(rang: 8, nom: 'Capacité de maître', description: 'Choisissez une capacité de rang 5 de n\'importe quelle voie issue d\'un profil de votre famille.'),
  ],
);

const _voie_familier_fantastique = VoieCatalogue(
  id: 'prestige_familier-fantastique',
  nom: 'Voie du Familier Fantastique',
  profil: 'Tout profil',
  famille: 'Voies de prestige génériques',
  description: 'Prérequis : S\'être attaché les services d\'un familier. Exception : Les rangs vont de 3 à 7 au lieu de 4 à 8.',
  capacites: [
    CapaciteCatalogue(rang: 3, nom: 'Familier fantastique', type: 'A', description: 'Le personnage fait l\'acquisition d\'un familier fantastique (Animal céleste, Mort-vivant, Araignée géante, etc.). Le personnage peut utiliser les sens de son familier et communiquer avec lui à distance illimitée.'),
    CapaciteCatalogue(rang: 4, nom: 'Pouvoir mineur', description: 'Le familier confère au personnage un pouvoir magique mineur dépendant de sa nature.'),
    CapaciteCatalogue(rang: 5, nom: 'Résistance', description: 'Le familier obtient une RD de 1 par rang. De plus, le personnage apprend un sort de rang 1 ou 2 d\'un profil de magie lié au familier.'),
    CapaciteCatalogue(rang: 6, nom: 'Inséparables', type: 'M', description: 'Le familier est téléporté sur son maître au prix d\'une action de mouvement. Confère 1 PC supplémentaire.'),
    CapaciteCatalogue(rang: 7, nom: 'Pouvoir supérieur', description: 'Le familier confère au personnage un second pouvoir magique ainsi qu\'un bonus de +1 sur une caractéristique liée au familier.'),
  ],
);

const _voie_lycanthrope = VoieCatalogue(
  id: 'prestige_lycanthrope',
  nom: 'Voie du Lycanthrope',
  profil: 'Tout profil',
  famille: 'Voies de prestige génériques',
  description: 'Prérequis : Avoir été mordu par un lycanthrope. La lycanthropie donne 5 PV par niveau.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Forme hybride', type: 'L', description: 'Transformation en hybride pour 1 min (1 fois / récup. rapide). Gain d\'une attaque de morsure [1d4°+FOR] en action gratuite.'),
    CapaciteCatalogue(rang: 5, nom: 'Transformation en loup', type: 'L', description: 'Transformation en loup (FOR+3, AGI+1, Init 15, DM 1d4+3, RD 5 non argent) pour 1 h par rang / jour.'),
    CapaciteCatalogue(rang: 6, nom: 'Éventration', description: 'Sous forme hybride ou de loup, un 15-20 sur l\'attaque de morsure ajoute +1d4° aux DM.'),
    CapaciteCatalogue(rang: 7, nom: 'Résistance surnaturelle', description: 'Sous forme hybride, le lycanthrope réduit de 5 les DM infligés par des armes qui ne sont pas en argent.'),
    CapaciteCatalogue(rang: 8, nom: 'Forme puissante', description: 'Augmente la FOR de +2 sous forme de loup ou d\'hybride (+2 en attaque et DM au contact).'),
  ],
);

const _voie_sang_dragon = VoieCatalogue(
  id: 'prestige_sang-dragon',
  nom: 'Voie du Sang-Dragon',
  profil: 'Tout profil',
  famille: 'Voies de prestige génériques',
  description: 'Cet héritage peut sommeiller durant plusieurs générations et ressurgir sans explication.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Ascendance draconique', description: 'Choisissez une couleur de dragon. Il obtient une réduction des DM de 5 (qui passe à 10 au rang 8), correspondant au type d\'énergie utilisé par le souffle du dragon. De plus, il voit dans le noir total comme dans la pénombre jusqu\'à 20 m.'),
    CapaciteCatalogue(rang: 5, nom: 'Griffes du dragon', type: 'L', description: 'Une fois par combat, pendant [rang] rounds, griffes au bout de ses doigts : +2 en FOR et une attaque de griffes par round en action gratuite (G) infligeant [1d6°+FOR] DM.'),
    CapaciteCatalogue(rang: 6, nom: 'Souffle du dragon', type: 'L', description: 'Une fois par combat, produit un souffle (cône 5 m long/large). 5d4° DM (moitié si test d\'AGI [8 + rang]).'),
    CapaciteCatalogue(rang: 7, nom: 'Ailes de dragon', type: 'L', description: 'Une fois par combat, déploie des ailes de dragon pendant CON minutes (min 1 min). Vitesse de vol 15 m.'),
    CapaciteCatalogue(rang: 8, nom: 'Écailles de dragon', description: 'Lorsque le personnage passe sous la moitié de ses PV, il gagne une réduction des DM de 5 face à tous les types de dommages.'),
  ],
);

const _voie_specialiste = VoieCatalogue(
  id: 'prestige_specialiste',
  nom: 'Voie du Spécialiste',
  profil: 'Tout profil',
  famille: 'Voies de prestige génériques',
  description: 'Prérequis : Avoir acquis le rang 4 dans la voie à laquelle s\'appliquera la voie du spécialiste.',
  capacites: [
    CapaciteCatalogue(rang: 4, nom: 'Expertise', description: 'Le personnage peut choisir entre un bonus de +1 en attaque pour une capacité spécifique, ou un bonus de +5 sur une compétence acquise par une capacité.'),
    CapaciteCatalogue(rang: 5, nom: 'Capacité fabuleuse', description: 'Désormais, il lui suffit d\'une action d\'attaque pour utiliser une capacité limitée spécifique. S\'il s\'agit d\'un sort en action d\'attaque, il peut bénéficier de la concentration sans prendre une action limitée.'),
    CapaciteCatalogue(rang: 6, nom: 'Caractéristique fabuleuse', description: 'Le joueur augmente de +1 la valeur de sa plus haute caractéristique. De plus, un résultat de 1 sur cette caractéristique peut être relancé.'),
    CapaciteCatalogue(rang: 7, nom: 'Capacité supérieure', description: 'Le joueur choisit une capacité. Lorsqu\'il l\'utilise, il ajoute +1d4° aux DM produits une fois par round.'),
    CapaciteCatalogue(rang: 8, nom: 'Capacité signature', description: 'Une fois par combat, il peut utiliser une capacité choisie en plus de ses actions normales à son tour, sans les limitations de fréquence (le coût en PM s\'applique).'),
  ],
);



// ── MAP GLOBALE POUR L'AFFICHAGE ─────────────────────────────────────────────

const kVoiesDePrestigeParProfil = <String, List<VoieCatalogue>>{
  'Aventuriers': [
    _voie_archer_arcanique,
    _voie_casse_cou,
    _voie_chasseur_de_prime,
    _voie_duelliste,
    _voie_espion,
    _voie_flibustier,
    _voie_heros,
    _voie_maitre_poisons,
    _voie_ombres,
    _voie_pacte_feerique,
    _voie_touche_a_tout,
    _voie_tueur_gages,
  ],
  'Combattants': [
    _voie_arme_liee,
    _voie_armes_deux_mains,
    _voie_chevalier_dragon,
    _voie_colosse,
    _voie_combat_du_mal,
    _voie_combattant_des_tunnels,
    _voie_danseur_de_guerre,
    _voie_ecorcheur,
    _voie_guerrier_mage,
    _voie_ours,
    _voie_porteur_bouclier,
    _voie_tueur_geants,
  ],
  'Mages': [
    _voie_archimage,
    _voie_chaos,
    _voie_cristaux,
    _voie_elementaliste,
    _voie_enchanteur,
    _voie_gel,
    _voie_invocation_majeure,
    _voie_mage_guerre,
    _voie_magie_esprit,
    _voie_magie_mots,
    _voie_magie_temps,
    _voie_maitre_sorts,
    _voie_vision,
  ],
  'Mystiques': [
    _voie_armure_sacree,
    _voie_changeforme,
    _voie_combat_mystique,
    _voie_elementaire_air,
    _voie_elementaire_eau,
    _voie_elementaire_feu,
    _voie_elementaire_terre,
    _voie_guerisseur,
    _voie_maitre_nature,
    _voie_saisons,
    _voie_templier,
    _voie_vermines,
  ],
  'Tout profil': [
    _voie_expert,
    _voie_familier_fantastique,
    _voie_lycanthrope,
    _voie_sang_dragon,
    _voie_specialiste,
  ],
};