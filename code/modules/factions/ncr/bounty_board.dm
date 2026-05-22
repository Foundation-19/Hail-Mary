// NCR Bounty Board
// Allows NCR officers to post bounties and manage contracts

/obj/machinery/bounty_board/ncr
	name = "NCR Bounty Terminal"
	desc = "A terminal displaying wanted posters and bounty contracts for the New California Republic."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	req_access = list(ACCESS_NCR)
	density = FALSE
	anchored = TRUE

	var/datum/bounty_board_data/board_data

/obj/machinery/bounty_board/ncr/Initialize()
	. = ..()
	board_data = new /datum/bounty_board_data(src)
	board_data.generate_contracts()

/obj/machinery/bounty_board/ncr/Destroy()
	QDEL_NULL(board_data)
	return ..()

/obj/machinery/bounty_board/ncr/attack_hand(mob/user)
	if(!allowed(user))
		to_chat(user, span_warning("Access denied. NCR personnel only."))
		return
	ui_interact(user)

/obj/machinery/bounty_board/ncr/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BountyBoard")
		ui.open()

/obj/machinery/bounty_board/ncr/ui_data(mob/user)
	return board_data ? board_data.get_ui_data(user) : list()

/obj/machinery/bounty_board/ncr/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	if(!board_data)
		return FALSE

	. = board_data.handle_action(action, params, usr)

// ============ BOUNTY BOARD DATA ============

GLOBAL_LIST_EMPTY(ncr_bounties_global)
GLOBAL_LIST_EMPTY(ncr_contract_cooldowns)
GLOBAL_LIST_EMPTY(ncr_player_active_contracts)

/datum/bounty_board_data
	var/obj/machinery/bounty_board/ncr/owner
	var/list/active_bounties = list()
	var/list/available_contracts = list()
	var/bounty_pool = 0

	var/list/post_cooldowns = list()
	var/list/player_marks = list()

/datum/bounty_board_data/New(obj/machinery/bounty_board/ncr/board)
	owner = board
	active_bounties = GLOB.ncr_bounties_global
	INVOKE_ASYNC(src, PROC_REF(setup_database))

