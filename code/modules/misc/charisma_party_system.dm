/**
 * A lightweight social "party" grouping, formed by inviting nearby living mobs.
 * The leader's Charisma determines both how many people can follow them, and the
 * strength of the leadership buff radiated to members who stay near them.
 */
/datum/party
	var/mob/living/leader
	var/list/mob/living/members = list()

/datum/party/New(mob/living/starting_leader)
	. = ..()
	leader = starting_leader
	members += starting_leader
	starting_leader.party = src
	add_verb(starting_leader, /mob/living/proc/kick_from_party)
	add_verb(starting_leader, /mob/living/proc/leave_party)

/datum/party/proc/get_cap()
	return leader.get_special_charisma_party_cap()

/datum/party/proc/add_member(mob/living/new_member)
	members += new_member
	new_member.party = src
	new_member.apply_status_effect(STATUS_EFFECT_PARTY_RALLY, leader)
	add_verb(new_member, /mob/living/proc/leave_party)
	to_chat(new_member, span_notice("You are now part of [leader]'s party. Stay near [leader.p_them()] to benefit from [leader.p_their()] leadership."))

/// Removes a member from the party. If the leader leaves, leadership passes to the next member, or the party disbands if nobody's left.
/datum/party/proc/remove_member(mob/living/member, silent = FALSE)
	if(!(member in members))
		return
	members -= member
	member.party = null
	member.remove_status_effect(STATUS_EFFECT_PARTY_RALLY)
	remove_verb(member, /mob/living/proc/leave_party)
	if(member == leader)
		remove_verb(member, /mob/living/proc/kick_from_party)
		leader = length(members) ? members[1] : null
		if(leader)
			add_verb(leader, /mob/living/proc/kick_from_party)
			to_chat(leader, span_notice("You are now the leader of the party!"))
	if(!silent)
		to_chat(member, span_warning("You are no longer part of the party."))
	if(!length(members))
		qdel(src)

// A real verb (not add_verb()'d) since it's the only entry point that creates a party in the first place - every mob needs it available from the start, not just existing leaders.
/mob/living/verb/invite_to_party()
	set name = "Invite To Party"
	set desc = "Invite a nearby player to your party. Only the party leader can invite."
	set category = "Party"

	if(party && party.leader != src)
		to_chat(src, span_warning("Only the party leader can invite new members!"))
		return

	var/cap = party ? party.get_cap() : get_special_charisma_party_cap()
	if(party && length(party.members) >= cap)
		to_chat(src, span_warning("You don't have the charisma to lead any more people!"))
		return

	var/list/possible_targets = list()
	for(var/mob/living/target in oview(src))
		if(target == src || target.stat || !target.mind || !target.client)
			continue
		if(target.party)
			continue
		possible_targets += target

	if(!length(possible_targets))
		to_chat(src, span_warning("There's nobody suitable nearby to invite."))
		return

	var/mob/living/chosen = input(src, "Choose who to invite to your party!", "Party invitation") as null|mob in possible_targets
	if(!chosen || QDELETED(chosen) || chosen.party)
		return
	if(get_dist(src, chosen) > 7)
		to_chat(src, span_warning("They've wandered too far away!"))
		return

	if(alert(chosen, "[src] invites you to join their party.", "Party invitation", "Yes", "No") != "Yes")
		to_chat(src, span_warning("[chosen] declined to join your party."))
		return
	if(QDELETED(chosen) || QDELETED(src) || chosen.party || chosen.stat)
		return

	if(!party)
		new /datum/party(src)
	if(length(party.members) >= party.get_cap())
		to_chat(src, span_warning("You don't have the charisma to lead any more people!"))
		return

	party.add_member(chosen)
	to_chat(src, span_notice("[chosen] has joined your party!"))

/mob/living/proc/leave_party()
	set name = "Leave Party"
	set desc = "Leave your current party."
	set category = "Party"

	if(!party)
		return
	party.remove_member(src)

/mob/living/proc/kick_from_party()
	set name = "Kick From Party"
	set desc = "Remove a member from your party."
	set category = "Party"

	if(!party || party.leader != src)
		to_chat(src, span_warning("You aren't leading a party!"))
		return

	var/list/kickable = party.members - src
	if(!length(kickable))
		to_chat(src, span_warning("Nobody else is in your party."))
		return

	var/mob/living/chosen = input(src, "Choose who to remove from your party!", "Kick member") as null|mob in kickable
	if(!chosen || !party || !(chosen in party.members))
		return

	to_chat(chosen, span_warning("[src] has removed you from the party."))
	party.remove_member(chosen, TRUE)
