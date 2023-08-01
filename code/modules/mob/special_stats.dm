//////////////////////////////////////////////////////
////////////////////SUBTLE COMMAND////////////////////
//////////////////////////////////////////////////////

#define DEFAULT_SPECIAL_ATTR_VALUE 5
#define MIN_INT_CRAFTING_REQUIREMENT 3
/mob
	var/flavor_text = "" //tired of fucking double checking this
	var/special_s = DEFAULT_SPECIAL_ATTR_VALUE // +/-2 dmg in melee for each level above/below 5 ST
	var/special_p = DEFAULT_SPECIAL_ATTR_VALUE // +/- 5 degrees of innate gun spread for each level below/above 5 PR
	var/special_e = DEFAULT_SPECIAL_ATTR_VALUE // +/-5 maxHealth for each level above/below 5 END
	var/special_c = DEFAULT_SPECIAL_ATTR_VALUE // Desc message + moodlets
	var/special_i = DEFAULT_SPECIAL_ATTR_VALUE // Can't craft with INT under MIN_INT_CRAFTING_REQUIREMENT, certain recipes can be INT locked, certain guns can be INT locked
	var/special_a = DEFAULT_SPECIAL_ATTR_VALUE // +/- 10% Sprint stamina usage modifier -/+ 0.05 movespeed modifier per lvl below/above 5 AGI
	var/special_l = DEFAULT_SPECIAL_ATTR_VALUE //done 10+3.5*l chance to get bonus items from trash piles

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
	return ((user.special_s - DEFAULT_SPECIAL_ATTR_VALUE) * 2)

/datum/species/proc/calc_unarmed_dam_mod_from_special(mob/living/user)
	return ((user.special_s - DEFAULT_SPECIAL_ATTR_VALUE) * 2)

/// PERCEPTION

/obj/item/ammo_casing/proc/calc_bullet_spread_mod_from_special(mob/living/user)
	return ((user.special_p - DEFAULT_SPECIAL_ATTR_VALUE) * 5) // +/- 5 degrees of innate spread per lvl

/// ENDURANCE

/mob/living/carbon/human/initialize_special_endurance()
	maxHealth = initial(maxHealth) + ((special_e - DEFAULT_SPECIAL_ATTR_VALUE) * 5)
	health = maxHealth

/// CHARISMA

/mob/living/carbon/human/initialize_special_charisma()
	RegisterSignal(src, COMSIG_PARENT_EXAMINE, .proc/handle_special_charisma_examine_moodlet)

/mob/living/carbon/human/Destroy()
	UnregisterSignal(src, COMSIG_PARENT_EXAMINE)
	return ..()


/mob/proc/handle_special_charisma_examine_moodlet(mob/living/examiner)
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
	description = span_boldwarning("special_disgusting_char_desc")
	mood_change = -5
	timeout = 5 MINUTES

/datum/mood_event/special_bad_looking_char
	description = span_warning("special_bad_looking_char_desc")
	mood_change = -2
	timeout = 4 MINUTES

/datum/mood_event/special_good_looking_char
	description = span_nicegreen("special_good_looking_char_desc")
	mood_change = 2
	timeout = 5 MINUTES

/datum/mood_event/special_beautiful_char
	description = span_nicegreen("special_beautiful_char_desc")
	mood_change = 5
	timeout = 6 MINUTES

/// INTELLIGENCE

/obj/item/gun/proc/gun_firing_special_stat_check(mob/living/user)
	if(user.special_i >= required_int_to_fire)
		return TRUE
	to_chat(user, "How do you use this thing?!")
	return FALSE

/datum/component/personal_crafting/proc/special_crafting_check(mob/living/user)
	if(!istype(user))
		return FALSE
	if(user.special_i <= MIN_INT_CRAFTING_REQUIREMENT)
		to_chat(user,  "Your brain is too dumb to craft items.")
		return FALSE
	return TRUE

/datum/crafting_recipe/proc/special_crafting_requirements_check(mob/user)
	return (user.special_i >= required_int)

/datum/crafting_recipe/proc/generate_special_req_text()
	return ", [required_int] Intelligence"

/// AGILITY

/mob/living/proc/calc_sprint_stamina_mod_from_special()
	return

/mob/living/carbon/calc_sprint_stamina_mod_from_special()
	return (1 - ((user.special_a - DEFAULT_SPECIAL_ATTR_VALUE) * 0.1))

/mob/proc/calc_movespeed_mod_from_special()
	return -((user.special_a - DEFAULT_SPECIAL_ATTR_VALUE) * 0.05)

/// LUCK




/// misc examine procs
/mob/proc/generate_special_examine_text()
	var/msg = "*---------*" //S:[special_s],P:[special_p],E:[special_e],C:[special_c],I:[special_i],A:[special_a],L:[special_l]<br>"

	if (special_s<3) // Str
		msg += "<br>This person looks puny, like a total noodle."
	if (special_p<3) // Per
		msg += "<br>Even with glasses, an elephant could easily sneak by them."
	if (special_e<3) // End
		msg += "<br>It looks like a stiff breeze could tear them in two."
	if (special_i<3) // Int
		msg += "<br>They look like they'd struggle to get water out of a boot with instructions printed on the heel."
	if (special_a<3) // Agi
		msg += "<br>Maladroit and unbalanced, it is a wonder they can even stand straight."
	if (special_l<3) // Lck
		msg += "<br>Misfortune just seems to stick to them like a fly to shit."


	//Charisma
	msg += gen_charisma_examine_text()

	if (special_s>7) // Str
		msg += "<br>Simply built out of muscle, they could wrestle a deathclaw to death."
	if (special_p>7) // Per
		msg += "<br>A sharp and attentive gaze almost pierces through you, nothing gets past them it seems."
	if (special_e>7) // End
		msg += "<br>As solid as an oak, they look like they could run for miles on end."
	if (special_i>7) // Int
		msg += "<br>A bright and careful gaze in their eyes, they seem to know much more than you."
	if (special_a>7) // Agi
		msg += "<br>Moving like a panther, it is a wonder you have even noticed that they are here."
	if (special_l>7) // Lck
		msg += "<br>Somehow you just know that they are as lucky as it gets."
	msg += "<br> *---------*"
	return msg

/mob/proc/gen_charisma_examine_text()
	switch(special_c)
		if(1)
			return "<br>You struggle not to vomit looking at this horribly fugly creature."
		if(2)
			return "<br>They look like a product of incest."
		if(3)
			return "<br>They look kinda ugly."
		if(4)
			return "<br>They look a little off appearance-wise."
		if(5)
			return "<br>They look incredibly average."
		if(6)
			return "<br>They look slightly better than your average waster."
		if(7)
			return "<br>They look pretty damn good."
		if(8)
			return "<br>They look strikingly great."
		if(9)
			return "<br>They look exceptionally beautiful."
		if(10)
			return "<br>They have a perfect beauty to them leagues above the rest."
