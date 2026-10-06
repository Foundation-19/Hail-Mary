/obj/item/lipstick
	gender = PLURAL
	name = "red lipstick"
	desc = "A generic brand of lipstick."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "lipstick"
	w_class = WEIGHT_CLASS_TINY
	var/colour = "red"
	var/open = FALSE

/obj/item/lipstick/purple
	name = "purple lipstick"
	colour = "purple"

/obj/item/lipstick/jade
	//It's still called Jade, but theres no HTML color for jade, so we use lime.
	name = "jade lipstick"
	colour = "lime"

/obj/item/lipstick/black
	name = "black lipstick"
	colour = "black"

/obj/item/lipstick/random
	name = "lipstick"
	icon_state = "random_lipstick"

/obj/item/lipstick/random/New()
	..()
	icon_state = "lipstick"
	colour = pick("red","purple","lime","black","green","blue","white")
	name = "[colour] lipstick"

/obj/item/lipstick/attack_self(mob/user)
	cut_overlays()
	to_chat(user, span_notice("You twist \the [src] [open ? "closed" : "open"]."))
	open = !open
	if(open)
		var/mutable_appearance/colored_overlay = mutable_appearance(icon, "lipstick_uncap_color")
		colored_overlay.color = colour
		icon_state = "lipstick_uncap"
		add_overlay(colored_overlay)
	else
		icon_state = "lipstick"

/obj/item/lipstick/attack(mob/M, mob/user)
	if(!open)
		return

	if(!ismob(M))
		return

	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.is_mouth_covered())
			to_chat(user, span_warning("Remove [ H == user ? "your" : "[H.p_their()]" ] mask!"))
			return
		if(H.lip_style)	//if they already have lipstick on
			to_chat(user, span_warning("You need to wipe off the old lipstick first!"))
			return
		if(H == user)
			user.visible_message(span_notice("%SELF_NAME% does [user.p_their()] lips with \the [src]."), \
								span_notice("You take a moment to apply \the [src]. Perfect!"), visible_message_flags = ANONYMIZE_NAMES)
			H.lip_style = "lipstick"
			H.lip_color = colour
			H.update_body()
		else
			user.visible_message(span_warning("%SELF_NAME% begins to do %ACTOR_NAME%'s lips with \the [src]."), \
								span_notice("You begin to apply \the [src] on %ACTOR_NAME%'s lips..."), visible_message_flags = ANONYMIZE_NAMES, name_actor = H)
			if(do_after(user, 20, target = H))
				user.visible_message("%SELF_NAME% does %ACTOR_NAME%'s lips with \the [src].", \
									span_notice("You apply \the [src] on %ACTOR_NAME%'s lips."), visible_message_flags = ANONYMIZE_NAMES, name_actor = H)
				H.lip_style = "lipstick"
				H.lip_color = colour
				H.update_body()
	else
		to_chat(user, span_warning("Where are the lips on that?"))

//you can wipe off lipstick with paper!
/obj/item/paper/attack(mob/M, mob/user)
	if(user.zone_selected == BODY_ZONE_PRECISE_MOUTH)
		if(!ismob(M))
			return

		if(ishuman(M))
			var/mob/living/carbon/human/H = M
			if(H == user)
				to_chat(user, span_notice("You wipe off the lipstick with [src]."))
				H.lip_style = null
				H.update_body()
			else
				user.visible_message(span_warning("%SELF_NAME% begins to wipe %ACTOR_NAME%'s lipstick off with \the [src]."), \
									span_notice("You begin to wipe off %ACTOR_NAME%'s lipstick..."), visible_message_flags = ANONYMIZE_NAMES, name_actor = H)
				if(do_after(user, 10, target = H))
					user.visible_message("%SELF_NAME% wipes %ACTOR_NAME%'s lipstick off with \the [src].", \
										span_notice("You wipe off %ACTOR_NAME%'s lipstick."), visible_message_flags = ANONYMIZE_NAMES, name_actor = H)
					H.lip_style = null
					H.update_body()
	else
		..()

/obj/item/razor
	name = "electric razor"
	desc = "The latest and greatest power razor born from the science of shaving."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "razor"
	flags_1 = CONDUCT_1
	w_class = WEIGHT_CLASS_TINY

