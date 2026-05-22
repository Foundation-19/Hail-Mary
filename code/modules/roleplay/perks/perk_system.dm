// MAX_PERK_POINTS defined in code/__DEFINES/roleplay_constants.dm

// Map of perk_id to conflicting quirk trait
GLOBAL_LIST_INIT(perk_quirk_conflicts, list(
	"iron_fist" = TRAIT_IRONFIST,
	"big_leagues" = TRAIT_BIG_LEAGUES,
	"light_step" = TRAIT_LIGHT_STEP,
	"chemist" = TRAIT_CHEMWHIZ,
	"steelfist" = TRAIT_STEELFIST
))

// Check if player has conflicting quirk trait
/proc/has_quirk_conflict(mob/living/carbon/human/user, perk_id)
	if(!istype(user))
		return FALSE
	var/conflicting_trait = GLOB.perk_quirk_conflicts[perk_id]
	if(conflicting_trait && HAS_TRAIT(user, conflicting_trait))
		return TRUE
	return FALSE

// Check if player has reached soft cap (for elite perks only)
/proc/has_reached_perk_cap(ckey)
	var/points = get_total_perk_points(ckey)
	return points >= MAX_PERK_POINTS

// Check if player can unlock a specific perk
/proc/can_unlock_perk(mob/living/carbon/human/user, perk_id)
	if(!istype(user))
		return FALSE

	var/ckey = user.ckey
	var/datum/perk/perk = get_perk_info(perk_id)
	if(!perk)
		return FALSE

	// Check if already has perk
	if(has_perk(ckey, perk_id))
		return FALSE

	// Check for quirk conflicts
	if(has_quirk_conflict(user, perk_id))
		return FALSE

	// Check if has enough points
	var/available_points = get_perk_points(ckey)
	if(available_points <= 0)
		return FALSE

	// Check soft cap - regular perks (tier 1) blocked if at cap
	if(has_reached_perk_cap(ckey) && perk.tier <= 1)
		return FALSE

	// Check SPECIAL stat requirement
	switch(perk.special_stat)
		if("S")
			if(user.special_s < perk.special_min)
				return FALSE
		if("P")
			if(user.special_p < perk.special_min)
				return FALSE
		if("E")
			if(user.special_e < perk.special_min)
				return FALSE
		if("C")
			if(user.special_c < perk.special_min)
				return FALSE
		if("I")
			if(user.special_i < perk.special_min)
				return FALSE
		if("A")
			if(user.special_a < perk.special_min)
				return FALSE
		if("L")
			if(user.special_l < perk.special_min)
				return FALSE

	// Check prerequisite perk
	if(perk.requires_perk)
		if(!has_perk(ckey, perk.requires_perk))
			return FALSE

	return TRUE

// Grant a perk to a player
/proc/grant_perk(mob/living/carbon/human/user, perk_id)
	if(!istype(user))
		return FALSE

	var/ckey = user.ckey
	var/datum/perk/perk = get_perk_info(perk_id)
	if(!perk)
		return FALSE

	if(!can_unlock_perk(user, perk_id))
		return FALSE

	// Spend point and add perk to DB
	if(!spend_perk_point(ckey))
		return FALSE

	if(!grant_perk_db(ckey, perk_id))
		// Refund point if DB failed
		add_perk_point(ckey, 1)
		return FALSE

	// Apply the perk's trait
	if(perk.trait_given)
		ADD_TRAIT(user, perk.trait_given, "perk")
	// Also apply the corresponding quirk trait so game code recognizes it
	var/quirk_trait = GLOB.perk_quirk_conflicts[perk_id]
	if(quirk_trait)
		ADD_TRAIT(user, quirk_trait, "perk")

	to_chat(user, span_notice("You unlocked [perk.name]!"))
	to_chat(user, span_notice(perk.desc))

	return TRUE

