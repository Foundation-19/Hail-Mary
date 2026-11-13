//////////////////////////////////////////
//										//
//		SMITHED ITEMS BASE CODE			//
//										//
//////////////////////////////////////////

/obj/item/blacksmith
	icon = 'icons/obj/blacksmith_bd2.dmi'
	righthand_file = 'icons/onmob/righthand.dmi'
	lefthand_file = 'icons/onmob/lefthand.dmi'
	force = WEAPON_FORCE_BIG_TOOL
	max_integrity = 40
	w_class = WEIGHT_CLASS_SMALL

/obj/item/smithing
	name = "base class /obj/item/smithing"
	desc = "Attach a wooden rod."
	icon = 'icons/obj/blacksmith_bd2.dmi'
	icon_state = "unfinished"
	material_flags = MATERIAL_COLOR | MATERIAL_ADD_PREFIX
	light_system = MOVABLE_LIGHT
	light_range = 1
	light_power = GLOW_WEAK
	light_color = LIGHT_COLOR_FIRE
	light_on = FALSE
	var/quality = 0 //quality. Changed by the smithing process.
	var/obj/item/finishingitem = WOODEN_ROD //What this item needs to be hit by to create finalitem
	var/obj/item/finalitem
	var/artifact = FALSE
	var/toohot = TRUE // Too hot to touch with bare hands, not tempered yet
	var/finishing_touch // The final step when this item was created
	var/quality_locked = FALSE
	var/quench_started_at = 0
	var/quench_medium = null
	var/forging_steps = 0
	var/bright_forging_steps = 0
	var/final_forging_stress = 0
	var/peak_forging_stress = 0
	var/cracked_during_forging = FALSE
	var/recipe_string
	var/forging_used_flux = FALSE
	var/differential_hardening = FALSE
	var/differential_hardening_allowed = FALSE
	var/pattern_welded = FALSE

/obj/item/smithing/proc/get_preferred_quench()
	if(!islist(custom_materials))
		return "water"
	// custom_materials keys are material datum refs once set_custom_materials() runs, not type paths.
	for(var/material_key in custom_materials)
		var/datum/material/material = SSmaterials.GetMaterialRef(material_key)
		if(istype(material, /datum/material/adamantine) || istype(material, /datum/material/titanium))
			return "oil"
	return "water"

/obj/item/smithing/proc/apply_quench(medium)
	if(quality_locked || !toohot)
		return FALSE
	quench_medium = medium
	quality_locked = TRUE
	toohot = FALSE
	if(medium == get_preferred_quench())
		quality = min(quality + 1, 25)
	else
		quality = max(quality - 2, -10)
	if(differential_hardening && differential_hardening_allowed && medium == get_preferred_quench())
		quality = min(quality + 1, 25)
	istempered()
	return TRUE

/obj/item/smithing/proc/air_cool()
	if(quality_locked || !toohot)
		return FALSE
	quality_locked = TRUE
	quench_medium = "air"
	toohot = FALSE
	quality = max(quality - 2, -10)
	istempered()
	return TRUE

/obj/item/smithing/Initialize()
	. = ..()
	quench_started_at = world.time
	add_overlay(image(icon= 'icons/obj/blacksmith_bd2.dmi',icon_state="[icon_state]_hot"))
	set_light_on(TRUE)
	update_icon()
	return .

/obj/item/smithing/proc/istempered()
	cut_overlay(image(icon= 'icons/obj/blacksmith_bd2.dmi',icon_state="[icon_state]_hot"))
	set_light_on(FALSE)
	update_icon()
	return

/obj/item/smithing/on_attack_hand(mob/user)
	var/mob/living/carbon/human/H
	if(toohot != TRUE)
		return ..()
	var/prot = 0
	if(ishuman(user))
		H = user
		if(H.gloves)
			var/obj/item/clothing/gloves/G = H.gloves
			if(G.max_heat_protection_temperature)
				prot = (G.max_heat_protection_temperature > 360)
		else
			prot = 0
	if(prot > 0 || HAS_TRAIT(user, TRAIT_RESISTHEAT) || HAS_TRAIT(user, TRAIT_RESISTHEATHANDS))
		to_chat(user, "<span class='notice'>You pick up the [src].</span>")
		return ..()
	else
		to_chat(user, "<span class='warning'>You try to move the [src], but you burn your hand on it!</span>")
	if(H)
		var/obj/item/bodypart/affecting = H.get_bodypart("[(user.active_hand_index % 2 == 0) ? "r" : "l" ]_arm")
		if(affecting && affecting.receive_damage( 0, 5 ))		// 5 burn damage
			H.update_damage_overlays()
		playsound(src, 'code/modules/smithing/sound/burned.ogg', 15, 1)
		var/list/hand_items = list(H.get_active_held_item(),H.get_inactive_held_item())
		if(src in hand_items)
			H.dropItemToGround(src)


