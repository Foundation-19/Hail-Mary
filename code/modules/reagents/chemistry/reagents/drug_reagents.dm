/datum/reagent/drug
	name = "Drug"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	taste_description = "bitterness"
	var/trippy = TRUE //Does this drug make you trip?

/datum/reagent/drug/on_mob_end_metabolize(mob/living/M)
	if(trippy)
		SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "[type]_high")

/datum/reagent/drug/proc/dont_do_drugs(mob/living/carbon/M)
	if(!iscarbon(M))
		return
	if(NODRUGS(M))
		switch(rand(1,20))
			if(1 to 5)
				M.vomit()
			if(6 to 10)
				M.emote("cry")
			if(11 to 17)
				M.emote("scream")
			if(18 to 20)
				M.emote("scrungy")
		return TRUE

/// Faction-flavoured mood from using drugs, shared by the combat drugs
/datum/reagent/drug/proc/apply_drug_moods(mob/living/carbon/M)
	if(M.mind)
		var/datum/job/job = SSjob.GetJob(M.mind.assigned_role)
		if(istype(job))
			switch(job.faction)
				if(FACTION_NCR, FACTION_ENCLAVE, FACTION_BROTHERHOOD)
					SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "used drugs", /datum/mood_event/used_drugs, name)
				if(FACTION_LEGION)
					SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "betrayed Caesar", /datum/mood_event/betrayed_caesar, name)
	SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "jet euphoria", /datum/mood_event/jet_euphoria, name)

/datum/reagent/drug/space_drugs
	name = "Space drugs"
	value = REAGENT_VALUE_VERY_COMMON
	description = "An illegal chemical compound used as drug."
	color = "#60A584" // rgb: 96, 165, 132
	overdose_threshold = 30
	pH = 9

/datum/reagent/drug/space_drugs/on_mob_life(mob/living/carbon/M)
	if(dont_do_drugs(M))
		. = TRUE
		..()
		return
	M.set_drugginess(15)
	if(isturf(M.loc) && !isspaceturf(M.loc))
		if(CHECK_MOBILITY(M, MOBILITY_MOVE))
			if(prob(10))
				step(M, pick(GLOB.cardinals))
	if(prob(7))
		M.emote(pick("twitch","drool","moan","giggle"))
	..()

/datum/reagent/drug/space_drugs/overdose_start(mob/living/M)
	to_chat(M, span_userdanger("You start tripping hard!"))
	SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "[type]_overdose", /datum/mood_event/overdose, name)

/datum/reagent/drug/space_drugs/overdose_process(mob/living/M)
	if(M.hallucination < volume && prob(20))
		M.hallucination += 5
	..()

/datum/reagent/drug/nicotine
	name = "Nicotine"
	description = "Slightly reduces stun times. If overdosed it will deal toxin and oxygen damage."
	reagent_state = LIQUID
	color = "#60A584" // rgb: 96, 165, 132
	addiction_threshold = 20
	taste_description = "smoke"
	trippy = FALSE
	pH = 8

/datum/reagent/drug/nicotine/on_mob_life(mob/living/carbon/M)
	if(dont_do_drugs(M))
		. = TRUE
		..()
		return
	if(prob(1))
		var/smoke_message = pick("You feel relaxed.", "You feel calmed.","You feel alert.","You feel rugged.")
		to_chat(M, span_notice("[smoke_message]"))
	SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "smoked", /datum/mood_event/smoked, name)
	M.AdjustAllImmobility(-20, 0)
	M.AdjustUnconscious(-20, 0)
	M.adjustStaminaLoss(-0.5*REM, 0)
	..()
	. = 1

/datum/reagent/drug/crank
	name = "Crank"
	description = "Reduces stun times by about 200%. If overdosed or addicted it will deal significant Toxin, Brute and Brain damage."
	reagent_state = LIQUID
	color = "#FA00C8"
	overdose_threshold = 20
	addiction_threshold = 10
	pH = 10
	value = REAGENT_VALUE_UNCOMMON

/datum/reagent/drug/crank/on_mob_life(mob/living/carbon/M)
	if(dont_do_drugs(M))
		. = TRUE
		..()
		return
	if(prob(5))
		var/high_message = pick("You feel jittery.", "You feel like you gotta go fast.", "You feel like you need to step it up.")
		to_chat(M, span_notice("[high_message]"))
	M.AdjustAllImmobility(-20, 0)
	M.AdjustUnconscious(-20, 0)
	..()
	. = 1

/datum/reagent/drug/crank/overdose_process(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2*REM)
	M.adjustToxLoss(2*REM, 0)
	M.adjustBruteLoss(2*REM, 0)
	..()
	. = 1

/datum/reagent/drug/crank/addiction_act_stage1(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 5*REM)
	..()

/datum/reagent/drug/crank/addiction_act_stage2(mob/living/M)
	M.adjustToxLoss(5*REM, 0)
	..()
	. = 1

/datum/reagent/drug/crank/addiction_act_stage3(mob/living/M)
	M.adjustBruteLoss(5*REM, 0)
	..()
	. = 1

/datum/reagent/drug/crank/addiction_act_stage4(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 3*REM)
	M.adjustToxLoss(5*REM, 0)
	M.adjustBruteLoss(5*REM, 0)
	..()
	. = 1

/datum/reagent/drug/krokodil
	name = "Krokodil"
	description = "Cools and calms you down. If overdosed it will deal significant Brain and Toxin damage. If addicted it will begin to deal fatal amounts of Brute damage as the subject's skin falls off."
	reagent_state = LIQUID
	color = "#0064B4"
	overdose_threshold = 20
	addiction_threshold = 15
	pH = 9
	value = REAGENT_VALUE_UNCOMMON


