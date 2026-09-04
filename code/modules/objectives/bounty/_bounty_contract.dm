/*
	Fallout 13 Faction Bounty Board (v1)

	Deliberately its own system, not a reskin of vanilla's cargo /datum/bounty (which is
	shuttle/dock-based) or the old QuestMachines /datum/bounty_quest (pod-turf based).
	Turn-in is direct: walk up to a /obj/machinery/bounty_board and hand over the item.
	Credit is per-delivery (whoever hands in the item completes it, no per-player tracking).
	Reward is a loot crate plus persistent-for-the-round points on the deliverer's mind,
	which feed the round-end bounty report/greentext threshold (bounty_roundend.dm).
*/

// Contract pool GLOB lists (universal + one per faction) are declared and populated together
// in bounty_content.dm via GLOBAL_LIST_INIT, alongside the actual bounty content.

/// Returns the faction-locked pool list for a FACTION_* string, or null if that faction has no pool.
/proc/get_bounty_pool_for_faction(faction)
	switch(faction)
		if(FACTION_BROTHERHOOD)
			return GLOB.bounty_contract_pool_bos
		if(FACTION_LEGION)
			return GLOB.bounty_contract_pool_legion
		if(FACTION_NCR)
			return GLOB.bounty_contract_pool_ncr
		if(FACTION_EASTWOOD)
			return GLOB.bounty_contract_pool_town
	return null

// War factions capable of having a rival this round. The town/Eastwood is deliberately excluded -
// it's a neutral trading settlement, not a combatant, so its contracts never trigger a rival hit.
#define BOUNTY_RIVAL_CANDIDATE_FACTIONS list(FACTION_BROTHERHOOD, FACTION_LEGION, FACTION_NCR)

/// Living, faction-employed player counts per FACTION_* among BOUNTY_RIVAL_CANDIDATE_FACTIONS.
/proc/get_bounty_faction_populations()
	var/list/counts = list()
	for(var/mob/living/M as anything in GLOB.player_list)
		if(!M.mind || !M.mind.assigned_role)
			continue
		var/datum/job/job = SSjob.GetJob(M.mind.assigned_role)
		if(!job || !(job.faction in BOUNTY_RIVAL_CANDIDATE_FACTIONS))
			continue
		counts[job.faction] = (counts[job.faction] || 0) + 1
	return counts

/// Returns the FACTION_* that loses standing when the given faction gains it, or null if none.
/// Dynamic per-round rather than a fixed pair: only the two most populated war factions right
/// now are treated as rivals, so a nearly-empty faction doesn't drag another's reputation down,
/// and a map that's shifted to e.g. NCR vs BoS gets that rivalry without any code changes.
/proc/get_rival_faction(faction)
	if(!(faction in BOUNTY_RIVAL_CANDIDATE_FACTIONS))
		return null
	var/list/counts = get_bounty_faction_populations()
	if(length(counts) < 2)
		return null // fewer than two war factions are actually active - no rivalry to speak of
	var/first_faction
	var/first_count = -1
	for(var/f in counts)
		if(counts[f] > first_count)
			first_faction = f
			first_count = counts[f]
	var/second_faction
	var/second_count = -1
	for(var/f in counts)
		if(f == first_faction)
			continue
		if(counts[f] > second_count)
			second_faction = f
			second_count = counts[f]
	if(faction == first_faction)
		return second_faction
	if(faction == second_faction)
		return first_faction
	return null

/datum/bounty_contract
	/// Short board listing name, e.g. "Deathclaw Cull".
	var/name = "Bounty"
	/// Who's asking, shown in the board UI.
	var/employer = "Unknown"
	/// Flavor text for why they want it.
	var/flavor = ""
	/// null = universal (any board can roll it). Else one of the FACTION_* defines - only that
	/// faction's board (or a board with free_access to that faction's pool) can roll it.
	var/faction = null
	/// The item type required. Kept single-type by design - variety in a faction's needs comes
	/// from rolling multiple different contracts, not from one contract needing several types.
	var/required_type
	var/required_count = 1
	var/delivered_count = 0
	/// If FALSE, only the exact required_type counts (no subtypes).
	var/include_subtypes = TRUE
	/// Optional second item type for "bring A and B" contracts. Null (default) means single-item,
	/// same as before - set this on a contract to turn it into a two-part delivery.
	var/required_type_2
	var/required_count_2 = 1
	var/delivered_count_2 = 0
	var/include_subtypes_2 = TRUE
	/// If required_type is a reagent container, the reagent it must actually be full of (e.g.
	/// /datum/reagent/water for waterbottle contracts) - stops empty bottles or ones topped up
	/// with something else from counting. Null = no reagent check (default, most contracts).
	var/required_reagent_type
	/// Minimum fraction (0-1) of the container's max volume that must be required_reagent_type.
	var/required_reagent_fill = 0.9
	var/reward_crate_type = /obj/structure/closet/crate/bounty/melee_low
	var/reward_points = 10
	var/claimed = FALSE
	/// Standing with this contract's faction (see /datum/mind/bounty_reputation) needed to get
	/// reward_crate_type. Below this, the deliverer gets fallback_crate_type instead - a faction
	/// isn't going to hand over guns/power armor to someone it doesn't know yet.
	var/min_reputation = 0
	/// Reward given in place of reward_crate_type when the deliverer hasn't earned min_reputation.
	var/fallback_crate_type = /obj/structure/closet/crate/bounty/supplies
	/// Standing gained with this contract's faction on completion. Universal/crossfaction
	/// contracts still grant this, credited to whichever board's faction it was turned in at.
	var/reputation_gain = 1
	/// If TRUE, this contract is small/deniable enough that the rival faction never hears about
	/// it - skips the usual rival reputation hit entirely. For "it's fine, they'll never notice"
	/// flavored jobs rather than anything that would show up on the rival's radar.
	var/quiet_dealing = FALSE

