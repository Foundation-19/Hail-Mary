#!/usr/bin/env python3
"""
Applies armour_penetration (AP) and damage_threshold_penetration_mob (DTP) to mobs by type path.

Edits your CURRENT .dm files in place, so nothing gets overwritten by stale copies.
- Looks up each type by its exact header line, in any .dm file under the folder you give it.
- Replaces an existing armour_penetration / damage_threshold_penetration_mob line, or inserts
  new ones after the type's melee_damage_upper line (or right under the header if it has none).
- Safe to run repeatedly: unchanged values are reported as 'ok', missing types as 'not found'.
- Keeps each file's line endings (CRLF or LF).

Usage:
    python apply_penetration_pass.py <folder> [--dry-run]
"""
import os
import re
import sys

PREFIX = "/mob/living/simple_animal/hostile/"

# (path under PREFIX, armour_penetration, damage_threshold_penetration_mob)
# --- existing mobs (first pass) ---
EXISTING = [
    ("deathclaw", 0.2, 6), ("deathclaw/playable", 0.2, 0), ("deathclaw/mother", 0.25, 8),
    ("deathclaw/legendary", 0.3, 10), ("deathclaw/power_armor", 0.4, 12),
    ("deathclaw/inteligent/inflicted", 0, 0),
    ("trog/sporecarrier", 0.05, 2), ("trog/tunneler", 0.25, 6),
    ("mirelurk", 0.05, 2), ("mirelurk/hunter", 0.15, 4), ("mirelurk/queen", 0.25, 8),
    ("mirelurk/king", 0.3, 8), ("mirelurk/softshell", 0, 0), ("mirelurk/baby", 0, 0),
    ("supermutant", 0.05, 2), ("supermutant/playable", 0, 0), ("supermutant/meleemutant", 0.1, 4),
    ("supermutant/legendary", 0.25, 8), ("supermutant/nightkin", 0.15, 6),
    ("supermutant/nightkin/elitemutant", 0.2, 6), ("supermutant/meleemutant/rain", 0.15, 6),
    ("supermutant/nightkin/rain", 0.2, 6), ("supermutant/nightkin/elitemutant/rain", 0.25, 8),
    ("ghoul/reaver", 0.05, 2), ("ghoul/coldferal", 0.05, 2), ("ghoul/glowing/strong", 0.1, 4),
    ("ghoul/legendary", 0.2, 6), ("ghoul/zombie/reaver", 0.1, 4), ("ghoul/zombie/glowing", 0.1, 4),
    ("ghoul/zombie/legendary", 0.15, 6),
    ("centaur/strong", 0.1, 4), ("abomination", 0.1, 6), ("abomination/weak", 0, 0),
    ("abomhorror", 0.15, 6), ("abomhorror/nsb", 0.2, 8),
    ("wolf", 0.05, 2), ("wolf/playable", 0, 0), ("wolf/alpha", 0.1, 4),
    ("wolf/alpha/playable", 0, 0), ("wolf/cold", 0.1, 4),
    ("texas_rattler", 0.2, 6),
    ("giantant", 0.05, 2), ("fireant", 0.05, 2), ("giantantqueen", 0.2, 6),
    ("radscorpion", 0.15, 4), ("radscorpion/black", 0.2, 6),
    ("gecko/big", 0.1, 2), ("gecko/playable", 0, 0),
]

# --- mobs added in this conversation (every one explicit, so nothing is left to inheritance) ---
ADDED = [
    # super mutants: automatics + specialists
    ("supermutant/rangedmutant/smg", 0.05, 2),
    ("supermutant/rangedmutant/rifleman", 0.05, 2),
    ("supermutant/rangedmutant/suppressor", 0.1, 4),
    ("supermutant/nightkin/rangedmutant/infiltrator", 0.15, 6),
    ("supermutant/suicider", 0, 0),
    ("supermutant/rangedmutant/flamer", 0.05, 2),
    ("supermutant/overlord", 0.3, 10),
    # ghouls: ferals + ranged soldiers
    ("ghoul/roamer", 0.05, 2),
    ("ghoul/charred", 0, 0),
    ("ghoul/gangrenous", 0, 0),
    ("ghoul/glowing/bloated", 0.05, 2),
    ("ghoul/soldier/rifleman", 0, 0),
    ("ghoul/soldier/gunner", 0, 0),
    # deathclaws
    ("deathclaw/young", 0.05, 0),
    ("deathclaw/alpha", 0.3, 8),
    ("deathclaw/chameleon", 0.15, 6),
    ("deathclaw/mother/nesting", 0.25, 8),
    # insects
    ("mantis", 0.15, 4),
    ("bloodbug", 0, 0),
    ("stingwing", 0, 0),
    ("radroach/glowing", 0, 0),
    # wasteland animals
    ("gecko/golden", 0.05, 2),
    ("wolf/coyote", 0, 0),
    ("giantrat", 0, 0),
]


