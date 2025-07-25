///////////////
//// ARMOR ////
///////////////

/obj/item/clothing/suit/armor
	name = "armor template"
	icon = 'icons/obj/clothing/suits.dmi'
	lefthand_file = 'icons/mob/inhands/clothing_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/clothing_righthand.dmi'
	cold_protection = CHEST|GROIN
	min_cold_protection_temperature = ARMOR_MIN_TEMP_PROTECT
	heat_protection = CHEST|GROIN
	max_heat_protection_temperature = ARMOR_MAX_TEMP_PROTECT
	strip_delay = 30
	equip_delay_other = 40
	max_integrity = 250
	resistance_flags = NONE
	body_parts_covered = CHEST|GROIN|ARMS|LEGS // gonna be like this until limbs stop critting people
	blood_overlay_type = "armor"
	slowdown = ARMOR_SLOWDOWN_NONE * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tier_desc = ARMOR_CLOTHING_DESC
	mutantrace_variation = STYLE_DIGITIGRADE

	/// which mutantrace variations are supported. leave at NONE to keep it snapped at plantigrade
	//mutantrace_variation = NONE

	/// These dont seem to do anything
	var/list/protected_zones = list(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_GROIN, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	var/armor_block_chance = null //Chance for the armor to block a low penetration projectile
	var/deflection_chance = null //Chance for the armor to redirect a blocked projectile
	var/melee_block_threshold = null
	var/dmg_block_threshold = null

/obj/item/clothing/suit/armor/Initialize()
	. = ..()
	if(!islist(allowed))
		allowed = list()
	// Here we set up what's allowed in their suit storage.
	// this lets us merge multiple lists, and also disallow certain things from it too
	allowed |= GLOB.default_all_armor_slot_allowed

/obj/item/clothing/suit/armor/examine()
	. = ..()
	. += span_notice(armor_tier_desc)


/*

* ARMOR TIERS
*
* Clothes (not armor)
* - lightly armored at best, might be craftable into armor accessories later
* - Pockets?
*
* Light
* - High mobility (can run from most mobs easily)
* - Common, cheap, usually
* - Low protection
* Medium
* - Less mobility (likely need sprint to escape most mobs)
* - something
* - Med protection
* Heavy
* - Low mobility (Tank hits or have friends)
* - High protection
* - More specialized armor too
* Power Armor
* - Mobile
* - Just about godmode

 */

/////////////
// CLOTHES //
/////////////

/*
 * Types:
 * Overalls (chest legs)
 * - utility suits for holding tools and stuff
 * Jacket (chest arms)
 * - Might have pockets?
 * Duster (chest arms legs)
 * - Full body decorative and cool
 * vest (chest)
 * - Decorative and cool
 * costume? (everything?)
 * Also should have armor inserts later
 */

//// Clothes ARMOR PARENT ////

/obj/item/clothing/suit/armor/outfit
	name = "basic outerwear template"
	desc = "probably shouldnt see this"
	icon = 'icons/obj/clothing/suits.dmi'
	//mob_overlay_icon = 'icons/fallout/onmob/clothes/suit_utility.dmi'
	icon_state = "overalls_farmer"
	item_state = "overalls_farmer"
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/jacket //fuck it everyone gets pockets
	cold_protection = CHEST|GROIN
	heat_protection = CHEST|GROIN
	min_cold_protection_temperature = ARMOR_MIN_TEMP_PROTECT
	max_heat_protection_temperature = ARMOR_MAX_TEMP_PROTECT
	strip_delay = 10
	equip_delay_other = 10
	max_integrity = 100
	armor = ARMOR_VALUE_CLOTHES

//////////////////
//// OVERALLS ////
//////////////////

/obj/item/clothing/suit/armor/outfit/overalls
	name = "overalls"
	desc = "A set of overall templates that shouldnt exist."
	icon = 'icons/fallout/clothing/suits_utility.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/suit_utility.dmi'
	icon_state = "overalls_farmer"
	item_state = "overalls_farmer"
	pocket_storage_component_path = /datum/component/storage/concrete/pockets // big pockets!
	body_parts_hidden = CHEST|GROIN|LEGS

/obj/item/clothing/suit/armor/outfit/overalls/farmer
	name = "farmer overalls"
	desc = "A set of denim overalls suitable for farming."
	icon = 'icons/fallout/clothing/suits_utility.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/suit_utility.dmi'
	icon_state = "overalls_farmer"
	item_state = "overalls_farmer"
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/service/overalls

/obj/item/clothing/suit/armor/outfit/overalls/farmer/Initialize()
	. = ..()
	allowed |= GLOB.toolbelt_allowed

/obj/item/clothing/suit/armor/outfit/overalls/sexymaid // best suit
	name = "sexy maid outfit"
	desc = "A maid outfit that shows just a little more skin than needed for cleaning duties."
	icon = 'icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'icons/mob/clothing/suit.dmi'
	icon_state = "sexymaid_s"
	item_state = "sexymaid_s"
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/service/overalls

/obj/item/clothing/suit/armor/outfit/overalls/sexymaid/Initialize()
	. = ..()
	allowed |= GLOB.toolbelt_allowed

/obj/item/clothing/suit/armor/outfit/overalls/blacksmith
	name = "blacksmith apron"
	desc = "A heavy leather apron designed for protecting the user when metalforging."
	icon = 'icons/fallout/clothing/aprons.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/apron.dmi'
	icon_state = "forge"
	item_state = "forge"
	blood_overlay_type = "armor"
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/service/overalls
	body_parts_hidden = CHEST

/* 	icon = 'icons/obj/clothing/suits.dmi'
	icon_state = "opifex_apron"
	item_state = "opifex_apron" */ // cus this darn sprite is hidden so well I cant find it

/obj/item/clothing/suit/armor/outfit/overalls/blacksmith/Initialize()
	. = ..()
	allowed |= GLOB.toolbelt_allowed

//////////////
//// VEST ////
//////////////

/obj/item/clothing/suit/armor/outfit/vest
	name = "tan vest"
	desc = "It's a vest made of tanned leather."
	icon_state = "tanleather"
	item_state = "det_suit"
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/armor
	body_parts_hidden = CHEST

/obj/item/clothing/suit/armor/outfit/vest/cowboy //Originally cowboy stuff by Nienhaus
	name = "brown vest"
	desc = "A brown vest, typically worn by wannabe cowboys and prospectors. It has a few pockets for tiny items."
	icon_state = "cowboybvest"
	item_state = "lb_suit"

/obj/item/clothing/suit/armor/outfit/vest/bartender
	name = "bartenders vest"
	desc = "A grey vest, adorned with bartenders arm cuffs, a classic western look."
	icon_state = "westender"
	item_state = "lb_suit"
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/service/overalls

/obj/item/clothing/suit/armor/outfit/vest/cowboy/grey
	name = "grey vest"
	desc = "A grey vest, typically worn by wannabe cowboys and prospectors. It has a few pockets for tiny items."
	icon_state = "cowboygvest"
	item_state = "gy_suit"

/obj/item/clothing/suit/armor/outfit/vest/utility
	name = "utility vest"
	desc = "A practical vest with pockets for tools and such."
	icon_state = "vest_utility"
	item_state = "vest_utility"
	icon = 'icons/fallout/clothing/suits_utility.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/suit_utility.dmi'
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/small/four
	body_parts_hidden = 0 // has a bit of upper window stuff

/obj/item/clothing/suit/armor/outfit/vest/utility/logisticsofficer //same as his beret
	name = "logistics officer utility vest"
	desc = "A practical and armored vest with pockets for tools and such."

/obj/item/clothing/suit/armor/outfit/vest/flakjack
	name = "flak jacket"
	desc = "A dilapidated jacket made of ballistic nylon. Smells faintly of napalm."
	icon_state = "flakjack"
	item_state = "redtag"
	blood_overlay_type = "armor"
	body_parts_covered = CHEST|GROIN|LEGS|ARMS|HANDS|HEAD
	resistance_flags = NONE
	armor = ARMOR_VALUE_LIGHT
	mutantrace_variation = STYLE_DIGITIGRADE
	armor_tokens = list()



////////////////
//// JACKET ////
////////////////

/obj/item/clothing/suit/armor/outfit/jacket
	name = "jacket template"
	desc = "its a jacket!!"
	icon_state = "veteran"
	item_state = "suit-command"
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/jacket
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1)
	body_parts_hidden = CHEST|ARMS

/obj/item/clothing/suit/armor/outfit/jacket/merc
	name = "merc veteran coat"
	desc = " A blue leather coat adorned with war medals.<br>This type of outfit is common for professional mercenaries and bounty hunters."
	icon_state = "veteran"
	item_state = "suit-command"
	body_parts_hidden = CHEST

/obj/item/clothing/suit/armor/outfit/jacket/battlecruiser //Do we have Star Craft here as well?!
	name = "captain's coat"
	desc = "Battlecruiser operational!"
	icon_state = "battlecruiser"
	item_state = "hostrench"

/obj/item/clothing/suit/armor/outfit/jacket/mantle
	name = "hide mantle"
	desc = " A rather grisly selection of cured hides and skin, sewn together to form a ragged mantle."
	icon_state = "mantle_liz"
	item_state = "det_suit"
	body_parts_hidden = 0

/obj/item/clothing/suit/armor/outfit/jacket/mfp //Mad Max 1 1979 babe!
	name = "MFP jacket"
	desc = "A Main Force Patrol leather jacket.<br>Offbeat."
	icon_state = "mfp"
	item_state = "hostrench"

/obj/item/clothing/suit/armor/outfit/jacket/mfp/raider
	name = "offbeat jacket"
	desc = "A black leather jacket with a single metal shoulder pad on the right side.<br>The right sleeve was obviously ripped or cut away.<br>It looks like it was originally a piece of a Main Force Patrol uniform."
	icon_state = "mfp_raider"
	body_parts_hidden = CHEST|ARMS

/obj/item/clothing/suit/armor/outfit/jacket/navyblue
	name = "security officer's jacket"
	desc = "This jacket is for those special occasions when a security officer isn't required to wear their armor."
	icon_state = "officerbluejacket"
	item_state = "officerbluejacket"
	// body_parts_covered = CHEST|ARMS
	mutantrace_variation = STYLE_DIGITIGRADE
	body_parts_hidden = CHEST|ARMS

/obj/item/clothing/suit/armor/outfit/jacket/banker
	name = "bankers tailcoat"
	desc = " A long black jacket, finely crafted black leather and smooth finishings make this an extremely fancy piece of rich-mans apparel."
	icon_state = "banker"
	item_state = "banker"
	// body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS
	body_parts_hidden = ARMS

/obj/item/clothing/suit/armor/outfit/jacket/jamrock
	name = "disco-ass blazer"
	desc = "Looks like someone skinned this blazer off some long extinct disco-animal. It has an enigmatic white rectangle on the back and the right sleeve."
	icon_state = "jamrock_blazer"
	item_state = "jamrock_blazer"
	body_parts_hidden = ARMS

/obj/item/clothing/suit/armor/outfit/jacket/blackformaljacket
	name = "black formal overcoat"
	desc = "A neat black overcoat that's only slightly weathered from a nuclear apocalypse."
	icon_state = "black_oversuit"
	item_state = "banker"
	body_parts_hidden = ARMS

/obj/item/clothing/suit/armor/outfit/jacket/police
	name = "police officer's jacket"
	desc = "A simple dark navy jacket, worn by police."
	icon = 'icons/fallout/clothing/suits_cosmetic.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/suit_cosmetic.dmi'
	icon_state = "police_officer"
	item_state = "police_officer"
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/outfit/jacket/police/lieutenant
	name = "police lieutenant's jacket"
	desc = " A simple dark navy jacket, worn by police."
	icon = 'icons/fallout/clothing/suits_cosmetic.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/suit_cosmetic.dmi'
	icon_state = "police_lieutenant"
	item_state = "police_lieutenant"
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/outfit/jacket/police/chief
	name = "police chief's jacket"
	desc = "A simple dark navy jacket, worn by police."
	icon = 'icons/fallout/clothing/suits_cosmetic.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/suit_cosmetic.dmi'
	icon_state = "police_chief"
	item_state = "police_chief"
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/outfit/jacket/ncrcfjacket
	name = "blue denim jacket"
	desc = "A simple breezy denim jacket."
	icon_state = "ncrcfjacket"
	item_state = "ncrcfjacket"
	body_parts_hidden = ARMS

// until togglesuits are made into normal suits, treat these as jackets

/obj/item/clothing/suit/toggle/labcoat
	name = "labcoat"
	desc = "A suit that protects against minor chemical spills."
	icon_state = "labcoat"
	item_state = "labcoat"
	blood_overlay_type = "coat"
	// body_parts_covered = CHEST|ARMS
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/jacket
	togglename = "buttons"
	species_exception = list(/datum/species/golem)
	armor = ARMOR_VALUE_CLOTHES
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1)
	body_parts_hidden = CHEST | ARMS
	toggled_hidden_parts = ARMS

/obj/item/clothing/suit/toggle/labcoat/cmo
	name = "chief medical officer's labcoat"
	desc = "Bluer than the standard model."
	icon_state = "labcoat_cmo"
	item_state = "labcoat_cmo"
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T2)

/obj/item/clothing/suit/toggle/labcoat/mad
	name = "\proper The Mad's labcoat"
	desc = "It makes you look capable of konking someone on the noggin and shooting them into space."
	icon_state = "labgreen"
	item_state = "labgreen"

/obj/item/clothing/suit/toggle/labcoat/genetics
	name = "geneticist labcoat"
	desc = "A suit that protects against minor chemical spills. Has a blue stripe on the shoulder."
	icon_state = "labcoat_gen"

/obj/item/clothing/suit/toggle/labcoat/chemist
	name = "chemist labcoat"
	desc = " A suit that protects against minor chemical spills. Has an orange stripe on the shoulder."
	icon_state = "labcoat_chem"
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T2)

/obj/item/clothing/suit/toggle/labcoat/virologist
	name = "virologist labcoat"
	desc = "A suit that protects against minor chemical spills. Offers slightly more protection against biohazards than the standard model. Has a green stripe on the shoulder."
	icon_state = "labcoat_vir"
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T2)

/obj/item/clothing/suit/toggle/labcoat/science
	name = "scientist labcoat"
	desc = "A suit that protects against minor chemical spills. Has a purple stripe on the shoulder."
	icon_state = "labcoat_tox"
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T2)

// Departmental Jackets

/obj/item/clothing/suit/toggle/labcoat/depjacket/sci
	name = "science jacket"
	desc = "A comfortable jacket in science purple."
	icon_state = "sci_dep_jacket"
	item_state = "sci_dep_jacket"
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T2)

/obj/item/clothing/suit/toggle/labcoat/depjacket/med
	name = "medical jacket"
	desc = "A comfortable jacket in medical blue."
	icon_state = "med_dep_jacket"
	item_state = "med_dep_jacket"

/obj/item/clothing/suit/toggle/labcoat/depjacket/sec
	name = "security jacket"
	desc = "A comfortable jacket in security red."
	icon_state = "sec_dep_jacket"
	item_state = "sec_dep_jacket"
	armor_tokens = list(ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/toggle/labcoat/depjacket/sup
	name = "supply jacket"
	desc = "A comfortable jacket in supply brown."
	icon_state = "supply_dep_jacket"
	item_state = "supply_dep_jacket"

/obj/item/clothing/suit/toggle/labcoat/depjacket/sup/qm
	name = "quartermaster's jacket"
	desc = "A loose covering often warn by station quartermasters."
	icon_state = "qmjacket"
	item_state = "qmjacket"

/obj/item/clothing/suit/toggle/labcoat/depjacket/eng
	name = "engineering jacket"
	desc = "A comfortable jacket in engineering yellow."
	icon_state = "engi_dep_jacket"
	item_state = "engi_dep_jacket"

/obj/item/clothing/suit/toggle/labcoat/fieldscribe
	name = "fieldscribe suit"
	desc = "A heavy-duty coat and chestrig fitted with tons of pockets. Ballistic weave and ceramic inserts are included to substantially increase Field Scribe survival rates."
	icon_state = "fieldscribe"
	mutantrace_variation = STYLE_DIGITIGRADE

/obj/item/clothing/suit/toggle/labcoat/scribecoat
	name = "fieldscribe coat"
	desc = "A heavy-duty coat and chestrig fitted with tons of pockets. Ballistic weave and ceramic inserts are included to substantially increase Field Scribe survival rates."
	icon_state = "scribecoat"
	mutantrace_variation = STYLE_DIGITIGRADE

/obj/item/clothing/suit/toggle/labcoat/emergency
	name = "first responder jacket"
	desc = "A high-visibility jacket worn by medical first responders."
	icon_state = "fr_jacket"
	item_state = "fr_jacket"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/toggle/labcoat/warriors
	name = "warriors jacket"
	desc = "A red leather jacket, with the word \"Warriors\" sewn above the white wings on the back."
	icon_state = "warriors"
	item_state = "owl"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/toggle/labcoat/wanderer
	name = "wanderer jacket"
	desc = "A zipped-up hoodie made of tanned leather."
	icon_state = "wanderer"
	item_state = "owl"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/toggle/labcoat/followers
	name = "clinic lab coat"
	desc = "A worn-down white labcoat with some wiring hanging from the right side.<br>Upon closer inspection, you can see an ancient bloodstains that could tell an entire story about thrilling adventures of a previous owner."
	icon_state = "followers"
	item_state = "labcoat"

//these are jackets too
/obj/item/clothing/suit/hooded/parka/medical
	name = "armored medical parka"
	icon_state = "armormedical"
	desc = "A staunch, practical parka made out of a wind-breaking jacket, reinforced with metal plates."
	hoodtype = /obj/item/clothing/head/hooded/parkahood/medical
	body_parts_hidden = CHEST | ARMS
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/head/hooded/parkahood/medical
	name = "armored medical parka hood"
	icon_state = "armorhoodmedical"
	desc = " A protective & concealing parka hood."
	flags_inv = HIDEEARS|HIDEEYES|HIDEHAIR|HIDEFACIALHAIR

/obj/item/clothing/suit/hooded/parka/grey
	name = "grey armored parka"
	desc = "A staunch, practical parka made out of a wind-breaking jacket, reinforced with metal plates."
	icon_state = "armorgrey"
	hoodtype = /obj/item/clothing/head/hooded/parkahood/grey
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/head/hooded/parkahood/grey
	name = "armored grey parka hood"
	desc = "A protective & concealing parka hood."
	icon_state = "armorhoodgrey"
	flags_inv = HIDEEARS|HIDEEYES|HIDEHAIR|HIDEFACIALHAIR

/////////////////
//// COSTUME ////
/////////////////

/obj/item/clothing/suit/armor/outfit/costume/ghost
	name = "ghost sheet"
	desc = "The hands float by themselves, so it's extra spooky."
	icon_state = "ghost_sheet"
	item_state = "ghost_sheet"
	throwforce = 0
	throw_speed = 1
	throw_range = 2
	w_class = WEIGHT_CLASS_TINY
	flags_inv = HIDEGLOVES|HIDEEARS|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR

/obj/item/clothing/suit/armor/outfit/slavelabor
	name = "old leather strips"
	desc = "Worn leather strips, used as makeshift protection from chafing and sharp stones by labor slaves."
	icon = 'icons/fallout/clothing/suits_utility.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/suit_utility.dmi'
	icon_state = "legion_slaveleather"
	item_state = "legion_slaveleather"
	body_parts_hidden = 0

///////////
// LIGHT //
///////////

/* Stats
 * No slowdown, mobility key
 * 10% DR for general armor
 * 15-20% for specialist armor (most everything else is butt)
 * Assuming 25 damage from the average attack:
 * - goes from 4 hit crit to 5 at 25
 * - 5 hit crit to 6 at 20 dmg
 * - 4 hit crit to 5 at 30 for specialists maybe???
 *
 * Types:
 * Tribal
 * Duster
 * Raider
 * leather (special, ++melee , --bullet, --laser)
 * light ballistic vest (special, ++bullet , --melee, --laser, chest only)
 * metal breastplate (special, ++laser , +melee, --bullet, chest only)
 */

//// LIGHT ARMOR PARENT ////
/obj/item/clothing/suit/armor/light
	name = "light armor template"
	//icon = 'icons/fallout/clothing/armored_light.dmi'
	//mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	cold_protection = CHEST|GROIN
	heat_protection = CHEST|GROIN
	min_cold_protection_temperature = ARMOR_MIN_TEMP_PROTECT
	max_heat_protection_temperature = ARMOR_MAX_TEMP_PROTECT
	strip_delay = 10
	equip_delay_other = 10
	max_integrity = 100
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/armor
	slowdown = ARMOR_SLOWDOWN_LIGHT * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_LIGHT
	armor_tier_desc = ARMOR_CLOTHING_LIGHT
	stiffness = LIGHT_STIFFNESS

////////////////////////
// LIGHT TRIBAL ARMOR //
////////////////////////
/obj/item/clothing/suit/armor/light/tribal
	name = "tribal armor"
	desc = "A set of armor made of gecko hides.<br>It's pretty good for makeshift armor."
	icon_state = "tribal"
	item_state = "tribal"
//	flags_inv = HIDEJUMPSUIT
	//icon = 'icons/fallout/clothing/armored_light.dmi'
	//mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	cold_protection = CHEST|GROIN|ARMS|LEGS // worm
	heat_protection = CHEST|GROIN|ARMS|LEGS // chyll
	min_cold_protection_temperature = ARMOR_MIN_TEMP_PROTECT
	max_heat_protection_temperature = ARMOR_MAX_TEMP_PROTECT
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_DOWN_ENV_T1)

