# 🚀 CO Compagnon V2 — Notes de version `v0.0.6`

![Flutter](https://img.shields.io/badge/Flutter-3.29.3-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Cloudflare Workers](https://img.shields.io/badge/Cloudflare_Workers-Neon_DB-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)
![Status](https://img.shields.io/badge/Status-Stable-success?style=for-the-badge)

Cette mise à jour majeure résout définitivement les instabilités critiques d'authentification sur les environnements distribués et pose les bases d'une synchronisation multiplateforme unifiée et sécurisée entre le **Web (GitHub Pages)**, le **Mobile**, et notre infrastructure backend.

---

## 🛠️ Quoi de neuf ?

### 🌐 1. Authentification Google Web & Mobile Unifiée
Le plugin d'authentification a subi une refonte complète pour corriger le blocage infini du navigateur après la sélection du compte Google en production. L'application implémente désormais une **architecture de jetons hybride** qui s'adapte dynamiquement aux politiques de sécurité de chaque plateforme.

#### 📊 Matrice de gestion des Jetons (Tokens)

| Plateforme | Type de Jeton utilisé | Mécanisme de Stockage | Contraintes de sécurité résolues |
| :--- | :--- | :--- | :--- |
| **Android / iOS** | `idToken` (JWT natif) | `FlutterSecureStorage` | Chiffrement matériel local (Keystore/Keychain) |
| **Web (GitHub Pages)** | `accessToken` (`ya29.`) | `SharedPreferences` | Contournement des politiques strictes `CORS` & `COOP` |

---

### ⚡ 2. Refonte de la Synchronisation Backend (Cloudflare Worker)
Notre API de synchronisation a été mise à niveau pour valider de manière agnostique les flux d'identification Web et Mobile.

* **Mode Hybride :** Le Worker accepte l' `idToken` (validation via clés cryptographiques asymétriques JWKS) **OU** l' `accessToken` (validation directe en temps réel auprès de l'API OAuth2 de Google).
* **Éradication de l'erreur `401 (Unauthorized)` :** Résolution définitive du bug qui bloquait les requêtes d'initialisation de profil et de récupération de la liste des personnages (`/sync/list`).
* **Brouillard de guerre préservé :** Les calculs d'exposition des caractéristiques des monstres restent inchangés pour le mode spectateur.

---

### 📦 3. Optimisations Architecturales (Flutter)
Afin d'éviter les désynchronisations d'état mémoire ("Race Conditions") sur les builds de production, trois changements structurels majeurs ont été injectés :

* **Pattern Singleton pour `AuthService` :** Garantie qu'une seule instance globale gère et distribue le jeton à travers toute l'application.
* **Sécurisation Asynchrone des Requêtes :** Blocage préventif des requêtes HTTP sortantes si le jeton est en cours d'écriture ou considéré comme corrompu.
* **Validation d'écriture Web :** Ajout d'un verrou de confirmation immédiate après l'appel à `SharedPreferences.getInstance()`.

```mermaid
graph LR
    A[RemoteCharacterService] -->|Demande asynchrone| B(AuthService Singleton)
    B -->|Si Web| C[SharedPreferences]
    B -->|Si Mobile| D[FlutterSecureStorage]
    C -->|Jeton ya29.| E[Worker Cloudflare]
    D -->|Jeton JWT| E