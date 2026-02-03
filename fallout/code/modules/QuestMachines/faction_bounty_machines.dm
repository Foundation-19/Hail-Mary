/obj/machinery/bounty_machine/faction
	/* Available item types and prices. [key] - item type< [value] - item price*/
	var/list/price_list = list()

	/* Will create one copy for each item in price list.*/
	var/list/items_ref_list = list()

	/* How many caps stored in machine */
	var/stored_caps = 0

	/* Only head of this faction will have access to machine */
	var/faction_id = "city"

	/* If true - everyone can use machine. If false - only a faction head */
	var/free_access = 0

	/* In vend mode user can buy items. If not - user can complete quests */
	var/vend_mode = 0

/*
================ Content =====================
*/
/*  Courier */

/obj/machinery/bounty_machine/faction/courier
	name = "Parcel Terminal"
	desc = "Issues sealed delivery parcels for cross-faction courier routes."
	icon_state = "enclave_on"
	free_access = TRUE
	quest_type = /datum/bounty_quest/faction/courier
	quest_limit = 0
	faction_id = FACTION_EASTWOOD
	var/min_receiver_distance = 35
	price_list = list(
	/obj/item/parcel = 0
					)

/obj/machinery/bounty_machine/faction/courier/town
	faction_id = FACTION_EASTWOOD

/obj/machinery/bounty_machine/faction/courier/ncr
	faction_id = FACTION_NCR

/obj/machinery/bounty_machine/faction/courier/legion
	faction_id = FACTION_LEGION

/obj/machinery/bounty_machine/faction/courier/bos
	faction_id = FACTION_BROTHERHOOD

/*
================ Mechanics ======================
*/
/obj/machinery/bounty_machine/faction/New()
	..()
	for(var/i = 1; i <= price_list.len; i++)
		var/target_type = price_list[i]
		var/atom/A = new target_type(src)
		items_ref_list.Add(A)

/obj/machinery/bounty_machine/faction/Destroy()
	for(var/atom/Itm in items_ref_list)
		qdel(Itm)
	return ..()

/* Add caps */
/obj/machinery/bounty_machine/faction/proc/add_caps(var/obj/item/stack/f13Cash/caps/C)
	if(!C) return

	var/mob/character = usr
	if(character.doUnEquip(C))
		var/caps_count = C.amount
		stored_caps += caps_count
		playsound(src, 'sound/items/change_jaws.ogg', 60, 1)
		to_chat(usr, "[stored_caps] caps added.")
		qdel(C)

/* Spawn all caps on world and clear caps storage */
/obj/machinery/bounty_machine/faction/proc/remove_all_caps()
	if(stored_caps <= 0)
		return
	var/obj/item/stack/f13Cash/caps/C = new/obj/item/stack/f13Cash/caps
	if(stored_caps > C.max_amount)
		C.add(C.max_amount - 1)
		C.forceMove(src.loc)
		stored_caps -= C.max_amount
	else
		C.add(stored_caps - 1)
		C.forceMove(src.loc)
		stored_caps = 0
	playsound(src, 'sound/items/coinflip.ogg', 60, 1)
	src.ShowUI(usr)

/* Buy item */
/obj/machinery/bounty_machine/faction/proc/buy(var/item_index, var/mob/user)
	if(item_index > price_list.len)
		to_chat(usr, "Invalid item! *beep*")
		return

	if(!connected_pod)
		to_chat(usr, "No pod connected")
		return

	var/target_type = price_list[item_index]

	// Check price
	if(stored_caps >= price_list[target_type])
		// animation
		flick("tele0", connected_pod)

		//Remove caps
		stored_caps -= price_list[target_type]

		// Create item
		new target_type(connected_pod.loc)
		to_chat(usr, "Ready. *boop*")
	else
		to_chat(usr, "Insufficient funds.")

/obj/machinery/bounty_machine/faction/courier/proc/get_canonical_faction_id()
	if(SSfaction_control)
		var/canonical = SSfaction_control.normalize_faction(faction_id)
		if(canonical)
			return canonical
	return faction_id

/obj/machinery/bounty_machine/faction/courier/proc/get_destination_candidates(origin_faction)
	var/list/candidates = list()
	var/turf/origin_turf = get_turf(src)
	for(var/obj/machinery/f13/parcel_receiver_terminal/R in world)
		var/f = R.get_canonical_faction()
		if(!f || f == origin_faction)
			continue
		var/turf/receiver_turf = get_turf(R)
		if(origin_turf && receiver_turf && origin_turf.z == receiver_turf.z)
			if(get_dist(origin_turf, receiver_turf) < min_receiver_distance)
				continue
		if(!(f in candidates))
			candidates += f
	return candidates

/obj/machinery/bounty_machine/faction/courier/proc/pick_destination_faction(origin_faction)
	var/list/candidates = get_destination_candidates(origin_faction)
	if(length(candidates))
		return pick(candidates)

	// Fallback to any canonical controllable faction except the origin.
	if(SSfaction_control && islist(SSfaction_control.controllable_factions))
		for(var/f in SSfaction_control.controllable_factions)
			if(f == origin_faction)
				continue
			candidates += f
	if(length(candidates))
		return pick(candidates)
	return null

