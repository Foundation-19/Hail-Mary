#define WOUND_DAMAGE_EXPONENT 1.3

/// an attack must do this much damage after armor in order to roll for being a wound (incremental pressure damage need not apply)
#define WOUND_MINIMUM_DAMAGE 3
/// an attack must do this much damage after armor in order to be eliigible to dismember a suitably mushed bodypart
#define DISMEMBER_MINIMUM_DAMAGE 10
/// any damage dealt over this is ignored for damage rolls unless the target has the frail quirk (35^1.4=145)
#define WOUND_MAX_CONSIDERED_DAMAGE	150
/// when rolling for wounds, this is the lowest it'll be multiplied by
#define WOUND_DAMAGE_RANDOM_FLOOR_MULT 1
/// when rolling for wounds, this is the highest it'll be multiplied by
#define WOUND_DAMAGE_RANDOM_MAX_MULT 1.25

#define WOUND_SEVERITY_TRIVIAL	0 // for jokey/meme wounds like stubbed toe, no standard messages/sounds or second winds
#define WOUND_SEVERITY_MODERATE	1
#define WOUND_SEVERITY_SEVERE	2
#define WOUND_SEVERITY_CRITICAL	3
#define WOUND_SEVERITY_LOSS		4 // theoretical total limb loss, like dismemberment for cuts

/// any brute weapon/attack that doesn't have sharpness. rolls for blunt bone wounds
#define WOUND_BLUNT 1
/// any brute weapon/attack with sharpness = SHARP_EDGED. rolls for slash wounds
#define WOUND_SLASH 2
/// any brute weapon/attack with sharpness = SHARP_POINTY. rolls for piercing wounds
#define WOUND_PIERCE 3
/// any concentrated burn attack (lasers really). rolls for burning wounds
#define WOUND_BURN 4

/// Wounds considered for paper skin
#define PAPER_SKIN_WOUNDS list(WOUND_SLASH, WOUND_PIERCE, WOUND_BURN)

// How much determination reagent to add each time someone gains a new wound in [/datum/wound/proc/second_wind()]
#define WOUND_DETERMINATION_MODERATE 5
#define WOUND_DETERMINATION_SEVERE 8
#define WOUND_DETERMINATION_CRITICAL 10
#define WOUND_DETERMINATION_LOSS 15

// If limb's bleed damage is above this, cause this level of severity
#define WOUND_BLEED_MODERATE_THRESHOLD 25
#define WOUND_BLEED_SEVERE_THRESHOLD 50
#define WOUND_BLEED_CRITICAL_THRESHOLD 75

/// Below this amount of bleed damage on a limb, remove all bleeding wounds
#define WOUND_BLEED_CLOSE_THRESHOLD (WOUND_BLEED_MODERATE_THRESHOLD * 0.5)

/// How high can wounding on a limb go
#define WOUND_BLEED_CAP 100

// handle_damage check returns
#define WOUND_PROMOTE "promote_wound"
#define WOUND_DEMOTE "demote_wound"
#define WOUND_RENEW "renew_wound"
#define WOUND_DELETE "delete_wound"
#define WOUND_DO_NOTHING "its_fine"

/// the max amount of determination you can have
#define WOUND_DETERMINATION_MAX 20

/// set wound_bonus on an item or attack to this to disable checking wounding for the attack
#define CANT_WOUND -100

/// Open fracture extra bleeding baseline (applies on top of normal bone wound behavior)
#define WOUND_OPEN_FRACTURE_BLOODFLOW_MODERATE 2
#define WOUND_OPEN_FRACTURE_BLOODFLOW_SEVERE   4
#define WOUND_OPEN_FRACTURE_BLOODFLOW_CRITICAL 6

/// Extra incoming damage multiplier penalty for open fractures (tenderness)
#define WOUND_OPEN_FRACTURE_DAMAGE_MUL_MODERATE 1.10
#define WOUND_OPEN_FRACTURE_DAMAGE_MUL_SEVERE   1.20
#define WOUND_OPEN_FRACTURE_DAMAGE_MUL_CRITICAL 1.35

