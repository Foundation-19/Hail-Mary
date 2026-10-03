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
	if(ishuman(source))
		var/mob/living/carbon/human/H = source
		if(H.gloves?.glove_weapon)
			return
	var/obj/item/melee/fists/F = new(source)
	if(ishuman(source))
		var/mob/living/carbon/human/H = source
		F.force = H.dna.species.punchdamagehigh
		F.attack_verb = list(H.dna.species.attack_verb)
	source.put_in_active_hand(F, forced = TRUE)

/datum/component/unarmed_power_attack/proc/remove_fists(mob/living/source)
	for(var/obj/item/melee/fists/F in source.held_items)
		qdel(F)
