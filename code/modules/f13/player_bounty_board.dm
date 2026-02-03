// code/modules/f13/player_bounty_board.dm
// Player-created bounty board with escrowed rewards and proof-based claiming.

#define PB_MODE_DEAD "dead"
#define PB_MODE_ALIVE "alive"
#define PB_MODE_DOA "dead_or_alive"

#define PB_STATUS_OPEN "open"
#define PB_STATUS_CLAIMED "claimed"
#define PB_STATUS_CANCELLED "cancelled"
#define PB_STATUS_EXPIRED "expired"

/datum/player_bounty_contract
	var/id = ""
	var/target_name = ""
	var/target_ckey = ""
	var/requester_name = ""
	var/requester_ckey = ""
	var/reward_caps = 0
	var/mode = PB_MODE_DOA
	var/notes = ""
	var/created_at = 0
	var/expires_at = 0
	var/status = PB_STATUS_OPEN
	var/claimer_name = ""
	var/claimer_ckey = ""
	var/resolved_at = 0


/obj/machinery/f13/player_bounty_board
	name = "wasteland bounty board"
	desc = "Post player bounties with escrowed rewards. Bring targets here alive, dead, or either."
	icon = 'code/modules/f13/64x32_sprites.dmi'
	icon_state = ""
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0

	/// Active + historical contracts.
	var/list/contracts = list()
	/// Escrow wallet by ckey (caps equivalent).
	var/list/escrow_by_ckey = list()
	/// Increasing id seed.
	var/next_contract_id = 1

	var/min_reward_caps = 100
	var/max_reward_caps = 50000
	var/default_expire_ds = 45 * 60 * 10
	var/min_expire_minutes = 10
	var/max_expire_minutes = 240
	var/max_open_contracts = 40
	var/max_history_records = 120

/obj/machinery/f13/player_bounty_board/proc/get_user_ckey(mob/user)
	if(!user)
		return null
	if(user.ckey)
		return ckey(user.ckey)
	if(user.mind?.key)
		return ckey(user.mind.key)
	return null

/obj/machinery/f13/player_bounty_board/proc/get_user_name(mob/user)
	if(!user)
		return "Unknown"
	if(user:real_name)
		return "[user:real_name]"
	return "[user.name]"

/obj/machinery/f13/player_bounty_board/proc/get_wallet_balance(user_ckey)
	if(!istext(user_ckey) || !length(user_ckey))
		return 0
	return max(0, round(escrow_by_ckey[user_ckey] || 0))

/obj/machinery/f13/player_bounty_board/proc/set_wallet_balance(user_ckey, amount)
	if(!istext(user_ckey) || !length(user_ckey))
		return
	escrow_by_ckey[user_ckey] = max(0, round(amount))

/obj/machinery/f13/player_bounty_board/proc/add_wallet_balance(user_ckey, amount)
	if(!istext(user_ckey) || !length(user_ckey))
		return
	if(!isnum(amount))
		return
	set_wallet_balance(user_ckey, get_wallet_balance(user_ckey) + amount)

/obj/machinery/f13/player_bounty_board/proc/remove_wallet_balance(user_ckey, amount)
	if(!istext(user_ckey) || !length(user_ckey))
		return FALSE
	if(!isnum(amount))
		return FALSE
	amount = max(0, round(amount))
	var/current = get_wallet_balance(user_ckey)
	if(amount > current)
		return FALSE
	set_wallet_balance(user_ckey, current - amount)
	return TRUE

/obj/machinery/f13/player_bounty_board/proc/drop_caps_reward(amount, turf/T)
	if(!T || !isnum(amount))
		return FALSE
	amount = max(0, round(amount))
	if(!amount)
		return FALSE
	while(amount > 0)
		var/chunk = min(amount, 15000)
		var/obj/item/stack/f13Cash/caps/C = new /obj/item/stack/f13Cash/caps(T)
		C.amount = chunk
		C.update_desc()
		C.update_icon()
		amount -= chunk
	return TRUE