/datum/bounty_contract/proc/applies_to(obj/item/I)
	if(claimed || !required_type || !istype(I))
		return FALSE
	if(I.fabricated)
		return FALSE
	if(I.flags_1 & HOLOGRAM_1)
		return FALSE
	return matching_slot(I) != 0

/// Which required_type slot I satisfies (1 or 2), or 0 if it fulfills neither / neither has room left.
/datum/bounty_contract/proc/matching_slot(obj/item/I)
	if(delivered_count < required_count && (include_subtypes ? istype(I, required_type) : I.type == required_type) && reagent_check_passed(I))
		return 1
	if(required_type_2 && delivered_count_2 < required_count_2 && (include_subtypes_2 ? istype(I, required_type_2) : I.type == required_type_2))
		return 2
	return 0

/// Reagent purity/fill check for required_type (slot 1 only - see required_reagent_type).
/datum/bounty_contract/proc/reagent_check_passed(obj/item/I)
	if(!required_reagent_type)
		return TRUE
	if(!I.reagents || !I.reagents.maximum_volume)
		return FALSE
	var/needed = required_reagent_fill * I.reagents.maximum_volume
	return I.reagents.get_reagent_amount(required_reagent_type) >= needed

/// Consumes as much of I as applies (stacks partially accepted), returns TRUE if anything was taken.
/datum/bounty_contract/proc/deliver(obj/item/I, mob/user, board_faction)
	var/slot = matching_slot(I)
	if(claimed || !slot || I.fabricated || (I.flags_1 & HOLOGRAM_1))
		return FALSE
	var/amount = 1
	var/needed = (slot == 1) ? (required_count - delivered_count) : (required_count_2 - delivered_count_2)
	if(istype(I, /obj/item/stack))
		var/obj/item/stack/S = I
		amount = min(S.amount, needed)
		S.use(amount)
	else
		qdel(I)
	if(slot == 1)
		delivered_count += amount
	else
		delivered_count_2 += amount
	if(delivered_count >= required_count && (!required_type_2 || delivered_count_2 >= required_count_2))
		complete(user, board_faction)
	return TRUE

/datum/bounty_contract/proc/complete(mob/user, board_faction)
	if(claimed)
		return
	claimed = TRUE
	var/reputation = user?.mind ? (user.mind.bounty_reputation[board_faction] || 0) : 0
	var/trusted = (reputation >= min_reputation)
	var/crate_type = trusted ? reward_crate_type : fallback_crate_type
	var/turf/T = get_turf(user)
	if(crate_type && T)
		new crate_type(T)
	if(user?.mind)
		user.mind.bounty_points += reward_points
		if(board_faction)
			user.mind.bounty_reputation[board_faction] = reputation + reputation_gain
			var/rival = quiet_dealing ? null : get_rival_faction(board_faction)
			if(rival)
				var/rival_reputation = user.mind.bounty_reputation[rival] || 0
				user.mind.bounty_reputation[rival] = rival_reputation - reputation_gain
		SSblackbox.record_feedback("tally", "bounty_contracts_completed", 1, name)
	if(user)
		to_chat(user, span_greentext("Bounty complete: [name]! +[reward_points] bounty points."))
		if(!trusted && min_reputation > 0)
			to_chat(user, span_notice("[employer] doesn't trust you with the good stuff yet - you get the standard crate instead. Complete more of their contracts to earn better rewards."))
		if(board_faction && !quiet_dealing && get_rival_faction(board_faction))
			to_chat(user, span_warning("Word of this will get back to the [get_rival_faction(board_faction)] - your standing with them just dropped."))

/datum/bounty_contract/proc/progress_string()
	if(required_type_2)
		return "[delivered_count]/[required_count] + [delivered_count_2]/[required_count_2]"
	return "[delivered_count]/[required_count]"

/datum/bounty_contract/proc/requirement_string()
	var/atom/dummy_path = required_type
	. = "[required_count]x [initial(dummy_path.name)]"
	if(required_type_2)
		var/atom/dummy_path_2 = required_type_2
		. += " + [required_count_2]x [initial(dummy_path_2.name)]"

/// For board UI display - whether user's current standing with board_faction meets min_reputation.
/datum/bounty_contract/proc/reputation_met(mob/user, board_faction)
	if(min_reputation <= 0)
		return TRUE
	var/reputation = user?.mind ? (user.mind.bounty_reputation[board_faction] || 0) : 0
	return reputation >= min_reputation
