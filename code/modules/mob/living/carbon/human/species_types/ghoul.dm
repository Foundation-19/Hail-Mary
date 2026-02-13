//ghouls-heal from radiation, do not breathe. do not go into crit. terrible at melee, easily dismembered.
//NECROTIC SURGE SYSTEM - Your dead heart can only pump so many times before it needs to rest
//Radiation is the FUEL consumed during healing, not the source of charges
//Charges = emergency healing bursts that regenerate slowly over time
//FERAL STACKS - Each surge used builds up feral instinct, pushing you toward meltdown

// -------------------------
// Per-mob variables
// -------------------------
/mob/living/carbon/human
	var/ghoul_wave_next = 0
	var/ghoul_feedback_next = 0
	var/ghoul_feral_ally = FALSE
	var/ghoul_starve_ticks = 0
	var/ghoul_exposure_ticks = 0
	var/ghoul_last_state = "normal"
	var/ghoul_surges = 0                    // Necrotic surges (0-10) - START AT ZERO
	var/ghoul_surges_max = 10
	var/ghoul_surge_recharge_next = 0       // When next surge will recharge
	var/ghoul_regen_active = FALSE          // Tracks if regeneration is currently active
	var/ghoul_last_heal_tick = 0            // Last time we actually healed damage
	var/ghoul_feral_stacks = 0              // Feral stacks (0-100) - builds with surge use
	var/ghoul_feral_accumulator = 0         // Fractional feral gain tracker
	var/ghoul_radaway_purge_next = 0        // Cooldown for radaway feral purging
	var/last_radiation_check = 0            // For tracking radiation gain vs decay
	var/ghoul_feral_decay_counter = 0       // Counter for interval-based feral decay
	var/ghoul_last_combat_time = 0          // Last time we took damage from another mob
	var/ghoul_last_damage_source = null     // What last damaged us (for self-damage check)
	var/ghoul_rad_removed_accumulator = 0   // Tracks total rads removed by radaway
	var/ghoul_cleanse_charges = 0           // Cleanse charges available (max 3)
	var/ghoul_cleanse_active = FALSE        // Is cleanse currently firing?
	var/ghoul_cleanse_next = 0              // When can next cleanse fire (cooldown tracker)
	var/ghoul_damage_window_start = 0       // When current damage window started
	var/ghoul_latent_damage = 0             // Damage taken since last surge recharge scan
	var/ghoul_damage_snapshot = 0           // Snapshot of total damage for surge activation check
	var/ghoul_whisper_next = 0              // Cooldown for internal feral whispers
	var/ghoul_speech_next = 0				// Cooldown for actual speech (feral growls)
	var/ghoul_radaway_active = FALSE    // Set by handle_chemicals, consumed in spec_life
	var/ghoul_last_cleanse_time = 0
	var/ghoul_cleanse_cooldown_duration = 1200  // 2 minutes base


// Factor procs
/proc/ghoul_rad_factor(rads)
	if(rads <= GHOUL_RAD_HEAL_START)
		return 0
	var/t = (rads - GHOUL_RAD_HEAL_START) / (GHOUL_RAD_HEAL_FULL - GHOUL_RAD_HEAL_START)
	t = clamp(t, 0, 1)
	return t * t

// NEW: Meltdown now based on FERAL STACKS instead of radiation
/proc/ghoul_meltdown_factor(feral_stacks)
	if(feral_stacks <= GHOUL_FERAL_MELTDOWN_START)
		return 0
	var/t = (feral_stacks - GHOUL_FERAL_MELTDOWN_START) / (GHOUL_FERAL_MELTDOWN_FULL - GHOUL_FERAL_MELTDOWN_START)
	return clamp(t, 0, 1)

/proc/ghoul_starve_factor(rads)
	if(rads >= GHOUL_RAD_STARVE_START)
		return 0
	
	var/t = (GHOUL_RAD_STARVE_START - rads) / GHOUL_RAD_STARVE_START
	t = clamp(t, 0, 1)
	
	if(rads >= 100)
		return t * t * t * 0.3
	else if(rads >= 50)
		return 0.3 + (t * t * 0.4)
	else
		return 0.7 + (t * 0.3)

// NEW: Feral stacks amplify radiation absorption
/proc/ghoul_feral_rad_multiplier(feral_stacks)
	var/t = feral_stacks / GHOUL_FERAL_MAX
	t = clamp(t, 0, 1)
	return GHOUL_FERAL_RAD_MULT_MIN + ((GHOUL_FERAL_RAD_MULT_MAX - GHOUL_FERAL_RAD_MULT_MIN) * t)

// NEW: Clean up tiny damage values
/proc/ghoul_cleanup_damage(mob/living/carbon/human/H)
	if(!H)
		return
	
	// Round damage values below 1.0 to 0
	if(H.getBruteLoss() > 0 && H.getBruteLoss() < 1.0)
		H.adjustBruteLoss(-H.getBruteLoss())
	if(H.getFireLoss() > 0 && H.getFireLoss() < 1.0)
		H.adjustFireLoss(-H.getFireLoss())
	if(H.getToxLoss() > 0 && H.getToxLoss() < 1.0)
		H.adjustToxLoss(-H.getToxLoss())
	if(H.getCloneLoss() > 0 && H.getCloneLoss() < 1.0)
		H.adjustCloneLoss(-H.getCloneLoss())

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
	inherent_traits = list(TRAIT_RADIMMUNE, TRAIT_VIRUSIMMUNE, TRAIT_NOBREATH, TRAIT_NOHARDCRIT, TRAIT_NOSOFTCRIT, TRAIT_GHOULMELEE, TRAIT_EASYDISMEMBER, TRAIT_EASYLIMBDISABLE, TRAIT_LIMBATTACHMENT, TRAIT_NOHUNGER)
	inherent_biotypes = list(MOB_ORGANIC, MOB_HUMANOID, MOB_BEAST)
	mutant_bodyparts = list("mcolor" = "FFFFFF","mcolor2" = "FFFFFF","mcolor3" = "FFFFFF", "mam_snouts" = "Husky", "mam_tail" = "Husky", "mam_ears" = "Husky", "deco_wings" = "None", "mam_body_markings" = "Husky", "taur" = "None", "horns" = "None", "legs" = "Plantigrade", "meat_type" = "Mammalian")
	attack_verb = "claw"
	punchstunthreshold = 9
	tail_type = "tail_human"
	wagging_type = "waggingtail_human"
	species_type = "human"
	use_skintones = 0
	speedmod = 0.2
	sexes = 1
	sharp_blunt_mod = 2
	sharp_edged_mod = 2
	disliked_food = NONE
	liked_food = NONE
	var/info_text = "You are a <span class='danger'>Ghoul.</span> Your necrotic heart surges with power, but each use builds <b>feral instinct</b>. Manage your radiation and feral stacks carefully, or risk losing yourself to the wasteland."

