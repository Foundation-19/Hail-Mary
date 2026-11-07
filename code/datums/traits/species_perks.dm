//Species rules for perks and traits. Ghouls, Super Mutants and C-27s are not humans, so perks built around
//human biology (eating, breathing, bleeding, radiation) are hidden from them in chargen, and each gets perks
//of its own. A quirk can also set species_whitelist (exclusive to those species) or species_mults (shared perk,
//stronger or weaker depending on what you are). Species ids: "human", "ghoul", "smutant", "c27".

GLOBAL_LIST_INIT(quirk_species_blacklist, build_quirk_species_blacklist())

/proc/build_quirk_species_blacklist()
	//the Wasteland's radiation doesn't touch them, so resisting it is pointless
	var/list/radiation = list(
		/datum/quirk/radresist_rank1,
		/datum/quirk/radresist_rank2,
		/datum/quirk/radresist_rank3,
		/datum/quirk/blooddeficiency,
	)
	//no blood to lose or thicken
	var/list/blood = list(
		/datum/quirk/bloodpressure,
		/datum/quirk/modular/hemophilia,
	)
	//no lungs to speak of
	var/list/breathing = list(
		/datum/quirk/modular/steady_breather,
		/datum/quirk/modular/weak_lungs,
	)
	//ghouls and C-27s don't need food, and the stomach perks are about what a stomach does
	var/list/eating = list(
		/datum/quirk/voracious,
		/datum/quirk/modular/big_appetite,
		/datum/quirk/modular/trait_fast_metabolism,
		/datum/quirk/modular/iron_stomach,
		/datum/quirk/modular/delicate_stomach,
	)
	//robots have no thirst, no taste buds, no gut and no liver
	var/list/machine_body = list(
		/datum/quirk/modular/water_wise,
		/datum/quirk/modular/dehydrated,
		/datum/quirk/modular/leadbelly_rank1,
		/datum/quirk/modular/leadbelly_rank2,
		/datum/quirk/modular/leadbelly_rank3,
		/datum/quirk/no_taste,
		/datum/quirk/snob,
		/datum/quirk/pineapple_liker,
		/datum/quirk/pineapple_hater,
		/datum/quirk/deviant_tastes,
		/datum/quirk/vegetarian,
		/datum/quirk/horrifying_tastes,
		/datum/quirk/autobrew,
		/datum/quirk/nukalover,
		/datum/quirk/alcohol_intolerance,
		/datum/quirk/drunkhealing,
		/datum/quirk/trait_iron_liver,
		/datum/quirk/modular/poor_immune_system,
		/datum/quirk/modular/thick_skinned,
		/datum/quirk/tribal,
		/datum/quirk/modular/trait_tribal_roots,
	)
	//a super mutant is a walking wall: frailty perks make no sense on one
	var/list/frailty = list(
		/datum/quirk/trait_small_frame,
		/datum/quirk/flimsy,
		/datum/quirk/veryflimsy,
		/datum/quirk/paper_skin,
		/datum/quirk/modular/glass_jaw,
		/datum/quirk/modular/fragile,
		/datum/quirk/modular/weak_back,
		/datum/quirk/modular/bad_back,
		/datum/quirk/wimpy,
		/datum/quirk/gentle,
		/datum/quirk/modular/pushover,
		/datum/quirk/noodle_fist,
	)
	//liabilities about flesh and fluids that a machine can't have
	var/list/robot_liabilities = list(
		/datum/quirk/modular/squeamish,
		/datum/quirk/modular/heat_intolerant,
		/datum/quirk/modular/chronic_pain,
		/datum/quirk/brainproblems,
		/datum/quirk/paper_skin,
		/datum/quirk/trait_small_frame,
		/datum/quirk/trait_night_owl,
	)
	//how a living body takes chems and healing; a robot has no metabolism, tolerance or veins to react
	var/list/body_chemistry = list(
		/datum/quirk/modular/hardy_metabolism,
		/datum/quirk/modular/seasoned_user,
		/datum/quirk/modular/cast_iron_constitution,
		/datum/quirk/modular/frail_constitution,
		/datum/quirk/modular/needle_phobia,
		/datum/quirk/modular/clean_living,
		/datum/quirk/modular/careful_dosing,
		/datum/quirk/modular/detox_specialist,
		/datum/quirk/modular/adrenaline_management,
		/datum/quirk/modular/slow_healer,
	)
	return list(
		"ghoul" = radiation + blood + breathing + eating,
		"smutant" = radiation + frailty,
		"c27" = radiation + blood + breathing + eating + machine_body + robot_liabilities + body_chemistry,
	)