/obj/item/clothing/suit/armor/light/tribal/wastetribe
	name = "wasteland tribe armor"
	desc = "Soft armor made from layered dog hide strips glued together, with some metal bits here and there."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "tribal"
	item_state = "tribal"
	body_parts_hidden = GROIN|ARMS|LEGS
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T1)

/obj/item/clothing/suit/armor/light/tribal/cloak
	name = "light tribal cloak"
	desc = "A light cloak made from gecko skins and small metal plates at vital areas to give some protection, a favorite amongst scouts of the tribe."
	icon_state = "lightcloak"
	item_state = "lightcloak"
	body_parts_hidden = CHEST|ARMS|LEGS
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T2)


/obj/item/clothing/suit/armor/light/tribal/simple
	name = "simple tribal armor"
	desc = "Armor made of leather strips and a large, flat piece of turquoise. The wearer is displaying the Wayfinders traditional garb."
	icon_state = "tribal_armor"
	item_state = "tribal_armor"
	body_parts_hidden = CHEST|ARMS|LEGS

/obj/item/clothing/suit/armor/light/tribal/sorrows
	name = "Sorrows armour"
	desc = "A worn ballistic vest from Salt Lake, adorned with feathers and turqoise beads, with an ornamental pattern painted over the sides. Commonly worn by the members of the peaceful Sorrows tribe."
	icon_state = "sorrows_armour"
	item_state = "sorrows_armour"
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T1)

/obj/item/clothing/suit/armor/light/tribal/westernwayfarer
	name = "Western Wayfarer salvaged armor"
	desc = "A set of scrap and banded metal armor forged by the Wayfarer tribe, due to it's lightweight and unrestrictive nature,  it's used by scouts and agile hunters. A torn cloak hangs around its neck, protecting the user from the harsh desert sands."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "western_wayfarer_armor"
	item_state = "western_wayfarer_armor"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/tribal/bone
	name = "Bone armor"
	desc = "A tribal armor plate, crafted from animal bone."
	icon_state = "bone_dancer_armor_light"
	item_state = "bone_dancer_armor_light"
	blood_overlay_type = "armor"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_DOWN_BULLET_T1)

/obj/item/clothing/suit/armor/light/tribal/bone/cool
	name = "bone armor suit"
	desc = "A tribal armor plate, crafted from animal bone."
	icon_state = "bonearmor_light"
	item_state = "bonearmor_light"
	blood_overlay_type = "armor"

/obj/item/clothing/suit/armor/light/tribal/rustwalkers
	name = "Rustwalkers light armor"
	desc = "A chestplate, pauldron and vambrace that bear a distinct resemblance to a coolant tank, engine valves and an exhaust. Commonly worn by members of the Rustwalkers tribe"
	icon_state = "rustwalkers_armour_light"
	item_state = "rustwalkers_armour_light"
	body_parts_hidden = ARMS

/obj/item/clothing/suit/armor/light/tribal/whitelegs
	name = "White Legs light armour"
	desc = "A series of tan and khaki armour plates, held in place with a considerable amount of strapping. Commonly worn by members of the White Legs tribe."
	icon_state = "white_legs_armour_light"
	item_state = "white_legs_armour_light"
	body_parts_hidden = ARMS
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/tribal/eighties
	name = "80s light armour"
	desc = "A plain, slightly cropped leather jacket with a black lining and neck brace, paired with a set of metal vambraces and a black belt of pouches. Commonly worn by the members of the 80s tribe."
	icon_state = "80s_armour_light"
	item_state = "80s_armour_light"
	body_parts_hidden = ARMS

/obj/item/clothing/suit/armor/light/tribal/deadhorses
	name = "Dead Horses light armour"
	desc = "A simple leather bandolier and gecko hide chest covering, with an engraved metal pauldron and a pair of black leather straps. Commonly worn by the members of the Dead Horses tribe."
	icon_state = "dead_horses_armour_light"
	item_state = "dead_horses_armour_light"
	body_parts_hidden = 0

/obj/item/clothing/suit/armor/light/tribal/geckocloak
	name = "light tribal cloak"
	desc = "Light cloak armor, made of gecko skins and minor metal plating to protect against light weaponry, a favorite amongst scouts of the tribe."
	icon_state = "lightcloak"
	item_state = "lightcloak"
	body_parts_hidden = ARMS
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_DOWN_LASER_T2, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/light/tribal/strips
	name = "light tribal armor"
	desc = "Light armor made of leather stips and a large, flat piece of turquoise. Armor commonplace among the Wayfinders."
	icon_state = "tribal_armor"
	item_state = "tribal_armor"
	body_parts_hidden = CHEST
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

/// to be refactored to work with the New Tier System (tm)
/obj/item/clothing/suit/hooded/cloak
	name = "cloak"
	desc = "A cloak, made out of cloak."
	icon_state = "clawsuitcloak"
	hoodtype = /obj/item/clothing/head/hooded/cloakhood/goliath
	// body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	cold_protection = CHEST|GROIN|ARMS|LEGS
	heat_protection = CHEST|GROIN|ARMS|LEGS
	min_cold_protection_temperature = ARMOR_MIN_TEMP_PROTECT
	max_heat_protection_temperature = ARMOR_MAX_TEMP_PROTECT
	strip_delay = 10
	equip_delay_other = 10
	max_integrity = 100
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/armor
	body_parts_hidden = 0
	slowdown = ARMOR_SLOWDOWN_LIGHT * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_LIGHT
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/hooded/cloak/Initialize()
	/// make sure the parents work first for this, child lists take priority
	. = ..()
	/// i hate my extended family
	allowed = GLOB.default_all_armor_slot_allowed

/obj/item/clothing/suit/hooded/cloak/goliath
	name = "deathclaw cloak"
	desc = "A staunch, practical cloak made out of sinew and skin from the fearsome deathclaw."
	icon_state = "clawsuitcloak"
	hoodtype = /obj/item/clothing/head/hooded/cloakhood/goliath
	// body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_MEDIUM
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_DT_T2)

/obj/item/clothing/head/hooded/cloakhood/goliath
	name = "deathclaw cloak hood"
	desc = "A protective & concealing hood."
	icon_state = "clawheadcloak"
	flags_inv = HIDEEARS|HIDEEYES|HIDEHAIR|HIDEFACIALHAIR
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_MEDIUM
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_DT_T2)

/obj/item/clothing/suit/hooded/cloak/goliath/tatteredred
	name = "tattered red cloak"
	desc = "An old ragged, tattered red cloak that is covered in burns and bullet holes."
	icon_state = "goliath_cloak"
	hoodtype = /obj/item/clothing/head/hooded/cloakhood/goliath/tattered
	// body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_MEDIUM
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1)

/obj/item/clothing/head/hooded/cloakhood/goliath/tattered
	name = "tattered red cloak hood"
	desc = "A tattered hood, better than nothing in the waste."
	icon_state = "golhood"
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_MEDIUM
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1)

/obj/item/clothing/suit/hooded/cloak/drake //SS13 item, obviously
	name = "drake armour"
	desc = "A suit of armour fashioned from the remains of an ash drake."
	icon_state = "dragon"
	hoodtype = /obj/item/clothing/head/hooded/cloakhood/drake
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	// body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | ACID_PROOF
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_MEDIUM
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_DT_T2)

/obj/item/clothing/head/hooded/cloakhood/drake
	name = "drake helm"
	desc = "The skull of a dragon."
	icon_state = "dragon"
	heat_protection = HEAD
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF | ACID_PROOF
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_MEDIUM
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_DT_T2)

/obj/item/clothing/suit/hooded/cloak/hhunter
	name = "Razorclaw armour"
	desc = "A suit of armour fashioned out of the remains of a legendary deathclaw."
	icon_state = "rcarmour"
	hoodtype = /obj/item/clothing/head/hooded/cloakhood/hhunter
	heat_protection = CHEST|GROIN|LEGS|ARMS|HANDS
	// body_parts_covered = CHEST|GROIN|LEGS|ARMS|HANDS
	resistance_flags = FIRE_PROOF | ACID_PROOF
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_MEDIUM
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_DOWN_LASER_T2, ARMOR_MODIFIER_UP_DT_T2)
	body_parts_hidden = 0

/obj/item/clothing/head/hooded/cloakhood/hhunter
	name = "Razorclaw helm"
	desc = "The skull of a legendary deathclaw."
	icon_state = "rchelmet"
	heat_protection = HEAD
	resistance_flags = FIRE_PROOF | ACID_PROOF
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_MEDIUM
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_DOWN_LASER_T2, ARMOR_MODIFIER_UP_DT_T2)

/obj/item/clothing/suit/hooded/cloak/shunter
	name = "quickclaw armour"
	desc = "A suit of armour fashioned out of the remains of a legendary deathclaw, this one has been crafted to remove a good portion of its protection to improve on speed and trekking."
	icon_state = "birdarmor"
	hoodtype = /obj/item/clothing/head/hooded/cloakhood/shunter
	heat_protection = CHEST|GROIN|LEGS|ARMS|HANDS
	// body_parts_covered = CHEST|GROIN|LEGS|ARMS|HANDS
	resistance_flags = FIRE_PROOF | ACID_PROOF
	slowdown = ARMOR_SLOWDOWN_LIGHT * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_LIGHT
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_DOWN_LASER_T2, ARMOR_MODIFIER_UP_DT_T2)
	body_parts_hidden = 0

/obj/item/clothing/head/hooded/cloakhood/shunter
	name = "quickclaw hood"
	desc = "A hood made of deathclaw hides, light while also being comfortable to wear, designed for speed."
	icon_state = "birdhood"
	heat_protection = HEAD
	resistance_flags = FIRE_PROOF | ACID_PROOF
	slowdown = ARMOR_SLOWDOWN_LIGHT * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_LIGHT
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_DOWN_LASER_T2, ARMOR_MODIFIER_UP_DT_T2)

/obj/item/clothing/suit/hooded/cloak/deathclaw
	name = "deathclaw cloak"
	icon_state = "deathclaw"
	desc = "Made from the sinew and skin of the fearsome deathclaw, this cloak will shield its wearer from harm."
	hoodtype = /obj/item/clothing/head/hooded/cloakhood/deathclaw
	// body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_MEDIUM
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_UP_DT_T2)
	body_parts_hidden = 0

/obj/item/clothing/head/hooded/cloakhood/deathclaw
	name = "deathclaw cloak hood"
	icon_state = "hood_deathclaw"
	desc = "A protective and concealing hood."
	flags_inv = HIDEEARS|HIDEEYES|HIDEHAIR|HIDEFACIALHAIR
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_MEDIUM
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_UP_DT_T2)

/obj/item/clothing/suit/hooded/cloak/razorclaw
	name = "razorclaw cloak"
	icon_state = "rcarmor"
	desc = "A suit of armour fashioned out of the remains of a legendary deathclaw."
	hoodtype = /obj/item/clothing/head/hooded/cloakhood/razorclaw
	heat_protection = CHEST|GROIN|LEGS|ARMS|HANDS
	// body_parts_covered = CHEST|GROIN|LEGS|ARMS|HANDS
	resistance_flags = FIRE_PROOF | ACID_PROOF
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_MEDIUM
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_UP_DT_T2)
	body_parts_hidden = 0

/obj/item/clothing/head/hooded/cloakhood/razorclaw
	name = "razorclaw helm"
	icon_state = "helmet_razorclaw"
	desc = "The skull of a legendary deathclaw."
	heat_protection = HEAD
	resistance_flags = FIRE_PROOF | ACID_PROOF
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_MEDIUM
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_UP_DT_T2)

/obj/item/clothing/suit/hooded/cloak/desert
	name = "desert cloak"
	icon_state = "desertcloak"
	desc = "A practical cloak made out of animal hide."
	hoodtype = /obj/item/clothing/head/hooded/cloakhood/desert

/obj/item/clothing/head/hooded/cloakhood/desert
	name = "desert cloak hood"
	icon_state = "desertcloak"
	desc = "A protective and concealing hood."
	flags_inv = HIDEEARS|HIDEEYES|HIDEHAIR|HIDEFACIALHAIR

/obj/item/clothing/suit/hooded/cloak/desert/raven_cloak
	name = "Raven cloak"
	desc = "A huge cloak made out of hundreds of knife-like black bird feathers. It glitters in the light, ranging from blue to dark green and purple."
	icon_state = "raven_cloak"
	item_state = "raven_cloak"
	hoodtype = /obj/item/clothing/head/hooded/cloakhood/desert/raven_hood

/obj/item/clothing/head/hooded/cloakhood/desert/raven_hood
	name = "Raven cloak hood"
	desc = "A hood fashioned out of patchwork and feathers"
	icon_state = "raven_hood"
	item_state = "raven_hood"

/obj/item/clothing/suit/hooded/outcast
	name = "patched heavy leather cloak"
	desc = "A robust cloak made from layered gecko skin patched with various bits of leather from dogs and other animals, able to absorb more force than one would expect from leather."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "cloak_outcast"
	item_state = "cloak_outcast"
	hoodtype = /obj/item/clothing/head/hooded/cloakhood/outcast
	// body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	slowdown = ARMOR_SLOWDOWN_LIGHT * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_LIGHT
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_DT_T1)
	body_parts_hidden = 0

/obj/item/clothing/head/hooded/cloakhood/outcast
	name = "patched leather hood"
	desc = "Thick layered leather, patched together."
	icon = 'icons/fallout/clothing/hats.dmi'
	icon_state = "hood_tribaloutcast"
	mob_overlay_icon = 'icons/fallout/onmob/clothes/head.dmi'
	item_state = "hood_tribaloutcast"
	flags_inv = HIDEEARS|HIDEEYES|HIDEHAIR|HIDEFACIALHAIR
	slowdown = ARMOR_SLOWDOWN_LIGHT * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_LIGHT
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/hooded/outcast/tribal
	name = "patched heavy leather cloak"
	desc = "A robust cloak made from layered gecko skin patched with various bits of leather from dogs and other animals, able to absorb more force than one would expect from leather."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	icon_state = "cloak_outcast"
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	item_state = "cloak_outcast"
	strip_delay = 40
	hoodtype = /obj/item/clothing/head/hooded/cloakhood/tribaloutcast
	// body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	slowdown = ARMOR_SLOWDOWN_LIGHT * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_LIGHT
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_DT_T1)
	body_parts_hidden = 0

/obj/item/clothing/head/hooded/cloakhood/tribaloutcast
	name = "patched leather hood"
	desc = "Thick layered leather, patched together."
	icon = 'icons/fallout/clothing/hats.dmi'
	icon_state = "hood_tribaloutcast"
	mob_overlay_icon = 'icons/fallout/onmob/clothes/head.dmi'
	item_state = "hood_tribaloutcast"
	flags_inv = HIDEEARS|HIDEEYES|HIDEHAIR|HIDEFACIALHAIR
	slowdown = ARMOR_SLOWDOWN_LIGHT * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_LIGHT
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_DT_T1)

//////////////////
// LIGHT RAIDER //
//////////////////
// more style and pockets, less protection

/obj/item/clothing/suit/armor/light/raider
	cold_protection = CHEST|GROIN
	heat_protection = CHEST|GROIN
	min_cold_protection_temperature = ARMOR_MIN_TEMP_PROTECT
	max_heat_protection_temperature = ARMOR_MAX_TEMP_PROTECT
	strip_delay = 10
	equip_delay_other = 10
	max_integrity = 150
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/jacket
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1)

/obj/item/clothing/suit/armor/light/raider/badlands
	name = "badlands raider armor"
	desc = "A leather top with a bandolier over it and a straps that cover the arms. Suited for warm climates, comes with storage space."
	icon_state = "badlands"
	item_state = "badlands"
	body_parts_hidden = ARMS
	armor_tokens = list(ARMOR_MODIFIER_UP_LASER_T1)

/obj/item/clothing/suit/armor/light/raider/tribalraider
	name = "tribal raider wear"
	desc = "Very worn bits of clothing and armor in a style favored by many tribes."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "tribal_outcast"
	item_state = "tribal_outcast"
	body_parts_hidden = ARMS | GROIN
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1)

/obj/item/clothing/suit/armor/light/raider/supafly
	name = "supa-fly raider armor"
	desc = "Fabulous mutant powers were revealed to me the day I held aloft my bumper sword and said...<br>BY THE POWER OF NUKA-COLA, I AM RAIDER MAN!"
	icon_state = "supafly"
	item_state = "supafly"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)


/obj/item/clothing/suit/armor/light/raider/sadist
	name = "sadist raider armor"
	desc = "A bunch of metal chaps adorned with severed hands at the waist with a leather plate worn on the left shoulder. Very intimidating."
	icon_state = "sadist"
	item_state = "sadist"
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_DOWN_LASER_T1)

/obj/item/clothing/suit/armor/light/raider/painspike
	name = "painspike raider armor"
	desc = "A particularly unhuggable armor, even by raider standards. Extremely spiky."
	icon_state = "painspike"
	item_state = "painspike"


/////////////////////
// DUSTERS & COATS //
/////////////////////

/obj/item/clothing/suit/armor/light/duster
	name = "duster"
	desc = "A long brown leather overcoat with discrete protective reinforcements sewn into the lining."
	icon_state = "duster"
	item_state = "duster"
	permeability_coefficient = 0.5
	heat_protection = CHEST|GROIN|ARMS|LEGS
	cold_protection = CHEST|GROIN|ARMS|LEGS
	min_cold_protection_temperature = ARMOR_MIN_TEMP_PROTECT
	max_heat_protection_temperature = ARMOR_MAX_TEMP_PROTECT
	strip_delay = 20
	equip_delay_other = 20
	max_integrity = 150
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/duster
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T2)
	// Nothing extra fancy for their storage, but they can carry an extra 2 normal-sized guns in their pockets
	body_parts_hidden = CHEST|ARMS

