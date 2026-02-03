// code/controllers/subsystem/faction_control.dm
// District ownership + faction economy + utility control hooks.

#define FACTION_CTRL_TICK 5 SECONDS
#define FACTION_CTRL_PAYOUT_EVERY 30 SECONDS
#define FACTION_CTRL_DEFAULT_DISTRICT_INCOME 8
#define FACTION_CTRL_GRID_DOWN_MULT 0.5
#define FACTION_CTRL_CAPTURE_DECAY 4
#define FACTION_CTRL_CAPTURE_GAIN 12
#define FACTION_CTRL_SUPPLY_COST 80
#define FACTION_CTRL_OVERRIDE_COST 65
#define FACTION_CTRL_SUPPLY_COOLDOWN 8 MINUTES
#define FACTION_CTRL_OVERRIDE_COOLDOWN 4 MINUTES
#define FACTION_CTRL_OVERRIDE_BLACKOUT 90 SECONDS
#define FACTION_CTRL_BANNED_CAPTURE_DECAY 6
#define FACTION_CTRL_RESOURCE_EVERY 10 MINUTES
#define FACTION_CTRL_RESOURCE_METAL 500
#define FACTION_CTRL_RESOURCE_BLACKPOWDER 100
#define FACTION_CTRL_RESOURCE_CAPS 2000
#define FACTION_CTRL_SUPPLY_DROP_METAL 250
#define FACTION_CTRL_SUPPLY_DROP_BLACKPOWDER 50
#define FACTION_CTRL_SUPPLY_DROP_CAPS 1000
#define FACTION_CTRL_RARE_CRAFT_CHANCE 35
#define FACTION_CTRL_RARE_CRAFT_MAX_ROLLS 2
#define FACTION_CTRL_CONTRACT_INTERVAL 4 MINUTES
#define FACTION_CTRL_CONTRACTS_PER_FACTION 3
#define FACTION_CTRL_CONTRACT_DURATION 25 MINUTES
#define FACTION_CTRL_CONTRACT_REWARD_CAPS 110
#define FACTION_CTRL_CONTRACT_REWARD_REP 3
#define FACTION_CTRL_CONTRACT_REWARD_RESEARCH 8
#define FACTION_CTRL_EVENT_INTERVAL 12 MINUTES
#define FACTION_CTRL_EVENT_DURATION 8 MINUTES
#define FACTION_CTRL_CARAVAN_DURATION 5 MINUTES
#define FACTION_CTRL_CARAVAN_COST 60
#define FACTION_CTRL_MAX_ACTIVE_CARAVANS 2
#define FACTION_CTRL_UPGRADE_MAX_LEVEL 3
#define FACTION_CTRL_UPGRADE_COST_BASE 120
#define FACTION_CTRL_UTILITY_EVAL_EVERY 45 SECONDS
#define FACTION_CTRL_STABILITY_START 60
#define FACTION_CTRL_STABILITY_LOW 35
#define FACTION_CTRL_STABILITY_CRITICAL 18
#define FACTION_CTRL_WATER_NODE_OUTPUT 28
#define FACTION_CTRL_INTEL_PER_TOWER 2
#define FACTION_CTRL_INTEL_REVEAL_COST 25
#define FACTION_CTRL_INTEL_JAM_COST 35
#define FACTION_CTRL_INTEL_FAKE_COST 20
#define FACTION_CTRL_INTEL_REVEAL_DURATION 5 MINUTES
#define FACTION_CTRL_INTEL_JAM_DURATION 4 MINUTES
#define FACTION_CTRL_HAZARD_INTERVAL 9 MINUTES
#define FACTION_CTRL_HAZARD_DURATION 7 MINUTES
#define FACTION_CTRL_HAZARD_EXTRACT_COOLDOWN 4 MINUTES
#define FACTION_CTRL_HAZARD_EXTRACT_COST 30

SUBSYSTEM_DEF(faction_control)
	name = "Faction Control"
	wait = FACTION_CTRL_TICK
	priority = 36
	flags = SS_BACKGROUND

	/// district id => owning faction
	var/list/district_owner = list()
	/// district id => base income
	var/list/district_income = list()
	/// faction => funds
	var/list/faction_funds = list()
	/// "faction|district" => cooldown end
	var/list/override_cd = list()
	/// faction => cooldown end
	var/list/supply_cd = list()
	/// active capture nodes
	var/list/capture_nodes = list()
	/// active resource pads
	var/list/resource_pads = list()
	/// active water nodes/purifiers
	var/list/water_nodes = list()
	/// active intel towers
	var/list/intel_towers = list()
	/// counter for auto-generated district ids used by relay nodes
	var/next_dynamic_district_id = 1
	/// district id => list("industry"=0,"logistics"=0,"security"=0)
	var/list/district_upgrades = list()
	/// faction => list(/datum/faction_control_contract)
	var/list/faction_contracts = list()
	/// active world events
	var/list/active_events = list()
	/// active caravan routes
	var/list/active_caravans = list()
	/// "[faction]|[district]" => successful supply drops
	var/list/supply_count_by_key = list()
	/// "[faction]|[district]" => completed caravans arriving into district
	var/list/caravan_count_by_key = list()
	/// "[faction]|[district]" => completed hazard extraction runs
	var/list/hazard_extract_count_by_key = list()
	/// faction => research points
	var/list/faction_research_points = list()
	/// faction => unlocked research tier
	var/list/faction_research_tier = list()
	/// faction => associative set of unlocked research project ids
	var/list/faction_research_unlocks = list()
	/// cached research project definitions
	var/list/research_project_defs = null
	/// ckey => list(faction => reputation)
	var/list/player_rep_by_ckey = list()
	/// district => current water score (0..100)
	var/list/district_water = list()
	/// district => current logistics health score (0..100)
	var/list/district_logistics_health = list()
	/// district => settlement stability (0..100)
	var/list/district_stability = list()
	/// district => world.time when the latest supply drop landed
	var/list/district_last_supply_time = list()
	/// district => world.time when the latest caravan arrived
	var/list/district_last_caravan_time = list()
	/// district => world.time until local comms are jammed
	var/list/district_jam_until = list()
	/// district => world.time of last generated crisis event
	var/list/district_last_crisis_event = list()
	/// district => cached utility state list("power"=BOOL, "water"=BOOL, "logistics"=BOOL)
	var/list/district_utility_cache = list()
	/// faction => intel points
	var/list/faction_intel_points = list()
	/// faction => world.time until enemy caravan routes are revealed
	var/list/faction_route_reveal_until = list()
	/// active hazard windows
	var/list/active_hazard_zones = list()
	/// "[faction]|[district]" => world.time cooldown for hazard extraction
	var/list/hazard_extract_cd = list()
	/// district => list("kind","name","faction","desc")
	var/list/district_buildables = list()
	/// monotonically increasing ids for generated content
	var/next_contract_id = 1
	var/next_event_id = 1
	var/next_caravan_id = 1
	var/next_hazard_id = 1
	/// world.time schedulers
	var/next_contract_roll = 0
	var/next_event_roll = 0
	var/next_utility_eval = 0
	var/next_hazard_roll = 0
	/// canonical factions that can run control gameplay
	var/list/controllable_factions = list(FACTION_BROTHERHOOD, FACTION_NCR, FACTION_LEGION, FACTION_EASTWOOD)
	/// alias map => canonical faction
	var/list/faction_aliases = list(
		"bos" = FACTION_BROTHERHOOD,
		"bs" = FACTION_BROTHERHOOD,
		"brotherhood" = FACTION_BROTHERHOOD,
		"steel rangers" = FACTION_BROTHERHOOD,
		"ncr" = FACTION_NCR,
		"legion" = FACTION_LEGION,
		"red eye army" = FACTION_LEGION,
		"town" = FACTION_EASTWOOD,
		"city" = FACTION_EASTWOOD,
		"eastwood" = FACTION_EASTWOOD
	)
	/// world.time
	var/next_payout = 0

/datum/controller/subsystem/faction_control/Initialize(timeofday)
	. = ..()
	bootstrap_districts()
	roll_contracts()
	next_payout = world.time + FACTION_CTRL_PAYOUT_EVERY
	next_contract_roll = world.time + FACTION_CTRL_CONTRACT_INTERVAL
	next_event_roll = world.time + FACTION_CTRL_EVENT_INTERVAL
	next_utility_eval = world.time + FACTION_CTRL_UTILITY_EVAL_EVERY
	next_hazard_roll = world.time + FACTION_CTRL_HAZARD_INTERVAL

/datum/controller/subsystem/faction_control/fire(resumed = FALSE)
	if(world.time >= next_payout)
		process_income_payout()
		next_payout = world.time + FACTION_CTRL_PAYOUT_EVERY

	if(world.time >= next_contract_roll)
		roll_contracts()
		next_contract_roll = world.time + FACTION_CTRL_CONTRACT_INTERVAL

	if(world.time >= next_event_roll)
		spawn_world_event()
		next_event_roll = world.time + FACTION_CTRL_EVENT_INTERVAL

	if(world.time >= next_utility_eval)
		process_utility_state()
		next_utility_eval = world.time + FACTION_CTRL_UTILITY_EVAL_EVERY

	if(world.time >= next_hazard_roll)
		roll_hazard_zone()
		next_hazard_roll = world.time + FACTION_CTRL_HAZARD_INTERVAL

	process_world_events()
	process_hazard_zones()
	process_caravans()
	process_capture_nodes()
	process_resource_pads()
	process_intel_towers()

/datum/controller/subsystem/faction_control/proc/bootstrap_districts()
	if(!islist(district_owner)) district_owner = list()
	if(!islist(district_income)) district_income = list()
	if(!islist(faction_funds)) faction_funds = list()
	if(!islist(override_cd)) override_cd = list()
	if(!islist(supply_cd)) supply_cd = list()
	if(!islist(capture_nodes)) capture_nodes = list()
	if(!islist(resource_pads)) resource_pads = list()
	if(!islist(water_nodes)) water_nodes = list()
	if(!islist(intel_towers)) intel_towers = list()
	if(!islist(district_upgrades)) district_upgrades = list()
	if(!islist(faction_contracts)) faction_contracts = list()
	if(!islist(active_events)) active_events = list()
	if(!islist(active_caravans)) active_caravans = list()
	if(!islist(supply_count_by_key)) supply_count_by_key = list()
	if(!islist(caravan_count_by_key)) caravan_count_by_key = list()
	if(!islist(hazard_extract_count_by_key)) hazard_extract_count_by_key = list()
	if(!islist(faction_research_points)) faction_research_points = list()
	if(!islist(faction_research_tier)) faction_research_tier = list()
	if(!islist(faction_research_unlocks)) faction_research_unlocks = list()
	if(!islist(player_rep_by_ckey)) player_rep_by_ckey = list()
	if(!islist(district_water)) district_water = list()
	if(!islist(district_logistics_health)) district_logistics_health = list()
	if(!islist(district_stability)) district_stability = list()
	if(!islist(district_last_supply_time)) district_last_supply_time = list()
	if(!islist(district_last_caravan_time)) district_last_caravan_time = list()
	if(!islist(district_jam_until)) district_jam_until = list()
	if(!islist(district_last_crisis_event)) district_last_crisis_event = list()
	if(!islist(district_utility_cache)) district_utility_cache = list()
	if(!islist(faction_intel_points)) faction_intel_points = list()
	if(!islist(faction_route_reveal_until)) faction_route_reveal_until = list()
	if(!islist(active_hazard_zones)) active_hazard_zones = list()
	if(!islist(hazard_extract_cd)) hazard_extract_cd = list()
	if(!islist(district_buildables)) district_buildables = list()
	if(!islist(controllable_factions) || !length(controllable_factions))
		controllable_factions = list(FACTION_BROTHERHOOD, FACTION_NCR, FACTION_LEGION, FACTION_EASTWOOD)
	if(!islist(faction_aliases) || !length(faction_aliases))
		faction_aliases = list()

	for(var/f in controllable_factions)
		if(isnull(faction_research_points[f]))
			faction_research_points[f] = 0
		if(isnull(faction_research_tier[f]))
			faction_research_tier[f] = 0
		if(!islist(faction_research_unlocks[f]))
			faction_research_unlocks[f] = list()
		if(!islist(faction_contracts[f]))
			faction_contracts[f] = list()
		if(isnull(faction_intel_points[f]))
			faction_intel_points[f] = 0
		if(isnull(faction_route_reveal_until[f]))
			faction_route_reveal_until[f] = 0

	for(var/area/A in world)
		if(!A) continue
		var/d = get_district_for_area(A)
		if(!istext(d) || !length(d)) continue
		if(isnull(district_income[d]))
			district_income[d] = FACTION_CTRL_DEFAULT_DISTRICT_INCOME
		ensure_upgrade_row(d)
		if(isnull(district_water[d]))
			district_water[d] = 55
		if(isnull(district_logistics_health[d]))
			district_logistics_health[d] = 55
		if(isnull(district_stability[d]))
			district_stability[d] = FACTION_CTRL_STABILITY_START

/datum/controller/subsystem/faction_control/proc/register_capture_node(obj/machinery/f13/faction_capture_node/N)
	if(!N) return
	if(!(N in capture_nodes))
		capture_nodes += N

/datum/controller/subsystem/faction_control/proc/unregister_capture_node(obj/machinery/f13/faction_capture_node/N)
	if(!N) return
	capture_nodes -= N

/datum/controller/subsystem/faction_control/proc/register_resource_pad(obj/machinery/f13/faction_resource_pad/P)
	if(!P) return
	if(!(P in resource_pads))
		resource_pads += P

/datum/controller/subsystem/faction_control/proc/unregister_resource_pad(obj/machinery/f13/faction_resource_pad/P)
	if(!P) return
	resource_pads -= P

/datum/controller/subsystem/faction_control/proc/register_water_node(obj/machinery/f13/faction_water_purifier/W)
	if(!W) return
	if(!(W in water_nodes))
		water_nodes += W

/datum/controller/subsystem/faction_control/proc/unregister_water_node(obj/machinery/f13/faction_water_purifier/W)
	if(!W) return
	water_nodes -= W

/datum/controller/subsystem/faction_control/proc/register_intel_tower(obj/machinery/f13/faction_intel_tower/T)
	if(!T) return
	if(!(T in intel_towers))
		intel_towers += T

/datum/controller/subsystem/faction_control/proc/unregister_intel_tower(obj/machinery/f13/faction_intel_tower/T)
	if(!T) return
	intel_towers -= T

/datum/controller/subsystem/faction_control/proc/process_intel_towers()
	if(!length(intel_towers)) return
	var/list/remove = list()
	for(var/obj/machinery/f13/faction_intel_tower/T in intel_towers)
		if(!T || QDELETED(T))
			remove += T
			continue
		T.process_intel_tick()
		if(MC_TICK_CHECK)
			break
	intel_towers -= remove

/datum/controller/subsystem/faction_control/proc/process_capture_nodes()
	if(!length(capture_nodes)) return

	var/list/remove = list()
	for(var/obj/machinery/f13/faction_capture_node/N in capture_nodes)
		if(!N || QDELETED(N))
			remove += N
			continue
		N.process_capture_tick()
		if(MC_TICK_CHECK)
			break
	capture_nodes -= remove

/datum/controller/subsystem/faction_control/proc/process_resource_pads()
	if(!length(resource_pads)) return

	var/list/remove = list()
	for(var/obj/machinery/f13/faction_resource_pad/P in resource_pads)
		if(!P || QDELETED(P))
			remove += P
			continue
		P.process_resource_tick()
		if(MC_TICK_CHECK)
			break
	resource_pads -= remove

