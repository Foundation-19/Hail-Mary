

// ============ FEV STRAIN DEFINES ============

#define FEV_STRAIN_RAW "raw"
#define FEV_STRAIN_COMBAT "combat"
#define FEV_STRAIN_RESISTANCE "resistance"
#define FEV_STRAIN_HEALING "healing"
#define FEV_STRAIN_SENSES "senses"
#define FEV_STRAIN_MENTAL "mental"
#define FEV_STRAIN_TRANSFORMATION "transformation"
#define FEV_STRAIN_CUSTOM "custom"

// ============ FEV SYNTHESIS MANAGER ============

/datum/enclave_fev_research
	var/list/available_strains = list()
	var/list/custom_strains = list()
	var/list/synthesis_materials = list()
	var/fev_vat_level = 0
	var/max_fev_vat = 100

/datum/enclave_fev_research/proc/initialize_strains()
	available_strains = list(
		FEV_STRAIN_RAW = new /datum/fev_strain/raw(),
		FEV_STRAIN_COMBAT = new /datum/fev_strain/combat(),
		FEV_STRAIN_RESISTANCE = new /datum/fev_strain/resistance(),
		FEV_STRAIN_HEALING = new /datum/fev_strain/healing(),
		FEV_STRAIN_SENSES = new /datum/fev_strain/senses(),
		FEV_STRAIN_MENTAL = new /datum/fev_strain/mental(),
		FEV_STRAIN_TRANSFORMATION = new /datum/fev_strain/transformation(),
	)

/datum/enclave_fev_research/proc/synthesize_strain(strain_type, mob/user)
	if(!available_strains[strain_type])
		return FALSE

	var/datum/fev_strain/strain = available_strains[strain_type]
	if(!can_synthesize(strain, user))
		return FALSE

	consume_synthesis_materials(strain)
	
	var/obj/item/fev_vial/vial = new /obj/item/fev_vial(get_turf(user))
	vial.strain_type = strain_type
	vial.name = "[strain.name] FEV Vial"
	vial.desc = strain.desc
	vial.effect_bias = strain.effect_bias.Copy()
	vial.success_modifier = strain.success_modifier
	vial.magnitude_modifier = strain.magnitude_modifier
	vial.stability = strain.stability
	
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.put_in_hands(vial)
	
	return TRUE

/datum/enclave_fev_research/proc/can_synthesize(datum/fev_strain/strain, mob/user)
	for(var/material in strain.required_materials)
		if((synthesis_materials[material] || 0) < strain.required_materials[material])
			return FALSE
	
	if(fev_vat_level < strain.fev_cost)
		return FALSE
	
	return TRUE

/datum/enclave_fev_research/proc/consume_synthesis_materials(datum/fev_strain/strain)
	for(var/material in strain.required_materials)
		synthesis_materials[material] -= strain.required_materials[material]
	fev_vat_level -= strain.fev_cost

/datum/enclave_fev_research/proc/add_synthesis_material(material_type, amount)
	synthesis_materials[material_type] = (synthesis_materials[material_type] || 0) + amount
	return TRUE

/datum/enclave_fev_research/proc/add_fev_to_vat(amount)
	fev_vat_level = min(fev_vat_level + amount, max_fev_vat)
	return TRUE

/datum/enclave_fev_research/proc/create_custom_strain(name, list/effect_priorities, mob/user)
	if(custom_strains.len >= 5)
		return FALSE

	var/datum/fev_strain/custom/strain = new()
	strain.name = name
	strain.effect_bias = effect_priorities.Copy()
	strain.creator_ckey = user?.ckey
	strain.required_materials = list(
		"genetic_data" = 50,
		"refined_fev" = 30,
	)
	strain.fev_cost = 25
	
	custom_strains += strain
	available_strains["[name]"] = strain
	
	return TRUE

// ============ FEV STRAIN DATUM ============

/datum/fev_strain
	var/name = "FEV Strain"
	var/desc = "A strain of the Forced Evolutionary Virus."
	var/strain_type = FEV_STRAIN_RAW
	var/list/effect_bias = list()
	var/success_modifier = 0
	var/magnitude_modifier = 0
	var/stability = 100
	var/list/required_materials = list()
	var/fev_cost = 10

/datum/fev_strain/proc/get_bias_for_category(category)
	return effect_bias[category] || 0

/datum/fev_strain/raw
	name = "Raw"
	desc = "Unrefined FEV. Highly unstable and unpredictable."
	strain_type = FEV_STRAIN_RAW
	effect_bias = list(
		"physical" = 1,
		"sensory" = 1,
		"mental" = 1,
		"resistance" = 1,
		"healing" = 1,
	)
	success_modifier = 0
	magnitude_modifier = 0
	stability = 50
	required_materials = list("biological_matter" = 10)
	fev_cost = 5

