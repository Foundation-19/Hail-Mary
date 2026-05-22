

// ============ FEV RESEARCH DEFINES ============

#define FEV_MUT_NONE 0
#define FEV_MUT_SKIN_GREEN 1
#define FEV_MUT_SKIN_YELLOW 2
#define FEV_MUT_SKIN_BLUE 3
#define FEV_MUT_GLOW 4
#define FEV_MUT_SIZE 5
#define FEV_MUT_EYES 6

// SPECIAL stat defines for FEV system
#define STAT_STR "strength"
#define STAT_END "endurance"
#define STAT_PER "perception"
#define STAT_INT "intelligence"
#define STAT_AGI "agility"

// Custom traits for FEV effects
#define TRAIT_FEV_PAIN_RESIST "fev_pain_resist"
#define TRAIT_FEV_GOOD_HEARING "fev_good_hearing"
#define TRAIT_FEV_SECURITY_HUD "fev_security_hud"
#define TRAIT_FEV_PHOTOSHOT "fev_photoshot"

// ============ FEV HELPER PROCS ============

/proc/fev_change_stat(mob/living/carbon/human/target, stat_type, amount)
	if(!target || !istype(target))
		return FALSE
	switch(stat_type)
		if(STAT_STR)
			target.special_s = clamp(target.special_s + amount, SPECIAL_MIN_ATTR_VALUE, SPECIAL_MAX_ATTR_VALUE)
		if(STAT_END)
			target.special_e = clamp(target.special_e + amount, SPECIAL_MIN_ATTR_VALUE, SPECIAL_MAX_ATTR_VALUE)
		if(STAT_PER)
			target.special_p = clamp(target.special_p + amount, SPECIAL_MIN_ATTR_VALUE, SPECIAL_MAX_ATTR_VALUE)
		if(STAT_INT)
			target.special_i = clamp(target.special_i + amount, SPECIAL_MIN_ATTR_VALUE, SPECIAL_MAX_ATTR_VALUE)
		if(STAT_AGI)
			target.special_a = clamp(target.special_a + amount, SPECIAL_MIN_ATTR_VALUE, SPECIAL_MAX_ATTR_VALUE)
	return TRUE

// ============ FEV RESEARCH MANAGER ============

/datum/enclave_fev_research
	var/list/research_projects = list()
	var/list/unlocked_projects = list()
	var/list/test_subjects = list()
	var/research_points = 0
	var/list/active_mutations = list()
	var/initialized = FALSE
	var/round_seed = 0
	var/list/outcome_cache = list()

/datum/enclave_fev_research/proc/initialize_projects()
	if(initialized)
		return

	initialized = TRUE
	round_seed = rand(1, 999999)
	research_projects = list()

	var/list/base_projects = list(
		list("id" = "project_alpha", "name" = "Project ALPHA", "cost" = 150, "category" = "physical"),
		list("id" = "project_beta", "name" = "Project BETA", "cost" = 200, "category" = "physical"),
		list("id" = "project_gamma", "name" = "Project GAMMA", "cost" = 250, "category" = "sensory"),
		list("id" = "project_delta", "name" = "Project DELTA", "cost" = 300, "category" = "resistance"),
		list("id" = "project_epsilon", "name" = "Project EPSILON", "cost" = 350, "category" = "mental"),
		list("id" = "project_zeta", "name" = "Project ZETA", "cost" = 400, "category" = "healing"),
		list("id" = "project_eta", "name" = "Project ETA", "cost" = 450, "category" = "physical"),
		list("id" = "project_theta", "name" = "Project THETA", "cost" = 500, "category" = "resistance"),
		list("id" = "project_iota", "name" = "Project IOTA", "cost" = 400, "category" = "resistance"),
		list("id" = "project_kappa", "name" = "Project KAPPA", "cost" = 300, "category" = "resistance"),
		list("id" = "project_lambda", "name" = "Project LAMBDA", "cost" = 250, "category" = "sensory"),
		list("id" = "project_mu", "name" = "Project MU", "cost" = 250, "category" = "physical"),
		list("id" = "project_nu", "name" = "Project NU", "cost" = 1000, "category" = "transformation"),
	)

	for(var/list/p in base_projects)
		var/datum/fev_project/project = new()
		project.project_id = p["id"]
		project.name = p["name"]
		project.research_cost = p["cost"]
		project.category = p["category"]
		project.effect_description = "Effect unknown - requires testing"
		project.internal_seed = rand(1, 999999)
		research_projects += project