/obj/item/smithing/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/blacksmith/clay_coating))
		if(!differential_hardening_allowed)
			to_chat(user, span_warning("This piece is not suited to differential hardening."))
			return
		if(!toohot || quality_locked || world.time >= quench_started_at + 2 MINUTES)
			to_chat(user, span_warning("The coating must be applied to a hot, unquenched piece."))
			return
		if(differential_hardening)
			to_chat(user, span_warning("This piece is already coated for differential hardening."))
			return
		if(!do_after(user, 20, TRUE, src))
			return
		differential_hardening = TRUE
		qdel(I)
		to_chat(user, span_notice("You coat the spine, leaving the edge exposed for a differential quench."))
		return
	if(toohot == TRUE)
		if(world.time >= quench_started_at + 2 MINUTES)
			air_cool()
			to_chat(user, span_notice("The [src] has cooled in the air. Its quality is now locked in."))
		else
			to_chat(user, span_warning("You need to quench the [src] or let it cool in the air for two minutes before finishing it."))
			return
	if(!quality_locked)
		to_chat(user, span_warning("The quality of [src] has not been locked by heat treatment yet."))
		return
	if(istype(I, finishingitem))
		if(finishingitem == LEATHER_STRIP)
			to_chat(user, "<span class='warning'>You start to wrap the leather strip around the [src].</span>")
			I.use(1)
			playsound(src, 'code/modules/smithing/sound/latex.ogg', 70, 1)
		else
			qdel(I)
			to_chat(user, "<span class='warning'>You start to attach the handle and fittings to the [src].</span>")
			playsound(src, 'code/modules/smithing/sound/craft_3.ogg', 90, 1)
		if(!do_after(user, 30, TRUE, src))
			return
		startfinish(user)
		user.put_in_hands(finalitem)
	else
		return ..()

/obj/item/smithing/proc/finishing_touches()
	if(!finishing_touch)
		return
	switch(finishing_touch)
		if("finish (sharp)")
			finalitem.armour_penetration += 0.12
			finalitem.force *= 0.9
		if("finish (jagged)")
			finalitem.wound_bonus += 15
			finalitem.force *= 0.9

#define SMITH_STRESS_REWARD_THRESHOLD 60

/obj/item/smithing/proc/startfinish(mob/user)
	dofinish(user)

/obj/item/smithing/proc/dofinish(mob/user)
	finishing_touches()
	if(differential_hardening && differential_hardening_allowed && quench_medium == get_preferred_quench() && finalitem.sharpness == SHARP_EDGED)
		finalitem.armour_penetration += 0.05
	var/qualname
	switch(round(quality))
		if(-INFINITY to -1)
			qualname = "poor"
		if(0 to 4)
			qualname = "average"
		if(5 to 9)
			qualname = "good"
		if(10 to 14)
			qualname = "excellent"
		if(15 to 16)
			qualname = "masterwork"
		if(17 to 18)
			qualname = "high masterwork"
		if(19)
			qualname = "peak masterwork"
		if(20 to INFINITY)
			qualname = "legendary"
	var/datum/material/mat = custom_materials[1]
	finalitem.set_custom_materials(custom_materials)
	mat = mat.name
	var/touch_name = ""
	switch(finishing_touch)
		if("finish (sharp)")
			touch_name = "sharp "
		if("finish (jagged)")
			touch_name = "jagged "
	if(artifact)
		//dwarfyartifact(finalitem, mat)
		var/artifact_name = stripped_input(user, "Name your artifact")
		if(artifact_name)
			finalitem.name = artifact_name
	else
		finalitem.name = "[touch_name][qualname] [mat] [initial(finalitem.name)]"
	if(pattern_welded)
		finalitem.desc += " Its layered construction forms a distinctive pattern."
	finalitem.AddComponent(/datum/component/smithing_maker_mark, quality)
	finalitem.forceMove(get_turf(src))
	if(forging_steps && final_forging_stress < SMITH_STRESS_REWARD_THRESHOLD && bright_forging_steps * 2 >= forging_steps)
		record_mastery(user, "bright forging")
	if(forging_used_flux && quench_medium == get_preferred_quench())
		record_mastery(user, "flux and quench")
	if(quality >= 15 && final_forging_stress < SMITH_STRESS_REWARD_THRESHOLD)
		record_mastery(user, "masterwork control")
	if(differential_hardening && differential_hardening_allowed && quench_medium == get_preferred_quench() && finalitem.sharpness == SHARP_EDGED)
		record_mastery(user, "differential hardening")
	if(pattern_welded && quench_medium == get_preferred_quench())
		record_mastery(user, "pattern welding")
	give_finish_xp(user)
	qdel(src)

/obj/item/smithing/proc/give_finish_xp(mob/user)
	if(!user?.mind?.skill_holder)
		return
	var/xp = 50 * length(recipe_string) * clamp(0.5 + quality / 10, 0.5, 2.5)
	if(peak_forging_stress >= SMITH_STRESS_REWARD_THRESHOLD && !cracked_during_forging)
		xp *= 1.25
	if(cracked_during_forging)
		xp *= 0.7
	if(!(recipe_string in user.mind.smithed_recipes))
		user.mind.smithed_recipes += recipe_string
		xp += 150
		to_chat(user, span_notice("You feel you've learned something new by making this for the first time."))
	user.mind.auto_gain_experience(/datum/skill/level/dwarfy/blacksmithing, round(xp), 500000, silent = FALSE)

/obj/item/smithing/proc/record_mastery(mob/user, technique)
	if(!user?.mind)
		return
	var/previous_count = 0
	if(user.mind.smithing_mastery[technique])
		previous_count = user.mind.smithing_mastery[technique]
	user.mind.smithing_mastery[technique] = previous_count + 1
	if(!previous_count)
		to_chat(user, span_notice("You have begun mastering [technique]."))
#undef SMITH_STRESS_REWARD_THRESHOLD

