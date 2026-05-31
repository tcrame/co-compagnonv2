#!/usr/bin/env python3
"""
extract_bestiary.py
-------------------
Extrait les profils de créatures d'un PDF de bestiaire (Chroniques Oubliées)
et met à jour les fichiers Markdown correspondants dans rules/bestiary/.

Usage:
    python3 tools/extract_bestiary.py <chemin_vers_le_pdf>

Options:
    --dry-run    Affiche les changements sans modifier les fichiers
    --only NAME  Ne traite que la créature dont le nom contient NAME (insensible à la casse)

Exemple:
    python3 tools/extract_bestiary.py images/bestiraire.pdf
    python3 tools/extract_bestiary.py images/bestiraire.pdf --dry-run
    python3 tools/extract_bestiary.py images/bestiraire.pdf --only lion
"""

import argparse
import os
import re
import sys

try:
    import pdfplumber
except ImportError:
    print("Erreur : pdfplumber n'est pas installé. Lancez : pip install pdfplumber")
    sys.exit(1)

# ---------------------------------------------------------------------------
# Constantes
# ---------------------------------------------------------------------------

BESTIARY_ROOT = os.path.join(os.path.dirname(__file__), '..', 'rules', 'bestiary')

# Mapping nom PDF (majuscules) → clé du fichier markdown
PDF_TO_MD: dict[str, str] = {
    'ASSASSIN': 'assassin',
    'BANDIT DE BASE': 'bandit-de-base',
    'BANDIT VÉTÉRAN': 'bandit-veteran',
    'CHEF BANDIT': 'chef-bandit',
    'MILICIEN': 'milicien',
    'GARDE DE LA VILLE': 'garde-de-la-ville',
    'VÉTÉRAN OU': 'veteran-garde-ducal',
    'CAPITAINE': 'capitaine',
    'GARDE DU CORPS': 'garde-du-corps',
    'SORCIER': 'sorcier',
    'AIGLE COMMUN': 'aigle-commun',
    'ANIMAL MINUSCULE': 'animal-minuscule',
    'ANIMAL PETIT': 'animal-petit',
    'ANIMAL TRÈS PETIT': 'animal-tres-petit',
    'CHEVAL DE SELLE': 'cheval-de-selle',
    'CHEVALE DE GUERRE': 'cheval-de-guerre',
    'CROCODILE': 'crocodile',
    'BISON': 'bison',
    'ÉLÉPHANT': 'elephant',
    'GORILLE': 'gorille',
    'LION': 'lion',
    'LOUP': 'loup',
    'MÂLE ALPHA': 'loup-alpha',
    'OURS NOIR': 'ours-noir',
    'OURS POLAIRE': 'ours-polaire',
    'OURS BRUN': 'ours-brun',
    'PANTHÈRE': 'panthere',
    'REQUIN': 'requin',
    'SANGLIER': 'sanglier',
    'RHINOCÉROS': 'rhinoceros',
    'SERPENT VENIMEUX': 'serpent-venimeux',
    'SERPENT': 'serpent-constricteur',
    'ARAIGNÉE GÉANTE': 'araignee-geante',
    'BASILIC': 'basilic',
    'CHIMÈRE': 'chimere',
    'CHIMÈRE DRACONIQUE': 'chimere-draconique',
    'DÉMONET': 'demonet',
    'DRAGON DES FORÊTS': 'dragon-des-forets',
    "ÉLÉMENTAIRE D'EAU": 'elementaire-eau-grand',
    'GÉANT DU FEU': 'geant-du-feu',
    'GEOSELACHIS': 'geoselachis',
    'GNOLL DE BASE': 'gnoll-base',
    'SERGENT GNOLL': 'gnoll-sergent',
    'CHEF GNOLL': 'gnoll-chef',
    'GOBELIN DE BASE': 'gobelin-base',
    'GOBELIN ÉLITE': 'gobelin-elite',
    'CHEF GOBELIN': 'gobelin-chef',
    'SHAMAN GOBELIN': 'gobelin-shaman',
    'GOLEM DE CHAIR': 'golem-de-chair',
    'GOULE': 'goule',
    'ABOMINATION': 'goule-abomination',
    'GRIFFON': 'griffon',
    'HYDRE À CINQ TÊTES': 'hydre-5-tetes',
    'CRYOHYDRE': 'cryohydre-10-tetes',
    'KOBOLD DE BASE': 'kobold-base',
    'CHEF KOBOLD': 'kobold-chef',
    'PRÊTRE KOBOLD': 'kobold-pretre',
    'LICORNE': 'licorne',
    'MOMIE': 'momie',
    'MOMIE AUGUSTE': 'momie-auguste',
    'OGRE DE BASE': 'ogre-base',
    'CHEF OGRE': 'ogre-chef',
    'ORC DE BASE': 'orc-base',
    'ORC NOIR': 'orc-noir',
    'BERSERKER ORC': 'orc-berserker',
    'SERGENT ORC': 'orc-sergent',
    'CHEF ORC': 'orc-chef',
    'SHAMAN ORC': 'orc-shaman',
    'RAT GÉANT': 'rat-geant',
    'OURHIBLE': 'ourhible',
    'SKRAMBLER': 'skrambler',
    'SQUELETTE DE BASE': 'squelette-base',
    'SQUELETTE GÉANT': 'squelette-geant',
    'TROLL': 'troll',
    'VAMPIRE': 'vampire',
    'VAMPIRE ANCIEN': 'vampire-ancien',
    'VAMPIRIEN': 'vampirien',
    'WORG': 'worg',
    'ZOMBIE HUMAIN': 'zombie-humain',
    'ZOMBIE CHOURSETTE': 'zombie-choursette',
}

