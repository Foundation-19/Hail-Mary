//ghouls-heal from radiation, do not breathe. do not go into crit. terrible at melee, easily dismembered.
//cannot use medical chemicals to heal brute or burn, must heal from rads, sutures. can use antitoxin chemicals.  //actually changed my mind i'll give stims reduced effect instead
//Slower than humans at combat armor speed, appear dead. rotted organs unable to use for transplant.
//like before, they cannot take piercing wounds or burn wounds or slash wounds, but they can have their bones broken by any source of wound now instead of being impervious

// -------------------------
// Ghoul radiation scaling knobs
// TUNE THESE to your server's radiation numbers.
// Goal: no "free" healing at tiny rads; you need to actually be irradiated.
// -------------------------
#define GHOUL_RAD_HEAL_START     500      // below this: basically no healing
#define GHOUL_RAD_HEAL_FULL      2000     // at/above this: max healing
#define GHOUL_RAD_MELTDOWN_START 4000     // above this: instability begins (self-damage / clumsiness)
#define GHOUL_RAD_MELTDOWN_FULL  8000     // at/above this: meltdown at max intensity

#define GHOUL_HEAL_MIN           0        // healpwr at/under start
#define GHOUL_HEAL_MAX           8        // healpwr at full
#define GHOUL_GLOW_MIN           0
#define GHOUL_GLOW_MAX           3        // light intensity at full

#define GHOUL_MELTDOWN_BRUTE_MAX 2        // occasional self-brute at full meltdown
#define GHOUL_MELTDOWN_SLOW_MAX  0.10     // slows you back down at full meltdown (stacked on top)

// Below this, ghoul bodies begin to "starve" for radiation and degrade.
#define GHOUL_RAD_STARVE_START   250
#define GHOUL_STARVE_TOX_MAX     1.2
#define GHOUL_STARVE_CLONE_MAX   1

// -------------------------
// Ghoul radiation wave emission knobs
// Uses /datum/radiation_wave (SSradiation) so it respects shielding + insulation + falloff.
// IMPORTANT: wave strength must be >= 1 or your wave code's FLOOR() will zero it out.
// -------------------------
#define GHOUL_WAVE_PULSE_CD        30      // ticks; throttle. if your world.tick_lag=1 (10 TPS) -> ~3s
#define GHOUL_WAVE_MIN_FACTOR      0.20    // below this f, don't emit (note: f is squared)
#define GHOUL_WAVE_INTENSITY_MIN   4       // baseline wave intensity (MUST be >= 1)
#define GHOUL_WAVE_INTENSITY_MAX   22      // at full f (before meltdown multiplier)
#define GHOUL_WAVE_DIAGONALS_PROB  30      // % chance to emit diagonals per pulse
#define GHOUL_WAVE_CAN_CONTAMINATE TRUE    // flip to FALSE if contamination gets stupid fast
#define GHOUL_WAVE_RANGE_MOD       RAD_DISTANCE_COEFFICIENT

// Debug toggle (spammy). Leave FALSE unless you're diagnosing.
#define GHOUL_DEBUG_RADIATION FALSE

#define GHOUL_FEEDBACK_CD        (45 SECONDS)
#define GHOUL_FERAL_CONFUSED_MAX 14
#define GHOUL_FERAL_JITTER_MAX   10

// At higher meltdown, ferals stop treating the ghoul as prey.
// Hysteresis prevents rapid on/off flipping around threshold values.
#define GHOUL_FERAL_ALLY_ON      0.35
#define GHOUL_FERAL_ALLY_OFF     0.20

// -------------------------
// Per-mob throttle storage (REAL fix vs H.vars hacks)
// Declared on the mob type so it actually persists.
// -------------------------
/mob/living/carbon/human
	var/ghoul_wave_next = 0
	var/ghoul_feedback_next = 0
	var/ghoul_feral_ally = FALSE

// Smooth-ish 0..1 ramp with ease-in (needs real rads to matter)
/proc/ghoul_rad_factor(rads)
	if(rads <= GHOUL_RAD_HEAL_START)
		return 0
	var/t = (rads - GHOUL_RAD_HEAL_START) / (GHOUL_RAD_HEAL_FULL - GHOUL_RAD_HEAL_START)
	t = clamp(t, 0, 1)
	return t * t

/proc/ghoul_meltdown_factor(rads)
	if(rads <= GHOUL_RAD_MELTDOWN_START)
		return 0
	var/t = (rads - GHOUL_RAD_MELTDOWN_START) / (GHOUL_RAD_MELTDOWN_FULL - GHOUL_RAD_MELTDOWN_START)
	return clamp(t, 0, 1)

