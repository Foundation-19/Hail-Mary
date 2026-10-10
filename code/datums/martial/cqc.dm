#define SLAM_COMBO "DH"
#define KICK_COMBO "HH"
#define RESTRAIN_COMBO "GG"
#define PRESSURE_COMBO "DDD"
#define CONSECUTIVE_COMBO "DDH"

/datum/martial_art/cqc
	name = "CQC"
	id = MARTIALART_CQC
	help_verb = /mob/living/carbon/human/proc/CQC_help
	block_chance = 75
	pugilist = TRUE
	var/old_grab_state = null

/datum/martial_art/cqc/reset_streak(mob/living/carbon/human/new_target)
	. = ..()
	restraining = FALSE

/datum/martial_art/cqc/proc/check_streak(mob/living/carbon/human/A, mob/living/carbon/human/D)
	if(!can_use(A))
		return FALSE
	if(findtext(streak,SLAM_COMBO))
		streak = ""
		Slam(A,D)
		return TRUE
	if(findtext(streak,KICK_COMBO))
		streak = ""
		Kick(A,D)
		return TRUE
	if(findtext(streak,RESTRAIN_COMBO))
		streak = ""
		Restrain(A,D)
		return TRUE
	if(findtext(streak,PRESSURE_COMBO))
		streak = ""
		Pressure(A,D)
		return TRUE
	if(findtext(streak,CONSECUTIVE_COMBO))
		streak = ""
		Consecutive(A,D)
	return FALSE

/datum/martial_art/cqc/proc/Slam(mob/living/carbon/human/A, mob/living/carbon/human/D)
	if(!can_use(A))
		return FALSE
	var/damage = (damage_roll(A,D) + 5)
	if(CHECK_MOBILITY(D, MOBILITY_STAND))
		D.visible_message(span_warning("%ACTOR_NAME% slams %SELF_NAME% into the ground!"), \
							span_userdanger("%ACTOR_NAME% slams you into the ground!"), \
							visible_message_flags = ANONYMIZE_NAMES, name_actor = A)
		playsound(get_turf(A), 'sound/weapons/slam.ogg', 50, 1, -1)
		deal_damage(A, D, damage, BRUTE)
		D.DefaultCombatKnockdown(120 * A.get_strength_grapple_control_multiplier() * D.get_endurance_grapple_resist_multiplier())
		log_combat(A, D, "slammed (CQC)")
	return TRUE

/datum/martial_art/cqc/proc/Kick(mob/living/carbon/human/A, mob/living/carbon/human/D)
	if(!can_use(A))
		return FALSE
	var/damage = damage_roll(A,D)
	if(!CHECK_MOBILITY(D, MOBILITY_STAND) && CHECK_MOBILITY(D, MOBILITY_USE))
		log_combat(A, D, "knocked out (Head kick)(CQC)")
		D.visible_message(span_warning("%ACTOR_NAME% kicks %SELF_NAME%'s head, knocking [D.p_them()] out!"), \
							span_userdanger("%ACTOR_NAME% kicks your head, knocking you out!"), \
							visible_message_flags = ANONYMIZE_NAMES, name_actor = A)
		playsound(get_turf(A), 'sound/weapons/genhit1.ogg', 50, 1, -1)
		var/ko_control_mod = A.get_strength_grapple_control_multiplier() * D.get_endurance_grapple_resist_multiplier()
		D.SetSleeping(300 * ko_control_mod)
		deal_damage(A, D, damage + 5, BRUTE)
		var/atom/throw_target = get_edge_target_turf(D, A.dir)
		D.throw_at(throw_target, 1, 14, A)
		D.adjustOrganLoss(ORGAN_SLOT_BRAIN, (damage + 10) * ko_control_mod, 150)
	else
		D.visible_message(span_warning("%ACTOR_NAME% kicks %SELF_NAME%!"), \
							span_userdanger("%ACTOR_NAME% kicks you!"), \
							visible_message_flags = ANONYMIZE_NAMES, name_actor = A)
		playsound(get_turf(A), 'sound/weapons/cqchit1.ogg', 50, 1, -1)
		D.Dizzy(damage)
		deal_damage(A, D, damage + 15, BRUTE)
		var/atom/throw_target = get_edge_target_turf(D, A.dir)
		D.throw_at(throw_target, 1, 14, A)
		log_combat(A, D, "kicked (CQC)")
	return TRUE

