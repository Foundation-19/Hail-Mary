//////////////////////////////////////////
//										//
//		SMITHED ITEMS BASE CODE			//
//										//
//////////////////////////////////////////
// Values in brackets [37/39 (40) AP 0.2 Parry] are one handed/wielded (thrown) armour piercing, and abilities, for quality 12 Iron weapons.


/obj/item/melee/smith
	name = "base class obj/item/melee/smith"
	desc = "cringe"
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	lefthand_file = 'modular_BD2/blacksmith/icons/onmob/lefthand.dmi'
	righthand_file = 'modular_BD2/blacksmith/icons/onmob/righthand.dmi'
	mob_overlay_icon = 'modular_BD2/blacksmith/icons/onmob/slot.dmi'
	force = FORCE_SMITH_LOW
	throwforce = THROWING_DECENT
	wound_bonus = WOUNDING_BONUS_MODEST
	wielded_mult = 1
	material_flags = MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS
	total_mass = TOTAL_MASS_MEDIEVAL_WEAPON
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_NORMAL
	obj_flags = UNIQUE_RENAME
	flags_1 = CONDUCT_1
	var/quality
	var/overlay_state = "woodenrod"
	var/mutable_appearance/overlay
	force_wielded = 15

/obj/item/melee/smith/Initialize()
	. = ..()
	if(desc == "cringe")
		desc = "A handmade [name]."
	overlay = mutable_appearance(icon, overlay_state)
	overlay.appearance_flags = RESET_COLOR
	add_overlay(overlay)
	if(force < 0)
		force = 0


/obj/item/twohanded/smithed // compatible with the Eris wield stuff
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	lefthand_file = 'modular_BD2/blacksmith/icons/onmob/lefthand.dmi'
	righthand_file = 'modular_BD2/blacksmith/icons/onmob/righthand.dmi'
	mob_overlay_icon = 'modular_BD2/blacksmith/icons/onmob/slot.dmi'
	attack_speed = MELEE_SPEED_SLOW
	force = FORCE_SMITH_LOW
	throwforce = THROWING_POOR
	sharpness = SHARP_EDGED
	material_flags = MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS
	w_class = WEIGHT_CLASS_BULKY
	wielded = FALSE
	total_mass = (TOTAL_MASS_MEDIEVAL_WEAPON * 1.5)
	max_integrity = 200
	flags_1 = CONDUCT_1
	force_wielded
	wielded_mult = 1.5
	var/mutable_appearance/overlay
	var/overlay_state = "woodenrod"
	var/x_offset = null
	var/y_offset = null

/obj/item/twohanded/smithed/Initialize()
	. = ..()
	overlay = mutable_appearance(icon, overlay_state)
	overlay.appearance_flags = RESET_COLOR
	add_overlay(overlay)
	if(force < 0)
		force = 0



//////////////////////
//					//
//  SMITHED TOOLS	//
//					//
//////////////////////

// -------- BLACKSMITHING HAMMER -------- //
/obj/item/melee/smith/hammer
	name = "smithing hammer"
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	icon_state = "hammer"
	lefthand_file = 'modular_BD2/blacksmith/icons/onmob/lefthand.dmi'
	righthand_file = 'modular_BD2/blacksmith/icons/onmob/righthand.dmi'
	mob_overlay_icon = 'modular_BD2/blacksmith/icons/onmob/slot.dmi'
	item_state = "hammer"
	overlay_state = "hammerhandle"
	attack_speed = MELEE_SPEED_SLOWEST
	force = WEAPON_FORCE_CLUB
	slot_flags = ITEM_SLOT_BELT
	wound_bonus = WOUNDING_BONUS_SMALL
	var/smithing_speed = 0

/obj/item/melee/smith/hammer/premade
	quality = 3
	smithing_speed = 1
	custom_materials = list(/datum/material/iron = 1000)

// Debugging Hammer
/obj/item/melee/smith/hammer/debug
	name = "debugging hammer"
	desc = "A DEBUGGING HAMMER!! EPIC!!."
	smithing_speed = 50


// -------- PROSPECTORS PICK -------- // Knock on rock to scan for minerals. Lowest quality too shitty to test.
/obj/item/mining_scanner/prospector
	name = "prospectors pick"
	material_flags = MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS
	obj_flags = UNIQUE_RENAME
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	icon_state = "prospect_smith"
	lefthand_file = 'modular_BD2/blacksmith/icons/onmob/lefthand.dmi'
	righthand_file = 'modular_BD2/blacksmith/icons/onmob/righthand.dmi'
	mob_overlay_icon = 'modular_BD2/blacksmith/icons/onmob/slot.dmi'
	item_state = "prospect_smith"
	sharpness = SHARP_POINTY
	slot_flags = ITEM_SLOT_BELT