/datum/component/smithing_maker_mark
	var/marked = FALSE
	/// Final quality of the piece, shown on examine
	var/quality

/datum/component/smithing_maker_mark/Initialize(_quality)
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE || !isatom(parent))
		return COMPONENT_INCOMPATIBLE
	quality = _quality
	if(!isnull(quality))
		RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/smithing_maker_mark/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("It was forged to a quality of <b>[round(quality, 0.1)]</b>.")

/datum/component/smithing_maker_mark/proc/apply_mark(mob/user, mark_text)
	if(marked)
		return FALSE
	var/obj/item/marked_item = parent
	marked_item.desc += " It bears the maker's mark '[mark_text]', applied by [user.real_name]."
	marked = TRUE
	return TRUE

/obj/item/blacksmith/branding_iron
	name = "maker's branding iron"
	desc = "A fine tool for adding a permanent maker's mark to a finished, cooled piece."
	icon_state = "hammer"

// Works both ways: hold the iron and click the piece, or use the piece on the iron.
/obj/item/blacksmith/branding_iron/afterattack(atom/target, mob/user, proximity, params)
	. = ..()
	if(!proximity || !isitem(target))
		return
	apply_maker_mark(target, user)
	return TRUE

/obj/item/blacksmith/branding_iron/attackby(obj/item/I, mob/user, params)
	apply_maker_mark(I, user)
	return TRUE

/obj/item/blacksmith/branding_iron/proc/apply_maker_mark(obj/item/I, mob/user)
	if(!user.mind || user.mind.get_skill_level(/datum/skill/level/dwarfy/blacksmithing) < 6)
		to_chat(user, span_warning("You need more blacksmithing experience (level 6) to apply a maker's mark."))
		return
	var/datum/component/smithing_maker_mark/mark_component = I.GetComponent(/datum/component/smithing_maker_mark)
	if(!mark_component)
		to_chat(user, span_warning("That item is not a finished piece of smithing."))
		return
	if(mark_component.marked)
		to_chat(user, span_warning("A maker's mark has already been applied to that piece."))
		return
	var/mark_text = stripped_input(user, "Enter the maker's mark")
	if(!mark_text)
		return
	if(!do_after(user, 30, TRUE, I))
		return
	if(!mark_component.apply_mark(user, mark_text))
		to_chat(user, span_warning("The maker's mark could not be applied."))
		return
	to_chat(user, span_notice("You apply your maker's mark to [I]."))

/*
// Artifcats. Still a Frankenstein uncurated mutated TG remnant with memery but whatever.
/obj/item/smithing/proc/dwarfyartifact(obj/item/finalitem, mat)
	var/finaldesc = "A [initial(finalitem.name)] made of [mat], all craftsmanship is of the highest quality. It "
	switch(pick(1,2,3,4,5))
		if(1)
			finaldesc += "is encrusted with [pick("","fake ","multi-faceted ","radioactive ","plastic ") + pick("stickers","emeralds","jade","bottle caps","diamonds")]."
		if(2)
			finaldesc += "is laced with studs of [pick("gold","silver","aluminium","titanium")]."
		if(3)
			finaldesc += "is etched with pictographs of [pick("nuclear bombs","power-armored men","pinup-girls","the president","a hognose snake")]."
		if(4)
			finaldesc += "menaces with spikes of [pick("ceramite","uranium","plastic","blued steel")]."
		if(5)
			finaldesc += "is encrusted with [pick("","synthetic ","multi-faceted ","radioactive ","plastic ") + pick("rubies","dice","jade","opals","bottle caps")],laced with studs of [pick("gold","silver","aluminium","titanium")], encircled with bands of [pick("durasteel","metallic hydrogen","ferritic-alloy","plasteel","duranium")] and menaces with spikes of [pick("ytterbium","uranium","white pearl","black steel")]."
	finalitem.desc = finaldesc
	finalitem.name = pick("Mutants Choice", "Nuka Smash", "Gallius Rex","Fist of Fury", "The Big Bad", "Good Old Boy", "Serial Crusher", "Caesars Own", "Kiloton Deluxe", "Lämp", "Cosmic Knife Deluxe", "Master Superior", "Even Better", "The Mackintosh", "Oltud", "Deleratîs", "Nökornomal") //one of these is literally BLOOD POOL CREATE.iirc its Nazushagsaldôbar.
*/

/obj/item/smithing/weapon
	var/quality_to_force_coeff = 0
	var/quality_to_pen_coeff = 0

/obj/item/smithing/weapon/startfinish(mob/user)
	finalitem = new finalitem(src)
	finalitem.force += quality * quality_to_force_coeff
	finalitem.armour_penetration += quality * quality_to_pen_coeff
	. = ..()

//////////////////////////////////
//								//
//			INGOTS				//
//								//
//////////////////////////////////

/obj/item/blacksmith/ingot
	name = "ingot"
	icon_state = "ingot"
	material_flags = MATERIAL_COLOR | MATERIAL_ADD_PREFIX
	light_system = MOVABLE_LIGHT
	light_range = 1
	light_power = GLOW_WEAK
	light_color = LIGHT_COLOR_FIRE
	light_on = FALSE
	var/workability = FALSE
	var/heat_peak = SMITH_HEAT_COLD //Hottest stage reached at heat_time
	var/heat_time = 0
	var/forge_cleanliness = 0
	/// Progress kept when a partly worked piece is lifted off the anvil
	var/list/progress

