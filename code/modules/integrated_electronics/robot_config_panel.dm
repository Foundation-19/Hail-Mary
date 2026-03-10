// ====================================================
// ROBOT CONFIGURATION PANEL
// Admin browser UI. Multitool + open panel = opens this.
// Topic() on the robot mob -- browser src = REF(robot).
// No canUseTopic, no datum wrapper. Matches terminal.dm.
// ====================================================

#define RCP_IDENTITY  1
#define RCP_FACTIONS  2
#define RCP_HARDWARE  3
#define RCP_LOADOUT   4

#define RCP_PRESETS list("wastebots","hostile","raider","enclave","ncr","brotherhood","legion","neutral","silicon")

// -- State vars on the robot mob itself
/mob/living/silicon/robot
	var/rcp_mode       = RCP_IDENTITY
	var/rcp_hw_mode    = null    // null | "add_cat" | "add_type"
	var/rcp_hw_cat     = null
	var/control_mode   = null
	var/locked_ckey    = null


// ====================================================
// ENTRY POINT
// Called from attackby() when multitool + opened
// ====================================================

/mob/living/silicon/robot/proc/open_config_panel(mob/user)
	if(!check_rights_for(user.client, R_ADMIN))
		to_chat(user, span_warning("Access denied."))
		return
	rcp_mode    = RCP_IDENTITY
	rcp_hw_mode = null
	rcp_hw_cat  = null
	_rcp_push(user)


// -- Build and push the browser window
/mob/living/silicon/robot/proc/_rcp_push(mob/user)
	if(QDELETED(src) || QDELETED(user))
		return
	var/dat = _rcp_css()
	dat += _rcp_header()
	dat += _rcp_nav()

	switch(rcp_mode)
		if(RCP_IDENTITY) dat += _rcp_identity()
		if(RCP_FACTIONS) dat += _rcp_factions()
		if(RCP_HARDWARE) dat += _rcp_hardware()
		if(RCP_LOADOUT)  dat += _rcp_loadout()

	dat += _rcp_footer()
	dat += "</body></html>"

	var/datum/browser/popup = new(user, "rcp_[REF(src)]", "RobCo Config - [real_name]", 680, 540)
	popup.set_content(dat)
	popup.open()


// ====================================================
// TOPIC -- clicks route here (no parent call, no canUseTopic)
// ====================================================

/mob/living/silicon/robot/Topic(href, list/href_list)
	var/mob/U = usr
	if(!U?.client || !check_rights_for(U.client, R_ADMIN))
		return

	if(href_list["rcp_nav"])
		rcp_mode    = text2num(href_list["rcp_nav"])
		rcp_hw_mode = null
		rcp_hw_cat  = null
		_rcp_push(U)
		return

	if("rcp_hw_mode" in href_list)
		rcp_hw_mode = href_list["rcp_hw_mode"] || null
		rcp_hw_cat  = href_list["hw_cat"] || null
		_rcp_push(U)
		return

	var/a = href_list["a"]
	if(!a)
		_rcp_push(U)
		return

	switch(a)

		if("set_name")
			var/n = stripped_input(U, "Enter display name:", "Robot Name", real_name, max_length=64)
			if(!QDELETED(src) && n)
				log_game("[key_name(U)] renamed robot [real_name] -> [n]")
				real_name = n
				name      = n
				if(builtInCamera) builtInCamera.c_tag = n

		if("set_ident")
			var/v = input(U, "Enter ident (1-9999):", "Ident", ident) as num|null
			if(!QDELETED(src) && v != null)
				ident = clamp(round(v), 1, 9999)

		if("set_ctrl")
			var/val = href_list["val"]
			if(val == "locked")
				var/ck = stripped_input(U, "Lock to ckey:", "Lock", "")
				if(length(ck))
					control_mode = "locked"
					locked_ckey  = ck
					log_game("[key_name(U)] locked [real_name] to [ck]")
			else if(val in list("npc","open"))
				control_mode = val
				locked_ckey  = null
				log_game("[key_name(U)] set [real_name] control=[val]")

		if("set_cha")
			var/v = input(U, "CHA modifier (0-20):", "CHA", cert_cha_modifier) as num|null
			if(!QDELETED(src) && v != null)
				cert_cha_modifier = clamp(round(v), 0, 20)

		if("add_fac")
			var/tag = href_list["val"]
			if(tag && length(tag))
				if(!faction) faction = list()
				faction |= tag
				log_game("[key_name(U)] added faction [tag] to [real_name]")

		if("add_fac_custom")
			var/tag = stripped_input(U, "Custom faction tag:", "Faction", "")
			if(tag && length(tag))
				if(!faction) faction = list()
				faction |= tag

		if("del_fac")
			var/tag = href_list["val"]
			if(tag && faction && (tag in faction))
				faction -= tag
				log_game("[key_name(U)] removed faction [tag] from [real_name]")

		if("add_hw")
			var/ht = text2path(href_list["ht"])
			if(ht && ispath(ht, /datum/robot_hardware))
				var/dupe = FALSE
				for(var/datum/robot_hardware/ex in installed_hardware)
					if(ex.type == ht) dupe = TRUE; break
				if(!dupe)
					var/datum/robot_hardware/hw = new ht()
					hw.install(src)
					log_game("[key_name(U)] installed [ht] on [real_name]")
				else
					to_chat(U, span_warning("Already installed."))
			rcp_hw_mode = null; rcp_hw_cat = null

		if("del_hw")
			var/datum/robot_hardware/HW = locate(href_list["ref"])
			if(istype(HW) && (HW in installed_hardware))
				log_game("[key_name(U)] removed [HW.hardware_name] from [real_name]")
				HW.uninstall(src)
				qdel(HW)

		if("apply_preset")
			var/design_path = text2path(href_list["dtype"])
			if(design_path)
				var/list/entries = get_recommended_hardware(design_path)
				var/applied = 0
				for(var/list/E in entries)
					var/hw_type = E[1]
					var/already = FALSE
					for(var/datum/robot_hardware/ex in installed_hardware)
						if(istype(ex, hw_type))
							already = TRUE
							break
					if(already) continue
					var/datum/robot_hardware/NHW = new hw_type()
					if(E.len >= 2 && islist(E[2]))
						for(var/key in E[2])
							NHW.vars[key] = E[2][key]
					installed_hardware += NHW
					NHW.install(src)
					applied++
				log_game("[key_name(U)] applied preset [design_path] to [real_name] ([applied] modules added)")

	if(!QDELETED(src))
		_rcp_push(U)


