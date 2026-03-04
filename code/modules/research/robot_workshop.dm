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
// IC SLOT DEFINES
// Human-readable hardware slot names shown in HARDWARE tab.
// Matched against behavior_circuit.hardware_slot_name.
// ====================================================

#define IC_SLOT_WEAPON_FIRING    "Weapon Firing IC"
#define IC_SLOT_AIR_CANNON       "Air Cannon IC"
#define IC_SLOT_GRENADE_THROWER  "Grenade + Thrower IC"
#define IC_SLOT_THROWER_GRABBER  "Thrower + Grabber IC"
#define IC_SLOT_BORGHYPO         "Borghypo (Injector)"
#define IC_SLOT_GRABBER          "Grabber IC"
#define IC_SLOT_EXTINGUISHER     "Extinguisher IC"
#define IC_SLOT_LIGHT            "Light Output IC"
#define IC_SLOT_REAGENT_PUMP     "Reagent Pump IC"
#define IC_SLOT_SIGNALER         "Signaler IC"
#define IC_SLOT_SCREEN           "Screen Display IC"
#define IC_SLOT_ID_READER        "ID Card Reader IC"
#define IC_SLOT_MICROPHONE       "Microphone IC"
#define IC_SLOT_GPS              "GPS IC"
#define IC_SLOT_ATMOSPHERICS     "Atmospherics IC"
#define IC_SLOT_HEALTH_SCANNER   "Health Scanner IC"


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

#define RW_HOME      0
#define RW_BUILD     1
#define RW_HARDWARE  2
#define RW_PROGRAMS  3
#define RW_FINALIZE  4


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

/datum/robot_build_design/handy
	design_name    = "Mr. Handy"
	design_desc    = "Pre-war household assistant. Useful for service and basic repairs."
	module_type    = /obj/item/robot_module/handy
	tier           = WORKSHOP_TIER_UTILITY
	mat_cost       = RW_COST_TIER1
	preview_icon   = "handy"
	display_health = 200

/datum/robot_build_design/liberator
	design_name    = "Liberator"
	design_desc    = "Compact combat drone. Light armor, fast, low threat ceiling."
	module_type    = /obj/item/robot_module/liberator
	tier           = WORKSHOP_TIER_UTILITY
	mat_cost       = RW_COST_TIER1
	preview_icon   = "liberator"
	display_health = 150

/datum/robot_build_design/protectron
	design_name    = "Protectron"
	design_desc    = "Basic law enforcement unit. Slow but sturdy."
	module_type    = /obj/item/robot_module/protectron
	tier           = WORKSHOP_TIER_SECURITY
	mat_cost       = RW_COST_TIER2
	preview_icon   = "protectron"
	display_health = 250

/datum/robot_build_design/gutsy
	design_name    = "Mr. Gutsy"
	design_desc    = "Military-grade service unit. Aggressive temperament, heavier armor."
	module_type    = /obj/item/robot_module/gutsy
	tier           = WORKSHOP_TIER_SECURITY
	mat_cost       = RW_COST_TIER2
	preview_icon   = "gutsy"
	display_health = 300

/datum/robot_build_design/securitron
	design_name    = "Securitron"
	design_desc    = "Heavy security platform. High health, strong weapons. Dangerous in numbers."
	module_type    = /obj/item/robot_module/securitron
	tier           = WORKSHOP_TIER_SECURITY
	mat_cost       = RW_COST_TIER3
	preview_icon   = "securitron"
	display_health = 500

/datum/robot_build_design/assaultron
	design_name    = "Assaultron"
	design_desc    = "High-speed combat unit. Lethal up close. Do not build without assembly."
	module_type    = /obj/item/robot_module/assaultron
	tier           = WORKSHOP_TIER_COMBAT
	mat_cost       = RW_COST_TIER3
	preview_icon   = "assaultron"
	display_health = 450

