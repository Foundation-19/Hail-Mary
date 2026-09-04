/*
	Faction bounty board terminal.

	Deliberately simpler than the old QuestMachines bounty_machine: no separate "pod" turf to
	find, no shop/vend mode. Walk up, hand over the item with attackby(), get your crate. This
	trades vend-mode flexibility for a one-step interaction loop that matches how a bounty board
	should feel: post a job, hand in the goods, get paid.
*/

/obj/machinery/bounty_board
	name = "bounty board"
	desc = "A board listing contracted work. Hand over the requested goods to claim a reward."
	icon = 'icons/fallout/machines/terminals.dmi'
	icon_state = "terminal"
	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	obj_integrity = 300
	max_integrity = 300
	armor = list(melee = 20, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 50, acid = 70)

	/// null = universal board only. Set to a FACTION_* define to also roll that faction's pool.
	var/faction = null
	var/list/datum/bounty_contract/active_contracts = list()
	var/contract_limit = 4
	var/refresh_cooldown = 30 MINUTES
	var/last_refresh = 0
	/// Contracts hand-posted by a faction member (see post_contract()), separate from the
	/// passively auto-rolled active_contracts so posting one doesn't eat into the normal rotation.
	var/list/datum/bounty_contract/custom_contracts = list()
	var/custom_contract_limit = 2

GLOBAL_LIST_EMPTY(bounty_boards)

/obj/machinery/bounty_board/Initialize(mapload)
	. = ..()
	GLOB.bounty_boards += src
	refresh_contracts(force = TRUE)

/obj/machinery/bounty_board/Destroy()
	GLOB.bounty_boards -= src
	QDEL_LIST(active_contracts)
	QDEL_LIST(custom_contracts)
	return ..()

/obj/machinery/bounty_board/proc/get_available_pool()
	var/list/pool = GLOB.bounty_contract_pool_universal.Copy()
	if(faction)
		var/list/faction_pool = get_bounty_pool_for_faction(faction)
		if(faction_pool)
			pool += faction_pool
	return pool

/// Rerolls the whole board. Ignores cooldown if force = TRUE (used on spawn/admin refresh).
/obj/machinery/bounty_board/proc/refresh_contracts(force = FALSE)
	if(!force && (world.time - last_refresh) < refresh_cooldown)
		return FALSE
	QDEL_LIST(active_contracts)
	active_contracts = list()
	last_refresh = world.time
	fill_empty_slots()
	return TRUE

/// Tops the board back up to contract_limit without touching contracts already in progress.
/obj/machinery/bounty_board/proc/fill_empty_slots()
	var/list/pool = get_available_pool()
	var/list/rolled_types = list()
	for(var/datum/bounty_contract/C in active_contracts)
		rolled_types += C.type
	for(var/datum/bounty_contract/C in custom_contracts)
		rolled_types += C.type
	pool -= rolled_types
	while(length(active_contracts) < contract_limit && length(pool))
		var/picked_type = pick(pool)
		pool -= picked_type
		active_contracts += new picked_type()

/// The FACTION_* a user represents for posting purposes, or null if they have no faction job.
/obj/machinery/bounty_board/proc/get_user_faction(mob/user)
	var/datum/job/job = user?.GetJob()
	return job?.faction

/// Faction members can only post from their own board (or anyone can post to a universal board) -
/// this is what keeps custom bounties to "pick from the pool", never an arbitrary made-up job.
/obj/machinery/bounty_board/proc/can_post_custom(mob/user)
	if(length(custom_contracts) >= custom_contract_limit)
		return FALSE
	if(!faction)
		return TRUE
	return get_user_faction(user) == faction

