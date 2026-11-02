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

/* ------------------------------ Loot & Economy (Batch A) ------------------------------ */

/datum/quirk/modular/fortune_finder_rank1
	name = "Fortune Finder I"
	desc = "Fortune favours you. Scavenging and trash piles have a 15% chance to reroll toward rarer loot."
	value = 2
	trait_flags = list(TRAIT_FORTUNE_FINDER_RANK1)
	required_special_stat = "special_l"
	required_special_name = "Luck"
	required_special_value = 4
	gain_text = span_notice("You've got a feeling about the next pile of junk.")
	lose_text = span_danger("Your luck with scavenging runs dry.")

/datum/quirk/modular/fortune_finder_rank2
	name = "Fortune Finder II"
	desc = "30% chance to reroll toward rarer loot. Requires Fortune Finder I."
	value = 4
	requires_quirk = "Fortune Finder I"
	trait_flags = list(TRAIT_FORTUNE_FINDER_RANK2)
	required_special_stat = "special_l"
	required_special_name = "Luck"
	required_special_value = 6
	gain_text = span_notice("Good stuff just seems to find you.")
	lose_text = span_danger("Your luck with scavenging runs dry.")

/datum/quirk/modular/fortune_finder_rank3
	name = "Fortune Finder III"
	desc = "45% chance to reroll toward rarer loot. Requires Fortune Finder II."
	value = 6
	requires_quirk = "Fortune Finder II"
	trait_flags = list(TRAIT_FORTUNE_FINDER_RANK3)
	required_special_stat = "special_l"
	required_special_name = "Luck"
	required_special_value = 8
	gain_text = span_notice("You could find treasure in a landfill fire.")
	lose_text = span_danger("Your luck with scavenging runs dry.")

/datum/quirk/modular/scrounger_rank1
	name = "Scrounger I"
	desc = "Scavenging has a 10% chance, and trash piles a 15% chance, to turn up extra ammo or parts."
	value = 2
	trait_flags = list(TRAIT_SCROUNGER_RANK1)
	required_special_stat = "special_l"
	required_special_name = "Luck"
	required_special_value = 4
	gain_text = span_notice("You never leave a pile without checking the corners.")
	lose_text = span_danger("You stop checking the corners.")

/datum/quirk/modular/scrounger_rank2
	name = "Scrounger II"
	desc = "20% scavenging chance, 30% trash pile chance for extras. Requires Scrounger I."
	value = 4
	requires_quirk = "Scrounger I"
	trait_flags = list(TRAIT_SCROUNGER_RANK2)
	required_special_stat = "special_l"
	required_special_name = "Luck"
	required_special_value = 6
	gain_text = span_notice("Nothing goes to waste around you.")
	lose_text = span_danger("You stop checking the corners.")

/datum/quirk/modular/scrounger_rank3
	name = "Scrounger III"
	desc = "30% scavenging chance, 45% trash pile chance for extras. Requires Scrounger II."
	value = 6
	requires_quirk = "Scrounger II"
	trait_flags = list(TRAIT_SCROUNGER_RANK3)
	required_special_stat = "special_l"
	required_special_name = "Luck"
	required_special_value = 7
	gain_text = span_notice("You could strip a vault of its bolts.")
	lose_text = span_danger("You stop checking the corners.")

/datum/quirk/modular/trader_rank1
	name = "Trader I"
	desc = "You haggle well. Vending machine prices are 8% lower."
	value = 2
	trait_flags = list(TRAIT_TRADER_RANK1)
	required_special_stat = "special_c"
	required_special_name = "Charisma"
	required_special_value = 5
	gain_text = span_notice("You know exactly how much to push on a price.")
	lose_text = span_danger("Your haggling instincts fade.")

/datum/quirk/modular/trader_rank2
	name = "Trader II"
	desc = "Vending machine prices are 15% lower. Requires Trader I."
	value = 4
	requires_quirk = "Trader I"
	trait_flags = list(TRAIT_TRADER_RANK2)
	required_special_stat = "special_c"
	required_special_name = "Charisma"
	required_special_value = 7
	gain_text = span_notice("Merchants dread seeing you coming.")
	lose_text = span_danger("Your haggling instincts fade.")

