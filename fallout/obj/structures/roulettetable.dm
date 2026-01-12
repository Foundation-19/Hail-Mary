
/obj/structure/table/roulette
	name = "roulette table"
	desc = "A table with a roulette wheel. The wheel is of a 'single zero' design."
	icon = 'icons/fallout/machines/roulette_table.dmi'
	icon_state = "roulette"
	layer = TABLE_LAYER
	smooth = SMOOTH_FALSE
	max_integrity = 100
	bound_width = 64
	var/working = FALSE
	var/result
	var/spin_timer = 30

/obj/structure/table/roulette/wrench_act(mob/living/user, obj/item/I)
	if(working)
		to_chat(user, span_warning("You cannot unwrench the table during operation!"))
		return FALSE
	default_unfasten_wrench(user, I)
	return TRUE

/obj/structure/table/roulette/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(working)
		to_chat(user, span_warning("The wheel is already spinning!"))
		return
	if(!anchored)
		to_chat(user, span_warning("The table must be secured before spinning!"))
		return
	spinroulettewheel(user)

/obj/structure/table/roulette/proc/spinroulettewheel(mob/user)
	visible_message(span_notice("[user] spins the roulette wheel!"))
	working = TRUE
	update_icon()
	playsound(src, 'sound/f13machines/roulette_wheel.ogg', 50, 1)

	spawn(spin_timer)
		result = rand(0,36)
		var/comment = ""
		//if result
		if(result in list(1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,35,36))
			comment = "Red!"
		else if(result in list(2,4,6,8,10,11,13,15,17,20,22,24,26,28,29,31,33))
			comment = "Black!"
		else
			comment = "Zero!"
		visible_message("The roulette wheel lands on [result]. [comment]")
		working = FALSE
		update_icon()

/obj/structure/table/roulette/update_icon()
	if(working)
		icon_state = "roulette_act"
	else
		icon_state = "roulette"



/*  Will be added eventually.
/datum/crafting_recipe/roulette
	name = "Roulette Table"
	result = /obj/structure/table/roulette
	reqs = list(/obj/item/stack/sheet/mineral/wood = 5,
				/obj/item/stack/sheet/cloth = 5,
				/obj/item/stack/sheet/metal = 5)
	tools = list(TOOL_WRENCH, TOOL_SCREWDRIVER)
	time = 80
	subcategory = CAT_MISCELLANEOUS
	category = CAT_MISC
*/
