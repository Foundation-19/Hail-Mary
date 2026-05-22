/datum/tgui_view_variables
	var/client/owner
	var/datum/target
	var/is_list = FALSE

/datum/tgui_view_variables/New(client/C, datum/T)
	if(!istype(C))
		qdel(src)
		CRASH("TGUI VV attempted to open without a valid client")
	owner = C
	target = T
	is_list = islist(T)

/datum/tgui_view_variables/Destroy()
	owner = null
	target = null
	return ..()

/datum/tgui_view_variables/ui_state(mob/user)
	return GLOB.admin_state

/datum/tgui_view_variables/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ViewVariables")
		ui.open()

/datum/tgui_view_variables/ui_data(mob/user)
	. = list()
	
	// Datum info
	.["datum"] = list(
		"name" = is_list ? "/list" : "[target]",
		"type" = is_list ? "/list" : "[target.type]",
		"ref" = REF(target),
		"is_marked" = !is_list && owner?.holder?.marked_datum == target,
		"is_edited" = !is_list && (target.datum_flags & DF_VAR_EDITED),
		"is_deleted" = !is_list && target.gc_destroyed,
	)
	
	// Dropdown options
	.["dropdown_options"] = list()
	if(is_list)
		.["dropdown_options"] = list(
			list("name" = "Add Item", "action" = "list_add"),
			list("name" = "Remove Nulls", "action" = "list_erase_nulls"),
			list("name" = "Remove Dupes", "action" = "list_erase_dupes"),
			list("name" = "Set Length", "action" = "list_set_length"),
			list("name" = "Shuffle", "action" = "list_shuffle"),
			list("name" = "View References", "action" = "view_references"),
		)
	else
		if(istype(target, /atom))
			.["dropdown_options"] = list(
				list("name" = "Mark Object", "action" = "mark"),
				list("name" = "Delete", "action" = "delete"),
				list("name" = "Jump To", "action" = "jump_to"),
				list("name" = "Get", "action" = "get"),
				list("name" = "View References", "action" = "view_references"),
			)
		if(ismob(target))
			.["dropdown_options"] += list(
				list("name" = "Player Panel", "action" = "player_panel"),
				list("name" = "Heal", "action" = "heal"),
			)
		.["dropdown_options"] += list(
			list("name" = "Call Proc", "action" = "call_proc"),
		)
	
	// Variables
	var/list/variables_list = list()
	if(is_list)
		var/list/L = target
		for(var/i in 1 to L.len)
			var/key = L[i]
			var/value
			if(IS_NORMAL_LIST(L) && IS_VALID_ASSOC_KEY(key))
				value = L[key]
			variables_list += list(serialize_variable("[i]", value, L))
	else
		var/list/var_names = list()
		for(var/V in target.vars)
			var_names += V
		var_names = sortList(var_names)
		for(var/V in var_names)
			if(target.can_vv_get(V))
				variables_list += list(serialize_variable(V, target.vars[V], target))
	.["variables"] = variables_list

/datum/tgui_view_variables/proc/serialize_variable(name, value, datum/source)
	var/list/data = list(
		"name" = name,
		"value" = null,
		"type" = "null",
		"ref" = null,
		"is_editable" = TRUE,
		"sub_vars" = list(),
	)
	
	if(isnull(value))
		data["type"] = "null"
		data["value"] = "null"
		return data
	
	if(isnum(value))
		if(name in GLOB.bitfields)
			data["type"] = "bitfield"
			var/list/flags = list()
			for(var/i in GLOB.bitfields[name])
				if(value & GLOB.bitfields[name][i])
					flags += i
			data["value"] = jointext(flags, ", ")
		else
			data["type"] = "number"
			data["value"] = value
		return data
	
	if(istext(value))
		if(findtext(value, "\n"))
			data["type"] = "message"
		else
			data["type"] = "text"
		data["value"] = value
		return data
	
	if(isicon(value))
		data["type"] = "icon"
		data["value"] = "[value]"
		return data
	
	if(isfile(value))
		data["type"] = "file"
		data["value"] = "[value]"
		return data
	
	if(ismob(value))
		data["type"] = "mob"
		data["value"] = "[value] [(value:type)]"
		data["ref"] = REF(value)
		return data
	
	if(isloc(value))
		data["type"] = "atom"
		data["value"] = "[value] [(value:type)]"
		data["ref"] = REF(value)
		return data
	
	if(istype(value, /client))
		data["type"] = "client"
		data["value"] = "[value]"
		data["ref"] = REF(value)
		return data
	
	if(istype(value, /datum))
		data["type"] = "datum"
		data["value"] = "[value] [(value:type)]"
		data["ref"] = REF(value)
		return data
	
	if(ispath(value))
		if(ispath(value, /atom))
			data["type"] = "atom_type"
		else if(ispath(value, /datum))
			data["type"] = "datum_type"
		else
			data["type"] = "type"
		data["value"] = "[value]"
		return data
	
	if(islist(value))
		data["type"] = "list"
		var/list/L = value
		data["value"] = "/list ([L.len])"
		data["ref"] = REF(value)
		data["sub_vars"] = L.len
		return data
	
	data["type"] = "unknown"
	data["value"] = "[value]"
	return data