/obj/item/razor/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("%SELF_NAME% begins shaving [user.p_them()]self without the razor guard! It looks like [user.p_theyre()] trying to commit suicide!"), visible_message_flags = ANONYMIZE_NAMES)
	shave(user, BODY_ZONE_PRECISE_MOUTH)
	shave(user, BODY_ZONE_HEAD)//doesnt need to be BODY_ZONE_HEAD specifically, but whatever
	return BRUTELOSS

/obj/item/razor/proc/shave(mob/living/carbon/human/H, location = BODY_ZONE_PRECISE_MOUTH)
	if(location == BODY_ZONE_PRECISE_MOUTH)
		H.facial_hair_style = "Shaved"
	else
		H.hair_style = "Skinhead"

	H.update_hair()
	playsound(loc, 'sound/items/welder2.ogg', 20, 1)


/obj/item/razor/attack(mob/M, mob/user)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/location = user.zone_selected
		if((location in list(BODY_ZONE_PRECISE_EYES, BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_HEAD)) && !H.get_bodypart(BODY_ZONE_HEAD))
			to_chat(user, span_warning("[H] doesn't have a head!"))
			return
		if(location == BODY_ZONE_PRECISE_MOUTH)
			if(!(FACEHAIR in H.dna.species.species_traits))
				to_chat(user, span_warning("There is no facial hair to shave!"))
				return
			if(!get_location_accessible(H, location))
				to_chat(user, span_warning("The mask is in the way!"))
				return
			if(H.facial_hair_style == "Shaved")
				to_chat(user, span_warning("Already clean-shaven!"))
				return

			if(H == user) //shaving yourself
				user.visible_message("%SELF_NAME% starts to shave [user.p_their()] facial hair with [src].", \
									span_notice("You take a moment to shave your facial hair with [src]..."), visible_message_flags = ANONYMIZE_NAMES)
				if(do_after(user, 50, target = H))
					user.visible_message("%SELF_NAME% shaves [user.p_their()] facial hair clean with [src].", \
										span_notice("You finish shaving with [src]. Fast and clean!"), visible_message_flags = ANONYMIZE_NAMES)
					shave(H, location)
			else
				var/turf/H_loc = H.loc
				user.visible_message(span_warning("%SELF_NAME% tries to shave %ACTOR_NAME%'s facial hair with [src]."), \
									span_notice("You start shaving %ACTOR_NAME%'s facial hair..."), visible_message_flags = ANONYMIZE_NAMES, name_actor = H)
				if(do_after(user, 50, target = H))
					if(H_loc == H.loc)
						user.visible_message(span_warning("%SELF_NAME% shaves off %ACTOR_NAME%'s facial hair with [src]."), \
										span_notice("You shave %ACTOR_NAME%'s facial hair clean off."), visible_message_flags = ANONYMIZE_NAMES, name_actor = H)

		else if(location == BODY_ZONE_HEAD)
			if(!(HAIR in H.dna.species.species_traits))
				to_chat(user, span_warning("There is no hair to shave!"))
				return
			if(!get_location_accessible(H, location))
				to_chat(user, span_warning("The headgear is in the way!"))
				return
			if(H.hair_style == "Bald" || H.hair_style == "Balding Hair" || H.hair_style == "Skinhead")
				to_chat(user, span_warning("There is not enough hair left to shave!"))
				return

			if(H == user) //shaving yourself
				user.visible_message("%SELF_NAME% starts to shave [user.p_their()] head with [src].", \
									span_notice("You start to shave your head with [src]..."), visible_message_flags = ANONYMIZE_NAMES)
				if(do_after(user, 5, target = H))
					user.visible_message("%SELF_NAME% shaves [user.p_their()] head with [src].", \
										span_notice("You finish shaving with [src]."), visible_message_flags = ANONYMIZE_NAMES)
					shave(H, location)
			else
				var/turf/H_loc = H.loc
				user.visible_message(span_warning("%SELF_NAME% tries to shave %ACTOR_NAME%'s head with [src]!"), \
									span_notice("You start shaving %ACTOR_NAME%'s head..."), visible_message_flags = ANONYMIZE_NAMES, name_actor = H)
				if(do_after(user, 50, target = H))
					if(H_loc == H.loc)
						user.visible_message(span_warning("%SELF_NAME% shaves %ACTOR_NAME%'s head bald with [src]!"), \
										span_notice("You shave %ACTOR_NAME%'s head bald."), visible_message_flags = ANONYMIZE_NAMES, name_actor = H)
						shave(H, location)
		else
			..()
	else
		..()
