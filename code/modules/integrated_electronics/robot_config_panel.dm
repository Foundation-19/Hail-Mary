// ====================================================
// ROBOT CONFIGURATION PANEL
// Service interface: a technician opens the robot's
// maintenance panel with a multitool and tunes its
// software -- adjusting hardware settings, faction
// alignment, and operator access.
//
// This panel does NOT add or remove physical hardware.
// That is the robot workshop's job.
//
// Three tabs:
//   DIAGNOSTICS -- unit status at a glance; name; control mode
//   SOFTWARE    -- edit config vars on each installed module
//   ALIGNMENT   -- faction tags (who this unit recognizes as allied)
// ====================================================

#define RCP_DIAG      1
#define RCP_SOFTWARE  2
#define RCP_ALIGNMENT 3

// Common faction tag shortcuts in the Alignment tab


// ?? State vars on the robot mob ??????????????????????????????????????????????

/mob/living/silicon/robot
	var/rcp_mode       = RCP_DIAG
	var/rcp_sw_ref     = null    // REF of the hardware datum currently expanded for editing
	var/control_mode   = null    // null/"npc" = behavior circuits; "open" = any player; "locked" = one ckey
	var/locked_ckey    = null
	/// Set when the config panel is waiting for a faction-auth ID card swipe.
	/// Stores the action to perform: "faction", "lock", or "follow"
	var/rcp_pending_action = null
	/// The user whose panel is open and waiting for the swipe.
	var/datum/weakref/rcp_pending_user = null


// ====================================================
// ENTRY POINT
// ====================================================

/mob/living/silicon/robot/proc/open_config_panel(mob/user)
	if(!check_rights_for(user.client, R_ADMIN) && !allowed(user) && !HAS_TRAIT(user, TRAIT_ROBOT_WHISPERER))
		to_chat(user, span_warning("Access denied. Robotics clearance or Robot Whisperer skill required."))
		return
	rcp_mode   = RCP_DIAG
	rcp_sw_ref = null
	_rcp_push(user)


/mob/living/silicon/robot/proc/_rcp_push(mob/user)
	if(QDELETED(src) || QDELETED(user))
		return
	var/dat = _rcp_css()
	dat += _rcp_header()
	dat += _rcp_nav()

	switch(rcp_mode)
		if(RCP_DIAG)      dat += _rcp_diag()
		if(RCP_SOFTWARE)  dat += _rcp_software()
		if(RCP_ALIGNMENT) dat += _rcp_alignment()

	dat += _rcp_footer()
	dat += "</body></html>"

	var/datum/browser/popup = new(user, "rcp_[REF(src)]", "RobCo Config - [real_name]", 680, 560)
	popup.set_content(dat)
	popup.open()


// ====================================================
// TOPIC
// ====================================================