/obj/item/mining_scanner/prospector/Initialize()
	..()
	var/mutable_appearance/overlay
	desc = "A sounding pick, by tapping the rockface and listening to the reverberation, a skilled user can determine where to dig to find deposits of minerals."
	overlay = mutable_appearance(icon, "handle_prospect")
	overlay.appearance_flags = RESET_COLOR
	add_overlay(overlay)

/obj/item/mining_scanner/prospector/afterattack(atom/A, mob/living/user, proximity)
	. = ..()
	if(!proximity || IS_STAMCRIT(user))
		return
	if(istype(A, /turf/closed/mineral))
		mineral_scan_pulse(get_turf(user), range)
		playsound(src, 'modular_BD2/blacksmith/sound/pickaxe_2.ogg', 70, 1)

/obj/item/mining_scanner/prospector/attack_self(mob/user)
	return


// -------- SMITHED PICKAXE -------- //
/obj/item/pickaxe/smithed
	name = "pickaxe"
	desc = "A handmade pickaxe."
	material_flags = MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS
	obj_flags = UNIQUE_RENAME
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	icon_state = "pickaxe"
	lefthand_file = 'modular_BD2/blacksmith/icons/onmob/lefthand.dmi'
	righthand_file = 'modular_BD2/blacksmith/icons/onmob/righthand.dmi'
	mob_overlay_icon = 'modular_BD2/blacksmith/icons/onmob/slot.dmi'
	item_state = "pickaxe"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_BACK
	sharpness = SHARP_POINTY

/obj/item/pickaxe/smithed/Initialize()
	..()
	desc = "A handmade [name]."
	var/mutable_appearance/overlay
	overlay = mutable_appearance(icon, "handle_pickaxe")
	overlay.appearance_flags = RESET_COLOR
	add_overlay(overlay)
	if(force < 0)
		force = 0

/obj/item/pickaxe/smithed/attack_self(mob/user)
		to_chat(user, "<span class='notice'>Tool does not have a configureable dig range.</span>")


// -------- SMITHED SHOVEL -------- //
/obj/item/shovel/smithed
	name = "shovel"
	desc = "A shovel."
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	icon_state = "shovel"
	righthand_file = 'modular_BD2/blacksmith/icons/onmob/righthand.dmi'
	lefthand_file = 'modular_BD2/blacksmith/icons/onmob/lefthand.dmi'
	mob_overlay_icon = 'modular_BD2/blacksmith/icons/onmob/slot.dmi'
	item_state = "shovel"
	obj_flags = UNIQUE_RENAME
	material_flags = MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS
	sharpness = SHARP_EDGED //it cuts through the earth

/obj/item/shovel/smithed/Initialize()
	..()
	desc = "A handmade [name]."
	var/mutable_appearance/overlay
	overlay = mutable_appearance(icon, "shovelhandle")
	overlay.appearance_flags = RESET_COLOR
	add_overlay(overlay)
	if(force < 0)
		force = 0


// -------- SMITHED CROWBAR -------- // Tops out at 0.2 Toolspeed, which while very fast, is for a crowbar, so meh. TO DO Force qualmod
/obj/item/crowbar/smithed
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	icon_state = "crowbar_smith"
	item_state = "crowbar"
	obj_flags = UNIQUE_RENAME
	toolspeed = 0.8
	force = 15
	material_flags = MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS

/obj/item/crowbar/smithed/Initialize()
	..()
	desc = "A handmade [name]."
	var/mutable_appearance/overlay
	overlay = mutable_appearance(icon, "handle_crowbar")
	overlay.appearance_flags = RESET_COLOR
	add_overlay(overlay)


// -------- UNIVERSAL TOOL -------- // Crowbar with more force, wood chopping and butchering
/obj/item/crowbar/smithedunitool
	name = "universal tool"
	desc = "A bizarre combination of a crowbar and some sort of blade."
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	icon_state = "unitool_smith"
	lefthand_file = 'modular_BD2/blacksmith/icons/onmob/lefthand.dmi'
	righthand_file = 'modular_BD2/blacksmith/icons/onmob/righthand.dmi'
	item_state = "unitool_smith"
	obj_flags = UNIQUE_RENAME
	sharpness = SHARP_POINTY
	material_flags = MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS
	force = WEAPON_FORCE_CLUB

