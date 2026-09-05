/datum/reagent/synthtissue
	name = "Synthtissue"
	description = "Synthetic tissue used for grafting onto damaged organs during surgery, or for treating limb damage. Has a very tight growth window between 305-320, any higher and the temperature will cause the cells to die. Additionally, growth time is considerably long, so chemists are encouraged to leave beakers with said reaction ongoing, while they tend to their other duties."
	pH = 7.6
	metabolization_rate = 0.05
	data = list("grown_volume" = 0, "injected_vol" = 0, "borrowed_health" = 0)
	var/borrowed_health = 0
	color = "#FFDADA"
	value = REAGENT_VALUE_COMMON

/datum/reagent/synthtissue/reaction_mob(mob/living/M, method=TOUCH, reac_volume,show_message = 1)
	if(iscarbon(M))
		var/mob/living/carbon/C = M
		var/healing_factor = (((data["grown_volume"] / 100) + 1)*reac_volume)
		if(method == PATCH)
			if (C.stat == DEAD)
				C.visible_message("The synthetic tissue rapidly grafts into [M]'s wounds, attempting to repair the damage as quickly as possible.")
				var/preheal_brute = C.getBruteLoss()
				var/preheal_burn = C.getFireLoss()
				var/preheal_tox = C.getToxLoss()
				var/preheal_oxy = C.getOxyLoss()
				C.adjustBruteLoss(-healing_factor*2)
				C.adjustFireLoss(-healing_factor*2)
				C.adjustToxLoss(-healing_factor)
				C.adjustCloneLoss(-healing_factor)
				borrowed_health += (preheal_brute - C.getBruteLoss()) + (preheal_burn - C.getFireLoss()) + (preheal_tox - C.getToxLoss()) + ((preheal_oxy - C.getOxyLoss()) / 2)
				C.updatehealth()
				if(data["grown_volume"] > 135 && ((C.health + C.oxyloss)>=80))
					var/tplus = world.time - M.timeofdeath
					if(C.can_revive(ignore_timelimit = TRUE, maximum_brute_dam = MAX_REVIVE_BRUTE_DAMAGE / 2, maximum_fire_dam = MAX_REVIVE_FIRE_DAMAGE / 2, ignore_heart = TRUE) && C.revive())
						C.grab_ghost()
						C.emote("gasp")
						borrowed_health *= 2
						if(borrowed_health < 100)
							borrowed_health = 100
						log_combat(M, M, "revived", src)
						var/list/policies = CONFIG_GET(keyed_list/policy)
						var/policy = policies[POLICYCONFIG_ON_DEFIB_LATE]
						if(policy)
							to_chat(C, policy)
						C.log_message("revived using synthtissue, [tplus] deciseconds from time of death, considered late revival due to usage of synthtissue.", LOG_GAME)
			else
				var/preheal_brute = C.getBruteLoss()
				var/preheal_burn = C.getFireLoss()
				M.adjustBruteLoss(-healing_factor)
				M.adjustFireLoss(-healing_factor)
				var/datum/reagent/synthtissue/active_tissue = M.reagents.has_reagent(/datum/reagent/synthtissue)
				var/imperfect = FALSE
				if(active_tissue && active_tissue.borrowed_health)
					borrowed_health += (preheal_brute - C.getBruteLoss()) + (preheal_burn - C.getFireLoss())
					imperfect = TRUE
				to_chat(M, span_danger("You feel your flesh [imperfect ? "partially and painfully" : ""] merge with the synthetic tissue! It stings like hell[imperfect ? " and is making you feel terribly sick" : ""]!"))
		SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "painful_medicine", /datum/mood_event/painful_medicine)
		data["borrowed_health"] += borrowed_health
		borrowed_health = 0
		if(method==INJECT)
			data["injected_vol"] = reac_volume
			var/obj/item/organ/heart/H = C.getorganslot(ORGAN_SLOT_HEART)
			if(H && data["grown_volume"] > 50 && H.organ_flags & ORGAN_FAILING)
				H.applyOrganDamage(-20)
	..()

/datum/reagent/synthtissue/on_mob_life(mob/living/carbon/C)
	if(!iscarbon(C))
		return ..()
	if(data["injected_vol"] > 14)
		if(data["grown_volume"] > 175)
			if(volume >= 14)
				if(C.regenerate_organs(only_one = TRUE))
					C.reagents.remove_reagent(type, 15)
					to_chat(C, span_notice("You feel something reform inside of you!"))

	data["injected_vol"] = max(0, data["injected_vol"] - metabolization_rate * C.metabolism_efficiency)
	if(borrowed_health)
		var/ratio = (current_cycle > SYNTHTISSUE_DAMAGE_FLIP_CYCLES) ? 0 : (1 - (current_cycle / SYNTHTISSUE_DAMAGE_FLIP_CYCLES))
		var/payback = 2 * C.metabolism_efficiency
		C.adjustToxLoss((1 - ratio) * payback * REAGENTS_EFFECT_MULTIPLIER, forced = TRUE)
		C.adjustCloneLoss(ratio * payback * REAGENTS_EFFECT_MULTIPLIER)
		borrowed_health = max(borrowed_health - payback, 0)
	..()

/datum/reagent/synthtissue/on_merge(passed_data)
	if(!passed_data)
		return ..()
	borrowed_health += max(0, passed_data["borrowed_health"])
	if(passed_data["grown_volume"] > data["grown_volume"])
		data["grown_volume"] = passed_data["grown_volume"]
	if(iscarbon(holder.my_atom))
		data["injected_vol"] = data["injected_vol"] + passed_data["injected_vol"]
		passed_data["injected_vol"] = 0
	update_name()
	..()

/datum/reagent/synthtissue/on_new(passed_data)
	if(!passed_data)
		return ..()
	borrowed_health = min(passed_data["borrowed_health"] + borrowed_health, SYNTHTISSUE_BORROW_CAP)
	if(passed_data["grown_volume"] > data["grown_volume"])
		data["grown_volume"] = passed_data["grown_volume"]
	update_name()
	..()

/datum/reagent/synthtissue/post_copy_data()
	data["borrowed_health"] = 0
	return ..()

/datum/reagent/synthtissue/proc/update_name()
	switch(data["grown_volume"])
		if(-INFINITY to 50)
			name = "Induced Synthtissue Colony"
		if(50 to 80)
			name = "Oligopotent Synthtissue Colony"
		if(80 to 135)
			name = "Pluripotent Synthtissue Colony"
		if(135 to 175)
			name = "SuperSomatic Synthtissue Colony"
		if(175 to INFINITY)
			name = "Omnipotent Synthtissue Colony"

/datum/reagent/synthtissue/on_mob_delete(mob/living/M)
	if(!iscarbon(M))
		return
	var/mob/living/carbon/C = M
	C.adjustBruteLoss(borrowed_health*1.25)
	C.adjustToxLoss(borrowed_health*1.25)
	C.adjustCloneLoss(borrowed_health*1.25)
	C.adjustAllOrganLoss(borrowed_health*0.25)
	M.updatehealth()
	if(C.stat != DEAD && borrowed_health && C.health < -20)
		M.visible_message("The synthetic tissue sloughs off [M]'s wounds as they collapse to the floor.")
		M.death()
