// Enclave Soldier Elite System
// Progression system for Enclave soldiers

// ============ SOLDIER PROGRESSION MANAGER ============

/datum/enclave_soldier_progression_manager
	var/list/records = list()

/datum/enclave_soldier_progression_manager/proc/get_record(ckey)
	for(var/datum/enclave_soldier_record/R in records)
		if(R.ckey == ckey)
			return R
	return null

/datum/enclave_soldier_progression_manager/proc/create_record(mob/living/carbon/human/user)
	if(get_record(user.ckey))
		return FALSE

	var/datum/enclave_soldier_record/record = new()
	record.ckey = user.ckey
	record.name = user.real_name
	record.soldier_tier = ENCLAVE_RANK_RECRUIT

	records += record
	GLOB.enclave_soldier_records[user.ckey] = record

	return TRUE

/datum/enclave_soldier_progression_manager/proc/promote_soldier(ckey)
	var/datum/enclave_soldier_record/record = get_record(ckey)
	if(!record)
		return FALSE

	if(record.soldier_tier >= ENCLAVE_RANK_COLONEL)
		return FALSE

	record.soldier_tier++

	var/mob/living/carbon/human/H = get_mob_by_ckey(ckey)
	if(H)
		to_chat(H, span_notice("You have been promoted to [get_rank_name(record.soldier_tier)]!"))
		grant_tier_abilities(H, record.soldier_tier)

	return TRUE

/datum/enclave_soldier_progression_manager/proc/demote_soldier(ckey)
	var/datum/enclave_soldier_record/record = get_record(ckey)
	if(!record)
		return FALSE

	if(record.soldier_tier <= ENCLAVE_RANK_RECRUIT)
		return FALSE

	record.soldier_tier--

	var/mob/living/carbon/human/H = get_mob_by_ckey(ckey)
	if(H)
		to_chat(H, span_warning("You have been demoted to [get_rank_name(record.soldier_tier)]."))

	return TRUE

/datum/enclave_soldier_progression_manager/proc/get_rank_name(tier)
	switch(tier)
		if(ENCLAVE_RANK_RECRUIT)
			return "Recruit"
		if(ENCLAVE_RANK_PRIVATE)
			return "Private"
		if(ENCLAVE_RANK_CORPORAL)
			return "Corporal"
		if(ENCLAVE_RANK_SERGEANT)
			return "Sergeant"
		if(ENCLAVE_RANK_LIEUTENANT)
			return "Lieutenant"
		if(ENCLAVE_RANK_COLONEL)
			return "Colonel"
		else
			return "Unknown"

/datum/enclave_soldier_progression_manager/proc/get_mob_by_ckey(ckey)
	for(var/mob/M in GLOB.player_list)
		if(M.ckey == ckey)
			return M
	return null

/datum/enclave_soldier_progression_manager/proc/grant_tier_abilities(mob/living/carbon/human/H, tier)
	switch(tier)
		if(ENCLAVE_RANK_PRIVATE)
			H.mind?.teach_spell(/datum/action/covert_stealth_basic)
		if(ENCLAVE_RANK_CORPORAL)
			H.mind?.teach_spell(/datum/action/enclave_combat_stance)
		if(ENCLAVE_RANK_SERGEANT)
			H.mind?.teach_spell(/datum/action/enclave_tactical_command)
		if(ENCLAVE_RANK_LIEUTENANT)
			H.mind?.teach_spell(/datum/action/enclave_stealth_field)
		if(ENCLAVE_RANK_COLONEL)
			H.mind?.teach_spell(/datum/action/enclave_vertibird_call)

/datum/enclave_soldier_progression_manager/proc/check_promotion_eligibility(ckey)
	var/datum/enclave_soldier_record/record = get_record(ckey)
	if(!record)
		return FALSE

	var/rep = get_faction_reputation(ckey, "enclave")

	var/required_rep = 0
	switch(record.soldier_tier + 1)
		if(ENCLAVE_RANK_PRIVATE)
			required_rep = 100
		if(ENCLAVE_RANK_CORPORAL)
			required_rep = 200
		if(ENCLAVE_RANK_SERGEANT)
			required_rep = 400
		if(ENCLAVE_RANK_LIEUTENANT)
			required_rep = 700
		if(ENCLAVE_RANK_COLONEL)
			required_rep = 1000

	return rep >= required_rep

