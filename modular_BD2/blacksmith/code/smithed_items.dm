//////////////////////////////////////////
//										//
//		SMITHED ITEMS BASE CODE			//
//										//
//////////////////////////////////////////

/obj/item/blacksmith
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	righthand_file = 'modular_BD2/blacksmith/icons/onmob/righthand.dmi'
	lefthand_file = 'modular_BD2/blacksmith/icons/onmob/lefthand.dmi'
	force = WEAPON_FORCE_BIG_TOOL
	max_integrity = 40
	w_class = WEIGHT_CLASS_SMALL

/obj/item/smithing
	name = "base class /obj/item/smithing"
	desc = "Attach a wooden rod."
	icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
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

/obj/item/smithing/Initialize()
	add_overlay(image(icon= 'modular_BD2/blacksmith/icons/blacksmith.dmi',icon_state="[icon_state]_hot"))
	set_light_on(TRUE)
	update_icon()
	return ..()

/obj/item/smithing/proc/istempered()
	cut_overlay(image(icon= 'modular_BD2/blacksmith/icons/blacksmith.dmi',icon_state="[icon_state]_hot"))
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
		playsound(src, 'modular_BD2/blacksmith/sound/burned.ogg', 15, 1)
		var/list/hand_items = list(H.get_active_held_item(),H.get_inactive_held_item())
		if(src in hand_items)
			H.dropItemToGround(src)


/obj/item/smithing/attackby(obj/item/I, mob/user)
	if(toohot == TRUE)
		to_chat(user, "<span class='warning'>You need to quench the [src] before finishing it!</span>")
		return
	if(istype(I, LEATHER_STRIP))
		to_chat(user, "<span class='warning'>You start to wrap the leather strip around the [src].</span>")
		I.use(1)
		playsound(src, 'modular_BD2/blacksmith/sound/latex.ogg', 70, 1)
		if(!do_after(user, 30, TRUE, src))
			return
		startfinish()
	else if(istype(I, finishingitem))
		qdel(I)
		to_chat(user, "<span class='warning'>You start to attach the handle and fittings to the [src].</span>")
		playsound(src, 'modular_BD2/blacksmith/sound/craft_3.ogg', 90, 1)
		if(!do_after(user, 30, TRUE, src))
			return
		startfinish()
		user.put_in_hands(finalitem)
	else
		return ..()


/obj/item/smithing/proc/startfinish()
	dofinish()

/obj/item/smithing/proc/dofinish()
	if(!finalitem)
		return
	var/qualname
	switch(quality)
		if(-1000 to -5)
			qualname = "awful"
		if(-1000 to -2)
			qualname = "shoddy"
		if(-1000 to -1)
			qualname =  "poor"
		if(-1 to 1)
			qualname = "normal"
		if(13 to INFINITY)
			qualname = "legendary"
		if(11 to 13)
			qualname = "masterwork"
		if(8 to 11)
			qualname = "excellent"
		if(5 to 8)
			qualname = "good"
		if(0 to 5)
			qualname = "above-average"
	var/datum/material/mat = custom_materials[1]
	finalitem.set_custom_materials(custom_materials)
	mat = mat.name
	if(artifact)
		dwarfyartifact(finalitem, mat)
	else
		finalitem.name = "[qualname] [mat] [initial(finalitem.name)]"
	finalitem.forceMove(get_turf(src))
	qdel(src)

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


/obj/item/blacksmith/ingot/on_attack_hand(mob/user)
	var/mob/living/carbon/human/H
	if(workability != "shapeable")
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
		playsound(src, 'modular_BD2/blacksmith/sound/burned.ogg', 15, 1)
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
		playsound(src, 'modular_BD2/blacksmith/sound/craft_3.ogg', 50, 1)
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
	hitsound = 'modular_BD2/blacksmith/sound/chain.ogg'


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

/obj/item/smithing/hammerhead/startfinish()
	var/obj/item/melee/smith/hammer/finalforreal = new /obj/item/melee/smith/hammer(src)
	finalforreal.force += quality/4
	finalforreal.qualitymod = quality/2.5
	finalitem = finalforreal
	..()