/// Current temperature stage, cooling over time since the last heating.
/obj/item/blacksmith/ingot/proc/get_heat_stage()
	if(!workability)
		return SMITH_HEAT_COLD
	if(!heat_time) // heated by something that doesn't track heat (e.g. cult forge)
		heat_peak = SMITH_HEAT_WORKING
		heat_time = world.time
	var/stage = calc_smith_heat(heat_peak, heat_time)
	if(stage == SMITH_HEAT_COLD)
		cool_down()
	return stage

/obj/item/blacksmith/ingot/proc/heat_up(heat_stage = SMITH_HEAT_BRIGHT, cleanliness = 0)
	if(get_heat_stage() >= SMITH_HEAT_BRIGHT)
		heat_peak = SMITH_HEAT_OVERHEATED
	else
		heat_peak = heat_stage
	heat_time = world.time
	forge_cleanliness = clamp(cleanliness, -1, 1)
	workability = "shapeable"

/obj/item/blacksmith/ingot/proc/cool_down()
	workability = FALSE
	heat_peak = SMITH_HEAT_COLD
	heat_time = 0
	icon_state = "ingot"
	set_light_on(FALSE)

/obj/item/blacksmith/ingot/examine(mob/user)
	. = ..()
	if(progress)
		. += span_notice("It has been partly worked on an anvil.")
		if(progress[6])
			. += span_warning("It is visibly cracked.")

/obj/item/blacksmith/ingot/on_attack_hand(mob/user)
	var/mob/living/carbon/human/H
	if(get_heat_stage() == SMITH_HEAT_COLD)
		return ..()
	var/prot = 0
	if(ishuman(user))
		H = user
		if(H.gloves)
			var/obj/item/clothing/gloves/G = H.gloves
			if(G.max_heat_protection_temperature)
				prot = (G.max_heat_protection_temperature > 360)
		else
			prot = 0
	if(prot > 0 || HAS_TRAIT(user, TRAIT_RESISTHEAT) || HAS_TRAIT(user, TRAIT_RESISTHEATHANDS))
		to_chat(user, "<span class='notice'>You pick up the [src].</span>")
		return ..()
	else
		to_chat(user, "<span class='warning'>You try to move the [src], but you burn your hand on it!</span>")
		playsound(src, 'code/modules/smithing/sound/burned.ogg', 15, 1)
	if(H)
		var/obj/item/bodypart/affecting = H.get_bodypart("[(user.active_hand_index % 2 == 0) ? "r" : "l" ]_arm")
		if(affecting && affecting.receive_damage( 0, 5 ))		// 5 burn damage
			H.update_damage_overlays()
		var/list/hand_items = list(H.get_active_held_item(),H.get_inactive_held_item())
		if(src in hand_items)
			H.dropItemToGround(src)

/obj/item/blacksmith/ingot/iron
	custom_materials = list(/datum/material/iron=12000)

/obj/item/blacksmith/ingot/uranium
	custom_materials = list(/datum/material/uranium=12000)

/obj/item/blacksmith/ingot/gold
	custom_materials = list(/datum/material/gold=12000)

/obj/item/blacksmith/ingot/silver
	custom_materials = list(/datum/material/silver=12000)

/obj/item/blacksmith/ingot/titanium
	custom_materials = list(/datum/material/titanium=12000)

/obj/item/blacksmith/ingot/adamantine
	custom_materials = list(/datum/material/adamantine=12000)
	name = "pre-war steel ingot"
	desc = "Top quality alloyed steel from the old world."
	material_flags = MATERIAL_COLOR

/obj/item/blacksmith/ingot/bronze
	custom_materials = list(/datum/material/bronze=12000)
	name = "bronze ingot"
	desc = "Softer than iron."


//////////////////////////////////
//								//
//		BLACKSMITH FINISHERS	//
//								//
//////////////////////////////////

// -------- WOODEN ROD -------- //
/obj/item/blacksmith/woodenrod
	name = "wooden rod"
	desc = "It's a rod, suitable for use of a handle of a tool. Also could serve as a weapon, in a pinch."
	icon_state = "woodenrod"
	resistance_flags = FLAMMABLE

// Make a sword handle by wrapping leather strips on a rod
/obj/item/blacksmith/woodenrod/attackby/(obj/item/W, mob/user, params)
	if (istype(W, LEATHER_STRIP))
		user.visible_message("[user] begins finishing the [src] into a sword handle.", \
				"<span class='notice'>You begin wrapping the [src] with leather strips, and shaping the wood into a sword handle.</span>", \
				"<span class='italics'>You hear faint sounds of handcrafting.</span>")
		playsound(src, 'code/modules/smithing/sound/craft_3.ogg', 50, 1)
		// 6 Second Timer
		if(!do_after(user, 40, TRUE, src))
			return
		// Make stick
		var/obj/item/blacksmith/swordhandle/new_item = new(user.loc)
		user.put_in_hands(new_item)
		user.visible_message("[user] finishes making a sword handle from the [src].", \
				"<span class='notice'>You finish making a sword handle from the [src].</span>")
		qdel(src)
		// Use up the strips
		W.use(1)
	else
		. = ..()

// -------- SWORD HANDLE -------- //
/obj/item/blacksmith/swordhandle
	name = "sword handle"
	desc = "It's a wooden handle with leather strips, making it comfortable to hold."
	icon_state = "swordhandle"
	resistance_flags = FLAMMABLE

