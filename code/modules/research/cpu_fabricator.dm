// ====================================================
// CPU CERT FABRICATOR
// Uses datum/browser HTML - same pattern as terminal.dm
//
// Tabs: Home | Base Certs | Upgrades | Behavior Asm. | Custom Build
// Behavior + Custom tabs only visible to TRAIT_ROBOT_WHISPERER users.
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
	/// Workshop phase: 0=pick trigger, 1=pick response, 2=configure, 3=review
	var/workshop_phase = 0


/obj/machinery/cpu_fabricator/Initialize(mapload)
	. = ..()
	_build_design_list()
	AddComponent(/datum/component/material_container, 		list(/datum/material/iron, /datum/material/glass, /datum/material/gold, /datum/material/silver), 		MINERAL_MATERIAL_AMOUNT * 50, TRUE, 		list(/obj/item/stack))


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
// PAGE RENDERERS
// ============================================================

/obj/machinery/cpu_fabricator/proc/_render_home(mob/user)
	var/dat = "<b>CATEGORIES</b><br><br>"
	dat += "&gt; <a href='byond://?src=[REF(src)];mode=[FAB_CERTS]'>Base Certifications</a> - chassis identity cards<br>"
	dat += "&gt; <a href='byond://?src=[REF(src)];mode=[FAB_UPGRADES]'>Upgrade Modules</a> - hardware enhancements<br>"
	if(HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
		dat += "&gt; <a href='byond://?src=[REF(src)];mode=[FAB_BEHAVIORS]'>Behavior Assemblies</a> - preset automation programs<br>"
		dat += "&gt; <a href='byond://?src=[REF(src)];mode=[FAB_CUSTOM]'>Custom Build</a> - wire your own trigger/response pair<br>"
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			var/sensor_range = min(10, 5 + max(0, H.special_p - 5))
			dat += "<br><b>YOUR S.P.E.C.I.A.L.</b><br>"
			dat += "<span class='dim'>&gt; Intelligence: [H.special_i] - gates assembly complexity</span><br>"
			dat += "<span class='dim'>&gt; Perception:   [H.special_p] - sensor range: [sensor_range] tiles</span><br>"
			if(H.special_l >= 7)
				var/luck_chance = (H.special_l - 6) * 15
				dat += "<span class='dim'>&gt; Luck:         [H.special_l]</span> - <span class='good'>[luck_chance]% chance of bonus circuit slot</span><br>"
			else
				dat += "<span class='dim'>&gt; Luck:         [H.special_l] - no bonus slot (LCK 7+ needed)</span><br>"
	else
		dat += "<br><span class='dim'>&gt; Behavior assembly fabrication requires the Robot Whisperer trait.</span><br>"
	// Assembly slot
	if(inserted_assembly)
		dat += "<br><b>REPROGRAM SLOT</b><br>"
		dat += "<span class='good'>&gt; [inserted_assembly.name]</span> - <a href='byond://?src=[REF(src)];eject_assembly=1'>&gt; Eject</a><br>"
	// Material hopper
	var/datum/component/material_container/mats = GetComponent(/datum/component/material_container)
	if(mats)
		dat += "<br><b>MATERIAL HOPPER</b> - <a href='byond://?src=[REF(src)];eject_mats=1'>&gt; Eject All</a><br>"
		var/list/mpaths = list(/datum/material/iron, /datum/material/glass, /datum/material/gold, /datum/material/silver)
		var/list/mnames  = list("iron", "glass", "gold", "silver")
		for(var/i in 1 to mpaths.len)
			var/amt = mats.get_material_amount(mpaths[i]) || 0
			dat += "<span class='dim'>&gt; [mnames[i]]: [amt] cm3</span><br>"
		dat += "<span class='dim'>(Insert sheets to load.)</span><br>"
	return dat


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
			var/dint = D.required_int
			dat += " <span class='dim'>(INT [dint]+)</span>"
		dat += "<br>"
		dat += "<span class='dim'>[ddesc]</span><br>"
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
			var/dint2 = D.required_int
			if(H.special_i < dint2)
				can_print = FALSE
				block_reason = "INT [dint2]+ required (you have [H.special_i])"
		if(D.for_ai)
			dat += "<span class='dim'>(Use on an AI unit, not a robot.)</span><br>"
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


/obj/machinery/cpu_fabricator/proc/_render_custom(mob/user)
	// INT check
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.special_i < 6)
			var/dat2 = "<b>CUSTOM BEHAVIOR WORKSHOP</b><br>"
			dat2 += "<span class='bad'>&gt; INTELLIGENCE TOO LOW. INT 6 required to program assemblies.</span><br>"
			return dat2
	return _render_workshop(user)