/obj/item/crowbar/smithedunitool/Initialize()
	..()
	var/mutable_appearance/overlay
	overlay = mutable_appearance(icon, "handle_unitool")
	overlay.appearance_flags = RESET_COLOR
	add_overlay(overlay)

/obj/item/crowbar/smithedunitool/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/butchering, 150, 80) //terrible. just terrible.

// -------- KITCHEN KNIFE -------- //
/obj/item/kitchen/knife/smithed
	name = "kitchen knife"
	desc = "A handmade kitchen knife, best suited to cut stuff that doesn't cut back."
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	icon_state = "knife_smith"
	lefthand_file = 'modular_BD2/blacksmith/icons/onmob/lefthand.dmi'
	righthand_file = 'modular_BD2/blacksmith/icons/onmob/righthand.dmi'
	item_state = "knife_smith"
	obj_flags = UNIQUE_RENAME
	material_flags = MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS
	force = WEAPON_FORCE_KNIFE-2

/obj/item/kitchen/knife/smithed/Initialize()
	. = ..()
	AddComponent(/datum/component/butchering, 70, 100, 40)
	var/mutable_appearance/overlay
	overlay = mutable_appearance(icon, "hilt_knife")
	overlay.appearance_flags = RESET_COLOR
	add_overlay(overlay)



//////////////////////////
//						//
//  	OTHER ITEMS		//
//						//
//////////////////////////

// ------------ BALL AND CHAIN ------------ //

/obj/item/restraints/legcuffs/ballandchain
	name = "ball and chain"
	desc = "Use this to keep prisoners in line."
	gender = PLURAL
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	icon_state = "ballandchain"
	mob_overlay_icon = 'modular_BD2/blacksmith/icons/onmob/slot.dmi'
	item_state = "ballandchain"
	lefthand_file = 'modular_BD2/blacksmith/icons/onmob/lefthand.dmi'
	righthand_file = 'modular_BD2/blacksmith/icons/onmob/righthand.dmi'
	throwforce = 10
	w_class = WEIGHT_CLASS_BULKY
	slowdown = 4
	breakouttime = 1200	//Deciseconds = 30s = 0.5 minute
	strip_delay = 100
	var/cuffsound = 'modular_BD2/blacksmith/sound/chain.ogg'
	var/trashtype = null //for disposable cuffs

/obj/item/restraints/legcuffs/ballandchain/attack(mob/living/carbon/C, mob/living/user)
	if(!istype(C))
		return

	if(iscarbon(user) && (HAS_TRAIT(user, TRAIT_CLUMSY) && prob(50)))
		to_chat(user, span_warning("Somehow I can't lock this..."))
		return

	if(!C.legcuffed)
		if(C.get_num_legs(FALSE) >= 1 || C.get_leg_ignore())
			C.visible_message(span_danger("[user] is trying to put [src.name] on [C]!"), \
								span_userdanger("[user] is trying to put [src.name] on [C]!"))

			playsound(loc, cuffsound, 50, 1, -2)
			if(do_mob(user, C, 30) && (C.get_num_legs(FALSE) >= 1 || C.get_leg_ignore()))
				if(iscyborg(user))
					apply_legcuffs(C, user, TRUE)
				else
					apply_legcuffs(C, user)
				to_chat(user, span_notice("You clamp irons on [C]."))
				SSblackbox.record_feedback("tally", "handcuffs", 1, type)

				log_combat(user, C, "clamped in irons")
			else
				to_chat(user, span_warning("You fail to clamp irons on [C]!"))
		else
			to_chat(user, span_warning("[C] doesn't have a leg..."))

/obj/item/restraints/legcuffs/ballandchain/proc/apply_legcuffs(mob/living/carbon/target, mob/user, dispense = 0)
	if(target.legcuffed)
		return

	if(!user.temporarilyRemoveItemFromInventory(src) && !dispense)
		return

	var/obj/item/restraints/legcuffs/ballandchain/cuffs = src
	if(trashtype)
		cuffs = new trashtype()
	else if(dispense)
		cuffs = new type()

	target.equip_to_slot(cuffs, SLOT_LEGCUFFED)

	if(trashtype && !dispense)
		qdel(src)
	return

/obj/item/restraints/legcuffs/ballandchain/smithed
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	icon_state = "ballandchain"
	name = "ball and chain"
	desc = "Clamp it on the prisoners feet. They will need a long time to remove it themselves."
	material_flags = MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS


//////////////////////////////////
//								//
//  		KNIVES				//
//								//
//////////////////////////////////

// ------------ DAGGER ------------ // [Eyestab]
/obj/item/melee/smith/dagger
	name = "dagger"
	icon_state = "dagger_smith"
	overlay_state = "hilt_dagger"
	attack_speed = MELEE_SPEED_FAST
	force = FORCE_SMITH_LOW
	armour_penetration = PIERCING_MINOR
	throwforce = THROWING_EFFECTIVE
	w_class = WEIGHT_CLASS_SMALL
	sharpness = SHARP_EDGED
	hitsound = 'modular_BD2/blacksmith/sound/hit_knife.ogg'


// go for the eyes Boo
/obj/item/melee/smith/dagger/attack(mob/living/carbon/M, mob/living/carbon/user)
	if(!istype(M))
		return ..()
	if(user.zone_selected == BODY_ZONE_PRECISE_EYES)
		M.apply_damage(7, BRUTE, BODY_ZONE_HEAD)
		playsound(M, 'modular_BD2/blacksmith/sound/meatslap.ogg', 80, 1)
		return eyestab(M,user)
	else
		return ..()

/obj/item/melee/smith/dagger/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/butchering, 100, 100, 10)

// ------------ BOWIE KNIFE ------------ // [Eyestab]
/obj/item/melee/smith/dagger/bowie
	name = "bowie knife"
	icon_state = "bowie_smith"
	overlay_state = "hilt_bowie"
	force = (FORCE_SMITH_LOW+2)



//////////////////////////////////
//								//
//  	ONE HANDED SWORDS		//
//								//
//////////////////////////////////

// ------------ MACHETE ------------ // [AP 0.1]
/obj/item/melee/smith/machete
	name = "machete"
	icon_state = "machete_smith"
	overlay_state = "hilt_machete"
	force = FORCE_SMITH_HIGH
	armour_penetration = PIERCING_MINOR
	wound_bonus = WOUNDING_BONUS_BIG
	block_chance = 20
	sharpness = SHARP_EDGED

/obj/item/melee/smith/machete/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/butchering, 100, 85, 10) //decent in a pinch.
	AddElement(/datum/element/sword_point)

// ------------ GLADIUS ------------ // [AP 0.1]
/obj/item/melee/smith/machete/gladius
	name = "gladius"
	icon_state = "gladius_smith"
	overlay_state = "hilt_gladius"

// ------------ REFORGED MACHETE ------------ // [AP 0.1]
/obj/item/melee/smith/machete/reforged
	name = "reforged machete"
	icon_state = "macheter_smith"
	overlay_state = "hilt_macheter"



//////////////////////////////////
//								//
//  	MIXED ONEHANDERS		//
//								//
//////////////////////////////////

// ------------ WAKIZASHI ------------ // [Parry]
/obj/item/melee/smith/wakizashi
	name = "wakizashi"
	icon_state = "waki_smith"
	overlay_state = "hilt_waki"
	force = (FORCE_SMITH_HIGH-2)
	block_chance = 5
	block_parry_data = /datum/block_parry_data/waki
	sharpness = SHARP_EDGED
	item_flags = ITEM_CAN_PARRY
	hitsound = 'modular_BD2/blacksmith/sound/hit_sword.ogg'

/datum/block_parry_data/waki
	parry_stamina_cost = 50
	parry_time_windup = 0
	parry_time_active = 15
	parry_time_spindown = 0
	parry_time_perfect = 2
	parry_time_perfect_leeway = 0.75
	parry_imperfect_falloff_percent = 7.5
	parry_efficiency_to_counterattack = 100
	parry_efficiency_considered_successful = 80
	parry_efficiency_perfect = 120
	parry_failed_stagger_duration = 2 SECONDS
	parry_data = list(PARRY_COUNTERATTACK_MELEE_ATTACK_CHAIN = 1)

/obj/item/melee/smith/wakizashi/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/butchering, 110, 70) //decent in a pinch, but pretty bad.


// ------------ SCRAP SAW ------------ // [Parry, stack damage experimental]
/obj/item/melee/smith/wakizashi/scrapsaw
	name = "scrap saw"
	icon_state = "saw_smith"
	overlay_state = "handle_saw"
	force = (FORCE_SMITH_HIGH-3)
	wound_bonus = WOUNDING_BONUS_TINY
	bare_wound_bonus = WOUNDING_BONUS_BIG
	tool_behaviour = TOOL_SAW
	toolspeed = 1
	hitsound = 'sound/effects/butcher.ogg'
	var/bleed_stacks_per_hit = 3