/datum/enclave_fev_research/proc/generate_outcome(project_id, mob/living/carbon/human/subject)
	var/datum/fev_project/project = get_project_by_id(project_id)
	if(!project)
		return list("success" = FALSE, "effect" = "error")

	var/list/outcome = list()
	var/seed = project.internal_seed + round_seed + (subject ? length(subject.ckey) : 0) + world.time
	var/rng = rustg_hash_string(RUSTG_HASH_MD5, "[seed]")

	var/success_roll = text2num(copytext(rng, 1, 3), 16)
	var/effect_roll = text2num(copytext(rng, 3, 5), 16)
	var/magnitude_roll = text2num(copytext(rng, 5, 7), 16)
	var/side_roll = text2num(copytext(rng, 7, 9), 16)

	var/base_success = 65
	if(subject)
		if(subject.dna?.species?.id == "ghoul")
			base_success -= 20
		if(subject.radiation > 50)
			base_success -= 10
		if(subject.stat != CONSCIOUS)
			base_success += 15
		for(var/datum/fev_mutation_record/M in active_mutations)
			if(M.ckey == subject.ckey)
				base_success -= 8

	var/risk_modifier = (project.research_cost - 150) / 100
	base_success -= risk_modifier * 5

	outcome["success"] = (success_roll % 100) < base_success

	if(!outcome["success"])
		var/list/failures = list("damage", "stat_loss", "mutation", "organ_failure", "critical_failure")
		var/fail_type = failures[(side_roll % failures.len) + 1]
		outcome["failure_type"] = fail_type
		outcome["failure_severity"] = 1 + (magnitude_roll % 3)
		return outcome

	var/list/possible_effects = list()

	if(project.category == "physical")
		possible_effects = list("strength", "endurance", "speed", "melee_armor", "pain_resist", "size")
	else if(project.category == "sensory")
		possible_effects = list("perception", "night_vision", "hearing", "awareness")
	else if(project.category == "mental")
		possible_effects = list("intelligence", "willpower", "memory", "focus")
	else if(project.category == "resistance")
		possible_effects = list("rad_immune", "toxin_immune", "thermal_resist", "disease_resist")
	else if(project.category == "healing")
		possible_effects = list("regeneration", "heal_speed", "blood_regen", "stamina_regen")
	else if(project.category == "transformation")
		possible_effects = list("super_mutant", "enhanced_mutant")

	var/effect_type = possible_effects[(effect_roll % possible_effects.len) + 1]
	var/magnitude = 1 + (magnitude_roll % 3)

	if(effect_type == "super_mutant")
		magnitude = 1
		if(subject && subject.dna?.species?.id == "ghoul")
			outcome["success"] = FALSE
			outcome["failure_type"] = "critical_failure"
			return outcome

	outcome["effect_type"] = effect_type
	outcome["magnitude"] = magnitude
	outcome["visual"] = generate_visual_effect(effect_type, magnitude_roll)

	return outcome

/datum/enclave_fev_research/proc/generate_visual_effect(effect_type, roll)
	if(effect_type in list("rad_immune", "regeneration"))
		return FEV_MUT_SKIN_GREEN
	if(effect_type in list("melee_armor"))
		return FEV_MUT_SKIN_YELLOW
	if(effect_type in list("strength", "size"))
		return FEV_MUT_SIZE
	if(effect_type in list("night_vision", "awareness"))
		return FEV_MUT_EYES
	if(roll % 10 == 0)
		return FEV_MUT_GLOW
	return FEV_MUT_NONE