/datum/reagent/drug/krokodil/on_mob_life(mob/living/carbon/M)
	if(dont_do_drugs(M))
		. = TRUE
		..()
		return
	var/high_message = pick("You feel calm.", "You feel collected.", "You feel like you need to relax.")
	if(prob(5))
		to_chat(M, span_notice("[high_message]"))
	..()

/datum/reagent/drug/krokodil/overdose_process(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.25*REM)
	M.adjustToxLoss(0.25*REM, 0)
	..()
	. = 1

/datum/reagent/drug/krokodil/addiction_act_stage1(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2*REM)
	M.adjustToxLoss(2*REM, 0)
	..()
	. = 1

/datum/reagent/drug/krokodil/addiction_act_stage2(mob/living/M)
	if(prob(25))
		to_chat(M, span_danger("Your skin feels loose..."))
	..()

/datum/reagent/drug/krokodil/addiction_act_stage3(mob/living/M)
	if(prob(25))
		to_chat(M, span_danger("Your skin starts to peel away..."))
	M.adjustBruteLoss(3*REM, 0)
	..()
	. = 1

/datum/reagent/drug/krokodil/addiction_act_stage4(mob/living/carbon/human/M)
	CHECK_DNA_AND_SPECIES(M)
	if(!istype(M.dna.species, /datum/species/krokodil_addict))
		to_chat(M, span_userdanger("Your skin falls off easily!"))
		M.adjustBruteLoss(50*REM, 0) // holy shit your skin just FELL THE FUCK OFF
		M.set_species(/datum/species/krokodil_addict)
	else
		M.adjustBruteLoss(5*REM, 0)
	..()
	. = 1

/datum/reagent/drug/heroin
	name = "Heroin"
	description = "Makes life feel like a beautiful dream."
	reagent_state = LIQUID
	color = "#c7AB00"
	overdose_threshold = 31
	addiction_threshold = 20
	pH = 9
	value = REAGENT_VALUE_UNCOMMON


/datum/reagent/drug/heroin/on_mob_life(mob/living/carbon/M)
	if(dont_do_drugs(M))
		. = TRUE
		..()
		return
	var/high_message = pick("You feel like you're floating.", "Life feels like a beautiful dream.", "Everything seems right with the world.")
	if(prob(5))
		to_chat(M, span_notice("[high_message]"))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/heroin/overdose_process(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.25*REM)
	M.adjustToxLoss(0.25*REM, 0)
	..()
	. = 1

/datum/reagent/drug/heroin/addiction_act_stage1(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2*REM)
	M.adjustToxLoss(2*REM, 0)
	..()
	. = 1

/datum/reagent/drug/heroin/addiction_act_stage2(mob/living/M)
	if(prob(25))
		to_chat(M, span_danger("Life feels so hard"))
	M.adjustToxLoss(3*REM, 0)
	..()
	. = 1

/datum/reagent/drug/heroin/addiction_act_stage3(mob/living/M)
	if(prob(25))
		to_chat(M, span_danger("YOU CAN'T TAKE THIS ANYMORE!!"))
	M.adjustToxLoss(4*REM, 0)
	..()
	. = 1

/datum/reagent/drug/methamphetamine
	name = "Methamphetamine"
	description = "Reduces stun times by about 300%, and allows the user to quickly recover stamina while dealing a small amount of Brain damage. If overdosed the subject will move randomly, laugh randomly, drop items and suffer from Toxin and Brain damage. If addicted the subject will constantly jitter and drool, before becoming dizzy and losing motor control and eventually suffer heavy toxin damage."
	reagent_state = LIQUID
	color = "#FAFAFA"
	overdose_threshold = 20
	addiction_threshold = 10
	metabolization_rate = 0.75 * REAGENTS_METABOLISM
	var/brain_damage = TRUE
	var/jitter = TRUE
	var/confusion = TRUE
	pH = 5
	value = REAGENT_VALUE_UNCOMMON

/datum/reagent/drug/methamphetamine/on_mob_metabolize(mob/living/L)
	..()
	if(dont_do_drugs(L))
		. = TRUE
		..()
		return
	L.ignore_slowdown(type)
	ADD_TRAIT(L, TRAIT_TASED_RESISTANCE, type)

/datum/reagent/drug/methamphetamine/on_mob_end_metabolize(mob/living/L)
	L.unignore_slowdown(type)
	REMOVE_TRAIT(L, TRAIT_TASED_RESISTANCE, type)
	..()

/datum/reagent/drug/methamphetamine/on_mob_life(mob/living/carbon/M)
	if(dont_do_drugs(M))
		. = TRUE
		..()
		return
	var/high_message = pick("You feel hyper.", "You feel like you need to go faster.", "You feel like you can run the world.")
	if(prob(5))
		to_chat(M, span_notice("[high_message]"))
	M.AdjustAllImmobility(-40, 0)
	M.AdjustUnconscious(-40, 0)
	M.adjustStaminaLoss(-7.5 * REM, 0)
	if(jitter)
		M.Jitter(2)
	if(brain_damage)
		M.adjustOrganLoss(ORGAN_SLOT_BRAIN, rand(1,4))
	M.heal_overall_damage(2, 2)
	if(prob(5))
		M.emote(pick("twitch", "shiver"))
	..()
	. = 1

/datum/reagent/drug/methamphetamine/overdose_process(mob/living/M)
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !ismovable(M.loc))
		for(var/i in 1 to 4)
			step(M, pick(GLOB.cardinals))
	if(prob(20))
		M.emote("laugh")
	if(prob(33))
		M.visible_message(span_danger("[M]'s hands flip out and flail everywhere!"))
		M.drop_all_held_items()
	..()
	M.adjustToxLoss(1, 0)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, pick(0.5, 0.6, 0.7, 0.8, 0.9, 1))
	. = 1

