/mob
	var/flavor_text = "" //tired of fucking double checking this
	var/special_s = SPECIAL_DEFAULT_ATTR_VALUE // +/-1.1 dmg in melee for each level above/below 5 ST, certain guns can be STR locked
	var/special_p = SPECIAL_DEFAULT_ATTR_VALUE // +/- 5 degrees of innate gun spread for each level below/above 5 PER
	var/special_e = SPECIAL_DEFAULT_ATTR_VALUE // -50 to +130 maxHealth (non-linear, see get_special_endurance_health_bonus) plus increased poison and rad resistance for each level above/below 5 END
	var/special_c = SPECIAL_DEFAULT_ATTR_VALUE // Desc message + other people get moodlets about your demeanor/appearance when they examine you; caps how many followers you can lead in a pull chain
	var/special_i = SPECIAL_DEFAULT_ATTR_VALUE // Can't craft with INT under SPECIAL_MIN_INT_CRAFTING_REQUIREMENT, certain recipes can be INT locked, certain guns can be INT locked
	var/special_a = SPECIAL_DEFAULT_ATTR_VALUE // +/- 5 tiles sprint buffer, +/- 10% sprint regen, +/- 0.05 sprint speed, +/- 10% sprint stamina usage per lvl below/above 5 AGI
	var/special_l = SPECIAL_DEFAULT_ATTR_VALUE // Money from trash piles and chance to fumble/whiff an attack if it's 3 or below

/mob/proc/get_top_level_mob()
	if(istype(src.loc,/mob)&&src.loc!=src)
		var/mob/M=src.loc
		return M.get_top_level_mob()
	return src

proc/get_top_level_mob(mob/S)
	if(istype(S.loc,/mob)&&S.loc!=S)
		var/mob/M=S.loc
		return M.get_top_level_mob()
	return S

/mob/proc/initialize_special_stats()
	initialize_special_strength()
	initialize_special_perception()
	initialize_special_endurance()
	initialize_special_charisma()
	initialize_special_intelligence()
	initialize_special_agility()
	initialize_special_luck()

/mob/proc/initialize_special_strength()
	return

/mob/proc/initialize_special_perception()
	return

/mob/proc/initialize_special_endurance()
	return

/mob/proc/initialize_special_charisma()
	return

/mob/proc/initialize_special_intelligence()
	return

/mob/proc/initialize_special_agility()
	return

/mob/proc/initialize_special_luck()
	return



/// STRENGTH

/obj/item/proc/calc_melee_dam_mod_from_special(mob/living/user)
	return ((user.special_s - SPECIAL_DEFAULT_ATTR_VALUE) * 1.1)

/obj/item/gun/proc/gun_firing_str_check(mob/living/user)
	if(user.special_s >= required_str_to_fire)
		return TRUE
	to_chat(user, span_warning("You're too weak to use this properly."))
	return FALSE

/datum/species/proc/calc_unarmed_dam_mod_from_special(mob/living/user)
	return ((user.special_s - SPECIAL_DEFAULT_ATTR_VALUE) * 1.1)

/// Blurry/blinded vision can make a melee swing whiff entirely before it ever reaches attackby(); keen Perception compensates, poor Perception compounds it.
/mob/proc/check_vision_impaired_miss()
	if(!eye_blurry && !eye_blind)
		return FALSE
	var/miss_chance = (eye_blurry * MELEE_BLUR_MISS_CHANCE_PER_LEVEL) + (eye_blind ? MELEE_BLIND_MISS_CHANCE : 0)
	miss_chance += (SPECIAL_DEFAULT_ATTR_VALUE - special_p) * MELEE_MISS_CHANCE_PER_PERCEPTION_LEVEL
	miss_chance = clamp(miss_chance, 0, MELEE_VISION_MISS_CHANCE_CAP)
	if(!prob(miss_chance))
		return FALSE
	visible_message(span_danger("[src] swings wildly and misses!"), span_warning("Your vision fails you and you swing wildly, missing completely!"))
	return TRUE

/// Strong grip/control trims how badly a gun cook-off burns your hand
/mob/proc/get_strength_cookoff_burn_multiplier()
	return CLAMP(1 - ((special_s - SPECIAL_DEFAULT_ATTR_VALUE) * 0.05), 0.5, 1.5)