/obj/item/melee/smith/wakizashi/scrapsaw/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!isliving(target) || !proximity_flag)
		return
	var/mob/living/M = target
	if(!(M.mob_biotypes & MOB_ORGANIC))
		return
	if(user.a_intent != INTENT_HARM)
		var/datum/status_effect/stacking/saw_bleed/bloodletting/B = M.has_status_effect(/datum/status_effect/stacking/saw_bleed/bloodletting)
		if(!B)
			M.apply_status_effect(/datum/status_effect/stacking/saw_bleed/bloodletting, bleed_stacks_per_hit)
		else
			B.add_stacks(bleed_stacks_per_hit)


// ------------ MACE ------------ //
/obj/item/melee/smith/mace
	name = "mace"
	icon_state = "mace_smith"
	overlay_state = "shaft_mace"
	attack_speed = MELEE_SPEED_SLOW
	force = (FORCE_SMITH_LOW+1)
	armour_penetration = PIERCING_MAJOR
	throwforce = THROWING_POOR
	wound_bonus = WOUNDING_BONUS_HUGE
	total_mass = (TOTAL_MASS_MEDIEVAL_WEAPON*1.2)
	hitsound = 'modular_BD2/blacksmith/sound/hit_mace.ogg'

/obj/item/melee/smith/mace/afterattack(mob/living/M, mob/living/user)
	. = ..()
	if(!istype(M))
		return
	M.apply_damage(15, STAMINA, "chest", M.run_armor_check("chest", "melee"))



//////////////////////////////////
//								//
//  	ONE HANDED SWORDS		//
//								//
//////////////////////////////////

// ------------ SWORD ------------ // [AP 0.1 Parry]
/obj/item/melee/smith/sword
	name = "sword"
	icon_state = "sword_smith"
	item_state = "sword_smith"
	overlay_state = "hilt_sword"
	force = FORCE_SMITH_HIGH
	armour_penetration = PIERCING_MINOR
	wound_bonus = WOUNDING_BONUS_BIG
	item_flags = ITEM_CAN_PARRY
	block_chance = 10
	block_parry_data = /datum/block_parry_data/sword
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_EDGED

/datum/block_parry_data/sword
	parry_stamina_cost = 50
	parry_time_windup = 0.5
	parry_time_active = 4
	parry_time_spindown = 1
	parry_time_perfect = 0.75
	parry_time_perfect_leeway = 0.75
	parry_imperfect_falloff_percent = 30
	parry_efficiency_perfect = 100
	parry_failed_stagger_duration = 3 SECONDS
	parry_failed_clickcd_duration = 2 SECONDS

/obj/item/melee/smith/sword/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/butchering, 120, 70) //decent in a pinch, but pretty bad.
	AddElement(/datum/element/sword_point)


// ------------ SPATHA ------------ // [AP 0.1 Parry]
/obj/item/melee/smith/sword/spatha
	name = "spatha"
	icon_state = "spatha_smith"
	item_state = "spatha_smith"
	overlay_state = "hilt_spatha"
	block_chance = 14


// ------------ SABRE ------------ // [AP 0.1 Parry]
/obj/item/melee/smith/sword/sabre
	name = "sabre"
	icon_state = "sabre_smith"
	item_state = "sabre_smith"
	overlay_state = "hilt_sabre"
	force = (FORCE_SMITH_HIGH-1)
	block_chance = 18
	block_parry_data = /datum/block_parry_data/smithsaber

/datum/block_parry_data/smithsaber
	parry_stamina_cost = 50
	parry_time_active = 8
	parry_time_perfect = 2
	parry_time_perfect_leeway = 2
	parry_failed_stagger_duration = 3 SECONDS
	parry_failed_clickcd_duration = 3 SECONDS
	parry_time_windup = 0
	parry_time_spindown = 0
	parry_imperfect_falloff_percent = 0
	parry_efficiency_to_counterattack = 100
	parry_efficiency_considered_successful = 100
	parry_efficiency_perfect = 120
	parry_data = list(PARRY_COUNTERATTACK_MELEE_ATTACK_CHAIN = 1)



//////////////////////////////////
//								//
//  		LONG SWORDS			//
//								//
//////////////////////////////////