# --- second pass: robots, Chinese remnant, faction NPCs, raiders ---
# Melee bands only. Anything that shoots gets its real damage from the projectile (see PROJECTILE_SWAPS).
# Playable variants are 0/0 so players do not gain power from this pass.
PASS2 = [
    # robots (wastebots)
    ("handy", 0.05, 2), ("handy/playable", 0, 0),
    ("handy/gutsy", 0.15, 4), ("handy/gutsy/playable", 0, 0),
    ("handy/liberator", 0, 0),
    ("handy/robobrain", 0.15, 4),
    ("handy/protectron", 0, 0), ("handy/protectron/playable", 0, 0),
    ("handy/assaultron", 0.2, 6), ("handy/assaultron/martha", 0.3, 10),
    ("handy/assaultron/ensign", 0.2, 8), ("handy/assaultron/playable", 0, 0),
    ("handy/assaultron/playable/medical", 0, 0),
    # securitrons
    ("securitron", 0, 0),
    ("securitron/sentrybot", 0.25, 8), ("securitron/sentrybot/playable", 0, 0),
    ("securitron/sentrybot/counterfeit", 0.3, 10),
    ("securitron/sentrybot/chew", 0.35, 10),
    ("securitron/sentrybot/chew/strong", 1, 0), # keeps its existing full armor-ignore (AP 1); explicit 0 DTP so it does not inherit Chew's 10
    ("securitron/sentrybot/suicide", 0, 0),
    # Chinese remnant
    ("chinese", 0.1, 4), ("chinese/ranged", 0, 0), ("chinese/ranged/assault", 0, 0),
    ("chinese/ranged/stealth", 0, 0),
    # faction NPCs
    ("vault", 0, 0), ("vault/security", 0, 0),
    ("enclave", 0.1, 4), ("enclave/scientist", 0, 0), ("enclave/soldier", 0.2, 6),
    ("bs", 0.05, 2), ("bs/paladin", 0.1, 4),
    ("ncr", 0.05, 2), ("ncr/ranger", 0.05, 2),
    ("legion", 0.05, 2), ("legion/decan", 0.1, 4),
    ("tribe", 0.1, 4),
    # raiders
    ("raider", 0, 0), ("raider/ranged", 0, 0), ("raider/legendary", 0.15, 4),
    ("raider/ranged/legendary", 0, 0), ("raider/ranged/boss", 0, 0),
    ("raider/ranged/sulphiteranged", 0, 0), ("raider/firefighter", 0.05, 2),
    ("raider/ranged/biker", 0.05, 2),
    ("raider/baseball", 0.05, 2), ("raider/tribal", 0.05, 2), ("raider/sulphite", 0.05, 2),
    ("raider/junker", 0.1, 4), ("raider/ranged/boss/junker", 0.15, 4),
    ("raider/junker/creator", 0, 0), ("raider/junker/boss", 0, 0),
    ("raider/cultist/melee", 0.05, 2), ("raider/cultist/ranged", 0, 0),
    ("raider/cultist/ranged/tesla", 0, 0), ("raider/cultist/ranged/radiation", 0, 0),
]

# --- East Coast critters (animalhostile.dm + east_coast_variants.dm) ---
EAST = [
    ("ghoulrotter", 0.05, 2), ("ghoulrotter/bloater", 0.05, 2), ("ghoulrotter/crawler", 0, 0),
    ("skolf", 0.05, 2), ("skolf/alpha", 0.1, 4), ("skolf/rabid", 0.05, 2),
    ("yaoguai", 0.25, 8), ("yaoguai/cub", 0, 0), ("yaoguai/matriarch", 0.35, 10), ("yaoguai/scarred", 0.25, 8),
    ("aradnid", 0.05, 2), ("aradnid/broodmother", 0.1, 4), ("aradnid_hatchling", 0, 0),
    ("scolopendra", 0.1, 4), ("scolopendra/giant", 0.2, 6), ("scolopendra_young", 0, 0),
]

