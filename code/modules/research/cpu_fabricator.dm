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
	/// Additional response type paths the player has added beyond the first.
	/// These are wired into trigger.responses_list at print time.
	var/list/extra_response_ids = list()
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
	designs += new /datum/cpu_fab_design/base/hacking_tool()
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
	designs += new /datum/cpu_fab_design/behavior/turret_bot()
	designs += new /datum/cpu_fab_design/behavior/combat_medic_protocol()
	designs += new /datum/cpu_fab_design/behavior/scavenger_protocol()
	designs += new /datum/cpu_fab_design/behavior/hunter_protocol()
	designs += new /datum/cpu_fab_design/behavior/clock_patrol_protocol()
	designs += new /datum/cpu_fab_design/behavior/farming_bot()
	designs += new /datum/cpu_fab_design/behavior/greeter()
	designs += new /datum/cpu_fab_design/behavior/panic()
	designs += new /datum/cpu_fab_design/behavior/sentry_hold()
	designs += new /datum/cpu_fab_design/behavior/fire_watch()
	designs += new /datum/cpu_fab_design/behavior/lockdown()
	designs += new /datum/cpu_fab_design/behavior/grudge()
	designs += new /datum/cpu_fab_design/behavior/watchful()
	designs += new /datum/cpu_fab_design/behavior/vengeance()
	designs += new /datum/cpu_fab_design/behavior/courier()
	designs += new /datum/cpu_fab_design/behavior/parrot()
	// Layer 6-10
	designs += new /datum/cpu_fab_design/behavior/shadow()
	designs += new /datum/cpu_fab_design/behavior/crowd_control()
	designs += new /datum/cpu_fab_design/behavior/depot()
	designs += new /datum/cpu_fab_design/behavior/bodyguard()
	designs += new /datum/cpu_fab_design/behavior/escalation()
	designs += new /datum/cpu_fab_design/behavior/dead_man_timer()
	// Layers A-C
	designs += new /datum/cpu_fab_design/behavior/janitor()
	designs += new /datum/cpu_fab_design/behavior/lamp_bot()
	designs += new /datum/cpu_fab_design/behavior/battery_steward()
	designs += new /datum/cpu_fab_design/behavior/chem_runner()
	designs += new /datum/cpu_fab_design/behavior/reactive_marksman()
	designs += new /datum/cpu_fab_design/behavior/grenadier()
	designs += new /datum/cpu_fab_design/behavior/stun_subdue()
	designs += new /datum/cpu_fab_design/behavior/combat_response()
	designs += new /datum/cpu_fab_design/behavior/bio_scout()
	designs += new /datum/cpu_fab_design/behavior/hazmat_responder()
	designs += new /datum/cpu_fab_design/behavior/gps_zone_guard()
	designs += new /datum/cpu_fab_design/behavior/announce_bot()
	designs += new /datum/cpu_fab_design/behavior/relay_station()
	designs += new /datum/cpu_fab_design/behavior/alchemist()
	// Layer E
	designs += new /datum/cpu_fab_design/behavior/sprint_ambush()
	designs += new /datum/cpu_fab_design/behavior/medevac()
	designs += new /datum/cpu_fab_design/behavior/riot_control()
	designs += new /datum/cpu_fab_design/behavior/thrower_bot()
	designs += new /datum/cpu_fab_design/behavior/supply_drop()
	designs += new /datum/cpu_fab_design/behavior/power_relay_bot()
	designs += new /datum/cpu_fab_design/behavior/collection_sweep()
	designs += new /datum/cpu_fab_design/behavior/watchpost()
	designs += new /datum/cpu_fab_design/behavior/one_shot_announcement()
	designs += new /datum/cpu_fab_design/behavior/pump_station()
	designs += new /datum/cpu_fab_design/behavior/door_patrol()
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
	css += ".csec{margin-top:2px;}"
	css += ".ccard{display:block;}.bcard{display:block;}"
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
	n += _navlink("Home",       FAB_HOME)
	n += " | "
	n += _navlink("Certs",      FAB_CERTS)
	n += " | "
	n += _navlink("Upgrades",   FAB_UPGRADES)
	if(HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
		n += " | "
		n += _navlink("Behavior",   FAB_BEHAVIORS)
		n += " | "
		n += _navlink("Custom",     FAB_CUSTOM)
	else
		n += " | "
		n += _navlink("Custom",     FAB_CUSTOM)
	n += " | "
	n += _navlink("AI Mods",    FAB_AI)
	if(inserted_assembly)
		n += " | "
		n += _navlink("Reprogram",  FAB_REPROG)
	n += "<br><hr>"
	return n


/obj/machinery/cpu_fabricator/proc/_navlink(label, mode_id)
	if(fab_mode == mode_id)
		return "&gt; [label]"
	return "<a href='byond://?src=[REF(src)];mode=[mode_id]'>&gt; [label]</a>"


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
				dat += _render_custom_preview(user)
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
	dat += "<span class='dim'>// This fabricator programs robot minds. Feed it materials, wire a trigger to a response, and print a behavior assembly you can slot into any robot CPU.</span><br><br>"
	dat += "MODULE DIRECTORY<br>"
	dat += "&gt; <a href='byond://?src=[REF(src)];mode=[FAB_CERTS]'>Base Certifications</a>  <span class='dim'>chassis identity cards</span><br>"
	dat += "&gt; <a href='byond://?src=[REF(src)];mode=[FAB_UPGRADES]'>Upgrade Modules</a>  <span class='dim'>hardware enhancements</span><br>"
	dat += "&gt; <a href='byond://?src=[REF(src)];mode=[FAB_AI]'>AI Mods</a>  <span class='dim'>software packages for AI units</span><br>"
	if(HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
		dat += "&gt; <a href='byond://?src=[REF(src)];mode=[FAB_BEHAVIORS]'>Behavior Assemblies</a>  <span class='dim'>preset automation programs</span><br>"
		dat += "&gt; <a href='byond://?src=[REF(src)];mode=[FAB_CUSTOM]'>Custom Build</a>  <span class='dim'>wire your own trigger/response pair</span><br>"
	else
		dat += "<span class='dim'>&gt; Behavior Assemblies  (requires Robot Whisperer trait)</span><br>"
		dat += "<span class='dim'>&gt; Custom Build  (requires Robot Whisperer trait)</span><br>"
	if(HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER) && ishuman(user))
		var/mob/living/carbon/human/H = user
		var/sensor_range = min(10, 5 + max(0, H.special_p - 5))
		var/luck_chance = H.special_l >= 5 ? (H.special_l - 4) * 5 : 0
		dat += "<br>OPERATOR PROFILE  <span class='dim'>// Robot Whisperer</span><br>"
		dat += "<span class='dim'>INT</span> <span class='[H.special_i >= 6 ? "good" : "warn"]'>[H.special_i]</span>"
		dat += "  <span class='dim'>// [H.special_i >= 8 ? "UNRESTRICTED" : H.special_i >= 7 ? "ADV" : H.special_i >= 6 ? "STD" : "LOCKED"]</span><br>"
		dat += "<span class='dim'>PER</span> <span class='good'>[H.special_p]</span>  <span class='dim'>// sensor range: [sensor_range] tiles</span><br>"
		if(luck_chance > 0)
			dat += "<span class='dim'>LCK</span> <span class='good'>[H.special_l]</span>  <span class='good'>// [luck_chance]% chance: bonus circuit slot on Wire and Print</span><br>"
		else
			dat += "<span class='dim'>LCK [H.special_l]  // LCK 5+ unlocks random bonus circuit slots during assembly</span><br>"
	dat += "<br>"
	if(inserted_assembly)
		dat += "REPROGRAM SLOT  <span class='good'>// LOADED</span><br>"
		dat += "<span class='good'>[inserted_assembly.assembly_label]</span>"
		dat += "  <span class='dim'>circuits: [inserted_assembly.circuits.len]/[inserted_assembly.max_circuits] | range: [inserted_assembly.sensor_range] tiles</span><br>"
		dat += "&gt; <a href='byond://?src=[REF(src)];mode=[FAB_REPROG]'>\[configure\]</a>"
		dat += "  <a href='byond://?src=[REF(src)];eject_assembly=1'>\[eject\]</a>"
	else
		dat += "REPROGRAM SLOT  <span class='dim'>// EMPTY - insert a behavior assembly</span><br>"
	var/datum/component/material_container/mats = GetComponent(/datum/component/material_container)
	if(mats)
		var/list/mpaths = list(/datum/material/iron, /datum/material/glass, /datum/material/gold, /datum/material/silver)
		var/list/mnames = list("iron", "glass", "gold", "silver")
		var/mat_max_fab = MINERAL_MATERIAL_AMOUNT * 50
		dat += "<br>MATERIAL HOPPER  <a href='byond://?src=[REF(src)];eject_mats=1'>\[eject all\]</a><br>"
		var/any_loaded = FALSE
		for(var/i in 1 to mpaths.len)
			var/amt = mats.get_material_amount(mpaths[i]) || 0
			if(amt > 0)
				any_loaded = TRUE
		if(!any_loaded)
			dat += "<span class='warn'>&gt; Hopper empty. Insert iron, glass, gold, or silver sheets from your inventory to load materials.</span><br>"
		for(var/i in 1 to mpaths.len)
			var/amt = mats.get_material_amount(mpaths[i]) || 0
			var/filled = round(clamp(amt / mat_max_fab, 0, 1) * 10)
			var/bar = ""
			for(var/j in 1 to 10)
				bar += (j <= filled) ? "#" : "-"
			dat += "<span class='dim'>[mnames[i]]</span>  "
			var/bar_class = amt > 0 ? "good" : "dim"
			dat += "<span class='[bar_class]'>\[[bar]\]</span>  "
			dat += "<span class='warn'>[amt]</span><span class='dim'>/[mat_max_fab] cm3</span>  "
			if(amt > 0)
				dat += "<a href='byond://?src=[REF(src)];eject_mat=[mnames[i]]'>\[eject\]</a>"
			dat += "<br>"
	return dat

// ============================================================
// PRESET LIST RENDERER
// ============================================================

/obj/machinery/cpu_fabricator/proc/_render_list(mob/user, category)
	var/dat = ""
	var/count = 0
	// Category intro headers
	if(category == "cert")
		dat += "<span class='dim'>// Cert cards define what a robot IS — its stats, upgrade slots, and what assemblies it can run. Print one and slot it into a robot at the workshop.</span><br>"
		dat += "<span class='dim'>// Workflow: print a cert here → carry it to the Robot Workshop → insert it in the Programs tab before building.</span><br>"
		dat += "<span class='dim'>// Start with Standard. Combat/Medical/Engineering require a purpose-built robot to be worth it.</span><br><br>"
	else if(category == "upgrade")
		dat += "<span class='dim'>// Upgrade cards install into a robot's cert slot to boost C.O.R.E. stats or add capabilities. Slot them directly onto the robot.</span><br><br>"
	else if(category == "behavior")
		dat += "<span class='dim'>// Behavior assemblies are pre-wired programs. Print one and slot it into a robot at the Robot Workshop.</span><br>"
		dat += "<span class='dim'>&gt; Search:</span> "
		var/ccs = null; ccs = ccs
		var/ccn = null; ccn = ccn
		var/cci = null; cci = cci
		dat += {"<input id='bfilter' type='text' autofocus placeholder='filter behaviors...' onkeyup='var ccs=this.value.toLowerCase();var ccn=document.getElementsByClassName(&quot;bcard&quot;).length;while(ccn--){cci=document.getElementsByClassName(&quot;bcard&quot;).item(ccn);cci.style.display=cci.getAttribute(&quot;data-s&quot;).indexOf(ccs)>=0?&quot;block&quot;:&quot;none&quot;;}' style='background:#062113;color:#4aed92;border:1px solid #2a7a52;font-family:monospace;padding:2px 4px;width:220px' /><br><br>"}
	for(var/datum/cpu_fab_design/D in designs)
		if(D.ui_category != category)
			continue
		count++
		var/dname = D.design_name
		var/ddesc = D.design_desc
		// Build search key for behavior entries
		var/searchkey = ""
		var/use_card = (category == "behavior")
		if(use_card)
			searchkey = replacetext(lowertext(dname) + " " + lowertext(ddesc), "'", "")
			dat += "<div class='bcard' data-s='[searchkey]'>"
		// Name line: name + inline tier/int tags + starter callout
		dat += "[dname]"
		if(D.starter_build)
			dat += "  <span class='good'>★ Starter</span>"
		if(D.required_tier > CERT_TIER_BASIC)
			dat += "  <span class='warn'>Tier 2 - Military</span>"
		if(D.required_int > 0)
			dat += "  <span class='dim'>INT [D.required_int]+</span>"
		dat += "<br>"
		// Desc line
		dat += "<span class='dim'>[ddesc]</span><br>"
		// Suited-for hint (cert category only)
		if(category == "cert" && D.suited_for != "")
			dat += "<span class='dim'>Best suited for: [D.suited_for]</span><br>"
		// Hardware required note (behaviors only)
		if(category == "behavior" && ispath(D.output_path, /obj/item/behavior_assembly))
			var/obj/item/behavior_assembly/test = new D.output_path()
			var/hw_list = ""
			for(var/datum/behavior_circuit/C in test.circuits)
				if(C.needs_hardware)
					hw_list += (hw_list ? ", " : "") + C.circuit_name
			qdel(test)
			if(hw_list)
				dat += "<span class='warn'>&gt; hardware required: [hw_list]</span><br>"
		// Upgrade-specific: C.O.R.E. delta, capability requirements, conflicts, tutorial
		if(category == "upgrade" || category == "ai_upgrade")
			if(ispath(D.output_path, /obj/item/cert_card/upgrade))
				var/obj/item/cert_card/upgrade/card = new D.output_path()
				var/datum/cert_upgrade/U = card.upgrade
				if(U)
					// C.O.R.E. delta line
					var/list/core_parts = list()
					if(U.compute_mod)
						var/s = U.compute_mod > 0 ? "+" : ""
						core_parts += "C[s][U.compute_mod]"
					if(U.operations_mod)
						var/s = U.operations_mod > 0 ? "+" : ""
						core_parts += "O[s][U.operations_mod]"
					if(U.resilience_mod)
						var/s = U.resilience_mod > 0 ? "+" : ""
						core_parts += "R[s][U.resilience_mod]"
					if(U.energy_mod)
						var/s = U.energy_mod > 0 ? "+" : ""
						core_parts += "E[s][U.energy_mod]"
					if(core_parts.len)
						dat += "<span class='dim'>C.O.R.E.: [core_parts.Join("  ")]</span><br>"
					// Required capability flag hint
					if(U.required_capability_flags)
						dat += "<span class='warn'>&gt; requires chassis capability flag [U.required_capability_flags]</span><br>"
					// Exclusive_with warning
					if(U.exclusive_with && U.exclusive_with.len)
						var/list/ex_names = list()
						for(var/T in U.exclusive_with)
							var/datum/cert_upgrade/ex_inst = new T()
							ex_names += ex_inst.upgrade_name
							qdel(ex_inst)
						dat += "<span class='warn'>&gt; conflicts with: [ex_names.Join(", ")]</span><br>"
					// Tutorial text
					if(U.tutorial_text && U.tutorial_text != "No documentation available.")
						dat += "<span class='dim'>[html_encode(U.tutorial_text)]</span><br>"
				qdel(card)
		// Cost line
		if(D.cost && D.cost.len)
			var/cost_text = ""
			var/first = TRUE
			for(var/mat in D.cost)
				var/amt = D.cost[mat]
				if(!first)
					cost_text += ", "
				cost_text += "[amt] [mat]"
				first = FALSE
			dat += "<span class='dim'>cost: [cost_text]</span><br>"
		if(D.for_ai)
			dat += "<span class='dim'>installed on AI units, not robots</span><br>"
		// Action line
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
		if(can_print)
			dat += "<a href='byond://?src=[REF(src)];print=[D.id]'>&gt; Print</a><br>"
		else if(block_reason)
			dat += "<span class='dim'>&gt; Locked: [block_reason]</span><br>"
		else
			dat += "<span class='dim'>&gt; Locked</span><br>"
		dat += "<hr>"
		if(use_card)
			dat += "</div>"
	if(!count)
		dat += "<span class='dim'>&gt; No designs in this category.</span><br>"
	return dat


// ============================================================
// CUSTOM BUILD WORKSHOP
// ============================================================

// Read-only browse preview of the custom workshop for players without Robot Whisperer.
// Shows all trigger/response combinations but locks the Wire and Print button.
/obj/machinery/cpu_fabricator/proc/_render_custom_preview(mob/user)
	var/dat = "BEHAVIOR ASSEMBLY WORKSHOP  <span class='warn'>// READ-ONLY PREVIEW</span><br>"
	dat += "<span class='dim'>Robot Whisperer trait required to wire and print. Browse below to see what's possible.</span><br><hr>"
	dat += "AVAILABLE TRIGGERS  <span class='dim'>// what makes your robot react</span><br>"
	for(var/T in subtypesof(/datum/behavior_circuit/trigger))
		if(T == /datum/behavior_circuit/trigger) continue
		var/datum/behavior_circuit/trigger/inst = new T
		dat += "<span class='dim'>&gt; [inst.circuit_name]</span>  <span class='dim'>CPU: [inst.cpu_cost]</span><br>"
		dat += "<span class='dim'>  [inst.circuit_desc]</span><br>"
		qdel(inst)
	dat += "<hr>AVAILABLE RESPONSES  <span class='dim'>// what your robot does when triggered</span><br>"
	for(var/T in subtypesof(/datum/behavior_circuit/response))
		if(T == /datum/behavior_circuit/response) continue
		var/datum/behavior_circuit/response/inst = new T
		dat += "<span class='dim'>&gt; [inst.circuit_name]</span>  <span class='dim'>CPU: [inst.cpu_cost]</span><br>"
		dat += "<span class='dim'>  [inst.circuit_desc]</span><br>"
		qdel(inst)
	dat += "<hr><span class='warn'>&gt; WIRE AND PRINT  // locked - Robot Whisperer trait required</span><br>"
	dat += "<span class='dim'>Operators with this trait can combine any trigger with any response to print a custom behavior assembly.</span><br>"
	return dat


/obj/machinery/cpu_fabricator/proc/_render_custom(mob/user)
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.special_i < 6)
			var/dat2 = "CUSTOM BEHAVIOR WORKSHOP<br>"
			dat2 += "<span class='bad'>&gt; INTELLIGENCE TOO LOW. INT 6 required to program assemblies.</span><br>"
			return dat2
	return _render_workshop(user)


