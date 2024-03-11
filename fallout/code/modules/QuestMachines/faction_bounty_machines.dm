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

/obj/machinery/bounty_machine/faction/coureer
	name = "Parcel Terminal"
	desc = "This terminal uses a courier to receive new parcels."
	icon_state = "terminal"
	free_access = TRUE
	quest_type = /datum/bounty_quest/faction/courier
	price_list = list(
	/obj/item/parcel = 400
					)

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
TYPE_PROC_REF(/obj/machinery/bounty_machine/faction, add_caps)(var/obj/item/stack/f13Cash/caps/C)
	if(!C) return

	var/mob/character = usr
	if(character.doUnEquip(C))
		var/caps_count = C.amount
		stored_caps += caps_count
		playsound(src, 'sound/items/change_jaws.ogg', 60, 1)
		to_chat(usr, "[stored_caps] caps added.")
		qdel(C)

/* Spawn all caps on world and clear caps storage */
TYPE_PROC_REF(/obj/machinery/bounty_machine/faction, remove_all_caps)()
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
TYPE_PROC_REF(/obj/machinery/bounty_machine/faction, buy)(var/item_index, var/mob/user)
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

/*  INTERACTION */
/obj/machinery/bounty_machine/faction/attackby(obj/item/OtherItem, /mob/living/carbon/human/user, parameters)

	// CAPS
	if(istype(OtherItem, /obj/item/stack/f13Cash/caps))
		add_caps(OtherItem)

/* GUI */
/* Shop UI*/
TYPE_PROC_REF(/obj/machinery/bounty_machine/faction, GetShopUI)()
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
TYPE_PROC_REF(/obj/machinery/bounty_machine/faction, GetQuestUI)()
	var/dat = {"<meta charset="UTF-8">"}
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
		dat += "<font color='green'><b>Reward:</b></font>"
		dat += "<font color='green'> [Q.caps_reward] caps</font><br>"
		dat += "<a href='?src=\ref[src];completequest=[item_index]'>send</a><br>"
		dat += "</div>"
		item_index++

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
	ShowUI()