/// Templates available to hand-post - same curated pool as the auto-roll, minus whatever's
/// already active (auto-rolled or posted) so you can't stack duplicates of one contract.
/obj/machinery/bounty_board/proc/get_postable_templates()
	var/list/pool = get_available_pool()
	var/list/taken_types = list()
	for(var/datum/bounty_contract/C in active_contracts)
		taken_types += C.type
	for(var/datum/bounty_contract/C in custom_contracts)
		taken_types += C.type
	pool -= taken_types
	return pool

/obj/machinery/bounty_board/attackby(obj/item/I, mob/user, params)
	if(try_deliver(I, user))
		return
	return ..()

/obj/machinery/bounty_board/proc/try_deliver(obj/item/I, mob/user)
	for(var/datum/bounty_contract/C in (active_contracts + custom_contracts))
		if(C.applies_to(I))
			var/was_claimed = C.claimed
			C.deliver(I, user, faction)
			if(!was_claimed && C.claimed)
				if(C in active_contracts)
					active_contracts -= C
					fill_empty_slots()
				else
					custom_contracts -= C
			return TRUE
	if(I.fabricated)
		for(var/datum/bounty_contract/C in (active_contracts + custom_contracts))
			if(!C.claimed && C.matching_slot(I))
				to_chat(user, span_warning("[C.employer] won't accept something churned out of a lathe - they want the genuine article."))
				return TRUE
	for(var/datum/bounty_contract/C in (active_contracts + custom_contracts))
		if(!C.claimed && C.required_reagent_type && C.delivered_count < C.required_count && istype(I, C.required_type) && !C.reagent_check_passed(I))
			to_chat(user, span_warning("[C.employer] wants that properly filled, not empty or watered down."))
			return TRUE
	to_chat(user, span_warning("Nothing on the board wants that."))
	return FALSE

/// Posts one of get_postable_templates() as a live contract, gated by can_post_custom().
/obj/machinery/bounty_board/proc/post_contract(mob/user, picked_type)
	if(!can_post_custom(user))
		return FALSE
	if(!(picked_type in get_postable_templates()))
		return FALSE
	custom_contracts += new picked_type()
	return TRUE

/// Admin/event tool: force an /event contract onto the board, bypassing contract_limit and the
/// normal curated-pool restriction. See code/modules/admin/verbs/bountyevent.dm.
/obj/machinery/bounty_board/proc/post_event_contract(picked_type)
	if(!ispath(picked_type, /datum/bounty_contract/event))
		return FALSE
	active_contracts += new picked_type()
	return TRUE

/obj/machinery/bounty_board/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	ShowUI(user)

/obj/machinery/bounty_board/proc/ShowUI(mob/user)
	var/dat = {"<h1>[name]</h1>"}
	if(faction)
		var/reputation = user?.mind ? (user.mind.bounty_reputation[faction] || 0) : 0
		dat += "Your standing: [reputation]<br>"
	dat += "<a href='?src=\ref[src];refresh=1'>Request new contracts</a>"
	dat += post_link_html(user)
	dat += "<br><br>"
	for(var/datum/bounty_contract/C in active_contracts)
		dat += contract_entry_html(C, user)
	for(var/datum/bounty_contract/C in custom_contracts)
		dat += contract_entry_html(C, user, posted = TRUE)
	var/datum/browser/popup = new(user, "bounty_board", name, 480, 480)
	popup.set_content(dat)
	popup.set_title_image(user.browse_rsc_icon(icon, icon_state))
	popup.open()

/obj/machinery/bounty_board/proc/contract_entry_html(datum/bounty_contract/C, mob/user, posted = FALSE)
	var/trusted = C.reputation_met(user, faction)
	var/dat = "<div class='statusDisplay'>"
	dat += "<font color='green'><b>[C.name][posted ? " (posted)" : ""]</b></font><br>"
	dat += "<font color='green'><b>Employer:</b> [C.employer]</font><br>"
	dat += "<font color='green'>[C.flavor]</font><br>"
	dat += "<font color='green'><b>Needs:</b> [C.requirement_string()] ([C.progress_string()])</font><br>"
	if(trusted)
		dat += "<font color='green'><b>Reward:</b> [C.reward_points] bounty points + crate</font><br>"
	else
		dat += "<font color='red'><b>Reward:</b> [C.reward_points] bounty points + crate (requires [C.min_reputation] standing - you have [user?.mind ? (user.mind.bounty_reputation[faction] || 0) : 0])</font><br>"
	dat += "</div>"
	return dat