/datum/bounty_board_data/proc/setup_database()
	if(!SSdbcore.Connect())
		return FALSE

	var/datum/db_query/query = SSdbcore.NewQuery({"
		CREATE TABLE IF NOT EXISTS [format_table_name("ncr_bounties")] (
			bounty_id INT AUTO_INCREMENT PRIMARY KEY,
			target_ckey VARCHAR(32) NOT NULL,
			target_name VARCHAR(100),
			amount INT NOT NULL,
			reason VARCHAR(255),
			placed_by_ckey VARCHAR(32) NOT NULL,
			placed_by_name VARCHAR(100),
			faction_restriction VARCHAR(50),
			placed_at DATETIME NOT NULL,
			expires_at DATETIME,
			status VARCHAR(20) DEFAULT 'active',
			INDEX idx_target (target_ckey),
			INDEX idx_status (status)
		)"})
	var/success = query.Execute()
	qdel(query)
	if(success)
		load_bounties()
	return success

/datum/bounty_board_data/proc/load_bounties()
	if(!SSdbcore.Connect())
		return

	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT bounty_id, target_ckey, target_name, amount, reason, placed_by_ckey, placed_by_name, faction_restriction, placed_at, expires_at, status FROM [format_table_name("ncr_bounties")] WHERE status = 'active' AND (expires_at IS NULL OR expires_at > NOW())"
	)

	if(query.Execute())
		while(query.NextRow())
			var/list/bounty_data = list(
				"bounty_id" = text2num(query.item[1]),
				"target_ckey" = query.item[2],
				"target_name" = query.item[3],
				"amount" = text2num(query.item[4]),
				"reason" = query.item[5],
				"placed_by_ckey" = query.item[6],
				"placed_by_name" = query.item[7],
				"faction_restriction" = query.item[8],
				"placed_at" = query.item[9],
				"expires_at" = query.item[10],
				"status" = query.item[11],
			)
			GLOB.ncr_bounties_global += list(bounty_data)
	qdel(query)

/datum/bounty_board_data/proc/generate_contracts()
	available_contracts = list()

	var/list/contract_types = subtypesof(/datum/ncr_contract)
	for(var/contract_type in contract_types)
		var/datum/ncr_contract/contract = new contract_type()
		if(contract.auto_generate)
			available_contracts += list(contract.get_data())

/datum/bounty_board_data/proc/get_ui_data(mob/user)
	var/list/data = list()

	data["active_bounties"] = active_bounties
	data["available_contracts"] = available_contracts
	data["bounty_pool"] = bounty_pool
	data["is_officer"] = is_ncr_officer(user)
	data["can_post"] = can_post_bounty(user)
	data["current_mark"] = player_marks[user.ckey]
	data["has_active_contract"] = GLOB.ncr_player_active_contracts[user.ckey] ? TRUE : FALSE

	var/count = 0
	for(var/list/b in active_bounties)
		if(b["placed_by_ckey"] == user.ckey)
			count++
	data["bounties_posted"] = count

	return data

/datum/bounty_board_data/proc/handle_action(action, list/params, mob/user)
	switch(action)
		if("post_bounty")
			return post_bounty(user, params)
		if("mark_target")
			return mark_target(user, params)
		if("clear_mark")
			return clear_mark(user)
		if("accept_contract")
			return accept_contract(user, params)
		if("complete_contract")
			return complete_contract(user, params)
		if("claim_bounty")
			return claim_bounty(user, params)
		if("refresh_contracts")
			generate_contracts()
			return TRUE

	return FALSE

/datum/bounty_board_data/proc/can_post_bounty(mob/user)
	if(!is_ncr_officer(user))
		return FALSE
	if(post_cooldowns[user.ckey] && post_cooldowns[user.ckey] > world.time)
		return FALSE

	var/count = 0
	for(var/list/b in active_bounties)
		if(b["placed_by_ckey"] == user.ckey)
			count++
	if(count >= NCR_BOUNTY_MAX_ACTIVE)
		return FALSE

	return TRUE

/datum/bounty_board_data/proc/is_ncr_officer(mob/user)
	if(!user.mind || !user.mind.assigned_role)
		return FALSE

	var/list/officer_roles = list(
		"NCR Captain",
		"NCR Lieutenant",
		"NCR Sergeant",
		"NCR Ranger",
		"Veteran Ranger",
		"NCR Heavy Trooper",
	)

	return user.mind.assigned_role in officer_roles

/datum/bounty_board_data/proc/post_bounty(mob/user, list/params)
	if(!can_post_bounty(user))
		return FALSE

	var/target_ckey = ckey(params["target_ckey"])
	var/amount = text2num(params["amount"])
	var/reason = params["reason"]
	var/faction_restriction = params["faction_restriction"]

	if(!target_ckey || !amount || !reason)
		return FALSE

	amount = clamp(amount, NCR_BOUNTY_MIN, NCR_BOUNTY_MAX)

	var/mob/target_mob = get_mob_by_ckey(target_ckey)
	var/target_name = target_mob ? (target_mob.real_name || target_ckey) : target_ckey

	var/bounty_id = rand(1000, 9999)

	if(SSdbcore.Connect())
		var/datum/db_query/query = SSdbcore.NewQuery(
			"INSERT INTO [format_table_name("ncr_bounties")] (target_ckey, target_name, amount, reason, placed_by_ckey, placed_by_name, faction_restriction, placed_at, expires_at, status) VALUES (:target_ckey, :target_name, :amount, :reason, :placed_by_ckey, :placed_by_name, :faction_restriction, NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY), 'active')",
			list(
				"target_ckey" = target_ckey,
				"target_name" = target_name,
				"amount" = amount,
				"reason" = reason,
				"placed_by_ckey" = user.ckey,
				"placed_by_name" = user.real_name,
				"faction_restriction" = faction_restriction,
			)
		)
		if(query.Execute())
			var/datum/db_query/id_query = SSdbcore.NewQuery("SELECT LAST_INSERT_ID()")
			if(id_query.Execute() && id_query.NextRow())
				bounty_id = text2num(id_query.item[1])
			qdel(id_query)
		qdel(query)

	post_cooldowns[user.ckey] = world.time + NCR_BOUNTY_COOLDOWN

	var/list/new_bounty = list(
		"bounty_id" = bounty_id,
		"target_ckey" = target_ckey,
		"target_name" = target_name,
		"amount" = amount,
		"reason" = reason,
		"placed_by_ckey" = user.ckey,
		"placed_by_name" = user.real_name,
		"faction_restriction" = faction_restriction,
		"placed_at" = time2text(world.timeofday, "YYYY-MM-DD hh:mm:ss"),
		"expires_at" = null,
		"status" = NCR_BOUNTY_STATUS_ACTIVE,
	)

	GLOB.ncr_bounties_global += list(new_bounty)
	active_bounties = GLOB.ncr_bounties_global

	notify_bounty_posted(target_ckey, amount, reason)

	return TRUE

/datum/bounty_board_data/proc/mark_target(mob/user, list/params)
	var/target_ckey = ckey(params["target_ckey"])
	if(!target_ckey)
		return FALSE

	for(var/list/b in active_bounties)
		if(b["target_ckey"] == target_ckey && b["status"] == NCR_BOUNTY_STATUS_ACTIVE)
			player_marks[user.ckey] = target_ckey
			return TRUE

	return FALSE

/datum/bounty_board_data/proc/clear_mark(mob/user)
	player_marks -= user.ckey
	return TRUE

/datum/bounty_board_data/proc/accept_contract(mob/user, list/params)
	var/contract_id = params["contract_id"]
	if(!contract_id)
		return FALSE

	if(GLOB.ncr_player_active_contracts[user.ckey])
		to_chat(user, span_warning("You already have an active contract."))
		return FALSE

	if(GLOB.ncr_contract_cooldowns[contract_id] && GLOB.ncr_contract_cooldowns[contract_id] > world.time)
		to_chat(user, span_warning("This contract is on cooldown."))
		return FALSE

	for(var/list/contract in available_contracts)
		if(contract["id"] == contract_id && contract["status"] == NCR_CONTRACT_STATUS_AVAILABLE)
			contract["status"] = NCR_CONTRACT_STATUS_ACCEPTED
			contract["accepted_by"] = user.ckey
			GLOB.ncr_player_active_contracts[user.ckey] = contract_id
			to_chat(user, span_notice("Contract accepted: [contract["name"]]"))
			return TRUE

	return FALSE

/datum/bounty_board_data/proc/complete_contract(mob/user, list/params)
	var/contract_id = params["contract_id"]
	if(!contract_id)
		return FALSE

	for(var/list/contract in available_contracts)
		if(contract["id"] == contract_id && contract["accepted_by"] == user.ckey)
			contract["status"] = NCR_CONTRACT_STATUS_COMPLETED
			GLOB.ncr_player_active_contracts -= user.ckey
			GLOB.ncr_contract_cooldowns[contract_id] = world.time + NCR_CONTRACT_COOLDOWN
			var/reward = contract["reward"] || 50
			if(ishuman(user))
				var/mob/living/carbon/human/H = user
				var/obj/item/stack/f13Cash/caps/cap_stack = new(get_turf(H))
				cap_stack.amount = min(reward, 50)
				H.put_in_hands(cap_stack)
			to_chat(user, span_notice("Contract completed! You earned [reward] caps."))
			adjust_faction_reputation(user.ckey, "ncr", 3)
			return TRUE

	return FALSE

/datum/bounty_board_data/proc/claim_bounty(mob/user, list/params)
	var/target_ckey = ckey(params["target_ckey"])
	if(!target_ckey)
		return FALSE

	for(var/i = 1; i <= active_bounties.len; i++)
		var/list/b = active_bounties[i]
		if(b["target_ckey"] == target_ckey && b["status"] == NCR_BOUNTY_STATUS_ACTIVE)
			var/amount = b["amount"]

			if(ishuman(user))
				var/mob/living/carbon/human/H = user
				var/obj/item/stack/f13Cash/caps/cap_stack = new(get_turf(H))
				cap_stack.amount = min(amount, 50)
				H.put_in_hands(cap_stack)
				to_chat(user, span_notice("You collected a [amount] cap bounty!"))

			if(SSdbcore.Connect())
				var/datum/db_query/query = SSdbcore.NewQuery(
					"UPDATE [format_table_name("ncr_bounties")] SET status = 'claimed' WHERE target_ckey = :target_ckey",
					list("target_ckey" = target_ckey)
				)
				query.Execute()
				qdel(query)

			GLOB.ncr_bounties_global.Cut(i, i+1)
			active_bounties = GLOB.ncr_bounties_global
			adjust_faction_reputation(user.ckey, "ncr", 5)
			adjust_karma(user.ckey, 1)

			return TRUE

	return FALSE

/datum/bounty_board_data/proc/notify_bounty_posted(target_ckey, amount, reason)
	var/mob/target = get_mob_by_ckey(target_ckey)
	if(target)
		to_chat(target, span_userdanger("The NCR has posted a [amount] cap bounty on your head!"))
		to_chat(target, span_warning("Reason: [reason]"))

	for(var/mob/M in GLOB.player_list)
		if(M.client && M.mind && (M.mind.assigned_role in list("NCR Captain", "NCR Lieutenant", "NCR Sergeant", "NCR Ranger")))
			to_chat(M, span_notice("NCR Bounty Alert: [amount] cap bounty posted on [target ? target.real_name : target_ckey]."))
