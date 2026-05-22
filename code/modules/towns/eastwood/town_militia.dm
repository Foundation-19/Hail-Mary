// Eastwood Town Militia
// Citizen defense force separate from NCR military

// ============ MILITIA DATUM ============

/datum/eastwood_militia
	var/list/members = list()
	var/list/patrols = list()
	var/alert_level = 0
	var/mobilized = FALSE
	var/list/supplies = list()

/datum/eastwood_militia/proc/is_member(ckey)
	for(var/datum/militia_member/M in members)
		if(M.ckey == ckey)
			return TRUE
	return FALSE

/datum/eastwood_militia/proc/get_member(ckey)
	for(var/datum/militia_member/M in members)
		if(M.ckey == ckey)
			return M
	return null

/datum/eastwood_militia/proc/enlist(mob/user)
	if(!GLOB.eastwood_council.is_citizen(user.ckey))
		return FALSE

	if(is_member(user.ckey))
		return FALSE

	if(members.len >= MILITIA_MAX_MEMBERS)
		return FALSE

	var/datum/militia_member/new_member = new()
	new_member.ckey = user.ckey
	new_member.name = user.name
	new_member.join_date = world.time
	new_member.rank = MILITIA_RANK_RECRUIT

	members += new_member
	return TRUE

/datum/eastwood_militia/proc/discharge(target_ckey)
	for(var/datum/militia_member/M in members)
		if(M.ckey == target_ckey)
			members -= M
			qdel(M)
			return TRUE
	return FALSE

/datum/eastwood_militia/proc/promote(target_ckey)
	var/datum/militia_member/M = get_member(target_ckey)
	if(!M)
		return FALSE

	switch(M.rank)
		if(MILITIA_RANK_RECRUIT)
			M.rank = MILITIA_RANK_MEMBER
		if(MILITIA_RANK_MEMBER)
			M.rank = MILITIA_RANK_SERGEANT
		if(MILITIA_RANK_SERGEANT)
			M.rank = MILITIA_RANK_COMMANDER
		else
			return FALSE

	return TRUE

/datum/eastwood_militia/proc/demote(target_ckey)
	var/datum/militia_member/M = get_member(target_ckey)
	if(!M)
		return FALSE

	switch(M.rank)
		if(MILITIA_RANK_COMMANDER)
			M.rank = MILITIA_RANK_SERGEANT
		if(MILITIA_RANK_SERGEANT)
			M.rank = MILITIA_RANK_MEMBER
		if(MILITIA_RANK_MEMBER)
			M.rank = MILITIA_RANK_RECRUIT
		else
			return FALSE

	return TRUE

/datum/eastwood_militia/proc/start_patrol(mob/user, patrol_type)
	if(!is_member(user.ckey))
		return FALSE

	var/datum/militia_patrol/patrol = new()
	patrol.leader_ckey = user.ckey
	patrol.patrol_type = patrol_type
	patrol.start_time = world.time
	patrol.end_time = world.time + PATROL_DURATION

	patrols += patrol

	addtimer(CALLBACK(src, .proc/end_patrol, patrol), PATROL_DURATION)
	return TRUE

/datum/eastwood_militia/proc/end_patrol(datum/militia_patrol/patrol)
	if(!patrol)
		return

	var/datum/militia_member/M = get_member(patrol.leader_ckey)
	if(M)
		M.patrols_completed++

	patrols -= patrol
	qdel(patrol)

/datum/eastwood_militia/proc/set_alert_level(new_level)
	alert_level = new_level

	switch(new_level)
		if(MILITIA_ALERT_PEACEFUL)
			mobilized = FALSE
		if(MILITIA_ALERT_ELEVATED)
			mobilized = FALSE
		if(MILITIA_ALERT_DANGER)
			mobilized = TRUE
		if(MILITIA_ALERT_EMERGENCY)
			mobilized = TRUE

	return TRUE

/datum/eastwood_militia/proc/issue_equipment(target_ckey, equipment_type)
	var/datum/militia_member/M = get_member(target_ckey)
	if(!M)
		return FALSE

	switch(equipment_type)
		if("rifle")
			if(M.issued_rifle)
				return FALSE
			M.issued_rifle = TRUE
		if("armor")
			if(M.issued_armor)
				return FALSE
			M.issued_armor = TRUE
		if("radio")
			if(M.issued_radio)
				return FALSE
			M.issued_radio = TRUE
		else
			return FALSE

	return TRUE

// ============ MILITIA MEMBER ============

/datum/militia_member
	var/ckey
	var/name
	var/join_date
	var/rank = MILITIA_RANK_RECRUIT
	var/patrols_completed = 0
	var/issued_rifle = FALSE
	var/issued_armor = FALSE
	var/issued_radio = FALSE

// ============ MILITIA PATROL ============

/datum/militia_patrol
	var/leader_ckey
	var/patrol_type
	var/start_time
	var/end_time

// ============ MILITIA ARMORY ============

/obj/machinery/computer/militia_armory
	name = "Militia Armory Terminal"
	desc = "A terminal for managing the town militia."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/militia_armory/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/militia_armory/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MilitiaArmory")
		ui.open()