/datum/controller/subsystem/faction_control/proc/get_faction_research_tier(faction)
	if(!faction) return 0
	var/v = faction_research_tier[faction]
	if(isnull(v)) return 0
	return clamp(round(v), 0, 4)

/datum/controller/subsystem/faction_control/proc/get_faction_research_points(faction)
	if(!faction) return 0
	var/v = faction_research_points[faction]
	if(isnull(v)) return 0
	return max(0, round(v))

/datum/controller/subsystem/faction_control/proc/add_research_points(faction, amount)
	if(!faction || amount <= 0) return
	faction_research_points[faction] = get_faction_research_points(faction) + round(amount)

/datum/controller/subsystem/faction_control/proc/get_research_unlock_cost(next_tier)
	switch(next_tier)
		if(1) return 40
		if(2) return 85
		if(3) return 140
		if(4) return 220
	return 9999

/datum/controller/subsystem/faction_control/proc/unlock_next_research(mob/user)
	if(!user) return FALSE
	var/f = get_mob_faction(user)
	if(!f || !is_controllable_faction(f))
		to_chat(user, span_warning("Your faction cannot access research tracks."))
		return FALSE

	var/tier = get_faction_research_tier(f)
	if(tier >= 4)
		to_chat(user, span_notice("All faction research tracks are already unlocked."))
		return FALSE

	var/next_tier = tier + 1
	var/cost = get_research_unlock_cost(next_tier)
	var/pts = get_faction_research_points(f)
	if(pts < cost)
		to_chat(user, span_warning("Research points required: [cost] (current [pts])."))
		return FALSE

	faction_research_points[f] = pts - cost
	faction_research_tier[f] = next_tier
	world << span_notice("[f] unlocked research tier [next_tier].")
	return TRUE

/datum/controller/subsystem/faction_control/proc/get_research_project_defs()
	if(islist(research_project_defs) && length(research_project_defs))
		return research_project_defs

	research_project_defs = list(
		list(
			"id" = "res_salvage_protocols",
			"name" = "Salvage Protocols",
			"track" = "Industry",
			"tier" = 1,
			"cost" = 55,
			"desc" = "Standardize salvage teams and scrap processing.",
			"effect" = "+20% metal output, +10% blackpowder output.",
			"exclusive_group" = null,
			"requires" = list()
		),
		list(
			"id" = "doc_industry_focus",
			"name" = "Doctrine: Industry",
			"track" = "Doctrine",
			"tier" = 1,
			"cost" = 60,
			"desc" = "Prioritize extraction, smelting, and field manufacturing.",
			"effect" = "Material production is higher across district outputs.",
			"exclusive_group" = "core_doctrine",
			"requires" = list()
		),
		list(
			"id" = "doc_military_focus",
			"name" = "Doctrine: Military",
			"track" = "Doctrine",
			"tier" = 1,
			"cost" = 60,
			"desc" = "Prioritize frontline logistics and munitions throughput.",
			"effect" = "Ammo output and combat contract rewards are stronger.",
			"exclusive_group" = "core_doctrine",
			"requires" = list()
		),
		list(
			"id" = "doc_medical_focus",
			"name" = "Doctrine: Medical",
			"track" = "Doctrine",
			"tier" = 1,
			"cost" = 60,
			"desc" = "Prioritize field hospitals, trauma support, and stabilization teams.",
			"effect" = "Faction contracts grant bonus reputation and research.",
			"exclusive_group" = "core_doctrine",
			"requires" = list()
		),
		list(
			"id" = "doc_power_focus",
			"name" = "Doctrine: Power",
			"track" = "Doctrine",
			"tier" = 1,
			"cost" = 60,
			"desc" = "Prioritize grid reliability, relay hardening, and power routing.",
			"effect" = "Owned districts gain extra income while local grids are online.",
			"exclusive_group" = "core_doctrine",
			"requires" = list()
		),
		list(
			"id" = "sec_ballistics_doctrine",
			"name" = "Ballistics Doctrine",
			"track" = "Security",
			"tier" = 1,
			"cost" = 65,
			"desc" = "Prioritize ballistic weapons in district arsenals.",
			"effect" = "Security upgrades spawn extra ballistic ammo.",
			"exclusive_group" = "security_doctrine",
			"requires" = list()
		),
		list(
			"id" = "sec_energy_doctrine",
			"name" = "Energy Doctrine",
			"track" = "Security",
			"tier" = 1,
			"cost" = 65,
			"desc" = "Prioritize energy-cell logistics and issue protocols.",
			"effect" = "Security upgrades can produce ammo energy cells.",
			"exclusive_group" = "security_doctrine",
			"requires" = list()
		),
		list(
			"id" = "logi_bulk_freight",
			"name" = "Bulk Freight Protocols",
			"track" = "Logistics",
			"tier" = 2,
			"cost" = 95,
			"desc" = "Wider caravans and denser cargo packing.",
			"effect" = "Caravan rewards +20%, district output +10%.",
			"exclusive_group" = "logistics_doctrine",
			"requires" = list()
		),
		list(
			"id" = "logi_rapid_dispatch",
			"name" = "Rapid Dispatch Protocols",
			"track" = "Logistics",
			"tier" = 2,
			"cost" = 95,
			"desc" = "Lean convoy routes and aggressive turnaround schedules.",
			"effect" = "Supply cooldown and caravan travel time reduced.",
			"exclusive_group" = "logistics_doctrine",
			"requires" = list()
		),
		list(
			"id" = "ind_smelter_chain",
			"name" = "Smelter Chain",
			"track" = "Industry",
			"tier" = 2,
			"cost" = 105,
			"desc" = "Field smelters produce refined composite materials.",
			"effect" = "Industry can generate plasteel bundles.",
			"exclusive_group" = null,
			"requires" = list("res_salvage_protocols")
		),
		list(
			"id" = "ind_advanced_forges",
			"name" = "Advanced Forges",
			"track" = "Industry",
			"tier" = 3,
			"cost" = 140,
			"desc" = "High-heat process unlocks aerospace-grade outputs.",
			"effect" = "Industry can generate titanium bundles.",
			"exclusive_group" = null,
			"requires" = list("ind_smelter_chain")
		),
		list(
			"id" = "sec_munitions_fabricator",
			"name" = "Munitions Fabricator",
			"track" = "Security",
			"tier" = 3,
			"cost" = 130,
			"desc" = "Distributed ammo fabs support frontline loadouts.",
			"effect" = "Security yields more and higher-tier ammo.",
			"exclusive_group" = null,
			"requires" = list("sec_ballistics_doctrine", "sec_energy_doctrine")
		),
		list(
			"id" = "ops_supply_automation",
			"name" = "Supply Automation",
			"track" = "Operations",
			"tier" = 4,
			"cost" = 180,
			"desc" = "Authorize automated beacon requisition systems.",
			"effect" = "Unlocks faction supply beacon terminals.",
			"exclusive_group" = null,
			"requires" = list()
		),
		list(
			"id" = "ops_strategic_override",
			"name" = "Strategic Grid Override",
			"track" = "Operations",
			"tier" = 4,
			"cost" = 180,
			"desc" = "Authorize strategic district power operations.",
			"effect" = "Unlocks faction grid override panels.",
			"exclusive_group" = null,
			"requires" = list()
		),
		list(
			"id" = "ops_turret_uplink",
			"name" = "Turret Uplink Doctrine",
			"track" = "Operations",
			"tier" = 4,
			"cost" = 180,
			"desc" = "Authorize district-wide defensive uplink control.",
			"effect" = "Unlocks faction turret controller networks.",
			"exclusive_group" = null,
			"requires" = list()
		),
		list(
			"id" = "ops_signal_warfare",
			"name" = "Signal Warfare Suite",
			"track" = "Operations",
			"tier" = 3,
			"cost" = 145,
			"desc" = "Advanced interception and spoofing protocols for district intel towers.",
			"effect" = "Unlocks district jamming and fake distress counter-intel operations.",
			"exclusive_group" = null,
			"requires" = list()
		),
		list(
			"id" = "ops_hazard_extraction",
			"name" = "Hazard Extraction Protocols",
			"track" = "Operations",
			"tier" = 4,
			"cost" = 180,
			"desc" = "Field safety doctrine for timed extraction runs in reactor/weather hazard zones.",
			"effect" = "Unlocks hazard extraction terminals and boosts rare material recovery.",
			"exclusive_group" = null,
			"requires" = list()
		)
	)
	return research_project_defs

/datum/controller/subsystem/faction_control/proc/get_research_project(project_id)
	if(!project_id) return null
	for(var/list/P in get_research_project_defs())
		if(P["id"] == project_id)
			return P
	return null

/datum/controller/subsystem/faction_control/proc/ensure_research_unlock_row(faction)
	if(!faction) return
	if(!islist(faction_research_unlocks[faction]))
		faction_research_unlocks[faction] = list()

/datum/controller/subsystem/faction_control/proc/has_research_unlock(faction, project_id)
	if(!faction || !project_id) return FALSE
	ensure_research_unlock_row(faction)
	var/list/U = faction_research_unlocks[faction]
	return !!U[project_id]

/datum/controller/subsystem/faction_control/proc/get_research_block_reason(faction, project_id)
	if(!faction || !project_id)
		return "Invalid request."
	var/list/P = get_research_project(project_id)
	if(!islist(P))
		return "Unknown project."
	if(has_research_unlock(faction, project_id))
		return "Already unlocked."

	var/need_tier = round(P["tier"])
	if(get_faction_research_tier(faction) < need_tier)
		return "Requires research tier [need_tier]."

	var/list/requires = P["requires"]
	if(islist(requires) && length(requires))
		for(var/r in requires)
			if(!r) continue
			if(has_research_unlock(faction, r))
				continue
			// For doctrine pair requirements (ballistics OR energy), allow either.
			if(project_id == "sec_munitions_fabricator" && r == "sec_energy_doctrine" && has_research_unlock(faction, "sec_ballistics_doctrine"))
				continue
			if(project_id == "sec_munitions_fabricator" && r == "sec_ballistics_doctrine" && has_research_unlock(faction, "sec_energy_doctrine"))
				continue
			var/list/RP = get_research_project(r)
			if(islist(RP))
				return "Requires [RP["name"]]."
			return "Missing prerequisite."

	var/group = P["exclusive_group"]
	if(istext(group) && length(group))
		for(var/list/Other in get_research_project_defs())
			if(!islist(Other)) continue
			if(Other["exclusive_group"] != group) continue
			var/other_id = Other["id"]
			if(other_id == project_id) continue
			if(has_research_unlock(faction, other_id))
				return "Locked by doctrine choice: [Other["name"]]."

	return null

/datum/controller/subsystem/faction_control/proc/unlock_research_project(mob/user, project_id)
	if(!user || !project_id) return FALSE
	var/f = get_mob_faction(user)
	if(!f || !is_controllable_faction(f))
		to_chat(user, span_warning("Your faction cannot access research projects."))
		return FALSE

	var/list/P = get_research_project(project_id)
	if(!islist(P))
		to_chat(user, span_warning("Unknown research project."))
		return FALSE

	var/reason = get_research_block_reason(f, project_id)
	if(istext(reason) && length(reason))
		to_chat(user, span_warning(reason))
		return FALSE

	var/cost = max(1, round(P["cost"]))
	var/pts = get_faction_research_points(f)
	if(pts < cost)
		to_chat(user, span_warning("Research points required: [cost] (current [pts])."))
		return FALSE

	ensure_research_unlock_row(f)
	faction_research_points[f] = pts - cost
	var/list/U = faction_research_unlocks[f]
	U[project_id] = TRUE
	world << span_notice("[f] completed research project: [P["name"]].")
	return TRUE

/datum/controller/subsystem/faction_control/proc/get_research_rows(faction)
	var/list/rows = list()
	if(!faction) return rows
	for(var/list/P in get_research_project_defs())
		if(!islist(P)) continue
		var/id = "[P["id"]]"
		var/cost = max(1, round(P["cost"]))
		var/unlocked = has_research_unlock(faction, id)
		var/reason = null
		var/available = FALSE
		if(!unlocked)
			reason = get_research_block_reason(faction, id)
			if(!reason)
				if(get_faction_research_points(faction) < cost)
					reason = "Need [cost] RP."
				else
					available = TRUE
		rows += list(list(
			"id" = id,
			"name" = "[P["name"]]",
			"track" = "[P["track"]]",
			"tier" = round(P["tier"]),
			"cost" = cost,
			"desc" = "[P["desc"]]",
			"effect" = "[P["effect"]]",
			"unlocked" = !!unlocked,
			"available" = !!available,
			"blocked_reason" = reason ? "[reason]" : ""
		))
	return rows

/datum/controller/subsystem/faction_control/proc/add_user_reputation(mob/user, faction, amount)
	if(!user || !faction || amount == 0) return
	var/client/C = user.client
	if(!C || !C.ckey) return
	var/ck = C.ckey
	if(!islist(player_rep_by_ckey[ck]))
		player_rep_by_ckey[ck] = list()
	var/list/rep_map = player_rep_by_ckey[ck]
	var/current = rep_map[faction]
	if(isnull(current)) current = 0
	rep_map[faction] = round(current) + round(amount)

/datum/controller/subsystem/faction_control/proc/get_user_reputation(mob/user, faction)
	if(!user || !faction) return 0
	var/client/C = user.client
	if(!C || !C.ckey) return 0
	var/list/rep_map = player_rep_by_ckey[C.ckey]
	if(!islist(rep_map)) return 0
	var/v = rep_map[faction]
	if(isnull(v)) return 0
	return round(v)

/datum/controller/subsystem/faction_control/proc/get_top_rep_rows(faction, max_rows = 5)
	var/list/rows = list()
	if(!faction) return rows
	var/list/pairs = list()
	for(var/ck in player_rep_by_ckey)
		var/list/rep_map = player_rep_by_ckey[ck]
		if(!islist(rep_map)) continue
		var/v = rep_map[faction]
		if(isnull(v)) v = 0
		v = round(v)
		if(v == 0) continue
		pairs += list(list("ckey" = "[ck]", "rep" = v))
		if(length(pairs) > 40)
			break

	// lightweight selection pass
	for(var/i in 1 to max_rows)
		var/list/best = null
		var/best_score = -999999
		for(var/list/entry in pairs)
			if(entry["taken"]) continue
			var/sc = entry["rep"]
			if(isnull(sc)) sc = 0
			sc = round(sc)
			if(sc > best_score)
				best_score = sc
				best = entry
		if(!best) break
		best["taken"] = TRUE
		var/brep = best["rep"]
		if(isnull(brep)) brep = 0
		rows += list(list("ckey" = "[best["ckey"]]", "rep" = round(brep)))
	return rows

/datum/controller/subsystem/faction_control/proc/ensure_upgrade_row(district)
	if(!district) return
	if(!islist(district_upgrades[district]))
		district_upgrades[district] = list(
			"industry" = 0,
			"logistics" = 0,
			"security" = 0
		)

/datum/controller/subsystem/faction_control/proc/get_upgrade_level(district, upgrade_key)
	if(!district || !upgrade_key) return 0
	ensure_upgrade_row(district)
	var/list/U = district_upgrades[district]
	var/v = U[upgrade_key]
	if(isnull(v)) v = 0
	return clamp(round(v), 0, FACTION_CTRL_UPGRADE_MAX_LEVEL)

/datum/controller/subsystem/faction_control/proc/get_upgrade_cost(district, upgrade_key)
	if(!district || !upgrade_key) return 9999
	var/lvl = get_upgrade_level(district, upgrade_key)
	if(lvl >= FACTION_CTRL_UPGRADE_MAX_LEVEL) return 0
	return FACTION_CTRL_UPGRADE_COST_BASE * (lvl + 1)

