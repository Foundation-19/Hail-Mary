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


/obj/machinery/cpu_fabricator/Initialize(mapload)
	. = ..()
	_build_design_list()


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


/obj/machinery/cpu_fabricator/Destroy()
	designs.Cut()
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
	css += "body{padding:0;margin:15px;background:#0a0a1a;color:#7ec8e3;line-height:160%;font-family:'Courier New',Courier,monospace;}"
	css += "a,a:link,a:visited,a:active{color:#7ec8e3;text-decoration:none;background:#0a0a1a;border:none;padding:1px 5px;margin:0 2px;cursor:default;}"
	css += "a:hover{color:#0a0a1a;background:#7ec8e3;}"
	css += ".good{color:#4aed92;font-weight:bold;}"
	css += ".bad{color:#c0392b;font-weight:bold;}"
	css += ".dim{color:#2a4a5a;}"
	css += ".warn{color:#e8a020;}"
	css += ".stat{color:#e8a020;font-weight:bold;}"
	css += ".tab{display:inline-block;padding:2px 8px;margin:1px;border:1px solid #2a4a5a;}"
	css += ".sel{background:#7ec8e3;color:#0a0a1a;font-weight:bold;}"
	css += ".card{border:1px solid #2a4a5a;padding:4px 8px;margin:3px 0;}"
	css += "hr{border:0;border-top:1px solid #2a4a5a;margin:6px 0;}"
	css += "</style></head>"
	return css


/obj/machinery/cpu_fabricator/proc/get_header()
	var/h = "<center><b>ROBCO INDUSTRIES - CPU CERTIFICATION SYSTEM</b><br>"
	h += "<b>CERT-TECH FABRICATOR v3.1</b></center><br>"
	return h


/obj/machinery/cpu_fabricator/proc/get_tabs(mob/user)
	var/t = ""
	t += _tab("Home",         FAB_HOME)
	t += _tab("Base Certs",   FAB_CERTS)
	t += _tab("Upgrades",     FAB_UPGRADES)
	if(HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
		t += _tab("Behavior Asm.", FAB_BEHAVIORS)
		t += _tab("Custom Build",  FAB_CUSTOM)
	t += "<br><hr>"
	return t


/obj/machinery/cpu_fabricator/proc/_tab(label, mode_id)
	if(fab_mode == mode_id)
		return "<a href='byond://?src=[REF(src)];mode=[mode_id]' class='tab sel'>[label]</a>"
	return "<a href='byond://?src=[REF(src)];mode=[mode_id]' class='tab'>[label]</a>"


// ============================================================
// MAIN UI DISPATCH
// ============================================================

/obj/machinery/cpu_fabricator/ui_interact(mob/user)
	. = ..()
	var/dat = get_fab_css()
	dat += get_header()
	dat += get_tabs(user)
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
	var/dat = "<b>CUSTOM BEHAVIOR ASSEMBLY</b><br>"
	dat += "<span class='dim'>Pick a trigger and a response, then print.</span><br>"
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.special_i < 6)
			return dat + "<br><span class='bad'>&gt; Intelligence too low. Need INT 6+ to program assemblies.</span><br>"
		var/sensor = min(10, 5 + max(0, H.special_p - 5))
		dat += "<span class='dim'>&gt; Sensor range (PER [H.special_p]): [sensor] tiles</span>"
		if(H.special_l >= 7)
			var/luck_chance = (H.special_l - 6) * 15
			dat += "  <span class='good'>LCK [H.special_l]: [luck_chance]% bonus slot</span>"
		dat += "<br>"
	dat += "<hr><b>SELECT TRIGGER</b><br>"
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
	dat += "<hr><b>SELECT RESPONSE</b><br>"
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
	if(custom_trigger_id)
		dat += "<span class='dim'>Trigger:  </span><span class='good'>[t_label]</span><br>"
	else
		dat += "<span class='dim'>Trigger:  </span><span class='bad'>[t_label]</span><br>"
	if(custom_response_id)
		dat += "<span class='dim'>Response: </span><span class='good'>[r_label]</span><br>"
	else
		dat += "<span class='dim'>Response: </span><span class='bad'>[r_label]</span><br>"
	if(!printing && custom_trigger_id && custom_response_id)
		dat += "<br><a href='byond://?src=[REF(src)];build_custom=1'>&gt; Wire and Print</a><br>"
	else if(printing)
		dat += "<br><span class='warn'>&gt; Printing...</span><br>"
	else
		dat += "<br><span class='dim'>&gt; Select both to enable printing.</span><br>"
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
		updateUsrDialog()
		return
	if(href_list["print"])
		var/datum/cpu_fab_design/D = _get_design(href_list["print"])
		if(D)
			_print_card(D, usr)
		updateUsrDialog()
		return
	if(href_list["sel_trigger"])
		var/T = text2path(href_list["sel_trigger"])
		if(T && ispath(T, /datum/behavior_circuit/trigger))
			custom_trigger_id = href_list["sel_trigger"]
		updateUsrDialog()
		return
	if(href_list["sel_response"])
		var/T = text2path(href_list["sel_response"])
		if(T && ispath(T, /datum/behavior_circuit/response))
			custom_response_id = href_list["sel_response"]
		updateUsrDialog()
		return
	if(href_list["build_custom"])
		_build_custom(usr)
		updateUsrDialog()
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
	addtimer(CALLBACK(src, PROC_REF(_finish_print), D, get_turf(src), builder_per, builder_lck, key_name(user)), 30, TIMER_OVERRIDE)


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
	printing = TRUE
	use_power(active_power_usage * 10)
	var/t_name = _resolve_circuit_name(custom_trigger_id)
	var/r_name = _resolve_circuit_name(custom_response_id)
	custom_trigger_id = null
	custom_response_id = null
	addtimer(CALLBACK(src, PROC_REF(_finish_custom), trigger_type, response_type, t_name, r_name, get_turf(src), H.special_p, H.special_l, key_name(H)), 30, TIMER_OVERRIDE)


/obj/machinery/cpu_fabricator/proc/_finish_custom(trigger_type, response_type, t_name, r_name, turf/T, builder_per, builder_lck, builder_ckey)
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
	A.circuits += TR
	A.circuits += RE
	log_game("Custom assembly '[label]' ([trigger_type]->[response_type]) printed by [builder_ckey]")
	visible_message(span_notice("[src] finishes printing: [label]."))


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

/datum/cpu_fab_design/upgrade
	ui_category = "upgrade"

/datum/cpu_fab_design/behavior
	ui_category = "behavior"
	requires_robot_whisperer = TRUE
	required_int = 6
	cost = list("iron" = 400, "glass" = 300, "gold" = 100)


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
	output_path = /obj/item/behavior_assembly/suicide_bomb
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

#undef FAB_HOME
#undef FAB_CERTS
#undef FAB_UPGRADES
#undef FAB_BEHAVIORS
#undef FAB_CUSTOM