/// Brawnier fighters gas out less from winding up a Power Attack; weaklings pay more stamina for the same swing.
/mob/living/proc/get_strength_power_attack_stamina_multiplier()
	return CLAMP(1 - ((special_s - SPECIAL_DEFAULT_ATTR_VALUE) * 0.06), 0.6, 1.6)

/// Brawnier wasters can cram more combined weight class into their bags/pockets/belts before they're full.
/mob/living/proc/get_strength_carry_capacity_multiplier()
	return CLAMP(1 + ((special_s - SPECIAL_DEFAULT_ATTR_VALUE) * 0.1), 0.5, 1.5)

/// PERCEPTION

/obj/item/ammo_casing/proc/calc_bullet_spread_mod_from_special(mob/living/user)
	return ((user.special_p - SPECIAL_DEFAULT_ATTR_VALUE) * 2) // +/- 5 degrees of innate spread per lvl

/// A perceptive shooter manages fire discipline (bursts, cooldown) better, trimming heat-driven jam chance
/mob/proc/get_perception_gun_jam_multiplier()
	return CLAMP(1 - ((special_p - SPECIAL_DEFAULT_ATTR_VALUE) * 0.05), 0.5, 1.5)

/// ENDURANCE

/mob/living/carbon/human/initialize_special_endurance()
	maxHealth = initial(maxHealth) + get_special_endurance_health_bonus()
	health = maxHealth

/// Non-linear so low END stays genuinely fragile and high END pays off hard, instead of a flat +/-5 per level
/// Keyed on SPECIAL_MIN/MAX_ATTR_VALUE and clamped, so a future stat-range change extends cleanly instead of silently returning 0
/mob/living/proc/get_special_endurance_health_bonus()
	// Index N corresponds directly to a special_e value of N (SPECIAL_MIN_ATTR_VALUE starts at 1)
	var/static/list/endurance_health_bonus = list(-50, -35, -20, -10, 0, 15, 35, 60, 90, 130)
	var/clamped_e = CLAMP(special_e, SPECIAL_MIN_ATTR_VALUE, SPECIAL_MAX_ATTR_VALUE)
	return endurance_health_bonus[clamped_e] || 0 // falls back to 0 if SPECIAL_MAX_ATTR_VALUE grows past the table without a matching row being added

/mob/living/proc/get_special_rad_resist_multiplier()
	return ((special_e - SPECIAL_DEFAULT_ATTR_VALUE) * -0.1 + 1)

/mob/living/proc/get_special_poison_resist_multiplier()
	// Index N corresponds directly to a special_e value of N (SPECIAL_MIN_ATTR_VALUE starts at 1)
	var/static/list/poison_resist_multiplier = list(2, 1.75, 1.5, 1.25, 1, 0.9, 0.8, 0.7, 0.6, 0.5)
	var/clamped_e = CLAMP(special_e, SPECIAL_MIN_ATTR_VALUE, SPECIAL_MAX_ATTR_VALUE)
	return poison_resist_multiplier[clamped_e] || 1


/// CHARISMA

/mob/living/carbon/human/initialize_special_charisma()
	RegisterSignal(src, COMSIG_PARENT_EXAMINE, PROC_REF(handle_special_charisma_examine_moodlet), TRUE)

/mob/living/carbon/human/Destroy()
	UnregisterSignal(src, COMSIG_PARENT_EXAMINE)
	return ..()

/// Max number of living followers a charismatic leader can keep chained behind them in a pull line (conga line/marched prisoners/escorted squad).
/// Does not block a bare single grab (every value allows at least 1 follower) - only caps extending the line further.
/mob/living/proc/get_special_charisma_pull_chain_cap()
	// Index N corresponds directly to a special_c value of N (SPECIAL_MIN_ATTR_VALUE starts at 1)
	var/static/list/charisma_pull_chain_cap = list(1, 1, 2, 2, 3, 3, 4, 4, 5, 6)
	var/clamped_c = CLAMP(special_c, SPECIAL_MIN_ATTR_VALUE, SPECIAL_MAX_ATTR_VALUE)
	return charisma_pull_chain_cap[clamped_c] || 1

