// ====================================================
// ROBOT HARDWARE DEFINES
// ====================================================

/// Trait added to robots with microphone hardware installed.
/// Signals behavior circuits to process heard speech.
#define TRAIT_HEARING_HARDWARE  "trait_hearing_hardware"

/// Signal fired by robot_hardware/clock each tick interval.
/// Received by behavior circuits using Trigger: On Clock Tick.
// COMSIG_ROBOT_CLOCK_TICK defined in behavior_defines.dm

// ====================================================
// ROBOT HARDWARE SYSTEM
// F13-native replacement for the SS13 integrated
// circuit system. Hardware datums represent physical
// capabilities installed into a robot at the workshop.
//
// Each datum has:
//   - Configurable vars with types for the workshop UI
//   - CORE costs (compute/operations/resilience/energy)
//   - INT minimum to install
//   - install(robot) / uninstall(robot) procs
//   - tutorial_text for newbie guidance
//
// File: code/modules/integrated_electronics/robot_hardware.dm
// ====================================================


// ====================================================
// INT GATE DEFINES
// ====================================================

#define RH_INT_BASIC    1   // Any builder
#define RH_INT_STANDARD 5   // Competent builder
#define RH_INT_ADVANCED 7   // Expert builder
#define RH_INT_MASTER   9   // Circuit board unlocked


// ====================================================
// HARDWARE CATEGORY DEFINES
// Used by workshop picker to group hardware
// ====================================================

#define RHC_WEAPONS      "Weapons"
#define RHC_MANIPULATION "Manipulation"
#define RHC_REAGENTS     "Reagents"
// RHC_ATMOSPHERICS removed: no atmos hardware. Reagent pump/sprayer now under RHC_REAGENTS.
#define RHC_SENSORS      "Sensors"
#define RHC_OUTPUT       "Output"
#define RHC_COMMS        "Communications"
#define RHC_NAVIGATION   "Navigation"
#define RHC_INTELLIGENCE "Intelligence"
#define RHC_SUPPORT      "Support"


// ====================================================
// BASE HARDWARE DATUM
// ====================================================

/datum/robot_hardware
	/// Display name shown in workshop picker
	var/hardware_name = "Unknown Hardware"
	/// Short description shown in picker list
	var/hardware_desc = "An unconfigured hardware module."
	/// Long explanation shown when selected - explains what behavior circuits it enables
	var/tutorial_text = "No documentation available."
	/// Hardware category - matches RHC_* defines
	var/category = RHC_SUPPORT
	/// Minimum builder INT required to install this hardware
	var/min_int = RH_INT_BASIC

	// ---- C.O.R.E. costs while installed ----
	var/core_compute    = 0
	var/core_operations = 0
	var/core_resilience = 0
	var/core_energy     = 0

	/// Material cost list: assoc list of material key -> amount
	var/list/mat_cost = list()

	/// Weakref to the robot this hardware is installed on
	var/datum/weakref/robot_ref = null

	/// Config var definitions for workshop UI
	/// Assoc list: var_name -> list("label", "type", default_value)
	/// Types: "number", "text", "bool", "list"
	var/list/config_defs = list()


/// Called by workshop at build time to apply hardware to the robot.
/datum/robot_hardware/proc/install(mob/living/silicon/robot/R)
	robot_ref = WEAKREF(R)
	R.installed_hardware += src

/// Called when hardware is removed from a robot.
/datum/robot_hardware/proc/uninstall(mob/living/silicon/robot/R)
	robot_ref = null
	R.installed_hardware -= src

/// Convenience: resolve the robot this is installed on
/datum/robot_hardware/proc/get_robot()
	return robot_ref?.resolve()

/// Apply SPECIAL bonuses from builder snapshot to this hardware's effective stats.
/// Called at install time. Override in subtypes.
/datum/robot_hardware/proc/apply_special(list/special_snapshot)
	return

/// Get a summary string for the finalize tab
/datum/robot_hardware/proc/get_summary()
	return hardware_name


// ====================================================
// WEAPONS
// ====================================================

// -- ENERGY WEAPON ------------------------------------

/datum/robot_hardware/weapon
	hardware_name    = "Energy Weapon Mount"
	hardware_desc    = "Mounts an energy weapon. The robot can fire it autonomously via behavior circuits."
	tutorial_text    = "Enables: Response: Fire Weapon. Pair with Trigger: On Enemy Spotted for auto-turret behavior. Configure the weapon type and fire mode below. High PER builders get bonus range."
	category         = RHC_WEAPONS
	min_int          = RH_INT_BASIC
	core_operations  = 2
	core_energy      = 2
	mat_cost         = list("iron" = 500, "gold" = 100)

	/// Path of the gun to install - must be /obj/item/gun subtype.
	/// If the robot already has a gun in its module inventory, that gun is used instead.
	var/gun_type = /obj/item/gun/energy/laser
	/// If TRUE fires lethal shots, if FALSE fires stun/disable
	var/lethal_mode = TRUE
	/// Effective fire range in tiles - modified by builder PER at install
	var/fire_range = 7
	/// Weakref to the actual gun item being used (set at install time)
	var/datum/weakref/gun_ref = null

/datum/robot_hardware/weapon/New()
	config_defs = list(
		"gun_type"    = list("Weapon Type",  "list",   /obj/item/gun/energy/laser),
		"lethal_mode" = list("Lethal Mode",  "bool",   TRUE),
		"fire_range"  = list("Fire Range",   "number", 7)
	)

/datum/robot_hardware/weapon/apply_special(list/S)
	// PER above 5 adds 1 tile range per point
	var/per_bonus = max(0, S["PER"] - 5)
	fire_range += per_bonus

/datum/robot_hardware/weapon/install(mob/living/silicon/robot/R)
	// Weapon hardware must adopt an existing gun from the module's basic_modules.
	// Spawning a generic weapon is not allowed - the module must already carry one.
	var/obj/item/gun/G = null
	if(R.module)
		// basic_modules is populated at module Initialize(), before hardware install.
		// modules is populated later by rebuild_modules(). Check basic_modules first.
		for(var/obj/item/gun/candidate in R.module.basic_modules)
			G = candidate
			break
		if(!G)
			for(var/obj/item/gun/candidate in R.module.modules)
				G = candidate
				break
	if(!G)
		log_game("HARDWARE weapon/install: [R] module has no gun in inventory - weapon hardware requires a gun already in the module's loadout. Not installed.")
		return  // do NOT call ..() - hardware is not installed at all
	. = ..()
	gun_ref = WEAKREF(G)
	gun_type = G.type  // sync gun_type so fire_at knows what we're using


/datum/robot_hardware/weapon/get_summary()
	return "[hardware_name] ([gun_type]) [lethal_mode ? "LETHAL" : "STUN"] range:[fire_range]"


// -- GRENADE LAUNCHER ---------------------------------

