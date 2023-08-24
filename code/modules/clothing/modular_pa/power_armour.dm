/**
	Modular armor

	Modular armor consists of a a suit and helmet.
	The suit is able to have a storage, module, and 3x armor attachments (chest, arms, and legs)
	Helmets only have a single module slot.


*/
/obj/item/clothing/suit/modular
	name = "Power Armour Frame"
	desc = "The frame of a mechanised infantry support suit, better known as Power Armour. Fits Power Armour parts and modules."
	icon = 'icons/mob/modular/modular_armor.dmi'
	icon_state = "paframe"
	item_state = "paframe"
	flags_atom = CONDUCT
	w_class = WEIGHT_CLASS_HUGE
	slowdown = 0.4 //+0.1 from helmet = total 0.5
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	item_flags = SLOWS_WHILE_IN_HAND
	clothing_flags = THICKMATERIALPORT
	equip_delay_self = 50
	equip_delay_other = 60
	strip_delay = 200
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	var/requires_training = TRUE
	flags_inv = HIDEJUMPSUIT|HIDENECK|HIDEEYES|HIDEEARS|HIDEFACE|HIDEMASK|HIDEGLOVES|HIDESHOES
	var/traits = list(TRAIT_IRONFIST, TRAIT_STUNIMMUNE, TRAIT_PUSHIMMUNE)
	var/deflect_damage = 10

/obj/item/clothing/suit/modular/Initialize()
	. = ..()
	AddComponent(/datum/component/spraycan_paintable)

/obj/item/clothing/suit/modular/mob_can_equip(mob/user, mob/equipper, slot, disable_warning = 1)
	. = ..()
	if(!.)
		return

	if(!ishuman(user))
		return FALSE

	var/mob/living/carbon/human/H = user
	if (!H.has_trait(TRAIT_PA_WEAR) && requires_training)
		to_chat(user, "<span class='warning'>You don't have the proper training to operate the power armor!</span>")
		return FALSE

/obj/item/clothing/suit/modular/equipped(mob/user, slot)
	. = ..()
	var/mob/living/carbon/human/H = user
	for(var/trait in traits)
		H.add_trait(trait, src)

/obj/item/clothing/suit/modular/dropped(mob/user)
	var/mob/living/carbon/human/H = user
	for(var/trait in traits)
		H.remove_trait(trait, src)
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
		/obj/item/armor_module/armor/chest/t45b,
		/obj/item/armor_module/armor/legs/t45b,
		/obj/item/armor_module/armor/arms/t45b,

		/obj/item/armor_module/armor/chest/t51,
		/obj/item/armor_module/armor/legs/t51,
		/obj/item/armor_module/armor/arms/t51,

		/obj/item/armor_module/armor/chest/apa,
		/obj/item/armor_module/armor/legs/apa,
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
	var/obj/structure/table/table = locate() in get_turf(frame)
	if(isnull(table))
  		to_chat(user, "You cannot modify the Power Armour without it being placed on a table or similar surface..")
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
	var/obj/structure/table/table = locate() in get_turf(frame)
	if(isnull(table))
  		to_chat(user, "You cannot modify the Power Armour without it being placed on a table or similar surface..")
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

/obj/item/clothing/suit/modular/on_pocket_insertion()
	. = ..()
	update_icon()

/obj/item/clothing/suit/modular/on_pocket_removal()
	. = ..()
	update_icon()

/obj/item/clothing/suit/modular/apply_custom(image/standing)
	for(var/key in attachment_overlays)
		var/image/overlay = attachment_overlays[key]
		if(!overlay)
			continue
		standing.overlays += overlay
	if(!attachments_by_slot[ATTACHMENT_SLOT_STORAGE] || !istype(attachments_by_slot[ATTACHMENT_SLOT_STORAGE], /obj/item/armor_module/storage))
		return standing
	var/obj/item/armor_module/storage/storage_module = attachments_by_slot[ATTACHMENT_SLOT_STORAGE]
	if(!storage_module.show_storage)
		return standing
	for(var/obj/item/stored AS in storage_module.storage.contents)
		standing.overlays += image(storage_module.show_storage_icon, icon_state = initial(stored.icon_state))
	return standing

