/obj/item/caution
	desc = "Caution! Wet Floor!"
	name = "wet floor sign"
	icon = 'icons/obj/janitor.dmi'
	icon_state = "caution"
	lefthand_file = 'icons/mob/inhands/equipment/custodial_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/custodial_righthand.dmi'
	force = 1
	throwforce = 3
	throw_speed = 2
	throw_range = 5
	w_class = WEIGHT_CLASS_SMALL
	attack_verb = list("warned", "cautioned", "smashed")

/obj/item/choice_beacon
	name = "choice beacon"
	desc = "Hey, why are you viewing this?!! Please let Centcom know about this odd occurance."
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-blue"
	item_state = "radio"
	var/list/stored_options
	var/force_refresh = FALSE

/obj/item/choice_beacon/attack_self(mob/user)
	if(canUseBeacon(user))
		generate_options(user)

/obj/item/choice_beacon/proc/generate_display_names()
	return list()

/obj/item/choice_beacon/proc/canUseBeacon(mob/living/user)
	if(user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return TRUE
	else
		playsound(src, 'sound/machines/buzz-sigh.ogg', 40, 1)
		return FALSE

/obj/item/choice_beacon/proc/generate_options(mob/living/M)
	if(!stored_options || force_refresh)
		stored_options = generate_display_names()
	if(!stored_options.len)
		return
	var/choice = input(M,"Which item would you like to order?","Select an Item") as null|anything in stored_options
	if(!choice || !M.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return

	spawn_option(stored_options[choice],M)
	qdel(src)

/obj/item/choice_beacon/proc/create_choice_atom(atom/choice, mob/owner)
	return new choice()

/obj/item/choice_beacon/proc/spawn_option(atom/choice,mob/living/M)
	var/obj/new_item = create_choice_atom(choice, M)
	var/obj/structure/closet/supplypod/bluespacepod/pod = new()
	pod.explosionSize = list(0,0,0,0)
	new_item.forceMove(pod)
	var/msg = span_danger("After making your selection, you notice a strange target on the ground. It might be best to step back!")
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(istype(H.ears, /obj/item/radio/headset))
			msg = "You hear something crackle in your ears for a moment before a voice speaks. \"Please stand by for a message from Central Command. Message as follows: <span class='bold'>Item request received. Your package is inbound, please stand back from the landing site.</span> Message ends.\""
	to_chat(M, msg)

	new /obj/effect/abstract/DPtarget(get_turf(src), pod)

/obj/item/choice_beacon/ingredients
	name = "ingredient box delivery beacon"
	desc = "Summon a box of ingredients from a wide selection!"
	icon_state = "gangtool-red"

/obj/item/choice_beacon/ingredients/generate_display_names()
	var/static/list/ingredientboxes
	if(!ingredientboxes)
		ingredientboxes = list()
		var/list/templist = typesof(/obj/item/storage/box/ingredients)
		for(var/V in templist)
			var/obj/item/storage/box/ingredients/A = V
			ingredientboxes[initial(A.theme_name)] = A
	return ingredientboxes

/obj/item/choice_beacon/hero
	name = "heroic beacon"
	desc = "To summon heroes from the past to protect the future."

/obj/item/choice_beacon/hero/generate_display_names()
	var/static/list/hero_item_list
	if(!hero_item_list)
		hero_item_list = list()
		var/list/templist = typesof(/obj/item/storage/box/hero)
		for(var/V in templist)
			var/atom/A = V
			hero_item_list[initial(A.name)] = A
	return hero_item_list

/obj/item/storage/box/hero
	name = "Courageous Tomb Raider - 1940's."

/obj/item/storage/box/hero/PopulateContents()
	new /obj/item/clothing/head/fedora/curator(src)
	new /obj/item/clothing/suit/curator(src)
	new /obj/item/clothing/under/rank/civilian/curator/treasure_hunter(src)
	new /obj/item/clothing/shoes/workboots/mining(src)

/obj/item/storage/box/hero/astronaut
	name = "First Man on the Moon - 1960's."

/obj/item/storage/box/hero/astronaut/PopulateContents()
	new /obj/item/clothing/suit/space/nasavoid(src)
	new /obj/item/clothing/head/helmet/space/nasavoid(src)
	new /obj/item/tank/internals/emergency_oxygen/double(src)
	new /obj/item/gps(src)

/obj/item/storage/box/hero/scottish
	name = "Braveheart, the Scottish rebel - 1300's."

/obj/item/storage/box/hero/scottish/PopulateContents()
	new /obj/item/clothing/under/costume/kilt(src)
	new /obj/item/claymore/weak/ceremonial(src)
	new /obj/item/toy/crayon/spraycan(src)
	new /obj/item/clothing/shoes/sandal(src)

/obj/item/choice_beacon/hosgun
	name = "personal weapon beacon"
	desc = "Use this to summon your personal Head of Security issued firearm!"

/obj/item/choice_beacon/hosgun/generate_display_names()
	var/static/list/hos_gun_list
	if(!hos_gun_list)
		hos_gun_list = list()
		var/list/templist = subtypesof(/obj/item/storage/secure/briefcase/hos/)
		for(var/V in templist)
			var/atom/A = V
			hos_gun_list[initial(A.name)] = A
	return hos_gun_list

/obj/item/choice_beacon/augments
	name = "augment beacon"
	desc = "Summons augmentations."

/obj/item/choice_beacon/augments/generate_display_names()
	var/static/list/augment_list
	if(!augment_list)
		augment_list = list()
		var/list/templist = list(
			/obj/item/organ/cyberimp/brain/anti_drop,
			/obj/item/organ/cyberimp/arm/toolset,
			/obj/item/organ/cyberimp/chest/nutriment/plus,
			/obj/item/organ/cyberimp/arm/esword,
			/obj/item/organ/cyberimp/arm/surgery,
			/obj/item/organ/lungs/cybernetic,
			/obj/item/organ/liver/cybernetic
		)
		for(var/V in templist)
			var/atom/A = V
			augment_list[initial(A.name)] = A
	return augment_list

/obj/item/choice_beacon/augments/spawn_option(atom/choice,mob/living/M)
	new choice(get_turf(M))
	to_chat(M, span_hear("You hear something crackle from the beacon for a moment before a voice speaks. \"Please stand by for a message from S.E.L.F. Message as follows: <b>Item request received. Your package has been transported, use the autosurgeon supplied to apply the upgrade.</b> Message ends.\""))

/obj/item/choice_beacon/pet
	name = "pet beacon"
	desc = "Straight from the outerspace pet shop to your feet."
	var/list/pets = list(
		"Brahmin" = /mob/living/simple_animal/cow/brahmin,
		"Chicken" = /mob/living/simple_animal/chicken,
		"Corgi" = /mob/living/simple_animal/pet/dog/corgi,
		"Pug" = /mob/living/simple_animal/pet/dog/pug,
		"Fox" = /mob/living/simple_animal/pet/fox,
		"Red Panda" = /mob/living/simple_animal/pet/redpanda,
		"Mouse" = /mob/living/simple_animal/mouse,
		"Cat" = /mob/living/simple_animal/pet/cat
	)
	var/pet_name

/obj/item/choice_beacon/pet/generate_display_names()
	return pets

/obj/item/choice_beacon/pet/create_choice_atom(atom/choice, mob/owner)
	var/mob/living/simple_animal/new_pet = new choice(get_turf(owner))
	new_pet.butcher_results = null
	new_pet.mob_size = MOB_SIZE_TINY
	new_pet.pass_flags = PASSTABLE | PASSMOB
	new_pet.density = FALSE
	new_pet.blood_volume = 0
	new_pet.desc = "A pet [initial(choice.name)], owned by [owner]!"
	new_pet.can_have_ai = FALSE
	
	if(pet_name)
		new_pet.name = pet_name
		new_pet.unique_name = TRUE
	
	return new_pet

/obj/item/choice_beacon/pet/spawn_option(atom/choice, mob/living/M)
	pet_name = input(M, "What would you like to name the pet? (leave blank for default name)", "Pet Name")
	..()  // Parent handles everything

/obj/item/choice_beacon/pet/mountable
	name = "mount beacon"
	desc = "Straight from the outerspace mount shop to your feet."
	pets = list(
		"Brahmin" = /mob/living/simple_animal/cow/brahmin,
		"Molerat" = /mob/living/simple_animal/cow/brahmin/molerat,
		"Horse" = /mob/living/simple_animal/cow/brahmin/horse,
		"Nightstalker" = /mob/living/simple_animal/cow/brahmin/nightstalker,
		"Hunter Spider" = /mob/living/simple_animal/cow/brahmin/nightstalker/hunterspider
	)

/obj/item/choice_beacon/cars
	name = "Cars beacon"
	desc = "Hey you found your keys !"
	var/list/cars = list(
		"Fully Equipped Blue Pickup" = /obj/mecha/working/normalvehicle/pickuptruck/blue/loaded,
		"Fully Equipped Red Pickup" = /obj/mecha/working/normalvehicle/pickuptruck/loaded,
		"Fully Equipped Dune Buggy" = /obj/mecha/working/normalvehicle/buggy/dune/loaded,
		"Fully Equipped Blue Buggy" = /obj/mecha/working/normalvehicle/buggy/blue/loaded,
		"Fully Equipped Red Buggy" = /obj/mecha/working/normalvehicle/buggy/red/loaded,
		"Fully Equipped Olive Buggy" = /obj/mecha/working/normalvehicle/buggy/loaded,
		"Unequipped Jeep" = /obj/mecha/working/normalvehicle/jeep,
		"Unequipped Corvega" = /obj/mecha/working/normalvehicle/corvega
	)

/obj/item/choice_beacon/cars/generate_display_names()
	return cars

/obj/item/choice_beacon/cars/cheap
	name = "Cheap Cars beacon"
	desc = "Hey you found your keys !... Its either a Cheap caravan, or a under equipped vehicle"
	cars = list(
		"Fully Equipped Caravan Truck" = /obj/mecha/working/normalvehicle/truckcaravan/loaded,
		"Unequipped Blue Pickup" = /obj/mecha/working/normalvehicle/pickuptruck/blue,
		"Unequipped Red Pickup" = /obj/mecha/working/normalvehicle/pickuptruck,
		"Unequipped Dune Buggy" = /obj/mecha/working/normalvehicle/buggy/dune,
		"Unequipped Blue Buggy" = /obj/mecha/working/normalvehicle/buggy/blue,
		"Unequipped Red Buggy" = /obj/mecha/working/normalvehicle/buggy/red,
		"Unequipped Olive Buggy" = /obj/mecha/working/normalvehicle/buggy
	)

/obj/item/choice_beacon/cars/nice
	name = "Nice Cars beacon"
	desc = "Hey you found your keys !"
	cars = list(
		"Fully Equipped Jeep" = /obj/mecha/working/normalvehicle/jeep/loaded,
		"Fully Equipped Corvega" = /obj/mecha/working/normalvehicle/corvega/loaded,
		"Fully Equipped Highwayman Eco" = /obj/mecha/working/normalvehicle/highwayman/loaded
	)

/obj/item/choice_beacon/box
	name = "choice box (default)"
	desc = "Think really hard about what you want, and then rip it open!"
	icon = 'icons/obj/storage.dmi'
	icon_state = "deliverypackage3"
	item_state = "deliverypackage3"

/obj/item/choice_beacon/box/spawn_option(atom/choice,mob/living/M)
	var/choice_text = choice
	if(ispath(choice_text))
		choice_text = initial(choice.name)
	to_chat(M, span_hear("The box opens, revealing the [choice_text]!"))
	playsound(src.loc, 'sound/items/poster_ripped.ogg', 50, 1)
	M.temporarilyRemoveItemFromInventory(src, TRUE)
	M.put_in_hands(new choice)
	qdel(src)

/obj/item/choice_beacon/box/plushie
	name = "choice box (plushie)"
	desc = "Using the power of quantum entanglement, this box contains every plush, until the moment it is opened!"
	icon = 'icons/obj/plushes.dmi'
	icon_state = "box"
	item_state = "box"

/obj/item/choice_beacon/box/plushie/generate_display_names()
	var/static/list/plushie_list
	if(!plushie_list)
		plushie_list = list()
		//regular plushies
		var/list/plushies = subtypesof(/obj/item/toy/plush) - list(
			/obj/item/toy/plush/narplush,
			/obj/item/toy/plush/awakenedplushie,
			/obj/item/toy/plush/random_snowflake,
			/obj/item/toy/plush/plushling
		)
		for(var/V in plushies)
			var/atom/A = V
			plushie_list[initial(A.name)] = A
		//snowflake plushies
		var/list/snowflakes = CONFIG_GET(keyed_list/snowflake_plushies)
		for(var/V in snowflakes)
			plushie_list[V] = V
	return plushie_list

/obj/item/choice_beacon/box/plushie/spawn_option(choice,mob/living/M)
	if(ispath(choice, /obj/item/toy/plush))
		..()
	else
		//snowflake plush
		var/obj/item/toy/plush/snowflake_plushie = new(get_turf(M))
		snowflake_plushie.set_snowflake_from_config(choice)
		M.temporarilyRemoveItemFromInventory(src, TRUE)
		M.put_in_hands(snowflake_plushie)
		qdel(src)

/obj/item/choice_beacon/box/carpet
	name = "choice box (carpet)"
	desc = "Contains 50 of a selected carpet inside!"
	var/static/list/carpet_list = list(
		"Carpet Carpet" = /obj/item/stack/tile/carpet/fifty,
		"Black Carpet" = /obj/item/stack/tile/carpet/black/fifty,
		"Black & Red Carpet" = /obj/item/stack/tile/carpet/blackred/fifty,
		"Monochrome Carpet" = /obj/item/stack/tile/carpet/monochrome/fifty,
		"Blue Carpet" = /obj/item/stack/tile/carpet/blue/fifty,
		"Cyan Carpet" = /obj/item/stack/tile/carpet/cyan/fifty,
		"Green Carpet" = /obj/item/stack/tile/carpet/green/fifty,
		"Orange Carpet" = /obj/item/stack/tile/carpet/orange/fifty,
		"Purple Carpet" = /obj/item/stack/tile/carpet/purple/fifty,
		"Red Carpet" = /obj/item/stack/tile/carpet/red/fifty,
		"Royal Black Carpet" = /obj/item/stack/tile/carpet/royalblack/fifty,
		"Royal Blue Carpet" = /obj/item/stack/tile/carpet/royalblue/fifty
	)

/obj/item/choice_beacon/box/carpet/generate_display_names()
	return carpet_list

/obj/item/choice_beacon/weapon
	name = "weapon crate"
	desc = "choose your weapon."
	icon = 'icons/obj/crates.dmi'
	icon_state = "weaponcrate"
	item_state = "syringe_kit"

/obj/item/choice_beacon/weapon/follower
	name = "Follower of the Apocalypse standard issue self-defense weapon crate"
	desc = "Has that weapon you ordered"
	var/static/list/follower_guns = list(
		"non-lethal" = /obj/item/gun/energy/laser/complianceregulator,
		"lethal, energy" = /obj/item/gun/energy/laser/wattz,
		"lethal, ballistics" = /obj/item/gun/ballistic/revolver/colt357
	)

/obj/item/choice_beacon/weapon/follower/generate_display_names()
	return follower_guns

/obj/item/choice_beacon/weapon/wastelander
	name = "personal weapon stash"
	desc = "contains your personal weapon, whatever it may be"
	var/static/list/wastelander_guns = list(
		"M1911" = /obj/item/gun/ballistic/automatic/pistol/m1911,
		"N99, 10mm" = /obj/item/gun/ballistic/automatic/pistol/n99,
		".357 Police Pistol" = /obj/item/gun/ballistic/revolver/police,
		".357 Single Action Revolver" = /obj/item/gun/ballistic/revolver/colt357,
		"5.56mm Varmint Rifle" = /obj/item/gun/ballistic/automatic/varmint
	)

/obj/item/choice_beacon/weapon/wastelander/generate_display_names()
	return wastelander_guns