/mob/living/silicon/robot/Topic(href, list/href_list)
	var/mob/U = usr
	if(!U?.client)
		return

	// Module picker self-selection — only the inhabited robot may confirm this.
	// Fires from the pick_module() HTML popup; no external panel access needed.
	if(href_list["pick_module_sel"])
		if(U != src || !module || module.type != /obj/item/robot_module)
			return
		var/T = text2path(href_list["pick_module_sel"])
		if(!T || !ispath(T, /obj/item/robot_module))
			return
		module.transform_to(T)
		if(cpu_cert && module)
			var/compute    = cpu_cert.get_core_stat(CORE_COMPUTE)
			var/slots_used = cpu_cert.upgrade_slots.len
			var/slots_max  = cpu_cert.max_upgrade_slots
			to_chat(src, span_good("> BOOT SEQUENCE COMPLETE."))
			to_chat(src, span_notice("MODULE: [module.name] | COMPUTE: [compute] | UPGRADE SLOTS: [slots_used]/[slots_max] free"))
			to_chat(src, span_notice("Find a CPU Certification Fabricator (green terminal) to print upgrade cards and expand your capabilities."))
		return

	// Full panel access: admin, robotics-access ID card, or Robot Whisperer trait
	if(!check_rights_for(U.client, R_ADMIN) && !allowed(U) && !HAS_TRAIT(U, TRAIT_ROBOT_WHISPERER))
		return

	// Tab navigation
	if(href_list["rcp_nav"])
		rcp_mode   = text2num(href_list["rcp_nav"])
		rcp_sw_ref = null
		_rcp_push(U)
		return

	// Expand/collapse a module in the Software tab
	if("rcp_sw_ref" in href_list)
		var/incoming = href_list["rcp_sw_ref"]
		// Clicking the same module again collapses it
		rcp_sw_ref = (incoming == rcp_sw_ref) ? null : incoming
		_rcp_push(U)
		return

	var/a = href_list["a"]
	if(!a)
		_rcp_push(U)
		return

	switch(a)

		// ?? DIAGNOSTICS ?????????????????????????????????????????????

		if("set_name")
			var/n = stripped_input(U, "Enter display name:", "Unit Name", real_name, max_length=64)
			if(!QDELETED(src) && n)
				log_service("RENAME -- [real_name] ? [n]")
				real_name = n
				name      = n
				if(builtInCamera) builtInCamera.c_tag = n

		if("set_ctrl")
			var/val = href_list["val"]
			if(val == "locked")
				var/ck = stripped_input(U, "Lock to ckey:", "Lock to Operator", "")
				if(length(ck))
					log_service("CONTROL MODE -- LOCKED ([ck])")
					control_mode         = "locked"
					player_robot_control = "locked"
					locked_ckey          = ck
					player_robot_ckey    = ck
					if(!mmi)
						mmi = new(src)

			else if(val in list("npc", "open"))
				log_service("CONTROL MODE -- [uppertext(val)]")
				control_mode         = val
				player_robot_control = val
				locked_ckey          = null
				player_robot_ckey    = null
				if(val == "open" && !mmi)
					mmi = new(src)

		// ?? SOFTWARE ????????????????????????????????????????????????

		if("cfg_set")
			// Edit a single config var on an installed hardware module.
			var/datum/robot_hardware/HW = locate(href_list["ref"])
			var/key = href_list["key"]
			if(istype(HW) && (HW in installed_hardware) && key && (key in HW.config_defs))
				var/list/def  = HW.config_defs[key]
				var/label     = def[1]
				var/dtype     = def[2]
				var/cur_val   = HW.vars[key]
				// def[4]/def[5] are optional min/max for "number" type. null = unclamped.
				var/cfg_min   = def.len >= 4 ? def[4] : null
				var/cfg_max   = def.len >= 5 ? def[5] : null
				var/new_val   = null
				if(dtype == "number")
					var/prompt = "[label]"
					if(!isnull(cfg_min) && !isnull(cfg_max))
						prompt += " ([cfg_min]-[cfg_max])"
					new_val = input(U, "Set [prompt]:", label, cur_val) as null|num
					if(!isnull(new_val))
						// Clamp to configured range if both bounds are set
						if(!isnull(cfg_min) && !isnull(cfg_max))
							new_val = clamp(new_val, cfg_min, cfg_max)
						else if(!isnull(cfg_min))
							new_val = max(new_val, cfg_min)
						else if(!isnull(cfg_max))
							new_val = min(new_val, cfg_max)
						HW.vars[key] = new_val

				else if(dtype == "bool")
					// Bool: toggle without a dialog
					HW.vars[key] = !cur_val
				else
					// "text" and "list" (type path / string): free text input
					new_val = stripped_input(U, "Set [label]:", label, "[cur_val]", max_length=128)
					if(!QDELETED(src) && !isnull(new_val) && length(new_val))
						if(ispath(cur_val))
							var/tp = text2path(new_val)
							if(tp) HW.vars[key] = tp
							else to_chat(U, span_warning("Invalid type path: [new_val]"))
						else
							HW.vars[key] = new_val

		// ?? ALIGNMENT ???????????????????????????????????????????????

		if("add_fac")
			var/tag = href_list["val"]
			if(tag && length(tag))
				if(!faction) faction = list()
				faction |= tag
				log_service("FACTION ADDED -- [tag]")

		if("del_fac")
			var/tag = href_list["val"]
			if(tag && faction && (tag in faction))
				faction -= tag
				log_service("FACTION REMOVED -- [tag]")

		if("clear_fac")
			log_service("FACTIONS CLEARED")
			faction = list()

		if("set_ctrl_card")
			// Close the cover and enter pending state.
			// The technician swipes their ID to authorize — faction is checked against their card.
			rcp_pending_action = "lock"
			rcp_pending_user   = WEAKREF(U)
			opened = FALSE
			update_icons()
			to_chat(U, span_notice("Cover closed. Swipe your ID card on [real_name] to authorize operator lock."))

		if("set_follow_card")
			// Close the cover and enter pending state.
			// The technician swipes an ID card to link that person as follow target.
			rcp_pending_action = "follow"
			rcp_pending_user   = WEAKREF(U)
			opened = FALSE
			update_icons()
			to_chat(U, span_notice("Cover closed. Swipe the target's ID card on [real_name] to link them as follow target."))

		if("set_security")
			var/new_diff = text2num(href_list["diff"])
			var/list/sec_min_int = list(1, 3, 5, 7, 9)
			var/list/sec_labels  = list("VERY EASY","EASY","AVERAGE","HARD","VERY HARD")
			if(isnull(new_diff) || new_diff < 0 || new_diff > 4)
				to_chat(U, span_warning("Invalid difficulty."))
			else if(istype(U, /mob/living) && U.special_i < sec_min_int[new_diff + 1])
				to_chat(U, span_warning("INT [sec_min_int[new_diff + 1]]+ required for [sec_labels[new_diff + 1]] security."))
			else
				security_difficulty = new_diff
				log_service("SECURITY DIFFICULTY -- set to [sec_labels[new_diff + 1]] by [U.name]")
				to_chat(U, span_nicegreen("Security software updated: [sec_labels[new_diff + 1]]."))

		if("add_fac_card")
			// Close the cover and enter pending state.
			// The technician swipes their ID ? faction is read from their card's assignment.
			rcp_pending_action = "faction"
			rcp_pending_user   = WEAKREF(U)
			opened = FALSE
			update_icons()
			to_chat(U, span_notice("Cover closed. Swipe your ID card on [real_name] to register your faction."))

		if("rcp_cancel_pending")
			rcp_pending_action = null
			rcp_pending_user   = null

		if("ctrl_clear")
			log_service("CONTROL MODE -- AUTONOMOUS (lock cleared)")
			control_mode         = null
			player_robot_control = "npc"
			locked_ckey          = null
			player_robot_ckey    = null

		if("reboot")
			if(!check_rights_for(U.client, R_ADMIN) && !allowed(U) && !HAS_TRAIT(U, TRAIT_ROBOT_WHISPERER))
				to_chat(U, span_warning("Access denied."))
			else
				log_service("REBOOT -- initiated by [U.name]")
				ResetModule()
				log_reboot()
				visible_message(span_warning("[src] reboots."))
				to_chat(U, span_nicegreen("[real_name] module reset."))

	if(!QDELETED(src))
		_rcp_push(U)