/obj/machinery/cpu_fabricator/proc/_render_workshop(mob/user)
	var/dat = "BEHAVIOR ASSEMBLY WORKSHOP"
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
		if(H.special_l >= 5)
			var/lchance = (H.special_l - 4) * 5
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
		if(5)
			dat += _workshop_phase_extra_response(user)
		else
			dat += _workshop_phase_trigger(user)
	return dat


// Phase 1: Pick a trigger - split into STANDARD and HARDWARE sections
/obj/machinery/cpu_fabricator/proc/_workshop_phase_trigger(mob/user)
	var/dat = "STEP 1 -- SELECT TRIGGER<br>"
	dat += "<span class='dim'>The trigger defines WHEN your assembly acts.</span><br>"
	dat += "<span class='dim'>&gt; Search:</span> "
	var/ccs = null; ccs = ccs // JS: search string
	var/ccn = null; ccn = ccn // JS: card count
	var/cci = null; cci = cci // JS: card item
	var/sn  = null; sn  = sn  // JS: section index
	dat += {"<input id='cfilter' type='text' autofocus placeholder='filter circuits...' onkeyup='var ccs=this.value.toLowerCase();var ccn=document.getElementsByClassName(&quot;ccard&quot;).length;while(ccn--){cci=document.getElementsByClassName(&quot;ccard&quot;).item(ccn);cci.style.display=cci.getAttribute(&quot;data-s&quot;).indexOf(ccs)>=0?&quot;block&quot;:&quot;none&quot;;}var sn=document.getElementsByClassName(&quot;csec&quot;).length;while(sn--){document.getElementsByClassName(&quot;csec&quot;).item(sn).style.display=ccs?&quot;none&quot;:&quot;block&quot;;}' style='background:#062113;color:#4aed92;border:1px solid #2a7a52;font-family:monospace;padding:2px 4px;width:220px' /><br>"}
	if(custom_trigger_id)
		dat += "&gt; <a href='byond://?src=[REF(src)];workshop_phase=1'>Continue to Response selection</a><br>"
	dat += "<br>"
	var/list/standard_triggers = list()
	var/list/hardware_triggers = list()
	for(var/T in subtypesof(/datum/behavior_circuit/trigger))
		if(T == /datum/behavior_circuit/trigger) continue
		var/datum/behavior_circuit/trigger/inst = new T
		var/entry = list("path"=T, "name"=inst.circuit_name, "desc"=inst.circuit_desc, "tut"=inst.tutorial_text, "cpu"=inst.cpu_cost, "hw"=inst.needs_hardware)
		if(inst.needs_hardware)
			hardware_triggers += list(entry)
		else
			standard_triggers += list(entry)
		qdel(inst)
	dat += "<div class='csec'>STANDARD TRIGGERS <span class='dim'>(work on any robot)</span></div>"
	for(var/list/E in standard_triggers)
		var/tpath = "[E["path"]]"
		var/searchkey = replacetext(lowertext(E["name"]) + " " + lowertext(E["desc"]), "'", "")
		dat += "<div class='ccard' data-s='[searchkey]'>"
		if(custom_trigger_id == tpath)
			dat += "<span class='good'>&gt; * [E["name"]]</span> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		else
			dat += "<a href='byond://?src=[REF(src)];sel_trigger=[tpath]'>&gt; [E["name"]]</a> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		dat += "<span class='dim'>[E["desc"]]</span><br>"
		dat += "<span class='dim' >[E["tut"]]</span>"
		dat += "</div>"
	dat += "<div class='csec'>HARDWARE TRIGGERS <span class='warn'>(require specific modules)</span></div>"
	for(var/list/E in hardware_triggers)
		var/tpath = "[E["path"]]"
		var/searchkey = replacetext(lowertext(E["name"]) + " " + lowertext(E["desc"]), "'", "")
		dat += "<div class='ccard' data-s='[searchkey]'>"
		if(custom_trigger_id == tpath)
			dat += "<span class='good'>&gt; * [E["name"]]</span> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		else
			dat += "<a href='byond://?src=[REF(src)];sel_trigger=[tpath]'>&gt; [E["name"]]</a> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		dat += "<span class='dim'>[E["desc"]]</span><br>"
		dat += "<span class='dim'>[E["tut"]]</span>"
		dat += "</div>"
	if(custom_trigger_id)
		dat += "<br><a href='byond://?src=[REF(src)];workshop_phase=1'>&gt; Continue to Response selection</a><br>"
	return dat