# Créatures dont les capacités sont définies dans un bloc générique au-dessus
# d'elles dans le PDF (pattern "Voir ci-dessus")
INHERIT_ABILITIES: dict[str, str] = {
    'bison-grand-male': 'bison',
    'lion-grand-male': 'lion',
}

# Capacités partagées par tous les zombies (définies dans la section générique)
ZOMBIE_ABILITIES = [
    ("Résistance Aux Dm",
     "Divisez par deux tous les DM infligés au zombie par des armes, "
     "sauf s'il s'agit d'armes tranchantes."),
    ("Sans Esprit",
     "Aucune âme n'habite la carcasse morte, le zombie est immunisé "
     "à tous les sorts qui affectent l'esprit."),
    ("Lenteur",
     "Le zombie voit son AGI réduite à -1 et sa PER à -2, "
     "et il ne se déplace que de 5 m par action de mouvement."),
    ("Insensible À La Douleur",
     "Ajoutez 3 x NC aux PV et retranchez 5 à la DEF. La créature peut "
     "encore faire une action (attaque ou mouvement) après avoir été réduite à 0 PV."),
]

# ---------------------------------------------------------------------------
# Extraction PDF
# ---------------------------------------------------------------------------

def extract_text(pdf_path: str) -> str:
    """Extrait le texte du PDF colonne par colonne pour éviter le mélange 2 colonnes."""
    pages_text = []
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            w, h = page.width, page.height
            left = page.crop((0, 0, w * 0.50, h)).extract_text() or ""
            right = page.crop((w * 0.50, 0, w, h)).extract_text() or ""
            pages_text.append(left + "\n" + right)
    return "\n".join(pages_text)


def clean_text(raw: str) -> str:
    """Supprime les artefacts de mise en page."""
    text = raw.replace('\x08', '').replace('\x0c', '')
    lines = []
    for line in text.split('\n'):
        line = re.sub(r'PAGE \d+\s+PARTIE III', '', line)
        line = re.sub(r'PARTIE III\s+PAGE \d+', '', line)
        line = re.sub(r'Teddy [A-Za-z]+.*', '', line)
        line = re.sub(r'^\s*[0-9]\s*$', '', line)
        line = re.sub(r'^\s*(INTRO|PERSO|RÈGLES|OPPOSITION)\s*$', '', line)
        lines.append(line)
    return '\n'.join(lines)


def split_blocks(text: str) -> list[tuple[str, str]]:
    """Découpe le texte en blocs par créature. Renvoie [(nom_pdf, bloc), ...]."""
    creature_pat = re.compile(r'^(.+?)\s*\|\s*NC\s+([\d/]+(?:\s*\(\d+\))?)', re.MULTILINE)
    matches = list(creature_pat.finditer(text))
    blocks = []
    for i, m in enumerate(matches):
        name = m.group(1).strip()
        if '|' in name or name.startswith('('):
            continue
        start = m.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        blocks.append((name, text[start:end]))
    return blocks


# ---------------------------------------------------------------------------
# Parsing d'un bloc créature
# ---------------------------------------------------------------------------

