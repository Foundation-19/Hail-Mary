/obj/item/mark
	name = "postal mark"
	desc = "An important piece of paper for the courier, if you are not a courier, give it to him."
	icon = 'icons/obj/quest_items.dmi'
	icon_state = "marka1"

/obj/item/mark/New()
	..()
	icon_state = "marka[rand(1,8)]"

/obj/item/courier_receipt
	name = "courier receipt"
	desc = "A stamped receipt proving a parcel was accepted by its recipient."
	icon = 'icons/obj/quest_items.dmi'
	icon_state = "paper"

/obj/item/contraband_tag
	name = "contraband tag"
	desc = "A coded tag used to verify sensitive cargo delivery."
	icon = 'icons/obj/quest_items.dmi'
	icon_state = "marka7"

/obj/item/parcel
	name = "parcel"
	desc = "The package clearly contains something valuable, and maybe not so much."
	icon = 'icons/obj/quest_items.dmi'
	icon_state = "bigbox"
	item_state = "bigbox"
	w_class = WEIGHT_CLASS_SMALL

	var/datum/mind/recipient = null

	var/screwup_chance = 60
	var/prepared = FALSE
	var/contraband = FALSE
	var/mob/living/prepared_by = null

	/// New delivery pipeline data (receiver terminal flow)
	var/courier_mode = FALSE
	var/courier_id = null
	var/origin_faction = null
	var/destination_faction = null
	var/origin_terminal_name = "Parcel Terminal"
	var/turf/origin_turf = null
	var/issued_time = 0
	var/min_delivery_time_ds = (2 MINUTES)
	var/min_delivery_distance = 40
	var/base_player_reward = 700
	var/base_faction_reward = 260
	var/base_research_reward = 1
	var/base_rep_reward = 2
	var/delivered = FALSE

	var/list/success_list = list(
	/obj/item/crafting/duct_tape,
	/obj/item/flashlight,
	/obj/item/wirecutters,
	/obj/item/reagent_containers/food/drinks/bottle/vodka,
	/obj/item/reagent_containers/food/drinks/bottle/sunset,
	/obj/item/reagent_containers/food/drinks/bottle/f13nukacola,
	/obj/item/reagent_containers/food/drinks/bottle/whiskey,
	/obj/item/reagent_containers/food/drinks/bottle/wine,
	/obj/item/reagent_containers/food/snacks/f13/crisps,
	/obj/item/reagent_containers/food/snacks/f13/steak,
	/obj/item/reagent_containers/food/snacks/donut,
	/obj/item/reagent_containers/hypospray/medipen/stimpak/super,
	/obj/item/storage/pill_bottle/chem_tin/buffout,
	/obj/item/storage/pill_bottle/chem_tin/mentats,
	/obj/item/storage/fancy/cigarettes/cigpack_bigboss,
	/obj/item/seeds/cannabis,
	/obj/item/seeds/random,
	/obj/item/seeds/gatfruit,
	/obj/item/nuke_core,
	/obj/item/camera/spooky,
	/obj/item/soap/deluxe,
	/obj/item/stealthboy,
	/obj/item/stock_parts/cell/super,
	/obj/item/stock_parts/cell/ammo/alien,
	/obj/item/stock_parts/cell/ammo/ec,
	/obj/item/stock_parts/cell/ammo/ecp,
	/obj/item/stock_parts/cell/ammo/mfc,
	/obj/item/stock_parts/cell/ammo/ultracite,
	/obj/item/taperecorder/empty,
	/obj/item/trash/f13/electronic/toaster,
	/obj/item/survivalcapsule/merchant,
	/obj/item/pizzabox/vegetable,
	/obj/item/pizzabox/pineapple,
	/obj/item/pizzabox/margherita,
	/obj/item/lipstick/random,
	/obj/item/lighter,
	/obj/item/instrument/harmonica,
	/obj/item/healthanalyzer/advanced,
	/obj/item/encryptionkey/headset_enclave,
	/obj/item/ammo_box/needle,
	/obj/item/blueprint/misc/stim,
	/obj/item/book/granter/trait/trekking,
	/obj/item/book/granter/trait/pa_wear,
	/obj/item/book/granter/trait/techno,
	/obj/item/book/granter/trait/chemistry,
	/obj/item/gun/ballistic/automatic/type93,
	/obj/item/ammo_box/magazine/m556/rifle,
	/obj/item/gun/energy/laser/wattz,
	/obj/item/gun/energy/laser/plasma/pistol,
	/obj/item/clothing/suit/armor/heavy,
	/obj/item/gun/ballistic/revolver/m29/alt,
	/obj/item/gun/ballistic/revolver/thatgun,
	/obj/item/gun/ballistic/revolver/widowmaker,
	/obj/item/gun/ballistic/shotgun/toy/unrestricted,
	/obj/item/gun/ballistic/automatic/toy/pistol/unrestricted,
	/obj/item/gun/ballistic/automatic/m1garand/oldglory,
	/obj/item/gun/ballistic/automatic/pistol/n99/executive,
	/obj/item/gun/ballistic/automatic/pistol/n99,
	/obj/item/gun/ballistic/automatic/pistol/m1911,
	/obj/item/twohanded/sledgehammer/warmace,
	/obj/item/clothing/gloves/krav_maga/sec,
	/obj/item/clothing/gloves/f13/doom,
	/obj/item/shishkebabpack,
	/obj/item/trash/f13/electronic/toaster/atomics,
	/obj/item/crafting/campfirekit
	)

	var/list/contraband_list = list(
	/obj/item/stealthboy,
	/obj/item/reagent_containers/hypospray/medipen/stimpak/super,
	/obj/item/gun/ballistic/automatic/pistol/n99,
	/obj/item/stock_parts/cell/ammo/mfc,
	/obj/item/stock_parts/cell/ammo/ecp,
	/obj/item/blueprint/misc/stim
	)

	var/list/failure_list = list(
	/obj/item/crafting/duct_tape,
	/obj/item/paper,
	/mob/living/simple_animal/hostile/wolf,
	/mob/living/simple_animal/hostile/cazador/young,
	/mob/living/simple_animal/chick,
	/mob/living/simple_animal/hostile/gecko,
	/obj/item/newspaper,
	/obj/item/paperplane,
	/obj/item/soap/homemade,
	/obj/item/stock_parts/cell/crap,
	/obj/item/tape/random,
	/obj/item/trash/f13/tin,
	/obj/item/trash/f13/rotten,
	/obj/item/shard,
	/obj/item/seeds/grass,
	/obj/item/seeds/nettle,
	/obj/item/organ/brain,
	/obj/item/lipstick/random,
	/obj/item/folder/blue,
	/obj/item/assembly/mousetrap/armed,
	/obj/item/gun/energy/laser/plasma/pistol,
	/obj/item/crafting/campfirekit,
	/obj/item/stack/crafting/metalparts/five,
	/obj/item/stack/crafting/metalparts,
	/obj/item/stack/crafting/metalparts/three,
	/obj/item/stack/crafting/goodparts/three,
	/obj/item/stack/crafting/goodparts/five,
	/obj/item/stack/crafting/goodparts,
	/obj/item/stack/crafting/electronicparts,
	/obj/item/stack/crafting/electronicparts/five,
	/obj/item/stack/crafting/electronicparts/three,
	/obj/item/crafting/lunchbox,
	)

