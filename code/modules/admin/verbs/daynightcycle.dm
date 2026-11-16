/client/proc/set_daynight_phase()
	set category = "Admin.Fun"
	set desc = "Force the day/night cycle to a specific phase and freeze it there until released"
	set name = "Set Day/Night Phase"

	if(!holder || !check_rights(R_FUN))
		return

	var/list/phase_names = list(
		"Sunrise" = NIGHTCYCLE_PHASE_SUNRISE,
		"Morning" = NIGHTCYCLE_PHASE_MORNING,
		"Late Morning" = NIGHTCYCLE_PHASE_LATEMORN,
		"Daytime" = NIGHTCYCLE_PHASE_DAYTIME,
		"Afternoon" = NIGHTCYCLE_PHASE_AFTERNOON,
		"Late Afternoon" = NIGHTCYCLE_PHASE_LATEAFTERNOON,
		"Sunset" = NIGHTCYCLE_PHASE_SUNSET,
		"Full Sunset" = NIGHTCYCLE_PHASE_FULLSUNSET,
		"Nighttime" = NIGHTCYCLE_PHASE_NIGHTTIME,
	)
	var/picked = input(usr, "Pick a day/night phase to force. This freezes the cycle there until you resume it (see \"Resume Day/Night Auto-Cycle\").", "Set Day/Night Phase") as null|anything in phase_names
	if(isnull(picked))
		return

	SSnightcycle.admin_frozen = TRUE
	SSnightcycle.set_phase(phase_names[picked], announce = FALSE)
	log_admin("[key_name(usr)] forced the day/night cycle to [picked] and froze it there.")
	message_admins("[key_name_admin(usr)] forced the day/night cycle to [picked] and froze it there.")

/client/proc/resume_daynight_autocycle()
	set category = "Admin.Fun"
	set desc = "Let the day/night cycle resume following the normal station clock"
	set name = "Resume Day/Night Auto-Cycle"

	if(!holder || !check_rights(R_FUN))
		return

	if(!SSnightcycle.admin_frozen)
		to_chat(usr, span_warning("The day/night cycle isn't frozen."))
		return

	SSnightcycle.admin_frozen = FALSE
	log_admin("[key_name(usr)] resumed the normal day/night cycle.")
	message_admins("[key_name_admin(usr)] resumed the normal day/night cycle.")