/obj/item/clothing/suit/armor/harpercoat
	name = "outlaw coat"
	desc = "An ugly looking combat duster"
	icon_state = "harperduster"
	item_state = "combatduster"
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/duster/armored
	armor = ARMOR_VALUE_LIGHT
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/light/duster/lonesome
	name = "lonesome duster"
	desc = "A blue leather coat with the number 21 on the back.<br><i>If war doesn't change, men must change, and so must their symbols.</i><br><i>Even if there is nothing at all, know what you follow.</i>"
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "duster_courier"
	item_state = "duster_courier"
	body_parts_hidden = ARMS

/obj/item/clothing/suit/armor/light/duster/autumn //Based of Colonel Autumn's uniform.
	name = "tan trenchcoat"
	desc = "A heavy-duty tan trenchcoat typically worn by pre-War generals."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "duster_autumn"
	item_state = "duster_autumn"

/obj/item/clothing/suit/armor/light/duster/vet
	name = "merc veteran coat"
	desc = "A blue leather coat with its sleeves cut off, adorned with war medals.<br>This type of outfit is common for professional mercenaries and bounty hunters."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "duster_vet"
	item_state = "duster_vet"
	body_parts_hidden = CHEST

/obj/item/clothing/suit/armor/light/duster/brahmin
	name = "brahmin leather duster"
	desc = "A duster made from tanned brahmin hide. It has a thick waxy surface from the processing, making it surprisingly laser resistant."
	icon_state = "duster"
	item_state = "duster"
	body_parts_hidden = ARMS

/obj/item/clothing/suit/armor/light/duster/brahmin/biker
	name = "sleeveless brahmin leather duster"
	desc = "A duster made from tanned brahmin hide. Seems to be missing its arms. Seems like it was on purpose.."
	icon_state = "brahmin_leather_duster_sleeveless"
	item_state = "duster"
	body_parts_hidden = 0

/* 	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "duster_brahmin"
	item_state = "duster_brahmin" */

/obj/item/clothing/suit/armor/light/duster/desperado
	name = "desperado's duster"
	desc = "A dyed brahmin hide duster, with a thick waxy surface, making it less vulnerable to lasers and energy based weapons."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "duster_lawman"
	item_state = "duster_lawman"
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_DT_T1)
	body_parts_hidden = ARMS

/obj/item/clothing/suit/armor/light/duster/town
	name = "town trenchcoat"
	desc = "A non-descript black trenchcoat."
	icon_state = "towntrench"
	item_state = "hostrench"
	body_parts_hidden = ARMS

/obj/item/clothing/suit/armor/light/duster/town/mayor
	name = "mayor trenchcoat"
	desc = "A symbol of the mayor's authority (or lack thereof)."

/obj/item/clothing/suit/armor/light/duster/rustedcowboy
	name = "rusted cowboy outfit"
	desc = "A weather treated leather cowboy outfit. Yeehaw Pard'!"
	icon_state = "rusted_cowboy"
	item_state = "rusted_cowboy"
	flags_inv = HIDEJUMPSUIT
	permeability_coefficient = 0.5

/obj/item/clothing/suit/armor/light/duster/vaquero
	name = "vaquero suit"
	desc = "An ornate suit popularized by traders from the south, using tiny metal studs and plenty of silver thread wich serves as decoration and also reflects energy very well, useful when facing the desert sun or a rogue Eyebot."
	icon_state = "vaquero"
	item_state = "vaquero"
	flags_inv = HIDEJUMPSUIT
	heat_protection = CHEST | GROIN | LEGS| ARMS | HEAD
	siemens_coefficient = 1.1
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/light/duster/battlecoat //Maxson's battlecoat from Fallout 4
	name = "battlecoat"
	desc = "A heavy padded leather coat, worn by pre-War bomber pilots in the past and post-War zeppelin pilots in the future."
	icon_state = "maxson_battlecoat"
	item_state = "maxson_battlecoat"
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'

/obj/item/clothing/suit/armor/light/duster/battlecoat/vault
	name = "command coat"
	desc = "A heavy pre-war bomber coat, dyed blue with the number '113' embroidered on the back. Most often worn by leaders, such as the Overseer."
	icon_state = "maxson_battlecoat"
	item_state = "maxson_battlecoat"

/obj/item/clothing/suit/armor/light/duster/battlecoat/vault/overseer
	name = "Overseer's battlecoat"
	desc = "A heavy pre-war bomber coat, dyed blue with the insignia of the Vault-Tec embroidered on the back. This one is worn by the Coalition's Overseer."
	icon_state = "maxson_battlecoat"
	item_state = "maxson_battlecoat"

/obj/item/clothing/suit/armor/light/duster/battlecoat/vault/marshal
	name = "Marhsal's battlecoat"
	desc = "A heavy pre-war bomber coat, dyed blue with the insignia of the Vault-Tec City Coalition embroidered on the back. This one is worn by the Marshals of the Coalition."
	icon_state = "maxson_battlecoat"
	item_state = "maxson_battlecoat"

/obj/item/clothing/suit/armor/light/duster/herbertranger //Armor wise, it's reskinned raider armor.
	name = "weathered desert ranger armor"
	desc = "A set of pre-unification desert ranger armor, made using parts of what was once USMC riot armor. It looks as if it has been worn for decades; the coat has become discoloured from years under the Mojave sun and has multiple tears and bullet holes in its leather. The armor plating itself seems to be in relatively good shape, though it could do with some maintenance."
	body_parts_covered = CHEST|GROIN|LEGS|ARMS
	icon_state = "usmc_riot_gear"
	item_state = "usmc_riot_gear"
	body_parts_hidden = CHEST|ARMS

/obj/item/clothing/suit/armor/light/duster/marlowsuit //Raider armour reskin.
	name = "Marlow gang overcoat"
	desc = "A heavy raw buckskin overcoat littered with aged bullet holes and frays from regular wear-and-tear."
	body_parts_covered = CHEST|GROIN|LEGS|ARMS
	icon_state = "marlowsuit"
	item_state = "marlowsuit"
	strip_delay = 40
	body_parts_hidden = ARMS

/obj/item/clothing/suit/armor/light/duster/marlowsuit/ikesuit
	name = "gunfighter's overcoat"
	desc = "A thick double-breasted red leather overcoat worn through with scattered tears and bullet holes."
	icon_state = "ikesuit"
	item_state = "ikesuit"

/obj/item/clothing/suit/armor/light/duster/marlowsuit/masonsuit
	name = "vagabond's vest"
	desc = "A padded thick red leather vest, coated in stitched pockets and other mends."
	icon_state = "masonsuit"
	item_state = "masonsuit"
	body_parts_hidden = 0

/obj/item/clothing/suit/armor/light/duster/rustedcowboy
	name = "rusted cowboy outfit"
	desc = " A weather treated leather cowboy outfit.  Yeehaw Pard'!"
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "rusted_cowboy"
	item_state = "rusted_cowboy"
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/duster/tan_robe
	name = "tan robe"
	desc = "Only a monk would find this robe nice and comfortable."
	icon_state = "robe_liz"
	item_state = "brownjsuit"

/obj/item/clothing/suit/armor/light/duster/town
	name = "town trenchcoat"
	desc = "A non-descript black trenchcoat."
	icon_state = "towntrench"
	item_state = "hostrench"

/obj/item/clothing/suit/armor/light/duster/robe_hubologist
	name = "hubologist robe"
	desc = "A black robe worn by Adepts of Hubology Studies.<br>Beware - the spirits of the dead are all around us!"
	icon_state = "hubologist"
	item_state = "wcoat"
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEHAIR|HIDEFACIALHAIR

/obj/item/clothing/suit/armor/light/duster/goner
	name = "dev-patched dull trenchcoat"
	desc = "A non-existent dull trenchcoat."
	icon = 'fallout/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'fallout/icons/mob/clothing/suit.dmi'
	anthro_mob_worn_overlay = 'fallout/icons/mob/clothing/suit_digi.dmi'
	icon_state = "goner_suit"
	item_state = "ro_suit"
	// body_parts_covered = CHEST|GROIN|LEGS|ARMS
	mutantrace_variation = STYLE_DIGITIGRADE

/* /obj/item/clothing/suit/armor/light/duster/goner/Initialize()
	. = ..()
	AddComponent(/datum/component/armor_plate) */

/obj/item/clothing/suit/armor/light/duster/goner/red
	name = "red-patched olive trenchcoat"
	desc = "A rather crude looking, olive trenchcoat with red linings and arm patches.<br>Guess war can be boring too."
	icon_state = "goner_suit_r"

/obj/item/clothing/suit/armor/light/duster/goner/green
	name = "green-patched olive trenchcoat"
	desc = "A rather crude looking, olive trenchcoat with green linings and arm patches.<br>Guess war can be boring too."
	icon_state = "goner_suit_g"

/obj/item/clothing/suit/armor/light/duster/goner/blue
	name = "blue-patched olive trenchcoat"
	desc = "A rather crude looking, olive trenchcoat with blue linings and arm patches.<br>Guess war can be boring too."
	icon_state = "goner_suit_b"

/obj/item/clothing/suit/armor/light/duster/goner/yellow
	name = "yellow-patched olive trenchcoat"
	desc = "A rather crude looking, olive trenchcoat with yellow linings and arm patches.<br>Guess war can be boring too."
	icon_state = "goner_suit_y"

/obj/item/clothing/suit/armor/light/duster/russian_coat
	name = "russian battle coat"
	desc = "Used in extremly cold fronts, made out of real bears."
	icon_state = "rus_coat"
	item_state = "rus_coat"
	clothing_flags = THICKMATERIAL
	// body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	cold_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT

/obj/item/clothing/suit/armor/light/duster/bos/scribe
	name = "Brotherhood Scribe's robe"
	desc = "A red cloth robe worn by the Brotherhood of Steel Scribes."
	icon_state = "scribe"
	item_state = "scribe"
	armor_tokens = list(ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/light/duster/bos/scribe/headscribe
	name = "brotherhood head scribe robe"
	desc = " A red cloth robe with gold trimmings, worn eclusively by the Head Scribe of a chapter."
	icon_state = "headscribe"
	item_state = "headscribe"
	armor_tokens = list(ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/light/duster/bos/scribe/seniorscribe
	name = "Brotherhood Senior Scribe's robe"
	desc = "A red cloth robe with silver gildings worn by the Brotherhood of Steel Senior Scribes."
	icon_state = "seniorscribe"
	item_state = "seniorscribe"
	armor_tokens = list(ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/light/duster/bos/scribe/elder
	name = "Brotherhood Elder's robe"
	desc = "A blue cloth robe with some scarlet red parts, traditionally worn by the Brotherhood of Steel Elder."
	icon_state = "elder"
	item_state = "elder"
	armor_tokens = list(ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/light/duster/bos/outcast
	name = "outcast's breastplate"
	desc = "A generic light piece of armor for the Southern Brotherhood Outcasts. In their hasty retreat, there was little time to delegate supplies; and so, a frock of kevlar, polypropylene, and alloy was woven. Obviously, does not protect your arms or legs- but it does its job fine, otherwise."
	icon_state = "brotherhood_armor_light"
	item_state = "brotherhood_armor_light"
	body_parts_covered = CHEST|GROIN
	armor_tokens = list(ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/light/duster/town
	name = "town trenchcoat"
	desc = "A non-descript black trenchcoat."
	icon_state = "towntrench"
	item_state = "hostrench"

/obj/item/clothing/suit/armor/light/duster/bomberjacket
	name = "armored bomber jacket"
	desc = "It looks like someone dragged this out of a muddy lake. This one has metal plates attached..."
	icon_state = "bomberalt"
	item_state = "bomberalt"
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/duster/armored
	armor = ARMOR_VALUE_LIGHT
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/light/duster/armoredformalcoat
	name = "armored formal overcoat"
	desc = "A neat black overcoat that's only slightly weathered from a nuclear apocalypse. This one has armor plating..."
	icon_state = "black_oversuit"
	item_state = "banker"
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/duster/armored
	armor = ARMOR_VALUE_LIGHT
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_DT_T1)

///////////////////
// LEATHER ARMOR //
///////////////////

/obj/item/clothing/suit/armor/light/leather
	name = "leather armor"
	desc = "Before the war motorcycle-football was one of the largest specator sports in America. This armor copies the style of armor used by the players,	using leather boiled in corn oil to make hard sheets to emulate the light weight and toughness of the original polymer armor."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "leather_armor"
	item_state = "leather_armor"
	permeability_coefficient = 0.9
	heat_protection = CHEST|GROIN|ARMS|LEGS
	cold_protection = CHEST|GROIN|ARMS|LEGS
	min_cold_protection_temperature = ARMOR_MIN_TEMP_PROTECT
	max_heat_protection_temperature = ARMOR_MAX_TEMP_PROTECT
	strip_delay = 20
	equip_delay_other = 20
	max_integrity = 150
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/armor
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_DOWN_BULLET_T1, ARMOR_MODIFIER_UP_DT_T2)
	body_parts_hidden = ARMS | CHEST

// Recipe the above + 2 gecko hides
/obj/item/clothing/suit/armor/light/leather/leathermk2
	name = "leather armor mk II"
	desc = "Armor in the motorcycle-football style, either with intact original polymer plating, or reinforced with gecko hide."
	icon_state = "leather_armor_mk2"
	item_state = "leather_armor_mk2"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_DOWN_FIRE_T2, ARMOR_MODIFIER_UP_DT_T3)

/obj/item/clothing/suit/armor/light/leather/leathersuit
	name = "leather suit"
	desc = "Comfortable suit of tanned leather leaving one arm mostly bare. Keeps you warm and cozy."
	icon_state = "leather_suit"
	item_state = "leather_suit"
	flags_inv = HIDEJUMPSUIT
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_DOWN_BULLET_T1, ARMOR_MODIFIER_DOWN_DT_T1)
	cold_protection = CHEST | GROIN | LEGS| ARMS | HEAD
	siemens_coefficient = 0.9
	body_parts_hidden = ARMS | CHEST | GROIN | LEGS

/obj/item/clothing/suit/armor/light/leather/leather_jacket
	name = "bouncer jacket"
	icon_state = "leather_jacket_fighter"
	item_state = "leather_jacket_fighter"
	desc = "A very stylish pre-War black, heavy leather jacket. Not always a good choice to wear this the scorching sun of the desert, and one of the arms has been torn off"
	body_parts_hidden = ARMS | CHEST

/obj/item/clothing/suit/armor/light/leather/leather_jacketmk2
	name = "thick leather jacket"
	desc = "This heavily padded leather jacket is unusual in that it has two sleeves. You'll definitely make a fashion statement whenever, and wherever, you rumble."
	icon_state = "leather_jacket_thick"
	item_state = "leather_jacket_thick"
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_DOWN_LASER_T2, ARMOR_MODIFIER_UP_DT_T2)
	body_parts_hidden = ARMS | CHEST | LEGS

// Recipe : Thick Leather Jacket + Deathclaw Skin
/obj/item/clothing/suit/armor/light/leather/leathercoat
	name = "thick leather coat"
	desc = "Reinforced leather jacket with a overcoat. Well insulated, creaks a lot while moving."
	icon_state = "leather_coat_fighter"
	item_state = "leather_coat_fighter"
	siemens_coefficient = 0.8
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_DOWN_LASER_T2, ARMOR_MODIFIER_DOWN_FIRE_T2, ARMOR_MODIFIER_UP_DT_T3)
	body_parts_hidden = ARMS | CHEST

/obj/item/clothing/suit/armor/light/leather/tanvest
	name = "tanned vest"
	icon_state = "tanleather"
	item_state = "tanleather"
	desc = "Layers of leather glued together to make a stiff vest, crude but gives some protection against wild beasts and knife stabs to the liver."
	armor_tokens = list(ARMOR_MODIFIER_DOWN_BULLET_T2, ARMOR_MODIFIER_DOWN_DT_T1)
	body_parts_hidden = 0

/obj/item/clothing/suit/armor/light/leather/cowboyvest
	name = "cowboy vest"
	icon_state = "cowboybvest"
	item_state = "cowboybvest"
	desc = "Stylish and has discrete lead plates inserted, just in case someone brings a laser to a fistfight."
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T2, ARMOR_MODIFIER_DOWN_DT_T1, ARMOR_MODIFIER_UP_LASER_T1)

/obj/item/clothing/suit/armor/light/leather/durathread
	name = "makeshift vest"
	desc = "A makeshift vest made of heat-resistant fiber."
	icon = 'icons/obj/clothing/suits.dmi'
	mob_overlay_icon = null
	icon_state = "durathread"
	item_state = "durathread"
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/light/leather/rig
	name = "chest gear harness"
	desc = "a handmade tactical rig. The actual rig is made of a black, fiberous cloth, being attached to a dusty desert-colored belt with enough room for four small items."
	icon_state = "r_gear_rig"
	item_state = "r_gear_rig"
	body_parts_hidden = 0
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/jacket
	armor_tokens = list(ARMOR_MODIFIER_DOWN_BULLET_T1, ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_DOWN_DT_T1)

////////////////
// ARMOR KITS //
////////////////