// Phase 2: Pick a response - split into STANDARD and HARDWARE sections
/obj/machinery/cpu_fabricator/proc/_workshop_phase_response(mob/user)
	var/dat = "STEP 2 -- SELECT RESPONSE<br>"
	dat += "<span class='dim'>The response defines WHAT happens when the trigger fires.</span><br>"
	dat += "<span class='dim'>&gt; Search:</span> "
	var/ccs = null; ccs = ccs // JS: search string
	var/ccn = null; ccn = ccn // JS: card count
	var/cci = null; cci = cci // JS: card item
	var/sn  = null; sn  = sn  // JS: section index
	dat += {"<input id='cfilter' type='text' autofocus placeholder='filter circuits...' onkeyup='var ccs=this.value.toLowerCase();var ccn=document.getElementsByClassName(&quot;ccard&quot;).length;while(ccn--){cci=document.getElementsByClassName(&quot;ccard&quot;).item(ccn);cci.style.display=cci.getAttribute(&quot;data-s&quot;).indexOf(ccs)>=0?&quot;block&quot;:&quot;none&quot;;}var sn=document.getElementsByClassName(&quot;csec&quot;).length;while(sn--){document.getElementsByClassName(&quot;csec&quot;).item(sn).style.display=ccs?&quot;none&quot;:&quot;block&quot;;}' style='background:#062113;color:#4aed92;border:1px solid #2a7a52;font-family:monospace;padding:2px 4px;width:220px' /><br>"}
	if(custom_response_id)
		dat += "&gt; <a href='byond://?src=[REF(src)];advance_from_response=1'>Continue</a><br>"
	dat += "<br>"
	var/list/standard_responses = list()
	var/list/hardware_responses = list()
	for(var/T in subtypesof(/datum/behavior_circuit/response))
		if(T == /datum/behavior_circuit/response) continue
		var/datum/behavior_circuit/response/inst = new T
		var/entry = list("path"=T, "name"=inst.circuit_name, "desc"=inst.circuit_desc, "tut"=inst.tutorial_text, "cpu"=inst.cpu_cost, "hw"=inst.needs_hardware)
		if(inst.needs_hardware)
			hardware_responses += list(entry)
		else
			standard_responses += list(entry)
		qdel(inst)
	dat += "<div class='csec'>STANDARD RESPONSES <span class='dim'>(work on any robot)</span></div>"
	for(var/list/E in standard_responses)
		var/rpath = "[E["path"]]"
		var/searchkey = replacetext(lowertext(E["name"]) + " " + lowertext(E["desc"]), "'", "")
		dat += "<div class='ccard' data-s='[searchkey]'>"
		if(custom_response_id == rpath)
			dat += "<span class='good'>&gt; * [E["name"]]</span> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		else
			dat += "<a href='byond://?src=[REF(src)];sel_response=[rpath]'>&gt; [E["name"]]</a> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		dat += "<span class='dim'>[E["desc"]]</span><br>"
		dat += "<span class='dim' >[E["tut"]]</span>"
		dat += "</div>"
	dat += "<div class='csec'>HARDWARE RESPONSES <span class='warn'>(require specific modules)</span></div>"
	for(var/list/E in hardware_responses)
		var/rpath = "[E["path"]]"
		var/searchkey = replacetext(lowertext(E["name"]) + " " + lowertext(E["desc"]), "'", "")
		dat += "<div class='ccard' data-s='[searchkey]'>"
		if(custom_response_id == rpath)
			dat += "<span class='good'>&gt; * [E["name"]]</span> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		else
			dat += "<a href='byond://?src=[REF(src)];sel_response=[rpath]'>&gt; [E["name"]]</a> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		dat += "<span class='dim'>[E["desc"]]</span><br>"
		dat += "<span class='dim'>[E["tut"]]</span>"
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
	var/dat = "BONUS CIRCUIT SLOT<br>"
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
		if(T == base_path) continue
		var/datum/behavior_circuit/inst = new T
		var/entry = list("path"=T, "name"=inst.circuit_name, "desc"=inst.circuit_desc, "cpu"=inst.cpu_cost, "hw"=inst.needs_hardware)
		if(inst.needs_hardware)
			hardware_bonus += list(entry)
		else
			standard_bonus += list(entry)
		qdel(inst)
	dat += "<div class='csec'>STANDARD</div>"
	for(var/list/E in standard_bonus)
		var/bpath = "[E["path"]]"
		dat += ""
		if(custom_bonus_id == bpath)
			dat += "<span class='good'>&gt; * [E["name"]]</span> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		else
			dat += "<a href='byond://?src=[REF(src)];sel_bonus=[bpath]'>&gt; [E["name"]]</a> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		dat += "<span class='dim'>[E["desc"]]</span>"
		dat += "</div>"
	dat += "<br><b>HARDWARE</b> <span class='warn'>(require specific modules)</span><br>"
	for(var/list/E in hardware_bonus)
		var/bpath = "[E["path"]]"
		dat += ""
		if(custom_bonus_id == bpath)
			dat += "<span class='good'>&gt; * [E["name"]]</span> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		else
			dat += "<a href='byond://?src=[REF(src)];sel_bonus=[bpath]'>&gt; [E["name"]]</a> <span class='dim'>CPU: [E["cpu"]]</span><br>"
		dat += "<span class='dim'>[E["desc"]]</span><br>"
	if(custom_bonus_id)
		dat += "<br><a href='byond://?src=[REF(src)];build_custom_confirm=1'>&gt; WIRE AND PRINT WITH BONUS</a><br>"
	dat += "<a href='byond://?src=[REF(src)];build_custom_defer=1'><span class='dim'>&gt; Print now, choose bonus at REPROGRAM</span></a><br>"
	return dat