# Set (or insert) any other var in a type's own block: (path, var, value)
# Fixes noted in animalhostile.dm's design comments: armor on the base critters ("armor so AP is useful"),
# own factions for yao guai / scolopendra (they were sharing the geckos' faction, and rifle.dm's gauss
# already lists "yaoguai" as a supereffective faction), and scolopendra speed ("very fast" but speed was 4).
VAR_SETS = [
    ("ghoulrotter", "mob_armor", "ARMOR_VALUE_GHOUL_NAKED"),
    ("skolf", "mob_armor", "ARMOR_VALUE_BEAST_HIDE"),
    ("yaoguai", "mob_armor", "ARMOR_VALUE_YAOGUAI"),
    ("yaoguai", "faction", 'list("yaoguai")'),
    ("aradnid", "mob_armor", "ARMOR_VALUE_ARADNID"),
    ("scolopendra", "mob_armor", "ARMOR_VALUE_SCOLOPENDRA"),
    ("scolopendra", "faction", 'list("scolopendra")'),
    ("scolopendra", "speed", "2"),
    ("scolopendra", "move_to_delay", "2"),
]

# Swap simple 5.56 / 7.62 shooters onto the DT-penetrating projectile subtypes from simple_projectiles_pen.dm.
# (path, expected current projectiletype, new projectiletype). Only swapped if the current value matches.
PROJECTILE_SWAPS = [
    ("chinese/ranged/assault", "/obj/item/projectile/bullet/a556/simple", "/obj/item/projectile/bullet/a556/simple/pen"),
    ("chinese/ranged/stealth", "/obj/item/projectile/bullet/a556/simple", "/obj/item/projectile/bullet/a556/simple/pen"),
    ("ncr/trooper", "/obj/item/projectile/bullet/a556/simple", "/obj/item/projectile/bullet/a556/simple/pen"),
    ("legion/prime", "/obj/item/projectile/bullet/a762/sport/simple", "/obj/item/projectile/bullet/a762/sport/simple/pen"),
    ("legion/decan", "/obj/item/projectile/bullet/a762/sport/simple", "/obj/item/projectile/bullet/a762/sport/simple/heavy"),
    ("raider/ranged/biker", "/obj/item/projectile/bullet/a762/sport/simple", "/obj/item/projectile/bullet/a762/sport/simple/pen"),
    # pistol / shotgun calibers (types live in simple_projectiles_pen.dm)
    ("raider/ranged", "/obj/item/projectile/bullet/c9mm/simple", "/obj/item/projectile/bullet/c9mm/simple/pen"),
    ("chinese/ranged", "/obj/item/projectile/bullet/c9mm/simple", "/obj/item/projectile/bullet/c9mm/simple/pen"),
    ("ghoul/scorched/ranged", "/obj/item/projectile/bullet/c9mm/simple", "/obj/item/projectile/bullet/c9mm/simple/pen"),
    ("supermutant/rangedmutant/smg", "/obj/item/projectile/bullet/c10mm/simple", "/obj/item/projectile/bullet/c10mm/simple/pen"),
    ("supermutant/nightkin/rangedmutant/infiltrator", "/obj/item/projectile/bullet/c10mm/simple", "/obj/item/projectile/bullet/c10mm/simple/pen"),
    ("ncr/ranger", "/obj/item/projectile/bullet/m44/simple", "/obj/item/projectile/bullet/m44/simple/pen"),
    ("raider/ranged/legendary", "/obj/item/projectile/bullet/m44/simple", "/obj/item/projectile/bullet/m44/simple/pen"),
    ("raider/ranged/sulphiteranged", "/obj/item/projectile/bullet/c45/simple", "/obj/item/projectile/bullet/c45/simple/pen"),
    ("raider/junker/creator", "/obj/item/projectile/bullet/c45/op", "/obj/item/projectile/bullet/c45/op/pen"),
    ("raider/cultist/ranged/shotgun", "/obj/item/projectile/bullet/pellet/shotgun_buckshot", "/obj/item/projectile/bullet/pellet/shotgun_buckshot/pen"),
]

