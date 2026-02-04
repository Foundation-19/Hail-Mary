/* FEV diseases */
#define FEV_MUTATION_SOURCE "fev_mutation_profile"

/mob/living
	/// Permanent profile granted by successful FEV-II conversion.
	var/fev_mutation_outcome = null
	/// Prevents stacking/re-rolling the permanent FEV profile.
	var/fev_mutation_outcome_applied = FALSE

/datum/movespeed_modifier/fev_mutation
	variable = TRUE
	blacklisted_movetypes = (FLYING|FLOATING)

/datum/movespeed_modifier/fev_mutation/boon

/datum/movespeed_modifier/fev_mutation/bane

// Main code
/datum/disease/transformation/mutant
	name = "Forced Evolutionary Virus"
	cure_text = "mutadone."
	cures = list(/datum/reagent/medicine/mutadone)
	cure_chance = 5 // Good luck
	stage_prob = 10
	agent = "FEV-I toxin strain" // The unstable one.
	desc = "A megavirus, with a protein sheath reinforced by ionized hydrogen. This virus is capable of mutating the affected into something horrifying..."
	severity = DISEASE_SEVERITY_BIOHAZARD
	visibility_flags = NONE
	stage1 = list()
	stage2 = list()
	stage3 = list()
	stage4 = list()
	stage5 = list(span_danger("You don't feel like yourself anymore!"))
	viable_mobtypes = list(/mob/living/carbon/human)
	new_form = /mob/living/simple_animal/hostile/centaur
	var/list/possible_forms = list(\
		/mob/living/simple_animal/hostile/centaur/strong = 4,
		/mob/living/simple_animal/hostile/abomination/weak = 3,
		/mob/living/simple_animal/hostile/ghoul/glowing/strong = 2,
		)

/datum/disease/transformation/mutant/do_disease_transformation(mob/living/affected_mob)
	new_form = pickweight(possible_forms)
	if(!ispath(new_form, /mob/living/carbon)) // If you've become simple_mob - you can't go and be all friendly to those around you!
		to_chat(affected_mob, "<big><span class='warning'><b>You've become something entirely different! You are being controlled only by your hunger and desire to kill!</b></span></big>")
	. = ..()

// FEV - I
/datum/disease/transformation/mutant/unstable/stage_act()
	..()

	if(!affected_mob)
		return
	affected_mob.adjustCloneLoss(-4,0) // Don't die while you are mutating.
	switch(stage)
		if(2)
			if (prob(8))
				to_chat(affected_mob, span_danger("You feel weird..."))
		if(3)
			if (prob(12))
				to_chat(affected_mob, span_danger("Your skin twitches..."))
				affected_mob.Jitter(3)
		if(4)
			if (prob(20))
				to_chat(affected_mob, span_danger("The pain is unbearable!"))
				affected_mob.emote("cry")
			if (prob(15))
				to_chat(affected_mob, span_danger("Your skin begins to shift, hurting like hell!"))
				affected_mob.emote("scream")
				affected_mob.Jitter(4)
			if (prob(6))
				to_chat(affected_mob, span_danger("Your body shuts down for a moment!"))
				affected_mob.Unconscious(10)

// FEV - II
/datum/disease/transformation/mutant/super
	agent = "FEV-II toxin strain" // The unstable one.
	desc = "A megavirus, with a protein sheath reinforced by ionized hydrogen. This variant has been mutated by radiation and will turn the affected person into something less horrifying."
	new_form = /mob/living/carbon/human/species/smutant
	possible_forms = list(/mob/living/carbon/human/species/smutant = 1)
	stage5 = list("<span class='reallybig hypnophrase'>Simple! Efficient! Glorious!</span>")

/datum/disease/transformation/mutant/super/stage_act()
	..()

	switch(stage)
		if(2)
			if (prob(8))
				to_chat(affected_mob, span_danger("You feel weird..."))
		if(3)
			if (prob(12))
				to_chat(affected_mob, span_danger("Your skin twitches..."))
				affected_mob.Jitter(3)
		if(4)
			if (prob(20))
				to_chat(affected_mob, span_danger("The pain is unbearable!"))
				affected_mob.emote("scream")
			if (prob(15))
				to_chat(affected_mob, span_warning("Your skin begins to shift, it hurts, but only for a moment..?"))
				affected_mob.emote("cry")
			if (prob(5))
				to_chat(affected_mob, span_notice("Simple, efficient, glorious..."))
				var/datum/component/mood/mood = affected_mob.GetComponent(/datum/component/mood)
				mood.setSanity(SANITY_INSANE) // You're happy, aren't you?