/datum/robot_build_design/sentrybot
	design_name    = "Sentry Bot"
	design_desc    = "Apex combat platform. Massive health, heavy weapons. Near-endgame threat level."
	module_type    = /obj/item/robot_module/sentrybot
	tier           = WORKSHOP_TIER_APEX
	mat_cost       = RW_COST_TIER4
	preview_icon   = "sentrybot"
	display_health = 600


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
	var/workshop_tier = WORKSHOP_TIER_NONE

	/// Installed cert cards that provided tier upgrades (stored for examination/ejection)
	var/list/installed_certs = list()

	/// Currently inserted robot chassis (robot_suit item)
	var/obj/item/robot_suit/chassis = null

	/// Currently selected build design path
	var/selected_design = null

	/// Currently inserted behavior assembly
	var/obj/item/behavior_assembly/behavior_assembly = null

	/// Hardware IC slots filled by player - assoc list: slot_name -> obj/item
	var/list/hardware_slots = list()

	/// Currently inserted cert card for the robot (optional)
	var/obj/item/cert_card/robot_cert = null

	/// Player control mode: "npc", "open", "locked"
	var/control_mode = "npc"

	/// If control_mode == "locked", only this ckey can ghost in
	var/locked_ckey = null

	/// UI mode
	var/ui_mode = RW_HOME

	/// Whether the machine is currently building
	var/building = FALSE

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
	// Eject hardware
	for(var/slot in hardware_slots)
		var/obj/item/I = hardware_slots[slot]
		if(I)
			I.forceMove(get_turf(src))
	hardware_slots = list()
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

	// Workshop cert cards -- tier upgrades
	if(istype(W, /obj/item/cert_card))
		var/obj/item/cert_card/CC = W
		_try_install_workshop_cert(CC, user)
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
		_rebuild_hw_slots()
		var/obj/item/behavior_assembly/BA_cast = W
		to_chat(user, span_notice("Behavior assembly queued: [BA_cast.assembly_label]."))
		ui_mode = RW_HARDWARE
		ui_interact(user)
		return

	// Hardware items -- fill named slots from the assembly
	if(behavior_assembly && hardware_slots.len)
		for(var/slot in hardware_slots)
			if(hardware_slots[slot])
				continue  // already filled
			if(_item_satisfies_slot(W, slot))
				if(!user.transferItemToLoc(W, src))
					return
				hardware_slots[slot] = W
				to_chat(user, span_notice("Installed [W] into [slot] slot."))
				ui_interact(user)
				return
		to_chat(user, span_warning("This item doesn't match any open hardware slot."))
		return

	// Cert card for the robot
	if(istype(W, /obj/item/cert_card) && !robot_cert)
		if(!user.transferItemToLoc(W, src))
			return
		robot_cert = W
		to_chat(user, span_notice("Robot cert card loaded."))
		ui_interact(user)
		return

	// Materials -- accept stacks of metal/glass/gold/silver
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
	// Tab nav - bracketed [TAB] style with pipes
	dat += _navlink("\[HOME\]",     RW_HOME)
	dat += " | "
	dat += _navlink("\[BUILD\]",    RW_BUILD)
	dat += " | "
	dat += _navlink("\[HARDWARE\]", RW_HARDWARE)
	dat += " | "
	dat += _navlink("\[PROGRAMS\]", RW_PROGRAMS)
	dat += " | "
	dat += _navlink("\[FINALIZE\]", RW_FINALIZE)
	dat += "<br>"
	if(workshop_tier > WORKSHOP_TIER_NONE)
		dat += "<span class='dim'>TIER: <b>[_tier_label(workshop_tier)]</b></span>"
	else
		dat += "<span class='warn'>TIER: UNCERTIFIED -- install a Workshop Cert Card</span>"
	if(building)
		dat += "  <span class='warn'>// FABRICATING...</span>"
	dat += "<hr>"
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
		return "<span class='good'><b>[label]</b></span>"
	return "<a href='byond://?src=[REF(src)];set_mode=[mode_id]'>[label]</a>"


// ====================================================
// HOME TAB
// ====================================================

