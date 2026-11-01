//Declarative quirk base used by the Trait/Perk/Liability expansion. Every quirk below is built from the
//same small set of REAL, already-wired hooks - SPECIAL deltas (via the set_special_* setters),
//mob physiology multipliers/adders, plain mob traits, and a periodic on_process - so nothing in here
//is a placeholder: if it is listed, it does something. Effects that would need brand-new combat/loot/chem
//hooks (crit chance, loot quality, fire rate, addiction rules...) are intentionally NOT in this file.

/datum/quirk/modular
	abstract_type = /datum/quirk/modular
	var/list/special_mods //"s"/"p"/"e"/"c"/"i"/"a"/"l" -> flat delta applied while the quirk is held (clamped to SPECIAL limits)
	var/list/physio_mult ///datum/physiology var name -> multiplier
	var/list/physio_add ///datum/physiology var name -> flat addition
	var/list/trait_flags //mob traits granted while held
	var/health_bonus = 0 //flat maxHealth change, applied once on spawn like Life Giver
	var/list/applied_special = list() //actual (post-clamp) deltas applied, so removal reverses exactly
	var/list/active_dyn = list() //currently-applied conditional physiology additions (see set_dyn)

/datum/quirk/modular/proc/shift_special(mob/living/L, stat, delta)
	var/old_value = L.vars["special_[stat]"]
	var/target = clamp(old_value + delta, SPECIAL_MIN_ATTR_VALUE, SPECIAL_MAX_ATTR_VALUE)
	switch(stat)
		if("s")
			L.set_special_s(target)
		if("p")
			L.set_special_p(target)
		if("e")
			L.set_special_e(target)
		if("c")
			L.set_special_c(target)
		if("i")
			L.set_special_i(target)
		if("a")
			L.set_special_a(target)
		if("l")
			L.set_special_l(target)
	return target - old_value

/datum/quirk/modular/add()
	var/mob/living/carbon/human/H = quirk_holder
	for(var/stat in special_mods)
		applied_special[stat] = shift_special(H, stat, special_mods[stat])
	for(var/v in physio_mult)
		H.physiology.vars[v] *= physio_mult[v]
	for(var/v in physio_add)
		H.physiology.vars[v] += physio_add[v]
	for(var/t in trait_flags)
		ADD_TRAIT(H, t, "[type]")

/datum/quirk/modular/on_spawn()
	if(!health_bonus)
		return
	var/mob/living/carbon/human/H = quirk_holder
	H.maxHealth += health_bonus
	H.health += health_bonus

/datum/quirk/modular/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(QDELETED(H))
		return
	set_dyn(null)
	for(var/stat in applied_special)
		shift_special(H, stat, -applied_special[stat])
	applied_special = list()
	for(var/v in physio_mult)
		H.physiology.vars[v] /= physio_mult[v]
	for(var/v in physio_add)
		H.physiology.vars[v] -= physio_add[v]
	for(var/t in trait_flags)
		REMOVE_TRAIT(H, t, "[type]")
	if(health_bonus)
		H.maxHealth -= health_bonus
		H.health = min(H.health, H.maxHealth)

//Swaps the conditional (state-dependent) physiology additions; pass null to clear them
/datum/quirk/modular/proc/set_dyn(list/new_mods)
	var/mob/living/carbon/human/H = quirk_holder
	if(!istype(H) || !H.physiology)
		return
	for(var/v in active_dyn)
		H.physiology.vars[v] -= active_dyn[v]
	active_dyn = new_mods ? new_mods.Copy() : list()
	for(var/v in active_dyn)
		H.physiology.vars[v] += active_dyn[v]

/datum/quirk/modular/proc/nearby_people(range = 7)
	. = 0
	for(var/mob/living/carbon/human/O in oview(range, quirk_holder))
		if(O.stat != DEAD && O.client)
			.++

/datum/quirk/modular/proc/health_fraction()
	var/mob/living/carbon/human/H = quirk_holder
	return H.maxHealth > 0 ? H.health / H.maxHealth : 1

/* ------------------------------ Free Wasteland Traits ------------------------------ */

