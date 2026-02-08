/datum/species/c27
	name = "C-27"
	id = "c27"
	limbs_id = "c27"
//	icon_limbs = "c27"
	say_mod = "beeps"
	default_color = "00FF00"
	blacklisted = 0
	speedmod = 2 //very slower than humans
	sexes = 0
	species_traits = list(
		MUTCOLORS,
		NOTRANSSTING,
		EYECOLOR,
		LIPS,
		ROBOTIC_LIMBS,
		HORNCOLOR,
		WINGCOLOR,
		NO_UNDERWEAR,
		NO_DNA_COPY,
		)
	inherent_traits = list(
		TRAIT_EASYDISMEMBER,
		TRAIT_LIMBATTACHMENT,
		TRAIT_NO_PROCESS_FOOD,
		TRAIT_RADIMMUNE,
		TRAIT_NOBREATH,
		TRAIT_NOHARDCRIT,
		TRAIT_NOSOFTCRIT,
		TRAIT_CLONEIMMUNE,
		TRAIT_VIRUSIMMUNE,
		TRAIT_MUTATION_STASIS,
		TRAIT_SPRINT_LOCKED,
		TRAIT_C27,
		)
	hair_alpha = 210
	inherent_biotypes = MOB_ROBOTIC|MOB_HUMANOID
	no_equip = list(SLOT_WEAR_SUIT)
//	mutant_bodyparts = list("ipc_screen" = "Blank", "ipc_antenna" = "None")
	meat = /obj/item/reagent_containers/food/snacks/meat/slab/human/mutant/ipc
	gib_types = list(/obj/effect/gibspawner/ipc, /obj/effect/gibspawner/ipc/bodypartless)

	//Just robo looking parts.
	mutant_heart = /obj/item/organ/heart/ipc
	mutantlungs = /obj/item/organ/lungs/ipc
	mutantliver = /obj/item/organ/liver/ipc
	mutantstomach = /obj/item/organ/stomach/ipc
	mutanteyes = /obj/item/organ/eyes/ipc
	mutantears = /obj/item/organ/ears/ipc
	mutanttongue = /obj/item/organ/tongue/robot/ipc
	mutant_brain = /obj/item/organ/brain/ipc

	//special cybernetic organ for getting power from apcs
	mutant_organs = list(/obj/item/organ/cyberimp/arm/power_cord)

	exotic_bloodtype = "HF"
	exotic_blood_color = BLOOD_COLOR_OIL
	species_type = "robotic"

//	var/datum/action/innate/monitor_change/screen
/* Furry no more!
/datum/species/synthfurry/ipc/on_species_gain(mob/living/carbon/human/C)
	if(isipcperson(C) && !screen)
		screen = new
		screen.Grant(C)
	..()

/datum/species/synthfurry/ipc/on_species_loss(mob/living/carbon/human/C)
	if(screen)
		screen.Remove(C)
	..()

/datum/action/innate/monitor_change
	name = "Screen Change"
	check_flags = AB_CHECK_CONSCIOUS
	icon_icon = 'icons/mob/actions/actions_silicon.dmi'
	button_icon_state = "drone_vision"

/datum/action/innate/monitor_change/Activate()
	var/mob/living/carbon/human/H = owner
	var/new_ipc_screen = input(usr, "Choose your character's screen:", "Monitor Display") as null|anything in GLOB.ipc_screens_list
	if(!new_ipc_screen)
		return
	H.dna.features["ipc_screen"] = new_ipc_screen
	H.update_body()
*/
/datum/species/c27/spec_life(mob/living/carbon/human/H)
	if(H.nutrition < NUTRITION_LEVEL_FED)
		H.nutrition = NUTRITION_LEVEL_FED
	if(H.nutrition > NUTRITION_LEVEL_FED)
		H.nutrition = NUTRITION_LEVEL_FED

/datum/species/c27/handle_mutations_and_radiation(mob/living/carbon/human/H)
	return FALSE

//datum/species/c27/handle_chemicals(datum/reagent/chem, mob/living/carbon/human/H)
//	if(istype(chem) && !chem.synthfriendly)
//		H.reagents.remove_reagent(chem.type, REAGENTS_METABOLISM * 1000)
//	return ..()

/datum/species/c27/qualifies_for_rank(rank, list/features)
	if(rank in GLOB.legion_positions)
		return 0
	if(rank in GLOB.brotherhood_positions)
		// Allow Corporal and below ranks
		if(rank in list(
					"Knight"))
			return 1
		return 0
	if(rank in GLOB.vault_positions)
		return 0
	if(rank in GLOB.ncr_positions)
		// Allow Trooper and below ranks
		if(rank in list(
					"NCR Rear Echelon",
					"NCR Conscript",
					"NCR Trooper"))
			return 1
		return 0  // Block higher NCR ranks
//	if(rank in GLOB.wasteland_positions)
//		return 0
//	if(rank in GLOB.outlaw_positions) 
//		return 0
	if(rank in GLOB.khan_positions) 
		return 0
	if(rank in GLOB.enclave_positions) 
		return 0
	if(rank in GLOB.locust_positions) 
		return 0
	if(rank in GLOB.atlantic_positions) 
		return 0
	if(rank in GLOB.followers_positions) 
		return 0
	if(rank in GLOB.tribal_positions) 
		return 0
	return ..()