/datum/quirk/modular/scavengers_eye
	name = "Scavenger's Eye"
	desc = "You spot the good stuff fast. Scavenging takes 20% less time."
	value = 2
	trait_flags = list(TRAIT_SCAVENGERS_EYE)
	required_special_stat = "special_p"
	required_special_name = "Perception"
	required_special_value = 5
	gain_text = span_notice("Your eyes pick out salvage like it's glowing.")
	lose_text = span_danger("Salvage blends back into the clutter.")

/datum/quirk/modular/junk_rattler
	name = "Junk Rattler"
	desc = "35% chance of extra components when salvaging or disassembling items."
	value = 2
	trait_flags = list(TRAIT_JUNK_RATTLER)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 4
	gain_text = span_notice("You know where every spare part hides.")
	lose_text = span_danger("You forget where the spare parts hide.")

/datum/quirk/modular/ammo_smith
	name = "Ammo Smith"
	desc = "Reloading benches use 10% less material for your work."
	value = 2
	trait_flags = list(TRAIT_AMMO_SMITH)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 5
	gain_text = span_notice("You can make every grain of powder count.")
	lose_text = span_danger("You waste powder again.")

/* ------------------------------ Combat Modifiers (Batch B) ------------------------------ */

/datum/quirk/modular/sniper_rank1
	name = "Sniper I"
	desc = "Scoped or zoomed guns have 15% less spread."
	value = 3
	trait_flags = list(TRAIT_SNIPER_RANK1)
	required_special_stat = "special_p"
	required_special_name = "Perception"
	required_special_value = 6
	gain_text = span_notice("You steady your breathing and the crosshairs settle.")
	lose_text = span_danger("Your scoped shots feel less certain.")

/datum/quirk/modular/sniper_rank2
	name = "Sniper II"
	desc = "Scoped or zoomed guns have 30% less spread. Requires Sniper I."
	value = 5
	requires_quirk = "Sniper I"
	trait_flags = list(TRAIT_SNIPER_RANK2)
	required_special_stat = "special_p"
	required_special_name = "Perception"
	required_special_value = 8
	gain_text = span_notice("One shot, one kill.")
	lose_text = span_danger("Your scoped shots feel less certain.")

/datum/quirk/modular/commando_rank1
	name = "Commando I"
	desc = "Automatic and burst-fire guns have 12% less spread."
	value = 3
	trait_flags = list(TRAIT_COMMANDO_RANK1)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 5
	gain_text = span_notice("Full-auto feels like second nature.")
	lose_text = span_danger("Your hip-fire control fades.")

/datum/quirk/modular/commando_rank2
	name = "Commando II"
	desc = "Automatic and burst-fire guns have 24% less spread. Requires Commando I."
	value = 5
	requires_quirk = "Commando I"
	trait_flags = list(TRAIT_COMMANDO_RANK2)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 7
	gain_text = span_notice("You ride the recoil like a wave.")
	lose_text = span_danger("Your hip-fire control fades.")

/datum/quirk/modular/gunslinger_rank1
	name = "Gunslinger I"
	desc = "One-handed guns have 12% less spread and a 8% shorter delay between shots."
	value = 3
	trait_flags = list(TRAIT_GUNSLINGER_RANK1)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 5
	gain_text = span_notice("Your sidearm feels like part of your hand.")
	lose_text = span_danger("Your sidearm feels clumsy again.")

/datum/quirk/modular/gunslinger_rank2
	name = "Gunslinger II"
	desc = "One-handed guns have 24% less spread and a 16% shorter delay between shots. Requires Gunslinger I."
	value = 5
	requires_quirk = "Gunslinger I"
	trait_flags = list(TRAIT_GUNSLINGER_RANK2)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 7
	gain_text = span_notice("Fast on the draw, faster on the trigger.")
	lose_text = span_danger("Your sidearm feels clumsy again.")

/datum/quirk/modular/heavy_gunner_rank1
	name = "Heavy Gunner I"
	desc = "Bulky and heavy guns have 12% less spread."
	value = 3
	trait_flags = list(TRAIT_HEAVY_GUNNER_RANK1)
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 6
	gain_text = span_notice("Heavy weapons feel lighter in your hands.")
	lose_text = span_danger("Heavy weapons feel unwieldy again.")

