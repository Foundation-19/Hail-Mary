// ====================================================
// ROBOT WORKSHOP
// A tiered assembly machine for building robot mobs
// from chassis parts + module + optional behavior
// assembly + hardware ICs.
//
// Tier unlocked by installing Workshop Cert Cards.
// Robot Whisperer trait required to operate.
//
// Tabs: HOME | BUILD | HARDWARE | PROGRAMS | FINALIZE
//
// File: code/modules/research/robot_workshop.dm
// ====================================================


// ====================================================
// HARDWARE SLOT DEFINES
// HW_SLOT_* defines are declared in behavior_circuits.dm
// and are available here since DM defines are compile-global.
// See behavior_circuits.dm for the full list.
// ====================================================


// ====================================================
// WORKSHOP TIER DEFINES
// ====================================================

#define WORKSHOP_TIER_NONE      0
#define WORKSHOP_TIER_UTILITY   1   // Mr. Handy, Liberator
#define WORKSHOP_TIER_SECURITY  2   // Protectron, Gutsy, Securitron
#define WORKSHOP_TIER_COMBAT    3   // Assaultron
#define WORKSHOP_TIER_APEX      4   // Sentry Bot


// ====================================================
// WORKSHOP UI MODE DEFINES
// ====================================================

#define RW_HOME      1
#define RW_BUILD     2
#define RW_HARDWARE  3
#define RW_PROGRAMS  4
#define RW_FINALIZE  5


// ====================================================
// MATERIAL COSTS
// ====================================================

// Base material costs for each tier of robot
// Format: list(iron, glass, gold, silver)
// These represent the workshop fabrication cost on top of the chassis
#define RW_COST_TIER1  list("iron" = 2000,  "glass" = 500,  "gold" = 0,    "silver" = 0)
#define RW_COST_TIER2  list("iron" = 4000,  "glass" = 1000, "gold" = 200,  "silver" = 0)
#define RW_COST_TIER3  list("iron" = 8000,  "glass" = 2000, "gold" = 500,  "silver" = 200)
#define RW_COST_TIER4  list("iron" = 15000, "glass" = 4000, "gold" = 1000, "silver" = 500)


// ====================================================
// ROBOT BUILD DESIGNS
// Each entry defines one buildable robot type.
// ====================================================

// ROBOT_ROLE_* defines are in _behavior_defines.dm


/datum/robot_build_design
	var/design_name = "Unknown"
	var/design_desc = "No description."
	var/module_type = /obj/item/robot_module
	var/mob_type    = /mob/living/silicon/robot
	var/tier        = WORKSHOP_TIER_NONE
	var/list/mat_cost = list()
	/// Icon state to show in the UI preview (uses robots.dmi)
	var/preview_icon = "robot"
	/// borghealth value - shown as stat in UI
	var/display_health = 100
	/// Short role/warning tags shown inline in the Build tab.
	/// Each entry is a list(label, css_class) — class is one of: "dim", "warn", "good", "bad", "stat"
	var/list/design_tags = list()
	/// If TRUE, the Build tab shows a "★ Recommended first build" callout.
	var/design_starter = FALSE
	/// If TRUE, the Build tab shows an assembly warning before the player can finalize.
	var/design_needs_assembly = FALSE
	/// One-line cert guidance shown under the chassis in the Build tab.
	var/cert_hint = ""
	/// Bitfield of ROBOT_ROLE_* tags.  The selected module_type must share at least
	/// one tag with this chassis or the build is blocked at Finalize.
	var/chassis_tags = ROBOT_ROLE_ANY


// ============================================================
// CHASSIS DEFINITIONS
// ============================================================
// Tags use list(label, css_class).  Classes: dim | warn | good | bad | stat
// Keep labels short — they render inline next to the chassis name.
// ============================================================

/datum/robot_build_design/handy
	design_name        = "Mr. Handy"
	design_desc        = "Pre-war household assistant rebuilt for the wasteland. Harvests, hauls, patches wounds, and serves water — all without complaining. The friendliest thing you'll build at this bench."
	module_type        = /obj/item/robot_module/handy
	tier               = WORKSHOP_TIER_UTILITY
	mat_cost           = RW_COST_TIER1
	preview_icon       = "handy"
	display_health     = 200
	design_starter     = TRUE
	design_tags        = list(
		list("SUPPORT",  "good"),
		list("STARTER",  "good")
	)
	cert_hint          = "Default cert: Standard. Swap to Medical cert for Medbot or Field Surgeon behaviors."
	chassis_tags       = ROBOT_ROLE_SUPPORT

/datum/robot_build_design/liberator
	design_name        = "Liberator"
	design_desc        = "Cheap, fast combat drone with a short lifespan. It will close ground and shoot things before most robots react. It will also die to anything that shoots back. Wire an assembly or it wanders aimlessly — and fragile things that wander get shot."
	module_type        = /obj/item/robot_module/liberator
	tier               = WORKSHOP_TIER_UTILITY
	mat_cost           = RW_COST_TIER1
	preview_icon       = "liberator"
	display_health     = 200
	design_needs_assembly = TRUE
	design_tags        = list(
		list("COMBAT",   "warn"),
		list("FRAGILE",  "bad")
	)
	cert_hint          = "Default cert: Standard. Combat cert gives +2 Operations and +2 Resilience — worth it here."
	chassis_tags       = ROBOT_ROLE_COMBAT

/datum/robot_build_design/protectron
	design_name        = "Protectron"
	design_desc        = "Slow, durable law enforcement unit with a built-in stun module. Won't win a footrace, but it absorbs punishment and drops enemies with electrical stuns. Good second build — more forgiving than it looks."
	module_type        = /obj/item/robot_module/protectron
	tier               = WORKSHOP_TIER_SECURITY
	mat_cost           = RW_COST_TIER2
	preview_icon       = "protectron"
	display_health     = 250
	design_tags        = list(
		list("SECURITY", "stat"),
		list("TANKY",    "good")
	)
	cert_hint          = "Default cert: Standard. Combat cert unlocks combat behaviors and adds speed — the intended pairing."
	chassis_tags       = ROBOT_ROLE_SECURITY

/datum/robot_build_design/gutsy
	design_name        = "Mr. Gutsy"
	design_desc        = "Military-grade service unit with a short temper and a laser arm. Heavier armor than a Protectron, higher aggression ceiling. Fully customizable voice lines — it ships with opinions already installed."
	module_type        = /obj/item/robot_module/gutsy
	tier               = WORKSHOP_TIER_SECURITY
	mat_cost           = RW_COST_TIER2
	preview_icon       = "gutsy"
	display_health     = 300
	design_tags        = list(
		list("SECURITY",   "stat"),
		list("AGGRESSIVE", "warn")
	)
	cert_hint          = "Default cert: Standard. Combat cert is the right call — unlocks combat behaviors and bumps resilience."
	chassis_tags       = ROBOT_ROLE_SECURITY

/datum/robot_build_design/securitron
	design_name        = "Securitron"
	design_desc        = "Heavy platform with a wall of HP and an air cannon that throws enemies across the room. Slower than everything else at this tier — but it doesn't need to be fast. Two of these guarding a position are almost impossible to dislodge."
	module_type        = /obj/item/robot_module/securitron
	tier               = WORKSHOP_TIER_SECURITY
	mat_cost           = RW_COST_TIER3
	preview_icon       = "securitron"
	display_health     = 500
	design_tags        = list(
		list("SECURITY", "stat"),
		list("HEAVY",    "good"),
		list("SLOW",     "warn")
	)
	cert_hint          = "Default cert: Standard. Combat cert recommended — this chassis is built to fight, give it the right cert."
	chassis_tags       = ROBOT_ROLE_SECURITY

/datum/robot_build_design/assaultron
	design_name        = "Assaultron"
	design_desc        = "The fastest chassis in the workshop. Closes distance in seconds, devastating at melee range. Without a behavior assembly it is a danger to everyone nearby, including you. Do not finalize without one."
	module_type        = /obj/item/robot_module/assaultron
	tier               = WORKSHOP_TIER_COMBAT
	mat_cost           = RW_COST_TIER3
	preview_icon       = "assaultron"
	display_health     = 450
	design_needs_assembly = TRUE
	design_tags        = list(
		list("COMBAT",          "warn"),
		list("FAST",            "good"),
		list("NEEDS ASSEMBLY",  "bad")
	)
	cert_hint          = "Needs Combat cert. Combat cert unlocks the aggressive behaviors this chassis was built to run."
	chassis_tags       = ROBOT_ROLE_COMBAT

/datum/robot_build_design/assaultron_medical
	design_name        = "Medical Assaultron"
	design_desc        = "An Assaultron chassis rebuilt for front-line trauma medicine. Full surgical suite, stabilizer injector, and a punchdagger for when the patients aren't the only problem. Fast enough to reach casualties before heavier units. Wire field medicine behaviors or it is just an expensive stretcher."
	module_type        = /obj/item/robot_module/assaultron/medical
	tier               = WORKSHOP_TIER_COMBAT
	mat_cost           = RW_COST_TIER3
	preview_icon       = "assaultron_sase"
	display_health     = 450
	design_needs_assembly = TRUE
	design_tags        = list(
		list("COMBAT",          "warn"),
		list("MEDICAL",         "good"),
		list("NEEDS ASSEMBLY",  "bad")
	)
	cert_hint          = "Combat cert for combat behaviors. Medical cert unlocks field surgery and stabilization protocols — the actual reason to build this over the standard Assaultron."
	chassis_tags       = ROBOT_ROLE_COMBAT

/datum/robot_build_design/sentrybot
	design_name        = "Sentry Bot"
	design_desc        = "The apex chassis. Grenade launcher, heavy laser, air cannon, HP that shrugs off most small-arms fire. The T4 cert that unlocks this does not come from the fabricator — you find it in the world. When you have it, you'll know it was worth it."
	module_type        = /obj/item/robot_module/sentrybot
	tier               = WORKSHOP_TIER_APEX
	mat_cost           = RW_COST_TIER4
	preview_icon       = "sentrybot"
	display_health     = 600
	design_tags        = list(
		list("APEX",        "bad"),
		list("WORLD CERT",  "warn")
	)
	cert_hint          = "Needs Combat cert (T2). The T4 workshop cert to build this doesn't come from the fabricator — find it in the world."
	chassis_tags       = ROBOT_ROLE_COMBAT | ROBOT_ROLE_APEX


// ============================================================
// PLAYER-INHABITED UNIT DESIGNS
// These are built like any other chassis but intended to be
// ghost-inhabited.  Set control mode to Open before building.
// ============================================================

/datum/robot_build_design/standard_unit
	design_name        = "Standard Unit"
	design_desc        = "Generalist borg body — repair tools, epi injector, extinguisher, first aid, and restraints. No weapons, no hard edges. The right first build for a player who wants to be a robot."
	module_type        = /obj/item/robot_module/standard
	tier               = WORKSHOP_TIER_UTILITY
	mat_cost           = RW_COST_TIER1
	preview_icon       = "robot"
	display_health     = 100
	design_tags        = list(
		list("SUPPORT", "dim")
	)
	cert_hint          = "Any cert works. Medical cert unlocks Field Surgeon and stabilization assemblies."
	chassis_tags       = ROBOT_ROLE_SUPPORT

/datum/robot_build_design/medical_unit
	design_name        = "Medical Unit"
	design_desc        = "Full surgical suite in a borg chassis. Best healer you can field — scalpel, saw, bone setter, defibrillator, the works. Fragile. Has no way to fight back. Don't send it in alone."
	module_type        = /obj/item/robot_module/medical
	tier               = WORKSHOP_TIER_UTILITY
	mat_cost           = RW_COST_TIER1
	preview_icon       = "robot"
	display_health     = 100
	design_tags        = list(
		list("MEDICAL", "good"),
		list("FRAGILE", "bad")
	)
	cert_hint          = "Medical cert required to run Field Surgeon and stabilization assemblies — the actual reason to build this chassis."
	chassis_tags       = ROBOT_ROLE_SUPPORT

/datum/robot_build_design/engineering_unit
	design_name        = "Engineering Unit"
	design_desc        = "Construction and repair chassis. RCD, full toolset, wire synthesis, sheet fabrication. Builds walls, lays cable, fixes pipes. The most useful non-combat robot you can put a player into."
	module_type        = /obj/item/robot_module/engineering
	tier               = WORKSHOP_TIER_UTILITY
	mat_cost           = RW_COST_TIER1
	preview_icon       = "robot"
	display_health     = 100
	design_tags        = list(
		list("BUILDER", "dim")
	)
	cert_hint          = "Engineering cert unlocks the Infrastructure Monitor assembly and engineering-specific behaviors."
	chassis_tags       = ROBOT_ROLE_SUPPORT

/datum/robot_build_design/security_unit
	design_name        = "Security Unit"
	design_desc        = "Enforcement chassis. Stun weapon, restraints, health monitor, crew tracker. Won't win a straight fight but nobody outruns it and nobody slips the cuffs. The right call when you need a body that doesn't get tired."
	module_type        = /obj/item/robot_module/security
	tier               = WORKSHOP_TIER_SECURITY
	mat_cost           = RW_COST_TIER2
	preview_icon       = "robot"
	display_health     = 100
	design_tags        = list(
		list("SECURITY", "stat")
	)
	cert_hint          = "No specialist cert required. Combat cert adds combat behaviors if you want more enforcement firepower."
	chassis_tags       = ROBOT_ROLE_SECURITY

/datum/robot_build_design/service_unit
	design_name        = "Service Unit"
	design_desc        = "Hospitality chassis. Cleans, serves drinks, carries food, plays music on request. Will not fight. Will not run. Will keep the floor spotless while everything goes wrong around it."
	module_type        = /obj/item/robot_module/butler
	tier               = WORKSHOP_TIER_UTILITY
	mat_cost           = RW_COST_TIER1
	preview_icon       = "robot"
	display_health     = 100
	design_tags        = list(
		list("CIVILIAN", "dim")
	)
	cert_hint          = "Any cert works. No behaviors are locked behind specialist certs for this chassis."
	chassis_tags       = ROBOT_ROLE_SUPPORT

/datum/robot_build_design/miner_unit
	design_name        = "Miner Unit"
	design_desc        = "Excavation chassis. Kinetic accelerator, ore bag, mining scanner, GPS. The highest-throughput resource platform available. A player in one of these is worth three pack brahmin."
	module_type        = /obj/item/robot_module/miner
	tier               = WORKSHOP_TIER_UTILITY
	mat_cost           = RW_COST_TIER1
	preview_icon       = "robot"
	display_health     = 100
	design_tags        = list(
		list("MINER",  "dim")
	)
	cert_hint          = "Any cert works. No behaviors are locked behind specialist certs for this chassis."
	chassis_tags       = ROBOT_ROLE_SUPPORT