/obj/item/clothing/suit/armor/light/kit
	name = "armor kit"
	desc = "Separate armor parts you can wear over your clothing, giving basic protection against bullets entering some of your organs. Very well ventilated."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "armorkit"
	item_state = "armorkit"
	heat_protection = CHEST | GROIN | LEGS| ARMS | HEAD
	siemens_coefficient = 1.1
	body_parts_hidden = 0
	armor_tokens = list(ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/light/kit/punk
	name = "punk armor kit"
	desc = "A couple of armor parts that can be worn over the clothing for moderate protection against the dangers of wasteland.<br>Do you feel lucky now? Well, do ya, punk?"
	icon_state = "armorkit_punk"
	item_state = "armorkit_punk"
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'

/obj/item/clothing/suit/armor/light/kit/shoulder
	name = "armor kit"
	desc = "A single big metal shoulderplate for the right side, keeping it turned towards the enemy is advisable."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "armorkit_shoulder"
	item_state = "armorkit_shoulder"

/obj/item/clothing/suit/armor/light/kit/plates
	name = "light armor plates"
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	desc = "Well-made metal plates covering your vital organs."
	icon_state = "light_plates"
	body_parts_hidden = CHEST

/* /obj/item/clothing/suit/armor/light/kit/Initialize()
	. = ..()
	AddComponent(/datum/component/armor_plate) */

/obj/item/clothing/suit/armor/light/mutantkit
	name = "oversized armor kit"
	desc = "Bits of armor fitted to a giant harness. Clearly not made for use by humans."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "mutie_armorkit"
	item_state = "mutie_armorkit"
	heat_protection = CHEST | GROIN | LEGS| ARMS | HEAD
	siemens_coefficient = 1.1

///////////////////////////////////////////////////////////////////
//Fenis's Snarmor Compendium of Snaggletoothed Snarting Snarmors//
/////////////////////////////////////////////////////////////////

/obj/item/clothing/suit/armor/light/kit/punk/bronzechestplate
	name = "old bronze chestplate"
	desc = "A bronze chestplate caste after the fall of the old world, it's in okay shape, if a little banged up."
	icon_state = "old_bronze_chestplate"
	item_state = "old_bronze_chestplate"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/kit/punk/leatherarmor
	name = "leather armor"
	desc = "A rough leather chestpiece, hardened to help keep the owies out."
	icon_state = "leather_armor"
	item_state = "leather_armor"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'

/obj/item/clothing/suit/armor/light/kit/punk/ironchestplate
	name = "iron chestplate"
	desc = "An iron breastplate made after the fall of the old world, its only a little rusted on the inside."
	icon_state = "iron_chestplate"
	item_state = "iron_chestplate"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/kit/punk/scaledarmor
	name = "scaled armor"
	desc = "Overlapping scaled armor made by a smith after the fall of the old world."
	icon_state = "scaled_armor"
	item_state = "scaled_armor"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/kit/punk/roughchainmail
	name = "rough chainmail"
	desc = "A roughly made, but workable, set of chainmail"
	icon_state = "early_chainmail"
	item_state = "early_chainmail"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/kit/punk/fullchainmail
	name = "chainmail shirt"
	desc = "A solidly made bit of chainmail in the shape of a shirt, protects the nips but may chafe."
	icon_state = "chainmail"
	item_state = "chainmail"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/kit/punk/ironchestplatered
	name = "iron chestplate with red cape"
	desc = "An iron breastplate made after the fall of the old world, includes a dashing red cape."
	icon_state = "iron_chestplater"
	item_state = "iron_chestplater"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/kit/punk/ironchestplateblue
	name = "iron chestplate with blue cape"
	desc = "An iron breastplate made after the fall of the old world, includes a cool blue cape."
	icon_state = "iron_chestplateb"
	item_state = "iron_chestplateb"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/kit/punk/oldscalemail
	name = "old scale armor"
	desc = "A set of dull scale armor, overlaps just right in all the wrong places."
	icon_state = "old_scale_armor"
	item_state = "old_scale_armor"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/kit/punk/scalemail
	name = "scale armor"
	desc = "A decent set of scale armor made in the last few years by a smith in the wastes."
	icon_state = "scale_armor"
	item_state = "scale_armor"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/kit/punk/varangianarmor
	name = "Lamellar Armor"
	desc = "A decent set of lamellar armor, no need to be byzantine about it."
	icon_state = "varangian_lamellar"
	item_state = "varangian_lamellar"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/kit/punk/egyptianlam
	name = "Dusty Lamellar Armor"
	desc = "You're in denial if you like this armor, but that's okay."
	icon_state = "egyptian_lamellar"
	item_state = "egyptian_lamellar"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/kit/punk/chitinbreastplate
	name = "Fire Ant Breastplate"
	desc = "A tough armor made out of the hide of gigantic fireants, pretty hot to be honest."
	icon_state = "chitin_chestplate"
	item_state = "chitin_chestplate"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/kit/punk/steppeleatherarmor
	name = "Full Leather Armor"
	desc = "Creaking leather armor with shoulder pads and thigh protection. Mongol Tested, Wasteland approved."
	icon_state = "steppe_leather_armor"
	item_state = "steppe_leather_armor"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'

/obj/item/clothing/suit/armor/light/kit/punk/chineselam
	name = "Lamellar Armor with Red Tunic"
	desc = "Your ancestors protect you more thant his armor likely does, but at least it looks nice."
	icon_state = "chinese_lamellar"
	item_state = "chinese_lamellar"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/kit/punk/chinesebreastplate
	name = "Steel Armor with Red Tunic"
	desc = "This steel breastplate and red shirt are quite stylish, if you like being imortalized in a clay statue."
	icon_state = "imperial_chinese"
	item_state = "imperial_chinese"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/kit/punk/woodenbreastplate
	name = "Wooden Breastplate"
	desc = "This is exactly what it would feel like to be a monkey wearing a coconut for armor."
	icon_state = "wooden_chestarmor"
	item_state = "wooden_chestarmor"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'


/obj/item/clothing/suit/armor/light/kit/punk/steelbreastplate
	name = "Unpainted Steel Breastplate"
	desc = "A relatively recently made breastplate, put together by god knows who in this swamp."
	icon_state = "imperial_breastplate"
	item_state = "imperial_breastplate"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

/obj/item/clothing/suit/armor/light/kit/punk/bronzebreastplate
	name = "Bronze Breastplate"
	desc = "Abs not included."
	icon_state = "bronze_chestplate"
	item_state = "bronze_chestplate"
	icon = 'fallout/icons/objects/civ13suitobj.dmi'
	mob_overlay_icon = 'fallout/icons/objects/civ13suitonmob.dmi'
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1)

////////////////
// OTHER //
////////////////

/obj/item/clothing/suit/armor/light/knight
	name = "preacher plate armour"
	desc = "A classic suit of plate armour, highly effective at stopping melee attacks."
	icon = 'icons/obj/clothing/suits.dmi'
	icon_state = "knight_red"
	item_state = "knight_red"
	armor = ARMOR_VALUE_LIGHT
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T3, ARMOR_MODIFIER_DOWN_BULLET_T1, ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_DT_T1)
	body_parts_hidden = ARMS | CHEST

/obj/item/clothing/suit/armor/light/poachervest
	name = "Poachers Vest"
	desc = "A makeshift vest made out of salvaged vault-suits haphazardly stitched together. Comes with a pelt collar, leather bits and a shoulder holster hidden underneath."
	icon = 'icons/fallout/clothing/belts.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/belt.dmi'
	icon_state = "poachervest"
	item_state = "poachervest"
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/magpouch
	armor = ARMOR_VALUE_LIGHT
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/light/kit/punk/labcoat
	name = "lightly armored labcoat"
	desc = "A tattered labocat with a faded silver emblem of  wings, cogwheels and a sword on it's back. It has a couple of armor parts affixed over a leg and the shoulders for moderate protection against the dangers of wasteland."
	icon_state = "armored_labcoat"
	item_state = "armorkit_punk"
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'

/////////////
// MEDIUM  //
/////////////

/*
 * Stats
 * Some slowdown, decent protection
 * 25% DR for general armor - 134% effective HP
 * 30-35% for specialist armor (most everything else is butt)
 * Assuming 25 damage from the average attack:
 * - goes from 4 hit crit to 6 at 25
 * - 5 hit crit to 7 at 20 dmg
 * - 4 hit crit to 6 at 30 dmg
 *
 * Tribal (general, got extra pockets)
 * Raider (general, ammo pouches?)
 * combat armor (Just good, also holds lots of stuff in the armor slot)
 * ballistic vest (++bullet , --melee, --laser)
 * breastplate (--bullet , ++melee, +laser)
 * riot (+++melee , -bullet, --laser, full body)
 */

/obj/item/clothing/suit/armor/medium
	name = "medium armor template"
	//icon = 'icons/fallout/clothing/armored_medium.dmi'
	//mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	slowdown = 0.5
	cold_protection = CHEST|GROIN
	heat_protection = CHEST|GROIN
	min_cold_protection_temperature = ARMOR_MIN_TEMP_PROTECT
	max_heat_protection_temperature = ARMOR_MAX_TEMP_PROTECT
	strip_delay = 30
	equip_delay_other = 50
	max_integrity = 200
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/armor
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_MEDIUM
	armor_tier_desc = ARMOR_CLOTHING_MEDIUM
	clothing_flags = CUSHIONED_ARMOR
	stiffness = MEDIUM_STIFFNESS

////////////////////////////
/// MEDIUM TRIBAL ARMOR ////
////////////////////////////

// big pockets, lighter, melee focus
/obj/item/clothing/suit/armor/medium/tribal
	name = "heavy tribal armor"
	desc = "A thick suit of armor made of brahmin and gecko hides. It seems lighter than one would expect."
	cold_protection = CHEST|GROIN
	heat_protection = CHEST|GROIN
	min_cold_protection_temperature = ARMOR_MIN_TEMP_PROTECT
	max_heat_protection_temperature = ARMOR_MAX_TEMP_PROTECT
	strip_delay = 30
	equip_delay_other = 50
	max_integrity = 200
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/duster
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_LESS_T2 * ARMOR_SLOWDOWN_GLOBAL_MULT // lighter, cus melee focus
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_DOWN_BULLET_T2, ARMOR_MODIFIER_DOWN_LASER_T2, ARMOR_MODIFIER_DOWN_ENV_T1)

/obj/item/clothing/suit/armor/medium/tribal/chitinarmor
	name = "insect chitin armor"
	desc = "A suit made from gleaming insect chitin. The glittering black scales are remarkably resistant to hostile environments, except cold."
	icon = 'icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "insect"
	item_state = "insect"
	flags_inv = HIDEJUMPSUIT
	heat_protection = CHEST | GROIN | LEGS| ARMS | HEAD
	resistance_flags = FIRE_PROOF | ACID_PROOF
	siemens_coefficient = 0.5
	permeability_coefficient = 0.5
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_DOWN_BULLET_T1, ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_UP_DT_T2) // tribal enviro armor

/obj/item/clothing/suit/armor/medium/tribal/rustwalkers
	name = "Rustwalkers armor"
	desc = "A car seat leather duster, a timing belt bandolier, and armour plating made from various parts of a car, it surely would weigh the wearer down. Commonly worn by members of the Rustwalkers tribe."
	icon_state = "rustwalkers_armour"
	item_state = "rustwalkers_armour"
	body_parts_hidden = CHEST
	armor_tokens = list(ARMOR_MODIFIER_DOWN_BULLET_T1, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/medium/tribal/whitelegs
	name = "White Legs armour"
	desc = "A series of tan and khaki armour plates, held in place with a considerable amount of strapping and possibly duct tape. Commonly worn by members of the White Legs tribe."
	icon_state = "white_legs_armour"
	item_state = "white_legs_armour"
	body_parts_hidden = ARMS | LEGS
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/medium/tribal/eighties
	name = "80s armour"
	desc = "A ballistic duster with the number 80 stitched onto the back worn over a breastplate made from a motorcycle's engine housing, with kneepads made from stirrups. Worn by the members of the 80s tribe."
	icon_state = "80s_armour"
	item_state = "80s_armour"
	body_parts_hidden = ARMS | CHEST

/obj/item/clothing/suit/armor/medium/tribal/deadhorses
	name = "Dead Horses armour"
	desc = "A simple leather bandolier and gecko hide chest covering, with an engraved metal pauldron and a set of black leather straps, one holding a shinpad in place. Commonly worn by the members of the Dead Horses tribe."
	icon_state = "dead_horses_armour"
	item_state = "dead_horses_armour"
	body_parts_hidden = 0

/obj/item/clothing/suit/armor/medium/tribal/bone
	name = "Reinforced Bone armor"
	desc = "A tribal armor plate, reinforced with leather and a few metal parts."
	icon_state = "bone_dancer_armor"
	item_state = "bone_dancer_armor"
	blood_overlay_type = "armor"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_DT_T2)

/*/obj/item/clothing/suit/armor/medium/tribal/westernwayfarer
	name = "Western Wayfarer armor"
	desc = "A Suit of armor crafted by Tribals using pieces of scrap metals and the armor of fallen foes, a bighorner's skull sits on the right pauldron along with bighorner fur lining the collar of the leather bound chest. Along the leather straps adoring it are multiple bone charms with odd markings on them."
	icon_state = "western_wayfarer_armor"
	item_state = "western_wayfarer_armor"
	// body_parts_covered = CHEST|GROIN|LEGS|ARMS|HANDS
	*/

/obj/item/clothing/suit/armor/medium/tribal/tribe_heavy_armor
	name = "heavy tribal armor"
	desc = "Heavy armor make of sturdy leather and pieces of bone. Worn by seasoned veterans within the Wayfinder tribe."
	icon = 'icons/fallout/clothing/armored_heavy.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_heavy.dmi'
	icon_state = "tribal_heavy"
	item_state = "tribal_heavy"
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_UP_DT_T3)

////////////////////////////////
//// MEDIUM BALLISTIC VESTS ////
////////////////////////////////

// Bullet resistant, melee vulnerable, light
/obj/item/clothing/suit/armor/medium/vest
	name = "light armor vest"
	desc = "A slim vest made of kevlar. Popular pre-war for their concealability, but popular in the Wasteland for their light weight and ability to stop most pistol rounds. Won't do much against bigger bullets, though."
	icon_state = "armoralt"
	item_state = "armoralt"
	blood_overlay_type = "armor"
	dog_fashion = /datum/dog_fashion/back
	armor_tier_desc = ARMOR_CLOTHING_LIGHT
	mutantrace_variation = STYLE_DIGITIGRADE
	slowdown = ARMOR_SLOWDOWN_LIGHT * ARMOR_SLOWDOWN_LESS_T2 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_LIGHT
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_DT_T1)
	body_parts_hidden = CHEST

/obj/item/clothing/suit/armor/medium/vest/flak
	name = "ancient flak vest"
	desc = "Poorly maintained, this patched vest will still still stop some bullets, but don't expect any miracles. The ballistic nylon used in its construction is inferior to kevlar, and very weak to acid, but still quite tough."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "vest_flak"
	item_state = "vest_flak"
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T1)

/obj/item/clothing/suit/armor/medium/vest/kevlar
	name = "kevlar vest"
	desc = "Worn but serviceable, the vest is is effective against ballistic impacts."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "vest_kevlar"
	item_state = "vest_kevlar"

/obj/item/clothing/suit/armor/medium/vest/bulletproof
	name = "bulletproof vest"
	desc = "This vest is in good shape, the layered kevlar lightweight yet very good at stopping bullets."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "vest_bullet"
	item_state = "vest_bullet"
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_LESS_T1 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T3, ARMOR_MODIFIER_DOWN_MELEE_T2, ARMOR_MODIFIER_DOWN_LASER_T2, ARMOR_MODIFIER_DOWN_ENV_T2, ARMOR_MODIFIER_UP_DT_T2)

/obj/item/clothing/suit/armor/medium/vest/bulletproof/armor
	name = "armored vest"
	desc = "Large bulletproof vest with ballistic plates."
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "vest_armor"
	item_state = "vest_armor"
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_MORE_T2 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T3, ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_DOWN_ENV_T2, ARMOR_MODIFIER_UP_DT_T3)

/obj/item/clothing/suit/armor/medium/vest/bulletproof/big
	name = "security vest"
	desc = "A thick bullet-resistant vest composed of ballistic plates and padding. Common with pre-war security forces."
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "vest_armor"
	item_state = "vest_armor"
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_MORE_T2 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T3, ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_UP_DT_T3)

/obj/item/clothing/suit/armor/medium/vest/followers
	name = "followers armor vest"
	desc = "A coat in light colors with the markings of the Followers, concealing a bullet-proof vest."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "vest_follower"
	item_state = "vest_follower"

/obj/item/clothing/suit/armor/medium/vest/town
	name = "Eastwood flak vest"
	desc = "A refurbished flak vest, repaired by the Eastwood Police Department. The ballistic nylon has a much tougher weave, but it still will not take acid or most high-powered rounds."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "vest_flak"
	item_state = "vest_flak"

/obj/item/clothing/suit/armor/medium/vest/eastwood
	name = "Vault-Sec vest"
	desc = "a lightweight ballistic vest that is commonly worn by Vault-Tec security personnel. This one still has the badge attached."
	icon_state = "blueshift"
	item_state = "blueshift"

/obj/item/clothing/suit/armor/medium/vest/atlantic
	name = "Atlantic Cross guard vest"
	desc = "A prewar vest, used by some private naval security forces on ships, to fight back against pirates of the mediterean seas, following the European and North African crisis of the 2050's to 2070's."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "atlanticguard"
	item_state = "atlanticguard"

/obj/item/clothing/suit/armor/medium/duster/trenchcoat/minutemen
	name = "minutemen coat"
	desc = "An armoured trenchcoat, modified and branded with Minutemen insignias and designs."
	icon = 'fallout/icons/obj/clothing/minutemen.dmi'
	mob_overlay_icon = 'fallout/icons/mob/clothing/minutemen.dmi'
	icon_state = "mm_coat"
	item_state = "mm_coat"
	mutantrace_variation = NONE
	body_parts_covered = CHEST|ARMS|LEGS
	armor_tokens = list(ARMOR_MODIFIER_UP_LASER_T2)

/obj/item/clothing/suit/armor/light/vest/russian
	name = "russian vest"
	desc = "A bulletproof vest with forest camo. Good thing there's plenty of forests to hide in around here, right?"
	icon_state = "rus_armor"
	item_state = "rus_armor"

/obj/item/clothing/suit/armor/medium/vest/chinese
	name = "chinese flak vest"
	desc = "An uncommon suit of pre-war Chinese armor. It's a very basic and straightforward piece of armor that covers the front of the user."
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "vest_chicom"
	item_state = "vest_chicom"

/obj/item/clothing/suit/armor/medium/vest/trench
	name = "followers trenchcoat"
	desc = "A grey and white trench coat with dark blue highlights, on the sides and back it has the unique symbol of the followers. Under said coat is an armor vest, perfect for light weight protection."
	icon_state = "followerstrench"
	item_state = "followerstrench"

/obj/item/clothing/suit/armor/medium/vest/alt
	desc = "A thick armored vest that provides decent protection against most types of damage."
	icon_state = "armor"
	item_state = "armor"

/obj/item/clothing/suit/armor/medium/vest/old
	name = "degrading armor vest"
	desc = "Older generation Type 1 armored vest. It looks like a fixer-upper, but it could still stop a bullet."
	icon_state = "armor"
	item_state = "armor"

/obj/item/clothing/suit/armor/medium/vest/blueshirt
	name = "large armor vest"
	desc = "A large, yet comfortable piece of armor, protecting you from some threats."
	icon_state = "blueshift"
	item_state = "blueshift"
	custom_premium_price = PRICE_ABOVE_EXPENSIVE

/obj/item/clothing/suit/armor/medium/vest/warden
	name = "warden's jacket"
	desc = "A navy-blue armored jacket with blue shoulder designations and '/Warden/' stitched into one of the chest pockets."
	icon_state = "warden_alt"
	item_state = "armor"
	resistance_flags = FLAMMABLE
	dog_fashion = null
	mutantrace_variation = STYLE_DIGITIGRADE

/obj/item/clothing/suit/armor/medium/vest/warden/alt
	name = "warden's armored jacket"
	desc = "A red jacket with silver rank pips and body armor strapped on top."
	icon_state = "warden_jacket"

/obj/item/clothing/suit/armor/medium/vest/warden/navyblue
	name = "warden's jacket"
	desc = "Perfectly suited for the warden that wants to leave an impression of style on those who visit the brig."
	icon_state = "wardenbluejacket"
	item_state = "wardenbluejacket"
	// body_parts_covered = CHEST|ARMS
	mutantrace_variation = STYLE_DIGITIGRADE

/obj/item/clothing/suit/armor/medium/vest/leather
	name = "security overcoat"
	desc = "Lightly armored leather overcoat meant as casual wear for high-ranking officers."
	icon_state = "leathercoat-sec"
	item_state = "hostrench"
	dog_fashion = null

/obj/item/clothing/suit/armor/medium/vest/capcarapace
	name = "captain's carapace"
	desc = "A fireproof armored chestpiece reinforced with ceramic plates and plasteel pauldrons to provide additional protection whilst still offering maximum mobility and flexibility. Issued only to the station's finest, although it does chafe your nipples."
	icon_state = "capcarapace"
	item_state = "armor"
	dog_fashion = null
	resistance_flags = FIRE_PROOF

/obj/item/clothing/suit/armor/medium/vest/capcarapace/syndicate
	name = "syndicate captain's vest"
	desc = "A sinister looking vest of advanced armor worn over a black and red fireproof jacket. The gold collar and shoulders denote that this belongs to a high ranking syndicate officer."
	icon_state = "syndievest"
	mutantrace_variation = STYLE_DIGITIGRADE

