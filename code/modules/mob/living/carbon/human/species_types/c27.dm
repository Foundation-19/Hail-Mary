/datum/species/c27
	name = "C-27"
	id = "c27"
	limbs_id = "c27"
//	icon_limbs = "c27"
	say_mod = "beeps"
	default_color = "00FF00"
	blacklisted = 0
	speedmod = 0.6 // heavy and deliberate but steady; they can't sprint, so this is their whole pace (human jog ~2.3 delay, C-27 ~2.6)
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
		NOBLOOD,
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
		TRAIT_PA_WEAR,
		TRAIT_NOHUNGER,
		TRAIT_TOXINIMMUNE,
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
/datum/movespeed_modifier/c27_low_power
	multiplicative_slowdown = C27_LOW_POWER_SLOWDOWN

/datum/movespeed_modifier/c27_servo_burst
	multiplicative_slowdown = C27_BURST_SLOWDOWN

/datum/species/c27
	var/datum/action/innate/c27_servo_burst/burst_action

/datum/species/c27/on_species_gain(mob/living/carbon/human/C, datum/species/old_species)
	. = ..()
	C.nutrition = NUTRITION_LEVEL_FED
	C.physiology.siemens_coeff *= C27_SHOCK_COEFF
	burst_action = new
	burst_action.Grant(C)

/datum/species/c27/on_species_loss(mob/living/carbon/human/C)
	C.physiology.siemens_coeff /= C27_SHOCK_COEFF
	C.remove_movespeed_modifier(/datum/movespeed_modifier/c27_low_power)
	C.remove_movespeed_modifier(/datum/movespeed_modifier/c27_servo_burst)
	if(burst_action)
		burst_action.Remove(C)
		QDEL_NULL(burst_action)
	return ..()

// Charge is a real resource: it drains with activity (see handle_digestion) and is refilled at APCs with the power cord.
/datum/species/c27/spec_life(mob/living/carbon/human/H)
	if(H.stat == DEAD)
		return
	if(H.nutrition < NUTRITION_LEVEL_STARVING)
		if(!H.has_movespeed_modifier(/datum/movespeed_modifier/c27_low_power))
			to_chat(H, span_userdanger("Warning: power reserves critical. Actuators throttled."))
			H.add_movespeed_modifier(/datum/movespeed_modifier/c27_low_power)
		if(H.nutrition < C27_SHUTDOWN_LEVEL && prob(5))
			to_chat(H, span_userdanger("Power failure! Systems rebooting..."))
			H.Paralyze(30)
	else
		H.remove_movespeed_modifier(/datum/movespeed_modifier/c27_low_power)
		// Maintenance nanites patch up damage, but only while there is power to spare
		if(H.nutrition >= NUTRITION_LEVEL_FED && (H.getBruteLoss() || H.getFireLoss()))
			H.adjustBruteLoss(-C27_REPAIR_RATE, FALSE, include_roboparts = TRUE)
			H.adjustFireLoss(-C27_REPAIR_RATE, FALSE, include_roboparts = TRUE)
			H.adjust_nutrition(-C27_REPAIR_RATE)

/// Short burst of speed that replaces the locked sprint
/datum/action/innate/c27_servo_burst
	name = "Servo Burst"
	desc = "Overdrive your leg servos for a few seconds. Costs charge and needs time to cool down."
	check_flags = AB_CHECK_CONSCIOUS
	icon_icon = 'icons/mob/actions/actions_silicon.dmi'
	button_icon_state = "drone_vision"
	var/next_use = 0

/datum/action/innate/c27_servo_burst/Activate()
	var/mob/living/carbon/human/H = owner
	if(world.time < next_use)
		to_chat(H, span_warning("Servos are still cooling down."))
		return
	if(H.nutrition < NUTRITION_LEVEL_HUNGRY)
		to_chat(H, span_warning("Not enough charge for a servo burst."))
		return
	next_use = world.time + C27_BURST_COOLDOWN
	H.adjust_nutrition(-C27_BURST_COST)
	H.add_movespeed_modifier(/datum/movespeed_modifier/c27_servo_burst)
	to_chat(H, span_notice("Your leg servos whine as they overdrive."))
	addtimer(CALLBACK(src, .proc/end_burst), C27_BURST_DURATION)

/datum/action/innate/c27_servo_burst/proc/end_burst()
	if(!owner)
		return
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/c27_servo_burst)
	to_chat(owner, span_warning("Servos throttle back down."))

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
	if(rank in GLOB.ranger_positions)
		return 0
	if(rank in GLOB.mutant_positions)
		return 0
	return ..()
