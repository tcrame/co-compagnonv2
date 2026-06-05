# co_compagnon_v2

Application Flutter pour COF2 (combat tracker, bestiaire, fiches personnages).

## Synchronisation personnages (Neon)

La synchronisation cloud fonctionne via une API HTTPS (Cloudflare Worker) qui
parle à Neon PostgreSQL. Le client Flutter ne stocke aucun secret PostgreSQL.

nom du worker : co-compagnon-sync.crame-teddy.workers.dev

### 1. Déployer le Worker de sync

```bash
cd sync_worker
npm install
npx wrangler secret put DATABASE_URL
npx wrangler deploy
```

Le Worker expose:
- `POST /sync/push`
- `POST /sync/pull`
- `POST /sync/list`

### 2. Lancer l'app Flutter avec l'URL API

```bash
fvm flutter run --dart-define=SYNC_API_BASE_URL=https://<votre-worker>.workers.dev
```

Sans `SYNC_API_BASE_URL`, les boutons cloud sont désactivés.

### 3. Commandes utiles (dev)

#### Voir devices / émulateurs

```bash
fvm flutter devices
fvm flutter emulators
```

#### Lancer un émulateur Android

```bash
fvm flutter emulators --launch Medium_Phone_API_36.0
```

#### Lancer l'app sur émulateur Android

```bash
fvm flutter run -d emulator-5554 --dart-define=SYNC_API_BASE_URL=https://co-compagnon-sync.crame-teddy.workers.dev
```

#### Lancer l'app sur mobile Android branché

```bash
fvm flutter devices
fvm flutter run -d <device_id_android> --dart-define=SYNC_API_BASE_URL=https://co-compagnon-sync.crame-teddy.workers.dev
```

Exemple device id réel:

```bash
fvm flutter run -d 4B101JEKB01839 --dart-define=SYNC_API_BASE_URL=https://co-compagnon-sync.crame-teddy.workers.dev
fvm flutter run -d RF8N31XXMHB --dart-define=SYNC_API_BASE_URL=https://co-compagnon-sync.crame-teddy.workers.dev
```

#### Builder APK avec URL de dev

```bash
fvm flutter build apk --debug --dart-define=SYNC_API_BASE_URL=https://co-compagnon-sync.crame-teddy.workers.dev
```

APK générée:

```bash
build/app/outputs/flutter-apk/app-debug.apk
```

Installer APK sur téléphone (optionnel):

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### 4. Utilisation

Dans **Fiches de Personnages**:
- Icône cloud upload: envoie personnage local vers Neon (mot de passe requis).
- Premier upload: mot de passe saisi 2 fois. Ensuite: 1 seul mot de passe.
- Icône cloud download: affiche liste cloud, puis demande mot de passe pour personnage choisi.
- En cas de conflit (version plus récente de l'autre côté): app demande **Écraser** ou **Annuler**.
- Mot de passe sync: saisi deux fois à la création, impossible à retrouver ou réinitialiser.
