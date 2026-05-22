// NCR Prison Cell
// Physical containment with interactive escape mechanics

/obj/structure/prison_cell
	name = "prison cell"
	desc = "A secure holding cell for NCR prisoners."
	icon = 'icons/obj/structures.dmi'
	icon_state = "prison_cell"
	density = TRUE
	anchored = TRUE
	layer = ABOVE_MOB_LAYER

	max_integrity = 200
	armor = list("melee" = 50, "bullet" = 50, "laser" = 30, "energy" = 30, "bomb" = 20, "bio" = 100, "rad" = 100, "fire" = 80, "acid" = 50)

	var/locked = TRUE
	var/lock_level = 2
	var/prisoner_ckey
	var/prisoner_name
	var/sentence_end_time
	var/datum/prisoner_record/record

	var/escape_progress = 0
	var/escape_attempt_time = 0
	var/last_escape_method
	var/alerted_guards = FALSE

	var/obj/item/holding_item

/obj/structure/prison_cell/examine(mob/user)
	. = ..()
	if(locked)
		. += span_notice("The cell is locked.")
	else
		. += span_notice("The cell is unlocked.")

	if(prisoner_name)
		. += span_notice("Prisoner: [prisoner_name]")
		if(record)
			. += span_notice("Crime: [record.crime]")
			var/time_left = max(0, (sentence_end_time - world.time) / (1 MINUTES))
			. += span_notice("Time remaining: [round(time_left, 0.1)] minutes")

	if(escape_progress > 0)
		. += span_warning("Someone has been tampering with this cell!")

/obj/structure/prison_cell/attack_hand(mob/user)
	if(user.ckey == prisoner_ckey)
		if(locked)
			show_escape_options(user)
		else
			exit_cell(user)
	else
		if(locked && is_ncr_law_enforcement(user))
			if(alert(user, "Unlock the cell?", "Prison Cell", "Yes", "No") == "Yes")
				unlock_cell(user)
		else if(!locked)
			if(alert(user, "Lock the cell?", "Prison Cell", "Yes", "No") == "Yes")
				lock_cell(user)

/obj/structure/prison_cell/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/lockpick) || istype(I, /obj/item/screwdriver) || istype(I, /obj/item/wirecutters))
		if(!locked)
			to_chat(user, span_notice("The cell is already unlocked."))
			return

		if(user.ckey == prisoner_ckey)
			attempt_lockpick(user, I)
		else if(is_ncr_law_enforcement(user))
			unlock_cell(user)
		else
			to_chat(user, span_warning("Only prisoners or guards can interact with the lock."))
		return

	if(istype(I, /obj/item/melee))
		if(user.ckey == prisoner_ckey)
			to_chat(user, span_warning("You can't attack your own cell from the inside!"))
			return
		user.visible_message(span_warning("[user] attacks [src]!"), span_notice("You attack [src]."))
		take_damage(I.force * 0.5)
		return

	..()

/obj/structure/prison_cell/proc/show_escape_options(mob/user)
	var/list/options = list(
		"Wait out sentence" = "wait",
		"Pick lock (needs tool)" = "picklock",
		"Force door (risky)" = "force",
		"Call for help" = "call",
	)

	var/choice = input(user, "How do you want to escape?", "Prison Cell") as null|anything in options

	if(!choice)
		return

	switch(options[choice])
		if("wait")
			to_chat(user, span_notice("You wait in your cell. Time remaining: [round((sentence_end_time - world.time) / (1 MINUTES), 0.1)] minutes."))
		if("picklock")
			attempt_lockpick(user, null)
		if("force")
			attempt_force_door(user)
		if("call")
			call_for_help(user)