/datum/disease/transformation/mutant/super/do_disease_transformation(mob/living/affected_mob)
	if(istype(affected_mob, /mob/living/carbon) && affected_mob.stat != DEAD)
		if(stage5)
			to_chat(affected_mob, pick(stage5))
		if(QDELETED(affected_mob))
			return
		if(affected_mob.mob_transforming)
			return
		affected_mob.mob_transforming = TRUE
		for(var/obj/item/W in affected_mob.get_equipped_items(TRUE))
			affected_mob.dropItemToGround(W)
		for(var/obj/item/I in affected_mob.held_items)
			affected_mob.dropItemToGround(I)
		var/mob/living/new_mob = new new_form(affected_mob.loc)
		if(istype(new_mob))
			if(bantype && jobban_isbanned(affected_mob, bantype))
				replace_banned_player(new_mob)
			new_mob.a_intent = INTENT_HARM
			if(affected_mob.mind)
				affected_mob.mind.transfer_to(new_mob)
			else
				affected_mob.transfer_ckey(new_mob)
			if(ishuman(new_mob))
				var/mob/living/carbon/human/H = new_mob
				_apply_fev_permanent_profile(H)
		new_mob.name = affected_mob.real_name
		new_mob.real_name = new_mob.name
		qdel(affected_mob)

/datum/disease/transformation/mutant/super/proc/_apply_fev_permanent_profile(mob/living/carbon/human/H)
	if(!H || H.fev_mutation_outcome_applied)
		return
	H.fev_mutation_outcome_applied = TRUE
	var/list/notes = list()
	var/list/positive_pool = list("adrenal_overdrive", "muscle_hypertrophy", "dense_tissue")
	var/list/negative_pool = list("motor_degradation", "cellular_instability", "cognitive_scarring")
	var/profile_roll = rand(1, 100)
	var/positive_rolls = 1
	var/negative_rolls = 1
	if(profile_roll <= 20)
		H.fev_mutation_outcome = "prime"
		positive_rolls = 2
		negative_rolls = 0
	else if(profile_roll <= 75)
		H.fev_mutation_outcome = "volatile"
	else
		H.fev_mutation_outcome = "catastrophic"
		positive_rolls = 0
		negative_rolls = 2

	while(positive_rolls > 0 && LAZYLEN(positive_pool))
		var/pick_effect = pick_n_take(positive_pool)
		notes += _apply_fev_positive(H, pick_effect)
		positive_rolls--

	while(negative_rolls > 0 && LAZYLEN(negative_pool))
		var/pick_effect = pick_n_take(negative_pool)
		notes += _apply_fev_negative(H, pick_effect)
		negative_rolls--

	H.updatehealth()
	to_chat(H, span_userdanger("The FEV rewrite stabilizes into a permanent [H.fev_mutation_outcome] profile."))
	for(var/note in notes)
		to_chat(H, span_notice("- [note]"))

/datum/disease/transformation/mutant/super/proc/_apply_fev_positive(mob/living/carbon/human/H, effect_id)
	switch(effect_id)
		if("adrenal_overdrive")
			H.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/fev_mutation/boon, TRUE, multiplicative_slowdown = -0.35)
			H.physiology.stun_mod *= 0.85
			return "Adrenal overdrive: you move faster and recover from stuns better."
		if("muscle_hypertrophy")
			ADD_TRAIT(H, TRAIT_FEV, FEV_MUTATION_SOURCE)
			H.physiology.brute_mod *= 0.90
			return "Muscle hypertrophy: stronger strikes and reduced brute damage taken."
		if("dense_tissue")
			H.setMaxHealth(H.maxHealth + 35)
			H.health = min(H.maxHealth, H.health + 35)
			H.physiology.damage_resistance = clamp(H.physiology.damage_resistance + 6, -50, 50)
			return "Dense tissue growth: increased max health and baseline durability."
	return "Unstable adaptation settled into a harmless configuration."

/datum/disease/transformation/mutant/super/proc/_apply_fev_negative(mob/living/carbon/human/H, effect_id)
	switch(effect_id)
		if("motor_degradation")
			H.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/fev_mutation/bane, TRUE, multiplicative_slowdown = 0.35)
			H.physiology.stamina_mod *= 1.15
			return "Motor degradation: movement and stamina economy are worse."
		if("cellular_instability")
			H.physiology.tox_mod *= 1.40
			H.physiology.clone_mod *= 1.25
			return "Cellular instability: toxin and clone damage now hit harder."
		if("cognitive_scarring")
			H.physiology.do_after_speed *= 1.20
			ADD_TRAIT(H, TRAIT_CLUMSY, FEV_MUTATION_SOURCE)
			return "Cognitive scarring: slower technical actions and reduced finesse."
	return "Latent scar tissue formed with no major mechanical impact."