// ====================================================
// HTML HELPERS
// ====================================================

/mob/living/silicon/robot/proc/_rcp_css()
	var/css = "<html><head><style>"
	// Exact match to terminal.dm color palette
	css += "body{padding:0;margin:15px;background-color:#062113;color:#4aed92;line-height:170%;font-family:'Courier New',Courier,monospace;}"
	css += "a,a:link,a:visited,a:active{color:#4aed92;text-decoration:none;background:#062113;border:none;padding:1px 4px;margin:0 2px;}"
	css += "a:hover{color:#062113;background:#4aed92;cursor:pointer;}"
	css += ".dim{color:#2a7a52;}"
	css += ".good{color:#4aed92;font-weight:bold;}"
	css += ".bad{color:#c0392b;font-weight:bold;}"
	css += ".warn{color:#e8a020;}"
	css += ".hi{color:#ffffff;}"
	css += "hr{border:none;border-top:1px solid #2a7a52;margin:4px 0;}"
	css += "table{width:100%;border-spacing:0 2px;}"
	css += "td{padding:1px 6px;border-bottom:1px solid #0d3322;vertical-align:top;}"
	css += "th{color:#2a7a52;text-align:left;padding:1px 6px;font-weight:normal;border-bottom:1px solid #2a7a52;}"
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
		list("Identity", RCP_IDENTITY),
		list("Factions", RCP_FACTIONS),
		list("Hardware", RCP_HARDWARE),
		list("Loadout",  RCP_LOADOUT)
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
	var/cmode = control_mode ? control_mode : "npc"
	var/cell_str = cell ? "[round(cell.charge/cell.maxcharge*100)]%" : "<span class='bad'>NO CELL</span>"
	var/stat_str = stat == DEAD ? "<span class='bad'>OFFLINE</span>" : "<span class='good'>ONLINE</span>"
	var/f = "<br><hr>"
	f += "<span class='dim'>HEALTH: [health]/[maxHealth]  |  CELL: [cell_str]  |  MODE: [cmode]  |  STATUS: [stat_str]</span>"
	return f


// ====================================================
// IDENTITY
// ====================================================

