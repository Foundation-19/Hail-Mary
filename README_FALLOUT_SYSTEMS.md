# Fallout Systems Guide (Definitive Ops + Mapping README)

This guide covers the custom Fallout systems currently wired in this codebase, how to place/map them, and where to tune them.

If you only do one thing: follow the **Map Setup Checklist** first, then compile.

For overall project workflow/debugging conventions, also read:
- `README_CODEBASE_WORKFLOW.md`

---

## 1) Quick Build / Sanity Check

Run:

```powershell
tools/build/build dm
tools/build/build tgui
```

If `dm` passes, your core DM integration is valid.

---

## 2) System Overview

### A) Faction Control (district ownership + economy + utility)
- Core file: `code/controllers/subsystem/faction_control.dm`
- Map objects: `code/modules/f13/faction_territory.dm`
- UI: `tgui/packages/tgui/interfaces/FactionControl.tsx`

Includes:
- District claiming
- Treasury economy
- Upgrades (industry/logistics/security)
- Supply drops + caravans
- Contracts + world events
- Water/intel/hazard loops
- Research unlocks + doctrine buildables

### B) Wasteland Grid / Reactor / District Power
- Core file: `code/modules/f13/wasteland_grid.dm`
- UIs:
  - `tgui/packages/tgui/interfaces/WastelandGrid.tsx`
  - `tgui/packages/tgui/interfaces/GridDistrictDispatch.tsx`
  - `tgui/packages/tgui/interfaces/WastelandGridAdvisor.tsx`

Includes:
- Reactor simulation + alarms + faults + maintenance
- Low-pop fault suppression
- Automation mode
- Power auctions (MW allocation)
- District relay sabotage/repair loop
- Dispatch, forensics, theft/spent-fuel loops

### C) Courier / Parcel / Bounty Loop
- Main machines:
  - `fallout/code/modules/QuestMachines/faction_bounty_machines.dm`
  - `fallout/code/modules/QuestMachines/parcel_receiver.dm`
  - `fallout/code/modules/QuestMachines/parcel.dm`
- Player bounty board:
  - `code/modules/f13/player_bounty_board.dm`
  - `tgui/packages/tgui/interfaces/PlayerBountyBoard.tsx`

### D) Mass Fusion Faction + Roles
- Jobs: `code/modules/jobs/job_types/mass_fusion.dm`
- Spawn landmarks: `code/game/objects/effects/landmarks.dm`

### E) Tribal Hunt Rewards
- Reward logic: `code/controllers/subsystem/faction_control.dm` (`reward_tribal_hunt_kill`)
- Hook: `code/modules/mob/living/simple_animal/hostile/hostile.dm` on hostile death

---

## 3) Map Setup Checklist (Out-of-the-box)

## 3.1 District tagging (required)
Your areas must resolve to districts. Best practice: set `grid_district` on areas.

Valid district labels used by current systems:
- `BOS`
- `NCR`
- `Legion`
- `Town`
- `Mass Fusion`
- (optional for faction gameplay) `Tribe`

If `grid_district` is missing, fallback inference tries area type/name, but explicit tags are safer.

## 3.2 Faction district control nodes
Place at least one per capturable district:
- `/obj/machinery/f13/faction_capture_node`

Optional but recommended near each node:
- `/obj/machinery/f13/faction_resource_pad`
- `/obj/machinery/f13/faction_water_purifier`
- `/obj/machinery/f13/faction_intel_tower`
- `/obj/machinery/f13/faction_turret_controller`

Flow:
1) Player of controllable faction uses relay node.
2) Claims district.
3) Scans nearby resource pad (within node scan range).
4) District economy loops begin.

## 3.3 Reactor + Grid
Place your reactor components/consoles from `wasteland_grid.dm` and ensure your operational room has:
- Main reactor console (`WastelandGrid`)
- Advisor console (`WastelandGridAdvisor`)
- Dispatch console (`GridDistrictDispatch`)

District power relay stack (per district):
- `/obj/structure/grid/power_relay` with `district = "<DistrictName>"`
- `/obj/structure/grid/relay_breaker_box` with same district
- `/obj/machinery/f13/grid_relay_console` (or subtype `/bos`, `/ncr`, `/legion`, `/town`, `/massfusion`)
- Optional deco: `/obj/structure/grid/relay_tower` (indestructible tower object)