/// Walks to the front of this mob's pull line and returns whoever's leading it (the mob nothing is pulling further up the chain).
/mob/living/proc/get_pull_chain_leader()
	var/mob/living/leader = src
	while(isliving(leader.pulledby))
		var/mob/living/next_leader = leader.pulledby
		if(next_leader.pulling != leader)
			break
		leader = next_leader
	return leader

/// Counts how many living mobs (itself plus everyone trailing behind it) are currently chained in this mob's pull line.
/mob/living/proc/get_pull_chain_member_count()
	var/count = 1
	var/mob/living/current = src
	while(isliving(current.pulling))
		count++
		current = current.pulling
	return count

/// Max total members (including the leader) a charismatic leader can keep in their party.
/mob/living/proc/get_special_charisma_party_cap()
	// Index N corresponds directly to a special_c value of N (SPECIAL_MIN_ATTR_VALUE starts at 1)
	var/static/list/charisma_party_cap = list(1, 2, 2, 3, 3, 4, 4, 5, 5, 6)
	var/clamped_c = CLAMP(special_c, SPECIAL_MIN_ATTR_VALUE, SPECIAL_MAX_ATTR_VALUE)
	return charisma_party_cap[clamped_c] || 1

/// Scales how strong a party leader's leadership buff is for the members following them.
/mob/living/proc/get_special_charisma_party_buff_tier()
	// Index N corresponds directly to a special_c value of N (SPECIAL_MIN_ATTR_VALUE starts at 1)
	var/static/list/charisma_party_buff_tier = list(0, 0, 1, 1, 2, 2, 3, 3, 4, 5)
	var/clamped_c = CLAMP(special_c, SPECIAL_MIN_ATTR_VALUE, SPECIAL_MAX_ATTR_VALUE)
	return charisma_party_buff_tier[clamped_c] || 0

/mob/proc/handle_special_charisma_examine_moodlet(mob/living/examinee, mob/living/examiner, text)
	if(!istype(examiner))
		return
	if(src == examiner)
		return
	switch(special_c)
		if(-INFINITY to 1)
			SEND_SIGNAL(examiner, COMSIG_ADD_MOOD_EVENT, "disgusting_char", /datum/mood_event/special_disgusting_char)
		if(2 to 3)
			SEND_SIGNAL(examiner, COMSIG_ADD_MOOD_EVENT, "bad_looking_char", /datum/mood_event/special_bad_looking_char)
		if(7 to 9)
			SEND_SIGNAL(examiner, COMSIG_ADD_MOOD_EVENT, "good_looking_char", /datum/mood_event/special_good_looking_char)
		if(10 to INFINITY)
			SEND_SIGNAL(examiner, COMSIG_ADD_MOOD_EVENT, "beautiful_char", /datum/mood_event/special_beautiful_char)

/datum/mood_event/special_disgusting_char
	description = span_boldwarning("I have struggled to comprehend an abomination given flesh. ")
	mood_change = -5
	timeout = 5 MINUTES

/datum/mood_event/special_bad_looking_char
	description = span_warning("I've had to endure seeing a face even a mother would struggle to love. ")
	mood_change = -2
	timeout = 4 MINUTES

/datum/mood_event/special_good_looking_char
	description = span_nicegreen("I've seen someone so good-looking that it made my day! ")
	mood_change = 2
	timeout = 5 MINUTES

/datum/mood_event/special_beautiful_char
	description = span_nicegreen("I have gazed upon the visage of perfection given form! ")
	mood_change = 5
	timeout = 6 MINUTES

/datum/mood_event/party_rally
	description = span_nicegreen("Following a charismatic leader is keeping my spirits up! ")
	mood_change = 2
	timeout = 20 SECONDS

/// INTELLIGENCE

/obj/item/gun/proc/gun_firing_int_check(mob/living/user)
	if(user.special_i >= required_int_to_fire)
		return TRUE
	to_chat(user, span_warning("You have no idea how to use this."))
	return FALSE

/datum/component/personal_crafting/proc/special_crafting_check(mob/living/user)
	if(!istype(user))
		return FALSE
	if(user.special_i <= SPECIAL_MIN_INT_CRAFTING_REQUIREMENT)
		to_chat(user,  "Your brain is too dumb to craft items.")
		return FALSE
	return TRUE