/datum/robot_hardware/grenade_launcher
	hardware_name    = "Grenade Launcher Mount"
	hardware_desc    = "Loads and primes grenades on command via behavior circuits."
	tutorial_text    = "Enables: Response: Prime Grenade. The robot will prime its loaded grenade when triggered. Configure grenade type and fuse timer. Dangerous - the robot WILL detonate it. Pair with Trigger: On Enemy Spotted."
	category         = RHC_WEAPONS
	min_int          = RH_INT_STANDARD
	core_operations  = 3
	core_energy      = 1
	mat_cost         = list("iron" = 600, "gold" = 150)

	var/grenade_type  = /obj/item/grenade
	/// Fuse time in deciseconds (10 = 1 second)
	var/fuse_time     = 30
	var/grenade_count = 1

/datum/robot_hardware/grenade_launcher/New()
	config_defs = list(
		"grenade_type"  = list("Grenade Type",  "list",   /obj/item/grenade),
		"fuse_time"     = list("Fuse Timer (ds)","number", 30),
		"grenade_count" = list("Grenade Count", "number", 1)
	)

/datum/robot_hardware/grenade_launcher/install(mob/living/silicon/robot/R)
	. = ..()
	for(var/i in 1 to grenade_count)
		var/obj/item/grenade/G = new grenade_type(R)
		G.det_time = fuse_time
		G.icon = 'icons/obj/assemblies/electronic_setups.dmi'
		G.icon_state = "setup_small"
		if(R.module)
			R.module.add_module(G, TRUE, FALSE)
		else
			G.forceMove(R)
	var/loaded = 0
	for(var/obj/item/grenade/existing in R)
		loaded++
	R.visible_message(span_notice("[R]'s grenade launcher is armed with [loaded] grenade(s)."))

/// Allow players to physically insert a grenade into the robot by clicking on it
/datum/robot_hardware/grenade_launcher/proc/accept_grenade(obj/item/grenade/G, mob/user, mob/living/silicon/robot/R)
	if(!G || !R || !user)
		return FALSE
	G.forceMove(R)
	G.det_time = fuse_time
	var/loaded = 0
	for(var/obj/item/grenade/existing in R)
		loaded++
	to_chat(user, span_notice("You load [G] into [R]. [loaded] grenade(s) ready."))
	return TRUE


// -- AIR CANNON ---------------------------------------

/datum/robot_hardware/air_cannon
	hardware_name    = "Pneumatic Cannon"
	hardware_desc    = "Fires compressed air to knock back targets without dealing direct damage."
	tutorial_text    = "Enables: Response: Fire Air Cannon. Non-lethal crowd control. Knocks targets back several tiles. Requires a gas canister to be loaded - configure gas type. Good for security bots that need to suppress without killing."
	category         = RHC_WEAPONS
	min_int          = RH_INT_STANDARD
	core_operations  = 2
	core_energy      = 3
	mat_cost         = list("iron" = 700, "glass" = 200)

	/// Knockback force in tiles
	var/knockback_force = 3
	/// Gas type used as propellant
	var/gas_type        = "o2"
	/// Internal gas volume available
	var/gas_volume      = 50

/datum/robot_hardware/air_cannon/New()
	config_defs = list(
		"knockback_force" = list("Knockback Force", "number", 3),
		"gas_type"        = list("Gas Type",        "list",   "o2"),
		"gas_volume"      = list("Gas Volume",      "number", 50)
	)

/datum/robot_hardware/air_cannon/apply_special(list/S)
	var/str_bonus = max(0, S["STR"] - 5)
	knockback_force += str_bonus


// -- STUN MODULE --------------------------------------

/datum/robot_hardware/stun_module
	hardware_name    = "Electrostatic Stun Module"
	hardware_desc    = "Delivers an electric shock to stun targets on contact or at close range."
	tutorial_text    = "Enables: Response: Stun Target. Stuns the nearest enemy for a configurable duration. Non-lethal. Useful as a secondary weapon or for capture-alive builds. Stun duration scales with builder STR."
	category         = RHC_WEAPONS
	min_int          = RH_INT_BASIC
	core_operations  = 1
	core_energy      = 2
	mat_cost         = list("iron" = 300, "gold" = 50)

	/// Stun duration in deciseconds
	var/stun_duration = 30
	/// Range in tiles (melee = 1)
	var/stun_range    = 1

/datum/robot_hardware/stun_module/New()
	config_defs = list(
		"stun_duration" = list("Stun Duration (ds)", "number", 30),
		"stun_range"    = list("Stun Range",         "number", 1)
	)

/datum/robot_hardware/stun_module/apply_special(list/S)
	var/str_bonus = max(0, S["STR"] - 5)
	stun_duration += str_bonus * 5


// ====================================================
// MANIPULATION
// ====================================================

// -- GRABBER ------------------------------------------

/datum/robot_hardware/grabber
	hardware_name    = "Grabber Arm"
	hardware_desc    = "A mechanical arm that can pick up, store, and drop items."
	tutorial_text    = "Enables: Response: Grab Nearest Item, Response: Drop All Items, Response: Throw Item At Enemy. The robot can collect items from the ground and throw them. Configure max carry weight and item capacity."
	category         = RHC_MANIPULATION
	min_int          = RH_INT_BASIC
	core_operations  = 1
	mat_cost         = list("iron" = 400, "glass" = 100)

	/// Max items the arm can hold at once
	var/max_items     = 5
	/// Max weight class of items it can lift (WEIGHT_CLASS_*)
	var/max_weight    = WEIGHT_CLASS_NORMAL
	/// Items currently held by this arm
	var/list/held_items = list()

/datum/robot_hardware/grabber/New()
	config_defs = list(
		"max_items"  = list("Max Items",    "number", 5),
		"max_weight" = list("Max Weight Class", "number", WEIGHT_CLASS_NORMAL)
	)

/datum/robot_hardware/grabber/apply_special(list/S)
	var/str_bonus = max(0, S["STR"] - 5)
	max_weight = min(max_weight + str_bonus, WEIGHT_CLASS_HUGE)


// -- THROWER ------------------------------------------

/datum/robot_hardware/thrower
	hardware_name    = "Throwing Arm"
	hardware_desc    = "Launches held items at targets with configurable force."
	tutorial_text    = "Enables: Response: Throw Item At Enemy. Requires Grabber Arm hardware to have items to throw. Configure throw force and maximum range. High STR builders improve throw force."
	category         = RHC_MANIPULATION
	min_int          = RH_INT_BASIC
	core_operations  = 1
	mat_cost         = list("iron" = 300)

	var/throw_force   = 5
	var/throw_range   = 7

/datum/robot_hardware/thrower/New()
	config_defs = list(
		"throw_force" = list("Throw Force", "number", 5),
		"throw_range" = list("Throw Range", "number", 7)
	)

/datum/robot_hardware/thrower/apply_special(list/S)
	var/str_bonus = max(0, S["STR"] - 5)
	throw_force += str_bonus
	throw_range += max(0, S["PER"] - 5)


// -- CLAW ---------------------------------------------

/datum/robot_hardware/claw
	hardware_name    = "Pulling Claw"
	hardware_desc    = "A hydraulic claw that can grab and pull mobs or objects."
	tutorial_text    = "Enables: Response: Pull Target. The robot grabs and drags a target. Configure grab strength - higher strength can grab and move larger targets. High STR builder increases max grab force."
	category         = RHC_MANIPULATION
	min_int          = RH_INT_BASIC
	core_operations  = 1
	mat_cost         = list("iron" = 350)

	/// Grab strength: GRAB_PASSIVE, GRAB_AGGRESSIVE, GRAB_NECK
	var/grab_strength = GRAB_PASSIVE