## 3.4 Courier loop
For each faction base:
- Place one courier/faction bounty terminal
- Place one receiver pair:
  - `/obj/structure/parcel_receiver_pad`
  - `/obj/machinery/parcel_receiver_terminal`

Parcels are generated from courier terminals and must be delivered to receiver pads, then finalized at receiver terminal.

## 3.5 Mass Fusion jobs (required if you want playable faction)
Place all these landmarks:
- `/obj/effect/landmark/start/f13/massfusionsupervisor`
- `/obj/effect/landmark/start/f13/massfusionscavenger`
- `/obj/effect/landmark/start/f13/massfusionreactoroperator`
- `/obj/effect/landmark/start/f13/massfusiongridtechnician`
- `/obj/effect/landmark/start/f13/massfusionrelayengineer`
- `/obj/effect/landmark/start/f13/massfusionhazardrecovery`

If landmarks are missing, jobs may appear but not spawn correctly (or be hidden by setup rules).

## 3.6 Full Placement Manifest (copy/paste for mappers)

Use this as the definitive placement list for Reactor + District Power + Courier/Bounty.

### Reactor Core Objects
- `/obj/structure/f13/grid_radiation_source`
- `/obj/machinery/f13/wasteland_grid_console`
- `/obj/machinery/f13/wasteland_grid_advisor_console`
- `/obj/structure/f13/work_order_board`
- `/obj/machinery/grid/pump`
- `/obj/structure/grid/filter_unit`
- `/obj/structure/grid/heat_exchanger`
- `/obj/structure/grid/turbine_assembly`
- `/obj/machinery/grid/turbine_controller`
- `/obj/structure/grid/sensor_panel`
- `/obj/structure/grid/relief_valve`
- `/obj/structure/grid/purge_valve`
- `/obj/structure/grid/breaker_cabinet`

### District Power / Relay Network (per district)
- `/obj/structure/grid/power_relay` (`district = "BOS"|"NCR"|"Legion"|"Town"|"Mass Fusion"`)
- `/obj/structure/grid/relay_breaker_box` (same `district`)
- `/obj/machinery/f13/grid_relay_console` (or subtype below)
  - `/obj/machinery/f13/grid_relay_console/bos`
  - `/obj/machinery/f13/grid_relay_console/ncr`
  - `/obj/machinery/f13/grid_relay_console/legion`
  - `/obj/machinery/f13/grid_relay_console/town`
  - `/obj/machinery/f13/grid_relay_console/massfusion`
- Optional visual tower:
  - `/obj/structure/grid/relay_tower`

### District Dispatch / Faction District Console
- `/obj/machinery/f13/grid_faction_district_console` (or faction subtype)
  - `/obj/machinery/f13/grid_faction_district_console/bos`
  - `/obj/machinery/f13/grid_faction_district_console/ncr`
  - `/obj/machinery/f13/grid_faction_district_console/legion`
  - `/obj/machinery/f13/grid_faction_district_console/town`
  - `/obj/machinery/f13/grid_faction_district_console/massfusion`

### Faction Territory Utility Objects
- `/obj/machinery/f13/faction_capture_node`
- `/obj/machinery/f13/faction_resource_pad`
- `/obj/machinery/f13/faction_water_purifier`
- `/obj/machinery/f13/faction_intel_tower`
- `/obj/machinery/f13/faction_turret_controller`

### Courier / Parcel Route Objects
- Courier issue terminals:
  - `/obj/machinery/bounty_machine/faction/courier/town`
  - `/obj/machinery/bounty_machine/faction/courier/ncr`
  - `/obj/machinery/bounty_machine/faction/courier/legion`
  - `/obj/machinery/bounty_machine/faction/courier/bos`
  - `/obj/machinery/bounty_machine/faction/courier/massfusion`
- Receiver pads:
  - `/obj/structure/f13/parcel_receiver_pad/town`
  - `/obj/structure/f13/parcel_receiver_pad/ncr`
  - `/obj/structure/f13/parcel_receiver_pad/legion`
  - `/obj/structure/f13/parcel_receiver_pad/bos`
  - `/obj/structure/f13/parcel_receiver_pad/massfusion`
- Receiver terminals:
  - `/obj/machinery/f13/parcel_receiver_terminal/town`
  - `/obj/machinery/f13/parcel_receiver_terminal/ncr`
  - `/obj/machinery/f13/parcel_receiver_terminal/legion`
  - `/obj/machinery/f13/parcel_receiver_terminal/bos`
  - `/obj/machinery/f13/parcel_receiver_terminal/massfusion`