// -------- CHAIN -------- //
/obj/item/blacksmith/chain
	name = "length of chain"
	desc = "It rattles and is pretty useless when not attached to stuff"
	icon_state = "chain"
	hitsound = 'code/modules/smithing/sound/chain.ogg'


//////////////////////////////
//							//
//  	SMITHED TOOLS		//
//							//
////////////////////////////// - Known issues - force not modified correctly by quality. Toolspeed works though.

// -------- BLACKSMITH HAMMER -------- //
/obj/item/smithing/hammerhead
	name = "smithed hammer head"
	finalitem = /obj/item/melee/smith/hammer
	icon_state = "hammer"

/obj/item/smithing/hammerhead/startfinish(mob/user)
	var/obj/item/melee/smith/hammer/finalforreal = new /obj/item/melee/smith/hammer(src)
	finalforreal.force += quality/4
	finalforreal.smithing_speed = quality
	finalforreal.smithing_quality_bonus = max(0, quality) / 40
	finalforreal.smithing_stress_modifier = clamp(1 - (quality * 0.02), 0.7, 1.3)
	finalitem = finalforreal
	..()

// -------- SHOVEL -------- //
/obj/item/smithing/shovelhead
	name = "smithed shovel head"
	finalitem = /obj/item/shovel/smithed
	icon_state = "shovel"

/obj/item/smithing/shovelhead/startfinish(mob/user)
	finalitem = new /obj/item/shovel/smithed(src)
	finalitem.force += quality/2
	if(quality > 0)
		finalitem.toolspeed = max(0.05,(1-(quality/10)))
	else
		finalitem.toolspeed *= max(1, (quality * -1))
	..()

// -------- PICKAXE -------- //
/obj/item/smithing/pickaxehead
	name = "smithed pickaxe head"
	finalitem = /obj/item/pickaxe/smithed
	icon_state = "pickaxe"

/obj/item/smithing/pickaxehead/startfinish(mob/user)
	var/obj/item/pickaxe/smithed/finalforreal = new /obj/item/pickaxe/smithed(src)
	finalforreal.force += quality/2
	if(quality > 0)
		finalforreal.toolspeed = max(0.05,(1-(quality/15)))
	else
		finalforreal.toolspeed *= max(1, (quality * -1))
	switch(quality)
		if(13 to INFINITY)
			finalforreal.digrange = 2
		if(3 to 13)
			finalforreal.digrange = 1
		else
			finalforreal.digrange = 1
	finalitem = finalforreal
	..()

// -------- PROSPECTORS PICK -------- //
/obj/item/smithing/prospectingpickhead
	name = "smithed prospector's pick head"
	icon_state = "prospect_smith"
	finalitem = /obj/item/mining_scanner/prospector
	var/cooldown = null
	var/range = null

/obj/item/smithing/prospectingpickhead/startfinish(mob/user)
	var/obj/item/mining_scanner/prospector/finalforreal = new /obj/item/mining_scanner/prospector(src)
	finalforreal.range = 2 + QUALITY_MODIFIER
	if(quality)
		finalforreal.cooldown = 100/quality
	finalforreal.force += QUALITY_MODIFIER
	finalitem = finalforreal
	..()

// -------- CROWBAR -------- //
/obj/item/smithing/crowbar
	name = "unwrapped crowbar"
	desc = "Wrap with leather strips."
	icon_state = "crowbar_smith"
	finishingitem = LEATHER_STRIP
	finalitem = /obj/item/crowbar/smithed

/obj/item/smithing/crowbar/startfinish(mob/user)
	var/obj/item/crowbar/smithed/finalforreal = new /obj/item/crowbar/smithed(src)
	finalforreal.force += QUALITY_MODIFIER
	if(quality > 0)
		finalforreal.toolspeed = max(0.05,(1-(quality/10)))
	else
		finalforreal.toolspeed *= max(1, (quality * -1))
	finalitem = finalforreal
	..()

// -------- UNIVERSAL TOOL -------- //
/obj/item/smithing/unitool
	name = "unwrapped universal tool"
	desc = "Wrap with leather strips."
	icon_state = "unitool_smith"
	finishingitem = LEATHER_STRIP
	finalitem = /obj/item/crowbar/smithedunitool

/obj/item/smithing/unitool/startfinish(mob/user)
	var/obj/item/crowbar/smithedunitool/finalforreal = new /obj/item/crowbar/smithedunitool(src)
	finalforreal.force += QUALITY_MODIFIER
	finalitem = finalforreal
	..()

// -------- KITCHEN KNIFE -------- //
/obj/item/smithing/weapon/knifeblade
	name = "smithed knife blade"
	desc = "Attach a sword handle."
	icon_state = "knife_smith"
	finishingitem = SWORD_HANDLE
	finalitem = /obj/item/kitchen/knife/smithed
	quality_to_force_coeff = 3
	differential_hardening_allowed = TRUE

//////////////////////////////////////////////////
//												//
//  	BLING - smithed and finished both		//
//												//
//////////////////////////////////////////////////

/obj/item/smithing/special
	mob_overlay_icon = 'icons/onmob/slot.dmi'
	gender = NEUTER
	w_class = WEIGHT_CLASS_SMALL

