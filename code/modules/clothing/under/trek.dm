//Just some alt-uniforms themed around Star Trek - Pls don't sue, Mr Roddenberry ;_;


/obj/item/clothing/under/trek
	name = "Section 31 Uniform"
	desc = "Oooh... right."
	item_state = ""
	can_adjust = FALSE	//to prevent you from "wearing it casually"


//TOS
/obj/item/clothing/under/trek/command
	name = "command uniform"
	desc = "The uniform worn by command officers in the mid 2260s."
	icon_state = "trek_command"
	item_state = "y_suit"

/obj/item/clothing/under/trek/engsec
	name = "operations uniform"
	desc = "The uniform worn by operations officers of the mid 2260s. You feel strangely vulnerable just seeing this..."
	icon_state = "trek_engsec"
	item_state = "r_suit"
	strip_delay = 50

/obj/item/clothing/under/trek/medsci
	name = "medsci uniform"
	desc = "The uniform worn by medsci officers in the mid 2260s."
	icon_state = "trek_medsci"
	item_state = "b_suit"
	permeability_coefficient = 0.50


//TNG
/obj/item/clothing/under/trek/command/next
	desc = "The uniform worn by command officers. This one's from the mid 2360s."
	icon_state = "trek_next_command"
	item_state = "r_suit"

/obj/item/clothing/under/trek/engsec/next
	desc = "The uniform worn by operation officers. This one's from the mid 2360s."
	icon_state = "trek_next_engsec"
	item_state = "y_suit"

/obj/item/clothing/under/trek/medsci/next
	desc = "The uniform worn by medsci officers. This one's from the mid 2360s."
	icon_state = "trek_next_medsci"
	item_state = "b_suit"


//ENT
/obj/item/clothing/under/trek/command/ent
	desc = "The uniform worn by command officers of the 2140s."
	icon_state = "trek_ent_command"
	item_state = "bl_suit"

/obj/item/clothing/under/trek/engsec/ent
	desc = "The uniform worn by operations officers of the 2140s."
	icon_state = "trek_ent_engsec"
	item_state = "bl_suit"

/obj/item/clothing/under/trek/medsci/ent
	desc = "The uniform worn by medsci officers of the 2140s."
	icon_state = "trek_ent_medsci"
	item_state = "bl_suit"


//VOY
/obj/item/clothing/under/trek/command/voy
	desc = "The uniform worn by command officers of the 2370s."
	icon_state = "trek_voy_command"
	item_state = "r_suit"

/obj/item/clothing/under/trek/engsec/voy
	desc = "The uniform worn by operations officers of the 2370s."
	icon_state = "trek_voy_engsec"
	item_state = "y_suit"

/obj/item/clothing/under/trek/medsci/voy
	desc = "The uniform worn by medsci officers of the 2370s."
	icon_state = "trek_voy_medsci"
	item_state = "b_suit"


//DS9
/obj/item/clothing/under/trek/command/ds9
	desc = "The uniform worn by command officers of the 2380s."
	icon_state = "trek_ds9_command"
	item_state = "r_suit"

/obj/item/clothing/under/trek/engsec/ds9
	desc = "The uniform worn by operations officers of the 2380s."
	icon_state = "trek_ds9_engsec"
	item_state = "y_suit"

/obj/item/clothing/under/trek/medsci/ds9
	desc = "The uniform undershirt worn by medsci officers of the 2380s."
	icon_state = "trek_ds9_medsci"
	item_state = "b_suit"

//Orvilike (Orville-inspired clothing with TOS-like color code)
/obj/item/clothing/under/trek/command/orv
	desc = "An uniform worn by command officers since 2420s."
	icon_state = "orv_com"

/obj/item/clothing/under/trek/engsec/orv
	desc = "An uniform worn by operations officers since 2420s."
	icon_state = "orv_ops"

/obj/item/clothing/under/trek/medsci/orv
	desc = "An uniform worn by medsci officers since 2420s."
	icon_state = "orv_medsci"

//Orvilike Extra (Ditto, but expands it for Civilian department with SS13 colors and gives specified command uniform)
//honestly no idea why i added specified comm. uniforms but w/e
/obj/item/clothing/under/trek/command/orv/captain
	name = "captain uniform"
	desc = "An uniform worn by captains since 2550s."
	icon_state = "orv_com_capt"

/obj/item/clothing/under/trek/command/orv/engsec
	name = "operations command uniform"
	desc = "An uniform worn by operations command officers since 2550s."
	icon_state = "orv_com_ops"

/obj/item/clothing/under/trek/command/orv/medsci
	name = "medsci command uniform"
	desc = "An uniform worn by medsci command officers since 2550s."
	icon_state = "orv_com_medsci"