/obj/item/clothing/suit/armor/medium/vest/capcarapace/alt
	name = "captain's parade jacket"
	desc = "For when an armoured vest isn't fashionable enough."
	icon_state = "capformal"
	item_state = "capspacesuit"

/obj/item/clothing/suit/armor/medium/vest/det_suit
	name = "detective's armor vest"
	desc = "An armored vest with a detective's badge on it."
	icon_state = "detective-armor"
	resistance_flags = FLAMMABLE
	dog_fashion = null

/obj/item/clothing/suit/armor/medium/vest/infiltrator
	name = "insidious combat vest"
	desc = "An insidious combat vest designed using Syndicate nanofibers to absorb the supreme majority of kinetic blows. Although it doesn't look like it'll do too much for energy impacts."
	icon_state = "infiltrator"
	item_state = "infiltrator"
	resistance_flags = FIRE_PROOF | ACID_PROOF
	strip_delay = 80

/obj/item/clothing/suit/armor/medium/vest/enclave
	name = "armored vest"
	desc = "Efficient prewar design issued to Enclave personell."
	icon_state = "armor_enclave_peacekeeper"
	item_state = "armor_enclave_peacekeeper"
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T3, ARMOR_MODIFIER_DOWN_MELEE_T2, ARMOR_MODIFIER_DOWN_LASER_T2, ARMOR_MODIFIER_DOWN_ENV_T2, ARMOR_MODIFIER_UP_DT_T3)


/////////////////////////////
//// MEDIUM BREASTPLATES ////
/////////////////////////////

// metal breastplates!
// ++Melee, -Bullet, +laser, bit slower
/obj/item/clothing/suit/armor/medium/vest/breastplate
	name = "steel breastplate"
	desc = "a steel breastplate, inspired by a pre-war design. It provides some protection against impacts, cuts, and medium-velocity bullets."
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "steel_bib"
	item_state = "steel_bib"
	slowdown = ARMOR_SLOWDOWN_LIGHT * ARMOR_SLOWDOWN_MORE_T1 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_DOWN_BULLET_T1, ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_DOWN_ENV_T1)

/obj/item/clothing/suit/armor/medium/vest/breastplate/light
	name = "light armor plates"
	desc = "Well-made metal plates covering your vital organs."
	icon = 'icons/fallout/clothing/armored_light.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_light.dmi'
	icon_state = "light_plates"
	item_state = "armorkit"
	armor = ARMOR_VALUE_LIGHT
	armor_tier_desc = ARMOR_CLOTHING_LIGHT
	slowdown = ARMOR_SLOWDOWN_LIGHT * ARMOR_SLOWDOWN_LESS_T1 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_DOWN_BULLET_T2, ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_DOWN_ENV_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/medium/vest/breastplate/eastwood
	name = "Eastwood steel breastplate"
	desc = "a steel breastplate, inspired by a pre-war design. Looks like Eastwood citizens added an additional layer of metal on the front face."
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "steel_bib"
	item_state = "steel_bib"

/obj/item/clothing/suit/armor/medium/vest/breastplate/town
	name = "steel breastplate"
	desc = "A steel breastplate inspired by a pre-war design, this one was made locally in Eastwood. It uses a stronger steel alloy in it's construction, still heavy though"
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'

/obj/item/clothing/suit/armor/medium/vest/breastplate/reinforced
	name = "reinforced steel breastplate"
	desc = "a steel breastplate inspired by a pre-war design. It provides some protection against impacts, cuts, and medium-velocity bullets. It's pressed steel construction feels heavy."
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "steel_bib_rein"
	item_state = "steel_bib_rein"
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_MORE_T1 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_MELEE_T3, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_DOWN_ENV_T1, ARMOR_MODIFIER_UP_DT_T3)

/obj/item/clothing/suit/armor/medium/vest/breastplate/scrap
	name = "scrap metal chestplate"
	desc = "Various metal bits welded together to form a crude chestplate."
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "metal_chestplate"
	item_state = "metal_chestplate"
	siemens_coefficient = 1.3
	armor_tokens = list(ARMOR_MODIFIER_DOWN_BULLET_T1, ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/medium/vest/breastplate/scrap/reinforced
	name = "reinforced metal chestplate"
	desc = "Various metal bits welded together to form a crude chestplate, with extra bits of metal top of the first layer. Heavy."
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "metal_chestplate2"
	item_state = "metal_chestplate2"
	armor_tokens = list(ARMOR_MODIFIER_DOWN_BULLET_T1, ARMOR_MODIFIER_UP_MELEE_T3, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_DOWN_ENV_T1, ARMOR_MODIFIER_UP_DT_T3)

/obj/item/clothing/suit/armor/medium/vest/breastplate/scrap/brokencombat
	name = "broken combat armor chestpiece"
	desc = "It's barely holding together, but the plates might still work, you hope."
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "combat_chestpiece"
	item_state = "combat_chestpiece"
	mutantrace_variation = NONE

/obj/item/clothing/suit/armor/medium/vest/breastplate/scrap/mutant
	name = "mutant armour"
	desc = "Metal plates rigged to fit the frame of a super mutant. Maybe he's the big iron with a ranger on his hip?"
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "mutie_heavy_metal"
	item_state = "mutie_heavy_metal"
	mutantrace_variation = NONE

///////////////////////
//// MEDIUM DUSTER ////
///////////////////////

/obj/item/clothing/suit/armor/medium/duster
	name = "armored greatcoat"
	desc = "A greatcoat enhanced with a special alloy for some extra protection and style for those with a commanding presence."
	icon_state = "hos"
	item_state = "greatcoat"
	// body_parts_covered = CHEST|GROIN|ARMS|LEGS
	cold_protection = CHEST|GROIN|LEGS|ARMS
	heat_protection = CHEST|GROIN|LEGS|ARMS
	strip_delay = 80
	mutantrace_variation = STYLE_DIGITIGRADE
	equip_delay_other = 50
	max_integrity = 200
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/duster/armored
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_LESS_T3 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T2, ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_ENV_T1)

/obj/item/clothing/suit/armor/medium/duster/navyblue
	name = "head of security's jacket"
	desc = "This piece of clothing was specifically designed for asserting superior authority."
	icon_state = "hosbluejacket"
	item_state = "hosbluejacket"

/obj/item/clothing/suit/armor/medium/duster/trenchcoat
	name = "armored trenchcoat"
	desc = "A trenchcoat enhanced with a special lightweight kevlar. The epitome of tactical plainclothes."
	icon_state = "hostrench"
	item_state = "hostrench"
	flags_inv = 0
	unique_reskin = list("Coat" = "hostrench",
						"Cloak" = "trenchcloak")

/obj/item/clothing/suit/armor/medium/duster/armoredcoat
	name = "armored battlecoat"
	desc = "A heavy padded leather coat with faded colors, worn over a armor vest."
	icon_state = "battlecoat_tan"
	item_state = "battlecoat_tan"

/obj/item/clothing/suit/armor/medium/duster/duster_renegade
	name = "renegade duster"
	desc = "Metal armor worn under a stylish duster. For the bad boy who wants to look good while commiting murder."
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "duster-renegade"
	item_state = "duster-renegade"

/obj/item/clothing/suit/armor/medium/duster/town
	name = "deputy trenchcoat"
	desc = "An armored trench coat with added shoulderpads, a chestplate, and leg guards."
	icon_state = "towntrench_medium"
	item_state = "hostrench"

/obj/item/clothing/suit/armor/medium/duster/town/embroidered
	name = "embroidered trenchcoat"
	desc = "A custom armored trench coat with extra-length and a raised collar. There's a flower embroidered onto the back, although the color is a little faded."
	icon_state = "towntrench_special"
	item_state = "towntrench_special"

/obj/item/clothing/suit/armor/medium/duster/town/deputy
	name = "armored town trenchcoat"
	desc = "An armored trench coat with added shoulderpads, a chestplate, and legguards."
	icon_state = "towntrench_medium"

/obj/item/clothing/suit/armor/medium/duster/town/sheriff
	name = "sheriff trenchcoat"
	desc = "A trenchcoat which does a poor job at hiding the full-body combat armor beneath it."
	icon_state = "towntrench_heavy"

/obj/item/clothing/suit/armor/medium/duster/town/sheriff/detsuit
	name = "sheriff duster"
	desc = "A long brown leather overcoat.<br>A powerful accessory of a respectful sheriff, bringer of justice."
	icon_state = "sheriff"
	item_state = "det_suit"

/obj/item/clothing/suit/armor/medium/duster/town/commissioner
	name = "commissioner's jacket"
	desc = "A navy-blue jacket with blue shoulder designations, '/NPD/' stitched into one of the chest pockets, and hidden ceramic trauma plates. It has a small compartment for a holdout pistol."
	icon_state = "warden_alt"
	item_state = "armor"

/obj/item/clothing/suit/armor/medium/duster/town/chief
	name = "NPD Chief's jacket"
	desc = "A navy-blue jacket with blue shoulder designations, '/NPD/' stitched into one of the chest pockets, and hidden ceramic trauma plates. It has a small compartment for a holdout pistol."
	icon = 'icons/fallout/clothing/suits_cosmetic.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/suit_cosmetic.dmi'
	icon_state = "police_chief"
	item_state = "police_chief"

/obj/item/clothing/suit/armor/medium/duster/town/mayor
	name = "mayor trenchcoat"
	desc = "A symbol of the mayor's authority (or lack thereof). It has discrete armor plating in the lining, to foil assassination attempts."

/obj/item/clothing/suit/armor/medium/duster/motorball
	name = "motorball suit"
	desc = "Reproduction motorcycle-football suit, made in vault 75 that was dedicated to a pure sports oriented culture."
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "motorball"
	item_state = "motorball"

/obj/item/clothing/suit/armor/medium/duster/mutant
	name = "mutant poncho"
	desc = "An oversized poncho, made to fit the frame of a super mutant. Maybe he's the big ranger with an iron on his hip?"
	icon_state = "mutie_poncho"
	item_state = "mutie_poncho"

/obj/item/clothing/suit/armor/medium/duster/cloak_armored
	name = "armored cloak"
	desc = "A dark cloak worn over protective plating."
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "cloak_armored"
	item_state = "cloak_armored"

/obj/item/clothing/suit/armor/medium/duster/enclave
	name = "enclave officer trenchcoat"
	desc = "Premium prewar military armor worn under a coat for Enclave officers."
	icon_state = "armor_enclave_officer"
	item_state = "armor_enclave_officer"

/obj/item/clothing/suit/armor/medium/duster/follower
	name = "White duster"
	desc = "An old military-grade pre-war combat armor under a white weathered duster. An emblem is on the back of it. It appears to be fitted with metal plates to replace the crumbling ceramic."
	icon_state = "shank_follower"
	item_state = "shank_follower"

//////////////////////
//// COMBAT ARMOR ////
//////////////////////

/obj/item/clothing/suit/armor/medium/combat
	name = "combat armor"
	desc = "An old military grade pre war combat armor."
	icon_state = "combat_armor"
	item_state = "combat_armor"
	salvage_loot = list(/obj/item/stack/crafting/armor_plate = 5)
	equip_delay_other = 50
	max_integrity = 200
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/magpouch // 4 slots for ammo!
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_LESS_T1 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_DT_T2)
	mutantrace_variation = NONE

/obj/item/clothing/suit/armor/medium/combat/laserproof
	name = "ablative combat armor"
	desc = "An old military grade pre war combat armor. This one switches out its ballistic fibers for an ablative coating that disrupts energy weapons."
	armor_tokens = list(ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_UP_ENV_T1)

/obj/item/clothing/suit/armor/medium/combat/dark
	name = "combat armor"
	desc = "An old military grade pre war combat armor. Now in dark, and extra-crispy!"
	color = "#514E4E"

/obj/item/clothing/suit/armor/medium/combat/Initialize()
	. = ..()
	AddComponent(/datum/component/spraycan_paintable)
	START_PROCESSING(SSobj, src) // Lagg note: No idea what this does

/obj/item/clothing/suit/armor/medium/combat/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/clothing/suit/armor/medium/combat/mk2
	name = "reinforced combat armor"
	desc = "A reinforced set of bracers, greaves, and torso plating of prewar design. This one is kitted with additional plates."
	icon = 'icons/obj/clothing/suits.dmi'
	icon_state = "combat_armor_mk2"
	item_state = "combat_armor_mk2"
	salvage_loot = list(/obj/item/stack/crafting/armor_plate = 8)
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_MORE_T2 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_DOWN_ENV_T1, ARMOR_MODIFIER_UP_DT_T3)

/obj/item/clothing/suit/armor/medium/combat/mk2/dark
	name = "reinforced combat armor"
	desc = "A reinforced model based of the pre-war combat armor. Now in dark, light, and smoky barbeque!"
	color = "#302E2E"

/obj/item/clothing/suit/armor/medium/combat/mk2/remnant
	name = "remnant combat armor"
	desc = "A dark armor, used commonly in espionage or shadow ops."
	icon_state = "remnant"
	item_state = "remnant"

/obj/item/clothing/suit/armor/medium/combat/mk2/desert_ranger
	name = "reinforced desert ranger armor"
	desc = "A suit of armor styled after those used by the Desert Rangers, with extra plates strapped to it to boot."
	icon_state = "ncr_patrol"
	item_state = "ncr_patrol"

/obj/item/clothing/suit/armor/medium/combat/mk2/desert_ranger/pro
	name = "reinforced desert ranger suit"
	desc = "A set of armor styled after those used by the Desert Rangers, with extra plates strapped to it to boot."
	icon_state = "ncr_armor_mk2"
	item_state = "ncr_armor_mk2"

/obj/item/clothing/suit/armor/medium/combat/mk2/raider
	name = "raider combat armor"
	desc = "An old set of reinforced combat armor with some parts supplanted with painspike armor. It seems less protective than a mint-condition set of combat armor. Can probably be used to make a better set, though..."
	item_state = "combat_armor_raider"
	armor_tokens = list(ARMOR_MODIFIER_DOWN_BULLET_T2, ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_DOWN_ENV_T1)

/obj/item/clothing/suit/armor/medium/combat/mk2/tribal
	name = "tribal reinforced combat armor"
	desc = "An old military grade pre-war reinforced combat armor, now decorated with sinew and the bones of the hunted for its new wearer."
	icon_state = "tribecombatarmor"
	item_state = "tribecombatarmor"
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_DOWN_ENV_T1, ARMOR_MODIFIER_UP_DT_T2)

/obj/item/clothing/suit/armor/medium/combat/swat
	name = "SWAT combat armor"
	desc = "A custom version of the pre-war combat armor, slimmed down and minimalist for domestic S.W.A.T. teams."
	icon_state = "armoralt"
	item_state = "armoralt"
	clothing_flags = CUSHIONED_ARMOR
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_LESS_T2 * ARMOR_SLOWDOWN_GLOBAL_MULT

/obj/item/clothing/suit/armor/medium/combat/chinese
	name = "chinese combat armor"
	desc = "(An uncommon suit of pre-war Chinese combat armor. It's a very basic and straightforward piece of armor that covers the front of the user."
	icon_state = "chicom_armor"
	item_state = "chicom_armor"

/obj/item/clothing/suit/armor/medium/combat/atlanticmarines
	name = "Atlantic Cross Marines combat armor"
	desc = "A balistic vest from prewar times, probably used by some marines."
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "atlanticmarine"
	item_state = "atlanticmarine"

/obj/item/clothing/suit/armor/medium/combat/desert_ranger
	name = "desert ranger combat armor"
	desc = "A suit of combat armor styled after those used by the Desert Rangers. It smells like red mist."
	icon_state = "desert_ranger"
	item_state = "desert_ranger"

/obj/item/clothing/suit/armor/medium/combat/desert_ranger/combat
	name = "desert ranger combat suit"
	desc = "A suit of combat armor styled after those used by the Desert Rangers. It smells like red mist."
	icon_state = "ncr_armor"
	item_state = "ncr_armor"

/obj/item/clothing/suit/armor/medium/combat/desert_ranger/scout
	name = "desert ranger scout armor"
	desc = "A refurbished set of desert ranger scout armor, refitted for use in the swamps. A few shiny platinum shards stick out of the webbing."
	icon_state = "refurb_scout"
	item_state = "refurb_scout"

/obj/item/clothing/suit/armor/medium/combat/desert_ranger/officer
	name = "desert ranger officer armor"
	desc = "A suit of desert ranger styled armor, now with a fancy-looking coat to boot. Very official."
	icon_state = "ncr_officer_coat"
	item_state = "ncr_officer_coat"

/obj/item/clothing/suit/armor/medium/combat/desert_ranger/officer/colonel
	name = "NCR colonels armor"
	desc = "A suit of desert ranger styled armor, decorated to look more official. Very, very official."
	icon_state = "ncr_captain_armour"
	item_state = "ncr_captain_armour"

/obj/item/clothing/suit/armor/medium/combat/desert_ranger/outlaw
	name = "desert outlaw armor"
	desc = "A modified detoriated armor kit consisting of Desert Ranger style combat armor and scrap metal."
	icon_state = "ncrexile"
	item_state = "ncrexile"

/obj/item/clothing/suit/armor/medium/combat/desert_ranger/mutant
	name = "NCR mutant armor"
	desc = "Multiple sets of NCR patrol vests that have been fused, stitched and welded together in order to fit the frame of a Super Mutant."
	icon_state = "mutie_ncr"
	item_state = "mutie_ncr"

/obj/item/clothing/suit/armor/medium/combat/desert_ranger/patrol/mutant
	name = "mutant desert ranger armor"
	desc = "Multiple sets of desert ranger patrol armor made to protect a massive humanoid, modified to be light and breezy here in the swamps, and smelling like blood sausage."
	icon_state = "mutie_ranger_armour"
	item_state = "mutie_ranger_armour"

/obj/item/clothing/suit/armor/medium/combat/desert_ranger/patrol/thax
	name = "desert ranger patrol duster"
	desc = "A customized and moderately-worn suit of desert ranger armor. A sun-worn thick olive duster is worn over the armor."
	icon_state = "thaxarmor"
	item_state = "thaxarmor"

/obj/item/clothing/suit/armor/medium/combat/rusted
	name = "rusted combat armor"
	desc = "An old military grade pre war combat armor. This set has seen better days, weathered by time. The composite plates, meant for bullets and lasers, look sound and intact still. Everything else...uh..."
	icon_state = "rusted_combat_armor"
	item_state = "rusted_combat_armor"
	slowdown = 0.6
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T2, ARMOR_MODIFIER_DOWN_ENV_T1, ARMOR_MODIFIER_DOWN_DT_T1)

/obj/item/clothing/suit/armor/medium/combat/environmental
	name = "environmental armor"
	desc = "A pre-war suit developed for use in heavily contaminated environments, and is prized in the Wasteland for its ability to protect against biological threats."
	icon_state = "environmental_armor"
	item_state = "environmental_armor"
	w_class = WEIGHT_CLASS_BULKY
	gas_transfer_coefficient = 0.9
	permeability_coefficient = 0.1
	strip_delay = 60
	equip_delay_other = 60
	flags_inv = HIDEJUMPSUIT
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_MORE_T1 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_ENV_T3)

/obj/item/clothing/suit/armor/medium/combat/environmental/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/rad_insulation, RAD_NO_INSULATION, TRUE, FALSE)

//recipe any combat armor + duster
/obj/item/clothing/suit/armor/medium/combat/duster
	name = "combat duster"
	desc = "Refurbished combat armor under a weathered duster. Simple metal plates replace the ceramic plates that has gotten damaged."
	icon_state = "combatduster"
	item_state = "combatduster"
	permeability_coefficient = 0.9
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/duster/armored
	armor_tokens = list(ARMOR_MODIFIER_DOWN_BULLET_T1, ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_DOWN_DT_T2)

