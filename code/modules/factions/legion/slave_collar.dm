// Legion Slave Collar
// Explosive collar with tracking and shock functions

/obj/item/slave_collar
	name = "slave collar"
	desc = "A thick metal collar with an explosive charge. Used by the Legion to ensure obedience."
	icon = 'icons/obj/clothing/neck.dmi'
	icon_state = "slave_collar"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_NECK

	var/armed = FALSE
	var/detonation_code = ""
	var/shock_level = 1
	var/mob/living/carbon/human/wearer = null
	var/datum/mind/owner_mind = null
	var/range_limit = SLAVE_COLLAR_RANGE
	var/time_until_freedom = 0
	var/freedom_timer_id = null
	var/last_owner_loc = null

/obj/item/slave_collar/Initialize()
	. = ..()
	detonation_code = "[rand(100, 999)]"

/obj/item/slave_collar/Destroy()
	if(wearer)
		if(armed)
			detonate()
		else
			wearer.visible_message(span_notice("[wearer]'s slave collar falls off."))
		wearer = null
	if(freedom_timer_id)
		deltimer(freedom_timer_id)
		freedom_timer_id = null
	return ..()

/obj/item/slave_collar/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_NECK && istype(user, /mob/living/carbon/human))
		wearer = user
		RegisterSignal(wearer, COMSIG_PARENT_QDELETING, .proc/on_wearer_deleted)

/obj/item/slave_collar/dropped(mob/user)
	. = ..()
	if(wearer)
		UnregisterSignal(wearer, COMSIG_PARENT_QDELETING)
		wearer = null

/obj/item/slave_collar/proc/on_wearer_deleted()
	wearer = null

/obj/item/slave_collar/proc/arm(mob/user)
	if(armed)
		return FALSE
	if(!wearer)
		return FALSE

	armed = TRUE
	wearer.visible_message(span_danger("[wearer]'s slave collar clicks and arms itself!"))
	playsound(src, 'sound/weapons/armbomb.ogg', 50, 1)
	start_freedom_timer()
	return TRUE

/obj/item/slave_collar/proc/start_freedom_timer()
	if(freedom_timer_id)
		deltimer(freedom_timer_id)
	time_until_freedom = SLAVE_MAX_ENSLAVEMENT_TIME
	freedom_timer_id = addtimer(CALLBACK(src, .proc/auto_release), SLAVE_MAX_ENSLAVEMENT_TIME, TIMER_STOPPABLE)

/obj/item/slave_collar/proc/auto_release()
	if(!wearer || !armed)
		return

	wearer.visible_message(span_notice("[wearer]'s slave collar beeps and falls off, releasing them."))
	armed = FALSE
	var/obj/item/slave_collar/collar = wearer.get_item_by_slot(ITEM_SLOT_NECK)
	if(collar)
		wearer.dropItemToGround(collar)
		collar.wearer = null

	for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
		if(entry.slave_ckey == wearer.ckey)
			entry.status = "freed"
			break

/obj/item/slave_collar/proc/detonate()
	if(!wearer)
		return

	wearer.visible_message(span_userdanger("[wearer]'s slave collar explodes!"))
	playsound(src, 'sound/effects/explosion1.ogg', 100, 1)

	var/turf/T = get_turf(wearer)
	explosion(T, 0, 0, 2, 3)

	if(wearer)
		wearer.gib()

	for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
		if(entry.slave_ckey == wearer?.ckey)
			entry.status = "dead"
			break

	qdel(src)

/obj/item/slave_collar/proc/shock(mob/user, level)
	if(!wearer || !armed)
		return

	var/stun_duration = 5 * level
	wearer.visible_message(span_danger("[wearer]'s slave collar shocks them!"))
	playsound(src, 'sound/effects/sparks4.ogg', 50, 1)

	wearer.Stun(stun_duration)
	wearer.adjustStaminaLoss(30 * level)

	for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
		if(entry.slave_ckey == wearer.ckey)
			if(entry.obedience)
				entry.obedience.on_shock()
			break