/obj/item/clothing/under/trek/orv
	name = "adjutant uniform"
	desc = "An uniform worn by adjutants <i>(assistants)</i> since 2550s."
	icon_state = "orv_ass"
	item_state = "gy_suit"

/obj/item/clothing/under/trek/orv/service
	name = "service uniform"
	desc = "An uniform worn by service officers since 2550s."
	icon_state = "orv_srv"
	item_state = "g_suit"

//The Motion Picture
/obj/item/clothing/under/trek/fedutil
	name = "federation utility uniform"
	desc = "The uniform worn by United Federation enlisted crew members in 2285s."
	icon_state = "trek_tmp_enlist"
	item_state = "r_suit"

/obj/item/clothing/under/trek/fedutil/trainee
	name = "federation trainee utility uniform"
	desc = "The uniform worn by United Federation enlisted trainees in 2285s."
	icon_state = "trek_tmp_trainee"

/obj/item/clothing/under/trek/fedutil/service
	name = "federation service uniform"
	desc = "The uniform worn by United Federation enlists for service work in 2285s."
	icon_state = "trek_tmp_service"

//Q
/obj/item/clothing/under/trek/Q
	name = "french marshall's uniform"
	desc = "Something about it feels off..."
	icon_state = "trek_Q"
	item_state = "r_suit"


// ==================== Merged from fallout (code\modules\fallout\code\modules\clothing\trek.dm) ====================
/*/////////////////////////////////////////////////////////////////////////////////
///////																		///////
///////								Star Trek Stuffs						///////
///////																		///////
*//////////////////////////////////////////////////////////////////////////////////
//  <3 Nienhaus && Joan.
// I made the Voy and DS9 stuff tho. - Poojy
// Armor lists for even Heads of Staff is Nulled out do round start armor as well most armor going onto the suit itself rather then a armor slot - Trilby
///////////////////////////////////////////////////////////////////////////////////

//DS9

/obj/item/clothing/suit/storage/trek/ds9
	name = "Padded Overcoat"
	desc = "The overcoat worn by all officers of the 2380s."
	icon = 'icons/obj/clothing/trek_item_icon.dmi'
	icon_state = "trek_ds9_coat"
	mob_overlay_icon = 'icons/mob/clothing/trek_mob_icon.dmi'
	item_state = "trek_ds9_coat"
	body_parts_covered = CHEST|GROIN|ARMS
	mutantrace_variation = STYLE_DIGITIGRADE
	permeability_coefficient = 0.50
	allowed = list(
		/obj/item/flashlight, /obj/item/analyzer,
		/obj/item/radio, /obj/item/tank/internals/emergency_oxygen,
		/obj/item/reagent_containers/hypospray, /obj/item/healthanalyzer,/obj/item/reagent_containers/syringe,
		/obj/item/reagent_containers/glass/bottle/vial,/obj/item/reagent_containers/glass/beaker,
		/obj/item/reagent_containers/pill,/obj/item/storage/pill_bottle, /obj/item/restraints/handcuffs,/obj/item/hypospray
		)
	armor = ARMOR_VALUE_LIGHT

/obj/item/clothing/suit/storage/trek/ds9/admiral // Only for adminuz
	name = "Admiral Overcoat"
	desc = "Admirality specialty coat to keep flag officers fashionable and protected."
	icon_state = "trek_ds9_coat_adm"
	item_state = "trek_ds9_coat_adm"
	permeability_coefficient = 0.01
	armor = ARMOR_VALUE_LIGHT

//MODERN ish Joan sqrl sprites. I think

//For general use
/obj/item/clothing/suit/storage/fluff/fedcoat
	name = "Federation Uniform Jacket"
	desc = "A uniform jacket from the United Federation. Set phasers to awesome."
	icon = 'icons/obj/clothing/trek_item_icon.dmi'
	mob_overlay_icon = 'icons/mob/clothing/trek_mob_icon.dmi'
	icon_state = "fedcoat"
	item_state = "fedcoat"
	mutantrace_variation = STYLE_DIGITIGRADE
	blood_overlay_type = "coat"
	body_parts_covered = CHEST|GROIN|ARMS
	allowed = list(
				/obj/item/tank/internals/emergency_oxygen,
				/obj/item/flashlight,
				/obj/item/analyzer,
				/obj/item/radio,
				/obj/item/gun,
				/obj/item/melee/baton,
				/obj/item/restraints/handcuffs,
				/obj/item/reagent_containers/hypospray,
				/obj/item/hypospray,
				/obj/item/healthanalyzer,
				/obj/item/reagent_containers/syringe,
				/obj/item/reagent_containers/glass/bottle/vial,
				/obj/item/reagent_containers/glass/beaker,
				/obj/item/storage/pill_bottle,
				/obj/item/taperecorder)
	armor = ARMOR_VALUE_LIGHT
	var/unbuttoned = 0

	verb/toggle()
		set name = "Toggle coat buttons"
		set category = "Object"
		set src in usr

		var/mob/living/L = usr
		if(!istype(L) || !CHECK_MOBILITY(L, MOBILITY_USE))
			return FALSE

		switch(unbuttoned)
			if(0)
				icon_state = "[initial(icon_state)]_open"
				item_state = "[initial(item_state)]_open"
				unbuttoned = 1
				to_chat(usr,"You unbutton the coat.")
			if(1)
				icon_state = "[initial(icon_state)]"
				item_state = "[initial(item_state)]"
				unbuttoned = 0
				to_chat(usr,"You button up the coat.")
		usr.update_inv_wear_suit()

	//Variants