/obj/machinery/bounty_machine/faction/courier/buy(item_index, mob/user)
	if(item_index > price_list.len)
		to_chat(user, "<span class='warning'>Invalid item.</span>")
		return

	if(!connected_pod)
		to_chat(user, "<span class='warning'>No pod connected.</span>")
		return

	var/target_type = price_list[item_index]
	var/price = price_list[target_type]
	if(stored_caps < price)
		to_chat(user, "<span class='warning'>Insufficient funds.</span>")
		return

	if(target_type == /obj/item/parcel)
		var/origin_faction = get_canonical_faction_id()
		var/destination_faction = pick_destination_faction(origin_faction)
		if(!destination_faction)
			to_chat(user, "<span class='warning'>No valid parcel receiver routes found. Ask an admin to place receiver terminals.</span>")
			return

		flick("tele0", connected_pod)
		stored_caps -= price
		var/obj/item/parcel/P = new /obj/item/parcel(connected_pod.loc)
		P.configure_courier_delivery(user, origin_faction, destination_faction, src)
		to_chat(user, "<span class='notice'>Parcel route issued: [origin_faction] -> [destination_faction]. Seal it with duct tape, then deliver it on the destination receiver pad.</span>")
		return

	..()

/obj/machinery/bounty_machine/faction/courier/GetQuestUI()
	var/dat = "<meta charset='UTF-8'>"
	dat += "<h1>Courier Operations Terminal</h1>"
	dat += "<font color='green'><b>Origin Base:</b> [get_canonical_faction_id()]</font><br>"

	if(connected_pod)
		dat += "<font color='green'>Pod found</font><br>"
	else
		dat += "<font color='red'>Pod not found</font><br>"
	dat += "<a href='?src=\ref[src];findpod=1'>Rescan Pod</a><br>"
	dat += "<a href='?src=\ref[src];shop=1'>Issue Parcel</a><br><br>"

	var/list/candidates = get_destination_candidates(get_canonical_faction_id())
	dat += "<b>Active Receiver Routes:</b><br>"
	if(length(candidates))
		for(var/f in candidates)
			dat += "- [f]<br>"
	else
		dat += "<font color='gray'>No valid routes. Place /obj/machinery/f13/parcel_receiver_terminal in other faction bases.</font><br>"

	dat += "<br><font color='orange'>How it works:</font><br>"
	dat += "1) Buy parcel -> spawns on pod.<br>"
	dat += "2) Seal parcel with duct tape.<br>"
	dat += "3) Carry to destination faction receiver pad.<br>"
	dat += "4) Use receiver terminal Send Parcel for payout.<br>"
	return dat

/*  INTERACTION */
/obj/machinery/bounty_machine/faction/attackby(obj/item/OtherItem, mob/living/carbon/human/user, params)
	..()


	// CAPS
	if(istype(OtherItem, /obj/item/stack/f13Cash/caps))
		add_caps(OtherItem)

/* GUI */
/* Shop UI*/
/obj/machinery/bounty_machine/faction/proc/GetShopUI()
	var/dat = "<h1>Shop</h1>"
	dat += "<a href='?src=\ref[src];exit=1'>Exit</a><br><br>"
	dat += "<font color = 'green'>Caps stored: [stored_caps]</font>"
	dat += "<a href='?src=\ref[src];removecaps=1'>Remove</a><br>"
	if(free_access)
		dat += "<font color = 'green'><b>Access:</b> Free</font><br>"
	else
		dat += "<font color = 'red'><b>Access:</b> Leader Only</font><br>"

	dat += "<div class='statusDisplay'>"
	for(var/i = 1; i <= price_list.len; i++)
		var/itm_type = price_list[i]
		var/atom/itm_ref = items_ref_list[i]
		var/price = price_list[itm_type]
		if(stored_caps < price_list[itm_type])
			dat += "<a href='?src=\ref[src];examine=[i]'>?</a>"
			dat += "<font color = 'grey'><b> [itm_ref] - [price] </b></font>"
			dat += "<a href='?src=\ref[src];buy=[i]'>Buy</a><br>"
		else
			dat += "<a href='?src=\ref[src];examine=[i]'>?</a>"
			dat += "<font color = 'green'><b> [itm_ref] - [price] </b></font>"
			dat += "<a href='?src=\ref[src];buy=[i]'>Buy</a><br>"
	dat += ""
	dat += "</div>"
	return dat