// ====================================================
// ID CARD SWIPE AUTH
// Intercepts the vanilla allowed() call made when an
// ID card is swiped on the robot while the cover is
// closed. Handles pending faction/lock actions and
// returns FALSE to suppress the cover-lock toggle.
// ====================================================

/// Called from the top of attackby in robot.dm when rcp_pending_action is set
/// and an ID card is swiped. Handles faction registration and operator lock auth.
/mob/living/silicon/robot/proc/rcp_handle_id_card_auth(obj/item/card/id/card, mob/user)
	var/mob/panel_user = rcp_pending_user ? rcp_pending_user.resolve() : null
	var/action = rcp_pending_action
	rcp_pending_action = null
	rcp_pending_user   = null
	if(action == "faction")
		var/faction_tag = _rcp_faction_from_card(card)
		if(!faction_tag)
			to_chat(user, span_warning("Could not determine faction from '[card.assignment ? card.assignment : "(no assignment)"]'. Faction could not be resolved -- check the card assignment."))
		else if(faction && (faction_tag in faction))
			to_chat(user, span_warning("[faction_tag] is already registered."))
		else
			if(!faction) faction = list()
			faction += faction_tag
			log_service("FACTION ADDED -- [faction_tag] (authorized by [card.registered_name ? card.registered_name : user.name])")
			to_chat(user, span_nicegreen("Faction '[faction_tag]' registered to [real_name]."))
	else if(action == "lock")
		var/op_name = card.registered_name
		if(!op_name || !length(op_name))
			to_chat(user, span_warning("This ID card has no registered name."))
		else
			control_mode         = "locked"
			player_robot_control = "locked"
			locked_ckey          = op_name
			player_robot_ckey    = op_name   // name-based; attack_ghost also checks real_name
			if(!mmi)
				mmi = new(src)
			log_service("CONTROL MODE -- LOCKED ([op_name]) authorized by [user.name]")
			to_chat(user, span_nicegreen("[real_name] locked to operator: [op_name]."))
	else if(action == "follow")
		var/person_name = card.registered_name
		if(!person_name || !length(person_name))
			to_chat(user, span_warning("This ID card has no registered name."))
		else
			// Find the mob in the world by name
			var/mob/living/target = null
			for(var/mob/living/M in GLOB.alive_mob_list)
				if(M.name == person_name || (istype(M, /mob/living/carbon/human) && M.real_name == person_name))
					target = M
					break
			if(!target)
				to_chat(user, span_warning("Could not locate '[person_name]' in the world. Are they alive and present?"))
			else
				// Find the installed assembly and link all follow_target circuits
				var/datum/cert_upgrade/robot/behavior_assembly/BA = null
				if(cpu_cert)
					for(var/datum/cert_upgrade/robot/behavior_assembly/U2 in cpu_cert.upgrade_slots)
						BA = U2
						break
				if(!BA?.assembly || !BA.assembly.circuits.len)
					to_chat(user, span_warning("[real_name] has no behavior assembly installed."))
				else
					var/linked = 0
					for(var/datum/behavior_circuit/response/follow_target/FT in BA.assembly.circuits)
						FT.set_linked_target(target, user)
						linked++
					if(!linked)
						to_chat(user, span_warning("[real_name]'s assembly has no Follow Linked Target circuit to configure."))
					else
						log_service("FOLLOW TARGET -- [person_name] linked via ID card by [user.name]")
						to_chat(user, span_nicegreen("Follow target set: [real_name] will follow [person_name]."))
	if(panel_user) _rcp_push(panel_user)