/datum/reagent/drug/methamphetamine/addiction_act_stage1(mob/living/M)
	M.Jitter(5)
	if(prob(20))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/methamphetamine/addiction_act_stage2(mob/living/M)
	M.Jitter(10)
	M.Dizzy(10)
	if(prob(30))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/methamphetamine/addiction_act_stage3(mob/living/M)
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !ismovable(M.loc))
		for(var/i = 0, i < 4, i++)
			step(M, pick(GLOB.cardinals))
	M.Jitter(15)
	M.Dizzy(15)
	if(prob(40))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/methamphetamine/addiction_act_stage4(mob/living/carbon/human/M)
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !ismovable(M.loc))
		for(var/i = 0, i < 8, i++)
			step(M, pick(GLOB.cardinals))
	M.Jitter(20)
	M.Dizzy(20)
	M.adjustToxLoss(5, 0)
	if(prob(50))
		M.emote(pick("twitch","drool","moan"))
	..()
	. = 1

/datum/reagent/drug/methamphetamine/changeling
	name = "Changeling Adrenaline"
	addiction_threshold = 35
	overdose_threshold = 35
	jitter = FALSE
	brain_damage = FALSE
	value = REAGENT_VALUE_RARE
	ghoulfriendly = TRUE

/datum/reagent/drug/bath_salts
	name = "Bath Salts"
	description = "Makes you impervious to stuns and grants a stamina regeneration buff, but you will be a nearly uncontrollable tramp-bearded raving lunatic."
	reagent_state = LIQUID
	color = "#FAFAFA"
	overdose_threshold = 20
	addiction_threshold = 10
	taste_description = "salt" // because they're bathsalts?
	var/datum/brain_trauma/special/psychotic_brawling/bath_salts/rage
	pH = 8.2
	value = REAGENT_VALUE_RARE
	ghoulfriendly = TRUE

/datum/reagent/drug/bath_salts/on_mob_metabolize(mob/living/L)
	..()
	if(dont_do_drugs(L))
		. = TRUE
		..()
		return
	ADD_TRAIT(L, TRAIT_STUNIMMUNE, type)
	ADD_TRAIT(L, TRAIT_SLEEPIMMUNE, type)
	if(iscarbon(L))
		var/mob/living/carbon/C = L
		rage = new()
		C.gain_trauma(rage, TRAUMA_RESILIENCE_ABSOLUTE)

/datum/reagent/drug/bath_salts/on_mob_end_metabolize(mob/living/L)
	REMOVE_TRAIT(L, TRAIT_STUNIMMUNE, type)
	REMOVE_TRAIT(L, TRAIT_SLEEPIMMUNE, type)
	if(rage)
		QDEL_NULL(rage)
	..()

/datum/reagent/drug/bath_salts/on_mob_life(mob/living/carbon/M)
	if(dont_do_drugs(M))
		. = TRUE
		..()
		return
	var/high_message = pick("You feel amped up.", "You feel ready.", "You feel like you can push it to the limit.")
	if(prob(5))
		to_chat(M, span_notice("[high_message]"))
	M.adjustStaminaLoss(-5, 0)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 4)
	M.hallucination += 5
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !ismovable(M.loc))
		step(M, pick(GLOB.cardinals))
		step(M, pick(GLOB.cardinals))
	..()
	. = 1

/datum/reagent/drug/bath_salts/overdose_process(mob/living/M)
	M.hallucination += 5
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !ismovable(M.loc))
		for(var/i in 1 to 8)
			step(M, pick(GLOB.cardinals))
	if(prob(20))
		M.emote(pick("twitch","drool","moan"))
	if(prob(33))
		M.drop_all_held_items()
	..()

/datum/reagent/drug/bath_salts/addiction_act_stage1(mob/living/M)
	M.hallucination += 10
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !ismovable(M.loc))
		for(var/i = 0, i < 8, i++)
			step(M, pick(GLOB.cardinals))
	M.Jitter(5)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 10)
	if(prob(20))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/bath_salts/addiction_act_stage2(mob/living/M)
	M.hallucination += 20
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !ismovable(M.loc))
		for(var/i = 0, i < 8, i++)
			step(M, pick(GLOB.cardinals))
	M.Jitter(10)
	M.Dizzy(10)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 10)
	if(prob(30))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/bath_salts/addiction_act_stage3(mob/living/M)
	M.hallucination += 30
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !ismovable(M.loc))
		for(var/i = 0, i < 12, i++)
			step(M, pick(GLOB.cardinals))
	M.Jitter(15)
	M.Dizzy(15)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 10)
	if(prob(40))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/bath_salts/addiction_act_stage4(mob/living/carbon/human/M)
	M.hallucination += 30
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !ismovable(M.loc))
		for(var/i = 0, i < 16, i++)
			step(M, pick(GLOB.cardinals))
	M.Jitter(50)
	M.Dizzy(50)
	M.adjustToxLoss(5, 0)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 10)
	if(prob(50))
		M.emote(pick("twitch","drool","moan"))
	..()
	. = 1

/datum/reagent/drug/aranesp
	name = "Aranesp"
	description = "Amps you up and gets you going, fixing stamina damage but possibly causing toxin and oxygen damage."
	reagent_state = LIQUID
	color = "#78FFF0"
	pH = 9.2
	value = REAGENT_VALUE_RARE

/datum/reagent/drug/aranesp/on_mob_life(mob/living/carbon/M)
	if(dont_do_drugs(M))
		. = TRUE
		..()
		return
	var/high_message = pick("You feel amped up.", "You feel ready.", "You feel like you can push it to the limit.")
	if(prob(5))
		to_chat(M, span_notice("[high_message]"))
	M.adjustStaminaLoss(-10, 0)
	M.adjustToxLoss(0.5, 0)
	if(prob(50))
		M.losebreath++
		M.adjustOxyLoss(1, 0)
	..()
	. = 1