/datum/crafting_recipe/proc/special_crafting_requirements_check(mob/user)
	return (user.special_i >= required_int)

/datum/crafting_recipe/proc/generate_special_req_text()
	return ", [required_int] Intelligence"

/// Smarter field repairs restore more gun condition per wrench pass
/mob/proc/get_intelligence_gun_repair_multiplier()
	return CLAMP(1 + ((special_i - SPECIAL_DEFAULT_ATTR_VALUE) * 0.1), 0.5, 1.5)

/// AGILITY

/mob/living/proc/calc_sprint_stamina_mod_from_special()
	return

/mob/living/carbon/proc/calc_sprint_speed_mod_from_special()
	// BURST SPEED with double diminishing returns
	var/base_sprint_boost = CONFIG_GET(number/movedelay/sprint_speed_increase)
	var/agi_diff = special_a - SPECIAL_DEFAULT_ATTR_VALUE
	
	var/speed_bonus
	if(agi_diff > 3) // Agility above 8 (5 + 3)
		// First bracket: AGI 5-8
		var/first_bracket = sqrt(3) * 0.1344
		// Second bracket: AGI 9+
		var/second_bracket = sqrt(agi_diff - 3) * 0.067
		speed_bonus = base_sprint_boost + first_bracket + second_bracket
	else if(agi_diff > 0)
		speed_bonus = base_sprint_boost + (sqrt(agi_diff) * 0.1344)
	else
		speed_bonus = base_sprint_boost + (agi_diff * 0.1344)
	
	// Apply armor penalties to sprint speed with STRENGTH thresholds
	var/armor_penalty = 0
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		if(istype(H.wear_suit))
			var/obj/item/clothing/suit/armor = H.wear_suit
			if(armor.slowdown == ARMOR_SLOWDOWN_SALVAGE)
				armor_penalty = 0.50
				if(special_s < 6)
					armor_penalty += 0.50
			else if(armor.slowdown == ARMOR_SLOWDOWN_PA)
				armor_penalty = 0.30
				if(special_s < 4)
					armor_penalty += 0.40
			else if(armor.slowdown == ARMOR_SLOWDOWN_HEAVY)
				armor_penalty = 0.30
				if(special_s < 6)
					armor_penalty += 0.40
			else if(armor.slowdown == ARMOR_SLOWDOWN_MEDIUM)
				if(special_s < 4)
					armor_penalty = 0.30
			else if(armor.slowdown == ARMOR_SLOWDOWN_LIGHT)
				if(special_s < 3)
					armor_penalty = 0.30
	
	return speed_bonus - armor_penalty

/mob/living/carbon/calc_sprint_stamina_mod_from_special()
	// Base stamina cost from agility
	var/agi_diff = special_a - SPECIAL_DEFAULT_ATTR_VALUE
	
	var/base_modifier
	if(agi_diff > 0)
		base_modifier = (1 - (sqrt(agi_diff) * 0.07)) * 0.65
	else
		base_modifier = (1 - (agi_diff * 0.07)) * 0.65

	// Armor penalties
	var/armor_multiplier = 1.0
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		if(istype(H.wear_suit))
			var/obj/item/clothing/suit/armor = H.wear_suit
			if(armor.slowdown == ARMOR_SLOWDOWN_SALVAGE)
				armor_multiplier = 1.5
			else if(armor.slowdown == ARMOR_SLOWDOWN_PA)
				armor_multiplier = 1.4
			else if(armor.slowdown == ARMOR_SLOWDOWN_HEAVY)
				armor_multiplier = 1.4
			else if(armor.slowdown == ARMOR_SLOWDOWN_MEDIUM)
				armor_multiplier = 1.3
			else if(armor.slowdown == ARMOR_SLOWDOWN_LIGHT)
				armor_multiplier = 1.3
	
	return base_modifier * armor_multiplier