/obj/item/parcel/New()
	..()
	icon_state = pick("bigbox", "longbox", "smallbox")
	contraband = prob(20)

	for(var/mob/living/player in shuffle(GLOB.player_list))
		if(player.stat != DEAD && !isanimal(player) && ishuman(player) && player.mind)
			recipient = player.mind
			break

/obj/item/parcel/proc/configure_courier_delivery(mob/user, new_origin_faction, new_destination_faction, atom/source_terminal)
	courier_mode = TRUE
	courier_id = "[world.time]-[rand(1000,9999)]"
	origin_faction = new_origin_faction
	destination_faction = new_destination_faction
	origin_terminal_name = source_terminal ? "[source_terminal]" : "Parcel Terminal"
	origin_turf = source_terminal ? get_turf(source_terminal) : null
	issued_time = world.time
	delivered = FALSE
	recipient = null
	if(user)
		prepared_by = user

	var/destination_label = destination_faction ? "[destination_faction]" : "Unknown"
	desc = "Courier contract parcel. Seal it with duct tape, then deliver it to the [destination_label] parcel receiver pad."

	if(contraband)
		base_player_reward += 120
		base_faction_reward += 80
		base_research_reward += 1
		base_rep_reward += 1

/obj/item/parcel/proc/get_route_multiplier(atom/destination_anchor)
	var/mult = 1.0
	if(origin_turf && destination_anchor)
		var/turf/destination_turf = get_turf(destination_anchor)
		if(destination_turf && destination_turf.z == origin_turf.z)
			var/dist = get_dist(origin_turf, destination_turf)
			var/bonus = min(0.7, max(0, (dist - min_delivery_distance) / 140))
			mult += bonus
	return mult