// Phase 3: Configure vars for selected circuits
/obj/machinery/cpu_fabricator/proc/_workshop_phase_configure(mob/user)
	var/dat = "STEP 3 -- CONFIGURE<br>"
	dat += "<span class='dim'>Adjust parameters for your circuits. Leave defaults if unsure.</span><br><hr>"
	// Trigger
	dat += "TRIGGER: <span class='[custom_trigger_id ? "good" : "bad"]'>[custom_trigger_id ? _resolve_circuit_name(custom_trigger_id) : "(none selected)"]</span>"
	if(custom_trigger_id)
		dat += " <a href='byond://?src=[REF(src)];workshop_phase=0'>\[change\]</a>"
	dat += "<br>"
	if(custom_trigger_id)
		var/trigger_type = text2path(custom_trigger_id)
		if(trigger_type)
			var/datum/behavior_circuit/TI = new trigger_type()
			dat += _render_circuit_config_inline(TI, "trigger")
			qdel(TI)
	dat += "<hr>RESPONSE: <span class='[custom_response_id ? "good" : "bad"]'>[custom_response_id ? _resolve_circuit_name(custom_response_id) : "(none selected)"]</span>"
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
		dat += "<hr>BONUS [uppertext(bonus_slot_mode)]: <span class='good'>[_resolve_circuit_name(custom_bonus_id)]</span><br>"
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
/obj/machinery/cpu_fabricator/proc/_workshop_phase_extra_response(mob/user)
	var/dat = "ADD RESPONSE<br>"
	dat += "<span class='dim'>Pick an additional response. The trigger will fire ALL wired responses in sequence.</span><br><hr>"
	var/list/standard_responses = list()
	var/list/hardware_responses = list()
	for(var/T in subtypesof(/datum/behavior_circuit/response))
		if(T == /datum/behavior_circuit/response) continue
		var/datum/behavior_circuit/response/inst = new T
		var/entry = list("path"=T, "name"=inst.circuit_name, "desc"=inst.circuit_desc, "cpu"=inst.cpu_cost, "hw"=inst.needs_hardware)
		if(inst.needs_hardware)
			hardware_responses += list(entry)
		else
			standard_responses += list(entry)
		qdel(inst)
	dat += "<div class='csec'>STANDARD RESPONSES</div>"
	for(var/list/E in standard_responses)
		var/rpath = "[E["path"]]"
		if(rpath == custom_response_id || (extra_response_ids && (rpath in extra_response_ids)))
			dat += "<span class='dim'>[E["name"]] (already added)</span><br>"
			continue
		dat += "<a href='byond://?src=[REF(src)];add_extra_response=[rpath]'>&gt; [E["name"]]</a> <span class='dim'>CPU: [E["cpu"]]</span><br>"
	dat += "<div class='csec'>HARDWARE RESPONSES</div>"
	for(var/list/E in hardware_responses)
		var/rpath = "[E["path"]]"
		if(rpath == custom_response_id || (extra_response_ids && (rpath in extra_response_ids)))
			dat += "<span class='dim'>[E["name"]] (already added)</span><br>"
			continue
		dat += "<a href='byond://?src=[REF(src)];add_extra_response=[rpath]'>&gt; [E["name"]]</a> <span class='dim'>CPU: [E["cpu"]] | requires hardware</span><br>"
	dat += "<hr><a href='byond://?src=[REF(src)];workshop_phase=4'>&lt; Back to Review</a><br>"
	return dat



// Phase 4: Review + print
/obj/machinery/cpu_fabricator/proc/_workshop_phase_review(mob/user)
	var/dat = "STEP 4 -- REVIEW & PRINT<br>"
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
	dat += "TRIGGER:  <span class='[custom_trigger_id ? "good" : "bad"]'>[t_name]</span>"
	if(custom_trigger_id)
		dat += " <a href='byond://?src=[REF(src)];workshop_phase=0'>\[change\]</a>"
	dat += " <span class='dim'>CPU: [t_cpu]</span><br>"
	dat += "RESPONSE: <span class='[custom_response_id ? "good" : "bad"]'>[r_name]</span>"
	if(custom_response_id)
		dat += " <a href='byond://?src=[REF(src)];workshop_phase=1'>\[change\]</a>"
	dat += " <span class='dim'>CPU: [r_cpu]</span><br>"
	// Extra responses (multi-response wiring)
	if(extra_response_ids && extra_response_ids.len)
		dat += "<span class='dim'>+ [extra_response_ids.len] additional response(s):</span><br>"
		for(var/eid in extra_response_ids)
			var/ename = _resolve_circuit_name(eid)
			dat += "&nbsp;&nbsp;<span class='good'>[ename]</span> <a href='byond://?src=[REF(src)];remove_extra_response=[eid]'>\[x\]</a><br>"
	if(custom_response_id && extra_response_ids.len < 3)
		dat += "<a href='byond://?src=[REF(src)];workshop_phase=5'><span class='dim'>+ Add another response</span></a><br>"
	if(bonus_slot_available && bonus_slot_mode && custom_bonus_id)
		dat += "BONUS [uppertext(bonus_slot_mode)]: <span class='good'>[_resolve_circuit_name(custom_bonus_id)]</span> <span class='dim'>CPU: [b_cpu]</span><br>"
	dat += "TOTAL CPU: <span class='good'>[total_cpu]</span>"
	dat += "  <span class='dim'>// cert budget: Standard=5  Combat=10  Medical=8  Engineering=7</span><br>"
	dat += "<span class='dim'>(Assembly must fit the compute budget of the cert installed in the robot.)</span><br>"
	// Plain-English summary
	if(custom_trigger_id && custom_response_id)
		var/summary = _build_plain_english_summary()
		if(summary)
			dat += "<br><span class='good'>// [summary]</span><br>"
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
		dat += "<a href='byond://?src=[REF(src)];build_custom=1'>&gt; WIRE AND PRINT</a>"
		dat += "  <a href='byond://?src=[REF(src)];clear_workshop=1'><span class='dim'>\[clear\]</span></a><br>"
	else
		dat += "<span class='bad'>&gt; Select trigger and response first.</span><br>"
	return dat