/datum/quirk/modular/heavy_gunner_rank2
	name = "Heavy Gunner II"
	desc = "Bulky and heavy guns have 24% less spread. Requires Heavy Gunner I."
	value = 5
	requires_quirk = "Heavy Gunner I"
	trait_flags = list(TRAIT_HEAVY_GUNNER_RANK2)
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 8
	gain_text = span_notice("You could fire a minigun from the hip all day.")
	lose_text = span_danger("Heavy weapons feel unwieldy again.")

/datum/quirk/modular/blademaster_rank1
	name = "Blademaster I"
	desc = "Edged melee weapons deal 10% more damage."
	value = 2
	trait_flags = list(TRAIT_BLADEMASTER_RANK1)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 5
	gain_text = span_notice("You know where a blade bites best.")
	lose_text = span_danger("Your blade technique dulls.")

/datum/quirk/modular/blademaster_rank2
	name = "Blademaster II"
	desc = "Edged melee weapons deal 20% more damage. Requires Blademaster I."
	value = 4
	requires_quirk = "Blademaster I"
	trait_flags = list(TRAIT_BLADEMASTER_RANK2)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 7
	gain_text = span_notice("Your cuts flow without effort.")
	lose_text = span_danger("Your blade technique dulls.")

/datum/quirk/modular/blademaster_rank3
	name = "Blademaster III"
	desc = "Edged melee weapons deal 30% more damage. Requires Blademaster II."
	value = 6
	requires_quirk = "Blademaster II"
	trait_flags = list(TRAIT_BLADEMASTER_RANK3)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 8
	gain_text = span_notice("The blade is an extension of your will.")
	lose_text = span_danger("Your blade technique dulls.")

/datum/quirk/modular/brawler_rank1
	name = "Brawler I"
	desc = "Unarmed punches deal 10% more damage."
	value = 2
	trait_flags = list(TRAIT_BRAWLER_RANK1)
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 5
	gain_text = span_notice("You've learned how to put your weight behind a punch.")
	lose_text = span_danger("Your punches lose their snap.")

/datum/quirk/modular/brawler_rank2
	name = "Brawler II"
	desc = "Unarmed punches deal 20% more damage. Requires Brawler I."
	value = 4
	requires_quirk = "Brawler I"
	trait_flags = list(TRAIT_BRAWLER_RANK2)
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 7
	gain_text = span_notice("Your fists hit like hammers.")
	lose_text = span_danger("Your punches lose their snap.")

/datum/quirk/modular/brawler_rank3
	name = "Brawler III"
	desc = "Unarmed punches deal 30% more damage. Requires Brawler II."
	value = 6
	requires_quirk = "Brawler II"
	trait_flags = list(TRAIT_BRAWLER_RANK3)
	required_special_stat = "special_s"
	required_special_name = "Strength"
	required_special_value = 8
	gain_text = span_notice("You could crack a wall with a straight right.")
	lose_text = span_danger("Your punches lose their snap.")

/datum/quirk/modular/steady_aim
	name = "Steady Aim"
	desc = "Guns have 15% less spread while you're standing still."
	value = 2
	trait_flags = list(TRAIT_STEADY_AIM)
	required_special_stat = "special_p"
	required_special_name = "Perception"
	required_special_value = 5
	gain_text = span_notice("You plant your feet and the barrel stops swaying.")
	lose_text = span_danger("Your aim wavers when you stop.")

/datum/quirk/modular/quick_draw
	name = "Quick Draw"
	desc = "Guns are ready to fire 40% faster after being drawn."
	value = 2
	trait_flags = list(TRAIT_QUICK_DRAW)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 5
	gain_text = span_notice("Your hand finds your gun before you think about it.")
	lose_text = span_danger("Your draw slows down.")

/datum/quirk/modular/concentrated_fire
	name = "Concentrated Fire"
	desc = "Shots at the same target in quick succession deal up to 20% more damage (4% per consecutive shot)."
	value = 3
	trait_flags = list(TRAIT_CONCENTRATED_FIRE)
	required_special_stat = "special_p"
	required_special_name = "Perception"
	required_special_value = 6
	gain_text = span_notice("You focus on one target and the rounds find the same spot.")
	lose_text = span_danger("Your focus scatters.")

/datum/quirk/modular/follow_through
	name = "Follow Through"
	desc = "Gunshots fired within a second of moving deal 10% more damage."
	value = 2
	trait_flags = list(TRAIT_FOLLOW_THROUGH)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 6
	gain_text = span_notice("You learn to fire with your momentum instead of against it.")
	lose_text = span_danger("Your shots stop carrying your momentum.")

