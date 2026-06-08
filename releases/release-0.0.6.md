🚀 CO Compagnon V2 — Notes de version v0.0.6
Cette mise à jour majeure résout définitivement les instabilités d'authentification et pose les bases d'une synchronisation multiplateforme unifiée et sécurisée entre le Web (GitHub Pages), le Mobile et notre serveur de données.

🛠️ Quoi de neuf dans la v0.0.6 ?
🌐 Authentification Google Web & Mobile unifiée
Correctif du gel de l'application sur le Web : Remplacement des anciennes API d'authentification Google obsolètes qui provoquaient un blocage infini du navigateur après la sélection du compte.

Architecture Hybride (idToken / accessToken) : L'application s'adapte désormais aux exigences de sécurité de chaque plateforme :

Émission et validation d'un idToken (JWT) natif sur Android & iOS.

Récupération automatique et sécurisée d'un accessToken (ya29.) sur le Web pour s'affranchir des restrictions de partage d'identifiants locaux (CORS et Cross-Origin-Opener-Policy).

⚡ Refonte de l'infrastructure de synchronisation (Cloudflare Worker)
Passage du Worker en mode Hybride : Notre Worker Cloudflare a été mis à niveau pour accepter et discriminer à la volée les jetons mobiles et les jetons web.

Validation Directe Google API : Pour les utilisateurs web, le Worker interroge désormais les serveurs d'authentification de Google en temps réel pour valider de manière infalsifiable l'identité et l'adresse e-mail du joueur.

Résolution de l'erreur 401 Unauthorized : Fin des rejets de requêtes intempestifs lors de la récupération de la liste des personnages (/sync/list).

📦 Optimisations de l'application Flutter
Migration vers le stockage persistant Web : Remplacement de FlutterSecureStorage par SharedPreferences sur le navigateur pour garantir une persistance des sessions de connexion 100 % fiable, sans latence de lecture.

Pattern Singleton pour AuthService : Le service d'authentification a été transformé en instance unique partagée (Singleton) pour éviter les décalages d'état mémoire entre les écrans de l'interface et les requêtes du service réseau (RemoteCharacterService).

Sécurisation des en-têtes HTTP : Ajout de verrous de contrôle asynchrones empêchant l'envoi de requêtes réseau si le jeton d'authentification n'est pas intégralement chargé ou s'il est corrompu.

🔧 Informations techniques & Déploiement
Version Flutter cible : 3.29.3 (Stable channel)

Nouveau package requis : shared_preferences ajouté aux dépendances.

Déploiement Worker : Validé via wrangler deploy.

Script de build CI/CD mis à jour : Prise en charge transparente de l'injection des variables d'environnement (SYNC_API_BASE_URL) pour les déploiements automatisés GitHub Pages.