/datum/reagent/drug/happiness
	name = "Happiness"
	description = "Fills you with ecstasic numbness and causes minor brain damage. Highly addictive. If overdosed causes sudden mood swings."
	reagent_state = LIQUID
	color = "#FFF378"
	addiction_threshold = 10
	overdose_threshold = 20
	pH = 10.5
	value = REAGENT_VALUE_RARE

/datum/reagent/drug/happiness/on_mob_add(mob/living/L)
	..()
	if(dont_do_drugs(L))
		to_chat(L, span_userdanger("You feel TOO happy!"))
		. = TRUE
		..()
		return
	ADD_TRAIT(L, TRAIT_FEARLESS, type)
	SEND_SIGNAL(L, COMSIG_ADD_MOOD_EVENT, "happiness_drug", /datum/mood_event/happiness_drug)

/datum/reagent/drug/happiness/on_mob_delete(mob/living/L)
	REMOVE_TRAIT(L, TRAIT_FEARLESS, type)
	SEND_SIGNAL(L, COMSIG_CLEAR_MOOD_EVENT, "happiness_drug")
	..()

/datum/reagent/drug/happiness/on_mob_life(mob/living/carbon/M)
	if(dont_do_drugs(M))
		. = TRUE
		..()
		return
	M.jitteriness = 0
	M.confused = 0
	M.disgust = 0
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.2)
	..()
	. = 1

/datum/reagent/drug/happiness/overdose_process(mob/living/M)
	if(prob(30))
		var/reaction = rand(1,3)
		switch(reaction)
			if(1)
				M.emote("laugh")
				SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "happiness_drug", /datum/mood_event/happiness_drug_good_od)
			if(2)
				M.emote("sway")
				M.Dizzy(25)
			if(3)
				M.emote("frown")
				SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "happiness_drug", /datum/mood_event/happiness_drug_bad_od)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.5)
	..()
	. = 1

/datum/reagent/drug/happiness/addiction_act_stage1(mob/living/M)// all work and no play makes jack a dull boy
	var/datum/component/mood/mood = M.GetComponent(/datum/component/mood)
	mood.setSanity(min(mood.sanity, SANITY_DISTURBED))
	M.Jitter(5)
	if(prob(20))
		M.emote(pick("twitch","laugh","frown"))
	..()

/datum/reagent/drug/happiness/addiction_act_stage2(mob/living/M)
	var/datum/component/mood/mood = M.GetComponent(/datum/component/mood)
	mood.setSanity(min(mood.sanity, SANITY_UNSTABLE))
	M.Jitter(10)
	if(prob(30))
		M.emote(pick("twitch","laugh","frown"))
	..()

/datum/reagent/drug/happiness/addiction_act_stage3(mob/living/M)
	var/datum/component/mood/mood = M.GetComponent(/datum/component/mood)
	mood.setSanity(min(mood.sanity, SANITY_CRAZY))
	M.Jitter(15)
	if(prob(40))
		M.emote(pick("twitch","laugh","frown"))
	..()

/datum/reagent/drug/happiness/addiction_act_stage4(mob/living/carbon/human/M)
	var/datum/component/mood/mood = M.GetComponent(/datum/component/mood)
	mood.setSanity(SANITY_INSANE)
	M.Jitter(20)
	if(prob(50))
		M.emote(pick("twitch","laugh","frown"))
	..()
	. = 1

/datum/reagent/drug/skooma
	name = "Getaway"
	description = "A highly-addictive drug developed by a local pre-war crime family. It greatly improves the user's speed and strength, but heavily impedes their intelligence and agility."
	reagent_state = LIQUID
	color = "#F3E0F9"
	taste_description = "moonshine and the feeling of a successful heist"
	addiction_threshold = 3 // highly addictive: two doses
	addiction_stage3_end = 40
	addiction_stage4_end = 240
	pH = 12.5
	value = REAGENT_VALUE_EXCEPTIONAL

/datum/reagent/drug/skooma/on_mob_metabolize(mob/living/L)
	. = ..()
	if(dont_do_drugs(L))
		to_chat(L, span_userdanger("But its illegal!"))
		. = TRUE
		..()
		return
	L.add_movespeed_modifier(/datum/movespeed_modifier/reagent/skooma)
	L.action_cooldown_mod *= 2
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		if(H.physiology)
			H.physiology.stamina_mod *= 0.5
		if(H.dna && H.dna.species)
			H.dna.species.punchdamagehigh += 4
			H.dna.species.punchdamagelow  += 4
			H.dna.species.punchstunthreshold -= 2

/datum/reagent/drug/skooma/on_mob_end_metabolize(mob/living/L)
	. = ..()
	if(dont_do_drugs(L))
		. = TRUE
		..()
		return
	L.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/skooma)
	L.action_cooldown_mod *= 0.5
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		if(H.physiology)
			H.physiology.stamina_mod *= 2
		if(H.dna && H.dna.species)
			H.dna.species.punchdamagehigh -= 4
			H.dna.species.punchdamagelow -= 4
			H.dna.species.punchstunthreshold += 2

/datum/reagent/drug/skooma/on_mob_life(mob/living/carbon/M)
	if(dont_do_drugs(M))
		. = TRUE
		..()
		return
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 1*REM)
	M.adjustToxLoss(1*REM)
	if(prob(10))
		M.adjust_blurriness(2)
	..()
	. = 1

/datum/reagent/drug/skooma/addiction_act_stage1(mob/living/M)
	M.Jitter(10)
	if(prob(50))
		M.adjust_blurriness(2)
	..()

/datum/reagent/drug/skooma/addiction_act_stage2(mob/living/M)
	M.Jitter(20)
	M.Dizzy(10)
	M.adjust_blurriness(2)
	..()