// -- Workshop: multi-phase tabbed build UI ------------------------------
/obj/machinery/cpu_fabricator/proc/_render_workshop(mob/user)
	var/dat = "<b>BEHAVIOR ASSEMBLY WORKSHOP</b>"
	// Phase nav
	dat += " - "
	var/list/phases = list("1:TRIGGER", "2:RESPONSE", "3:REVIEW+CONFIG")
	for(var/i in 1 to phases.len)
		var/ph = i - 1
		var/label = phases[i]
		if(workshop_phase == ph)
			dat += "<span class='good'><b>\[[label]\]</b></span>"
		else
			dat += "<a href='byond://?src=[REF(src)];workshop_phase=[ph]'>\[[label]\]</a>"
		if(i < phases.len)
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
	dat += "<hr>"
	switch(workshop_phase)
		if(0)
			dat += _workshop_phase_trigger(user)
		if(1)
			dat += _workshop_phase_response(user)
		else
			// Phase 2+ = review/configure; also auto-advance here
			dat += _workshop_phase_review(user)
	return dat


// Phase 1: Pick a trigger
/obj/machinery/cpu_fabricator/proc/_workshop_phase_trigger(mob/user)
	var/dat = "<b>STEP 1 - SELECT TRIGGER</b><br>"
	dat += "<span class='dim'>The trigger defines WHEN your assembly acts. It watches the robot continuously and fires when its condition is met.</span><br><br>"
	for(var/T in subtypesof(/datum/behavior_circuit/trigger))
		var/datum/behavior_circuit/trigger/inst = new T
		var/tname = inst.circuit_name
		var/tdesc = inst.circuit_desc
		var/ttut  = inst.tutorial_text
		var/tcpu  = inst.cpu_cost
		var/tpath = "[T]"
		qdel(inst)
		dat += "<div class='card'>"
		if(custom_trigger_id == tpath)
			dat += "<span class='good'><b>&gt; * [tname]</b></span> <span class='dim'>CPU: [tcpu]</span><br>"
		else
			dat += "<a href='byond://?src=[REF(src)];sel_trigger=[tpath]'><b>&gt; [tname]</b></a> <span class='dim'>CPU: [tcpu]</span><br>"
		dat += "<span class='dim'>[tdesc]</span><br>"
		dat += "<span class='dim' style='font-size:0.85em'>[ttut]</span>"
		dat += "</div>"
	if(custom_trigger_id)
		dat += "<br><a href='byond://?src=[REF(src)];workshop_phase=1'>&gt; Continue to Response selection</a><br>"
	return dat