/datum/enclave_fev_research/proc/apply_outcome(mob/living/carbon/human/target, list/outcome)
	if(!outcome || !target)
		return FALSE

	if(!outcome["success"])
		return apply_failure(target, outcome)

	var/effect_type = outcome["effect_type"]
	var/magnitude = outcome["magnitude"]

	switch(effect_type)
		if("strength")
			fev_change_stat(target, STAT_STR, magnitude)
		if("endurance")
			fev_change_stat(target, STAT_END, magnitude)
		if("speed")
			var/speed_bonus = 0.1 * magnitude
			target.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/enclave_fev, multiplicative_slowdown = -speed_bonus)
		if("melee_armor")
			target.physiology.armor.melee += (5 * magnitude)
		if("pain_resist")
			ADD_TRAIT(target, TRAIT_FEV_PAIN_RESIST, "fev_[effect_type]")
		if("size")
			target.resize = min(1.5, target.resize + (0.1 * magnitude))
			target.update_transform()
		if("perception")
			fev_change_stat(target, STAT_PER, magnitude)
		if("night_vision")
			target.see_invisible = SEE_INVISIBLE_MINIMUM
			if(magnitude >= 2)
				target.sight |= (SEE_MOBS | SEE_OBJS)
		if("hearing")
			ADD_TRAIT(target, TRAIT_FEV_GOOD_HEARING, "fev_[effect_type]")
		if("awareness")
			ADD_TRAIT(target, TRAIT_FEV_SECURITY_HUD, "fev_[effect_type]")
		if("intelligence")
			fev_change_stat(target, STAT_INT, magnitude)
		if("willpower")
			ADD_TRAIT(target, TRAIT_FEARLESS, "fev_[effect_type]")
		if("memory")
		if("focus")
			ADD_TRAIT(target, TRAIT_FEV_PHOTOSHOT, "fev_[effect_type]")
		if("rad_immune")
			ADD_TRAIT(target, TRAIT_RADIMMUNE, "fev_[effect_type]")
		if("toxin_immune")
			ADD_TRAIT(target, TRAIT_TOXINIMMUNE, "fev_[effect_type]")
		if("thermal_resist")
			target.physiology.heat_mod *= (1 - (0.15 * magnitude))
			target.physiology.cold_mod *= (1 - (0.15 * magnitude))
		if("disease_resist")
			ADD_TRAIT(target, TRAIT_VIRUSIMMUNE, "fev_[effect_type]")
		if("regeneration")
			RegisterSignal(target, COMSIG_LIVING_LIFE, .proc/handle_regeneration)
		if("heal_speed")
			target.physiology.brute_mod *= (1 - (0.1 * magnitude))
		if("blood_regen")
		if("stamina_regen")
		if("super_mutant")
			return transform_to_super_mutant(target)
		if("enhanced_mutant")
			fev_change_stat(target, STAT_STR, 2)
			fev_change_stat(target, STAT_END, 2)
			ADD_TRAIT(target, TRAIT_RADIMMUNE, "fev_[effect_type]")

	if(outcome["visual"])
		apply_visual_mutation(target, outcome["visual"])

	var/effect_desc = generate_effect_description(effect_type, magnitude)
	to_chat(target, span_notice("Procedure complete. Result: [effect_desc]"))

	return effect_desc

/datum/enclave_fev_research/proc/generate_effect_description(effect_type, magnitude)
	var/magnitude_text = magnitude == 3 ? "Major" : magnitude == 2 ? "Moderate" : "Minor"
	var/list/descriptions = list(
		"strength" = "[magnitude_text] strength enhancement",
		"endurance" = "[magnitude_text] endurance enhancement",
		"speed" = "[magnitude_text] speed enhancement",
		"melee_armor" = "[magnitude_text] subdermal hardening",
		"pain_resist" = "Pain response dampening",
		"size" = "Physical growth enhancement",
		"perception" = "[magnitude_text] perception enhancement",
		"night_vision" = magnitude >= 2 ? "Enhanced night vision" : "Minor night vision",
		"hearing" = "Auditory enhancement",
		"awareness" = "Situational awareness boost",
		"intelligence" = "[magnitude_text] cognitive enhancement",
		"willpower" = "Psychological fortification",
		"memory" = "Memory enhancement",
		"focus" = "Focus enhancement",
		"rad_immune" = "Radiation immunity",
		"toxin_immune" = "Toxin immunity",
		"thermal_resist" = "[magnitude_text] thermal resistance",
		"disease_resist" = "Disease resistance",
		"regeneration" = "Cellular regeneration",
		"heal_speed" = "Accelerated healing",
		"blood_regen" = "Blood regeneration",
		"stamina_regen" = "Stamina recovery",
		"super_mutant" = "Super Mutant transformation",
		"enhanced_mutant" = "Enhanced mutation",
	)
	return descriptions[effect_type] || "Unknown effect"