/obj/item/smithing/special/jewelry
	icon_state = "ring"
	item_state = "ring"
	obj_flags = UNIQUE_RENAME
	strip_delay = 20
	equip_delay_other = 40
	var/strip_mod = 1 //how much they alter stripping items time by, higher is quicker
	var/strip_silence = TRUE
	var/mood_event_on_equip = /datum/mood_event/equipped_ring/gold

// ------------ RING ------------ //
/obj/item/smithing/special/jewelry/ring
	name = "ring"
	desc = "A ring."
	w_class = WEIGHT_CLASS_TINY
	slot_flags = ITEM_SLOT_GLOVES
	attack_verb = list("proposed")

/obj/item/smithing/special/jewelry/ring/equipped(mob/user, slot)
	. = ..()
	if (slot == SLOT_GLOVES && istype(user))
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "ringbuff", mood_event_on_equip)
	else
		SEND_SIGNAL(user, COMSIG_CLEAR_MOOD_EVENT, "ringbuff")

/obj/item/smithing/special/jewelry/ring/dropped(mob/user)
	. = ..()
	SEND_SIGNAL(user, COMSIG_CLEAR_MOOD_EVENT, "ringbuff")


// ------------ BALL AND CHAIN ------------ //
/obj/item/smithing/weapon/ballandchain
	name = "unchained ball"
	desc = "Finish by attaching a chain to it."
	icon_state = "ball"
	finishingitem = CHAIN
	finalitem = /obj/item/restraints/legcuffs/ballandchain/smithed
	throwforce = 15
	throw_range = 2
	quality_to_force_coeff = 2
	differential_hardening_allowed = FALSE

// ------------ ARMOR PIECES ------------ //  - Obviously meant to be included in recipes to build metal armor instead of generic metal parts, at least for the less "scrap metal salvage" styled metal armors. Make it inherit material would be amusing.
/obj/item/smithing/armor_piece
	name = "metal armor parts"
	desc = "Metal worked to be used in making some sort of simple armor."
	icon_state = "armor_piece_smith"


//////////////////////////////////////////////////
//												//
//  			ONEHANDED WEAPONS				//
//												//
//////////////////////////////////////////////////

// ------------ DAGGER ------------ //
/obj/item/smithing/weapon/daggerblade
	name = "smithed dagger blade"
	desc = "Attach a sword handle."
	icon_state = "dagger_smith"
	finishingitem = SWORD_HANDLE
	finalitem = /obj/item/melee/smith/dagger
	quality_to_force_coeff = 1
	quality_to_pen_coeff = 0.01
	differential_hardening_allowed = TRUE

// ------------ BOWIE KNIFE ------------ //
/obj/item/smithing/weapon/daggerblade/bowieblade
	name = "smithed bowie blade"
	desc = "Attach a sword handle."
	icon_state = "bowie_smith"
	finalitem = /obj/item/melee/smith/dagger/bowie

// ------------ MACHETE ------------ //
/obj/item/smithing/weapon/macheteblade
	name = "smithed machete blade"
	desc = "Attach a sword handle."
	icon_state = "machete_smith"
	finishingitem = SWORD_HANDLE
	finalitem = /obj/item/melee/smith/machete
	quality_to_force_coeff = 1
	differential_hardening_allowed = TRUE

// ------------ GLADIUS ------------ //
/obj/item/smithing/weapon/macheteblade/gladiusblade
	name = "smithed gladius blade"
	icon_state = "gladius_smith"
	finalitem = /obj/item/melee/smith/machete/gladius

// ------------ REFORGED MACHETE ------------ //
/obj/item/smithing/weapon/macheteblade/macheterblade
	name = "reforged machete blade"
	icon_state = "macheter_smith"
	finalitem = /obj/item/melee/smith/machete/reforged

// ------------ WAKIZASHI ------------ //
/obj/item/smithing/weapon/macheteblade/wakiblade
	name = "smithed wakizashi blade"
	icon_state = "waki_smith"
	finalitem = /obj/item/melee/smith/wakizashi

// ------------ SCRAP SAW ------------ //
/obj/item/smithing/weapon/scrapsaw
	name = "unfinished scrap saw"
	desc = "Wrap it in leather strips."
	icon_state = "saw_smith"
	finishingitem = LEATHER_STRIP
	finalitem = /obj/item/melee/smith/wakizashi/scrapsaw
	quality_to_force_coeff = 1
	differential_hardening_allowed = FALSE

// ------------ MACE ------------ //
/obj/item/smithing/weapon/macehead
	name = "smithed macehead"
	icon_state = "mace_smith"
	finalitem = /obj/item/melee/smith/mace
	quality_to_force_coeff = 1
	quality_to_pen_coeff = 0.01
	differential_hardening_allowed = FALSE

// ------------ SWORD ------------ //
/obj/item/smithing/weapon/swordblade
	name = "smithed swordblade"
	desc = "Attach a sword handle."
	icon_state = "sword_smith"
	finishingitem = SWORD_HANDLE
	finalitem = /obj/item/melee/smith/sword
	quality_to_force_coeff = 1
	quality_to_pen_coeff = 0.01
	differential_hardening_allowed = TRUE

// ------------ SPATHA ------------ //
/obj/item/smithing/weapon/swordblade/spathablade
	name = "smithed spathablade"
	icon_state = "spatha_smith"
	finalitem = /obj/item/melee/smith/sword/spatha