///Whether a species may take the given quirk typepath. Species-exclusive perks list their species, everything else is open unless blacklisted above
/proc/quirk_allowed_for_species(datum/quirk/quirk_path, species_id)
	var/whitelist = initial(quirk_path.species_whitelist)
	if(whitelist && whitelist != species_id)
		return FALSE
	var/list/banned = GLOB.quirk_species_blacklist[species_id]
	if(banned && (quirk_path in banned))
		return FALSE
	return TRUE

/* ------------------------------------ Ghoul ------------------------------------ */

/datum/quirk/ghoul_leathery_hide
	name = "Leathery Hide"
	desc = "Decades of radiation have turned your skin to old leather. You take 10% less brute and burn damage. Ghouls only."
	value = 3
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 5
	species_whitelist = "ghoul"
	gain_text = span_notice("Your skin feels tougher than old boot leather.")
	lose_text = span_danger("Your hide feels thinner than it used to.")
	locked = TRUE

/datum/quirk/ghoul_leathery_hide/add()
	var/mob/living/carbon/human/H = quirk_holder
	H.physiology.brute_mod *= 0.9
	H.physiology.burn_mod *= 0.9

/datum/quirk/ghoul_leathery_hide/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H?.physiology)
		H.physiology.brute_mod /= 0.9
		H.physiology.burn_mod /= 0.9

/datum/quirk/ghoul_necrotic_mending
	name = "Necrotic Mending"
	desc = "Your rotting flesh knits itself back together, slowly. You steadily recover from cuts and burns while hurt. Ghouls only."
	value = 3
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 6
	species_whitelist = "ghoul"
	gain_text = span_notice("Your flesh crawls as it starts to knit itself together.")
	lose_text = span_danger("Your flesh stops mending itself.")
	locked = TRUE

/datum/quirk/ghoul_necrotic_mending/on_process()
	var/mob/living/carbon/human/H = quirk_holder
	if(H.stat == DEAD || H.health >= H.maxHealth)
		return
	H.heal_overall_damage(0.15, 0.15, updating_health = TRUE)

/* ---------------------------------- Super Mutant ---------------------------------- */

/datum/quirk/smutant_hulking_frame
	name = "Hulking Frame"
	desc = "FEV gave you far more body than a man needs. Gain +30 maximum Health. Super Mutants only."
	value = 3
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 6
	species_whitelist = "smutant"
	gain_text = span_notice("You flex, and every muscle answers.")
	lose_text = span_danger("Your frame feels smaller than it did.")
	locked = TRUE
	var/hp_applied = 0

/datum/quirk/smutant_hulking_frame/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	hp_applied = 30
	H.maxHealth += hp_applied
	H.health += hp_applied

/datum/quirk/smutant_hulking_frame/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H)
		H.maxHealth -= hp_applied
		H.health = min(H.health, H.maxHealth)

/datum/quirk/smutant_fev_vigor
	name = "FEV Vigor"
	desc = "The virus keeps your muscles fed and fresh. You take 15% less stamina damage, so you tire and stagger less. Super Mutants only."
	value = 3
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 6
	species_whitelist = "smutant"
	gain_text = span_notice("You feel like you could brawl for a week.")
	lose_text = span_danger("You tire more easily than you remember.")
	locked = TRUE

/datum/quirk/smutant_fev_vigor/add()
	var/mob/living/carbon/human/H = quirk_holder
	H.physiology.stamina_mod *= 0.85

/datum/quirk/smutant_fev_vigor/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H?.physiology)
		H.physiology.stamina_mod /= 0.85

