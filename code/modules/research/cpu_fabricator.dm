// ====================================================
// CPU CERT FABRICATOR
// Uses datum/browser HTML - same pattern as terminal.dm
//
// Tabs: Home | Base Certs | Upgrades | Behavior Asm. | Custom Build
// Behavior + Custom tabs only visible to TRAIT_ROBOT_WHISPERER users.
// AI MODS accessible to all.
//
// File: code/modules/research/cpu_fabricator.dm
// ====================================================

#define FAB_HOME       0
#define FAB_CERTS      1
#define FAB_UPGRADES   2
#define FAB_BEHAVIORS  3
#define FAB_CUSTOM     4
#define FAB_REPROG     5
#define FAB_AI         6

/obj/machinery/cpu_fabricator
	name = "CPU Certification Fabricator"
	desc = "A specialized fabricator for printing CPU certification cards, upgrade modules, and behavior assemblies."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "protolathe"
	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 20
	active_power_usage = 200

	var/list/designs = list()
	var/printing = FALSE
	var/fab_mode = FAB_HOME
	var/custom_trigger_id = null
	var/custom_response_id = null
	var/obj/item/behavior_assembly/inserted_assembly = null
	/// Assoc list: var_name -> value, set by workshop config fields
	var/list/custom_config = list()
	/// Workshop phase: 0=trigger, 1=response, 2=bonus(if earned), 3=configure, 4=review
	var/workshop_phase = 0
	/// Whether a bonus circuit slot was earned via luck roll
	var/bonus_slot_available = FALSE
	/// "trigger" or "response" - what kind of bonus the player chose
	var/bonus_slot_mode = null
	/// Type path string of the selected bonus circuit
	var/custom_bonus_id = null


/obj/machinery/cpu_fabricator/Initialize(mapload)
	. = ..()
	_build_design_list()
	AddComponent(/datum/component/material_container, \
		list(/datum/material/iron, /datum/material/glass, /datum/material/gold, /datum/material/silver), \
		MINERAL_MATERIAL_AMOUNT * 50, TRUE, \
		list(/obj/item/stack))


/obj/machinery/cpu_fabricator/proc/_build_design_list()
	designs += new /datum/cpu_fab_design/base/standard()
	designs += new /datum/cpu_fab_design/base/combat()
	designs += new /datum/cpu_fab_design/base/medical()
	designs += new /datum/cpu_fab_design/base/engineering()
	designs += new /datum/cpu_fab_design/upgrade/vtec()
	designs += new /datum/cpu_fab_design/upgrade/armor_plating()
	designs += new /datum/cpu_fab_design/upgrade/emp_shielding()
	designs += new /datum/cpu_fab_design/upgrade/hacking_module()
	designs += new /datum/cpu_fab_design/upgrade/designation_chip()
	designs += new /datum/cpu_fab_design/upgrade/rad_shielding()
	designs += new /datum/cpu_fab_design/upgrade/scavenger_array()
	designs += new /datum/cpu_fab_design/upgrade/saw_arm()
	designs += new /datum/cpu_fab_design/upgrade/stimpak_injector()
	designs += new /datum/cpu_fab_design/upgrade/faction_transponder()
	designs += new /datum/cpu_fab_design/behavior/sentry()
	designs += new /datum/cpu_fab_design/behavior/guardian()
	designs += new /datum/cpu_fab_design/behavior/medic_protocol()
	designs += new /datum/cpu_fab_design/behavior/watchdog()
	designs += new /datum/cpu_fab_design/behavior/deadman()
	designs += new /datum/cpu_fab_design/behavior/fortress()
	designs += new /datum/cpu_fab_design/behavior/drink_bot()
	designs += new /datum/cpu_fab_design/behavior/medbot()
	designs += new /datum/cpu_fab_design/behavior/night_watch()
	designs += new /datum/cpu_fab_design/behavior/escort()
	designs += new /datum/cpu_fab_design/behavior/last_resort()
	designs += new /datum/cpu_fab_design/behavior/sprint_chaser()
	designs += new /datum/cpu_fab_design/behavior/infiltrator()
	designs += new /datum/cpu_fab_design/behavior/field_surgeon()
	designs += new /datum/cpu_fab_design/behavior/broadcast_relay()
	// AI upgrade designs
	designs += new /datum/cpu_fab_design/ai_upgrade/surveillance()
	designs += new /datum/cpu_fab_design/ai_upgrade/malf_package()


/obj/machinery/cpu_fabricator/Destroy()
	var/datum/component/material_container/mats = GetComponent(/datum/component/material_container)
	if(mats)
		mats.retrieve_all()
	if(inserted_assembly)
		inserted_assembly.forceMove(get_turf(src))
		inserted_assembly = null
	designs.Cut()
	return ..()


/obj/machinery/cpu_fabricator/attackby(obj/item/O, mob/user)
	if(stat & (BROKEN|NOPOWER))
		return
	if(istype(O, /obj/item/behavior_assembly))
		if(inserted_assembly)
			to_chat(user, span_warning("Reprogram slot occupied. Eject the current assembly first."))
			return TRUE
		var/obj/item/behavior_assembly/A = O
		if(!user.transferItemToLoc(A, src))
			return TRUE
		inserted_assembly = A
		to_chat(user, span_notice("You slot [A] into the reprogramming port."))
		fab_mode = FAB_REPROG
		ui_interact(user)
		return TRUE
	if(istype(O, /obj/item/stack))
		var/datum/component/material_container/mats = GetComponent(/datum/component/material_container)
		if(!mats)
			return ..()
		if(!mats.has_space())
			to_chat(user, span_warning("Material hopper is full."))
			return TRUE
		mats.user_insert(O, user)
		ui_interact(user)
		return TRUE
	return ..()


/obj/machinery/cpu_fabricator/interact(mob/user)
	if(stat & (BROKEN|NOPOWER))
		return
	ui_interact(user)


// ============================================================
// CSS / SHARED HELPERS
// ============================================================

/obj/machinery/cpu_fabricator/proc/get_fab_css()
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
	css += "hr{border:0;border-top:1px solid #2a7a52;margin:6px 0;}"
	css += "</style></head>"
	return css


/obj/machinery/cpu_fabricator/proc/get_header()
	var/h = "<center><b>ROBCO INDUSTRIES UNIFIED OPERATING SYSTEM v.85</b><br>"
	h += "<b>COPYRIGHT 2075-2077 ROBCO INDUSTRIES</b><br>"
	h += "= CPU CERTIFICATION FABRICATOR =</center><br>"
	return h