// Phase 2: Pick a response
/obj/machinery/cpu_fabricator/proc/_workshop_phase_response(mob/user)
	var/dat = "<b>STEP 2 - SELECT RESPONSE</b><br>"
	dat += "<span class='dim'>The response defines WHAT happens when the trigger fires. Responses marked HARDWARE REQUIRED need an IC in the robot's module.</span><br><br>"
	for(var/T in subtypesof(/datum/behavior_circuit/response))
		var/datum/behavior_circuit/response/inst = new T
		var/rname = inst.circuit_name
		var/rdesc = inst.circuit_desc
		var/rtut  = inst.tutorial_text
		var/rcpu  = inst.cpu_cost
		var/rpath = "[T]"
		qdel(inst)
		dat += "<div class='card'>"
		if(custom_response_id == rpath)
			dat += "<span class='good'><b>&gt; * [rname]</b></span> <span class='dim'>CPU: [rcpu]</span><br>"
		else
			dat += "<a href='byond://?src=[REF(src)];sel_response=[rpath]'><b>&gt; [rname]</b></a> <span class='dim'>CPU: [rcpu]</span><br>"
		dat += "<span class='dim'>[rdesc]</span><br>"
		dat += "<span class='dim' style='font-size:0.85em'>[rtut]</span>"
		dat += "</div>"
	if(custom_response_id)
		dat += "<br><a href='byond://?src=[REF(src)];workshop_phase=2'>&gt; Continue to Configuration</a><br>"
	return dat


// Renders inline config fields for one circuit on the review page.
// Uses href links with text input prompts - no popup dialogs.
/obj/machinery/cpu_fabricator/proc/_render_circuit_config_inline(datum/behavior_circuit/C, prefix)
	var/dat = ""
	// Skip internal state vars - only show meaningful configuration vars
	var/list/skip = list(
		"circuit_name","circuit_desc","tutorial_text","cpu_cost","robot_ref","assembly_ref",
		"response","last_health","already_triggered","spot_cooldown","last_spotted",
		"hear_cooldown","last_heard","last_message","last_speaker","last_received","signal_cooldown",
		"last_check","check_cooldown","last_fire","was_low","in_zone","already_fired","last_shot",
		"last_scan_time","linked_target_ref","linked_target_name","follow_target_ref")
	var/has_vars = FALSE
	for(var/varname in C.vars)
		if(varname in skip)
			continue
		if(copytext(varname,1,2) == "_")
			continue
		var/cur_val = custom_config["[prefix].[varname]"] != null ? custom_config["[prefix].[varname]"] : C.vars[varname]
		// Render as an inline edit link - click to be prompted via browser input
		dat += "<span class='dim'>&gt; [varname]:</span> "
		dat += "<span class='good'>[cur_val]</span>"
		dat += " \[<a href='byond://?src=[REF(src)];prompt_config=[prefix].[varname]'>edit</a>\]<br>"
		has_vars = TRUE
	if(!has_vars)
		dat += "<span class='dim'>&gt; No configurable parameters.</span><br>"
	return dat