/datum/reagent/drug/skooma/addiction_act_stage3(mob/living/M)
	M.Jitter(50)
	M.Dizzy(20)
	M.adjust_blurriness(4)
	if(prob(20))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/skooma/addiction_act_stage4(mob/living/M)
	M.Jitter(50)
	M.Dizzy(50)
	M.adjust_blurriness(10)
	if(prob(50)) //This proc will be called about 200 times and the adjustbrainloss() below only has to be called 40 times to kill. This will make surviving skooma addiction pretty rare without mannitol usage.
		M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 5)
	if(prob(40))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/syndicateadrenals
	name = "Syndicate Adrenaline"
	description = "Regenerates your stamina and increases your reaction time."
	color = "#E62111"
	overdose_threshold = 6
	value = REAGENT_VALUE_VERY_RARE
	ghoulfriendly = TRUE

/datum/reagent/syndicateadrenals/on_mob_life(mob/living/M)
	M.adjustStaminaLoss(-5*REM)
	. = ..()

/datum/reagent/syndicateadrenals/on_mob_metabolize(mob/living/M)
	. = ..()
	if(istype(M) && !NODRUGS(M))
		M.action_cooldown_mod *= 0.5
		to_chat(M, span_notice("You feel an intense surge of energy rushing through your veins."))

/datum/reagent/syndicateadrenals/on_mob_end_metabolize(mob/living/M)
	. = ..()
	if(istype(M) && !NODRUGS(M))
		M.action_cooldown_mod *= 2
		to_chat(M, span_notice("You feel as though the world around you is going faster."))

/datum/reagent/syndicateadrenals/overdose_start(mob/living/M)
	to_chat(M, span_danger("You feel an intense pain in your chest..."))

/datum/reagent/syndicateadrenals/overdose_process(mob/living/M)
	if(iscarbon(M))
		var/mob/living/carbon/C = M
		if(!C.undergoing_cardiac_arrest())
			C.set_heartattack(TRUE)




// ==================== Merged from fallout (code\modules\fallout\reagents\drugs.dm) ====================
/datum/reagent/drug/jet
	name = "Jet Inhalant"
	description = "A chemical derived from brahmin dung and cooked into a short, intense euphoric rush that clears fatigue fast. Highly addictive, and the comedown is hard if you keep dosing."
	color = "#60A584" // rgb: 96, 165, 132
	overdose_threshold = 20
	addiction_threshold = 12.5
	ghoulfriendly = TRUE
	combat_load = 1
	var/ghoul_potency = JET_GHOUL_EFFECT_MULT
	var/rush_mult = 1

/// Ghoul-strength Jet, made with Sugar Bombs. Twice as potent, and it actually works on ghouls.
/datum/reagent/drug/jet/ultrajet
	name = "Ultrajet"
	description = "Jet cooked up with Sugar Bombs for ghouls, whom ordinary Jet barely touches. Twice as potent, and just as hard to quit."
	color = "#3FBF8F"
	overdose_threshold = 15
	addiction_threshold = 10
	combat_load = 1.5
	ghoul_potency = 1
	rush_mult = 2

/// A more addictive Jet variant, cooked in the back rooms of Vegas.
/datum/reagent/drug/jet/jet_stream
	name = "Jet Stream"
	description = "A cut of Jet that hits smoother and hooks much harder."
	color = "#7FD0B0"
	addiction_threshold = 6

/datum/reagent/drug/jet/on_mob_add(mob/living/carbon/human/M)
	..()
	if(isliving(M))
		if(NODRUGS(M))
			to_chat(M, span_userdanger("Jet-- but doesn't that come from-- OH SHIT???!"))
		else
			to_chat(M, span_notice("You feel an incredible high! You just absolutely love life in this moment!"))

/datum/reagent/drug/jet/on_mob_delete(mob/living/carbon/human/M)
	..()
	M.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/jet)
	if(isliving(M) && !NODRUGS(M))
		to_chat(M, span_notice("You come down from your high. The wild ride is unfortunately over..."))
		M.confused += 2

/datum/reagent/drug/jet/on_mob_life(mob/living/carbon/M)
	if(dont_do_drugs(M))
		. = TRUE
		..()
		return
	var/potency = isghoul(M) ? ghoul_potency : 1
	M.adjustStaminaLoss(-JET_STAMINA_RECOVERY * potency * rush_mult, 0)
	M.set_drugginess(20)
	// Time seems to slow: quicker reflexes, and faster recovery from being floored
	if(potency >= 1)
		M.add_movespeed_modifier(/datum/movespeed_modifier/reagent/jet)
		M.AdjustAllImmobility(-2)
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !isspaceturf(M.loc) && prob(10))
		step(M, pick(GLOB.cardinals))
	if(prob(12))
		M.emote(pick("twitch","drool","moan","giggle"))
	combat_tick(M)
	apply_drug_moods(M)
	..()
	. = TRUE

/datum/reagent/drug/jet/overdose_start(mob/living/M)
	to_chat(M, span_userdanger("You start tripping hard!"))
	SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "[type]_overdose", /datum/mood_event/overdose, name)

/datum/reagent/drug/jet/overdose_process(mob/living/M)
	if(M.hallucination < volume && prob(20))
		M.hallucination += 10
		M.adjustToxLoss(2, 0)
		M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 5)
	..()