/datum/controller/subsystem/faction_control/proc/buy_district_upgrade(mob/user, district, upgrade_key)
	if(!user || !district || !upgrade_key) return FALSE
	var/f = get_mob_faction(user)
	if(!f || !is_controllable_faction(f))
		to_chat(user, span_warning("Only controllable factions can buy upgrades."))
		return FALSE
	if(get_owner(district) != f)
		to_chat(user, span_warning("Your faction does not own [district]."))
		return FALSE
	if(!(upgrade_key in list("industry", "logistics", "security")))
		to_chat(user, span_warning("Unknown upgrade category: [upgrade_key]."))
		return FALSE

	var/cost = get_upgrade_cost(district, upgrade_key)
	if(cost <= 0)
		to_chat(user, span_notice("[upgrade_key] in [district] is already maxed."))
		return FALSE
	if(!spend_faction_funds(f, cost))
		to_chat(user, span_warning("Faction treasury cannot afford [upgrade_key] upgrade ([cost])."))
		return FALSE

	ensure_upgrade_row(district)
	var/list/U = district_upgrades[district]
	var/current = U[upgrade_key]
	if(isnull(current)) current = 0
	U[upgrade_key] = min(FACTION_CTRL_UPGRADE_MAX_LEVEL, round(current) + 1)
	world << span_notice("[f] upgraded [upgrade_key] in [district] to level [U[upgrade_key]].")
	return TRUE

/datum/controller/subsystem/faction_control/proc/get_upgrade_tier_effect(upgrade_key, tier_level)
	if(tier_level <= 0) return "No bonus."
	switch(upgrade_key)
		if("industry")
			switch(tier_level)
				if(1) return "+material throughput (metal/blackpowder/caps)."
				if(2) return "major throughput boost; enables plasteel output with Smelter Chain research."
				if(3) return "heavy throughput boost; enables titanium output with Advanced Forges research."
		if("logistics")
			switch(tier_level)
				if(1) return "faster supply cooldown and caravan timing."
				if(2) return "faster routes and stronger caravan returns."
				if(3) return "best routing efficiency and lower effective supply cost."
		if("security")
			switch(tier_level)
				if(1) return "basic ammo production support."
				if(2) return "adds rifle/shotgun ammo classes."
				if(3) return "adds high-tier ammo; strongest with munitions research."
	return "Operational bonus."

/datum/controller/subsystem/faction_control/proc/get_owned_districts(faction)
	var/list/owned = list()
	if(!faction) return owned
	for(var/d in district_owner)
		if(district_owner[d] == faction)
			owned += "[d]"
	return owned

/datum/controller/subsystem/faction_control/proc/get_primary_destination_for_caravan(faction, from_district)
	var/list/owned = get_owned_districts(faction)
	if(length(owned) < 2) return null
	var/best = null
	var/best_income = -1
	for(var/d in owned)
		if(d == from_district) continue
		var/inc = district_income[d]
		if(isnull(inc)) inc = FACTION_CTRL_DEFAULT_DISTRICT_INCOME
		inc = round(inc)
		if(inc > best_income)
			best_income = inc
			best = d
	return best

/datum/controller/subsystem/faction_control/proc/get_effective_supply_cooldown(faction, district)
	var/cd = FACTION_CTRL_SUPPLY_COOLDOWN
	var/logi_lvl = get_upgrade_level(district, "logistics")
	cd -= (logi_lvl * 1 MINUTES)
	if(has_research_unlock(faction, "logi_rapid_dispatch"))
		cd -= 45 SECONDS
	if(get_district_buildable_kind(district) == "ncr_logistics_hub")
		cd -= 45 SECONDS
	var/event_mult = get_event_caravan_mult(district)
	if(event_mult > 1)
		cd -= 30 SECONDS
	if(is_district_jammed(district))
		cd += 30 SECONDS
	if(get_district_logistics_level(district) < 35)
		cd += 30 SECONDS
	return max(2 MINUTES, cd)

/datum/controller/subsystem/faction_control/proc/get_effective_supply_cost(faction, district)
	var/cost = FACTION_CTRL_SUPPLY_COST
	if(get_upgrade_level(district, "logistics") >= 3)
		cost -= 5
	if(has_research_unlock(faction, "ops_supply_automation"))
		cost -= 15
	if(get_district_water_level(district) < 35)
		cost += 8
	if(get_district_logistics_level(district) < 35)
		cost += 10
	return max(25, round(cost))

/datum/controller/subsystem/faction_control/proc/get_effective_override_cost(faction, district)
	var/cost = FACTION_CTRL_OVERRIDE_COST
	if(get_upgrade_level(district, "security") >= 2)
		cost -= 5
	if(has_research_unlock(faction, "ops_strategic_override"))
		cost -= 15
	return max(20, round(cost))

/datum/controller/subsystem/faction_control/proc/get_effective_caravan_duration(faction, from_district)
	var/dur = FACTION_CTRL_CARAVAN_DURATION - (get_upgrade_level(from_district, "logistics") * 20 SECONDS)
	if(has_research_unlock(faction, "logi_rapid_dispatch"))
		dur -= 40 SECONDS
	if(get_district_buildable_kind(from_district) == "ncr_logistics_hub")
		dur -= 35 SECONDS
	if(is_district_jammed(from_district))
		dur += 45 SECONDS
	if(get_district_logistics_level(from_district) < 35)
		dur += 30 SECONDS
	return max(2 MINUTES, dur)

/datum/controller/subsystem/faction_control/proc/get_effective_caravan_reward_mult(faction, from_district = null, to_district = null)
	var/m = 1.0
	if(has_research_unlock(faction, "logi_bulk_freight"))
		m += 0.20
	if(from_district && get_district_buildable_kind(from_district) == "ncr_logistics_hub")
		m += 0.15
	if(to_district && get_district_buildable_kind(to_district) == "ncr_logistics_hub")
		m += 0.10
	return m

/datum/controller/subsystem/faction_control/proc/get_event_income_mult(district)
	var/m = 1.0
	for(var/datum/faction_control_event/E in active_events)
		if(!E || E.expired(world.time)) continue
		if(E.district != district) continue
		m *= E.income_mult
	return m

/datum/controller/subsystem/faction_control/proc/get_event_output_mult(district)
	var/m = 1.0
	for(var/datum/faction_control_event/E in active_events)
		if(!E || E.expired(world.time)) continue
		if(E.district != district) continue
		m *= E.output_mult
	return m

/datum/controller/subsystem/faction_control/proc/get_event_caravan_mult(district)
	var/m = 1.0
	for(var/datum/faction_control_event/E in active_events)
		if(!E || E.expired(world.time)) continue
		if(E.district != district) continue
		m *= E.caravan_mult
	return m

/datum/controller/subsystem/faction_control/proc/has_hostile_event_in_district(district)
	if(!district) return FALSE
	for(var/datum/faction_control_event/E in active_events)
		if(!E || E.expired(world.time)) continue
		if(E.district != district) continue
		if(E.hostile)
			return TRUE
		if(E.event_type in list("mutant_surge", "raider_pressure", "monster_incursion"))
			return TRUE
	return FALSE

/datum/controller/subsystem/faction_control/proc/get_research_output_mult(faction, resource_key)
	var/tier = get_faction_research_tier(faction)
	var/m = 1.0
	if(tier >= 2 && resource_key == "metal")
		m += 0.10
	if(tier >= 3 && resource_key == "blackpowder")
		m += 0.10
	if(tier >= 4 && resource_key == "caps")
		m += 0.10

	if(has_research_unlock(faction, "res_salvage_protocols"))
		if(resource_key == "metal")
			m += 0.20
		if(resource_key == "blackpowder")
			m += 0.10
	if(has_research_unlock(faction, "ind_smelter_chain") && resource_key == "plasteel")
		m += 0.25
	if(has_research_unlock(faction, "ind_advanced_forges") && resource_key == "titanium")
		m += 0.35
	if(has_research_unlock(faction, "ops_hazard_extraction"))
		if(resource_key in list("plasteel", "titanium", "ammo"))
			m += 0.12
	if(has_research_unlock(faction, "logi_bulk_freight"))
		if(resource_key in list("metal", "blackpowder", "caps", "plasteel", "titanium", "ammo"))
			m += 0.10
	if(has_research_unlock(faction, "sec_munitions_fabricator") && resource_key == "ammo")
		m += 0.25
	if(has_research_unlock(faction, "doc_industry_focus"))
		if(resource_key in list("metal", "blackpowder", "caps", "plasteel", "titanium"))
			m += 0.15
	if(has_research_unlock(faction, "doc_military_focus") && resource_key == "ammo")
		m += 0.20
	return m

/datum/controller/subsystem/faction_control/proc/get_resource_output_mult(faction, district, resource_key)
	var/m = 1.0
	var/industry_lvl = get_upgrade_level(district, "industry")
	var/logistics_lvl = get_upgrade_level(district, "logistics")
	var/security_lvl = get_upgrade_level(district, "security")

	switch(resource_key)
		if("ammo")
			m += (security_lvl * 0.20)
		if("caps")
			m += (industry_lvl * 0.10)
			m += (logistics_lvl * 0.05)
		if("plasteel", "titanium")
			m += (industry_lvl * 0.15)
		else
			m += (industry_lvl * 0.12)

	m *= get_event_output_mult(district)
	m *= get_hazard_output_mult(district)
	m *= get_research_output_mult(faction, resource_key)
	m *= get_buildable_output_mult(district, resource_key)
	m *= get_district_utility_efficiency(district)
	return m

/datum/controller/subsystem/faction_control/proc/get_rare_chance_bonus(faction)
	var/tier = get_faction_research_tier(faction)
	if(tier <= 0) return 0
	return tier * 5

/datum/controller/subsystem/faction_control/proc/get_faction_intel_points(faction)
	if(!faction) return 0
	var/v = faction_intel_points[faction]
	if(isnull(v)) return 0
	return max(0, round(v))

/datum/controller/subsystem/faction_control/proc/add_faction_intel_points(faction, amount)
	if(!faction || amount <= 0) return
	faction_intel_points[faction] = get_faction_intel_points(faction) + round(amount)

/datum/controller/subsystem/faction_control/proc/spend_faction_intel_points(faction, amount)
	if(!faction || amount <= 0) return FALSE
	var/current = get_faction_intel_points(faction)
	if(current < amount)
		return FALSE
	faction_intel_points[faction] = current - amount
	return TRUE

/datum/controller/subsystem/faction_control/proc/can_see_enemy_caravans(faction)
	if(!faction) return FALSE
	var/until = faction_route_reveal_until[faction]
	if(isnull(until)) return FALSE
	return world.time < until

/datum/controller/subsystem/faction_control/proc/is_district_jammed(district)
	if(!district) return FALSE
	var/until = district_jam_until[district]
	if(isnull(until)) return FALSE
	return world.time < until

/datum/controller/subsystem/faction_control/proc/get_district_water_level(district)
	if(!district) return 0
	var/v = district_water[district]
	if(isnull(v)) return 0
	return clamp(round(v), 0, 100)

/datum/controller/subsystem/faction_control/proc/get_district_logistics_level(district)
	if(!district) return 0
	var/v = district_logistics_health[district]
	if(isnull(v)) return 0
	return clamp(round(v), 0, 100)

/datum/controller/subsystem/faction_control/proc/get_district_stability(district)
	if(!district) return FACTION_CTRL_STABILITY_START
	var/v = district_stability[district]
	if(isnull(v)) return FACTION_CTRL_STABILITY_START
	return clamp(round(v), 0, 100)

/datum/controller/subsystem/faction_control/proc/get_district_buildable(district)
	if(!district) return null
	if(!islist(district_buildables[district]))
		return null
	return district_buildables[district]

/datum/controller/subsystem/faction_control/proc/get_district_buildable_kind(district)
	var/list/B = get_district_buildable(district)
	if(!islist(B)) return null
	var/k = B["kind"]
	if(!istext(k) || !length(k)) return null
	return k

/datum/controller/subsystem/faction_control/proc/get_district_utility_state(district)
	if(!district)
		return list("power" = FALSE, "water" = FALSE, "logistics" = FALSE)
	var/list/cached = district_utility_cache[district]
	if(islist(cached))
		return cached
	var/power_ok = _grid_is_district_on(district)
	var/water_ok = (get_district_water_level(district) >= 35)
	var/logi_ok = (get_district_logistics_level(district) >= 35) && !is_district_jammed(district)
	if(get_district_stability(district) <= FACTION_CTRL_STABILITY_CRITICAL)
		power_ok = FALSE
	return list("power" = !!power_ok, "water" = !!water_ok, "logistics" = !!logi_ok)

/datum/controller/subsystem/faction_control/proc/get_district_utility_efficiency(district)
	var/list/U = get_district_utility_state(district)
	var/m = 1.0
	var/missing = 0
	if(!U["power"])
		m *= 0.55
		missing++
	if(!U["water"])
		m *= 0.72
		missing++
	if(!U["logistics"])
		m *= 0.78
		missing++
	if(missing >= 2)
		m *= 0.90
	var/stability = get_district_stability(district)
	if(stability < FACTION_CTRL_STABILITY_LOW)
		m *= 0.85
	return max(0.20, m)

/datum/controller/subsystem/faction_control/proc/get_buildable_income_mult(district)
	var/k = get_district_buildable_kind(district)
	switch(k)
		if("town_trade_hub")
			return 1.22
		if("ncr_logistics_hub")
			return 1.10
	return 1.0

/datum/controller/subsystem/faction_control/proc/get_buildable_output_mult(district, resource_key)
	var/k = get_district_buildable_kind(district)
	switch(k)
		if("bos_hardpoint")
			if(resource_key == "ammo")
				return 1.25
		if("ncr_logistics_hub")
			if(resource_key in list("metal", "blackpowder", "caps", "plasteel", "titanium", "ammo"))
				return 1.10
		if("legion_warcamp")
			if(resource_key == "ammo")
				return 1.18
		if("town_trade_hub")
			if(resource_key == "caps")
				return 1.20
	return 1.0

/datum/controller/subsystem/faction_control/proc/get_event_water_mult(district)
	var/m = 1.0
	for(var/datum/faction_control_event/E in active_events)
		if(!E || E.expired(world.time)) continue
		if(E.district != district) continue
		if(isnull(E.water_mult)) continue
		m *= E.water_mult
	return m

/datum/controller/subsystem/faction_control/proc/get_event_logistics_mult(district)
	var/m = 1.0
	for(var/datum/faction_control_event/E in active_events)
		if(!E || E.expired(world.time)) continue
		if(E.district != district) continue
		if(isnull(E.logistics_mult)) continue
		m *= E.logistics_mult
	return m

/datum/controller/subsystem/faction_control/proc/maybe_trigger_stability_crisis(district)
	if(!district) return
	if(length(active_events) >= 8) return
	var/last = district_last_crisis_event[district]
	if(!isnull(last) && (world.time - round(last)) < (7 MINUTES))
		return
	var/datum/faction_control_event/E = new
	E.id = "E[next_event_id++]"
	E.district = district
	E.started_at = world.time
	E.ends_at = world.time + 6 MINUTES
	E.event_type = "civil_unrest"
	E.title = "Civil Unrest"
	E.desc = "Infrastructure strain in [district] triggered shortages and unrest."
	E.income_mult = 0.82
	E.output_mult = 0.88
	E.caravan_mult = 0.82
	E.water_mult = 0.90
	E.logistics_mult = 0.85
	E.hostile = TRUE
	active_events += E
	district_last_crisis_event[district] = world.time
	world << span_warning("District crisis: [district] is unstable (Civil Unrest).")