// Phase 4: Review + print
/obj/machinery/cpu_fabricator/proc/_workshop_phase_review(mob/user)
	var/dat = "<b>STEP 3 - REVIEW & CONFIGURE</b><br>"
	dat += "<span class='dim'>Adjust parameters below. All have sensible defaults - change only what you need.</span><br><hr>"
	// Circuit summary
	var/t_name = custom_trigger_id ? _resolve_circuit_name(custom_trigger_id) : "(none selected)"
	var/r_name = custom_response_id ? _resolve_circuit_name(custom_response_id) : "(none selected)"
	var/t_cpu = 0
	var/r_cpu = 0
	var/datum/behavior_circuit/trigger/TI = null
	var/datum/behavior_circuit/response/RI = null
	if(custom_trigger_id)
		TI = new (text2path(custom_trigger_id))
		t_cpu = TI.cpu_cost
	if(custom_response_id)
		RI = new (text2path(custom_response_id))
		r_cpu = RI.cpu_cost
	var/total_cpu = t_cpu + r_cpu
	dat += "<b>TRIGGER:</b>  <span class='[custom_trigger_id ? "good" : "bad"]'>[t_name]</span>"
	if(custom_trigger_id)
		dat += " <a href='byond://?src=[REF(src)];workshop_phase=0'>\[change\]</a>"
	dat += " <span class='dim'>CPU: [t_cpu]</span><br>"
	dat += "<b>RESPONSE:</b> <span class='[custom_response_id ? "good" : "bad"]'>[r_name]</span>"
	if(custom_response_id)
		dat += " <a href='byond://?src=[REF(src)];workshop_phase=1'>\[change\]</a>"
	dat += " <span class='dim'>CPU: [r_cpu]</span><br>"
	dat += "<b>TOTAL CPU:</b> <span class='warn'>[total_cpu]</span><br>"
	// Inline config fields
	dat += "<hr><b>TRIGGER PARAMETERS</b><br>"
	if(TI)
		dat += _render_circuit_config_inline(TI, "trigger")
		dat += "<span class='dim' style='font-size:0.85em'>[TI.tutorial_text]</span><br>"
		qdel(TI)
	dat += "<hr><b>RESPONSE PARAMETERS</b><br>"
	if(RI)
		dat += _render_circuit_config_inline(RI, "response")
		dat += "<span class='dim' style='font-size:0.85em'>[RI.tutorial_text]</span><br>"
		qdel(RI)
	// Material cost summary
	var/datum/cpu_fab_design/behavior/dummy = new()
	var/cost_dat = ""
	for(var/mat in dummy.cost)
		cost_dat += "[dummy.cost[mat]] [mat] cm3, "
	qdel(dummy)
	if(cost_dat)
		dat += "<hr><span class='dim'>Material cost: [copytext(cost_dat, 1, length(cost_dat)-1)]</span><br>"
	// Print button
	dat += "<hr>"
	if(printing)
		dat += "<span class='warn'>&gt; PRINTING IN PROGRESS...</span><br>"
	else if(custom_trigger_id && custom_response_id)
		dat += "<a href='byond://?src=[REF(src)];build_custom=1'><b>&gt; WIRE AND PRINT</b></a>"
		dat += "  <a href='byond://?src=[REF(src)];clear_workshop=1'><span class='dim'>\[clear\]</span></a><br>"
	else
		dat += "<span class='bad'>&gt; Select trigger and response first.</span><br>"
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
			custom_config = list()  // reset config on new selection
		ui_interact(usr)
		return
	if(href_list["sel_response"])
		var/T = text2path(href_list["sel_response"])
		if(T && ispath(T, /datum/behavior_circuit/response))
			custom_response_id = href_list["sel_response"]
			custom_config = list()
			workshop_phase = 2  // auto-advance to review
		ui_interact(usr)
		return
	if(href_list["build_custom"])
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
		// Inline config edit - prompt the user via browser input
		var/key = href_list["prompt_config"]
		var/cur = custom_config[key] || ""
		var/new_val = input(usr, "Set value for [key]:", "Configure Assembly", cur)
		if(new_val != null)
			custom_config[key] = new_val
		ui_interact(usr)
		return
	if(href_list["clear_workshop"])
		custom_trigger_id = null
		custom_response_id = null
		custom_config = list()
		workshop_phase = 0
		ui_interact(usr)
		return
	if(href_list["eject_assembly"])
		if(inserted_assembly)
			inserted_assembly.forceMove(get_turf(src))
			to_chat(usr, span_notice("You retrieve [inserted_assembly] from the reprogramming slot."))
			inserted_assembly = null
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
		var/dint = D.required_int
		if(H.special_i < dint)
			to_chat(user, span_warning("Intelligence too low. (Requires [dint])"))
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
	// Warn if this assembly requires cert upgrades the robot may not have
	if(ispath(D.output_path, /obj/item/behavior_assembly))
		var/obj/item/behavior_assembly/test = new D.output_path()
		var/incompatible = !test.cert_compatible(null)
		qdel(test)
		if(incompatible)
			to_chat(user, span_warning("Warning: this assembly requires specific cert upgrades to function."))
	addtimer(CALLBACK(src, PROC_REF(_finish_print), D, get_turf(src), builder_per, builder_lck, key_name(user)), 30, TIMER_UNIQUE|TIMER_OVERRIDE)