/datum/quirk/modular/trait_kamikaze
	name = "Kamikaze"
	desc = "You hit hard and think about the consequences later. Your melee and unarmed attacks hit harder, but you take more damage from everything."
	value = 0
	is_trait = TRUE
	trait_flags = list(TRAIT_BIG_LEAGUES_MID)
	physio_mult = list("brute_mod" = 1.15, "burn_mod" = 1.15)
	gain_text = span_notice("You feel reckless and strong, and a little less careful with yourself.")
	lose_text = span_danger("You feel cautious again.")
	medical_record_text = "Patient shows a pronounced disregard for personal safety."

/datum/quirk/modular/trait_hot_blooded
	name = "Hot Blooded"
	desc = "Your blood runs hot. You shrug off the cold, but heat and fire hurt you much more."
	value = 0
	is_trait = TRUE
	trait_flags = list(TRAIT_RESISTCOLD)
	physio_mult = list("heat_mod" = 1.4)
	gain_text = span_notice("You feel warm all the way through.")
	lose_text = span_danger("Your body temperature feels normal again.")
	medical_record_text = "Patient runs hot: cold-tolerant, heat-sensitive."

/datum/quirk/modular/trait_cold_blooded
	name = "Cold Blooded"
	desc = "You thrive in heat and barely notice it, but the cold bites you much harder."
	value = 0
	is_trait = TRUE
	trait_flags = list(TRAIT_RESISTHEAT)
	physio_mult = list("cold_mod" = 1.4)
	gain_text = span_notice("The heat feels like an old friend.")
	lose_text = span_danger("Your body temperature feels normal again.")
	medical_record_text = "Patient runs cold: heat-tolerant, cold-sensitive."

/datum/quirk/modular/trait_fast_metabolism
	name = "Fast Metabolism"
	desc = "While well fed, your body slowly knits wounds closed. You also get hungry much faster."
	value = 0
	is_trait = TRUE
	physio_mult = list("hunger_mod" = 1.4)
	gain_text = span_notice("Your body feels like a furnace, burning through everything you eat.")
	lose_text = span_danger("Your metabolism slows to normal.")
	medical_record_text = "Patient has an unusually fast metabolism."

/datum/quirk/modular/trait_fast_metabolism/on_process()
	var/mob/living/carbon/human/H = quirk_holder
	if(H.nutrition > NUTRITION_LEVEL_FED && (H.getBruteLoss() || H.getFireLoss()))
		H.adjustBruteLoss(-0.3)
		H.adjustFireLoss(-0.2)

/datum/quirk/modular/trait_loner
	name = "Loner"
	desc = "You're tougher when nobody is around, but crowds wear you down fast - stamina damage hits you harder with company nearby."
	value = 0
	is_trait = TRUE
	gain_text = span_notice("You feel most yourself when you're alone.")
	lose_text = span_danger("You feel like company is fine again.")
	medical_record_text = "Patient is markedly more resilient when isolated."

/datum/quirk/modular/trait_loner/on_process()
	if(nearby_people(7))
		set_dyn(list("stamina_mod" = 0.15))
	else
		set_dyn(list("damage_resistance" = 8))

/datum/quirk/modular/trait_pack_mentality
	name = "Pack Mentality"
	desc = "You fight and endure better with allies close by, but being alone leaves you shaky and vulnerable to fatigue."
	value = 0
	is_trait = TRUE
	gain_text = span_notice("You feel safest in a group.")
	lose_text = span_danger("You feel like you can handle being alone again.")
	medical_record_text = "Patient is markedly more resilient in a group."

/datum/quirk/modular/trait_pack_mentality/on_process()
	if(nearby_people(7))
		set_dyn(list("damage_resistance" = 8))
	else
		set_dyn(list("stamina_mod" = 0.15))

/datum/quirk/modular/trait_feral
	name = "Feral Tendencies"
	desc = "Pain makes you dangerous: you take far less damage while badly injured. But near death you lose control, and may stumble around blindly."
	value = 0
	is_trait = TRUE
	gain_text = span_notice("Something wild stirs behind your eyes.")
	lose_text = span_danger("The wildness fades.")
	medical_record_text = "Patient shows a fight-or-flight response far outside the normal range."

/datum/quirk/modular/trait_feral/on_process()
	var/frac = health_fraction()
	if(frac < 0.4)
		set_dyn(list("damage_resistance" = 15))
	else
		set_dyn(null)
	if(frac < 0.25 && prob(8))
		to_chat(quirk_holder, span_userdanger("You lose yourself to the pain and lash out blindly!"))
		step(quirk_holder, pick(GLOB.alldirs))

