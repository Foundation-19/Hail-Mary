/mob/living/carbon/human/resist_a_rest(automatic = FALSE, ignoretimer = FALSE)
	if(!resting || stat || (combat_flags & COMBAT_FLAG_RESISTING_REST))
		if(!automatic && resting && !stat && (combat_flags & COMBAT_FLAG_RESISTING_REST))
			to_chat(src, span_notice("You're already trying to get up!"))
		return FALSE
	if(ignoretimer)
		set_resting(FALSE, FALSE)
		return TRUE
	if(!lying)				//if they're in a chair or something they don't need to force themselves off the ground.
		set_resting(FALSE, FALSE)
		return TRUE
	else if(!CHECK_MOBILITY(src, MOBILITY_RESIST))
		if(!automatic)
			to_chat(src, span_warning("You are unable to stand up right now."))
		return FALSE
	else
		var/totaldelay = 3 //A little bit less than half of a second as a baseline for getting up from a rest
		if(IS_STAMCRIT(src))
			to_chat(src, "<span class='warning'>You're too exhausted to get up!")
			return FALSE
		combat_flags |= COMBAT_FLAG_RESISTING_REST
		var/health_deficiency = max((maxHealth - (health - getStaminaLoss()))*0.5, 0)
		if(!has_gravity())
			health_deficiency = health_deficiency*0.2
		totaldelay += min(health_deficiency, GETUP_DELAY_CAP) // capped - see GETUP_DELAY_CAP
		var/standupwarning = "%SELF_NAME% and everyone around them should probably yell at the dev team"
		switch(health_deficiency)
			if(-INFINITY to 10)
				standupwarning = "%SELF_NAME% stands right up!"
			if(10 to 35)
				standupwarning = "%SELF_NAME% tries to stand up."
			if(35 to 60)
				standupwarning = "%SELF_NAME% slowly pushes [p_them()]self upright."
			if(60 to 80)
				standupwarning = "%SELF_NAME% weakly attempts to stand up."
			if(80 to INFINITY)
				standupwarning = "%SELF_NAME% struggles to stand up."
		var/usernotice = automatic ? span_notice("You are now getting up. (Auto)") : span_notice("You are now getting up.")
		visible_message(span_notice("[standupwarning]"), usernotice, vision_distance = 5, visible_message_flags = ANONYMIZE_NAMES)
		//resting blocks MOBILITY_MOVE, so any loc change here is external (zero-g drift/bumps, being dragged) - don't let that spuriously restart the attempt
		if(do_after(src, totaldelay, target = src, required_mobility_flags = MOBILITY_RESIST, allow_movement = TRUE))
			set_resting(FALSE, TRUE)

			combat_flags &= ~COMBAT_FLAG_RESISTING_REST
			return TRUE
		else
			combat_flags &= ~COMBAT_FLAG_RESISTING_REST
			if(resting)		//we didn't shove ourselves up or something
				visible_message(span_notice("[src] falls right back down."), span_notice("You fall right back down."))
				if(has_gravity())
					playsound(src, "bodyfall", 20, 1)
			return FALSE