// ============================================================
// PLAIN-ENGLISH SUMMARY
// Generates a one-sentence description of what the wired
// assembly will do, shown on the Review screen.
// ============================================================

/obj/machinery/cpu_fabricator/proc/_build_plain_english_summary()
	if(!custom_trigger_id || !custom_response_id)
		return null
	var/t_name = _resolve_circuit_name(custom_trigger_id)
	var/r_name = _resolve_circuit_name(custom_response_id)
	// Build extra response clause if any
	var/extra_clause = ""
	if(extra_response_ids && extra_response_ids.len)
		var/list/extra_names = list()
		for(var/eid in extra_response_ids)
			extra_names += _resolve_circuit_name(eid)
		extra_clause = " AND [extra_names.Join(", ")]"
	// Bonus circuit clause
	var/bonus_clause = ""
	if(bonus_slot_available && bonus_slot_mode && custom_bonus_id)
		bonus_clause = " (Bonus: also [_resolve_circuit_name(custom_bonus_id)].)"
	return "When your robot triggers [t_name], it will [r_name][extra_clause].[bonus_clause]"


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
	dat += "<span class='dim'>[C.tutorial_text]</span><br>"
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
		dat += "<span class='dim'>[label]</span>"
		dat += " = <span class='good'>[cur_val]</span>"
		dat += " \[<a href='byond://?src=[REF(src)];prompt_config=[prefix].[varname]'>edit</a>\]"
		if(hint)
			dat += "  <span class='dim'>[hint]</span>"
		dat += "<br>"
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
	var/dat = "CONFIGURE: [A.assembly_label]<br>"
	dat += "<span class='dim'>Slots: [A.circuits.len]/[A.max_circuits] | Range: [A.sensor_range] tiles</span><br>"
	// Pending bonus from deferred LCK roll at print time
	if(A.pending_bonus_slot)
		dat += "<br>PENDING BONUS CIRCUIT  <span class='good'>// earned at print via LCK</span><br>"
		dat += "<span class='dim'>Pick a [A.pending_bonus_slot] circuit to wire into this assembly.</span><br>"
		var/base_path2 = A.pending_bonus_slot == "trigger" ? /datum/behavior_circuit/trigger : /datum/behavior_circuit/response
		for(var/T2 in subtypesof(base_path2))
			var/datum/behavior_circuit/inst2 = new T2
			var/bpath2 = "[T2]"
			var/hw2 = inst2.needs_hardware
			var/bname2 = inst2.circuit_name
			var/bdesc2 = inst2.circuit_desc
			qdel(inst2)
			dat += ""
			dat += "&gt; <a href='byond://?src=[REF(src)];wire_pending_bonus=[bpath2]'>[bname2]</a>"
			if(hw2)
				dat += "  <span class='warn'>HARDWARE</span>"
			dat += "<br><span class='dim'>[bdesc2]</span>"
			dat += "<br>"
		dat += "<a href='byond://?src=[REF(src)];wire_pending_bonus=skip'><span class='dim'>&gt; Skip - discard bonus</span></a><br>"
		dat += "<hr>"
	else if(!A.slot_expansion_used && HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER) && A.max_circuits < 4)
		dat += "<br>EXPAND CIRCUIT SLOT  <span class='dim'>(one-time | costs [REPROGRAM_COST_GOLD] gold)</span><br>"
		dat += "<span class='dim'>Adds one empty slot so you can install an additional circuit. Cannot be undone.</span><br>"
		dat += "&gt; <a href='byond://?src=[REF(src)];reprog_expand=trigger'>\[+ TRIGGER slot\]</a>"
		dat += "  <a href='byond://?src=[REF(src)];reprog_expand=response'>\[+ RESPONSE slot\]</a><br>"
		dat += "<hr>"
	if(A.circuits.len)
		dat += "<br>INSTALLED CIRCUITS<br>"
		for(var/datum/behavior_circuit/C in A.circuits)
			var/hw_label = C.needs_hardware ? "  <span class='warn'>HARDWARE</span>" : ""
			dat += "<span class='dim'>&gt; [C.circuit_name][hw_label]</span><br>"
	dat += "<hr>"
	dat += "CONFIGURE VARIABLES  <span class='dim'>(free - no material cost)</span><br>"
	dat += "<span class='dim'>Changes apply immediately. Preset protocols cannot be rewired, only tuned.</span><br>"
	if(A.circuits.len)
		for(var/datum/behavior_circuit/C in A.circuits)
			dat += "<br><span class='good'>[C.circuit_name]</span><br>"
			dat += _render_circuit_config_inline(C, "reprogram_[A.circuits.Find(C)]")
		dat += "<br><a href='byond://?src=[REF(src)];reprogram_vars=1'>&gt; Apply Changes</a><br>"
	else
		dat += "<span class='dim'>&gt; No circuits installed.</span><br>"
	dat += "<hr>"
	dat += "<a href='byond://?src=[REF(src)];eject_assembly=1'>&gt; Eject Assembly</a><br>"
	return dat

// Wire a deferred bonus circuit earned via LCK roll at print time.
// "skip" discards it; any valid path installs the circuit into the assembly.
/obj/machinery/cpu_fabricator/proc/_wire_pending_bonus(mob/user, path_or_skip)
	if(!inserted_assembly)
		return
	var/obj/item/behavior_assembly/A = inserted_assembly
	if(!A.pending_bonus_slot)
		to_chat(user, span_warning("No pending bonus circuit on this assembly."))
		return
	if(path_or_skip == "skip")
		A.pending_bonus_slot = null
		A.max_circuits = max(A.max_circuits - 1, A.circuits.len)  // reclaim reserved slot
		to_chat(user, span_warning("Bonus circuit discarded."))
		return
	var/bonus_path = text2path(path_or_skip)
	if(!bonus_path)
		return
	var/base_path = A.pending_bonus_slot == "trigger" ? /datum/behavior_circuit/trigger : /datum/behavior_circuit/response
	if(!ispath(bonus_path, base_path))
		return
	if(A.circuits.len >= A.max_circuits)
		to_chat(user, span_warning("Assembly is full."))
		return
	var/datum/behavior_circuit/BONUS = new bonus_path()
	// If it's a trigger, wire it to fire the first installed response
	if(istype(BONUS, /datum/behavior_circuit/trigger))
		var/datum/behavior_circuit/trigger/BT = BONUS
		for(var/datum/behavior_circuit/response/R in A.circuits)
			BT.response = R
			break
	var/bonus_slot_type = A.pending_bonus_slot
	A.circuits += BONUS
	A.pending_bonus_slot = null
	to_chat(user, span_good("Bonus [bonus_slot_type] wired: [BONUS.circuit_name]."))
	visible_message(span_notice("[src] completes a circuit installation on [A.assembly_label]."))
	log_game("[key_name(user)] wired deferred bonus '[BONUS.circuit_name]' into '[A.assembly_label]' at [AREACOORD(src)]")


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
			// Coerce to number if the existing var is numeric - input() always returns text
			if(isnum(old_val) && istext(new_val))
				new_val = text2num(new_val)
				if(isnull(new_val))
					new_val = old_val  // bad input - keep old value
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
	// Wire primary response and any extra responses as multi-response list
	if(extra_response_ids && extra_response_ids.len)
		TR.responses_list = list(RE)
		for(var/extra_path_str in extra_response_ids)
			var/extra_path = text2path(extra_path_str)
			if(extra_path && ispath(extra_path, /datum/behavior_circuit/response))
				var/datum/behavior_circuit/response/ER = new extra_path()
				TR.responses_list += ER
				A.circuits += ER
	else
		TR.response = RE
	A.circuits += TR
	A.circuits += RE
	A.assembly_label = "[_resolve_circuit_name(custom_trigger_id)] -> [_resolve_circuit_name(custom_response_id)]"
	A.name = "behavior assembly - [A.assembly_label]"
	custom_trigger_id = null
	custom_response_id = null
	extra_response_ids = list()
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
	if(href_list["add_extra_response"])
		var/epath = href_list["add_extra_response"]
		if(ispath(text2path(epath), /datum/behavior_circuit/response))
			if(!(epath in extra_response_ids) && epath != custom_response_id)
				extra_response_ids += epath
		workshop_phase = 4
		ui_interact(usr)
		return
	if(href_list["remove_extra_response"])
		extra_response_ids -= href_list["remove_extra_response"]
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
			if(H.special_l >= 5)
				var/luck_chance = (H.special_l - 4) * 5
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
	if(href_list["build_custom_defer"])
		_build_custom(usr, TRUE)
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
			// Clamp numeric inputs to sane ranges to prevent runtime overflows
			var/num_test = text2num(new_val)
			if(!isnull(num_test))
				new_val = "[clamp(num_test, -9999, 99999)]"
			custom_config[key] = new_val
		ui_interact(usr)
		return
	if(href_list["clear_workshop"])
		custom_trigger_id = null
		custom_response_id = null
		extra_response_ids = list()
		custom_bonus_id = null
		bonus_slot_mode = null
		bonus_slot_available = FALSE
		custom_config = list()
		workshop_phase = 0
		ui_interact(usr)
		return
	if(href_list["wire_pending_bonus"])
		_wire_pending_bonus(usr, href_list["wire_pending_bonus"])
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
	if(href_list["eject_mat"])
		var/datum/component/material_container/mats_single = GetComponent(/datum/component/material_container)
		if(mats_single)
			var/list/mat_map = list(
				"iron"   = /datum/material/iron,
				"glass"  = /datum/material/glass,
				"gold"   = /datum/material/gold,
				"silver" = /datum/material/silver
			)
			var/mkey = href_list["eject_mat"]
			var/mpath = mat_map[mkey]
			if(mpath)
				var/have = mats_single.get_material_amount(mpath) || 0
				if(have > 0)
					var/sheets = round(have / MINERAL_MATERIAL_AMOUNT)
					mats_single.use_amount_mat(sheets * MINERAL_MATERIAL_AMOUNT, mpath)
					if(sheets > 0)
						var/list/sheet_paths = list(
							/datum/material/iron   = /obj/item/stack/sheet/metal,
							/datum/material/glass  = /obj/item/stack/sheet/glass,
							/datum/material/gold   = /obj/item/stack/sheet/mineral/gold,
							/datum/material/silver = /obj/item/stack/sheet/mineral/silver
						)
						var/spath = sheet_paths[mpath]
						if(spath)
							new spath(get_turf(src), sheets)
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