/mob/living/carbon/human/initialize_special_agility()
	var/base_regen = CONFIG_GET(number/movedelay/sprint_buffer_regen_per_ds)
	var/agi_diff = special_a - SPECIAL_DEFAULT_ATTR_VALUE
	
	// sprint_buffer_max is already set by update_config_movespeed() or initialize_sprint_stats()
	sprint_buffer = sprint_buffer_max  // Just reset buffer to max

	// Base regen from agility
	if(agi_diff > 0)
		sprint_buffer_regen_ds = base_regen * (1 + (sqrt(agi_diff) * 0.03))
	else
		sprint_buffer_regen_ds = base_regen * (1 + (agi_diff * 0.03))

	// Armor penalties
	var/regen_armor_modifier = 1.0
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		if(istype(H.wear_suit))
			var/obj/item/clothing/suit/armor = H.wear_suit
			if(armor.slowdown == ARMOR_SLOWDOWN_SALVAGE)
				regen_armor_modifier = 0.2
			else if(armor.slowdown == ARMOR_SLOWDOWN_PA)
				regen_armor_modifier = 1.0
			else if(armor.slowdown == ARMOR_SLOWDOWN_HEAVY)
				regen_armor_modifier = 1.0
			else if(armor.slowdown == ARMOR_SLOWDOWN_MEDIUM)
				regen_armor_modifier = 0.6
			else if(armor.slowdown == ARMOR_SLOWDOWN_LIGHT)
				regen_armor_modifier = 0.15
		else
			regen_armor_modifier = 0.1

	// High agility bonus
	if(special_a >= 7)
		sprint_buffer_regen_ds *= (1.0 + (0.40 * regen_armor_modifier))
	if(special_a >= 9)
		sprint_buffer_regen_ds *= (1.0 + (0.30 * regen_armor_modifier))

/// Nimble hands clear gun jams and swap magazines faster - multiplies the relevant do_after duration
/mob/proc/get_agility_gun_speed_multiplier()
	return CLAMP(1 - ((special_a - SPECIAL_DEFAULT_ATTR_VALUE) * 0.05), 0.5, 1.5)

/// Quick hands commit to a Power Attack windup faster/slower. Multiplies the required windup time.
/mob/living/proc/get_power_attack_windup_multiplier()
	return CLAMP(1 - ((special_a - SPECIAL_DEFAULT_ATTR_VALUE) * 0.08), 0.5, 1.5)

/// Nimble fighters land basic melee swings faster too, not just Power Attacks. Multiplies the weapon's attack_speed.
/mob/living/proc/get_agility_melee_speed_multiplier()
	return CLAMP(1 - ((special_a - SPECIAL_DEFAULT_ATTR_VALUE) * 0.03), 0.8, 1.2)

/// ENDURANCE (power attacks)

/// Tougher mobs shrug off getting interrupted mid-swing faster.
/mob/living/proc/get_power_attack_interrupt_stagger_duration()
	return CLAMP(3 SECONDS - ((special_e - SPECIAL_DEFAULT_ATTR_VALUE) * 0.3 SECONDS), 1 SECONDS, 5 SECONDS)

/// LUCK

/// Currently affects only money from trashpiles
/mob/proc/get_luck_loot_amt_multiplier()
	// Index N corresponds directly to a special_l value of N (SPECIAL_MIN_ATTR_VALUE starts at 1)
	var/static/list/luck_loot_multiplier = list(0.5, 0.625, 0.75, 0.875, 1, 1.1, 1.2, 1.3, 1.4, 1.5)
	var/clamped_l = CLAMP(special_l, SPECIAL_MIN_ATTR_VALUE, SPECIAL_MAX_ATTR_VALUE)
	return luck_loot_multiplier[clamped_l] || 1

/// Chance to fumble an attack entirely: a melee swing goes wide and misses, or a gun is fumbled and dropped before firing
/mob/proc/get_luck_critfail_chance()
	switch(special_l)
		if(1)
			return 6
		if(2)
			return 3
		if(3)
			return 1
	return 0

/// Unlucky swingers risk fumbling (whiffing + a short self-stagger) on a Power Attack release.
/mob/living/proc/get_power_attack_fumble_chance()
	switch(special_l)
		if(1)
			return 15
		if(2)
			return 8
		if(3)
			return 3
	return 0