/datum/martial_art/cqc/proc/Pressure(mob/living/carbon/human/A, mob/living/carbon/human/D)
	if(!can_use(A))
		return FALSE
	var/damage = (damage_roll(A,D) + 55)
	log_combat(A, D, "pressured (CQC)")
	D.visible_message(span_warning("%ACTOR_NAME% punches %SELF_NAME%'s neck!"), \
		visible_message_flags = ANONYMIZE_NAMES, name_actor = A)
	deal_damage(A, D, damage, STAMINA)
	playsound(get_turf(A), 'sound/weapons/cqchit1.ogg', 50, 1, -1)
	return TRUE

/datum/martial_art/cqc/proc/Restrain(mob/living/carbon/human/A, mob/living/carbon/human/D)
	if(restraining)
		return
	if(!can_use(A))
		return FALSE
	var/damage = (damage_roll(A,D) + 15)
	if(!D.stat)
		log_combat(A, D, "restrained (CQC)")
		D.visible_message(span_warning("%ACTOR_NAME% locks %SELF_NAME% into a restraining position!"), \
							span_userdanger("%ACTOR_NAME% locks you into a restraining position!"), \
							visible_message_flags = ANONYMIZE_NAMES, name_actor = A)
		deal_damage(A, D, damage, STAMINA)
		D.Stun(100 * A.get_strength_grapple_control_multiplier() * D.get_endurance_grapple_resist_multiplier())
		restraining = TRUE
		addtimer(VARSET_CALLBACK(src, restraining, FALSE), 50, TIMER_UNIQUE)
	return TRUE

/datum/martial_art/cqc/proc/Consecutive(mob/living/carbon/human/A, mob/living/carbon/human/D)
	if(!can_use(A))
		return FALSE
	var/damage = damage_roll(A,D)
	if(!D.stat)
		log_combat(A, D, "consecutive CQC'd (CQC)")
		D.visible_message(span_warning("%ACTOR_NAME% strikes %SELF_NAME%'s abdomen, neck and back consecutively"), \
							span_userdanger("%ACTOR_NAME% strikes your abdomen, neck and back consecutively!"), \
							visible_message_flags = ANONYMIZE_NAMES, name_actor = A)
		playsound(get_turf(D), 'sound/weapons/cqchit2.ogg', 50, 1, -1)
		var/obj/item/I = D.get_active_held_item()
		if(I && D.temporarilyRemoveItemFromInventory(I))
			A.put_in_hands(I)
		deal_damage(A, D, damage + 45, STAMINA)
		deal_damage(A, D, damage + 20, BRUTE)
	return TRUE

/datum/martial_art/cqc/grab_act(mob/living/carbon/human/A, mob/living/carbon/human/D)
	if(A.a_intent == INTENT_GRAB && A!=D && can_use(A)) // A!=D prevents grabbing yourself
		add_to_streak("G",D)
		if(check_streak(A,D)) //if a combo is made no grab upgrade is done
			return TRUE
		old_grab_state = A.grab_state
		D.grabbedby(A, 1)
		return TRUE
	return FALSE

/datum/martial_art/cqc/harm_act(mob/living/carbon/human/A, mob/living/carbon/human/D)
	if(!can_use(A))
		return FALSE
	add_to_streak("H",D)
	if(check_streak(A,D))
		return TRUE
	log_combat(A, D, "attacked (CQC)")
	A.do_attack_animation(D)
	var/picked_hit_type = pick("CQC'd", "Big Bossed")
	var/bonus_damage = (damage_roll(A,D) + 7)
	if(!CHECK_MOBILITY(D, MOBILITY_STAND))
		bonus_damage += 5
		picked_hit_type = "stomps on"
	deal_damage(A, D, bonus_damage, BRUTE)
	if(picked_hit_type == "kicks" || picked_hit_type == "stomps on")
		playsound(get_turf(D), 'sound/weapons/cqchit2.ogg', 50, 1, -1)
	else
		playsound(get_turf(D), 'sound/weapons/cqchit1.ogg', 50, 1, -1)
	D.visible_message(span_danger("%ACTOR_NAME% [picked_hit_type] %SELF_NAME%!"), \
					span_userdanger("%ACTOR_NAME% [picked_hit_type] you!"), \
					visible_message_flags = ANONYMIZE_NAMES, name_actor = A)
	log_combat(A, D, "[picked_hit_type] (CQC)")
	if(!CHECK_MOBILITY(A, MOBILITY_STAND) && !D.stat && CHECK_MOBILITY(D, MOBILITY_STAND))
		D.visible_message("<span class='warning'>%ACTOR_NAME% leg sweeps %SELF_NAME%!", \
							span_userdanger("%ACTOR_NAME% leg sweeps you!"), \
							visible_message_flags = ANONYMIZE_NAMES, name_actor = A)
		playsound(get_turf(A), 'sound/effects/hit_kick.ogg', 50, 1, -1)
		deal_damage(A, D, bonus_damage, BRUTE)
		D.DefaultCombatKnockdown(60)
		log_combat(A, D, "sweeped (CQC)")
	return TRUE