/datum/enclave_fev_research/proc/apply_failure(mob/living/carbon/human/target, list/outcome)
	var/fail_type = outcome["failure_type"]
	var/severity = outcome["failure_severity"]

	switch(fail_type)
		if("damage")
			var/damage = 15 * severity
			target.adjustBruteLoss(damage)
			target.adjustToxLoss(damage * 0.5)
			to_chat(target, span_warning("Genetic rejection causes tissue damage!"))
		if("stat_loss")
			var/list/stats = list(STAT_STR, STAT_END, STAT_PER, STAT_INT)
			var/lost_stat = pick(stats)
			fev_change_stat(target, lost_stat, -severity)
			to_chat(target, span_warning("Genetic degradation: -[severity] [lost_stat]"))
		if("mutation")
			apply_visual_mutation(target, pick(FEV_MUT_SKIN_GREEN, FEV_MUT_SKIN_YELLOW, FEV_MUT_SKIN_BLUE))
			to_chat(target, span_warning("Uncontrolled mutation!"))
		if("organ_failure")
			target.adjustOrganLoss(ORGAN_SLOT_HEART, 15 * severity)
			target.adjustOrganLoss(ORGAN_SLOT_LIVER, 10 * severity)
			to_chat(target, span_warning("Organ damage from genetic stress!"))
		if("critical_failure")
			if(severity >= 3 && prob(40))
				target.gib()
				to_chat(target, span_userdanger("Catastrophic genetic failure!"))
		else
			target.adjustBruteLoss(50)
			target.adjustToxLoss(50)
			fev_change_stat(target, STAT_INT, -2)
			to_chat(target, span_userdanger("Severe genetic destabilization!"))

	return FALSE

/datum/enclave_fev_research/proc/transform_to_super_mutant(mob/living/carbon/human/target)
	if(!target || !istype(target))
		return FALSE

	if(target.dna?.species?.id == "smutant")
		to_chat(target, span_warning("Already a Super Mutant."))
		return FALSE

	var/seed = round_seed + length(target.ckey) + world.time
	var/rng = rustg_hash_string(RUSTG_HASH_MD5, "[seed]")
	var/survive_roll = text2num(copytext(rng, 1, 3), 16)

	var/survival_chance = 50
	if(target.dna?.species?.id == "ghoul")
		survival_chance = 20
	if(target.radiation > 100)
		survival_chance += 10

	if((survive_roll % 100) >= survival_chance)
		to_chat(target, span_userdanger("Your body rejects the transformation!"))
		target.gib()
		return FALSE

	to_chat(target, span_userdanger("Your body begins to transform!"))
	target.Paralyze(30 SECONDS)

	addtimer(CALLBACK(src, .proc/complete_transformation, target), 30 SECONDS)
	return TRUE

/datum/enclave_fev_research/proc/complete_transformation(mob/living/carbon/human/target)
	if(!target || QDELETED(target))
		return

	target.set_species(/datum/species/smutant)

	var/seed = round_seed + length(target.ckey)
	var/rng = rustg_hash_string(RUSTG_HASH_MD5, "[seed]")
	var/stat_roll = text2num(copytext(rng, 1, 2), 16)

	var/str_gain = 3 + (stat_roll % 3)
	var/end_gain = 3 + ((stat_roll + 1) % 3)
	var/int_loss = 3 + ((stat_roll + 2) % 3)

	fev_change_stat(target, STAT_STR, str_gain)
	fev_change_stat(target, STAT_END, end_gain)
	fev_change_stat(target, STAT_INT, -int_loss)
	fev_change_stat(target, STAT_AGI, -2)

	target.skin_tone = "green1"
	target.dna.update_ui_block(DNA_SKIN_TONE_BLOCK)
	target.update_body()

	ADD_TRAIT(target, TRAIT_RADIMMUNE, "super_mutant")
	ADD_TRAIT(target, TRAIT_TOXINIMMUNE, "super_mutant")

	to_chat(target, span_notice("Transformation complete."))
	message_admins("[key_name(target)] transformed to Super Mutant via FEV.")
	log_game("[key_name(target)] transformed to Super Mutant via FEV.")

/datum/enclave_fev_research/proc/contribute_research(amount)
	research_points += amount
	return TRUE

