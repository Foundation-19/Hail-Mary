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
	mob_overlay_icon = 'icons/mob/modular/power_armor.dmi'
	icon_state = "paframe"
	item_state = "paframe"
	w_class = WEIGHT_CLASS_HUGE
	slowdown = 0.4 //+0.1 from helmet = total 0.5
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	pocket_storage_component_path = null
	item_flags = SLOWS_WHILE_IN_HAND
	equip_delay_self = 50
	equip_delay_other = 60
	strip_delay = 200
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	actions_types = list(/datum/action/item_action/toggle)
	var/requires_training = TRUE
	flags_inv = HIDEJUMPSUIT|HIDENECK|HIDEEYES|HIDEEARS|HIDEFACE|HIDEMASK|HIDEGLOVES|HIDESHOES
	var/traits = list(TRAIT_IRONFIST, TRAIT_STUNIMMUNE, TRAIT_PUSHIMMUNE)
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
	AddComponent(/datum/component/spraycan_paintable)

/obj/item/clothing/suit/modular/mob_can_equip(mob/user, mob/equipper, slot, disable_warning = 1)
	var/mob/living/carbon/human/H = user
	if(src == H.wear_suit) //Suit is already equipped
		return ..()
	if (!HAS_TRAIT(H, TRAIT_PA_WEAR) && slot == SLOT_WEAR_SUIT && requires_training)
		to_chat(user, span_warning("You don't have the proper training to operate the power armor!"))
		return 0
	if(slot == SLOT_WEAR_SUIT)
		ADD_TRAIT(user, TRAIT_STUNIMMUNE,	"stun_immunity")
		ADD_TRAIT(user, TRAIT_PUSHIMMUNE,	"push_immunity")
		ADD_TRAIT(user, TRAIT_IRONFIST,	"iron_fist")
		ADD_TRAIT(user, SPREAD_CONTROL, "PA_spreadcontrol")
		return ..()
	return

/obj/item/clothing/suit/modular/dropped(mob/user)
	REMOVE_TRAIT(user, TRAIT_STUNIMMUNE,	"stun_immunity")
	REMOVE_TRAIT(user, TRAIT_PUSHIMMUNE,	"push_immunity")
	REMOVE_TRAIT(user, TRAIT_IRONFIST,	"iron_fist")
	REMOVE_TRAIT(user, SPREAD_CONTROL, "PA_spreadcontrol")
	return ..()

/obj/item/clothing/suit/modular/Initialize()
	. = ..()
	AddComponent(/datum/component/attachment_handler, attachments_by_slot, attachments_allowed, attachment_offsets, starting_attachments, overlays = attachment_overlays)
	update_icon()

/obj/item/clothing/suit/modular/equipped(mob/user, slot)
	. = ..()
	for(var/key in attachments_by_slot)
		if(!attachments_by_slot[key])
			continue
		var/obj/item/armor_module/module = attachments_by_slot[key]
		if(!CHECK_BITFIELD(module.flags_attach_features, ATTACH_ACTIVATION))
			continue
		LAZYADD(module.actions_types, /datum/action/item_action/toggle)
		var/datum/action/item_action/toggle/new_action = new(module)
		new_action.give_action(user)

/obj/item/clothing/suit/modular/proc/unequipped(mob/unequipper, slot)
    . = ..()
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
		item_state = initial(mob_overlay_icon) + "_[current_variant]"
	update_clothing_icon()
	update_onmob_icon()

/obj/item/clothing/suit/modular/worn_overlays(isinhands, icon_file, used_state, style_flags)
    . = ..()
    if(!isinhands)
        for(var/key in attachments_by_slot)
            if(!attachments_by_slot[key])
                continue
            var/obj/item/armor_module/module = attachments_by_slot[key]
            . += mutable_appearance(module.mob_overlay_icon, module.icon_state + "_a")
