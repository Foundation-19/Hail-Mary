/**
	Modular armor

	Modular armor consists of a a suit and helmet.
	The suit is able to have a storage, module, and 3x armor attachments (chest, arms, and legs)
	Helmets only have a single module slot.


*/
/obj/item/clothing/suit/modular
	name = "Power Armour Frame"
	desc = "The frame of a mechanised infantry support suit, better known as Power Armour. Fits Power Armour parts and modules."
	icon = 'icons/mob/modular/power_armor.dmi'
	icon_state = "paframe"
	item_state = "paframe"
	w_class = WEIGHT_CLASS_HUGE
	slowdown = 0.4 //+0.1 from helmet = total 0.5
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	item_flags = SLOWS_WHILE_IN_HAND
	equip_delay_self = 50
	equip_delay_other = 60
	strip_delay = 200
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	var/requires_training = TRUE
	flags_inv = HIDEJUMPSUIT|HIDENECK|HIDEEYES|HIDEEARS|HIDEFACE|HIDEMASK|HIDEGLOVES|HIDESHOES
	var/traits = list(TRAIT_IRONFIST, TRAIT_STUNIMMUNE, TRAIT_PUSHIMMUNE)
	var/deflect_damage = 10
	var/deflection_chance = 50 //Chance for the power armor to redirect a blocked projectile
	var/armor_block_threshold = 0.3 //projectiles below this will deflect
	var/melee_block_threshold = 30
	var/dmg_block_threshold = 42
	var/armor_block_chance = 25 //Chance for the power armor to block a low penetration projectile

/obj/item/clothing/suit/modular/Initialize()
	. = ..()
	AddComponent(/datum/component/spraycan_paintable)

/obj/item/clothing/suit/armor/power_armor/mob_can_equip(mob/user, mob/equipper, slot, disable_warning = 1)
	var/mob/living/carbon/human/H = user
	if(src == H.wear_suit) //Suit is already equipped
		return ..()
	if (!HAS_TRAIT(H, TRAIT_PA_WEAR) && slot == SLOT_WEAR_SUIT && requires_training)
		to_chat(user, span_warning("You don't have the proper training to operate the power armor!"))
		return 0
	if(slot == SLOT_WEAR_SUIT)
		ADD_TRAIT(user, TRAIT_STUNIMMUNE,	"stun_immunity")
		ADD_TRAIT(user, TRAIT_PUSHIMMUNE,	"push_immunity")
		return ..()
	return

/obj/item/clothing/suit/armor/power_armor/dropped(mob/user)
	REMOVE_TRAIT(user, TRAIT_STUNIMMUNE,	"stun_immunity")
	REMOVE_TRAIT(user, TRAIT_PUSHIMMUNE,	"push_immunity")
	return ..()

	actions_types = list(/datum/action/item_action/toggle)
	///Assoc list of available slots.
	var/list/attachments_by_slot = list(
		ATTACHMENT_SLOT_CHESTPLATE,
		ATTACHMENT_SLOT_SHOULDER,
		ATTACHMENT_SLOT_KNEE,
		ATTACHMENT_SLOT_MODULE,
	)
	///Typepath list of allowed attachment types.
	var/list/attachments_allowed = list(
		/obj/item/armor_module/armor/chest/t45d,
		/obj/item/armor_module/armor/leg/t45d,
		/obj/item/armor_module/armor/arms/t45d,

		/obj/item/armor_module/armor/chest/t51,
		/obj/item/armor_module/armor/leg/t51,
		/obj/item/armor_module/armor/arms/t51,

		/obj/item/armor_module/armor/chest/apa,
		/obj/item/armor_module/armor/leg/apa,
		/obj/item/armor_module/armor/arms/apa,

	)
	///Pixel offsets for specific attachment slots. Is not used currently.
	var/list/attachment_offsets = list()
	///List of attachment types that is attached to the object on initialize.
	var/list/starting_attachments = list()
	///List of the attachment overlays.
	var/list/attachment_overlays = list()
	///List of icon_state suffixes for armor varients.
	var/list/icon_state_variants = list()
	///Current varient selected.
	var/current_variant

/obj/item/clothing/suit/modular/Initialize()
	. = ..()
	AddComponent(/datum/component/attachment_handler, attachments_by_slot, attachments_allowed, attachment_offsets, starting_attachments, null, null, null, attachment_overlays)
	update_icon()

/obj/item/clothing/suit/modular/equipped(mob/user, slot)
	. = ..()
	var/obj/structure/table/table = locate() in get_turf(/obj/item/clothing/suit/armor/power_armor)
	if(isnull(table))
		to_chat(user, "You cannot modify the Power Armour without it being placed on a table or similar surface.")
		return
	for(var/key in attachments_by_slot)
		if(!attachments_by_slot[key])
			continue
		var/obj/item/armor_module/module = attachments_by_slot[key]
		if(!CHECK_BITFIELD(module.flags_attach_features, ATTACH_ACTIVATION))
			continue
		LAZYADD(module.actions_types, /datum/action/item_action/toggle)
		var/datum/action/item_action/toggle/new_action = new(module)
		new_action.give_action(user)

