
/mob/living/silicon/robot/Login()
	..()
	regenerate_icons()
	show_laws(0)
	// Prompt module selection for player-controlled robots with no module chosen yet.
	// Workshop robots have their module pre-set; this only fires for classic MMI/ghost borgs.
	if(module && module.type == /obj/item/robot_module)
		INVOKE_ASYNC(src, PROC_REF(pick_module))