/obj/machinery/f13/player_bounty_board/proc/deposit_escrow_from_item(obj/item/stack/f13Cash/C, mob/living/user)
	if(!C || !user)
		return FALSE
	var/user_ckey = get_user_ckey(user)
	if(!user_ckey)
		to_chat(user, span_warning("Unable to identify your account key for escrow."))
		return FALSE
	var/value = round(C.get_item_credit_value())
	if(value <= 0)
		to_chat(user, span_warning("That currency stack has no value."))
		return FALSE
	if(!user.doUnEquip(C))
		to_chat(user, span_warning("You need to be holding the currency to deposit it."))
		return FALSE
	add_wallet_balance(user_ckey, value)
	qdel(C)
	playsound(src, 'sound/items/change_jaws.ogg', 60, TRUE)
	to_chat(user, span_notice("Deposited [value] caps into escrow wallet."))
	return TRUE

/obj/machinery/f13/player_bounty_board/proc/get_open_contract_count()
	var/count = 0
	for(var/datum/player_bounty_contract/C in contracts)
		if(!C) continue
		if(C.status == PB_STATUS_OPEN)
			count++
	return count

/obj/machinery/f13/player_bounty_board/proc/find_contract_by_id(contract_id)
	if(!istext(contract_id) || !length(contract_id))
		return null
	for(var/datum/player_bounty_contract/C in contracts)
		if(!C) continue
		if(C.id == contract_id)
			return C
	return null

/obj/machinery/f13/player_bounty_board/proc/get_mob_ckey(mob/M)
	if(!M)
		return null
	if(M.ckey)
		return ckey(M.ckey)
	if(M.mind?.key)
		return ckey(M.mind.key)
	return null

/obj/machinery/f13/player_bounty_board/proc/get_mob_name(mob/M)
	if(!M)
		return ""
	if(M:real_name)
		return "[M:real_name]"
	return "[M.name]"

/obj/machinery/f13/player_bounty_board/proc/is_target_match(datum/player_bounty_contract/C, mob/living/L)
	if(!C || !L)
		return FALSE
	if(C.target_ckey && length(C.target_ckey))
		var/target_ckey = get_mob_ckey(L)
		if(target_ckey && target_ckey == ckey(C.target_ckey))
			return TRUE
	var/contract_name = ckey(C.target_name)
	if(contract_name && length(contract_name))
		var/mob_name = ckey(get_mob_name(L))
		if(mob_name == contract_name)
			return TRUE
	return FALSE

/obj/machinery/f13/player_bounty_board/proc/find_target_nearby_for_contract(datum/player_bounty_contract/C, need_alive = FALSE, need_dead = FALSE)
	if(!C)
		return null
	for(var/mob/living/L in range(1, src))
		if(QDELETED(L)) continue
		if(!is_target_match(C, L)) continue
		if(need_alive && L.stat == DEAD) continue
		if(need_dead && L.stat != DEAD) continue
		return L
	return null

/obj/machinery/f13/player_bounty_board/proc/can_user_claim_contract(mob/user, datum/player_bounty_contract/C)
	if(!user || !C)
		return FALSE
	if(C.status != PB_STATUS_OPEN)
		return FALSE
	var/user_ckey = get_user_ckey(user)
	if(!user_ckey)
		return FALSE
	if(user_ckey == C.requester_ckey)
		return FALSE
	if(is_target_match(C, user))
		return FALSE
	switch(C.mode)
		if(PB_MODE_DEAD)
			return !!find_target_nearby_for_contract(C, FALSE, TRUE)
		if(PB_MODE_ALIVE)
			var/mob/living/L = find_target_nearby_for_contract(C, TRUE, FALSE)
			return !!(L && (L.restrained() || L.buckled))
		else
			var/mob/living/alive = find_target_nearby_for_contract(C, TRUE, FALSE)
			if(alive && (alive.restrained() || alive.buckled))
				return TRUE
			return !!find_target_nearby_for_contract(C, FALSE, TRUE)