/obj/machinery/robot_workshop/proc/_render_home(mob/user)
	var/dat = ""

	// Workshop tier
	dat += "<b>WORKSHOP STATUS</b><br>"
	dat += "Tier: <span class='good'>[_tier_label(workshop_tier)]</span><br>"
	if(workshop_tier == WORKSHOP_TIER_NONE)
		dat += "<span class='warn'>Install a Workshop Cert Card to unlock fabrication.</span><br>"
	dat += "<br>"

	// Installed tier certs
	dat += "<b>INSTALLED CERTS</b><br>"
	if(installed_certs.len)
		for(var/obj/item/cert_card/C in installed_certs)
			dat += "<span class='dim'>&gt; [C.name]</span>"
			dat += "  <a href='byond://?src=[REF(src)];eject_tier_cert=[REF(C)]'>\[eject\]</a><br>"
	else
		dat += "<span class='dim'>None installed.</span><br>"
	dat += "<br>"

	// Chassis slot
	dat += "<b>CHASSIS SLOT</b><br>"
	if(chassis)
		dat += "<span class='good'>&gt; [chassis.name]</span>"
		dat += "  <a href='byond://?src=[REF(src)];eject_chassis=1'>\[eject\]</a><br>"
	else
		dat += "<span class='dim'>Empty -- insert a robot_suit chassis.</span><br>"
	dat += "<br>"

	// Material hopper
	dat += "<b>MATERIAL HOPPER</b><br>"
	for(var/mat in materials)
		var/amt = materials[mat]
		var/bar = _mat_bar(amt, mat_max)
		dat += "<span class='dim'>[uppertext(mat)]</span>  [bar]  <span class='dim'>[amt]/[mat_max]</span><br>"
	dat += "<br>"

	// Unlock table
	dat += "<b>TIER UNLOCK GUIDE</b><br>"
	dat += "<span class='dim'>T1 Utility:  Mr. Handy, Liberator</span><br>"
	dat += "<span class='dim'>T2 Security: Protectron, Mr. Gutsy, Securitron</span><br>"
	dat += "<span class='dim'>T3 Combat:   Assaultron</span><br>"
	dat += "<span class='dim'>T4 Apex:     Sentry Bot  // find the cert first</span><br>"

	return dat


// ====================================================
// BUILD TAB
// ====================================================

/obj/machinery/robot_workshop/proc/_render_build(mob/user)
	var/dat = ""
	dat += "<b>SELECT ROBOT TYPE</b>  <span class='dim'>// filtered by workshop tier</span><br><br>"

	if(workshop_tier == WORKSHOP_TIER_NONE)
		dat += "<span class='warn'>Workshop uncertified. Install a Workshop Cert Card first.</span><br>"
		return dat

	var/any_shown = FALSE
	for(var/datum/robot_build_design/D in designs)
		if(D.tier > workshop_tier)
			continue
		any_shown = TRUE
		var/is_selected = (selected_design == D.type)
		var/tier_label = _tier_label(D.tier)
		var/sel_class = is_selected ? " sel" : ""
		dat += "<div class='card[sel_class]'>"
		dat += "<b>[D.design_name]</b>  <span class='dim'>T[D.tier] [tier_label]</span><br>"
		dat += "<span class='dim'>[D.design_desc]</span><br>"
		dat += "HP: <span class='good'>[D.display_health]</span>  "
		dat += "Cost: <span class='dim'>[_mat_cost_str(D.mat_cost)]</span><br>"
		if(is_selected)
			dat += "<span class='good'>&gt; SELECTED</span>"
			dat += "  <a href='byond://?src=[REF(src)];select_design=clear'>\[clear\]</a>"
		else
			dat += "<a href='byond://?src=[REF(src)];select_design=[D.type]'>&gt; \[SELECT\]</a>"
		dat += "</div>"

	if(!any_shown)
		dat += "<span class='warn'>No designs available at current tier.</span><br>"

	return dat


// ====================================================
// HARDWARE TAB
// ====================================================

