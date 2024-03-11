GLOBAL_LIST_EMPTY(traitor_classes)

/datum/traitor_class
	var/name = "Bad Coders Ltd."
	var/employer = "The Syndicate"
	var/weight = 0
	var/chaos = 0
	var/threat = 0
	var/TC = 20
	/// Minimum players for this to randomly roll via get_random_traitor_class().
	var/min_players = 0
	var/list/uplink_filters

/datum/traitor_class/New()
	..()
	if(src.type in GLOB.traitor_classes)
		qdel(src)
	else
		GLOB.traitor_classes += src.type
		GLOB.traitor_classes[src.type] = src

TYPE_PROC_REF(/datum/traitor_class, forge_objectives)(datum/antagonist/traitor/T)
	// Like the old forge_human_objectives. Makes all the objectives for this traitor class.

TYPE_PROC_REF(/datum/traitor_class, forge_single_objective)(datum/antagonist/traitor/T)
	// As forge_single_objective.

TYPE_PROC_REF(/datum/traitor_class, on_removal)(datum/antagonist/traitor/T)
	// What this does to the antag datum on removal. Called before proper removal, obviously.

TYPE_PROC_REF(/datum/traitor_class, apply_innate_effects)(mob/living/M)
	// What innate effects it should have. See: AI.

TYPE_PROC_REF(/datum/traitor_class, remove_innate_effects)(mob/living/M)
	// Cleaning up the innate effects.

TYPE_PROC_REF(/datum/traitor_class, greet)(datum/antagonist/traitor/T)
	// Message upon creation. Not necessary, but can be useful.

TYPE_PROC_REF(/datum/traitor_class, finalize_traitor)(datum/antagonist/traitor/T)
	// Finalization. Return TRUE if should play standard traitor sound/equip, return FALSE if both are special case
	return TRUE

TYPE_PROC_REF(/datum/traitor_class, clean_up_traitor)(datum/antagonist/traitor/T)
	// Any effects that need to be cleaned up if traitor class is being swapped.
	