///brotherhood of steel
/obj/item/clothing/suit/armor/medium/combat/brotherhood
	name = "brotherhood armor"
	desc = "A combat armor set made by the Brotherhood of Steel, standard issue for all Knights. It bears a red stripe."
	icon_state = "brotherhood_armor_knight"
	item_state = "brotherhood_armor_knight"
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T3, ARMOR_MODIFIER_DOWN_BULLET_T2, ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/medium/combat/brotherhood/senior
	name = "brotherhood senior knight armor"
	desc = "A renforced combat armor set made by the Brotherhood of Steel, standard issue for all Senior Knights. It bears a silver stripe."
	icon_state = "brotherhood_armor_senior"
	item_state = "brotherhood_armor_senior"

/obj/item/clothing/suit/armor/medium/combat/brotherhood/sarge
	name = "brotherhood Knight Sarge Armor"
	desc = "A renforced combat armor set made by the Brotherhood of Steel, standard issue for all Knight Sarge. It bears a silver stripe."
	icon_state = "brotherhood_armor_senior"
	item_state = "brotherhood_armor_senior"
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T3, ARMOR_MODIFIER_DOWN_BULLET_T2, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/medium/combat/brotherhood/captain
	name = "brotherhood head knight armor"
	desc = "A renforced combat armor set made by the Brotherhood of Steel, standard issue for all Head Knights. It bears golden embroidery."
	icon_state = "brotherhood_armor_captain"
	item_state = "brotherhood_armor_captain"
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T3, ARMOR_MODIFIER_DOWN_BULLET_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/medium/combat/brotherhood/initiate
	name = "initiate armor"
	desc = "An old degraded pre war combat armor, repainted to the colour scheme of the Brotherhood of Steel."
	icon_state = "brotherhood_armor"
	item_state = "brotherhood_armor"
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T3, ARMOR_MODIFIER_DOWN_BULLET_T3, ARMOR_MODIFIER_DOWN_LASER_T2)

/obj/item/clothing/suit/armor/medium/combat/brotherhood/initiate/mk2
	name = "reinforced knight armor"
	desc = "A reinforced set of bracers, greaves, and torso plating of prewar design This one is kitted with additional plates and, repainted to the colour scheme of the Brotherhood of Steel."
	icon_state = "brotherhood_armor_mk2"
	item_state = "brotherhood_armor_mk2"
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T3, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/medium/combat/brotherhood/outcast
	name = "brotherhood armor" //unused?
	desc = "A superior combat armor set made by the Brotherhood of Steel, bearing a series of red markings."
	icon_state = "brotherhood_armor_outcast"
	item_state = "brotherhood_armor_outcast"

/obj/item/clothing/suit/armor/medium/combat/brotherhood/exile
	name = "modified Brotherhood armor"
	desc = "A modified detoriated armor kit consisting of brotherhood combat armor and scrap metal."
	icon = 'icons/fallout/clothing/armored_heavy.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_heavy.dmi'
	icon_state = "exile_bos"
	item_state = "exile_bos"
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_LESS_T1 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_DOWN_ENV_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/medium/combat/tribal
	name = "tribal combat armor"
	desc = "An old military grade pre war combat armor, now decorated with sinew and the bones of the hunted for its new wearer."
	icon_state = "tribecombatarmor"
	item_state = "tribecombatarmor"
	body_parts_covered = CHEST|GROIN|ARMS|LEGS
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_LESS_T1 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_DT_T2)

/obj/item/clothing/suit/armor/medium/combat/marine
	name = "old United States Marine Corp Armor"
	desc = "An advanced model of combat armor worn by marines aboard the USS Democracy, second only to power armor in protection used by the USCM For various tasks and operations, it's handled the nuclear wasteland somewhat better than the rest of the armors you've seen."
	icon_state = "enclave_marine"
	item_state = "enclave_marine"

/obj/item/clothing/suit/armor/medium/combat/enclave
	name = "enclave combat armor"
	desc = "An old set of pre-war combat armor, painted black."
	icon_state = "enclave_new"
	item_state = "enclave_new"

///////////////////
// MEDIUM RAIDER //
///////////////////
// Has the heavier raider armors in it, less style, more protection. Still pretty light

/obj/item/clothing/suit/armor/medium/raider
	name = "base raider armor"
	desc = "for testing"
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/jacket
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_LESS_T1 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T2, ARMOR_MODIFIER_DOWN_BULLET_T2, ARMOR_MODIFIER_DOWN_LASER_T2, ARMOR_MODIFIER_DOWN_ENV_T1)

/obj/item/clothing/suit/armor/medium/raider/slam
	name = "slammer raider armor"
	desc = "Crude armor that appears to employ a tire of some kind as the shoulder pad. What appears to be a quilt is tied around the waist.<br>Come on and slam and turn your foes to jam!"
	icon_state = "slam"
	item_state = "slam"
	flags_inv = HIDEJUMPSUIT
	strip_delay = 40
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	body_parts_hidden = ARMS | LEGS | GROIN
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_DOWN_BULLET_T2, ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_DOWN_ENV_T1)

/obj/item/clothing/suit/armor/medium/raider/rebel
	name = "rebel raider armor"
	desc = "Rebel, rebel. Your face is a mess."
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "raider_rebel_icon"
	item_state = "raider_rebel_armor"

/obj/item/clothing/suit/armor/medium/raider/scrapcombat
	name = "scrap combat armor"
	desc = "Scavenged military combat armor, repaired by unskilled hands many times, most of the original plating having cracked or crumbled to dust."
	icon_state = "raider_combat"
	item_state = "raider_combat"
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T3, ARMOR_MODIFIER_DOWN_BULLET_T2, ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_DOWN_ENV_T1)

/obj/item/clothing/suit/armor/medium/raider/badlands
	name = "badlands raider armor"
	desc = "A leather top with a bandolier over it and a straps that cover the arms."
	icon_state = "badlands"
	item_state = "badlands"
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/magpouch
	body_parts_hidden = ARMS | LEGS | GROIN

/obj/item/clothing/suit/armor/medium/raider/combatduster
	name = "combat duster"
	desc = "An old military-grade pre-war combat armor under a weathered duster. It appears to be fitted with metal plates to replace the crumbling ceramic."
	icon_state = "combatduster"
	item_state = "combatduster"
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/duster/armored
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_LESS_T1 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T2, ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/medium/raider/combatduster/patrolduster
	name = "Patrol Duster"
	desc = "What appears to be an NCR patrol ranger's armor under a green tinted duster. The armor itself looks much more well kept then the duster itself, said duster looking somewhat faded. On the back of the duster, is a symbol of a skull with an arrow piercing through the eye."
	icon_state = "patrolduster"
	item_state = "patrolduster"

/obj/item/clothing/suit/armor/medium/raider/raidercombat
	name = "combat raider armor"
	desc = "An old military-grade pre-war combat armor. It appears to be fitted with metal plates to replace the crumbling ceramic."
	icon_state = "raider_combat"
	item_state = "raider_combat"
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_DOWN_BULLET_T1, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_ENV_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/medium/raider/raidermetal
	name = "metal raider armor"
	desc = "A suit of welded, fused metal plates. Looks bulky, with great protection."
	icon_state = "raider_metal"
	item_state = "raider_metal"
	resistance_flags = FIRE_PROOF
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_MORE_T1 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_DOWN_BULLET_T2, ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_DOWN_ENV_T1)

/obj/item/clothing/suit/armor/medium/raider/wastewar
	name = "wasteland warrior armor"
	desc = "a mad attempt to recreate armor based of images of japanese samurai, using a sawn up old car tire as shoulder pads, bits of chain to cover the hips and pieces of furniture for a breastplate. Might stop a blade but nothing else, burns easily too. Comes with an enormous scabbard welded to the back!"
	icon_state = "wastewar"
	item_state = "wastewar"
	resistance_flags = FLAMMABLE
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/massive/swords
	body_parts_hidden = CHEST | GROIN
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_DOWN_BULLET_T2, ARMOR_MODIFIER_DOWN_LASER_T2, ARMOR_MODIFIER_DOWN_ENV_T1)

/obj/item/clothing/suit/armor/medium/raider/blastmaster
	name = "blastmaster raider armor"
	desc = "A suit composed largely of blast plating, though there's so many holes it's hard to say if it will protect against much."
	icon_state = "blastmaster"
	item_state = "blastmaster"
	flash_protect = 2
	armor_tokens = list(ARMOR_MODIFIER_DOWN_BULLET_T3, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_UP_BOMB_T2)

/obj/item/clothing/suit/armor/medium/raider/yankee
	name = "yankee raider armor"
	desc = "A set of armor made from bulky plastic and rubber. A faded sports team logo is printed in various places. Go Desert Rats!"
	icon_state = "yankee"
	item_state = "yankee"
	body_parts_hidden = ARMS | CHEST

/// Environmental raider armor
/obj/item/clothing/suit/armor/medium/raider/iconoclast
	name = "iconoclast raider armor"
	desc = "A rigid armor set that appears to be fashioned from a radiation suit, or a mining suit."
	icon_state = "iconoclast"
	item_state = "iconoclast"
	slowdown = ARMOR_SLOWDOWN_MEDIUM * ARMOR_SLOWDOWN_MORE_T1 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_UP_ENV_T2)


///////////
// HEAVY //
///////////

/*
 * Stats
 * Big slowdown, high protection
 * 40% DR for general armor - ???% effective HP
 * 50-60% for specialist armor (most everything else is butt)
 *
 * Types:
 * Tribal Raider (basically the same at this point)
 * metal (-bullet , ++melee, ++laser)
 * Polished (--bullet , +melee, +++laser)
 * riot (special, +++melee , -bullet, --laser)
 * Vest - bulletproof (special, +++bullet, --everything else)
 * Salvaged PA (partway to PA, but super sloooow and bulky)
 */

/obj/item/clothing/suit/armor/heavy
	name = "heavy armor template"
	//icon = 'icons/fallout/clothing/armored_heavy.dmi'
	//mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_heavy.dmi'
	slowdown = 1
	strip_delay = 50
	equip_delay_other = 50
	max_integrity = 300
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/armor
	slowdown = ARMOR_SLOWDOWN_HEAVY * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_HEAVY
	armor_tier_desc = ARMOR_CLOTHING_HEAVY
	clothing_flags = CUSHIONED_ARMOR
	stiffness = HEAVY_STIFFNESS

/////////////////////
//// BULLET VEST //// ...?
/////////////////////

/obj/item/clothing/suit/armor/heavy/vest/bulletproof
	name = "heavy bulletproof armor"
	desc = "A heavy bulletproof vest that excels in protecting the wearer against traditional projectile weaponry."
	icon_state = "bulletproof"
	item_state = "armor"
	blood_overlay_type = "armor"
	mutantrace_variation = STYLE_DIGITIGRADE
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/magpouch // 4 slots for ammo!
	slowdown = ARMOR_SLOWDOWN_HEAVY * ARMOR_SLOWDOWN_LESS_T2 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T3, ARMOR_MODIFIER_UP_BULLET_T3, ARMOR_MODIFIER_DOWN_LASER_T3, ARMOR_MODIFIER_DOWN_ENV_T2, ARMOR_MODIFIER_UP_DT_T3)

//////////////////////
//// TRIBAL ARMOR ////
//////////////////////

/obj/item/clothing/suit/armor/heavy/tribal
	name = "tribal heavy carapace"
	desc = "Thick layers of leather and bone, with metal reinforcements, surely this will make the wearer tough and uncaring for claws and blades."
	icon = 'icons/fallout/clothing/armored_heavy.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_heavy.dmi'
	icon_state = "tribal_heavy"
	item_state = "tribal_heavy"
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/jacket
	slowdown = ARMOR_SLOWDOWN_HEAVY * ARMOR_SLOWDOWN_LESS_T1 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_DOWN_LASER_T4, ARMOR_MODIFIER_DOWN_BULLET_T2)


/obj/item/clothing/suit/armor/heavy/tribal/bone
	name = "Heavy Bone armor"
	desc = "A tribal full armor plate, crafted from animal bone, metal and leather. Usually worn by the Bone Dancers"
	icon = 'icons/obj/clothing/suits.dmi'
	mob_overlay_icon = null
	icon_state = "bone_dancer_armor_heavy"
	item_state = "bone_dancer_armor_heavy"
	blood_overlay_type = "armor"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T3, ARMOR_MODIFIER_DOWN_LASER_T3, ARMOR_MODIFIER_DOWN_BULLET_T2)


/obj/item/clothing/suit/armor/heavy/tribal/metal
	name = "metal armor suit"
	desc = "A suit of welded, fused metal plates. Bulky, but with great protection."
	icon = 'icons/obj/clothing/suits.dmi'
	mob_overlay_icon = null
	icon_state = "raider_metal"
	item_state = "raider_metal"
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_DOWN_BULLET_T2)

/obj/item/clothing/suit/armor/heavy/tribal/rustwalkers
	name = "Rustwalkers heavy armor"
	desc = "A car seat leather duster, a timing belt bandolier, and armour plating made from various parts of a car, it surely would weigh the wearer down. Commonly worn by members of the Rustwalkers tribe."
	icon_state = "rustwalkers_armour_heavy"
	item_state = "rustwalkers_armour_heavy"

/obj/item/clothing/suit/armor/heavy/tribal/whitelegs
	name = "White Legs heavy armour"
	desc = "A series of tan and khaki armour plates, held in place with a considerable amount of strapping and possibly duct tape. Commonly worn by members of the White Legs tribe."
	icon_state = "white_legs_armour_heavy"
	item_state = "white_legs_armour_heavy"
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T2, ARMOR_MODIFIER_DOWN_LASER_T3, ARMOR_MODIFIER_UP_BULLET_T3)


/obj/item/clothing/suit/armor/heavy/tribal/eighties
	name = "80s heavy armour"
	desc = "A ballistic duster with the number 80 stitched onto the back worn over a breastplate made from a motorcycle's engine housing, with kneepads made from stirrups. Worn by the members of the 80s tribe."
	icon_state = "80s_armour_heavy"
	item_state = "80s_armour_heavy"

/obj/item/clothing/suit/armor/heavy/tribal/deadhorses
	name = "Dead Horses heavy armour"
	desc = "A simple leather bandolier and gecko hide chest covering, with an engraved metal pauldron and a set of black leather straps, one holding a shinpad in place. Commonly worn by the members of the Dead Horses tribe."
	icon_state = "dead_horses_armour_heavy"
	item_state = "dead_horses_armour_heavy"

/obj/item/clothing/suit/armor/heavy/tribal/westernwayfarer
	name = "Western Wayfarer heavy armor"
	desc = "A Suit of armor crafted by Tribals using pieces of scrap metals and the armor of fallen foes, a bighorner's skull sits on the right pauldron along with bighorner fur lining the collar of the leather bound chest. Along the leather straps adoring it are multiple bone charms with odd markings on them."
	icon_state = "western_wayfarer_armor_heavy"
	item_state = "western_wayfarer_armor_heavy"
	body_parts_covered = CHEST|GROIN|LEGS|ARMS|HANDS

/obj/item/clothing/suit/armor/heavy/tribal/bone
	name = "Heavy Bone armor"
	desc = "A tribal full armor plate, crafted from animal bone, metal and leather. Usually worn by the Bone Dancers"
	icon_state = "bone_dancer_armor_heavy"
	item_state = "bone_dancer_armor_heavy"
	blood_overlay_type = "armor"
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T3, ARMOR_MODIFIER_DOWN_LASER_T3, ARMOR_MODIFIER_DOWN_BULLET_T2)

/////////////////////
//// METAL ARMOR ////
/////////////////////

/obj/item/clothing/suit/armor/heavy/metal
	name = "metal armor"
	desc = "A set of plates formed together to form a crude chestplate."
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "metal_chestplate"
	item_state = "metal_chestplate"
	slowdown = ARMOR_SLOWDOWN_HEAVY * ARMOR_SLOWDOWN_MORE_T1 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_DOWN_BULLET_T3, ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/heavy/metal/polished
	name = "polished metal armor"
	desc = "A set of plates formed together to form a crude chestplate. These have been waxed and buffed to a mirror finish, but it looks a bit thinner."
	icon = 'icons/fallout/clothing/armored_medium.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_medium.dmi'
	icon_state = "armor_enclave_peacekeeper"
	item_state = "armor_enclave_peacekeeper"
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_UP_LASER_T3, ARMOR_MODIFIER_UP_ENV_T1)
	mutantrace_variation = NONE

/obj/item/clothing/suit/armor/heavy/metal/polished/actually_laserproof // also actually_unobtainable
	name = "reflector vest"
	desc = "A vest that excels in protecting the wearer against energy projectiles, as well as occasionally reflecting them."
	icon = 'icons/obj/clothing/suits.dmi'
	icon_state = "armor_reflec"
	item_state = "armor_reflec"
	blood_overlay_type = "armor"
	mob_overlay_icon = null
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	mutantrace_variation = STYLE_DIGITIGRADE
	var/hit_reflect_chance = 40
	protected_zones = list(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_GROIN)
	mutantrace_variation = NONE
	armor = list(
		"melee" = 0,
		"bullet" = 0,
		"laser" = 90,
		"energy" = 30,
		"bomb" = 10,
		"bio" = 10,
		"rad" = 10,
		"fire" = 10,
		"acid" = 50)

/obj/item/clothing/suit/armor/heavy/metal/polished/actually_laserproof/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(def_zone in protected_zones)
		if(prob(hit_reflect_chance))
			return BLOCK_SHOULD_REDIRECT | BLOCK_REDIRECTED | BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL
	return ..()

/obj/item/clothing/suit/armor/heavy/metal/tesla //changed from armor/laserproof
	name = "tesla armor"
	desc = "A prewar armor design by Nikola Tesla before being confinscated by the U.S. government. Has a chance to deflect energy projectiles."
	icon = 'icons/obj/clothing/suits.dmi'
	icon_state = "tesla_armor"
	item_state = "tesla_armor"
	blood_overlay_type = "armor"
	mob_overlay_icon = null
	resistance_flags = FIRE_PROOF
	var/hit_reflect_chance = 20
	protected_zones = list(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_GROIN, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	mutantrace_variation = NONE
	armor = list(
		"melee" = 5,
		"bullet" = 5,
		"laser" = 65,
		"energy" = 50,
		"bomb" = 0,
		"bio" = 0,
		"rad" = 0,
		"fire" = 0,
		"acid" = 0)

/obj/item/clothing/suit/armor/heavy/metal/tesla/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(is_energy_reflectable_projectile(object) && (attack_type == ATTACK_TYPE_PROJECTILE) && (def_zone in protected_zones))
		if(prob(hit_reflect_chance))
			block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_DEFLECT
			return BLOCK_SHOULD_REDIRECT | BLOCK_REDIRECTED | BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL
	return ..()

/obj/item/clothing/suit/armor/heavy/metal/reinforced
	name = "reinforced metal armor"
	desc = "A set of well-fitted plates formed together to provide effective protection."
	icon_state = "metal_chestplate2"
	item_state = "metal_chestplate2"
	slowdown = ARMOR_SLOWDOWN_HEAVY * ARMOR_SLOWDOWN_MORE_T1 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_DOWN_BULLET_T2, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/heavy/metal/mutant
	name = "mutant armour"
	desc = "An oversized set of metal armour, made to fit the frame of a super mutant. Maybe he's the big iron with a ranger on his hip?"
	icon = 'icons/obj/clothing/suits.dmi'
	icon_state = "mutie_metal_armour"
	item_state = "mutie_metal_armour"
	mutantrace_variation = NONE

/obj/item/clothing/suit/armor/heavy/metal/mutant/reinforced
	name = "mutant armour"
	desc = "An oversized boiler plate, hammered to fit the frame of a super mutant. Maybe he's the big iron with a ranger on his hip?"
	icon_state = "mutie_metal_armour_mk2"
	item_state = "mutie_metal_armour_mk2"
	slowdown = ARMOR_SLOWDOWN_HEAVY * ARMOR_SLOWDOWN_MORE_T1 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_LASER_T1, ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_DT_T1)
	mutantrace_variation = NONE

