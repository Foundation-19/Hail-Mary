/obj/structure/f13/parcel_receiver_pad
	name = "parcel receiver pad"
	desc = "Place a sealed courier parcel here, then use the linked receiver terminal to send it."
	icon = 'icons/obj/machines/teleporter.dmi'
	icon_state = "tele-o"
	anchored = TRUE
	density = FALSE
	layer = LOW_OBJ_LAYER
	var/faction_id = null

/obj/structure/f13/parcel_receiver_pad/town
	faction_id = FACTION_EASTWOOD

/obj/structure/f13/parcel_receiver_pad/ncr
	faction_id = FACTION_NCR

/obj/structure/f13/parcel_receiver_pad/legion
	faction_id = FACTION_LEGION

/obj/structure/f13/parcel_receiver_pad/bos
	faction_id = FACTION_BROTHERHOOD

/obj/machinery/f13/parcel_receiver_terminal
	name = "parcel receiver terminal"
	desc = "Authenticates sealed courier parcels and credits the courier and local faction treasury."
	icon = 'icons/fallout/machines/terminals.dmi'
	icon_state = "Bounty_Console"
	anchored = TRUE
	density = TRUE
	use_power = NO_POWER_USE
	var/faction_id = FACTION_EASTWOOD
	var/pad_link_range = 2
	var/send_cooldown_ds = 300
	var/obj/structure/f13/parcel_receiver_pad/linked_pad = null
	var/static/list/last_send_by_ckey = list()

/obj/machinery/f13/parcel_receiver_terminal/town
	faction_id = FACTION_EASTWOOD

/obj/machinery/f13/parcel_receiver_terminal/ncr
	faction_id = FACTION_NCR

/obj/machinery/f13/parcel_receiver_terminal/legion
	faction_id = FACTION_LEGION

/obj/machinery/f13/parcel_receiver_terminal/bos
	faction_id = FACTION_BROTHERHOOD

/obj/machinery/f13/parcel_receiver_terminal/Initialize(mapload)
	. = ..()
	link_pad()

/obj/machinery/f13/parcel_receiver_terminal/proc/get_canonical_faction()
	if(SSfaction_control)
		var/canonical = SSfaction_control.normalize_faction(faction_id)
		if(canonical)
			return canonical
	return faction_id

/obj/machinery/f13/parcel_receiver_terminal/proc/link_pad()
	linked_pad = null
	var/canonical = get_canonical_faction()

	for(var/obj/structure/f13/parcel_receiver_pad/P in range(pad_link_range, src))
		if(P.faction_id)
			var/pad_faction = P.faction_id
			if(SSfaction_control)
				pad_faction = SSfaction_control.normalize_faction(P.faction_id)
			if(canonical && pad_faction && canonical != pad_faction)
				continue
		linked_pad = P
		break

/obj/machinery/f13/parcel_receiver_terminal/proc/get_pad_parcel_count()
	if(!linked_pad)
		return 0
	var/count = 0
	for(var/obj/item/parcel/P in linked_pad.loc)
		count++
	return count

/obj/machinery/f13/parcel_receiver_terminal/proc/get_single_pad_parcel()
	if(!linked_pad)
		return null
	var/obj/item/parcel/found = null
	for(var/obj/item/parcel/P in linked_pad.loc)
		if(found)
			return null
		found = P
	return found

/obj/machinery/f13/parcel_receiver_terminal/proc/get_send_error(mob/user, obj/item/parcel/P)
	if(!linked_pad)
		return "No receiver pad linked."
	if(!P)
		return "Place exactly one parcel on the linked pad."
	if(P.delivered)
		return "That parcel was already processed."
	if(!P.courier_mode)
		return "This parcel is not a courier contract parcel."
	if(!P.prepared)
		return "Seal the parcel with duct tape before sending."

	var/my_faction = get_canonical_faction()
	var/target_faction = P.destination_faction
	if(SSfaction_control)
		target_faction = SSfaction_control.normalize_faction(target_faction)
	if(!target_faction || !my_faction || target_faction != my_faction)
		return "Wrong destination. This parcel is routed for [P.destination_faction]."

	if(P.origin_faction && target_faction == P.origin_faction)
		return "Invalid route: destination cannot match the origin faction."

	var/turf/here = get_turf(src)
	if(P.origin_turf && here && P.origin_turf.z == here.z)
		var/dist = get_dist(P.origin_turf, here)
		if(dist < P.min_delivery_distance)
			return "Route too short ([dist] tiles). Minimum is [P.min_delivery_distance]."

	var/ready_at = P.issued_time + P.min_delivery_time_ds
	if(world.time < ready_at)
		var/remaining = max(1, round((ready_at - world.time) / 10))
		return "Routing lock active for [remaining]s."

	var/client/C = user ? user.client : null
	if(C && C.ckey)
		var/cd_until = last_send_by_ckey[C.ckey]
		if(!isnull(cd_until) && cd_until > world.time)
			var/cd_s = max(1, round((cd_until - world.time) / 10))
			return "Receiver cooldown active for [cd_s]s."

	return null

