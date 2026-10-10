/// Grants bare-handed combat-mode users a temporary "fists" item in their active hand so the (entirely item-driven)
/// Power Attack system works unarmed too. The fist is a HAND_ITEM/ABSTRACT/DROPDEL pseudo-item - see can_put_in_hand()
/// in code/modules/mob/inventory.dm for how a real item picked up over it displaces and deletes it automatically.
/datum/component/unarmed_power_attack
	dupe_mode = COMPONENT_DUPE_UNIQUE

/datum/component/unarmed_power_attack/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, COMSIG_LIVING_COMBAT_ENABLED, PROC_REF(on_combat_enabled))
	RegisterSignal(parent, COMSIG_LIVING_COMBAT_DISABLED, PROC_REF(on_combat_disabled))
	RegisterSignal(parent, COMSIG_MOB_SWAP_HANDS, PROC_REF(on_swap_hands))

/datum/component/unarmed_power_attack/proc/on_combat_enabled(mob/living/source)
	SIGNAL_HANDLER
	equip_fists(source)

/datum/component/unarmed_power_attack/proc/on_combat_disabled(mob/living/source)
	SIGNAL_HANDLER
	remove_fists(source)

/datum/component/unarmed_power_attack/proc/on_swap_hands(mob/living/source)
	SIGNAL_HANDLER
	if(SEND_SIGNAL(source, COMSIG_COMBAT_MODE_CHECK, COMBAT_MODE_ACTIVE))
		equip_fists(source)

/datum/component/unarmed_power_attack/proc/equip_fists(mob/living/source)
	if(source.get_active_held_item())
		return
	// A worn powerfist-style glove throws its own punch via UnarmedAttack() directly (see other_mobs.dm) - no synthetic stand-in needed, and it has no power_attacks of its own to arm anyway.
	var/obj/item/melee/unarmed/worn_glove_weapon
	if(ishuman(source))
		var/mob/living/carbon/human/H = source
		if(H.gloves?.glove_weapon)
			return
		if(istype(H.gloves, /obj/item/melee/unarmed))
			worn_glove_weapon = H.gloves
	var/obj/item/melee/fists/F = new(source)
	if(ishuman(source))
		var/mob/living/carbon/human/H = source
		F.force = H.dna.species.punchdamagehigh
		F.attack_verb = list(H.dna.species.attack_verb)
	// A worn glove weapon (brass knuckles, tiger claws, etc) should arm the same Power Attacks it would held in a hand -
	// copy the stats their can_select() gates and payoffs actually check, instead of leaving the stand-in as plain blunt fists.
	if(worn_glove_weapon)
		F.sharpness = worn_glove_weapon.sharpness
		F.armour_penetration = worn_glove_weapon.armour_penetration
		F.wound_bonus = worn_glove_weapon.wound_bonus
		F.bare_wound_bonus = worn_glove_weapon.bare_wound_bonus
		F.w_class = worn_glove_weapon.w_class
	source.put_in_active_hand(F, forced = TRUE)

/datum/component/unarmed_power_attack/proc/remove_fists(mob/living/source)
	for(var/obj/item/melee/fists/F in source.held_items)
		qdel(F)