/* ------------------------------------- C-27 ------------------------------------- */

/datum/quirk/c27_reinforced_chassis
	name = "Reinforced Chassis"
	desc = "Extra plating has been bolted over your vital systems. You take 10% less brute damage. C-27s only."
	value = 3
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 5
	species_whitelist = "c27"
	gain_text = span_notice("Your chassis settles under a fresh layer of plating.")
	lose_text = span_danger("Your extra plating has been stripped away.")
	locked = TRUE

/datum/quirk/c27_reinforced_chassis/add()
	var/mob/living/carbon/human/H = quirk_holder
	H.physiology.brute_mod *= 0.9

/datum/quirk/c27_reinforced_chassis/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H?.physiology)
		H.physiology.brute_mod /= 0.9

/datum/quirk/c27_self_repair
	name = "Self-Repair Routines"
	desc = "Your maintenance routines kick in when you are badly damaged, slowly patching cuts and burns once you are below half health. C-27s only."
	value = 3
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 5
	species_whitelist = "c27"
	gain_text = span_notice("Your repair routines come online.")
	lose_text = span_danger("Your repair routines have been wiped.")
	locked = TRUE

/datum/quirk/c27_self_repair/on_process()
	var/mob/living/carbon/human/H = quirk_holder
	if(H.stat == DEAD || H.health > H.maxHealth * 0.5)
		return
	H.heal_overall_damage(0.25, 0.25, updating_health = TRUE)

/* ---------------------------- Species liabilities ---------------------------- */
//Each species can also earn Perk Points back with a drawback that fits its body.

/datum/quirk/modular/ghoul_withered_frame
	name = "Withered Frame"
	desc = "Your flesh has rotted thin over the years. You take 10% more brute damage. Ghouls only."
	value = -2
	species_whitelist = "ghoul"
	physio_mult = list("brute_mod" = 1.1)
	gain_text = span_danger("Your wasted body feels like paper.")
	lose_text = span_notice("Your body feels sturdier.")

/datum/quirk/modular/ghoul_stiff_joints
	name = "Stiff Joints"
	desc = "Your joints have set like old leather. -1 Agility. Ghouls only."
	value = -1
	species_whitelist = "ghoul"
	special_mods = list("a" = -1)
	gain_text = span_danger("Your joints creak and grind.")
	lose_text = span_notice("Your joints loosen up.")

/datum/quirk/modular/smutant_mutant_appetite
	name = "Mutant Appetite"
	desc = "All that muscle has to be fed. You get hungry 30% faster. Super Mutants only."
	value = -1
	species_whitelist = "smutant"
	physio_mult = list("hunger_mod" = 1.3)
	gain_text = span_danger("Your stomach growls like a deathclaw.")
	lose_text = span_notice("Your appetite settles down.")

/datum/quirk/modular/smutant_crude_mind
	name = "Crude Mind"
	desc = "FEV took more from your head than it gave your body. -2 Intelligence. Super Mutants only."
	value = -2
	species_whitelist = "smutant"
	special_mods = list("i" = -2)
	gain_text = span_danger("Big thoughts slip away from you.")
	lose_text = span_notice("Your head feels clearer.")

/datum/quirk/modular/c27_brittle_plating
	name = "Brittle Plating"
	desc = "Your chassis plating is worn and cracked. You take 10% more brute damage. C-27s only."
	value = -2
	species_whitelist = "c27"
	physio_mult = list("brute_mod" = 1.1)
	gain_text = span_danger("Your plating rattles loose.")
	lose_text = span_notice("Your plating has been patched up.")

/datum/quirk/modular/c27_glitchy_optics
	name = "Glitchy Optics"
	desc = "Your optical sensors flicker and drift. -1 Perception. C-27s only."
	value = -1
	species_whitelist = "c27"
	special_mods = list("p" = -1)
	gain_text = span_danger("Your vision flickers with static.")
	lose_text = span_notice("Your optics settle down.")