/datum/quirk/modular/trait_gifted
	name = "Gifted"
	desc = "You're naturally talented: +1 to every S.P.E.C.I.A.L. stat. But you start with one fewer Perk Point to spend."
	value = 0
	is_trait = TRUE
	special_mods = list("s" = 1, "p" = 1, "e" = 1, "c" = 1, "i" = 1, "a" = 1, "l" = 1)
	gain_text = span_notice("You feel naturally talented at everything you try.")
	lose_text = span_danger("You feel ordinary again.")
	medical_record_text = "Patient is a statistical outlier across the board."

/datum/quirk/modular/trait_bruiser
	name = "Bruiser"
	desc = "You're built like a brick: +1 Strength (hits harder, carries more) but -1 Perception and fine motor control."
	value = 0
	is_trait = TRUE
	special_mods = list("s" = 1, "p" = -1)
	gain_text = span_notice("You feel strong, though a little thick-fingered.")
	lose_text = span_danger("You feel average again.")
	medical_record_text = "Patient is powerfully built with reduced fine motor control."

/datum/quirk/modular/trait_good_natured
	name = "Good Natured"
	desc = "You're friendly and persuasive: +2 Charisma. You're no fighter though: -1 Strength."
	value = 0
	is_trait = TRUE
	special_mods = list("c" = 2, "s" = -1)
	gain_text = span_notice("You feel like everyone is a friend you haven't met yet.")
	lose_text = span_danger("You feel more guarded again.")
	medical_record_text = "Patient is unusually amiable and unusually unprepared for violence."

/datum/quirk/modular/trait_smooth_talker
	name = "Smooth Talker"
	desc = "You can talk your way into or out of anything: +1 Charisma. But when it fails, it fails: -1 Luck."
	value = 0
	is_trait = TRUE
	special_mods = list("c" = 1, "l" = -1)
	gain_text = span_notice("The right words come easily to you.")
	lose_text = span_danger("You lose your silver tongue.")
	medical_record_text = "Patient is a practiced talker."

/datum/quirk/modular/trait_cautious
	name = "Cautious"
	desc = "You look before you leap: +2 Perception. But you move and react deliberately: -1 Agility."
	value = 0
	is_trait = TRUE
	special_mods = list("p" = 2, "a" = -1)
	gain_text = span_notice("You start noticing every little detail around you.")
	lose_text = span_danger("You feel less watchful.")
	medical_record_text = "Patient is hypervigilant."

/datum/quirk/modular/trait_vault_educated
	name = "Vault Educated"
	desc = "A proper schooling: +2 Intelligence. But you've never had to survive a day in the Wasteland: -1 Endurance."
	value = 0
	is_trait = TRUE
	special_mods = list("i" = 2, "e" = -1)
	gain_text = span_notice("Years of schooling come flooding back.")
	lose_text = span_danger("Your education feels a bit more distant.")
	medical_record_text = "Patient is well-educated and sheltered."

/datum/quirk/modular/trait_tribal_roots
	name = "Tribal Roots"
	desc = "You were raised to survive: +1 Endurance and +1 Perception. But modern machinery baffles you: -2 Intelligence."
	value = 0
	is_trait = TRUE
	special_mods = list("e" = 1, "p" = 1, "i" = -2)
	gain_text = span_notice("The old ways come back to you.")
	lose_text = span_danger("You feel less in touch with the old ways.")
	medical_record_text = "Patient has a traditional upbringing."

/datum/quirk/modular/trait_four_eyes
	name = "Four Eyes"
	desc = "You see sharply through your glasses: +1 Perception while wearing any. Without them your vision is a blur."
	value = 0
	is_trait = TRUE
	gain_text = span_danger("Things far away from you start looking blurry.")
	lose_text = span_notice("You start seeing far-away things normally again.")
	medical_record_text = "Patient requires prescription glasses; sharp-eyed when corrected."
	var/glasses_bonus = FALSE

/datum/quirk/modular/trait_four_eyes/add()
	. = ..()
	quirk_holder.become_nearsighted(ROUNDSTART_TRAIT)

/datum/quirk/modular/trait_four_eyes/on_spawn()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	var/obj/item/clothing/glasses/regular/glasses = new(get_turf(H))
	if(!H.equip_to_slot_if_possible(glasses, SLOT_GLASSES))
		H.put_in_hands(glasses)

