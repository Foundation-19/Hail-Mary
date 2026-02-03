/datum/surgery/advanced/bioware/combat_profile
	name = "Combat Profile Implantation"
	desc = "A dangerous and unethical augmentation line that rewires combat response pathways. \
	These upgrades create terrifying specialists with hard physiological tradeoffs."
	possible_locs = list(BODY_ZONE_CHEST)
	bioware_target = BIOWARE_COMBAT_PROFILE
	requires_trait = "UNETHICAL_PRACTITIONER"

/datum/surgery/advanced/bioware/combat_profile/warform
	name = "Warform Lacing"
	desc = "Reinforces endocrine and musculoskeletal pathways for close-quarters violence. \
	Greatly improves melee lethality and stun resistance, but destabilizes thermal tolerance and appetite."
	steps = list(/datum/surgery_step/incise,
				/datum/surgery_step/retract_skin,
				/datum/surgery_step/clamp_bleeders,
				/datum/surgery_step/incise,
				/datum/surgery_step/incise,
				/datum/surgery_step/install_warform_lacing,
				/datum/surgery_step/close)

/datum/surgery_step/install_warform_lacing
	name = "lace combat endocrine pathways"
	accept_hand = TRUE
	time = 170

/datum/surgery_step/install_warform_lacing/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, span_notice("You begin weaving reinforced combat lacing through [target]'s endocrine network."),
		"[user] starts weaving reinforced combat lacing through [target]'s endocrine network.",
		"[user] starts making extensive changes to [target]'s endocrine system.")

/datum/surgery_step/install_warform_lacing/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, span_notice("You finish installing a warform combat profile into [target]'s body."),
		"[user] installs a warform combat profile into [target]'s body.",
		"[user] completes major combat-focused surgery on [target].")
	new /datum/bioware/combat_profile/warform_lacing(target)
	return TRUE

/datum/bioware/combat_profile
	name = "Combat Profile"
	desc = "A specialized combat bioware profile."
	mod_type = BIOWARE_COMBAT_PROFILE

/datum/bioware/combat_profile/warform_lacing
	name = "Warform Lacing"
	desc = "Close-quarters endocrine priming and reinforced strike pathways. \
	Exceptional in melee engagements, but thermally unstable and metabolically demanding."

/datum/bioware/combat_profile/warform_lacing/on_gain()
	..()
	ADD_TRAIT(owner, TRAIT_BIG_LEAGUES, "warform_lacing")
	ADD_TRAIT(owner, TRAIT_IRONFIST, "warform_lacing")
	ADD_TRAIT(owner, TRAIT_POOR_AIM, "warform_lacing")
	owner.physiology.stun_mod *= 0.8
	owner.physiology.stamina_mod *= 0.85
	owner.physiology.burn_mod *= 1.2
	owner.physiology.hunger_mod *= 1.7

/datum/bioware/combat_profile/warform_lacing/on_lose()
	..()
	REMOVE_TRAIT(owner, TRAIT_BIG_LEAGUES, "warform_lacing")
	REMOVE_TRAIT(owner, TRAIT_IRONFIST, "warform_lacing")
	REMOVE_TRAIT(owner, TRAIT_POOR_AIM, "warform_lacing")
	owner.physiology.stun_mod /= 0.8
	owner.physiology.stamina_mod /= 0.85
	owner.physiology.burn_mod /= 1.2
	owner.physiology.hunger_mod /= 1.7

/datum/surgery/advanced/bioware/combat_profile/deadeye
	name = "Deadeye Weave"
	desc = "Rewires sensorimotor timing and visual processing for ballistic precision. \
	Markedly improves ranged weapon performance, but leaves the user physically fragile in close combat."
	steps = list(/datum/surgery_step/incise,
				/datum/surgery_step/retract_skin,
				/datum/surgery_step/clamp_bleeders,
				/datum/surgery_step/incise,
				/datum/surgery_step/incise,
				/datum/surgery_step/install_deadeye_weave,
				/datum/surgery_step/close)

/datum/surgery_step/install_deadeye_weave
	name = "weave precision motor lattice"
	accept_hand = TRUE
	time = 170