/datum/reagent/drug/jet/addiction_act_stage1(mob/living/M)
	if(prob(20))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/jet/addiction_act_stage2(mob/living/M)
	M.Dizzy(5)
	M.adjustToxLoss(0.5, 0)
	if(prob(30))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/jet/addiction_act_stage3(mob/living/M)
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !ismovableatom(M.loc) && !isspaceturf(M.loc) && prob(40))
		step(M, pick(GLOB.cardinals))
	M.adjustToxLoss(1, 0)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 1)
	M.set_disgust(30)
	M.Dizzy(10)
	if(prob(40))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/jet/addiction_act_stage4(mob/living/carbon/human/M)
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !ismovableatom(M.loc) && !isspaceturf(M.loc) && prob(60))
		step(M, pick(GLOB.cardinals))
	M.adjustToxLoss(2, 0)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2)
	M.set_disgust(50)
	M.Dizzy(15)
	if(prob(50))
		M.emote(pick("twitch","drool","moan"))
	..()
	. = TRUE

// Cateye: night vision that washes out in bright light
/datum/reagent/drug/cateye
	name = "Cateye"
	description = "A mild stimulant that lets the eyes gather light, giving the user night vision. In bright daylight it washes out colour and stings the eyes."
	color = "#C9B44A"
	metabolization_rate = 0.4 * REAGENTS_METABOLISM
	overdose_threshold = 20
	addiction_threshold = 30
	ghoulfriendly = TRUE

/datum/reagent/drug/cateye/on_mob_add(mob/living/L)
	..()
	if(!iscarbon(L))
		return
	ADD_TRAIT(L, TRAIT_NIGHT_VISION, type)
	var/mob/living/carbon/C = L
	C.update_sight()
	to_chat(C, span_notice("The shadows seem to thin out around you."))

/datum/reagent/drug/cateye/on_mob_delete(mob/living/L)
	if(iscarbon(L))
		REMOVE_TRAIT(L, TRAIT_NIGHT_VISION, type)
		var/mob/living/carbon/C = L
		C.update_sight()
	..()

/datum/reagent/drug/cateye/on_mob_life(mob/living/carbon/M)
	var/turf/T = get_turf(M)
	if(T && T.get_lumcount() > 0.8 && prob(25))
		M.blur_eyes(2)
	..()
	. = TRUE

/datum/reagent/drug/cateye/overdose_process(mob/living/M)
	if(prob(25))
		M.blur_eyes(5)
		M.adjustOrganLoss(ORGAN_SLOT_EYES, 1)
	..()

/datum/reagent/drug/turbo
	name = "Turbo Inhalant"
	description = "A refined Jet derivative that sharpens the user's reflexes and makes the world seem to slow down. Carries a risk of addiction, a heavy crash, and extreme toxin damage & nausea if overdosed."
	reagent_state = LIQUID
	color = "#FAFAFA"
	overdose_threshold = 14
	addiction_threshold = 9
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	ghoulfriendly = TRUE
	combat_load = 1.5
	combat_stun_resist = COMBAT_STUN_RESIST_TURBO

/datum/reagent/drug/turbo/on_mob_add(mob/M)
	..()
	if(NODRUGS(M))
		to_chat(M, span_userdanger("What a horrible feeling!"))
		return
	ADD_TRAIT(M, TRAIT_IGNOREDAMAGESLOWDOWN, "[type]")
	M.add_movespeed_modifier(/datum/movespeed_modifier/reagent/turbo)

/datum/reagent/drug/turbo/on_mob_delete(mob/M)
	REMOVE_TRAIT(M, TRAIT_IGNOREDAMAGESLOWDOWN, "[type]")
	M.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/turbo)
	..()

/datum/reagent/drug/turbo/on_mob_life(mob/living/carbon/M)
	if(dont_do_drugs(M))
		. = TRUE
		..()
		return
	var/high_message = pick("You feel hyper.", "You feel like you need to go faster.", "You feel like you can run the world.")
	if(prob(5))
		to_chat(M, span_notice("[high_message]"))
	M.Jitter(2)
	if(prob(5))
		M.emote(pick("twitch", "shiver"))
	combat_tick(M)
	apply_drug_moods(M)
	..()
	. = TRUE

/datum/reagent/drug/turbo/overdose_process(mob/living/M)
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !ismovableatom(M.loc) && !isspaceturf(M.loc))
		for(var/i in 1 to 4)
			step(M, pick(GLOB.cardinals))
	if(prob(20))
		M.emote("laugh")
	if(prob(33))
		M.visible_message(span_danger("[M]'s hands flip out and flail everywhere!"))
		M.drop_all_held_items()
	..()
	M.adjustToxLoss(2, 0)
	. = TRUE

/datum/reagent/drug/turbo/addiction_act_stage1(mob/living/M)
	M.Jitter(5)
	if(prob(20))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/turbo/addiction_act_stage2(mob/living/M)
	M.Jitter(10)
	M.Dizzy(10)
	if(prob(30))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/turbo/addiction_act_stage3(mob/living/M)
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !ismovableatom(M.loc) && !isspaceturf(M.loc))
		for(var/i = 0, i < 4, i++)
			step(M, pick(GLOB.cardinals))
	M.Jitter(15)
	M.Dizzy(15)
	if(prob(40))
		M.emote(pick("twitch","drool","moan"))
	..()

/datum/reagent/drug/turbo/addiction_act_stage4(mob/living/carbon/human/M)
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !ismovableatom(M.loc) && !isspaceturf(M.loc))
		for(var/i = 0, i < 3, i++)
			step(M, pick(GLOB.cardinals))
	M.Jitter(20)
	M.Dizzy(20)
	M.adjustToxLoss(1.5, 0)
	if(prob(50))
		M.emote(pick("twitch","drool","moan"))
	..()
	. = TRUE

/datum/reagent/drug/psycho
	name = "Psycho Fluid"
	description = "Floods the user with aggression and a high pain threshold. They hit harder, take less damage and shrug off stuns, but it causes brain damage and carries a risk of addiction."
	reagent_state = LIQUID
	color = "#FF0000"
	overdose_threshold = 15
	addiction_threshold = 12.5
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	var/datum/brain_trauma/special/psychotic_brawling/bath_salts/rage
	var/psycho_buffed = FALSE
	ghoulfriendly = TRUE
	combat_load = 1.5
	combat_stun_resist = COMBAT_STUN_RESIST_PSYCHO