/obj/item/clothing/suit/armor/heavy/metal/sulphite
	name = "sulphite armor"
	desc = "A combination of what seems to be raider metal armor with a jerry-rigged flame-exhaust system and ceramic plating."
	icon = 'icons/fallout/clothing/armored_heavy.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_heavy.dmi'
	resistance_flags = FIRE_PROOF
	icon_state = "sulphite"
	item_state = "sulphite"
	slowdown = ARMOR_SLOWDOWN_HEAVY * ARMOR_SLOWDOWN_MORE_T1 * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T3, ARMOR_MODIFIER_DOWN_BULLET_T2, ARMOR_MODIFIER_UP_BOMB_T3, ARMOR_MODIFIER_UP_ENV_T2, ARMOR_MODIFIER_UP_FIRE_T3)
	mutantrace_variation = NONE

////////////////////
//// RIOT ARMOR ////
////////////////////

/obj/item/clothing/suit/armor/heavy/riot
	name = "riot suit"
	desc = "A suit of semi-flexible polycarbonate body armor with heavy padding to protect against melee attacks. Helps the wearer resist shoving in close quarters."
	icon_state = "riot"
	item_state = "swat_suit"
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/magpouch // 4 slots for ammo!
	blocks_shove_knockdown = TRUE
	slowdown = ARMOR_SLOWDOWN_HEAVY * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T3, ARMOR_MODIFIER_DOWN_BULLET_T2, ARMOR_MODIFIER_DOWN_LASER_T3, ARMOR_MODIFIER_DOWN_FIRE_T3, ARMOR_MODIFIER_UP_DT_T2)

/obj/item/clothing/suit/armor/heavy/riot/combat
	name = "combat riot armor"
	icon_state = "combat_coat"
	item_state = "combat_coat"
	desc = "A heavy armor with ballistic inserts, sewn into a padded riot police coat."

/obj/item/clothing/suit/armor/heavy/riot/bos
	name = "combat riot armor"
	icon_state = "broken_riot_bos"
	item_state = "broken_riot_bos"
	desc = "A heavy armor with ballistic inserts, sewn into a padded riot police coat."

/obj/item/clothing/suit/armor/heavy/riot/tribal
	name = "combat riot armor"
	icon_state = "broken_riot_tribal"
	item_state = "broken_riot_tribal"
	desc = "A heavy armor with ballistic inserts, sewn into a padded riot police coat."

/obj/item/clothing/suit/armor/heavy/riot/enclave
	name = "combat riot armor"
	icon_state = "enclave_broken_riot"
	item_state = "enclave_broken_riot"
	desc = "A heavy armor with ballistic inserts, sewn into a padded riot police coat."

/obj/item/clothing/suit/armor/heavy/riot/police
	name = "riot police armor"
	icon_state = "bulletproof_heavy"
	item_state = "bulletproof_heavy"
	desc = "Heavy armor with ballistic inserts, sewn into a padded riot police coat."

/obj/item/clothing/suit/armor/heavy/riot/vault
	name = "VTCC riot armour"
	desc = "(VII) A suit of riot armour adapted from the design of the pre-war U.S.M.C. armour, painted blue and white."
	icon_state = "vtcc_riot_gear"
	item_state = "vtcc_riot_gear"

/obj/item/clothing/suit/armor/heavy/riot/marine
	name = "old United States Marine Corp riot suit"
	desc = "A pre-war riot suit helmet used by the USCM For various tasks and operations, it's handled the nuclear wasteland somewhat better than the rest of the armors you've seen."
	icon_state = "usmc_riot_gear"
	item_state = "usmc_riot_gear"

/obj/item/clothing/suit/armor/heavy/riot/retrofitted
	name = "retro fitted riot combat armor"
	desc = "A pre-war riot suit helmet used by the USCM For various tasks and operations, it's handled the nuclear wasteland somewhat better than the rest of the armors you've seen, however most of the plates have been torn out to make room for various storage compartments."
	icon_state = "usmc_riot_gear"
	item_state = "usmc_riot_gear"
	slowdown = ARMOR_SLOWDOWN_LIGHT * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_DOWN_BULLET_T2, ARMOR_MODIFIER_DOWN_LASER_T1, ARMOR_MODIFIER_DOWN_FIRE_T3, ARMOR_MODIFIER_DOWN_DT_T1)

/obj/item/clothing/suit/armor/heavy/riot/elite
	name = "elite riot gear"
	desc = "A heavily reinforced set of military grade armor."
	icon_state = "elite_riot"
	item_state = "elite_riot"
	icon = 'icons/obj/clothing/suits.dmi'

/obj/item/clothing/suit/armor/heavy/riot/eliteweak
	name = "worn elite riot gear"
	desc = "A heavily reinforced set of military grade armor. This one appears to be aged..."
	icon_state = "elite_riot"
	item_state = "elite_riot"
	icon = 'icons/obj/clothing/suits.dmi'
	slowdown = ARMOR_SLOWDOWN_LIGHT * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor_tokens = list(ARMOR_MODIFIER_DOWN_BULLET_T1, ARMOR_MODIFIER_DOWN_LASER_T2, ARMOR_MODIFIER_DOWN_FIRE_T3, ARMOR_MODIFIER_DOWN_DT_T1)

//////////////////////////
// Salvaged Power Armor //
//////////////////////////

/obj/item/clothing/suit/armor/heavy/salvaged_pa
	name = "salvaged power armor"
	desc = "It's a set of early-model SS-13 power armor, except it isn't real. Stop looking at it, go ping coders or something. \
	It's literally not meant to be here, you are just wasting your time reading some text that someone wrote for you \
	because he thought it'd be funny, or expected someone to check GitHub for once, hello by the way. \
	If you still don't understand - it's a 'master' item, basically main type/parent object or something. \
	It isn't meant to be used, it just dictates procs and all that stuff to the subtypes, such as t45b and so on. \
	Now begone, report this to coders. NOW!"
	icon = 'icons/fallout/clothing/armored_heavy.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/armor_heavy.dmi'
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/armor
	slowdown = ARMOR_SLOWDOWN_SALVAGE * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_SALVAGE
	armor_tier_desc = ARMOR_CLOTHING_SALVAGE

// T-45B
/obj/item/clothing/suit/armor/heavy/salvaged_pa/t45b
	name = "salvaged T-45b power armor"
	desc = "It's a set of early-model T-45 power armor with a custom air conditioning module and stripped out servomotors. Bulky and slow, but almost as good as the real thing."
	icon_state = "t45b_salvaged"
	item_state = "t45b_salvaged"

/obj/item/clothing/suit/armor/heavy/salvaged_pa/t45b/raider
	name = "salvaged raider power armor"
	desc = "A destroyed T-45b power armor has been brought back to life with the help of a welder and lots of scrap metal."
	icon_state = "raider_salvaged"
	item_state = "raider_salvaged"

/obj/item/clothing/suit/armor/heavy/salvaged_pa/t45b/hotrod
	name = "salvaged hotrod T-45b power armor"
	desc = " It's a set of T-45b power armor with a with some of its plating removed. This set has exhaust pipes piped to the pauldrons, flames erupting from them."
	mob_overlay_icon = 'icons/fallout/clothing/armored_heavy.dmi'
	icon_state = "t45hotrod"
	item_state = "t45hotrod"
	armor_tokens = list(ARMOR_MODIFIER_UP_FIRE_T3, ARMOR_MODIFIER_DOWN_MELEE_T2, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_DOWN_DT_T1)


/obj/item/clothing/suit/armor/heavy/salvaged_pa/t45b/tribal
	name = "salvaged tribal T45-b power armor"
	desc = "A set of salvaged power armor, with certain bits of plating stripped out to retain more freedom of movement. No cooling module, though."
	icon_state = "tribal_power_armor"
	item_state = "tribal_power_armor"
	// body_parts_covered = CHEST|GROIN|ARMS|LEGS
	slowdown = ARMOR_SLOWDOWN_SALVAGE * ARMOR_SLOWDOWN_LESS_T3 * ARMOR_SLOWDOWN_GLOBAL_MULT // zooom
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_DOWN_BULLET_T1, ARMOR_MODIFIER_DOWN_LASER_T2)

/obj/item/clothing/suit/armor/heavy/salvaged_pa/t45b/bos
	name = "salvaged Brotherhood T45-b power armor"
	desc = "A set of salvaged power armor, with certain bits of plating stripped out to retain more freedom of movement. It holds some paint upon it showing it belonging to the brotherhood."
	icon_state = "t45b_salvaged_bos"
	item_state = "t45b_salvaged_bos"
	// body_parts_covered = CHEST|GROIN|ARMS|LEGS
	slowdown = ARMOR_SLOWDOWN_SALVAGE * ARMOR_SLOWDOWN_LESS_T3 * ARMOR_SLOWDOWN_GLOBAL_MULT // zooom
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_DOWN_BULLET_T1, ARMOR_MODIFIER_DOWN_LASER_T2)

/obj/item/clothing/suit/armor/heavy/salvaged_pa/t45b/enclave
	name = "salvaged Enclave T45-b power armor"
	desc = "A set of salvaged power armor, with certain bits of plating stripped out to retain more freedom of movement. It holds some paint upon it showing it belonging to the enclave."
	icon_state = "t45b_salvaged_enclave"
	item_state = "t45b_salvaged_enclave"
	// body_parts_covered = CHEST|GROIN|ARMS|LEGS
	slowdown = ARMOR_SLOWDOWN_SALVAGE * ARMOR_SLOWDOWN_LESS_T3 * ARMOR_SLOWDOWN_GLOBAL_MULT // zooom
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_DOWN_BULLET_T1, ARMOR_MODIFIER_DOWN_LASER_T2)

/obj/item/clothing/suit/armor/heavy/salvaged_pa/t45b/mutant
	name = "salvaged Mutant T45-b power armor"
	desc = "A set of salvaged power armor, with certain bits of plating stripped out to retain more freedom of movement. It's been heavily stripped apart, additional metal has been added so a super-mutant can fit within it."
	icon_state = "t45b_salvaged_sm"
	item_state = "t45b_salvaged_sm"
	// body_parts_covered = CHEST|GROIN|ARMS|LEGS
	slowdown = ARMOR_SLOWDOWN_SALVAGE * ARMOR_SLOWDOWN_LESS_T3 * ARMOR_SLOWDOWN_GLOBAL_MULT // zooom
	armor_tokens = list(ARMOR_MODIFIER_DOWN_MELEE_T1, ARMOR_MODIFIER_DOWN_BULLET_T1, ARMOR_MODIFIER_DOWN_LASER_T2)


/obj/item/clothing/suit/armor/heavy/salvaged_pa/t45b/tribal/junk
	name = "salvaged weathered tribal T45-b power armor"
	desc = "A set of salvaged tribal power armor, one that's seen better days. Proof that power armor doesn't age like wine, especially dragged through the swamp as much as this one has. All that weathered off armor plating's sure made it light, though!"
	icon_state = "tribal_power_armor"
	item_state = "tribal_power_armor"
	// body_parts_covered = CHEST|GROIN|ARMS|LEGS
	armor = ARMOR_VALUE_HEAVY
	slowdown = ARMOR_SLOWDOWN_HEAVY * ARMOR_SLOWDOWN_GLOBAL_MULT
	color = "#b1a687"

/obj/item/clothing/suit/armor/heavy/salvaged_pa/t45d
	name = "salvaged T-45d power armor"
	desc = "T-45d power armor with servomotors and all valuable components stripped out of it."
	icon_state = "t45d_salvaged"
	item_state = "t45d_salvaged"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_BULLET_T1)

// T-51B
/obj/item/clothing/suit/armor/heavy/salvaged_pa/t51b
	name = "salvaged T-51b power armor"
	desc = "T-51b power armor with servomotors and all valuable components stripped out of it."
	icon_state = "t51b_salvaged"
	item_state = "t51b_salvaged"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_UP_DT_T1)


// X-02
/obj/item/clothing/suit/armor/heavy/salvaged_pa/x02
	name = "salvaged Enclave power armor"
	desc = "X-02 power armor with servomotors and all valuable components stripped out of it."
	icon_state = "advanced_salvaged"
	item_state = "advanced_salvaged"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T3, ARMOR_MODIFIER_UP_BULLET_T3, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_UP_DT_T2)


// Just generic PA I guess??
/obj/item/clothing/suit/armor/heavy/salvaged_pa/recycled
	name = "recycled power armor"
	desc = "Taking pieces off from a wrecked power armor will at least give you thick plating, but don't expect too much of this shot up, piecemeal armor.."
	icon_state = "recycled_power"

/////////////////
// Power armor //
/////////////////

/obj/item/clothing/suit/armor/power_armor
	w_class = WEIGHT_CLASS_HUGE
	// body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	cold_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	flags_inv = HIDEJUMPSUIT
	item_flags = SLOWS_WHILE_IN_HAND
	clothing_flags = THICKMATERIAL
	equip_delay_self = 50
	equip_delay_other = 60
	strip_delay = 200
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	cold_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	salvage_loot = list(/obj/item/stack/crafting/armor_plate = 20)
	salvage_tool_behavior = TOOL_WELDER
	pocket_storage_component_path = null // quit ripping your power cell out ffs
	/// Cell that is currently installed in the suit
	var/obj/item/stock_parts/cell/cell = /obj/item/stock_parts/cell/high
	/// How much power the cell consumes each process tick
	var/usage_cost = 15 // With high-capacity cell it'd run out of charge in ~33 minutes
	/// If TRUE - suit has ran out of charge and is currently affected by slowdown from it
	var/no_power = FALSE
	/// How much slowdown is added when suit is unpowered
	var/unpowered_slowdown = 5
	/// Projectiles below this damage will get deflected
	var/deflect_damage = 18
	/// If TRUE - it requires PA training trait to be worn
	var/requires_training = TRUE
	/// If TRUE - the suit will give its user specific traits when worn
	var/powered = TRUE
	/// If TRUE - the suit has been recently affected by EMP blast
	var/emped = FALSE
	/// Path of item that this set of armor gets salvaged into
	var/obj/item/salvaged_type = null
	/// Used to track next tool required to salvage the suit
	var/salvage_step = 0
	slowdown = ARMOR_SLOWDOWN_PA * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_PA
	armor_tier_desc = ARMOR_CLOTHING_PA
	clothing_flags = CUSHIONED_ARMOR
	stiffness = MEDIUM_STIFFNESS

/obj/item/clothing/suit/armor/power_armor/Initialize()
	. = ..()
	if(ispath(cell))
		cell = new cell(src)

/obj/item/clothing/suit/armor/power_armor/mob_can_equip(mob/user, mob/equipper, slot, disable_warning = 1)
	var/mob/living/carbon/human/H = user
	if(src == H.wear_suit) //Suit is already equipped
		return ..()
	if (!HAS_TRAIT(H, TRAIT_PA_WEAR) && slot == SLOT_WEAR_SUIT && requires_training)
		to_chat(user, span_warning("You don't have the proper training to operate the power armor!"))
		return FALSE
	if(slot == SLOT_WEAR_SUIT)
		return ..()
	return

/obj/item/clothing/suit/armor/power_armor/equipped(mob/user, slot)
	..()
	if(slot == SLOT_WEAR_SUIT && powered)
		START_PROCESSING(SSobj, src)
		assign_traits(user)

/obj/item/clothing/suit/armor/power_armor/proc/assign_traits(mob/user)
	if(no_power) // Has no charge left
		return
	ADD_TRAIT(user, TRAIT_STUNIMMUNE, "PA_stun_immunity")
	ADD_TRAIT(user, TRAIT_PUSHIMMUNE, "PA_push_immunity")
	ADD_TRAIT(user, SPREAD_CONTROL, "PA_spreadcontrol")
	ADD_TRAIT(user, TRAIT_POWER_ARMOR, "PA_worn_trait") // General effects from being in PA

/obj/item/clothing/suit/armor/power_armor/dropped(mob/user)
	..()
	if(powered)
		STOP_PROCESSING(SSobj, src)
		remove_traits(user)

/obj/item/clothing/suit/armor/power_armor/proc/remove_traits(mob/user)
	REMOVE_TRAIT(user, TRAIT_STUNIMMUNE, "PA_stun_immunity")
	REMOVE_TRAIT(user, TRAIT_PUSHIMMUNE, "PA_push_immunity")
	REMOVE_TRAIT(user, SPREAD_CONTROL, "PA_spreadcontrol")
	REMOVE_TRAIT(user, TRAIT_POWER_ARMOR, "PA_worn_trait")

/obj/item/clothing/suit/armor/power_armor/Destroy()
	. = ..()
	STOP_PROCESSING(SSobj, src)

/obj/item/clothing/suit/armor/power_armor/process()
	var/mob/living/carbon/human/user = src.loc
	if(!user || !ishuman(user) || (user.wear_suit != src))
		return
	if((!cell || !cell?.use(usage_cost) || (salvage_step > 1))) // No cell, ran out of charge or we're in the process of being salvaged
		if(!no_power)
			remove_power(user)
		return
	if(no_power) // Above didn't proc and suit is currently unpowered, meaning cell is installed and has charge - restore power
		restore_power(user)
		return

/obj/item/clothing/suit/armor/power_armor/proc/remove_power(mob/user)
	if(salvage_step > 1) // Being salvaged
		to_chat(user, span_warning("Components in [src] require repairs!"))
	else
		to_chat(user, span_warning("\The [src] has ran out of charge!"))
	slowdown += unpowered_slowdown
	no_power = TRUE
	remove_traits(user)
	user.update_equipment_speed_mods()

/obj/item/clothing/suit/armor/power_armor/proc/restore_power(mob/user)
	to_chat(user, span_notice("\The [src]'s power restored."))
	slowdown -= unpowered_slowdown
	no_power = FALSE
	assign_traits(user)
	user.update_equipment_speed_mods()