// ============ SOLDIER RECORD DATUM ============

/datum/enclave_soldier_record
	var/ckey
	var/name
	var/soldier_tier = ENCLAVE_RANK_RECRUIT
	var/missions_completed = 0
	var/kills = 0
	var/advanced_pa_certified = FALSE
	var/combat_victories = 0
	var/codex_violations = 0
	var/training_complete = FALSE

// ============ SOLDIER ABILITIES ============

/datum/action/covert_stealth_basic
	name = "Basic Stealth"
	desc = "Activate stealth mode for a short duration."
	button_icon_state = "stealth"
	var/active = FALSE
	var/duration = 30 SECONDS
	var/cooldown = 5 MINUTES
	var/last_used = 0

/datum/action/covert_stealth_basic/Trigger()
	if(world.time - last_used < cooldown)
		to_chat(owner, span_warning("Ability on cooldown."))
		return FALSE

	active = TRUE
	last_used = world.time
	owner.alpha = 128
	owner.invisibility = INVISIBILITY_OBSERVER

	to_chat(owner, span_notice("Stealth activated."))

	addtimer(CALLBACK(src, .proc/deactivate), duration)
	return TRUE

/datum/action/covert_stealth_basic/proc/deactivate()
	active = FALSE
	owner.alpha = 255
	owner.invisibility = 0
	to_chat(owner, span_warning("Stealth deactivated."))

/datum/action/enclave_combat_stance
	name = "Combat Stance"
	desc = "Enter an enhanced combat stance for increased effectiveness."
	button_icon_state = "combat"
	var/active = FALSE
	var/damage_bonus = 0.15
	var/accuracy_bonus = 15

/datum/action/enclave_combat_stance/Trigger()
	active = !active

	if(active)
		owner.add_client_colour(/datum/client_colour/enclave_combat)
		to_chat(owner, span_notice("Combat stance engaged."))
	else
		owner.remove_client_colour(/datum/client_colour/enclave_combat)
		to_chat(owner, span_notice("Combat stance disengaged."))

	return TRUE

/datum/client_colour/enclave_combat
	colour = list(1.2,0,0,0, 0,1.1,0,0, 0,0,1,0, 0,0,0,1, 0,0,0,0)
	priority = 10

/datum/action/enclave_tactical_command
	name = "Tactical Command"
	desc = "Buff nearby Enclave members."
	button_icon_state = "command"
	var/range = 7
	var/buff_duration = 2 MINUTES
	var/cooldown = 10 MINUTES
	var/last_used = 0

/datum/action/enclave_tactical_command/Trigger()
	if(world.time - last_used < cooldown)
		to_chat(owner, span_warning("Ability on cooldown."))
		return FALSE

	last_used = world.time

	var/buffed = 0
	for(var/mob/living/carbon/human/H in view(range, owner))
		if(H.faction == "enclave" && H != owner)
			H.add_client_colour(/datum/client_colour/tactical_buff)
			buffed++
			to_chat(H, span_notice("You feel inspired by tactical command!"))

			addtimer(CALLBACK(src, .proc/remove_buff, H), buff_duration)

	to_chat(owner, span_notice("Tactical command inspired [buffed] nearby soldiers."))
	return TRUE

/datum/action/enclave_tactical_command/proc/remove_buff(mob/living/carbon/human/H)
	if(H)
		H.remove_client_colour(/datum/client_colour/tactical_buff)

/datum/client_colour/tactical_buff
	colour = list(1,0.1,0,0, 0.1,1,0,0, 0,0.1,1,0, 0,0,0,1, 0,0,0,0)
	priority = 5

/datum/action/enclave_stealth_field
	name = "Stealth Field"
	desc = "Activate APA stealth field."
	button_icon_state = "stealth_field"
	var/active = FALSE
	var/duration = 30 SECONDS
	var/cooldown = 5 MINUTES
	var/last_used = 0

/datum/action/enclave_stealth_field/Trigger()
	if(active)
		return FALSE

	if(world.time - last_used < cooldown)
		to_chat(owner, span_warning("Stealth field recharging."))
		return FALSE

	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE

	var/obj/item/clothing/suit/space/hardsuit/power_armor/apa = H.wear_suit
	if(!istype(apa))
		to_chat(owner, span_warning("Requires Advanced Power Armor."))
		return FALSE

	active = TRUE
	last_used = world.time
	H.alpha = 50
	H.invisibility = INVISIBILITY_LEVEL_TWO

	to_chat(owner, span_notice("Stealth field activated."))

	addtimer(CALLBACK(src, .proc/deactivate), duration)
	return TRUE