/* ------------------------------ Defense & Detection (Batch C) ------------------------------ */

/datum/quirk/modular/dodger_rank1
	name = "Dodger I"
	desc = "6% chance to completely avoid a melee attack."
	value = 3
	trait_flags = list(TRAIT_DODGER_RANK1)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 5
	gain_text = span_notice("You start moving before the blow lands.")
	lose_text = span_danger("Your reflexes dull.")

/datum/quirk/modular/dodger_rank2
	name = "Dodger II"
	desc = "12% chance to completely avoid a melee attack. Requires Dodger I."
	value = 5
	requires_quirk = "Dodger I"
	trait_flags = list(TRAIT_DODGER_RANK2)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 7
	gain_text = span_notice("Blows seem to slow down around you.")
	lose_text = span_danger("Your reflexes dull.")

/datum/quirk/modular/awareness_rank1
	name = "Awareness I"
	desc = "10% chance to spot a landmine in time to step around it, and sneak vision cones appear 1 tile further out."
	value = 2
	trait_flags = list(TRAIT_AWARENESS_RANK1)
	required_special_stat = "special_p"
	required_special_name = "Perception"
	required_special_value = 5
	gain_text = span_notice("You notice small details others walk past.")
	lose_text = span_danger("You stop noticing the little things.")

/datum/quirk/modular/awareness_rank2
	name = "Awareness II"
	desc = "20% chance to spot a landmine, and cones appear 2 tiles further out. Requires Awareness I."
	value = 4
	requires_quirk = "Awareness I"
	trait_flags = list(TRAIT_AWARENESS_RANK2)
	required_special_stat = "special_p"
	required_special_name = "Perception"
	required_special_value = 7
	gain_text = span_notice("Nothing escapes your attention.")
	lose_text = span_danger("You stop noticing the little things.")

/datum/quirk/modular/awareness_rank3
	name = "Awareness III"
	desc = "30% chance to spot a landmine, and cones appear 3 tiles further out. Requires Awareness II."
	value = 6
	requires_quirk = "Awareness II"
	trait_flags = list(TRAIT_AWARENESS_RANK3)
	required_special_stat = "special_p"
	required_special_name = "Perception"
	required_special_value = 8
	gain_text = span_notice("You feel the whole room at once.")
	lose_text = span_danger("You stop noticing the little things.")

/datum/quirk/modular/scout_rank1
	name = "Scout I"
	desc = "Sneak vision cones of hostile creatures appear 3 tiles further out."
	value = 2
	trait_flags = list(TRAIT_SCOUT_RANK1)
	required_special_stat = "special_p"
	required_special_name = "Perception"
	required_special_value = 5
	gain_text = span_notice("You read the land ahead of you.")
	lose_text = span_danger("Your long-range scouting skills fade.")

/datum/quirk/modular/scout_rank2
	name = "Scout II"
	desc = "Sneak vision cones appear 5 tiles further out. Requires Scout I."
	value = 4
	requires_quirk = "Scout I"
	trait_flags = list(TRAIT_SCOUT_RANK2)
	required_special_stat = "special_p"
	required_special_name = "Perception"
	required_special_value = 7
	gain_text = span_notice("You can feel trouble before you see it.")
	lose_text = span_danger("Your long-range scouting skills fade.")

/datum/quirk/modular/scout_rank3
	name = "Scout III"
	desc = "Sneak vision cones appear 7 tiles further out. Requires Scout II."
	value = 6
	requires_quirk = "Scout II"
	trait_flags = list(TRAIT_SCOUT_RANK3)
	required_special_stat = "special_p"
	required_special_name = "Perception"
	required_special_value = 8
	gain_text = span_notice("The wasteland holds no secrets from you.")
	lose_text = span_danger("Your long-range scouting skills fade.")

/datum/quirk/modular/shadow_rank1
	name = "Shadow I"
	desc = "Your movement noise is a further 15% lower while sneaking."
	value = 3
	trait_flags = list(TRAIT_SHADOW_RANK1)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 6
	gain_text = span_notice("You move like a whisper.")
	lose_text = span_danger("Your footsteps get louder.")

