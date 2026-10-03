/**
 * A lightweight social "party" grouping, formed by inviting nearby living mobs.
 * The leader's Charisma determines both how many people can follow them, and the
 * strength of the leadership buff radiated to members who stay near them.
 */
/datum/party
	var/mob/living/leader
	var/list/mob/living/members = list()
	/// Currently-radiated leadership aura. Swappable by the leader via set_party_aura() once they've unlocked more than the default Vanguard.
	var/datum/party_aura/aura = new /datum/party_aura/vanguard()
	/// world.time deadline until which Rally Cry's temporary tier boost applies to every in-range member.
	var/rally_cry_pulse_until = 0
	/// world.time deadline before Rally Cry can be used again.
	var/rally_cry_cooldown_until = 0

/datum/party/New(mob/living/starting_leader)
	. = ..()
	leader = starting_leader
	members += starting_leader
	starting_leader.party = src
	starting_leader.apply_status_effect(STATUS_EFFECT_PARTY_FRICTION)
	add_verb(starting_leader, /mob/living/proc/kick_from_party)
	add_verb(starting_leader, /mob/living/proc/leave_party)
	add_verb(starting_leader, /mob/living/proc/set_party_aura)
	add_verb(starting_leader, /mob/living/proc/party_rally_cry)

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
		remove_verb(member, /mob/living/proc/set_party_aura)
		remove_verb(member, /mob/living/proc/party_rally_cry)
		member.remove_status_effect(STATUS_EFFECT_PARTY_FRICTION)
		leader = length(members) ? members[1] : null
		if(leader)
			add_verb(leader, /mob/living/proc/kick_from_party)
			add_verb(leader, /mob/living/proc/set_party_aura)
			add_verb(leader, /mob/living/proc/party_rally_cry)
			leader.apply_status_effect(STATUS_EFFECT_PARTY_FRICTION)
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

	// get_special_charisma_party_cap() counts the leader too, so a Charisma-1/2 mob with a cap of 1 has no room for anyone - reject before ever bothering a nearby target with a doomed invite.
	var/cap = party ? party.get_cap() : get_special_charisma_party_cap()
	var/current_count = party ? length(party.members) : 1
	if(current_count >= cap)
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

	// Re-check the cap with the pre-accept math (not party.get_cap(), since no party may exist yet) BEFORE creating one, so a cap that's since been exceeded never leaves behind an orphaned leader-only party.
	cap = party ? party.get_cap() : get_special_charisma_party_cap()
	current_count = party ? length(party.members) : 1
	if(current_count >= cap)
		to_chat(src, span_warning("You don't have the charisma to lead any more people!"))
		return

	if(!party)
		new /datum/party(src)
	party.add_member(chosen)
	to_chat(src, span_notice("[chosen] has joined your party!"))

// Real verb (not add_verb()'d) since it's an innate low-Charisma ability, not something tied to leading a party - everyone has access to it, but only low-CHA mobs get anything out of using it.
/mob/living/verb/intimidating_presence()
	set name = "Intimidating Presence"
	set desc = "Let your unsettling demeanor wash over everyone nearby, rattling and slowing them down for a while."
	set category = "Party"

	var/tier = get_special_low_charisma_intimidation_tier()
	if(tier <= 0)
		to_chat(src, span_warning("You're too personable for anyone to find you unsettling."))
		return
	if(world.time < intimidate_cooldown_until)
		to_chat(src, span_warning("You need to wait [round((intimidate_cooldown_until - world.time) / 10)] more seconds before unsettling anyone again!"))
		return

	var/list/mob/living/targets = list()
	for(var/mob/living/target in oview(5, src))
		if(target == src || target.stat || (party && (target in party.members)))
			continue
		targets += target

	if(!length(targets))
		to_chat(src, span_warning("There's nobody nearby to unsettle."))
		return

	var/duration = 4 SECONDS + (tier * 2 SECONDS)
	intimidate_cooldown_until = world.time + (30 SECONDS - (tier * 5 SECONDS))
	visible_message(span_warning("[src] fixes everyone nearby with an unsettling glare!"), span_notice("You let your unnerving presence wash over everyone nearby!"))
	for(var/mob/living/target in targets)
		to_chat(target, span_userdanger("[src]'s presence rattles you, slowing your movements!"))
		target.apply_status_effect(STATUS_EFFECT_INTIMIDATED, duration, src)
	to_chat(src, span_notice("[length(targets)] nearby [length(targets) == 1 ? "person flinches" : "people flinch"] away from you."))

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