/datum/enclave_fev_research/proc/unlock_project(project_id)
	var/datum/fev_project/project = get_project_by_id(project_id)
	if(!project || project.unlocked)
		return FALSE

	if(research_points < project.research_cost)
		return FALSE

	research_points -= project.research_cost
	project.unlocked = TRUE
	unlocked_projects += project
	return TRUE

/datum/enclave_fev_research/proc/test_project(mob/living/carbon/human/target, project_id)
	var/datum/fev_project/project = get_project_by_id(project_id)
	if(!project || !project.unlocked)
		return FALSE

	if(!target || !istype(target))
		return FALSE

	if(target.dna?.species?.id == "smutant")
		to_chat(target, span_warning("Super Mutants cannot be tested further."))
		return FALSE

	var/list/outcome = generate_outcome(project_id, target)
	var/result = apply_outcome(target, outcome)

	if(outcome["success"])
		project.discovered_effects += list(list(
			"effect" = result,
			"magnitude" = outcome["magnitude"],
			"time" = world.time,
		))
		project.tests_successful++

		var/datum/fev_mutation_record/record = new()
		record.ckey = target.ckey
		record.project_id = project_id
		record.result = result
		record.time = world.time
		active_mutations += record

	return result

/datum/enclave_fev_research/proc/handle_regeneration(mob/living/carbon/human/target)
	if(target.health < target.maxHealth)
		target.adjustBruteLoss(-1)
		target.adjustFireLoss(-0.5)

/datum/enclave_fev_research/proc/apply_visual_mutation(mob/living/carbon/human/target, mutation_type)
	if(!target || !istype(target))
		return

	switch(mutation_type)
		if(FEV_MUT_SKIN_GREEN)
			target.skin_tone = "green1"
		if(FEV_MUT_SKIN_YELLOW)
			target.skin_tone = "yellow1"
		if(FEV_MUT_SKIN_BLUE)
			target.skin_tone = "blue1"
		if(FEV_MUT_GLOW)
			target.set_light(3, 2, "#00ff00")
		if(FEV_MUT_SIZE)
			target.resize = min(1.5, target.resize + 0.1)
			target.update_transform()
		if(FEV_MUT_EYES)
			target.left_eye_color = "0f0"
			target.right_eye_color = "0f0"

	target.dna.update_ui_block(DNA_SKIN_TONE_BLOCK)
	target.dna.update_ui_block(DNA_LEFT_EYE_COLOR_BLOCK)
	target.dna.update_ui_block(DNA_RIGHT_EYE_COLOR_BLOCK)
	target.update_body()

/datum/enclave_fev_research/proc/get_project_by_id(project_id)
	for(var/datum/fev_project/P in research_projects)
		if(P.project_id == project_id)
			return P
	return null

/datum/enclave_fev_research/proc/add_test_subject(mob/living/carbon/human/subject)
	if(!subject || !istype(subject))
		return FALSE

	for(var/datum/test_subject_record/R in test_subjects)
		if(R.ckey == subject.ckey)
			return FALSE

	var/datum/test_subject_record/record = new()
	record.ckey = subject.ckey
	record.name = subject.real_name
	record.added_time = world.time
	test_subjects += record
	return TRUE

/datum/enclave_fev_research/proc/consume_test_subject(ckey, project_id)
	var/datum/fev_project/project = get_project_by_id(project_id)
	if(!project)
		return FALSE

	for(var/datum/test_subject_record/R in test_subjects)
		if(R.ckey == ckey)
			project.research_progress += 50 + rand(0, 30)
			project.test_subjects_consumed++
			test_subjects -= R
			qdel(R)
			return TRUE
	return FALSE

// ============ FEV PROJECT DATUM ============

/datum/fev_project
	var/project_id
	var/name = "FEV Project"
	var/research_cost = 100
	var/research_progress = 0
	var/effect_description = "Unknown"
	var/unlocked = FALSE
	var/test_subjects_consumed = 0
	var/category = "physical"
	var/tests_successful = 0
	var/list/discovered_effects = list()
	var/internal_seed = 0

/datum/fev_project/proc/get_discovered_effects()
	if(discovered_effects.len == 0)
		return "Not yet tested"
	var/list/effects = list()
	for(var/list/e in discovered_effects)
		effects += e["effect"]
	return english_list(effects)

// ============ TEST SUBJECT RECORD ============

