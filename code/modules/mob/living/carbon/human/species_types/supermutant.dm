/datum/species/smutant
	name = "Super Mutant"
	id = "smutant"
	say_mod = "yells"
	limbs_id = "smutant"
	inherent_traits = list(TRAIT_RADIMMUNE,TRAIT_VIRUSIMMUNE,TRAIT_SMUTANT,)
	inherent_biotypes = list(MOB_INORGANIC, MOB_HUMANOID)
	speedmod = 0.2
	siemens_coeff = 0
	punchdamagelow = 20
	punchdamagehigh = 30
	armor = 5
	use_skintones = 0
	sexes = 0
	liked_food = JUNKFOOD | FRIED | RAW 
	thirst_rate_mod = SMUTANT_THIRST_MOD // big bodies need more water, but they hold more of it
	stomach_water_mod = SMUTANT_STOMACH_MOD

/datum/species/smutant/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	..()
	if(ishuman(C))
		var/mob/living/carbon/human/H = C
		H.physiology.hunger_mod *= SMUTANT_HUNGER_MOD
	for(var/obj/item/bodypart/b in C.bodyparts)
		b.max_damage += 80
	if(!istype(C, /mob/living/carbon/human/dummy))
		C.resize = 1.5
		C.update_transform()

/datum/species/smutant/on_species_loss(mob/living/carbon/C)
	..()
	if(ishuman(C))
		var/mob/living/carbon/human/H = C
		H.physiology.hunger_mod /= SMUTANT_HUNGER_MOD
	for(var/obj/item/bodypart/b in C.bodyparts)
		b.max_damage = initial(b.max_damage)
	if(!istype(C, /mob/living/carbon/human/dummy))
		C.resize = 0.5
		C.update_transform()

/datum/species/smutant/qualifies_for_rank(rank, list/features)
	if(rank in GLOB.legion_positions)
		return 0
	if(rank in GLOB.brotherhood_positions)
		return 0
	if(rank in GLOB.vault_positions)
		return 0
	if(rank in GLOB.ncr_positions)
		// Allow Corporal and below ranks
		if(rank in list(
					"NCR Rear Echelon",
					"NCR Conscript",
					"NCR Trooper", 
					"NCR Corporal"))
			return 1
		return 0  // Block higher NCR ranks
	if(rank in GLOB.wasteland_positions)
		return 0
	if(rank in GLOB.outlaw_positions) 
		return 0
	if(rank in GLOB.khan_positions) 
		return 0
	if(rank in GLOB.enclave_positions) 
		return 0
	if(rank in GLOB.locust_positions) 
		return 0
	if(rank in GLOB.atlantic_positions) 
		return 0
	if(rank in GLOB.ranger_positions)
		return 0
/*	if(rank in GLOB.followers_positions) 
		return 0*/
	/*
	if(rank in GLOB.tribal_positions) 
		return 0
	*/
	return ..()