def parse_stats(block: str) -> dict:
    """Extrait les statistiques numériques d'un bloc créature."""
    stats: dict = {}

    m = re.search(r'\|\s*NC\s+([\d/]+)', block)
    if m:
        stats['nc'] = m.group(1).strip()

    m = re.search(r'\(S\)\s*D[ée]fense\s+(\d+)', block)
    if m:
        stats['defense'] = m.group(1)

    m = re.search(r'\(V\)\s*Points de vigueur\s+(\d+)(?:\s*\(RD(\d+)\))?', block)
    if m:
        stats['pv'] = m.group(1)
        if m.group(2):
            stats['rd'] = m.group(2)

    m = re.search(r'\(I\)\s*Initiative\s+(\d+)', block)
    if m:
        stats['init'] = m.group(1)

    cleaned = block.replace('\u2011', '-').replace('\u2013', '-').replace('‑', '-')
    for stat in ['AGI', 'CON', 'FOR', 'PER', 'CHA', 'INT', 'VOL']:
        m = re.search(r'\b' + stat + r'\s*([+\-]\d+)\*?', cleaned)
        if m:
            stats[stat.lower()] = m.group(1)

    stats['attacks'] = parse_attacks(block)
    return stats


def parse_attacks(block: str) -> list[dict]:
    """Extrait les lignes d'attaque entre Initiative et les capacités."""
    init_pos = block.find('(I) Initiative')
    if init_pos < 0:
        return []
    ability_pat = re.compile(
        r'^[A-ZÀÂÄÉÈÊËÎÏÔÖÙÛÜÇŒÆ][A-ZÀÂÄÉÈÊËÎÏÔÖÙÛÜÇŒÆ\s\-]{2,}(?:\([A-Z]\))?\s*:\s*$',
        re.MULTILINE,
    )
    ability_m = ability_pat.search(block, init_pos)
    end_pos = ability_m.start() if ability_m else len(block)
    section = block[init_pos:end_pos]

    attacks = []
    for line in section.split('\n'):
        line = line.strip().replace('·', ' · ').replace('\u00b7', ' · ')
        if not line or line.startswith('(') or line.startswith('|'):
            continue
        if re.match(r'^[A-Z]{3,}\s*:', line):
            break

        range_m = re.search(r'\((\d+\s*m)\)', line)
        portee = range_m.group(1) if range_m else 'Contact'
        clean = re.sub(r'\s*\(\d+\s*m\)', '', line)
        clean = re.sub(r'\s*\(\d+ attaques?\)', '', clean).strip()

        bonus_m = re.search(r'([+\-]\d+)\s*(?:·|DM\b)', clean)
        if not bonus_m:
            bonus_m = re.search(r'([+\-]\d+)\s*$', clean)
        bonus = bonus_m.group(1) if bonus_m else ''

        dm_m = re.search(r'DM\s+([\dd+\-]+(?:\s*\+\s*[\dd+\-]+)*)', line)
        if not dm_m:
            dm_m = re.search(r'·\s*([\dd+\-]+)', line)
        damage = re.sub(r'\s+', '', dm_m.group(1)) if dm_m else ''

        if bonus:
            idx = clean.rfind(bonus)
            atk_name = clean[:idx].strip(' ·') if idx >= 0 else clean
        else:
            atk_name = clean
        atk_name = re.sub(r'\s+', ' ', atk_name).strip(' ·+')

        if atk_name and len(atk_name) > 1 and bonus:
            attacks.append({'name': atk_name, 'bonus': bonus,
                            'damage': damage, 'portee': portee})
    return attacks