/proc/ghoul_starve_factor(rads)
	if(rads >= GHOUL_RAD_STARVE_START)
		return 0
	var/t = (GHOUL_RAD_STARVE_START - rads) / GHOUL_RAD_STARVE_START
	t = clamp(t, 0, 1)
	return t * t

// Variable movespeed modifier used by ghouls (rad-buffed or meltdown-dulled)
/datum/movespeed_modifier/ghoul_rad
	variable = TRUE
	id = "ghoul_rad"
	priority = 50


/datum/species/ghoul
	name = "Ghoul"
	id = "ghoul"
	say_mod = "rasps"
	limbs_id = "ghoul"
	species_traits = list(HAIR,FACEHAIR,HAS_BONE, NOBLOOD, MUTCOLORS, EYECOLOR,LIPS, HORNCOLOR,WINGCOLOR)
	inherent_traits = list(TRAIT_RADIMMUNE, TRAIT_VIRUSIMMUNE, TRAIT_NOBREATH, TRAIT_NOHARDCRIT, TRAIT_NOSOFTCRIT, TRAIT_GHOULMELEE, TRAIT_EASYDISMEMBER, TRAIT_EASYLIMBDISABLE, TRAIT_LIMBATTACHMENT)
	inherent_biotypes = list(MOB_ORGANIC, MOB_HUMANOID, MOB_BEAST)
	mutant_bodyparts = list("mcolor" = "FFFFFF","mcolor2" = "FFFFFF","mcolor3" = "FFFFFF", "mam_snouts" = "Husky", "mam_tail" = "Husky", "mam_ears" = "Husky", "deco_wings" = "None", "mam_body_markings" = "Husky", "taur" = "None", "horns" = "None", "legs" = "Plantigrade", "meat_type" = "Mammalian")
	attack_verb = "claw"
	punchstunthreshold = 9
	tail_type = "tail_human"
	wagging_type = "waggingtail_human"
	species_type = "human"

	allowed_limb_ids = list("human")
	use_skintones = 0
	speedmod = 0.3 //slightly slower than humans
	sexes = 1
	sharp_blunt_mod = 2
	sharp_edged_mod = 2
	disliked_food = NONE
	liked_food = NONE
	var/info_text = "You are a <span class='danger'>Ghoul.</span>. As pre-war zombified relic, or an unluckily recently made post-necrotic, you cannot bleed, cannot breathe, and heal from radiation. On surface examination, you are indistinguishable from a corpse. \
					Your <span class='warning'>fragile limbs</span> are a source of vulnerability for you-they are easily dismembered and easily detached, though you can stick them on just as easily. You are incredibly fragile in melee. \
					<span class='boldwarning'>Stimpaks and powder</span> will have reduced effect on your bizzare biology. Sutures, radiation, and other, non-chemical sources of healing are more effective. All chemicals that do not heal brute or burn work as normal. \
					<span class='nicegreen'>Radiation heals and empowers you.</span> Too little radiation now causes tissue decay, while too much can push you into feral instability. \
					At high meltdown, feral ghouls may temporarily identify you as one of their own. \
					<span class='warning'>You are terrible at melee</span> and innately slower than humans. You also cannot go into critical condition-ever. You will keep shambling forward until you are <span class='danger'>dead.</span>"