/mob/living/proc/set_party_aura()
	set name = "Set Party Aura"
	set desc = "Choose which leadership aura your party radiates."
	set category = "Party"

	if(!party || party.leader != src)
		to_chat(src, span_warning("You aren't leading a party!"))
		return

	var/tier = get_special_charisma_party_buff_tier()
	var/list/unlocked = list()
	for(var/datum/party_aura/aura_type as anything in subtypesof(/datum/party_aura))
		if(initial(aura_type.required_tier) <= tier)
			unlocked[initial(aura_type.name)] = aura_type

	var/choice = input(src, "Choose your party's aura!", "Party Aura") as null|anything in unlocked
	if(!choice || !party || party.leader != src)
		return

	var/datum/party_aura/new_aura_type = unlocked[choice]
	if(new_aura_type == party.aura.type)
		return

	for(var/mob/living/member in party.members)
		party.aura.remove(member)
	party.aura = new new_aura_type()
	to_chat(src, span_notice("Your party now radiates the [party.aura.name] aura!"))

/mob/living/proc/party_rally_cry()
	set name = "Rally Cry"
	set desc = "Pulse a stronger version of your party aura to everyone nearby for a short time."
	set category = "Party"

	if(!party || party.leader != src)
		to_chat(src, span_warning("You aren't leading a party!"))
		return

	var/tier = get_special_charisma_party_buff_tier()
	if(tier <= 0)
		to_chat(src, span_warning("You don't have the charisma to rally anyone!"))
		return
	if(world.time < party.rally_cry_cooldown_until)
		to_chat(src, span_warning("You need to wait [round((party.rally_cry_cooldown_until - world.time) / 10)] more seconds before rallying again!"))
		return

	visible_message(span_notice("[src] rallies the party!"), span_notice("You rally your party, boosting the [party.aura.name] aura for everyone nearby!"))
	party.rally_cry_pulse_until = world.time + (6 SECONDS + (tier * 1 SECONDS))
	party.rally_cry_cooldown_until = world.time + (60 SECONDS - (tier * 4 SECONDS))
	for(var/mob/living/member in (party.members - src))
		var/datum/status_effect/party_rally/rally = member.has_status_effect(STATUS_EFFECT_PARTY_RALLY)
		if(rally?.buffed)
			to_chat(member, span_notice("You feel a surge of extra strength as [src] rallies the party!"))

/// Surfaces live party info in the statpanel: the leader sees every member's in-range status, members see whether they're currently in rally range and benefiting from the buff.
/mob/living/get_status_tab_items()
	. = ..()
	if(!party)
		return
	. += ""
	if(party.leader == src)
		var/rally_ready = world.time >= party.rally_cry_cooldown_until
		. += "Party: Leading [length(party.members)]/[party.get_cap()] member\s - [party.aura.name] aura - Rally Cry [rally_ready ? "ready" : "recharging ([round((party.rally_cry_cooldown_until - world.time) / 10)]s)"]"
		for(var/mob/living/member in (party.members - src))
			var/in_range = !QDELETED(member) && !member.stat && member.z == z && get_dist(src, member) <= 7
			. += "- [member.name][in_range ? "" : " (out of range)"]"
	else
		var/mob/living/leader = party.leader
		var/in_range = !QDELETED(leader) && !leader.stat && leader.z == z && get_dist(src, leader) <= 7
		var/datum/status_effect/party_rally/rally = has_status_effect(STATUS_EFFECT_PARTY_RALLY)
		var/rally_state = "out of range!"
		if(in_range)
			rally_state = (rally?.buffed) ? "buffed ([party.aura.name])" : "in range"
		. += "Party: Following [leader.name] ([rally_state])"