/datum/quirk/modular/trait_four_eyes/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(!QDELETED(H))
		if(glasses_bonus)
			H.set_special_p(H.special_p - 1)
			glasses_bonus = FALSE
		H.cure_nearsighted(ROUNDSTART_TRAIT)
	return ..()

/datum/quirk/modular/trait_four_eyes/on_process()
	var/mob/living/carbon/human/H = quirk_holder
	var/wearing = !!istype(H.glasses, /obj/item/clothing/glasses)
	if(wearing && !glasses_bonus)
		glasses_bonus = TRUE
		H.set_special_p(H.special_p + 1)
	else if(!wearing && glasses_bonus)
		glasses_bonus = FALSE
		H.set_special_p(H.special_p - 1)

/* ------------------------------ Ranked Perk families ------------------------------ */

/datum/quirk/modular/toughness_rank1
	name = "Toughness I"
	desc = "You've learned to take a hit. Flat 4% damage resistance."
	value = 2
	physio_add = list("damage_resistance" = 4)
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 5
	gain_text = span_notice("You feel tougher.")
	lose_text = span_danger("You feel less tough.")

/datum/quirk/modular/toughness_rank2
	name = "Toughness II"
	desc = "Hits just bounce off you. Flat 8% damage resistance. Requires Toughness I."
	value = 4
	requires_quirk = "Toughness I"
	physio_add = list("damage_resistance" = 8)
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 7
	gain_text = span_notice("You feel much tougher.")
	lose_text = span_danger("You feel less tough.")

/datum/quirk/modular/toughness_rank3
	name = "Toughness III"
	desc = "You're a living wall. Flat 12% damage resistance. Requires Toughness II."
	value = 6
	requires_quirk = "Toughness II"
	physio_add = list("damage_resistance" = 12)
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 8
	gain_text = span_notice("You feel nearly unbreakable.")
	lose_text = span_danger("You feel less tough.")

/datum/quirk/modular/actionboy_rank1
	name = "Action Boy/Girl I"
	desc = "You tire out slower. Stamina damage reduced by 8%."
	value = 2
	physio_mult = list("stamina_mod" = 0.92)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 5
	gain_text = span_notice("You feel tireless.")
	lose_text = span_danger("You feel more easily tired.")

/datum/quirk/modular/actionboy_rank2
	name = "Action Boy/Girl II"
	desc = "You barely feel fatigue. Stamina damage reduced by 16%. Requires Action Boy/Girl I."
	value = 4
	requires_quirk = "Action Boy/Girl I"
	physio_mult = list("stamina_mod" = 0.84)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 7
	gain_text = span_notice("You feel almost tireless.")
	lose_text = span_danger("You feel more easily tired.")

/datum/quirk/modular/actionboy_rank3
	name = "Action Boy/Girl III"
	desc = "Fatigue is a rumor. Stamina damage reduced by 24%. Requires Action Boy/Girl II."
	value = 6
	requires_quirk = "Action Boy/Girl II"
	physio_mult = list("stamina_mod" = 0.76)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 8
	gain_text = span_notice("You feel unstoppable.")
	lose_text = span_danger("You feel more easily tired.")

/datum/quirk/modular/survivalist_rank1
	name = "Survivalist I"
	desc = "You make food last and weather the elements. 10% less hunger, 10% less heat and cold damage."
	value = 2
	physio_mult = list("hunger_mod" = 0.9, "heat_mod" = 0.9, "cold_mod" = 0.9)
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 5
	gain_text = span_notice("You feel well-prepared for the Wasteland.")
	lose_text = span_danger("You feel less prepared for the Wasteland.")

/datum/quirk/modular/survivalist_rank2
	name = "Survivalist II"
	desc = "20% less hunger, 20% less heat and cold damage. Requires Survivalist I."
	value = 4
	requires_quirk = "Survivalist I"
	physio_mult = list("hunger_mod" = 0.8, "heat_mod" = 0.8, "cold_mod" = 0.8)
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 7
	gain_text = span_notice("You feel very well-prepared for the Wasteland.")
	lose_text = span_danger("You feel less prepared for the Wasteland.")

