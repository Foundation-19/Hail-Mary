// Implements the actual effects of perks in gameplay

// ==========================================
// STRENGTH PERKS - Melee Damage Hook
// ==========================================

/obj/item/proc/calc_perk_melee_damage_mod(mob/living/user)
	var/damage_mod = 1.0
	
	if(HAS_TRAIT(user, TRAIT_PERK_IRON_FIST))
		damage_mod += 0.20
	
	if(HAS_TRAIT(user, TRAIT_PERK_BIG_LEAGUES))
		damage_mod += 0.25
	
	return damage_mod

// Steel Fist - Armor bypass on unarmed
/mob/living/carbon/human/proc/has_steel_fist_perk()
	return HAS_TRAIT(src, TRAIT_PERK_STEELFIST)

// Tank - Damage reduction
/mob/living/proc/get_perk_damage_reduction()
	var/reduction = 0.0
	
	if(HAS_TRAIT(src, TRAIT_PERK_TANK))
		reduction += 0.10
	
	if(HAS_TRAIT(src, TRAIT_PERK_TOUGHNESS))
		reduction += 0.10
		
	// Living Legend: -25% damage when below 30% health
	if(HAS_TRAIT(src, TRAIT_PERK_LIVING_LEGEND) && health <= (maxHealth * 0.3))
		reduction += 0.25
	
	return reduction

// Apply damage reduction
/mob/living/proc/apply_perk_damage_reduction(damage, damage_type)
	var/reduction = get_perk_damage_reduction()
	if(reduction > 0)
		damage = max(0, damage * (1 - reduction))
	return damage

// ==========================================
// PERCEPTION PERKS - Awareness & Vision
// ==========================================

// Awareness - Show enemy health on examine
/mob/living/carbon/human/proc/has_awareness_perk()
	return HAS_TRAIT(src, TRAIT_PERK_AWARENESS)

// Night Sight - Low-light vision (handled via trait in actual code)
// The trait itself handles the vision modification

// Sniper - Accuracy bonus
/obj/item/gun/proc/calc_perk_accuracy_mod(mob/living/user)
	var/acc_mod = 0
	
	if(HAS_TRAIT(user, TRAIT_PERK_SNIPER))
		acc_mod += 0.15
	
	return acc_mod

// Targeted - Critical hit bonus
/mob/living/proc/get_perk_crit_chance()
	var/crit_chance = 0
	
	if(HAS_TRAIT(src, TRAIT_PERK_TARGETED))
		crit_chance += 10
		
	if(HAS_TRAIT(src, TRAIT_PERK_CRITICAL_EYE))
		crit_chance += 10
	
	// Safe for Work - No critical fails handled separately
	
	return crit_chance

// ==========================================
// ENDURANCE PERKS - Survival
// ==========================================

// Rad Resistance already handled by trait system
// Toxicity already handled by trait system  
// Fast Healer - Healing item efficiency
/mob/living/proc/get_perk_heal_mod()
	var/heal_mod = 1.0
	
	if(HAS_TRAIT(src, TRAIT_PERK_FAST_HEALER))
		heal_mod += 0.25
	
	return heal_mod

// Water Breathing - handled by trait

// ==========================================
// INTELLIGENCE PERKS - Crafting/Loot
// ==========================================

// Medic - Chem healing efficiency
/mob/living/proc/get_perk_medic_efficiency()
	var/efficiency = 1.0
	
	if(HAS_TRAIT(src, TRAIT_PERK_MEDIC))
		efficiency += 0.25
		
	if(HAS_TRAIT(src, TRAIT_PERK_CHEMIST))
		efficiency += 0.30
	
	return efficiency

// ==========================================
// AGILITY PERKS - Speed/Dodge
// ==========================================