// FEV - Curling 13
/datum/disease/curling_thirteen
	form = "Virus"
	name = "Curling 13"
	desc = "A modified version of Forced Evolutionary Virus specifically engineered to kill every irradiated lifeform. The more radiation you have stored - the faster you'll die."
	max_stages = 5
	stage_prob = 100 // It's handled below
	spread_text = "Airborne"
	agent = "Forced Evolutionary Virus"
	viable_mobtypes = list(/mob/living/carbon/human)
	cure_text = "Mutadone, Haloperidol and Penicillin"
	cures = list(/datum/reagent/medicine/mutadone, /datum/reagent/medicine/haloperidol, /datum/reagent/medicine/spaceacillin)
	cure_chance = 8 // If you can gather all three - you deserve a somewhat of a good chance.
	severity = DISEASE_SEVERITY_BIOHAZARD

/datum/disease/curling_thirteen/update_stage(new_stage)
	if(new_stage > stage)
		var/radiation_prob = max(round(affected_mob.radiation * 0.05), 1) // 1000 rads will result in 50 chance
		var/new_stage_prob = min(radiation_prob, 50)
		if(prob(new_stage_prob))
			return ..()
		return
	return ..()

/datum/disease/curling_thirteen/stage_act()
	..()
	switch(stage)
		if(1) // Calm before the storm
			if(prob(1))
				to_chat(affected_mob, "<span class='warning'>You scratch at an itch.")
				affected_mob.adjustBruteLoss(1,0)
			if(prob(1))
				affected_mob.emote("cough")
		if(2)
			if(prob(2))
				to_chat(affected_mob, "<span class='warning'>You scratch at an itch.")
				affected_mob.adjustBruteLoss(3,0)
			if(prob(2))
				affected_mob.emote("cough")
				affected_mob.adjustOxyLoss(2)
				to_chat(affected_mob, span_warning("Your chest hurts."))
			if(prob(4))
				to_chat(affected_mob, span_warning("You feel a cold sweat form."))
		if(3)
			if(prob(2))
				to_chat(affected_mob, span_danger("You see four of everything..."))
				affected_mob.Dizzy(5)
			if(prob(3))
				to_chat(affected_mob, span_danger("You feel a sharp pain from your lower chest!"))
				affected_mob.adjustOxyLoss(6)
				affected_mob.emote("gasp")
			if(prob(3))
				to_chat(affected_mob, "<span class='danger'>It hurts like hell! Make it stop!")
				affected_mob.adjustBruteLoss(6,0)
			if(prob(3))
				affected_mob.vomit(10)
			if(prob(4))
				to_chat(affected_mob, span_danger("Your head feels dizzy..."))
				affected_mob.adjustStaminaLoss(10)
		if(4) // That's the part where you start dying
			if(prob(2))
				to_chat(affected_mob, span_userdanger("You feel as if your organs just exploded!"))
				affected_mob.playsound_local(affected_mob, 'sound/effects/singlebeat.ogg', 50, 0)
				affected_mob.blur_eyes(10)
				affected_mob.vomit(10, 1, 1, 0, 1, 1)
			if(prob(3))
				to_chat(affected_mob, span_warning("You should probably lie down for a moment..."))
				affected_mob.adjustStaminaLoss(30)
			if(prob(3))
				to_chat(affected_mob, "<span class='userdanger'>Your skin starts to rip apart!")
				affected_mob.adjustBruteLoss(10,0)
				affected_mob.emote("scream")
			if(prob(8))
				affected_mob.adjustToxLoss(2)
		if(5) // That's the part where you die for real
			var/datum/component/mood/mood = affected_mob.GetComponent(/datum/component/mood)
			mood.setSanity(SANITY_INSANE) // Who wouldn't be insane when they have 5 seconds left to live?
			if(prob(5))
				to_chat(affected_mob, span_userdanger("You feel as if all your organs just exploded!"))
				affected_mob.emote("scream")
				affected_mob.blur_eyes(5)
				affected_mob.vomit(50, 1, 1, 0, 1, 1)
			if(prob(7))
				to_chat(affected_mob, "<span class='userdanger'>Your skin keeps ripping itself apart!")
				affected_mob.adjustBruteLoss(15,0)
				affected_mob.emote("cry")
			if(prob(10))
				affected_mob.adjustToxLoss(5)
	return

#undef FEV_MUTATION_SOURCE
