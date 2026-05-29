# Règles de création de personnage — Chroniques Oubliées Fantasy v2

---

## 1. Peuples

| Peuple      | Bonus                                      | Malus              | Profils typiques                  |
|-------------|--------------------------------------------|--------------------|-----------------------------------|
| Demi-elfe   | +1 PER ou CHA                              | -1 FOR ou CON      | Barde, Prêtre                     |
| Demi-orc    | +1 FOR ou CON                              | -1 CHA ou INT      | Barbare, Guerrier                 |
| Elfe haut   | +1 INT ou CHA                              | -1 FOR             | Barde, Magicien, Ensorceleur      |
| Elfe sylvain| +1 AGI ou PER                              | -1 FOR             | Druide, Rôdeur                    |
| Gnome       | +1 INT ou PER                              | -1 FOR             | Forgesort, Arquebusier            |
| Halfelin    | +1 AGI ou VOL                              | -1 FOR             | Voleur, Rôdeur                    |
| Humain      | +1 à l'une des deux plus faibles carac.    | Aucun              | Tous                              |
| Nain        | +1 CON ou VOL                              | -1 AGI             | Guerrier, Prêtre                  |

---

## 2. Caractéristiques

Le personnage est défini par **7 caractéristiques** (4 physiques, 3 mentales). À la création, chaque valeur est comprise entre **-2 et +5**.

### Caractéristiques physiques

| Abrév. | Nom          | Description                                                                                          | Actions type                                                                              |
|--------|--------------|------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------|
| AGI    | Agilité      | Coordination, vitesse, souplesse, réflexes, dextérité                                               | Acrobaties, équilibre, grimper, sauter, discrétion, crochetage, esquive, attaque distance |
| CON    | Constitution | Santé, vitalité, résistance, endurance                                                               | Résister aux éléments, fatigue, poisons, privations, encaisser des blessures              |
| FOR    | Force        | Puissance physique et musculaire, liée au gabarit                                                    | Bras de fer, soulever, lancer, immobiliser, attaque au contact, dégâts                   |
| PER    | Perception   | Les cinq sens, intuition, capacité à percevoir les émotions. Détermine l'ordre d'action en combat   | Vigilance, observer, pister, deviner, ressentir, magie druidique                          |

### Caractéristiques mentales

| Abrév. | Nom          | Description                                                                                         | Actions type                                                                          |
|--------|--------------|-----------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| CHA    | Charisme     | Persuasion, personnalité, séduction, destinée. Détermine les points de chance                      | Bluffer, mentir, négocier, séduire, intimider, magie innée/divine (barde, prêtre…)   |
| INT    | Intelligence | Érudition, mémoire, apprentissage, raisonnement. Un INT négatif = ne sait ni lire ni écrire        | Raisonner, apprendre, rechercher, magie profane (magicien, forgesort, sorcier)        |
| VOL    | Volonté      | Force de caractère, courage, énergie interne. Détermine l'attaque magique et les points de mana   | Résister à la magie ou à la peur                                                      |

### Séries de répartition

Répartissez les 7 valeurs de la série choisie librement entre les caractéristiques.  
> Il est conseillé d'affecter les 3 meilleures valeurs aux caractéristiques associées au profil.

| Série        | Valeurs                               |
|--------------|---------------------------------------|
| Polyvalent   | +2, +2, +2, +1, +1, +0, -1           |
| Expert       | +3, +2, +1, +1, +0, +0, -1           |
| Spécialiste  | +4, +2, +1, +0, +0, -1, -1           |

> **Magie :** si vous voulez pratiquer la magie, mettez au moins +1 dans la caractéristique de magie correspondante :
> - INT → Magicien, Forgesort, Sorcier
> - CHA → Ensorceleur, Barde, Prêtre
> - PER → Druide

---

## 3. Voies et Capacités

À la création, le personnage reçoit **3 voies** et obtient automatiquement la capacité de **rang 1** dans chacune.