/mob/living/silicon/robot/proc/_rcp_identity()
	var/d = "<b>// IDENTITY //</b><br><br>"
	d += "<b>Display Name:</b> [html_encode(name)]<br>"
	d += "<a href='byond://?src=[REF(src)];a=set_name'>&gt; Edit Name</a><br><br>"

	d += "<b>Robot ID (ident):</b> [ident]<br>"
	d += "<a href='byond://?src=[REF(src)];a=set_ident'>&gt; Edit Ident</a><br><br>"

	var/cmode = control_mode ? html_encode(control_mode) : "npc"
	d += "<b>Control Mode:</b> [cmode]"
	if(control_mode == "locked" && locked_ckey)
		d += " <span class='dim'>([html_encode(locked_ckey)])</span>"
	d += "<br>"
	d += "<a href='byond://?src=[REF(src)];a=set_ctrl;val=npc'>&gt; Set NPC</a> "
	d += "<a href='byond://?src=[REF(src)];a=set_ctrl;val=open'>&gt; Set Open</a> "
	d += "<a href='byond://?src=[REF(src)];a=set_ctrl;val=locked'>&gt; Lock to Ckey</a><br><br>"

	d += "<b>Module:</b> [module ? html_encode(module.name) : "<span class='dim'>none</span>"]<br>"
	d += "<b>CPU Cert:</b> [cpu_cert ? "[cpu_cert.type]" : "<span class='dim'>none</span>"]<br>"
	return d


// ====================================================
// FACTIONS
// ====================================================

/mob/living/silicon/robot/proc/_rcp_factions()
	var/d = "<b>// FACTIONS //</b><br>"
	d += "<span class='dim'>Robot attacks mobs whose faction is not in this list.</span><br><br>"

	d += "<b>Active Tags:</b><br>"
	if(!faction || !faction.len)
		d += "<span class='dim'>(none -- will engage all targets)</span><br>"
	else
		for(var/f in faction)
			d += "<span class='warn'>[html_encode(f)]</span> "
			d += "<a href='byond://?src=[REF(src)];a=del_fac;val=[url_encode(f)]'>(x)</a>  "
		d += "<br>"

	d += "<br><b>Add Tag:</b><br>"
	for(var/p in RCP_PRESETS)
		var/have = faction && (p in faction)
		if(have)
			d += "<span class='dim'>&gt; [p] <span class='good'>(active)</span></span><br>"
		else
			d += "<a href='byond://?src=[REF(src)];a=add_fac;val=[url_encode(p)]'>&gt;  [p]</a><br>"
	d += "<a href='byond://?src=[REF(src)];a=add_fac_custom'>&gt; Custom...</a><br><br>"

	d += "<hr><b>CHA Modifier:</b> [cert_cha_modifier] "
	d += "<a href='byond://?src=[REF(src)];a=set_cha'>(edit)</a><br>"
	d += "<span class='dim'>Widens faction-check radius in behavior circuits.</span>"
	return d


// ====================================================
// HARDWARE
// ====================================================

#define _HW_CATS list(\
	"Weapons"        = list(/datum/robot_hardware/weapon,/datum/robot_hardware/grenade_launcher,/datum/robot_hardware/air_cannon,/datum/robot_hardware/stun_module),\
	"Reagents"       = list(/datum/robot_hardware/injector,/datum/robot_hardware/reagent_pump,/datum/robot_hardware/reagent_tank),\
	"Sensors"        = list(/datum/robot_hardware/health_scanner,/datum/robot_hardware/environment_scanner,/datum/robot_hardware/bio_scanner,/datum/robot_hardware/object_locator,/datum/robot_hardware/id_reader,/datum/robot_hardware/gps),\
	"Comms"          = list(/datum/robot_hardware/microphone,/datum/robot_hardware/speaker,/datum/robot_hardware/signaler),\
	"Output"         = list(/datum/robot_hardware/display_screen,/datum/robot_hardware/light),\
	"Navigation"     = list(/datum/robot_hardware/locomotion,/datum/robot_hardware/nav_computer),\
	"Intelligence"   = list(/datum/robot_hardware/logic_core,/datum/robot_hardware/memory_core,/datum/robot_hardware/vocabulary_module,/datum/robot_hardware/circuit_board),\
	"Support"        = list(/datum/robot_hardware/clock,/datum/robot_hardware/power_relay,/datum/robot_hardware/grabber,/datum/robot_hardware/harvester,/datum/robot_hardware/material_collector)\
)