/datum/robot_build_design/farmer_unit
	design_name        = "Farmer Unit"
	design_desc        = "Agricultural maintenance chassis. Cultivator, rake, spade, mini extinguisher, crowbar, sensor device, and gripper. Pair with a Farm Tender Protocol assembly for automated weed and water maintenance. Add surgical extras from the loadout panel if you want a field medic unit."
	module_type        = /obj/item/robot_module/farmer
	tier               = WORKSHOP_TIER_UTILITY
	mat_cost           = RW_COST_TIER1
	preview_icon       = "robot"
	display_health     = 100
	design_tags        = list(
		list("FARMER",   "good"),
		list("CIVILIAN", "dim")
	)
	cert_hint          = "Any cert works. No specialist cert required for farming or maintenance assemblies."
	chassis_tags       = ROBOT_ROLE_SUPPORT


/datum/robot_build_design/trader_unit
	design_name        = "Trader Unit"
	design_desc        = "Mobile commerce chassis. Stock goods, set prices, and collect caps — all from a Protectron frame. Use the spawned vendor key to enter service mode. Pair with a Trader Protocol assembly for automated customer pitches. Customers browse stock by clicking the bot."
	module_type        = /obj/item/robot_module/trader
	tier               = WORKSHOP_TIER_UTILITY
	mat_cost           = RW_COST_TIER1
	preview_icon       = "protectron"
	display_health     = 100
	design_tags        = list(
		list("TRADER",   "good"),
		list("CIVILIAN", "dim")
	)
	cert_hint          = "Any cert works. Pair with a Trader Protocol assembly for player-free operation."
	chassis_tags       = ROBOT_ROLE_SUPPORT


// ====================================================
// MACHINE
// ====================================================

/obj/machinery/robot_workshop
	name = "Robot Workshop"
	desc = "A heavy-duty assembly station for constructing robot units from chassis parts."
	icon = 'icons/obj/machines/heavy_lathe.dmi'
	icon_state = "h_lathe"
	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 40
	active_power_usage = 400

	/// Current workshop tier unlocked by installed cert cards
	var/workshop_tier = WORKSHOP_TIER_UTILITY  // Baseline -- UTILITY designs build freely. Higher tiers need a Workshop Cert Card.

	/// Installed cert cards that provided tier upgrades (stored for examination/ejection)
	var/list/installed_certs = list()

	/// Currently inserted robot chassis (robot_suit item)
	var/obj/item/robot_suit/chassis = null

	/// Currently selected build design path
	var/selected_design = null

	/// Currently inserted behavior assembly
	var/obj/item/behavior_assembly/behavior_assembly = null

	/// Hardware IC slots filled by player - assoc list: slot_name -> obj/item

	/// Currently inserted cert card for the robot (optional)
	var/obj/item/cert_card/robot_cert = null

	/// Player control mode: "npc", "open", "locked"
	var/control_mode = "npc"

	/// If control_mode == "locked", only this ckey can ghost in
	var/locked_ckey = null

	/// UI mode
	var/ui_mode = RW_HOME

	/// Hardware sub-mode: null, "pick", "config", "circuit"
	var/hw_mode = null
	/// Slot key currently being configured in pick/config mode
	var/hw_active_slot = null
	/// Hardware datum type currently being configured before confirm
	var/hw_pending_type = null
	/// Pending config overrides assoc varname -> value
	var/list/hw_pending_config = list()
	/// Final hardware list: assoc slot_key -> datum/robot_hardware
	var/list/pending_hardware = list()
	/// Slot key of circuit_board hardware open in circuit editor
	var/hw_circuit_slot = null
	/// Node connection state for circuit editor wiring
	var/list/hw_connect_from = null

	/// Logic Core inline condition builder state (Programs tab)
	var/lc_build_var = "health_pct"
	var/lc_build_op  = "<"
	var/lc_build_val = 0

	/// Whether the machine is currently building
	var/building = FALSE

	/// Pending loadout item swaps: assoc item_index(num as text) -> type path
	/// Applied at build time to override default basic_modules items
	var/list/pending_loadout_swaps = list()
	/// Index (1-based, as text) of the loadout slot currently open for picking
	var/loadout_pick_idx = null
	/// Addable extras toggled on by the player: list of type paths from module.loadout_extras
	/// Applied at build time by appending new instances to M.basic_modules
	var/list/pending_loadout_adds = list()

	/// Materials hopper - assoc list: material key -> amount
	var/list/materials = list(
		"iron"   = 0,
		"glass"  = 0,
		"gold"   = 0,
		"silver" = 0
	)

	/// Max material storage per type
	var/mat_max = 50000

	/// List of all build designs, populated in Initialize
	var/list/datum/robot_build_design/designs = list()


// ====================================================
// INITIALIZE / DESTROY
// ====================================================

/obj/machinery/robot_workshop/Initialize(mapload)
	. = ..(  )
	// Populate build designs
	for(var/T in subtypesof(/datum/robot_build_design))
		designs += new T()

/obj/machinery/robot_workshop/Destroy()
	// Eject chassis
	if(chassis)
		chassis.forceMove(get_turf(src))
	chassis = null
	// Eject assembly
	if(behavior_assembly)
		behavior_assembly.forceMove(get_turf(src))
	behavior_assembly = null
	// Eject cert
	if(robot_cert)
		robot_cert.forceMove(get_turf(src))
	robot_cert = null
	// Eject pending hardware datums
	for(var/slot in pending_hardware)
		var/datum/robot_hardware/HW = pending_hardware[slot]
		if(HW) qdel(HW)
	pending_hardware = list()
	// Eject tier certs
	for(var/obj/item/cert_card/C in installed_certs)
		C.forceMove(get_turf(src))
	installed_certs.Cut()
	designs.Cut()
	return ..(  )


// ====================================================
// ATTACKBY -- physical item insertion
// ====================================================