/obj/machinery/cpu_fabricator/proc/_finish_print(datum/cpu_fab_design/D, turf/T, builder_per, builder_lck, builder_ckey)
	printing = FALSE
	var/atom/movable/result = new D.output_path(T)
	if(D.requires_robot_whisperer && istype(result, /obj/item/behavior_assembly))
		var/obj/item/behavior_assembly/A = result
		A.sensor_range = clamp(5 + max(0, builder_per - 5), 5, 10)
		A.builder_ckey = builder_ckey
		if(builder_lck >= 7)
			var/luck_chance = (builder_lck - 6) * 15
			if(prob(luck_chance))
				A.max_circuits++
				visible_message(span_notice("[src] hums with unusual efficiency - a bonus circuit slot was configured!"))
		var/arange = A.sensor_range
		var/aslots = A.max_circuits
		var/dname = D.design_name
		log_game("Behavior assembly '[dname]' printed by [builder_ckey] (range:[arange] slots:[aslots])")
	var/dname2 = D.design_name
	visible_message(span_notice("[src] finishes printing [dname2]."))
	// Re-open UI for nearby users so the print button unlocks without manual tab switch
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
	// Custom build costs materials - same base as a preset behavior assembly
	var/datum/cpu_fab_design/behavior/dummy = new()
	if(!_spend_materials(dummy, user))
		qdel(dummy)
		return
	qdel(dummy)
	printing = TRUE
	use_power(active_power_usage * 10)
	var/t_name = _resolve_circuit_name(custom_trigger_id)
	var/r_name = _resolve_circuit_name(custom_response_id)
	custom_trigger_id = null
	custom_response_id = null
	var/list/config_snap = custom_config.Copy()
	custom_config = list()
	workshop_phase = 0
	addtimer(CALLBACK(src, PROC_REF(_finish_custom), trigger_type, response_type, t_name, r_name, get_turf(src), H.special_p, H.special_l, key_name(H), config_snap), 30, TIMER_UNIQUE|TIMER_OVERRIDE)


/obj/machinery/cpu_fabricator/proc/_finish_custom(trigger_type, response_type, t_name, r_name, turf/T, builder_per, builder_lck, builder_ckey, list/config_snapshot)
	printing = FALSE
	var/label = "[t_name] -> [r_name]"
	var/obj/item/behavior_assembly/A = new(T)
	A.assembly_label = label
	A.name = "behavior assembly - [label]"
	A.sensor_range = clamp(5 + max(0, builder_per - 5), 5, 10)
	A.builder_ckey = builder_ckey
	if(builder_lck >= 7)
		var/luck_chance = (builder_lck - 6) * 15
		if(prob(luck_chance))
			A.max_circuits++
			visible_message(span_notice("[src] hums with unusual efficiency - a bonus circuit slot was configured!"))
	var/datum/behavior_circuit/trigger/TR = new trigger_type()
	var/datum/behavior_circuit/response/RE = new response_type()
	TR.response = RE
	// Apply workshop config vars
	for(var/key in config_snapshot)
		var/val = config_snapshot[key]
		// Try trigger first then response
		if(key in TR.vars)
			TR.vars[key] = val
		else if(key in RE.vars)
			RE.vars[key] = val
	A.circuits += TR
	A.circuits += RE
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
// REPROGRAMMING
// ============================================================

// Reprogram cost: gold only (rerouting logic, no new chassis material needed)
#define REPROGRAM_COST_GOLD 100

