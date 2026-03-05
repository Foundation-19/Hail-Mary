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
		_rebuild_hw_slots()
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

	// Operator SPECIAL profile
	if(istype(user, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = user
		dat += "<br><b>OPERATOR PROFILE</b>  <span class='dim'>// your stats at build time</span><br>"
		dat += "<span class='dim'>STR [H.special_s]  PER [H.special_p]  END [H.special_e]  CHA [H.special_c]"
		dat += "  INT [H.special_i]  AGI [H.special_a]  LCK [H.special_l]</span><br>"
		var/lck_disc = get_workshop_lck_discount(H)
		if(lck_disc > 0)
			dat += "<span class='good'>LCK bonus: [lck_disc]% material cost discount active</span><br>"
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
		dat += "<b>REQUIRED HARDWARE SLOTS</b>  <span class='dim'>// from queued assembly</span><br>"
		for(var/slot_key in asm_slots)
			dat += _hw_slot_row(slot_key, TRUE, H)
		dat += "<br>"

	// Optional hardware
	dat += "<b>OPTIONAL HARDWARE</b>  <span class='dim'>// enhances robot beyond assembly requirements</span><br>"
	// Show already-added optional slots
	for(var/slot_key in pending_hardware)
		if(slot_key in asm_slots)
			continue
		dat += _hw_slot_row(slot_key, FALSE, H)
	dat += "<a href='byond://?src=[REF(src)];hw_add_optional=1'>\[+ add optional hardware\]</a><br>"

	// Base module loadout
	if(selected_design)
		var/datum/robot_build_design/D = _get_design(selected_design)
		if(D)
			dat += "<br><b>BASE MODULE LOADOUT</b>  <span class='dim'>// pre-installed, not configurable</span><br>"
			var/obj/item/robot_module/dummy = new D.module_type(null)
			for(var/obj/item/I in dummy.basic_modules)
				dat += "<span class='dim'>  + [I.name]</span><br>"
			qdel(dummy)

	return dat


/obj/machinery/robot_workshop/proc/_hw_slot_row(slot_key, required, mob/living/carbon/human/builder)
	var/datum/robot_hardware/HW = pending_hardware[slot_key]
	var/dat = ""
	var/card_class = HW ? "card hw" : "card"
	dat += "<div class='[card_class]'>"
	if(HW)
		dat += "<span class='good'>&gt; [slot_key]</span><br>"
		dat += "<span class='dim'>[HW.hardware_name]"
		if(HW.core_compute || HW.core_operations || HW.core_resilience || HW.core_energy)
			dat += "  C.O.R.E: C[HW.core_compute] O[HW.core_operations] R[HW.core_resilience] E[HW.core_energy]"
		dat += "</span><br>"
		dat += "<a href='byond://?src=[REF(src)];hw_configure=[slot_key]'>\[configure\]</a>"
		if(istype(HW, /datum/robot_hardware/circuit_board))
			dat += "  <a href='byond://?src=[REF(src)];hw_circuit_edit=[slot_key]'>\[circuit editor\]</a>"
		dat += "  <a href='byond://?src=[REF(src)];hw_remove=[slot_key]'>\[remove\]</a>"
	else
		var/slot_class = required ? "warn" : "dim"
		var/slot_label = required ? "Required" : "Optional"
		dat += "<span class='[slot_class]'>&gt; [slot_key]</span><br>"
		dat += "<span class='dim'>[slot_label] -- not configured.</span><br>"
		dat += "<a href='byond://?src=[REF(src)];hw_pick=[slot_key]'>\[select hardware\]</a>"
	dat += "</div>"
	return dat


/obj/machinery/robot_workshop/proc/_hw_special_preview(mob/living/carbon/human/H)
	var/dat = "<b>OPERATOR INFLUENCE</b>  <span class='dim'>// your SPECIAL baked into this robot at build</span><br>"
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
	dat += "<b>SELECT HARDWARE</b>  <span class='dim'>// slot: [hw_active_slot]</span>"
	dat += "  <a href='byond://?src=[REF(src)];hw_cancel_pick=1'>\[cancel\]</a><br><br>"

	var/list/by_cat = list()
	for(var/T in subtypesof(/datum/robot_hardware))
		var/datum/robot_hardware/proto = new T()
		if(!by_cat[proto.category])
			by_cat[proto.category] = list()
		by_cat[proto.category] += T
		qdel(proto)

	for(var/cat in by_cat)
		dat += "<b>[cat]</b><br>"
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
			if(blocked)
				dat += "<div class='card'>"
				dat += "<span class='dim'>&gt; [proto.hardware_name]  [gate_label]</span><br>"
				dat += "<span class='dim'>[proto.hardware_desc]</span><br>"
				dat += "<span class='dim'>CORE: [core_str]  MAT: [mat_str]  // INT too low</span>"
				dat += "</div>"
			else if(overbudget)
				dat += "<div class='card'>"
				dat += "<span class='warn'>&gt; [proto.hardware_name]</span><br>"
				dat += "<span class='dim'>[proto.hardware_desc]</span><br>"
				dat += "<span class='warn'>CORE: [core_str]  // overbudget</span>  MAT: [mat_str]"
				dat += "</div>"
			else
				dat += "<div class='card hw'>"
				dat += "<span class='good'>&gt; [proto.hardware_name]</span>  [gate_label]"
				dat += "  <a href='byond://?src=[REF(src)];hw_select_type=[T]'>\[select\]</a><br>"
				dat += "<span class='dim'>[proto.hardware_desc]</span><br>"
				dat += "<span class='dim'>CORE: [core_str]  MAT: [mat_str]</span>"
				dat += "</div>"
			qdel(proto)
		dat += "<br>"

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
	dat += "<b>CONFIGURE: [proto.hardware_name]</b>"
	dat += "  <span class='dim'>// slot: [hw_active_slot]</span><br>"
	dat += "<a href='byond://?src=[REF(src)];hw_back_to_pick=1'>\[back\]</a>"
	dat += "  <a href='byond://?src=[REF(src)];hw_confirm=1'><b>\[CONFIRM & INSTALL\]</b></a><br><br>"

	dat += "<span class='dim'>[proto.tutorial_text]</span><br><br>"

	if(proto.config_defs.len)
		dat += "<b>CONFIGURATION</b><br>"
		for(var/varname in proto.config_defs)
			var/list/def = proto.config_defs[varname]
			var/label    = def[1]
			var/dtype    = def[2]
			var/cur_val  = hw_pending_config[varname] != null ? hw_pending_config[varname] : def[3]
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
	dat += "<b>CIRCUIT BOARD EDITOR</b>  <span class='dim'>// slot: [hw_circuit_slot]  nodes: [CB.nodes.len]/[CB.max_nodes]</span><br>"
	dat += "<a href='byond://?src=[REF(src)];hw_circuit_done=1'>\[done - return to overview\]</a><br><br>"

	// -- ADD NODE panel --
	dat += "<b>ADD NODE</b>  <span class='dim'>// click to place</span><br>"
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
	dat += "<b>PLACED NODES</b><br>"
	if(!CB.nodes.len)
		dat += "<span class='dim'>No nodes placed yet. Add from the list above.</span><br>"
	else
		for(var/i in 1 to CB.nodes.len)
			var/datum/circuit_node/N = CB.nodes[i]
			dat += "<div class='card hw'>"
			dat += "<b>[i]. [N.node_name]</b>  <span class='dim'>[N.node_category]</span>"
			dat += "  <a href='byond://?src=[REF(src)];ce_remove_node=[i]'>\[remove\]</a><br>"
			// Inputs
			if(N.inputs.len)
				dat += "<span class='dim'>IN: "
				var/list/iparts = list()
				for(var/inp in N.inputs)
					iparts += "[inp]=[N.inputs[inp]]"
				dat += iparts.Join("  ") + "</span><br>"
			// Outputs
			if(N.outputs.len)
				dat += "<span class='dim'>OUT: "
				var/list/oparts = list()
				for(var/outp in N.outputs)
					oparts += "<a href='byond://?src=[REF(src)];ce_connect_from=[i]:[outp]'>[outp]=[N.outputs[outp]]</a>"
				dat += oparts.Join("  ") + "</span><br>"
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
			dat += "</div>"

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
				var/mat_class = ok ? "good" : "warn"
				dat += "<span class='[mat_class]'>[uppertext(mat)]: [cost]</span>  "
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
			for(var/slot in pending_hardware)
				var/datum/robot_hardware/HW = pending_hardware[slot]
				if(HW) qdel(HW)
			pending_hardware = list()
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

	// ---- HARDWARE OVERVIEW ACTIONS ----

	if(href_list["hw_use_recommended"])
		_hw_apply_recommended(usr)
		ui_interact(usr)
		return

	if(href_list["hw_clear_all"])
		pending_hardware = list()
		ui_interact(usr)
		return

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
			// Copy existing config into pending
			hw_pending_config = list()
			for(var/varname in HW.config_defs)
				hw_pending_config[varname] = HW.vars[varname]
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
	var/opt_idx = 1
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
		// Find a matching assembly slot or use optional slot
		var/slot_key = null
		for(var/sk in asm_slots)
			if(sk in pending_hardware) continue
			// Rough match: slot key contains hardware category
			slot_key = sk
			break
		if(!slot_key)
			slot_key = "Optional [opt_idx]"
			opt_idx++
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
	var/list/snap_hw                             = pending_hardware.Copy()
	var/turf/T                                   = get_turf(src)
	var/builder_ckey                             = key_name(user)
	var/mob/living/carbon/human/snap_builder     = istype(user, /mob/living/carbon/human) ? user : null

	// Clear workshop state immediately so slots are free
	behavior_assembly = null
	robot_cert        = null
	chassis           = null
	hardware_slots    = list()
	pending_hardware  = list()
	selected_design   = null

	addtimer(CALLBACK(src, PROC_REF(_set_working_anim)), 10, TIMER_UNIQUE|TIMER_OVERRIDE)
	addtimer(CALLBACK(src, PROC_REF(_finish_robot),
		snap_design, snap_control, snap_ckey,
		snap_assembly, snap_cert, snap_chassis,
		snap_hw, T, builder_ckey, snap_builder), 50, TIMER_UNIQUE|TIMER_OVERRIDE)



/obj/machinery/robot_workshop/proc/_set_working_anim()
	if(building)
		icon_state = "h_lathe_wloop"

/obj/machinery/robot_workshop/proc/_finish_robot(
	design_path, control_mode_snap, ckey_snap,
	obj/item/behavior_assembly/A,
	obj/item/cert_card/CC,
	obj/item/robot_suit/suit,
	list/hw_snap, turf/T, builder_ckey,
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

	// Install robot hardware datums via robot_hardware_defaults proc
	if(hw_snap && hw_snap.len)
		// Build a flat list of hardware datums from the pending_hardware assoc list
		var/list/hw_list = list()
		for(var/slot in hw_snap)
			var/datum/robot_hardware/HW = hw_snap[slot]
			if(HW) hw_list += HW
		// Install first so R.installed_hardware is populated,
		// THEN apply SPECIAL so apply_special() fires on each datum correctly.
		for(var/datum/robot_hardware/HW in hw_list)
			HW.install(R)
		if(builder)
			apply_special_to_hardware(builder, R)

	// Validate assembly hardware slot coverage against what was actually installed.
	// _validate_build() ran pre-timer; re-check here in case of race or direct API use.
	if(A)
		for(var/datum/behavior_circuit/C in A.circuits)
			if(!C.needs_hardware || !C.hardware_slot_name || !C.required_hardware_type)
				continue
			var/found = FALSE
			if(hw_snap)
				var/datum/robot_hardware/HW = hw_snap[C.hardware_slot_name]
				if(HW && ispath(HW.type, text2path(C.hardware_slot_name)))
					found = TRUE
			if(!found)
				log_game("[builder_ckey] built [R] with assembly '[A.assembly_label]' but circuit '[C.circuit_name]' is missing required hardware in slot [C.hardware_slot_name] -- circuit will silently no-op.")


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
	if(behavior_assembly && (robot_cert || TRUE))
		var/datum/cpu_cert/ac = robot_cert ? robot_cert.base_cert : new /datum/cpu_cert/robot()
		if(!behavior_assembly.cert_compatible(ac))
			errors += "Assembly '[behavior_assembly.assembly_label]' requires capabilities this cert does not have."
		if(!robot_cert) qdel(ac)

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
	css += ".card{border:1px solid #2a7a52;padding:4px 8px;margin:3px 0;}"
	css += ".hw{border-left:3px solid #e8a020;}"
	css += ".sel{border-left:3px solid #4aed92;background:#071a0f;}"
	css += "hr{border:0;border-top:1px solid #2a7a52;margin:6px 0;}"
	css += "</style></head>"
	return css