/obj/item/clothing/suit/storage/fluff/fedcoat/medsci
		icon_state = "fedblue"
		item_state = "fedblue"

/obj/item/clothing/suit/storage/fluff/fedcoat/eng
		icon_state = "fedeng"
		item_state = "fedeng"

/obj/item/clothing/suit/storage/fluff/fedcoat/capt
		icon_state = "fedcapt"
		item_state = "fedcapt"

//"modern" ones for fancy

/obj/item/clothing/suit/storage/fluff/modernfedcoat
	name = "Modern Federation Uniform Jacket"
	desc = "A modern uniform jacket from the United Federation."
	icon = 'icons/obj/clothing/trek_item_icon.dmi'
	mob_overlay_icon = 'icons/mob/clothing/trek_mob_icon.dmi'
	icon_state = "fedmodern"
	item_state = "fedmodern"
	mutantrace_variation = STYLE_DIGITIGRADE
	body_parts_covered = CHEST|GROIN|ARMS
	allowed = list(
		/obj/item/flashlight, /obj/item/analyzer,
		/obj/item/radio, /obj/item/tank/internals/emergency_oxygen,
		/obj/item/reagent_containers/hypospray, /obj/item/healthanalyzer,/obj/item/reagent_containers/syringe,
		/obj/item/reagent_containers/glass/bottle/vial,/obj/item/reagent_containers/glass/beaker,
		/obj/item/reagent_containers/pill,/obj/item/storage/pill_bottle, /obj/item/restraints/handcuffs,/obj/item/hypospray
		)
	armor = ARMOR_VALUE_LIGHT

	//Variants
/obj/item/clothing/suit/storage/fluff/modernfedcoat/medsci
		icon_state = "fedmodernblue"
		item_state = "fedmodernblue"

/obj/item/clothing/suit/storage/fluff/modernfedcoat/eng
		icon_state = "fedmoderneng"
		item_state = "fedmoderneng"

/obj/item/clothing/suit/storage/fluff/modernfedcoat/sec
		icon_state = "fedmodernsec"
		item_state = "fedmodernsec"

/obj/item/clothing/head/caphat/formal/fedcover
	name = "Federation Officer's Cap"
	armor = ARMOR_VALUE_LIGHT
	desc = "An officer's cap that demands discipline from the one who wears it."
	icon = 'icons/obj/clothing/trek_item_icon.dmi'
	icon_state = "fedcapofficer"
	mob_overlay_icon = 'icons/mob/clothing/trek_mob_icon.dmi'
	item_state = "fedcapofficer"

	//Variants
/obj/item/clothing/head/caphat/formal/fedcover/medsci
		icon_state = "fedcapsci"
		item_state = "fedcapsci"

/obj/item/clothing/head/caphat/formal/fedcover/eng
		icon_state = "fedcapeng"
		item_state = "fedcapeng"

/obj/item/clothing/head/caphat/formal/fedcover/sec
		icon_state = "fedcapsec"
		item_state = "fedcapsec"

/obj/item/clothing/head/caphat/formal/fedcover/black
		icon_state = "fedcapblack"
		item_state = "fedcapblack"

//orvilike caps
/obj/item/clothing/head/kepi/orvi
	name = "\improper Federation kepi"
	desc = "A visored cap worn by all officers since 2550s."
	icon_state = "kepi_ass"

/obj/item/clothing/head/kepi/orvi/command
	icon_state = "kepi_com"

/obj/item/clothing/head/kepi/orvi/engsec
	icon_state = "kepi_ops"

/obj/item/clothing/head/kepi/orvi/medsci
	icon_state = "kepi_medsci"

/obj/item/clothing/head/kepi/orvi/service
	icon_state = "kepi_srv"