/datum/robot_hardware/claw/New()
	config_defs = list(
		"grab_strength" = list("Grab Strength", "number", GRAB_PASSIVE)
	)

/datum/robot_hardware/claw/apply_special(list/S)
	var/str_bonus = max(0, S["STR"] - 5)
	grab_strength = min(grab_strength + str_bonus, GRAB_NECK)


// -- HARVESTER ----------------------------------------

/datum/robot_hardware/harvester
	hardware_name    = "Harvester Module"
	hardware_desc    = "Allows the robot to tend, harvest, and replant hydroponic trays."
	tutorial_text    = "Enables: Response: Harvest Nearby Plants. The robot will harvest mature plants in range and optionally replant them. Great for Mr. Handy utility builds. Requires Grabber Arm to collect yield."
	category         = RHC_MANIPULATION
	min_int          = RH_INT_BASIC
	core_operations  = 1
	mat_cost         = list("iron" = 200, "glass" = 100)

	var/harvest_range  = 3
	var/auto_replant   = TRUE
	/// world.time of last harvest attempt - prevents per-tick spam across multiple trays
	var/last_harvest   = 0
	var/harvest_cooldown = 30  // 3 seconds between harvest attempts

/datum/robot_hardware/harvester/New()
	config_defs = list(
		"harvest_range" = list("Harvest Range", "number", 3),
		"auto_replant"  = list("Auto Replant",  "bool",   TRUE)
	)

/datum/robot_hardware/harvester/apply_special(list/S)
	harvest_range += max(0, S["PER"] - 5)


// -- MATERIAL COLLECTOR --------------------------------

/datum/robot_hardware/material_collector
	hardware_name    = "Material Collector"
	hardware_desc    = "Automatically scavenges and stores raw materials from the environment."
	tutorial_text    = "Enables: Response: Collect Nearby Items. The robot picks up raw materials (metal, glass, etc.) in range and stores them. Used for scavenger or resource-gathering bot builds. Pairs with Grabber Arm."
	category         = RHC_MANIPULATION
	min_int          = RH_INT_BASIC
	core_operations  = 1
	mat_cost         = list("iron" = 300, "glass" = 100)

	var/collect_range  = 4
	/// List of typepaths the collector will prioritize
	var/list/target_types = list(/obj/item/stack/sheet/metal, /obj/item/stack/sheet/glass)

/datum/robot_hardware/material_collector/New()
	config_defs = list(
		"collect_range" = list("Collection Range", "number", 4)
	)

/datum/robot_hardware/material_collector/apply_special(list/S)
	collect_range += max(0, S["PER"] - 5)


// ====================================================
// REAGENTS
// ====================================================

// -- INJECTOR (BORGHYPO) ------------------------------

/datum/robot_hardware/injector
	hardware_name    = "Reagent Injector"
	hardware_desc    = "Injects or extracts reagents from mobs. The F13 equivalent of a borghypo."
	tutorial_text    = "Enables: Response: Inject Reagent, Response: Offer Drink. Configure the reagent type, dose per injection, and whether to target friendlies or hostiles. A medic bot needs this to heal. A Drink-Bot needs this to serve."
	category         = RHC_REAGENTS
	min_int          = RH_INT_BASIC
	core_operations  = 1
	mat_cost         = list("iron" = 200, "glass" = 150, "gold" = 50)

	/// Reagent path to load
	var/reagent_type   = /datum/reagent/water
	/// Units loaded at build time
	var/reagent_volume = 30
	/// Units injected per activation
	var/dose_per_use   = 5
	/// TRUE = inject, FALSE = extract
	var/inject_mode    = TRUE
	/// TRUE = only targets friendlies
	var/target_friendly = TRUE

/datum/robot_hardware/injector/New()
	config_defs = list(
		"reagent_type"    = list("Reagent Type",     "list",   /datum/reagent/water),
		"reagent_volume"  = list("Volume Loaded",    "number", 30),
		"dose_per_use"    = list("Dose Per Use (u)", "number", 5),
		"inject_mode"     = list("Inject Mode",      "bool",   TRUE),
		"target_friendly" = list("Friendlies Only",  "bool",   TRUE)
	)

/datum/robot_hardware/injector/install(mob/living/silicon/robot/R)
	. = ..()
	// Create the borghypo, fill it, store ref, and add to loadout
	var/obj/item/reagent_containers/borghypo/H = new(R)
	H.reagents.add_reagent(reagent_type, reagent_volume)
	H.icon = 'icons/obj/assemblies/electronic_setups.dmi'
	H.icon_state = "setup_small"
	reagent_tank = H
	if(R.module)
		R.module.add_module(H, TRUE, FALSE)


// -- REAGENT PUMP -------------------------------------

/datum/robot_hardware/reagent_pump
	hardware_name    = "Reagent Pump"
	hardware_desc    = "Moves reagents between internal storage and adjacent containers."
	tutorial_text    = "Enables: Response: Pump Reagents. The robot can transfer liquids to/from adjacent containers. Useful for chemical distribution robots or medical bots that need to refill their injector from a tank."
	category         = RHC_REAGENTS
	min_int          = RH_INT_STANDARD
	core_operations  = 1
	core_energy      = 1
	mat_cost         = list("iron" = 300, "glass" = 200)

	/// Units transferred per pump activation (also aliased as pump_amount for circuits)
	var/transfer_amount = 10
	var/pump_in         = TRUE

/datum/robot_hardware/reagent_pump/New()
	config_defs = list(
		"transfer_amount" = list("Transfer Amount (u)", "number", 10),
		"pump_in"         = list("Pump In (vs Out)",    "bool",   TRUE)
	)


// -- REAGENT TANK -------------------------------------

/datum/robot_hardware/reagent_tank
	hardware_name    = "Internal Reagent Tank"
	hardware_desc    = "An internal reservoir for storing liquids. Feeds the Injector and Reagent Pump."
	tutorial_text    = "Passive hardware. Provides internal liquid storage that other reagent hardware draws from. Configure capacity and initial fill. Without this, the injector has a small built-in reservoir only."
	category         = RHC_REAGENTS
	min_int          = RH_INT_BASIC
	core_resilience  = 1
	mat_cost         = list("iron" = 200, "glass" = 300)

	var/tank_capacity  = 120
	var/reagent_type   = /datum/reagent/water
	var/prefill_volume = 0

/datum/robot_hardware/reagent_tank/New()
	config_defs = list(
		"tank_capacity"  = list("Tank Capacity (u)", "number", 120),
		"reagent_type"   = list("Prefill Reagent",   "list",   /datum/reagent/water),
		"prefill_volume" = list("Prefill Volume (u)","number", 0)
	)