/datum/reagent/drug/psycho/on_mob_life(mob/living/carbon/M)
	if(dont_do_drugs(M))
		. = TRUE
		..()
		return
	var/high_message = pick("<br><font color='#FF0000'><b>FUCKING KILL!</b></font>", "<br><font color='#FF0000'><b>RAAAAR!</b></font>", "<br><font color='#FF0000'><b>BRING IT!</b></font>")
	if(prob(20))
		to_chat(M, span_notice("[high_message]"))
	M.adjustStaminaLoss(-5, 0)
	M.Jitter(2)
	combat_tick(M)
	apply_drug_moods(M)
	..()
	. = TRUE

/datum/reagent/drug/psycho/on_mob_add(mob/living/L)
	..()
	if(NODRUGS(L))
		return
	ADD_TRAIT(L, TRAIT_SLEEPIMMUNE, "[type]")
	ADD_TRAIT(L, TRAIT_PSYCHO_BUFF, "[type]")
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		H.physiology.brute_mod *= PSYCHO_DAMAGE_REDUCTION
		H.physiology.burn_mod *= PSYCHO_DAMAGE_REDUCTION
		psycho_buffed = TRUE

/datum/reagent/drug/psycho/on_mob_delete(mob/living/L)
	REMOVE_TRAIT(L, TRAIT_SLEEPIMMUNE, "[type]")
	REMOVE_TRAIT(L, TRAIT_PSYCHO_BUFF, "[type]")
	if(psycho_buffed && ishuman(L))
		var/mob/living/carbon/human/H = L
		H.physiology.brute_mod /= PSYCHO_DAMAGE_REDUCTION
		H.physiology.burn_mod /= PSYCHO_DAMAGE_REDUCTION
		psycho_buffed = FALSE
	if(rage)
		QDEL_NULL(rage)
	..()

/datum/reagent/drug/psycho/overdose_process(mob/living/carbon/human/M)
	if(!rage && prob(PSYCHO_OVERDOSE_RAGE_PROB))
		rage = new()
		M.gain_trauma(rage, TRAUMA_RESILIENCE_ABSOLUTE)
	M.hallucination += 20
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !ismovableatom(M.loc) && !isspaceturf(M.loc) && prob(40))
		step(M, pick(GLOB.cardinals))
	if(prob(20))
		M.emote(pick("twitch","scream","laugh"))
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2)
	if(prob(4) && !M.undergoing_cardiac_arrest())
		M.set_heartattack(TRUE)
		M.visible_message(span_userdanger("[M] clutches at their chest as if their heart stopped!"))
		to_chat(M, span_danger("Your vision goes black and your heart stops beating as the amount of drugs in your system shuts down your organs one by one. Say hello to Elvis in the afterlife. "))
	..()
	return TRUE

/datum/reagent/drug/psycho/addiction_act_stage1(mob/living/M)
	M.hallucination += 10
	M.Jitter(5)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 1)
	if(prob(20))
		M.emote(pick("twitch","scream","laugh"))
	..()
	return
/datum/reagent/drug/psycho/addiction_act_stage2(mob/living/M)
	M.hallucination += 20
	M.Jitter(10)
	M.Dizzy(10)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 1)
	if(prob(30))
		M.emote(pick("twitch","scream","laugh"))
	..()
	return
/datum/reagent/drug/psycho/addiction_act_stage3(mob/living/M)
	M.hallucination += 30
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !ismovableatom(M.loc) && !isspaceturf(M.loc) && prob(40))
		step(M, pick(GLOB.cardinals))
	M.Jitter(15)
	M.Dizzy(15)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2)
	if(prob(40))
		M.emote(pick("twitch","scream","laugh"))
	..()
	return
/datum/reagent/drug/psycho/addiction_act_stage4(mob/living/carbon/human/M)
	M.hallucination += 40
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !ismovableatom(M.loc) && !isspaceturf(M.loc) && prob(60))
		step(M, pick(GLOB.cardinals))
	M.Jitter(50)
	M.Dizzy(50)
	M.adjustToxLoss(2)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 4)
	if(prob(50))
		M.emote(pick("twitch","scream","laugh"))
	..()
	return

/datum/reagent/drug/buffout
	name = "Buffout Powder"
	description = "A powerful steroid which increases the user's strength and endurance. The comedown leaves the muscles shaking and the heart racing."
	color = "#FF9900"
	reagent_state = SOLID
	overdose_threshold = 20
	addiction_threshold = 11
	metabolization_rate = 1.25 * REAGENTS_METABOLISM
	var/datum/brain_trauma/special/psychotic_brawling/bath_salts/rage
	var/buffed = FALSE
	ghoulfriendly = TRUE
	combat_load = 1
	combat_stun_resist = COMBAT_STUN_RESIST_BUFFOUT

/datum/reagent/drug/buffout/on_mob_add(mob/living/carbon/human/M)
	..()
	if(isliving(M))
		if(NODRUGS(M))
			to_chat(M, span_userdanger("Steroids have been linked to heart attacks and infertility! Oh no!"))
			return
		to_chat(M, span_notice("You feel stronger, and like you're able to endure more."))
		ADD_TRAIT(M, TRAIT_BUFFOUT_BUFF, "buffout")
		M.maxHealth += BUFFOUT_MAX_HEALTH_BONUS
		M.health += BUFFOUT_MAX_HEALTH_BONUS
		buffed = TRUE