/datum/species/ghoul/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	..()
	to_chat(C, "[info_text]")
	
	for(var/obj/item/bodypart/b in C.bodyparts)
		if(istype(b, /obj/item/bodypart/chest))
			continue
		b.max_damage -= 20
		b.wound_resistance = -35
	
	if(istype(C, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = C
		H.ghoul_wave_next = 0
		H.ghoul_feedback_next = 0
		H.ghoul_feral_ally = FALSE
		H.ghoul_starve_ticks = 0
		H.ghoul_exposure_ticks = 0
		H.ghoul_surges = 0
		H.ghoul_surges_max = GHOUL_SURGES_MAX
		H.ghoul_surge_recharge_next = world.time + (GHOUL_SURGE_COOLDOWN * 10)
		H.ghoul_regen_active = FALSE
		H.ghoul_last_heal_tick = 0
		H.ghoul_feral_stacks = 0
		H.ghoul_feral_accumulator = 0
		H.ghoul_radaway_purge_next = 0
		H.last_radiation_check = H.radiation
		H.ghoul_feral_decay_counter = 0
		H.ghoul_last_combat_time = 0
		H.ghoul_last_damage_source = null
		H.ghoul_rad_removed_accumulator = 0
		H.ghoul_cleanse_charges = 0
		H.ghoul_cleanse_active = FALSE
		H.ghoul_cleanse_next = 0
		H.ghoul_last_cleanse_time = 0
		H.ghoul_cleanse_cooldown_duration = 1200  // 2min base cooldown
		H.ghoul_damage_window_start = world.time
		H.ghoul_latent_damage = 0
		H.ghoul_damage_snapshot = 0
		H.ghoul_whisper_next = 0
		H.ghoul_speech_next = 0
		H.ghoul_radaway_active = FALSE
		
		RegisterSignal(H, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
		
		#if GHOUL_DEBUG_RADIATION
		world.log << "GHOUL INIT: [H] surges=[H.ghoul_surges]/[H.ghoul_surges_max] radiation=[H.radiation] feral=[H.ghoul_feral_stacks]"
		to_chat(H, span_notice("DEBUG: Ghoul initialized - surges_max=[H.ghoul_surges_max]"))
		#endif

/datum/species/ghoul/on_species_loss(mob/living/carbon/C)
	..()
	
	for(var/obj/item/bodypart/b in C.bodyparts)
		if(istype(b, /obj/item/bodypart/chest))
			continue
		b.max_damage = initial(b.max_damage)
		b.wound_resistance = initial(b.wound_resistance)
	
	if(istype(C, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = C
		if(H.ghoul_feral_ally)
			H.faction -= "ghoul"
			H.ghoul_feral_ally = FALSE
		H.remove_movespeed_modifier(/datum/movespeed_modifier/ghoul_rad)
		
		UnregisterSignal(H, COMSIG_PARENT_EXAMINE)

/datum/species/ghoul/proc/on_examine(mob/living/carbon/human/H, mob/user, list/examine_list)
	SIGNAL_HANDLER
	
	var/t_He = H.p_they(TRUE)
	var/t_his = H.p_their()
	var/t_His = H.p_their(TRUE)
	var/t_him = H.p_them()
	var/t_is = H.p_are()
	
	// PERCEPTION CHECK - determines how much you can sense
	var/user_perception = 5 // Default
	if(isliving(user))
		var/mob/living/L = user
		user_perception = L.special_p
	
	// === NECROTIC HEART STATUS (Perception-based) ===
	// Low perception: You feel something's off
	// Mid perception: You can sense the pulse
	// High perception: You can almost see the radiation flowing
	
	var/surge_percent = (H.ghoul_surges / H.ghoul_surges_max) * 100
	
	if(user_perception >= 7) // High perception - detailed
		if(H.ghoul_surges >= H.ghoul_surges_max)
			examine_list += span_warning("[t_He] [t_is] barely holding still - you can almost SEE the necrotic pulse hammering against [t_his] ribcage.")
		else if(surge_percent >= 70)
			examine_list += span_notice("[t_He] [t_is] twitching slightly - the dead heart is building power, you can sense it.")
		else if(surge_percent >= 40)
			examine_list += "[t_He] has a faint unnatural heat radiating from [t_his] chest - the necrotic heart is stirring."
		else if(surge_percent >= 10)
			examine_list += span_warning("[t_He] seems... diminished. The unnatural warmth is fading from [t_his] chest.")
		else
			examine_list += span_danger("There's nothing there. No pulse, no warmth - just a corpse that refuses to stop moving.")
	
	else if(user_perception >= 5) // Mid perception - vague sense
		if(H.ghoul_surges >= H.ghoul_surges_max)
			examine_list += span_warning("[t_He] [t_is] vibrating with barely-contained energy.")
		else if(surge_percent >= 70)
			examine_list += "[t_He] seems unusually animated for a ghoul."
		else if(surge_percent >= 40)
			examine_list += "[t_He] looks about as active as you'd expect a ghoul to be."
		else if(surge_percent >= 10)
			examine_list += span_warning("[t_He] looks weak, even by ghoul standards.")
		else
			examine_list += span_danger("[t_He] looks like a corpse on its last legs.")
	
	else if(user_perception >= 3) // Low perception - just gut feeling
		if(H.ghoul_surges >= H.ghoul_surges_max || surge_percent <= 10)
			examine_list += span_warning("Something feels... off about [t_him].")
	// Below 3 perception: You notice nothing special
	
	// === FERAL STATUS (Always visible through behavior) ===
	if(H.stat == DEAD)
		examine_list += span_notice("[t_He] [t_is] dead. Whatever was driving them is gone now.")
		return  // Don't show feral or surge status for corpses

	var/feral_percent = (H.ghoul_feral_stacks / GHOUL_FERAL_MAX) * 100
	
	if(feral_percent >= 80)
		examine_list += span_danger("[t_He] moves with savage, twitching jerks - barely more than a feral beast. [t_His] eyes are wild and unfocused.")
	else if(feral_percent >= 60)
		examine_list += span_danger("[t_He] keeps scratching at [t_his] own skin and sniffing the air hungrily. The feral urge is strong in this one.")
	else if(feral_percent >= 40)
		examine_list += span_warning("[t_He] has a distant, predatory look. [t_He] keeps staring at exposed skin a bit too long.")
	else if(feral_percent >= 20)
		examine_list += span_notice("[t_He] occasionally tilts [t_his] head unnaturally and mutters under [t_his] breath.")
	// Below 20%: No feral signs visible

/datum/species/ghoul/qualifies_for_rank(rank, list/features)
	if(rank in GLOB.legion_positions)
		return 0
	if(rank in GLOB.brotherhood_positions)
		return 0
	if(rank in GLOB.vault_positions)
		return 0
	if(rank in GLOB.mutant_positions)
		return 0
	return ..()

/datum/species/ghoul/handle_chemicals(datum/reagent/chem, mob/living/carbon/human/H)
	if(istype(chem) && !chem.ghoulfriendly)
		H.reagents.remove_reagent(chem.type, REAGENTS_METABOLISM * 1000)
		return TRUE
	
	// RADAWAY - Just damages, cleansing happens automatically in spec_life
	if(chem.type == /datum/reagent/medicine/radaway)
		H.adjustBruteLoss(GHOUL_RADAWAY_DAMAGE)
		H.ghoul_radaway_active = TRUE   // Flag before removing
		H.reagents.remove_reagent(chem.type, REAGENTS_METABOLISM)
		
		if(prob(GHOUL_RADAWAY_FEEDBACK))
			to_chat(H, span_warning("The radaway burns as it courses through your veins..."))
	
	if(chem.type == /datum/reagent/medicine/radx)
		H.adjustBruteLoss(GHOUL_RADX_DAMAGE)
		if(prob(GHOUL_RADX_FEEDBACK))
			to_chat(H, span_warning("You feel sick..."))
		H.reagents.remove_reagent(chem.type, REAGENTS_METABOLISM)
	if(chem.type == /datum/reagent/medicine/stimpak)
		H.adjustBruteLoss(GHOUL_STIMPAK_PENALTY)
	if(chem.type == /datum/reagent/medicine/super_stimpak)
		H.adjustBruteLoss(GHOUL_SUPERSTIM_PENALTY)
	return ..()

// ========== RADIATION ABSORPTION OVERRIDE ==========
/mob/living/carbon/human/apply_effect(effect, effecttype, blocked, knockdown_stamoverride, knockdown_stammax)
	if(effecttype == EFFECT_IRRADIATE && dna && dna.species && istype(dna.species, /datum/species/ghoul))
		// Base 2x absorption, then amplified by feral stacks
		var/feral_mult = ghoul_feral_rad_multiplier(ghoul_feral_stacks)
		effect = effect * GHOUL_RAD_ABSORPTION_MULT * feral_mult
		
		#if GHOUL_DEBUG_RADIATION
		if(effect > 0)
			world.log << "GHOUL RAD ABSORB: [src] original=[effect / (GHOUL_RAD_ABSORPTION_MULT * feral_mult)] base_mult=2.0 feral_mult=[feral_mult] final=[effect] feral_stacks=[ghoul_feral_stacks]"
		#endif
		
		// Feral feedback - much less spammy
		if(feral_mult >= 2.5 && prob(2))
			to_chat(src, span_warning("Your feral instinct hungers for radiation!"))
	
	return ..()

// ========== MAIN SPEC_LIFE ==========
/datum/species/ghoul/spec_life(mob/living/carbon/human/H)
	// DO NOT CALL PARENT
	
	if(!H || !istype(H))
		return

	if(H.stat == DEAD)
		update_feral_alignment(H, 0)
		H.set_light(0)
		H.remove_status_effect(/datum/status_effect/ghoulheal)
		H.remove_movespeed_modifier(/datum/movespeed_modifier/ghoul_rad)
		H.ghoul_starve_ticks = 0
		H.ghoul_exposure_ticks = 0
		H.sprint_buffer_regen_last = world.time
		H.ghoul_regen_active = FALSE
		return

	// ========== CALCULATE RADIATION FACTORS EARLY ==========
	var/r = H.radiation
	var/f = ghoul_rad_factor(r)
	var/m = ghoul_meltdown_factor(H.ghoul_feral_stacks)  // NOW BASED ON FERAL STACKS
	var/s = ghoul_starve_factor(r)
	
	// Calculate current damage once (used in multiple places)
	var/current_damage = H.getBruteLoss() + H.getFireLoss() + H.getCloneLoss() + H.getToxLoss()

	// ========== STEP 1: SURGE RECHARGE (with snapshot-based combat detection) ==========
	
	// Track radiation change for recharge fuel
	var/rad_gained_this_tick = 0
	if(H.radiation > (H.last_radiation_check ? H.last_radiation_check : 0))
		rad_gained_this_tick = H.radiation - (H.last_radiation_check ? H.last_radiation_check : 0)
	
	// Check if injured for faster recharge
	var/is_injured = current_damage >= GHOUL_INJURY_THRESHOLD
	
	// SNAPSHOT-BASED COMBAT DETECTION:
	// When a surge recharges, snapshot the current damage
	// On NEXT surge recharge, compare: if damage increased, that's new combat damage
	var/in_combat = FALSE
	if(world.time >= H.ghoul_surge_recharge_next && H.ghoul_surges < H.ghoul_surges_max)
		// Check if damage increased since last snapshot (new damage = combat)
		if(current_damage > H.ghoul_damage_snapshot)
			in_combat = TRUE
			
			#if GHOUL_DEBUG_RADIATION
			world.log << "GHOUL COMBAT DETECTED: [src] damage_now=[current_damage] damage_snapshot=[H.ghoul_damage_snapshot] - NEW DAMAGE!"
			#endif
			
			// Anti-gaming: Check if damage source was self-inflicted
			// If last damage was from self AND it happened recently (within 10 seconds), deny combat bonus
			if(H.ghoul_last_damage_source == H && (world.time - H.ghoul_last_combat_time) < 100) // 10 seconds
				in_combat = FALSE // Deny combat bonus for self-damage
				
				#if GHOUL_DEBUG_RADIATION
				world.log << "GHOUL COMBAT DENIED: [src] self-inflicted damage detected - no combat bonus"
				#endif
		
		// Update snapshot for next time
		H.ghoul_damage_snapshot = current_damage
	
	// Calculate recharge cooldown with combat bonus
	var/recharge_cooldown = is_injured ? (GHOUL_SURGE_COOLDOWN_INJURED * 10) : (GHOUL_SURGE_COOLDOWN * 10)
	if(in_combat)
		recharge_cooldown = round(recharge_cooldown * GHOUL_COMBAT_COOLDOWN_MULT)
	
	// ONLY recharge if: 1) we're GAINING radiation (not decaying), 2) NOT actively regenerating, 3) not at max
	if(rad_gained_this_tick > 0 && !H.ghoul_regen_active && H.ghoul_surges < H.ghoul_surges_max && world.time >= H.ghoul_surge_recharge_next)
		// If completely exhausted (0 surges), restore 1 surge
		if(H.ghoul_surges == 0)
			H.ghoul_surges = 1
			H.ghoul_surge_recharge_next = world.time + recharge_cooldown
			
			#if GHOUL_DEBUG_RADIATION
			world.log << "GHOUL SURGE RECHARGE: [src] surges=[H.ghoul_surges]/[H.ghoul_surges_max] rad_gained=[rad_gained_this_tick] injured=[is_injured] in_combat=[in_combat] next_in=[recharge_cooldown/10]s"
			#endif
			
			if(in_combat)
				to_chat(H, span_nicegreen("The thrill of battle surges through your dead heart! ([H.ghoul_surges]/[H.ghoul_surges_max])"))
			else if(is_injured)
				to_chat(H, span_notice("Pain spurs your necrotic heart back to life. ([H.ghoul_surges]/[H.ghoul_surges_max])"))
			else
				to_chat(H, span_notice("Your dead heart shudders with unnatural life. ([H.ghoul_surges]/[H.ghoul_surges_max])"))
		
		// If you have at least 1 surge and less than max, slowly build up more
		else if(H.ghoul_surges > 0 && H.ghoul_surges < H.ghoul_surges_max)
			H.ghoul_surges = min(H.ghoul_surges_max, H.ghoul_surges + 1)
			H.ghoul_surge_recharge_next = world.time + recharge_cooldown
			
			#if GHOUL_DEBUG_RADIATION
			world.log << "GHOUL SURGE RECHARGE: [src] surges=[H.ghoul_surges]/[H.ghoul_surges_max] rad_gained=[rad_gained_this_tick] injured=[is_injured] in_combat=[in_combat] next_in=[recharge_cooldown/10]s"
			#endif
			
			if(in_combat)
				to_chat(H, span_notice("Violence feeds the beast within. ([H.ghoul_surges]/[H.ghoul_surges_max])"))
			else
				to_chat(H, span_notice("Another pulse of necrotic energy builds. ([H.ghoul_surges]/[H.ghoul_surges_max])"))
			
			if(H.ghoul_surges >= H.ghoul_surges_max)
				to_chat(H, span_nicegreen("Your dead heart swells with terrible power!"))
	
	// ========== STEP 2: RADIATION DECAY (only when NOT regenerating) ==========
	if(!H.ghoul_regen_active && H.radiation > GHOUL_RAD_DECAY_SCALE_START)
		var/decay_factor = (H.radiation - GHOUL_RAD_DECAY_SCALE_START) / (GHOUL_RAD_MELTDOWN_FULL - GHOUL_RAD_DECAY_SCALE_START)
		decay_factor = clamp(decay_factor, 0, 1)
		var/decay_amount = GHOUL_RAD_DECAY_BASE + ((GHOUL_RAD_DECAY_MAX - GHOUL_RAD_DECAY_BASE) * decay_factor)
		
		H.radiation = max(0, H.radiation - decay_amount)
		
		#if GHOUL_DEBUG_RADIATION
		if(world.time % 100 == 0)
			world.log << "GHOUL RAD DECAY: [src] radiation=[H.radiation] decay=[decay_amount]"
		#endif
	
	// ========== STEP 3: FERAL STACK NATURAL DECAY (whole numbers on interval) ==========
	if(H.ghoul_feral_stacks > 0 && !H.ghoul_regen_active && H.ghoul_surges < H.ghoul_surges_max)
		H.ghoul_feral_decay_counter++
		if(H.ghoul_feral_decay_counter >= GHOUL_FERAL_DECAY_INTERVAL)
			H.ghoul_feral_stacks = max(0, H.ghoul_feral_stacks - GHOUL_FERAL_DECAY_RATE)
			H.ghoul_feral_decay_counter = 0
			
			#if GHOUL_DEBUG_RADIATION
			world.log << "GHOUL FERAL DECAY: [src] feral=[H.ghoul_feral_stacks] decayed=[GHOUL_FERAL_DECAY_RATE]"
			#endif
	else if(H.ghoul_regen_active || H.ghoul_surges >= H.ghoul_surges_max)
		H.ghoul_feral_decay_counter = 0  // Reset counter so decay doesn't burst when surge ends
	else
		H.ghoul_feral_decay_counter = 0

// ========== STEP 3.5: RADAWAY CLEANSE SYSTEM ==========
	
	// Track RADAWAY ACTIVE flag and grant cleanse charges
	if(H.ghoul_radaway_active)
		H.ghoul_radaway_active = FALSE  // Consume the flag
		
		var/radaway_cleanse_value = 25  // How much radiation RadAway removes
		
		#if GHOUL_DEBUG_RADIATION
		world.log << "GHOUL RADAWAY CONSUMED: [src] cleanse_value=[radaway_cleanse_value] cleanse_active=[H.ghoul_cleanse_active]"
		#endif
		
		// Check if in cooldown OR already cleansing
		var/in_cooldown = (world.time < H.ghoul_cleanse_next)
		
		if(in_cooldown)
			#if GHOUL_DEBUG_RADIATION
			var/time_remaining = (H.ghoul_cleanse_next - world.time) / 10
			world.log << "GHOUL RADAWAY BLOCKED: [src] in cooldown for [time_remaining]s more"
			#endif
		else if(H.ghoul_cleanse_active)
			#if GHOUL_DEBUG_RADIATION
			world.log << "GHOUL RADAWAY BLOCKED: [src] cleanse system is active, can't build charges"
			#endif
		else
			// ==========================================
			// CRITICAL FIX #1: Actually remove radiation!
			// ==========================================
			
			// Check if we have enough radiation to remove
			if(H.radiation < radaway_cleanse_value)
				#if GHOUL_DEBUG_RADIATION
				world.log << "GHOUL RADAWAY BLOCKED: [src] not enough radiation (have [H.radiation], need [radaway_cleanse_value])"
				#endif
				to_chat(H, "<span class='notice'><font color='#FFA500'>The radaway burns as it courses through your veins...</font></span>")
				// Don't add to accumulator if we can't actually remove the rads
			else
				// STATE 1: BUILDING - Actually remove the radiation
				H.radiation -= radaway_cleanse_value
				H.ghoul_rad_removed_accumulator += radaway_cleanse_value
				
				#if GHOUL_DEBUG_RADIATION
				world.log << "GHOUL RADAWAY ACCUMULATOR: [src] accumulator=[H.ghoul_rad_removed_accumulator] charges=[H.ghoul_cleanse_charges] rads_removed=[radaway_cleanse_value]"
				#endif
				
				to_chat(H, "<span class='notice'><font color='#FFA500'>The radaway burns as it courses through your veins...</font></span>")
				
				// ==========================================
				// CRITICAL FIX #2: Proper accumulator reset!
				// ==========================================
				while(H.ghoul_rad_removed_accumulator >= GHOUL_RADS_PER_CLEANSE && H.ghoul_cleanse_charges < GHOUL_CLEANSE_MAX_CHARGES)
					H.ghoul_rad_removed_accumulator -= GHOUL_RADS_PER_CLEANSE  // Reset accumulator!
					H.ghoul_cleanse_charges++

					to_chat(H, "<span class='notice'><font color='#FFA500'>Your chest lurches painfully. The necrotic pulse stutters. ([H.ghoul_cleanse_charges]/[GHOUL_CLEANSE_MAX_CHARGES] interruptions)</font></span>")
					
					#if GHOUL_DEBUG_RADIATION
					world.log << "GHOUL CLEANSE CHARGE GAINED: [src] charges=[H.ghoul_cleanse_charges] accumulator_reset=[H.ghoul_rad_removed_accumulator]"
					#endif
					
					// Check if we just hit max
					if(H.ghoul_cleanse_charges >= GHOUL_CLEANSE_MAX_CHARGES)
						H.ghoul_cleanse_active = TRUE
						// Set initial cooldown so it doesn't fire immediately
						if(H.ghoul_cleanse_next < world.time)
							H.ghoul_cleanse_next = world.time + GHOUL_CLEANSE_COOLDOWN
						#if GHOUL_DEBUG_RADIATION
						world.log << "GHOUL CLEANSE READY: [src] max charges reached, entering SPENDING mode, cooldown=[GHOUL_CLEANSE_COOLDOWN/10]s"
						#endif

	// STATE 2: SPENDING - Use charges ONE AT A TIME with proportional cooldown
	if(H.ghoul_cleanse_active && world.time >= H.ghoul_cleanse_next)
		// Safety check
		if(H.ghoul_cleanse_charges <= 0)
			H.ghoul_cleanse_active = FALSE
			#if GHOUL_DEBUG_RADIATION
			world.log << "GHOUL CLEANSE ERROR: [src] in SPENDING mode but 0 charges, exiting"
			#endif
		
		// Check if feral is high enough to cleanse (minimum 15 feral required)
		else if(H.ghoul_feral_stacks >= 15)
			#if GHOUL_DEBUG_RADIATION
			var/old_feral = H.ghoul_feral_stacks
			#endif
			
			// Calculate cleanse amount
			var/cleanse_per_charge = GHOUL_FERAL_PER_CLEANSE
			
			// Apply radiation resistance modifiers
			if(H.radiation >= GHOUL_RAD_MELTDOWN_FULL)
				cleanse_per_charge = round(GHOUL_FERAL_PER_CLEANSE * GHOUL_CLEANSE_RESIST_HIGH)
			else if(H.radiation >= (GHOUL_RAD_MELTDOWN_START + (GHOUL_RAD_MELTDOWN_FULL - GHOUL_RAD_MELTDOWN_START) * 0.5))
				cleanse_per_charge = round(GHOUL_FERAL_PER_CLEANSE * GHOUL_CLEANSE_RESIST_MID)
			else if(H.radiation >= GHOUL_RAD_MELTDOWN_START)
				cleanse_per_charge = round(GHOUL_FERAL_PER_CLEANSE * GHOUL_CLEANSE_RESIST_LOW)
			
			// Spend ONE charge
			H.ghoul_feral_stacks = max(0, H.ghoul_feral_stacks - cleanse_per_charge)
			H.ghoul_cleanse_charges--
			
			// Update tracking
			H.ghoul_last_cleanse_time = world.time
			
			#if GHOUL_DEBUG_RADIATION
			world.log << "GHOUL RADAWAY SPENDING (1 CHARGE): [src] feral=[old_feral]->[H.ghoul_feral_stacks] removed=[cleanse_per_charge] charges_left=[H.ghoul_cleanse_charges]"
			#endif
			
			// Outcome messages
			if(H.ghoul_feral_stacks == 0)
				H.visible_message(
					span_notice("[H] gasps sharply, eyes suddenly focusing with terrifying clarity..."),
					"<span class='nicegreen'><font color='#90EE90'>The radaway CHOKES the necrotic pulse (1 charge spent). The feral fog lifts completely.</font></span>"
				)
			else if(H.ghoul_feral_stacks < GHOUL_FERAL_MELTDOWN_START)
				H.visible_message(
					span_notice("[H] shudders violently, clutching their chest..."),
					"<span class='notice'><font color='#FFA500'>The radaway tightens around your dead heart (1 charge spent). It skips - the beast retreats.</font></span>"
				)
			else
				H.visible_message(
					span_warning("[H] convulses as if struck..."),
					"<span class='warning'><font color='#FFA500'>The radaway burns (1 charge spent), but the beast won't let go. Not yet.</font></span>"
				)
			
			// Check if we're done cleansing (no charges left OR feral too low)
			if(H.ghoul_cleanse_charges <= 0 || H.ghoul_feral_stacks < 15)
				// PROPORTIONAL COOLDOWN: Based on how many charges were actually used
				var/charges_used = GHOUL_CLEANSE_MAX_CHARGES - H.ghoul_cleanse_charges
				var/cooldown_multiplier = charges_used / GHOUL_CLEANSE_MAX_CHARGES
				var/actual_cooldown = round(H.ghoul_cleanse_cooldown_duration * cooldown_multiplier)
				
				H.ghoul_cleanse_next = world.time + actual_cooldown
				H.ghoul_cleanse_active = FALSE
				
				// Show completion message
				if(H.ghoul_cleanse_charges > 0)
					// Partial cleanse (stopped early because feral < 15)
					to_chat(H, "<span class='notice'><font color='#FFA500'>The radaway dissipates - not enough feral urge to purge. [H.ghoul_cleanse_charges] charge[H.ghoul_cleanse_charges > 1 ? "s" : ""] wasted. Reduced cooldown: [actual_cooldown/10]s</font></span>")
					
					#if GHOUL_DEBUG_RADIATION
					world.log << "GHOUL RADAWAY PARTIAL SPENDING: [src] charges_wasted=[H.ghoul_cleanse_charges] charges_used=[charges_used] cooldown=[actual_cooldown/10]s"
					#endif
				else
					// Full cleanse (all charges spent)
					to_chat(H, "<span class='notice'><font color='#FFA500'>All charges spent. Full cooldown: [actual_cooldown/10]s</font></span>")
					
					#if GHOUL_DEBUG_RADIATION
					world.log << "GHOUL RADAWAY FULL SPENDING: [src] all_charges_used cooldown=[actual_cooldown/10]s"
					#endif
				
				// Reset charges
				H.ghoul_cleanse_charges = 0
			else
				// Still have charges and feral is high enough - continue spending next tick
				H.ghoul_cleanse_next = world.time + GHOUL_CLEANSE_COOLDOWN
				to_chat(H, "<span class='notice'><font color='#FFA500'>[H.ghoul_cleanse_charges] charge[H.ghoul_cleanse_charges > 1 ? "s" : ""] remain. Next cleanse in [GHOUL_CLEANSE_COOLDOWN/10]s.</font></span>")
		
		// Feral too low - stop immediately and enter proportional cooldown
		else
			var/charges_wasted = H.ghoul_cleanse_charges
			var/charges_used = GHOUL_CLEANSE_MAX_CHARGES - charges_wasted
			var/cooldown_multiplier = charges_used / GHOUL_CLEANSE_MAX_CHARGES
			var/actual_cooldown = round(H.ghoul_cleanse_cooldown_duration * cooldown_multiplier)
			
			H.ghoul_cleanse_charges = 0
			H.ghoul_cleanse_active = FALSE
			H.ghoul_last_cleanse_time = world.time
			H.ghoul_cleanse_next = world.time + actual_cooldown
			
			to_chat(H, "<span class='notice'><font color='#FFA500'>The radaway dissipates - not enough feral urge to purge. [charges_wasted] charge[charges_wasted > 1 ? "s" : ""] wasted. Reduced cooldown: [actual_cooldown/10]s</font></span>")
			
			#if GHOUL_DEBUG_RADIATION
			world.log << "GHOUL RADAWAY DUMP: [src] charges_wasted=[charges_wasted] feral_too_low=[H.ghoul_feral_stacks] charges_used=[charges_used] cooldown=[actual_cooldown/10]s"
			#endif

	// ========== STEP 4: UPDATE FERAL ALIGNMENT ==========
	update_feral_alignment(H, m)

	// ========== STEP 4.5: FERAL MELTDOWN PASSIVE EFFECTS ==========
	// These fire regardless of whether healing is active.
	// The beast doesn't care if your heart is surging or not.
	if(m > 0)
		// Confusion and jitter scale with feral stacks
		H.confused = max(H.confused, round(2 + (GHOUL_FERAL_CONFUSED_MAX * m)))
		H.jitteriness = max(H.jitteriness, round(1 + (GHOUL_FERAL_JITTER_MAX * m)))
		H.slurring = max(H.slurring, round(1 + (6 * m)))

		// Occasional self-brute from feral thrashing (independent of healing)
		if(prob(round(3 + (9 * m))))  // Half the rate of the healing version, stacks with it
			H.adjustBruteLoss(rand(1, max(1, GHOUL_MELTDOWN_BRUTE_MAX)))

		// Loss of movement control at high feral
		if(m >= 0.70 && prob(round(4 + (10 * m))))
			step(H, pick(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))
		
		// NEW: At very high feral, occasional forced attack animation / emote (pure cosmetic)
		if(m >= 0.85 && prob(round(5 + (10 * m))))
			H.emote(pick("twitch", "scream"), TRUE)

		// NEW: Screen overlay flash at full meltdown to signal you're barely holding it together
		if(m >= 0.95 && prob(15) && world.time >= H.ghoul_feedback_next)
			to_chat(H, span_userdanger("The beast tears at the inside of your skull. You can barely think straight."))
			H.ghoul_feedback_next = world.time + GHOUL_FEEDBACK_CD
		
		// High feral + high radiation: predator senses kick in, mobs visible through darkness
		if(H.ghoul_feral_stacks >= GHOUL_FERAL_MELTDOWN_START && H.radiation >= GHOUL_RAD_MELTDOWN_START && m >= 0.5)
			if(!HAS_TRAIT(H, TRAIT_THERMAL_VISION))
				ADD_TRAIT(H, TRAIT_THERMAL_VISION, "ghoul_feral")
				H.update_sight()
				to_chat(H, span_warning("Your senses sharpen to a predatory edge. Everything warm stands out in the dark."))
		else
			if(HAS_TRAIT(H, TRAIT_THERMAL_VISION) && HAS_TRAIT_FROM(H, TRAIT_THERMAL_VISION, "ghoul_feral"))
				REMOVE_TRAIT(H, TRAIT_THERMAL_VISION, "ghoul_feral")
				H.update_sight()
				to_chat(H, span_notice("The predator's edge fades from your vision.")) // Let normal sight rules apply when not in feral meltdown

	// ========== STEP 5: HIGH-RAD EXPOSURE ==========
	if(r >= GHOUL_HIGHRAD_THRESHOLD && r < GHOUL_RAD_MELTDOWN_START)
		H.ghoul_exposure_ticks++
		
		if(H.ghoul_exposure_ticks >= GHOUL_EXPOSURE_BUILDUP)
			H.radiation += GHOUL_EXPOSURE_RADS_GAIN
			
			if(H.ghoul_exposure_ticks == GHOUL_EXPOSURE_BUILDUP)
				to_chat(H, span_warning("Your body absorbs more radiation than it can safely process."))
	else
		if(H.ghoul_exposure_ticks > 0)
			H.ghoul_exposure_ticks = max(0, H.ghoul_exposure_ticks - 3)

	// ========== STEP 6: HEALING - NEW LOGIC ==========
	// Clean up tiny damage values first
	ghoul_cleanup_damage(H)
	
	// Recalculate damage after cleanup
	current_damage = H.getBruteLoss() + H.getFireLoss() + H.getCloneLoss() + H.getToxLoss()
	
	// ACTIVATION: Reach 10 surges with radiation fuel and damage to heal (minimum threshold)
	if(!H.ghoul_regen_active && H.ghoul_surges >= H.ghoul_surges_max && r >= GHOUL_RAD_HEAL_START && current_damage >= GHOUL_DAMAGE_ACTIVATION_MIN)
		H.ghoul_regen_active = TRUE
		H.ghoul_last_heal_tick = world.time
		to_chat(H, span_nicegreen("Your necrotic heart SURGES to life! Regeneration activated!"))
		H.jitteriness = max(H.jitteriness, 20)  // Initial activation jitter
		
		#if GHOUL_DEBUG_RADIATION
		world.log << "GHOUL REGEN ACTIVATED: [src] surges=[H.ghoul_surges] rads=[r]"
		#endif
	
	// DEACTIVATION CONDITIONS:
	// 1. Surges hit 0
	// 2. No damage healed for GHOUL_REGEN_TIMEOUT (idle timeout)
	// NOTE: We do NOT check radiation while regen is active - surges are the only limit
	if(H.ghoul_regen_active)
		var/should_deactivate = FALSE
		var/deactivate_reason = ""
		
		if(H.ghoul_surges <= 0)
			should_deactivate = TRUE
			deactivate_reason = "Your necrotic heart is exhausted! Regeneration stops."
		else if(current_damage < GHOUL_DAMAGE_ACTIVATION_MIN && (world.time - H.ghoul_last_heal_tick) >= GHOUL_REGEN_TIMEOUT)
			should_deactivate = TRUE
			deactivate_reason = "Your wounds are healed. Regeneration goes dormant."
		
		if(should_deactivate)
			H.ghoul_regen_active = FALSE
			to_chat(H, span_warning("[deactivate_reason]"))
			
			#if GHOUL_DEBUG_RADIATION
			world.log << "GHOUL REGEN DEACTIVATED: [src] reason=[deactivate_reason]"
			#endif
	
	// HEALING: Only heal if regeneration is ACTIVE
	if(H.ghoul_regen_active && current_damage >= GHOUL_DAMAGE_ACTIVATION_MIN)
		// Calculate max possible HP
		var/max_hp = H.getMaxHealth()
		
		// Healing scales with radiation level (percentage of max HP)
		var/heal_percent = GHOUL_HEAL_PERCENT_MIN + ((GHOUL_HEAL_PERCENT_MAX - GHOUL_HEAL_PERCENT_MIN) * f)
		var/healpwr = round(max_hp * heal_percent)
		healpwr = max(1, healpwr) // Minimum 1 HP healed
		
		#if GHOUL_DEBUG_RADIATION
		world.log << "GHOUL HEAL ACTIVE: [src] healpwr=[healpwr] damage=[current_damage] surges=[H.ghoul_surges] rads=[r]"
		#endif
		
		// Meltdown effects
		if(m > 0)
			if(prob(30 + round(40*m)))
				healpwr = max(1, healpwr - 3)
			
			if(prob(round(6 + 18*m)))
				H.adjustBruteLoss(rand(1, max(1, GHOUL_MELTDOWN_BRUTE_MAX)))
			
			if(m >= 0.70 && prob(round(6 + (12 * m))))
				step(H, pick(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))
		
		// Apply healing
		var/brute_before = H.getBruteLoss()
		var/burn_before = H.getFireLoss()
		var/clone_before = H.getCloneLoss()
		var/tox_before = H.getToxLoss()
		
		H.heal_overall_damage(healpwr, healpwr, healpwr)
		H.adjustCloneLoss(-healpwr)
		H.adjustToxLoss(-0.3)
		
		var/brute_healed = brute_before - H.getBruteLoss()
		var/burn_healed = burn_before - H.getFireLoss()
		var/clone_healed = clone_before - H.getCloneLoss()
		var/tox_healed = tox_before - H.getToxLoss()
		var/total_healed = brute_healed + burn_healed + clone_healed + tox_healed
		
		if(total_healed > 0)
			H.ghoul_last_heal_tick = world.time  // Update last heal time
			
			// CONSUME RADIATION (your fuel) - base consumption
			var/rad_consume = GHOUL_RAD_CONSUME_BASE
			if(current_damage > 75)
				rad_consume = GHOUL_RAD_CONSUME_HEAVY  // Heavy injuries burn more fuel
			
			#if GHOUL_DEBUG_RADIATION
			var/old_rads = H.radiation
			#endif
			H.radiation = max(0, H.radiation - rad_consume)
			
			// CONSUME SURGE (your heart expends a pump)
			// Each surge lasts for multiple healing ticks
			// Consume 1 surge per ~15 HP healed (adjust this to your taste)
			if(prob(total_healed * 6)) // ~6% chance per HP healed = 1 surge per ~17 HP
				H.ghoul_surges = max(0, H.ghoul_surges - 1)
				
				// FLAT FERAL GAIN PER SURGE USE - can't avoid this cost!
				#if GHOUL_DEBUG_RADIATION
				var/old_feral_surge = H.ghoul_feral_stacks
				#endif
				H.ghoul_feral_stacks = min(GHOUL_FERAL_MAX, H.ghoul_feral_stacks + GHOUL_FERAL_PER_SURGE_USE)
				
				#if GHOUL_DEBUG_RADIATION
				world.log << "GHOUL SURGE CONSUMED: [src] +[GHOUL_FERAL_PER_SURGE_USE] FLAT feral from surge use feral=[old_feral_surge]->[H.ghoul_feral_stacks]"
				#endif
				
				// CONSUME EXTRA RADIATION when surge is used (from stored rads)
				H.radiation = max(0, H.radiation - GHOUL_RAD_CONSUME_SURGE)
				
				// ALSO consume radiation metabolism (effect_irradiate) - eat pending radiation absorption
				// This keeps total radiation lower by consuming the "incoming" radiation
				if(H.reagents)
					var/metabolism_consumed = 0
					for(var/datum/reagent/R in H.reagents.reagent_list)
						// Look for radiation effects in metabolism
						if(istype(R, /datum/reagent/toxin/plasma) || istype(R, /datum/reagent/uranium))
							var/amount_to_remove = min(R.volume, GHOUL_RAD_CONSUME_SURGE / 10)
							H.reagents.remove_reagent(R.type, amount_to_remove)
							metabolism_consumed += amount_to_remove * 10
					
					#if GHOUL_DEBUG_RADIATION
					if(metabolism_consumed > 0)
						world.log << "GHOUL SURGE METABOLISM: [src] consumed=[metabolism_consumed] rads from metabolism"
					#endif
				
				// JITTER FEEDBACK - Visual cue that a surge was consumed
				H.jitteriness = max(H.jitteriness, 15)
				
				// Surge warnings
				if(H.ghoul_surges == 7)
					to_chat(H, span_warning("Your necrotic heart is burning through surges! ([H.ghoul_surges]/[H.ghoul_surges_max] remaining)"))
				else if(H.ghoul_surges == 3)
					to_chat(H, span_boldwarning("Your necrotic heart is nearly spent! ([H.ghoul_surges]/[H.ghoul_surges_max] remaining)"))
					// Deactivation will happen next tick
			
			// BUILD FERAL STACKS based on HEALING POWER (more HP healed = more feral)
			// Use accumulator to prevent rounding loss
			var/old_feral = H.ghoul_feral_stacks
			var/feral_gain = total_healed * GHOUL_FERAL_PER_HP_HEALED

			// Add a rad multiplier to feral gain - high radiation accelerates feral buildup
			if(H.radiation >= GHOUL_RAD_MELTDOWN_START)
				var/rad_gain_t = (H.radiation - GHOUL_RAD_MELTDOWN_START) / (GHOUL_RAD_MELTDOWN_FULL - GHOUL_RAD_MELTDOWN_START)
				rad_gain_t = clamp(rad_gain_t, 0, 1)
				var/rad_gain_mult = GHOUL_FERAL_RAD_GAIN_MULT_LOW + ((GHOUL_FERAL_RAD_GAIN_MULT_HIGH - GHOUL_FERAL_RAD_GAIN_MULT_LOW) * rad_gain_t)
				feral_gain *= rad_gain_mult

				// Feedback when radiation is actively accelerating feral gain
				if(prob(3) && world.time >= H.ghoul_feedback_next)
					H.ghoul_feedback_next = world.time + GHOUL_FEEDBACK_CD

					if(rad_gain_t >= 0.75)  // Near full meltdown radiation
						var/list/msgs_high = list(
							"The radiation doesn't just heal you. It feeds something worse.",
							"Your dead cells drink it in. So does the beast.",
							"Every rem soaking into your bones makes it harder to remember who you were.",
							"The rads taste good. That should scare you more than it does.",
							"You're not healing. You're being rewritten."
						)
						to_chat(H, span_danger(pick(msgs_high)))

					else if(rad_gain_t >= 0.35)  // Mid meltdown radiation
						var/list/msgs_mid = list(
							"The radiation sharpens the hunger. You're not sure which one you are anymore.",
							"Healing and losing ground at the same time. The math isn't in your favor.",
							"Something in your chest gets louder every time you close a wound.",
							"The rads fix the flesh. Something else pays the tab.",
							"Two hundred years of this. No wonder they all go feral eventually."
						)
						to_chat(H, span_warning(pick(msgs_mid)))

					else  // Just crossed meltdown threshold
						var/list/msgs_low = list(
							"The radiation is doing more than healing you now.",
							"You can feel the difference. The surge costs more here.",
							"Something's off. The rads are too hot, even for you.",
							"Your necrotic heart drinks deep. Don't let it get too comfortable.",
							"That familiar itch behind your eyes. Too much radiation, not enough left of you."
						)
						to_chat(H, span_notice(pick(msgs_low)))
			
			// Add to accumulator instead of rounding immediately
			H.ghoul_feral_accumulator += feral_gain
			
			// Only apply whole number feral stacks
			if(H.ghoul_feral_accumulator >= 1.0)
				var/stacks_to_add = floor(H.ghoul_feral_accumulator)
				H.ghoul_feral_stacks = min(GHOUL_FERAL_MAX, H.ghoul_feral_stacks + stacks_to_add)
				H.ghoul_feral_accumulator -= stacks_to_add
			
			#if GHOUL_DEBUG_RADIATION
			if(feral_gain > 0)
				world.log << "GHOUL FERAL GAIN: [src] healed=[total_healed] feral_gain=[feral_gain] accumulator=[H.ghoul_feral_accumulator] feral=[old_feral]->[H.ghoul_feral_stacks]"
			#endif
			
			// Feral warnings - only when crossing thresholds
			if(H.ghoul_feral_stacks >= GHOUL_FERAL_MELTDOWN_FULL && old_feral < GHOUL_FERAL_MELTDOWN_FULL)
				to_chat(H, span_userdanger("FERAL RAGE CONSUMES YOU! Your mind fractures as the beast takes over!"))
			else if(H.ghoul_feral_stacks >= GHOUL_FERAL_MELTDOWN_START && old_feral < GHOUL_FERAL_MELTDOWN_START)
				to_chat(H, span_danger("The beast within stirs - you feel yourself slipping toward feral madness!"))
			else if(H.ghoul_feral_stacks >= 60 && old_feral < 60)
				to_chat(H, span_warning("Feral instinct builds with each surge. ([H.ghoul_feral_stacks]/[GHOUL_FERAL_MAX] feral)"))
			
			#if GHOUL_DEBUG_RADIATION
			world.log << "GHOUL RAD CONSUME: [src] healed=[total_healed] consumed=[rad_consume] rads=[old_rads]->[H.radiation]"
			#endif
			
			// Visual feedback
			if(total_healed >= 3 && prob(15))
				var/list/healing_messages = list()
				
				if(brute_healed >= 2)
					healing_messages += "flesh knits"
				if(burn_healed >= 2)
					healing_messages += "burns seal"
				if(clone_healed >= 2)
					healing_messages += "decay reverses"
				
				if(healing_messages.len > 0)
					var/message = english_list(healing_messages)
					H.visible_message(
						span_notice("[H]'s [message] with a sickly green pulse!"),
						span_notice("Your necrotic heart surges as [message]!")
					)
	else if(!H.ghoul_regen_active && current_damage >= GHOUL_DAMAGE_ACTIVATION_MIN)
		// Explain why healing isn't working
		if(H.ghoul_surges < H.ghoul_surges_max && prob(1))
			var/time_until = round((H.ghoul_surge_recharge_next - world.time) / 10)
			if(time_until > 0)
				to_chat(H, span_warning("Your necrotic heart isn't at full capacity! ([H.ghoul_surges]/[H.ghoul_surges_max] surges - next in [time_until]s)"))
			else
				to_chat(H, span_warning("Your necrotic heart isn't at full capacity! ([H.ghoul_surges]/[H.ghoul_surges_max] surges)"))
		else if(r < GHOUL_RAD_HEAL_START && prob(1))
			to_chat(H, span_warning("Your wounds won't close - you need more radiation fuel! (Currently: [round(r)]/[GHOUL_RAD_HEAL_START])"))

	// ========== STEP 7: FERAL SPEECH (runechat visible) ==========
	process_feral_speech(H)
	process_feral_whispers(H)

	// ========== STEP 8: STARVATION ==========
	if(s > 0)
		H.ghoul_starve_ticks++
		
		var/neglect_mult = 1.0
		if(H.ghoul_starve_ticks >= GHOUL_NEGLECT_THRESHOLD)
			var/neglect_progress = min((H.ghoul_starve_ticks - GHOUL_NEGLECT_THRESHOLD) / GHOUL_NEGLECT_THRESHOLD, 1.0)
			neglect_mult = 1.0 + (GHOUL_NEGLECT_MULTIPLIER - 1.0) * neglect_progress
		
		var/starve_tox = (0.08 + (GHOUL_STARVE_TOX_MAX * s)) * neglect_mult
		H.adjustToxLoss(starve_tox)
		
		var/clone_chance = round((15 + (35 * s)) * neglect_mult)
		if(prob(clone_chance))
			H.adjustCloneLoss(round((0.5 + (GHOUL_STARVE_CLONE_MAX * s)) * neglect_mult))
		
		if(H.ghoul_starve_ticks == GHOUL_NEGLECT_THRESHOLD)
			to_chat(H, span_boldwarning("Your tissue deteriorates rapidly. You NEED radiation!"))
	else
		H.ghoul_starve_ticks = 0

	// ========== STEP 9: STAMINA RECOVERY ==========
	if(H.getStaminaLoss() > 0)
		var/stam_recovery = -1.5
		
		if(s > 0)
			stam_recovery = stam_recovery * (1.0 - (0.6 * s))
		
		H.adjustStaminaLoss(stam_recovery)

	// ========== STEP 10: GLOW - ONLY AT VERY HIGH RADIATION (GLOWING ONE) ==========
	// Glow ONLY activates when you're approaching/at meltdown radiation levels (Glowing One transformation)
	// This is SEPARATE from regeneration - you can regen without glowing!
	if(r >= GHOUL_RAD_MELTDOWN_START)
		// Scale glow intensity with radiation level
		var/glow_factor = (r - GHOUL_RAD_MELTDOWN_START) / (GHOUL_RAD_MELTDOWN_FULL - GHOUL_RAD_MELTDOWN_START)
		glow_factor = clamp(glow_factor, 0, 1)
		var/glow_power = GHOUL_GLOW_MIN + ((GHOUL_GLOW_MAX - GHOUL_GLOW_MIN) * glow_factor)
		
		H.set_light(glow_power, 15, LIGHT_COLOR_GREEN)
		H.apply_status_effect(/datum/status_effect/ghoulheal) // Glowing One aura healing
	else
		H.set_light(0)
		H.remove_status_effect(/datum/status_effect/ghoulheal)

	// ========== STEP 11: SPEED ==========
	var/speed_slowdown = 0

	if(s > 0)
		speed_slowdown += (0.04 + (0.10 * s))

	if(m > 0)
		speed_slowdown += (GHOUL_MELTDOWN_SLOW_MAX * m)

	H.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/ghoul_rad, TRUE, speed_slowdown)

	// ========== STEP 12: FEEDBACK ==========
	var/status_changed = check_radiation_status_change(H, f, m, s)
	if(!status_changed)
		send_ghoul_feedback(H, f, m, s)

	// ========== STEP 13: EMIT WAVES - GLOWING ONE TRANSFORMATION (high radiation only) ==========
	if(r >= GHOUL_WAVE_MIN_RADS)
		emit_radiation_waves(H, r, m)

// ========== FERAL SPEECH SYSTEM (runechat visible) ==========
/datum/species/ghoul/proc/process_feral_speech(mob/living/carbon/human/H)
	if(!H || H.stat == DEAD || H.stat == UNCONSCIOUS)
		return
	
	if(H.ghoul_feral_stacks < GHOUL_FERAL_SPEAK_FERAL_MIN)
		return
	
	if(world.time < H.ghoul_speech_next)
		return

	// Determine speak chance based on feral level
	var/speak_chance = 0
	var/speak_cd = 0
	var/feral_tier = 1

	if(H.ghoul_feral_stacks >= GHOUL_FERAL_SPEAK_FERAL_HIGH)
		speak_chance = GHOUL_FERAL_SPEAK_CHANCE_HIGH
		speak_cd = GHOUL_FERAL_CD_HIGH
		feral_tier = 3
	else if(H.ghoul_feral_stacks >= GHOUL_FERAL_SPEAK_FERAL_MID)
		speak_chance = GHOUL_FERAL_SPEAK_CHANCE_MID
		speak_cd = GHOUL_FERAL_CD_MID
		feral_tier = 2
	else
		speak_chance = GHOUL_FERAL_SPEAK_CHANCE_LOW
		speak_cd = GHOUL_FERAL_CD_LOW
		feral_tier = 1

	if(!prob(speak_chance))
		return

	H.ghoul_speech_next = world.time + speak_cd

	// Low feral: creepy whispers
	var/list/feral_whispers = list(
		"hungry...",
		"need... flesh...",
		"smoothskin...",
		"so... hungry...",
		"rads...",
		"itches...",
		"what... was I...?"
	)
	
	// Mid feral: audible mutters
	var/list/feral_mutters = list(
		"Hungry... so hungry...",
		"Smoothskins... I smell them...",
		"The rads... they call...",
		"What... happened to me...?",
		"Flesh... need flesh...",
		"Can't... think..."
	)
	
	// High feral: loud outbursts
	var/list/feral_shouts = list(
		"SMOOTHSKIN!",
		"HUNGRY!",
		"RADS!",
		"FLESH!",
		"MINE!",
		"GET AWAY!"
	)
	
	var/list/feral_emotes_low = list(
		"twitches slightly",
		"scratches at their arm",
		"stares off into the distance",
		"tilts their head unnaturally"
	)
	
	var/list/feral_emotes_mid = list(
		"twitches violently",
		"claws at their own skin",
		"sniffs the air hungrily",
		"drools slightly",
		"shambles in place"
	)
	
	var/list/feral_emotes_high = list(
		"convulses with feral rage",
		"claws wildly at the air",
		"snaps their jaws like a rabid animal",
		"hunches over, breathing heavily",
		"lets out a bestial snarl"
	)
	
	if(prob(60))
		var/message = ""
		switch(feral_tier)
			if(1)
				message = pick(feral_whispers)
				H.whisper(message, forced = "feral whisper")
			if(2)
				message = pick(feral_mutters)
				H.say(message, forced = "feral mutter")
			if(3)
				message = pick(feral_shouts)
				H.say(message, forced = "feral shout")
	else
		var/emote_text = ""
		switch(feral_tier)
			if(1)
				emote_text = pick(feral_emotes_low)
			if(2)
				emote_text = pick(feral_emotes_mid)
			if(3)
				emote_text = pick(feral_emotes_high)
		H.emote("me", 1, emote_text, TRUE)

// ========== INTERNAL FERAL WHISPERS (private only, cloud gray) ==========
/datum/species/ghoul/proc/process_feral_whispers(mob/living/carbon/human/H)
	if(!H || H.stat == DEAD || H.stat == UNCONSCIOUS)
		return
	if(H.ghoul_feral_stacks < GHOUL_FERAL_SPEAK_FERAL_MIN)
		return
	if(world.time < H.ghoul_whisper_next)
		return

	var/whisper_chance = 0
	var/whisper_cd = 0

	if(H.ghoul_feral_stacks >= GHOUL_FERAL_SPEAK_FERAL_HIGH)
		whisper_chance = GHOUL_WHISPER_CHANCE_HIGH
		whisper_cd = GHOUL_WHISPER_CD_HIGH
	else if(H.ghoul_feral_stacks >= GHOUL_FERAL_SPEAK_FERAL_MID)
		whisper_chance = GHOUL_WHISPER_CHANCE_MID
		whisper_cd = GHOUL_WHISPER_CD_MID
	else
		whisper_chance = GHOUL_WHISPER_CHANCE_LOW
		whisper_cd = GHOUL_WHISPER_CD_LOW

	if(!prob(whisper_chance))
		return

	H.ghoul_whisper_next = world.time + whisper_cd

	var/list/whispers_low = list(
		"...need it.",
		"...so empty.",
		"...just a taste.",
		"...what did I used to be?",
		"...it hurts less if I don't think.",
	)

	var/list/whispers_mid = list(
		"...they look so warm.",
		"...the rads smell like food.",
		"...stop. STOP. I said stop.",
		"...I had a name. I had a name.",
		"...can't tell if I'm thinking or it is.",
		"...been this way so long.",
		"...just meat. we're all just meat."
	)

	var/list/whispers_high = list(
		"...HUNGRY.",
		"...smoothskin. close. i can smell it.",
		"...don't. don't. DON'T.",
		"...losing the thread again.",
		"...wasn't always like this. was I?",
		"...kill it. eat it. no. no no no.",
		"...still in here. still in here. still—"
	)

	var/whisper_text = ""
	if(H.ghoul_feral_stacks >= GHOUL_FERAL_SPEAK_FERAL_HIGH)
		whisper_text = pick(whispers_high)
	else if(H.ghoul_feral_stacks >= GHOUL_FERAL_SPEAK_FERAL_MID)
		whisper_text = pick(whispers_mid)
	else
		whisper_text = pick(whispers_low)

	to_chat(H, "<i><span style='color:#a0a0a0'>[whisper_text]</span></i>")

// ========== WAVE EMISSION (Glowing One) ==========
/datum/species/ghoul/proc/emit_radiation_waves(mob/living/carbon/human/H, rads, m)
	if(!H || H.stat == DEAD)
		return

	if(world.time < H.ghoul_wave_next)
		return
	H.ghoul_wave_next = world.time + GHOUL_WAVE_PULSE_CD

	// Intensity scales with radiation level (glowing one transformation)
	var/rad_factor = (rads - GHOUL_WAVE_MIN_RADS) / (GHOUL_RAD_MELTDOWN_FULL - GHOUL_WAVE_MIN_RADS)
	rad_factor = clamp(rad_factor, 0, 1)
	var/intensity = round(GHOUL_WAVE_INTENSITY_MIN + ((GHOUL_WAVE_INTENSITY_MAX - GHOUL_WAVE_INTENSITY_MIN) * rad_factor))

	if(m > 0)
		intensity = round(intensity * (1 + (0.60 * m)))

	intensity = clamp(intensity, 1, GHOUL_WAVE_INTENSITY_MAX * 2)

	#if GHOUL_DEBUG_RADIATION
	world.log << "GHOUL WAVE (GLOWING ONE): [src] rads=[rads] rad_factor=[rad_factor] intensity=[intensity]"
	#endif

	new /datum/radiation_wave(H, NORTH, intensity, GHOUL_WAVE_RANGE_MOD, GHOUL_WAVE_CAN_CONTAMINATE)
	new /datum/radiation_wave(H, SOUTH, intensity, GHOUL_WAVE_RANGE_MOD, GHOUL_WAVE_CAN_CONTAMINATE)
	new /datum/radiation_wave(H, EAST,  intensity, GHOUL_WAVE_RANGE_MOD, GHOUL_WAVE_CAN_CONTAMINATE)
	new /datum/radiation_wave(H, WEST,  intensity, GHOUL_WAVE_RANGE_MOD, GHOUL_WAVE_CAN_CONTAMINATE)

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
		to_chat(H, span_notice("Radiation fuels your undead form."))
	else
		return

	H.ghoul_feedback_next = world.time + GHOUL_FEEDBACK_CD

/datum/species/ghoul/proc/update_feral_alignment(mob/living/carbon/human/H, m)
	if(!H)
		return
	if(!islist(H.faction))
		H.faction = list(H.faction)

	// Remove from feral faction if dead or conditions not met
	if(H.stat == DEAD || m <= GHOUL_FERAL_ALLY_OFF || H.radiation < GHOUL_FERAL_ALLY_RAD_MIN)
		if(H.ghoul_feral_ally)
			H.ghoul_feral_ally = FALSE
			H.faction -= "ghoul"
			if(H.stat != DEAD)
				to_chat(H, span_notice("Your scent settles. Nearby ferals will no longer mistake you for one of their own."))
		return

	// Join feral faction if BOTH high feral AND high radiation (radmaxxing route)
	if(m >= GHOUL_FERAL_ALLY_ON && H.radiation >= GHOUL_FERAL_ALLY_RAD_MIN && !H.ghoul_feral_ally)
		H.ghoul_feral_ally = TRUE
		H.faction |= "ghoul"
		to_chat(H, span_warning("Feral instinct and radiation saturation flood your senses. Wild ghouls now recognize you as kin."))

/datum/species/ghoul/proc/check_radiation_status_change(mob/living/carbon/human/H, f, m, s)
	var/old_state = H.ghoul_last_state
	var/new_state = "normal"
	
	// Now check feral stacks for meltdown state instead of radiation
	if(H.ghoul_feral_stacks >= GHOUL_FERAL_MELTDOWN_FULL)
		new_state = "meltdown_full"
	else if(H.ghoul_feral_stacks >= GHOUL_FERAL_MELTDOWN_START)
		new_state = "meltdown"
	else if(H.radiation >= GHOUL_RAD_HEAL_FULL)
		new_state = "optimal"
	else if(H.radiation >= GHOUL_RAD_HEAL_START)
		new_state = "healing"
	else if(H.radiation >= GHOUL_RAD_STARVE_START)
		new_state = "stable"
	else if(H.radiation >= 50)
		new_state = "starving"
	else
		new_state = "critical_starve"
	
	H.ghoul_last_state = new_state
	
	if(old_state != new_state)
		var/tier_message = get_status_tier_message(H)
		if(tier_message)
			to_chat(H, tier_message)
		return TRUE
	
	return FALSE

/datum/species/ghoul/proc/get_status_tier_message(mob/living/carbon/human/H)
	var/f = H.ghoul_feral_stacks
	var/r = H.radiation
	
	// Feral states take priority
	if(f >= GHOUL_FERAL_MELTDOWN_FULL)
		return span_userdanger("Your humanity shatters. The feral beast has taken over completely.")
	else if(f >= GHOUL_FERAL_MELTDOWN_START)
		return span_danger("Feral instinct claws at your sanity. You're losing control!")
	else if(f >= 60)
		return span_warning("The beast within grows stronger. You feel yourself slipping.")
	else if(f >= 40)
		return span_warning("Feral urges build in the back of your mind.")
	
	// Then radiation states
	else if(r >= GHOUL_RAD_HEAL_FULL)
		return span_nicegreen("You're perfectly irradiated - radiation fuels your undead form.")
	else if(r >= GHOUL_RAD_HEAL_START)
		return span_notice("Ambient radiation sustains your body.")
	else if(r >= GHOUL_RAD_STARVE_START)
		return "You feel stable, but not particularly energized."
	else if(r >= 50)
		return span_warning("Your flesh aches for radiation. You're beginning to wither.")
	else
		return span_danger("Your body is collapsing from radiation starvation!")

/datum/species/ghoul/spec_unarmedattacked(mob/living/carbon/human/user, mob/living/carbon/human/target)
	..()
	if(!user || !target || target.stat == DEAD)
		return
	if(HAS_TRAIT(target, TRAIT_RADIMMUNE))
		return
	if(target.dna && target.dna.species && target.dna.species.id == id)
		return

	var/f = ghoul_rad_factor(user.radiation)
	var/m = ghoul_meltdown_factor(user.ghoul_feral_stacks)
	if(f <= 0)
		return

	if(!prob(round(20 + (60 * f) + (10 * m))))
		return

	var/rad_touch = round(5 + (15 * f) + (8 * m))
	target.apply_effect(rad_touch, EFFECT_IRRADIATE, 0)

	// Stamina drain at high feral
	if(m >= 0.40 && prob(round(8 + (18 * m))))
		target.adjustStaminaLoss(round(8 + (10 * m)))

	// Self-damage at extreme feral
	if(m >= 0.65 && prob(round(6 + (16 * m))))
		user.adjustBruteLoss(1)

	// TARGET feedback - always shown on a hit
	to_chat(target, span_warning("[user]'s necrotic claws inject a sick heat under your skin."))

	// Visible message to the room
	user.visible_message(
		span_warning("[user] rakes their irradiated claws across [target]!"),
		span_notice("Your necrotic claws tear into [target] - you feel the radiation pass through them.")
	)

	// Meltdown tier: extra sting message to target
	if(m >= 0.50)
		to_chat(target, span_danger("Something wrong seeps into the wound - their claws feel diseased."))
	if(m >= 0.80)
		to_chat(target, span_userdanger("Your veins burn where they touched you. Whatever is in those claws isn't just radiation."))

// ========== COMBAT TRACKING ==========
// Hook into damage to track combat state via latent damage window
/mob/living/carbon/human/apply_damage(damage = 0, damagetype = BRUTE, def_zone = null, blocked = FALSE, forced = FALSE, spread_damage = FALSE, wound_bonus = 0, bare_wound_bonus = 0, sharpness = SHARP_NONE, damage_threshold = 0, sendsignal = TRUE)
	// Track latent damage for ghouls (only if damage came from another mob, not self-inflicted)
	if(damage > 0 && dna && dna.species && istype(dna.species, /datum/species/ghoul))
		if(ghoul_last_damage_source && ghoul_last_damage_source != src)
			// Add to latent damage window BEFORE calling parent
			ghoul_latent_damage += damage
			
			#if GHOUL_DEBUG_RADIATION
			world.log << "GHOUL LATENT DAMAGE: [src] +[damage] from [ghoul_last_damage_source] (total: [ghoul_latent_damage])"
			#endif
		
		// Clear the damage source after recording
		ghoul_last_damage_source = null
	
	return ..()

// Track damage source
/mob/living/carbon/human/attackby(obj/item/I, mob/user, params)
	if(dna && dna.species && istype(dna.species, /datum/species/ghoul))
		if(user != src)  // Not self-inflicted
			ghoul_last_damage_source = user
			
			#if GHOUL_DEBUG_RADIATION
			world.log << "GHOUL ATTACKBY: [src] damage source set to [user]"
			#endif
	return ..()

/mob/living/carbon/human/attack_hand(mob/living/carbon/human/user, list/modifiers)
	if(dna && dna.species && istype(dna.species, /datum/species/ghoul))
		if(user != src)  // Not self-inflicted
			ghoul_last_damage_source = user
			
			#if GHOUL_DEBUG_RADIATION
			world.log << "GHOUL ATTACK_HAND: [src] damage source set to [user]"
			#endif
	return ..()

/mob/living/carbon/human/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	if(dna && dna.species && istype(dna.species, /datum/species/ghoul))
		if(throwingdatum && throwingdatum.thrower)
			var/mob/thrower = throwingdatum.thrower
			// Check if it's a valid mob reference
			if(istype(thrower) && thrower != src)  // Not self-inflicted
				ghoul_last_damage_source = thrower
				
				#if GHOUL_DEBUG_RADIATION
				world.log << "GHOUL HITBY: [src] damage source set to [thrower]"
				#endif
	return ..()

/mob/living/carbon/human/bullet_act(obj/item/projectile/P, def_zone, piercing_hit)
	if(dna && dna.species && istype(dna.species, /datum/species/ghoul))
		if(P && P.firer && P.firer != src)  // Not self-inflicted
			ghoul_last_damage_source = P.firer
			
			#if GHOUL_DEBUG_RADIATION
			world.log << "GHOUL BULLET_ACT: [src] damage source set to [P.firer]"
			#endif
	return ..()
