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
	/// Stores the action to perform: "faction" or "lock"
	var/rcp_pending_action = null
	/// The user whose panel is open and waiting for the swipe.
	var/datum/weakref/rcp_pending_user = null


// ====================================================
// ENTRY POINT
// ====================================================

/mob/living/silicon/robot/proc/open_config_panel(mob/user)
	if(!check_rights_for(user.client, R_ADMIN))
		to_chat(user, span_warning("Access denied."))
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
	if(!U?.client || !check_rights_for(U.client, R_ADMIN))
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
				log_game("[key_name(U)] renamed robot [real_name] -> [n]")
				real_name = n
				name      = n
				if(builtInCamera) builtInCamera.c_tag = n

		if("set_ctrl")
			var/val = href_list["val"]
			if(val == "locked")
				var/ck = stripped_input(U, "Lock to ckey:", "Lock to Operator", "")
				if(length(ck))
					log_service("CONTROL MODE -- LOCKED ([ck])")
					control_mode = "locked"
					locked_ckey  = ck
					log_game("[key_name(U)] locked [real_name] to [ck]")
			else if(val in list("npc", "open"))
				log_service("CONTROL MODE -- [uppertext(val)]")
				control_mode = val
				locked_ckey  = null
				log_game("[key_name(U)] set [real_name] control mode = [val]")

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
						log_game("[key_name(U)] set [HW.hardware_name].[key] = [new_val] on [real_name]")
				else if(dtype == "bool")
					// Bool: toggle without a dialog
					HW.vars[key] = !cur_val
					log_game("[key_name(U)] toggled [HW.hardware_name].[key] = [!cur_val] on [real_name]")
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
						log_game("[key_name(U)] set [HW.hardware_name].[key] = [new_val] on [real_name]")

		// ?? ALIGNMENT ???????????????????????????????????????????????

		if("add_fac")
			var/tag = href_list["val"]
			if(tag && length(tag))
				if(!faction) faction = list()
				faction |= tag
				log_service("FACTION ADDED -- [tag]")
				log_game("[key_name(U)] added faction [tag] to [real_name]")

		if("del_fac")
			var/tag = href_list["val"]
			if(tag && faction && (tag in faction))
				faction -= tag
				log_service("FACTION REMOVED -- [tag]")
				log_game("[key_name(U)] removed faction [tag] from [real_name]")

		if("clear_fac")
			log_service("FACTIONS CLEARED")
			log_game("[key_name(U)] cleared all factions from [real_name]")
			faction = list()

		if("set_ctrl_card")
			// Close the cover and enter pending state.
			// The technician swipes their ID to authorize ? faction is checked against their card.
			rcp_pending_action = "lock"
			rcp_pending_user   = WEAKREF(U)
			opened = FALSE
			update_icons()
			to_chat(U, span_notice("Cover closed. Swipe your ID card on [real_name] to authorize operator lock."))

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
			log_game("[key_name(U)] cleared operator lock on [real_name] via config panel")
			control_mode = null
			locked_ckey  = null

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
			log_game("[key_name(user)] added faction [faction_tag] to [real_name] via ID card swipe")
			to_chat(user, span_nicegreen("Faction '[faction_tag]' registered to [real_name]."))
	else if(action == "lock")
		var/op_name = card.registered_name
		if(!op_name || !length(op_name))
			to_chat(user, span_warning("This ID card has no registered name."))
		else
			control_mode = "locked"
			locked_ckey  = op_name
			log_service("CONTROL MODE -- LOCKED ([op_name]) authorized by [user.name]")
			log_game("[key_name(user)] locked [real_name] to [op_name] via ID card swipe")
			to_chat(user, span_nicegreen("[real_name] locked to operator: [op_name]."))
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

	// ?? Control mode ??????????????????????????????????????????????
	// Plain-language description of each mode so it reads like a service menu,
	// not a codebase variable.
	d += "<b>CONTROL MODE</b><br>"
	var/cmode = control_mode ? control_mode : "npc"
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
	d += "<br><br>"

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