### Bounty Boards / Bounty Machines
- Player-created bounty board:
  - `/obj/machinery/f13/player_bounty_board`
- Classic bounty system:
  - `/obj/machinery/bounty_machine`
  - `/obj/machinery/bounty_pod` (near the bounty machine)
- Optional faction bounty machine:
  - `/obj/machinery/bounty_machine/faction`

### Minimum “it works” map set
At absolute minimum for the integrated loops:
1) One reactor console + advisor + work board
2) One relay node + resource pad per active district
3) One power relay + breaker + relay console per active district
4) One courier terminal and one receiver terminal+pad for each participating faction base
5) Mass Fusion job spawn landmarks if you want that faction playable

---

## 4) Economy + MW Auction Integration (How it works)

MW auctions are run by grid logic, and faction impact/rewards are handed to faction control.

Current model:
- Districts/factions bid caps for MW allocation.
- Caps are escrowed and settled on auction close.
- MW allocations are committed by district.
- Research points can be awarded per MW (`GRID_AUCTION_RESEARCH_PER_MW` in `wasteland_grid.dm`).

To increase available MW:
- Improve plant condition and stability
- Complete overhaul cycles
- Keep faults under control and relay network online
- Tune auction capacity constants in `wasteland_grid.dm`

---

## 5) Key Tuning Knobs

## 5.1 Faction control knobs
Top of `code/controllers/subsystem/faction_control.dm`:
- Income cadence and base values, supply costs/cooldowns
- Caravan duration/cost/max active
- Contract/event frequency and rewards
- Utility/stability/water/intel/hazard constants

## 5.2 Grid/reactor knobs
`code/modules/f13/wasteland_grid.dm`:
- Automation threshold (`grid_auto_player_threshold`)
- Low-pop maintenance/fault suppression threshold (`grid_lowpop_faults_threshold`)
- Alarm behavior (manual + auto-danger)
- Auction supply/research constants (`GRID_AUCTION_*`)
- Fault generation/escalation and maintenance task creation

## 5.3 Tribal hunt rewards
`code/controllers/subsystem/faction_control.dm`:
- `reward_tribal_hunt_kill`
- Treasury/research/rep gain formula by target toughness

---

## 6) Add a New Faction (Pattern)

1) Add defines/faction identity:
- `code/__DEFINES/jobs.dm`
- `fallout/code/modules/factions.dm` (if needed by your social/faction systems)

2) Add job positions and category:
- `code/modules/jobs/jobs.dm` (position lists + category entries)
- `code/modules/jobs/job_types/<new_faction>.dm`

3) Add spawn landmarks:
- `code/game/objects/effects/landmarks.dm`

4) Add faction control support:
- Include faction in `controllable_factions` in `faction_control.dm`
- Add aliases in `faction_aliases`
- Optionally add faction-specific doctrine buildable template

5) Add district routing support:
- Tag areas with `grid_district`
- Add relay objects if district-level outage gameplay is desired

---

## 7) Troubleshooting

## "undefined type path /obj/structure/f13/faction_caravan_marker"
- Ensure `code/modules/f13/faction_territory.dm` is included in `hailmary.dme`.
- Ensure no dynamic `new` is used without resolvable typed path (already fixed in subsystem).

## "Faction/job not visible in job menu"
- Verify job is in `jobs.dm` position/category list.
- Verify job file is included in `hailmary.dme`.
- Verify matching start landmarks exist on map.

## District console says missing/empty districts
- Your areas likely lack `grid_district` tags and name/type inference failed.
- Add explicit `grid_district` for mapped areas.

## Courier terminal says no valid routes
- Missing receiver terminals/pads for destination factions.
- Place receiver pad + receiver terminal in each target faction base.

---

## 8) Recommended Admin Validation Pass (5 minutes)

1) Spawn into each faction and claim a district node.
2) Confirm resource pad links and starts output.
3) Open faction console and verify district appears.
4) Open reactor console and verify alarms/fault tabs update.
5) Sabotage/repair one district relay and confirm district power toggles.
6) Run one courier parcel from terminal -> receiver pad -> receiver terminal.
7) Kill one hostile as Tribal and confirm treasury/research reward message.

If all 7 pass, your setup is production-ready.