// ------------ KATANA ------------ // [AP 0.2 Parry]
/obj/item/twohanded/smithed/katana
	name = "katana"
	icon_state = "katana_smith"
	icon_prefix = "katana_smith"
	wielded_icon = "katana_smith"
	overlay_state = "hilt_katana"
	force = (FORCE_SMITH_HIGH-1)
	armour_penetration = PIERCING_MODERATE
	throwforce = THROWING_POOR
	wound_bonus = WOUNDING_BONUS_BIG
	wielded_mult = 1.25
	item_flags = ITEM_CAN_PARRY
	block_chance = 15
	block_parry_data = /datum/block_parry_data/smithkatana
	slot_flags = ITEM_SLOT_BELT
	hitsound = 'modular_BD2/blacksmith/sound/hit_sword.ogg'

/datum/block_parry_data/smithkatana
	parry_stamina_cost = 50
	parry_time_active = 6
	parry_time_perfect = 3
	parry_time_perfect_leeway = 3
	parry_failed_stagger_duration = 3 SECONDS
	parry_failed_clickcd_duration = 3 SECONDS
	parry_time_windup = 0
	parry_time_spindown = 0
	parry_imperfect_falloff_percent = 0
	parry_efficiency_to_counterattack = 100
	parry_efficiency_considered_successful = 120
	parry_efficiency_perfect = 120
	parry_data = list(PARRY_COUNTERATTACK_MELEE_ATTACK_CHAIN = 1)

/obj/item/twohanded/smithed/katana/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/butchering, 130, 60) //pretty bad.
	AddElement(/datum/element/sword_point)


// ------------ LONGSWORD ------------ // [AP 0.2 Parry]
/obj/item/twohanded/smithed/katana/longsword
	name = "longsword"
	icon_state = "longsword_smith"
	icon_prefix = "longsword_smith"
	wielded_icon = "longsword_smith"
	overlay_state = "hilt_longsword"



	// ------------ ZWEIHANDER ------------ // SCHEISSE, DAS IST DER GROSS BLADEN
/obj/item/twohanded/smithed/zweihander
	name = "zweihander"
	desc = "Scheiße, das ist ein groß fucking sword!"
	icon_state = "zwei_smith"
	icon_prefix = "zwei_smith"
	wielded_icon = "zwei_smith"
	icon_prefix = "zwei_smith"
	overlay_state = "hilt_zwei"
	attack_speed = MELEE_SPEED_SLOWEST
	force = FORCE_SMITH_HIGH
	armour_penetration = PIERCING_MODERATE
	throwforce = THROWING_POOR
	wound_bonus = WOUNDING_BONUS_HUGE
	sharpness = SHARP_EDGED
	wielded_mult = 1.4
	slot_flags = ITEM_SLOT_BACK
	item_flags = ITEM_CAN_PARRY
	total_mass = TOTAL_MASS_MEDIEVAL_WEAPON * 3
	hitsound = 'sound/weapons/zweihander.ogg'
	block_chance = 20
	block_parry_data = /datum/block_parry_data/smithzweihander

/datum/block_parry_data/smithzweihander
	parry_stamina_cost = 50
	parry_time_active = 10
	parry_time_perfect = 3
	parry_time_perfect_leeway = 3
	parry_failed_stagger_duration = 4 SECONDS
	parry_failed_clickcd_duration = 4 SECONDS
	parry_time_windup = 1
	parry_time_spindown = 1
	parry_imperfect_falloff_percent = 0
	parry_efficiency_to_counterattack = 100
	parry_efficiency_considered_successful = 120
	parry_efficiency_perfect = 120
	parry_data = list(PARRY_COUNTERATTACK_MELEE_ATTACK_CHAIN = 1)


// ------------ SCRAP BLADE ------------ // [AP 0.2 Parry]
/obj/item/twohanded/smithed/katana/scrapblade
	name = "scrap blade"
	icon_state = "scrap_smith"
	icon_prefix = "scrap_smith"
	wielded_icon = "scrap_smith"
	overlay_state = "hilt_scrap"
	attack_speed = MELEE_SPEED_SLOW
	force = FORCE_SMITH_HIGH

/obj/item/twohanded/smithed/katana/scrapblade/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/butchering, 110, 75) //decent in a pinch, but pretty bad.



//////////////////////////////////
//								//
// 		 		AXES			//
//								//
//////////////////////////////////