/obj/machinery/f13/player_bounty_board/proc/claim_contract(mob/user, datum/player_bounty_contract/C)
	if(!user || !C)
		return FALSE
	if(C.status != PB_STATUS_OPEN)
		to_chat(user, span_warning("That bounty is no longer open."))
		return FALSE
	var/user_ckey = get_user_ckey(user)
	if(!user_ckey)
		to_chat(user, span_warning("Unable to verify claimant identity."))
		return FALSE
	if(user_ckey == C.requester_ckey)
		to_chat(user, span_warning("You cannot claim your own bounty."))
		return FALSE
	if(is_target_match(C, user))
		to_chat(user, span_warning("The listed target cannot claim this bounty."))
		return FALSE

	var/mob/living/proof_target = null
	switch(C.mode)
		if(PB_MODE_DEAD)
			proof_target = find_target_nearby_for_contract(C, FALSE, TRUE)
			if(!proof_target)
				to_chat(user, span_warning("No dead target body matching this contract is next to the board."))
				return FALSE
		if(PB_MODE_ALIVE)
			proof_target = find_target_nearby_for_contract(C, TRUE, FALSE)
			if(!proof_target)
				to_chat(user, span_warning("No living target matching this contract is next to the board."))
				return FALSE
			if(!(proof_target.restrained() || proof_target.buckled))
				to_chat(user, span_warning("Alive captures must be restrained or buckled to claim."))
				return FALSE
		else
			proof_target = find_target_nearby_for_contract(C, TRUE, FALSE)
			if(proof_target && !(proof_target.restrained() || proof_target.buckled))
				proof_target = null
			if(!proof_target)
				proof_target = find_target_nearby_for_contract(C, FALSE, TRUE)
			if(!proof_target)
				to_chat(user, span_warning("Bring the target here alive (restrained) or dead to claim this bounty."))
				return FALSE

	var/turf/T = get_turf(src)
	if(!T)
		return FALSE

	C.status = PB_STATUS_CLAIMED
	C.claimer_ckey = user_ckey
	C.claimer_name = get_user_name(user)
	C.resolved_at = world.time

	drop_caps_reward(C.reward_caps, T)
	playsound(src, 'sound/items/coinflip.ogg', 60, TRUE)
	visible_message(span_notice("[user] claims bounty [C.id] for [C.reward_caps] caps."))
	to_chat(user, span_notice("Bounty paid: [C.reward_caps] caps."))
	return TRUE

/obj/machinery/f13/player_bounty_board/proc/cull_expired_and_prune()
	if(!islist(contracts))
		contracts = list()
	for(var/datum/player_bounty_contract/C in contracts)
		if(!C) continue
		if(C.status != PB_STATUS_OPEN) continue
		if(!C.expires_at) continue
		if(world.time < C.expires_at) continue
		C.status = PB_STATUS_EXPIRED
		C.resolved_at = world.time
		if(C.requester_ckey && C.reward_caps > 0)
			add_wallet_balance(C.requester_ckey, C.reward_caps)

	if(length(contracts) <= (max_open_contracts + max_history_records))
		return

	var/list/open_list = list()
	var/list/resolved_list = list()
	for(var/datum/player_bounty_contract/C2 in contracts)
		if(!C2) continue
		if(C2.status == PB_STATUS_OPEN)
			open_list += C2
		else
			resolved_list += C2

	var/list/trimmed_resolved = list()
	var/keep_resolved = max(0, max_history_records)
	var/start_idx = max(1, length(resolved_list) - keep_resolved + 1)
	for(var/i in start_idx to length(resolved_list))
		trimmed_resolved += resolved_list[i]

	contracts = open_list + trimmed_resolved

/obj/machinery/f13/player_bounty_board/proc/get_online_target_rows()
	var/list/rows = list()
	for(var/client/C)
		if(!C || !C.mob) continue
		var/mob/M = C.mob
		if(QDELETED(M)) continue
		if(istype(M, /mob/dead/observer)) continue
		var/target_ckey = ckey(C.ckey)
		if(!target_ckey || !length(target_ckey)) continue
		rows += list(list(
			"ckey" = target_ckey,
			"name" = get_mob_name(M)
		))
	return rows