/datum/quirk/modular/survivalist_rank3
	name = "Survivalist III"
	desc = "30% less hunger, 30% less heat and cold damage. Requires Survivalist II."
	value = 6
	requires_quirk = "Survivalist II"
	physio_mult = list("hunger_mod" = 0.7, "heat_mod" = 0.7, "cold_mod" = 0.7)
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 8
	gain_text = span_notice("The Wasteland holds no surprises for you.")
	lose_text = span_danger("You feel less prepared for the Wasteland.")

/datum/quirk/modular/silentrun_rank1
	name = "Silent Running I"
	desc = "You've learned to run without pounding the ground. While running, hostile mobs hear you 25% less."
	value = 2
	trait_flags = list(TRAIT_SILENT_RUN_RANK1)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 4
	gain_text = span_notice("You run on the balls of your feet.")
	lose_text = span_danger("Your running gets noisy again.")

/datum/quirk/modular/silentrun_rank2
	name = "Silent Running II"
	desc = "While running, hostile mobs hear you 45% less. Requires Silent Running I."
	value = 4
	requires_quirk = "Silent Running I"
	trait_flags = list(TRAIT_SILENT_RUN_RANK2)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 6
	gain_text = span_notice("You run almost silently.")
	lose_text = span_danger("Your running gets noisy again.")

/datum/quirk/modular/silentrun_rank3
	name = "Silent Running III"
	desc = "While running, hostile mobs hear you 60% less. Requires Silent Running II."
	value = 6
	requires_quirk = "Silent Running II"
	trait_flags = list(TRAIT_SILENT_RUN_RANK3)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 8
	gain_text = span_notice("You run like a ghost.")
	lose_text = span_danger("Your running gets noisy again.")

/datum/quirk/modular/fixit_rank1
	name = "Mr. Fixit I"
	desc = "You work with your hands. Timed actions (repairs, building, crafting) finish 10% faster."
	value = 2
	physio_mult = list("do_after_speed" = 0.9)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 5
	gain_text = span_notice("Your hands know what to do.")
	lose_text = span_danger("Your hands feel less sure.")

/datum/quirk/modular/fixit_rank2
	name = "Mr. Fixit II"
	desc = "Timed actions finish 20% faster. Requires Mr. Fixit I."
	value = 4
	requires_quirk = "Mr. Fixit I"
	physio_mult = list("do_after_speed" = 0.8)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 7
	gain_text = span_notice("You fix things on instinct.")
	lose_text = span_danger("Your hands feel less sure.")

/datum/quirk/modular/fixit_rank3
	name = "Mr. Fixit III"
	desc = "Timed actions finish 30% faster. Requires Mr. Fixit II."
	value = 6
	requires_quirk = "Mr. Fixit II"
	physio_mult = list("do_after_speed" = 0.7)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 8
	gain_text = span_notice("Nothing stays broken around you.")
	lose_text = span_danger("Your hands feel less sure.")

/datum/quirk/modular/leadbelly_rank1
	name = "Lead Belly I"
	desc = "Your stomach has seen worse. Toxin damage (including from bad food and water) reduced by 10%."
	value = 2
	physio_mult = list("tox_mod" = 0.9)
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 4
	gain_text = span_notice("Your stomach feels like lead.")
	lose_text = span_danger("Your stomach feels delicate again.")

/datum/quirk/modular/leadbelly_rank2
	name = "Lead Belly II"
	desc = "Toxin damage reduced by 20%. Requires Lead Belly I."
	value = 4
	requires_quirk = "Lead Belly I"
	physio_mult = list("tox_mod" = 0.8)
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 6
	gain_text = span_notice("You could eat rust and ask for seconds.")
	lose_text = span_danger("Your stomach feels delicate again.")

/datum/quirk/modular/leadbelly_rank3
	name = "Lead Belly III"
	desc = "Toxin damage reduced by 30%. Requires Lead Belly II."
	value = 6
	requires_quirk = "Lead Belly II"
	physio_mult = list("tox_mod" = 0.7)
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 8
	gain_text = span_notice("Your gut is made of iron.")
	lose_text = span_danger("Your stomach feels delicate again.")

/* ------------------------------ Power Armor Training II ------------------------------ */
//Rank 1 is /datum/quirk/pa_wear (good.dm). Rank 2 needs both Strength and Intelligence 6.