/obj/machinery/robot_workshop/proc/_render_hardware(mob/user)
	var/dat = ""
	dat += "<b>HARDWARE SLOTS</b>  <span class='dim'>// derived from queued assembly circuits</span><br><br>"

	if(!behavior_assembly)
		dat += "<span class='dim'>No behavior assembly queued. Go to PROGRAMS to insert one.</span><br>"
		dat += "<span class='dim'>Hardware slots appear here once an assembly is loaded.</span><br>"
		return dat

	if(!hardware_slots.len)
		dat += "<span class='good'>This assembly has no hardware requirements.</span><br>"
		dat += "<span class='dim'>All circuits are software-only.</span><br>"
		return dat

	// Show which circuits need what
	dat += "<span class='dim'>Insert items into the machine to fill named slots.</span><br><br>"

	var/all_filled = TRUE
	for(var/slot in hardware_slots)
		var/obj/item/I = hardware_slots[slot]
		var/label = _slot_label(slot)
		if(I)
			dat += "<div class='card'>"
			dat += "<span class='good'>&gt; [label]</span><br>"
			dat += "<span class='dim'>Installed: [I.name]</span>"
			dat += "  <a href='byond://?src=[REF(src)];eject_hw=[slot]'>\[eject\]</a>"
			dat += "</div>"
		else
			all_filled = FALSE
			dat += "<div class='card hw'>"
			dat += "<span class='warn'>&gt; [label]</span><br>"
			dat += "<span class='dim'>Empty -- insert a compatible item into the machine.</span>"
			dat += "</div>"

	if(all_filled)
		dat += "<br><span class='good'>&gt; All hardware slots filled.</span><br>"

	// Show base module items (pre-installed, not removable)
	if(selected_design)
		var/datum/robot_build_design/D = _get_design(selected_design)
		if(D)
			dat += "<br><b>BASE MODULE LOADOUT</b>  <span class='dim'>// pre-installed, not configurable</span><br>"
			var/obj/item/robot_module/dummy = new D.module_type(null)
			for(var/path in dummy.basic_modules)
				var/obj/item/thing = new path(null)
				dat += "<span class='dim'>  + [thing.name]</span><br>"
				qdel(thing)
			qdel(dummy)

	return dat


// ====================================================
// PROGRAMS TAB
// ====================================================

/obj/machinery/robot_workshop/proc/_render_programs(mob/user)
	var/dat = ""
	dat += "<b>BEHAVIOR ASSEMBLY</b><br><br>"

	if(behavior_assembly)
		var/obj/item/behavior_assembly/A = behavior_assembly
		dat += "<div class='card'>"
		dat += "<b>[A.assembly_label]</b><br>"
		dat += "<span class='dim'>Circuits: [A.circuits.len]/[A.max_circuits]</span><br>"
		dat += "<span class='dim'>Sensor range: [A.sensor_range] tiles</span><br>"
		if(A.circuits.len)
			dat += "<br>"
			for(var/datum/behavior_circuit/C in A.circuits)
				var/hw_note = C.needs_hardware ? "  <span class='warn'>HARDWARE</span>" : ""
				dat += "<span class='dim'>  [C.circuit_name][hw_note]</span><br>"
				dat += "<span class='dim'>    [C.circuit_desc]</span><br>"
		dat += "</div>"
		dat += "<a href='byond://?src=[REF(src)];eject_assembly=1'>\[Eject assembly\]</a><br>"
	else
		dat += "<span class='dim'>No assembly queued. Insert a behavior_assembly item into the machine.</span><br>"
		dat += "<span class='dim'>Assemblies are printed at the CPU Cert Fabricator.</span><br>"
		dat += "<br><span class='dim'>Building without an assembly produces a basic NPC robot using its default module behaviors.</span><br>"

	dat += "<br><b>ROBOT CERT CARD</b>  <span class='dim'>(optional)</span><br>"
	if(robot_cert)
		dat += "<span class='good'>&gt; [robot_cert.name]</span>"
		dat += "  <a href='byond://?src=[REF(src)];eject_robot_cert=1'>\[eject\]</a><br>"
	else
		dat += "<span class='dim'>None -- robot will get a default cert auto-applied at spawn.</span><br>"
		dat += "<span class='dim'>Insert a cert_card item to override.</span><br>"

	return dat


// ====================================================
// FINALIZE TAB
// ====================================================