// Remove a perk from a player
/proc/remove_perk(mob/living/carbon/human/user, perk_id)
	if(!istype(user))
		return FALSE

	var/ckey = user.ckey
	var/datum/perk/perk = get_perk_info(perk_id)
	if(!perk)
		return FALSE

	if(!has_perk(ckey, perk_id))
		return FALSE

	// Remove from DB
	if(!remove_perk_db(ckey, perk_id))
		return FALSE

	// Refund point
	add_perk_point(ckey, 1)

	// Remove the perk's trait
	if(perk.trait_given)
		REMOVE_TRAIT(user, perk.trait_given, "perk")
	var/quirk_trait = GLOB.perk_quirk_conflicts[perk_id]
	if(quirk_trait)
		REMOVE_TRAIT(user, quirk_trait, "perk")

	to_chat(user, span_warning("You have removed [perk.name]."))

	return TRUE

// Load perks for a player when they spawn/login
/proc/load_player_perks(mob/living/carbon/human/user)
	if(!istype(user) || !user.ckey)
		return

	var/ckey = user.ckey
	var/list/perks = get_active_perks(ckey)

	for(var/perk_id in perks)
		var/datum/perk/perk = get_perk_info(perk_id)
		if(perk && perk.trait_given)
			ADD_TRAIT(user, perk.trait_given, "perk")
		var/quirk_trait = GLOB.perk_quirk_conflicts[perk_id]
		if(quirk_trait)
			ADD_TRAIT(user, quirk_trait, "perk")

// Get all perks organized by SPECIAL stat
/proc/get_perks_by_stat(special_stat)
	var/list/perks = list()
	for(var/id in GLOB.perk_datums)
		var/datum/perk/P = GLOB.perk_datums[id]
		if(P.special_stat == special_stat)
			perks += id
	return perks

// Get list of perks the player can currently unlock
/proc/get_available_perks(mob/living/carbon/human/user)
	if(!istype(user))
		return list()

	var/list/available = list()

	for(var/id in GLOB.perk_datums)
		if(can_unlock_perk(user, id))
			available += id

	return available

// Get all perks the player qualifies for (meets stat reqs but may not have prereqs or points)
/proc/get_qualifiable_perks(mob/living/carbon/human/user)
	if(!istype(user))
		return list()

	var/list/qualifiable = list()

	for(var/id in GLOB.perk_datums)
		var/datum/perk/P = GLOB.perk_datums[id]
		if(P.special_stat)
			switch(P.special_stat)
				if("S")
					if(user.special_s >= P.special_min)
						qualifiable += id
				if("P")
					if(user.special_p >= P.special_min)
						qualifiable += id
				if("E")
					if(user.special_e >= P.special_min)
						qualifiable += id
				if("C")
					if(user.special_c >= P.special_min)
						qualifiable += id
				if("I")
					if(user.special_i >= P.special_min)
						qualifiable += id
				if("A")
					if(user.special_a >= P.special_min)
						qualifiable += id
				if("L")
					if(user.special_l >= P.special_min)
						qualifiable += id

	return qualifiable

// Update perks when SPECIAL stats change
/mob/living/carbon/human/proc/update_perk_traits()
	if(!ckey)
		return

	// Check if any perks need to be removed due to stat changes
	var/list/perks = get_active_perks(ckey)
	for(var/perk_id in perks)
		var/datum/perk/P = get_perk_info(perk_id)
		if(!P || !P.special_stat)
			continue

		var/stat_val = 0
		switch(P.special_stat)
			if("S") stat_val = special_s
			if("P") stat_val = special_p
			if("E") stat_val = special_e
			if("C") stat_val = special_c
			if("I") stat_val = special_i
			if("A") stat_val = special_a
			if("L") stat_val = special_l

		// If no longer meets stat requirement, remove trait (but keep perk record)
		if(stat_val < P.special_min)
			if(P.trait_given && HAS_TRAIT(src, P.trait_given))
				REMOVE_TRAIT(src, P.trait_given, "perk")
				to_chat(src, span_warning("You no longer meet the requirements for [P.name]. The perk is temporarily disabled."))
		else
			// Re-apply if we meet requirements again
			if(P.trait_given && !HAS_TRAIT(src, P.trait_given))
				ADD_TRAIT(src, P.trait_given, "perk")
				to_chat(src, span_notice("You now meet the requirements for [P.name] again."))
