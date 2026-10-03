/mob/living/carbon/human
	hud_possible = list(
		HEALTH_HUD,
		STATUS_HUD,
		ID_HUD,
		WANTED_HUD,
		IMPLOYAL_HUD,
		IMPCHEM_HUD,
		IMPTRACK_HUD,
		NANITE_HUD,
		DIAG_NANITE_FULL_HUD,
		ANTAG_HUD,
		GLAND_HUD,
		SENTIENT_DISEASE_HUD,
		RAD_HUD,
		ONLINE_HUD,
		)
	hud_type = /datum/hud/human
	possible_a_intents = list(INTENT_HELP, INTENT_DISARM, INTENT_GRAB, INTENT_HARM)
	pressure_resistance = 25
	can_buckle = TRUE
	buckle_lying = FALSE
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	/// Enable stamina combat
	combat_flags = COMBAT_FLAGS_DEFAULT | COMBAT_FLAG_UNARMED_PARRY | COMBAT_FLAG_UNARMED_BLOCK
	status_flags = CANSTUN|CANKNOCKDOWN|CANUNCONSCIOUS|CANPUSH|CANSTAGGER
	has_field_of_vision = FALSE //Handled by species.

	blocks_emissive = EMISSIVE_BLOCK_UNIQUE

	block_parry_data = /datum/block_parry_data/unarmed/human

	//Hair colour and style
	var/hair_color = "000"
	var/hair_style = "Bald"

	//Facial hair colour and style
	var/facial_hair_color = "000"
	var/facial_hair_style = "Shaved"

	//Eye colour
	var/left_eye_color = "000"
	var/right_eye_color = "000"

	var/skin_tone = "caucasian1"	//Skin tone

	var/lip_style = null	//no lipstick by default- arguably misleading, as it could be used for general makeup
	var/lip_color = "white"

	var/age = 30		//Player's age

	var/underwear = "Nude"	//Which underwear the player wants
	var/undie_color = "FFFFFF"
	var/undershirt = "Nude" //Which undershirt the player wants
	var/shirt_color = "FFFFFF"
	var/socks = "Nude" //Which socks the player wants
	var/socks_color = "FFFFFF"

	var/warpaint = null
	var/warpaint_color = null

	//Equipment slots
	var/obj/item/wear_suit = null
	var/obj/item/w_uniform = null
	var/obj/item/belt = null
	var/obj/item/wear_id = null
	var/obj/item/r_store = null
	var/obj/item/l_store = null
	var/obj/item/s_store = null

/// When an braindead player has their equipment fiddled with, we log that info here for when they come back so they know who took their ID while they were DC'd for 30 seconds
	var/list/afk_thefts

	var/special_voice = "" // For changing our voice. Used by a symptom.

	var/bleedsuppress = 0 //for stopping bloodloss, eventually this will be limb-based like bleeding

	var/blood_state = BLOOD_STATE_NOT_BLOODY
	var/list/blood_smear = list(BLOOD_STATE_BLOOD = 0, BLOOD_STATE_OIL = 0, BLOOD_STATE_NOT_BLOODY = 0)

	var/name_override //For temporary visible name changes

	var/custom_species = null

	var/datum/physiology/physiology

	/// Multiplier last applied to physiology by the active party aura (Guardian/Operative) - tracked so it can be divided back out cleanly on removal or aura swap.
	var/party_aura_applied_mod

	/// Multiplier last applied to physiology by party_friction's Intelligence-mismatch miscommunication penalty - tracked the same way as party_aura_applied_mod so it divides back out cleanly.
	var/party_friction_applied_mod

	var/list/datum/bioware = list()

	var/creamed = FALSE //to use with creampie overlays
	var/static/list/can_ride_typecache = typecacheof(list(/mob/living/carbon/human, /mob/living/simple_animal/slime, /mob/living/simple_animal/parrot))
	var/lastpuke = 0
	var/account_id
	var/last_fire_update

	var/busy= FALSE

	var/thirst = THIRST_LEVEL_START

/// Unarmed parry/block data for human
/datum/block_parry_data/unarmed/human
	parry_respect_clickdelay = TRUE
	parry_stamina_cost = 4
	parry_attack_types = ATTACK_TYPE_UNARMED
	parry_flags = PARRY_DEFAULT_HANDLE_FEEDBACK | PARRY_LOCK_ATTACKING

	parry_time_windup = 0
	parry_time_spindown = 1
	parry_time_active = 5

	parry_time_perfect = 1
	parry_time_perfect_leeway = 1
	parry_imperfect_falloff_percent = 20
	parry_efficiency_perfect = 100

	parry_efficiency_considered_successful = 0.01
	parry_efficiency_to_counterattack = 0.01
	parry_max_attacks = 3
	parry_cooldown = 30
	parry_failed_stagger_duration = 0

	// Raised forearms are not a shield - whatever's left after this gets reduced again by worn armor in the normal
	// run_armor_check() pass, so the two are meant to stack, not for this alone to carry the whole mitigation job.
	block_damage_absorption = 3 // vs shield's 5, chair's 7, base 10 - bare arms barely take the edge off a hit
	block_damage_multiplier = 0.85 // vs shield's 0.25, chair's 0.7 - most of the overrun still gets through
	block_damage_limit = 25 // vs shield/base 80, chair's 20 - a real hit just blows through your guard entirely
	block_stamina_efficiency = 1.25 // vs shield's 2.5, chair's 2, base 3 - eating it on your own arms costs way more stamina per point blocked
	block_resting_stamina_penalty_multiplier = 2 // no leverage at all without an object while downed
	block_projectile_mitigation = 5 // vs shield's 75, chair's 20 - your forearm does nothing against a bullet
	block_slowdown = 0.5
	block_start_delay = 1 // no gear to hoist, fists come up fast
	block_sounds = list('sound/weapons/punch1.ogg' = 1, 'sound/weapons/punch2.ogg' = 1, 'sound/weapons/punch3.ogg' = 1, 'sound/weapons/punch4.ogg' = 1)
	parry_failed_clickcd_duration = 0.4

	parry_data = list(			// yeah it's snowflake
		"HUMAN_PARRY_STAGGER" = 3 SECONDS,
		"HUMAN_PARRY_PUNCH" = TRUE,
		"HUMAN_PARRY_MININUM_EFFICIENCY" = 0.9
	)

/mob/living/carbon/human/on_active_parry(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, list/block_return, parry_efficiency, parry_time)
	var/datum/block_parry_data/D = return_block_parry_datum(block_parry_data)
	if(!owner.Adjacent(attacker))
		return ..()
	if(parry_efficiency < D.parry_data["HUMAN_PARRY_MINIMUM_EFFICIENCY"])
		return ..()
	visible_message(span_warning("[src] strikes back perfectly at [attacker], staggering them!"))
	if(D.parry_data["HUMAN_PARRY_PUNCH"])
		UnarmedAttack(attacker, TRUE, INTENT_HARM, ATTACK_IS_PARRY_COUNTERATTACK | ATTACK_IGNORE_ACTION | ATTACK_IGNORE_CLICKDELAY | NO_AUTO_CLICKDELAY_HANDLING)
	var/mob/living/L = attacker
	if(istype(L))
		L.Stagger(D.parry_data["HUMAN_PARRY_STAGGER"])