/datum/fev_strain/combat
	name = "Combat"
	desc = "Refined FEV biased toward physical enhancement."
	strain_type = FEV_STRAIN_COMBAT
	effect_bias = list(
		"physical" = 4,
		"sensory" = 1,
		"mental" = 0.5,
		"resistance" = 2,
		"healing" = 1,
	)
	success_modifier = 10
	magnitude_modifier = 1
	stability = 75
	required_materials = list(
		"biological_matter" = 15,
		"genetic_data" = 10,
	)
	fev_cost = 15

/datum/fev_strain/resistance
	name = "Resistance"
	desc = "Refined FEV biased toward immunity and protection."
	strain_type = FEV_STRAIN_RESISTANCE
	effect_bias = list(
		"physical" = 1,
		"sensory" = 0.5,
		"mental" = 0.5,
		"resistance" = 4,
		"healing" = 2,
	)
	success_modifier = 15
	magnitude_modifier = 0
	stability = 80
	required_materials = list(
		"biological_matter" = 10,
		"radiation_sample" = 5,
		"genetic_data" = 15,
	)
	fev_cost = 20

/datum/fev_strain/healing
	name = "Healing"
	desc = "Refined FEV biased toward regeneration and recovery."
	strain_type = FEV_STRAIN_HEALING
	effect_bias = list(
		"physical" = 1,
		"sensory" = 0.5,
		"mental" = 0.5,
		"resistance" = 1,
		"healing" = 4,
	)
	success_modifier = 20
	magnitude_modifier = 1
	stability = 85
	required_materials = list(
		"biological_matter" = 20,
		"genetic_data" = 20,
	)
	fev_cost = 20

/datum/fev_strain/senses
	name = "Sensory"
	desc = "Refined FEV biased toward enhanced perception."
	strain_type = FEV_STRAIN_SENSES
	effect_bias = list(
		"physical" = 0.5,
		"sensory" = 4,
		"mental" = 2,
		"resistance" = 0.5,
		"healing" = 0.5,
	)
	success_modifier = 15
	magnitude_modifier = 0
	stability = 80
	required_materials = list(
		"biological_matter" = 10,
		"genetic_data" = 15,
	)
	fev_cost = 15

/datum/fev_strain/mental
	name = "Mental"
	desc = "Refined FEV biased toward cognitive enhancement."
	strain_type = FEV_STRAIN_MENTAL
	effect_bias = list(
		"physical" = 0.5,
		"sensory" = 2,
		"mental" = 4,
		"resistance" = 0.5,
		"healing" = 0.5,
	)
	success_modifier = 5
	magnitude_modifier = 0
	stability = 70
	required_materials = list(
		"biological_matter" = 10,
		"genetic_data" = 25,
	)
	fev_cost = 25

/datum/fev_strain/transformation
	name = "Transformation"
	desc = "Highly concentrated FEV for radical genetic alteration."
	strain_type = FEV_STRAIN_TRANSFORMATION
	effect_bias = list(
		"transformation" = 4,
	)
	success_modifier = -10
	magnitude_modifier = 2
	stability = 40
	required_materials = list(
		"biological_matter" = 30,
		"genetic_data" = 50,
		"radiation_sample" = 10,
	)
	fev_cost = 40

/datum/fev_strain/custom
	name = "Custom"
	desc = "A custom-engineered FEV strain."
	strain_type = FEV_STRAIN_CUSTOM
	var/creator_ckey

// ============ FEV VIAL ITEM ============

/obj/item/fev_vial
	name = "FEV Vial"
	desc = "A vial containing FEV solution."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "vial"
	w_class = WEIGHT_CLASS_SMALL
	var/strain_type = FEV_STRAIN_RAW
	var/list/effect_bias = list()
	var/success_modifier = 0
	var/magnitude_modifier = 0
	var/stability = 100
	var/doses = 1

/obj/item/fev_vial/attack_self(mob/user)
	if(!ishuman(user))
		return
	
	var/mob/living/carbon/human/H = user
	var/list/outcome = GLOB.enclave_fev_research.generate_strain_outcome(src, H)
	GLOB.enclave_fev_research.apply_outcome(H, outcome)
	
	doses--
	if(doses <= 0)
		qdel(src)

/obj/item/fev_vial/attack(mob/living/target, mob/user)
	if(!ishuman(target))
		return
	
	if(user.a_intent == INTENT_HARM)
		return ..()
	
	var/mob/living/carbon/human/H = target
	var/list/outcome = GLOB.enclave_fev_research.generate_strain_outcome(src, H)
	GLOB.enclave_fev_research.apply_outcome(H, outcome)
	
	to_chat(user, span_notice("You inject [H] with the FEV solution."))
	to_chat(H, span_warning("You feel a strange sensation as the FEV enters your system."))
	
	doses--
	if(doses <= 0)
		qdel(src)

