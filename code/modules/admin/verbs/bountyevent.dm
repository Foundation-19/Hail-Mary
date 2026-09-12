/client/proc/force_bounty_event(obj/machinery/bounty_board/B in GLOB.bounty_boards)
	set category = "Fun"
	set desc = "Force an event bounty contract onto a chosen board"
	set name = "Force Bounty Event"

	if(!holder || !check_rights(R_FUN))
		return

	var/list/event_types = subtypesof(/datum/bounty_contract/event)
	var/picked = input(usr, "Pick an event contract to post to [B.name]", "Force Bounty Event") as null|anything in event_types
	if(!picked)
		return

	if(B.post_event_contract(picked))
		log_admin("[key_name(usr)] forced event bounty [picked] onto [B] at [AREACOORD(B)]")
		message_admins("[key_name_admin(usr)] forced event bounty [picked] onto [B] at [AREACOORD(B)]")
	else
		to_chat(usr, span_warning("Failed to post that event contract."))
