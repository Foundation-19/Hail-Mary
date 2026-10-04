//Fallout-style "Wasteland Traits" - free roundstart picks (see MAX_TRAITS) that each bundle ONE
//boon together with ONE burden, same as real Fallout 1/2/NV Traits. Unlike the point-buy quirks
//in good.dm/negative.dm/neutral.dm, these never cost or refund Trait Points (is_trait = TRUE,
//value is always 0) - see GetQuirkBalance()/GetTraitCount() in preferences.dm.
//Each Trait here reuses the exact mechanical hooks (mob_trait defines, on_spawn/on_process logic)
//of two now-retired standalone quirks, which have been commented out in good.dm/negative.dm so
//their effects can no longer be cherry-picked on their own.

/datum/quirk/trait_small_frame
	name = "Small Frame"
	desc = "You're built small and light. You take no damage from falls, but your bones are far more brittle and break easily."
	value = 0
	is_trait = TRUE
	gain_text = span_notice("You feel light on your feet, but a little more breakable.")
	lose_text = span_danger("You feel like your old self again.")
	medical_record_text = "Patient has an abnormally light frame: resistant to falls, but prone to fractures."

/datum/quirk/trait_small_frame/add()
	var/mob/living/carbon/human/H = quirk_holder
	ADD_TRAIT(H, TRAIT_FREEFALLER, "Small Frame")
	ADD_TRAIT(H, TRAIT_GLASS_BONES, "Small Frame")

/datum/quirk/trait_small_frame/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(!QDELETED(H))
		REMOVE_TRAIT(H, TRAIT_FREEFALLER, "Small Frame")
		REMOVE_TRAIT(H, TRAIT_GLASS_BONES, "Small Frame")

/datum/quirk/trait_heavy_handed
	name = "Heavy Handed"
	desc = "You hit like a deathclaw with your bare hands, but all that raw power comes at the cost of fine motor control - your aim with guns suffers for it."
	value = 0
	is_trait = TRUE
	gain_text = span_notice("Your fists feel furious, but your hands feel clumsy around triggers.")
	lose_text = span_danger("Your fists feel calm again.")
	medical_record_text = "Patient has powerful hands but a pronounced tremor when handling fine machinery."

/datum/quirk/trait_heavy_handed/add()
	var/mob/living/carbon/human/H = quirk_holder
	ADD_TRAIT(H, TRAIT_IRONFIST, "Heavy Handed")
	ADD_TRAIT(H, TRAIT_POOR_AIM, "Heavy Handed")

/datum/quirk/trait_heavy_handed/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(!QDELETED(H))
		REMOVE_TRAIT(H, TRAIT_IRONFIST, "Heavy Handed")
		REMOVE_TRAIT(H, TRAIT_POOR_AIM, "Heavy Handed")

/datum/quirk/trait_heavy_handed/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	H.dna.species.punchdamagelow = IRON_FIST_PUNCH_DAMAGE_LOW
	H.dna.species.punchdamagehigh = IRON_FIST_PUNCH_DAMAGE_MAX

/datum/quirk/trait_sure_and_steady
	name = "Sure and Steady"
	desc = "You move with a slow, deliberate gait that never makes a sound - you'll never be quick on your feet, but you'll never be heard either."
	value = 0
	is_trait = TRUE
	gain_text = span_notice("Your footsteps fade away, though your pace slows to a crawl.")
	lose_text = span_danger("You find yourself surprised by the sound of your own footsteps.")
	medical_record_text = "Patient moves with unusual quiet, at a significant cost to overall pace."

/datum/quirk/trait_sure_and_steady/add()
	var/mob/living/carbon/human/H = quirk_holder
	ADD_TRAIT(H, TRAIT_SILENT_STEP, "Sure and Steady")
	ADD_TRAIT(H, TRAIT_SLOWAF, "Sure and Steady")

/datum/quirk/trait_sure_and_steady/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(!QDELETED(H))
		REMOVE_TRAIT(H, TRAIT_SILENT_STEP, "Sure and Steady")
		REMOVE_TRAIT(H, TRAIT_SLOWAF, "Sure and Steady")

/datum/quirk/trait_night_owl
	name = "Night Owl"
	desc = "You've adapted to life after dark - you see slightly further in full darkness, but bright light irritates your eyes, skin, and hair."
	value = 0
	is_trait = TRUE
	gain_text = span_notice("The shadows seem a little less dark, but the light feels a little too bright.")
	lose_text = span_danger("Day and night feel the same to you again.")
	medical_record_text = "Patient demonstrates unusually good night vision alongside acute photosensitivity."

/datum/quirk/trait_night_owl/add()
	var/mob/living/carbon/human/H = quirk_holder
	ADD_TRAIT(H, TRAIT_NIGHT_VISION, "Night Owl")

/datum/quirk/trait_night_owl/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(!QDELETED(H))
		REMOVE_TRAIT(H, TRAIT_NIGHT_VISION, "Night Owl")
	SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, "brightlight")

/datum/quirk/trait_night_owl/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	H.update_sight()

/datum/quirk/trait_night_owl/on_process()
	var/turf/T = get_turf(quirk_holder)
	var/lums = T.get_lumcount()
	if(lums >= 0.8)
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "brightlight", /datum/mood_event/brightlight)
	else
		SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, "brightlight")