/datum/robot_hardware/reagent_tank/install(mob/living/silicon/robot/R)
	. = ..()
	var/obj/item/reagent_containers/glass/beaker/large/tank = new(R)
	tank.reagents.maximum_volume = tank_capacity
	if(prefill_volume > 0 && reagent_type)
		tank.reagents.add_reagent(reagent_type, min(prefill_volume, tank_capacity))
	if(R.module)
		R.module.add_module(tank, TRUE, FALSE)


// -- GRINDER MODULE -----------------------------------

/datum/robot_hardware/grinder_module
	hardware_name    = "Integrated Grinder"
	hardware_desc    = "Grinds items held by the Grabber Arm into reagents stored in the Reagent Tank."
	tutorial_text    = "Enables: Response: Grind Item. The robot processes grabbed items into their chemical components and stores results in the onboard Reagent Tank. Requires Grabber Arm and Reagent Tank hardware. Good for chemistry support bots."
	category         = RHC_REAGENTS
	min_int          = RH_INT_STANDARD
	core_operations  = 2
	core_energy      = 1
	mat_cost         = list("iron" = 400, "gold" = 100)

	/// If set, overrides the natural grind output with a specific reagent
	var/output_override = null
	var/grind_speed     = 10  // deciseconds per grind

/datum/robot_hardware/grinder_module/New()
	config_defs = list(
		"grind_speed" = list("Grind Speed (ds)", "number", 10)
	)


// ====================================================
// ATMOSPHERICS
// ====================================================

// -- GAS PUMP -----------------------------------------

/datum/robot_hardware/reagent_pump
	hardware_name    = "Reagent Pump"
	hardware_desc    = "Transfers reagents between the robot's internal tank and an adjacent container."
	tutorial_text    = "Enables: Response: Collect Reagents. The robot transfers reagents to or from adjacent reagent containers. Configure direction (0=pull in, 1=push out) and transfer rate. Used for medical supply bots and chem dispensers."
	category         = RHC_REAGENTS
	min_int          = RH_INT_STANDARD
	core_operations  = 1
	core_energy      = 1
	mat_cost         = list("iron" = 300, "glass" = 150)

	/// 0 = pull from container into robot, 1 = push from robot into container
	var/pump_direction = 0
	/// Units to transfer per activation
	var/transfer_rate  = 50

/datum/robot_hardware/reagent_pump/New()
	config_defs = list(
		"pump_direction" = list("Direction (0=pull 1=push)", "number", 0),
		"transfer_rate"  = list("Transfer Rate (u)",        "number", 50)
	)


// -- CHEM SPRAYER -------------------------------------

/datum/robot_hardware/chem_sprayer
	hardware_name    = "Chem Sprayer"
	hardware_desc    = "Sprays a reagent from the robot's internal tank onto a nearby mob."
	tutorial_text    = "Enables: Response: Spray Reagent. The robot sprays a configured reagent from its tank onto a nearby target. Set spray_range and spray_amount. Good for: RadAway dispensers, stimpak sprayers, or chemical deterrents."
	category         = RHC_REAGENTS
	min_int          = RH_INT_STANDARD
	core_operations  = 1
	core_energy      = 1
	mat_cost         = list("iron" = 250, "glass" = 200)

	/// Range in tiles to find a spray target
	var/spray_range  = 2
	/// Amount of reagent to transfer per spray (units)
	var/spray_amount = 10

/datum/robot_hardware/chem_sprayer/New()
	config_defs = list(
		"spray_range"  = list("Spray Range (tiles)", "number", 2),
		"spray_amount" = list("Spray Amount (u)",    "number", 10)
	)

// ====================================================
// SENSORS
// ====================================================

// -- MICROPHONE ---------------------------------------

/datum/robot_hardware/microphone
	hardware_name    = "Microphone Array"
	hardware_desc    = "Listens for speech in the robot's vicinity. Can trigger behaviors on specific phrases."
	tutorial_text    = "Enables: Trigger: On Speech Heard. The robot listens for speech in range. Leave trigger_phrase blank to react to ANY speech. Set a phrase to only react when that exact phrase is heard. Range scales with builder PER."
	category         = RHC_SENSORS
	min_int          = RH_INT_BASIC
	core_compute     = 1
	mat_cost         = list("iron" = 150, "glass" = 100)

	/// If set, only triggers on this exact phrase. Empty = any speech.
	var/trigger_phrase = ""
	var/listen_range   = 7

/datum/robot_hardware/microphone/New()
	config_defs = list(
		"trigger_phrase" = list("Trigger Phrase (blank=any)", "text",   ""),
		"listen_range"   = list("Listen Range",               "number", 7)
	)

/datum/robot_hardware/microphone/apply_special(list/S)
	listen_range += max(0, S["PER"] - 5)

/datum/robot_hardware/microphone/install(mob/living/silicon/robot/R)
	. = ..()
	// Register hearing - robot will route Hear() calls through behavior circuits
	ADD_TRAIT(R, TRAIT_HEARING_HARDWARE, "robot_hardware")


// -- GPS ----------------------------------------------

/datum/robot_hardware/gps
	hardware_name    = "GPS Positioning Unit"
	hardware_desc    = "Provides the robot with its own absolute map coordinates."
	tutorial_text    = "Enables: Trigger: On GPS Zone. The robot knows its own position at all times. Configure a zone trigger (x1,y1 to x2,y2) to fire behaviors when entering or leaving an area. Used for patrol routes and zone defense."
	category         = RHC_SENSORS
	min_int          = RH_INT_BASIC
	core_compute     = 1
	mat_cost         = list("iron" = 100, "gold" = 50)

	/// Zone trigger: x1,y1,x2,y2 - 0 = no zone trigger
	var/zone_x1 = 0
	var/zone_y1 = 0
	var/zone_x2 = 0
	var/zone_y2 = 0
	/// TRUE = trigger on enter, FALSE = trigger on exit
	var/trigger_on_enter = TRUE

/datum/robot_hardware/gps/New()
	config_defs = list(
		"zone_x1"          = list("Zone X1",          "number", 0),
		"zone_y1"          = list("Zone Y1",          "number", 0),
		"zone_x2"          = list("Zone X2",          "number", 0),
		"zone_y2"          = list("Zone Y2",          "number", 0),
		"trigger_on_enter" = list("Trigger On Enter", "bool",   TRUE)
	)


// -- ID CARD READER -----------------------------------

/datum/robot_hardware/id_reader
	hardware_name    = "ID Card Reader"
	hardware_desc    = "Scans ID cards on nearby mobs to check access levels."
	tutorial_text    = "Enables: Trigger: On Access Granted. The robot scans ID cards of mobs in range. Configure the minimum access level required to trigger. Used for access control robots that open doors or sound alarms based on credentials."
	category         = RHC_SENSORS
	min_int          = RH_INT_BASIC
	core_compute     = 1
	mat_cost         = list("iron" = 100, "gold" = 75)

	/// Minimum access level to trigger (ACCESS_* define)
	var/required_access = ACCESS_SECURITY
	var/scan_range      = 1

/datum/robot_hardware/id_reader/New()
	config_defs = list(
		"required_access" = list("Required Access Level", "number", ACCESS_SECURITY),
		"scan_range"      = list("Scan Range",            "number", 1)
	)