/obj/item/clothing/suit/armor/power_armor/attackby(obj/item/I, mob/living/carbon/human/user, params)
	if(powered && istype(I, /obj/item/stock_parts/cell))
		if(cell)
			to_chat(user, span_warning("\The [src] already has a cell installed."))
			return
		if(user.transferItemToLoc(I, src))
			cell = I
			to_chat(user, span_notice("You successfully install \the [cell] into [src]."))
		return

	if(ispath(salvaged_type))
		switch(salvage_step)
			if(0)
				// Salvage
				if(istype(I, /obj/item/screwdriver))
					if(ishuman(user) && user.wear_suit == src)
						to_chat(user, span_warning("You have to take off the suit before salvaging it."))
						return
					to_chat(user, span_notice("You begin unsecuring the wiring cover..."))
					if(I.use_tool(src, user, 60, volume=50))
						salvage_step = 1
						to_chat(user, span_notice("You unsecure the wiring cover."))
					return
			if(1)
				// Salvage
				if(istype(I, /obj/item/wirecutters))
					if(ishuman(user) && user.wear_suit == src)
						to_chat(user, span_warning("You have to take off the suit before salvaging it."))
						return
					to_chat(user, span_notice("You start to cut down the wiring..."))
					if(I.use_tool(src, user, 80, volume=50))
						salvage_step = 2
						to_chat(user, span_notice("You disconnect the wires."))
					return
				// Fix
				if(istype(I, /obj/item/screwdriver))
					if(ishuman(user) && user.wear_suit == src)
						to_chat(user, span_warning("You have to take off the suit before fixing it."))
						return
					to_chat(user, span_notice("You begin securing the wiring cover..."))
					if(I.use_tool(src, user, 60, volume=50))
						salvage_step = 0
						to_chat(user, span_notice("You secure the wiring cover."))
					return
			if(2)
				// Salvage
				if(istype(I, /obj/item/wrench))
					if(ishuman(user) && user.wear_suit == src)
						to_chat(user, span_warning("You have to take off the suit before salvaging it."))
						return
					to_chat(user, span_notice("You start loosening the bolts that secure components to the frame..."))
					if(I.use_tool(src, user, 100, volume=50))
						salvage_step = 3
						to_chat(user, span_notice("You disconnect the inner components."))
					return
				// Fix
				if(istype(I, /obj/item/wirecutters))
					if(ishuman(user) && user.wear_suit == src)
						to_chat(user, span_warning("You have to take off the suit before fixing it."))
						return
					to_chat(user, span_notice("You begin placing wires back into their place..."))
					if(I.use_tool(src, user, 80, volume=50))
						salvage_step = 1
						to_chat(user, span_notice("You re-connect the wires."))
					return
			if(3)
				// Salvage
				if(istype(I, /obj/item/weldingtool) || istype(I, /obj/item/gun/energy/plasmacutter))
					if(ishuman(user) && user.wear_suit == src)
						to_chat(user, span_warning("You have to take off the suit before salvaging it."))
						return
					to_chat(user, span_notice("You begin slicing the servomotors apart from the frame..."))
					if(I.use_tool(src, user, 150, volume=60))
						salvage_step = 4
						to_chat(user, span_notice("You disconnect servomotors from the main frame."))
					return
				// Fix
				if(istype(I, /obj/item/wrench))
					if(ishuman(user) && user.wear_suit == src)
						to_chat(user, span_warning("You have to take off the suit before fixing it."))
						return
					to_chat(user, span_notice("You start securing components to the frame..."))
					if(I.use_tool(src, user, 100, volume=50))
						salvage_step = 2
						to_chat(user, span_notice("You re-connect the inner components."))
					return
			if(4)
				// Salvage
				if(istype(I, /obj/item/crowbar))
					if(ishuman(user) && user.wear_suit == src)
						to_chat(user, span_warning("You have to take off the suit before salvaging it."))
						return
					to_chat(user, span_notice("You start to remove remaining components..."))
					if(I.use_tool(src, user, 50, volume=70))
						to_chat(user, span_notice("You finish salvaging the suit."))
						var/obj/item/ST = new salvaged_type(src)
						user.put_in_hands(ST)
						qdel(src)
					return
				// Fix
				if(istype(I, /obj/item/weldingtool) || istype(I, /obj/item/gun/energy/plasmacutter))
					if(ishuman(user) && user.wear_suit == src)
						to_chat(user, span_warning("You have to take off the suit before fixing it."))
						return
					to_chat(user, span_notice("You begin welding the servomotors to the frame..."))
					if(I.use_tool(src, user, 150, volume=60))
						salvage_step = 3
						to_chat(user, span_notice("You re-connect servomotors to the main frame."))
					return
	return ..()

/obj/item/clothing/suit/armor/power_armor/attack_self(mob/living/user)
	if(powered)
		toggle_cell(user)
	return ..()

/obj/item/clothing/suit/armor/power_armor/AltClick(mob/living/user)
	if(!user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
		return ..()
	if(powered)
		toggle_cell(user)
	return

/obj/item/clothing/suit/armor/power_armor/proc/toggle_cell(mob/living/user)
	if(cell)
		user.visible_message(span_notice("[user] removes \the [cell] from [src]!"), \
			span_notice("You remove [cell]."))
		cell.add_fingerprint(user)
		user.put_in_hands(cell)
		cell = null
	else
		to_chat(user, span_warning("[src] has no cell installed."))

/obj/item/clothing/suit/armor/power_armor/examine(mob/user)
	. = ..()
	if(powered && (in_range(src, user) || isobserver(user)))
		if(cell)
			. += "The power meter shows [round(cell.percent(), 0.1)]% charge remaining."
		else
			. += "The power cell slot is currently empty."
	if(ispath(salvaged_type))
		. += salvage_hint()

/obj/item/clothing/suit/armor/power_armor/proc/salvage_hint()
	switch(salvage_step)
		if(0)
			return "<span class='notice'>The wiring cover is <i>screwed</i> in place.</span>"
		if(1)
			return "<span class='notice'>The cover is <i>screwed</i> open and <i>wires</i> are visible.</span>"
		if(2)
			return "<span class='warning'>The wiring has been <i>cut</i> and components connected with <i>bolts</i> are visible.</span>"
		if(3)
			return "<span class='warning'>The components have been <i>unanchored</i> servomotors inside the suit can be <i>sliced through</i>.</span>"
		if(4)
			return "<span class='warning'>The servomotors have been <i>sliced apart</i> from the frame and remaining components can be <i>pried away</i>.</span>"

/obj/item/clothing/suit/armor/power_armor/emp_act(mob/living/carbon/human/owner, severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(!powered)
		return
	if(cell)
		cell.emp_act(severity)
	if(!emped)
		if(isliving(loc))
			var/mob/living/L = loc
			var/induced_slowdown = 0
			if(severity >= 41) //heavy emp
				induced_slowdown = 4
				to_chat(L, span_boldwarning("Warning: severe electromagnetic surge detected in armor. Rerouting power to emergency systems."))
			else
				induced_slowdown = 2
				to_chat(L, span_warning("Warning: light electromagnetic surge detected in armor. Rerouting power to emergency systems."))
			emped = TRUE
			slowdown += induced_slowdown
			L.update_equipment_speed_mods()
			addtimer(CALLBACK(src, PROC_REF(end_emp_effect), induced_slowdown), 50)
	return

/obj/item/clothing/suit/armor/power_armor/proc/end_emp_effect(slowdown_induced)
	emped = FALSE
	slowdown -= slowdown_induced // Even if armor is dropped it'll fix slowdown
	if(isliving(loc))
		var/mob/living/L = loc
		to_chat(L, span_warning("Armor power reroute successful. All systems operational."))
		L.update_equipment_speed_mods()

/obj/item/clothing/suit/armor/power_armor/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if((attack_type == ATTACK_TYPE_PROJECTILE) && (def_zone in protected_zones))
		if(prob(70) && (damage < deflect_damage) && (armour_penetration <= 0)) // Weak projectiles like shrapnel get deflected
			block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_DEFLECT
			return BLOCK_SHOULD_REDIRECT | BLOCK_REDIRECTED | BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL
	return ..()

/obj/item/clothing/suit/armor/power_armor/t45b
	name = "Refurbished T-45b power armor"
	desc = "It's a set of early-model T-45 power armor with a custom air conditioning module and restored servomotors. Bulky, but almost as good as the real thing."
	icon_state = "t45bpowerarmor"
	item_state = "t45bpowerarmor"
	armor = ARMOR_VALUE_SALVAGE
	slowdown = ARMOR_SLOWDOWN_SALVAGE * ARMOR_SLOWDOWN_GLOBAL_MULT
	salvaged_type = /obj/item/clothing/suit/armor/heavy/salvaged_pa/t45b

/obj/item/clothing/suit/armor/power_armor/t45b/raider
	name = "powered scrap suit"
	desc = "A monumentously heavy suit of rusty metal and car parts. Either an actual power armor exoskeleton or some home-built substitute sits embedded under all that rust. Is this some attempt at power armor???"
	icon_state = "raiderpa"
	item_state = "raiderpa"
	salvaged_type = /obj/item/clothing/suit/armor/medium/raider/raidermetal

/obj/item/clothing/suit/armor/power_armor/t45d
	name = "T-45d power armor"
	desc = "Originally developed and manufactured for the United States Army by American defense contractor West Tek, the T-45d power armor was the first version of power armor to be successfully deployed in battle."
	icon_state = "t45dpowerarmor"
	item_state = "t45dpowerarmor"
	salvaged_type = /obj/item/clothing/suit/armor/heavy/salvaged_pa/t45d
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/power_armor/t45d/knightcaptain
	name = "Head-Knight's T-45d Power Armour"
	desc = "A classic set of T-45d Power Armour only to be used in armed combat, it signifies the Head Knight and their place in the Brotherhood. A leader, and a beacon of structure in a place where chaos reigns. All must rally to his call, for he is the Head Knight and your safety is his duty."
	icon_state = "t45dkc"
	item_state = "t45dkc"

/obj/item/clothing/suit/armor/power_armor/t45d/bos
	name = "Brotherhood T-45d Power Armour"
	desc = "A suit of T-45d Power Armour adorned with the markings of the Brotherhood of Steel. Commonly used by the Paladins of the Brotherhood."
	icon_state = "t45dpowerarmor_bos"
	item_state = "t45dpowerarmor_bos"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/power_armor/t45d/minutemen
	name = "minutemen T-45d Power Armour"
	desc = "A suit of T-45d Power Armour adorned with the markings of the Minutemen. Though rare to see, sometimes it can be seen in the minutemen."
	icon_state = "t45dpowerarmor_minutemen"
	item_state = "t45dpowerarmor_minutemen"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/power_armor/t45d/enclave
	name = "Brotherhood T-45d Power Armour"
	desc = "A suit of T-45d Power Armour adorned with the markings of the Enclave. Not very commonly used by low ranking Enclave Soldiers."
	icon_state = "t45dpowerarmor_enclave"
	item_state = "t45dpowerarmor_enclave"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_UP_DT_T1)


/obj/item/clothing/suit/armor/power_armor/t51b
	name = "T-51b power armor"
	desc = "The pinnacle of pre-war technology. This suit of power armor provides substantial protection to the wearer."
	icon_state = "t51bpowerarmor"
	item_state = "t51bpowerarmor"
	salvage_loot = list(/obj/item/stack/crafting/armor_plate = 25)
	salvaged_type = /obj/item/clothing/suit/armor/heavy/salvaged_pa/t51b
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T1, ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_UP_DT_T1)


/obj/item/clothing/suit/armor/power_armor/t51b/hardened
	name = "Hardened T-51b power armor"
	desc = "The pinnacle of pre-war technology. This suit of power armor provides substantial protection to the wearer. It's plates have been chemially treated to be stronger."
	icon_state = "t51green"
	item_state = "t51green"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_UP_DT_T2)

/obj/item/clothing/suit/armor/power_armor/t51b/palcomm
	name = "T-51b Paladin Commander Armor"
	desc = "The pinnacle of pre-war technology. This suit of power armor is customised heavily to fit the Paladin Commander."
	icon_state = "palcomm"
	item_state = "palcomm"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_BULLET_T3, ARMOR_MODIFIER_UP_LASER_T3, ARMOR_MODIFIER_UP_DT_T2)

/obj/item/clothing/suit/armor/power_armor/t51b/bos
	name = "Brotherhood T-51b Power Armour"
	desc = "The pinnacle of pre-war technology, appropriated by the Brotherhood of Steel. Commonly worn by Head Paladins."
	icon_state = "t51bpowerarmor_bos"
	item_state = "t51bpowerarmor_bos"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/power_armor/t51b/minutemen
	name = "Brotherhood T-51b Power Armour"
	desc = "The pinnacle of pre-war technology, appropriated by the Brotherhood of Steel. Commonly worn by Head Paladins."
	icon_state = "t51bpowerarmor_minutemen"
	item_state = "t51bpowerarmor_minutemen"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/power_armor/t51b/enclave
	name = "Enclave T-51b Power Armour"
	desc = "The pinnacle of pre-war technology, appropriated by the Enclave. Commonly worn by the Enclave Armored Corp."
	icon_state = "t51bpowerarmor_enclave"
	item_state = "t51bpowerarmor_enclave"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/power_armor/excavator
	name = "excavator power armor"
	desc = "Developed by Garrahan Mining Co. in collaboration with West Tek, the Excavator-class power armor was designed to protect miners from rockfalls and airborne contaminants while increasing the speed at which they could work. "
	icon_state = "excavator"
	item_state = "excavator"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_DOWN_BULLET_T3, ARMOR_MODIFIER_DOWN_LASER_T3, ARMOR_MODIFIER_UP_ENV_T3, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/armor/power_armor/advanced
	name = "advanced power armor"
	desc = "An advanced suit of armor typically used by the Enclave.<br>It is composed of lightweight metal alloys, reinforced with ceramic castings at key stress points.<br>Additionally, like the T-51b power armor, it includes a recycling system that can convert human waste into drinkable water, and an air conditioning system for its user's comfort."
	icon_state = "advpowerarmor1"
	item_state = "advpowerarmor1"
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T2, ARMOR_MODIFIER_UP_BULLET_T2, ARMOR_MODIFIER_UP_LASER_T2, ARMOR_MODIFIER_UP_DT_T2)


//Peacekeeper armor adjust as needed
/obj/item/clothing/suit/armor/power_armor/advanced/x02
	name = "Enclave power armor"
	desc = "Upgraded pre-war power armor design used by the Enclave. It is mildly worn due to it's age and lack of maintenance after the fall of the Enclave."
	icon_state = "advanced"
	item_state = "advanced"
	salvaged_type = /obj/item/clothing/suit/armor/heavy/salvaged_pa/x02 // Oh the misery
	armor_tokens = list(ARMOR_MODIFIER_UP_MELEE_T3, ARMOR_MODIFIER_UP_BULLET_T3, ARMOR_MODIFIER_UP_LASER_T3, ARMOR_MODIFIER_UP_DT_T3)

/obj/item/clothing/suit/toggle/armor
	// body_parts_covered = CHEST|GROIN
	cold_protection = CHEST|GROIN
	min_cold_protection_temperature = ARMOR_MIN_TEMP_PROTECT
	heat_protection = CHEST|GROIN
	max_heat_protection_temperature = ARMOR_MAX_TEMP_PROTECT
	strip_delay = 60
	equip_delay_other = 40
	max_integrity = 250
	resistance_flags = NONE
	togglename = "collar"

// Toggle armor
/obj/item/clothing/suit/toggle/armored
	// body_parts_covered = CHEST|GROIN
	cold_protection = CHEST|GROIN
	min_cold_protection_temperature = ARMOR_MIN_TEMP_PROTECT
	heat_protection = CHEST|GROIN
	max_heat_protection_temperature = ARMOR_MAX_TEMP_PROTECT
	strip_delay = 60
	equip_delay_other = 40
	max_integrity = 250
	resistance_flags = NONE
	togglename = "collar"

//Biosuit complete with shoes (in the item sprite)
/obj/item/clothing/head/bio_hood
	name = "bio hood"
	icon_state = "bio"
	desc = "A hood that protects the head and face from biological contaminants."
	permeability_coefficient = 0.01
	clothing_flags = THICKMATERIAL | BLOCK_GAS_SMOKE_EFFECT
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEHAIR|HIDEFACIALHAIR|HIDEFACE
	resistance_flags = ACID_PROOF
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	slowdown = ARMOR_SLOWDOWN_LIGHT * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_LIGHT
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T4)

/obj/item/clothing/suit/bio_suit
	name = "bio suit"
	desc = "A suit that protects against biological contamination."
	icon_state = "bio"
	item_state = "bio_suit"
	w_class = WEIGHT_CLASS_BULKY
	gas_transfer_coefficient = 0.01
	permeability_coefficient = 0.01
	clothing_flags = THICKMATERIAL
	// body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT
	strip_delay = 70
	equip_delay_other = 70
	resistance_flags = ACID_PROOF
	mutantrace_variation = STYLE_DIGITIGRADE
	slowdown = ARMOR_SLOWDOWN_LIGHT * ARMOR_SLOWDOWN_GLOBAL_MULT
	armor = ARMOR_VALUE_LIGHT
	armor_tokens = list(ARMOR_MODIFIER_UP_ENV_T4)

/obj/item/clothing/suit/bio_suit/enclave
	name = "enclave envirosuit"
	desc = "An advanced white and airtight environmental suit. It seems to be equipped with a fire-resistant seal and a refitted internals system. This one looks to have been developed by the Enclave sometime after the Great War. You'd usually exclusively see this on scientists of the Enclave."
	icon_state = "envirosuit"
	item_state = "envirosuit"
	w_class = WEIGHT_CLASS_BULKY
	gas_transfer_coefficient = 0.9
	permeability_coefficient = 0.5
	clothing_flags = THICKMATERIAL
	strip_delay = 60
	equip_delay_other = 60
	flags_inv = HIDEJUMPSUIT
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE

//Standard biosuit, orange stripe
/obj/item/clothing/head/bio_hood/general
	icon_state = "bio_general"

/obj/item/clothing/suit/bio_suit/general
	icon_state = "bio_general"


//Virology biosuit, green stripe
/obj/item/clothing/head/bio_hood/virology
	icon_state = "bio_virology"

/obj/item/clothing/suit/bio_suit/virology
	icon_state = "bio_virology"


//Security biosuit, grey with red stripe across the chest
/obj/item/clothing/head/bio_hood/security
	icon_state = "bio_security"
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_ENV_T4, ARMOR_MODIFIER_UP_DT_T1)

/obj/item/clothing/suit/bio_suit/security
	icon_state = "bio_security"
	armor_tokens = list(ARMOR_MODIFIER_UP_BULLET_T1, ARMOR_MODIFIER_UP_ENV_T4, ARMOR_MODIFIER_UP_DT_T1)

//Janitor's biosuit, grey with purple arms
/obj/item/clothing/head/bio_hood/janitor
	icon_state = "bio_janitor"

/obj/item/clothing/suit/bio_suit/janitor
	icon_state = "bio_janitor"


//Scientist's biosuit, white with a pink-ish hue
/obj/item/clothing/head/bio_hood/scientist
	icon_state = "bio_scientist"

/obj/item/clothing/suit/bio_suit/scientist
	icon_state = "bio_scientist"


//CMO's biosuit, blue stripe
/obj/item/clothing/suit/bio_suit/cmo
	icon_state = "bio_cmo"

/obj/item/clothing/head/bio_hood/cmo
	icon_state = "bio_cmo"


//Plague Dr mask can be found in clothing/masks/gasmask.dm
/obj/item/clothing/suit/bio_suit/plaguedoctorsuit
	name = "plague doctor suit"
	desc = "It protected doctors from the Black Death, back then. You bet your arse it's gonna help you against viruses."
	icon_state = "plaguedoctor"
	item_state = "bio_suit"
	strip_delay = 40
	equip_delay_other = 20

/obj/item/clothing/suit/bio_suit/hazmat
	name = "hazmat suit"
	desc = "(Yellow Level A , hazmat protective suit.<br>You can see some numbers on the tag: 35 56."
	icon = 'icons/fallout/clothing/suits_utility.dmi'
	mob_overlay_icon = 'icons/fallout/onmob/clothes/suit_utility.dmi'
	icon_state = "hazmat"
	item_state = "hazmat"

/obj/item/clothing/head/bio_hood/hazmat
	name = "hazmat hood"
	desc = "My star, my perfect silence."
	icon = 'icons/fallout/clothing/hats.dmi'
	icon_state = "hazmat"
	item_state = "hazmat_helmet"