/obj/machinery/robot_workshop/proc/_render_finalize(mob/user)
	var/dat = ""
	dat += "<b>BUILD SUMMARY</b><br><br>"

	// Validate
	var/list/errors = _validate_build()

	// Chassis
	dat += "Chassis:  "
	if(chassis)
		dat += "<span class='good'>[chassis.name]</span><br>"
	else
		dat += "<span class='warn'>MISSING</span><br>"

	// Module
	dat += "Module:   "
	if(selected_design)
		var/datum/robot_build_design/D = _get_design(selected_design)
		dat += "<span class='good'>[D.design_name]</span>  <span class='dim'>(T[D.tier])</span><br>"
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

	// Hardware slots
	if(hardware_slots.len)
		dat += "Hardware: "
		var/filled = 0
		for(var/slot in hardware_slots)
			if(hardware_slots[slot])
				filled++
		var/total = hardware_slots.len
		if(filled < total)
			dat += "<span class='warn'>[filled]/[total] slots filled</span><br>"
		else
			dat += "<span class='good'>All [total] slots filled</span><br>"

	// Material cost
	if(selected_design)
		var/datum/robot_build_design/D2 = _get_design(selected_design)
		if(D2)
			dat += "<br><b>MATERIAL COST</b><br>"
			for(var/mat in D2.mat_cost)
				var/cost = D2.mat_cost[mat]
				var/have = materials[mat]
				var/ok = have >= cost
				dat += "<span class='[ok ? "good" : "warn"]'>[uppertext(mat)]: [cost]</span>  "
				dat += "<span class='dim'>(stored: [have])</span><br>"

	// Control mode
	dat += "<br><b>PLAYER CONTROL</b><br>"
	dat += "<span class='dim'>Mode: </span>"
	switch(control_mode)
		if("npc")
			dat += "<span class='good'>NPC ONLY</span>"
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
		dat += "<b>CANNOT BUILD:</b><br>"
		for(var/e in errors)
			dat += "<span class='warn'>  ! [e]</span><br>"
	else
		dat += "<a href='byond://?src=[REF(src)];build_robot=1'><b>&gt; \[FABRICATE ROBOT\]</b></a><br>"

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
			hardware_slots = list()
		else
			var/path = text2path(val)
			if(_get_design(path))
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
			hardware_slots = list()
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

	if(href_list["eject_hw"])
		var/slot = href_list["eject_hw"]
		if(hardware_slots[slot])
			var/obj/item/I = hardware_slots[slot]
			I.forceMove(get_turf(src))
			hardware_slots[slot] = null
			to_chat(usr, span_notice("[slot] slot cleared."))
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


// ====================================================
// BUILDING
// ====================================================

/obj/machinery/robot_workshop/proc/_build_robot(mob/living/user)
	if(building)
		to_chat(user, span_warning("Already fabricating."))
		return

	var/list/errors = _validate_build()
	if(errors.len)
		to_chat(user, span_warning("Build errors: [errors[1]]"))
		return

	var/datum/robot_build_design/D = _get_design(selected_design)

	// Spend materials
	for(var/mat in D.mat_cost)
		materials[mat] -= D.mat_cost[mat]

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
	var/list/snap_hw                             = hardware_slots.Copy()
	var/turf/T                                   = get_turf(src)
	var/builder_ckey                             = key_name(user)

	// Clear workshop state immediately so slots are free
	behavior_assembly = null
	robot_cert        = null
	chassis           = null
	hardware_slots    = list()
	selected_design   = null

	addtimer(CALLBACK(src, PROC_REF(_set_working_anim)), 10, TIMER_UNIQUE|TIMER_OVERRIDE)
	addtimer(CALLBACK(src, PROC_REF(_finish_robot),
		snap_design, snap_control, snap_ckey,
		snap_assembly, snap_cert, snap_chassis,
		snap_hw, T, builder_ckey), 50, TIMER_UNIQUE|TIMER_OVERRIDE)



/obj/machinery/robot_workshop/proc/_set_working_anim()
	if(building)
		icon_state = "h_lathe_wloop"