/obj/item/slave_collar/proc/remove(mob/user)
	if(!wearer)
		return FALSE

	if(!user || !user.mind)
		return FALSE

	var/skill_level = 0
	if(user.mind && user.mind.active_skills)
		skill_level = user.mind.active_skills["engineering"] || 0

	if(user.mind.assigned_role in list("Brotherhood Scribe", "Brotherhood Knight", "Brotherhood Paladin"))
		skill_level += 10

	if(skill_level < 15)
		to_chat(user, span_warning("You don't have the engineering skill to remove this safely."))
		return FALSE

	to_chat(user, span_notice("You begin carefully removing the collar... This will take 2 minutes."))

	if(do_after(user, 120, target = wearer))
		if(prob(40))
			to_chat(user, span_userdanger("The collar malfunctions!"))
			detonate()
			return FALSE

		wearer.visible_message(span_notice("[user] successfully removes [wearer]'s slave collar."))
		armed = FALSE

		var/obj/item/slave_collar/collar = wearer.get_item_by_slot(ITEM_SLOT_NECK)
		if(collar)
			wearer.dropItemToGround(collar)
			collar.wearer = null

		for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
			if(entry.slave_ckey == wearer.ckey)
				entry.status = "freed"
				break

		adjust_karma(user.ckey, KARMA_REMOVE_COLLAR)
		return TRUE

	return FALSE

/obj/item/slave_collar/attack_self(mob/user)
	if(!user.mind)
		return

	if(user.mind.assigned_role in list("Legion Centurion", "Legion Legate"))
		var/choice = input(user, "Collar Management", "Slave Collar") as null|anything in list("Shock", "Check Timer", "Detonate (CODE REQUIRED)")
		if(!choice)
			return

		switch(choice)
			if("Shock")
				var/level = input(user, "Shock Level (1-3)", "Shock Level") as num
				level = clamp(round(level), 1, 3)
				shock(user, level)
			if("Check Timer")
				var/time_left = time2text(time_until_freedom, "mm:ss")
				to_chat(user, span_notice("Time until automatic release: [time_left]"))
			if("Detonate (CODE REQUIRED)")
				var/code = input(user, "Enter detonation code:", "Detonate Collar") as text
				if(code == detonation_code)
					var/confirm = alert(user, "This will KILL the wearer. Are you sure?", "Confirm Detonation", "Yes", "No")
					if(confirm == "Yes")
						message_admins("[key_name(user)] detonated [key_name(wearer)]'s slave collar.")
						detonate()
				else
					to_chat(user, span_warning("Incorrect code."))
	else
		to_chat(user, span_warning("You cannot use this collar."))

/obj/item/slave_collar/examine(mob/user)
	. = ..()
	if(armed)
		. += span_danger("It is armed and will explode if tampered with improperly.")
		if(time_until_freedom > 0)
			. += span_notice("Time until automatic release: [time2text(time_until_freedom, "mm:ss")]")

// ============ SLAVE COLLAR REMOVER ============

/obj/item/slave_collar_remover
	name = "collar removal kit"
	desc = "A kit containing tools for safely removing slave collars."
	icon = 'icons/obj/tools.dmi'
	icon_state = "collar_kit"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/slave_collar_remover/attack(mob/living/target, mob/living/user)
	if(!istype(target, /mob/living/carbon/human))
		return ..()

	var/obj/item/slave_collar/collar = target.get_item_by_slot(ITEM_SLOT_NECK)
	if(!istype(collar))
		to_chat(user, span_warning("[target] is not wearing a slave collar."))
		return

	collar.remove(user)

// ============ SLAVE CLOTHING ============

/obj/item/clothing/under/slave
	name = "slave rags"
	desc = "Rough, uncomfortable clothing for slaves."
	icon_state = "slave_rags"
	has_sensor = 0
	armor = list("melee" = 0, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 0, "acid" = 0)
