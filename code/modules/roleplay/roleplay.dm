// This module adds faction reputation, karma, backgrounds, and other RP features

#define ROLEPLAY_MODULE

// Forward declarations for trigger procs
/proc/on_player_death(mob/living/victim, mob/attacker)
	if(!victim || !victim.lastattackerckey)
		return
	handle_death_reputation(victim, FALSE)

/proc/on_player_heal(mob/living/carbon/target, mob/healer, healing_amount)
	if(!healer || !target || healer == target)
		return
	if(!healer.ckey)
		return
	
	// Determine if target is player or NPC
	var/karma_action = target.client ? "heal_player" : "heal_npc"
	var/reason = "Healed [target.real_name]"
	
	// Check if using a stimpak for bonus
	if(istype(healer.get_active_held_item(), /obj/item/reagent_containers/hypospray/medipen/stimpak) || istype(healer.get_active_held_item(), /obj/item/reagent_containers/hypospray/medipen))
		karma_action = "use_stimpak_other"
		reason = "Used stimpak on [target.real_name]"
	
	modify_karma_by_action(healer.ckey, karma_action, null, reason)

/proc/on_mission_complete(ckey, faction_id, success = TRUE)
/proc/on_faction_donate(ckey, faction_id, item_value = 0)
/proc/on_civilian_defended(ckey)

GLOBAL_DATUM_INIT(roleplay_system, /datum/roleplay_system, new)

/datum/roleplay_system
	var/initialized = FALSE

/datum/roleplay_system/New()
	. = ..()
	initialize_factions()

/datum/roleplay_system/proc/initialize_factions()
	// Factions are loaded from faction_definitions.dm via init_factions()
	// This just marks the system as ready
	initialized = TRUE