//Called when a living mob's species changes mid-round: perks that don't suit the new body fall away
/mob/living/carbon/human/proc/drop_unsuitable_quirks()
	var/species_id = dna?.species?.id
	if(!species_id)
		return
	for(var/datum/quirk/Q in roundstart_quirks.Copy())
		if(!quirk_allowed_for_species(Q.type, species_id))
			to_chat(src, span_warning("Your new body can't keep '[Q.name]'."))
			qdel(Q)

/* ------------------------- Species perk upgrades (rank II) ------------------------- */
//A rank-up replaces the lower perk, so each of these carries the full effect on its own.

/datum/quirk/ghoul_leathery_hide_ii
	name = "Leathery Hide II"
	desc = "Your hide is now tougher than armor plate. You take 20% less brute and burn damage. Requires Leathery Hide. Ghouls only."
	value = 5
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 7
	requires_quirk = "Leathery Hide"
	species_whitelist = "ghoul"
	gain_text = span_notice("Your skin has gone as hard as tire rubber.")
	lose_text = span_danger("Your hide softens.")
	locked = TRUE

/datum/quirk/ghoul_leathery_hide_ii/add()
	var/mob/living/carbon/human/H = quirk_holder
	H.physiology.brute_mod *= 0.8
	H.physiology.burn_mod *= 0.8

/datum/quirk/ghoul_leathery_hide_ii/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H?.physiology)
		H.physiology.brute_mod /= 0.8
		H.physiology.burn_mod /= 0.8

/datum/quirk/ghoul_necrotic_mending_ii
	name = "Necrotic Mending II"
	desc = "Your rotting flesh knits itself back together twice as fast. Requires Necrotic Mending. Ghouls only."
	value = 5
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 8
	requires_quirk = "Necrotic Mending"
	species_whitelist = "ghoul"
	gain_text = span_notice("Your flesh knits itself together in earnest.")
	lose_text = span_danger("Your flesh mends more slowly again.")
	locked = TRUE

/datum/quirk/ghoul_necrotic_mending_ii/on_process()
	var/mob/living/carbon/human/H = quirk_holder
	if(H.stat == DEAD || H.health >= H.maxHealth)
		return
	H.heal_overall_damage(0.3, 0.3, updating_health = TRUE)

/datum/quirk/smutant_hulking_frame_ii
	name = "Hulking Frame II"
	desc = "You are a walking wall of muscle. Gain +60 maximum Health. Requires Hulking Frame. Super Mutants only."
	value = 5
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 8
	requires_quirk = "Hulking Frame"
	species_whitelist = "smutant"
	gain_text = span_notice("You feel like nothing could knock you down.")
	lose_text = span_danger("Your frame shrinks back down.")
	locked = TRUE
	var/hp_applied = 0

/datum/quirk/smutant_hulking_frame_ii/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	hp_applied = 60
	H.maxHealth += hp_applied
	H.health += hp_applied

/datum/quirk/smutant_hulking_frame_ii/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H)
		H.maxHealth -= hp_applied
		H.health = min(H.health, H.maxHealth)

/datum/quirk/smutant_fev_vigor_ii
	name = "FEV Vigor II"
	desc = "You almost never run out of breath. You take 30% less stamina damage. Requires FEV Vigor. Super Mutants only."
	value = 5
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 8
	requires_quirk = "FEV Vigor"
	species_whitelist = "smutant"
	gain_text = span_notice("You could brawl for a month.")
	lose_text = span_danger("You tire more easily again.")
	locked = TRUE

/datum/quirk/smutant_fev_vigor_ii/add()
	var/mob/living/carbon/human/H = quirk_holder
	H.physiology.stamina_mod *= 0.7

/datum/quirk/smutant_fev_vigor_ii/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H?.physiology)
		H.physiology.stamina_mod /= 0.7

/datum/quirk/c27_reinforced_chassis_ii
	name = "Reinforced Chassis II"
	desc = "A full set of heavy plating covers your chassis. You take 20% less brute damage. Requires Reinforced Chassis. C-27s only."
	value = 5
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 7
	requires_quirk = "Reinforced Chassis"
	species_whitelist = "c27"
	gain_text = span_notice("Heavy plating locks into place over your chassis.")
	lose_text = span_danger("Your heavy plating has been stripped away.")
	locked = TRUE