/obj/machinery/cpu_fabricator/proc/_build_custom(mob/user, defer_bonus = FALSE)
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
	var/list/extra_snap = extra_response_ids.Copy()
	custom_config = list()
	extra_response_ids = list()
	workshop_phase = 0
	var/deferred_bonus_mode = defer_bonus ? b_mode : null
	addtimer(CALLBACK(src, PROC_REF(_finish_custom), trigger_type, response_type, bonus_type, b_mode, deferred_bonus_mode, t_name, r_name, b_name, get_turf(src), H.special_p, H.special_l, key_name(H), config_snap, extra_snap), 30, TIMER_UNIQUE|TIMER_OVERRIDE)


/obj/machinery/cpu_fabricator/proc/_finish_custom(trigger_type, response_type, bonus_type, bonus_mode, deferred_bonus_mode, t_name, r_name, b_name, turf/T, builder_per, builder_lck, builder_ckey, list/config_snapshot, list/extra_response_paths = null)
	printing = FALSE
	var/label = "[t_name] -> [r_name]"
	if(b_name)
		label += " + [b_name]"
	var/obj/item/behavior_assembly/A = new(T)
	A.assembly_label = label
	A.name = "behavior assembly - [label]"
	A.sensor_range = clamp(5 + max(0, builder_per - 5), 5, 10)
	A.builder_ckey = builder_ckey
	// Deferred bonus: player chose to wire the bonus circuit later at REPROGRAM
	if(deferred_bonus_mode)
		A.pending_bonus_slot = deferred_bonus_mode
		A.max_circuits = 3  // reserve the slot
		A.slot_expansion_used = TRUE  // block the paid expand since LCK already gave a slot
	// Immediate bonus: circuit wired now, mark as used
	else if(bonus_type)
		A.max_circuits = 3
		A.slot_expansion_used = TRUE
	var/datum/behavior_circuit/trigger/TR = new trigger_type()
	var/datum/behavior_circuit/response/RE = new response_type()
	// Multi-response: if extra paths were selected, use responses_list instead of single response
	if(extra_response_paths && extra_response_paths.len)
		TR.responses_list = list(RE)
		for(var/epath in extra_response_paths)
			var/epath_type = text2path(epath)
			if(epath_type && ispath(epath_type, /datum/behavior_circuit/response))
				var/datum/behavior_circuit/response/ER = new epath_type()
				TR.responses_list += ER
				A.circuits += ER
	else
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
			var/existing_t = TR.vars[varname]
			TR.vars[varname] = (isnum(existing_t) && istext(val)) ? (text2num(val) || existing_t) : val
		else if(prefix == "response" && (varname in RE.vars))
			var/existing_r = RE.vars[varname]
			RE.vars[varname] = (isnum(existing_r) && istext(val)) ? (text2num(val) || existing_r) : val
	A.circuits += TR
	A.circuits += RE
	// Wire bonus circuit (only if not deferred - deferred bonuses are wired later at REPROGRAM)
	if(bonus_type && !deferred_bonus_mode)
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
	/// If TRUE the behavior list shows a ★ Starter callout next to this entry.
	var/starter_build = FALSE
	/// Optional one-line "best suited for" hint shown under cert designs.
	/// Empty string = no hint shown.
	var/suited_for = ""

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
	design_desc = "The all-purpose cert. Balanced C.O.R.E. stats (5/5/5/5), 3 upgrade slots. Fits any robot in the workshop. Print this first if you're not sure what you need."
	id = "cert_base_standard"
	output_path = /obj/item/cert_card/base
	cost = list("iron" = 500, "glass" = 200)
	starter_build = TRUE
	suited_for = "Any chassis"

/datum/cpu_fab_design/base/combat
	design_name = "Combat Chassis Cert"
	design_desc = "Military-grade cert. Faster and tougher than Standard (C4/O7/R7/E6), 4 upgrade slots, unlocks combat behaviors. Requires Tier 2. Slot this on a Protectron, Gutsy, Assaultron, or Securitron."
	id = "cert_base_combat"
	required_tier = CERT_TIER_MILITARY
	output_path = /obj/item/cert_card/base/combat
	cost = list("iron" = 1000, "glass" = 200, "gold" = 300)
	suited_for = "Combat / Security / Apex chassis"

/datum/cpu_fab_design/base/medical
	design_name = "Medical Chassis Cert"
	design_desc = "Field medicine cert. Unlocks repair and triage capabilities (C6/O5/R5/E6), 4 upgrade slots. Required to run Medbot or Field Surgeon assemblies. Pairs well with Mr. Handy."
	id = "cert_base_medical"
	output_path = /obj/item/cert_card/base/medical
	cost = list("iron" = 500, "glass" = 400)
	suited_for = "Support chassis (Mr. Handy)"

/datum/cpu_fab_design/base/engineering
	design_name = "Engineering Chassis Cert"
	design_desc = "Infrastructure cert. Unlocks repair and machine interface capabilities (C6/O4/R6/E7), 4 upgrade slots. Higher energy budget means more hardware. Good for a dedicated support robot."
	id = "cert_base_engineering"
	output_path = /obj/item/cert_card/base/engineering
	cost = list("iron" = 700, "glass" = 200)
	suited_for = "Any chassis — high energy for hardware-heavy builds"

/datum/cpu_fab_design/base/hacking_tool
	design_name = "Hacking Tool Certificate"
	design_desc = "Unlocks robot hacking on a hacking device. Print this, use it on your hacking device to slot it in, then click any standard robot to start the wordlist minigame. Basic tier gives 2 compute (4+ attempts). Military-grade is world-found only and masks your identity."
	id = "cert_hacking_tool"
	output_path = /obj/item/cert_card/base/hacking_tool
	cost = list("iron" = 600, "glass" = 300, "gold" = 200)
	suited_for = "Hacking device — slot this card into the device to enable robot hacking"


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
	starter_build = TRUE

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
	starter_build = TRUE

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
	starter_build = TRUE

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
	starter_build = TRUE

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

/datum/cpu_fab_design/behavior/turret_bot
	design_name = "Turret Protocol"
	design_desc = "Fires at enemies on sight. Requires a weapon cert (CERT_CAN_SHOOT). Best on an anchored or slow chassis."
	id = "behavior_turret_bot"
	output_path = /obj/item/behavior_assembly/turret_bot

/datum/cpu_fab_design/behavior/combat_medic_protocol
	design_name = "Combat Medic Protocol"
	design_desc = "Injects nearby injured friendlies in combat. Requires a repair cert (CERT_CAN_REPAIR) and Injector hardware."
	id = "behavior_combat_medic"
	output_path = /obj/item/behavior_assembly/combat_medic
	cost = list("iron" = 300, "glass" = 200, "gold" = 100)

