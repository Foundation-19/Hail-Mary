//Brain Traumas are the new actual brain damage. Brain damage itself acts as a way to acquire traumas: every time brain damage is dealt, there's a chance of receiving a trauma.
//This chance gets higher the higher the mob's brainloss is. Removing traumas is a separate thing from removing brain damage: you can get restored to full brain operativity,
// but keep the quirks, until repaired by neurine, surgery, lobotomy or magic; depending on the resilience
// of the trauma.

/datum/brain_trauma
	var/name = "Brain Trauma"
	var/desc = "A trauma caused by brain damage, which causes issues to the patient."
	var/scan_desc = "generic brain trauma" //description when detected by a health scanner
	var/mob/living/carbon/owner //the poor bastard
	var/obj/item/organ/brain/brain //the poor bastard's brain
	var/gain_text = span_notice("You feel traumatized.")
	var/lose_text = span_notice("You no longer feel traumatized.")
	var/can_gain = TRUE
	var/random_gain = FALSE //can this be gained through random traumas?
	var/resilience = TRAUMA_RESILIENCE_BASIC //how hard is this to cure?
	var/clonable = TRUE // will this transfer if the brain is cloned? - currently has no effect

/datum/brain_trauma/Destroy()
	if(brain && brain.traumas)
		brain.traumas -= src
	if(owner)
		on_lose()
	brain = null
	owner = null
	return ..()

TYPE_PROC_REF(/datum/brain_trauma, on_clone)()
	if(clonable)
		return new type

//Called on life ticks
TYPE_PROC_REF(/datum/brain_trauma, on_life)()
	return

//Called on death
TYPE_PROC_REF(/datum/brain_trauma, on_death)()
	return

//Called when given to a mob
TYPE_PROC_REF(/datum/brain_trauma, on_gain)()
	to_chat(owner, gain_text)
	RegisterSignal(owner, COMSIG_MOB_SAY, PROC_REF(handle_speech))
	RegisterSignal(owner, COMSIG_MOVABLE_HEAR, PROC_REF(handle_hearing))

//Called when removed from a mob
TYPE_PROC_REF(/datum/brain_trauma, on_lose)(silent)
	if(!silent)
		to_chat(owner, lose_text)
	UnregisterSignal(owner, COMSIG_MOB_SAY)
	UnregisterSignal(owner, COMSIG_MOVABLE_HEAR)

//Called when hearing a spoken message
TYPE_PROC_REF(/datum/brain_trauma, handle_hearing)(datum/source, list/hearing_args)
	UnregisterSignal(owner, COMSIG_MOVABLE_HEAR)

//Called when speaking
TYPE_PROC_REF(/datum/brain_trauma, handle_speech)(datum/source, list/speech_args)
	UnregisterSignal(owner, COMSIG_MOB_SAY)


//Called when hugging. expand into generally interacting, where future coders could switch the intent?
TYPE_PROC_REF(/datum/brain_trauma, on_hug)(mob/living/hugger, mob/living/hugged)
	return