/datum/quirk/modular/pa_wear_rank2
	name = "Power Armor Training II"
	desc = "You've mastered your suit's power systems. Power Armor fusion cells drain 15% slower. Requires Power Armor Training."
	value = 5
	requires_quirk = "Power Armor Training"
	trait_flags = list(TRAIT_PA_WEAR, TRAIT_PA_TRAINED_RANK2)
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 6
	required_special_stat_2 = "special_i"
	required_special_name_2 = "Intelligence"
	required_special_value_2 = 6
	gain_text = span_notice("You've got the suit's power systems down cold.")
	lose_text = span_danger("You forget the finer points of Power Armor operation.")

/* ------------------------------ Flat Positives (point-buy, all SPECIAL-locked) ------------------------------ */

/datum/quirk/modular/thick_skinned
	name = "Thick Skinned"
	desc = "Minor damage resistance (3%)."
	value = 2
	physio_add = list("damage_resistance" = 3)
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 4
	gain_text = span_notice("Your skin feels a little tougher.")
	lose_text = span_danger("Your skin feels normal again.")

/datum/quirk/modular/pack_rat
	name = "Pack Rat"
	desc = "Small flat carry capacity bonus."
	value = 1
	trait_flags = list(TRAIT_STRONGBACK_RANK1)
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 4
	gain_text = span_notice("Your pack feels lighter.")
	lose_text = span_danger("Your pack feels heavier.")

/datum/quirk/modular/pack_mule
	name = "Pack Mule"
	desc = "Larger flat carry capacity bonus."
	value = 2
	trait_flags = list(TRAIT_STRONGBACK_RANK2)
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 6
	gain_text = span_notice("Your pack feels much lighter.")
	lose_text = span_danger("Your pack feels heavier.")

/datum/quirk/modular/steady_breather
	name = "Steady Breather"
	desc = "Stamina damage reduced by 10%."
	value = 1
	physio_mult = list("stamina_mod" = 0.9)
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 4
	gain_text = span_notice("Your breathing steadies.")
	lose_text = span_danger("Your breathing feels normal again.")

/datum/quirk/modular/cool_under_fire
	name = "Cool Under Fire"
	desc = "You shake off stuns and flinches 15% faster."
	value = 2
	physio_mult = list("stun_mod" = 0.85)
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 5
	gain_text = span_notice("Nothing rattles you.")
	lose_text = span_danger("You feel rattled more easily.")

/datum/quirk/modular/adrenaline_rush
	name = "Adrenaline Rush"
	desc = "Below 35% health you gain 10% damage resistance and shrug off stamina damage."
	value = 2
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 5
	gain_text = span_notice("Your heart is ready to pound.")
	lose_text = span_danger("Your heart rate feels normal.")

/datum/quirk/modular/adrenaline_rush/on_process()
	if(health_fraction() < 0.35)
		set_dyn(list("damage_resistance" = 10, "stamina_mod" = -0.2))
	else
		set_dyn(null)

/* ------------------------------ Liabilities (give Perk Points back) ------------------------------ */

/datum/quirk/modular/hemophilia
	name = "Hemophilia"
	desc = "You bleed 50% more and clot poorly."
	value = -2
	physio_mult = list("bleed_mod" = 1.5)
	gain_text = span_danger("Your blood feels thin.")
	lose_text = span_notice("Your blood feels normal.")
	medical_record_text = "Patient has impaired clotting."

/datum/quirk/modular/heat_intolerant
	name = "Heat Intolerant"
	desc = "Heat and fire hurt you 40% more."
	value = -1
	physio_mult = list("heat_mod" = 1.4)
	gain_text = span_danger("You feel the heat more than most.")
	lose_text = span_notice("Heat feels normal again.")

/datum/quirk/modular/cold_intolerant
	name = "Cold Intolerant"
	desc = "Cold hurts you 40% more."
	value = -1
	physio_mult = list("cold_mod" = 1.4)
	gain_text = span_danger("You feel the cold more than most.")
	lose_text = span_notice("Cold feels normal again.")

/datum/quirk/modular/weak_lungs
	name = "Weak Lungs"
	desc = "You take 30% more suffocation damage."
	value = -2
	physio_mult = list("oxy_mod" = 1.3)
	gain_text = span_danger("Your lungs feel tight.")
	lose_text = span_notice("Your lungs feel normal again.")