/datum/action/enclave_stealth_field/proc/deactivate()
	active = FALSE
	owner.alpha = 255
	owner.invisibility = 0
	to_chat(owner, span_warning("Stealth field depleted."))

/datum/action/enclave_vertibird_call
	name = "Call Vertibird"
	desc = "Call in a vertibird extraction."
	button_icon_state = "vertibird"
	var/cooldown = 30 MINUTES
	var/last_used = 0

/datum/action/enclave_vertibird_call/Trigger()
	if(world.time - last_used < cooldown)
		to_chat(owner, span_warning("Vertibird on standby."))
		return FALSE

	last_used = world.time

	var/turf/T = get_turf(owner)
	var/obj/structure/vertibird_pad/pad = locate() in range(10, T)

	if(pad)
		GLOB.enclave_vertibird.dispatch_to(pad)
		to_chat(owner, span_notice("Vertibird dispatched to your location."))
	else
		to_chat(owner, span_warning("No suitable landing zone nearby."))

	return TRUE

// ============ SOLDIER TERMINAL ============

/obj/machinery/computer/enclave_soldier_terminal
	name = "Enclave Personnel Terminal"
	desc = "A terminal for soldier progression and training."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/enclave_soldier_terminal/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/enclave_soldier_terminal/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "EnclaveTerminal")
		ui.open()

/obj/machinery/computer/enclave_soldier_terminal/ui_data(mob/user)
	var/list/data = list()

	var/datum/enclave_soldier_record/record = GLOB.enclave_soldier_progression.get_record(user.ckey)
	if(record)
		data["has_record"] = TRUE
		data["tier"] = record.soldier_tier
		data["rank_name"] = GLOB.enclave_soldier_progression.get_rank_name(record.soldier_tier)
		data["missions"] = record.missions_completed
		data["kills"] = record.kills
		data["apa_certified"] = record.advanced_pa_certified
		data["eligible"] = GLOB.enclave_soldier_progression.check_promotion_eligibility(user.ckey)
	else
		data["has_record"] = FALSE

	var/list/tiers = list()
	for(var/i in 0 to 5)
		tiers += list(list("tier" = i, "name" = GLOB.enclave_soldier_progression.get_rank_name(i)))
	data["tiers"] = tiers

	var/list/roster_data = list()
	for(var/ckey in GLOB.enclave_soldier_records)
		var/datum/enclave_soldier_record/R = GLOB.enclave_soldier_records[ckey]
		roster_data += list(list("ckey" = R.ckey, "name" = R.name, "tier" = R.soldier_tier, "rank" = GLOB.enclave_soldier_progression.get_rank_name(R.soldier_tier)))
	data["roster"] = roster_data

	return data

/obj/machinery/computer/enclave_soldier_terminal/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("create_record")
			if(GLOB.enclave_soldier_progression.create_record(usr))
				to_chat(usr, span_notice("Soldier record created."))
			return TRUE

		if("request_promotion")
			if(GLOB.enclave_soldier_progression.promote_soldier(usr.ckey))
				to_chat(usr, span_notice("Promotion approved!"))
			else
				to_chat(usr, span_warning("Not eligible for promotion."))
			return TRUE

		if("apa_certification")
			var/datum/enclave_soldier_record/record = GLOB.enclave_soldier_progression.get_record(usr.ckey)
			if(record && record.soldier_tier >= ENCLAVE_RANK_LIEUTENANT)
				record.advanced_pa_certified = TRUE
				to_chat(usr, span_notice("APA certification granted."))
			else
				to_chat(usr, span_warning("Not eligible for APA certification."))
			return TRUE

		if("promote_soldier")
			var/target_ckey = params["target_ckey"]
			if(GLOB.enclave_soldier_progression.promote_soldier(target_ckey))
				to_chat(usr, span_notice("Soldier promoted."))
			return TRUE

		if("demote_soldier")
			var/target_ckey = params["target_ckey"]
			if(GLOB.enclave_soldier_progression.demote_soldier(target_ckey))
				to_chat(usr, span_notice("Soldier demoted."))
			return TRUE

	return FALSE