def parse_abilities(block: str) -> list[tuple[str, str]]:
    """Extrait les capacités spéciales (nom + description) d'un bloc créature."""
    ability_header = re.compile(
        r'^([A-ZÀÂÄÉÈÊËÎÏÔÖÙÛÜÇŒÆ][A-ZÀÂÄÉÈÊËÎÏÔÖÙÛÜÇŒÆ\s\-\'\u2013\u2014]{1,}?'
        r'(?:\s*\([A-Z*+]\))?)\s*:\s*$',
        re.MULTILINE,
    )
    section_title = re.compile(r'^[A-ZÀÂÄÉÈÊËÎÏÔÖÙÛÜÇŒÆ][a-zàâäéèêëîïôöùûüçœæ][a-zA-ZÀ-ÿ\s\-]*$')
    skip_words = {'CRÉATURE', 'TAILLE', 'AGI', 'PARTIE', 'PROFILS', 'CAPACITÉS'}
    lead_words = {'La ', 'Le ', 'Les ', 'Un ', 'Une ', 'Au ', 'Si ', 'En ',
                  'Ce ', 'Lorsque ', 'Pour ', 'Toute '}

    abilities: list[tuple[str, str]] = []
    block_lines = block.split('\n')
    i = 0
    while i < len(block_lines):
        line = block_lines[i].strip()
        m = ability_header.match(line)
        if m:
            ability_name = m.group(1).strip()
            if any(w in ability_name for w in skip_words) or len(ability_name) < 3:
                i += 1
                continue
            desc_lines = []
            j = i + 1
            while j < len(block_lines):
                nxt = block_lines[j].strip()
                if ability_header.match(nxt) and len(nxt) > 3:
                    break
                if (section_title.match(nxt) and len(nxt) < 40 and nxt
                        and not any(nxt.startswith(w) for w in lead_words)
                        and len(nxt.split()) <= 4):
                    break
                desc_lines.append(nxt)
                j += 1
            desc = ' '.join(l for l in desc_lines if l)
            desc = re.sub(r'\s+', ' ', desc).strip()
            desc = (desc
                    .replace('\u2011', '-').replace('\u2013', '-').replace('\u2014', '—')
                    .replace('\u2019', "'").replace('\u2018', "'")
                    .replace('‑', '-'))
            desc = re.sub(r'\s*(Ce profil.*|Les animaux.*)', '', desc).strip()
            # Fix word-break hyphens from PDF layout
            desc = re.sub(r'([a-zàâäéèêëîïôöùûüçœæ])- ([a-zàâäéèêëîïôöùûüçœæ])',
                          r'\1\2', desc)
            if desc and len(desc) > 10:
                abilities.append((_smart_title(ability_name), desc))
            i = j
        else:
            i += 1
    return abilities


def _smart_title(name: str) -> str:
    """Title-case un nom de capacité en préservant les marqueurs (A), (L), etc."""
    return ' '.join(
        w if re.match(r'^\([A-Z*+]\)$', w) else w.capitalize()
        for w in name.split()
    )


# ---------------------------------------------------------------------------
# Mise à jour des fichiers Markdown
# ---------------------------------------------------------------------------

def find_md_file(md_key: str):
    root = os.path.normpath(BESTIARY_ROOT)
    for dirpath, _, files in os.walk(root):
        for fname in files:
            if fname == f'{md_key}.md':
                return os.path.join(dirpath, fname)
    return None


def build_abilities_section(abilities: list[tuple[str, str]]) -> str:
    if not abilities:
        return "## Capacités spéciales\n\n*Aucune capacité spéciale.*"
    lines = ["## Capacités spéciales", ""]
    for name, desc in abilities:
        lines.append(f"- **{name}** : {desc}")
    return '\n'.join(lines)


def update_markdown(path: str, stats: dict, abilities: list[tuple[str, str]],
                    dry_run: bool = False) -> bool:
    with open(path, 'r') as f:
        content = f.read()

    original = content

    # --- Stats table ---
    nc = stats.get('nc', '?')
    pv = stats.get('pv', '?')
    defense = stats.get('defense', '?')
    init_val = stats.get('init', '?')

    vit_m = re.search(
        r'\|[-\s\d/]+\|[-\s\d]+\|[-\s\d]+\|[-\s\d+]+\|\s*([^|\n]+?)\s*\|', content
    )
    vitesse = vit_m.group(1).strip() if vit_m else '—'

    new_stats = (
        "| NC | PV | Défense | Init | Vitesse |\n"
        "|----|----|---------|------|---------|\n"
        f"| {nc} | {pv} | {defense} | {init_val} | {vitesse} |"
    )
    content = re.sub(
        r'\| NC \| PV \| Défense \| Init \| Vitesse \|\n\|[-|]+\|\n[^\n]+',
        new_stats, content,
    )

    # --- Caractéristiques table ---
    carac = {s: stats.get(s, '+0') for s in ('agi', 'con', 'for', 'per', 'cha', 'int', 'vol')}
    new_carac = (
        "| AGI | CON | FOR | PER | CHA | INT | VOL |\n"
        "|-----|-----|-----|-----|-----|-----|-----|\n"
        "| {agi} | {con} | {for} | {per} | {cha} | {int} | {vol} |"
    ).format(**carac)
    content = re.sub(
        r'\| AGI \| CON \| FOR \| PER \| CHA \| INT \| VOL \|\n\|[-|]+\|\n[^\n]+',
        new_carac, content,
    )

    # --- Attacks table ---
    attacks = stats.get('attacks', [])
    if attacks:
        rows = ''.join(
            f"| {a['name']} | {a['bonus']} | {a['damage']} | {a['portee']} |\n"
            for a in attacks
        )
        new_atk = (
            "| Attaque | Bonus | Dégâts | Portée |\n"
            "|---------|-------|--------|--------|\n"
            + rows.rstrip()
        )
        content = re.sub(
            r'\| Attaque \| Bonus \| Dégâts \| Portée \|\n\|[-|]+\|\n(?:\|[^\n]+\n?)+',
            new_atk, content,
        )

    # --- Capacités spéciales ---
    new_cap = build_abilities_section(abilities)
    cap_pat = re.compile(r'## Capacités spéciales\s*\n.*?(?=\n## |\Z)', re.DOTALL)
    if cap_pat.search(content):
        content = cap_pat.sub(new_cap, content)
    else:
        content = content.rstrip() + '\n\n' + new_cap + '\n'

    changed = content != original
    if not dry_run and changed:
        with open(path, 'w') as f:
            f.write(content)
    return changed