/datum/controller/subsystem/faction_control/proc/process_turret_power_overrides()
	for(var/obj/machinery/f13/faction_turret_controller/C in world)
		if(!C || QDELETED(C)) continue
		var/d = get_district_for_atom(C)
		if(!d) continue
		var/list/U = get_district_utility_state(d)
		if(!U["power"] || !U["logistics"] || is_district_jammed(d))
			C.apply_network_state(FALSE)

/datum/controller/subsystem/faction_control/proc/process_utility_state()
	bootstrap_districts()
	if(!length(district_income)) return

	var/list/water_add = list()
	var/list/tax_gain = list()
	var/list/all_districts = list()
	for(var/d in district_income)
		all_districts += "[d]"
		if(isnull(district_water[d]))
			district_water[d] = 55
		if(isnull(district_logistics_health[d]))
			district_logistics_health[d] = 55
		if(isnull(district_stability[d]))
			district_stability[d] = FACTION_CTRL_STABILITY_START
		water_add[d] = 0

	var/list/remove_nodes = list()
	for(var/obj/machinery/f13/faction_water_purifier/W in water_nodes)
		if(!W || QDELETED(W))
			remove_nodes += W
			continue
		if(!W.operational) continue
		var/district = W.get_district()
		var/owner = W.owner_faction
		if(!district || !owner) continue
		if(get_owner(district) != owner) continue
		var/produced = max(5, round(W.output_rate * (1 + (get_upgrade_level(district, "industry") * 0.12))))
		var/local_share = round(produced * 0.65)
		water_add[district] += local_share
		var/export_share = max(0, produced - local_share)
		if(export_share <= 0) continue

		switch(W.export_mode)
			if("restricted")
				var/list/owned = get_owned_districts(owner)
				if(!length(owned))
					water_add[district] += export_share
				else
					var/per_owned = round(export_share / length(owned))
					if(per_owned <= 0)
						water_add[district] += export_share
					else
						for(var/od in owned)
							water_add[od] += per_owned
			if("taxed")
				var/per_taxed = length(all_districts) ? max(0, round(export_share / length(all_districts))) : export_share
				for(var/ad in all_districts)
					water_add[ad] += per_taxed
				tax_gain[owner] += round(export_share * 0.5)
			else // share
				var/per_shared = length(all_districts) ? max(0, round(export_share / length(all_districts))) : export_share
				for(var/ad2 in all_districts)
					water_add[ad2] += per_shared
	water_nodes -= remove_nodes

	for(var/f in tax_gain)
		var/v = tax_gain[f]
		if(isnull(v)) continue
		add_faction_funds(f, round(v))

	for(var/d in district_income)
		var/current_water = get_district_water_level(d)
		var/added_water = water_add[d]
		if(isnull(added_water)) added_water = 0
		var/passive_water = 28
		var/new_water = round((current_water * 0.65) + ((added_water + passive_water) * 0.45))
		new_water = round(new_water * get_event_water_mult(d))
		if(is_district_jammed(d))
			new_water -= 8
		district_water[d] = clamp(new_water, 0, 100)

		var/logi = 40 + (get_upgrade_level(d, "logistics") * 20)
		var/last_supply = district_last_supply_time[d]
		var/last_caravan = district_last_caravan_time[d]
		if(!isnull(last_supply) && (world.time - round(last_supply)) <= (15 MINUTES))
			logi += 25
		if(!isnull(last_caravan) && (world.time - round(last_caravan)) <= (15 MINUTES))
			logi += 25
		if(has_hostile_event_in_district(d))
			logi -= 15
		if(is_district_jammed(d))
			logi -= 30
		if(get_district_buildable_kind(d) == "ncr_logistics_hub")
			logi += 18
		logi = round(logi * get_event_logistics_mult(d))
		district_logistics_health[d] = clamp(logi, 0, 100)

		var/power_ok = _grid_is_district_on(d)
		var/water_ok = (district_water[d] >= 35)
		var/logi_ok = (district_logistics_health[d] >= 35) && !is_district_jammed(d)
		var/stability = get_district_stability(d)
		if(stability <= FACTION_CTRL_STABILITY_CRITICAL)
			power_ok = FALSE
		var/list/U = list(
			"power" = !!power_ok,
			"water" = !!water_ok,
			"logistics" = !!logi_ok
		)
		district_utility_cache[d] = U

		var/owner_faction = get_owner(d)
		var/delta = 0
		if(U["power"]) delta += 2
		else delta -= 3
		if(U["water"]) delta += 1
		else delta -= 3
		if(U["logistics"]) delta += 1
		else delta -= 2
		delta += (get_upgrade_level(d, "security") - 1)
		if(has_hostile_event_in_district(d))
			delta -= 2
		if(is_district_jammed(d))
			delta -= 2
		if(owner_faction && has_research_unlock(owner_faction, "doc_medical_focus"))
			delta += 1
		if(get_district_buildable_kind(d) == "bos_hardpoint")
			delta += 1
		if(get_district_buildable_kind(d) == "town_trade_hub")
			delta += 1
		district_stability[d] = clamp(stability + delta, 0, 100)

		if(district_stability[d] < FACTION_CTRL_STABILITY_LOW)
			maybe_trigger_stability_crisis(d)
		if(district_stability[d] <= FACTION_CTRL_STABILITY_CRITICAL)
			district_jam_until[d] = max(round(district_jam_until[d]), world.time + 30 SECONDS)

	process_turret_power_overrides()

/datum/controller/subsystem/faction_control/proc/intel_scan_routes(mob/user)
	if(!user) return FALSE
	var/f = get_mob_faction(user)
	if(!f || !is_controllable_faction(f))
		to_chat(user, span_warning("Only controllable factions can run intel scans."))
		return FALSE
	if(!spend_faction_intel_points(f, FACTION_CTRL_INTEL_REVEAL_COST))
		to_chat(user, span_warning("Need [FACTION_CTRL_INTEL_REVEAL_COST] intel points to reveal routes."))
		return FALSE
	faction_route_reveal_until[f] = world.time + FACTION_CTRL_INTEL_REVEAL_DURATION
	to_chat(user, span_notice("Enemy caravan routes revealed for [round(FACTION_CTRL_INTEL_REVEAL_DURATION / 10)]s."))
	return TRUE

/datum/controller/subsystem/faction_control/proc/intel_jam_district(mob/user, district)
	if(!user || !district) return FALSE
	var/f = get_mob_faction(user)
	if(!f || !is_controllable_faction(f))
		to_chat(user, span_warning("Only controllable factions can run signal jamming."))
		return FALSE
	if(!has_research_unlock(f, "ops_signal_warfare"))
		to_chat(user, span_warning("Requires Signal Warfare Suite research."))
		return FALSE
	var/owner = get_owner(district)
	if(owner == f)
		to_chat(user, span_warning("Cannot jam your own district."))
		return FALSE
	if(!spend_faction_intel_points(f, FACTION_CTRL_INTEL_JAM_COST))
		to_chat(user, span_warning("Need [FACTION_CTRL_INTEL_JAM_COST] intel points to jam [district]."))
		return FALSE
	district_jam_until[district] = max(round(district_jam_until[district]), world.time + FACTION_CTRL_INTEL_JAM_DURATION)
	world << span_warning("[f] triggered a communications jam in [district].")
	return TRUE

/datum/controller/subsystem/faction_control/proc/intel_fake_distress(mob/user, district)
	if(!user || !district) return FALSE
	var/f = get_mob_faction(user)
	if(!f || !is_controllable_faction(f))
		to_chat(user, span_warning("Only controllable factions can run counter-intel operations."))
		return FALSE
	if(!has_research_unlock(f, "ops_signal_warfare"))
		to_chat(user, span_warning("Requires Signal Warfare Suite research."))
		return FALSE
	if(!spend_faction_intel_points(f, FACTION_CTRL_INTEL_FAKE_COST))
		to_chat(user, span_warning("Need [FACTION_CTRL_INTEL_FAKE_COST] intel points for a fake distress operation."))
		return FALSE

	var/affected = 0
	for(var/datum/faction_control_caravan/C in active_caravans)
		if(!C) continue
		if(C.faction == f) continue
		if(C.from_district != district && C.to_district != district) continue
		C.arrive_at += 45 SECONDS
		C.compromised = TRUE
		affected++

	if(!affected)
		var/datum/faction_control_event/E = new
		E.id = "E[next_event_id++]"
		E.district = district
		E.started_at = world.time
		E.ends_at = world.time + 4 MINUTES
		E.event_type = "false_distress"
		E.title = "False Distress Call"
		E.desc = "Signal spoofing in [district] is confusing logistics traffic."
		E.caravan_mult = 0.75
		E.logistics_mult = 0.80
		active_events += E

	world << span_warning("[f] ran a fake distress operation in [district].")
	return TRUE

/datum/controller/subsystem/faction_control/proc/roll_hazard_zone()
	bootstrap_districts()
	if(!length(district_income)) return
	if(length(active_hazard_zones) >= 4) return

	var/list/candidates = list()
	for(var/d in district_income)
		candidates += "[d]"
	if(!length(candidates)) return
	var/chosen_district = pick(candidates)

	var/reactor_hot = FALSE
	if(istext(GLOB.wasteland_grid_state) && GLOB.wasteland_grid_state == "RED")
		reactor_hot = TRUE
	if(!isnull(GLOB.wasteland_grid_background_rads) && GLOB.wasteland_grid_background_rads >= 10)
		reactor_hot = TRUE

	if(reactor_hot && prob(60))
		spawn_hazard_zone(chosen_district, "reactor_fallout", "Reactor Fallout Window", "Reactor bleed-through made salvage in this district extremely dangerous.")
		return

	switch(rand(1, 3))
		if(1)
			spawn_hazard_zone(chosen_district, "radstorm_window", "Radstorm Extraction Window", "Radiation peaks are exposing high-value salvage.")
		if(2)
			spawn_hazard_zone(chosen_district, "heatwave_window", "Heatwave Salvage Window", "Extreme heat cracked old bunkers and exposed rare components.")
		if(3)
			spawn_hazard_zone(chosen_district, "fauna_breach", "Fauna Breach Zone", "A local fauna surge opened new scavenging opportunities.")

/datum/controller/subsystem/faction_control/proc/spawn_hazard_zone(district, hazard_type, title, desc)
	if(!district || !hazard_type) return null
	for(var/datum/faction_hazard_zone/H in active_hazard_zones)
		if(!H || H.expired(world.time)) continue
		if(H.district == district && H.hazard_type == hazard_type)
			return H
	var/datum/faction_hazard_zone/HZ = new
	HZ.id = "HZ[next_hazard_id++]"
	HZ.district = district
	HZ.hazard_type = hazard_type
	HZ.title = title ? title : "Hazard Zone"
	HZ.desc = desc ? desc : "Dangerous extraction opportunity."
	HZ.started_at = world.time
	HZ.ends_at = world.time + FACTION_CTRL_HAZARD_DURATION
	switch(hazard_type)
		if("reactor_fallout")
			HZ.resource_mult = 1.45
		if("radstorm_window")
			HZ.resource_mult = 1.30
		if("heatwave_window")
			HZ.resource_mult = 1.22
		if("fauna_breach")
			HZ.resource_mult = 1.18
		else
			HZ.resource_mult = 1.15
	active_hazard_zones += HZ
	world << span_warning("Hazard Zone: [HZ.title] in [district] ([round((HZ.ends_at - world.time) / 10)]s).")
	return HZ

/datum/controller/subsystem/faction_control/proc/process_hazard_zones()
	if(!length(active_hazard_zones)) return
	var/list/remove = list()
	for(var/datum/faction_hazard_zone/H in active_hazard_zones)
		if(!H || H.expired(world.time))
			remove += H
	active_hazard_zones -= remove

/datum/controller/subsystem/faction_control/proc/get_hazard_output_mult(district)
	var/m = 1.0
	for(var/datum/faction_hazard_zone/H in active_hazard_zones)
		if(!H || H.expired(world.time)) continue
		if(H.district != district) continue
		m *= H.resource_mult
	return m

/datum/controller/subsystem/faction_control/proc/get_hazard_rows()
	var/list/rows = list()
	for(var/datum/faction_hazard_zone/H in active_hazard_zones)
		if(!H || H.expired(world.time)) continue
		rows += list(list(
			"id" = H.id,
			"district" = "[H.district]",
			"type" = H.hazard_type,
			"title" = H.title,
			"desc" = H.desc,
			"remaining_s" = max(0, round((H.ends_at - world.time) / 10)),
			"mult" = round(H.resource_mult * 100)
		))
	return rows

/datum/controller/subsystem/faction_control/proc/get_active_hazard_for_district(district)
	if(!district) return null
	for(var/datum/faction_hazard_zone/H in active_hazard_zones)
		if(!H || H.expired(world.time)) continue
		if(H.district == district)
			return H
	return null

/datum/controller/subsystem/faction_control/proc/extract_hazard_resources(mob/user, district, turf/drop_turf)
	if(!user || !district || !drop_turf) return FALSE
	var/f = get_mob_faction(user)
	if(!f || !is_controllable_faction(f))
		to_chat(user, span_warning("Only controllable factions can run hazard extraction."))
		return FALSE
	if(!has_research_unlock(f, "ops_hazard_extraction"))
		to_chat(user, span_warning("Requires Hazard Extraction Protocols research."))
		return FALSE
	if(get_owner(district) != f)
		to_chat(user, span_warning("Your faction must control [district] to extract there."))
		return FALSE
	var/datum/faction_hazard_zone/H = get_active_hazard_for_district(district)
	if(!H)
		to_chat(user, span_warning("No active hazard extraction window in [district]."))
		return FALSE
	var/key = "[f]|[district]"
	var/cd = hazard_extract_cd[key]
	if(!isnull(cd) && world.time < round(cd))
		var/remaining = round((round(cd) - world.time) / 10)
		to_chat(user, span_warning("Hazard extraction cooldown: [remaining]s"))
		return FALSE
	if(!spend_faction_funds(f, FACTION_CTRL_HAZARD_EXTRACT_COST))
		to_chat(user, span_warning("Faction treasury cannot afford hazard extraction ([FACTION_CTRL_HAZARD_EXTRACT_COST])."))
		return FALSE

	var/m = H.resource_mult
	spawn_plasteel_bundle(drop_turf, max(0, round(10 * m)))
	spawn_titanium_bundle(drop_turf, max(0, round(8 * m)))
	spawn_metal_bundle(drop_turf, max(0, round(90 * m)))
	spawn_blackpowder_bundle(drop_turf, max(0, round(20 * m)))
	spawn_security_ammo_bundle(drop_turf, f, district, 0.8 * m)
	spawn_rare_crafting_bundle(drop_turf, get_rare_chance_bonus(f) + 20)
	add_research_points(f, 5)
	add_user_reputation(user, f, 2)
	hazard_extract_count_by_key["[f]|[district]"] = get_hazard_extract_count(f, district) + 1
	hazard_extract_cd[key] = world.time + FACTION_CTRL_HAZARD_EXTRACT_COOLDOWN
	to_chat(user, span_notice("Hazard extraction complete in [district]. Rare materials recovered."))
	return TRUE