/datum/quirk/modular/shadow_rank2
	name = "Shadow II"
	desc = "Your movement noise is a further 30% lower while sneaking. Requires Shadow I."
	value = 5
	requires_quirk = "Shadow I"
	trait_flags = list(TRAIT_SHADOW_RANK2)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 8
	gain_text = span_notice("You are the dark between the lights.")
	lose_text = span_danger("Your footsteps get louder.")

/datum/quirk/modular/eagle_eye
	name = "Eagle Eye"
	desc = "Looking down a scope shows you one tile further ahead."
	value = 2
	trait_flags = list(TRAIT_EAGLE_EYE)
	required_special_stat = "special_p"
	required_special_name = "Perception"
	required_special_value = 6
	gain_text = span_notice("Distant things sharpen into focus.")
	lose_text = span_danger("Distant things blur again.")

/datum/quirk/modular/medic_rank1
	name = "Medic I"
	desc = "Medical items heal 10% more and apply 12% faster."
	value = 3
	trait_flags = list(TRAIT_MEDIC_RANK1)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 4
	gain_text = span_notice("You know your way around a wound.")
	lose_text = span_danger("Your medical know-how fades.")

/datum/quirk/modular/medic_rank2
	name = "Medic II"
	desc = "Medical items heal 20% more and apply 24% faster. Requires Medic I."
	value = 4
	requires_quirk = "Medic I"
	trait_flags = list(TRAIT_MEDIC_RANK2)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 6
	gain_text = span_notice("Your hands move with practiced certainty.")
	lose_text = span_danger("Your medical know-how fades.")

/datum/quirk/modular/medic_rank3
	name = "Medic III"
	desc = "Medical items heal 30% more and apply 36% faster. Requires Medic II."
	value = 5
	requires_quirk = "Medic II"
	trait_flags = list(TRAIT_MEDIC_RANK3)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 8
	gain_text = span_notice("You could patch up a corpse and make it complain.")
	lose_text = span_danger("Your medical know-how fades.")

/datum/quirk/modular/healer_rank1
	name = "Healer I"
	desc = "You perform surgery 12% faster."
	value = 3
	trait_flags = list(TRAIT_HEALER_RANK1)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 5
	gain_text = span_notice("Surgical steps come easier to you.")
	lose_text = span_danger("Your surgical fluency fades.")

/datum/quirk/modular/healer_rank2
	name = "Healer II"
	desc = "You perform surgery 24% faster. Requires Healer I."
	value = 4
	requires_quirk = "Healer I"
	trait_flags = list(TRAIT_HEALER_RANK2)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 7
	gain_text = span_notice("You operate with calm precision.")
	lose_text = span_danger("Your surgical fluency fades.")

/datum/quirk/modular/mad_scientist_rank1
	name = "Mad Scientist I"
	desc = "Crafting takes 15% less time."
	value = 3
	trait_flags = list(TRAIT_MAD_SCIENTIST_RANK1)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 6
	gain_text = span_notice("Contraptions practically assemble themselves.")
	lose_text = span_danger("Your tinkering instincts fade.")

/datum/quirk/modular/mad_scientist_rank2
	name = "Mad Scientist II"
	desc = "Crafting takes 30% less time. Requires Mad Scientist I."
	value = 4
	requires_quirk = "Mad Scientist I"
	trait_flags = list(TRAIT_MAD_SCIENTIST_RANK2)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 8
	gain_text = span_notice("Genius and madness, in the right proportions.")
	lose_text = span_danger("Your tinkering instincts fade.")

/datum/quirk/modular/robotics_expert_rank1
	name = "Robotics Expert I"
	desc = "Salvaging machinery has a 20% chance of an extra drop."
	value = 3
	trait_flags = list(TRAIT_ROBOTICS_EXPERT_RANK1)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 6
	gain_text = span_notice("You can read a circuit board like a book.")
	lose_text = span_danger("Your robotics knowledge fades.")

/datum/quirk/modular/robotics_expert_rank2
	name = "Robotics Expert II"
	desc = "Salvaging machinery has a 40% chance of an extra drop. Requires Robotics Expert I."
	value = 4
	requires_quirk = "Robotics Expert I"
	trait_flags = list(TRAIT_ROBOTICS_EXPERT_RANK2)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 8
	gain_text = span_notice("Machines surrender their secrets to you.")
	lose_text = span_danger("Your robotics knowledge fades.")

