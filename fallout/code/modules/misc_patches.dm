/mob/living/Login()
	. = ..()
	HandlePopupMenu()

TYPE_PROC_REF(/mob/living, HandlePopupMenu)()
	if(!client)
		return
	
	if(enabled_combat_indicator)
		client.show_popup_menus = FALSE
	else
		client.show_popup_menus = TRUE


/obj/item/reagent_containers/food/drinks/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ATOM_LICKED, PROC_REF(LapDrink))


/obj/item/reagent_containers/food/drinks/Destroy()
	. = ..()
	UnregisterSignal(src, COMSIG_ATOM_LICKED)

TYPE_PROC_REF(/obj/item/reagent_containers/food/drinks, LapDrink)(atom/A, mob/living/carbon/licker, obj/item/hand_item/tongue)
	if(!iscarbon(licker) || !tongue)
		return FALSE

	attack(licker, licker, licker.get_organ_target())