/datum/controller/subsystem/faction_control/proc/get_buildable_template_for_faction(faction)
	if(!faction) return null
	switch(faction)
		if(FACTION_BROTHERHOOD)
			return list(
				"kind" = "bos_hardpoint",
				"name" = "BOS Bastion Uplink",
				"desc" = "Hardpoint doctrine node: stronger district defense output and stability.",
				"cost" = 170,
				"requires" = "ops_turret_uplink"
			)
		if(FACTION_NCR)
			return list(
				"kind" = "ncr_logistics_hub",
				"name" = "NCR Logistics Hub",
				"desc" = "Route office: better logistics health, convoy speed, and district throughput.",
				"cost" = 160,
				"requires" = "logi_bulk_freight"
			)
		if(FACTION_LEGION)
			return list(
				"kind" = "legion_warcamp",
				"name" = "Legion War Camp",
				"desc" = "War camp: stronger combat contract payouts and munitions tempo.",
				"cost" = 150,
				"requires" = "doc_military_focus"
			)
		if(FACTION_EASTWOOD)
			return list(
				"kind" = "town_trade_hub",
				"name" = "Town Trade Hub",
				"desc" = "Trade exchange: stronger district economy and civil stability.",
				"cost" = 145,
				"requires" = "doc_industry_focus"
			)
	return null

/datum/controller/subsystem/faction_control/proc/deploy_doctrine_buildable(mob/user, district, turf/drop_turf)
	if(!user || !district || !drop_turf) return FALSE
	var/f = get_mob_faction(user)
	if(!f || !is_controllable_faction(f))
		to_chat(user, span_warning("Only controllable factions can deploy doctrine buildables."))
		return FALSE
	if(get_owner(district) != f)
		to_chat(user, span_warning("Your faction must control [district] to deploy there."))
		return FALSE
	if(islist(district_buildables[district]))
		to_chat(user, span_warning("[district] already has a doctrine buildable."))
		return FALSE
	var/list/T = get_buildable_template_for_faction(f)
	if(!islist(T))
		to_chat(user, span_warning("No doctrine buildable is configured for your faction."))
		return FALSE
	var/need = T["requires"]
	if(istext(need) && length(need) && !has_research_unlock(f, need))
		var/list/RP = get_research_project(need)
		if(islist(RP))
			to_chat(user, span_warning("Requires research: [RP["name"]]."))
		else
			to_chat(user, span_warning("Required doctrine research is not unlocked."))
		return FALSE
	var/cost = max(50, round(T["cost"]))
	if(!spend_faction_funds(f, cost))
		to_chat(user, span_warning("Faction treasury cannot afford deployment ([cost])."))
		return FALSE
	district_buildables[district] = list(
		"kind" = "[T["kind"]]",
		"name" = "[T["name"]]",
		"faction" = "[f]",
		"desc" = "[T["desc"]]"
	)
	var/obj/structure/f13/faction_district_buildable_marker/M = new(drop_turf)
	M.configure_from_data("[T["name"]]", "[T["desc"]]", f, district)
	world << span_notice("[f] deployed [T["name"]] in [district].")
	return TRUE

/datum/controller/subsystem/faction_control/proc/get_doctrine_buildable_rows(faction)
	var/list/rows = list()
	var/list/T = get_buildable_template_for_faction(faction)
	var/required_id = null
	if(islist(T))
		required_id = T["requires"]
	for(var/d in district_income)
		var/owner = get_owner(d)
		var/list/B = district_buildables[d]
		var/name = ""
		var/kind = ""
		if(islist(B))
			name = "[B["name"]]"
			kind = "[B["kind"]]"
		var/owned_by_you = (faction && owner == faction)
		var/can_deploy = FALSE
		var/reason = ""
		if(owned_by_you && !islist(B) && islist(T))
			can_deploy = TRUE
			if(required_id && !has_research_unlock(faction, required_id))
				can_deploy = FALSE
				var/list/R = get_research_project(required_id)
				reason = islist(R) ? "Need [R["name"]]." : "Research locked."
		rows += list(list(
			"district" = "[d]",
			"owner" = owner ? "[owner]" : "Unclaimed",
			"buildable_name" = name,
			"buildable_kind" = kind,
			"is_owned_by_you" = !!owned_by_you,
			"can_deploy" = !!can_deploy,
			"blocked_reason" = reason
		))
	return rows

/datum/controller/subsystem/faction_control/proc/get_water_rows(for_faction = null)
	var/list/rows = list()
	for(var/obj/machinery/f13/faction_water_purifier/W in water_nodes)
		if(!W || QDELETED(W)) continue
		var/d = W.get_district()
		rows += list(list(
			"id" = REF(W),
			"district" = d ? "[d]" : "Unmapped",
			"owner" = W.owner_faction ? "[W.owner_faction]" : "Unclaimed",
			"mode" = W.export_mode ? "[W.export_mode]" : "share",
			"output" = round(W.output_rate),
			"operational" = !!W.operational,
			"is_owner" = !!(for_faction && W.owner_faction == for_faction)
		))
	return rows

/datum/controller/subsystem/faction_control/proc/note_supply_drop(faction, district, mob/user)
	if(!faction || !district) return
	var/key = "[faction]|[district]"
	var/current = supply_count_by_key[key]
	if(isnull(current)) current = 0
	supply_count_by_key[key] = round(current) + 1
	district_last_supply_time[district] = world.time
	add_user_reputation(user, faction, 1)

/datum/controller/subsystem/faction_control/proc/get_supply_count(faction, district)
	if(!faction || !district) return 0
	var/v = supply_count_by_key["[faction]|[district]"]
	if(isnull(v)) return 0
	return round(v)

/datum/controller/subsystem/faction_control/proc/get_caravan_count(faction, district)
	if(!faction || !district) return 0
	var/v = caravan_count_by_key["[faction]|[district]"]
	if(isnull(v)) return 0
	return round(v)

/datum/controller/subsystem/faction_control/proc/get_hazard_extract_count(faction, district)
	if(!faction || !district) return 0
	var/v = hazard_extract_count_by_key["[faction]|[district]"]
	if(isnull(v)) return 0
	return round(v)

/datum/controller/subsystem/faction_control/proc/has_active_linked_pad_for_district(faction, district)
	if(!faction || !district) return FALSE
	for(var/obj/machinery/f13/faction_resource_pad/P in resource_pads)
		if(!P || QDELETED(P)) continue
		if(!P.active_from_node) continue
		if(P.get_district() != district) continue
		if(get_owner(district) != faction) continue
		return TRUE
	return FALSE

/datum/controller/subsystem/faction_control/proc/get_active_linked_pad_for_district(faction, district)
	if(!faction || !district) return null
	for(var/obj/machinery/f13/faction_resource_pad/P in resource_pads)
		if(!P || QDELETED(P)) continue
		if(!P.active_from_node) continue
		if(P.get_district() != district) continue
		if(get_owner(district) != faction) continue
		return P
	return null

/datum/controller/subsystem/faction_control/proc/get_mob_faction(mob/M)
	if(!M) return null
	if(M:social_faction && istext(M:social_faction) && length(M:social_faction))
		var/c1 = normalize_faction(M:social_faction)
		if(c1) return c1
	if(islist(M:faction))
		for(var/f in M:faction)
			if(!istext(f) || !length(f)) continue
			var/c2 = normalize_faction(f)
			if(c2) return c2
	return null

/datum/controller/subsystem/faction_control/proc/normalize_faction(raw)
	if(!raw || !istext(raw)) return null
	var/l = lowertext(raw)
	if(faction_aliases[l])
		return faction_aliases[l]
	if(raw in controllable_factions)
		return raw
	return null

/datum/controller/subsystem/faction_control/proc/is_controllable_faction(faction)
	if(!faction) return FALSE
	var/c = normalize_faction(faction)
	if(!c) return FALSE
	return (c in controllable_factions)

/datum/controller/subsystem/faction_control/proc/infer_district_for_area(area/Ar)
	if(!Ar) return null

	var/type_path = lowertext("[Ar.type]")
	if(findtext(type_path, "/area/f13/brotherhood") || findtext(type_path, "/area/f13/underground/bos") || findtext(type_path, "/area/f13/bos"))
		return "BOS"
	if(findtext(type_path, "/area/f13/ncr"))
		return "NCR"
	if(findtext(type_path, "/area/f13/legion"))
		return "Legion"
	if(findtext(type_path, "/area/f13/village") || findtext(type_path, "/area/f13/hub") || findtext(type_path, "/area/f13/city") || findtext(type_path, "/area/f13/wasteland/town"))
		return "Town"

	var/area_name = lowertext("[Ar.name]")
	if(findtext(area_name, "brotherhood") || findtext(area_name, "bos"))
		return "BOS"
	if(findtext(area_name, "ncr"))
		return "NCR"
	if(findtext(area_name, "legion"))
		return "Legion"
	if(findtext(area_name, "town") || findtext(area_name, "village") || findtext(area_name, "city") || findtext(area_name, "hub"))
		return "Town"

	return null

/datum/controller/subsystem/faction_control/proc/get_district_for_area(area/Ar)
	if(!Ar) return null
	var/d = Ar:grid_district
	if(istext(d) && length(d))
		return d
	return infer_district_for_area(Ar)

/datum/controller/subsystem/faction_control/proc/get_district_for_atom(atom/A)
	if(!A) return null
	if(istext(A:district_id) && length(A:district_id))
		return A:district_id
	var/area/Ar = get_area(A)
	if(!Ar) return null
	return get_district_for_area(Ar)

/datum/controller/subsystem/faction_control/proc/get_owner(district)
	if(!district) return null
	return district_owner[district]

/datum/controller/subsystem/faction_control/proc/ensure_district(district)
	if(!district) return null
	bootstrap_districts()
	if(isnull(district_income[district]))
		district_income[district] = FACTION_CTRL_DEFAULT_DISTRICT_INCOME
	ensure_upgrade_row(district)
	if(isnull(district_water[district]))
		district_water[district] = 55
	if(isnull(district_logistics_health[district]))
		district_logistics_health[district] = 55
	if(isnull(district_stability[district]))
		district_stability[district] = FACTION_CTRL_STABILITY_START
	return district

/datum/controller/subsystem/faction_control/proc/create_dynamic_district()
	bootstrap_districts()
	var/new_id = "District [next_dynamic_district_id]"
	while(district_income[new_id])
		next_dynamic_district_id++
		new_id = "District [next_dynamic_district_id]"
	next_dynamic_district_id++
	district_income[new_id] = FACTION_CTRL_DEFAULT_DISTRICT_INCOME
	ensure_upgrade_row(new_id)
	if(isnull(district_water[new_id]))
		district_water[new_id] = 55
	if(isnull(district_logistics_health[new_id]))
		district_logistics_health[new_id] = 55
	if(isnull(district_stability[new_id]))
		district_stability[new_id] = FACTION_CTRL_STABILITY_START
	return new_id

/datum/controller/subsystem/faction_control/proc/set_owner(district, faction, mob/user)
	if(!district || !faction) return FALSE
	bootstrap_districts()
	ensure_district(district)
	var/old = district_owner[district]
	district_owner[district] = faction
	if(old != faction)
		world << span_warning("Faction Control: [district] is now controlled by [faction].")
		if(is_controllable_faction(faction))
			add_research_points(faction, 3)
	return TRUE

/datum/controller/subsystem/faction_control/proc/can_faction_capture(district, faction)
	if(!district || !faction) return FALSE
	return is_controllable_faction(faction)

/datum/controller/subsystem/faction_control/proc/get_faction_funds(faction)
	if(!faction) return 0
	var/v = faction_funds[faction]
	if(isnull(v)) return 0
	return round(v)

/datum/controller/subsystem/faction_control/proc/add_faction_funds(faction, amount)
	if(!faction || amount <= 0) return 0
	var/current = get_faction_funds(faction)
	current += amount
	faction_funds[faction] = current
	return current

/datum/controller/subsystem/faction_control/proc/spend_faction_funds(faction, amount)
	if(!faction || amount <= 0) return FALSE
	var/current = get_faction_funds(faction)
	if(current < amount)
		return FALSE
	faction_funds[faction] = current - amount
	return TRUE

/datum/controller/subsystem/faction_control/proc/process_income_payout()
	bootstrap_districts()
	if(!length(district_owner)) return

	var/list/totals = list()
	var/list/intel_totals = list()
	for(var/district in district_owner)
		var/faction = district_owner[district]
		if(!is_controllable_faction(faction)) continue

		var/base_income = district_income[district]
		if(isnull(base_income))
			base_income = FACTION_CTRL_DEFAULT_DISTRICT_INCOME

		var/mult = 1.0
		mult += (get_upgrade_level(district, "industry") * 0.15)
		mult *= get_event_income_mult(district)
		mult *= get_buildable_income_mult(district)
		if(get_faction_research_tier(faction) >= 4)
			mult += 0.10
		var/list/U = get_district_utility_state(district)
		if(has_research_unlock(faction, "doc_power_focus") && U["power"])
			mult += 0.10
		mult *= get_district_utility_efficiency(district)

		var/payout = max(1, round(base_income * mult))
		totals[faction] += payout
		var/security_lvl = get_upgrade_level(district, "security")
		var/intel_gain = max(0, security_lvl - 1)
		if(get_district_buildable_kind(district) == "bos_hardpoint")
			intel_gain += 1
		intel_totals[faction] += intel_gain

	for(var/f in totals)
		add_faction_funds(f, totals[f])
	for(var/f2 in intel_totals)
		var/i_amt = intel_totals[f2]
		if(!isnull(i_amt) && round(i_amt) > 0)
			add_faction_intel_points(f2, round(i_amt))

/datum/controller/subsystem/faction_control/proc/request_grid_override(mob/user, district, mode = "blackout")
	if(!user) return FALSE
	to_chat(user, span_warning("Faction blackout controls are disabled. Use reactor district load controllers for local power routing."))
	return FALSE

/datum/controller/subsystem/faction_control/proc/request_supply_drop(mob/user, turf/drop_turf, district_override = null)
	if(!user || !drop_turf) return FALSE
	var/faction = get_mob_faction(user)
	if(!faction)
		to_chat(user, span_warning("You are not aligned with a controllable faction."))
		return FALSE
	if(!is_controllable_faction(faction))
		to_chat(user, span_warning("Your faction is not authorized for district control systems."))
		return FALSE

	var/district = district_override
	if(!district)
		district = get_district_for_atom(drop_turf)
	if(!district)
		to_chat(user, span_warning("No valid district at this location."))
		return FALSE
	if(get_owner(district) != faction)
		to_chat(user, span_warning("Your faction does not control [district]."))
		return FALSE

	var/effective_cd = get_effective_supply_cooldown(faction, district)
	var/cd = supply_cd[faction]
	if(cd && world.time < cd)
		var/remaining = round((cd - world.time) / 10)
		to_chat(user, span_warning("Supply channel cooling down ([remaining]s)."))
		return FALSE

	var/supply_cost = get_effective_supply_cost(faction, district)
	if(!spend_faction_funds(faction, supply_cost))
		to_chat(user, span_warning("Faction treasury cannot afford supply drop ([supply_cost])."))
		return FALSE

	var/turf/final_drop_turf = drop_turf
	var/turf/user_turf = get_turf(user)
	if(user_turf && get_district_for_atom(user_turf) == district)
		final_drop_turf = user_turf

	// Spawn a loaded crate, plus visible resources around it for immediate pickup.
	var/obj/structure/closet/crate/C = new(final_drop_turf)
	C.name = "[faction] supply crate"
	C.desc = "A requisitioned crate marked for [faction]."

	var/industry_lvl = get_upgrade_level(district, "industry")
	var/supply_metal = round((FACTION_CTRL_SUPPLY_DROP_METAL + (industry_lvl * 120)) * get_resource_output_mult(faction, district, "metal"))
	var/supply_powder = round((FACTION_CTRL_SUPPLY_DROP_BLACKPOWDER + (industry_lvl * 22)) * get_resource_output_mult(faction, district, "blackpowder"))
	var/supply_caps = round((FACTION_CTRL_SUPPLY_DROP_CAPS + (industry_lvl * 180)) * get_resource_output_mult(faction, district, "caps"))
	spawn_metal_bundle(C, supply_metal)
	spawn_blackpowder_bundle(C, supply_powder)
	spawn_caps_bundle(C, supply_caps)
	if(has_research_unlock(faction, "ind_smelter_chain") && industry_lvl >= 2)
		var/plasteel_amount = round((10 + (industry_lvl * 8)) * get_resource_output_mult(faction, district, "plasteel"))
		spawn_plasteel_bundle(C, max(0, plasteel_amount))
	if(has_research_unlock(faction, "ind_advanced_forges") && industry_lvl >= 3)
		var/titanium_amount = round((8 + (industry_lvl * 6)) * get_resource_output_mult(faction, district, "titanium"))
		spawn_titanium_bundle(C, max(0, titanium_amount))
	spawn_security_ammo_bundle(C, faction, district, 1.0)
	spawn_rare_crafting_bundle(C, get_rare_chance_bonus(faction))

	supply_cd[faction] = world.time + effective_cd
	note_supply_drop(faction, district, user)
	add_research_points(faction, 2)
	world << span_notice("[faction] received a loaded supply drop in [district].")
	return TRUE