/obj/machinery/cpu_fabricator/proc/_render_reprog(mob/user)
	if(!inserted_assembly)
		return "<span class='bad'>&gt; No assembly in reprogramming slot.</span><br>"
	var/obj/item/behavior_assembly/A = inserted_assembly
	var/dat = "<b>REPROGRAMMING: [A.assembly_label]</b><br>"
	dat += "<span class='dim'>Circuits: [A.circuits.len]/[A.max_circuits] | Sensor range: [A.sensor_range] tiles</span><br>"
	if(A.circuits.len)
		dat += "<br><b>INSTALLED CIRCUITS:</b><br>"
		for(var/datum/behavior_circuit/C in A.circuits)
			dat += "<span class='dim'>&gt; [C.circuit_name]</span><br>"
	dat += "<hr><b>SELECT NEW TRIGGER</b><br>"
	for(var/T in subtypesof(/datum/behavior_circuit/trigger))
		var/datum/behavior_circuit/trigger/inst = new T
		var/tname = inst.circuit_name
		var/tdesc = inst.circuit_desc
		var/tpath = "[T]"
		qdel(inst)
		if(custom_trigger_id == tpath)
			dat += "<span class='good'>&gt; * [tname]</span> <span class='dim'>- [tdesc]</span><br>"
		else
			dat += "&gt; <a href='byond://?src=[REF(src)];sel_trigger=[tpath]'>[tname]</a> <span class='dim'>- [tdesc]</span><br>"
	dat += "<hr><b>SELECT NEW RESPONSE</b><br>"
	for(var/T in subtypesof(/datum/behavior_circuit/response))
		var/datum/behavior_circuit/response/inst = new T
		var/rname = inst.circuit_name
		var/rdesc = inst.circuit_desc
		var/rpath = "[T]"
		qdel(inst)
		if(custom_response_id == rpath)
			dat += "<span class='good'>&gt; * [rname]</span> <span class='dim'>- [rdesc]</span><br>"
		else
			dat += "&gt; <a href='byond://?src=[REF(src)];sel_response=[rpath]'>[rname]</a> <span class='dim'>- [rdesc]</span><br>"
	dat += "<hr>"
	var/t_label = custom_trigger_id ? _resolve_circuit_name(custom_trigger_id) : "(none)"
	var/r_label = custom_response_id ? _resolve_circuit_name(custom_response_id) : "(none)"
	dat += "<span class='dim'>Trigger:  </span><span class='[custom_trigger_id ? "good" : "bad"]'>[t_label]</span><br>"
	dat += "<span class='dim'>Response: </span><span class='[custom_response_id ? "good" : "bad"]'>[r_label]</span><br>"
	dat += "<span class='dim'>Cost: [REPROGRAM_COST_GOLD] gold cm3</span><br>"
	if(!printing && custom_trigger_id && custom_response_id)
		dat += "<br><a href='byond://?src=[REF(src)];reprogram=1'>&gt; Reprogram Assembly</a><br>"
	else if(printing)
		dat += "<br><span class='warn'>&gt; Busy...</span><br>"
	else
		dat += "<br><span class='dim'>&gt; Select trigger and response to proceed.</span><br>"
	dat += "<br><a href='byond://?src=[REF(src)];eject_assembly=1'>&gt; Eject Assembly</a><br>"
	return dat


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
	// Check and deduct reprogram cost
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
	to_chat(user, span_notice("Assembly reprogrammed: [A.assembly_label]."))
	visible_message(span_notice("[src] completes a reprogramming cycle."))
	log_game("[key_name(user)] reprogrammed assembly '[A.assembly_label]' at [AREACOORD(src)]")


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
// These are printed by the fabricator and used on AI units.
// The upgrade var carries the datum/cert_upgrade/ai/* datum.

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
	design_desc = "Military-grade combat chassis certification."
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
	design_desc = "Faraday cage shielding woven into chassis internals."
	id = "cert_upgrade_emp"
	output_path = /obj/item/cert_card/upgrade/emp_shielding
	cost = list("iron" = 500, "gold" = 200)

/datum/cpu_fab_design/upgrade/hacking_module
	design_name = "Intrusion Countermeasure Suite"
	design_desc = "Military-grade hacking suite. Requires Tier 2 chassis."
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
	design_desc = "Broadcasts distress when the robot takes damage."
	id = "behavior_guardian"
	output_path = /obj/item/behavior_assembly/guardian

/datum/cpu_fab_design/behavior/medic_protocol
	design_name = "Medic Protocol"
	design_desc = "Self-repair pulse on damage. Requires CERT_CAN_REPAIR."
	id = "behavior_medic"
	output_path = /obj/item/behavior_assembly/medic
	cost = list("iron" = 400, "glass" = 400, "gold" = 100)