/datum/quirk/c27_reinforced_chassis_ii/add()
	var/mob/living/carbon/human/H = quirk_holder
	H.physiology.brute_mod *= 0.8

/datum/quirk/c27_reinforced_chassis_ii/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H?.physiology)
		H.physiology.brute_mod /= 0.8

/datum/quirk/c27_self_repair_ii
	name = "Self-Repair Routines II"
	desc = "Your repair routines run twice as fast and start sooner, below 60% health. Requires Self-Repair Routines. C-27s only."
	value = 5
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 7
	requires_quirk = "Self-Repair Routines"
	species_whitelist = "c27"
	gain_text = span_notice("Your repair routines are upgraded.")
	lose_text = span_danger("Your repair routines revert to the old version.")
	locked = TRUE

/datum/quirk/c27_self_repair_ii/on_process()
	var/mob/living/carbon/human/H = quirk_holder
	if(H.stat == DEAD || H.health > H.maxHealth * 0.6)
		return
	H.heal_overall_damage(0.5, 0.5, updating_health = TRUE)

/* -------------------------- More species liabilities -------------------------- */

/datum/quirk/modular/ghoul_parched_husk
	name = "Parched Husk"
	desc = "Your dried-out body drinks water like a sponge. You get thirsty 30% faster. Ghouls only."
	value = -1
	species_whitelist = "ghoul"
	gain_text = span_danger("Your throat feels like sandpaper.")
	lose_text = span_notice("Your throat finally feels moist again.")

/datum/quirk/modular/ghoul_parched_husk/add()
	..()
	var/mob/living/carbon/human/H = quirk_holder
	H.dna.species.thirst_rate_mod *= 1.3

/datum/quirk/modular/ghoul_parched_husk/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H?.dna?.species)
		H.dna.species.thirst_rate_mod /= 1.3
	..()

/datum/quirk/modular/ghoul_shunned
	name = "Shunned"
	desc = "Smooth-skins flinch at the sight of you. -1 Charisma. Ghouls only."
	value = -1
	species_whitelist = "ghoul"
	special_mods = list("c" = -1)
	gain_text = span_danger("People look away when you walk past.")
	lose_text = span_notice("People seem a little more willing to look at you.")

/datum/quirk/modular/ghoul_brittle_limbs
	name = "Brittle Limbs"
	desc = "Your rotted body is easy to knock off its feet. You are stunned and knocked down 20% longer. Ghouls only."
	value = -1
	species_whitelist = "ghoul"
	physio_mult = list("stun_mod" = 1.2)
	gain_text = span_danger("Your body feels like it could crumble.")
	lose_text = span_notice("Your body feels a little sturdier.")

/datum/quirk/modular/smutant_thick_fingers
	name = "Thick Fingers"
	desc = "Your huge hands fumble with small things. Tasks that take time, like crafting and repairs, take 20% longer. Super Mutants only."
	value = -1
	species_whitelist = "smutant"
	physio_mult = list("do_after_speed" = 1.2)
	gain_text = span_danger("Everything small feels like a toy in your hands.")
	lose_text = span_notice("Your hands feel a little more nimble.")

/datum/quirk/modular/smutant_short_fuse
	name = "Short Fuse"
	desc = "Your rage burns through your stamina. You take 15% more stamina damage. Super Mutants only."
	value = -1
	species_whitelist = "smutant"
	physio_mult = list("stamina_mod" = 1.15)
	gain_text = span_danger("You feel one bad day away from smashing something.")
	lose_text = span_notice("Your temper cools down.")

/datum/quirk/modular/smutant_frightening_visage
	name = "Frightening Visage"
	desc = "Folks run screaming at the sight of you. -2 Charisma. Super Mutants only."
	value = -2
	species_whitelist = "smutant"
	special_mods = list("c" = -2)
	gain_text = span_danger("You look like something out of a nightmare.")
	lose_text = span_notice("Your face looks a little less monstrous.")