// ------------ SABRE ------------ //
/obj/item/smithing/weapon/swordblade/sabreblade
	name = "smithed sabre blade"
	finalitem = /obj/item/melee/smith/sword/sabre
	icon_state = "sabre_smith"

//////////////////////////////////////////////////
//												//
//  			TWOHANDED WEAPONS				//
//												//
//////////////////////////////////////////////////

// ------------ KATANA ------------ //
/obj/item/smithing/katanablade
	name = "smithed katana blade"
	desc = "Attach a sword handle."
	icon_state = "katana_smith"
	finishingitem = SWORD_HANDLE
	finalitem = /obj/item/twohanded/smithed/katana
	differential_hardening_allowed = TRUE

/obj/item/smithing/katanablade/startfinish(mob/user)
	var/obj/item/twohanded/smithed/katana/finalforreal = new /obj/item/twohanded/smithed/katana(src)
	finalforreal.force += QUALITY_MODIFIER
	finalforreal.force_wielded = finalforreal.force*finalforreal.wielded_mult
	finalforreal.force_unwielded = finalforreal.force
	finalforreal.AddComponent(/datum/component/two_handed, force_unwielded=finalforreal.force_unwielded, force_wielded=finalforreal.force_wielded, icon_wielded="[icon_state]_wield") // - icon_wielded basically makes the wield icon for direct click wield, sort of redundant if you change it to shift-x only
	finalitem = finalforreal
	..()

// ------------ LONG SWORDS ------------ //
/obj/item/smithing/longswordblade
	name = "smithed longsword blade"
	desc = "Attach a sword handle."
	icon_state = "longsword_smith"
	finishingitem = SWORD_HANDLE
	finalitem = /obj/item/twohanded/smithed/katana/longsword
	differential_hardening_allowed = TRUE

/obj/item/smithing/longswordblade/startfinish(mob/user)
	var/obj/item/twohanded/smithed/katana/longsword/finalforreal = new /obj/item/twohanded/smithed/katana/longsword(src)
	finalforreal.force += QUALITY_MODIFIER
	finalforreal.force_wielded = finalforreal.force*finalforreal.wielded_mult
	finalforreal.force_unwielded = finalforreal.force
	finalforreal.AddComponent(/datum/component/two_handed, force_unwielded=finalforreal.force_unwielded, force_wielded=finalforreal.force_wielded, icon_wielded="[icon_state]_wield")
	finalitem = finalforreal
	..()


// ------------ ZWEIHANDER ------------ //
/obj/item/smithing/zweiblade
	name = "smithed zweihander blade"
	desc = "Attach a sword handle."
	icon_state = "zwei_smith"
	finishingitem = SWORD_HANDLE
	finalitem = /obj/item/twohanded/smithed/zweihander
	differential_hardening_allowed = TRUE

/obj/item/smithing/zweiblade/startfinish(mob/user)
	var/obj/item/twohanded/smithed/zweihander/finalforreal = new /obj/item/twohanded/smithed/zweihander(src)
	finalforreal.force += QUALITY_MODIFIER
	finalforreal.force_wielded = finalforreal.force*finalforreal.wielded_mult
	finalforreal.force_unwielded = finalforreal.force
	finalforreal.AddComponent(/datum/component/two_handed, force_unwielded=finalforreal.force_unwielded, force_wielded=finalforreal.force_wielded, icon_wielded="[icon_state]_wield")
	finalitem = finalforreal
	..()


// ------------ SCRAP BLADE ------------ //
/obj/item/smithing/scrapblade
	name = "smithed scrap blade"
	desc = "Wrap in leather strips."
	icon_state = "scrap_smith"
	finishingitem = LEATHER_STRIP
	finalitem = /obj/item/twohanded/smithed/katana/scrapblade
	differential_hardening_allowed = TRUE

/obj/item/smithing/scrapblade/startfinish(mob/user)
	var/obj/item/twohanded/smithed/katana/scrapblade/finalforreal = new /obj/item/twohanded/smithed/katana/scrapblade(src)
	finalforreal.force += QUALITY_MODIFIER
	finalforreal.force_wielded = finalforreal.force*finalforreal.wielded_mult
	finalforreal.force_unwielded = finalforreal.force
	finalforreal.AddComponent(/datum/component/two_handed, force_unwielded=finalforreal.force_unwielded, force_wielded=finalforreal.force_wielded, icon_wielded="[icon_state]_wield")
	finalitem = finalforreal
	..()


// ------------ HEAVY AXE ------------ //
/obj/item/smithing/axehead
	name = "smithed axehead"
	icon_state = "axe_smith"
	finalitem = /obj/item/twohanded/smithed/axe

/obj/item/smithing/axehead/startfinish(mob/user)
	var/obj/item/twohanded/smithed/axe/finalforreal = new /obj/item/twohanded/smithed/axe(src)
	finalforreal.force += QUALITY_MODIFIER
	finalforreal.force_wielded = finalforreal.force*finalforreal.wielded_mult
	finalforreal.force_unwielded = finalforreal.force
	finalforreal.AddComponent(/datum/component/two_handed, force_unwielded=finalforreal.force_unwielded, force_wielded=finalforreal.force_wielded, icon_wielded="[icon_state]_wield")
	finalitem = finalforreal
	..()
	finalitem.force += QUALITY_MODIFIER

// ------------ WAR AXE ------------ //
/obj/item/smithing/waraxehead
	name = "smithed war-axehead"
	icon_state = "waraxe_smith"
	finalitem = /obj/item/twohanded/smithed/axe/waraxe