// -- HEALTH SCANNER -----------------------------------

/datum/robot_hardware/health_scanner
	hardware_name    = "Health Analyzer"
	hardware_desc    = "Scans nearby mobs for health status and critical conditions."
	tutorial_text    = "Enables: Trigger: Health Scan Critical. The robot monitors nearby mobs' health. Configure the HP threshold that counts as critical and whether to scan friendlies, hostiles, or all. Medic bots need this."
	category         = RHC_SENSORS
	min_int          = RH_INT_BASIC
	core_compute     = 1
	mat_cost         = list("iron" = 150, "gold" = 75)

	var/scan_range        = 5
	/// HP percentage below which a mob is considered critical
	var/critical_threshold = 30
	/// "friendly", "hostile", "all"
	var/scan_target       = "friendly"

/datum/robot_hardware/health_scanner/New()
	config_defs = list(
		"scan_range"         = list("Scan Range",            "number", 5),
		"critical_threshold" = list("Critical HP Threshold %","number", 30),
		"scan_target"        = list("Scan Target",           "list",   "friendly")
	)

/datum/robot_hardware/health_scanner/apply_special(list/S)
	scan_range += max(0, S["PER"] - 5)


// -- ENVIRONMENT SCANNER ------------------------------

/datum/robot_hardware/environment_scanner
	hardware_name    = "Environment Scanner"
	hardware_desc    = "Scans nearby tiles for hazards: fire, radiation, gas, bodies, and items."
	tutorial_text    = "Enables: Trigger: On Radiation Detected, Trigger: On Item Spotted, Trigger: On Body Detected. The robot analyzes its surroundings and triggers behaviors based on environmental conditions. Configure what to scan for and at what threshold."
	category         = RHC_SENSORS
	min_int          = RH_INT_STANDARD
	core_compute     = 2
	mat_cost         = list("iron" = 200, "glass" = 100, "gold" = 50)

	var/scan_radius        = 5
	var/detect_fire        = TRUE
	var/detect_radiation   = TRUE
	var/detect_bodies      = TRUE
	var/detect_items       = FALSE
	/// Radiation threshold in rads/tick to trigger
	var/rad_threshold      = 5

/datum/robot_hardware/environment_scanner/New()
	config_defs = list(
		"scan_radius"      = list("Scan Radius",         "number", 5),
		"detect_fire"      = list("Detect Fire",         "bool",   TRUE),
		"detect_radiation" = list("Detect Radiation",    "bool",   TRUE),
		"detect_bodies"    = list("Detect Bodies",       "bool",   TRUE),
		"detect_items"     = list("Detect Items",        "bool",   FALSE),
		"rad_threshold"    = list("Radiation Threshold", "number", 5)
	)

/datum/robot_hardware/environment_scanner/apply_special(list/S)
	scan_radius += max(0, S["PER"] - 5)


// -- OBJECT LOCATOR -----------------------------------

/datum/robot_hardware/object_locator
	hardware_name    = "Object Locator"
	hardware_desc    = "Searches for specific item types in range and reports their location."
	tutorial_text    = "Enables: Trigger: On Item Spotted (specific type). More precise than the Environment Scanner - configure the exact item type to hunt for. The robot will pathfind toward it when found. Used for scavenger bots."
	category         = RHC_SENSORS
	min_int          = RH_INT_STANDARD
	core_compute     = 1
	mat_cost         = list("iron" = 150, "gold" = 75)

	/// Typepath of target item to locate
	var/target_type   = /obj/item
	var/search_radius = 10

/datum/robot_hardware/object_locator/New()
	config_defs = list(
		"target_type"   = list("Target Item Type", "list",   /obj/item),
		"search_radius" = list("Search Radius",    "number", 10)
	)

/datum/robot_hardware/object_locator/apply_special(list/S)
	search_radius += max(0, S["PER"] - 5)


// -- BIO SCANNER --------------------------------------

/datum/robot_hardware/bio_scanner
	hardware_name    = "Biological Scanner"
	hardware_desc    = "Scans living mobs for species, mutation flags, faction, and health state."
	tutorial_text    = "Enables: Trigger: On Mutant Detected, Response: Broadcast Bio Report. The robot analyzes biological signatures of nearby mobs. Useful for field research robots, bounty hunters, or medical units that need to distinguish mob types."
	category         = RHC_SENSORS
	min_int          = RH_INT_ADVANCED
	core_compute     = 2
	mat_cost         = list("iron" = 250, "gold" = 150)

	var/scan_radius      = 7
	/// TRUE = broadcast scan results over radio
	var/broadcast_results = FALSE
	/// Specific species/type to flag - empty = flag any non-human
	var/target_species   = ""

/datum/robot_hardware/bio_scanner/New()
	config_defs = list(
		"scan_radius"       = list("Scan Radius",         "number", 7),
		"broadcast_results" = list("Broadcast Results",   "bool",   FALSE),
		"target_species"    = list("Target Species (blank=any)", "text", "")
	)

/datum/robot_hardware/bio_scanner/apply_special(list/S)
	scan_radius += max(0, S["PER"] - 5)


// ====================================================
// OUTPUT
// ====================================================

// -- LIGHT --------------------------------------------

/datum/robot_hardware/light
	hardware_name    = "Light Module"
	hardware_desc    = "A controllable light source mounted on the robot chassis."
	tutorial_text    = "Enables: Response: Toggle Light. The robot can turn its light on/off via behavior circuits. Configure brightness and color. Useful for night-cycle automation or stealth builds that go dark."
	category         = RHC_OUTPUT
	min_int          = RH_INT_BASIC
	core_energy      = 1
	mat_cost         = list("iron" = 100, "glass" = 50)

	var/light_brightness = 3
	var/light_color      = "#FFFFFF"
	var/start_on         = TRUE

/datum/robot_hardware/light/New()
	config_defs = list(
		"light_brightness" = list("Brightness (1-10)", "number", 3),
		"light_color"      = list("Color (hex)",       "text",   "#FFFFFF"),
		"start_on"         = list("Start On",          "bool",   TRUE)
	)

/datum/robot_hardware/light/install(mob/living/silicon/robot/R)
	. = ..()
	if(start_on)
		R.set_light_range(light_brightness)
		R.set_light_on(TRUE)


// -- DISPLAY SCREEN -----------------------------------

/datum/robot_hardware/display_screen
	hardware_name    = "Display Screen"
	hardware_desc    = "A small screen that displays text messages to nearby mobs."
	tutorial_text    = "Enables: Response: Display Screen Message. The robot shows configurable text on its screen. The message can be set at build time (static) or updated by behavior circuits at runtime. Good for vendor bots or alert bots."
	category         = RHC_OUTPUT
	min_int          = RH_INT_BASIC
	core_compute     = 1
	mat_cost         = list("iron" = 100, "glass" = 150)

	var/default_message = "UNIT OPERATIONAL"
	/// Broadcast range - 0 = examine only, >0 = visible message
	var/broadcast_range = 0

/datum/robot_hardware/display_screen/New()
	config_defs = list(
		"default_message" = list("Default Message",  "text",   "UNIT OPERATIONAL"),
		"broadcast_range" = list("Broadcast Range",  "number", 0)
	)


