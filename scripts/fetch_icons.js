const fs = require('fs');
const https = require('https');

console.log("📥 Téléchargement de l'index Game-icons via le miroir public Iconify...");

const options = {
    hostname: 'raw.githubusercontent.com',
    port: 443,
    // Chemin stable vers le fichier de données officiel d'Iconify pour Game-icons
    path: '/iconify/icon-sets/master/json/game-icons.json',
    method: 'GET',
    headers: {
        'User-Agent': 'NodeJS-Fetch-Script'
    }
};

const req = https.request(options, (res) => {
    let data = '';

    if (res.statusCode !== 200) {
        console.error(`❌ Impossible de récupérer le fichier (Code : ${res.statusCode})`);
        return;
    }

    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
        try {
            const iconifyData = JSON.parse(data);
            const iconsList = [];

            // Iconify stocke les icônes sous forme d'un dictionnaire d'objets dans la clé 'icons'
            if (!iconifyData.icons) {
                throw new Error("Le format du fichier Iconify est invalide (clé 'icons' manquante).");
            }

            for (const [iconName, iconContent] of Object.entries(iconifyData.icons)) {
                // Dans Iconify, les catégories sont parfois des tags ou absents, on va utiliser les catégories du projet
                // Les catégories de Game-icons sont déduites des catégories d'Iconify ou de tags génériques
                let tags = [];
                if (iconifyData.categories) {
                    for (const [catName, catIcons] of Object.entries(iconifyData.categories)) {
                        if (catIcons.includes(iconName)) {
                            tags.push(catName);
                        }
                    }
                }

                // Par défaut, s'il n'y a pas de catégorie, on le met dans "Général"
                if (tags.length === 0) tags.push("Général");

                // Extraction de l'auteur si dispo dans les métadonnées (Lorc ou Delapouite par défaut dans 95% des cas)
                // Pour éviter les erreurs de chemin sur game-icons.net, on utilise l'API de fallback d'Iconify ou on normalise
                // Astuce : Game-icons.net accepte souvent de rediriger, mais pour coller à ton format $_b :
                // La quasi totalité des icônes modernes non-spécifiées fonctionnent avec 'lorc' ou 'delapouite'
                // Pour être 100% compatible avec l'URL brute de Game-icons.net, nous allons lier l'API Iconify (plus fiable !)

                iconsList.push({
                    n: iconName.replace(/-/g, ' '), // Nom propre pour la recherche textuelle
                    a: "iconify",
                    p: iconName, // Le slug unique de l'icône (ex: "croc-sword")
                    t: tags // Catégories pour filtrer
                });
            }

            // Génération du fichier final destiné à être importé par ton Worker Cloudflare
            const output = `// Catalogue officiel Game-icons (Via Iconify) (~${iconsList.length} icônes)\nexport const gameIconsBank = ${JSON.stringify(iconsList, null, 2)};`;

            fs.writeFileSync('./game_icons_bank.js', output);
            console.log(`\n✅ Fichier game_icons_bank.js généré avec succès ! (${iconsList.length} icônes enregistrées)`);
            console.log("💡 Note : Les chemins d'icônes ont été normalisés pour s'adapter au catalogue global.");
        } catch (parseError) {
            console.error("\n❌ Erreur lors du traitement du fichier : " + parseError.message);
        }
    });
});

req.on('error', (err) => {
    console.error("❌ Erreur réseau : " + err.message);
});

req.end();