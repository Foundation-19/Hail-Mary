/datum/component/souldeath
	var/mob/living/wearer
	var/equip_slot
	var/signal = FALSE

/datum/component/souldeath/Initialize()
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, PROC_REF(equip))
	RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(unequip))

TYPE_PROC_REF(/datum/component/souldeath, equip)(datum/source, mob/living/equipper, slot)
	if(!slot || equip_slot == slot)
		wearer = equipper
		RegisterSignal(wearer, COMSIG_MOB_DEATH, PROC_REF(die), TRUE)
		signal = TRUE
	else
		if(signal)
			UnregisterSignal(wearer, COMSIG_MOB_DEATH)
			signal = FALSE
		return

TYPE_PROC_REF(/datum/component/souldeath, unequip)()
	UnregisterSignal(wearer, COMSIG_MOB_DEATH)
	wearer = null
	signal = FALSE

TYPE_PROC_REF(/datum/component/souldeath, die)()
	if(!wearer)
		return //idfk
	new/obj/effect/temp_visual/souldeath(wearer.loc, wearer)
	playsound(wearer, 'sound/misc/souldeath.ogg', 100, FALSE)

/datum/component/souldeath/neck
	equip_slot = SLOT_NECK