// -- SPEAKER ------------------------------------------

/datum/robot_hardware/speaker
	hardware_name    = "Speaker System"
	hardware_desc    = "Plays sounds or synthesized speech on command."
	tutorial_text    = "Enables: Response: Play Sound. Configure a sound file path or use text-to-speech mode. The robot broadcasts audio at configurable volume and range. Useful for alert robots, vendor bots, or flavor builds."
	category         = RHC_OUTPUT
	min_int          = RH_INT_BASIC
	core_energy      = 1
	mat_cost         = list("iron" = 100, "glass" = 50)

	var/sound_file   = 'sound/machines/ding.ogg'
	var/volume       = 50
	var/sound_range  = 5
	/// TRUE = use text-to-speech via robot say, FALSE = play sound file
	var/tts_mode     = FALSE
	var/tts_text     = "Attention."

/datum/robot_hardware/speaker/New()
	config_defs = list(
		"sound_file"  = list("Sound File",   "text",   "sound/machines/ding.ogg"),
		"volume"      = list("Volume",       "number", 50),
		"sound_range" = list("Sound Range",  "number", 5),
		"tts_mode"    = list("TTS Mode",     "bool",   FALSE),
		"tts_text"    = list("TTS Text",     "text",   "Attention.")
	)

/datum/robot_hardware/speaker/install(mob/living/silicon/robot/R)
	. = ..()
	// Stored for behavior circuits to read and trigger playsound
	R.speaker_hardware = src


// ====================================================
// COMMUNICATIONS
// ====================================================

// -- SIGNALER -----------------------------------------

/datum/robot_hardware/signaler
	hardware_name    = "Integrated Signaler"
	hardware_desc    = "Sends and receives radio signals on a configurable frequency."
	tutorial_text    = "Enables: Trigger: On Signal Received, Response: Send Radio Signal. The robot can communicate via radio signaler frequencies. Set the frequency and code. Use matching code on a handheld signaler to trigger the robot remotely."
	category         = RHC_COMMS
	min_int          = RH_INT_BASIC
	core_compute     = 1
	core_energy      = 1
	mat_cost         = list("iron" = 150, "gold" = 75)

	var/frequency = FREQ_SIGNALER
	var/code      = DEFAULT_SIGNALER_CODE

/datum/robot_hardware/signaler/New()
	config_defs = list(
		"frequency" = list("Frequency", "number", FREQ_SIGNALER),
		"code"      = list("Code",      "number", DEFAULT_SIGNALER_CODE)
	)

/datum/robot_hardware/signaler/install(mob/living/silicon/robot/R)
	. = ..()
	// Register on radio system
	var/datum/radio_frequency/RF = SSradio.add_object(R, frequency, RADIO_SIGNALER)
	R.signaler_connection = RF
	R.signaler_frequency  = frequency
	R.signaler_code       = code

/datum/robot_hardware/signaler/uninstall(mob/living/silicon/robot/R)
	. = ..()
	if(R.signaler_connection)
		SSradio.remove_object(R, frequency)
	R.signaler_connection = null



// ====================================================
// NAVIGATION
// ====================================================

// -- LOCOMOTION ---------------------------------------

/datum/robot_hardware/locomotion
	hardware_name    = "Locomotion Controller"
	hardware_desc    = "Fine-tunes the robot's movement parameters: speed, sprint, and patrol mode."
	tutorial_text    = "Passive hardware. Improves movement. Configure move speed modifier, whether the robot can sprint, and patrol behavior (random wander vs. waypoint follow). High AGI builders reduce movement delay further."
	category         = RHC_NAVIGATION
	min_int          = RH_INT_BASIC
	core_operations  = 1
	core_energy      = 1
	mat_cost         = list("iron" = 200)

	/// Move delay modifier - negative = faster
	var/speed_modifier   = 0
	var/can_sprint       = FALSE
	/// "none", "random", "waypoint"
	var/patrol_mode      = "none"

/datum/robot_hardware/locomotion/New()
	config_defs = list(
		"speed_modifier" = list("Speed Modifier",  "number", 0),
		"can_sprint"     = list("Can Sprint",       "bool",   FALSE),
		"patrol_mode"    = list("Patrol Mode",      "list",   "none")
	)

/datum/robot_hardware/locomotion/apply_special(list/S)
	var/agi_bonus = max(0, S["AGI"] - 5)
	speed_modifier -= agi_bonus * 0.1

/datum/robot_hardware/locomotion/install(mob/living/silicon/robot/R)
	. = ..()
	R.speed += speed_modifier
	if(can_sprint)
		R.cansprint = TRUE
	// Hook up random wander if configured. patrol_mode "random" makes the robot
	// step_rand() on each SSobj process tick when no combat is active.
	// "waypoint" mode is handled by the on_interval + patrol_waypoints assembly circuit.
	if(patrol_mode == "random")
		START_PROCESSING(SSobj, src)

/datum/robot_hardware/locomotion/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD || R.anchored)
		// Robot is dead, gone, or stuck -- stop wander processing
		STOP_PROCESSING(SSobj, src)
		return
	// Don't wander if robot is being player-controlled
	if(R.client)
		return
	// Don't wander if a behavior assembly has switched to combat mode
	if(R.a_intent == INTENT_HARM)
		return
	step_rand(R)


// -- NAV COMPUTER -------------------------------------

/datum/robot_hardware/nav_computer
	hardware_name    = "Navigation Computer"
	hardware_desc    = "Stores up to 5 waypoints. The robot can patrol between them in sequence."
	tutorial_text    = "Enables patrol routes. Store coordinate pairs (x,y) as waypoints. Pair with Locomotion Controller in waypoint mode to make the robot follow a defined route. High INT builder gets more waypoint slots."
	category         = RHC_NAVIGATION
	min_int          = RH_INT_ADVANCED
	core_compute     = 2
	mat_cost         = list("iron" = 300, "gold" = 150)

	/// List of waypoints: each entry is list(x, y)
	var/list/waypoints    = list()
	var/max_waypoints     = 5
	/// TRUE = loop back to start, FALSE = reverse direction
	var/loop_route        = TRUE
	var/current_waypoint  = 1

/datum/robot_hardware/nav_computer/New()
	config_defs = list(
		"loop_route"    = list("Loop Route",     "bool",   TRUE),
		"max_waypoints" = list("Max Waypoints",  "number", 5)
	)

/datum/robot_hardware/nav_computer/apply_special(list/S)
	var/int_bonus = max(0, S["INT"] - 7)
	max_waypoints = min(max_waypoints + int_bonus, 10)


// ====================================================
// INTELLIGENCE
// ====================================================

// -- LOGIC CORE ---------------------------------------