// ============ SYNTHESIS MATERIALS ============

/obj/item/fev_material
	name = "FEV Material"
	desc = "Raw material for FEV synthesis."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "material"
	w_class = WEIGHT_CLASS_SMALL
	var/material_type = "biological_matter"
	var/amount = 10

/obj/item/fev_material/biological
	name = "Biological Sample"
	desc = "Organic material for FEV synthesis."
	material_type = "biological_matter"
	icon_state = "biomass"

/obj/item/fev_material/genetic_data
	name = "Genetic Data Storage"
	desc = "Encoded genetic information from FEV testing."
	material_type = "genetic_data"
	icon_state = "data_disk"

/obj/item/fev_material/radiation
	name = "Irradiated Sample"
	desc = "Highly radioactive material for FEV synthesis."
	material_type = "radiation_sample"
	icon_state = "rad_sample"
	var/radiation_level = 50

/obj/item/fev_material/refined_fev
	name = "Refined FEV Base"
	desc = "Purified FEV solution ready for strain synthesis."
	material_type = "refined_fev"
	icon_state = "fev_base"

// ============ MATERIAL PROCESSING ============

/obj/machinery/fev_processor
	name = "FEV Processor"
	desc = "Processes biological materials into FEV synthesis components."
	icon = 'icons/obj/computer.dmi'
	icon_state = "dna"
	density = TRUE
	anchored = TRUE
	var/processing = FALSE
	var/process_time = 30 SECONDS
	var/list/queued_materials = list()

/obj/machinery/fev_processor/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/fev_material))
		var/obj/item/fev_material/M = I
		queued_materials[M.material_type] = (queued_materials[M.material_type] || 0) + M.amount
		qdel(I)
		to_chat(user, span_notice("Material added to processor."))
		return TRUE
	
	if(istype(I, /obj/item/organ))
		queued_materials["biological_matter"] = (queued_materials["biological_matter"] || 0) + 10
		qdel(I)
		to_chat(user, span_notice("Organ processed for biological matter."))
		return TRUE
	
	if(istype(I, /obj/item/reagent_containers/blood))
		queued_materials["biological_matter"] = (queued_materials["biological_matter"] || 0) + 5
		queued_materials["genetic_data"] = (queued_materials["genetic_data"] || 0) + 5
		qdel(I)
		to_chat(user, span_notice("Blood sample processed."))
		return TRUE
	
	return ..()

/obj/machinery/fev_processor/attack_hand(mob/user)
	if(processing)
		to_chat(user, span_warning("Processor is running."))
		return
	
	if(queued_materials.len == 0)
		to_chat(user, span_notice("No materials queued."))
		return
	
	processing = TRUE
	to_chat(user, span_notice("Processing materials..."))
	
	addtimer(CALLBACK(src, .proc/complete_processing), process_time)

/obj/machinery/fev_processor/proc/complete_processing()
	processing = FALSE
	
	var/bio_matter = queued_materials["biological_matter"] || 0
	var/gen_data = queued_materials["genetic_data"] || 0
	var/rad_sample = queued_materials["radiation_sample"] || 0
	
	queued_materials = list()
	
	if(bio_matter > 0)
		GLOB.enclave_fev_research.add_synthesis_material("biological_matter", bio_matter)
	if(gen_data > 0)
		GLOB.enclave_fev_research.add_synthesis_material("genetic_data", gen_data)
	if(rad_sample > 0)
		GLOB.enclave_fev_research.add_synthesis_material("radiation_sample", rad_sample)
	
	var/refined = round((bio_matter + gen_data) / 10)
	if(refined > 0)
		GLOB.enclave_fev_research.add_fev_to_vat(refined)
		GLOB.enclave_fev_research.add_synthesis_material("refined_fev", refined)
	
	visible_message(span_notice("[src] finishes processing."))
	playsound(src, 'sound/machines/ding.ogg', 50, TRUE)

// ============ STRAIN-SPECIFIC OUTCOME GENERATION ============

