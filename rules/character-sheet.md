# Fiche de Personnage — Chroniques Oubliées Fantasy v2

---

## En-tête

| Champ  | Type        | Description                                     |
|--------|-------------|-------------------------------------------------|
| Nom    | Texte libre | Nom du personnage                               |
| Niveau | Entier      | Niveau actuel du personnage                     |
| Race   | Sélection   | Race du personnage (ex : Humain, Elfe, Nain…)  |
| Profil | Sélection   | Classe du personnage (ex : Guerrier, Rôdeur…)  |

> Un portrait (image) peut être associé à la Race et au Profil.

---

## Onglets

| # | Onglet            | Description                                        |
|---|-------------------|----------------------------------------------------|
| 1 | Description       | Informations narratives et biographiques           |
| 2 | Caractéristiques  | Stats de base et valeurs de combat                 |
| 3 | Combat            | Détails des équipements et armes                   |
| 4 | Inventaire        | Objets portés                                      |
| 5 | Voies & Capacités | Capacités spéciales et voies de progression        |
| 6 | Effets            | Effets actifs sur le personnage                    |

---

## Onglet : Caractéristiques

### 1. Caractéristiques (CARAC.)

7 caractéristiques fondamentales. Chaque ligne dispose d'une **case à cocher** et de trois colonnes calculées.

| Abrév. | Nom complet  | Description                                  |
|--------|--------------|----------------------------------------------|
| AGI    | Agilité      | Réflexes, esquive, précision physique        |
| CON    | Constitution | Endurance, résistance physique               |
| FOR    | Force        | Puissance physique, dégâts en corps à corps  |
| PER    | Perception   | Acuité sensorielle, vigilance                |
| CHA    | Charisme     | Présence sociale, leadership                 |
| INT    | Intelligence | Savoir, mémoire, magie apprise               |
| VOL    | Volonté      | Résistance mentale, détermination            |

**Colonnes :**

| Colonne | Description                                            |
|---------|--------------------------------------------------------|
| Valeur  | Modificateur de base du personnage (peut être négatif) |
| Racial  | Bonus apporté par la race                              |
| Total   | `Valeur + Racial`                                      |

---

### 2. Attaque

3 types d'attaque disponibles.

| Type     | Description                              |
|----------|------------------------------------------|
| CONTACT  | Attaque au corps à corps                 |
| DISTANCE | Attaque à distance (arc, arbalète…)      |
| MAGIQUE  | Attaque par sort ou magie                |

**Colonnes :**

| Colonne | Description                   |
|---------|-------------------------------|
| Base    | Valeur de base du bonus       |
| Bonus   | Bonus additionnels            |
| Malus   | Malus à soustraire            |
| Total   | `Base + Bonus - Malus`        |

---

### 3. Combat

| Stat       | Description                                        |
|------------|----------------------------------------------------|
| Initiative | Détermine l'ordre de passage en combat             |

**Colonnes :** Base · Bonus · Malus · Total (`Base + Bonus - Malus`)

---

### 4. Vitalité — PV (Points de Vie)

| Champ  | Description                                                |
|--------|------------------------------------------------------------|
| DV     | Dé de Vie utilisé pour calculer les PV (ex : 1d6, 1d8…)  |
| Base   | PV de base, calculés selon le niveau et le DV              |
| Bonus  | Bonus additionnels aux PV                                  |
| Max    | Maximum de PV (`Base + Bonus`)                             |
| Actuel | PV actuels du personnage, modifiable en cours de partie   |

---

### 5. Récupération — DR (Dés de Récupération)

| Champ  | Description                                       |
|--------|---------------------------------------------------|
| Base   | Nombre de dés de récupération de base             |
| Bonus  | Bonus additionnels                                |
| Max    | Maximum de DR disponibles (`Base + Bonus`)        |
| Actuel | DR restants, modifiable en cours de partie        |

---

### 6. Défense

| Stat | Description                                                         |
|------|---------------------------------------------------------------------|
| DEF  | Valeur de défense globale (`Base + Bonus - Malus`)                  |
| RD   | Réduction des Dégâts : dégâts absorbés avant application            |

**Colonnes :** Base · Bonus · Malus · Total (`Base + Bonus - Malus`)

---

### 7. Ressources

| Ressource        | Abrév. | Description                                               |
|------------------|--------|-----------------------------------------------------------|
| Points de Magie  | PM     | Ressource consommée pour lancer des sorts                 |
| Points de Chance | PC     | Permet de relancer des dés ou d'éviter un échec critique  |

**Colonnes :** Base · Bonus · Max (`Base + Bonus`) · Actuel

---

### 8. Encombrement

Malus global lié au poids de l'équipement porté. Une valeur négative indique une pénalité.

| Colonne | Description                          |
|---------|--------------------------------------|
| Armure  | Malus apporté par l'armure portée    |
| Autre   | Malus apporté par les autres objets  |
| Total   | `Armure + Autre`                     |

---

## Règles de calcul

| Champ               | Formule                        |
|---------------------|--------------------------------|
| Total CARAC.        | `Valeur + Racial`              |
| Attaque Total       | `Base + Bonus - Malus`         |
| Initiative Total    | `Base + Bonus - Malus`         |
| PV Max              | `Base + Bonus`                 |
| DR Max              | `Base + Bonus`                 |
| DEF Total           | `Base + Bonus - Malus`         |
| PM / PC Max         | `Base + Bonus`                 |
| Encombrement Total  | `Armure + Autre`               |