// -------------------------
// Radiation wave emitter (species-local)
// -------------------------
/datum/species/ghoul/proc/emit_radiation_waves(mob/living/carbon/human/H, f, m)
	if(!H || H.stat == DEAD)
		return

	// squared curve means f hits 0.20 later than you think; this gate is intentional.
	if(f < GHOUL_WAVE_MIN_FACTOR)
		return

	// Throttle per-mob (real var, not H.vars hack)
	if(world.time < H.ghoul_wave_next)
		return
	H.ghoul_wave_next = world.time + GHOUL_WAVE_PULSE_CD

	// Scale intensity with radiation factor
	var/intensity = round(GHOUL_WAVE_INTENSITY_MIN + ((GHOUL_WAVE_INTENSITY_MAX - GHOUL_WAVE_INTENSITY_MIN) * f))

	// Meltdown ramps output (danger loop)
	if(m > 0)
		intensity = round(intensity * (1 + (0.60 * m)))

	// HARD clamp: your wave code effectively needs >= 1 to do anything
	intensity = clamp(intensity, 1, GHOUL_WAVE_INTENSITY_MAX * 2)

	#if GHOUL_DEBUG_RADIATION
	world.log << "GHOUL DEBUG: [H] rads=[H.radiation] f=[f] m=[m] wave_intensity=[intensity]"
	#endif

	// Cross pattern (cheap + effective)
	new /datum/radiation_wave(H, NORTH, intensity, GHOUL_WAVE_RANGE_MOD, GHOUL_WAVE_CAN_CONTAMINATE)
	new /datum/radiation_wave(H, SOUTH, intensity, GHOUL_WAVE_RANGE_MOD, GHOUL_WAVE_CAN_CONTAMINATE)
	new /datum/radiation_wave(H, EAST,  intensity, GHOUL_WAVE_RANGE_MOD, GHOUL_WAVE_CAN_CONTAMINATE)
	new /datum/radiation_wave(H, WEST,  intensity, GHOUL_WAVE_RANGE_MOD, GHOUL_WAVE_CAN_CONTAMINATE)

	// Diagonals sometimes for "pulse" feel (more CPU, so probabilistic)
	if(prob(GHOUL_WAVE_DIAGONALS_PROB))
		var/diag = max(1, round(intensity * 0.75))
		new /datum/radiation_wave(H, NORTHEAST, diag, GHOUL_WAVE_RANGE_MOD, GHOUL_WAVE_CAN_CONTAMINATE)
		new /datum/radiation_wave(H, NORTHWEST, diag, GHOUL_WAVE_RANGE_MOD, GHOUL_WAVE_CAN_CONTAMINATE)
		new /datum/radiation_wave(H, SOUTHEAST, diag, GHOUL_WAVE_RANGE_MOD, GHOUL_WAVE_CAN_CONTAMINATE)
		new /datum/radiation_wave(H, SOUTHWEST, diag, GHOUL_WAVE_RANGE_MOD, GHOUL_WAVE_CAN_CONTAMINATE)

/datum/species/ghoul/proc/send_ghoul_feedback(mob/living/carbon/human/H, f, m, s)
	if(!H)
		return
	if(world.time < H.ghoul_feedback_next)
		return

	if(m >= 0.75)
		to_chat(H, span_warning("Your mind frays as feral instinct claws at your thoughts."))
	else if(s >= 0.65)
		to_chat(H, span_warning("Your necrotic flesh aches. You need radiation soon."))
	else if(f >= 0.75)
		to_chat(H, span_notice("Radiation invigorates your dead flesh."))
	else
		return

	H.ghoul_feedback_next = world.time + GHOUL_FEEDBACK_CD

/datum/species/ghoul/proc/update_feral_alignment(mob/living/carbon/human/H, m)
	if(!H)
		return
	if(!islist(H.faction))
		H.faction = list(H.faction)

	if(H.stat == DEAD || m <= GHOUL_FERAL_ALLY_OFF)
		if(H.ghoul_feral_ally)
			H.ghoul_feral_ally = FALSE
			H.faction -= "ghoul"
			if(H.stat != DEAD)
				to_chat(H, span_notice("Your scent settles. Nearby ferals will no longer mistake you for one of their own."))
		return

	if(m >= GHOUL_FERAL_ALLY_ON && !H.ghoul_feral_ally)
		H.ghoul_feral_ally = TRUE
		H.faction |= "ghoul"
		to_chat(H, span_warning("Feral instinct floods your senses. Wild ghouls now read you as kin."))