// ====================================================
// FACTION FROM CARD
// ====================================================

/// Resolves an ID card's assignment to a canonical faction tag.
/// Delegates to the global resolve_faction_from_card() proc defined
/// in terminal.dm, which is the single authoritative implementation.
/mob/living/silicon/robot/proc/_rcp_faction_from_card(obj/item/card/id/card)
	return resolve_faction_from_card(card)


// ====================================================
// HTML HELPERS
// ====================================================

/mob/living/silicon/robot/proc/_rcp_css()
	var/css = "<html><head><style>"
	css += "body{padding:0;margin:15px;background-color:#062113;color:#4aed92;line-height:170%;font-family:'Courier New',Courier,monospace;}"
	css += "a,a:link,a:visited,a:active{color:#4aed92;text-decoration:none;background:#062113;border:none;padding:1px 4px;margin:0 2px;}"
	css += "a:hover{color:#062113;background:#4aed92;cursor:pointer;}"
	css += ".dim{color:#2a7a52;}"
	css += ".good{color:#4aed92;font-weight:bold;}"
	css += ".bad{color:#c0392b;font-weight:bold;}"
	css += ".warn{color:#e8a020;}"
	css += "hr{border:none;border-top:1px solid #2a7a52;margin:4px 0;}"
	css += "table{width:100%;border-spacing:0 2px;}"
	css += "td{padding:2px 6px;border-bottom:1px solid #0d3322;vertical-align:top;}"
	css += "th{color:#2a7a52;text-align:left;padding:2px 6px;font-weight:normal;border-bottom:1px solid #2a7a52;}"
	css += "</style></head><body>"
	return css