/obj/machinery/f13/parcel_receiver_terminal/proc/send_parcel(mob/user)
	if(!linked_pad)
		link_pad()

	var/count = get_pad_parcel_count()
	if(count != 1)
		to_chat(user, "<span class='warning'>Place exactly one parcel on the linked receiver pad.</span>")
		return

	var/obj/item/parcel/P = get_single_pad_parcel()
	var/error = get_send_error(user, P)
	if(error)
		to_chat(user, "<span class='warning'>[error]</span>")
		return

	var/faction = get_canonical_faction()
	var/player_reward = P.get_player_reward(src)
	var/faction_reward = P.get_faction_reward(src)
	var/research_reward = P.get_research_reward(src)
	var/rep_reward = P.get_rep_reward(src)

	var/turf/drop_turf = linked_pad ? get_turf(linked_pad) : get_turf(src)
	var/obj/item/stack/f13Cash/caps/C = new /obj/item/stack/f13Cash/caps(drop_turf)
	C.add(max(0, player_reward - 1))

	if(SSfaction_control && faction)
		SSfaction_control.add_faction_funds(faction, faction_reward)
		SSfaction_control.add_research_points(faction, research_reward)
		SSfaction_control.add_user_reputation(user, faction, rep_reward)

	if(user && hascall(user, "add_courier_rep"))
		call(user, "add_courier_rep")(max(1, rep_reward))
	if(P.prepared_by && P.prepared_by != user && hascall(P.prepared_by, "add_courier_rep"))
		call(P.prepared_by, "add_courier_rep")(1)

	var/client/client_sender = user ? user.client : null
	if(client_sender && client_sender.ckey)
		last_send_by_ckey[client_sender.ckey] = world.time + send_cooldown_ds

	to_chat(user, "<span class='notice'>Parcel sent: +[player_reward] caps to courier. [faction] treasury +[faction_reward], research +[research_reward].</span>")
	log_game("Courier parcel [P.courier_id] delivered by [key_name(user)] to [faction]. Player reward [player_reward], faction reward [faction_reward], research [research_reward], rep [rep_reward].")
	qdel(P)

/obj/machinery/f13/parcel_receiver_terminal/proc/get_ui_text(mob/user)
	var/dat = "<h1>Parcel Receiver</h1>"
	dat += "<b>Destination Faction:</b> [get_canonical_faction()]<br>"
	if(linked_pad)
		dat += "<font color='green'>Pad linked.</font> <a href='?src=\ref[src];rescan=1'>Rescan</a><br>"
	else
		dat += "<font color='red'>No pad linked.</font> <a href='?src=\ref[src];rescan=1'>Rescan</a><br>"

	var/count = get_pad_parcel_count()
	dat += "<b>Parcels on pad:</b> [count]<br>"
	if(count == 1)
		var/obj/item/parcel/P = get_single_pad_parcel()
		if(P)
			var/sealed_txt = P.prepared ? "Yes" : "No"
			dat += "<b>Route:</b> [P.origin_faction] -> [P.destination_faction]<br>"
			dat += "<b>Sealed:</b> [sealed_txt]<br>"
			dat += "<b>Estimated Courier Payout:</b> [P.get_player_reward(src)] caps<br>"
			dat += "<b>Estimated Faction Reward:</b> [P.get_faction_reward(src)] treasury, [P.get_research_reward(src)] research<br>"
			var/error = get_send_error(user, P)
			if(error)
				dat += "<font color='orange'>Ready check: [error]</font><br>"
			else
				dat += "<font color='green'>Ready to send.</font><br>"
			dat += "<a href='?src=\ref[src];send=1'>Send Parcel</a><br>"
	else
		dat += "<font color='gray'>Place exactly one sealed parcel on the linked pad.</font><br>"

	return dat

/obj/machinery/f13/parcel_receiver_terminal/proc/show_ui(mob/user)
	if(!user)
		return
	var/datum/browser/popup = new(user, "parcel_receiver", "Parcel Receiver", 450, 360)
	popup.set_content(get_ui_text(user))
	popup.set_title_image(user.browse_rsc_icon(src.icon, src.icon_state))
	popup.open()

/obj/machinery/f13/parcel_receiver_terminal/attack_hand(mob/user)
	..()
	show_ui(user)

/obj/machinery/f13/parcel_receiver_terminal/Topic(href, href_list)
	..()
	if(href_list["rescan"])
		link_pad()
	if(href_list["send"])
		send_parcel(usr)
	show_ui(usr)
