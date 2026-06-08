# 📜 Notes de mise à jour — CO Compagnon V2 `v0.0.5`

![Flutter](https://img.shields.io/badge/Flutter-3.29.3-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Database](https://img.shields.io/badge/SQLite-Neon_Cloud-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![Status](https://img.shields.io/badge/Status-Legacy-orange?style=for-the-badge)

Une mise à jour majeure axée sur le **partage en temps réel**, la **sécurité des salons** et le **confort de jeu du MJ**. Vos tables de *Chroniques Oubliées V2* n'ont jamais été aussi connectées et immersives !

---

## 🚀 Nouvelles Fonctionnalités

### 📺 1. Mode Spectateur & Brouillard de Guerre en Temps Réel
Les joueurs peuvent désormais suivre le déroulement tactique du combat en direct depuis leur propre écran. Plus besoin de couper le rythme de la partie pour demander *"C'est à qui ?"* ou *"Le gobelin est bientôt mort ?"*.

#### 👁️ Gestion adaptative de l'affichage (Fog of War)

| Type de Participant | Informations visibles par les Joueurs | Impact sur la table |
| :--- | :--- | :--- |
| **🛡️ Aventuriers (Alliés)** | Santé précise (PV exacts), Classe d'Armure (DEF) et Altérations d'état. | Transparence totale et stratégie d'équipe facilitée. |
| **👹 Créatures (Ennemis)** | Santé narrative uniquement (*Indemne, Égratigné, Blessé, Agonisant...*). | Préservation du mystère et de la tension du combat. |

---

### 🎰 2. Sécurisation des Salons par Codes Uniques
Oubliez les configurations réseau complexes. Le système de salon a été simplifié à l'extrême pour garantir un accès rapide et sécurisé.
* **Génération à la volée :** Chaque session de combat génère instantanément un code d'accès unique et sécurisé à 6 caractères alphanumeric (ex: `X9R2A4`).
* **Visibilité MJ :** Le code reste affiché en permanence en haut de l'écran du Maître de Jeu, prêt à être dicté en un clin d'œil à un joueur qui rejoint la table en cours de route.

---

### ⏪ 3. Système d'Analyse Temporelle : Le Bouton "Undo"
Une erreur de manipulation est vite arrivée derrière l'écran du MJ.
* **Retour dans le passé :** En cas de clic accidentel sur *"Nouveau tour"*, un bouton **Undo** (Retour) apparaît dynamiquement.
* **Restauration d'état :** Il permet de revenir instantanément au tour précédent, de réajuster l'index actif ainsi que les PV modifiés par erreur, tout en synchronisant immédiatement l'affichage de tous les joueurs connectés.

---

## 🎨 Améliorations de l'Interface (UI/UX)

* **Intégration des États :** Les altérations d'état infligées par le MJ (*Paralysé, Aveuglé, Béni...*) ainsi que leurs compteurs de tours restants s'affichent désormais en temps réel sur l'interface des spectateurs.
* **Suivi des Versions :** Le numéro de version officiel de l'application est maintenant visible discrètement en bas de l'écran d'accueil pour faciliter les retours de bugs.
* **Polissage Cosmétique :** Nettoyage global des labels système de l'application sur le lanceur du téléphone (adieu les vilains "_" informatiques pour un rendu épuré).

---

## 🔧 Coulisses & Corrections de Bugs

* **Fix de l'Initiative Réelle :** Correction d'un bug critique où le mode spectateur affichait l'initiative de base statique des participants au lieu du score final calculé et modifié par le jet de dé au lancement du combat (`1d6 + base`).
* **Optimisation de la structure SQL :** Consolidation des scripts de migration de la base de données SQLite locale pour garantir la rétrocompatibilité des fiches de personnages avec les architectures cloud des versions suivantes.