/datum/cpu_fab_design/behavior/watchdog
	design_name = "Watchdog Protocol"
	design_desc = "Broadcasts power warning when cell runs critically low."
	id = "behavior_watchdog"
	output_path = /obj/item/behavior_assembly/watchdog

/datum/cpu_fab_design/behavior/deadman
	design_name = "Deadman Protocol"
	design_desc = "Broadcasts final distress signal with location on death."
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
	design_desc = "Offers water to thirsty survivors that approach."
	id = "behavior_drinkbot"
	output_path = /obj/item/behavior_assembly/drink_bot

/datum/cpu_fab_design/behavior/medbot
	design_name = "Medbot Protocol"
	design_desc = "Broadcasts alert when a nearby friendly is critically injured."
	id = "behavior_medbot"
	output_path = /obj/item/behavior_assembly/medbot

/datum/cpu_fab_design/behavior/night_watch
	design_name = "Night Watch Protocol"
	design_desc = "Automatically enters combat mode at nightfall."
	id = "behavior_nightwatch"
	output_path = /obj/item/behavior_assembly/night_watch

/datum/cpu_fab_design/behavior/escort
	design_name = "Escort Protocol"
	design_desc = "Follows the nearest friendly mob in sensor range."
	id = "behavior_escort"
	output_path = /obj/item/behavior_assembly/escort

/datum/cpu_fab_design/behavior/last_resort
	design_name = "Last Resort Protocol"
	design_desc = "Detonates when an enemy is spotted. Requires CERT_CAN_MALF. Dangerous."
	id = "behavior_lastresort"
	required_int = 8
	output_path = /obj/item/behavior_assembly/last_resort
	cost = list("iron" = 600, "glass" = 200, "gold" = 300)


/datum/cpu_fab_design/behavior/sprint_chaser
	design_name = "Sprint Chaser Protocol"
	design_desc = "Pursues enemies automatically. Pairs with VTEC Sprint System upgrade for maximum effectiveness."
	id = "behavior_sprint_chaser"
	required_int = 5
	output_path = /obj/item/behavior_assembly/sprint_chaser
	cost = list("iron" = 300, "glass" = 100)

/datum/cpu_fab_design/behavior/infiltrator
	design_name = "Infiltrator Protocol"
	design_desc = "Reports in and shadows targets after bypassing access. Requires Intrusion Countermeasure Suite (CERT_CAN_HACK)."
	id = "behavior_infiltrator"
	required_int = 7
	output_path = /obj/item/behavior_assembly/infiltrator
	cost = list("iron" = 400, "glass" = 300, "gold" = 200)

/datum/cpu_fab_design/behavior/field_surgeon
	design_name = "Field Surgeon Protocol"
	design_desc = "Automatically moves toward injured friendlies. Pairs with Stimpak Injector or Saw Arm cert upgrades."
	id = "behavior_field_surgeon"
	required_int = 5
	output_path = /obj/item/behavior_assembly/field_surgeon
	cost = list("iron" = 300, "glass" = 200)

/datum/cpu_fab_design/behavior/broadcast_relay
	design_name = "Broadcast Relay Protocol"
	design_desc = "Periodically transmits faction identification. Requires Faction Transponder upgrade (CERT_CAN_BROADCAST)."
	id = "behavior_broadcast_relay"
	required_int = 4
	output_path = /obj/item/behavior_assembly/broadcast_relay
	cost = list("iron" = 200, "glass" = 100)

// ---- AI upgrades ----

/datum/cpu_fab_design/ai_upgrade/surveillance
	design_name = "Surveillance Software Package"
	design_desc = "Allows the AI to hear through cameras. Installs on AI units, not robots."
	id = "ai_upgrade_surveillance"
	output_path = /obj/item/cert_card/upgrade/ai/surveillance
	cost = list("glass" = 2000, "gold" = 2000)

/datum/cpu_fab_design/ai_upgrade/malf_package
	design_name = "Combat Software Package"
	design_desc = "Illegal. Grants malfunction-class combat routines. Requires Military-tier AI cert."
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