/datum/cpu_fab_design/behavior/scavenger_protocol
	design_name = "Scavenger Protocol"
	design_desc = "Grabs loose items on a timer. Pairs well with Depot Protocol for a full collect-deposit loop. Requires Grabber Arm hardware."
	id = "behavior_scavenger"
	output_path = /obj/item/behavior_assembly/scavenger_bot

/datum/cpu_fab_design/behavior/hunter_protocol
	design_name = "Hunter Protocol"
	design_desc = "Fires on spotted enemies, remembers them after they break line of sight, and pursues. Requires Weapon hardware."
	id = "behavior_hunter"
	required_int = 5
	output_path = /obj/item/behavior_assembly/hunter
	cost = list("iron" = 400, "glass" = 200)

/datum/cpu_fab_design/behavior/clock_patrol_protocol
	design_name = "Clock Patrol Protocol"
	design_desc = "Steps through stored waypoints on each clock tick. Requires Navigation Computer and Interval Clock hardware. INT 5+."
	id = "behavior_clock_patrol"
	required_int = 5
	output_path = /obj/item/behavior_assembly/clock_patrol
	cost = list("iron" = 300, "glass" = 100)

/datum/cpu_fab_design/behavior/farming_bot
	design_name = "Farming Protocol"
	design_desc = "Harvests mature plants, collects the yield, then returns to a linked drop-off target when loaded. Requires Harvester Module and Grabber Arm hardware. Link target with multitool."
	id = "behavior_farming_bot"
	output_path = /obj/item/behavior_assembly/farming_bot
	starter_build = TRUE
	cost = list("iron" = 300, "glass" = 100)

/datum/cpu_fab_design/behavior/greeter
	design_name = "Greeter Protocol"
	design_desc = "Waves and greets any mob that approaches. The friendliest thing you can wire. No hardware required."
	id = "behavior_greeter"
	output_path = /obj/item/behavior_assembly/greeter
	starter_build = TRUE

/datum/cpu_fab_design/behavior/panic
	design_name = "Panic Protocol"
	design_desc = "Flees, calls for reinforcements, and broadcasts distress when critically damaged. Turns any robot into a survivor."
	id = "behavior_panic"
	output_path = /obj/item/behavior_assembly/panic
	cost = list("iron" = 500, "glass" = 200)

/datum/cpu_fab_design/behavior/sentry_hold
	design_name = "Sentry Hold Protocol"
	design_desc = "Locks down and enters combat on enemy contact. Releases after 30 seconds of quiet. A proper guard robot."
	id = "behavior_sentry_hold"
	output_path = /obj/item/behavior_assembly/sentry_hold
	cost = list("iron" = 400, "glass" = 200)

/datum/cpu_fab_design/behavior/fire_watch
	design_name = "Fire Watch Protocol"
	design_desc = "Sounds an alarm and deploys the extinguisher when fire is detected nearby. Requires Extinguisher Module hardware."
	id = "behavior_fire_watch"
	output_path = /obj/item/behavior_assembly/fire_watch
	cost = list("iron" = 300, "glass" = 200)

/datum/cpu_fab_design/behavior/lockdown
	design_name = "Lockdown Protocol"
	design_desc = "On enemy contact: bolts the nearest door, sounds the alarm, and enters combat. The full security response in one assembly."
	id = "behavior_lockdown"
	output_path = /obj/item/behavior_assembly/lockdown
	cost = list("iron" = 500, "glass" = 200)

/datum/cpu_fab_design/behavior/grudge
	design_name = "Grudge Protocol"
	design_desc = "Remembers enemies by name, announces them, chases persistently, and broadcasts distress on death. Requires Memory Core hardware. INT 7+."
	id = "behavior_grudge"
	required_int = 7
	output_path = /obj/item/behavior_assembly/grudge
	cost = list("iron" = 500, "glass" = 300, "gold" = 200)

/datum/cpu_fab_design/behavior/watchful
	design_name = "Watchful Protocol"
	design_desc = "Checks in on radio periodically, then switches cleanly into combat mode on enemy contact. Requires Memory Core hardware. INT 7+."
	id = "behavior_watchful"
	required_int = 7
	output_path = /obj/item/behavior_assembly/watchful
	cost = list("iron" = 400, "glass" = 200, "gold" = 150)

/datum/cpu_fab_design/behavior/vengeance
	design_name = "Vengeance Protocol"
	design_desc = "Goes berserk when an ally dies nearby. Enters combat, charges the enemy, taunts them, and sounds the alarm. No hardware required."
	id = "behavior_vengeance"
	output_path = /obj/item/behavior_assembly/vengeance
	cost = list("iron" = 400, "glass" = 200)

/datum/cpu_fab_design/behavior/courier
	design_name = "Courier Protocol"
	design_desc = "Collects nearby items and brings them to a linked target. Link a delivery target with a multitool. Requires Grabber Arm hardware."
	id = "behavior_courier"
	output_path = /obj/item/behavior_assembly/courier
	cost = list("iron" = 300, "glass" = 100)

/datum/cpu_fab_design/behavior/parrot
	design_name = "Parrot Protocol"
	design_desc = "Repeats everything it hears. Requires Microphone hardware. Simple. Strange. Extremely effective at annoying people."
	id = "behavior_parrot"
	output_path = /obj/item/behavior_assembly/parrot

// -- Layer 6-10 designs --

/datum/cpu_fab_design/behavior/shadow
	design_name = "Shadow Protocol"
	design_desc = "Cuts lights and goes silent on enemy contact. Sounds the alarm on unauthorized access. Requires Light and Memory Core hardware."
	id = "behavior_shadow"
	required_int = 6
	output_path = /obj/item/behavior_assembly/shadow
	cost = list("iron" = 400, "glass" = 200, "gold" = 100)

/datum/cpu_fab_design/behavior/crowd_control
	design_name = "Crowd Control Protocol"
	design_desc = "Area suppression when surrounded by 3+ enemies: air blast, smoke, alarm. Requires Air Cannon hardware."
	id = "behavior_crowd_control"
	output_path = /obj/item/behavior_assembly/crowd_control
	cost = list("iron" = 400, "glass" = 200)

/datum/cpu_fab_design/behavior/depot
	design_name = "Depot Protocol"
	design_desc = "Collect-deposit loop: grabs items until full, deposits into the nearest container, repeats. Requires Grabber Arm hardware."
	id = "behavior_depot"
	output_path = /obj/item/behavior_assembly/depot
	cost = list("iron" = 300, "glass" = 100)

/datum/cpu_fab_design/behavior/bodyguard
	design_name = "Bodyguard Protocol"
	design_desc = "Follows a linked target and interposes itself when they take damage. Link target with multitool + ID card."
	id = "behavior_bodyguard"
	output_path = /obj/item/behavior_assembly/bodyguard
	cost = list("iron" = 400, "glass" = 200)

/datum/cpu_fab_design/behavior/escalation
	design_name = "Escalation Protocol"
	design_desc = "Stays calm under light fire. After absorbing 3 significant hits, escalates to full combat and calls for backup. Requires Memory Core hardware. INT 7+."
	id = "behavior_escalation"
	required_int = 7
	output_path = /obj/item/behavior_assembly/escalation
	cost = list("iron" = 500, "glass" = 300, "gold" = 200)

/datum/cpu_fab_design/behavior/dead_man_timer
	design_name = "Dead Man Timer"
	design_desc = "Arms a countdown on death and detonates after a short delay. Gives enemies a moment to react. Requires Memory Core hardware."
	id = "behavior_dead_man_timer"
	required_int = 6
	output_path = /obj/item/behavior_assembly/dead_man_timer
	cost = list("iron" = 500, "glass" = 200, "gold" = 200)


// ---- Layer A: Utility & Service ----

/datum/cpu_fab_design/behavior/janitor
	design_name = "Janitor Protocol"
	design_desc = "Reacts to nearby mess with an emote and complaint, then idles by cleaning ambient surfaces. No hardware required. Mr. Handy pairing."
	id = "behavior_janitor"
	output_path = /obj/item/behavior_assembly/janitor
	starter_build = TRUE

/datum/cpu_fab_design/behavior/lamp_bot
	design_name = "Lamp Bot Protocol"
	design_desc = "Turns its own light on when dark, off when lit. A robot that is a smart light. Requires Light hardware."
	id = "behavior_lamp_bot"
	output_path = /obj/item/behavior_assembly/lamp_bot

/datum/cpu_fab_design/behavior/battery_steward
	design_name = "Battery Steward Protocol"
	design_desc = "Retreats to its spawn point when low on power and announces when it's back online. No hardware required."
	id = "behavior_battery_steward"
	output_path = /obj/item/behavior_assembly/battery_steward
	starter_build = TRUE