/obj/machinery/robot_workshop/proc/_finish_robot(
	design_path, control_mode_snap, ckey_snap,
	obj/item/behavior_assembly/A,
	obj/item/cert_card/CC,
	obj/item/robot_suit/suit,
	list/hw_snap, turf/T, builder_ckey)

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

	// Install hardware ICs into added_modules
	for(var/slot in hw_snap)
		var/obj/item/I = hw_snap[slot]
		if(I)
			I.forceMove(R)
			R.module.add_module(I, TRUE, FALSE)

	R.module.rebuild_modules()

	// Apply cert
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
		A.assembly_override = TRUE  // assemblies always fire on workshop robots
		A.forceMove(R)
		var/datum/cert_upgrade/robot/behavior_assembly/U = new()
		U.assembly = A
		if(R.cpu_cert.can_install_upgrade(U))
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
			// Pure NPC -- no MMI setup needed, robot runs on assembly only
			R.mind = null
		if("open")
			// Anyone can ghost in -- create MMI but leave it empty
			if(!R.mmi)
				R.mmi = new(R)
		if("locked")
			// MMI open but only specified ckey can take it
			if(!R.mmi)
				R.mmi = new(R)
			if(ckey_snap)
				// Store ckey so ghost-takeover proc can gate on it
				// Standard SS13 ckey restriction via mmi name tag
				R.mmi.name = "MMI: Reserved for [ckey_snap]"

	// Cosmetics
	R.name = "[D.design_name]-[rand(100,999)]"
	R.real_name = R.name
	R.maxHealth = D.display_health
	R.health = D.display_health
	R.update_icons()

	log_game("[builder_ckey] built [R.name] ([D.design_name], T[D.tier]) at [AREACOORD(T)]")
	visible_message(span_notice("[src] finishes fabricating: <b>[R.name]</b>."))
	playsound(T, 'sound/machines/ding.ogg', 75, 1)


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
	workshop_tier = WORKSHOP_TIER_NONE
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

/obj/machinery/robot_workshop/proc/_validate_build()
	var/list/errors = list()
	if(!chassis)
		errors += "No chassis loaded."
	if(!selected_design)
		errors += "No robot type selected."
	if(workshop_tier == WORKSHOP_TIER_NONE)
		errors += "Workshop uncertified -- install a Workshop Cert Card."
	if(selected_design)
		var/datum/robot_build_design/D = _get_design(selected_design)
		if(D)
			if(D.tier > workshop_tier)
				errors += "This design requires Tier [D.tier] but workshop is Tier [workshop_tier]."
			for(var/mat in D.mat_cost)
				if(materials[mat] < D.mat_cost[mat])
					errors += "Insufficient [mat]: need [D.mat_cost[mat]], have [materials[mat]]."
	// Hardware slots -- warn but don't block (partial hardware is allowed, circuit silently no-ops)
	// If you want hard blocking, uncomment:
	// for(var/slot in hardware_slots)
	//     if(!hardware_slots[slot])
	//         errors += "Hardware slot unfilled: [slot]."
	return errors


// ====================================================
// HELPERS
// ====================================================

/obj/machinery/robot_workshop/proc/_get_design(path)
	for(var/datum/robot_build_design/D in designs)
		if(D.type == path)
			return D
	return null

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

/obj/machinery/robot_workshop/proc/_rebuild_hw_slots()
	// Build required hardware slot list from the queued assembly's circuits
	hardware_slots = list()
	if(!behavior_assembly)
		return
	var/list/seen_slots = list()
	for(var/datum/behavior_circuit/C in behavior_assembly.circuits)
		if(!C.needs_hardware || !C.hardware_slot_name)
			continue
		if(C.hardware_slot_name in seen_slots)
			continue  // deduplicate same slot type
		seen_slots += C.hardware_slot_name
		hardware_slots[C.hardware_slot_name] = null  // null = unfilled