/obj/item/parcel/proc/get_player_reward(atom/destination_anchor)
	return max(1, round(base_player_reward * get_route_multiplier(destination_anchor)))

/obj/item/parcel/proc/get_faction_reward(atom/destination_anchor)
	return max(1, round(base_faction_reward * get_route_multiplier(destination_anchor)))

/obj/item/parcel/proc/get_research_reward(atom/destination_anchor)
	return max(1, round(base_research_reward * get_route_multiplier(destination_anchor)))

/obj/item/parcel/proc/get_rep_reward(atom/destination_anchor)
	return max(1, round(base_rep_reward * get_route_multiplier(destination_anchor)))

/obj/item/parcel/attackby(obj/item/I, mob/user, params)
	. = ..()

	if(!prepared)
		if(istype(I, /obj/item/crafting/duct_tape))
			flick("[icon_state]_prepare", src)
			if(do_after(user, 5, target = src))
				if(icon_state == "bigbox")
					icon_state = "bigbox1"
					item_state = "bigbox"
				if(icon_state == "longbox")
					icon_state = "longbox1"
					item_state = "longbox"
				if(icon_state == "smallbox")
					icon_state = "smallbox1"
					item_state = "smallbox"
				if(courier_mode)
					desc = "Courier contract parcel for [destination_faction]. Deliver it to the parcel receiver pad."
				else if(recipient)
					desc = "A package clearly containing something valuable is intended for [recipient.name]."
				else
					desc = "A package clearly containing something valuable."
				prepared_by = user
				qdel(I)
				prepared = TRUE
				screwup_chance = rand(50,70)
		return

	if(courier_mode)
		if(istype(I, /obj/item/kitchen/knife) || istype(I, /obj/item/melee/onehanded/machete) || istype(I, /obj/item/melee/onehanded/knife/switchblade))
			to_chat(user, "<span class='warning'>This parcel is security-sealed for courier delivery. Use a parcel receiver pad.</span>")
		return

	if(istype(I, /obj/item/kitchen/knife) || istype(I, /obj/item/melee/onehanded/machete) || istype(I, /obj/item/melee/onehanded/knife/switchblade))
		if(!isturf(src.loc) || ( !(locate(/obj/structure/table) in src.loc) && !(locate(/obj/structure/table/optable) in src.loc) ))
			to_chat(user, "<span class='warning'>You need table to do this.</span>")
			return FALSE

		if(user.mind == recipient)
			if(do_after(user, 30, target = src))
				var/atom/movable/booty_type = pick(success_list)
				var/atom/movable/booty = new booty_type(loc)
				new /obj/item/mark(loc)
				new /obj/item/courier_receipt(loc)
				if(contraband)
					var/atom/movable/contraband_type = pick(contraband_list)
					new contraband_type(loc)
					new /obj/item/contraband_tag(loc)
				if(prepared_by && prepared_by != user)
					if(hascall(prepared_by, "add_courier_rep"))
						call(prepared_by, "add_courier_rep")(contraband ? 3 : 2)
				to_chat(user, "<span class='notice'>You found [booty] inside of parcel.</span>")
				qdel(src)
		else
			if(do_after(user, 50, target = src))
				if(prob(screwup_chance))
					to_chat(user, "<span class='notice'>You managed to break the contents of the parcel...</span>")
					new /obj/effect/gibspawner/robot(src.loc)
					qdel(src)
				else
					var/atom/movable/booty_type = pick(failure_list)
					var/atom/movable/booty = new booty_type(loc)
					to_chat(user, "<span class='notice'>You found [booty] inside of parcel.</span>")
					qdel(src)