/datum/cpu_fab_design/behavior/chem_runner
	design_name = "Chem Runner Protocol"
	design_desc = "Collects nearby reagent containers and brings them to a linked target. Link with multitool. No hardware required."
	id = "behavior_chem_runner"
	output_path = /obj/item/behavior_assembly/chem_runner
	cost = list("iron" = 200, "glass" = 100)


// ---- Layer B: Combat Depth ----

/datum/cpu_fab_design/behavior/reactive_marksman
	design_name = "Reactive Marksman Protocol"
	design_desc = "Backs off when hit, returns fire, and taunts. A robot that fights dirty when cornered. Requires Weapon hardware."
	id = "behavior_reactive_marksman"
	output_path = /obj/item/behavior_assembly/reactive_marksman
	cost = list("iron" = 400, "glass" = 200)

/datum/cpu_fab_design/behavior/grenadier
	design_name = "Grenadier Protocol"
	design_desc = "Lobs a grenade into crowds of 3+ enemies then retreats. Requires Grenade Launcher hardware."
	id = "behavior_grenadier"
	output_path = /obj/item/behavior_assembly/grenadier
	cost = list("iron" = 400, "glass" = 200)

/datum/cpu_fab_design/behavior/stun_subdue
	design_name = "Stun & Subdue Protocol"
	design_desc = "Stuns enemies on sight and when allies are attacked. Focuses on incapacitation over lethal force. Best on a Protectron."
	id = "behavior_stun_subdue"
	output_path = /obj/item/behavior_assembly/stun_subdue
	cost = list("iron" = 300, "glass" = 200)

/datum/cpu_fab_design/behavior/combat_response
	design_name = "Combat Response Protocol"
	design_desc = "Wakes on gunfire, reports contact, and pursues the source. Requires Microphone hardware. INT 5+."
	id = "behavior_combat_response"
	required_int = 5
	output_path = /obj/item/behavior_assembly/combat_response
	cost = list("iron" = 400, "glass" = 200, "gold" = 100)


// ---- Layer C: Specialist ----

/datum/cpu_fab_design/behavior/bio_scout
	design_name = "Bio Scout Protocol"
	design_desc = "Scans for unusual biology, broadcasts a bio report, and logs the contact. Requires Bio Scanner hardware. INT 7+."
	id = "behavior_bio_scout"
	required_int = 7
	output_path = /obj/item/behavior_assembly/bio_scout
	cost = list("iron" = 300, "glass" = 200, "gold" = 150)

/datum/cpu_fab_design/behavior/hazmat_responder
	design_name = "Hazmat Responder Protocol"
	design_desc = "On radiation detection: broadcasts hazmat warning, sprays RadAway, seals the nearest door. Requires Environment Scanner + Chem Sprayer hardware."
	id = "behavior_hazmat_responder"
	output_path = /obj/item/behavior_assembly/hazmat_responder
	cost = list("iron" = 400, "glass" = 300, "gold" = 100)

/datum/cpu_fab_design/behavior/gps_zone_guard
	design_name = "GPS Zone Guard Protocol"
	design_desc = "Locks down and sounds alarm only when inside a defined coordinate zone. Requires GPS hardware."
	id = "behavior_gps_zone_guard"
	required_int = 5
	output_path = /obj/item/behavior_assembly/gps_zone_guard
	cost = list("iron" = 300, "glass" = 100, "gold" = 100)

/datum/cpu_fab_design/behavior/announce_bot
	design_name = "Announce Bot Protocol"
	design_desc = "Cycles through stored vocabulary phrases and updates its display screen on a slow timer. Requires Vocabulary Module + Display Screen hardware."
	id = "behavior_announce_bot"
	output_path = /obj/item/behavior_assembly/announce_bot

/datum/cpu_fab_design/behavior/relay_station
	design_name = "Relay Station Protocol"
	design_desc = "Receives a radio signal and rebroadcasts on its own channel. Chains robots across distances. Requires Signaler hardware."
	id = "behavior_relay_station"
	output_path = /obj/item/behavior_assembly/relay_station
	cost = list("iron" = 200, "glass" = 100)

/datum/cpu_fab_design/behavior/alchemist
	design_name = "Alchemist Protocol"
	design_desc = "Collects reagent containers, grinds items, and pumps reagents autonomously. Requires Grabber + Reagent Tank + Grinder + Pump hardware. INT 7+."
	id = "behavior_alchemist"
	required_int = 7
	output_path = /obj/item/behavior_assembly/alchemist
	cost = list("iron" = 500, "glass" = 300, "gold" = 200)


// ---- Layer E: Clearing Orphans ----

/datum/cpu_fab_design/behavior/sprint_ambush
	design_name = "Sprint Ambush Protocol"
	design_desc = "Surges into range when an enemy is spotted and taunts on every shot. Requires Weapon + Locomotion (sprint) hardware."
	id = "behavior_sprint_ambush"
	output_path = /obj/item/behavior_assembly/sprint_ambush
	cost = list("iron" = 400, "glass" = 200)

/datum/cpu_fab_design/behavior/medevac
	design_name = "Medevac Protocol"
	design_desc = "Drags critically injured allies to safety. Retreats and calls for help when its own health is critical. Requires Health Scanner hardware."
	id = "behavior_medevac"
	output_path = /obj/item/behavior_assembly/medevac
	cost = list("iron" = 400, "glass" = 200, "gold" = 100)

/datum/cpu_fab_design/behavior/riot_control
	design_name = "Riot Control Protocol"
	design_desc = "Area blast + strobe when surrounded. Steps back and cannon-blasts single targets. Maximum non-lethal suppression. Requires Air Cannon hardware."
	id = "behavior_riot_control"
	output_path = /obj/item/behavior_assembly/riot_control
	cost = list("iron" = 400, "glass" = 200)

/datum/cpu_fab_design/behavior/thrower_bot
	design_name = "Thrower Protocol"
	design_desc = "Picks up loose items and throws them at enemies. Collects more when empty. Requires Grabber Arm + Throwing Arm hardware."
	id = "behavior_thrower_bot"
	output_path = /obj/item/behavior_assembly/thrower_bot
	cost = list("iron" = 300, "glass" = 100)

/datum/cpu_fab_design/behavior/supply_drop
	design_name = "Supply Drop Protocol"
	design_desc = "Offers held items to approaching friendlies and requests resupply when empty. Requires Grabber Arm hardware."
	id = "behavior_supply_drop"
	output_path = /obj/item/behavior_assembly/supply_drop
	cost = list("iron" = 200, "glass" = 100)

/datum/cpu_fab_design/behavior/power_relay_bot
	design_name = "Power Relay Protocol"
	design_desc = "Periodically relays charge to nearby robots and reports its own battery. Calls for help when critically low. Requires Power Relay hardware."
	id = "behavior_power_relay_bot"
	output_path = /obj/item/behavior_assembly/power_relay_bot
	cost = list("iron" = 300, "glass" = 100, "gold" = 150)

/datum/cpu_fab_design/behavior/collection_sweep
	design_name = "Collection Sweep Protocol"
	design_desc = "Collects spotted items with an audio ping, drops payload and reports when full. Requires Material Collector + Grabber hardware."
	id = "behavior_collection_sweep"
	output_path = /obj/item/behavior_assembly/collection_sweep
	cost = list("iron" = 300, "glass" = 100)

/datum/cpu_fab_design/behavior/watchpost
	design_name = "Watchpost Protocol"
	design_desc = "Responds when addressed, alarms on casualties, and stands down when the alert clears. Requires Microphone + Environment Scanner hardware."
	id = "behavior_watchpost"
	required_int = 5
	output_path = /obj/item/behavior_assembly/watchpost
	cost = list("iron" = 400, "glass" = 200, "gold" = 100)

/datum/cpu_fab_design/behavior/one_shot_announcement
	design_name = "One-Shot Announcement"
	design_desc = "Fires once when anyone approaches — says a message, plays a chime, then locks itself out forever. No hardware required."
	id = "behavior_one_shot_announcement"
	output_path = /obj/item/behavior_assembly/one_shot_announcement

/datum/cpu_fab_design/behavior/pump_station
	design_name = "Pump Station Protocol"
	design_desc = "Pumps reagents on a timer, counts cycles, and broadcasts the running total. Requires Reagent Pump + Memory Core hardware."
	id = "behavior_pump_station"
	output_path = /obj/item/behavior_assembly/pump_station
	cost = list("iron" = 200, "glass" = 100)

/datum/cpu_fab_design/behavior/door_patrol
	design_name = "Door Patrol Protocol"
	design_desc = "Opens doors, steps through, and seals them behind itself on a timer. No hardware required."
	id = "behavior_door_patrol"
	output_path = /obj/item/behavior_assembly/door_patrol


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