/mob/living/silicon/robot/proc/_rcp_header()
	var/h = "<center>"
	h += "<b>ROBCO INDUSTRIES UNIFIED OPERATING SYSTEM</b><br>"
	h += "<b>ROBOT CONFIGURATION INTERFACE v2.3</b><br>"
	h += "<span class='dim'>= [real_name] ([type]) =</span>"
	h += "</center><br>"
	return h

/mob/living/silicon/robot/proc/_rcp_nav()
	var/tabs = list(
		list("Diagnostics", RCP_DIAG),
		list("Software",    RCP_SOFTWARE),
		list("Alignment",   RCP_ALIGNMENT)
	)
	var/n = ""
	for(var/t in tabs)
		var/label = t[1]
		var/mode  = t[2]
		if(rcp_mode == mode)
			n += "<b>&gt; [label]</b> | "
		else
			n += "<a href='byond://?src=[REF(src)];rcp_nav=[mode]'>&gt; [label]</a> | "
	n += "<br><hr><br>"
	return n

/mob/living/silicon/robot/proc/_rcp_footer()
	var/cell_str = cell ? "[round(cell.charge/cell.maxcharge*100)]%" : "<span class='bad'>NO CELL</span>"
	var/stat_str = stat == DEAD ? "<span class='bad'>OFFLINE</span>" : "<span class='good'>ONLINE</span>"
	var/f = "<br><hr>"
	f += "<span class='dim'>HEALTH: [health]/[maxHealth]  |  CELL: [cell_str]  |  STATUS: [stat_str]</span>"
	return f


// ====================================================
// DIAGNOSTICS TAB
// Unit status at a glance. Name and control mode are
// the only things a technician would edit here.
// ====================================================