// list in order of highest severity to lowest
GLOBAL_LIST_INIT(global_wound_types, alist(
	WOUND_BLUNT = list(
		/datum/wound/blunt/open_fracture/critical,
		/datum/wound/blunt/open_fracture/severe,
		/datum/wound/blunt/open_fracture/moderate,
		/datum/wound/blunt/critical,
		/datum/wound/blunt/severe,
		/datum/wound/blunt/moderate),
	WOUND_SLASH = list(
		/datum/wound/bleed/slash),
	WOUND_PIERCE = list(
		/datum/wound/bleed/pierce),
	WOUND_BURN = list(
		/datum/wound/burn/critical,
		/datum/wound/burn/severe,
		/datum/wound/burn/moderate)
))

// List of slash wounds by severity
GLOBAL_LIST_INIT(global_slash_wound_severities, alist(
	WOUND_SEVERITY_MODERATE = /datum/wound/bleed/slash/moderate,
	WOUND_SEVERITY_SEVERE = /datum/wound/bleed/slash/severe,
	WOUND_SEVERITY_CRITICAL = /datum/wound/bleed/slash/critical
))

// List of blunt wounds by severity (classic blunt wounds)
GLOBAL_LIST_INIT(global_blunt_wound_severities, alist(
	WOUND_SEVERITY_MODERATE = /datum/wound/blunt/moderate,
	WOUND_SEVERITY_SEVERE = /datum/wound/blunt/severe,
	WOUND_SEVERITY_CRITICAL = /datum/wound/blunt/critical
))

// List of open fracture wounds by severity
GLOBAL_LIST_INIT(global_open_fracture_wound_severities, alist(
	WOUND_SEVERITY_MODERATE = /datum/wound/blunt/open_fracture/moderate,
	WOUND_SEVERITY_SEVERE = /datum/wound/blunt/open_fracture/severe,
	WOUND_SEVERITY_CRITICAL = /datum/wound/blunt/open_fracture/critical
))

// List of pierce wounds by severity
GLOBAL_LIST_INIT(global_pierce_wound_severities, alist(
	WOUND_SEVERITY_MODERATE = /datum/wound/bleed/pierce/moderate,
	WOUND_SEVERITY_SEVERE = /datum/wound/bleed/pierce/severe,
	WOUND_SEVERITY_CRITICAL = /datum/wound/bleed/pierce/critical
))

GLOBAL_LIST_INIT(global_all_wound_types, list(
	/datum/wound/blunt/open_fracture/critical,
	/datum/wound/blunt/open_fracture/severe,
	/datum/wound/blunt/open_fracture/moderate,
	/datum/wound/blunt/critical,
	/datum/wound/blunt/severe,
	/datum/wound/blunt/moderate,
	/datum/wound/bleed/slash/critical,
	/datum/wound/bleed/slash/severe,
	/datum/wound/bleed/slash/moderate,
	/datum/wound/bleed/pierce/critical,
	/datum/wound/bleed/pierce/severe,
	/datum/wound/bleed/pierce/moderate,
	/datum/wound/burn/critical,
	/datum/wound/burn/severe,
	/datum/wound/burn/moderate
))

// Thresholds for infection for burn wounds, once infestation hits each threshold, things get steadily worse
#define WOUND_INFECTION_MODERATE	3
#define WOUND_INFECTION_SEVERE		6
#define WOUND_INFECTION_CRITICAL	9
#define WOUND_INFECTION_SEPTIC		15

/// how quickly sanitization removes infestation and decays per tick
#define WOUND_BURN_SANITIZATION_RATE 0.25
/// how much blood you can lose per tick per slash max
#define WOUND_MAX_BLOODFLOW 14
/// dead people don't bleed, but they can clot!
#define WOUND_SLASH_DEAD_CLOT_MIN 0.05
/// trauma timer variance
#define WOUND_BONE_HEAD_TIME_VARIANCE 20