/obj/machinery/f13/player_bounty_board/proc/contract_to_row(datum/player_bounty_contract/C, mob/user)
	if(!C)
		return null
	var/list/row = list()
	row["id"] = C.id
	row["target_name"] = C.target_name
	row["target_ckey"] = C.target_ckey
	row["requester_name"] = C.requester_name
	row["requester_ckey"] = C.requester_ckey
	row["reward_caps"] = C.reward_caps
	row["mode"] = C.mode
	row["notes"] = C.notes
	row["status"] = C.status
	row["claimer_name"] = C.claimer_name
	row["age_s"] = max(0, round((world.time - C.created_at) / 10))
	row["expires_s"] = (C.status == PB_STATUS_OPEN) ? max(0, round((C.expires_at - world.time) / 10)) : 0
	row["can_claim"] = can_user_claim_contract(user, C)
	var/user_ckey = get_user_ckey(user)
	row["can_cancel"] = (C.status == PB_STATUS_OPEN && user_ckey && user_ckey == C.requester_ckey)
	return row

/obj/machinery/f13/player_bounty_board/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	if(istype(I, /obj/item/stack/f13Cash))
		deposit_escrow_from_item(I, user)
		ui_interact(user, null)
		return

/obj/machinery/f13/player_bounty_board/attack_hand(mob/user)
	. = ..()
	ui_interact(user, null)

/obj/machinery/f13/player_bounty_board/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/f13/player_bounty_board/ui_data(mob/user)
	cull_expired_and_prune()
	var/user_ckey = get_user_ckey(user)
	var/list/open_rows = list()
	var/list/my_rows = list()
	var/list/history_rows = list()
	for(var/datum/player_bounty_contract/C in contracts)
		if(!C) continue
		var/list/row = contract_to_row(C, user)
		if(!islist(row)) continue
		if(C.status == PB_STATUS_OPEN)
			open_rows += list(row)
		else
			history_rows += list(row)
		if(user_ckey && C.requester_ckey == user_ckey)
			my_rows += list(row)

	return list(
		"escrow_caps" = user_ckey ? get_wallet_balance(user_ckey) : 0,
		"user_ckey" = user_ckey || "",
		"min_reward_caps" = min_reward_caps,
		"max_reward_caps" = max_reward_caps,
		"default_expire_minutes" = round(default_expire_ds / 600),
		"open_count" = get_open_contract_count(),
		"max_open_contracts" = max_open_contracts,
		"open_rows" = open_rows,
		"my_rows" = my_rows,
		"history_rows" = history_rows,
		"online_targets" = get_online_target_rows()
	)