/datum/test_subject_record
	var/ckey
	var/name
	var/added_time

// ============ FEV MUTATION RECORD ============

/datum/fev_mutation_record
	var/ckey
	var/project_id
	var/result
	var/time

// ============ FEV RESEARCH TERMINAL ============

/obj/machinery/computer/enclave_fev_research
	name = "Enclave FEV Research Terminal"
	desc = "A terminal for genetic research. Results are unpredictable."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/enclave_fev_research/Initialize()
	. = ..()
	if(GLOB.enclave_fev_research.research_projects.len == 0)
		GLOB.enclave_fev_research.initialize_projects()
	if(GLOB.enclave_fev_research.available_strains.len == 0)
		GLOB.enclave_fev_research.initialize_strains()

/obj/machinery/computer/enclave_fev_research/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/enclave_fev_research/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FEVResearch")
		ui.open()

/obj/machinery/computer/enclave_fev_research/ui_data(mob/user)
	var/list/data = list()

	data["research_points"] = GLOB.enclave_fev_research.research_points

	var/list/projects_data = list()
	for(var/datum/fev_project/P in GLOB.enclave_fev_research.research_projects)
		projects_data += list(list(
			"id" = P.project_id,
			"name" = P.name,
			"cost" = P.research_cost,
			"progress" = P.research_progress,
			"effect" = P.effect_description,
			"unlocked" = P.unlocked,
			"category" = P.category,
			"tests_successful" = P.tests_successful,
			"discovered_effects" = P.get_discovered_effects(),
		))
	data["projects"] = projects_data

	var/list/subjects_data = list()
	for(var/datum/test_subject_record/R in GLOB.enclave_fev_research.test_subjects)
		subjects_data += list(list(
			"ckey" = R.ckey,
			"name" = R.name,
		))
	data["test_subjects"] = subjects_data

	data["can_create_weapons"] = GLOB.enclave_fev_research.unlocked_projects.len >= 3

	return data

/obj/machinery/computer/enclave_fev_research/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("contribute_rp")
			var/amount = text2num(params["amount"]) || 0
			GLOB.enclave_fev_research.contribute_research(amount)
			return TRUE

		if("unlock_project")
			var/project_id = params["project_id"]
			if(GLOB.enclave_fev_research.unlock_project(project_id))
				to_chat(usr, span_notice("Project unlocked."))
			else
				to_chat(usr, span_warning("Cannot unlock."))
			return TRUE

		if("test_project")
			var/project_id = params["project_id"]
			if(!ishuman(usr))
				return FALSE
			var/mob/living/carbon/human/H = usr
			GLOB.enclave_fev_research.test_project(H, project_id)
			return TRUE

		if("add_subject")
			var/mob/living/carbon/human/target = usr.pulling
			if(target && istype(target))
				if(GLOB.enclave_fev_research.add_test_subject(target))
					to_chat(usr, span_notice("Subject added."))
			return TRUE

		if("consume_subject")
			var/ckey = params["ckey"]
			var/project_id = params["project_id"]
			GLOB.enclave_fev_research.consume_test_subject(ckey, project_id)
			adjust_karma(usr.ckey, -30)
			return TRUE

		if("create_weapon")
			return create_weapon(usr, params["weapon_type"])

	return FALSE

/obj/machinery/computer/enclave_fev_research/proc/create_weapon(mob/user, weapon_type)
	if(GLOB.enclave_fev_research.unlocked_projects.len < 3)
		return FALSE

	var/obj/item/weapon
	switch(weapon_type)
		if("fev_grenade")
			weapon = new /obj/item/grenade/fev_grenade(get_turf(user))
		if("fev_dart")
			weapon = new /obj/item/ammo_casing/fev_dart(get_turf(user))
		if("fev_vial")
			weapon = new /obj/item/reagent_containers/glass/bottle/fev_extract(get_turf(user))

	if(weapon && ishuman(user))
		var/mob/living/carbon/human/H = user
		H.put_in_hands(weapon)
		adjust_karma(user.ckey, -15)
		return TRUE
	return FALSE

// ============ FEV VATS ============

/obj/machinery/fev_vat
	name = "FEV Vat"
	desc = "Contains Forced Evolutionary Virus. Results are unpredictable."
	icon = 'icons/obj/computer.dmi'
	icon_state = "dna"
	density = TRUE
	anchored = TRUE
	var/processing = FALSE
	var/mob/living/carbon/human/vat_occupant = null