#define WOUND_BLEED_MODERATE_BLOOD_LOSS_THRESHOLD BLOOD_VOLUME_SYMPTOMS_ANNOYING + 50
#define WOUND_BLEED_SEVERE_BLOOD_LOSS_THRESHOLD BLOOD_VOLUME_SYMPTOMS_DEBILITATING + 50
#define WOUND_BLEED_CRITICAL_BLOOD_LOSS_THRESHOLD BLOOD_VOLUME_DEATH + 50

#define WOUND_BLEED_MODERATE_BLOOD_LOSS_MULTIPLIER 0.05
#define WOUND_BLEED_SEVERE_BLOOD_LOSS_MULTIPLIER 0.05
#define WOUND_BLEED_CRITICAL_BLOOD_LOSS_MULTIPLIER 0.005
#define WOUND_BLEED_LYING_DOWN_MULTIPLIER 0.50

#define BANDAGE_POOR_MAX_DURATION 10 MINUTES
#define BANDAGE_OKAY_MAX_DURATION 20 MINUTES
#define BANDAGE_GOOD_MAX_DURATION 30 MINUTES

#define BLOODLEAF_MAX_DURATION 15 SECONDS

#define SUTURE_POOR_MAX_DURATION 10 MINUTES
#define SUTURE_OKAY_MAX_DURATION 20 MINUTES
#define SUTURE_GOOD_MAX_DURATION 30 MINUTES

#define BANDAGE_GOODLIFE_DURATION 0.70
#define BANDAGE_MIDLIFE_DURATION 0.30
#define BANDAGE_ENDLIFE_DURATION 0.1

#define SUTURE_GOODLIFE_DURATION 0.70
#define SUTURE_MIDLIFE_DURATION 0.30
#define SUTURE_ENDLIFE_DURATION 0.1

#define BANDAGE_COOLDOWN_ID "bandage_cooldown_id"
#define SUTURE_COOLDOWN_ID "suture_cooldown_id"
#define BLEED_HEAL_COOLDOWN_TIME 1 SECONDS

#define WOUND_BLEED_BANDAGE_MULTIPLIER 0.15
#define WOUND_BLEED_SUTURE_MULTIPLIER 0.05

#define SCAR_SAVE_VERS				1
#define SCAR_SAVE_ZONE				2
#define SCAR_SAVE_DESC				3
#define SCAR_SAVE_PRECISE_LOCATION	4
#define SCAR_SAVE_SEVERITY			5
#define SCAR_SAVE_LENGTH			5
#define SCAR_CURRENT_VERSION		1

#define BODYPART_MANGLED_NONE	0
#define BODYPART_MANGLED_BONE	1
#define BODYPART_MANGLED_FLESH	2
#define BODYPART_MANGLED_BOTH	3

#define BIO_INORGANIC	0
#define BIO_JUST_BONE	1
#define BIO_JUST_FLESH	2
#define BIO_FLESH_BONE	3

#define FLESH_WOUND		(1<<0)
#define BONE_WOUND		(1<<1)
#define MANGLES_FLESH	(1<<2)
#define MANGLES_BONE	(1<<3)
#define ACCEPTS_GAUZE	(1<<4)
#define ACCEPTS_SUTURE	(1<<5)

#define BANDAGE_NEW_APPLIED (1<<0)
#define BANDAGE_WAS_REPAIRED (1<<1)
#define BANDAGE_WAS_REPAIRED_TO_FULL (1<<2)
#define BANDAGE_TIMER_REFILLED (1<<3)
#define BANDAGE_NOT_APPLIED (1<<4)
#define BANDAGE_STILL_INTACT (1<<5)
#define BANDAGE_TIMED_OUT (1<<6)
#define BANDAGE_NOT_FOUND (1<<7)