/datum/robot_hardware/logic_core
	hardware_name    = "Logic Core"
	hardware_desc    = "Adds conditional logic to behavior circuits. Up to 4 configurable conditions gate when responses fire."
	tutorial_text    = "Advanced hardware. Define up to 4 conditions (e.g. health < 30, enemy_count > 2). Behavior circuits check these conditions before executing. Without conditions set they always pass. High INT builder unlocks more condition slots."
	category         = RHC_INTELLIGENCE
	min_int          = RH_INT_STANDARD
	core_compute     = 3
	mat_cost         = list("iron" = 300, "gold" = 200)

	/// Each condition: list(left_var, operator, right_value)
	/// Operators: "<", ">", "==", "!=", ">=", "<="
	var/list/conditions   = list()
	var/max_conditions    = 4
	/// "AND" or "OR" - how multiple conditions combine
	var/condition_mode    = "AND"

/datum/robot_hardware/logic_core/New()
	config_defs = list(
		"condition_mode" = list("Condition Mode (AND/OR)", "list", "AND"),
		"max_conditions" = list("Max Conditions",          "number", 4)
	)

/datum/robot_hardware/logic_core/apply_special(list/S)
	var/int_bonus = max(0, S["INT"] - 7)
	max_conditions = min(max_conditions + int_bonus, 8)

/// Evaluate all conditions against a robot's current state.
/// Returns TRUE if conditions pass, FALSE if blocked.
/datum/robot_hardware/logic_core/proc/evaluate(mob/living/silicon/robot/R)
	if(!conditions.len)
		return TRUE
	var/list/results = list()
	for(var/list/cond in conditions)
		if(cond.len < 3)
			continue
		var/left_var  = cond[1]
		var/operator  = cond[2]
		var/right_val = cond[3]
		var/left_val  = _read_robot_var(R, left_var)
		results += _compare(left_val, operator, right_val)
	if(!results.len)
		return TRUE
	if(condition_mode == "AND")
		for(var/r in results)
			if(!r) return FALSE
		return TRUE
	else  // OR
		for(var/r in results)
			if(r) return TRUE
		return FALSE

/datum/robot_hardware/logic_core/proc/_read_robot_var(mob/living/silicon/robot/R, varname)
	switch(varname)
		if("health")         return R.health
		if("max_health")     return R.maxHealth
		if("health_pct")     return (R.health / max(R.maxHealth, 1)) * 100
		if("enemy_count")
			var/count = 0
			for(var/mob/living/M in range(10, R))
				if(!_is_faction_friend(R, M))
					count++
			return count
		if("world_time")     return world.time
	return 0

/datum/robot_hardware/logic_core/proc/_compare(left, operator, right)
	switch(operator)
		if("<")  return left < right
		if(">")  return left > right
		if("==") return left == right
		if("!=") return left != right
		if(">=") return left >= right
		if("<=") return left <= right
	return FALSE


// -- MEMORY CORE --------------------------------------

/datum/robot_hardware/memory_core
	hardware_name    = "Memory Core"
	hardware_desc    = "Persistent key-value storage. Behavior circuits can read and write named variables that survive across ticks."
	tutorial_text    = "Advanced hardware. Provides named persistent variables for circuit_board nodes and advanced behavior logic. Without this, robots reset all state each tick. Configure number of slots (1-16). High INT builder unlocks more slots."
	category         = RHC_INTELLIGENCE
	min_int          = RH_INT_ADVANCED
	core_compute     = 2
	mat_cost         = list("iron" = 200, "gold" = 150)

	var/max_slots = 8
	/// Runtime storage - populated at play time not build time
	var/list/memory = list()

/datum/robot_hardware/memory_core/New()
	config_defs = list(
		"max_slots" = list("Memory Slots (1-16)", "number", 8)
	)

/datum/robot_hardware/memory_core/apply_special(list/S)
	var/int_bonus = max(0, S["INT"] - 7)
	max_slots = min(max_slots + int_bonus * 2, 16)

/datum/robot_hardware/memory_core/proc/read(key)
	return memory[key]

/datum/robot_hardware/memory_core/proc/write(key, value)
	if(memory.len >= max_slots && !(key in memory))
		return FALSE  // out of space
	memory[key] = value
	return TRUE

/datum/robot_hardware/memory_core/proc/clear(key)
	memory.Remove(key)


// -- CLOCK --------------------------------------------

/datum/robot_hardware/clock
	hardware_name    = "Interval Clock"
	hardware_desc    = "Provides a configurable tick counter and interval timer for behavior circuits."
	tutorial_text    = "Enables: Trigger: On Clock Tick. The clock fires a trigger pulse at a set interval. Configure the interval in deciseconds. Useful for timed behaviors that need to fire on a schedule independent of external events."
	category         = RHC_INTELLIGENCE
	min_int          = RH_INT_STANDARD
	core_compute     = 1
	core_energy      = 1
	mat_cost         = list("iron" = 150, "gold" = 100)

	/// Interval between ticks in deciseconds
	var/tick_interval = 40
	var/reset_on_trigger = FALSE
	var/next_tick    = 0
	var/is_running   = FALSE

/datum/robot_hardware/clock/New()
	config_defs = list(
		"tick_interval"    = list("Tick Interval (ds)",  "number", 40),
		"reset_on_trigger" = list("Reset On Trigger",    "bool",   FALSE)
	)

/datum/robot_hardware/clock/install(mob/living/silicon/robot/R)
	. = ..()
	is_running = TRUE
	next_tick = world.time + tick_interval
	START_PROCESSING(SSfastprocess, src)

/datum/robot_hardware/clock/uninstall(mob/living/silicon/robot/R)
	. = ..()
	is_running = FALSE
	STOP_PROCESSING(SSfastprocess, src)

/datum/robot_hardware/clock/process()
	if(!is_running)
		return
	if(world.time < next_tick)
		return
	next_tick = world.time + tick_interval
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		return
	// Signal clock tick to all registered behavior circuits
	SEND_SIGNAL(R, COMSIG_ROBOT_CLOCK_TICK, src)


// -- VOCABULARY MODULE --------------------------------

/datum/robot_hardware/vocabulary_module
	hardware_name    = "Vocabulary Module"
	hardware_desc    = "Stores up to 8 custom phrases the robot can say via behavior circuits."
	tutorial_text    = "Enables indexed speech. Stores named phrases (e.g. greeting, warning, alert). Behavior circuits reference phrase slots by index. Without this, robots can only say hardcoded text. High CHA builder unlocks more phrase slots."
	category         = RHC_INTELLIGENCE
	min_int          = RH_INT_BASIC
	core_compute     = 1
	mat_cost         = list("iron" = 100, "glass" = 50)

	/// Assoc list: slot_name -> phrase text
	var/list/phrases = list(
		"greeting" = "Unit online.",
		"warning"  = "Halt. Identify yourself.",
		"alert"    = "Hostile detected.",
		"help"     = "Assistance required.",
		"idle"     = "All clear."
	)
	var/max_phrases = 8

/datum/robot_hardware/vocabulary_module/New()
	config_defs = list(
		"max_phrases"       = list("Max Phrases", "number", 8),
		"phrase_greeting"   = list("Greeting Phrase",  "text", "Unit online."),
		"phrase_warning"    = list("Warning Phrase",   "text", "Halt. Identify yourself."),
		"phrase_alert"      = list("Alert Phrase",     "text", "Hostile detected."),
		"phrase_help"       = list("Help Phrase",      "text", "Assistance required."),
		"phrase_idle"       = list("Idle Phrase",      "text", "All clear.")
	)