// -------- SHOVEL -------- //
/obj/item/smithing/shovelhead
	name = "smithed shovel head"
	finalitem = /obj/item/shovel/smithed
	icon_state = "shovel"

/obj/item/smithing/shovelhead/startfinish()
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

/obj/item/smithing/pickaxehead/startfinish()
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

/obj/item/smithing/prospectingpickhead/startfinish()
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

/obj/item/smithing/crowbar/startfinish()
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

/obj/item/smithing/unitool/startfinish()
	var/obj/item/crowbar/smithedunitool/finalforreal = new /obj/item/crowbar/smithedunitool(src)
	finalforreal.force += QUALITY_MODIFIER
	finalitem = finalforreal
	..()

// -------- KITCHEN KNIFE -------- //
/obj/item/smithing/knifeblade
	name = "smithed knife blade"
	desc = "Attach a sword handle."
	icon_state = "knife_smith"
	finishingitem = SWORD_HANDLE
	finalitem = /obj/item/kitchen/knife/smithed

/obj/item/smithing/knifeblade/startfinish()
	var/obj/item/kitchen/knife/smithed/finalforreal = new /obj/item/kitchen/knife/smithed(src)
	finalforreal.force = QUALITY_MODIFIER*3
	finalitem = finalforreal
	..()


//////////////////////////////////////////////////
//												//
//  	BLING - smithed and finished both		//
//												//
//////////////////////////////////////////////////

/obj/item/smithing/special
	mob_overlay_icon = 'modular_BD2/blacksmith/icons/onmob/slot.dmi'
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
/obj/item/smithing/ballandchain
	name = "unchained ball"
	desc = "Finish by attaching a chain to it."
	icon_state = "ball"
	finishingitem = CHAIN
	finalitem = /obj/item/restraints/legcuffs/ballandchain
	throwforce = 15
	throw_range = 2

/obj/item/smithing/ballandchain/startfinish()
	var/obj/item/smithing/ballandchain/finalforreal = new /obj/item/restraints/legcuffs/ballandchain(src)
	finalitem = new /obj/item/restraints/legcuffs/ballandchain(src)
	finalforreal.force += QUALITY_MODIFIER*2
	finalitem = finalforreal
	finalitem.icon = 'modular_BD2/blacksmith/icons/blacksmith.dmi'
	finalitem.icon_state = "ballandchain"
	finalitem.name = "ball and chain"
	finalitem.desc = "Clamp it on the prisoners feet. They will need a long time to remove it themselves."
	finalitem.material_flags = MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS
	..()


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
/obj/item/smithing/daggerblade
	name = "smithed dagger blade"
	desc = "Attach a sword handle."
	icon_state = "dagger_smith"
	finishingitem = SWORD_HANDLE
	finalitem = /obj/item/melee/smith/dagger

/obj/item/smithing/daggerblade/startfinish()
	finalitem = new /obj/item/melee/smith/dagger(src)
	finalitem.force += QUALITY_MODIFIER
	finalitem.armour_penetration += QUALITY_MODIFIER*0.01
	..()

// ------------ BOWIE KNIFE ------------ //
/obj/item/smithing/bowieblade
	name = "smithed bowie blade"
	desc = "Attach a sword handle."
	icon_state = "bowie_smith"
	finishingitem = SWORD_HANDLE
	finalitem = /obj/item/melee/smith/dagger/bowie

/obj/item/smithing/bowieblade/startfinish()
	finalitem = new /obj/item/melee/smith/dagger/bowie(src)
	finalitem.force += QUALITY_MODIFIER
	finalitem.armour_penetration += QUALITY_MODIFIER*0.01
	..()


// ------------ MACHETE ------------ //
/obj/item/smithing/macheteblade
	name = "smithed machete blade"
	desc = "Attach a sword handle."
	icon_state = "machete_smith"
	finishingitem = SWORD_HANDLE
	finalitem = /obj/item/melee/smith/machete

/obj/item/smithing/macheteblade/startfinish()
	finalitem = new /obj/item/melee/smith/machete(src)
	finalitem.force += QUALITY_MODIFIER
	..()