/datum/controller/subsystem/faction_control/proc/can_use_faction_locked(mob/user, list/allowed_factions)
	if(!user) return FALSE
	if(!islist(allowed_factions) || !length(allowed_factions))
		return TRUE
	var/f = get_mob_faction(user)
	if(!f) return FALSE
	if(!is_controllable_faction(f)) return FALSE
	var/list/norm_allowed = list()
	for(var/a in allowed_factions)
		var/n = normalize_faction(a)
		if(n) norm_allowed[n] = TRUE
	return !!norm_allowed[f]

/datum/controller/subsystem/faction_control/proc/get_status_rows(for_faction = null)
	bootstrap_districts()
	var/list/rows = list()
	for(var/d in district_income)
		var/owner = district_owner[d]
		var/income = district_income[d]
		if(isnull(income))
			income = FACTION_CTRL_DEFAULT_DISTRICT_INCOME
		var/on = _grid_is_district_on(d)
		var/industry_lvl = get_upgrade_level(d, "industry")
		var/logistics_lvl = get_upgrade_level(d, "logistics")
		var/security_lvl = get_upgrade_level(d, "security")
		var/list/U = get_district_utility_state(d)
		var/water_level = get_district_water_level(d)
		var/logistics_health = get_district_logistics_level(d)
		var/stability = get_district_stability(d)
		var/buildable_kind = get_district_buildable_kind(d)
		var/list/B = get_district_buildable(d)
		var/buildable_name = islist(B) ? "[B["name"]]" : ""
		var/jammed = is_district_jammed(d)
		var/effective_mult = 1.0
		effective_mult += (industry_lvl * 0.15)
		effective_mult *= get_event_income_mult(d)
		effective_mult *= get_buildable_income_mult(d)
		if(owner && get_faction_research_tier(owner) >= 4)
			effective_mult += 0.10
		if(owner && has_research_unlock(owner, "doc_power_focus") && U["power"])
			effective_mult += 0.10
		effective_mult *= get_district_utility_efficiency(d)
		var/effective_income = max(1, round(income * effective_mult))
		rows += list(list(
			"district" = "[d]",
			"owner" = owner ? "[owner]" : "Unclaimed",
			"income" = round(income),
			"effective_income" = effective_income,
			"grid_on" = !!on,
			"power_ok" = !!U["power"],
			"water_ok" = !!U["water"],
			"logistics_ok" = !!U["logistics"],
			"water_level" = water_level,
			"logistics_health" = logistics_health,
			"stability" = stability,
			"jammed" = !!jammed,
			"buildable_kind" = buildable_kind ? "[buildable_kind]" : "",
			"buildable_name" = buildable_name,
			"industry_lvl" = industry_lvl,
			"logistics_lvl" = logistics_lvl,
			"security_lvl" = security_lvl,
			"is_owned_by_you" = (!!for_faction && owner == for_faction)
		))
	return rows

/datum/controller/subsystem/faction_control/proc/get_faction_dashboard(mob/user)
	var/list/data = list()
	var/f = get_mob_faction(user)
	data["faction"] = f ? f : "None"
	data["can_control"] = !!is_controllable_faction(f)
	data["funds"] = get_faction_funds(f)
	var/display_supply_cost = FACTION_CTRL_SUPPLY_COST
	var/list/owned_preview = get_owned_districts(f)
	if(length(owned_preview))
		var/preview_district = owned_preview[1]
		display_supply_cost = get_effective_supply_cost(f, preview_district)
	data["supply_cost"] = display_supply_cost
	data["override_cost"] = 0
	data["rows"] = get_status_rows(f)
	data["district_total"] = length(district_income)
	var/owned_count = 0
	var/owned_income = 0
	for(var/d in district_owner)
		if(district_owner[d] == f)
			owned_count++
			var/inc = district_income[d]
			if(isnull(inc)) inc = FACTION_CTRL_DEFAULT_DISTRICT_INCOME
			owned_income += round(inc)
	data["district_owned"] = owned_count
	data["income_owned"] = owned_income
	var/cd_supply = supply_cd[f]
	data["supply_cd"] = max(0, (cd_supply ? cd_supply - world.time : 0))
	data["supply_ready"] = !(cd_supply && world.time < cd_supply)
	data["contracts"] = get_contract_rows(f)
	data["events"] = get_event_rows()
	data["caravans"] = get_caravan_rows(f)
	data["upgrade_rows"] = get_upgrade_rows(f)
	data["research_rows"] = get_research_rows(f)
	data["water_rows"] = get_water_rows(f)
	data["hazard_rows"] = get_hazard_rows()
	data["buildable_rows"] = get_doctrine_buildable_rows(f)
	data["research_points"] = get_faction_research_points(f)
	data["research_tier"] = get_faction_research_tier(f)
	var/list/RU = faction_research_unlocks[f]
	data["research_unlocked_count"] = islist(RU) ? length(RU) : 0
	data["research_projects_total"] = length(get_research_project_defs())
	var/next_tier = get_faction_research_tier(f) + 1
	data["research_next_cost"] = (next_tier > 4) ? 0 : get_research_unlock_cost(next_tier)
	data["rep"] = get_user_reputation(user, f)
	data["top_rep"] = get_top_rep_rows(f, 5)
	data["intel_points"] = get_faction_intel_points(f)
	var/reveal_until = faction_route_reveal_until[f]
	data["intel_reveal_s"] = max(0, (reveal_until ? round((round(reveal_until) - world.time) / 10) : 0))
	var/template_name = ""
	var/template_need = ""
	var/list/BT = get_buildable_template_for_faction(f)
	if(islist(BT))
		template_name = "[BT["name"]]"
		var/req_id = BT["requires"]
		if(req_id)
			var/list/RP = get_research_project(req_id)
			if(islist(RP))
				template_need = "[RP["name"]]"
	data["buildable_template_name"] = template_name
	data["buildable_template_requires"] = template_need
	return data

/datum/controller/subsystem/faction_control/proc/get_drop_turf_near(atom/center)
	var/turf/base = get_turf(center)
	if(!base) return null
	var/list/candidates = list()
	for(var/turf/T in range(1, base))
		if(!T || T.density) continue
		candidates += T
	if(!length(candidates))
		if(base.density)
			return null
		return base
	if(base in candidates && length(candidates) > 1)
		candidates -= base
	if(!length(candidates))
		return null
	return pick(candidates)

/datum/controller/subsystem/faction_control/proc/spawn_metal_bundle(atom/center, total)
	if(total <= 0) return
	while(total >= 50)
		var/turf/T = get_drop_turf_near(center)
		if(!T) return
		new /obj/item/stack/sheet/metal/fifty(T)
		total -= 50
	while(total >= 20)
		var/turf/T2 = get_drop_turf_near(center)
		if(!T2) return
		new /obj/item/stack/sheet/metal/twenty(T2)
		total -= 20
	while(total >= 10)
		var/turf/T3 = get_drop_turf_near(center)
		if(!T3) return
		new /obj/item/stack/sheet/metal/ten(T3)
		total -= 10
	while(total >= 5)
		var/turf/T4 = get_drop_turf_near(center)
		if(!T4) return
		new /obj/item/stack/sheet/metal/five(T4)
		total -= 5
	if(total > 0)
		var/turf/T5 = get_drop_turf_near(center)
		if(T5)
			var/obj/item/stack/sheet/metal/M = new(T5)
			if(total > 1)
				M.add(total - 1)

/datum/controller/subsystem/faction_control/proc/spawn_blackpowder_bundle(atom/center, total)
	if(total <= 0) return
	while(total >= 50)
		var/turf/T = get_drop_turf_near(center)
		if(!T) return
		new /obj/item/stack/ore/blackpowder/fifty(T)
		total -= 50
	while(total >= 20)
		var/turf/T2 = get_drop_turf_near(center)
		if(!T2) return
		new /obj/item/stack/ore/blackpowder/twenty(T2)
		total -= 20
	while(total >= 5)
		var/turf/T3 = get_drop_turf_near(center)
		if(!T3) return
		new /obj/item/stack/ore/blackpowder/five(T3)
		total -= 5
	while(total >= 2)
		var/turf/T4 = get_drop_turf_near(center)
		if(!T4) return
		new /obj/item/stack/ore/blackpowder/two(T4)
		total -= 2
	if(total > 0)
		var/turf/T5 = get_drop_turf_near(center)
		if(T5)
			var/obj/item/stack/ore/blackpowder/B = new(T5)
			if(total > 1)
				B.add(total - 1)

/datum/controller/subsystem/faction_control/proc/spawn_caps_bundle(atom/center, total)
	if(total <= 0) return
	while(total >= 1000)
		var/turf/T = get_drop_turf_near(center)
		if(!T) return
		new /obj/item/stack/f13Cash/caps/onezerozerozero(T)
		total -= 1000
	while(total >= 500)
		var/turf/T2 = get_drop_turf_near(center)
		if(!T2) return
		new /obj/item/stack/f13Cash/caps/fivezerozero(T2)
		total -= 500
	while(total >= 100)
		var/turf/T3 = get_drop_turf_near(center)
		if(!T3) return
		new /obj/item/stack/f13Cash/caps/onezerozero(T3)
		total -= 100
	if(total > 0)
		var/turf/T4 = get_drop_turf_near(center)
		if(T4)
			var/obj/item/stack/f13Cash/caps/C = new(T4)
			if(total > 1)
				C.add(total - 1)

/datum/controller/subsystem/faction_control/proc/spawn_plasteel_bundle(atom/center, total)
	if(total <= 0) return
	while(total >= 50)
		var/turf/T = get_drop_turf_near(center)
		if(!T) return
		new /obj/item/stack/sheet/plasteel/fifty(T)
		total -= 50
	while(total >= 20)
		var/turf/T2 = get_drop_turf_near(center)
		if(!T2) return
		new /obj/item/stack/sheet/plasteel/twenty(T2)
		total -= 20
	while(total >= 5)
		var/turf/T3 = get_drop_turf_near(center)
		if(!T3) return
		new /obj/item/stack/sheet/plasteel/five(T3)
		total -= 5
	if(total > 0)
		var/turf/T4 = get_drop_turf_near(center)
		if(T4)
			var/obj/item/stack/sheet/plasteel/P = new(T4)
			if(total > 1)
				P.add(total - 1)

/datum/controller/subsystem/faction_control/proc/spawn_titanium_bundle(atom/center, total)
	if(total <= 0) return
	while(total >= 50)
		var/turf/T = get_drop_turf_near(center)
		if(!T) return
		new /obj/item/stack/sheet/mineral/titanium/fifty(T)
		total -= 50
	while(total >= 25)
		var/turf/T2 = get_drop_turf_near(center)
		if(!T2) return
		new /obj/item/stack/sheet/mineral/titanium/twentyfive(T2)
		total -= 25
	if(total > 0)
		var/turf/T3 = get_drop_turf_near(center)
		if(T3)
			var/obj/item/stack/sheet/mineral/titanium/Ti = new(T3)
			if(total > 1)
				Ti.add(total - 1)

/datum/controller/subsystem/faction_control/proc/spawn_security_ammo_bundle(atom/center, faction, district, intensity_scale = 1.0)
	if(!center || !faction || !district) return
	var/security_lvl = get_upgrade_level(district, "security")
	if(security_lvl <= 0) return

	var/m = get_resource_output_mult(faction, district, "ammo")
	m *= max(0.5, intensity_scale)
	var/rolls = clamp(round((security_lvl + 1) * m), 1, 10)

	for(var/i in 1 to rolls)
		var/turf/T = get_drop_turf_near(center)
		if(!T) return
		switch(security_lvl)
			if(1)
				switch(rand(1, 3))
					if(1) new /obj/item/ammo_box/magazine/m9mm(T)
					if(2) new /obj/item/ammo_box/magazine/m10mm/adv(T)
					if(3) new /obj/item/ammo_box/magazine/m45(T)
			if(2)
				switch(rand(1, 6))
					if(1) new /obj/item/ammo_box/magazine/m9mm(T)
					if(2) new /obj/item/ammo_box/magazine/m10mm/adv(T)
					if(3) new /obj/item/ammo_box/magazine/m45(T)
					if(4) new /obj/item/ammo_box/magazine/m556/rifle/small(T)
					if(5) new /obj/item/ammo_box/shotgun/buck(T)
					if(6) new /obj/item/ammo_box/magazine/m556/rifle/small(T)
			else
				switch(rand(1, 8))
					if(1) new /obj/item/ammo_box/magazine/m10mm/adv(T)
					if(2) new /obj/item/ammo_box/magazine/m45(T)
					if(3) new /obj/item/ammo_box/magazine/m556/rifle/small(T)
					if(4) new /obj/item/ammo_box/shotgun/buck(T)
					if(5) new /obj/item/ammo_box/a308(T)
					if(6) new /obj/item/ammo_box/magazine/m556/rifle(T)
					if(7) new /obj/item/ammo_box/a308(T)
					if(8) new /obj/item/ammo_box/shotgun/buck(T)

	if(has_research_unlock(faction, "sec_ballistics_doctrine"))
		var/extra_ballistic = clamp(round((security_lvl * 0.8) * m), 1, 5)
		for(var/j in 1 to extra_ballistic)
			var/turf/Tb = get_drop_turf_near(center)
			if(!Tb) return
			switch(rand(1, 4))
				if(1) new /obj/item/ammo_box/magazine/m10mm/adv(Tb)
				if(2) new /obj/item/ammo_box/magazine/m556/rifle/small(Tb)
				if(3) new /obj/item/ammo_box/shotgun/buck(Tb)
				if(4) new /obj/item/ammo_box/magazine/m45(Tb)

	if(has_research_unlock(faction, "sec_energy_doctrine") && security_lvl >= 2)
		var/ecells = clamp(round((security_lvl * 0.5) * m), 1, 4)
		for(var/k in 1 to ecells)
			var/turf/Te = get_drop_turf_near(center)
			if(!Te) return
			new /obj/item/stock_parts/cell/ammo/ec(Te)

	if(has_research_unlock(faction, "sec_munitions_fabricator") && security_lvl >= 3)
		var/advanced = clamp(round(1 + m), 1, 4)
		for(var/n in 1 to advanced)
			var/turf/Ta = get_drop_turf_near(center)
			if(!Ta) return
			switch(rand(1, 3))
				if(1) new /obj/item/ammo_box/a308(Ta)
				if(2) new /obj/item/ammo_box/magazine/m556/rifle(Ta)
				if(3) new /obj/item/ammo_box/shotgun/buck(Ta)