/obj/structure/prison_cell/proc/attempt_lockpick(mob/user, obj/item/tool)
	var/pick_time = 30 SECONDS
	var/success_chance = 30

	if(tool)
		if(istype(tool, /obj/item/lockpick))
			success_chance = 50
			pick_time = 20 SECONDS
		else if(istype(tool, /obj/item/screwdriver))
			success_chance = 25
			pick_time = 40 SECONDS
		else if(istype(tool, /obj/item/wirecutters))
			success_chance = 20
			pick_time = 35 SECONDS

	if(!tool && !user.is_holding_item_of_type(/obj/item/lockpick) && !user.is_holding_item_of_type(/obj/item/screwdriver) && !user.is_holding_item_of_type(/obj/item/wirecutters))
		to_chat(user, span_warning("You need a lockpick, screwdriver, or wirecutters to pick the lock."))
		return

	visible_message(span_warning("[user] starts picking the lock on [src]!"), span_notice("You begin picking the lock..."))

	if(!do_after(user, pick_time, target = src))
		return

	if(prob(success_chance))
		locked = FALSE
		visible_message(span_warning("[src]'s lock clicks open!"), span_notice("Success! The lock opens."))
		record.escape_attempts++
		alert_guards(user, "lockpick")
		exit_cell(user)
		post_escape(user)
	else
		visible_message(span_warning("[user] fails to pick the lock!"), span_warning("You fail to pick the lock!"))
		record.escape_attempts++
		record.sentence_minutes += NCR_PRISON_ESCAPE_BONUS / (1 MINUTES)
		alert_guards(user, "lockpick failed")
		to_chat(user, span_warning("5 minutes added to your sentence."))

/obj/structure/prison_cell/proc/attempt_force_door(mob/user)
	var/force_time = 20 SECONDS
	var	success_chance = 15
	var	damage_chance = 60

	visible_message(span_warning("[user] starts forcing the door on [src]!"), span_notice("You throw yourself against the door..."))

	if(!do_after(user, force_time, target = src))
		return

	if(prob(success_chance))
		locked = FALSE
		take_damage(50)
		visible_message(span_warning("[src]'s door bursts open!"), span_notice("The door bursts open!"))
		record.escape_attempts++
		alert_guards(user, "forced")
		exit_cell(user)
		post_escape(user)
	else
		visible_message(span_warning("[user] fails to force the door!"), span_warning("You fail to force the door!"))
		record.escape_attempts++
		record.sentence_minutes += NCR_PRISON_ESCAPE_BONUS / (1 MINUTES)

		if(prob(damage_chance))
			user.apply_damage(10, BRUTE, BODY_ZONE_HEAD)
			to_chat(user, span_warning("You hurt yourself trying to force the door!"))

		alert_guards(user, "forced failed")
		to_chat(user, span_warning("5 minutes added to your sentence."))

/obj/structure/prison_cell/proc/call_for_help(mob/user)
	to_chat(user, span_notice("You call out for help..."))

	for(var/mob/M in GLOB.player_list)
		if(M.client && get_dist(M, src) <= 15)
			to_chat(M, span_warning("You hear someone calling for help from [src]!"))

/obj/structure/prison_cell/proc/alert_guards(mob/escapee, method)
	if(alerted_guards)
		return

	alerted_guards = TRUE

	var/method_text = ""
	switch(method)
		if("lockpick", "lockpick failed")
			method_text = "trying to pick the lock"
		if("forced", "forced failed")
			method_text = "trying to force the door"

	var/message = "PRISONER ALERT: [prisoner_name] is [method_text] at [get_area_name(src)]!"

	for(var/mob/M in GLOB.player_list)
		if(M.client && M.mind && is_ncr_law_enforcement(M))
			to_chat(M, span_alert(message))

	addtimer(VARSET_CALLBACK(src, alerted_guards, FALSE), 1 MINUTES)

/obj/structure/prison_cell/proc/unlock_cell(mob/user)
	locked = FALSE
	visible_message(span_notice("[user] unlocks [src]."), span_notice("You unlock the cell."))

/obj/structure/prison_cell/proc/lock_cell(mob/user)
	if(prisoner_ckey)
		locked = TRUE
		visible_message(span_notice("[user] locks [src]."), span_notice("You lock the cell."))