/obj/machinery/fev_vat/relaymove(mob/user)
	return

/obj/machinery/fev_vat/attack_hand(mob/user)
	if(processing)
		to_chat(user, span_warning("Currently processing."))
		return
	if(vat_occupant)
		vat_occupant.forceMove(get_turf(src))
		vat_occupant = null
	else
		to_chat(user, span_notice("Empty."))

/obj/machinery/fev_vat/attackby(obj/item/I, mob/user, params)
	if(iscarbon(user.pulling) && user.Adjacent(user.pulling))
		var/mob/living/carbon/human/H = user.pulling
		if(istype(H))
			H.forceMove(src)
			vat_occupant = H
			to_chat(user, span_notice("[H] placed in vat."))
			return TRUE
	return ..()

// ============ FEV WEAPONS ============

/obj/item/grenade/fev_grenade
	name = "FEV Grenade"
	desc = "Unstable FEV compound. Results unpredictable."
	icon = 'icons/obj/grenade.dmi'
	icon_state = "fev_grenade"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/grenade/fev_grenade/prime()
	var/turf/T = get_turf(src)
	for(var/mob/living/carbon/human/H in range(3, T))
		if(prob(40 + rand(0, 30)))
			H.adjustBruteLoss(20 + rand(10, 30))
			H.adjustToxLoss(30 + rand(0, 20))
			if(prob(25))
				GLOB.enclave_fev_research.apply_visual_mutation(H, pick(FEV_MUT_SKIN_GREEN, FEV_MUT_SKIN_YELLOW, FEV_MUT_SKIN_BLUE))
			to_chat(H, span_userdanger("Uncontrolled genetic reaction!"))
	playsound(T, 'sound/effects/spray.ogg', 50, TRUE)
	qdel(src)

/obj/item/ammo_casing/fev_dart
	name = "FEV Dart"
	desc = "Unstable FEV compound."
	icon_state = "dart"
	projectile_type = /obj/item/projectile/bullet/dart/fev
	caliber = "dart"

/obj/item/projectile/bullet/dart/fev
	name = "FEV dart"
	piercing = TRUE

/obj/item/projectile/bullet/dart/fev/on_hit(atom/target, blocked = FALSE, skip = FALSE)
	. = ..(target, blocked, TRUE)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		H.adjustToxLoss(20 + rand(0, 15))
		if(prob(30))
			GLOB.enclave_fev_research.apply_visual_mutation(H, pick(FEV_MUT_SKIN_GREEN, FEV_MUT_SKIN_YELLOW))

/obj/item/reagent_containers/glass/bottle/fev_extract
	name = "FEV Extract"
	desc = "Unstable FEV solution."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle-4"
	list_reagents = list(/datum/reagent/toxin/fev_solution = 30)

/datum/reagent/toxin/fev_solution
	name = "FEV Solution"
	description = "Unstable genetic compound."
	color = "#4cff4c"
	toxpwr = 2
	metabolization_rate = 0.3

/datum/reagent/toxin/fev_solution/on_mob_life(mob/living/carbon/M)
	if(prob(8))
		M.adjustBruteLoss(5)
		M.adjustToxLoss(5)
	if(prob(4))
		var/effect = pick("str", "end", "int")
		if(effect == "str")
			if(ishuman(M))
				var/mob/living/carbon/human/H = M
				fev_change_stat(H, STAT_STR, prob(50) ? 1 : -1)
		if(effect == "end")
			if(ishuman(M))
				var/mob/living/carbon/human/H = M
				fev_change_stat(H, STAT_END, prob(50) ? 1 : -1)
		if(effect == "int")
			if(ishuman(M))
				var/mob/living/carbon/human/H = M
				fev_change_stat(H, STAT_INT, -1)
	if(prob(2) && ishuman(M))
		var/mob/living/carbon/human/H = M
		GLOB.enclave_fev_research.apply_visual_mutation(H, pick(FEV_MUT_SKIN_GREEN, FEV_MUT_SKIN_YELLOW, FEV_MUT_GLOW))
	return ..()

// ============ MOVESPEED MODIFIER ============

/datum/movespeed_modifier/enclave_fev
	multiplicative_slowdown = 0