/mob/living/silicon/robot/proc/_rcp_diag()
	var/d = ""

	// ?? Unit identity ?????????????????????????????????????????????
	d += "<b>UNIT IDENTITY</b><br>"
	d += "Name: <b>[html_encode(name)]</b>  <a href='byond://?src=[REF(src)];a=set_name'>\[rename\]</a><br>"
	d += "Type: <span class='dim'>[type]</span><br>"
	d += "CPU cert: <span class='dim'>[cpu_cert ? "[cpu_cert.type]" : "none"]</span><br>"
	d += "<br>"

	// ?? Cert and installed upgrades ?????????????????????????????????????????????
	d += "<b>CERTIFICATION</b><br>"
	if(cpu_cert)
		d += "Cert: <span class='good'>[html_encode(cpu_cert.cert_name)]</span>"
		d += "  <span class='dim'>Tier [cpu_cert.cert_tier]  Slots: [cpu_cert.upgrade_slots.len]/[cpu_cert.max_upgrade_slots]</span><br>"
		d += "<span class='dim'>C.O.R.E. base: C[cpu_cert.base_compute] O[cpu_cert.base_operations] R[cpu_cert.base_resilience] E[cpu_cert.base_energy]</span><br>"
		// Show effective after upgrades
		d += "<span class='dim'>C.O.R.E. effective: C[cpu_cert.get_compute()] O[cpu_cert.get_operations()] R[cpu_cert.get_resilience()] E[cpu_cert.get_energy()]</span><br>"
		if(cpu_cert.upgrade_slots.len)
			d += "<br><span class='dim'>INSTALLED UPGRADES:</span><br>"
			for(var/datum/cert_upgrade/U in cpu_cert.upgrade_slots)
				// Skip behavior_assembly -- it's shown in Programs tab
				if(istype(U, /datum/cert_upgrade/robot/behavior_assembly))
					continue
				var/list/delta_parts = list()
				if(U.compute_mod)
					var/s = U.compute_mod > 0 ? "+" : ""
					delta_parts += "C[s][U.compute_mod]"
				if(U.operations_mod)
					var/s = U.operations_mod > 0 ? "+" : ""
					delta_parts += "O[s][U.operations_mod]"
				if(U.resilience_mod)
					var/s = U.resilience_mod > 0 ? "+" : ""
					delta_parts += "R[s][U.resilience_mod]"
				if(U.energy_mod)
					var/s = U.energy_mod > 0 ? "+" : ""
					delta_parts += "E[s][U.energy_mod]"
				var/delta_txt = delta_parts.len ? "  <span class='dim'>([delta_parts.Join(" ")])</span>" : ""
				d += "&gt; <b>[html_encode(U.upgrade_name)]</b>[delta_txt]<br>"
		else
			d += "<span class='dim'>No upgrades installed.</span><br>"
	else
		d += "<span class='warn'>No certification installed. Robot may behave unexpectedly.</span><br>"
	d += "<br>"
	// Plain-language description of each mode so it reads like a service menu,
	// not a codebase variable.
	d += "<b>CONTROL MODE</b><br>"
	var/cmode = player_robot_control ? player_robot_control : "npc"
	switch(cmode)
		if("npc")
			d += "&gt; <b>AUTONOMOUS</b>  <span class='dim'>-- unit operates under installed behavior circuits</span><br>"
		if("open")
			d += "&gt; <b>OPEN OPERATOR</b>  <span class='warn'>-- any player may log in and take direct control</span><br>"
		if("locked")
			var/op = locked_ckey ? html_encode(locked_ckey) : "???"
			d += "&gt; <b>RESERVED</b>  <span class='dim'>-- operator slot reserved for <b>[op]</b></span><br>"
	d += "<br>"
	d += "<span class='dim'>Change:</span>  "
	if(cmode != "npc")
		d += "<a href='byond://?src=[REF(src)];a=set_ctrl;val=npc'>\[Autonomous\]</a>  "
	else
		d += "<span class='dim'>\[Autonomous\]</span>  "
	if(cmode != "open")
		d += "<a href='byond://?src=[REF(src)];a=set_ctrl;val=open'>\[Open\]</a>  "
	else
		d += "<span class='dim'>\[Open\]</span>  "
	// Lock options
	if(cmode == "locked")
		d += "<a href='byond://?src=[REF(src)];a=ctrl_clear'>\[Clear lock\]</a>"
	else if(rcp_pending_action == "lock")
		d += "<span class='warn'>Swipe your ID card on the robot...</span>  <a href='byond://?src=[REF(src)];a=rcp_cancel_pending'>\[cancel\]</a>"
	else
		d += "<a href='byond://?src=[REF(src)];a=set_ctrl;val=locked'>\[Reserve -- enter ckey\]</a>  "
		d += "<a href='byond://?src=[REF(src)];a=set_ctrl_card'>\[Reserve -- swipe ID card\]</a>"
	d += "<br>"
	// Follow target link
	if(rcp_pending_action == "follow")
		d += "<span class='warn'>Swipe the target's ID card on the robot...</span>  <a href='byond://?src=[REF(src)];a=rcp_cancel_pending'>\[cancel\]</a><br>"
	else
		d += "<a href='byond://?src=[REF(src)];a=set_follow_card'>\[Set follow target -- swipe ID card\]</a>  <span class='dim'>// links Follow Linked Target circuits</span><br>"
	d += "<br>"

	// ?? Security software difficulty
	d += "<b>SECURITY SOFTWARE</b><br>"
	d += "<span class='dim'>Raise this to make hacking harder. Requires Intelligence to configure.</span><br>"
	var/list/sec_labels = list("VERY EASY","EASY","AVERAGE","HARD","VERY HARD")
	var/list/sec_min_int = list(1, 3, 5, 7, 9)
	d += "<span class='dim'>Current: </span><b>[sec_labels[security_difficulty + 1]]</b><br>"
	for(var/i = 0 to 4)
		var/can_set = TRUE
		var/locked_txt = ""
		if(istype(usr, /mob/living))
			var/mob/living/L = usr
			if(L.special_i < sec_min_int[i+1])
				can_set = FALSE
				locked_txt = " <span class='dim'>(INT [sec_min_int[i+1]]+)</span>"
		var/selected_txt = (security_difficulty == i) ? " <span class='good'>\[active\]</span>" : ""
		if(can_set)
			d += "&gt; <a href='byond://?src=[REF(src)];a=set_security;diff=[i]'>[sec_labels[i+1]]</a>[selected_txt]<br>"
		else
			d += "&gt; <span class='dim'>[sec_labels[i+1]]</span>[locked_txt][selected_txt]<br>"
	d += "<br>"

	// ?? Installed modules -- summary only ??????????????????????????
	// Full config is in the Software tab; this is just a quick read.
	d += "<b>INSTALLED MODULES</b>  <span class='dim'>([installed_hardware ? installed_hardware.len : 0])</span><br>"
	if(!installed_hardware || !installed_hardware.len)
		d += "<span class='dim'>(none)</span><br>"
	else
		var/list/by_cat = list()
		for(var/datum/robot_hardware/HW in installed_hardware)
			var/cat = HW.category ? HW.category : "Other"
			if(!(cat in by_cat)) by_cat[cat] = list()
			by_cat[cat] += HW.hardware_name
		for(var/cat in by_cat)
			var/list/cat_items = by_cat[cat]
			d += "<span class='dim'>[cat]:</span>  [cat_items.Join(", ")]<br>"

	// ?? Circuit/hardware compatibility check ???????????????????????????
	// Walk installed behavior assembly circuits; warn on any that declare
	// required_hardware_type but whose hardware is not installed.
	if(cpu_cert)
		var/datum/cert_upgrade/robot/behavior_assembly/BA = null
		for(var/datum/cert_upgrade/robot/behavior_assembly/U2 in cpu_cert.upgrade_slots)
			BA = U2
			break
		if(BA?.assembly && BA.assembly.circuits.len)
			var/list/hw_types = list()
			for(var/datum/robot_hardware/HW in installed_hardware)
				hw_types += HW.type
			var/list/missing_hw = list()
			for(var/datum/behavior_circuit/C in BA.assembly.circuits)
				if(!C.needs_hardware || !C.required_hardware_type) continue
				var/found = FALSE
				for(var/ht in hw_types)
					if(ht == C.required_hardware_type || ispath(ht, C.required_hardware_type))
						found = TRUE
						break
				if(!found)
					missing_hw += "[C.circuit_name] needs [C.hardware_slot_name]"
			if(missing_hw.len)
				d += "<br><span class='warn'>CIRCUIT HARDWARE MISSING:</span><br>"
				for(var/warn in missing_hw)
					d += "<span class='warn'>&gt; [warn]</span><br>"

	// Service actions
	d += "<br><b>SERVICE</b><br>"
	if(stat != DEAD)
		d += "<a href='byond://?src=[REF(src)];a=reboot'>\[Reboot Unit\]</a>  <span class='dim'>// resets module state; drops non-locked cert upgrades</span><br>"
	else
		d += "<span class='dim'>\[Reboot Unit\]</span>  <span class='dim'>// unit is offline</span><br>"

	return d