# Rage hooks: only applied if the exact old text is found exactly once.
RAGE_EDITS = [
    ("deathclaw.dm",
     "\tarmour_penetration = initial(armour_penetration) + 0.15 // bypasses a chunk of even heavy armor like riot gear once enraged\n",
     "\tarmour_penetration = initial(armour_penetration) + 0.15 // bypasses a chunk of even heavy armor like riot gear once enraged\n\tif(!ckey)\n\t\tdamage_threshold_penetration_mob = initial(damage_threshold_penetration_mob) + 4 // enraged claws punch through more flat DT too\n"),
    ("deathclaw.dm",
     "\tarmour_penetration = initial(armour_penetration)\n\tsee_in_dark = initial(see_in_dark)\n",
     "\tarmour_penetration = initial(armour_penetration)\n\tdamage_threshold_penetration_mob = initial(damage_threshold_penetration_mob)\n\tsee_in_dark = initial(see_in_dark)\n"),
    ("tunnelers.dm",
     "\tarmour_penetration = 0.35  // Increased from 0.25\n",
     "\tarmour_penetration = 0.35  // Increased from 0.25\n\tdamage_threshold_penetration_mob = initial(damage_threshold_penetration_mob) + 4\n"),
    ("tunnelers.dm",
     "\tarmour_penetration = initial(armour_penetration)\n\tis_low_health = FALSE\n",
     "\tarmour_penetration = initial(armour_penetration)\n\tdamage_threshold_penetration_mob = initial(damage_threshold_penetration_mob)\n\tis_low_health = FALSE\n"),
    ("animalhostile.dm",
     "\t\tH.reagents.add_reagent(/datum/reagent/toxin/polonium, 20) //irradiates as pebbles wanted it to do\n",
     "\t\tH.apply_effect(20, EFFECT_IRRADIATE, 0) // was polonium; real radiation, as the design note asked\n"),
]

AP_RE = re.compile(r"^\tarmour_penetration\s*=")
DTP_RE = re.compile(r"^\tdamage_threshold_penetration_mob\s*=")
MELEE_UP_RE = re.compile(r"^\tmelee_damage_upper\s*=")


def fmt(v):
    return str(int(v)) if float(v).is_integer() else str(v)


def find_dm_files(root):
    for d, _, files in os.walk(root):
        for f in files:
            if f.lower().endswith(".dm"):
                yield os.path.join(d, f)


# latin-1 maps every byte to a character and back, so files with odd bytes (or UTF-8 text)
# are read and written back byte-for-byte, regardless of the OS default encoding.
ENC = "latin-1"


def read(path):
    with open(path, newline="", encoding=ENC) as fh:
        raw = fh.read()
    crlf = "\r\n" in raw
    return raw.replace("\r\n", "\n"), crlf


def write(path, text, crlf):
    with open(path, "w", newline="", encoding=ENC) as fh:
        fh.write(text.replace("\n", "\r\n") if crlf else text)


def apply_one(lines, header_idx, ap, dtp):
    """Returns (changed, notes). Edits lines in place."""
    j = header_idx + 1
    while j < len(lines) and (lines[j] == "" or lines[j][0] in "\t "):
        j += 1
    block = range(header_idx + 1, j)
    ap_idx = next((k for k in block if AP_RE.match(lines[k])), None)
    dtp_idx = next((k for k in block if DTP_RE.match(lines[k])), None)
    new_ap = "\tarmour_penetration = %s" % fmt(ap)
    new_dtp = "\tdamage_threshold_penetration_mob = %s" % fmt(dtp)
    changed = False

    # armour_penetration: keep any trailing // comment when only the value is the same
    if ap_idx is not None:
        old = lines[ap_idx]
        m = re.match(r"^\tarmour_penetration\s*=\s*(-?[0-9.]+)\s*(//.*)?$", old)
        if m and float(m.group(1)) == float(ap):
            pass  # already the right value
        else:
            lines[ap_idx] = new_ap
            changed = True
    # damage_threshold_penetration_mob
    if dtp_idx is not None:
        m = re.match(r"^\tdamage_threshold_penetration_mob\s*=\s*(-?[0-9.]+)", lines[dtp_idx])
        if not (m and float(m.group(1)) == float(dtp)):
            lines[dtp_idx] = new_dtp
            changed = True
    # inserts
    to_insert = []
    if ap_idx is None:
        to_insert.append(new_ap)
    if dtp_idx is None:
        to_insert.append(new_dtp)
    if to_insert:
        melee_idx = next((k for k in block if MELEE_UP_RE.match(lines[k])), None)
        # prefer to sit right after the AP line when it exists, else after melee_damage_upper, else under the header
        anchor = ap_idx if ap_idx is not None else (melee_idx if melee_idx is not None else header_idx)
        lines[anchor + 1:anchor + 1] = to_insert
        changed = True
    return changed