/datum/tgui_view_variables/ui_act(action, params)
	if(..())
		return
	
	if(!owner?.holder)
		return
	
	switch(action)
		if("refresh")
			return
		
		if("edit_var")
			var/var_name = params["name"]
			if(var_name)
				do_edit_var(var_name)
		
		if("change_var")
			var/var_name = params["name"]
			if(var_name)
				do_change_var(var_name)
		
		if("mass_edit")
			var/var_name = params["name"]
			if(var_name)
				do_mass_edit(var_name)
		
		if("view_ref")
			var/ref_to_view = params["ref"]
			if(ref_to_view)
				var/datum/D = locate(ref_to_view)
				if(D)
					owner.debug_variables_tgui(D)
		
		if("dropdown_action")
			var/dropdown_action = params["action"]
			handle_dropdown_action(dropdown_action)
	
	return TRUE

/datum/tgui_view_variables/proc/do_edit_var(var_name)
	if(!owner?.holder || !check_rights(R_VAREDIT))
		return
	
	var/current_value
	if(is_list)
		var/list/L = target
		var/index = text2num(var_name)
		if(!index || index < 1 || index > L.len)
			return
		current_value = L[index]
	else
		current_value = target.vars[var_name]
	
	var/list/value_data = owner.vv_get_value(VV_NUM, VV_NUM, current_value, var_name = var_name)
	if(value_data["class"] != null && !isnull(value_data["value"]))
		if(is_list)
			var/list/L = target
			var/index = text2num(var_name)
			L[index] = value_data["value"]
		else
			target.vv_edit_var(var_name, value_data["value"])
		log_admin("[key_name(owner)] modified [is_list ? "list" : target.type].[var_name] to [value_data["value"]]")

/datum/tgui_view_variables/proc/do_change_var(var_name)
	if(!owner?.holder || !check_rights(R_VAREDIT))
		return
	
	var/current_value
	if(is_list)
		var/list/L = target
		var/index = text2num(var_name)
		if(!index || index < 1 || index > L.len)
			return
		current_value = L[index]
	else
		current_value = target.vars[var_name]
	
	var/list/value_data = owner.vv_get_value(null, VV_NUM, current_value, var_name = var_name)
	if(value_data["class"] != null && !isnull(value_data["value"]))
		if(is_list)
			var/list/L = target
			var/index = text2num(var_name)
			L[index] = value_data["value"]
		else
			target.vv_edit_var(var_name, value_data["value"])
		log_admin("[key_name(owner)] changed [is_list ? "list" : target.type].[var_name] to [value_data["value"]]")

/datum/tgui_view_variables/proc/do_mass_edit(var_name)
	if(!owner?.holder || !check_rights(R_VAREDIT))
		return
	
	if(is_list)
		return
	
	var/current_value = target.vars[var_name]
	var/list/value_data = owner.vv_get_value(null, VV_NUM, current_value, var_name = var_name)
	if(value_data["class"] != null && !isnull(value_data["value"]))
		var/count = 0
		for(var/V in typesof(target.type))
			var/datum/instance = locate(V)
			if(istype(instance) && instance.vars.Find(var_name))
				instance.vv_edit_var(var_name, value_data["value"])
				count++
		log_admin("[key_name(owner)] mass-edited [var_name] on [target.type] ([count] instances)")

/datum/tgui_view_variables/proc/handle_dropdown_action(action)
	if(!owner?.holder)
		return
	
	var/ref = REF(target)
	var/href = "?_src_=vars;[HrefToken()]"
	
	switch(action)
		if("mark")
			owner.mark_datum(target)
		if("delete")
			usr.client << link("[href];admin_delete=[ref]")
		if("jump_to")
			var/atom/A = target
			if(istype(A))
				owner.jumptomob(A)
		if("get")
			var/atom/A = target
			if(istype(A))
				usr.client << link("[href];getmob=[ref]")
		if("view_references")
			usr.client << link("[href];view_references=[ref]")
		if("call_proc")
			owner.callproc_blocking(list(), target)
		if("player_panel")
			var/mob/M = target
			if(ismob(M) && owner.holder)
				owner.holder.show_player_panel_tgui(M)
		if("heal")
			var/mob/living/L = target
			if(istype(L))
				L.revive(full_heal = TRUE, admin_revive = TRUE)
				log_admin("[key_name(owner)] healed [key_name(L)] via VV")
				message_admins("[key_name_admin(owner)] healed [ADMIN_LOOKUPFLW(L)] via VV")
		if("list_add")
			usr.client << link("[href];list_add=[ref]")
		if("list_erase_nulls")
			usr.client << link("[href];list_erase_nulls=[ref]")
		if("list_erase_dupes")
			usr.client << link("[href];list_erase_dupes=[ref]")
		if("list_set_length")
			usr.client << link("[href];list_set_length=[ref]")
		if("list_shuffle")
			usr.client << link("[href];list_shuffle=[ref]")

/client/proc/debug_variables_tgui(datum/D in world)
	set category = "Debug"
	set name = "View Variables (TGUI)"
	
	if(!usr.client || !usr.client.holder)
		to_chat(usr, span_danger("You need to be an administrator to access this."), confidential = TRUE)
		return
	
	if(!D)
		return
	
	var/is_list = islist(D)
	if(!is_list && !istype(D))
		return
	
	log_admin("[key_name(usr)] viewed variables (TGUI) of [is_list ? "/list" : D.type].")
	
	var/datum/tgui_view_variables/panel = new(src, D)
	panel.ui_interact(usr)