/datum/surgery_step/install_deadeye_weave/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, span_notice("You start threading a precision motor lattice through [target]'s chest and neck pathways."),
		"[user] starts threading a precision motor lattice through [target]'s chest and neck pathways.",
		"[user] begins precise neuromotor surgery on [target].")

/datum/surgery_step/install_deadeye_weave/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, span_notice("You finalize a deadeye combat profile for [target]."),
		"[user] finalizes a deadeye combat profile for [target].",
		"[user] completes precise combat neurosurgery on [target].")
	new /datum/bioware/combat_profile/deadeye_weave(target)
	return TRUE

/datum/bioware/combat_profile/deadeye_weave
	name = "Deadeye Weave"
	desc = "Ballistic optimization profile that stabilizes aiming and shot placement. \
	The user becomes significantly weaker in melee pressure and sustained brawls."

/datum/bioware/combat_profile/deadeye_weave/on_gain()
	..()
	ADD_TRAIT(owner, TRAIT_NICE_SHOT, "deadeye_weave")
	ADD_TRAIT(owner, TRAIT_WIMPY, "deadeye_weave")
	owner.physiology.stun_mod *= 0.85
	owner.physiology.brute_mod *= 1.2
	owner.physiology.stamina_mod *= 1.2

/datum/bioware/combat_profile/deadeye_weave/on_lose()
	..()
	REMOVE_TRAIT(owner, TRAIT_NICE_SHOT, "deadeye_weave")
	REMOVE_TRAIT(owner, TRAIT_WIMPY, "deadeye_weave")
	owner.physiology.stun_mod /= 0.85
	owner.physiology.brute_mod /= 1.2
	owner.physiology.stamina_mod /= 1.2

/datum/surgery/advanced/bioware/combat_profile/juggernaut
	name = "Juggernaut Plating"
	desc = "Builds dense layered bioplating and reinforced connective channels to create a walking tank. \
	Greatly improves durability, but severely strains oxygen delivery and mobility."
	steps = list(/datum/surgery_step/incise,
				/datum/surgery_step/retract_skin,
				/datum/surgery_step/clamp_bleeders,
				/datum/surgery_step/incise,
				/datum/surgery_step/incise,
				/datum/surgery_step/install_juggernaut_plating,
				/datum/surgery_step/close)

/datum/surgery_step/install_juggernaut_plating
	name = "install dense bioplating lattice"
	accept_hand = TRUE
	time = 190

/datum/surgery_step/install_juggernaut_plating/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, span_notice("You begin anchoring dense bioplating through [target]'s thoracic frame."),
		"[user] begins anchoring dense bioplating through [target]'s thoracic frame.",
		"[user] starts heavy reinforcement surgery on [target].")

/datum/surgery_step/install_juggernaut_plating/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, span_notice("You complete juggernaut plating for [target]."),
		"[user] completes juggernaut plating for [target].",
		"[user] finishes extensive reinforcement surgery on [target].")
	new /datum/bioware/combat_profile/juggernaut_plating(target)
	return TRUE

/datum/bioware/combat_profile/juggernaut_plating
	name = "Juggernaut Plating"
	desc = "Dense layered biological armor that soaks punishment. \
	The user becomes slow, always hungry, and vulnerable to toxins and oxygen stress."

/datum/bioware/combat_profile/juggernaut_plating/on_gain()
	..()
	ADD_TRAIT(owner, TRAIT_NODISMEMBER, "juggernaut_plating")
	ADD_TRAIT(owner, TRAIT_NORUNNING, "juggernaut_plating")
	owner.physiology.brute_mod *= 0.75
	owner.physiology.burn_mod *= 0.9
	owner.physiology.tox_mod *= 1.3
	owner.physiology.oxy_mod *= 1.2
	owner.physiology.hunger_mod *= 1.5

/datum/bioware/combat_profile/juggernaut_plating/on_lose()
	..()
	REMOVE_TRAIT(owner, TRAIT_NODISMEMBER, "juggernaut_plating")
	REMOVE_TRAIT(owner, TRAIT_NORUNNING, "juggernaut_plating")
	owner.physiology.brute_mod /= 0.75
	owner.physiology.burn_mod /= 0.9
	owner.physiology.tox_mod /= 1.3
	owner.physiology.oxy_mod /= 1.2
	owner.physiology.hunger_mod /= 1.5