/obj/machinery/robot_workshop/proc/_slot_label(slot_name)
	switch(slot_name)
		if(IC_SLOT_WEAPON_FIRING)    return "Weapon Firing Mechanism"
		if(IC_SLOT_AIR_CANNON)       return "Pneumatic Air Cannon"
		if(IC_SLOT_GRENADE_THROWER)  return "Grenade Launcher + Thrower"
		if(IC_SLOT_THROWER_GRABBER)  return "Thrower + Grabber Arm"
		if(IC_SLOT_BORGHYPO)         return "Hypodermic Injector (Borghypo)"
		if(IC_SLOT_GRABBER)          return "Grabber Arm"
		if(IC_SLOT_EXTINGUISHER)     return "Fire Extinguisher / Atmos IC"
		if(IC_SLOT_LIGHT)            return "Light Output Module"
		if(IC_SLOT_REAGENT_PUMP)     return "Reagent Pump"
		if(IC_SLOT_SIGNALER)         return "Radio Signaler"
		if(IC_SLOT_SCREEN)           return "Display Screen"
		if(IC_SLOT_ID_READER)        return "ID Card Reader"
		if(IC_SLOT_MICROPHONE)       return "Microphone Input"
		if(IC_SLOT_GPS)              return "GPS Locator"
		if(IC_SLOT_ATMOSPHERICS)     return "Atmospherics Sensor"
		if(IC_SLOT_HEALTH_SCANNER)   return "Health Analyzer"
	return slot_name

/obj/machinery/robot_workshop/proc/_item_satisfies_slot(obj/item/I, slot_name)
	// Maps slot names to acceptable item types
	switch(slot_name)
		if(IC_SLOT_WEAPON_FIRING)
			return istype(I, /obj/item/integrated_circuit/weaponized/weapon_firing)
		if(IC_SLOT_AIR_CANNON)
			return istype(I, /obj/item/integrated_circuit/weaponized/air_cannon)
		if(IC_SLOT_GRENADE_THROWER)
			return istype(I, /obj/item/integrated_circuit/weaponized/grenade) || istype(I, /obj/item/integrated_circuit/manipulation/thrower)
		if(IC_SLOT_THROWER_GRABBER)
			return istype(I, /obj/item/integrated_circuit/manipulation/thrower) || istype(I, /obj/item/integrated_circuit/manipulation/grabber)
		if(IC_SLOT_BORGHYPO)
			return istype(I, /obj/item/reagent_containers/borghypo)
		if(IC_SLOT_GRABBER)
			return istype(I, /obj/item/integrated_circuit/manipulation/grabber)
		if(IC_SLOT_EXTINGUISHER)
			return istype(I, /obj/item/extinguisher) || istype(I, /obj/item/integrated_circuit/atmospherics)
		if(IC_SLOT_LIGHT)
			return istype(I, /obj/item/integrated_circuit/output/light)
		if(IC_SLOT_REAGENT_PUMP)
			return istype(I, /obj/item/integrated_circuit/reagent)
		if(IC_SLOT_SIGNALER)
			return istype(I, /obj/item/integrated_circuit/input/signaler)
		if(IC_SLOT_SCREEN)
			return istype(I, /obj/item/integrated_circuit/output/screen)
		if(IC_SLOT_ID_READER)
			return istype(I, /obj/item/integrated_circuit/input/card_reader) || istype(I, /obj/item/card/id)
		if(IC_SLOT_MICROPHONE)
			return istype(I, /obj/item/integrated_circuit/input/microphone)
		if(IC_SLOT_GPS)
			return istype(I, /obj/item/integrated_circuit/input/gps) || istype(I, /obj/item/gps)
		if(IC_SLOT_ATMOSPHERICS)
			return istype(I, /obj/item/integrated_circuit/atmospherics)
		if(IC_SLOT_HEALTH_SCANNER)
			return istype(I, /obj/item/healthanalyzer)
	return FALSE


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
	css += ".card{border:1px solid #2a7a52;padding:4px 8px;margin:3px 0;}"
	css += ".hw{border-left:3px solid #e8a020;}"
	css += ".sel{border-left:3px solid #4aed92;background:#071a0f;}"
	css += "hr{border:0;border-top:1px solid #2a7a52;margin:6px 0;}"
	css += "</style></head>"
	return css