/mob/living/silicon/robot/proc/_rcp_hardware()
	var/d = "<b>// HARDWARE MODULES //</b><br><br>"

	// Installed list
	if(!installed_hardware || !installed_hardware.len)
		d += "<span class='dim'>(no hardware installed)</span><br>"
	else
		d += "<table><tr><th>Module</th><th>Category</th><th>Info</th><th></th></tr>"
		for(var/datum/robot_hardware/HW in installed_hardware)
			d += "<tr><td><b>[html_encode(HW.hardware_name)]</b></td>"
			d += "<td class='dim'>[html_encode(HW.category ? HW.category : "--")]</td>"
			d += "<td class='dim'>[html_encode(HW.get_summary())]</td>"
			d += "<td><a href='byond://?src=[REF(src)];a=del_hw;ref=[REF(HW)]'>(remove)</a></td></tr>"
		d += "</table>"

	d += "<br>"

	if(!rcp_hw_mode)
		d += "<a href='byond://?src=[REF(src)];rcp_hw_mode=add_cat'>&gt; Install Module...</a>"

	else if(rcp_hw_mode == "add_cat")
		d += "<b>Select category:</b><br>"
		var/cats = _HW_CATS
		for(var/cat in cats)
			d += "<a href='byond://?src=[REF(src)];rcp_hw_mode=add_type;hw_cat=[url_encode(cat)]'>&gt;  [cat]</a><br>"
		d += "<a href='byond://?src=[REF(src)];rcp_hw_mode='>&gt; Cancel</a>"

	else if(rcp_hw_mode == "add_type" && rcp_hw_cat)
		var/cats = _HW_CATS
		var/list/opts = cats[rcp_hw_cat]
		d += "<b>[html_encode(rcp_hw_cat)] -- select module:</b><br>"
		if(opts)
			d += "<table><tr><th>Module</th><th>Description</th><th></th></tr>"
			for(var/ht in opts)
				var/datum/robot_hardware/proto = new ht()
				var/installed = FALSE
				for(var/datum/robot_hardware/ex in installed_hardware)
					if(ex.type == ht) installed = TRUE; break
				d += "<tr><td><b>[html_encode(proto.hardware_name)]</b></td>"
				d += "<td class='dim'>[html_encode(proto.hardware_desc ? proto.hardware_desc : "--")]</td>"
				if(installed)
					d += "<td class='dim'>installed</td>"
				else
					d += "<td><a href='byond://?src=[REF(src)];a=add_hw;ht=[url_encode("[ht]")]'>(install)</a></td>"
				d += "</tr>"
				qdel(proto)
			d += "</table>"
		d += "<br><a href='byond://?src=[REF(src)];rcp_hw_mode=add_cat'>&gt; Back</a> "
		d += "<a href='byond://?src=[REF(src)];rcp_hw_mode='>&gt; Cancel</a>"

	return d


// ====================================================
// LOADOUT
// ====================================================

/mob/living/silicon/robot/proc/_rcp_loadout()
	var/d = "<b>// PRESET LOADOUTS //</b><br>"
	d += "<span class='dim'>Apply a hardware preset. Installs missing modules but does not remove existing ones.</span><br><br>"

	// List all available preset configs with apply links
	var/found_any = FALSE
	for(var/T in subtypesof(/datum/recommended_hardware_config))
		var/datum/recommended_hardware_config/RHC = new T()
		if(!RHC.design_type)
			qdel(RHC)
			continue
		found_any = TRUE
		var/label = uppertext(copytext("[RHC.design_type]", findlasttext("[RHC.design_type]", "/") + 1))
		d += "&gt; <b>[label]</b> <span class='dim'>([RHC.hardware_entries.len] modules)</span>"
		d += " <a href='byond://?src=[REF(src)];a=apply_preset;dtype=[url_encode("[RHC.design_type]")]'>&gt; APPLY</a><br>"
		qdel(RHC)
	if(!found_any)
		d += "<span class='dim'>(no presets defined)</span><br>"

	d += "<br><b>// INSTALLED HARDWARE //</b><br>"
	if(!installed_hardware || !installed_hardware.len)
		d += "<span class='dim'>(none)</span><br>"
	else
		for(var/datum/robot_hardware/HW in installed_hardware)
			d += "&gt; [html_encode(HW.hardware_name)]"
			if(HW.hardware_desc)
				d += " <span class='dim'>-- [html_encode(HW.hardware_desc)]</span>"
			d += "<br>"
	return d


// ====================================================
// CLEANUP
// ====================================================

#undef RCP_IDENTITY
#undef RCP_FACTIONS
#undef RCP_HARDWARE
#undef RCP_LOADOUT
#undef RCP_PRESETS
#undef _HW_CATS