/obj/machinery/robot_workshop/attackby(obj/item/W, mob/user, params)
	if(!HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
		to_chat(user, span_warning("You don't know how to operate this equipment."))
		return

	// Cert cards -- two kinds: workshop tier certs and robot base certs
	if(istype(W, /obj/item/cert_card))
		var/obj/item/cert_card/CC = W
		if(CC.base_cert && istype(CC.base_cert, /datum/cpu_cert/workshop))
			_try_install_workshop_cert(CC, user)
			return
		// Robot base cert or upgrade cert -- load into the robot cert slot
		if(!robot_cert)
			if(!user.transferItemToLoc(W, src))
				return
			robot_cert = CC
			to_chat(user, span_notice("Robot cert card loaded."))
			ui_interact(user)
			return
		to_chat(user, span_warning("A robot cert is already loaded. Eject it first."))
		return

	// Robot chassis
	if(istype(W, /obj/item/robot_suit))
		if(chassis)
			to_chat(user, span_warning("A chassis is already loaded. Remove it first."))
			return
		if(!user.transferItemToLoc(W, src))
			return
		chassis = W
		to_chat(user, span_notice("Chassis loaded into workshop."))
		ui_interact(user)
		return

	// Behavior assembly
	if(istype(W, /obj/item/behavior_assembly))
		if(behavior_assembly)
			to_chat(user, span_warning("An assembly is already queued. Remove it first."))
			return
		if(!user.transferItemToLoc(W, src))
			return
		behavior_assembly = W
		// Populate hardware slots required by this assembly
		var/obj/item/behavior_assembly/BA_cast = W
		to_chat(user, span_notice("Behavior assembly queued: [BA_cast.assembly_label]."))
		ui_mode = RW_HARDWARE
		ui_interact(user)
		return

	// Materials -- accept stacks of metal/glass/gold/silver (check before hardware slots)
	var/mat_key = _mat_key_from_item(W)
	if(mat_key)
		var/obj/item/stack/S = W
		var/space = mat_max - materials[mat_key]
		if(space <= 0)
			to_chat(user, span_warning("[mat_key] hopper is full."))
			return
		var/to_take = min(S.amount, round(space / 2000))
		if(to_take <= 0)
			to_chat(user, span_warning("Not enough room for more [mat_key]."))
			return
		S.use(to_take)
		materials[mat_key] += to_take * 2000
		to_chat(user, span_notice("Added [to_take] sheets of [mat_key]. ([materials[mat_key]]/[mat_max])"))
		ui_interact(user)
		return


	return ..(  )


// ====================================================
// UI INTERACT
// ====================================================

/obj/machinery/robot_workshop/ui_interact(mob/user, datum/tgui/ui)
	if(!HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
		to_chat(user, span_warning("You don't know how to operate this equipment."))
		return
	var/dat = _render_page(user)
	var/datum/browser/popup = new(user, "robot_workshop", "ROBOT WORKSHOP", 620, 720)
	popup.set_content(dat)
	popup.open()

/obj/machinery/robot_workshop/proc/_render_page(mob/user)
	var/dat = _get_css()
	// ROBCO header - exact match to cpu_fabricator
	dat += "<center><b>ROBCO INDUSTRIES UNIFIED OPERATING SYSTEM v.85</b><br>"
	dat += "<b>COPYRIGHT 2075-2077 ROBCO INDUSTRIES</b><br>"
	dat += "= ROBOT WORKSHOP =</center><br>"
	dat += _navlink("Home",     RW_HOME)
	dat += " | "
	dat += _navlink("Build",    RW_BUILD)
	dat += " | "
	dat += _navlink("Hardware", RW_HARDWARE)
	dat += " | "
	dat += _navlink("Programs", RW_PROGRAMS)
	dat += " | "
	dat += _navlink("Finalize", RW_FINALIZE)
	dat += "<br><hr>"
	if(workshop_tier > WORKSHOP_TIER_NONE)
		dat += "<span class='dim'>TIER: <b>[_tier_label(workshop_tier)]</b></span>"
	else
		dat += "<span class='warn'>TIER: UNCERTIFIED -- install a Workshop Cert Card</span>"
	if(building)
		dat += "  <span class='warn'>// FABRICATING...</span>"
	dat += "<br>"
	// Page content
	switch(ui_mode)
		if(RW_HOME)
			dat += _render_home(user)
		if(RW_BUILD)
			dat += _render_build(user)
		if(RW_HARDWARE)
			dat += _render_hardware(user)
		if(RW_PROGRAMS)
			dat += _render_programs(user)
		if(RW_FINALIZE)
			dat += _render_finalize(user)
	return dat

/obj/machinery/robot_workshop/proc/_navlink(label, mode_id)
	if(ui_mode == mode_id)
		return "<b>&gt; [label]</b>"
	return "<a href='byond://?src=[REF(src)];set_mode=[mode_id]'>&gt; [label]</a>"


// ====================================================
// HOME TAB
// ====================================================

/obj/machinery/robot_workshop/proc/_render_home(mob/user)
	var/dat = ""
	dat += "<span class='dim'>// This bench builds robot units from chassis parts, hardware modules, and behavior assemblies. Pick a design, load materials, and finalize to fabricate.</span><br><br>"

	// Quick-start guide for new builders
	dat += "QUICKSTART<br>"
	dat += "<span class='dim'>1. Load materials into the hopper (insert metal/glass/gold/silver sheets).</span><br>"
	dat += "<span class='dim'>2. Go to <b>Build</b> and pick a robot type. Mr. Handy is the recommended first build.</span><br>"
	dat += "<span class='dim'>3. Go to <b>Hardware</b> and click \[USE RECOMMENDED HARDWARE\] to auto-fill slots.</span><br>"
	dat += "<span class='dim'>4. Go to <b>Programs</b> if you have a behavior assembly to slot in (optional).</span><br>"
	dat += "<span class='dim'>5. Go to <b>Finalize</b> and hit FABRICATE ROBOT.</span><br>"
	dat += "<br>"

	// Workshop tier
	dat += "WORKSHOP STATUS<br>"
	dat += "Tier: <span class='good'>[_tier_label(workshop_tier)]</span>"
	// Next tier teaser
	var/next_tier = workshop_tier + 1
	if(next_tier <= WORKSHOP_TIER_APEX)
		dat += "  <span class='dim'>// install a T[next_tier] Workshop Cert Card to unlock [_tier_label(next_tier)] chassis</span>"
	dat += "<br>"

	// Installed tier certs
	if(installed_certs.len)
		dat += "Installed certs:<br>"
		for(var/obj/item/cert_card/C in installed_certs)
			dat += "<span class='dim'>&gt; [C.name]</span>"
			dat += "  <a href='byond://?src=[REF(src)];eject_tier_cert=[REF(C)]'>\[eject\]</a><br>"
	dat += "<br>"

	// Chassis slot
	dat += "CHASSIS SLOT<br>"
	if(chassis)
		dat += "<span class='good'>&gt; [chassis.name]</span>"
		dat += "  <a href='byond://?src=[REF(src)];eject_chassis=1'>\[eject\]</a><br>"
	else
		dat += "<span class='dim'>Empty -- chassis is optional. Insert a robot suit item to give the robot a cosmetic body skin at spawn.</span><br>"
	dat += "<br>"

	// Material hopper
	var/any_mats = FALSE
	for(var/mat in materials)
		if(materials[mat] > 0)
			any_mats = TRUE
			break
	dat += "MATERIAL HOPPER  <a href='byond://?src=[REF(src)];eject_mats=1'>\[eject all\]</a><br>"
	if(!any_mats)
		dat += "<span class='warn'>&gt; Hopper empty. Insert iron, glass, gold, or silver sheets from your inventory.</span><br>"
	for(var/mat in materials)
		var/amt = materials[mat]
		var/bar = _mat_bar(amt, mat_max)
		dat += "<span class='dim'>[uppertext(mat)]</span>  [bar]  "
		dat += "<span class='warn'>[amt]</span><span class='dim'>/[mat_max] cm3</span>  "
		if(amt > 0)
			dat += "<a href='byond://?src=[REF(src)];eject_mat=[mat]'>\[eject\]</a>"
		dat += "<br>"
	dat += "<br>"

	// Operator SPECIAL profile
	if(istype(user, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = user
		dat += "OPERATOR PROFILE  <span class='dim'>// your stats shape this robot at build time</span><br>"
		dat += "<span class='dim'>STR [H.special_s]  PER [H.special_p]  END [H.special_e]  CHA [H.special_c]"
		dat += "  INT [H.special_i]  AGI [H.special_a]  LCK [H.special_l]</span><br>"
		var/lck_disc = get_workshop_lck_discount(H)
		if(lck_disc > 0)
			dat += "<span class='good'>LCK [H.special_l]: [lck_disc]% material cost discount active</span><br>"
		else if(H.special_l < 5)
			dat += "<span class='dim'>LCK [H.special_l]: LCK 5+ gives a material cost discount at build time</span><br>"
		if(H.special_i >= RH_INT_MASTER)
			dat += "<span class='good'>INT [H.special_i]: Circuit Board slot unlocked on HARDWARE tab</span><br>"
		else if(H.special_i < RH_INT_STANDARD)
			dat += "<span class='warn'>INT [H.special_i]: limited hardware access (INT [RH_INT_STANDARD]+ recommended)</span><br>"

	return dat


// ====================================================
// BUILD TAB
// ====================================================

/obj/machinery/robot_workshop/proc/_render_build(mob/user)
	var/dat = ""
	dat += "SELECT ROBOT TYPE  <span class='dim'>// filtered by workshop tier</span><br><br>"

	var/any_shown = FALSE
	var/next_locked_tier = -1  // lowest locked tier above current

	for(var/datum/robot_build_design/D in designs)
		// Track lowest locked tier for preview
		if(D.tier > workshop_tier)
			if(next_locked_tier < 0 || D.tier < next_locked_tier)
				next_locked_tier = D.tier
		if(D.tier > workshop_tier)
			continue
		any_shown = TRUE
		var/is_selected = (selected_design == D.type)

		// Build inline tag string
		var/tag_str = ""
		if(D.design_tags && D.design_tags.len)
			for(var/list/tag in D.design_tags)
				tag_str += "  <span class='[tag[2]]'>\[[tag[1]]\]</span>"

		if(is_selected)
			dat += "<b>&gt; [D.design_name]</b>[tag_str]<br>"
			if(D.design_starter)
				dat += "<span class='good'>  ★ Recommended first build</span><br>"
			dat += "<span class='dim'>[D.design_desc]</span><br>"
			dat += "HP: <span class='good'>[D.display_health]</span>  "
			dat += "Cost: <span class='dim'>[_mat_cost_str(D.mat_cost)]</span><br>"
			if(D.cert_hint)
				dat += "<span class='dim'>Cert: [D.cert_hint]</span><br>"
			// Module role requirement
			if(D.chassis_tags && D.chassis_tags != ROBOT_ROLE_ANY)
				var/role_label = _role_tag_label(D.chassis_tags)
				var/module_tag_val = initial(D.module_type:module_tags)
				if(D.chassis_tags & module_tag_val)
					dat += "<span class='dim'>Module role: [role_label] — compatible.</span><br>"
				else
					dat += "<span class='bad'>! Module mismatch: [D.design_name] requires a [role_label] module. Select a matching chassis module on the Build tab.</span><br>"
			if(D.design_needs_assembly)
				dat += "<span class='bad'>&gt; Assembly warning: slot a behavior assembly before finalizing or this robot will be uncontrolled.</span><br>"
			dat += "<span class='good'>&gt; SELECTED</span>"
			dat += "  <a href='byond://?src=[REF(src)];select_design=clear'>\[clear\]</a><br>"
		else
			dat += "&gt; <a href='byond://?src=[REF(src)];select_design=[D.type]'>[D.design_name]</a>[tag_str]<br>"
			if(D.design_starter)
				dat += "<span class='good'>  ★ Recommended first build</span><br>"
			dat += "<span class='dim'>[D.design_desc]</span><br>"
			dat += "HP: <span class='good'>[D.display_health]</span>  "
			dat += "Cost: <span class='dim'>[_mat_cost_str(D.mat_cost)]</span><br>"
			if(D.cert_hint)
				dat += "<span class='dim'>Cert: [D.cert_hint]</span><br>"
			if(D.chassis_tags && D.chassis_tags != ROBOT_ROLE_ANY)
				dat += "<span class='dim'>Module role: [_role_tag_label(D.chassis_tags)]</span><br>"
		dat += "<br>"

	if(!any_shown)
		dat += "<span class='warn'>No designs available at current tier.</span><br>"

	// Locked tier preview — show the next tier's chassis as dim teasers
	if(next_locked_tier > 0)
		dat += "<hr><span class='dim'>LOCKED — [_tier_label(next_locked_tier)] tier  // install a T[next_locked_tier] Workshop Cert Card to unlock</span><br>"
		for(var/datum/robot_build_design/D in designs)
			if(D.tier != next_locked_tier)
				continue
			var/tag_str = ""
			if(D.design_tags && D.design_tags.len)
				for(var/list/tag in D.design_tags)
					tag_str += "  <span class='dim'>\[[tag[1]]\]</span>"
			dat += "<span class='dim'>&gt; [D.design_name][tag_str]</span><br>"

	return dat


// ====================================================
// HARDWARE TAB
// ====================================================

// ====================================================
// HARDWARE TAB - DISPATCH
// Sub-modes: null=overview, "pick"=picker, "config"=configurator
//            "circuit"=circuit board node editor
// ====================================================

/obj/machinery/robot_workshop/proc/_render_hardware(mob/user)
	if(hw_mode == "pick")
		return _render_hw_picker(user)
	if(hw_mode == "config")
		return _render_hw_config(user)
	if(hw_mode == "circuit")
		return _render_circuit_editor(user)
	return _render_hw_overview(user)


// ====================================================
// HARDWARE TAB - OVERVIEW
// ====================================================

/obj/machinery/robot_workshop/proc/_render_hw_overview(mob/user)
	var/dat = ""
	var/mob/living/carbon/human/H = istype(user, /mob/living/carbon/human) ? user : null

	if(!selected_design)
		dat += "<span class='dim'>// Tip: go to the <b>Build</b> tab and select a robot type first. That unlocks \[USE RECOMMENDED HARDWARE\] and shows which hardware slots are required for that chassis.</span><br><br>"

	// Recommended button
	if(selected_design)
		dat += "<a href='byond://?src=[REF(src)];hw_use_recommended=1'><b>\[USE RECOMMENDED HARDWARE\]</b></a>"
		dat += "  <span class='dim'>// auto-fills all slots for this robot type</span><br>"
		if(pending_hardware.len)
			dat += "<a href='byond://?src=[REF(src)];hw_clear_all=1'>\[clear all\]</a><br>"
		dat += "<br>"

	// CORE budget meter
	if(robot_cert)
		dat += get_core_usage_display(pending_hardware, robot_cert.base_cert) + "<br><br>"
	else
		var/datum/cpu_cert/default_cert = new /datum/cpu_cert/robot()
		dat += get_core_usage_display(pending_hardware, default_cert) + "<br>"
		qdel(default_cert)
		dat += "<span class='dim'>(using default cert - insert a cert card for accurate budget)</span><br><br>"

	// SPECIAL influence preview
	if(H)
		dat += _hw_special_preview(H) + "<br>"

	// Hardware slots derived from assembly
	var/list/asm_slots = _get_assembly_slot_keys()

	if(asm_slots.len)
		dat += "REQUIRED HARDWARE SLOTS  <span class='dim'>// from queued assembly</span><br>"
		for(var/slot_key in asm_slots)
			dat += _hw_slot_row(slot_key, TRUE, H)
		dat += "<br>"

	// Optional hardware
	dat += "OPTIONAL HARDWARE  <span class='dim'>// enhances robot beyond assembly requirements</span><br>"
	// Show already-added optional slots
	for(var/slot_key in pending_hardware)
		if(slot_key in asm_slots)
			continue
		dat += _hw_slot_row(slot_key, FALSE, H)
	dat += "<a href='byond://?src=[REF(src)];hw_add_optional=1'>\[+ add optional hardware\]</a><br>"

	// Base module loadout ? player can swap same-type alternatives
	if(selected_design)
		var/datum/robot_build_design/D = _get_design(selected_design)
		if(D)
			var/module_desc_text = initial(D.module_type:module_desc)
			var/persona_name = initial(D.module_type:personality_name)
			dat += "<br>MODULE LOADOUT"
			if(module_desc_text)
				dat += "  <span class='dim'>// [module_desc_text]</span>"
			dat += "<br>"
			if(persona_name)
				dat += "<span class='dim'>Personality: [persona_name]  // robot will speak ambient lines when no player is inhabiting</span><br>"
			var/obj/item/robot_module/dummy = new D.module_type(null)
			var/list/base_items = list()
			for(var/obj/item/I in dummy.basic_modules)
				base_items += I
			for(var/idx = 1 to base_items.len)
				var/obj/item/I = base_items[idx]
				var/idx_key = "[idx]"
				var/swapped_path = pending_loadout_swaps[idx_key]
				if(swapped_path)
					dat += "&gt; [I.name]  <span class='dim'>?</span>  <span class='good'>[initial(swapped_path:name)]</span>  <a href='byond://?src=[REF(src)];loadout_swap_clear=[idx_key]'>\[reset\]</a><br>"
				else if(loadout_pick_idx == idx_key)
					dat += "<span class='good'>&gt; [I.name]</span>  <span class='dim'>// picking replacement:</span><br>"
					var/list/candidates = list()
					for(var/ctype in subtypesof(I.type))
						if(ctype == I.type) continue
						candidates += ctype
					if(candidates.len)
						for(var/ctype in candidates)
							var/ctype_str = "[ctype]"
							dat += "  <a href='byond://?src=[REF(src)];loadout_swap_set=[idx_key];loadout_swap_type=[url_encode(ctype_str)]'>&gt; [initial(ctype:name)]</a><br>"
					else
						dat += "  <span class='dim'>(no alternatives found)</span><br>"
					dat += "  <a href='byond://?src=[REF(src)];loadout_pick_cancel=1'>\[cancel\]</a><br>"
				else
					dat += "<span class='dim'>  + [I.name]</span>  <a href='byond://?src=[REF(src)];loadout_pick=[idx_key]'>\[swap\]</a><br>"

			// ADDABLE ITEMS -- extras declared by the module but not in the base loadout
			var/list/extras = dummy.loadout_extras
			if(extras && extras.len)
				dat += "<br>ADDABLE ITEMS  <span class='dim'>// optional extras this module supports</span><br>"
				for(var/add_path in extras)
					var/add_name = initial(add_path:name)
					if(add_path in pending_loadout_adds)
						dat += "<span class='good'>  + [add_name]</span>  <a href='byond://?src=[REF(src)];loadout_add_toggle=[url_encode("[add_path]")]'>\[remove\]</a><br>"
					else
						dat += "<span class='dim'>  + [add_name]</span>  <a href='byond://?src=[REF(src)];loadout_add_toggle=[url_encode("[add_path]")]'>\[add\]</a><br>"

			// ASSEMBLY CHECKLIST -- cross-check circuit tool requirements against effective loadout
			if(behavior_assembly)
				var/list/required_items = behavior_assembly.get_required_module_items()
				if(required_items && required_items.len)
					// Build effective type list: swapped base items + toggled adds
					var/list/effective_types = list()
					for(var/cidx = 1 to base_items.len)
						var/obj/item/CI = base_items[cidx]
						var/cidx_key = "[cidx]"
						var/swap_path = pending_loadout_swaps[cidx_key]
						effective_types += swap_path ? swap_path : CI.type
					for(var/add_path in pending_loadout_adds)
						effective_types += add_path
					dat += "<br>ASSEMBLY CHECKLIST  <span class='dim'>// tools required by loaded assembly circuits</span><br>"
					for(var/req_path in required_items)
						var/req_name = initial(req_path:name)
						var/found = FALSE
						for(var/etype in effective_types)
							if(ispath(etype, req_path))
								found = TRUE
								break
						if(found)
							dat += "<span class='good'>  ✓ [req_name]</span><br>"
						else
							dat += "<span class='warn'>  ✗ [req_name]  <span class='dim'>(not in module loadout - add above or swap a slot)</span></span><br>"

			qdel(dummy)

	return dat


/obj/machinery/robot_workshop/proc/_hw_slot_row(slot_key, required, mob/living/carbon/human/builder)
	var/datum/robot_hardware/HW = pending_hardware[slot_key]
	var/dat = ""
	// Readable slot label: strip /datum/robot_hardware/ prefix from type-path keys
	var/display_key = slot_key
	if(copytext(slot_key, 1, 23) == "/datum/robot_hardware/")
		display_key = replacetext(copytext(slot_key, 23), "_", " ")
	if(HW)
		dat += "<span class='good'>&gt; [display_key]</span>  [HW.hardware_name]<br>"
		if(HW.core_compute || HW.core_operations || HW.core_resilience || HW.core_energy)
			dat += "<span class='dim'>C.O.R.E: C[HW.core_compute] O[HW.core_operations] R[HW.core_resilience] E[HW.core_energy]</span><br>"
		dat += "<a href='byond://?src=[REF(src)];hw_configure=[slot_key]'>\[configure\]</a>"
		if(istype(HW, /datum/robot_hardware/circuit_board))
			dat += "  <a href='byond://?src=[REF(src)];hw_circuit_edit=[slot_key]'>\[circuit editor\]</a>"
		dat += "  <a href='byond://?src=[REF(src)];hw_remove=[slot_key]'>\[remove\]</a><br>"
	else
		var/slot_class = required ? "warn" : "dim"
		var/slot_label = required ? "required" : "optional"
		dat += "<span class='[slot_class]'>&gt; [display_key]</span>  <span class='dim'>([slot_label] -- empty)</span><br>"
		dat += "<a href='byond://?src=[REF(src)];hw_pick=[slot_key]'>\[select hardware\]</a><br>"
	return dat


/obj/machinery/robot_workshop/proc/_hw_special_preview(mob/living/carbon/human/H)
	var/dat = "OPERATOR INFLUENCE  <span class='dim'>// your SPECIAL baked into this robot at build</span><br>"
	var/per = H.special_p
	var/str = H.special_s
	var/end_s = H.special_e
	var/cha = H.special_c
	var/int_s = H.special_i
	var/agi = H.special_a
	var/lck = H.special_l
	if(per > 5)
		dat += "<span class='good'>PER [per]</span>  <span class='dim'>+[per-5] tile sensor/weapon range</span><br>"
	if(str > 5)
		dat += "<span class='good'>STR [str]</span>  <span class='dim'>+[str-5] grab force, +[(str-5)*5]ds stun duration, +[(str-5)] knockback</span><br>"
	if(end_s > 5)
		dat += "<span class='good'>END [end_s]</span>  <span class='dim'>+[(end_s-5)*10] robot HP</span><br>"
	if(agi > 5)
		dat += "<span class='good'>AGI [agi]</span>  <span class='dim'>-[round((agi-5)*0.1, 0.01)] movement delay</span><br>"
	if(int_s >= RH_INT_MASTER)
		dat += "<span class='good'>INT [int_s]</span>  <span class='dim'>Advanced Circuit Board unlocked -- add via \[+ add optional hardware\]</span><br>"
	else if(int_s >= RH_INT_ADVANCED)
		dat += "<span class='good'>INT [int_s]</span>  <span class='dim'>Advanced configs unlocked // circuit board requires INT [RH_INT_MASTER]</span><br>"
	else if(int_s >= RH_INT_STANDARD)
		dat += "<span class='dim'>INT [int_s]  // standard hardware</span><br>"
	else
		dat += "<span class='warn'>INT [int_s]  // basic hardware only (INT [RH_INT_STANDARD]+ for full access)</span><br>"
	var/lck_disc = get_workshop_lck_discount(H)
	if(lck_disc > 0)
		dat += "<span class='good'>LCK [lck]</span>  <span class='dim'>[lck_disc]% material cost discount</span><br>"
	if(cha > 5)
		dat += "<span class='good'>CHA [cha]</span>  <span class='dim'>+[cha-5] vocabulary slots, reduced neutral aggro</span><br>"
	return dat


/obj/machinery/robot_workshop/proc/_get_assembly_slot_keys()
	var/list/keys = list()
	if(!behavior_assembly)
		return keys
	var/list/seen = list()
	for(var/datum/behavior_circuit/C in behavior_assembly.circuits)
		if(!C.needs_hardware || !C.hardware_slot_name)
			continue
		if(C.hardware_slot_name in seen)
			continue
		seen += C.hardware_slot_name
		keys += C.hardware_slot_name
	return keys


// ====================================================
// HARDWARE TAB - PICKER
// ====================================================

/obj/machinery/robot_workshop/proc/_render_hw_picker(mob/user)
	var/mob/living/carbon/human/H = istype(user, /mob/living/carbon/human) ? user : null
	var/int_level = H ? H.special_i : RH_INT_BASIC
	var/dat = ""
	dat += "SELECT HARDWARE  <span class='dim'>// slot: [hw_active_slot]</span>"
	dat += "  <a href='byond://?src=[REF(src)];hw_cancel_pick=1'>\[cancel\]</a><br>"
	dat += "<span class='dim'>&gt; Search:</span> "
	var/ccs = null; ccs = ccs
	var/ccn = null; ccn = ccn
	var/cci = null; cci = cci
	var/sn  = null; sn  = sn
	dat += {"<input id='cfilter' type='text' autofocus placeholder='filter hardware...' onkeyup='var ccs=this.value.toLowerCase();var ccn=document.getElementsByClassName(&quot;ccard&quot;).length;while(ccn--){cci=document.getElementsByClassName(&quot;ccard&quot;).item(ccn);cci.style.display=cci.getAttribute(&quot;data-s&quot;).indexOf(ccs)>=0?&quot;block&quot;:&quot;none&quot;;}var sn=document.getElementsByClassName(&quot;csec&quot;).length;while(sn--){document.getElementsByClassName(&quot;csec&quot;).item(sn).style.display=ccs?&quot;none&quot;:&quot;block&quot;;}' style='background:#062113;color:#4aed92;border:1px solid #2a7a52;font-family:monospace;padding:2px 4px;width:220px' /><br><br>"}

	var/list/by_cat = list()
	for(var/T in subtypesof(/datum/robot_hardware))
		var/datum/robot_hardware/proto = new T()
		if(!by_cat[proto.category])
			by_cat[proto.category] = list()
		by_cat[proto.category] += T
		qdel(proto)

	for(var/cat in by_cat)
		dat += "<div class='csec'>[cat]</div>"
		for(var/T in by_cat[cat])
			var/datum/robot_hardware/proto = new T()
			// Skip hardware that doesn't satisfy the required slot type
			if(hw_active_slot && !_slot_accepts_hw_type(hw_active_slot, T))
				qdel(proto)
				continue
			var/blocked = int_level < proto.min_int
			var/gate_label = get_int_gate_label(proto.min_int)
			// CORE budget check
			var/list/test_hw = pending_hardware.Copy()
			test_hw[hw_active_slot] = proto
			var/datum/cpu_cert/cert = robot_cert ? robot_cert.base_cert : new /datum/cpu_cert/robot()
			var/list/core_errors = check_hardware_core_budget(test_hw, cert)
			if(!robot_cert) qdel(cert)
			var/overbudget = core_errors.len > 0
			var/core_str = "C[proto.core_compute] O[proto.core_operations] R[proto.core_resilience] E[proto.core_energy]"
			var/mat_str = _mat_cost_str(proto.mat_cost)
			var/searchkey = replacetext(lowertext(proto.hardware_name) + " " + lowertext(proto.hardware_desc) + " " + lowertext(cat), "'", "")
			dat += "<div class='ccard' data-s='[searchkey]'>"
			if(blocked)
				dat += "<span class='dim'>&gt; [proto.hardware_name]  [gate_label]</span><br>"
				dat += "<span class='dim'>[proto.hardware_desc]</span><br>"
				dat += "<span class='dim'>CORE: [core_str]  MAT: [mat_str]</span>"
			else if(overbudget)
				dat += "<span class='bad'>&gt; [proto.hardware_name]  // overbudget</span><br>"
				dat += "<span class='dim'>[proto.hardware_desc]</span><br>"
				dat += "<span class='dim'>CORE: [core_str]  MAT: [mat_str]</span>"
			else
				dat += "&gt; <a href='byond://?src=[REF(src)];hw_select_type=[T]'>[proto.hardware_name]</a>"
				if(gate_label)
					dat += "  [gate_label]"
				dat += "<br>"
				dat += "<span class='dim'>[proto.hardware_desc]</span><br>"
				dat += "<span class='dim'>CORE: [core_str]  MAT: [mat_str]</span>"
			dat += "</div>"
			qdel(proto)

	return dat


// ====================================================
// HARDWARE TAB - CONFIGURATOR
// ====================================================

/obj/machinery/robot_workshop/proc/_render_hw_config(mob/user)
	if(!hw_pending_type)
		hw_mode = null
		return _render_hw_overview(user)

	var/datum/robot_hardware/proto = new hw_pending_type()
	var/dat = ""
	dat += "CONFIGURE: [proto.hardware_name]"
	dat += "  <span class='dim'>// slot: [hw_active_slot]</span><br>"
	dat += "<a href='byond://?src=[REF(src)];hw_back_to_pick=1'>\[back\]</a>"
	dat += "  <a href='byond://?src=[REF(src)];hw_confirm=1'><b>\[CONFIRM & INSTALL\]</b></a><br><br>"

	dat += "<span class='dim'>[proto.tutorial_text]</span><br><br>"

	if(proto.config_defs.len)
		dat += "CONFIGURATION<br>"
		for(var/varname in proto.config_defs)
			var/list/def = proto.config_defs[varname]
			var/label    = def[1]
			var/dtype    = def[2]
			var/cur_val  = hw_pending_config[varname] != null ? hw_pending_config[varname] : def[3]
			if(dtype == "waypoint_list")
				// Waypoint list: render an inline editor instead of a plain edit link
				var/list/wps = islist(cur_val) ? cur_val : list()
				var/max_wp = hw_pending_config["max_waypoints"] != null ? hw_pending_config["max_waypoints"] : 5
				dat += "<span class='dim'>[label]:</span>  <span class='good'>[wps.len]/[max_wp]</span><br>"
				for(var/i in 1 to wps.len)
					var/list/wp = wps[i]
					dat += "&nbsp;&nbsp;[i]. X:[wp[1]] Y:[wp[2]]"
					dat += "  <a href='byond://?src=[REF(src)];hw_wp_remove=[i]'>\[remove\]</a><br>"
				if(wps.len < max_wp)
					dat += "&nbsp;&nbsp;<a href='byond://?src=[REF(src)];hw_wp_add=1'>\[+ Add Waypoint\]</a><br>"
				else
					dat += "&nbsp;&nbsp;<span class='dim'>(waypoint slots full)</span><br>"
				continue
			dat += "<span class='dim'>[label]:</span>  "
			dat += "<span class='good'>[cur_val]</span>"
			dat += "  <a href='byond://?src=[REF(src)];hw_edit_var=[varname]'>\[edit\]</a>"
			if(dtype == "bool")
				dat += "  <a href='byond://?src=[REF(src)];hw_toggle_var=[varname]'>\[toggle\]</a>"
			dat += "<br>"
	else
		dat += "<span class='dim'>No configuration options for this hardware.</span><br>"

	dat += "<br><span class='dim'>CORE cost: C[proto.core_compute] O[proto.core_operations] R[proto.core_resilience] E[proto.core_energy]</span><br>"
	dat += "<span class='dim'>Material cost: [_mat_cost_str(proto.mat_cost)]</span><br>"
	qdel(proto)
	return dat


// ====================================================
// HARDWARE TAB - CIRCUIT BOARD EDITOR
// ====================================================

/obj/machinery/robot_workshop/proc/_render_circuit_editor(mob/user)
	var/datum/robot_hardware/circuit_board/CB = pending_hardware[hw_circuit_slot]
	if(!CB || !istype(CB, /datum/robot_hardware/circuit_board))
		hw_mode = null
		return _render_hw_overview(user)

	var/dat = ""
	dat += "CIRCUIT BOARD EDITOR  <span class='dim'>// slot: [hw_circuit_slot]  nodes: [CB.nodes.len]/[CB.max_nodes]</span><br>"
	dat += "<a href='byond://?src=[REF(src)];hw_circuit_done=1'>\[done - return to overview\]</a><br><br>"

	// -- ADD NODE panel --
	dat += "ADD NODE  <span class='dim'>// click to place</span><br>"
	var/list/cat_nodes = list()
	for(var/T in /datum/circuit_node_catalog::all_types)
		var/datum/circuit_node/proto = new T()
		if(!cat_nodes[proto.node_category])
			cat_nodes[proto.node_category] = list()
		cat_nodes[proto.node_category] += T
		qdel(proto)
	for(var/cat in cat_nodes)
		dat += "<span class='dim'>[cat]:</span>  "
		var/list/links = list()
		for(var/T in cat_nodes[cat])
			var/datum/circuit_node/proto = new T()
			links += "<a href='byond://?src=[REF(src)];ce_add_node=[T]'>[proto.node_name]</a>"
			qdel(proto)
		dat += links.Join("  ")
		dat += "<br>"
	dat += "<br>"

	// -- PLACED NODES panel --
	dat += "PLACED NODES<br>"
	if(!CB.nodes.len)
		dat += "<span class='dim'>No nodes placed yet. Add from the list above.</span><br>"
	else
		for(var/i in 1 to CB.nodes.len)
			var/datum/circuit_node/N = CB.nodes[i]
			dat += ""
			dat += "<b>[i]. [N.node_name]</b>  <span class='dim'>[N.node_category]</span>"
			dat += "  <a href='byond://?src=[REF(src)];ce_remove_node=[i]'>\[remove\]</a><br>"
			// Inputs
			if(N.inputs.len)
				dat += "<span class='dim'>IN: "
				var/list/iparts = list()
				for(var/inp in N.inputs)
					iparts += "[inp]=[N.inputs[inp]]"
				dat += iparts.Join("  ") + "</div>"
			// Outputs
			if(N.outputs.len)
				dat += "<span class='dim'>OUT: "
				var/list/oparts = list()
				for(var/outp in N.outputs)
					oparts += "<a href='byond://?src=[REF(src)];ce_connect_from=[i]:[outp]'>[outp]=[N.outputs[outp]]</a>"
				dat += oparts.Join("  ") + "</div>"
			// Config
			if(N.config_defs.len)
				for(var/varname in N.config_defs)
					var/list/def = N.config_defs[varname]
					dat += "<span class='dim'>[def[1]]:</span> [N.vars[varname]]"
					dat += "  <a href='byond://?src=[REF(src)];ce_edit_node=[i]:[varname]'>\[edit\]</a><br>"
					if(def[2] == "bool")
						dat += "  <a href='byond://?src=[REF(src)];ce_toggle_node=[i]:[varname]'>\[toggle\]</a><br>"
			// Pending connect state
			if(hw_connect_from && hw_connect_from[1] != i)
				for(var/inp in N.inputs)
					dat += "<a href='byond://?src=[REF(src)];ce_connect_to=[i]:[inp]'><b>\[WIRE TO [inp]\]</b></a>  "
				dat += "<br>"


	// -- CONNECTIONS panel --
	dat += "<br><b>CONNECTIONS</b><br>"
	if(!CB.connections.len)
		dat += "<span class='dim'>No wires. Click an output pin above to begin wiring.</span><br>"
	else
		for(var/ci in 1 to CB.connections.len)
			var/list/conn = CB.connections[ci]
			var/datum/weakref/from_ref = conn[1]
			var/datum/weakref/to_ref   = conn[3]
			var/datum/circuit_node/FN = from_ref?.resolve()
			var/datum/circuit_node/TN = to_ref?.resolve()
			var/fname = FN ? FN.node_name : "?"
			var/tname = TN ? TN.node_name : "?"
			dat += "<span class='dim'>[fname].[conn[2]] &rarr; [tname].[conn[4]]</span>"
			dat += "  <a href='byond://?src=[REF(src)];ce_disconnect=[ci]'>\[disconnect\]</a><br>"

	// Evaluate button
	dat += "<br><a href='byond://?src=[REF(src)];ce_evaluate=1'><b>\[EVALUATE BOARD\]</b></a>"
	dat += "  <span class='dim'>// runs all nodes, shows live output values above</span><br>"

	if(hw_connect_from)
		dat += "<br><span class='warn'>Wiring mode: select a destination input pin above. "
		dat += "<a href='byond://?src=[REF(src)];ce_cancel_connect=1'>\[cancel\]</a></span><br>"

	return dat

// ====================================================
// PROGRAMS TAB
// ====================================================

/obj/machinery/robot_workshop/proc/_render_programs(mob/user)
	var/dat = ""
	dat += "BEHAVIOR ASSEMBLY<br><br>"

	if(behavior_assembly)
		var/obj/item/behavior_assembly/A = behavior_assembly
		dat += "[A.assembly_label]<br>"
		dat += "<span class='dim'>Circuits: [A.circuits.len]/[A.max_circuits]</span><br>"
		dat += "<span class='dim'>Sensor range: [A.sensor_range] tiles</span><br>"
		if(A.circuits.len)
			dat += "<br>"
			for(var/datum/behavior_circuit/C in A.circuits)
				var/hw_note = C.needs_hardware ? "  <span class='warn'>HARDWARE</span>" : ""
				dat += "<span class='dim'>  [C.circuit_name][hw_note]</span><br>"
				dat += "<span class='dim'>    [C.circuit_desc]</span><br>"
		// TRIGGER GATES -- only shown when a circuit_board is installed in hardware
		var/datum/robot_hardware/circuit_board/ptcb = null
		for(var/slot in pending_hardware)
			var/datum/robot_hardware/hw = pending_hardware[slot]
			if(istype(hw, /datum/robot_hardware/circuit_board))
				ptcb = hw
				break
		if(ptcb && ptcb.nodes.len)
			dat += "<br>TRIGGER GATES  <span class='dim'>// wire a board node output to gate a trigger's responses</span><br>"
			var/trig_idx = 0
			for(var/datum/behavior_circuit/C in A.circuits)
				if(!istype(C, /datum/behavior_circuit/trigger))
					continue
				trig_idx++
				var/datum/behavior_circuit/trigger/TR = C
				dat += "<span class='dim'>[TR.circuit_name]</span>  "
				if(TR.board_gate_node_idx > 0 && TR.board_gate_node_idx <= ptcb.nodes.len)
					var/datum/circuit_node/GN = ptcb.nodes[TR.board_gate_node_idx]
					dat += "<span class='good'>gate: [GN.node_name].[TR.board_gate_output]</span>"
					dat += "  <a href='byond://?src=[REF(src)];prog_clear_gate=[trig_idx]'>\[clear\]</a>"
				else
					dat += "<span class='dim'>no gate</span>"
					// Build picker: list all node outputs available
					var/list/gate_links = list()
					for(var/ni in 1 to ptcb.nodes.len)
						var/datum/circuit_node/N = ptcb.nodes[ni]
						for(var/outp in N.outputs)
							gate_links += "<a href='byond://?src=[REF(src)];prog_set_gate=[trig_idx]:[ni]:[outp]'>[N.node_name].[outp]</a>"
					if(gate_links.len)
						dat += "  set: " + gate_links.Join("  ")
				dat += "<br>"
		// LOGIC CORE CONDITIONS -- shown when a logic_core is in pending_hardware
		var/datum/robot_hardware/logic_core/ptlc = null
		for(var/slot in pending_hardware)
			var/datum/robot_hardware/hw = pending_hardware[slot]
			if(istype(hw, /datum/robot_hardware/logic_core))
				ptlc = hw
				break
		if(ptlc)
			var/mode_other = ptlc.condition_mode == "AND" ? "OR" : "AND"
			dat += "<br>LOGIC CORE CONDITIONS  <span class='dim'>// global gate on all triggers — mode: <a href='byond://?src=[REF(src)];lc_set_mode=[mode_other]'>[ptlc.condition_mode]</a>  ([ptlc.conditions.len]/[ptlc.max_conditions])</span><br>"
			if(ptlc.conditions.len)
				var/ci = 0
				for(var/list/cond in ptlc.conditions)
					ci++
					dat += "<span class='good'>  [cond[1]] [cond[2]] [cond[3]]</span>"
					dat += "  <a href='byond://?src=[REF(src)];lc_remove_cond=[ci]'>\[remove\]</a><br>"
			else
				dat += "<span class='dim'>  (none — all triggers pass unconditionally)</span><br>"
			if(ptlc.conditions.len < ptlc.max_conditions)
				dat += "  add: "
				var/list/_lc_vars = list("health", "max_health", "health_pct", "enemy_count", "world_time")
				for(var/v in _lc_vars)
					if(v == lc_build_var)
						dat += "<span class='good'>[v]</span>  "
					else
						dat += "<a href='byond://?src=[REF(src)];lc_set_bvar=[v]'>[v]</a>  "
				dat += "  "
				var/list/_lc_ops = list("<", ">", "==", "!=", ">=", "<=")
				for(var/i in 1 to _lc_ops.len)
					var/op = _lc_ops[i]
					if(op == lc_build_op)
						dat += "<span class='good'>[op]</span>  "
					else
						dat += "<a href='byond://?src=[REF(src)];lc_set_bop=[i]'>[op]</a>  "
				dat += "  <span class='good'>[lc_build_val]</span>"
				dat += "  <a href='byond://?src=[REF(src)];lc_set_bval=1'>\[set val\]</a>"
				dat += "  <a href='byond://?src=[REF(src)];lc_add_cond=1'>\[+ add\]</a><br>"
		dat += "<a href='byond://?src=[REF(src)];eject_assembly=1'>\[Eject assembly\]</a><br>"
	else
		dat += "<span class='dim'>No assembly queued. Insert a behavior_assembly item into the machine.</span><br>"
		dat += "<span class='dim'>Assemblies are printed at the CPU Cert Fabricator.</span><br>"
		dat += "<br><span class='dim'>Building without an assembly produces a basic NPC robot using its default module behaviors.</span><br>"

	dat += "<br>CERT CARD  <span class='dim'>// defines robot C.O.R.E. stats (Compute/Operations/Resilience/Energy), upgrade slots, and capability tier</span><br>"
	if(robot_cert)
		dat += "<span class='good'>&gt; [robot_cert.name]</span>"
		dat += "  <a href='byond://?src=[REF(src)];eject_robot_cert=1'>\[eject\]</a><br>"
	else
		dat += "<span class='dim'>None — robot will receive a Standard cert at spawn (C5/O5/R5/E5, 3 upgrade slots).</span><br>"
		dat += "<span class='dim'>Print a cert card at the CPU Cert Fabricator and insert it here to override.</span><br>"
		dat += "<span class='dim'>Combat cert unlocks combat behaviors. Medical unlocks repair. Engineering unlocks machine interfaces.</span><br>"

	return dat


// ====================================================
// FINALIZE TAB
// ====================================================

/obj/machinery/robot_workshop/proc/_render_finalize(mob/user)
	var/dat = ""
	dat += "BUILD SUMMARY<br><br>"

	// Validate
	var/list/errors = _validate_build(user)

	// Plain-English summary of what the player is building
	if(selected_design)
		var/datum/robot_build_design/D0 = _get_design(selected_design)
		if(D0)
			var/asm_clause = behavior_assembly ? "running [behavior_assembly.assembly_label]" : "no behavior assembly (NPC default)"
			dat += "<span class='good'>// You are building a [D0.design_name] — [asm_clause].</span><br>"
			// Assembly danger warning for chassis that really need one
			if(D0.design_needs_assembly && !behavior_assembly)
				dat += "<span class='bad'>! WARNING: [D0.design_name] without an assembly is uncontrolled and dangerous. Slot a behavior assembly in the Programs tab before finalizing.</span><br>"
			dat += "<br>"

	dat += "Chassis:  "
	if(chassis)
		dat += "<span class='good'>[chassis.name]</span><br>"
	else
		dat += "<span class='dim'>None (optional)</span><br>"

	// Module
	dat += "Module:   "
	if(selected_design)
		var/datum/robot_build_design/Dm = _get_design(selected_design)
		dat += "<span class='good'>[Dm.design_name]</span>  <span class='dim'>(T[Dm.tier])</span><br>"
		var/persona = initial(Dm.module_type:personality_name)
		if(persona)
			dat += "<span class='dim'>Personality: [persona]</span><br>"
	else
		dat += "<span class='warn'>NOT SELECTED</span><br>"

	// Assembly
	dat += "Assembly: "
	if(behavior_assembly)
		dat += "<span class='good'>[behavior_assembly.assembly_label]</span><br>"
	else
		dat += "<span class='dim'>None (NPC default behavior)</span><br>"

	// Cert
	dat += "Cert:     "
	if(robot_cert)
		dat += "<span class='good'>[robot_cert.name]</span><br>"
	else
		dat += "<span class='dim'>Auto-assigned</span><br>"

	// Hardware summary
	var/list/hw_warns = _get_hw_warnings()
	dat += "Hardware: "
	if(pending_hardware.len)
		dat += "<span class='good'>[pending_hardware.len] configured</span>"
	else
		dat += "<span class='dim'>none configured</span>"
	dat += "<br>"
	if(hw_warns.len)
		for(var/w in hw_warns)
			dat += "<span class='warn'>  ! [w]</span><br>"

	// Material cost
	if(selected_design)
		var/datum/robot_build_design/D2 = _get_design(selected_design)
		if(D2)
			dat += "<br>MATERIAL COST<br>"
			for(var/mat in D2.mat_cost)
				var/cost = D2.mat_cost[mat]
				var/have = materials[mat]
				var/ok = have >= cost
				var/mat_class = ok ? "good" : "bad"
				dat += "<span class='[mat_class]'>[uppertext(mat)]: [cost]</span>  "
				dat += "<span class='dim'>(stored: [have])</span><br>"

	// Control mode
	dat += "<br>PLAYER CONTROL<br>"
	dat += "<span class='dim'>Mode: </span>"
	switch(control_mode)
		if("npc")
			dat += "<span class='good'>NPC ONLY</span>"
			dat += "  <span class='dim'>// robot runs on its module's built-in AI; no player inhabitation</span>"
			dat += "  <a href='byond://?src=[REF(src)];set_control=open'>\[allow players\]</a>"
			dat += "  <a href='byond://?src=[REF(src)];set_control=locked'>\[lock to ckey\]</a>"
		if("open")
			dat += "<span class='good'>OPEN -- any ghost can inhabit</span>"
			dat += "  <a href='byond://?src=[REF(src)];set_control=npc'>\[NPC only\]</a>"
			dat += "  <a href='byond://?src=[REF(src)];set_control=locked'>\[lock to ckey\]</a>"
		if("locked")
			dat += "<span class='good'>LOCKED -- [locked_ckey ? locked_ckey : "(no ckey set)"]</span>"
			dat += "  <a href='byond://?src=[REF(src)];set_ckey=1'>\[set ckey\]</a>"
			dat += "  <a href='byond://?src=[REF(src)];set_control=npc'>\[NPC only\]</a>"
	dat += "<br>"
	dat += "<span class='dim'>// Assemblies fire on ALL robots regardless of player control.</span><br>"

	dat += "<br>"
	if(building)
		dat += "<span class='warn'>&gt; FABRICATING -- please wait...</span><br>"
	else if(errors.len)
		dat += "CANNOT BUILD<br>"
		for(var/e in errors)
			dat += "<span class='bad'>  ! [e]</span><br>"
	else
		dat += "<a href='byond://?src=[REF(src)];build_robot=1'>&gt; FABRICATE ROBOT</a><br>"

	return dat


// ====================================================
// TOPIC -- handle href clicks
// ====================================================

/obj/machinery/robot_workshop/Topic(href, list/href_list)
	. = ..(  )
	if(!HAS_TRAIT(usr, TRAIT_ROBOT_WHISPERER))
		return
	if(!usr.Adjacent(src))
		return

	if(href_list["set_mode"])
		ui_mode = text2num(href_list["set_mode"])
		ui_interact(usr)
		return

	if(href_list["select_design"])
		var/val = href_list["select_design"]
		if(val == "clear")
			selected_design = null
			for(var/slot in pending_hardware)
				var/datum/robot_hardware/HW = pending_hardware[slot]
				if(HW) qdel(HW)
			pending_hardware = list()
			pending_loadout_swaps = list()
			pending_loadout_adds = list()
			loadout_pick_idx = null
		else
			var/path = text2path(val)
			if(_get_design(path))
				if(selected_design != path)
					pending_loadout_swaps = list()
					pending_loadout_adds = list()
					loadout_pick_idx = null
				selected_design = path
		ui_interact(usr)
		return

	if(href_list["eject_chassis"])
		if(chassis)
			chassis.forceMove(get_turf(src))
			chassis = null
			to_chat(usr, span_notice("Chassis ejected."))
		ui_interact(usr)
		return

	if(href_list["eject_assembly"])
		if(behavior_assembly)
			behavior_assembly.forceMove(get_turf(src))
			behavior_assembly = null
			to_chat(usr, span_notice("Assembly ejected."))
		ui_interact(usr)
		return

	if(href_list["eject_robot_cert"])
		if(robot_cert)
			robot_cert.forceMove(get_turf(src))
			robot_cert = null
			to_chat(usr, span_notice("Cert card ejected."))
		ui_interact(usr)
		return

	if(href_list["eject_mats"])
		for(var/mat in materials)
			var/amt = materials[mat]
			if(amt > 0)
				var/mat_path = _mat_path_from_key(mat)
				if(mat_path)
					var/sheets = round(amt / 2000)
					if(sheets > 0)
						new mat_path(get_turf(src), sheets)
					materials[mat] = 0
		to_chat(usr, span_notice("All materials ejected."))
		ui_interact(usr)
		return

	if(href_list["eject_mat"])
		var/mkey = href_list["eject_mat"]
		if(mkey in materials)
			var/amt = materials[mkey]
			if(amt > 0)
				var/mat_path = _mat_path_from_key(mkey)
				if(mat_path)
					var/sheets = round(amt / 2000)
					if(sheets > 0)
						new mat_path(get_turf(src), sheets)
					materials[mkey] = 0
					to_chat(usr, span_notice("[sheets] sheet\s of [mkey] ejected."))
		ui_interact(usr)
		return

	if(href_list["eject_tier_cert"])
		var/obj/item/cert_card/CC = locate(href_list["eject_tier_cert"]) in installed_certs
		if(CC)
			installed_certs -= CC
			CC.forceMove(get_turf(src))
			_recalculate_tier()
			to_chat(usr, span_notice("Workshop cert ejected. Tier recalculated."))
		ui_interact(usr)
		return

	if(href_list["set_control"])
		control_mode = href_list["set_control"]
		ui_interact(usr)
		return

	if(href_list["set_ckey"])
		var/new_ckey = stripped_input(usr, "Enter ckey to lock robot control to:", "Lock Control", locked_ckey)
		if(new_ckey)
			locked_ckey = new_ckey
			control_mode = "locked"
		ui_interact(usr)
		return

	if(href_list["build_robot"])
		_build_robot(usr)
		ui_interact(usr)
		return

	// ---- HARDWARE OVERVIEW ACTIONS ----

	if(href_list["hw_use_recommended"])
		_hw_apply_recommended(usr)
		ui_interact(usr)
		return

	if(href_list["hw_clear_all"])
		pending_hardware = list()
		ui_interact(usr)
		return

	// ?? Loadout item swap handlers ????????????????????????????????????????????
	if(href_list["loadout_pick"])
		loadout_pick_idx = href_list["loadout_pick"]
		ui_interact(usr)
		return

	if(href_list["loadout_pick_cancel"])
		loadout_pick_idx = null
		ui_interact(usr)
		return

	if(href_list["loadout_swap_set"])
		var/idx_key = href_list["loadout_swap_set"]
		var/swap_path = text2path(url_decode(href_list["loadout_swap_type"]))
		if(idx_key && swap_path)
			if(!pending_loadout_swaps) pending_loadout_swaps = list()
			pending_loadout_swaps[idx_key] = swap_path
		loadout_pick_idx = null
		ui_interact(usr)
		return

	if(href_list["loadout_swap_clear"])
		var/idx_key = href_list["loadout_swap_clear"]
		if(pending_loadout_swaps && (idx_key in pending_loadout_swaps))
			pending_loadout_swaps.Remove(idx_key)
		ui_interact(usr)
		return

	if(href_list["loadout_add_toggle"])
		var/add_path = text2path(url_decode(href_list["loadout_add_toggle"]))
		if(add_path)
			if(add_path in pending_loadout_adds)
				pending_loadout_adds -= add_path
			else
				pending_loadout_adds += add_path
		ui_interact(usr)
		return

	// ?? Hardware IC topic handlers ?????????????????????????????????????????????

	if(href_list["hw_pick"])
		hw_active_slot = href_list["hw_pick"]
		hw_pending_type = null
		hw_pending_config = list()
		hw_mode = "pick"
		ui_interact(usr)
		return

	if(href_list["hw_configure"])
		var/slot = href_list["hw_configure"]
		var/datum/robot_hardware/HW = pending_hardware[slot]
		if(HW)
			hw_active_slot = slot
			hw_pending_type = HW.type
			// Copy existing config into pending; deep-copy lists so edits don't alias the installed datum
			hw_pending_config = list()
			for(var/varname in HW.config_defs)
				var/val = HW.vars[varname]
				if(islist(val))
					var/list/lval = val
					hw_pending_config[varname] = lval.Copy()
				else
					hw_pending_config[varname] = val
			hw_mode = "config"
		ui_interact(usr)
		return

	if(href_list["hw_remove"])
		var/slot = href_list["hw_remove"]
		if(slot in pending_hardware)
			var/datum/robot_hardware/HW = pending_hardware[slot]
			if(HW) qdel(HW)
			pending_hardware.Remove(slot)
		ui_interact(usr)
		return

	if(href_list["hw_add_optional"])
		hw_active_slot = "Optional [pending_hardware.len + 1]"
		hw_pending_type = null
		hw_pending_config = list()
		hw_mode = "pick"
		ui_interact(usr)
		return

	if(href_list["hw_circuit_edit"])
		hw_circuit_slot = href_list["hw_circuit_edit"]
		hw_mode = "circuit"
		hw_connect_from = null
		ui_interact(usr)
		return

	// ---- HARDWARE PICKER ACTIONS ----

	if(href_list["hw_cancel_pick"])
		hw_mode = null
		hw_active_slot = null
		ui_interact(usr)
		return

	if(href_list["hw_select_type"])
		var/path = text2path(href_list["hw_select_type"])
		if(ispath(path, /datum/robot_hardware))
			hw_pending_type = path
			hw_pending_config = list()
			// Seed config with defaults from config_defs
			var/datum/robot_hardware/proto = new path()
			for(var/varname in proto.config_defs)
				var/list/def = proto.config_defs[varname]
				var/dtype = def[2]
				// waypoint_list always starts with a fresh empty list to avoid sharing the template reference
				if(dtype == "waypoint_list")
					hw_pending_config[varname] = list()
				else
					hw_pending_config[varname] = def[3]
			qdel(proto)
			hw_mode = "config"
		ui_interact(usr)
		return

	// ---- HARDWARE CONFIGURATOR ACTIONS ----

	if(href_list["hw_back_to_pick"])
		hw_pending_type = null
		hw_pending_config = list()
		hw_mode = "pick"
		ui_interact(usr)
		return

	// ---- WAYPOINT EDITOR ACTIONS (nav_computer) ----

	if(href_list["hw_wp_add"])
		if(hw_pending_type && ispath(hw_pending_type, /datum/robot_hardware/nav_computer))
			var/max_wp = hw_pending_config["max_waypoints"] != null ? hw_pending_config["max_waypoints"] : 5
			if(!islist(hw_pending_config["waypoints"]))
				hw_pending_config["waypoints"] = list()
			var/list/wps_add = hw_pending_config["waypoints"]
			if(wps_add.len < max_wp)
				var/new_x = input(usr, "Enter X coordinate for the new waypoint:", "Waypoint X") as null|num
				if(!isnull(new_x))
					var/new_y = input(usr, "Enter Y coordinate for the new waypoint:", "Waypoint Y") as null|num
					if(!isnull(new_y))
						wps_add += list(list(new_x, new_y))
		ui_interact(usr)
		return

	if(href_list["hw_wp_remove"])
		if(hw_pending_type && islist(hw_pending_config["waypoints"]))
			var/list/wps_rem = hw_pending_config["waypoints"]
			var/idx = text2num(href_list["hw_wp_remove"])
			if(idx >= 1 && idx <= wps_rem.len)
				wps_rem.Cut(idx, idx + 1)
		ui_interact(usr)
		return

	if(href_list["hw_edit_var"])
		var/varname = href_list["hw_edit_var"]
		if(hw_pending_type && (varname in hw_pending_config))
			var/datum/robot_hardware/proto = new hw_pending_type()
			if(varname in proto.config_defs)
				var/list/def = proto.config_defs[varname]
				var/dtype = def[2]
				var/new_val
				if(dtype == "number")
					new_val = input(usr, "Enter value for [def[1]]:", "[def[1]]", hw_pending_config[varname]) as null|num
				else if(dtype == "list")
					new_val = input(usr, "Enter value for [def[1]]:", "[def[1]]", hw_pending_config[varname]) as null|text
				else
					new_val = input(usr, "Enter value for [def[1]]:", "[def[1]]", hw_pending_config[varname]) as null|text
				if(!isnull(new_val))
					hw_pending_config[varname] = new_val
			qdel(proto)
		ui_interact(usr)
		return

	if(href_list["hw_toggle_var"])
		var/varname = href_list["hw_toggle_var"]
		if(varname in hw_pending_config)
			hw_pending_config[varname] = !hw_pending_config[varname]
		ui_interact(usr)
		return

	if(href_list["hw_confirm"])
		_hw_confirm_slot(usr)
		ui_interact(usr)
		return

	// ---- CIRCUIT EDITOR ACTIONS ----

	if(href_list["hw_circuit_done"])
		hw_mode = null
		hw_circuit_slot = null
		hw_connect_from = null
		ui_interact(usr)
		return

	if(href_list["ce_add_node"])
		var/datum/robot_hardware/circuit_board/CB = pending_hardware[hw_circuit_slot]
		if(CB && istype(CB, /datum/robot_hardware/circuit_board))
			var/path = text2path(href_list["ce_add_node"])
			if(ispath(path, /datum/circuit_node))
				CB.add_node(path)
		ui_interact(usr)
		return

	if(href_list["ce_remove_node"])
		var/datum/robot_hardware/circuit_board/CB = pending_hardware[hw_circuit_slot]
		if(CB && istype(CB, /datum/robot_hardware/circuit_board))
			var/idx = text2num(href_list["ce_remove_node"])
			if(idx >= 1 && idx <= CB.nodes.len)
				CB.remove_node(CB.nodes[idx])
		hw_connect_from = null
		ui_interact(usr)
		return

	if(href_list["ce_connect_from"])
		var/list/parts = splittext(href_list["ce_connect_from"], ":")
		if(parts.len == 2)
			hw_connect_from = list(text2num(parts[1]), parts[2])
		ui_interact(usr)
		return

	if(href_list["ce_cancel_connect"])
		hw_connect_from = null
		ui_interact(usr)
		return

	if(href_list["ce_connect_to"])
		var/datum/robot_hardware/circuit_board/CB = pending_hardware[hw_circuit_slot]
		if(CB && istype(CB, /datum/robot_hardware/circuit_board) && hw_connect_from)
			var/list/parts = splittext(href_list["ce_connect_to"], ":")
			if(parts.len == 2)
				var/from_idx  = hw_connect_from[1]
				var/from_out  = hw_connect_from[2]
				var/to_idx    = text2num(parts[1])
				var/to_inp    = parts[2]
				if(from_idx >= 1 && from_idx <= CB.nodes.len && to_idx >= 1 && to_idx <= CB.nodes.len)
					CB.connect(CB.nodes[from_idx], from_out, CB.nodes[to_idx], to_inp)
		hw_connect_from = null
		ui_interact(usr)
		return

	if(href_list["ce_disconnect"])
		var/datum/robot_hardware/circuit_board/CB = pending_hardware[hw_circuit_slot]
		if(CB && istype(CB, /datum/robot_hardware/circuit_board))
			var/ci = text2num(href_list["ce_disconnect"])
			if(ci >= 1 && ci <= CB.connections.len)
				CB.connections.Cut(ci, ci+1)
		ui_interact(usr)
		return

	if(href_list["ce_evaluate"])
		var/datum/robot_hardware/circuit_board/CB = pending_hardware[hw_circuit_slot]
		if(CB && istype(CB, /datum/robot_hardware/circuit_board))
			CB.evaluate()
		ui_interact(usr)
		return

	if(href_list["ce_edit_node"])
		var/datum/robot_hardware/circuit_board/CB = pending_hardware[hw_circuit_slot]
		if(CB && istype(CB, /datum/robot_hardware/circuit_board))
			var/list/parts = splittext(href_list["ce_edit_node"], ":")
			if(parts.len == 2)
				var/idx = text2num(parts[1])
				var/varname = parts[2]
				if(idx >= 1 && idx <= CB.nodes.len)
					var/datum/circuit_node/N = CB.nodes[idx]
					if(varname in N.config_defs)
						var/list/def = N.config_defs[varname]
						var/new_val = input(usr, "Set [def[1]] on [N.node_name]:", def[1], N.vars[varname]) as null|text
						if(!isnull(new_val))
							if(def[2] == "number") N.vars[varname] = text2num(new_val) || 0
							else N.vars[varname] = new_val
		ui_interact(usr)
		return

	if(href_list["ce_toggle_node"])
		var/datum/robot_hardware/circuit_board/CB = pending_hardware[hw_circuit_slot]
		if(CB && istype(CB, /datum/robot_hardware/circuit_board))
			var/list/parts = splittext(href_list["ce_toggle_node"], ":")
			if(parts.len == 2)
				var/idx = text2num(parts[1])
				var/varname = parts[2]
				if(idx >= 1 && idx <= CB.nodes.len)
					var/datum/circuit_node/N = CB.nodes[idx]
					N.vars[varname] = !N.vars[varname]
		ui_interact(usr)
		return

	// ---- TRIGGER GATE HANDLERS ----
	// prog_set_gate=trig_idx:node_idx:output_name
	// Wires a circuit_board node output to gate a trigger's responses.

	if(href_list["prog_set_gate"])
		if(!behavior_assembly)
			return
		var/list/parts = splittext(href_list["prog_set_gate"], ":")
		if(parts.len == 3)
			var/trig_target = text2num(parts[1])
			var/node_idx    = text2num(parts[2])
			var/outp_name   = parts[3]
			// Validate the node and output against the pending circuit_board
			var/datum/robot_hardware/circuit_board/CB = null
			for(var/slot in pending_hardware)
				var/datum/robot_hardware/hw = pending_hardware[slot]
				if(istype(hw, /datum/robot_hardware/circuit_board))
					CB = hw
					break
			if(CB && node_idx >= 1 && node_idx <= CB.nodes.len)
				var/datum/circuit_node/GN = CB.nodes[node_idx]
				if(outp_name in GN.outputs)
					var/trig_count = 0
					for(var/datum/behavior_circuit/C in behavior_assembly.circuits)
						if(!istype(C, /datum/behavior_circuit/trigger))
							continue
						trig_count++
						if(trig_count == trig_target)
							var/datum/behavior_circuit/trigger/TR = C
							TR.board_gate_node_idx = node_idx
							TR.board_gate_output   = outp_name
							break
		ui_interact(usr)
		return

	if(href_list["prog_clear_gate"])
		if(!behavior_assembly)
			return
		var/trig_target = text2num(href_list["prog_clear_gate"])
		var/trig_count  = 0
		for(var/datum/behavior_circuit/C in behavior_assembly.circuits)
			if(!istype(C, /datum/behavior_circuit/trigger))
				continue
			trig_count++
			if(trig_count == trig_target)
				var/datum/behavior_circuit/trigger/TR = C
				TR.board_gate_node_idx = 0
				TR.board_gate_output   = "result"
				break
		ui_interact(usr)
		return


	// ---- LOGIC CORE CONDITION HANDLERS ----
	// Manage conditions list on a pending logic_core datum.
	// The datum is routed through live_hw_datums at build time so these
	// direct mutations to .conditions survive finalization.

	if(href_list["lc_set_mode"])
		var/datum/robot_hardware/logic_core/LC = null
		for(var/slot in pending_hardware)
			var/datum/robot_hardware/hw = pending_hardware[slot]
			if(istype(hw, /datum/robot_hardware/logic_core))
				LC = hw
				break
		if(LC)
			LC.condition_mode = (LC.condition_mode == "AND") ? "OR" : "AND"
		ui_interact(usr)
		return

	if(href_list["lc_set_bvar"])
		var/static/list/_lc_vars = list("health", "max_health", "health_pct", "enemy_count", "world_time")
		var/v = href_list["lc_set_bvar"]
		if(v in _lc_vars)
			lc_build_var = v
		ui_interact(usr)
		return

	if(href_list["lc_set_bop"])
		var/static/list/_lc_ops = list("<", ">", "==", "!=", ">=", "<=")
		var/idx = text2num(href_list["lc_set_bop"])
		if(isnum(idx) && idx >= 1 && idx <= _lc_ops.len)
			lc_build_op = _lc_ops[idx]
		ui_interact(usr)
		return

	if(href_list["lc_set_bval"])
		var/new_val = input(usr, "Enter comparison value:", "Condition Value", "[lc_build_val]") as null|text
		if(!isnull(new_val))
			lc_build_val = text2num(new_val) || 0
		ui_interact(usr)
		return

	if(href_list["lc_add_cond"])
		var/datum/robot_hardware/logic_core/LC = null
		for(var/slot in pending_hardware)
			var/datum/robot_hardware/hw = pending_hardware[slot]
			if(istype(hw, /datum/robot_hardware/logic_core))
				LC = hw
				break
		if(LC && LC.conditions.len < LC.max_conditions)
			var/static/list/_lc_vars = list("health", "max_health", "health_pct", "enemy_count", "world_time")
			var/static/list/_lc_ops = list("<", ">", "==", "!=", ">=", "<=")
			if((lc_build_var in _lc_vars) && (lc_build_op in _lc_ops))
				LC.conditions += list(list(lc_build_var, lc_build_op, lc_build_val))
		ui_interact(usr)
		return

	if(href_list["lc_remove_cond"])
		var/idx = text2num(href_list["lc_remove_cond"])
		var/datum/robot_hardware/logic_core/LC = null
		for(var/slot in pending_hardware)
			var/datum/robot_hardware/hw = pending_hardware[slot]
			if(istype(hw, /datum/robot_hardware/logic_core))
				LC = hw
				break
		if(LC && isnum(idx) && idx >= 1 && idx <= LC.conditions.len)
			LC.conditions.Cut(idx, idx + 1)
		ui_interact(usr)
		return


// ====================================================
// BUILDING
// ====================================================

/obj/machinery/robot_workshop/proc/_hw_confirm_slot(mob/living/user)
	if(!hw_pending_type || !hw_active_slot)
		return
	// Remove old datum in this slot if any
	var/datum/robot_hardware/old = pending_hardware[hw_active_slot]
	if(old) qdel(old)
	// Create new datum with pending config applied
	var/datum/robot_hardware/HW = new hw_pending_type()
	for(var/varname in hw_pending_config)
		if(varname in HW.config_defs)
			HW.vars[varname] = hw_pending_config[varname]
	pending_hardware[hw_active_slot] = HW
	// Reset picker state
	hw_mode = null
	hw_active_slot = null
	hw_pending_type = null
	hw_pending_config = list()


/obj/machinery/robot_workshop/proc/_hw_apply_recommended(mob/living/user)
	if(!selected_design)
		return
	// Clear existing pending hardware
	for(var/slot in pending_hardware)
		var/datum/robot_hardware/HW = pending_hardware[slot]
		if(HW) qdel(HW)
	pending_hardware = list()
	// Get recommended entries for this design
	var/list/recs = get_recommended_hardware(selected_design)
	if(!recs || !recs.len)
		to_chat(user, span_notice("No recommended hardware config for this robot type."))
		return
	// Instantiate each entry - use slot names matching assembly or auto-name
	var/list/asm_slots = _get_assembly_slot_keys()
	for(var/list/entry in recs)
		if(!islist(entry) || entry.len < 1) continue
		var/hw_type      = entry[1]
		var/list/config  = entry.len >= 2 ? entry[2] : list()
		// INT gate
		var/mob/living/carbon/human/H = istype(user, /mob/living/carbon/human) ? user : null
		var/datum/robot_hardware/test = new hw_type()
		var/gated = H && !check_int_gate(H, test)
		qdel(test)
		if(gated) continue
		// Create and configure
		var/datum/robot_hardware/HW = new hw_type()
		for(var/key in config)
			if(key in HW.config_defs)
				HW.vars[key] = config[key]
		// CORE budget check -- skip this entry if adding it would push over the cert limit
		var/list/hw_values_test = list()
		for(var/sk in pending_hardware)
			var/datum/robot_hardware/HWV = pending_hardware[sk]
			if(HWV) hw_values_test += HWV
		hw_values_test += HW
		var/datum/cpu_cert/budget_cert_test = robot_cert ? robot_cert.base_cert : new /datum/cpu_cert/robot()
		var/list/budget_errors = check_hardware_core_budget(hw_values_test, budget_cert_test)
		if(!robot_cert) qdel(budget_cert_test)
		if(budget_errors.len)
			qdel(HW)
			continue
		// Key optional hardware by its type path so it's stable and findable
		var/slot_key = "[hw_type]"
		// If the assembly has a slot that expects this exact hardware type, use that
		for(var/sk in asm_slots)
			if(sk in pending_hardware) continue
			var/required = text2path(sk)
			if(required && ispath(hw_type, required))
				slot_key = sk
				break
		pending_hardware[slot_key] = HW
	var/design_label = "this robot"
	if(selected_design)
		var/datum/robot_build_design/D = _get_design(selected_design)
		if(D) design_label = D.design_name
	to_chat(user, span_notice("Recommended hardware loaded for [design_label]."))


/obj/machinery/robot_workshop/proc/_build_robot(mob/living/user)
	if(building)
		to_chat(user, span_warning("Already fabricating."))
		return

	var/list/errors = _validate_build(user)
	if(errors.len)
		to_chat(user, span_warning("Build errors: [errors[1]]"))
		return

	var/datum/robot_build_design/D = _get_design(selected_design)

	// Spend materials -- apply LCK discount if builder is present
	var/mob/living/carbon/human/snap_builder = istype(user, /mob/living/carbon/human) ? user : null
	var/lck_discount_pct = snap_builder ? get_workshop_lck_discount(snap_builder) : 0
	for(var/mat in D.mat_cost)
		var/final_cost = round(D.mat_cost[mat] * (1 - lck_discount_pct / 100))
		materials[mat] -= final_cost

	building = TRUE
	icon_state = "h_lathe_load"
	use_power(active_power_usage * 20)

	// Snapshot state before addtimer
	var/snap_design   = selected_design
	var/snap_control  = control_mode
	var/snap_ckey     = locked_ckey
	var/obj/item/behavior_assembly/snap_assembly = behavior_assembly
	var/obj/item/cert_card/snap_cert             = robot_cert
	var/obj/item/robot_suit/snap_chassis         = chassis
	var/list/snap_hw                             = pending_hardware.Copy()
	var/list/snap_loadout                        = pending_loadout_swaps.Copy()
	var/list/snap_adds                           = pending_loadout_adds.Copy()
	var/turf/T                                   = get_turf(src)
	var/builder_ckey                             = key_name(user)

	// Clear workshop state immediately so slots are free
	behavior_assembly = null
	robot_cert        = null
	chassis           = null
	pending_hardware  = list()
	pending_loadout_swaps = list()
	pending_loadout_adds  = list()
	loadout_pick_idx  = null
	selected_design   = null

	addtimer(CALLBACK(src, PROC_REF(_set_working_anim)), 10, TIMER_UNIQUE|TIMER_OVERRIDE)
	addtimer(CALLBACK(src, PROC_REF(_finish_robot),
		snap_design, snap_control, snap_ckey,
		snap_assembly, snap_cert, snap_chassis,
		snap_hw, snap_loadout, snap_adds, T, builder_ckey, snap_builder), 50, TIMER_UNIQUE|TIMER_OVERRIDE)



/obj/machinery/robot_workshop/proc/_set_working_anim()
	if(building)
		icon_state = "h_lathe_wloop"

/obj/machinery/robot_workshop/proc/_finish_robot(
	design_path, control_mode_snap, ckey_snap,
	obj/item/behavior_assembly/A,
	obj/item/cert_card/CC,
	obj/item/robot_suit/suit,
	list/hw_snap, list/loadout_snap, list/adds_snap, turf/T, builder_ckey,
	mob/living/carbon/human/builder)

	building = FALSE
	icon_state = "h_lathe"

	var/datum/robot_build_design/D = _get_design(design_path)
	if(!D)
		visible_message(span_warning("[src]: fabrication failed -- design lost."))
		return

	// Spawn robot mob
	var/mob/living/silicon/robot/R = new D.mob_type(T)

	// Apply robot suit / chassis
	if(suit)
		R.robot_suit = suit
		suit.forceMove(R)

	// Set module
	if(R.module)
		qdel(R.module)
	R.module = new D.module_type(R)

	// Build hardware entry list from what the player explicitly configured.
	// Recommended hardware is only used to pre-populate the HARDWARE tab UI --
	// it is never silently installed. If the player didn't touch the HARDWARE tab,
	// hw_snap is empty and the robot gets no hardware (just its basic_modules items).
	//
	// circuit_board is a special case: its node graph (nodes list + connections list)
	// lives on the datum itself and is NOT serializable through config_defs. We pass
	// the live datum directly so the node graph survives finalization intact.
	// The datum is transferred out of pending_hardware so it won't get qdel'd when
	// the workshop clears its state.
	var/list/hw_entries = list()
	/// Carry live circuit_board datums separately so they bypass the type+config path.
	var/list/live_hw_datums = list()
	if(hw_snap && hw_snap.len)
		for(var/slot in hw_snap)
			var/datum/robot_hardware/custom = hw_snap[slot]
			if(!custom) continue
			if(istype(custom, /datum/robot_hardware/circuit_board) || istype(custom, /datum/robot_hardware/logic_core))
				// Hand this datum off directly -- runtime state (node graph / conditions list)
				// is not serializable through config_defs and must survive as-is.
				live_hw_datums += custom
				continue
			// Standard path: snapshot config vars so a fresh datum can be built.
			var/list/config = list()
			for(var/key in custom.config_defs)
				config[key] = custom.vars[key]
			hw_entries += list(list(custom.type, config))

	// Clock hardware is always installed as the base heartbeat for behavior circuits.
	// Without it, On Clock Tick triggers never fire regardless of assembly configuration.
	// Merge into hw_entries only if the player didn't already configure clock hardware.
	var/clock_already_configured = FALSE
	for(var/list/entry in hw_entries)
		if(entry[1] == /datum/robot_hardware/clock || ispath(entry[1], /datum/robot_hardware/clock))
			clock_already_configured = TRUE
			break
	if(!clock_already_configured)
		hw_entries += list(list(/datum/robot_hardware/clock, list("tick_interval" = 20)))

	// Install hardware and rebuild module item list.
	// rebuild_modules() is called unconditionally after so basic_modules items always load
	// even when the player picked no hardware.
	instantiate_hardware_list(hw_entries, R, builder)

	// Install live circuit_board datums directly (their node graphs can't round-trip through
	// the type+config snapshot). Apply SPECIAL and install in the same fashion as
	// instantiate_hardware_list does for normal hardware.
	if(live_hw_datums.len)
		var/list/special_snap = builder ? list(
			"STR" = builder.special_s,
			"PER" = builder.special_p,
			"END" = builder.special_e,
			"CHA" = builder.special_c,
			"INT" = builder.special_i,
			"AGI" = builder.special_a,
			"LCK" = builder.special_l
		) : list()
		for(var/datum/robot_hardware/H in live_hw_datums)
			if(builder && !check_int_gate(builder, H))
				continue
			H.apply_special(special_snap)
			H.install(R)

	if(R.module)
		R.module.rebuild_modules()

	// Apply player-selected loadout item swaps.
	// loadout_snap is assoc: "1" -> /obj/item/gun/... etc.
	// Index corresponds to position in basic_modules at build time.
	if(loadout_snap && loadout_snap.len && R.module)
		var/list/bm = R.module.basic_modules
		if(bm && bm.len)
			for(var/idx_key in loadout_snap)
				var/idx = text2num(idx_key)
				if(!idx || idx < 1 || idx > bm.len) continue
				var/swap_path = loadout_snap[idx_key]
				if(!swap_path || !ispath(swap_path)) continue
				var/obj/item/old_item = bm[idx]
				if(!old_item) continue
				// Verify type compatibility (swap_path must be same parent as old_item)
				if(!ispath(swap_path, old_item.type) && !istype(old_item, swap_path))
					// Also allow sibling types (same grandparent)
					var/compatible = FALSE
					for(var/ancestor in typesof(old_item.type))
						if(ispath(swap_path, ancestor)) { compatible = TRUE; break }
					if(!compatible) continue
				bm -= old_item
				qdel(old_item)
				var/obj/item/new_item = new swap_path(R.module)
				bm.Insert(idx, new_item)
			R.module.rebuild_modules()

	// Apply player-toggled addable items from loadout_extras.
	// adds_snap is a list of item type paths to append to basic_modules.
	if(adds_snap && adds_snap.len && R.module)
		for(var/add_path in adds_snap)
			if(!add_path || !ispath(add_path)) continue
			var/obj/item/new_add = new add_path(R.module)
			R.module.basic_modules += new_add
		R.module.rebuild_modules()

	if(CC && CC.base_cert)
		R.cpu_cert = CC.base_cert
		CC.base_cert = null
		R.cpu_cert.apply_to_holder(R)
		qdel(CC)
	else if(!R.cpu_cert)
		R.cpu_cert = new /datum/cpu_cert/robot()
		R.cpu_cert.apply_to_holder(R)

	// Install behavior assembly
	if(A)
		// Final cert_compatible gate -- _validate_build already blocked incompatible
		// assemblies, but re-check here in case cert was swapped or path bypassed.
		if(!A.cert_compatible(R.cpu_cert))
			A.forceMove(T)
			visible_message(span_warning("[src]: assembly '[A.assembly_label]' is not compatible with installed cert. Assembly dropped."))
			log_game("[builder_ckey] tried to build [R.name] with incompatible assembly '[A.assembly_label]' -- dropped at [AREACOORD(T)]")
		else
			A.assembly_override = TRUE  // assemblies always fire on workshop robots
			A.forceMove(R)
			var/datum/cert_upgrade/robot/behavior_assembly/U = new()
			U.assembly = A
			if(R.cpu_cert.can_install_upgrade(U))
				// install_upgrade calls on_apply -> assembly.register_signals(R)
				// which calls C.register(R, A) on every circuit.
				R.cpu_cert.install_upgrade(U, R)
			else
				// Cert full -- drop assembly at feet with a warning
				A.assembly_override = FALSE
				A.forceMove(T)
				U.assembly = null
				qdel(U)
				visible_message(span_warning("[src]: assembly could not be installed -- cert slots full. Assembly dropped."))

	// Player control mode
	switch(control_mode_snap)
		if("npc")
			// Pure NPC -- no player control needed. Remove the MMI the base robot
			// Initialize() auto-created so vanilla Destroy() doesn't runtime on a brainless MMI.
			if(R.mmi)
				qdel(R.mmi)
				R.mmi = null
			R.mind = null
		if("open")
			// Anyone can ghost in -- attack_ghost on the robot handles entry
			if(!R.mmi)
				R.mmi = new(R)
			R.player_robot_control = "open"
		if("locked")
			// Only the specified ckey can enter
			if(!R.mmi)
				R.mmi = new(R)
			R.player_robot_control = "locked"
			if(ckey_snap)
				R.player_robot_ckey = ckey_snap

	// Cosmetics
	R.name = "[D.design_name]-[rand(100,999)]"
	R.real_name = R.name
	R.maxHealth = D.display_health
	R.health = D.display_health
	if(R.module)  // guard: update_icons() reads R.module.cyborg_base_icon - must not be null
		R.update_icons()

	log_game("[builder_ckey] built [R.name] ([D.design_name], T[D.tier]) at [AREACOORD(T)]")
	visible_message(span_notice("[src] finishes fabricating: <b>[R.name]</b>."))
	playsound(T, 'sound/machines/ding.ogg', 75, 1)

	// Ghost notifications for player-inhabitable robots
	if(control_mode_snap == "open")
		notify_ghosts("[R.name] ([D.design_name]) is ready for inhabitation in [get_area(R)]!", source = R, action = NOTIFY_ATTACK, flashwindow = FALSE, ignore_dnr_observers = TRUE)
	else if(control_mode_snap == "locked" && ckey_snap)
		for(var/client/C in GLOB.clients)
			if(C.ckey == ckey_snap)
				to_chat(C, span_ghostalert("[R.name] ([D.design_name]) has been built for you in [get_area(R)]. Click the robot to inhabit it."))
				break


// ====================================================
// CERT CARD INSTALLATION (tier upgrades)
// ====================================================

/obj/machinery/robot_workshop/proc/_try_install_workshop_cert(obj/item/cert_card/CC, mob/user)
	// We look for a special base_cert subtype that carries a workshop tier datum
	if(!CC.base_cert)
		to_chat(user, span_warning("This cert card doesn't carry a valid workshop certification."))
		return
	if(!istype(CC.base_cert, /datum/cpu_cert/workshop))
		to_chat(user, span_warning("This is a robot cert, not a workshop upgrade cert."))
		return
	var/datum/cpu_cert/workshop/WC = CC.base_cert
	// Check for duplicates
	for(var/obj/item/cert_card/existing in installed_certs)
		if(istype(existing.base_cert, /datum/cpu_cert/workshop))
			var/datum/cpu_cert/workshop/EW = existing.base_cert
			if(EW.grants_tier == WC.grants_tier)
				to_chat(user, span_warning("A tier [WC.grants_tier] cert is already installed."))
				return
	if(!user.transferItemToLoc(CC, src))
		return
	installed_certs += CC
	_recalculate_tier()
	to_chat(user, span_good("Workshop cert installed! Tier unlocked: [_tier_label(WC.grants_tier)]."))
	ui_interact(user)

/obj/machinery/robot_workshop/proc/_recalculate_tier()
	// Baseline is UTILITY -- the machine always builds T1 without any cert.
	// Installed certs can raise the tier but ejecting them never drops below T1.
	workshop_tier = WORKSHOP_TIER_UTILITY
	for(var/obj/item/cert_card/C in installed_certs)
		if(istype(C.base_cert, /datum/cpu_cert/workshop))
			var/datum/cpu_cert/workshop/WC = C.base_cert
			if(WC.grants_tier > workshop_tier)
				workshop_tier = WC.grants_tier


// ====================================================
// WORKSHOP CERT DATUM
// Carried by cert_card items found as loot.
// ====================================================

/datum/cpu_cert/workshop
	/// Which workshop tier this cert unlocks
	var/grants_tier = WORKSHOP_TIER_NONE

/datum/cpu_cert/workshop/utility
	grants_tier = WORKSHOP_TIER_UTILITY

/datum/cpu_cert/workshop/security
	grants_tier = WORKSHOP_TIER_SECURITY

/datum/cpu_cert/workshop/combat
	grants_tier = WORKSHOP_TIER_COMBAT

/datum/cpu_cert/workshop/apex
	grants_tier = WORKSHOP_TIER_APEX


// ====================================================
// WORKSHOP CERT CARD SUBTYPES (loot items)
// ====================================================

/obj/item/cert_card/workshop
	name = "workshop cert card"
	desc = "A battered certification card. Might unlock something if you find the right machine."

/obj/item/cert_card/workshop/Initialize(mapload)
	. = ..(  )
	// base_cert is set by subtype

/obj/item/cert_card/workshop/utility
	name = "workshop cert: UTILITY"
	desc = "Civilian-grade robot fabrication certification. Unlocks Tier 1 workshop builds."

/obj/item/cert_card/workshop/utility/Initialize(mapload)
	. = ..(  )
	base_cert = new /datum/cpu_cert/workshop/utility()

/obj/item/cert_card/workshop/security
	name = "workshop cert: SECURITY"
	desc = "Security-grade fabrication cert. Unlocks Tier 2 workshop builds."

/obj/item/cert_card/workshop/security/Initialize(mapload)
	. = ..(  )
	base_cert = new /datum/cpu_cert/workshop/security()

/obj/item/cert_card/workshop/combat
	name = "workshop cert: COMBAT"
	desc = "Military fabrication cert. Unlocks Tier 3 workshop builds. Handle with care."

/obj/item/cert_card/workshop/combat/Initialize(mapload)
	. = ..(  )
	base_cert = new /datum/cpu_cert/workshop/combat()

/obj/item/cert_card/workshop/apex
	name = "workshop cert: APEX"
	desc = "Pre-war apex fabrication cert. Unlocks Sentry Bot construction. Extremely rare."

/obj/item/cert_card/workshop/apex/Initialize(mapload)
	. = ..(  )
	base_cert = new /datum/cpu_cert/workshop/apex()


// ====================================================
// VALIDATION
// ====================================================

/obj/machinery/robot_workshop/proc/_validate_build(mob/living/user = null)
	var/list/errors = list()
	// Chassis is optional -- robot spawns without a suit if none loaded.
	// if(!chassis) errors += "No chassis loaded."
	if(!selected_design)
		errors += "No robot type selected."
	if(selected_design)
		var/datum/robot_build_design/D = _get_design(selected_design)
		if(D)
			if(D.tier > workshop_tier)
				errors += "This design requires Tier [D.tier] but workshop is Tier [workshop_tier]."
			for(var/mat in D.mat_cost)
				// Apply LCK discount at validation so the threshold matches what spend will use
				var/lck_disc_val = istype(user, /mob/living/carbon/human) ? get_workshop_lck_discount(user) : 0
				var/discounted_cost = round(D.mat_cost[mat] * (1 - lck_disc_val / 100))
				if(materials[mat] < discounted_cost)
					errors += "Insufficient [mat]: need [discounted_cost] (after LCK discount), have [materials[mat]]."
	// CORE budget -- hard block if hardware exceeds cert limits
	var/datum/cpu_cert/budget_cert = robot_cert ? robot_cert.base_cert : null
	if(!budget_cert)
		budget_cert = new /datum/cpu_cert/robot()
	var/list/core_errors = check_hardware_core_budget(pending_hardware, budget_cert)
	if(!robot_cert) qdel(budget_cert)
	for(var/ce in core_errors)
		errors += ce

	// Circuit cpu_cost -- sum all circuits in queued assembly vs cert compute
	if(behavior_assembly && behavior_assembly.circuits.len)
		var/datum/cpu_cert/cc = robot_cert ? robot_cert.base_cert : new /datum/cpu_cert/robot()
		var/total_cpu = 0
		for(var/datum/behavior_circuit/C in behavior_assembly.circuits)
			total_cpu += C.cpu_cost
		var/avail_cpu = cc.get_compute()
		if(!robot_cert) qdel(cc)
		if(total_cpu > avail_cpu)
			errors += "Assembly cpu_cost [total_cpu] exceeds cert Compute [avail_cpu]. Remove circuits or use a higher-tier cert."

	// Assembly cert_compatible check -- ensures assembly capability flags match the cert
	if(behavior_assembly)
		var/datum/cpu_cert/ac = robot_cert ? robot_cert.base_cert : new /datum/cpu_cert/robot()
		if(!behavior_assembly.cert_compatible(ac))
			errors += "Assembly '[behavior_assembly.assembly_label]' requires capabilities this cert does not have."
		if(!robot_cert) qdel(ac)

	// Chassis-module tag compatibility check
	// The selected module_type must share at least one ROBOT_ROLE_* tag with the chassis design.
	if(selected_design)
		var/datum/robot_build_design/D = _get_design(selected_design)
		if(D && D.chassis_tags != ROBOT_ROLE_ANY)
			var/module_tag_val = initial(D.module_type:module_tags)
			if(!(D.chassis_tags & module_tag_val))
				var/mod_name = initial(D.module_type:name)
				errors += "Module '[mod_name]' is not compatible with [D.design_name]. This chassis requires a matching role module."

	return errors


/obj/machinery/robot_workshop/proc/_get_hw_warnings()
	var/list/warns = list()
	if(!behavior_assembly)
		return warns
	var/list/seen = list()
	for(var/datum/behavior_circuit/C in behavior_assembly.circuits)
		if(!C.needs_hardware || !C.hardware_slot_name)
			continue
		if(C.hardware_slot_name in seen)
			continue
		seen += C.hardware_slot_name
		if(!(C.hardware_slot_name in pending_hardware))
			warns += "[C.circuit_name]: needs hardware in '[C.hardware_slot_name]' -- circuit will no-op until hardware is installed separately."
	return warns


// ====================================================
// HELPERS
// ====================================================

/obj/machinery/robot_workshop/proc/_get_design(path)
	for(var/datum/robot_build_design/D in designs)
		if(D.type == path)
			return D
	return null

/// Returns a human-readable label for a chassis_tags bitfield value.
/obj/machinery/robot_workshop/proc/_role_tag_label(tags)
	if(tags == ROBOT_ROLE_ANY || !tags)
		return "Any"
	var/list/parts = list()
	if(tags & ROBOT_ROLE_SUPPORT)  parts += "Support"
	if(tags & ROBOT_ROLE_COMBAT)   parts += "Combat"
	if(tags & ROBOT_ROLE_SECURITY) parts += "Security"
	if(tags & ROBOT_ROLE_APEX)     parts += "Apex"
	return parts.Join("/")


/obj/machinery/robot_workshop/proc/_tier_label(tier)
	switch(tier)
		if(WORKSHOP_TIER_NONE)     return "UNCERTIFIED"
		if(WORKSHOP_TIER_UTILITY)  return "UTILITY"
		if(WORKSHOP_TIER_SECURITY) return "SECURITY"
		if(WORKSHOP_TIER_COMBAT)   return "COMBAT"
		if(WORKSHOP_TIER_APEX)     return "APEX"
	return "UNKNOWN"

/obj/machinery/robot_workshop/proc/_mat_bar(amt, max)
	var/filled = round((amt / max) * 10)
	var/bar = "\["
	for(var/i in 1 to 10)
		bar += i <= filled ? "#" : "-"
	bar += "\]"
	return bar

/obj/machinery/robot_workshop/proc/_mat_cost_str(list/cost)
	var/list/parts = list()
	for(var/mat in cost)
		if(cost[mat] > 0)
			parts += "[cost[mat]] [mat]"
	return parts.Join(" / ")

/obj/machinery/robot_workshop/proc/_mat_key_from_item(obj/item/W)
	if(istype(W, /obj/item/stack/sheet/metal))    return "iron"
	if(istype(W, /obj/item/stack/sheet/glass))    return "glass"
	if(istype(W, /obj/item/stack/sheet/mineral/gold))   return "gold"
	if(istype(W, /obj/item/stack/sheet/mineral/silver)) return "silver"
	return null

/obj/machinery/robot_workshop/proc/_mat_path_from_key(key)
	switch(key)
		if("iron")   return /obj/item/stack/sheet/metal
		if("glass")  return /obj/item/stack/sheet/glass
		if("gold")   return /obj/item/stack/sheet/mineral/gold
		if("silver") return /obj/item/stack/sheet/mineral/silver
	return null


/obj/machinery/robot_workshop/proc/_slot_label(slot_name)
	// slot_name is a /datum/robot_hardware type path string.
	// Instantiate a proto to read hardware_name, then clean up.
	var/hw_type = text2path(slot_name)
	if(hw_type && ispath(hw_type, /datum/robot_hardware))
		var/datum/robot_hardware/proto = new hw_type()
		var/label = proto.hardware_name
		qdel(proto)
		return label
	return slot_name

/obj/machinery/robot_workshop/proc/_item_satisfies_slot(obj/item/I, slot_name)
	// Legacy stub - physical IC items no longer used for hardware slots.
	// Hardware is now installed via datum/robot_hardware at build time.
	// This proc is retained only for any external callers; always returns FALSE.
	return FALSE

/// Returns TRUE if the given hardware datum type satisfies the slot requirement.
/// slot_name is a HW_SLOT_* define (a /datum/robot_hardware type path string).
/obj/machinery/robot_workshop/proc/_slot_accepts_hw_type(slot_name, hw_type)
	if(!slot_name || !hw_type)
		return TRUE  // no constraint -- show everything
	var/required = text2path(slot_name)
	if(!required)
		return TRUE  // slot_name is not a type path (e.g. "Optional 1") -- no filter
	return ispath(hw_type, required)


// ====================================================
// CSS WRAPPER


// ====================================================
// CSS WRAPPER
// Matches cpu_fabricator terminal aesthetic
// ====================================================

/obj/machinery/robot_workshop/proc/_get_css()
	var/css = "<head><style>"
	css += "body{padding:0;margin:15px;background-color:#062113;color:#4aed92;line-height:170%;font-family:'Courier New',Courier,monospace;}"
	css += "a,a:link,a:visited,a:active{color:#4aed92;text-decoration:none;background:#062113;border:none;padding:1px 4px;margin:0 2px;cursor:default;}"
	css += "a:hover{color:#062113;background:#4aed92;}"
	css += ".good{color:#4aed92;font-weight:bold;}"
	css += ".bad{color:#c0392b;font-weight:bold;}"
	css += ".dim{color:#2a7a52;}"
	css += ".warn{color:#e8a020;}"
	css += ".stat{color:#e8a020;font-weight:bold;}"
	css += ".csec{margin-top:2px;}"
	css += "hr{border:0;border-top:1px solid #2a7a52;margin:6px 0;}"
	css += "</style></head>"
	return css