/obj/machinery/bounty_board/proc/post_link_html(mob/user)
	if(faction && get_user_faction(user) != faction)
		return " | <font color='gray'>Post a contract (requires being employed by this board's faction)</font>"
	if(length(custom_contracts) >= custom_contract_limit)
		return " | <font color='gray'>Post a contract (board already has [custom_contract_limit] posted)</font>"
	return " | <a href='?src=\ref[src];post=1'>Post a contract</a>"

/// Picker UI for post_contract() - templates only, no free-form item/reward entry.
/obj/machinery/bounty_board/proc/ShowPostUI(mob/user)
	var/dat = "<h1>Post a Contract</h1>"
	var/list/templates = get_postable_templates()
	if(!length(templates))
		dat += "Nothing left to post right now - every template contract is already active."
	for(var/picked_type in templates)
		var/datum/bounty_contract/dummy = picked_type
		dat += "<div class='statusDisplay'>"
		dat += "<font color='green'><b>[initial(dummy.name)]</b></font><br>"
		dat += "<font color='green'>[initial(dummy.flavor)]</font><br>"
		dat += "<a href='?src=\ref[src];post_confirm=[picked_type]'>Post this contract</a>"
		dat += "</div>"
	dat += "<br><a href='?src=\ref[src];refresh=0'>Back</a>"
	var/datum/browser/popup = new(user, "bounty_board", name, 480, 480)
	popup.set_content(dat)
	popup.set_title_image(user.browse_rsc_icon(icon, icon_state))
	popup.open()

/obj/machinery/bounty_board/Topic(href, href_list)
	. = ..()
	if(.)
		return
	if(!usr.canUseTopic(src, be_close = TRUE))
		return
	if(href_list["refresh"] == "1")
		if(!refresh_contracts())
			to_chat(usr, span_warning("The board isn't due for new contracts yet."))
		ShowUI(usr)
	else if(href_list["refresh"] == "0")
		ShowUI(usr)
	else if(href_list["post"])
		if(!can_post_custom(usr))
			to_chat(usr, span_warning("You're not in a position to post contracts here."))
			ShowUI(usr)
			return
		ShowPostUI(usr)
	else if(href_list["post_confirm"])
		var/picked_type = text2path(href_list["post_confirm"])
		if(picked_type && post_contract(usr, picked_type))
			to_chat(usr, span_notice("Contract posted to the board."))
		else
			to_chat(usr, span_warning("Couldn't post that contract."))
		ShowUI(usr)

/// Universal-only board, can be placed anywhere without implying a faction owns it.
/obj/machinery/bounty_board/universal
	name = "wasteland bounty board"

/obj/machinery/bounty_board/bos
	name = "Brotherhood requisitions board"
	desc = "A terminal listing Brotherhood salvage and tech contracts."
	icon_state = "advanced"
	faction = FACTION_BROTHERHOOD

/obj/machinery/bounty_board/legion
	name = "Legion contracts board"
	desc = "A board listing Legion kill contracts, signed in Caesar's name."
	icon_state = "military"
	faction = FACTION_LEGION

/obj/machinery/bounty_board/ncr
	name = "NCR quartermaster board"
	desc = "A board listing New California Republic military procurement contracts."
	icon_state = "military"
	faction = FACTION_NCR

/obj/machinery/bounty_board/town
	name = "town trading board"
	desc = "A board listing local trade requests - mostly food, caps, and materials."
	icon_state = "laptop"
	faction = FACTION_EASTWOOD