/datum/controller/subsystem/faction_control/proc/spawn_rare_crafting_bundle(atom/center, bonus_chance = 0)
	var/chance = clamp(FACTION_CTRL_RARE_CRAFT_CHANCE + round(bonus_chance), 0, 95)
	if(!prob(chance))
		return

	var/rolls = rand(1, FACTION_CTRL_RARE_CRAFT_MAX_ROLLS)
	for(var/i in 1 to rolls)
		var/turf/T = get_drop_turf_near(center)
		if(!T) return
		switch(rand(1, 10))
			if(1)
				new /obj/item/stack/crafting/goodparts/three(T)
			if(2)
				new /obj/item/stack/crafting/electronicparts/three(T)
			if(3)
				new /obj/item/stack/sheet/plasteel/five(T)
			if(4)
				new /obj/item/crafting/wonderglue(T)
			if(5)
				new /obj/item/crafting/board(T)
			if(6)
				new /obj/item/crafting/transistor(T)
			if(7)
				new /obj/item/crafting/diode(T)
			if(8)
				new /obj/item/crafting/capacitor(T)
			if(9)
				new /obj/item/crafting/fuse(T)
			if(10)
				new /obj/item/stack/sheet/lead/five(T)

/datum/controller/subsystem/faction_control/proc/roll_contracts()
	bootstrap_districts()
	for(var/f in controllable_factions)
		var/list/contracts = faction_contracts[f]
		if(!islist(contracts))
			contracts = list()
			faction_contracts[f] = contracts

		var/list/remove = list()
		for(var/datum/faction_control_contract/C in contracts)
			if(!C || QDELETED(C))
				remove += C
				continue
			if(world.time >= C.expires_at)
				remove += C
		contracts -= remove

		while(length(contracts) < FACTION_CTRL_CONTRACTS_PER_FACTION)
			var/datum/faction_control_contract/new_contract = generate_contract_for_faction(f)
			if(!new_contract)
				break
			contracts += new_contract

/datum/controller/subsystem/faction_control/proc/generate_contract_for_faction(faction)
	if(!faction) return null
	var/list/owned = get_owned_districts(faction)
	var/list/unowned = list()
	var/list/enemy_owned = list()
	var/list/owned_hotspots = list()
	var/list/owned_utility_crisis = list()
	var/list/owned_water_crisis = list()
	var/list/owned_hazards = list()
	for(var/d in district_income)
		var/o = get_owner(d)
		if(o == faction)
			if(has_hostile_event_in_district(d))
				owned_hotspots += "[d]"
			var/list/U = get_district_utility_state(d)
			if(!U["power"] || !U["logistics"] || get_district_stability(d) < FACTION_CTRL_STABILITY_LOW)
				owned_utility_crisis += "[d]"
			if(get_district_water_level(d) < 35)
				owned_water_crisis += "[d]"
			if(get_active_hazard_for_district(d))
				owned_hazards += "[d]"
			continue
		if(!o)
			unowned += "[d]"
		else
			enemy_owned += "[d]"

	var/list/options = list("treasury")
	if(length(owned))
		options += "supply_run"
		options += "defend_node"
		options += "pad_link"
	if(length(owned_hotspots))
		options += "clear_nest"
		options += "clear_nest"
	if(length(owned_utility_crisis))
		options += "utility_crisis"
		options += "stability_push"
	if(length(owned_water_crisis))
		options += "water_crisis"
	if(length(owned_hazards))
		options += "hazard_extract"
	if(length(unowned))
		options += "expand"
	if(length(unowned) || length(enemy_owned))
		options += "sabotage_reactor_line"
	if(length(owned) >= 2)
		options += "escort"

	var/chosen = pick(options)
	var/datum/faction_control_contract/C = new
	C.id = "C[next_contract_id++]"
	C.faction = faction
	C.contract_type = chosen
	C.expires_at = world.time + FACTION_CTRL_CONTRACT_DURATION
	C.reward_caps = FACTION_CTRL_CONTRACT_REWARD_CAPS
	C.reward_rep = FACTION_CTRL_CONTRACT_REWARD_REP
	C.reward_research = FACTION_CTRL_CONTRACT_REWARD_RESEARCH

	switch(chosen)
		if("clear_nest")
			C.district = length(owned_hotspots) ? pick(owned_hotspots) : pick(owned)
			C.target = 1
			C.title = "Clear Nest ([C.district])"
			C.desc = "Eliminate hostile activity and stabilize [C.district]."
			C.reward_research += 5
			C.reward_rep += 1
		if("utility_crisis")
			C.district = length(owned_utility_crisis) ? pick(owned_utility_crisis) : pick(owned)
			C.target = 1
			C.title = "Crisis Contract: Restore Utilities ([C.district])"
			C.desc = "Restore power/logistics stability in [C.district]."
			C.reward_caps += 45
			C.reward_research += 6
		if("stability_push")
			C.district = length(owned_utility_crisis) ? pick(owned_utility_crisis) : pick(owned)
			C.target = 45
			C.title = "Crisis Contract: Raise Stability ([C.district])"
			C.desc = "Raise district stability to [C.target]+ in [C.district]."
			C.reward_caps += 30
			C.reward_research += 4
			C.reward_rep += 1
		if("water_crisis")
			C.district = length(owned_water_crisis) ? pick(owned_water_crisis) : pick(owned)
			C.target = 35
			C.title = "Crisis Contract: Restore Water ([C.district])"
			C.desc = "Bring district water level to [C.target]+ in [C.district]."
			C.reward_caps += 35
			C.reward_research += 5
		if("hazard_extract")
			C.district = length(owned_hazards) ? pick(owned_hazards) : pick(owned)
			C.target = 1
			C.baseline = get_hazard_extract_count(faction, C.district)
			C.title = "Hazard Zone Extraction ([C.district])"
			C.desc = "Run a hazard extraction in [C.district] while the window is active."
			C.reward_caps += 55
			C.reward_research += 6
		if("defend_node")
			C.district = pick(owned)
			C.target = 1
			C.title = "Defend Relay Node ([C.district])"
			C.desc = "Keep [C.district] controlled with grid routing online."
			C.reward_rep += 1
		if("supply_run")
			C.district = pick(owned)
			C.target = 2
			C.baseline = get_supply_count(faction, C.district)
			C.title = "Supply Run ([C.district])"
			C.desc = "Call [C.target] supply drops into [C.district]."
		if("stabilize")
			C.district = pick(owned)
			C.target = 1
			C.title = "Stabilize Grid ([C.district])"
			C.desc = "Ensure [C.district] grid is online."
		if("pad_link")
			C.district = pick(owned)
			C.target = 1
			C.title = "Industrial Link ([C.district])"
			C.desc = "Link and activate a resource pad in [C.district]."
			C.reward_research += 4
		if("expand")
			if(length(unowned))
				C.district = pick(unowned)
			else
				C.district = pick(enemy_owned)
			C.target = 1
			C.title = "Expansion ([C.district])"
			C.desc = "Capture control of [C.district]."
			C.reward_caps += 40
			C.reward_research += 2
		if("escort")
			C.district = pick(owned)
			C.target = 1
			C.baseline = get_caravan_count(faction, C.district)
			C.title = "Escort Caravan ([C.district])"
			C.desc = "Complete an escorted caravan arriving at [C.district]."
			C.reward_caps += 35
			C.reward_research += 4
		if("caravan")
			C.district = pick(owned)
			C.target = 1
			C.baseline = get_caravan_count(faction, C.district)
			C.title = "Caravan Route ([C.district])"
			C.desc = "Complete a caravan arriving at [C.district]."
			C.reward_caps += 35
			C.reward_research += 4
		if("sabotage_reactor_line")
			if(length(enemy_owned))
				C.district = pick(enemy_owned)
			else
				C.district = pick(unowned)
			C.target = 1
			C.title = "Sabotage Reactor Line ([C.district])"
			C.desc = "Seize [C.district] to sever enemy routing and disrupt their reactor line."
			C.reward_caps += 55
			C.reward_research += 5
			C.reward_rep += 1
		else
			C.baseline = get_faction_funds(faction)
			C.target = C.baseline + 150
			C.title = "Treasury Milestone"
			C.desc = "Raise faction treasury to [C.target] caps."
			C.reward_caps += 25
	return C

/datum/controller/subsystem/faction_control/proc/get_contract_progress(datum/faction_control_contract/C)
	if(!C || !C.faction) return 0
	switch(C.contract_type)
		if("clear_nest")
			if(get_owner(C.district) != C.faction)
				return 0
			return has_hostile_event_in_district(C.district) ? 0 : 1
		if("utility_crisis")
			var/list/U = get_district_utility_state(C.district)
			return (get_owner(C.district) == C.faction && U["power"] && U["logistics"]) ? 1 : 0
		if("stability_push")
			return get_owner(C.district) == C.faction ? get_district_stability(C.district) : 0
		if("water_crisis")
			return get_owner(C.district) == C.faction ? get_district_water_level(C.district) : 0
		if("hazard_extract")
			return max(0, get_hazard_extract_count(C.faction, C.district) - C.baseline)
		if("defend_node")
			return (get_owner(C.district) == C.faction && _grid_is_district_on(C.district)) ? 1 : 0
		if("supply_run")
			return max(0, get_supply_count(C.faction, C.district) - C.baseline)
		if("stabilize")
			return (get_owner(C.district) == C.faction && _grid_is_district_on(C.district)) ? 1 : 0
		if("pad_link")
			return has_active_linked_pad_for_district(C.faction, C.district) ? 1 : 0
		if("expand")
			return (get_owner(C.district) == C.faction) ? 1 : 0
		if("sabotage_reactor_line")
			return (get_owner(C.district) == C.faction) ? 1 : 0
		if("escort")
			return max(0, get_caravan_count(C.faction, C.district) - C.baseline)
		if("caravan")
			return max(0, get_caravan_count(C.faction, C.district) - C.baseline)
		if("treasury")
			return get_faction_funds(C.faction)
	return 0

/datum/controller/subsystem/faction_control/proc/is_contract_complete(datum/faction_control_contract/C)
	if(!C) return FALSE
	var/p = get_contract_progress(C)
	return p >= C.target

/datum/controller/subsystem/faction_control/proc/turn_in_contract(mob/user, contract_id)
	if(!user || !contract_id) return FALSE
	var/f = get_mob_faction(user)
	if(!f || !is_controllable_faction(f))
		to_chat(user, span_warning("You cannot turn in faction contracts."))
		return FALSE

	var/list/contracts = faction_contracts[f]
	if(!islist(contracts) || !length(contracts))
		to_chat(user, span_warning("No active contracts."))
		return FALSE

	var/datum/faction_control_contract/target_contract = null
	for(var/datum/faction_control_contract/C in contracts)
		if(C.id == contract_id)
			target_contract = C
			break
	if(!target_contract)
		to_chat(user, span_warning("That contract is no longer available."))
		return FALSE
	if(world.time >= target_contract.expires_at)
		to_chat(user, span_warning("Contract expired."))
		contracts -= target_contract
		return FALSE
	if(!is_contract_complete(target_contract))
		var/progress = get_contract_progress(target_contract)
		to_chat(user, span_warning("Contract incomplete ([progress]/[target_contract.target])."))
		return FALSE

	var/reward_caps = target_contract.reward_caps
	var/reward_research = target_contract.reward_research
	var/reward_rep = target_contract.reward_rep
	var/build_kind = target_contract.district ? get_district_buildable_kind(target_contract.district) : null
	if(build_kind == "legion_warcamp" && (target_contract.contract_type in list("clear_nest", "sabotage_reactor_line", "defend_node", "utility_crisis")))
		reward_caps += 20
	if(build_kind == "town_trade_hub")
		reward_rep += 1
	if(has_research_unlock(f, "doc_medical_focus"))
		reward_research += 2
		reward_rep += 1
	if(has_research_unlock(f, "doc_military_focus"))
		reward_caps += 15
	add_faction_funds(f, reward_caps)
	add_research_points(f, reward_research)
	add_user_reputation(user, f, reward_rep)
	spawn_rare_crafting_bundle(get_turf(user), get_rare_chance_bonus(f))
	contracts -= target_contract
	to_chat(user, span_notice("Contract complete: [target_contract.title]. Treasury +[reward_caps], research +[reward_research], rep +[reward_rep]."))
	roll_contracts()
	return TRUE

/datum/controller/subsystem/faction_control/proc/get_contract_rows(faction)
	var/list/rows = list()
	if(!faction) return rows
	var/list/contracts = faction_contracts[faction]
	if(!islist(contracts)) return rows
	for(var/datum/faction_control_contract/C in contracts)
		if(!C) continue
		var/progress = get_contract_progress(C)
		rows += list(list(
			"id" = C.id,
			"title" = C.title,
			"type" = C.contract_type,
			"district" = C.district ? "[C.district]" : "-",
			"desc" = C.desc ? "[C.desc]" : "",
			"target" = C.target,
			"progress" = progress,
			"complete" = (progress >= C.target),
			"reward_caps" = C.reward_caps,
			"reward_rep" = C.reward_rep,
			"reward_research" = C.reward_research,
			"expires_s" = max(0, round((C.expires_at - world.time) / 10))
		))
	return rows

/datum/controller/subsystem/faction_control/proc/spawn_world_event()
	bootstrap_districts()
	if(!length(district_income)) return
	if(length(active_events) >= 3) return

	var/list/districts = list()
	for(var/d in district_income)
		districts += "[d]"
	if(!length(districts)) return
	var/chosen_district = pick(districts)

	var/datum/faction_control_event/E = new
	E.id = "E[next_event_id++]"
	E.district = chosen_district
	E.started_at = world.time
	E.ends_at = world.time + FACTION_CTRL_EVENT_DURATION

	switch(rand(1, 7))
		if(1)
			E.event_type = "crashed_convoy"
			E.title = "Crashed Convoy"
			E.desc = "A downed convoy in [chosen_district] attracts scavengers and raiders."
			E.output_mult = 1.20
			E.caravan_mult = 1.15
			spawn_hazard_zone(chosen_district, "salvage_window", "Convoy Salvage Window", "Scavengers report exposed high-value cargo around the crash site.")
		if(2)
			E.event_type = "raider_cache"
			E.title = "Raider Cache"
			E.desc = "Raiders are massing around a hidden cache in [chosen_district]."
			E.income_mult = 0.90
			E.output_mult = 0.95
			E.logistics_mult = 0.85
			E.hostile = TRUE
		if(3)
			E.event_type = "radstorm_shelter"
			E.title = "Radstorm Shelter Rush"
			E.desc = "A severe radstorm pushes survivors into shelter routes near [chosen_district]."
			E.income_mult = 0.85
			E.caravan_mult = 0.85
			E.water_mult = 0.90
			spawn_hazard_zone(chosen_district, "radstorm_window", "Radstorm Extraction Window", "Radiation spikes are exposing rare salvage seams.")
		if(4)
			E.event_type = "mutant_surge"
			E.title = "Mutant Surge"
			E.desc = "Mutant packs are flooding [chosen_district]."
			E.income_mult = 0.80
			E.output_mult = 0.85
			E.logistics_mult = 0.80
			E.hostile = TRUE
			if(SSmonster_wave && hascall(SSmonster_wave, "spawn_monsterwave"))
				call(SSmonster_wave, "spawn_monsterwave")()
		if(5)
			E.event_type = "drought"
			E.title = "Drought Pressure"
			E.desc = "Water lines in [chosen_district] are collapsing under drought pressure."
			E.income_mult = 0.90
			E.output_mult = 0.90
			E.water_mult = 0.65
		if(6)
			E.event_type = "signal_blackout"
			E.title = "Signal Blackout"
			E.desc = "Long-range comms around [chosen_district] are disrupted."
			E.caravan_mult = 0.82
			E.logistics_mult = 0.75
			district_jam_until[chosen_district] = max(round(district_jam_until[chosen_district]), world.time + 2 MINUTES)
		if(7)
			E.event_type = "caravan_ambush"
			E.title = "Caravan Ambush Corridor"
			E.desc = "Raiders are actively ambushing routes in [chosen_district]."
			E.income_mult = 0.88
			E.caravan_mult = 0.72
			E.logistics_mult = 0.78
			E.hostile = TRUE

	active_events += E
	world << span_warning("Wasteland Event: [E.title] in [chosen_district] ([round((E.ends_at - world.time) / 10)]s).")