// ------------ GLADIUS ------------ //
/obj/item/smithing/gladiusblade
	name = "smithed gladius blade"
	desc = "Attach a sword handle."
	icon_state = "gladius_smith"
	finishingitem = SWORD_HANDLE
	finalitem = /obj/item/melee/smith/machete/gladius

/obj/item/smithing/gladiusblade/startfinish()
	finalitem = new /obj/item/melee/smith/machete/gladius(src)
	finalitem.force += QUALITY_MODIFIER
	..()

// ------------ REFORGED MACHETE ------------ //
/obj/item/smithing/macheterblade
	name = "reforged machete blade"
	desc = "Attach a sword handle."
	icon_state = "macheter_smith"
	finishingitem = SWORD_HANDLE
	finalitem = /obj/item/melee/smith/machete/reforged

/obj/item/smithing/macheterblade/startfinish()
	finalitem = new /obj/item/melee/smith/machete/reforged(src)
	finalitem.force += QUALITY_MODIFIER
	..()


// ------------ WAKIZASHI ------------ //
/obj/item/smithing/wakiblade
	name = "smithed wakizashi blade"
	desc = "Attach a sword handle."
	icon_state = "waki_smith"
	finishingitem = SWORD_HANDLE
	finalitem = /obj/item/melee/smith/wakizashi

/obj/item/smithing/wakiblade/startfinish()
	finalitem = new /obj/item/melee/smith/wakizashi(src)
	finalitem.force += QUALITY_MODIFIER
	..()

// ------------ SCRAP SAW ------------ //
/obj/item/smithing/scrapsaw
	name = "unfinished scrap saw"
	desc = "Wrap it in leather strips."
	icon_state = "saw_smith"
	finishingitem = LEATHER_STRIP
	finalitem = /obj/item/melee/smith/wakizashi/scrapsaw

/obj/item/smithing/scrapsaw/startfinish()
	finalitem = new /obj/item/melee/smith/wakizashi/scrapsaw(src)
	finalitem.force += QUALITY_MODIFIER
	..()


// ------------ MACE ------------ //
/obj/item/smithing/macehead
	name = "smithed macehead"
	icon_state = "mace_smith"
	finalitem = /obj/item/melee/smith/mace

/obj/item/smithing/macehead/startfinish()
	finalitem = new /obj/item/melee/smith/mace(src)
	finalitem.force += QUALITY_MODIFIER
	finalitem.armour_penetration += QUALITY_MODIFIER*0.01
	..()


// ------------ SWORD ------------ //
/obj/item/smithing/swordblade
	name = "smithed swordblade"
	desc = "Attach a sword handle."
	icon_state = "sword_smith"
	finishingitem = SWORD_HANDLE
	finalitem = /obj/item/melee/smith/sword

/obj/item/smithing/swordblade/startfinish()
	finalitem = new /obj/item/melee/smith/sword(src)
	finalitem.force += QUALITY_MODIFIER
	finalitem.armour_penetration += QUALITY_MODIFIER*0.01
	..()

// ------------ SPATHA ------------ //
/obj/item/smithing/spathablade
	name = "smithed spathablade"
	desc = "Attach a sword handle."
	icon_state = "spatha_smith"
	finishingitem = SWORD_HANDLE
	finalitem = /obj/item/melee/smith/sword/spatha

/obj/item/smithing/spathablade/startfinish()
	finalitem = new /obj/item/melee/smith/sword/spatha(src)
	finalitem.force += QUALITY_MODIFIER
	finalitem.armour_penetration += QUALITY_MODIFIER*0.01
	..()

// ------------ SABRE ------------ //
/obj/item/smithing/sabreblade
	name = "smithed sabre blade"
	desc = "Attach a sword handle."
	finishingitem = SWORD_HANDLE
	finalitem = /obj/item/melee/smith/sword/sabre
	icon_state = "sabre_smith"

/obj/item/smithing/sabreblade/startfinish()
	finalitem = new /obj/item/melee/smith/sword/sabre(src)
	finalitem.force += QUALITY_MODIFIER
	finalitem.armour_penetration += QUALITY_MODIFIER*0.01
	..()


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

/obj/item/smithing/katanablade/startfinish()
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