/obj/item/smithing/waraxehead/startfinish(mob/user)
	var/obj/item/twohanded/smithed/axe/waraxe/finalforreal = new /obj/item/twohanded/smithed/axe/waraxe(src)
	finalforreal.force += QUALITY_MODIFIER
	finalforreal.force_wielded = finalforreal.force*finalforreal.wielded_mult
	finalforreal.force_unwielded = finalforreal.force
	finalforreal.AddComponent(/datum/component/two_handed, force_unwielded=finalforreal.force_unwielded, force_wielded=finalforreal.force_wielded, icon_wielded="[icon_state]_wield")
	finalitem = finalforreal
	..()

// ------------ GHOUL CRUSHER ------------ // - for those dry twig like limbs, snap snap.
/obj/item/smithing/crusherhead
	name = "smithed crusher head"
	finalitem = /obj/item/twohanded/smithed/crusher
	icon_state = "crusher_smith"

/obj/item/smithing/crusherhead/startfinish(mob/user)
	var/obj/item/twohanded/smithed/crusher/finalforreal = new /obj/item/twohanded/smithed/crusher(src)
	finalforreal.force += QUALITY_MODIFIER
	finalforreal.force_wielded = finalforreal.force*finalforreal.wielded_mult
	finalforreal.force_unwielded = finalforreal.force
	finalforreal.AddComponent(/datum/component/two_handed, force_unwielded=finalforreal.force_unwielded, force_wielded=finalforreal.force_wielded, icon_wielded="[icon_state]_wield")
	finalitem = finalforreal
	..()


// ------------ SPEAR ------------ //
/obj/item/smithing/spearhead
	name = "smithed spearhead"
	finalitem = /obj/item/twohanded/smithed/spear
	icon_state = "spear_smith"

/obj/item/smithing/spearhead/startfinish(mob/user)
	var/obj/item/twohanded/smithed/finalforreal = new finalitem(src)
	finalforreal.force += QUALITY_MODIFIER
	finalforreal.force_wielded = finalforreal.force*finalforreal.wielded_mult
	finalforreal.force_unwielded = finalforreal.force
	finalforreal.AddComponent(/datum/component/two_handed, force_unwielded=finalforreal.force_unwielded, force_wielded=finalforreal.force_wielded, icon_wielded="[icon_state]_wield")
	finalforreal.throwforce = finalforreal.force
	finalitem = finalforreal
	..()

// ------------ TRIDENT ------------ //
/obj/item/smithing/spearhead/tridenthead
	name = "smithed tridenthead"
	finalitem = /obj/item/twohanded/smithed/spear/trident
	icon_state = "trident_smith"

// ------------ PIKE ------------ //
/obj/item/smithing/spearhead/pikehead
	name = "smithed pikehead"
	finalitem = /obj/item/twohanded/smithed/spear/pike
	icon_state = "pike_smith"

// ------------ LEGION LANCE ------------ //
/obj/item/smithing/spearhead/lancehead
	name = "smithed lancehead"
	finalitem = /obj/item/twohanded/smithed/spear/lance
	icon_state = "lance_smith"

//////////////////////////////////////////////////
//												//
//  			THROWING WEAPONS				//
//												//
//////////////////////////////////////////////////

// ------------ THROWING KNIFE ------------ //
/obj/item/smithing/throwingknife
	name = "unfinished throwing knife"
	desc = "Add leather strips."
	icon_state = "throwing_smith"
	finishingitem = LEATHER_STRIP
	finalitem = /obj/item/melee/smith/throwingknife

/obj/item/smithing/throwingknife/startfinish(mob/user)
	var/obj/item/melee/smith/throwingknife/finalforreal = new /obj/item/melee/smith/throwingknife(src)
	finalforreal.force += QUALITY_MODIFIER
	finalforreal.throwforce = finalforreal.force*1.4
	finalitem = finalforreal
	..()

// ------------ JAVELIN ------------ //
/obj/item/smithing/javelinhead
	name = "smithed javelin head"
	icon_state = "javelin_smith"
	finalitem = /obj/item/melee/smith/javelin

/obj/item/smithing/javelinhead/startfinish(mob/user)
	var/obj/item/melee/smith/javelin/finalforreal = new /obj/item/melee/smith/javelin(src)
	finalforreal.force += QUALITY_MODIFIER
	finalforreal.throwforce = finalforreal.force*1.5
	finalitem = finalforreal
	..()

// ------------ METAL BOLA ------------ //
/obj/item/smithing/bola
	name = "unfinished bola pieces"
	desc = "Add a chain."
	icon_state = "bola_smith"
	finishingitem = CHAIN
	finalitem = /obj/item/restraints/legcuffs/bola/smithed

/obj/item/smithing/bola/startfinish(mob/user)
	var/obj/item/restraints/legcuffs/bola/smithed/finalforreal = new /obj/item/restraints/legcuffs/bola/smithed(src)
	finalforreal.breakouttime += QUALITY_MODIFIER * 2
	finalitem = finalforreal
	..()

#undef WOODEN_ROD
#undef SWORD_HANDLE
#undef LEATHER_STRIP
#undef CHAIN
#undef QUALITY_MODIFIER
#undef GLOW_BRIGHT
#undef GLOW_MODERATE
#undef GLOW_WEAK
