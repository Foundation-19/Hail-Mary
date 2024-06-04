/obj/item/reagent_containers/pill/patch
	name = "chemical patch"
	desc = "A chemical patch for touch based applications."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bandaid"
	item_state = "bandaid"
	possible_transfer_amounts = list()
	volume = 40
	apply_type = PATCH
	apply_method = "apply"
	self_delay = 30		// three seconds
	dissolvable = FALSE

/obj/item/reagent_containers/pill/patch/attack(mob/living/L, mob/user)
	if(ishuman(L))
		var/obj/item/bodypart/affecting = L.get_bodypart(check_zone(user.zone_selected))
		if(!affecting)
			to_chat(user, span_warning("The limb is missing!"))
			return
		//if(!L.can_inject(user, TRUE, user.zone_selected, FALSE, TRUE)) //stopped by clothing, not by species immunity.
			//return
		if(affecting.status != BODYPART_ORGANIC)
			to_chat(user, span_notice("Medicine won't work on a robotic limb!"))
			return
	..()

/obj/item/reagent_containers/pill/patch/canconsume(mob/eater, mob/user)
	if(!iscarbon(eater))
		return 0
	return 1 // Masks were stopping people from "eating" patches. Thanks, inheritance.

/obj/item/reagent_containers/pill/patch/styptic
	name = "brute patch"
	desc = "Helps with brute injuries."
	icon = 'icons/obj/chemical.dmi'
	list_reagents = list(/datum/reagent/medicine/styptic_powder = 20)
	icon_state = "bandaid_brute"

/obj/item/reagent_containers/pill/patch/silver_sulf
	name = "burn patch"
	desc = "Helps with burn injuries."
	icon = 'icons/obj/chemical.dmi'
	list_reagents = list(/datum/reagent/medicine/silver_sulfadiazine = 20)
	icon_state = "bandaid_burn"

/obj/item/reagent_containers/pill/patch/get_belt_overlay()
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "pouch")


// ---------------------------------
// JET

/obj/item/reagent_containers/pill/patch/jet
	name = "Jet"
	desc = "A highly addictive meta-amphetamine that produces a fast-acting, intense euphoric high on the user."
	list_reagents = list(/datum/reagent/drug/jet = 10)
	icon = 'icons/fallout/objects/medicine/drugs.dmi'
	icon_state = "patch_jet"


// ---------------------------------
// TURBO

/obj/item/reagent_containers/pill/patch/turbo
	name = "Turbo"
	desc = "A chem that vastly increases the user's reflexes and slows their perception of time."
	icon = 'icons/fallout/objects/medicine/drugs.dmi'
	icon_state = "patch_turbo"
	list_reagents = list(/datum/reagent/drug/turbo = 5)


// ---------------------------------
// HEALING POWDER

/obj/item/reagent_containers/pill/healingpowder // 50hp over 50 seconds.
	name = "Healing powder"
	desc = "A powder used to heal physical wounds derived from ground broc flowers and xander roots, commonly used by tribals."
	icon = 'icons/fallout/objects/medicine/drugs.dmi'
	icon_state = "patch_healingpowder"
	list_reagents = list(/datum/reagent/medicine/healing_powder = 10)
	self_delay = 5

/obj/item/reagent_containers/pill/healingpowder/random
	name = "randomized powder"
	desc = "A long forgotten prescription. who knows what it contains."
	color = COLOR_PALE_GREEN_GRAY

/obj/item/reagent_containers/pill/healingpowder/random/Initialize()
	list_reagents = list(get_random_reagent_id() = rand(5,15))
	var/powder_name = pick("candy", "fun", "discarded", "forgotten", "old", "ancient", "random", "unknown", "strange", "abandoned", "hobo", "trash", "forsaken", "alluring", "peculiar", "anomalous", "unfamiliar", "odd", "funny", "tasty", "neglected", "mysterious", "strange")
	name = "[powder_name] powder"
	. = ..()



// ---------------------------------
// CUSTOM POWDER

/obj/item/reagent_containers/pill/healingpowder/custom
	name = "Homebrew powder"
	desc = "A mysterious mix of powders."
	list_reagents = null
	icon = 'icons/fallout/objects/medicine/drugs.dmi'
	icon_state = "patch_healingpowder"
	self_delay = 5
	color = COLOR_PALE_GREEN_GRAY

// ---------------------------------
// HEALING POULTICE

/obj/item/reagent_containers/pill/patch/healpoultice // 100hp over 50 seconds. a bit more potent than just bitters.
	name = "Healing poultice"
	desc = "A concoction of broc flower, cave fungus, agrave fruit and xander root."
	icon = 'icons/fallout/objects/medicine/drugs.dmi'
	list_reagents = list(/datum/reagent/medicine/healing_powder/poultice = 10, /datum/reagent/medicine/healing_powder = 10, /datum/reagent/medicine/bicaridine = 5, /datum/reagent/medicine/kelotane = 5)
	icon_state = "patch_healingpoultice"
	self_delay = 5

// ---------------------------------
// BITTER DRINK

/obj/item/reagent_containers/pill/bitterdrink // 50hp over 25 seconds
	name = "Bitter drink"
	desc = "A strong herbal healing concoction invented and created by the Twin Mothers tribe."
	icon = 'icons/fallout/objects/medicine/drugs.dmi'
	icon_state = "patch_bitterdrink"
	list_reagents = list(/datum/reagent/medicine/bitter_drink = 5, /datum/reagent/medicine/bicaridine = 5, /datum/reagent/medicine/kelotane = 5) 
	self_delay = 5

/obj/item/reagent_containers/pill/patch/random
	name = "randomized patch"
	desc = "A long forgotten prescription. who knows what it contains."
	icon_state = "bandaid"

/obj/item/reagent_containers/pill/patch/random/Initialize()
	list_reagents = list(get_random_reagent_id() = rand(5,15))
	var/patch_name = pick("candy", "fun", "discarded", "forgotten", "old", "ancient", "random", "unknown", "strange", "abandoned", "hobo", "trash", "forsaken", "alluring", "peculiar", "anomalous", "unfamiliar", "odd", "funny", "tasty", "neglected", "mysterious", "strange")
	name = "[patch_name] patch"
	. = ..()

// ---------------------------------
// HYDRA - now a thing. KYS furries.

/obj/item/reagent_containers/pill/patch/hydra
	name = "Hydra"
	desc = "A potent blend of herbs and plants used by Tribals and Legionnaires alike to quickly close wounds."
	icon = 'icons/fallout/objects/medicine/drugs.dmi'
	icon_state = "patch_hydra"
	list_reagents = list(/datum/reagent/medicine/hydra = 20)
	self_delay = 0