/obj/item/smithing/longswordblade/startfinish()
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

/obj/item/smithing/zweiblade/startfinish()
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

/obj/item/smithing/scrapblade/startfinish()
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

/obj/item/smithing/axehead/startfinish()
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

/obj/item/smithing/waraxehead/startfinish()
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

/obj/item/smithing/crusherhead/startfinish()
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

/obj/item/smithing/spearhead/startfinish()
	var/obj/item/twohanded/smithed/spear/finalforreal = new /obj/item/twohanded/smithed/spear(src)
	finalforreal.force += QUALITY_MODIFIER
	finalforreal.force_wielded = finalforreal.force*finalforreal.wielded_mult
	finalforreal.force_unwielded = finalforreal.force
	finalforreal.AddComponent(/datum/component/two_handed, force_unwielded=finalforreal.force_unwielded, force_wielded=finalforreal.force_wielded, icon_wielded="[icon_state]_wield")
	finalforreal.throwforce = finalforreal.force
	finalitem = finalforreal
	..()

// ------------ TRIDENT ------------ //
/obj/item/smithing/tridenthead
	name = "smithed tridenthead"
	finalitem = /obj/item/twohanded/smithed/spear/trident
	icon_state = "trident_smith"

/obj/item/smithing/tridenthead/startfinish()
	var/obj/item/twohanded/smithed/spear/trident/finalforreal = new /obj/item/twohanded/smithed/spear/trident(src)
	finalforreal.force += QUALITY_MODIFIER
	finalforreal.force_wielded = finalforreal.force*finalforreal.wielded_mult
	finalforreal.force_unwielded = finalforreal.force
	finalforreal.AddComponent(/datum/component/two_handed, force_unwielded=finalforreal.force_unwielded, force_wielded=finalforreal.force_wielded, icon_wielded="[icon_state]_wield")
	finalforreal.throwforce = finalforreal.force
	finalitem = finalforreal
	..()


// ------------ PIKE ------------ //
/obj/item/smithing/pikehead
	name = "smithed pikehead"
	finalitem = /obj/item/twohanded/smithed/spear/pike
	icon_state = "pike_smith"

/obj/item/smithing/pikehead/startfinish()
	var/obj/item/twohanded/smithed/spear/pike/finalforreal = new /obj/item/twohanded/smithed/spear/pike(src)
	finalforreal.force += QUALITY_MODIFIER
	finalforreal.force_wielded = finalforreal.force*finalforreal.wielded_mult
	finalforreal.force_unwielded = finalforreal.force
	finalforreal.AddComponent(/datum/component/two_handed, force_unwielded=finalforreal.force_unwielded, force_wielded=finalforreal.force_wielded, icon_wielded="[icon_state]_wield")
	finalforreal.throwforce = finalforreal.force
	finalitem = finalforreal
	..()


// ------------ LEGION LANCE ------------ //
/obj/item/smithing/lancehead
	name = "smithed lancehead"
	finalitem = /obj/item/twohanded/smithed/spear/lance
	icon_state = "lance_smith"

/obj/item/smithing/lancehead/startfinish()
	var/obj/item/twohanded/smithed/spear/lance/finalforreal = new /obj/item/twohanded/smithed/spear/lance(src)
	finalforreal.force += QUALITY_MODIFIER
	finalforreal.force_wielded = finalforreal.force*finalforreal.wielded_mult
	finalforreal.force_unwielded = finalforreal.force
	finalforreal.AddComponent(/datum/component/two_handed, force_unwielded=finalforreal.force_unwielded, force_wielded=finalforreal.force_wielded, icon_wielded="[icon_state]_wield")
	finalforreal.throwforce = finalforreal.force
	finalitem = finalforreal
	..()


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

/obj/item/smithing/throwingknife/startfinish()
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

/obj/item/smithing/javelinhead/startfinish()
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

/obj/item/smithing/bola/startfinish()
	var/obj/item/restraints/legcuffs/bola/smithed/finalforreal = new /obj/item/restraints/legcuffs/bola/smithed(src)
	finalforreal.breakouttime+= QUALITY_MODIFIER
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