- **2 voies** à choisir parmi les 5 voies du profil
- **1 voie de peuple** attribuée automatiquement selon le peuple choisi

### Cas particulier — Mages

En plus de leurs deux capacités de rang 1, les personnages mages peuvent choisir **l'une des deux options** suivantes :

- Obtenir une capacité de **rang 2** dans l'une des deux voies de profil choisies
- Obtenir le **rang 2 de la voie du mage**

> La **voie du mage** peut remplacer la voie de peuple. Le personnage bénéficie tout de même des effets du rang 1 de sa voie de peuple (cochable sur la fiche), mais ne peut pas acquérir les rangs suivants.  
> Il est possible d'obtenir le rang 2 de la voie du mage (*Maîtrise de la magie*) dès le niveau 1 en utilisant le point de capacité supplémentaire des mages.

---

## 4. Valeurs calculées à la création

### Points de Vie (PV)

| Niveau     | Formule                                  |
|------------|------------------------------------------|
| Niveau 1   | `(2 × PV famille) + CON`                |
| Niveau N+1 | `PV famille + CON` par niveau gagné     |

### Dés de Récupération (DR)

| Profil    | Formule de base   |
|-----------|-------------------|
| Standard  | `2 + CON` DR      |
| Mystique  | `3 + CON` DR      |

> **Cas particulier :** un personnage avec -2 en CON n'a aucun DR (2 - 2 = 0). Il ne peut se soigner qu'avec une récupération complète et doit toujours lancer le dé (pas de résultat maximal automatique).

### Points de Chance (PC)

| Profil      | Formule          |
|-------------|------------------|
| Standard    | `2 + CHA` PC     |
| Aventurier  | `3 + CHA` PC     |

### Points de Mana (PM)

> Nécessite au moins une capacité marquée d'un `*` (sort).

```
PM = VOL + nombre de sorts appris
```

### Initiative

```
Initiative de base = 10 + PER
```

### Défense (DEF)

```
DEF = 10 + AGI + modificateurs (capacités, armure…)
```

### Valeurs d'Attaque

```
Attaque au contact = niveau + FOR
Attaque à distance = niveau + AGI
Attaque magique    = niveau + VOL
```

### Dommages (DM)

- **Contact :** FOR s'ajoute aux DM
- **Distance :** aucune valeur ajoutée
- **Magique :** bonus aux DM précisé dans la description de la capacité

---

## 5. Familles de profils

### Aventuriers

| Champ                 | Valeur    |
|-----------------------|-----------|
| PV de la famille      | 4         |
| Dé de récupération    | d8        |
| Bonus                 | +1 PC     |

### Combattants

| Champ                 | Valeur    |
|-----------------------|-----------|
| PV de la famille      | 5         |
| Dé de récupération    | d10       |
| Bonus                 | Aucun     |

**Profils :** Barbare · Chevalier · Guerrier

### Mages

| Champ                 | Valeur                                                              |
|-----------------------|---------------------------------------------------------------------|
| PV de la famille      | 3                                                                   |
| Dé de récupération    | d6                                                                  |
| Bonus                 | Peut choisir une capacité de rang 2 gratuitement à la création     |

**Profils :** Ensorceleur · Forgesort · Magicien · Sorcier

### Mystiques

| Champ                 | Valeur    |
|-----------------------|-----------|
| PV de la famille      | 4         |
| Dé de récupération    | d8        |
| Bonus                 | +1 DR     |

**Profils :** Druide · Moine · Prêtre

---

## 6. Équipement de départ

Chaque personnage débute avec un **sac d'aventurier** contenant :

- Une couverture
- Une torche
- Un briquet à silex
- Une outre
- Une gamelle
- Une bourse de `2d6` pièces d'argent (pa)

> Chaque personnage reçoit également un équipement supplémentaire indiqué dans la description de son profil.
