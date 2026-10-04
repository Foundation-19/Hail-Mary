/**
 * A lightweight social "party" grouping, formed by inviting nearby living mobs.
 * The leader's Charisma determines both how many people can follow them, and the
 * strength of the leadership buff radiated to members who stay near them.
 */
/datum/party
	var/mob/living/leader
	var/list/mob/living/members = list()
	/// Currently-radiated leadership aura. Swappable by the leader via the party panel's "set_aura" action once they've unlocked more than the default Vanguard.
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
	add_verb(starting_leader, /mob/living/proc/open_party_menu)

/datum/party/proc/get_cap()
	return leader.get_special_charisma_party_cap()

/datum/party/ui_state(mob/user)
	return GLOB.party_state

/datum/party/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PartyManagement")
		ui.open()

/datum/party/ui_data(mob/user)
	var/list/data = list()
	var/is_leader = (leader == user)
	data["is_leader"] = is_leader
	data["cap"] = get_cap()
	data["aura_name"] = aura?.name

	var/list/member_list = list()
	for(var/mob/living/member in members)
		member_list += list(list(
			"ref" = REF(member),
			"name" = member.name,
			"is_leader" = (member == leader),
			"is_self" = (member == user),
		))
	data["members"] = member_list

	if(is_leader)
		var/tier = leader.get_special_charisma_party_buff_tier()
		var/list/aura_list = list()
		for(var/datum/party_aura/aura_type as anything in subtypesof(/datum/party_aura))
			aura_list += list(list(
				"type" = "[aura_type]",
				"name" = initial(aura_type.name),
				"desc" = initial(aura_type.desc),
				"required_tier" = initial(aura_type.required_tier),
				"unlocked" = (initial(aura_type.required_tier) <= tier),
				"is_current" = (aura_type == aura.type),
			))
		data["auras"] = aura_list
		data["rally_ready"] = (world.time >= rally_cry_cooldown_until)
		data["rally_cooldown_seconds"] = max(0, round((rally_cry_cooldown_until - world.time) / 10))
		data["rally_tier"] = tier
	return data

/datum/party/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	var/mob/living/user = ui.user
	switch(action)
		if("kick")
			if(leader != user)
				return
			var/mob/living/target = locate(params["ref"]) in (members - leader)
			if(!target)
				return
			to_chat(target, span_warning("[user] has removed you from the party."))
			remove_member(target, TRUE)
			. = TRUE
		if("leave")
			if(!(user in members))
				return
			remove_member(user)
			. = TRUE
		if("set_aura")
			if(leader != user)
				return
			var/datum/party_aura/new_aura_type = text2path(params["aura_type"])
			if(!ispath(new_aura_type, /datum/party_aura))
				return
			if(initial(new_aura_type.required_tier) > user.get_special_charisma_party_buff_tier())
				return
			if(new_aura_type == aura.type)
				return
			for(var/mob/living/member in members)
				aura.remove(member)
			aura = new new_aura_type()
			to_chat(user, span_notice("Your party now radiates the [aura.name] aura!"))
			. = TRUE
		if("rally_cry")
			if(leader != user)
				return
			var/tier = user.get_special_charisma_party_buff_tier()
			if(tier <= 0)
				to_chat(user, span_warning("You don't have the charisma to rally anyone!"))
				return
			if(world.time < rally_cry_cooldown_until)
				return
			user.visible_message(span_notice("[user] rallies the party!"), span_notice("You rally your party, boosting the [aura.name] aura for everyone nearby!"))
			rally_cry_pulse_until = world.time + (6 SECONDS + (tier * 1 SECONDS))
			rally_cry_cooldown_until = world.time + (60 SECONDS - (tier * 4 SECONDS))
			for(var/mob/living/member in (members - user))
				var/datum/status_effect/party_rally/rally = member.has_status_effect(STATUS_EFFECT_PARTY_RALLY)
				if(rally?.buffed)
					to_chat(member, span_notice("You feel a surge of extra strength as [user] rallies the party!"))
			. = TRUE

/datum/party/proc/add_member(mob/living/new_member)
	members += new_member
	new_member.party = src
	new_member.apply_status_effect(STATUS_EFFECT_PARTY_RALLY, leader)
	add_verb(new_member, /mob/living/proc/open_party_menu)
	to_chat(new_member, span_notice("You are now part of [leader]'s party. Stay near [leader.p_them()] to benefit from [leader.p_their()] leadership."))

/// Removes a member from the party. If the leader leaves, leadership passes to the next member, or the party disbands if nobody's left.
/datum/party/proc/remove_member(mob/living/member, silent = FALSE)
	if(!(member in members))
		return
	members -= member
	member.party = null
	member.remove_status_effect(STATUS_EFFECT_PARTY_RALLY)
	remove_verb(member, /mob/living/proc/open_party_menu)
	if(member == leader)
		member.remove_status_effect(STATUS_EFFECT_PARTY_FRICTION)
		leader = length(members) ? members[1] : null
		if(leader)
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

// Real verb (not add_verb()'d), mirroring intimidating_presence() - innate to everyone, but only high-CHA mobs get anything out of it. Doesn't discriminate party from non-party, friend from foe, same as its low-CHA counterpart.
/mob/living/verb/commanding_presence()
	set name = "Commanding Presence"
	set desc = "Let your natural authority wash over everyone nearby, rallying and quickening them for a while."
	set category = "Party"

	var/tier = get_special_high_charisma_command_tier()
	if(tier <= 0)
		to_chat(src, span_warning("You're not commanding enough for anyone to rally behind you."))
		return
	if(world.time < command_cooldown_until)
		to_chat(src, span_warning("You need to wait [round((command_cooldown_until - world.time) / 10)] more seconds before rallying anyone again!"))
		return

	var/list/mob/living/targets = list()
	for(var/mob/living/target in oview(5, src))
		if(target == src || target.stat || (party && (target in party.members)))
			continue
		targets += target

	if(!length(targets))
		to_chat(src, span_warning("There's nobody nearby to rally."))
		return

	var/duration = 4 SECONDS + (tier * 2 SECONDS)
	command_cooldown_until = world.time + (30 SECONDS - (tier * 5 SECONDS))
	visible_message(span_notice("[src] carries [src.p_them()]self with unshakable authority!"), span_notice("You let your commanding presence wash over everyone nearby!"))
	for(var/mob/living/target in targets)
		to_chat(target, span_nicegreen("[src]'s presence bolsters you, quickening your step!"))
		target.apply_status_effect(STATUS_EFFECT_INSPIRED, duration, src)
	to_chat(src, span_notice("[length(targets)] nearby [length(targets) == 1 ? "person stands" : "people stand"] a little taller."))

// Single party-tab entry point for all members (leader or not) - every other party action (kick/leave/aura/rally) lives inside the panel itself.
/mob/living/proc/open_party_menu()
	set name = "Party"
	set desc = "Open your party roster and (if leading) manage members, aura, and Rally Cry."
	set category = "Party"

	if(!party)
		to_chat(src, span_warning("You aren't part of a party!"))
		return
	party.ui_interact(src)

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