/obj/structure/prison_cell/proc/exit_cell(mob/user)
	user.forceMove(get_turf(src))
	prisoner_ckey = null
	prisoner_name = null
	record = null
	sentence_end_time = 0

/obj/structure/prison_cell/proc/post_escape(mob/escapee)
	var/datum/prisoner_record/escaped_record = record

	escaped_record.status = NCR_PRISONER_STATUS_ESCAPED

	GLOB.ncr_prisoners -= escaped_record
	GLOB.ncr_escapees += list(escaped_record)

	for(var/mob/M in GLOB.player_list)
		if(M.client && M.mind && is_ncr_law_enforcement(M))
			to_chat(M, span_alert("PRISONER ESCAPE: [escapee.real_name] has escaped from custody!"))

	to_chat(escapee, span_userdanger("You escaped! But you are now wanted by the NCR!"))

	var/datum/bounty_board_data/bounty_board = locate(/datum/bounty_board_data) in GLOB.ncr_bounties_global
	if(bounty_board)
		var/bounty_amount = min(escaped_record.sentence_minutes * 5, 300)
		bounty_board.post_bounty(escapee.ckey, bounty_amount, "Escaped NCR prisoner - [escaped_record.crime]")

	STOP_PROCESSING(SSobj, escaped_record)

/obj/structure/prison_cell/proc/insert_prisoner(mob/living/carbon/human/prisoner, datum/prisoner_record/new_record)
	if(!istype(prisoner))
		return FALSE

	prisoner_ckey = prisoner.ckey
	prisoner_name = prisoner.real_name
	record = new_record
	sentence_end_time = world.time + (new_record.sentence_minutes * 1 MINUTES)

	prisoner.forceMove(loc)

	locked = TRUE

	to_chat(prisoner, span_userdanger("You have been locked in the prison cell!"))
	to_chat(prisoner, span_notice("Sentence: [new_record.sentence_minutes] minutes for [new_record.crime]."))
	to_chat(prisoner, span_notice("Click on the cell to see escape options."))

	START_PROCESSING(SSobj, src)

	return TRUE

/obj/structure/prison_cell/process()
	if(!prisoner_ckey || !record)
		return PROCESSING_KILL

	record.time_served += 1 / 60

	if(world.time >= sentence_end_time)
		release_prisoner()
		return PROCESSING_KILL

	if(record.time_served >= record.sentence_minutes * 0.67 && record.escape_attempts == 0)
		record.sentence_minutes = record.sentence_minutes * 0.67
		sentence_end_time = world.time + ((record.sentence_minutes - record.time_served) * 1 MINUTES)

		var/mob/prisoner = get_mob_by_ckey(prisoner_ckey)
		if(prisoner)
			to_chat(prisoner, span_notice("Good behavior reduction applied."))

/obj/structure/prison_cell/proc/release_prisoner()
	var/mob/prisoner = get_mob_by_ckey(prisoner_ckey)

	if(prisoner)
		locked = FALSE
		exit_cell(prisoner)
		to_chat(prisoner, span_notice("You have served your sentence. You are free to go."))

	record.status = NCR_PRISONER_STATUS_RELEASED
	GLOB.ncr_prisoners -= record
	STOP_PROCESSING(SSobj, record)

/obj/structure/prison_cell/Destroy()
	if(prisoner_ckey)
		var/mob/prisoner = get_mob_by_ckey(prisoner_ckey)
		if(prisoner && prisoner.loc == loc)
			post_escape(prisoner)
	return ..()

/obj/structure/prison_cell/proc/is_ncr_law_enforcement(mob/user)
	if(!user.mind || !user.mind.assigned_role)
		return FALSE
	return user.mind.assigned_role in list("NCR Trooper", "NCR Sergeant", "NCR Lieutenant", "NCR Captain", "NCR Ranger", "Veteran Ranger", "NCR Military Police")
