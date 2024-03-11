/datum/antagonist/collector
	name = "Contraband Collector"
	show_in_antagpanel = FALSE
	show_name_in_check_antagonists = FALSE
	blacklisted_quirks = list() // no blacklist, these guys are harmless

TYPE_PROC_REF(/datum/antagonist/collector, forge_objectives)()
	var/datum/objective/hoard/collector/O = new
	O.owner = owner
	O.find_target()
	objectives += O

/datum/antagonist/collector/on_gain()
	forge_objectives()
	. = ..()

/datum/antagonist/collector/greet()
	to_chat(owner, "<B>You are a contraband collector!</B>")
	owner.announce_objectives()