/datum/quirk/modular/field_medic
	name = "Field Medic"
	desc = "Medical items apply 15% faster and heal 10% more."
	value = 3
	trait_flags = list(TRAIT_FIELD_MEDIC)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 5
	gain_text = span_notice("You can patch a wound under fire.")
	lose_text = span_danger("Your field medicine fades.")

/datum/quirk/modular/weapon_maintenance
	name = "Weapon Maintenance"
	desc = "Jams wear your guns 40% less, and servicing a gun restores 30% more condition."
	value = 2
	trait_flags = list(TRAIT_WEAPON_MAINTENANCE)
	required_special_stat = "special_i"
	required_special_name = "Intelligence"
	required_special_value = 5
	gain_text = span_notice("You treat your weapons with care.")
	lose_text = span_danger("You get sloppy with your weapons.")

/datum/quirk/modular/steady_hands
	name = "Steady Hands"
	desc = "Your gun spread is 10% tighter."
	value = 2
	trait_flags = list(TRAIT_STEADY_HANDS)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 5
	gain_text = span_notice("Your hands stop shaking.")
	lose_text = span_danger("Your hands begin to tremble.")

/datum/quirk/modular/more_criticals_rank1
	name = "More Criticals I"
	desc = "+3% critical hit chance with guns and melee."
	value = 3
	trait_flags = list(TRAIT_MORE_CRITICALS_RANK1)
	required_special_stat = "special_l"
	required_special_name = "Luck"
	required_special_value = 5
	gain_text = span_notice("You start spotting the soft spots.")
	lose_text = span_danger("You lose your eye for weak points.")

/datum/quirk/modular/more_criticals_rank2
	name = "More Criticals II"
	desc = "+6% critical hit chance with guns and melee. Requires More Criticals I."
	value = 4
	requires_quirk = "More Criticals I"
	trait_flags = list(TRAIT_MORE_CRITICALS_RANK2)
	required_special_stat = "special_l"
	required_special_name = "Luck"
	required_special_value = 7
	gain_text = span_notice("Openings in a fight seem to find you.")
	lose_text = span_danger("You lose your eye for weak points.")

/datum/quirk/modular/more_criticals_rank3
	name = "More Criticals III"
	desc = "+9% critical hit chance with guns and melee. Requires More Criticals II."
	value = 5
	requires_quirk = "More Criticals II"
	trait_flags = list(TRAIT_MORE_CRITICALS_RANK3)
	required_special_stat = "special_l"
	required_special_name = "Luck"
	required_special_value = 9
	gain_text = span_notice("Every shot and swing looks for the kill.")
	lose_text = span_danger("You lose your eye for weak points.")

/datum/quirk/modular/better_criticals
	name = "Better Criticals"
	desc = "Your critical hits deal x2 damage instead of x1.5."
	value = 4
	trait_flags = list(TRAIT_BETTER_CRITICALS)
	required_special_stat = "special_l"
	required_special_name = "Luck"
	required_special_value = 7
	gain_text = span_notice("When you land a good hit, you make it count.")
	lose_text = span_danger("Your good hits lose their sting.")

/datum/quirk/modular/water_wise
	name = "Water Wise"
	desc = "You get thirsty 25% more slowly."
	value = 2
	trait_flags = list(TRAIT_WATER_WISE)
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 5
	gain_text = span_notice("You've learned to make every sip count.")
	lose_text = span_danger("You start to feel thirsty more often.")

/datum/quirk/modular/camper
	name = "Camper"
	desc = "Wood adds 50% more fuel to campfires, and you cook over them faster."
	value = 2
	trait_flags = list(TRAIT_CAMPER)
	required_special_stat = "special_e"
	required_special_name = "Endurance"
	required_special_value = 5
	gain_text = span_notice("A good fire is second nature to you.")
	lose_text = span_danger("Your campcraft fades.")

/datum/quirk/modular/quick_clean
	name = "Quick Clean"
	desc = "Soap cleans 40% faster."
	value = 1
	trait_flags = list(TRAIT_QUICK_CLEAN)
	required_special_stat = "special_a"
	required_special_name = "Agility"
	required_special_value = 5
	gain_text = span_notice("You scrub with practiced efficiency.")
	lose_text = span_danger("Your scrubbing slows down.")

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