// ====================================================
// SOFTWARE TAB
// The core of the panel. Shows every installed hardware
// module; clicking one expands its configurable settings
// so the technician can read and edit each value.
// ====================================================

/mob/living/silicon/robot/proc/_rcp_software()
	var/d = ""

	if(!installed_hardware || !installed_hardware.len)
		d += "<span class='dim'>No hardware installed. Install modules at the robot workshop.</span><br>"
		return d

	d += "<span class='dim'>Select a module to view and edit its configuration.</span><br><br>"

	for(var/datum/robot_hardware/HW in installed_hardware)
		var/hw_ref    = REF(HW)
		var/expanded  = (rcp_sw_ref == hw_ref)
		var/has_cfg   = HW.config_defs && HW.config_defs.len

		// Module header row -- always visible
		if(expanded)
			d += "<b>&gt; [html_encode(HW.hardware_name)]</b>"
			d += "  <span class='dim'>[html_encode(HW.category ? HW.category : "")]</span>"
			d += "  <a href='byond://?src=[REF(src)];rcp_sw_ref=[hw_ref]'>\[close\]</a><br>"
		else
			d += "<a href='byond://?src=[REF(src)];rcp_sw_ref=[hw_ref]'>&gt; [html_encode(HW.hardware_name)]</a>"
			d += "  <span class='dim'>[html_encode(HW.category ? HW.category : "")]</span>"
			if(has_cfg)
				d += "  <span class='dim'>// [HW.config_defs.len] setting[HW.config_defs.len != 1 ? "s" : ""]</span>"
			else
				d += "  <span class='dim'>// no configurable settings</span>"
			d += "<br>"

		// Expanded config -- shown only for the selected module
		if(expanded)
			// Show tutorial text so the technician knows what this hardware enables
			if(HW.tutorial_text && HW.tutorial_text != "No documentation available.")
				d += "  <span class='dim'>[html_encode(HW.tutorial_text)]</span><br>"
			if(!has_cfg)
				d += "  <span class='dim'>This module has no configurable settings.</span><br>"
			else
				d += "<table>"
				for(var/key in HW.config_defs)
					var/list/def  = HW.config_defs[key]
					var/label     = def[1]
					var/dtype     = def[2]
					var/cur_val   = HW.vars[key]
					var/cfg_min   = def.len >= 4 ? def[4] : null
					var/cfg_max   = def.len >= 5 ? def[5] : null

					d += "<tr>"
					d += "<td class='dim'>[html_encode(label)]</td>"

					// Value cell -- display differs by type
					if(dtype == "bool")
						var/bval = cur_val ? "YES" : "NO"
						var/bcls = cur_val ? "good" : "bad"
						d += "<td><span class='[bcls]'>[bval]</span></td>"
						d += "<td><a href='byond://?src=[REF(src)];a=cfg_set;ref=[hw_ref];key=[url_encode(key)]'>\[toggle\]</a></td>"
					else if(dtype == "number")
						var/range_hint = (!isnull(cfg_min) && !isnull(cfg_max)) ? " <span class='dim'>([cfg_min]-[cfg_max])</span>" : ""
						d += "<td><b>[cur_val]</b>[range_hint]</td>"
						d += "<td><a href='byond://?src=[REF(src)];a=cfg_set;ref=[hw_ref];key=[url_encode(key)]'>\[edit\]</a></td>"
					else
						// text / list (type path or string) -- show shortened if long
						var/display = html_encode("[cur_val]")
						if(length(display) > 40)
							display = copytext(display, 1, 38) + "..."
						d += "<td class='dim'>[display]</td>"
						d += "<td><a href='byond://?src=[REF(src)];a=cfg_set;ref=[hw_ref];key=[url_encode(key)]'>\[edit\]</a></td>"

					d += "</tr>"
				d += "</table>"
			d += "<br>"

	return d