/obj/item/clothing/suit/modular/unequipped(mob/unequipper, slot)
	. = ..()
	var/obj/structure/table/table = locate() in get_turf(/obj/item/clothing/suit/armor/power_armor)
	if(isnull(table))
		to_chat(user, "You cannot modify the Power Armour without it being placed on a table or similar surface.")
		return
	for(var/key in attachments_by_slot)
		if(!attachments_by_slot[key])
			continue
		var/obj/item/armor_module/module = attachments_by_slot[key]
		if(!CHECK_BITFIELD(module.flags_attach_features, ATTACH_ACTIVATION))
			continue
		LAZYREMOVE(module.actions_types, /datum/action/item_action/toggle)
		var/datum/action/item_action/toggle/old_action = locate(/datum/action/item_action/toggle) in module.actions
		old_action.remove_action(unequipper)

/obj/item/clothing/suit/modular/update_icon()
	. = ..()
	if(current_variant)
		icon_state = initial(icon_state) + "_[current_variant]"
		item_state = initial(item_state) + "_[current_variant]"
	update_clothing_icon()
		
/obj/item/clothing/suit/armor/power_armor/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	. = ..()
	if(check_armor_penetration(object) <= src.armor_block_threshold && (attack_type == ATTACK_TYPE_PROJECTILE) && (def_zone in protected_zones))
		if(prob(armor_block_chance))
			var/ratio = rand(0,100)
			if(ratio <= deflection_chance)
				block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_DEFLECT
				return BLOCK_SHOULD_REDIRECT | BLOCK_REDIRECTED | BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL
			if(ismob(loc))
				to_chat(loc, span_warning("Your power armor absorbs the projectile's impact!"))
			block_return[BLOCK_RETURN_SET_DAMAGE_TO] = 0
			return BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL
	return


/** Core helmet module */
/obj/item/clothing/head/modular
	cold_protection = HEAD
	heat_protection = HEAD
	ispowerarmor = 1 //TRUE
	strip_delay = 200
	equip_delay_self = 20
	slowdown = 0.05
	flags_inv = HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR|HIDEMASK|HIDEJUMPSUIT
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	clothing_flags = THICKMATERIAL
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	item_flags = SLOWS_WHILE_IN_HAND
	flash_protect = 2
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""
	speechspan = SPAN_ROBOT //makes you sound like a robot
	max_heat_protection_temperature = FIRE_HELM_MAX_TEMP_PROTECT
	cold_protection = HEAD
	min_cold_protection_temperature = FIRE_HELM_MIN_TEMP_PROTECT
	light_system = MOVABLE_LIGHT_DIRECTIONAL
	light_range = 5
	light_on = FALSE
	salvage_loot = list(/obj/item/stack/crafting/armor_plate = 10)
	salvage_tool_behavior = TOOL_WELDER
	/// Projectiles below this damage will get deflected
	var/deflect_damage = 18
	/// If TRUE - it requires PA training trait to be worn
	var/requires_training = TRUE
	/// If TRUE - the suit will give its user specific traits when worn
	var/powered = TRUE
	/// Path of item that this helmet gets salvaged into
	var/obj/item/salvaged_type = null
	/// Used to track next tool required to salvage the suit
	var/salvage_step = 0
	armor = ARMOR_VALUE_PA

/obj/item/clothing/head/helmet/f13/power_armor/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)

/obj/item/clothing/head/helmet/f13/power_armor/mob_can_equip(mob/user, mob/equipper, slot, disable_warning = 1)
	var/mob/living/carbon/human/H = user
	if(src == H.head) //Suit is already equipped
		return ..()
	if (!HAS_TRAIT(H, TRAIT_PA_WEAR) && slot == SLOT_HEAD && requires_training)
		to_chat(user, span_warning("You don't have the proper training to operate the power armor!"))
		return 0
	if(slot == SLOT_HEAD)
		return ..()
	return

/obj/item/clothing/head/helmet/f13/power_armor/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if((attack_type == ATTACK_TYPE_PROJECTILE) && (def_zone in protected_zones))
		if(prob(70) && (damage < deflect_damage))
			block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_DEFLECT
			return BLOCK_SHOULD_REDIRECT | BLOCK_REDIRECTED | BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL
	return ..()

/obj/item/clothing/head/modular/t45d
	name = "T45d Helmet"
	desc = "A helmet of a t45d Power Armour."
	icon_state = "t45d_helmet"
	armor = list("melee" = 50, "bullet" = 50, "laser" = 50, "energy" = 50, "bomb" = 50, "bio" = 50, "rad" = 50, "fire" = 50, "acid" = 50)

/obj/item/clothing/head/modular/t51
	name = "T51 Helmet"
	desc = "A helmet of a T51 Power Armour."
	icon_state = "t51_helmet"

/obj/item/clothing/head/modular/apa
	name = "X-01 Helmet"
	desc = "An Advanced Power Armour helmet."
	icon_state = "apa"