/obj/item/clothing/suit/modular/attack_self(mob/user)
	. = ..()
	if(.)
		return
	if(!isturf(user.loc))
		to_chat(user, span_warning("You cannot turn the light on while in [user.loc]."))
		return
	if(TIMER_COOLDOWN_CHECK(src, COOLDOWN_ARMOR_LIGHT) || !ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(H.wear_suit != src)
		return
	turn_light(user, !light_on)
	return TRUE

/obj/item/clothing/suit/modular/MouseDrop(over_object, src_location, over_location)
	if(!attachments_by_slot[ATTACHMENT_SLOT_STORAGE])
		return ..()
	if(!istype(attachments_by_slot[ATTACHMENT_SLOT_STORAGE], /obj/item/armor_module/storage))
		return ..()
	var/obj/item/armor_module/storage/armor_storage = attachments_by_slot[ATTACHMENT_SLOT_STORAGE]
	if(armor_storage.storage.handle_mousedrop(usr, over_object))
		return ..()
		
/obj/item/clothing/modular/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(check_armor_penetration(object) <= 0.15 && (attack_type == ATTACK_TYPE_PROJECTILE) && (def_zone in protected_zones))
		if(prob(armor_block_chance))
			var/ratio = rand(0,100)
			if(ratio <= deflection_chance)
				block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_DEFLECT
				return BLOCK_SHOULD_REDIRECT | BLOCK_REDIRECTED | BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL
			if(ismob(loc))
				to_chat(loc, span_warning("Your power armor absorbs the projectile's impact!"))
			block_return[BLOCK_RETURN_SET_DAMAGE_TO] = 1
			return BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL
	return ..()

/** Core helmet module */
/obj/item/clothing/head/modular
	name = "Power Armour Helmet"
	desc = "Usually paired with the Jaeger Combat Exoskeleton. Can mount utility functions on the helmet hard points."
	
	strip_delay = 200
	equip_delay_self = 20
	slowdown = 0.1
	flags_inv = HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR|HIDEMASK|HIDEJUMPSUIT
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	clothing_flags = THICKMATERIALPORT
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	item_flags = SLOWS_WHILE_IN_HAND
	flash_protect = 2
	speechspan = SPAN_ROBOT //makes you sound like a robot
	lighting_alpha = LIGHTING_PLANE_ALPHA_LOWLIGHT_VISION
	var/requires_training = TRUE
	light_range = 4 //luminosity when the light is on
	light_on = FALSE
	var/on = FALSE
	light_color = LIGHT_COLOR_YELLOW
	light_system = MOVABLE_LIGHT_DIRECTIONAL
	actions_types = list(/datum/action/item_action/toggle_light)

	///Current PA Health
	var/pa_health = 1000

/obj/item/clothing/head/helmet/f13/power_armor/Initialize()
	. = ..()
	AddComponent(/datum/component/spraycan_paintable)
	START_PROCESSING(SSobj, src)

/obj/item/clothing/head/helmet/f13/power_armor/attack_self(mob/user)
	on = !on
//	icon_state = "[initial(icon_state)][on]"
	user.update_inv_head()	//so our mob-overlays update

	set_light_on(on)
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtonIcon()

/obj/item/clothing/head/helmet/f13/power_armor/mob_can_equip(mob/user, mob/equipper, slot, disable_warning = 1)
	var/mob/living/carbon/human/H = user
	if(src == H.head) //Suit is already equipped
		return ..()
	if (!H.has_trait(TRAIT_PA_WEAR) && !istype(src, /obj/item/clothing/head/helmet/f13/power_armor/t45b) && slot == SLOT_HEAD && requires_training)
		to_chat(user, "<span class='warning'>You don't have the proper training to operate the power armor!</span>")
		return 0
	if(slot == SLOT_HEAD)
		return ..()
	return

/obj/item/clothing/head/modular/t45b
	name = "T45b Helmet"
	desc = "A helmet of a T45b Power Armour."
	icon_state = "t45b_helmet"
	armor = list("melee" = 50, "bullet" = 50, "laser" = 50, "energy" = 50, "bomb" = 50, "bio" = 50, "rad" = 50, "fire" = 50, "acid" = 50)

/obj/item/clothing/head/modular/t51
	name = "T51 Helmet
	desc = "A helmet of a T51 Power Armour."
	icon_state = "t51_helmet"

/obj/item/clothing/head/modular/apa
	name = "X-01 Helmet"
	desc = "An Advanced Power Armour helmet."
	icon_state = "apa"