/datum/quirk/trait_iron_liver
	name = "Iron Liver"
	desc = "Years of rotgut moonshine have hardened your liver against alcohol - but that same resilience makes your body violently reject most other chems."
	value = 0
	is_trait = TRUE
	gain_text = span_notice("You feel like you could drink a whole keg, though your stomach turns at the thought of anything else.")
	lose_text = span_danger("Your tolerance feels... average again.")
	medical_record_text = "Patient shows a high tolerance for alcohol but an unusual rejection of other chemical compounds."

/datum/quirk/trait_iron_liver/add()
	var/mob/living/carbon/human/H = quirk_holder
	ADD_TRAIT(H, TRAIT_ALCOHOL_TOLERANCE, "Iron Liver")
	ADD_TRAIT(H, TRAIT_NODRUGS, "Iron Liver")

/datum/quirk/trait_iron_liver/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(!QDELETED(H))
		REMOVE_TRAIT(H, TRAIT_ALCOHOL_TOLERANCE, "Iron Liver")
		REMOVE_TRAIT(H, TRAIT_NODRUGS, "Iron Liver")

/datum/quirk/trait_overwhelmed_empath
	name = "Overwhelmed Empath"
	desc = "You read people's moods and injuries at a glance - but having their emotions wash over you leaves you anxious and prone to stuttering or freezing up around others."
	value = 0
	is_trait = TRUE
	mood_quirk = FALSE
	gain_text = span_notice("You feel in tune with those around you, though it's a little overwhelming.")
	lose_text = span_danger("You feel isolated from others.")
	medical_record_text = "Patient is highly perceptive of social and emotional cues, to the point of social anxiety."
	var/dumb_thing = TRUE

/datum/quirk/trait_overwhelmed_empath/add()
	var/mob/living/carbon/human/H = quirk_holder
	ADD_TRAIT(H, TRAIT_EMPATH, "Overwhelmed Empath")
	RegisterSignal(quirk_holder, COMSIG_MOB_EYECONTACT, PROC_REF(eye_contact))

/datum/quirk/trait_overwhelmed_empath/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(!QDELETED(H))
		REMOVE_TRAIT(H, TRAIT_EMPATH, "Overwhelmed Empath")
	if(!quirk_holder)
		return
	UnregisterSignal(quirk_holder, COMSIG_MOB_EYECONTACT)

/datum/quirk/trait_overwhelmed_empath/on_process()
	var/nearby_people = 0
	for(var/mob/living/carbon/human/H in oview(4, quirk_holder))
		if(H.client)
			nearby_people++
	var/mob/living/carbon/human/H = quirk_holder
	if(!H.stuttering && prob(min(1 + nearby_people, 8)))
		H.stuttering = max(3, H.stuttering)
	else if(prob(0.5) && dumb_thing)
		to_chat(H, span_userdanger("You think of a dumb thing you said a long time ago and scream internally."))
		dumb_thing = FALSE //only once per life

/datum/quirk/trait_overwhelmed_empath/proc/eye_contact(datum/source, mob/living/other_mob, triggering_examiner)
	if(prob(75))
		return
	var/msg
	if(triggering_examiner)
		msg = "You make eye contact with [other_mob], "
	else
		msg = "[other_mob] is staring at you, "

	switch(rand(1,3))
		if(1)
			quirk_holder.Jitter(10)
			msg += "causing you to start fidgeting!"
		if(2)
			quirk_holder.stuttering = max(3, quirk_holder.stuttering)
			msg += "causing you to start stuttering!"
		if(3)
			quirk_holder.Stun(2 SECONDS)
			msg += "causing you to freeze up!"

	SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "anxiety_eyecontact", /datum/mood_event/anxiety_eyecontact)
	addtimer(CALLBACK(GLOBAL_PROC,GLOBAL_PROC_REF(to_chat), quirk_holder, span_userdanger("[msg]")), 3) // so the examine signal has time to fire and this will print after
	return COMSIG_BLOCK_EYECONTACT

/datum/quirk/trait_people_person
	name = "People Person"
	desc = "You're naturally upbeat, and your sunny mood rubs off on everyone around you - but being left alone for too long wears on you badly."
	value = 0
	is_trait = TRUE
	mood_quirk = TRUE
	gain_text = span_notice("You feel a quiet happiness, though you'd rather not be left alone.")
	lose_text = span_danger("Your mood settles back to normal.")
	medical_record_text = "Patient demonstrates constant euthymia irregular for environment, alongside marked distress when isolated."

/datum/quirk/trait_people_person/add()
	var/mob/living/carbon/human/H = quirk_holder
	ADD_TRAIT(H, TRAIT_JOLLY, "People Person")

/datum/quirk/trait_people_person/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(!QDELETED(H))
		REMOVE_TRAIT(H, TRAIT_JOLLY, "People Person")
		H.cure_trauma_type(/datum/brain_trauma/severe/monophobia, TRAUMA_RESILIENCE_ABSOLUTE)

/datum/quirk/trait_people_person/post_add()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	H.gain_trauma(/datum/brain_trauma/severe/monophobia, TRAUMA_RESILIENCE_ABSOLUTE)

/datum/quirk/trait_people_person/on_process()
	if(prob(0.05))
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "jolly", /datum/mood_event/jolly)
