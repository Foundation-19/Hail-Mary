/client/proc/cmd_faction_set_district_owner()
	set category = "Admin.Faction"
	set name = "Faction Control: Set District Owner"

	if(!check_rights(R_ADMIN))
		return
	if(!SSfaction_control)
		if(mob) to_chat(mob, span_warning("Faction control subsystem is unavailable."))
		return

	var/list/districts = list()
	for(var/d in SSfaction_control.district_income)
		districts += "[d]"
	if(!length(districts))
		if(mob) to_chat(mob, span_warning("No districts were discovered. Check area.grid_district values."))
		return

	var/district = input(src, "Choose district to modify.", "Faction Control") as null|anything in districts
	if(!district)
		return

	var/list/factions = list("Unclaimed")
	for(var/f in SSfaction_control.controllable_factions)
		factions += "[f]"
	var/choice = input(src, "Choose new owner for [district].", "Faction Control") as null|anything in factions
	if(!choice)
		return

	var/new_owner = null
	if(choice != "Unclaimed")
		new_owner = choice

	var/old_owner = SSfaction_control.get_owner(district)
	if(new_owner)
		SSfaction_control.set_owner(district, new_owner, null)
	else
		SSfaction_control.district_owner -= district
		world << span_warning("Faction Control: [district] is now unclaimed.")

	log_admin("[key_name(src)] set district [district] owner from [old_owner ? old_owner : "Unclaimed"] to [new_owner ? new_owner : "Unclaimed"].")
	message_admins(span_adminnotice("[key_name_admin(src)] set [district] owner to [new_owner ? new_owner : "Unclaimed"]."))

/client/proc/cmd_faction_add_funds()
	set category = "Admin.Faction"
	set name = "Faction Control: Adjust Faction Funds"

	if(!check_rights(R_ADMIN))
		return
	if(!SSfaction_control)
		if(mob) to_chat(mob, span_warning("Faction control subsystem is unavailable."))
		return

	var/list/factions = list()
	for(var/f in SSfaction_control.controllable_factions)
		factions += "[f]"
	if(!length(factions))
		if(mob) to_chat(mob, span_warning("No controllable factions configured."))
		return

	var/faction = input(src, "Choose faction to edit funds.", "Faction Control") as null|anything in factions
	if(!faction)
		return

	var/amount = input(src, "Positive adds funds, negative removes funds.", "Adjust Funds", 100) as null|num
	if(isnull(amount))
		return

	var/current = SSfaction_control.get_faction_funds(faction)
	var/new_total = current + round(amount)
	if(new_total < 0)
		new_total = 0
	SSfaction_control.faction_funds[faction] = new_total

	log_admin("[key_name(src)] adjusted [faction] treasury by [round(amount)] (now [new_total]).")
	message_admins(span_adminnotice("[key_name_admin(src)] adjusted [faction] treasury by [round(amount)] (now [new_total])."))

/client/proc/cmd_faction_snapshot()
	set category = "Admin.Faction"
	set name = "Faction Control: Snapshot"

	if(!check_rights(R_ADMIN))
		return
	if(!SSfaction_control)
		if(mob) to_chat(mob, span_warning("Faction control subsystem is unavailable."))
		return

	var/list/rows = SSfaction_control.get_status_rows()
	if(mob) to_chat(mob, span_notice("=== Faction Control Snapshot ==="))
	for(var/list/r in rows)
		if(mob) to_chat(mob, span_notice("[r["district"]]: owner=[r["owner"]] income=[r["income"]] grid=[r["grid_on"] ? "ON" : "OFF"]"))

	if(mob) to_chat(mob, span_notice("=== Treasuries ==="))
	for(var/f in SSfaction_control.controllable_factions)
		if(mob) to_chat(mob, span_notice("[f]: [SSfaction_control.get_faction_funds(f)]"))

/client/proc/cmd_faction_roll_contracts()
	set category = "Admin.Faction"
	set name = "Faction Control: Roll Contracts"

	if(!check_rights(R_ADMIN))
		return
	if(!SSfaction_control)
		if(mob) to_chat(mob, span_warning("Faction control subsystem is unavailable."))
		return

	SSfaction_control.roll_contracts()
	if(mob) to_chat(mob, span_notice("Faction contracts rolled."))

/client/proc/cmd_faction_spawn_event()
	set category = "Admin.Faction"
	set name = "Faction Control: Spawn Event"

	if(!check_rights(R_ADMIN))
		return
	if(!SSfaction_control)
		if(mob) to_chat(mob, span_warning("Faction control subsystem is unavailable."))
		return

	SSfaction_control.spawn_world_event()
	if(mob) to_chat(mob, span_notice("Forced a new wasteland event spawn."))