// Action Girl - Sprint regen bonus
/mob/living/carbon/proc/get_perk_sprint_regen_mod()
	var/regen_mod = 1.0
	
	if(HAS_TRAIT(src, TRAIT_PERK_ACTION_GIRL))
		regen_mod += 0.25
		
	// Speed Demon - Additional boost
	if(HAS_TRAIT(src, TRAIT_PERK_SPEED_DEMON))
		regen_mod += 0.20
	
	return regen_mod

// Moving Target - Damage reduction while moving
/mob/living/proc/is_moving_target_perk_active()
	if(!HAS_TRAIT(src, TRAIT_PERK_MOVING_TARGET))
		return FALSE
	
	// Check if currently moving
	return (moving_diagonally != 0 || (m_intent != MOVE_INTENT_WALK))

// Dodger - Dodge chance
/mob/living/proc/get_perk_dodge_chance()
	var/dodge = 0
	
	if(HAS_TRAIT(src, TRAIT_PERK_DODGER))
		dodge += 10
		
	// Martial Arts adds dodge when unarmed
	if(HAS_TRAIT(src, TRAIT_PERK_MARTIAL_ARTS))
		dodge += 15
	
	return dodge

// Silent Running - handled via footsteps check
/mob/living/proc/has_silent_running_perk()
	return HAS_TRAIT(src, TRAIT_PERK_SILENT_RUNNING)

// ==========================================
// LUCK PERKS - Loot/Crits
// ==========================================

// Fortune Finder - Caps multiplier
/mob/proc/get_perk_fortune_multiplier()
	var/multiplier = 1.0
	
	if(HAS_TRAIT(src, TRAIT_PERK_FORTUNE_FINDER))
		multiplier += 0.25
		
	// Greedy Gift adds more
	if(HAS_TRAIT(src, TRAIT_PERK_GREEDY_GIFT))
		multiplier += 0.10
	
	return multiplier

// Looter - Drop rate bonus
/mob/proc/get_perk_loot_multiplier()
	var/multiplier = 1.0
	
	if(HAS_TRAIT(src, TRAIT_PERK_LOOTER))
		multiplier += 0.15
		
	return multiplier

// Mysterious Stranger - Instakill chance
/mob/proc/roll_mysterious_stranger()
	if(HAS_TRAIT(src, TRAIT_PERK_MYSTERIOUS_STRANGER))
		return prob(5)
	return FALSE

// Safe for Work - No crit fails
/mob/proc/has_safe_for_work_perk()
	return HAS_TRAIT(src, TRAIT_PERK_SAFE_FOR_WORK)

// Casino - Slot machine bonus (handled in machine code)

// ==========================================
// CHARISMA PERKS - Social
// ==========================================

// Speaker - Speech check bonus (used in dialogue system)
/mob/living/proc/get_perk_speech_bonus()
	var/bonus = 0
	
	if(HAS_TRAIT(src, TRAIT_PERK_SPEAKER))
		bonus += 20
		
	if(HAS_TRAIT(src, TRAIT_PERK_VOICE_OF_CHARISMA))
		bonus += 10
	
	return bonus

// Merchant - Vendor price bonus (integrated in reputation_effects.dm)
/mob/living/proc/get_perk_vendor_bonus()
	var/bonus = 0
	
	if(HAS_TRAIT(src, TRAIT_PERK_MERCHANT))
		bonus += 10
	
	return bonus

// Leader - Companion damage bonus
/mob/living/carbon/human/proc/get_companion_damage_bonus()
	if(HAS_TRAIT(src, TRAIT_PERK_LEADER))
		return 1.20
	return 1.0

// Animal Friend - Already handled by trait

// Intimidator - Fear action bonus
/mob/living/proc/get_perk_intimidate_bonus()
	if(HAS_TRAIT(src, TRAIT_PERK_INTIMIDATOR))
		return 15
	return 0

// ==========================================
// Initialize perks on spawn
// ==========================================

/mob/living/carbon/human/proc/initialize_perk_system()
	if(!ckey)
		return
	
	// Load and apply perks
	load_player_perks(src)

/mob/living/carbon/human/var/initialized_perks = FALSE
