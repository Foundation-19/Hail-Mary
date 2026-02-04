# Hail-Mary Codebase Workflow Guide

This is the practical guide for working in this codebase without losing your mind.

Use this alongside `README_FALLOUT_SYSTEMS.md`.

---

## 1) The 80/20 Mental Model

Most gameplay features in this repo touch four layers:

1. **DM gameplay logic** (`code/`, `fallout/code/`)
2. **Map placement** (`_maps/`, area tags, landmarks)
3. **UI** (`tgui/packages/tgui/interfaces/`)
4. **Build wiring** (`hailmary.dme`, includes, job lists, subsystem registration)

If one layer is missing, the feature “exists in code” but won’t work in-game.

---

## 2) Fast Dev Loop (recommended)

Run these constantly:

```powershell
tools/build/build dm
tools/build/build tgui
```

If DM fails:
- Fix DM first, then re-run.

If TGUI fails:
- Check interface filename/export name and UI id string in DM (`new(user, src, "InterfaceName")`).

---

## 3) Folder Map (what lives where)

- `code/controllers/subsystem/` → subsystem brains (tick-based game loops)
- `code/modules/f13/` → Fallout-specific systems (reactor, faction territory, etc.)
- `fallout/code/modules/QuestMachines/` → bounty/courier/parcel machines
- `code/modules/jobs/` + `code/game/objects/effects/landmarks.dm` → jobs + spawn points
- `fallout/areas/area.dm` → area definitions and district tagging
- `tgui/packages/tgui/interfaces/` → TSX/JS UIs
- `hailmary.dme` → include order / compile wiring

---

## 4) Non-negotiable Rules for Adding Features

## 4.1 Add to compile graph
If you add a new DM file, ensure it is included in `hailmary.dme`.

## 4.2 Map objects if needed
Anything map-driven (nodes, consoles, pads, relays, landmarks) must be placed on map or it will look “broken”.

## 4.3 Add area context
District/power/faction logic relies on area context (`grid_district`, fallback naming heuristics).

## 4.4 Keep IDs consistent
For UI:
- DM ui id string must match interface export filename target.

## 4.5 Avoid fragile dynamic constructors
Prefer explicit typed `new /obj/...` over loose dynamic creation when possible.

---

## 5) Debugging Checklist (when “it doesn’t work”)

1. Compile clean? (`tools/build/build dm`)
2. Runtime log line + proc + file line?
3. Object actually mapped where expected?
4. Area has proper district tag?
5. Job appears in job list AND has landmarks?
6. Faction alias/normalization includes your faction?
7. Is access gated by faction lock/research lock/ownership?
8. UI receiving data keys that TSX expects?

---

## 6) Common Failure Patterns in This Repo

- **Job not visible**: missing job category/list entry or file include
- **Job visible but no spawn**: missing landmarks
- **District console empty**: missing `grid_district` mapping
- **Courier says no routes**: missing receiver terminals/pads for destinations
- **Subsystem “works” but no effect**: map object not placed
- **Undefined type / implicit new hint**: weakly typed dynamic instantiation

---

## 7) Safe Way to Ship Big Features

Use phased merges:

1. **Foundation phase**: data + state + backend logic
2. **Interaction phase**: map objects + verbs/actions
3. **UI phase**: TGUI
4. **Balance phase**: constants only
5. **Ops phase**: docs + mapper checklist + admin test script

This prevents “all-at-once spaghetti” breakage.

---

## 8) Tuning Without Refactoring

Prefer adjusting top constants first:
- Subsystem define blocks (`#define ...`) for cadence/cost/reward
- Avoid rewriting logic if balance-only changes are needed

Track changes in one place, test, then iterate.

---

## 9) Map Authoring Contract (for team members)

Before claiming a system is broken, verify:

- Required objects are placed
- Required area tags exist
- Required landmarks exist
- Required paired machines (e.g., courier terminal + receiver terminal + receiver pad) are all present

If those are missing, it is a map config issue, not code logic.

---

## 10) Suggested “Definition of Done”

A feature is done only when:

1. DM compiles clean
2. TGUI compiles clean (if UI exists)
3. Required map objects listed in docs
4. Happy-path tested in-game
5. Failure-path tested (missing resources, wrong faction, sabotage, cooldowns)
6. README updated

---

## 11) Practical Command Snippets

Search quickly:

```powershell
rg -n "keyword" code fallout tgui -S
```

Check if something is included:

```powershell
rg -n "your_file.dm" hailmary.dme -S
```

Check if a map object type exists:

```powershell
rg -n "^/obj/.*/your_object_type" code fallout -S
```

---

## 12) Where to Start for Your Current Systems

- Reactor & Grid: `code/modules/f13/wasteland_grid.dm`
- Faction Economy & Contracts: `code/controllers/subsystem/faction_control.dm`
- Faction map machines: `code/modules/f13/faction_territory.dm`
- Courier/Parcel: `fallout/code/modules/QuestMachines/`
- Player bounties: `code/modules/f13/player_bounty_board.dm`
- Full mapper checklist: `README_FALLOUT_SYSTEMS.md`

