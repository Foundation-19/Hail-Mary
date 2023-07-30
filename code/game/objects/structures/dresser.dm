/obj/structure/dresser
	name = "dresser"
	desc = "A nicely-crafted wooden dresser. It's filled with lots of undies."
	icon = 'icons/fallout/objects/furniture/stationary.dmi'
	icon_state = "dresser"
	density = TRUE
	anchored = TRUE

/obj/structure/dresser/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/wrench))
		to_chat(user, span_notice("You begin to [anchored ? "unwrench" : "wrench"] [src]."))
		if(I.use_tool(src, user, 20, volume=50))
			to_chat(user, span_notice("You successfully [anchored ? "unwrench" : "wrench"] [src]."))
			setAnchored(!anchored)
	else
		return ..()

/obj/structure/dresser/deconstruct(disassembled = TRUE)
	new /obj/item/stack/sheet/mineral/wood(drop_location(), 10)
	qdel(src)

/obj/structure/dresser/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(. || !ishuman(user) || !user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	var/mob/living/carbon/human/H = user

	if(H.dna && H.dna.species && (NO_UNDERWEAR in H.dna.species.species_traits))
		to_chat(H, span_warning("You are not capable of wearing underwear."))
		return

	add_fingerprint(H)
	H.update_body(TRUE)

/obj/structure/dresser/proc/recolor_undergarment(mob/living/carbon/human/H, garment_type = "underwear", default_color)
	var/n_color = input(H, "Choose your [garment_type]'\s color.", "Character Preference", default_color) as color|null
	if(!n_color || !H.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return default_color
	return sanitize_hexcolor(n_color, 3, FALSE, default_color)

/obj/structure/dresser/modern
	desc = "A dresser in a modern circular style."
	icon_state = "dresser_retro"

/obj/structure/dresser/modern2
	desc = "A dresser in a modern circular style."
	icon_state = "dresser_retro2"