/obj/machinery/f13/player_bounty_board/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/user = ui?.user
	if(!user)
		user = usr
	if(!user)
		return TRUE

	cull_expired_and_prune()

	var/user_ckey = get_user_ckey(user)
	if(!user_ckey)
		to_chat(user, span_warning("Unable to identify your escrow account key."))
		return TRUE

	switch(action)
		if("withdraw_escrow")
			var/requested = text2num(params["amount"])
			var/all_flag = !!params["all"]
			var/current_wallet = get_wallet_balance(user_ckey)
			if(current_wallet <= 0)
				to_chat(user, span_warning("You have no escrow balance to withdraw."))
				return TRUE
			var/amount = all_flag ? current_wallet : max(0, round(requested))
			amount = min(amount, current_wallet)
			if(amount <= 0)
				return TRUE
			if(!remove_wallet_balance(user_ckey, amount))
				to_chat(user, span_warning("Escrow withdrawal failed."))
				return TRUE
			var/turf/T = get_turf(src)
			if(T)
				drop_caps_reward(amount, T)
			playsound(src, 'sound/items/coinflip.ogg', 60, TRUE)
			to_chat(user, span_notice("Withdrew [amount] caps from escrow."))
			return TRUE

		if("post_bounty")
			if(get_open_contract_count() >= max_open_contracts)
				to_chat(user, span_warning("This board is at open contract capacity."))
				return TRUE

			var/target_ckey = ckey(params["target_ckey"] || "")
			var/target_name = trim("[params["target_name"] || ""]")
			var/notes = trim("[params["notes"] || ""]")
			var/reward = round(text2num(params["reward_caps"]))
			var/expire_minutes = round(text2num(params["expire_minutes"]))
			var/mode = "[params["mode"] || PB_MODE_DOA]"

			if(length(target_name) > 64)
				target_name = copytext(target_name, 1, 65)
			if(length(notes) > 240)
				notes = copytext(notes, 1, 241)

			if(target_ckey && !length(target_name))
				var/mob/M = get_mob_by_ckey(target_ckey)
				if(M)
					target_name = get_mob_name(M)

			if(!length(target_name))
				to_chat(user, span_warning("Provide a target name or select an online target."))
				return TRUE

			if(target_ckey && target_ckey == user_ckey)
				to_chat(user, span_warning("You cannot post a bounty on yourself."))
				return TRUE

			if(reward < min_reward_caps || reward > max_reward_caps)
				to_chat(user, span_warning("Reward must be between [min_reward_caps] and [max_reward_caps] caps."))
				return TRUE

			var/current_wallet2 = get_wallet_balance(user_ckey)
			if(current_wallet2 < reward)
				to_chat(user, span_warning("Insufficient escrow balance. Deposit more caps first."))
				return TRUE

			if(mode != PB_MODE_DEAD && mode != PB_MODE_ALIVE && mode != PB_MODE_DOA)
				mode = PB_MODE_DOA

			expire_minutes = clamp(expire_minutes, min_expire_minutes, max_expire_minutes)
			var/expire_ds = expire_minutes * 60 * 10
			if(expire_ds <= 0)
				expire_ds = default_expire_ds

			if(!remove_wallet_balance(user_ckey, reward))
				to_chat(user, span_warning("Failed to reserve escrow for this contract."))
				return TRUE

			var/datum/player_bounty_contract/C = new
			C.id = "PB-[next_contract_id++]"
			C.target_name = target_name
			C.target_ckey = target_ckey
			C.requester_name = get_user_name(user)
			C.requester_ckey = user_ckey
			C.reward_caps = reward
			C.mode = mode
			C.notes = notes
			C.created_at = world.time
			C.expires_at = world.time + expire_ds
			C.status = PB_STATUS_OPEN
			contracts += C

			to_chat(user, span_notice("Posted bounty [C.id] on [C.target_name] for [reward] caps ([mode])."))
			return TRUE

		if("cancel_bounty")
			var/contract_id = "[params["id"] || ""]"
			var/datum/player_bounty_contract/C2 = find_contract_by_id(contract_id)
			if(!C2)
				to_chat(user, span_warning("Contract not found."))
				return TRUE
			if(C2.status != PB_STATUS_OPEN)
				to_chat(user, span_warning("Only open contracts can be cancelled."))
				return TRUE
			if(C2.requester_ckey != user_ckey)
				to_chat(user, span_warning("Only the poster can cancel that bounty."))
				return TRUE

			C2.status = PB_STATUS_CANCELLED
			C2.resolved_at = world.time
			add_wallet_balance(user_ckey, C2.reward_caps)
			to_chat(user, span_notice("Cancelled [C2.id]. Reward returned to your escrow wallet."))
			return TRUE

		if("claim_bounty")
			var/contract_id2 = "[params["id"] || ""]"
			var/datum/player_bounty_contract/C3 = find_contract_by_id(contract_id2)
			if(!C3)
				to_chat(user, span_warning("Contract not found."))
				return TRUE
			claim_contract(user, C3)
			return TRUE

	return FALSE

/obj/machinery/f13/player_bounty_board/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PlayerBountyBoard")
		ui.open()

#undef PB_MODE_DEAD
#undef PB_MODE_ALIVE
#undef PB_MODE_DOA
#undef PB_STATUS_OPEN
#undef PB_STATUS_CLAIMED
#undef PB_STATUS_CANCELLED
#undef PB_STATUS_EXPIRED