// ------------ HEAVY AXE ------------ // [AP 0.1 Doorbusting]
/obj/item/twohanded/smithed/axe
	name = "heavy axe"
	icon_state = "axe_smith"
	wielded_icon = "axe_smith"
	icon_prefix = "axe_smith"
	overlay_state = "shaft_axe"
	force = FORCE_SMITH_LOW
	armour_penetration = PIERCING_MODERATE
	throwforce = THROWING_POOR
	wound_bonus = WOUNDING_BONUS_BIG
	total_mass = TOTAL_MASS_MEDIEVAL_WEAPON * 2
	slot_flags = ITEM_SLOT_BACK

/obj/item/twohanded/smithed/axe/afterattack(atom/A, mob/living/user, proximity)
	. = ..()
	if(!proximity || !wielded || IS_STAMCRIT(user))
		return
	if(istype(A, /obj/machinery/door))
		var/obj/machinery/door/D = A
		D.take_damage(20, BRUTE, "melee", 0)
	else if(istype(A, /obj/structure/simple_door))
		var/obj/structure/simple_door/M = A
		M.take_damage(20, BRUTE, "melee", 0)


// ------------ LEGION WAR AXE ------------ // [AP 0.1 Doorbusting]
/obj/item/twohanded/smithed/axe/waraxe
	name = "war axe"
	icon_state = "waraxe_smith"
	icon_prefix = "waraxe_smith"
	wielded_icon = "waraxe_smith"
	icon_prefix = "waraxe_smith"
	overlay_state = "shaft_waraxe"
	throwforce = THROWING_GOOD

/obj/item/twohanded/smithed/axe/waraxe/afterattack(atom/A, mob/living/user, proximity)
	. = ..()
	if(!proximity || !wielded || IS_STAMCRIT(user))
		return
	if(istype(A, /obj/machinery/door))
		var/obj/machinery/door/D = A
		D.take_damage(20, BRUTE, "melee", 0)
	else if(istype(A, /obj/structure/simple_door))
		var/obj/structure/simple_door/M = A
		M.take_damage(20, BRUTE, "melee", 0)


// ------------ GHOUL CRUSHER ------------ // [Ghoul bonus] - for those dry twig like limbs, snap snap..(was meant to dislocate PC ghouls but code did not work properly so removed)
/obj/item/twohanded/smithed/crusher
	name = "crusher"
	desc = "Affectionally known as the ghoul crusher, this club is extremely difficult to swing."
	icon_state = "crusher_smith"
	icon_prefix = "crusher_smith"
	wielded_icon = "crusher_smith"
	icon_prefix = "crusher_smith"
	overlay_state = "shaft_crusher"
	attack_speed = MELEE_SPEED_SLOWEST
	force = FORCE_SMITH_LOW
	armour_penetration = PIERCING_MAJOR
	throwforce = THROWING_PATHETIC
	wound_bonus = WOUNDING_BONUS_BIG
	sharpness = SHARP_NONE
	slot_flags = ITEM_SLOT_BACK
	total_mass = TOTAL_MASS_MEDIEVAL_WEAPON * 4
	hitsound = 'modular_BD2/blacksmith/sound/hit_mace.ogg'

/obj/item/twohanded/smithed/crusher/afterattack(atom/A, mob/living/user, proximity)
	. = ..()
	if(!proximity || !wielded || IS_STAMCRIT(user))
		return
	if(istype(A, /mob/living/simple_animal/hostile/ghoul))
		var/mob/living/simple_animal/hostile/ghoul/D = A
		D.apply_damage(25, BRUTE)



//////////////////////////////////////
//									//
// 		 		POLEARMS			//
//									//
//////////////////////////////////////

// ------------ SPEAR ------------ // [Reach]
/obj/item/twohanded/smithed/spear
	name = "spear"
	lefthand_file = 'modular_BD2/blacksmith/icons/onmob/64x64_lefthand.dmi'
	righthand_file = 'modular_BD2/blacksmith/icons/onmob/64x64_righthand.dmi'
	icon_state = "spear_smith"
	wielded_icon = "spear_smith"
	icon_prefix = "spear_smith"
	overlay_state = "shaft_spear"
	force = FORCE_SMITH_REACH
	throwforce = THROWING_GOOD
	wielded_mult = 1.3
	max_reach = 2
	sharpness = SHARP_POINTY
	inhand_x_dimension = 64
	inhand_y_dimension = 64