/obj/machinery/cpu_fabricator/proc/get_nav(mob/user)
	var/n = ""
	n += _navlink("\[HOME\]",       FAB_HOME)
	n += " | "
	n += _navlink("\[CERTS\]",      FAB_CERTS)
	n += " | "
	n += _navlink("\[UPGRADES\]",   FAB_UPGRADES)
	if(HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
		n += " | "
		n += _navlink("\[BEHAVIOR\]",   FAB_BEHAVIORS)
		n += " | "
		n += _navlink("\[CUSTOM\]",     FAB_CUSTOM)
	n += " | "
	n += _navlink("\[AI MODS\]",    FAB_AI)
	if(inserted_assembly)
		n += " | "
		n += _navlink("\[REPROGRAM\]",  FAB_REPROG)
	n += "<br><hr>"
	return n


/obj/machinery/cpu_fabricator/proc/_navlink(label, mode_id)
	if(fab_mode == mode_id)
		return "<span class='good'><b>[label]</b></span>"
	return "<a href='byond://?src=[REF(src)];mode=[mode_id]'>[label]</a>"


// ============================================================
// MAIN UI DISPATCH
// ============================================================

/obj/machinery/cpu_fabricator/ui_interact(mob/user)
	. = ..()
	var/dat = get_fab_css()
	dat += get_header()
	dat += get_nav(user)
	if(printing)
		dat += "<span class='warn'>&gt; PRINTING IN PROGRESS...</span><br><br>"
	switch(fab_mode)
		if(FAB_HOME)
			dat += _render_home(user)
		if(FAB_CERTS)
			dat += _render_list(user, "cert")
		if(FAB_UPGRADES)
			dat += _render_list(user, "upgrade")
		if(FAB_BEHAVIORS)
			if(HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
				dat += _render_list(user, "behavior")
			else
				dat += "<span class='bad'>&gt; Robot Whisperer trait required.</span><br>"
		if(FAB_CUSTOM)
			if(HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
				dat += _render_custom(user)
			else
				dat += "<span class='bad'>&gt; Robot Whisperer trait required.</span><br>"
		if(FAB_AI)
			dat += _render_list(user, "ai_upgrade")
		if(FAB_REPROG)
			if(inserted_assembly)
				dat += _render_reprog(user)
			else
				dat += "<span class='bad'>&gt; No assembly in reprogramming slot.</span><br>"
	var/datum/browser/popup = new(user, "cpu_fabricator", name, 680, 500)
	popup.set_content(dat)
	popup.open()


// ============================================================
// HOME TAB
// ============================================================

/obj/machinery/cpu_fabricator/proc/_render_home(mob/user)
	var/dat = ""
	dat += "<b>MODULE DIRECTORY</b><br>"
	dat += "<div class='card'>"
	dat += "&gt; <a href='byond://?src=[REF(src)];mode=[FAB_CERTS]'><b>BASE CERTIFICATIONS</b></a>  <span class='dim'>chassis identity cards</span><br>"
	dat += "&gt; <a href='byond://?src=[REF(src)];mode=[FAB_UPGRADES]'><b>UPGRADE MODULES</b></a>  <span class='dim'>hardware enhancements</span><br>"
	dat += "&gt; <a href='byond://?src=[REF(src)];mode=[FAB_AI]'><b>AI MODS</b></a>  <span class='dim'>software packages for AI units</span><br>"
	if(HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
		dat += "&gt; <a href='byond://?src=[REF(src)];mode=[FAB_BEHAVIORS]'><b>BEHAVIOR ASSEMBLIES</b></a>  <span class='dim'>preset automation programs</span><br>"
		dat += "&gt; <a href='byond://?src=[REF(src)];mode=[FAB_CUSTOM]'><b>CUSTOM BUILD</b></a>  <span class='dim'>wire your own trigger/response pair</span><br>"
	else
		dat += "<span class='dim'>&gt; BEHAVIOR ASSEMBLIES  (requires Robot Whisperer trait)</span><br>"
	dat += "</div>"
	if(HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER) && ishuman(user))
		var/mob/living/carbon/human/H = user
		var/sensor_range = min(10, 5 + max(0, H.special_p - 5))
		var/luck_chance = H.special_l >= 7 ? (H.special_l - 6) * 15 : 0
		dat += "<br><b>OPERATOR PROFILE</b>  <span class='dim'>// Robot Whisperer</span><br>"
		dat += "<div class='card'>"
		dat += "<span class='dim'>INT</span> <span class='[H.special_i >= 6 ? "good" : "warn"]'>[H.special_i]</span>"
		dat += "  <span class='dim'>// [H.special_i >= 8 ? "UNRESTRICTED" : H.special_i >= 7 ? "ADV" : H.special_i >= 6 ? "STD" : "LOCKED"]</span><br>"
		dat += "<span class='dim'>PER</span> <span class='good'>[H.special_p]</span>  <span class='dim'>// sensor range: [sensor_range] tiles</span><br>"
		if(luck_chance > 0)
			dat += "<span class='dim'>LCK</span> <span class='good'>[H.special_l]</span>  <span class='good'>// [luck_chance]% BONUS CIRCUIT on Wire and Print</span><br>"
		else
			dat += "<span class='dim'>LCK [H.special_l]  // no bonus circuit (LCK 7+ needed)</span><br>"
		dat += "</div>"
	dat += "<br>"
	if(inserted_assembly)
		dat += "<b>REPROGRAM SLOT</b>  <span class='good'>// LOADED</span><br>"
		dat += "<div class='card'>"
		dat += "<span class='good'>[inserted_assembly.assembly_label]</span>"
		dat += "  <span class='dim'>circuits: [inserted_assembly.circuits.len]/[inserted_assembly.max_circuits] | range: [inserted_assembly.sensor_range] tiles</span><br>"
		dat += "&gt; <a href='byond://?src=[REF(src)];mode=[FAB_REPROG]'>\[configure\]</a>"
		dat += "  <a href='byond://?src=[REF(src)];eject_assembly=1'>\[eject\]</a>"
		dat += "</div>"
	else
		dat += "<b>REPROGRAM SLOT</b>  <span class='dim'>// EMPTY - insert a behavior assembly</span><br>"
	var/datum/component/material_container/mats = GetComponent(/datum/component/material_container)
	if(mats)
		dat += "<br><b>MATERIAL HOPPER</b>  <a href='byond://?src=[REF(src)];eject_mats=1'>\[eject all\]</a><br>"
		dat += "<div class='card'>"
		var/list/mpaths = list(/datum/material/iron, /datum/material/glass, /datum/material/gold, /datum/material/silver)
		var/list/mnames = list("iron", "glass", "gold", "silver")
		for(var/i in 1 to mpaths.len)
			var/amt = mats.get_material_amount(mpaths[i]) || 0
			var/filled = round(clamp(amt / 2000, 0, 1) * 10)
			var/bar = ""
			for(var/j in 1 to 10)
				bar += (j <= filled) ? "#" : "-"
			dat += "<span class='dim'>[mnames[i]]</span>  <span class='[amt > 0 ? "good" : "dim"]'>\[[bar]\]</span>  <span class='warn'>[amt]</span> <span class='dim'>cm3</span><br>"
		dat += "<span class='dim'>(Insert material sheets to load.)</span>"
		dat += "</div>"
	return dat

// ============================================================
// PRESET LIST RENDERER
// ============================================================

/obj/machinery/cpu_fabricator/proc/_render_list(mob/user, category)
	var/dat = ""
	var/count = 0
	for(var/datum/cpu_fab_design/D in designs)
		if(D.ui_category != category)
			continue
		count++
		var/dname = D.design_name
		var/ddesc = D.design_desc
		dat += "<div class='card'>"
		dat += "<b>[dname]</b>"
		if(D.required_tier > CERT_TIER_BASIC)
			dat += " <span class='warn'>(Tier 2 - Military)</span>"
		if(D.required_int > 0)
			dat += " <span class='dim'>(INT [D.required_int]+)</span>"
		dat += "<br>"
		dat += "<span class='dim'>[ddesc]</span><br>"
		// Show hardware requirements for behavior assemblies
		if(category == "behavior" && ispath(D.output_path, /obj/item/behavior_assembly))
			var/obj/item/behavior_assembly/test = new D.output_path()
			var/hw_list = ""
			for(var/datum/behavior_circuit/C in test.circuits)
				if(C.needs_hardware)
					hw_list += (hw_list ? ", " : "") + C.circuit_name
			qdel(test)
			if(hw_list)
				dat += "<span class='warn' style='font-size:0.88em'>&gt; HARDWARE REQUIRED for: [hw_list]</span><br>"
		if(D.cost && D.cost.len)
			var/cost_text = "Cost: "
			var/first = TRUE
			for(var/mat in D.cost)
				var/amt = D.cost[mat]
				if(!first)
					cost_text += ", "
				cost_text += "[amt] [mat]"
				first = FALSE
			dat += "<span class='dim'>[cost_text]</span><br>"
		var/can_print = !printing
		var/block_reason = ""
		if(D.requires_robot_whisperer && !HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
			can_print = FALSE
			block_reason = "Robot Whisperer required"
		else if(D.required_int > 0 && ishuman(user))
			var/mob/living/carbon/human/H = user
			if(H.special_i < D.required_int)
				can_print = FALSE
				block_reason = "INT [D.required_int]+ required (you have [H.special_i])"
		if(D.for_ai)
			dat += "<span class='dim'>(Installed on AI units, not robots.)</span><br>"
		if(can_print)
			dat += "<a href='byond://?src=[REF(src)];print=[D.id]'>&gt; Print</a>"
		else if(block_reason)
			dat += "<span class='dim'>&gt; Locked: [block_reason]</span>"
		else
			dat += "<span class='dim'>&gt; Locked</span>"
		dat += "</div>"
	if(!count)
		dat += "<span class='dim'>&gt; No designs in this category.</span><br>"
	return dat


// ============================================================
// CUSTOM BUILD WORKSHOP
// ============================================================

/obj/machinery/cpu_fabricator/proc/_render_custom(mob/user)
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.special_i < 6)
			var/dat2 = "<b>CUSTOM BEHAVIOR WORKSHOP</b><br>"
			dat2 += "<span class='bad'>&gt; INTELLIGENCE TOO LOW. INT 6 required to program assemblies.</span><br>"
			return dat2
	return _render_workshop(user)


/obj/machinery/cpu_fabricator/proc/_render_workshop(mob/user)
	var/dat = "<b>BEHAVIOR ASSEMBLY WORKSHOP</b>"
	// Phase nav
	dat += " - "
	var/list/phase_labels = list("1:TRIGGER", "2:RESPONSE", "3:CONFIGURE", "4:REVIEW")
	if(bonus_slot_available)
		phase_labels += "5:BONUS CIRCUIT"
	var/list/phase_ids = list(0, 1, 3, 4)
	if(bonus_slot_available)
		phase_ids += 2
	for(var/i in 1 to phase_labels.len)
		var/ph = phase_ids[i]
		var/label = phase_labels[i]
		if(workshop_phase == ph)
			dat += "<span class='good'><b>\[[label]\]</b></span>"
		else
			dat += "<a href='byond://?src=[REF(src)];workshop_phase=[ph]'>\[[label]\]</a>"
		if(i < phase_labels.len)
			dat += " "
	dat += "<br>"
	// Builder stats
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/sensor = min(10, 5 + max(0, H.special_p - 5))
		dat += "<span class='dim'>INT [H.special_i] | PER [H.special_p] (sensor: [sensor] tiles)"
		if(H.special_l >= 7)
			var/lchance = (H.special_l - 6) * 15
			dat += " | <span class='good'>LCK [H.special_l]: [lchance]% bonus slot</span>"
		dat += "</span><br>"
	if(bonus_slot_available && bonus_slot_mode)
		dat += "<span class='good'>&gt; BONUS SLOT ACTIVE: [bonus_slot_mode == "trigger" ? "second TRIGGER" : "second RESPONSE"]"
		if(custom_bonus_id)
			dat += " - [_resolve_circuit_name(custom_bonus_id)]"
		dat += "</span><br>"
	dat += "<hr>"
	switch(workshop_phase)
		if(0)
			dat += _workshop_phase_trigger(user)
		if(1)
			dat += _workshop_phase_response(user)
		if(2)
			dat += _workshop_phase_bonus(user)
		if(3)
			dat += _workshop_phase_configure(user)
		if(4)
			dat += _workshop_phase_review(user)
		else
			dat += _workshop_phase_trigger(user)
	return dat


// Phase 1: Pick a trigger - split into STANDARD and HARDWARE sections
/obj/machinery/cpu_fabricator/proc/_workshop_phase_trigger(mob/user)
	var/dat = "<b>STEP 1 - SELECT TRIGGER</b><br>"
	dat += "<span class='dim'>The trigger defines WHEN your assembly acts.</span><br><br>"
	var/list/standard_triggers = list()
	var/list/hardware_triggers = list()
	for(var/T in subtypesof(/datum/behavior_circuit/trigger))
		var/datum/behavior_circuit/trigger/inst = new T
		var/entry = list("path"=T, "name"=inst.circuit_name, "desc"=inst.circuit_desc, "tut"=inst.tutorial_text, "cpu"=inst.cpu_cost, "hw"=inst.needs_hardware)
		if(inst.needs_hardware)
			hardware_triggers += list(entry)
		else
			standard_triggers += list(entry)
		qdel(inst)
	dat += "<b>STANDARD TRIGGERS</b> <span class='dim'>(work on any robot)</span><br>"
	for(var/list/E in standard_triggers)
		var/tpath = "[E["path"]]"
		dat += "<div class='card'>"
		if(custom_trigger_id == tpath)
			dat += "<span class='good'><b>&gt; * [E["name"]]</b></span> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		else
			dat += "<a href='byond://?src=[REF(src)];sel_trigger=[tpath]'><b>&gt; [E["name"]]</b></a> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		dat += "<span class='dim'>[E["desc"]]</span><br>"
		dat += "<span class='dim' style='font-size:0.85em'>[E["tut"]]</span>"
		dat += "</div>"
	dat += "<br><b>HARDWARE TRIGGERS</b> <span class='warn'>(require specific modules in robot)</span><br>"
	for(var/list/E in hardware_triggers)
		var/tpath = "[E["path"]]"
		dat += "<div class='card hw'>"
		if(custom_trigger_id == tpath)
			dat += "<span class='good'><b>&gt; * [E["name"]]</b></span> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		else
			dat += "<a href='byond://?src=[REF(src)];sel_trigger=[tpath]'><b>&gt; [E["name"]]</b></a> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		dat += "<span class='dim'>[E["desc"]]</span><br>"
		dat += "<span class='dim' style='font-size:0.85em'>[E["tut"]]</span>"
		dat += "</div>"
	if(custom_trigger_id)
		dat += "<br><a href='byond://?src=[REF(src)];workshop_phase=1'>&gt; Continue to Response selection</a><br>"
	return dat


// Phase 2: Pick a response - split into STANDARD and HARDWARE sections
/obj/machinery/cpu_fabricator/proc/_workshop_phase_response(mob/user)
	var/dat = "<b>STEP 2 - SELECT RESPONSE</b><br>"
	dat += "<span class='dim'>The response defines WHAT happens when the trigger fires.</span><br><br>"
	var/list/standard_responses = list()
	var/list/hardware_responses = list()
	for(var/T in subtypesof(/datum/behavior_circuit/response))
		var/datum/behavior_circuit/response/inst = new T
		var/entry = list("path"=T, "name"=inst.circuit_name, "desc"=inst.circuit_desc, "tut"=inst.tutorial_text, "cpu"=inst.cpu_cost, "hw"=inst.needs_hardware)
		if(inst.needs_hardware)
			hardware_responses += list(entry)
		else
			standard_responses += list(entry)
		qdel(inst)
	dat += "<b>STANDARD RESPONSES</b> <span class='dim'>(work on any robot)</span><br>"
	for(var/list/E in standard_responses)
		var/rpath = "[E["path"]]"
		dat += "<div class='card'>"
		if(custom_response_id == rpath)
			dat += "<span class='good'><b>&gt; * [E["name"]]</b></span> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		else
			dat += "<a href='byond://?src=[REF(src)];sel_response=[rpath]'><b>&gt; [E["name"]]</b></a> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		dat += "<span class='dim'>[E["desc"]]</span><br>"
		dat += "<span class='dim' style='font-size:0.85em'>[E["tut"]]</span>"
		dat += "</div>"
	dat += "<br><b>HARDWARE RESPONSES</b> <span class='warn'>(require specific modules in robot)</span><br>"
	for(var/list/E in hardware_responses)
		var/rpath = "[E["path"]]"
		dat += "<div class='card hw'>"
		if(custom_response_id == rpath)
			dat += "<span class='good'><b>&gt; * [E["name"]]</b></span> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		else
			dat += "<a href='byond://?src=[REF(src)];sel_response=[rpath]'><b>&gt; [E["name"]]</b></a> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		dat += "<span class='dim'>[E["desc"]]</span><br>"
		dat += "<span class='dim' style='font-size:0.85em'>[E["tut"]]</span>"
		dat += "</div>"
	if(custom_response_id)
		// Advance button: roll for bonus if eligible, otherwise go to configure
		dat += "<br><a href='byond://?src=[REF(src)];advance_from_response=1'>&gt; Continue</a><br>"
	return dat


// Phase 2B: Bonus slot - pick a second trigger or response
/obj/machinery/cpu_fabricator/proc/_workshop_phase_bonus(mob/user)
	if(!bonus_slot_available)
		workshop_phase = 3
		return _workshop_phase_configure(user)
	var/dat = "<b>BONUS CIRCUIT SLOT</b><br>"
	dat += "<span class='good'>&gt; Your Luck stat earned a bonus circuit slot! Wire in one extra trigger OR one extra response.</span><br><br>"
	if(!bonus_slot_mode)
		dat += "<a href='byond://?src=[REF(src)];set_bonus_mode=trigger'>\[Add a second TRIGGER\]</a> "
		dat += "<a href='byond://?src=[REF(src)];set_bonus_mode=response'>\[Add a second RESPONSE\]</a><br>"
		return dat
	// Mode chosen - show circuit list
	dat += "<span class='dim'>Mode: second <b>[bonus_slot_mode]</b></span> - <a href='byond://?src=[REF(src)];set_bonus_mode=clear'>\[change\]</a><br><br>"
	var/base_path = bonus_slot_mode == "trigger" ? /datum/behavior_circuit/trigger : /datum/behavior_circuit/response
	var/list/standard_bonus = list()
	var/list/hardware_bonus = list()
	for(var/T in subtypesof(base_path))
		var/datum/behavior_circuit/inst = new T
		var/entry = list("path"=T, "name"=inst.circuit_name, "desc"=inst.circuit_desc, "cpu"=inst.cpu_cost, "hw"=inst.needs_hardware)
		if(inst.needs_hardware)
			hardware_bonus += list(entry)
		else
			standard_bonus += list(entry)
		qdel(inst)
	dat += "<b>STANDARD</b><br>"
	for(var/list/E in standard_bonus)
		var/bpath = "[E["path"]]"
		dat += "<div class='card'>"
		if(custom_bonus_id == bpath)
			dat += "<span class='good'><b>&gt; * [E["name"]]</b></span> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		else
			dat += "<a href='byond://?src=[REF(src)];sel_bonus=[bpath]'>&gt; [E["name"]]</a> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		dat += "<span class='dim'>[E["desc"]]</span>"
		dat += "</div>"
	dat += "<br><b>HARDWARE</b> <span class='warn'>(require specific modules)</span><br>"
	for(var/list/E in hardware_bonus)
		var/bpath = "[E["path"]]"
		dat += "<div class='card hw'>"
		if(custom_bonus_id == bpath)
			dat += "<span class='good'><b>&gt; * [E["name"]]</b></span> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		else
			dat += "<a href='byond://?src=[REF(src)];sel_bonus=[bpath]'>&gt; [E["name"]]</a> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		dat += "<span class='dim'>[E["desc"]]</span>"
		dat += "</div>"
	if(custom_bonus_id)
		dat += "<br><a href='byond://?src=[REF(src)];build_custom_confirm=1'><b>&gt; WIRE AND PRINT WITH BONUS</b></a><br>"
	dat += "<a href='byond://?src=[REF(src)];build_custom_confirm=1'><span class='dim'>&gt; Skip - print without bonus</span></a><br>"
	return dat


// Phase 3: Configure vars for selected circuits
/obj/machinery/cpu_fabricator/proc/_workshop_phase_configure(mob/user)
	var/dat = "<b>STEP 3 - CONFIGURE</b><br>"
	dat += "<span class='dim'>Adjust parameters for your circuits. Leave defaults if unsure.</span><br><hr>"
	// Trigger
	dat += "<b>TRIGGER:</b> <span class='[custom_trigger_id ? "good" : "bad"]'>[custom_trigger_id ? _resolve_circuit_name(custom_trigger_id) : "(none selected)"]</span>"
	if(custom_trigger_id)
		dat += " <a href='byond://?src=[REF(src)];workshop_phase=0'>\[change\]</a>"
	dat += "<br>"
	if(custom_trigger_id)
		var/trigger_type = text2path(custom_trigger_id)
		if(trigger_type)
			var/datum/behavior_circuit/TI = new trigger_type()
			dat += _render_circuit_config_inline(TI, "trigger")
			qdel(TI)
	dat += "<hr><b>RESPONSE:</b> <span class='[custom_response_id ? "good" : "bad"]'>[custom_response_id ? _resolve_circuit_name(custom_response_id) : "(none selected)"]</span>"
	if(custom_response_id)
		dat += " <a href='byond://?src=[REF(src)];workshop_phase=1'>\[change\]</a>"
	dat += "<br>"
	if(custom_response_id)
		var/response_type = text2path(custom_response_id)
		if(response_type)
			var/datum/behavior_circuit/RI = new response_type()
			dat += _render_circuit_config_inline(RI, "response")
			qdel(RI)
	// Bonus circuit config if applicable
	if(bonus_slot_available && bonus_slot_mode && custom_bonus_id)
		dat += "<hr><b>BONUS [uppertext(bonus_slot_mode)]:</b> <span class='good'>[_resolve_circuit_name(custom_bonus_id)]</span><br>"
		var/bonus_type = text2path(custom_bonus_id)
		if(bonus_type)
			var/datum/behavior_circuit/BI = new bonus_type()
			dat += _render_circuit_config_inline(BI, "bonus")
			qdel(BI)
	dat += "<hr>"
	if(custom_trigger_id && custom_response_id)
		dat += "<a href='byond://?src=[REF(src)];workshop_phase=4'>&gt; Continue to Review</a><br>"
	else
		dat += "<span class='bad'>&gt; Select trigger and response first.</span><br>"
	return dat


// Phase 4: Review + print
/obj/machinery/cpu_fabricator/proc/_workshop_phase_review(mob/user)
	var/dat = "<b>STEP 4 - REVIEW & PRINT</b><br>"
	dat += "<span class='dim'>Final check before printing. CPU cost must fit your robot's cert.</span><br><hr>"
	var/t_name = custom_trigger_id ? _resolve_circuit_name(custom_trigger_id) : "(none)"
	var/r_name = custom_response_id ? _resolve_circuit_name(custom_response_id) : "(none)"
	var/t_cpu = 0
	var/r_cpu = 0
	var/b_cpu = 0
	if(custom_trigger_id)
		var/T = text2path(custom_trigger_id)
		if(T)
			var/datum/behavior_circuit/inst = new T
			t_cpu = inst.cpu_cost
			qdel(inst)
	if(custom_response_id)
		var/T = text2path(custom_response_id)
		if(T)
			var/datum/behavior_circuit/inst = new T
			r_cpu = inst.cpu_cost
			qdel(inst)
	if(bonus_slot_available && custom_bonus_id)
		var/T = text2path(custom_bonus_id)
		if(T)
			var/datum/behavior_circuit/inst = new T
			b_cpu = inst.cpu_cost
			qdel(inst)
	var/total_cpu = t_cpu + r_cpu + b_cpu
	dat += "<b>TRIGGER:</b>  <span class='[custom_trigger_id ? "good" : "bad"]'>[t_name]</span>"
	if(custom_trigger_id)
		dat += " <a href='byond://?src=[REF(src)];workshop_phase=0'>\[change\]</a>"
	dat += " <span class='dim'>CPU: [t_cpu]</span><br>"
	dat += "<b>RESPONSE:</b> <span class='[custom_response_id ? "good" : "bad"]'>[r_name]</span>"
	if(custom_response_id)
		dat += " <a href='byond://?src=[REF(src)];workshop_phase=1'>\[change\]</a>"
	dat += " <span class='dim'>CPU: [r_cpu]</span><br>"
	if(bonus_slot_available && bonus_slot_mode && custom_bonus_id)
		dat += "<b>BONUS [uppertext(bonus_slot_mode)]:</b> <span class='good'>[_resolve_circuit_name(custom_bonus_id)]</span> <span class='dim'>CPU: [b_cpu]</span><br>"
	dat += "<b>TOTAL CPU:</b> <span class='warn'>[total_cpu]</span><br>"
	// Material cost
	var/datum/cpu_fab_design/behavior/dummy = new()
	var/cost_dat = ""
	for(var/mat in dummy.cost)
		cost_dat += "[dummy.cost[mat]] [mat] cm3, "
	qdel(dummy)
	if(cost_dat)
		dat += "<hr><span class='dim'>Material cost: [copytext(cost_dat, 1, length(cost_dat)-1)]</span><br>"
	dat += "<hr>"
	if(printing)
		dat += "<span class='warn'>&gt; PRINTING IN PROGRESS...</span><br>"
	else if(custom_trigger_id && custom_response_id)
		dat += "<a href='byond://?src=[REF(src)];build_custom=1'><b>&gt; WIRE AND PRINT</b></a>"
		dat += "  <a href='byond://?src=[REF(src)];clear_workshop=1'><span class='dim'>\[clear\]</span></a><br>"
	else
		dat += "<span class='bad'>&gt; Select trigger and response first.</span><br>"
	return dat


// ============================================================
// CONFIG HELPERS
// ============================================================

/obj/machinery/cpu_fabricator/proc/_get_var_meta(varname)
	switch(varname)
		if("damage_threshold")  return list("Damage Threshold",   "Min damage per tick to fire (default 10). Lower = more sensitive.")
		if("charge_threshold")  return list("Charge Threshold",   "Cell ratio 0.0-1.0 to trigger at (default 0.2 = 20% charge).")
		if("restore_threshold") return list("Restore Threshold",  "Cell ratio to consider 'restored' (default 0.5 = 50%).")
		if("interval_ticks")    return list("Interval (ticks)",   "How often to fire in ticks. 10 ticks = 1 second (default 100 = 10s).")
		if("approach_range")    return list("Approach Range",     "Tiles away a mob must be to trigger (default 3).")
		if("health_threshold")  return list("Health Threshold",   "Raw health value below which an injured mob triggers this (default 50).")
		if("night_start")       return list("Night Start (ticks)","World time tick when night begins (default 180000).")
		if("night_end")         return list("Night End (ticks)",  "World time tick when night ends (default 360000).")
		if("spot_cooldown")     return list("Spot Cooldown",      "Ticks between enemy scans (default 50 = 5s).")
		if("check_cooldown")    return list("Check Cooldown",     "Ticks between checks (default 30-50).")
		if("pressure_min")      return list("Min Pressure (kPa)", "kPa below which atmos is considered dangerous (default 60).")
		if("o2_min")            return list("Min O2 (%)",         "O2 percentage below which atmos is considered dangerous (default 16).")
		if("zone_x1")           return list("Zone X1",            "West boundary of GPS trigger zone.")
		if("zone_y1")           return list("Zone Y1",            "South boundary of GPS trigger zone.")
		if("zone_x2")           return list("Zone X2",            "East boundary of GPS trigger zone.")
		if("zone_y2")           return list("Zone Y2",            "North boundary of GPS trigger zone.")
		if("alert_message")     return list("Alert Message",      "Text broadcast over radio when this fires.")
		if("say_string")        return list("Say Text",           "What the robot says out loud when this fires.")
		if("emote_text")        return list("Emote Text",         "Action text: robot will do '\[robot name\] \[text\].' visibly.")
		if("repair_amount")     return list("Repair Amount",      "HP repaired per pulse (default 15). Higher = more cell drain.")
		if("stun_duration")     return list("Stun Duration",      "Ticks to stun target (default 20 = 2s).")
		if("smoke_range")       return list("Smoke Range",        "Radius of smoke cloud in tiles (default 2).")
		if("smoke_duration")    return list("Smoke Duration",     "How long smoke lasts in ticks (default 15).")
		if("inject_amount")     return list("Inject Amount (u)",  "Units of reagent injected per trigger (default 5).")
		if("target_friendly")   return list("Friendlies Only",    "TRUE = only inject allies; FALSE = inject anyone nearby.")
		if("grab_range")        return list("Grab Range",         "Tiles away to grab items from (default 2).")
		if("detonation_time")   return list("Detonation Time (s)","Seconds before explosion after priming (default 3).")
		if("move_dir")          return list("Move Direction",     "Direction to step: NORTH=1, SOUTH=2, EAST=4, WEST=8.")
		if("force_state")       return list("Light Force State",  "-1=toggle, 0=force off, 1=force on.")
		if("sound_file")        return list("Sound File",         "Path to sound file (e.g. sound/machines/beep.ogg).")
		if("sound_volume")      return list("Sound Volume",       "0-100. Default 50.")
		if("display_text")      return list("Display Text",       "Message shown on the robot's screen display IC.")
	return null


/obj/machinery/cpu_fabricator/proc/_get_configurable_vars()
	return list(
		"damage_threshold", "charge_threshold", "restore_threshold",
		"interval_ticks", "approach_range", "health_threshold",
		"night_start", "night_end", "pressure_min", "o2_min",
		"zone_x1", "zone_y1", "zone_x2", "zone_y2",
		"alert_message", "say_string", "emote_text", "repair_amount",
		"stun_duration", "smoke_range", "smoke_duration",
		"inject_amount", "target_friendly", "grab_range",
		"detonation_time", "move_dir", "force_state",
		"sound_file", "sound_volume", "display_text"
	)


/obj/machinery/cpu_fabricator/proc/_render_circuit_config_inline(datum/behavior_circuit/C, prefix)
	var/dat = ""
	dat += "<span class='dim' style='font-size:0.88em;border-left:2px solid #2a7a52;padding-left:4px'>[C.tutorial_text]</span><br>"
	var/list/allowed = _get_configurable_vars()
	var/has_vars = FALSE
	for(var/varname in allowed)
		var/has_var = FALSE
		for(var/vn in C.vars)
			if(vn == varname)
				has_var = TRUE
				break
		if(!has_var)
			continue
		var/default_val = C.vars[varname]
		var/cur_val = (custom_config["[prefix].[varname]"] != null) ? custom_config["[prefix].[varname]"] : default_val
		var/list/meta = _get_var_meta(varname)
		var/label = meta ? meta[1] : varname
		var/hint  = meta ? meta[2] : ""
		dat += "<div style='margin:2px 0;padding:2px 4px;border-left:1px solid #2a7a52'>"
		dat += "<b><span class='good'>[label]</span></b>"
		dat += " = <span class='warn'>[cur_val]</span>"
		dat += " \[<a href='byond://?src=[REF(src)];prompt_config=[prefix].[varname]'>edit</a>\]"
		if(hint)
			dat += "<br><span class='dim' style='font-size:0.82em'>([hint])</span>"
		dat += "</div>"
		has_vars = TRUE
	if(!has_vars)
		dat += "<span class='dim'>&gt; No configurable parameters for this circuit.</span><br>"
	return dat


/obj/machinery/cpu_fabricator/proc/_resolve_circuit_name(path_text)
	var/T = text2path(path_text)
	if(!T)
		return path_text
	var/datum/behavior_circuit/inst = new T
	var/n = inst.circuit_name
	qdel(inst)
	return n


// ============================================================
// REPROGRAM TAB
// Two modes: configure vars (free) or full rewire (costs gold)
// ============================================================

#define REPROGRAM_COST_GOLD 100

/obj/machinery/cpu_fabricator/proc/_render_reprog(mob/user)
	if(!inserted_assembly)
		return "<span class='bad'>&gt; No assembly in reprogramming slot.</span><br>"
	var/obj/item/behavior_assembly/A = inserted_assembly
	var/dat = "<b>CONFIGURE: [A.assembly_label]</b><br>"
	dat += "<span class='dim'>Slots: [A.circuits.len]/[A.max_circuits] | Range: [A.sensor_range] tiles</span><br>"
	if(!A.slot_expansion_used && HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER) && A.max_circuits < 4)
		dat += "<br><b>EXPAND CIRCUIT SLOT</b>  <span class='dim'>(one-time | costs [REPROGRAM_COST_GOLD] gold)</span><br>"
		dat += "<span class='dim'>Adds one empty slot so you can install an additional circuit. Cannot be undone.</span><br>"
		dat += "&gt; <a href='byond://?src=[REF(src)];reprog_expand=trigger'>\[+ TRIGGER slot\]</a>"
		dat += "  <a href='byond://?src=[REF(src)];reprog_expand=response'>\[+ RESPONSE slot\]</a><br>"
		dat += "<hr>"
	if(A.circuits.len)
		dat += "<br><b>INSTALLED CIRCUITS:</b><br>"
		for(var/datum/behavior_circuit/C in A.circuits)
			var/hw_label = C.needs_hardware ? "  <span class='warn'>HARDWARE</span>" : ""
			dat += "<span class='dim'>&gt; [C.circuit_name][hw_label]</span><br>"
	dat += "<hr>"
	dat += "<b>CONFIGURE VARIABLES</b>  <span class='dim'>(free - no material cost)</span><br>"
	dat += "<span class='dim'>Changes apply immediately. Preset protocols cannot be rewired, only tuned.</span><br>"
	if(A.circuits.len)
		for(var/datum/behavior_circuit/C in A.circuits)
			dat += "<br><span class='good'>[C.circuit_name]</span><br>"
			dat += _render_circuit_config_inline(C, "reprogram_[A.circuits.Find(C)]")
		dat += "<br><a href='byond://?src=[REF(src)];reprogram_vars=1'><b>&gt; Apply Changes</b></a><br>"
	else
		dat += "<span class='dim'>&gt; No circuits installed.</span><br>"
	dat += "<hr>"
	dat += "<a href='byond://?src=[REF(src)];eject_assembly=1'>&gt; Eject Assembly</a><br>"
	return dat

// One-time slot expansion at reprogram terminal.
// No roll - player picks trigger or response type, pays gold, slot is added.
/obj/machinery/cpu_fabricator/proc/_reprog_expand(mob/user, slot_type)
	if(!inserted_assembly)
		return
	var/obj/item/behavior_assembly/A = inserted_assembly
	if(A.slot_expansion_used)
		to_chat(user, span_warning("This assembly's slot has already been expanded."))
		return
	if(!HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
		to_chat(user, span_warning("Requires Robot Whisperer expertise."))
		return
	if(slot_type != "trigger" && slot_type != "response")
		return
	if(A.max_circuits >= 4)
		to_chat(user, span_warning("Assembly is already at maximum circuit capacity."))
		return
	var/datum/component/material_container/mats = GetComponent(/datum/component/material_container)
	if(mats)
		var/have_gold = mats.get_material_amount(/datum/material/gold) || 0
		if(have_gold < REPROGRAM_COST_GOLD)
			to_chat(user, span_warning("Need [REPROGRAM_COST_GOLD] gold cm3, have [have_gold] cm3."))
			return
		mats.use_amount_mat(REPROGRAM_COST_GOLD, /datum/material/gold)
	A.slot_expansion_used = TRUE
	A.max_circuits++
	to_chat(user, span_good("Slot expanded. [A.assembly_label] now has [A.max_circuits] slots."))
	visible_message(span_notice("[src] hums as it reconfigures [A.assembly_label]'s circuit architecture."))
	log_game("[key_name(user)] expanded '[A.assembly_label]' +[slot_type] to [A.max_circuits] slots at [AREACOORD(src)]")


// Apply variable changes to installed circuits (free, in-place)
/obj/machinery/cpu_fabricator/proc/_reprogram_vars(mob/user)
	if(!inserted_assembly)
		return
	var/obj/item/behavior_assembly/A = inserted_assembly
	if(!A.circuits.len)
		return
	var/changed = 0
	for(var/datum/behavior_circuit/C in A.circuits)
		var/idx = A.circuits.Find(C)
		var/prefix = "reprogram_[idx]"
		var/list/allowed = _get_configurable_vars()
		for(var/varname in allowed)
			var/key = "[prefix].[varname]"
			if(!(key in custom_config))
				continue
			var/has_var = FALSE
			for(var/vn in C.vars)
				if(vn == varname)
					has_var = TRUE
					break
			if(!has_var)
				continue
			var/old_val = C.vars[varname]
			var/new_val = custom_config[key]
			C.vars[varname] = new_val
			if("[old_val]" != "[new_val]")
				changed++
				log_game("[key_name(user)] reprogrammed var '[varname]' on [C.circuit_name] in '[A.assembly_label]' at [AREACOORD(src)]: [old_val] -> [new_val]")
	custom_config = list()
	to_chat(user, span_notice("Variable changes applied. [changed] parameter(s) updated."))
	visible_message(span_notice("[src] completes a configuration update."))


/obj/machinery/cpu_fabricator/proc/_reprogram(mob/user)
	if(!inserted_assembly || printing)
		return
	if(!custom_trigger_id || !custom_response_id)
		return
	if(!HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
		to_chat(user, span_warning("You lack the expertise to reprogram this assembly."))
		return
	var/trigger_type = text2path(custom_trigger_id)
	var/response_type = text2path(custom_response_id)
	if(!trigger_type || !ispath(trigger_type, /datum/behavior_circuit/trigger))
		return
	if(!response_type || !ispath(response_type, /datum/behavior_circuit/response))
		return
	var/datum/component/material_container/mats = GetComponent(/datum/component/material_container)
	if(mats)
		var/have_gold = mats.get_material_amount(/datum/material/gold) || 0
		if(have_gold < REPROGRAM_COST_GOLD)
			to_chat(user, span_warning("Not enough gold. Need [REPROGRAM_COST_GOLD] cm3, have [have_gold] cm3."))
			return
		mats.use_amount_mat(REPROGRAM_COST_GOLD, /datum/material/gold)
	var/obj/item/behavior_assembly/A = inserted_assembly
	QDEL_LIST(A.circuits)
	A.circuits = list()
	var/datum/behavior_circuit/trigger/TR = new trigger_type()
	var/datum/behavior_circuit/response/RE = new response_type()
	TR.response = RE
	A.circuits += TR
	A.circuits += RE
	A.assembly_label = "[_resolve_circuit_name(custom_trigger_id)] -> [_resolve_circuit_name(custom_response_id)]"
	A.name = "behavior assembly - [A.assembly_label]"
	custom_trigger_id = null
	custom_response_id = null
	to_chat(user, span_notice("Assembly rewired: [A.assembly_label]."))
	visible_message(span_notice("[src] completes a full rewire cycle."))
	log_game("[key_name(user)] full-rewired assembly '[A.assembly_label]' at [AREACOORD(src)]")


// ============================================================
// TOPIC
// ============================================================

/obj/machinery/cpu_fabricator/Topic(href, href_list)
	if(..(href, href_list))
		return TRUE
	if(!usr || !usr.canUseTopic(src))
		return
	if(href_list["mode"])
		fab_mode = text2num(href_list["mode"])
		ui_interact(usr)
		return
	if(href_list["print"])
		var/datum/cpu_fab_design/D = _get_design(href_list["print"])
		if(D)
			_print_card(D, usr)
		ui_interact(usr)
		return
	if(href_list["sel_trigger"])
		var/T = text2path(href_list["sel_trigger"])
		if(T && ispath(T, /datum/behavior_circuit/trigger))
			custom_trigger_id = href_list["sel_trigger"]
		ui_interact(usr)
		return
	if(href_list["sel_response"])
		var/T = text2path(href_list["sel_response"])
		if(T && ispath(T, /datum/behavior_circuit/response))
			custom_response_id = href_list["sel_response"]
		ui_interact(usr)
		return
	if(href_list["advance_from_response"])
		workshop_phase = 3
		ui_interact(usr)
		return
	if(href_list["set_bonus_mode"])
		var/bmode = href_list["set_bonus_mode"]
		if(bmode == "clear")
			bonus_slot_mode = null
			custom_bonus_id = null
		else if(bmode == "trigger" || bmode == "response")
			bonus_slot_mode = bmode
			custom_bonus_id = null
		ui_interact(usr)
		return
	if(href_list["sel_bonus"])
		var/base_path = bonus_slot_mode == "trigger" ? /datum/behavior_circuit/trigger : /datum/behavior_circuit/response
		var/T = text2path(href_list["sel_bonus"])
		if(T && ispath(T, base_path))
			custom_bonus_id = href_list["sel_bonus"]
		ui_interact(usr)
		return
	if(href_list["build_custom"])
		// LCK roll fires NOW when player clicks Wire and Print
		if(!bonus_slot_available && ishuman(usr))
			var/mob/living/carbon/human/H = usr
			if(H.special_l >= 7)
				var/luck_chance = (H.special_l - 6) * 15
				if(prob(luck_chance))
					bonus_slot_available = TRUE
					to_chat(usr, span_good("Lucky! Pick a bonus circuit to wire into this assembly."))
		if(bonus_slot_available)
			workshop_phase = 2
		else
			_build_custom(usr)
		ui_interact(usr)
		return
	if(href_list["build_custom_confirm"])
		_build_custom(usr)
		ui_interact(usr)
		return
	if(href_list["workshop_phase"])
		workshop_phase = text2num(href_list["workshop_phase"])
		ui_interact(usr)
		return
	if(href_list["set_config"])
		var/key = href_list["set_config"]
		var/val = href_list["val"]
		if(key && val != null)
			custom_config[key] = val
		ui_interact(usr)
		return
	if(href_list["prompt_config"])
		var/key = href_list["prompt_config"]
		var/cur = custom_config[key]
		if(cur == null)
			var/dot = findtext(key, ".")
			var/prefix = copytext(key, 1, dot)
			var/varname = copytext(key, dot + 1)
			// Determine circuit for this prefix
			var/datum/behavior_circuit/inst = null
			if(prefix == "trigger" && custom_trigger_id)
				inst = new(text2path(custom_trigger_id))
			else if(prefix == "response" && custom_response_id)
				inst = new(text2path(custom_response_id))
			else if(prefix == "bonus" && custom_bonus_id)
				inst = new(text2path(custom_bonus_id))
			else
				// reprogram_N prefix - get from installed circuit
				var/idx = text2num(copytext(prefix, findtext(prefix, "_") + 1))
				if(inserted_assembly && idx >= 1 && idx <= inserted_assembly.circuits.len)
					inst = inserted_assembly.circuits[idx]
			if(inst && (varname in inst.vars))
				cur = "[inst.vars[varname]]"
			if(!isnull(inst) && !istype(inst, /obj/item/behavior_assembly))
				// Only qdel if we newed it (not a ref to an installed circuit)
				if(prefix == "trigger" || prefix == "response" || prefix == "bonus")
					qdel(inst)
		if(cur == null)
			cur = ""
		var/varname2 = copytext(key, findtext(key, ".") + 1)
		var/new_val = input(usr, "Set value for [varname2]:", "Configure Assembly", cur)
		if(new_val != null)
			custom_config[key] = new_val
		ui_interact(usr)
		return
	if(href_list["clear_workshop"])
		custom_trigger_id = null
		custom_response_id = null
		custom_bonus_id = null
		bonus_slot_mode = null
		bonus_slot_available = FALSE
		custom_config = list()
		workshop_phase = 0
		ui_interact(usr)
		return
	if(href_list["reprog_expand"])
		_reprog_expand(usr, href_list["reprog_expand"])
		ui_interact(usr)
		return
	if(href_list["eject_assembly"])
		if(inserted_assembly)
			inserted_assembly.forceMove(get_turf(src))
			to_chat(usr, span_notice("You retrieve [inserted_assembly] from the reprogramming slot."))
			inserted_assembly = null
			custom_config = list()
			if(fab_mode == FAB_REPROG)
				fab_mode = FAB_HOME
		ui_interact(usr)
		return
	if(href_list["eject_mats"])
		var/datum/component/material_container/mats = GetComponent(/datum/component/material_container)
		if(mats)
			mats.retrieve_all(get_turf(src))
		ui_interact(usr)
		return
	if(href_list["reprogram_vars"])
		_reprogram_vars(usr)
		ui_interact(usr)
		return
	if(href_list["reprogram"])
		_reprogram(usr)
		ui_interact(usr)
		return


/obj/machinery/cpu_fabricator/proc/_get_design(id)
	for(var/datum/cpu_fab_design/D in designs)
		if(D.id == id)
			return D
	return null


// ============================================================
// PRINTING - preset design
// ============================================================

/obj/machinery/cpu_fabricator/proc/_print_card(datum/cpu_fab_design/D, mob/user)
	if(printing)
		to_chat(user, span_warning("The fabricator is already printing."))
		return
	if(D.requires_robot_whisperer && !HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
		to_chat(user, span_warning("You don't have the knowledge to program behavior assemblies."))
		return
	if(D.required_int > 0 && ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.special_i < D.required_int)
			to_chat(user, span_warning("Intelligence too low. (Requires [D.required_int])"))
			return
	if(!_spend_materials(D, user))
		return
	printing = TRUE
	use_power(active_power_usage * 10)
	var/builder_per = 5
	var/builder_lck = 5
	if(D.requires_robot_whisperer && ishuman(user))
		var/mob/living/carbon/human/H = user
		builder_per = H.special_p
		builder_lck = H.special_l
	addtimer(CALLBACK(src, PROC_REF(_finish_print), D, get_turf(src), builder_per, builder_lck, key_name(user)), 30, TIMER_UNIQUE|TIMER_OVERRIDE)


/obj/machinery/cpu_fabricator/proc/_finish_print(datum/cpu_fab_design/D, turf/T, builder_per, builder_lck, builder_ckey)
	printing = FALSE
	var/atom/movable/result = new D.output_path(T)
	if(D.requires_robot_whisperer && istype(result, /obj/item/behavior_assembly))
		var/obj/item/behavior_assembly/A = result
		A.sensor_range = clamp(5 + max(0, builder_per - 5), 5, 10)
		A.builder_ckey = builder_ckey
		log_game("Behavior assembly '[D.design_name]' printed by [builder_ckey] (range:[A.sensor_range] slots:[A.max_circuits])")
	visible_message(span_notice("[src] finishes printing [D.design_name]."))
	for(var/mob/living/carbon/human/H in range(2, src))
		if(H.client)
			spawn(0) ui_interact(H)


// ============================================================
// PRINTING - custom assembly
// ============================================================

/obj/machinery/cpu_fabricator/proc/_build_custom(mob/user)
	if(printing)
		to_chat(user, span_warning("The fabricator is already printing."))
		return
	if(!HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
		return
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(H.special_i < 6)
		to_chat(user, span_warning("Intelligence too low. (Requires 6)"))
		return
	if(!custom_trigger_id || !custom_response_id)
		return
	var/trigger_type = text2path(custom_trigger_id)
	var/response_type = text2path(custom_response_id)
	if(!trigger_type || !ispath(trigger_type, /datum/behavior_circuit/trigger))
		return
	if(!response_type || !ispath(response_type, /datum/behavior_circuit/response))
		return
	// Validate bonus if present
	var/bonus_type = null
	if(bonus_slot_available && bonus_slot_mode && custom_bonus_id)
		bonus_type = text2path(custom_bonus_id)
		var/base_path = bonus_slot_mode == "trigger" ? /datum/behavior_circuit/trigger : /datum/behavior_circuit/response
		if(!bonus_type || !ispath(bonus_type, base_path))
			bonus_type = null
	var/datum/cpu_fab_design/behavior/dummy = new()
	if(!_spend_materials(dummy, user))
		qdel(dummy)
		return
	qdel(dummy)
	printing = TRUE
	use_power(active_power_usage * 10)
	var/t_name = _resolve_circuit_name(custom_trigger_id)
	var/r_name = _resolve_circuit_name(custom_response_id)
	var/b_mode = bonus_slot_mode
	var/b_name = custom_bonus_id ? _resolve_circuit_name(custom_bonus_id) : null
	// Snapshot and clear workshop state
	custom_trigger_id = null
	custom_response_id = null
	custom_bonus_id = null
	bonus_slot_mode = null
	bonus_slot_available = FALSE
	var/list/config_snap = custom_config.Copy()
	custom_config = list()
	workshop_phase = 0
	addtimer(CALLBACK(src, PROC_REF(_finish_custom), trigger_type, response_type, bonus_type, b_mode, t_name, r_name, b_name, get_turf(src), H.special_p, H.special_l, key_name(H), config_snap), 30, TIMER_UNIQUE|TIMER_OVERRIDE)


/obj/machinery/cpu_fabricator/proc/_finish_custom(trigger_type, response_type, bonus_type, bonus_mode, t_name, r_name, b_name, turf/T, builder_per, builder_lck, builder_ckey, list/config_snapshot)
	printing = FALSE
	var/label = "[t_name] -> [r_name]"
	if(b_name)
		label += " + [b_name]"
	var/obj/item/behavior_assembly/A = new(T)
	A.assembly_label = label
	A.name = "behavior assembly - [label]"
	A.sensor_range = clamp(5 + max(0, builder_per - 5), 5, 10)
	A.builder_ckey = builder_ckey
	// If bonus circuit included, raise max_circuits to match (3/3 not 3/2)
	// and mark slot_expansion_used so the reprogram expand button doesn't appear
	if(bonus_type)
		A.max_circuits = 3
		A.slot_expansion_used = TRUE
	var/datum/behavior_circuit/trigger/TR = new trigger_type()
	var/datum/behavior_circuit/response/RE = new response_type()
	TR.response = RE
	// Apply workshop config vars
	for(var/key in config_snapshot)
		var/val = config_snapshot[key]
		var/dot = findtext(key, ".")
		if(!dot)
			continue
		var/prefix  = copytext(key, 1, dot)
		var/varname = copytext(key, dot + 1)
		if(prefix == "trigger" && (varname in TR.vars))
			TR.vars[varname] = val
		else if(prefix == "response" && (varname in RE.vars))
			RE.vars[varname] = val
	A.circuits += TR
	A.circuits += RE
	// Wire bonus circuit
	if(bonus_type)
		var/datum/behavior_circuit/BONUS = new bonus_type()
		// Apply bonus config vars
		for(var/key in config_snapshot)
			var/val = config_snapshot[key]
			var/dot = findtext(key, ".")
			if(!dot)
				continue
			var/prefix  = copytext(key, 1, dot)
			var/varname = copytext(key, dot + 1)
			if(prefix == "bonus" && (varname in BONUS.vars))
				BONUS.vars[varname] = val
		if(bonus_mode == "trigger")
			// Bonus trigger also fires the same response
			if(istype(BONUS, /datum/behavior_circuit/trigger))
				var/datum/behavior_circuit/trigger/BT = BONUS
				BT.response = RE
		A.circuits += BONUS
	log_game("Custom assembly '[label]' ([trigger_type]->[response_type]) printed by [builder_ckey]")
	visible_message(span_notice("[src] finishes printing: [label]."))
	for(var/mob/living/carbon/human/H in range(2, src))
		if(H.client)
			spawn(0) ui_interact(H)


// ============================================================
// MATERIALS
// ============================================================

/obj/machinery/cpu_fabricator/proc/_mat_path(key)
	switch(key)
		if("iron")   return /datum/material/iron
		if("glass")  return /datum/material/glass
		if("gold")   return /datum/material/gold
		if("silver") return /datum/material/silver
	return null

/obj/machinery/cpu_fabricator/proc/_spend_materials(datum/cpu_fab_design/D, mob/user)
	if(!D.cost || !D.cost.len)
		return TRUE
	var/datum/component/material_container/mats = GetComponent(/datum/component/material_container)
	if(!mats)
		return TRUE
	for(var/key in D.cost)
		var/mat = _mat_path(key)
		if(!mat)
			continue
		var/needed = D.cost[key]
		var/have = mats.get_material_amount(mat) || 0
		if(have < needed)
			to_chat(user, span_warning("Not enough [key]. Need [needed] cm3, have [have] cm3."))
			return FALSE
	for(var/key in D.cost)
		var/mat = _mat_path(key)
		if(mat)
			mats.use_amount_mat(D.cost[key], mat)
	return TRUE


// ============================================================
// DESIGN DATUM BASE + CATEGORIES
// ============================================================

/datum/cpu_fab_design
	var/design_name = "Unknown"
	var/design_desc = ""
	var/id = "unknown"
	var/required_tier = CERT_TIER_BASIC
	var/required_int = 0
	var/output_path = /obj/item/cert_card
	var/list/cost = list()
	var/requires_robot_whisperer = FALSE
	var/ui_category = "cert"
	var/for_ai = FALSE

/datum/cpu_fab_design/upgrade
	ui_category = "upgrade"

/datum/cpu_fab_design/ai_upgrade
	ui_category = "ai_upgrade"
	for_ai = TRUE

/datum/cpu_fab_design/behavior
	ui_category = "behavior"
	requires_robot_whisperer = TRUE
	required_int = 6
	cost = list("iron" = 400, "glass" = 300, "gold" = 100)


// ---- AI upgrade cert cards ----

/obj/item/cert_card/upgrade/ai
	name = "cert card - AI upgrade"
	desc = "An AI-targeted upgrade card. Use it on an AI unit's upgrade interface."

/obj/item/cert_card/upgrade/ai/surveillance/Initialize(mapload)
	. = ..()
	upgrade = new /datum/cert_upgrade/ai/surveillance()
	_update_name()

/obj/item/cert_card/upgrade/ai/malf_package/Initialize(mapload)
	. = ..()
	upgrade = new /datum/cert_upgrade/ai/malf_package()
	_update_name()


// ---- Base certs ----

/datum/cpu_fab_design/base/standard
	design_name = "Standard Chassis Cert"
	design_desc = "General-purpose robotic chassis certification."
	id = "cert_base_standard"
	output_path = /obj/item/cert_card/base
	cost = list("iron" = 500, "glass" = 200)

/datum/cpu_fab_design/base/combat
	design_name = "Combat Chassis Cert"
	design_desc = "Military-grade combat chassis certification. Tier 2 required."
	id = "cert_base_combat"
	required_tier = CERT_TIER_MILITARY
	output_path = /obj/item/cert_card/base/combat
	cost = list("iron" = 1000, "glass" = 200, "gold" = 300)

/datum/cpu_fab_design/base/medical
	design_name = "Medical Chassis Cert"
	design_desc = "Medical chassis certification."
	id = "cert_base_medical"
	output_path = /obj/item/cert_card/base/medical
	cost = list("iron" = 500, "glass" = 400)

/datum/cpu_fab_design/base/engineering
	design_name = "Engineering Chassis Cert"
	design_desc = "Engineering chassis certification."
	id = "cert_base_engineering"
	output_path = /obj/item/cert_card/base/engineering
	cost = list("iron" = 700, "glass" = 200)


// ---- Upgrades ----

/datum/cpu_fab_design/upgrade/vtec
	design_name = "VTEC Sprint System"
	design_desc = "Overclocks locomotion servos for burst speed."
	id = "cert_upgrade_vtec"
	output_path = /obj/item/cert_card/upgrade/vtec
	cost = list("iron" = 300, "glass" = 100)

/datum/cpu_fab_design/upgrade/armor_plating
	design_name = "Reinforced Armor Plating"
	design_desc = "Heavy plating. Significant damage resistance increase."
	id = "cert_upgrade_armor"
	output_path = /obj/item/cert_card/upgrade/armor_plating
	cost = list("iron" = 800)

/datum/cpu_fab_design/upgrade/emp_shielding
	design_name = "EMP Shielding Array"
	design_desc = "Faraday cage shielding woven into chassis internals. Protects against EMP."
	id = "cert_upgrade_emp"
	output_path = /obj/item/cert_card/upgrade/emp_shielding
	cost = list("iron" = 500, "gold" = 200)

/datum/cpu_fab_design/upgrade/hacking_module
	design_name = "Intrusion Countermeasure Suite"
	design_desc = "Military-grade hacking suite. Requires Tier 2 chassis. Enables bypass and access manipulation behaviors."
	id = "cert_upgrade_hacking"
	required_tier = CERT_TIER_MILITARY
	output_path = /obj/item/cert_card/upgrade/hacking_module
	cost = list("iron" = 400, "glass" = 200, "gold" = 400)

/datum/cpu_fab_design/upgrade/designation_chip
	design_name = "Designation Chip"
	design_desc = "Allows the robot to set a custom callsign via Set Designation verb."
	id = "cert_upgrade_designation"
	output_path = /obj/item/cert_card/upgrade/designation_chip
	cost = list("glass" = 200, "gold" = 50)

/datum/cpu_fab_design/upgrade/rad_shielding
	design_name = "Rad Shielding Plating"
	design_desc = "Lead-lined internal shielding. Reduces radiation intake."
	id = "cert_upgrade_rad"
	output_path = /obj/item/cert_card/upgrade/rad_shielding
	cost = list("iron" = 400, "glass" = 200)

/datum/cpu_fab_design/upgrade/scavenger_array
	design_name = "Scavenger Array"
	design_desc = "Proximity sensors tuned to detect nearby salvage and remains."
	id = "cert_upgrade_scavenger"
	output_path = /obj/item/cert_card/upgrade/scavenger_array
	cost = list("glass" = 300, "gold" = 100)

/datum/cpu_fab_design/upgrade/saw_arm
	design_name = "Saw Arm Attachment"
	design_desc = "High-speed rotary saw replaces the standard manipulator. Brutal in melee."
	id = "cert_upgrade_saw"
	output_path = /obj/item/cert_card/upgrade/saw_arm
	cost = list("iron" = 500, "glass" = 100)

/datum/cpu_fab_design/upgrade/stimpak_injector
	design_name = "Stimpak Injector"
	design_desc = "Integrated stimpak reservoir. Administer aid to injured survivors."
	id = "cert_upgrade_stimpak"
	output_path = /obj/item/cert_card/upgrade/stimpak_injector
	cost = list("glass" = 400, "gold" = 100)

/datum/cpu_fab_design/upgrade/faction_transponder
	design_name = "Faction Transponder"
	design_desc = "Programmable IFF transponder. Set faction alignment via Set Faction Transponder verb."
	id = "cert_upgrade_transponder"
	output_path = /obj/item/cert_card/upgrade/faction_transponder
	cost = list("glass" = 200, "gold" = 150)


// ---- Behavior assemblies ----

/datum/cpu_fab_design/behavior/sentry
	design_name = "Sentry Protocol"
	design_desc = "Enters combat mode when an enemy is spotted."
	id = "behavior_sentry"
	output_path = /obj/item/behavior_assembly/sentry

/datum/cpu_fab_design/behavior/guardian
	design_name = "Guardian Protocol"
	design_desc = "Broadcasts a distress call when the robot takes damage."
	id = "behavior_guardian"
	output_path = /obj/item/behavior_assembly/guardian

/datum/cpu_fab_design/behavior/medic_protocol
	design_name = "Medic Protocol"
	design_desc = "Self-repair pulse when the robot takes damage. Requires a repair-capable robot."
	id = "behavior_medic"
	output_path = /obj/item/behavior_assembly/medic
	cost = list("iron" = 400, "glass" = 400, "gold" = 100)

/datum/cpu_fab_design/behavior/watchdog
	design_name = "Watchdog Protocol"
	design_desc = "Broadcasts a power warning when the cell runs critically low."
	id = "behavior_watchdog"
	output_path = /obj/item/behavior_assembly/watchdog

/datum/cpu_fab_design/behavior/deadman
	design_name = "Deadman Protocol"
	design_desc = "Broadcasts a final distress signal with location on death."
	id = "behavior_deadman"
	output_path = /obj/item/behavior_assembly/deadman

/datum/cpu_fab_design/behavior/fortress
	design_name = "Fortress Protocol"
	design_desc = "Emergency lockdown triggers on heavy damage. Requires INT 7+."
	id = "behavior_fortress"
	required_int = 7
	output_path = /obj/item/behavior_assembly/fortress
	cost = list("iron" = 600, "glass" = 300, "gold" = 200)

/datum/cpu_fab_design/behavior/drink_bot
	design_name = "Drink Bot Protocol"
	design_desc = "Offers water to thirsty survivors that approach. Requires a borghypo in the robot's module."
	id = "behavior_drinkbot"
	output_path = /obj/item/behavior_assembly/drink_bot

/datum/cpu_fab_design/behavior/medbot
	design_name = "Medbot Protocol"
	design_desc = "Injects nearby injured friendlies. Requires a borghypo in the robot's module."
	id = "behavior_medbot"
	output_path = /obj/item/behavior_assembly/medbot

/datum/cpu_fab_design/behavior/night_watch
	design_name = "Night Watch Protocol"
	design_desc = "Automatically enters combat mode at nightfall."
	id = "behavior_nightwatch"
	output_path = /obj/item/behavior_assembly/night_watch

/datum/cpu_fab_design/behavior/escort
	design_name = "Escort Protocol"
	design_desc = "Follows a linked target mob. Scan an ID card with a multitool and use it on the robot to link a follow target."
	id = "behavior_escort"
	output_path = /obj/item/behavior_assembly/escort

/datum/cpu_fab_design/behavior/last_resort
	design_name = "Last Resort Protocol"
	design_desc = "Detonates when an enemy is spotted. Extremely dangerous. Requires INT 8+."
	id = "behavior_lastresort"
	required_int = 8
	output_path = /obj/item/behavior_assembly/last_resort
	cost = list("iron" = 600, "glass" = 200, "gold" = 300)

/datum/cpu_fab_design/behavior/sprint_chaser
	design_name = "Sprint Chaser Protocol"
	design_desc = "Pursues enemies automatically. Pairs well with the VTEC Sprint System upgrade."
	id = "behavior_sprint_chaser"
	required_int = 5
	output_path = /obj/item/behavior_assembly/sprint_chaser
	cost = list("iron" = 300, "glass" = 100)

/datum/cpu_fab_design/behavior/infiltrator
	design_name = "Infiltrator Protocol"
	design_desc = "Reports in and shadows targets after bypassing access. Requires the Intrusion Countermeasure Suite upgrade."
	id = "behavior_infiltrator"
	required_int = 7
	output_path = /obj/item/behavior_assembly/infiltrator
	cost = list("iron" = 400, "glass" = 300, "gold" = 200)

/datum/cpu_fab_design/behavior/field_surgeon
	design_name = "Field Surgeon Protocol"
	design_desc = "Automatically moves toward critically injured friendlies. Pairs well with Stimpak Injector upgrade."
	id = "behavior_field_surgeon"
	required_int = 5
	output_path = /obj/item/behavior_assembly/field_surgeon
	cost = list("iron" = 300, "glass" = 200)

/datum/cpu_fab_design/behavior/broadcast_relay
	design_name = "Broadcast Relay Protocol"
	design_desc = "Periodically transmits faction identification. Requires the Faction Transponder upgrade."
	id = "behavior_broadcast_relay"
	required_int = 4
	output_path = /obj/item/behavior_assembly/broadcast_relay
	cost = list("iron" = 200, "glass" = 100)


// ---- AI upgrades ----

/datum/cpu_fab_design/ai_upgrade/surveillance
	design_name = "Surveillance Software Package"
	design_desc = "Allows the AI to hear through cameras. Installed on AI units, not robots."
	id = "ai_upgrade_surveillance"
	output_path = /obj/item/cert_card/upgrade/ai/surveillance
	cost = list("glass" = 2000, "gold" = 2000)

/datum/cpu_fab_design/ai_upgrade/malf_package
	design_name = "Combat Software Package"
	design_desc = "Illegal. Grants combat-class AI routines. Requires Military-tier AI cert. Installed on AI units."
	id = "ai_upgrade_malf"
	required_tier = CERT_TIER_MILITARY
	output_path = /obj/item/cert_card/upgrade/ai/malf_package
	cost = list("gold" = 4000, "glass" = 2000)


#undef FAB_HOME
#undef FAB_CERTS
#undef FAB_UPGRADES
#undef FAB_BEHAVIORS
#undef FAB_CUSTOM
#undef FAB_REPROG
#undef FAB_AI
#undef REPROGRAM_COST_GOLD
