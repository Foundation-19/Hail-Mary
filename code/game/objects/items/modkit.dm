/obj/item/modkit
	name = "modkit"
	desc = "A small container of parts made to modify a specific item. Use the target item on this kit to convert it."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "modkit"
	w_class = WEIGHT_CLASS_NORMAL
	var/list/target_items = list()
	var/result_item = null

/obj/item/modkit/pre_attack(obj/item/I, mob/user)
	if(is_type_in_list(I, target_items))
		var/obj/item/R = new result_item(get_turf(user))
		to_chat(user, span_notice("You apply the [src] to [I], using the custom parts to turn it into [R]."))
		remove_item_from_storage(I)
		qdel(I)
		user.put_in_hands(R)
		qdel(src)
		return TRUE
	else
		return ..()

/obj/item/modkit/riotgear
	name = "desert ranger riot gear modkit"
	target_items = list(/obj/item/clothing/suit/armor/rangercombat)
	result_item = /obj/item/clothing/suit/armor/medium/combat/desert_ranger

/obj/item/modkit/riotgear_helmet
	name = "desert ranger riot helmet modkit"
	target_items = list(/obj/item/clothing/head/helmet/f13/ncr/rangercombat)
	result_item = /obj/item/clothing/head/helmet/f13/ncr/rangercombat/desert

/obj/item/modkit/riotgear/fox
	name = "sniper riot gear modkit"
	result_item = /obj/item/clothing/suit/armor/rangercombat/foxcustom

/obj/item/modkit/riotgear_helmet/fox
	name = "reclaimed ranger-hunter combat helmet modkit"
	result_item = /obj/item/clothing/head/helmet/f13/ncr/rangercombat/foxcustom

/obj/item/modkit/riotgear/rigs
	name = "11th armored calvary armor modkit"
	result_item = /obj/item/clothing/suit/armor/rangercombat/rigscustom

/obj/item/modkit/riotgear_helmet/rigs
	name = "11th armored calvary helmet modkit"
	result_item = /obj/item/clothing/head/helmet/f13/ncr/rangercombat/rigscustom

/obj/item/modkit/thax_patrol
	name = "modified patrol armor modkit"
	target_items = list(/obj/item/clothing/suit/armor/medium/combat/desert_ranger/patrol)
	result_item = /obj/item/clothing/suit/armor/medium/combat/desert_ranger/patrol/thax

/obj/item/modkit/shank
	name = "follower's duster modkit"
	target_items = list(/obj/item/clothing/suit/armor/medium/raider)
	result_item = /obj/item/clothing/suit/armor/medium/duster/follower

/*
/obj/item/modkit/custom_excess
	name = "champion of kanab's armor modkit"
	target_items = list(/obj/item/clothing/suit/armor/legion/centurion,
						/obj/item/clothing/suit/armor/legion/rangercent,
						/obj/item/clothing/suit/armor/legion/palacent)
	result_item = /obj/item/clothing/suit/armor/legion/palacent/custom_excess

/obj/item/modkit/custom_excess_helmet
	name = "champion of kanab's helm modkit"
	target_items = list(/obj/item/clothing/head/helmet/f13/legion/centurion,
						/obj/item/clothing/head/helmet/f13/legion/rangercent,
						/obj/item/clothing/head/helmet/f13/legion/palacent)
	result_item = /obj/item/clothing/head/helmet/f13/legion/palacent/custom_excess
*/

/obj/item/modkit/piper_hat
	name = "gambler's hat modkit"
	target_items = list(/obj/item/clothing/head/f13/trailranger)
	result_item = /obj/item/clothing/head/f13/flatranger

/obj/item/modkit/piper_vest
	name = "armoured poncho modkit"
	target_items = list(/obj/item/clothing/suit/armor/trailranger)
	result_item = /obj/item/clothing/suit/toggle/armor/cloakranger

/obj/item/modkit/digger_helm
	name = "salvaged riot armor modkit"
	target_items = list(/obj/item/clothing/suit/armor/medium/raider)
	result_item = /obj/item/clothing/suit/armor/light/duster/herbertranger

/obj/item/modkit/digger_vest
	name = "salvaged riot helmet modkit"
	target_items = list(/obj/item/clothing/head/helmet/f13/raider)
	result_item = /obj/item/clothing/head/helmet/f13/herbertranger

/obj/item/modkit/diohelmet
	name = "galerum lacertarex"
	target_items = list(/obj/item/clothing/head/helmet/f13/legion/venator)
	result_item = /obj/item/clothing/head/helmet/f13/legion/venator/diohelmet

/obj/item/modkit/trenchcoatfollowers
	name = "followers trenchcoat modkit"
	target_items = list(/obj/item/clothing/suit/armor/medium/vest)
	result_item = /obj/item/clothing/suit/armor/medium/vest/trench

/obj/item/modkit/patrolduster
	name = "patrol duster modkit"
	target_items = list(/obj/item/clothing/suit/armor/medium/raider)
	result_item = /obj/item/clothing/suit/armor/medium/raider/combatduster/patrolduster

/obj/item/modkit/wolfvest
	name = "subdued ranger vest modkit"
	target_items = list(/obj/item/clothing/suit/armor/medium/combat/desert_ranger/patrol)
	result_item = /obj/item/clothing/suit/armor/trailranger/modif_r_vest

//YEEHAWGUVNAH/Trinity Kemble
/obj/item/modkit/kemblevest
	name = "light riot armour modkit"
	target_items = list(/obj/item/clothing/suit/armor/trailranger)
	result_item = /obj/item/clothing/suit/armor/trailranger/kemble

/obj/item/modkit/kemblehat
	name = "ranger slouch hat modkit"
	target_items = list(/obj/item/clothing/head/f13/trailranger)
	result_item = /obj/item/clothing/head/f13/trailranger/kemble