def main():
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    bad = [f for f in flags if f != "--dry-run"]
    if bad:
        print("Unknown option(s): %s\nOnly --dry-run is supported (check for a stray period or typo)." % " ".join(bad))
        sys.exit(1)
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry-run" in sys.argv
    if not args:
        print(__doc__)
        sys.exit(1)
    root = args[0]
    files = {p: read(p) for p in find_dm_files(root)}
    state = {p: [lines for lines in [t.split("\n")]][0] for p, (t, _) in files.items()}
    crlf = {p: c for p, (_, c) in files.items()}
    dirty = set()
    report = []

    for label, table in (("existing", EXISTING), ("added", ADDED), ("pass2", PASS2), ("east", EAST)):
        for path, ap, dtp in table:
            hdr = re.compile(r"^" + re.escape(PREFIX + path) + r"\s*(//.*)?$")
            hits = [(p, i) for p, lines in state.items() for i, l in enumerate(lines) if hdr.match(l)]
            if not hits:
                report.append((label, path, "not found"))
                continue
            if len(hits) > 1:
                report.append((label, path, "SKIPPED: defined %d times" % len(hits)))
                continue
            p, i = hits[0]
            if apply_one(state[p], i, ap, dtp):
                dirty.add(p)
                report.append((label, path, "updated  AP %s / DTP %s" % (fmt(ap), fmt(dtp))))
            else:
                report.append((label, path, "ok"))

    varset_report = []
    for path, var, value in VAR_SETS:
        hdr = re.compile(r"^" + re.escape(PREFIX + path) + r"\s*(//.*)?$")
        hits = [(p, i) for p, lines in state.items() for i, l in enumerate(lines) if hdr.match(l)]
        if len(hits) != 1:
            varset_report.append((path + "." + var, "not found" if not hits else "SKIPPED: defined %d times" % len(hits)))
            continue
        p, i = hits[0]
        lines = state[p]
        j = i + 1
        while j < len(lines) and (lines[j] == "" or lines[j][0] in "\t "):
            j += 1
        pat = re.compile(r"^\t" + re.escape(var) + r"\s*=\s*(.*?)\s*(//.*)?$")
        idx = next((k for k in range(i + 1, j) if pat.match(lines[k])), None)
        newline = "\t%s = %s" % (var, value)
        if idx is None:
            lines.insert(i + 1, newline)
            dirty.add(p)
            varset_report.append((path + "." + var, "added " + value))
        elif pat.match(lines[idx]).group(1) == value:
            varset_report.append((path + "." + var, "ok"))
        else:
            old = pat.match(lines[idx]).group(1)
            lines[idx] = newline + " // was " + old
            dirty.add(p)
            varset_report.append((path + "." + var, "set %s (was %s)" % (value, old)))

    swap_report = []
    for path, old, new in PROJECTILE_SWAPS:
        hdr = re.compile(r"^" + re.escape(PREFIX + path) + r"\s*(//.*)?$")
        hits = [(p, i) for p, lines in state.items() for i, l in enumerate(lines) if hdr.match(l)]
        if len(hits) != 1:
            swap_report.append((path, "not found" if not hits else "SKIPPED: defined %d times" % len(hits)))
            continue
        p, i = hits[0]
        lines = state[p]
        j = i + 1
        while j < len(lines) and (lines[j] == "" or lines[j][0] in "\t "):
            j += 1
        idx = next((k for k in range(i + 1, j) if re.match(r"^\tprojectiletype\s*=", lines[k])), None)
        if idx is None:
            swap_report.append((path, "SKIPPED: no projectiletype line in its own block (inherited)"))
            continue
        cur = lines[idx].split("=", 1)[1].strip().split("//")[0].strip()
        if cur == new:
            swap_report.append((path, "ok"))
        elif cur == old:
            lines[idx] = "\tprojectiletype = " + new
            dirty.add(p)
            swap_report.append((path, "projectile -> " + new.split("/")[-1]))
        else:
            swap_report.append((path, "SKIPPED: current projectile is " + cur))

    rage_report = []
    for fname, old, new in RAGE_EDITS:
        targets = [p for p in state if os.path.basename(p) == fname]
        if not targets:
            rage_report.append((fname, "file not found"))
            continue
        p = targets[0]
        text = "\n".join(state[p])
        if new in text:
            rage_report.append((fname, "ok"))
        elif text.count(old) == 1:
            state[p] = text.replace(old, new).split("\n")
            dirty.add(p)
            rage_report.append((fname, "rage hook added"))
        else:
            rage_report.append((fname, "SKIPPED: expected text not found exactly once"))

    if not dry:
        for p in dirty:
            write(p, "\n".join(state[p]), crlf[p])

    width = max(len(r[1]) for r in report)
    for label, path, status in report:
        print("[%-8s] %-*s  %s" % (label, width, path, status))
    for path, status in varset_report:
        print("[var     ] %-*s  %s" % (width, path, status))
    for path, status in swap_report:
        print("[swap    ] %-*s  %s" % (width, path, status))
    for fname, status in rage_report:
        print("[rage    ] %-*s  %s" % (width, fname, status))
    print("\n%s %d file(s)%s" % ("Would change" if dry else "Changed", len(dirty), " (dry run)" if dry else ""))


if __name__ == "__main__":
    main()