/datum/martial_art/cqc/disarm_act(mob/living/carbon/human/A, mob/living/carbon/human/D)
	if(!can_use(A))
		return FALSE
	add_to_streak("D",D)
	var/obj/item/I = null
	var/damage = damage_roll(A,D)
	var/stunthreshold = A.dna.species.punchstunthreshold
	if(check_streak(A,D))
		return TRUE
	if(CHECK_MOBILITY(D, MOBILITY_MOVE) || !restraining)
		A.do_attack_animation(D, ATTACK_EFFECT_PUNCH)
		if(damage >= stunthreshold)	
			I = D.get_active_held_item()
			D.visible_message(span_warning("%ACTOR_NAME% strikes %SELF_NAME%'s jaw with their hand!"), \
							span_userdanger("%ACTOR_NAME% strikes your jaw, disorienting you!"), \
							visible_message_flags = ANONYMIZE_NAMES, name_actor = A)
			playsound(get_turf(D), 'sound/weapons/cqchit1.ogg', 50, 1, -1)
			D.drop_all_held_items()
			D.Jitter(2)
			D.Dizzy(damage)
			deal_damage(A, D, damage*2 + 20, STAMINA)
			deal_damage(A, D, damage*0.5, BRUTE)
		else
			D.visible_message(span_danger("%ACTOR_NAME% strikes %SELF_NAME% in the chest!"), \
							span_userdanger("%ACTOR_NAME% strikes you in the chest!"), \
							visible_message_flags = ANONYMIZE_NAMES, name_actor = A)
			playsound(D, 'sound/weapons/cqchit1.ogg', 25, 1, -1)
			deal_damage(A, D, damage + 15, STAMINA)
			deal_damage(A, D, damage*0.5, BRUTE)
		log_combat(A, D, "disarmed (CQC)", "[I ? " grabbing \the [I]" : ""]")
	if(restraining && A.pulling == D)
		log_combat(A, D, "knocked out (Chokehold)(CQC)")
		D.visible_message(span_danger("%ACTOR_NAME% puts %SELF_NAME% into a chokehold!"), \
							span_userdanger("%ACTOR_NAME% puts you into a chokehold!"), \
							visible_message_flags = ANONYMIZE_NAMES, name_actor = A)
		restraining = FALSE
		if(A.grab_state < GRAB_NECK)
			A.setGrabState(GRAB_NECK)
	else
		restraining = FALSE
		return FALSE
	return TRUE

/mob/living/carbon/human/proc/CQC_help()
	set name = "Remember The Basics"
	set desc = "You try to remember some of the basics of CQC."
	set category = "CQC"
	to_chat(usr, "<b><i>You try to remember some of the basics of CQC.</i></b>")

	to_chat(usr, "<span class='notice'>Slam</span>: Disarm Harm. Slam opponent into the ground, knocking them down.")
	to_chat(usr, "<span class='notice'>CQC Kick</span>: Harm Harm. Knocks opponent away. Knocks out stunned or knocked down opponents.")
	to_chat(usr, "<span class='notice'>Restrain</span>: Grab Grab. Locks opponents into a restraining position, disarm to knock them out with a chokehold.")
	to_chat(usr, "<span class='notice'>Pressure</span>: Disarm Disarm Disarm. Decent stamina damage.")
	to_chat(usr, "<span class='notice'>Consecutive CQC</span>: Disarm Disarm Harm. Mainly offensive move, huge damage and decent stamina damage.")

	to_chat(usr, "<b><i>In addition, by having your throw mode on when being attacked, you enter an active defense mode where you have a chance to block and sometimes even counter attacks done to you.</i></b>")
	to_chat(usr, "<b><i>YOU DON'T INSTANTLY AGGRO GRAB ANYMORE. DON'T TRY IT BOSS.</i></b>")

///Subtype of CQC. Only used for the chef.
/datum/martial_art/cqc/under_siege
	name = "Close Quarters Cooking"

///Prevents use if the cook is not in the kitchen.
/datum/martial_art/cqc/under_siege/can_use(mob/living/carbon/human/H) //this is used to make chef CQC only work in kitchen
	if(!istype(get_area(H), /area/crew_quarters/kitchen))
		return FALSE
	return ..()