/datum/quirk/modular/c27_overheating_core
	name = "Overheating Core"
	desc = "Your cooling system is failing. You take 40% more heat damage. C-27s only."
	value = -1
	species_whitelist = "c27"
	physio_mult = list("heat_mod" = 1.4)
	gain_text = span_danger("Your core runs hot.")
	lose_text = span_notice("Your cooling system holds steady.")

/datum/quirk/modular/c27_corroded_wiring
	name = "Corroded Wiring"
	desc = "Frayed wiring leaves you wide open to shocks. You take 50% more damage from electricity. C-27s only."
	value = -1
	species_whitelist = "c27"
	physio_mult = list("siemens_coeff" = 1.5)
	gain_text = span_danger("Sparks crawl along your frayed wiring.")
	lose_text = span_notice("Your wiring has been re-sheathed.")

/datum/quirk/modular/c27_outdated_software
	name = "Outdated Software"
	desc = "Your programming is decades old and hard to update. -1 Intelligence. C-27s only."
	value = -1
	species_whitelist = "c27"
	special_mods = list("i" = -1)
	gain_text = span_danger("Your processes lag behind.")
	lose_text = span_notice("Your software feels up to date.")

/* ------------------- Perks that replace the flesh-and-blood ones ------------------- */
//C-27s can't take the body-chemistry perks, and chems do nothing for a machine, so these give the same kind of benefit in machine terms.

/datum/quirk/modular/c27_hardened_chassis
	name = "Heat-Sink Plating"
	desc = "Heat-sink plating carries fire and heat away from your vital systems. You take 10% less burn damage and 15% less heat damage. C-27s only."
	value = 2
	species_whitelist = "c27"
	physio_mult = list("burn_mod" = 0.9, "heat_mod" = 0.85)
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 6
	gain_text = span_notice("Heat-sink plating bolts onto your chassis.")
	lose_text = span_danger("Your heat-sink plating has been stripped off.")

/datum/quirk/modular/c27_shielded_circuits
	name = "Shielded Circuits"
	desc = "Your internals are well insulated. You take half as much damage from electric shocks and are stunned 10% less. C-27s only."
	value = 2
	species_whitelist = "c27"
	physio_mult = list("siemens_coeff" = 0.5, "stun_mod" = 0.9)
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 7
	gain_text = span_notice("Fresh shielding wraps your circuits.")
	lose_text = span_danger("Your shielding has worn thin.")

/datum/quirk/modular/c27_power_governor
	name = "Power Governor"
	desc = "A governor keeps your power draw inside safe limits. Stamina damage is reduced by 15%. C-27s only."
	value = 2
	species_whitelist = "c27"
	physio_mult = list("stamina_mod" = 0.85)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 6
	gain_text = span_notice("A power governor clicks into place.")
	lose_text = span_danger("Your power governor has been removed.")

/datum/quirk/modular/c27_servo_tuning
	name = "Servo Tuning"
	desc = "Your servos are tuned for fast, precise work. Timed actions such as crafting and repairs finish 10% quicker. C-27s only."
	value = 2
	species_whitelist = "c27"
	physio_mult = list("do_after_speed" = 0.9)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 7
	gain_text = span_notice("Your servos hum with fresh calibration.")
	lose_text = span_danger("Your servos drift out of tune.")

/datum/quirk/ghoul_radiation_feeder
	name = "Radiation Feeder"
	desc = "Your ruined body feeds on the radiation inside it, slowly mending cuts and burns while you are heavily irradiated. Ghouls only."
	value = 3
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 7
	species_whitelist = "ghoul"
	gain_text = span_notice("The radiation in you stops hurting and starts feeding you.")
	lose_text = span_danger("The radiation in you is just poison again.")

/datum/quirk/ghoul_radiation_feeder/on_process()
	var/mob/living/carbon/human/H = quirk_holder
	if(H.stat == DEAD || H.health >= H.maxHealth || H.radiation < 100)
		return
	H.heal_overall_damage(0.2, 0.2, updating_health = TRUE)