# ---------------------------------------------------------------------------
# Point d'entrée
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('pdf', help='Chemin vers le fichier PDF du bestiaire')
    parser.add_argument('--dry-run', action='store_true',
                        help='Affiche les changements sans écrire les fichiers')
    parser.add_argument('--only', metavar='NAME', default='',
                        help='Filtre : ne traite que les créatures dont le nom contient NAME')
    args = parser.parse_args()

    if not os.path.exists(args.pdf):
        print(f"Erreur : fichier introuvable : {args.pdf}")
        sys.exit(1)

    print(f"Extraction du PDF : {args.pdf}")
    raw = extract_text(args.pdf)
    text = clean_text(raw)
    blocks = split_blocks(text)
    print(f"  → {len(blocks)} blocs créature détectés")

    # Indexer les blocs (gérer les doublons comme GRAND MÂLE)
    indexed: dict[str, list[str]] = {}
    for name, block in blocks:
        indexed.setdefault(name, []).append(block)

    # Construire les stats et capacités pour chaque entrée
    creature_data: dict[str, dict] = {}
    for pdf_name, md_key in PDF_TO_MD.items():
        blks = indexed.get(pdf_name, [])
        if not blks:
            continue
        s = parse_stats(blks[0])
        s['abilities'] = parse_abilities(blks[0])
        creature_data[md_key] = s

    # Cas particuliers : GRAND MÂLE (bison puis lion)
    grand_males = indexed.get('GRAND MÂLE', [])
    if len(grand_males) >= 1:
        s = parse_stats(grand_males[0])
        s['abilities'] = creature_data.get('bison', {}).get('abilities', [])
        creature_data['bison-grand-male'] = s
    if len(grand_males) >= 2:
        s = parse_stats(grand_males[1])
        s['abilities'] = creature_data.get('lion', {}).get('abilities', [])
        creature_data['lion-grand-male'] = s

    # Zombies : capacités définies dans un bloc générique
    for zk in ('zombie-humain', 'zombie-choursette'):
        if zk in creature_data:
            creature_data[zk]['abilities'] = list(ZOMBIE_ABILITIES)

    # Appliquer le filtre --only
    filter_name = args.only.lower()

    updated = skipped = missing = 0
    for md_key, data in sorted(creature_data.items()):
        if filter_name and filter_name not in md_key:
            continue
        path = find_md_file(md_key)
        if not path:
            print(f"  ⚠  Fichier introuvable : {md_key}.md")
            missing += 1
            continue
        abilities = data.get('abilities', [])
        changed = update_markdown(path, data, abilities, dry_run=args.dry_run)
        status = '✏' if changed else '='
        if args.dry_run and changed:
            status = '[DRY-RUN]'
        print(f"  {status}  {md_key} ({len(abilities)} capacité(s))")
        if changed:
            updated += 1
        else:
            skipped += 1

    print()
    if args.dry_run:
        print(f"[DRY-RUN] {updated} fichier(s) seraient modifiés, {skipped} inchangé(s), {missing} introuvable(s).")
    else:
        print(f"✔ {updated} fichier(s) mis à jour, {skipped} inchangé(s), {missing} introuvable(s).")


if __name__ == '__main__':
    main()