//Ghouls have weak limbs.
/datum/species/ghoul/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	..()
	to_chat(C, "[info_text]")
	for(var/obj/item/bodypart/r_arm/b in C.bodyparts)
		b.max_damage -= 20
		b.wound_resistance = -35
	for(var/obj/item/bodypart/l_arm/b in C.bodyparts)
		b.max_damage -= 20
		b.wound_resistance = -35
	for(var/obj/item/bodypart/r_leg/b in C.bodyparts)
		b.max_damage -= 20
		b.wound_resistance = -35
	for(var/obj/item/bodypart/l_leg/b in C.bodyparts)
		b.max_damage -= 20
		b.wound_resistance = -35
	for(var/obj/item/bodypart/head/b in C.bodyparts)
		b.max_damage -= 20
		b.wound_resistance = -35

	// reset wave throttle when becoming ghoul
	if(istype(C, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = C
		H.ghoul_wave_next = 0
		H.ghoul_feedback_next = 0
		H.ghoul_feral_ally = FALSE


/datum/species/ghoul/on_species_loss(mob/living/carbon/C)
	..()
	for(var/obj/item/bodypart/r_arm/b in C.bodyparts)
		b.max_damage = initial(b.max_damage)
		b.wound_resistance = initial(b.wound_resistance)
	for(var/obj/item/bodypart/l_arm/b in C.bodyparts)
		b.max_damage = initial(b.max_damage)
		b.wound_resistance = initial(b.wound_resistance)
	for(var/obj/item/bodypart/r_leg/b in C.bodyparts)
		b.max_damage = initial(b.max_damage)
		b.wound_resistance = initial(b.wound_resistance)
	for(var/obj/item/bodypart/l_leg/b in C.bodyparts)
		b.max_damage = initial(b.max_damage)
		b.wound_resistance = initial(b.wound_resistance)
	for(var/obj/item/bodypart/head/b in C.bodyparts)
		b.max_damage = initial(b.max_damage)
		b.wound_resistance = initial(b.wound_resistance)

	// remove our variable rad movespeed modifier so it can't linger
	if(istype(C, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = C
		if(H.ghoul_feral_ally)
			H.faction -= "ghoul"
			H.ghoul_feral_ally = FALSE
		H.remove_movespeed_modifier(/datum/movespeed_modifier/ghoul_rad)
		H.ghoul_wave_next = 0
		H.ghoul_feedback_next = 0


/datum/species/ghoul/qualifies_for_rank(rank, list/features)
	// blocks: faction ranks that should not be available
	if(rank in GLOB.legion_positions) /* legion HATES these ghoul */
		return 0
	if(rank in GLOB.brotherhood_positions) //don't hate them, just tolerate.
		return 0
	if(rank in GLOB.vault_positions) //purest humans left in america. supposedly.
		return 0
	if(rank in GLOB.mutant_positions)
		return 0
	return ..()


/datum/species/ghoul/handle_chemicals(datum/reagent/chem, mob/living/carbon/human/H)
	if(istype(chem) && !chem.ghoulfriendly)
		H.reagents.remove_reagent(chem.type, REAGENTS_METABOLISM * 1000)
		return TRUE
	if(chem.type == /datum/reagent/medicine/radaway)
		H.adjustBruteLoss(2)
		H.reagents.remove_reagent(chem.type, REAGENTS_METABOLISM)
		if(prob(5))
			to_chat(H, span_warning("You feel like taking radaway wasn't the best idea."))
	if(chem.type == /datum/reagent/medicine/radx)
		H.adjustBruteLoss(2)
		if(prob(5))
			to_chat(H, span_warning("You feel sick..."))
		H.reagents.remove_reagent(chem.type, REAGENTS_METABOLISM)
	if(chem.type == /datum/reagent/medicine/stimpak)
		H.adjustBruteLoss(1.5) // shitty quick fix: reduced healing
	if(chem.type == /datum/reagent/medicine/super_stimpak)
		H.adjustBruteLoss(2.5)
	return ..()


/datum/species/ghoul/spec_life(mob/living/carbon/human/H)
	..()
	if(!H)
		return

	#if GHOUL_DEBUG_RADIATION
	world.log << "GHOUL DEBUG: spec_life for [H] rads=[H.radiation] stat=[H.stat]"
	#endif

	if(H.stat == DEAD)
		update_feral_alignment(H, 0)
		H.set_light(0)
		H.remove_status_effect(/datum/status_effect/ghoulheal)
		H.remove_movespeed_modifier(/datum/movespeed_modifier/ghoul_rad)
		return

	var/r = H.radiation
	var/f = ghoul_rad_factor(r)          // 0..1 heal/glow/speed factor (squared)
	var/m = ghoul_meltdown_factor(r)     // 0..1 instability factor
	var/s = ghoul_starve_factor(r)       // 0..1 low-rad degradation factor

	// Deep meltdown makes feral ghouls treat this ghoul as kin.
	update_feral_alignment(H, m)

	// -----------------
	// Healing scales with radiation (not binary).
	// -----------------
	var/healpwr = 0
	if(f > 0)
		healpwr = round(GHOUL_HEAL_MIN + ((GHOUL_HEAL_MAX - GHOUL_HEAL_MIN) * f))

	// Meltdown = healing becomes unreliable + occasional self-brute.
	if(m > 0)
		if(prob(30 + round(40*m)))
			healpwr = max(0, healpwr - 3)

		if(prob(round(6 + 18*m)))
			H.adjustBruteLoss(rand(1, max(1, GHOUL_MELTDOWN_BRUTE_MAX)))

		H.confused = max(H.confused, round(2 + (GHOUL_FERAL_CONFUSED_MAX * m)))
		H.jitteriness = max(H.jitteriness, round(1 + (GHOUL_FERAL_JITTER_MAX * m)))
		H.slurring = max(H.slurring, round(1 + (6 * m)))

		// Deep feral instability causes occasional loss of movement control.
		if(m >= 0.70 && prob(round(6 + (12 * m))))
			step(H, pick(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))

	// Apply core ghoul sustain
	H.adjustCloneLoss(-healpwr)
	H.adjustToxLoss(-0.3) // ghouls always heal toxin very slowly no matter what
	H.adjustStaminaLoss(-20) // ghouls don't get tired ever
	H.heal_overall_damage(healpwr, healpwr, healpwr)

	// If radiation runs too low, ghoul tissue starts to decay.
	if(s > 0)
		var/starve_tox = 0.15 + (GHOUL_STARVE_TOX_MAX * s)
		H.adjustToxLoss(starve_tox)
		if(prob(round(20 + (50 * s))))
			H.adjustCloneLoss(round(1 + (GHOUL_STARVE_CLONE_MAX * s)))

	// -----------------
	// Glow scales with radiation
	// -----------------
	if(f <= 0)
		H.set_light(0)
		H.remove_status_effect(/datum/status_effect/ghoulheal)
	else
		var/glow = round(GHOUL_GLOW_MIN + ((GHOUL_GLOW_MAX - GHOUL_GLOW_MIN) * f))
		glow = clamp(glow, 1, GHOUL_GLOW_MAX)
		H.set_light(glow, 15, LIGHT_COLOR_GREEN)
		H.apply_status_effect(/datum/status_effect/ghoulheal)

	// -----------------
	// Speed: rad-charged ghouls move a bit better; meltdown makes you clumsy again.
	// -----------------
	var/speed_slowdown = 0

	if(s > 0)
		speed_slowdown += (0.04 + (0.10 * s))

	if(f > 0)
		speed_slowdown = -(0.04 + (0.06 * f)) // ~ -0.04 .. -0.10

	if(m > 0)
		speed_slowdown += (GHOUL_MELTDOWN_SLOW_MAX * m)

	H.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/ghoul_rad, TRUE, speed_slowdown)

	send_ghoul_feedback(H, f, m, s)

	// -----------------
	// NEW: emit real radiation waves (respects shielding/falloff/insulation)
	// -----------------
	emit_radiation_waves(H, f, m)

/datum/species/ghoul/spec_unarmedattacked(mob/living/carbon/human/user, mob/living/carbon/human/target)
	..()
	if(!user || !target || target.stat == DEAD)
		return
	if(HAS_TRAIT(target, TRAIT_RADIMMUNE))
		return
	if(target.dna && target.dna.species && target.dna.species.id == id)
		return

	var/f = ghoul_rad_factor(user.radiation)
	var/m = ghoul_meltdown_factor(user.radiation)
	if(f <= 0)
		return

	if(!prob(round(20 + (60 * f) + (10 * m))))
		return

	var/rad_touch = round(5 + (15 * f) + (8 * m))
	target.apply_effect(rad_touch, EFFECT_IRRADIATE, 0)

	// High-meltdown ghouls can briefly overwhelm a target with feral strikes.
	if(m >= 0.40 && prob(round(8 + (18 * m))))
		target.adjustStaminaLoss(round(8 + (10 * m)))

	// Tradeoff: uncontrolled attacks can hurt the ghoul too.
	if(m >= 0.65 && prob(round(6 + (16 * m))))
		user.adjustBruteLoss(1)
	if(prob(round(20 + (25 * f))))
		to_chat(target, span_warning("[user]'s irradiated claws sear your flesh."))


/*/datum/species/ghoul/glowing
	name = "Glowing Ghoul"
	id = "glowing ghoul"
	limbs_id = "glowghoul"
	armor = -30
	speedmod = 0.5
	brutemod = 1.3
	punchdamagehigh = 6
	punchstunthreshold = 6
	use_skintones = 0
	sexes = 0

//Ghouls have weak limbs.
/datum/species/ghoul/glowing/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	..()
	for(var/obj/item/bodypart/b in C.bodyparts)
		b.max_damage -= 15
	C.faction |= "ghoul"
	C.set_light(2, 1, LIGHT_COLOR_GREEN)
	SSradiation.processing += C

/datum/species/ghoul/glowing/on_species_loss(mob/living/carbon/C)
	..()
	C.set_light(0)
	C.faction -= "ghoul"
	for(var/obj/item/bodypart/b in C.bodyparts)
		b.max_damage = initial(b.max_damage)
	SSradiation.processing -= C
*/