/datum/controller/subsystem/faction_control/proc/process_world_events()
	if(!length(active_events)) return
	var/list/remove = list()
	for(var/datum/faction_control_event/E in active_events)
		if(!E)
			remove += E
			continue
		if(E.expired(world.time))
			world << span_notice("Wasteland Event ended: [E.title] in [E.district].")
			remove += E
	active_events -= remove

/datum/controller/subsystem/faction_control/proc/get_event_rows()
	var/list/rows = list()
	for(var/datum/faction_control_event/E in active_events)
		if(!E || E.expired(world.time)) continue
		rows += list(list(
			"id" = E.id,
			"title" = E.title,
			"type" = E.event_type,
			"district" = E.district ? "[E.district]" : "-",
			"desc" = E.desc ? "[E.desc]" : "",
			"remaining_s" = max(0, round((E.ends_at - world.time) / 10))
		))
	return rows

/datum/controller/subsystem/faction_control/proc/get_anchor_turf_for_district(district)
	if(!district) return null
	for(var/obj/machinery/f13/faction_capture_node/N in capture_nodes)
		if(!N || QDELETED(N)) continue
		if(N.get_district() != district) continue
		var/turf/T = get_turf(N)
		if(T) return T
	for(var/obj/machinery/f13/faction_resource_pad/P in resource_pads)
		if(!P || QDELETED(P)) continue
		if(P.get_district() != district) continue
		var/turf/T2 = get_turf(P)
		if(T2) return T2
	for(var/obj/machinery/f13/faction_water_purifier/W in water_nodes)
		if(!W || QDELETED(W)) continue
		if(W.get_district() != district) continue
		var/turf/T3 = get_turf(W)
		if(T3) return T3
	return null

/datum/controller/subsystem/faction_control/proc/start_caravan(mob/user, from_district)
	if(!user || !from_district) return FALSE
	var/f = get_mob_faction(user)
	if(!f || !is_controllable_faction(f))
		to_chat(user, span_warning("Only controllable factions can launch caravans."))
		return FALSE
	if(get_owner(from_district) != f)
		to_chat(user, span_warning("Your faction does not own [from_district]."))
		return FALSE

	var/to_district = get_primary_destination_for_caravan(f, from_district)
	if(!to_district)
		to_chat(user, span_warning("Need at least two owned districts to route a caravan."))
		return FALSE

	var/running = 0
	for(var/datum/faction_control_caravan/C in active_caravans)
		if(!C) continue
		if(C.faction == f)
			running++
	if(running >= FACTION_CTRL_MAX_ACTIVE_CARAVANS)
		to_chat(user, span_warning("Faction already has [FACTION_CTRL_MAX_ACTIVE_CARAVANS] active caravans."))
		return FALSE

	if(!spend_faction_funds(f, FACTION_CTRL_CARAVAN_COST))
		to_chat(user, span_warning("Faction treasury cannot afford a caravan ([FACTION_CTRL_CARAVAN_COST])."))
		return FALSE

	var/datum/faction_control_caravan/N = new
	N.id = "CV[next_caravan_id++]"
	N.faction = f
	N.from_district = from_district
	N.to_district = to_district
	N.started_at = world.time
	N.arrive_at = world.time + get_effective_caravan_duration(f, from_district)
	var/from_income = district_income[from_district]
	if(isnull(from_income)) from_income = 0
	var/to_income = district_income[to_district]
	if(isnull(to_income)) to_income = 0
	N.base_reward_caps = 90 + round(from_income + to_income)
	N.base_reward_research = has_research_unlock(f, "logi_bulk_freight") ? 10 : 8
	N.started_by_ckey = user.client?.ckey
	N.cargo_manifest = list(
		"metal" = 90 + (get_upgrade_level(from_district, "industry") * 30),
		"blackpowder" = 20 + (get_upgrade_level(from_district, "industry") * 12),
		"caps" = max(60, round(N.base_reward_caps * 0.6))
	)
	var/turf/from_anchor = get_anchor_turf_for_district(from_district)
	var/turf/to_anchor = get_anchor_turf_for_district(to_district)
	if(from_anchor)
		var/obj/structure/f13/faction_caravan_marker/M = new(from_anchor)
		M.setup_route(N.id, f, from_district, to_district, to_anchor, N.cargo_manifest)
		N.cart_ref = WEAKREF(M)
	if(from_anchor)
		N.from_anchor_ref = WEAKREF(from_anchor)
	if(to_anchor)
		N.to_anchor_ref = WEAKREF(to_anchor)
	active_caravans += N

	world << span_notice("[f] launched a caravan from [from_district] to [to_district].")
	return TRUE

/datum/controller/subsystem/faction_control/proc/process_caravans()
	if(!length(active_caravans)) return
	var/list/remove = list()
	for(var/datum/faction_control_caravan/C in active_caravans)
		if(!C)
			remove += C
			continue
		if(world.time < C.arrive_at)
			var/obj/structure/f13/faction_caravan_marker/MovingCart = RESOLVEWEAKREF(C.cart_ref)
			var/turf/TargetTurf = RESOLVEWEAKREF(C.to_anchor_ref)
			if(MovingCart && TargetTurf)
				if(get_dist(MovingCart, TargetTurf) > 0)
					step_towards(MovingCart, TargetTurf)
			continue

		var/obj/structure/f13/faction_caravan_marker/Cart = RESOLVEWEAKREF(C.cart_ref)
		if(!Cart || QDELETED(Cart))
			C.compromised = TRUE

		if(C.compromised && prob(45))
			world << span_warning("[C.faction] caravan en route to [C.to_district] was lost after hostile interference.")
			var/datum/faction_control_event/Loss = new
			Loss.id = "E[next_event_id++]"
			Loss.district = C.to_district
			Loss.started_at = world.time
			Loss.ends_at = world.time + 3 MINUTES
			Loss.event_type = "caravan_loss"
			Loss.title = "Caravan Loss"
			Loss.desc = "A convoy was lost near [C.to_district], disrupting local logistics."
			Loss.caravan_mult = 0.75
			Loss.logistics_mult = 0.80
			Loss.hostile = TRUE
			active_events += Loss
			if(Cart && !QDELETED(Cart))
				qdel(Cart)
			remove += C
			continue

		var/m = 1.0
		m *= get_event_caravan_mult(C.from_district)
		m *= get_event_caravan_mult(C.to_district)
		m += (get_upgrade_level(C.from_district, "logistics") * 0.05)
		m += (get_upgrade_level(C.to_district, "logistics") * 0.05)
		m *= get_district_utility_efficiency(C.from_district)
		m *= get_district_utility_efficiency(C.to_district)
		m *= get_effective_caravan_reward_mult(C.faction, C.from_district, C.to_district)
		if(C.compromised)
			m *= 0.85

		var/caps = max(1, round(C.base_reward_caps * m))
		add_faction_funds(C.faction, caps)
		add_research_points(C.faction, C.base_reward_research)
		caravan_count_by_key["[C.faction]|[C.to_district]"] = get_caravan_count(C.faction, C.to_district) + 1
		district_last_caravan_time[C.to_district] = world.time

		// Caravans now physically reinforce districts by delivering materials
		// (if a linked resource pad exists for the destination district).
		var/obj/machinery/f13/faction_resource_pad/P = get_active_linked_pad_for_district(C.faction, C.to_district)
		if(P)
			var/industry_lvl = get_upgrade_level(C.to_district, "industry")
			var/shipment_metal = round((120 + (industry_lvl * 60)) * get_resource_output_mult(C.faction, C.to_district, "metal"))
			var/shipment_powder = round((25 + (industry_lvl * 15)) * get_resource_output_mult(C.faction, C.to_district, "blackpowder"))
			spawn_metal_bundle(P, max(0, shipment_metal))
			spawn_blackpowder_bundle(P, max(0, shipment_powder))
			if(has_research_unlock(C.faction, "ind_smelter_chain") && industry_lvl >= 2)
				var/ship_plasteel = round((8 + (industry_lvl * 5)) * get_resource_output_mult(C.faction, C.to_district, "plasteel"))
				spawn_plasteel_bundle(P, max(0, ship_plasteel))
			if(has_research_unlock(C.faction, "ind_advanced_forges") && industry_lvl >= 3)
				var/ship_titanium = round((6 + (industry_lvl * 4)) * get_resource_output_mult(C.faction, C.to_district, "titanium"))
				spawn_titanium_bundle(P, max(0, ship_titanium))
			spawn_security_ammo_bundle(P, C.faction, C.to_district, 0.65)

		for(var/mob/M in GLOB.player_list)
			if(M.client && M.client.ckey == C.started_by_ckey)
				add_user_reputation(M, C.faction, 2)
				break

		if(Cart && !QDELETED(Cart))
			qdel(Cart)
		world << span_notice("[C.faction] caravan arrived in [C.to_district]. Treasury +[caps], research +[C.base_reward_research].")
		remove += C

	active_caravans -= remove

/datum/controller/subsystem/faction_control/proc/get_caravan_rows(faction)
	var/list/rows = list()
	if(!faction) return rows
	var/show_enemy = can_see_enemy_caravans(faction)
	for(var/datum/faction_control_caravan/C in active_caravans)
		if(!C) continue
		var/is_enemy = (C.faction != faction)
		if(is_enemy && !show_enemy) continue
		var/list/manifest = C.cargo_manifest
		var/manifest_txt = ""
		if(islist(manifest))
			manifest_txt = "metal [round(manifest["metal"])] / powder [round(manifest["blackpowder"])] / caps [round(manifest["caps"])]"
		rows += list(list(
			"id" = C.id,
			"from_district" = "[C.from_district]",
			"to_district" = "[C.to_district]",
			"eta_s" = max(0, round((C.arrive_at - world.time) / 10)),
			"reward_caps" = C.base_reward_caps,
			"is_enemy" = !!is_enemy,
			"faction" = "[C.faction]",
			"compromised" = !!C.compromised,
			"manifest" = manifest_txt
		))
	return rows

/datum/controller/subsystem/faction_control/proc/get_upgrade_rows(faction)
	var/list/rows = list()
	for(var/d in district_income)
		var/owner = get_owner(d)
		var/owned_by_you = (faction && owner == faction)
		var/industry_lvl = get_upgrade_level(d, "industry")
		var/logistics_lvl = get_upgrade_level(d, "logistics")
		var/security_lvl = get_upgrade_level(d, "security")
		var/industry_next = (industry_lvl >= FACTION_CTRL_UPGRADE_MAX_LEVEL) ? "MAX" : get_upgrade_tier_effect("industry", industry_lvl + 1)
		var/logistics_next = (logistics_lvl >= FACTION_CTRL_UPGRADE_MAX_LEVEL) ? "MAX" : get_upgrade_tier_effect("logistics", logistics_lvl + 1)
		var/security_next = (security_lvl >= FACTION_CTRL_UPGRADE_MAX_LEVEL) ? "MAX" : get_upgrade_tier_effect("security", security_lvl + 1)
		rows += list(list(
			"district" = "[d]",
			"owner" = owner ? "[owner]" : "Unclaimed",
			"is_owned_by_you" = !!owned_by_you,
			"industry_lvl" = industry_lvl,
			"logistics_lvl" = logistics_lvl,
			"security_lvl" = security_lvl,
			"industry_cost" = get_upgrade_cost(d, "industry"),
			"logistics_cost" = get_upgrade_cost(d, "logistics"),
			"security_cost" = get_upgrade_cost(d, "security"),
			"industry_next" = industry_next,
			"logistics_next" = logistics_next,
			"security_next" = security_next
		))
	return rows

/datum/faction_control_contract
	var/id = ""
	var/faction = null
	var/contract_type = ""
	var/title = ""
	var/desc = ""
	var/district = null
	var/baseline = 0
	var/target = 1
	var/reward_caps = 0
	var/reward_rep = 0
	var/reward_research = 0
	var/expires_at = 0

/datum/faction_control_event
	var/id = ""
	var/event_type = ""
	var/title = ""
	var/desc = ""
	var/district = null
	var/started_at = 0
	var/ends_at = 0
	var/income_mult = 1.0
	var/output_mult = 1.0
	var/caravan_mult = 1.0
	var/water_mult = 1.0
	var/logistics_mult = 1.0
	var/hostile = FALSE

/datum/faction_control_event/proc/expired(now_time)
	return now_time >= ends_at

/datum/faction_control_caravan
	var/id = ""
	var/faction = null
	var/from_district = null
	var/to_district = null
	var/started_at = 0
	var/arrive_at = 0
	var/base_reward_caps = 0
	var/base_reward_research = 0
	var/started_by_ckey = null
	var/compromised = FALSE
	var/list/cargo_manifest = null
	var/datum/weakref/cart_ref = null
	var/datum/weakref/from_anchor_ref = null
	var/datum/weakref/to_anchor_ref = null

/datum/faction_hazard_zone
	var/id = ""
	var/hazard_type = ""
	var/title = ""
	var/desc = ""
	var/district = null
	var/started_at = 0
	var/ends_at = 0
	var/resource_mult = 1.0

/datum/faction_hazard_zone/proc/expired(now_time)
	return now_time >= ends_at

/obj/machinery/f13/faction_locked
	name = "faction-locked device"
	desc = "A device with faction authorization."
	icon = 'icons/obj/machines/antimatter.dmi'
	icon_state = "control_on"
	density = TRUE

	var/list/allowed_factions = null
	var/require_district_owner = FALSE
	/// Optional research id that must be unlocked by the user's faction.
	var/required_research_unlock = null
	/// Last computed access failure reason for user-facing feedback.
	var/tmp/last_access_denial_reason = null

/obj/machinery/f13/faction_locked/proc/can_user_access(mob/user)
	last_access_denial_reason = null
	if(!SSfaction_control)
		last_access_denial_reason = "Access denied: faction control subsystem unavailable."
		return FALSE
	if(!SSfaction_control.can_use_faction_locked(user, allowed_factions))
		last_access_denial_reason = "Access denied: faction authorization failed."
		return FALSE
	var/f = SSfaction_control.get_mob_faction(user)
	if(required_research_unlock)
		if(!SSfaction_control.has_research_unlock(f, required_research_unlock))
			var/list/P = SSfaction_control.get_research_project(required_research_unlock)
			if(islist(P))
				last_access_denial_reason = "Access denied: requires research '[P["name"]]'."
			else
				last_access_denial_reason = "Access denied: required research not unlocked."
			return FALSE
	if(require_district_owner)
		var/d = SSfaction_control.get_district_for_atom(src)
		if(!d)
			last_access_denial_reason = "Access denied: this device has no district configured."
			return FALSE
		if(d)
			var/o = SSfaction_control.get_owner(d)
			if(o && f != o)
				last_access_denial_reason = "Access denied: district not controlled by your faction."
				return FALSE
	return TRUE

/obj/machinery/f13/faction_locked/attack_hand(mob/user)
	if(!can_user_access(user))
		to_chat(user, span_warning(last_access_denial_reason ? last_access_denial_reason : "Access denied: faction authorization failed."))
		return
	return ..()