/datum/robot_hardware/vocabulary_module/apply_special(list/S)
	var/cha_bonus = max(0, S["CHA"] - 5)
	max_phrases = min(max_phrases + cha_bonus, 16)

/datum/robot_hardware/vocabulary_module/install(mob/living/silicon/robot/R)
	. = ..(R)
	// Map phrase_* config_defs into the phrases assoc list at install time.
	// config_defs stores "phrase_greeting" = "text", but the runtime var is phrases["greeting"].
	for(var/key in config_defs)
		if(copytext(key, 1, 8) != "phrase_")  // skip non-phrase keys like max_phrases
			continue
		var/slot = copytext(key, 8)  // strip "phrase_" prefix -> "greeting", "warning" etc
		var/list/def = config_defs[key]
		var/val = def.len >= 3 ? def[3] : ""
		if(slot && val)
			phrases[slot] = val

/datum/robot_hardware/vocabulary_module/proc/say_phrase(mob/living/silicon/robot/R, key)
	if(!(key in phrases))
		return
	R.say(phrases[key])


// ====================================================
// SUPPORT
// ====================================================

// -- POWER RELAY --------------------------------------

/datum/robot_hardware/power_relay
	hardware_name    = "Power Relay"
	hardware_desc    = "Wirelessly charges nearby robots or machines by sharing the robot's power cell."
	tutorial_text    = "Enables: Response: Relay Power. The robot can beam power to nearby machines or other robots. Configure transfer rate and range. Drains the robot's own power cell. Useful for support builds in long operations."
	category         = RHC_SUPPORT
	min_int          = RH_INT_STANDARD
	core_energy      = 3
	mat_cost         = list("iron" = 300, "gold" = 200)

	/// Power transferred per activation in watts
	var/transfer_rate = 500
	var/relay_range   = 3

/datum/robot_hardware/power_relay/New()
	config_defs = list(
		"transfer_rate" = list("Transfer Rate (W)", "number", 500),
		"relay_range"   = list("Relay Range",       "number", 3)
	)

/datum/robot_hardware/power_relay/apply_special(list/S)
	relay_range += max(0, S["PER"] - 5)


// ====================================================
// CIRCUIT BOARD (ADVANCED TIER)
// The circuit_board hardware slot hosts a full
// F13-native node graph editor for players who want
// deep automation beyond standard hardware configs.
// Replaces the SS13 electronic_assembly system.
// Nodes are datum/circuit_node instances - see
// circuit_node.dm for the full node type library.
// ====================================================

/datum/robot_hardware/circuit_board
	hardware_name    = "Advanced Circuit Board"
	hardware_desc    = "A programmable node-graph processor. Hosts datum/circuit_node chains for complex conditional automation."
	tutorial_text    = "MASTER TIER - requires INT 9+. Opens the circuit editor where you can chain computation nodes: math, logic, memory, timers, converters, text, routers, and list processors. Outputs wire into behavior circuits as dynamic inputs. This replaces the SS13 IC wiring system entirely."
	category         = RHC_INTELLIGENCE
	min_int          = RH_INT_MASTER
	core_compute     = 5
	core_energy      = 2
	mat_cost         = list("iron" = 500, "gold" = 400, "silver" = 200)

	/// The node graph for this board
	var/list/datum/circuit_node/nodes = list()
	/// Connections: list of list(from_node_ref, output_name, to_node_ref, input_name)
	var/list/connections = list()
	/// Max nodes allowed on this board
	var/max_nodes = 16

/datum/robot_hardware/circuit_board/New()
	config_defs = list(
		"max_nodes" = list("Max Nodes", "number", 16)
	)

/datum/robot_hardware/circuit_board/apply_special(list/S)
	var/int_bonus = max(0, S["INT"] - 9)
	max_nodes = min(max_nodes + int_bonus * 4, 48)

/datum/robot_hardware/circuit_board/Destroy()
	QDEL_LIST(nodes)
	connections.Cut()
	return ..()

/// Add a node to the board. Returns the node or null if full.
/datum/robot_hardware/circuit_board/proc/add_node(node_type)
	if(nodes.len >= max_nodes)
		return null
	var/datum/circuit_node/N = new node_type()
	N.board_ref = WEAKREF(src)
	nodes += N
	return N

/// Remove a node and clean up its connections.
/datum/robot_hardware/circuit_board/proc/remove_node(datum/circuit_node/N)
	nodes -= N
	// Remove all connections involving this node
	var/list/to_remove = list()
	for(var/list/conn in connections)
		var/datum/weakref/c1 = conn[1]
		var/datum/weakref/c3 = conn[3]
		if(c1 == WEAKREF(N) || c3 == WEAKREF(N))
			to_remove += conn
	for(var/conn in to_remove)
		connections -= conn
	qdel(N)

/// Wire an output of one node to an input of another.
/datum/robot_hardware/circuit_board/proc/connect(datum/circuit_node/from_node, output_name, datum/circuit_node/to_node, input_name)
	if(!(from_node in nodes) || !(to_node in nodes))
		return FALSE
	if(!(output_name in from_node.outputs))
		return FALSE
	if(!(input_name in to_node.inputs))
		return FALSE
	connections += list(list(WEAKREF(from_node), output_name, WEAKREF(to_node), input_name))
	return TRUE

/// Evaluate the entire node graph, propagating values through connections.
/// Called by behavior circuits that reference this board's outputs.
/datum/robot_hardware/circuit_board/proc/evaluate()
	// Topological evaluation - nodes with no inputs first
	var/list/evaluated = list()
	var/list/queue = list()
	// Seed with source nodes (no inputs wired)
	for(var/datum/circuit_node/N in nodes)
		var/has_input = FALSE
		for(var/list/conn in connections)
			var/datum/weakref/tgt_ref = conn[3]
			var/datum/circuit_node/target = tgt_ref?.resolve()
			if(target == N)
				has_input = TRUE
				break
		if(!has_input)
			queue += N
	// Evaluate in order
	while(queue.len)
		var/datum/circuit_node/N = queue[1]
		queue.Cut(1, 2)
		if(N in evaluated)
			continue
		N.evaluate()
		evaluated += N
		// Propagate outputs to connected inputs
		for(var/list/conn in connections)
			var/datum/weakref/from_ref = conn[1]
			var/datum/circuit_node/from_node = from_ref?.resolve()
			if(from_node != N)
				continue
			var/output_name = conn[2]
			var/datum/weakref/to_ref = conn[3]
			var/datum/circuit_node/to_node = to_ref?.resolve()
			var/input_name  = conn[4]
			if(to_node && (output_name in N.outputs))
				to_node.inputs[input_name] = N.outputs[output_name]
				if(!(to_node in queue) && !(to_node in evaluated))
					queue += to_node

/// Get the current output value of a named output on a named node.
/datum/robot_hardware/circuit_board/proc/get_output(node_name, output_name)
	for(var/datum/circuit_node/N in nodes)
		if(N.node_name == node_name)
			return N.outputs[output_name]
	return null