/datum/reagent/drug/buffout/on_mob_delete(mob/living/carbon/human/M)
	..()
	if(isliving(M) && buffed)
		to_chat(M, span_notice("You feel weaker, and your heart is still racing."))
		REMOVE_TRAIT(M, TRAIT_BUFFOUT_BUFF, "buffout")
		M.maxHealth -= BUFFOUT_MAX_HEALTH_BONUS
		M.health -= BUFFOUT_MAX_HEALTH_BONUS
		M.adjustOrganLoss(ORGAN_SLOT_HEART, 2)
		buffed = FALSE

/datum/reagent/drug/buffout/on_mob_life(mob/living/carbon/M)
	if(dont_do_drugs(M))
		. = TRUE
		..()
		return
	combat_tick(M)
	apply_drug_moods(M)
	..()
	. = TRUE

/datum/reagent/drug/buffout/overdose_process(mob/living/carbon/human/M)
	if(iscarbon(M) && !rage && prob(10))
		var/mob/living/carbon/C = M
		rage = new()
		C.gain_trauma(rage, TRAUMA_RESILIENCE_ABSOLUTE)
	if(prob(5))
		var/datum/disease/D = new /datum/disease/heart_failure
		M.ForceContractDisease(D)
	if(prob(33))
		M.visible_message(span_danger("[M]'s muscles spasm, making them drop what they were holding!"))
		M.drop_all_held_items()
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2)
	..()

/datum/reagent/drug/buffout/addiction_act_stage1(mob/living/M)
	to_chat(M, span_notice("Your muscles ache slightly."))
	M.adjustBruteLoss(1.5)
	if(prob(15))
		M.emote(pick("twitch"))
	..()
	return

/datum/reagent/drug/buffout/addiction_act_stage2(mob/living/M)
	to_chat(M, span_notice("Your muscles feel incredibly sore."))
	M.adjustBruteLoss(2)
	if(prob(15))
		to_chat(M, span_notice("Your muscles spasm, making you drop what you were holding."))
		M.drop_all_held_items()
		M.emote(pick("twitch"))
	..()
	return

/datum/reagent/drug/buffout/addiction_act_stage3(mob/living/M)
	to_chat(M, span_notice("Your muscles start to hurt badly, and everything feels like it hurts more."))
	M.adjustBruteLoss(3)
	if(prob(25))
		to_chat(M, span_notice("Your muscles spasm, making you drop what you were holding. You're not even sure if you can control your arms!"))
		M.drop_all_held_items()
		M.emote(pick("twitch"))
	..()
	return

/datum/reagent/drug/buffout/addiction_act_stage4(mob/living/M)
	to_chat(M, span_danger("Your muscles are in incredible pain! When will it stop!?"))
	M.adjustBruteLoss(5)
	if(prob(40))
		to_chat(M, span_danger("You can't even keep control of your muscles anymore!"))
		M.drop_all_held_items()
		M.emote(pick("twitch"))
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !isspaceturf(M.loc) && prob(25))
		step(M, pick(GLOB.cardinals))
	M.adjustOrganLoss(ORGAN_SLOT_HEART, 2)
	..()
	return

/datum/reagent/drug/steady
	name = "Steady Fluid"
	description = "A potent, untested drug which increases the user's accuracy."
	color = "#E0D532"
	reagent_state = LIQUID
	overdose_threshold = 20
	addiction_threshold = 9 // one normal dose, see addiction.dm
	metabolization_rate = 0.8 * REAGENTS_METABOLISM
	ghoulfriendly = TRUE

/datum/reagent/drug/steady/on_mob_add(mob/living/M)
	..()
	if(M)
		if(NODRUGS(M))
			to_chat(M, span_userdanger("But you were steady before! You feel TOO steady!"))
			return
		to_chat(M, span_notice("You feel your senses becoming sharper, your trigger finger moving instinctively."))
		ADD_TRAIT(M, SPREAD_CONTROL, "steady")

/datum/reagent/drug/steady/on_mob_delete(mob/living/M)
	..()
	if(M)
		to_chat(M, "You feel your aim going back to normal.")
		REMOVE_TRAIT(M, SPREAD_CONTROL, "steady")

/datum/reagent/drug/steady/overdose_process(mob/living/M)
	if(prob(33))
		M.visible_message(span_danger("[M]'s fingers twitch uncontrollably, making them drop what they were holding!"))
		M.drop_all_held_items()
	M.adjustOrganLoss(ORGAN_SLOT_EYES, 2)
	..()

/datum/reagent/drug/steady/addiction_act_stage1(mob/living/M)
	if(prob(50))
		to_chat(M, span_notice("Your senses feel dull."))
	if(prob(15))
		M.emote(pick("twitch","blink"))
	M.Dizzy(5)
	..()
	return

/datum/reagent/drug/steady/addiction_act_stage2(mob/living/M)
	if(prob(50))
		to_chat(M, span_notice("Your senses seem to lag."))
	if(prob(30))
		M.emote(pick("twitch","blink"))
	M.Dizzy(10)
	..()
	return

/datum/reagent/drug/steady/addiction_act_stage3(mob/living/M)
	M.adjustToxLoss(2, 0)
	if(prob(50))
		to_chat(M, span_notice("You feel like a snail, your reaction times have slowed down to a crawl."))
	if(prob(50))
		M.emote(pick("twitch","blink"))
	M.Dizzy(15)
	..()
	return

/datum/reagent/drug/steady/addiction_act_stage4(mob/living/M)
	M.adjustToxLoss(2, 0)
	if(prob(50))
		to_chat(M, span_danger("Your hand-eye coordination is a thing of the past, even walking feels hard!"))
	if(prob(90))
		M.emote(pick("blink","twitch"))
	if(CHECK_MOBILITY(M, MOBILITY_MOVE) && !isspaceturf(M.loc) && prob(75))
		step(M, pick(GLOB.cardinals))
	M.Dizzy(30)
	..()
	return