/datum/enclave_fev_research/proc/generate_strain_outcome(obj/item/fev_vial/vial, mob/living/carbon/human/subject)
	var/list/outcome = list()
	var/seed = round_seed + vial.stability + (subject ? length(subject.ckey) : 0) + world.time
	var/rng = rustg_hash_string(RUSTG_HASH_MD5, "[seed]")
	
	var/success_roll = text2num(copytext(rng, 1, 3), 16)
	var/effect_roll = text2num(copytext(rng, 3, 5), 16)
	var/magnitude_roll = text2num(copytext(rng, 5, 7), 16)
	var/category_roll = text2num(copytext(rng, 7, 9), 16)
	
	var/base_success = 65 + vial.success_modifier + round((vial.stability - 50) / 5)
	
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
	
	outcome["success"] = (success_roll % 100) < base_success
	
	if(!outcome["success"])
		var/list/failures = list("damage", "stat_loss", "mutation", "organ_failure", "critical_failure")
		var/fail_type = failures[(category_roll % failures.len) + 1]
		outcome["failure_type"] = fail_type
		outcome["failure_severity"] = 1 + (magnitude_roll % 3)
		return outcome
	
	var/list/categories = list()
	for(var/cat in vial.effect_bias)
		var/weight = vial.effect_bias[cat]
		for(var/i in 1 to weight)
			categories += cat
	
	var/selected_category = categories[(category_roll % categories.len) + 1]
	
	var/list/possible_effects = list()
	if(selected_category == "physical")
		possible_effects = list("strength", "endurance", "speed", "melee_armor", "pain_resist", "size")
	else if(selected_category == "sensory")
		possible_effects = list("perception", "night_vision", "hearing", "awareness")
	else if(selected_category == "mental")
		possible_effects = list("intelligence", "willpower", "memory", "focus")
	else if(selected_category == "resistance")
		possible_effects = list("rad_immune", "toxin_immune", "thermal_resist", "disease_resist")
	else if(selected_category == "healing")
		possible_effects = list("regeneration", "heal_speed", "blood_regen", "stamina_regen")
	else if(selected_category == "transformation")
		possible_effects = list("super_mutant", "enhanced_mutant")
	
	var/effect_type = possible_effects[(effect_roll % possible_effects.len) + 1]
	var/magnitude = 1 + (magnitude_roll % 3) + vial.magnitude_modifier
	magnitude = clamp(magnitude, 1, 4)
	
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

// ============ GENETIC DATA EXTRACTION ============

/obj/machinery/computer/enclave_fev_research/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	
	switch(action)
		if("synthesize_strain")
			var/strain_type = params["strain_type"]
			if(GLOB.enclave_fev_research.synthesize_strain(strain_type, usr))
				to_chat(usr, span_notice("Strain synthesized successfully."))
			else
				to_chat(usr, span_warning("Cannot synthesize - insufficient materials."))
			return TRUE
		
		if("create_custom_strain")
			var/strain_name = params["name"]
			var/list/priorities = list(
				"physical" = text2num(params["physical"]) || 1,
				"sensory" = text2num(params["sensory"]) || 1,
				"mental" = text2num(params["mental"]) || 1,
				"resistance" = text2num(params["resistance"]) || 1,
				"healing" = text2num(params["healing"]) || 1,
			)
			if(GLOB.enclave_fev_research.create_custom_strain(strain_name, priorities, usr))
				to_chat(usr, span_notice("Custom strain created: [strain_name]"))
			else
				to_chat(usr, span_warning("Cannot create more custom strains."))
			return TRUE
		
		if("extract_genetic_data")
			var/project_id = params["project_id"]
			var/datum/fev_project/project = GLOB.enclave_fev_research.get_project_by_id(project_id)
			if(project && project.discovered_effects.len > 0)
				GLOB.enclave_fev_research.add_synthesis_material("genetic_data", project.discovered_effects.len * 10)
				project.discovered_effects = list()
				to_chat(usr, span_notice("Genetic data extracted from [project.name]."))
			return TRUE
	
	return FALSE

/obj/machinery/computer/enclave_fev_research/ui_data(mob/user)
	var/list/data = ..()
	
	data["synthesis_materials"] = GLOB.enclave_fev_research.synthesis_materials
	data["fev_vat_level"] = GLOB.enclave_fev_research.fev_vat_level
	data["max_fev_vat"] = GLOB.enclave_fev_research.max_fev_vat
	data["custom_strain_count"] = GLOB.enclave_fev_research.custom_strains.len
	data["max_custom_strains"] = 5
	
	var/list/strains_data = list()
	for(var/strain_id in GLOB.enclave_fev_research.available_strains)
		var/datum/fev_strain/S = GLOB.enclave_fev_research.available_strains[strain_id]
		strains_data += list(list(
			"id" = strain_id,
			"name" = S.name,
			"desc" = S.desc,
			"stability" = S.stability,
			"success_mod" = S.success_modifier,
			"magnitude_mod" = S.magnitude_modifier,
			"fev_cost" = S.fev_cost,
			"materials" = S.required_materials,
		))
	data["available_strains"] = strains_data
	
	return data

// Global datum initialization - must be after all datum definitions
GLOBAL_DATUM_INIT(enclave_fev_research, /datum/enclave_fev_research, new())