#define SUTURE_NEW_APPLIED (1<<8)
#define SUTURE_WAS_REPAIRED (1<<9)
#define SUTURE_WAS_REPAIRED_TO_FULL (1<<10)
#define SUTURE_TIMER_REFILLED (1<<11)
#define SUTURE_NOT_APPLIED (1<<12)
#define SUTURE_STILL_INTACT (1<<13)
#define SUTURE_TIMED_OUT (1<<14)
#define SUTURE_NOT_FOUND (1<<15)

#define BANDAGE_DAMAGE_THRESHOLD_LOW 5
#define BANDAGE_DAMAGE_THRESHOLD_MED 20
#define BANDAGE_DAMAGE_THRESHOLD_MAX 45
#define BANDAGE_BURN_MULT 3

#define BLOODLEAF_HEAL_OVER_TIME 1
#define BANDAGE_HEAL_OVER_TIME_BASE 0.1

#define BANDAGE_IMPROVISED_HEAL_OVER_TIME (BANDAGE_HEAL_OVER_TIME_BASE * 0.5)
#define BANDAGE_NORMAL_HEAL_OVER_TIME (BANDAGE_HEAL_OVER_TIME_BASE * 1)
#define BANDAGE_MEDICAL_HEAL_OVER_TIME (BANDAGE_HEAL_OVER_TIME_BASE * 2)

#define SUTURE_HEAL_OVER_TIME_BASE 0.2

#define SUTURE_IMPROVISED_HEAL_OVER_TIME (SUTURE_HEAL_OVER_TIME_BASE * 0.5)
#define SUTURE_NORMAL_HEAL_OVER_TIME (SUTURE_HEAL_OVER_TIME_BASE * 1)
#define SUTURE_MEDICAL_HEAL_OVER_TIME (SUTURE_HEAL_OVER_TIME_BASE * 2)

#define SUTURE_DAMAGE_THRESHOLD_LOW 1
#define SUTURE_DAMAGE_THRESHOLD_MED 20
#define SUTURE_DAMAGE_THRESHOLD_MAX 35
#define SUTURE_BURN_MULT 5

#define SUTURE_BASE_WOUND_CLOSURE 0.40
#define SUTURE_GOOD_WOUND_CLOSURE (SUTURE_BASE_WOUND_CLOSURE * 1.5)
#define SUTURE_BEST_WOUND_CLOSURE (SUTURE_BASE_WOUND_CLOSURE * 3)

#define BANDAGE_BASE_WOUND_CLOSURE (SUTURE_BASE_WOUND_CLOSURE * 0.5)
#define BANDAGE_GOOD_WOUND_CLOSURE (BANDAGE_BASE_WOUND_CLOSURE * 1.5)
#define BANDAGE_BEST_WOUND_CLOSURE (BANDAGE_BASE_WOUND_CLOSURE * 3)

#define BANDAGE_BASE_WOUND_MAX (WOUND_BLEED_MODERATE_THRESHOLD)
#define BANDAGE_GOOD_WOUND_MAX (WOUND_BLEED_SEVERE_THRESHOLD)
#define BANDAGE_BEST_WOUND_MAX (WOUND_BLEED_SEVERE_THRESHOLD)

#define SUTURE_AND_BANDAGE_BONUS 2

#define WOUND_HEAL_NUTRITION_COST 4
#define WOUND_HEAL_FULL 5
#define WOUND_HEAL_FED 1
#define WOUND_HEAL_HUNGRY 1

#define DAMAGE_HEAL_NUTRITION_COST 2
#define DAMAGE_HEAL_FULL 3
#define DAMAGE_HEAL_FED 2
#define DAMAGE_HEAL_HUNGRY 1

#define COVERING_SUTURE "suture"
#define COVERING_BANDAGE "bandage"

#define COVERING_TIME_TRUE "time in deciseconds"
#define COVERING_TIME_MINUTE "time in minutes"
#define COVERING_TIME_MINUTE_FUZZY "fuzzy time in minutes"
#define COVERING_TIME_MINUTE_FUZZY_DELTA (5 MINUTES)