// ------------ PIKE ------------ // [Reach+1, armor pen]
/obj/item/twohanded/smithed/spear/pike
	name = "pike"
	desc = "A spear, but more. This very long weapon has even more reach than a normal spear but is a bit unwieldy to use, downright impossible up close."
	icon_state = "pike_smith"
	overlay_state = "shaft_pike"
	wielded_icon = "pike_smith_wield"
	icon_prefix = "pike_smith"
	force = (FORCE_SMITH_REACH-2)
	wielded_mult = 1.5
	throwforce = THROWING_POOR
	wound_bonus = WOUNDING_BONUS_BIG
	bare_wound_bonus = WOUNDING_BONUS_SMALL
	armour_penetration = PIERCING_MINOR
	min_reach = 2
	max_reach = 3
	sharpness = SHARP_POINTY
	attack_verb = list("impaled", "gored", "stabbed")
	hitsound = 'sound/weapons/pike.ogg'
	attack_speed = MELEE_SPEED_SLOWEST
	total_mass = TOTAL_MASS_MEDIEVAL_WEAPON * 2


// ------------ TRIDENT ------------ // [Reach Embed]
/obj/item/twohanded/smithed/spear/trident
	name = "trident"
	desc = "Made for spearing small lizard and fish, able to pin down the prey if thrown."
	icon_state = "trident_smith"
	wielded_icon = "trident_smith"
	icon_prefix = "trident_smith"
	overlay_state = "shaft_trident"
	attack_speed = MELEE_SPEED_SLOW
	force = (FORCE_SMITH_REACH+1)
	embedding = list("pain_mult" = 2, "embed_chance" = 40, "fall_chance" = 30, "ignore_throwspeed_threshold" = TRUE)
	armour_penetration = 0


// ------------ LEGION LANCE ------------ // [Reach]
/obj/item/twohanded/smithed/spear/lance
	name = "legion lance"
	icon_state = "lance_smith"
	wielded_icon = "lance_smith_wield"
	icon_prefix = "lance_smith"
	overlay_state = "shaft_lance"



//////////////////////////////////////////////////
//												//
//  			THROWING WEAPONS				//
//												//
//////////////////////////////////////////////////

// ------------ JAVELIN ------------ // [Embed]
/obj/item/melee/smith/javelin
	name = "javelin"
	icon_state = "javelin_smith"
	overlay_state = "shaft_javelin"
	item_state = "javelin_smith"
	force = FORCE_SMITH_REACH
	armour_penetration = PIERCING_MODERATE
	sharpness = SHARP_POINTY
	embedding = list("pain_mult" = 2, "embed_chance" = 62, "fall_chance" = 20, "ignore_throwspeed_threshold" = TRUE)

// ------------ THROWING KNIFE ------------ // [Embed]
/obj/item/melee/smith/throwingknife
	name = "throwing knife"
	icon_state = "throwing_smith"
	overlay_state = "handle_throwing"
	item_state = "dagger_smith"
	force = FORCE_SMITH_REACH
	armour_penetration = PIERCING_MINOR
	embedding = list("pain_mult" = 2, "embed_chance" = 65, "fall_chance" = 20, "ignore_throwspeed_threshold" = TRUE)
	w_class = WEIGHT_CLASS_SMALL

// ------------ METAL BOLA ------------ //
/obj/item/restraints/legcuffs/bola/smithed
	name = "bola"
	desc = "All-metal bola for strong prey."
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	icon_state = "bola_smith"
	lefthand_file = 'modular_BD2/blacksmith/icons/onmob/lefthand.dmi'
	righthand_file = 'modular_BD2/blacksmith/icons/onmob/righthand.dmi'
	item_state = "bola_smith"
	breakouttime = 40 //5 more deciseconds than regular bola
	material_flags = MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS

/obj/item/restraints/legcuffs/bola/smithed/Initialize()
	..()
	desc = "All-metal bola for strong prey."
	var/mutable_appearance/overlay
	overlay = mutable_appearance(icon, "chain_bola")
	overlay.appearance_flags = RESET_COLOR
	add_overlay(overlay)



//////////////////////////////////////////////
//											//
//  			SMITHED ARMOR				//
//											//
//////////////////////////////////////////////

/obj/item/clothing/suit/armor/heavy/metal/smithed
	name = "smithed metal armor"
	desc = "A set of plates with leather straps, protecting some vital areas."
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	lefthand_file = 'modular_BD2/blacksmith/icons/onmob/lefthand.dmi'
	righthand_file = 'modular_BD2/blacksmith/icons/onmob/righthand.dmi'
	mob_overlay_icon = 'modular_BD2/blacksmith/icons/onmob/slot.dmi'
	icon_state = "smithed_armor_metal"
	item_state = "smithed_armor_metal"