/datum/quirk/modular/glass_jaw
	name = "Glass Jaw"
	desc = "Stuns and knockdowns last 25% longer."
	value = -2
	physio_mult = list("stun_mod" = 1.25)
	gain_text = span_danger("Your head feels fragile.")
	lose_text = span_notice("Your head feels normal again.")

/datum/quirk/modular/fragile
	name = "Fragile"
	desc = "You take 15% more brute damage."
	value = -2
	physio_mult = list("brute_mod" = 1.15)
	gain_text = span_danger("You feel delicate.")
	lose_text = span_notice("You feel sturdy again.")

/datum/quirk/modular/poor_immune_system
	name = "Poor Immune System"
	desc = "You take 20% more toxin damage."
	value = -1
	physio_mult = list("tox_mod" = 1.2)
	gain_text = span_danger("You feel run down.")
	lose_text = span_notice("You feel healthy again.")

/datum/quirk/modular/bad_back
	name = "Bad Back"
	desc = "-1 Strength."
	value = -1
	special_mods = list("s" = -1)
	gain_text = span_danger("Your back aches.")
	lose_text = span_notice("Your back feels fine again.")

/datum/quirk/modular/bad_knees
	name = "Bad Knees"
	desc = "-1 Agility."
	value = -1
	special_mods = list("a" = -1)
	gain_text = span_danger("Your knees ache.")
	lose_text = span_notice("Your knees feel fine again.")

/datum/quirk/modular/tremors
	name = "Tremors"
	desc = "-1 Perception, and your hands shake now and then."
	value = -1
	special_mods = list("p" = -1)
	gain_text = span_danger("Your hands start to shake.")
	lose_text = span_notice("Your hands steady.")

/datum/quirk/modular/tremors/on_process()
	if(prob(3))
		quirk_holder.Jitter(10)

/datum/quirk/modular/chronic_pain
	name = "Chronic Pain"
	desc = "Pain flares up now and then, sapping your stamina."
	value = -2
	gain_text = span_danger("A dull ache settles in.")
	lose_text = span_notice("The ache fades.")

/datum/quirk/modular/chronic_pain/on_process()
	if(prob(3))
		var/mob/living/carbon/human/H = quirk_holder
		to_chat(H, span_warning("Pain flares through your body."))
		H.adjustStaminaLoss(15)

/datum/quirk/modular/hesitant
	name = "Hesitant"
	desc = "You take 10% longer to do anything that takes time."
	value = -1
	physio_mult = list("do_after_speed" = 1.1)
	gain_text = span_danger("You second-guess yourself.")
	lose_text = span_notice("You feel decisive again.")

/datum/quirk/modular/socially_awkward
	name = "Socially Awkward"
	desc = "-1 Charisma."
	value = -1
	special_mods = list("c" = -1)
	gain_text = span_danger("You feel awkward around people.")
	lose_text = span_notice("You feel comfortable around people again.")

/datum/quirk/modular/easily_distracted
	name = "Easily Distracted"
	desc = "-1 Perception."
	value = -1
	special_mods = list("p" = -1)
	gain_text = span_danger("Your mind wanders.")
	lose_text = span_notice("You can focus again.")

/datum/quirk/modular/lousy_shot
	name = "Lousy Shot"
	desc = "-2 Perception, which badly hurts your aim."
	value = -2
	special_mods = list("p" = -2)
	gain_text = span_danger("Your aim feels off.")
	lose_text = span_notice("Your aim feels true again.")

/datum/quirk/modular/clumsy_hands
	name = "Clumsy Hands"
	desc = "-1 Agility."
	value = -1
	special_mods = list("a" = -1)
	gain_text = span_danger("Your fingers feel like sausages.")
	lose_text = span_notice("Your fingers feel nimble again.")

/datum/quirk/modular/technophobe
	name = "Technophobe"
	desc = "-1 Intelligence; machines just don't make sense to you."
	value = -1
	special_mods = list("i" = -1)
	gain_text = span_danger("Machines make you uneasy.")
	lose_text = span_notice("Machines feel less threatening.")

/datum/quirk/modular/wasteland_naive
	name = "Wasteland Naive"
	desc = "You have no idea how the Wasteland works: -1 Endurance and -1 Luck."
	value = -2
	special_mods = list("e" = -1, "l" = -1)
	gain_text = span_danger("The Wasteland feels bigger than you thought.")
	lose_text = span_notice("You feel more at home in the Wasteland.")