/obj/machinery/computer/militia_armory/ui_data(mob/user)
	var/list/data = list()

	data["is_member"] = GLOB.eastwood_militia.is_member(user.ckey)
	data["is_commander"] = FALSE
	data["alert_level"] = GLOB.eastwood_militia.alert_level
	data["mobilized"] = GLOB.eastwood_militia.mobilized
	data["max_members"] = MILITIA_MAX_MEMBERS

	var/datum/militia_member/member = GLOB.eastwood_militia.get_member(user.ckey)
	if(member)
		data["rank"] = member.rank
		data["patrols_completed"] = member.patrols_completed
		data["issued_rifle"] = member.issued_rifle
		data["issued_armor"] = member.issued_armor
		data["issued_radio"] = member.issued_radio
		if(member.rank >= MILITIA_RANK_COMMANDER)
			data["is_commander"] = TRUE

	var/list/members_data = list()
	for(var/datum/militia_member/M in GLOB.eastwood_militia.members)
		members_data += list(list("ckey" = M.ckey, "name" = M.name, "rank" = M.rank, "patrols" = M.patrols_completed))
	data["members"] = members_data

	var/list/patrols_data = list()
	for(var/datum/militia_patrol/P in GLOB.eastwood_militia.patrols)
		patrols_data += list(list("leader" = P.leader_ckey, "type" = P.patrol_type))
	data["active_patrols"] = patrols_data

	return data

/obj/machinery/computer/militia_armory/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("enlist")
			if(GLOB.eastwood_militia.enlist(usr))
				to_chat(usr, span_notice("You have joined the Eastwood Militia!"))
			else
				to_chat(usr, span_warning("Cannot join militia. Check requirements."))
			return TRUE

		if("discharge")
			var/target_ckey = params["target_ckey"]
			if(GLOB.eastwood_militia.discharge(target_ckey))
				to_chat(usr, span_notice("Member discharged."))
			return TRUE

		if("promote")
			var/target_ckey = params["target_ckey"]
			if(GLOB.eastwood_militia.promote(target_ckey))
				to_chat(usr, span_notice("Member promoted."))
			return TRUE

		if("demote")
			var/target_ckey = params["target_ckey"]
			if(GLOB.eastwood_militia.demote(target_ckey))
				to_chat(usr, span_notice("Member demoted."))
			return TRUE

		if("start_patrol")
			var/patrol_type = params["patrol_type"]
			if(GLOB.eastwood_militia.start_patrol(usr, patrol_type))
				to_chat(usr, span_notice("Patrol started."))
			return TRUE

		if("set_alert")
			var/level = text2num(params["level"])
			var/datum/militia_member/M = GLOB.eastwood_militia.get_member(usr.ckey)
			if(M && M.rank >= MILITIA_RANK_COMMANDER)
				GLOB.eastwood_militia.set_alert_level(level)
				to_chat(usr, span_notice("Alert level changed."))
			return TRUE

		if("issue_equipment")
			var/target_ckey = params["target_ckey"]
			var/equipment = params["equipment"]
			if(GLOB.eastwood_militia.issue_equipment(target_ckey, equipment))
				to_chat(usr, span_notice("Equipment issued."))
			return TRUE

	return FALSE

// ============ MILITIA WEAPON RACK ============

/obj/structure/militia_rack
	name = "Militia Weapon Rack"
	desc = "A rack containing militia equipment."
	icon = 'icons/obj/structures.dmi'
	icon_state = "weapon_rack"
	density = TRUE
	anchored = TRUE

/obj/structure/militia_rack/attack_hand(mob/user)
	if(!GLOB.eastwood_militia.is_member(user.ckey))
		to_chat(user, span_warning("Only militia members may access this rack."))
		return

	var/datum/militia_member/M = GLOB.eastwood_militia.get_member(user.ckey)
	if(!M)
		return

	var/list/options = list()

	if(M.issued_rifle)
		options += "Retrieve Rifle"
	if(M.issued_armor)
		options += "Retrieve Armor"
	if(M.issued_radio)
		options += "Retrieve Radio"

	if(!options.len)
		to_chat(user, span_warning("No equipment assigned to you."))
		return

	var/choice = input(user, "Select equipment to retrieve:", "Militia Equipment") as null|anything in options
	if(!choice)
		return

	switch(choice)
		if("Retrieve Rifle")
			var/obj/item/gun/ballistic/rifle/hunting/rifle = new(get_turf(src))
			user.put_in_hands(rifle)
			to_chat(user, span_notice("You retrieve a militia rifle."))
		if("Retrieve Armor")
			var/obj/item/clothing/suit/armor/vest/leather/armor = new(get_turf(src))
			user.put_in_hands(armor)
			to_chat(user, span_notice("You retrieve militia armor."))
		if("Retrieve Radio")
			var/obj/item/radio/radio = new(get_turf(src))
			user.put_in_hands(radio)
			to_chat(user, span_notice("You retrieve a militia radio."))