/* Quest UI */
/obj/machinery/bounty_machine/faction/proc/GetQuestUI()
	var/dat = "<meta charset='UTF-8'>"
	var/datum/asset/assets = get_asset_datum(/datum/asset/simple/bounty_employers)
	assets.send(usr)

	dat += "<h1>Wasteland Bounty Station</h1>"


	if(connected_pod)
		dat += "<font color='green'>Pod found</font><br>"
		dat += "<a href='?src=\ref[src];findpod=1'>Rescan</a>"
	else
		dat += "<font color='red'>Pod not found</font><br>"
		dat += "<a href='?src=\ref[src];findpod=1'>Rescan</a>"
	dat += "<a href='?src=\ref[src];shop=1'>Shop</a><br>"
	dat += "<style>.leftimg {float:left;margin: 7px 7px 7px 0;}</style>"

	dat += "<h2>Contracts:</h2>"
	var/item_index = 1
	for(var/datum/bounty_quest/Q in active_quests)
		//usr << browse_rsc(Q.GetIconWithPath(), Q.employer_icon)
		dat += "<div class='statusDisplay'>"
		dat += "<img src='[Q.employer_icon]' class='leftimg' width = 59 height = 70></img>"
		dat += "<font color='green'><b>ID: </b> [Q.name]</font><br>"
		dat += "<font color='green'><b>Employer: </b> [Q.employer]</font><br>"
		dat += "<font color='green'><b>Message:</b></font>"
		dat += "<font color='green'>[Q.desc]</font><br><br>"
		dat += "<font color='green'><b>Needs: </b></font>"
		dat += "<font color='green'><i>[Q.need_message]. </i></font><br>"
		if(Q.HasBonus())
			var/bonus_reward = max(0, Q.bonus_reward)
			dat += "<font color='green'><b>Bonus: </b></font>"
			dat += "<font color='green'><i>[Q.bonus_need_message] </i>(+[bonus_reward] caps)</font><br>"
		dat += "<font color='green'><b>Reward:</b></font>"
		dat += "<font color='green'> [Q.caps_reward] caps</font><br>"
		dat += "<a href='?src=\ref[src];completequest=[item_index]'>send</a><br>"
		dat += "</div>"
		item_index++

	dat += GetFactionControlContractsUI(usr)

	return dat

/obj/machinery/bounty_machine/faction/proc/GetFactionControlContractsUI(mob/user)
	if(!SSfaction_control || !user)
		return ""
	var/f = SSfaction_control.get_mob_faction(user)
	if(!f || !SSfaction_control.is_controllable_faction(f))
		return ""

	var/dat = "<h2>Dynamic Operations Director</h2>"
	var/list/contracts = SSfaction_control.get_contract_rows(f)
	if(!islist(contracts) || !length(contracts))
		dat += "<font color='gray'>No live faction operations available right now.</font><br>"
		return dat

	for(var/list/C in contracts)
		if(!islist(C)) continue
		var/cid = C["id"]
		if(!cid) continue
		var/title = C["title"]
		var/district = C["district"]
		var/desc = C["desc"]
		var/progress = C["progress"]
		var/target = C["target"]
		var/reward_caps = C["reward_caps"]
		var/reward_research = C["reward_research"]
		var/reward_rep = C["reward_rep"]
		var/complete = !!C["complete"]
		var/expires_s = C["expires_s"]
		dat += "<div class='statusDisplay'>"
		dat += "<font color='orange'><b>[title]</b></font><br>"
		dat += "<font color='orange'>District: [district]</font><br>"
		dat += "<font color='orange'>[desc]</font><br>"
		dat += "<font color='orange'>Progress: [progress]/[target] | Expires: [expires_s]s</font><br>"
		dat += "<font color='orange'>Reward: [reward_caps] caps, [reward_research] research, [reward_rep] rep</font><br>"
		if(complete)
			dat += "<a href='?src=\ref[src];turninfcontract=[cid]'>turn in</a><br>"
		else
			dat += "<font color='gray'>incomplete</font><br>"
		dat += "</div>"
	return dat

/obj/machinery/bounty_machine/faction/ShowUI()
	var/dat
	if(vend_mode)
		dat = GetShopUI()
	else
		dat = GetQuestUI()

	var/datum/browser/popup = new(usr, "bounty", "Wasteland Faction Contracts Database", 640, 400) // Set up the popup browser window
	popup.set_content(dat)
	popup.set_title_image(usr.browse_rsc_icon(src.icon, src.icon_state))
	popup.open()

/* Topic */
/obj/machinery/bounty_machine/faction/Topic(href, href_list)
	..()
	if(href_list["exit"])
		vend_mode = 0
	if(href_list["examine"])
		var/itm_index = text2num(href_list["examine"])
		var/obj/T = items_ref_list[itm_index]
		T.examine(usr)
	if(href_list["buy"])
		var/itm_index = text2num(href_list["buy"])
		buy(itm_index, usr)
	if(href_list["shop"])
		vend_mode = 1
	if(href_list["removecaps"])
		remove_all_caps()
	if(href_list["turninfcontract"])
		var/cid = href_list["turninfcontract"]
		if(istext(cid) && length(cid) && SSfaction_control)
			SSfaction_control.turn_in_contract(usr, cid)
	ShowUI()