/// How much heat/condition-driven gun jam & cook-off chance gets scaled by luck - bad luck makes malfunctions more likely, good luck less
/mob/proc/get_luck_gun_jam_multiplier()
	// Index N corresponds directly to a special_l value of N (SPECIAL_MIN_ATTR_VALUE starts at 1)
	var/static/list/luck_jam_multiplier = list(1.8, 1.6, 1.4, 1.2, 1, 0.9, 0.8, 0.7, 0.6, 0.5)
	var/clamped_l = CLAMP(special_l, SPECIAL_MIN_ATTR_VALUE, SPECIAL_MAX_ATTR_VALUE)
	return luck_jam_multiplier[clamped_l] || 1

/// misc examine procs
/mob/proc/generate_special_examine_text()
	var/they = p_they()
	var/capital_they = capitalize(they)
	var/p_s = p_s()
	var/msg = "*---------*" //S:[special_s],P:[special_p],E:[special_e],C:[special_c],I:[special_i],A:[special_a],L:[special_l]<br>"
	msg += gen_strength_examine_text(capital_they, they, p_s)
	msg += gen_perception_examine_text(capital_they, they, p_s)
	msg += gen_endurance_examine_text(capital_they, they, p_s)
	msg += gen_charisma_examine_text(capital_they, they, p_s)
	msg += gen_intelligence_examine_text(capital_they, they, p_s)
	msg += gen_agility_examine_text(capital_they, they, p_s)
	msg += gen_luck_examine_text(capital_they, they, p_s)
	msg += "<br> *---------*"
	return msg

/mob/proc/gen_strength_examine_text(c_they, they, p_s)
	if(special_s <= 3)
		return "<br>This person looks puny, like a total noodle."
	if(special_s >= 7)
		return "<br>Simply built out of muscle, [they] could wrestle a deathclaw to death."

/mob/proc/gen_perception_examine_text(c_they, they, p_s)
	if(special_p <= 3)
		return "<br>Even with glasses, an elephant could easily sneak by [p_them()]."
	if(special_p >= 7)
		return "<br>A sharp and attentive gaze almost pierces through you, nothing gets past [p_them()] it seems."

/mob/proc/gen_endurance_examine_text(c_they, they, p_s)
	if(special_e <= 3)
		return "<br>It looks like a stiff breeze could tear [p_them()] in two."
	if(special_e >= 7)
		return "<br>As solid as an oak, [they] look[p_s] like [they] could run for miles on end."

/mob/proc/gen_charisma_examine_text(c_they, they, p_s)
	switch(special_c)
		if(1)
			return "<br>You struggle not to vomit looking at this horribly fugly creature."
		if(2)
			return "<br>[c_they] look[p_s] like a product of incest."
		if(3)
			return "<br>[c_they] look[p_s] kinda ugly."
		if(4)
			return "<br>[c_they] look[p_s] a little off appearance-wise."
		if(5)
			return "<br>[c_they] look[p_s] incredibly average."
		if(6)
			return "<br>[c_they] look[p_s] slightly better than your average waster."
		if(7)
			return "<br>[c_they] look[p_s] pretty damn good."
		if(8)
			return "<br>[c_they] look[p_s] strikingly great."
		if(9)
			return "<br>[c_they] look[p_s] exceptionally beautiful."
		if(10)
			return "<br>[c_they] [p_have()] a perfect beauty to [p_them()] leagues above the rest."

/mob/proc/gen_intelligence_examine_text(c_they, they, p_s)
	if(special_i <= 3)
		return "<br>[c_they] look[p_s] like [they]'d struggle to get water out of a boot with instructions printed on the heel."
	if(special_i >= 7)
		return "<br>A bright and careful gaze in [p_their()] eyes, [they] seem[p_s] to know much more than you."

/mob/proc/gen_agility_examine_text(c_they, they, p_s)
	if(special_a <= 3)
		return "<br>Maladroit and unbalanced, it is a wonder [they] can even stand straight."
	if(special_a >= 7)
		return "<br>Moving like a panther, it is a wonder you have even noticed that [they] [p_are()] here."

/mob/proc/gen_luck_examine_text(c_they, they, p_s)
	if(special_l <= 3)
		return "<br>Misfortune just seems to stick to [p_them()] like a fly to shit."
	if(special_l >= 7)
		return "<br>Somehow you just know that [they] [p_are()] as lucky as it gets."