// ====================================================
// ALIGNMENT TAB
// Faction tags -- who this unit treats as allied.
// A technician adjusts these when reassigning a robot
// to a new operator faction.
// ====================================================

/mob/living/silicon/robot/proc/_rcp_alignment()
	var/d = ""

	d += "<b>ALLIED FACTIONS</b><br>"
	d += "<span class='dim'>The unit will not engage targets that share any of these tags.</span><br><br>"

	if(!faction || !faction.len)
		d += "<span class='warn'>&gt; None -- unit will engage all targets.</span><br>"
	else
		d += "<table>"
		for(var/f in faction)
			// Skip malformed tags (raw refs stored accidentally)
			if(findtext(f, "\[") || !length(f)) continue
			d += "<tr>"
			d += "<td>&gt; <b>[html_encode(f)]</b></td>"
			d += "<td>&nbsp;&nbsp;<a href='byond://?src=[REF(src)];a=del_fac;val=[url_encode(f)]'>\[remove\]</a></td>"
			d += "</tr>"
		d += "</table>"
		d += "<br><a href='byond://?src=[REF(src)];a=clear_fac'>\[clear all\]</a>"
	d += "<br><br>"

	d += "<b>ADD TAG</b><br>"
	if(rcp_pending_action == "faction")
		d += "<span class='warn'>&gt; Swipe your ID card on the robot...</span>  <a href='byond://?src=[REF(src)];a=rcp_cancel_pending'>\[cancel\]</a><br>"
	else
		d += "<a href='byond://?src=[REF(src)];a=add_fac_card'>&gt; Swipe ID card to register faction</a><br>"

	return d


// ====================================================
// CLEANUP
// ====================================================

#undef RCP_DIAG
#undef RCP_SOFTWARE
#undef RCP_ALIGNMENT
