/mob/living/silicon/robot/examine(mob/user)
	. = list("<span class='info'>*---------*\nThis is [icon2html(src, user)] \a <EM>[src]</EM>, a [src.module.name] unit!")
	if(desc)
		. += "[desc]"

	var/obj/act_module = get_active_held_item()
	if(act_module)
		. += "It is holding [icon2html(act_module, user)] \a [act_module]."
	var/effects_exam = status_effect_examines()
	if(!isnull(effects_exam))
		. += effects_exam
	if (getBruteLoss())
		if (getBruteLoss() < maxHealth*0.5)
			. += span_warning("It looks slightly dented.")
		else
			. += "<span class='warning'><B>It looks severely dented!</B></span>"
	if (getFireLoss() || getToxLoss())
		var/overall_fireloss = getFireLoss() + getToxLoss()
		if (overall_fireloss < maxHealth * 0.5)
			. += span_warning("It looks slightly charred.")
		else
			. += span_warning("It looks slightly charred.")
	if (health < -maxHealth*0.5)
		. += span_warning("It looks barely operational.")
	if (fire_stacks < 0)
		. += span_warning("It's covered in water.")
	else if (fire_stacks > 0)
		. += span_warning("It's coated in something flammable.")

	if(opened)
		. += span_warning("Its cover is open and the power cell is [cell ? "installed" : "missing"].")
	else
		. += "Its cover is closed[locked ? "" : ", and looks unlocked"]."

	if(cell && cell.charge <= 0)
		. += span_warning("Its battery indicator is blinking red!")

	switch(stat)
		if(CONSCIOUS)
			if(shell)
				. += "It appears to be an [deployed ? "active" : "empty"] AI shell."
			else if(!client)
				. += "It appears to be in stand-by mode."
		if(UNCONSCIOUS)
			. += span_warning("It doesn't seem to be responding.")
		if(DEAD)
			. += span_deadsay("It looks like its system is corrupted and requires a reset.")

	// ---- CPU CERT INFO ----
	if(cpu_cert)
		. += "<span class='info'>*---------*"
		. += "CPU: <b>[cpu_cert.cert_name]</b> (Tier [cpu_cert.cert_tier])"

		// C.O.R.E. stats in the same style as SPECIAL
		var/compute    = cpu_cert.get_core_stat(CORE_COMPUTE)
		var/operations = cpu_cert.get_core_stat(CORE_OPERATIONS)
		var/resilience = cpu_cert.get_core_stat(CORE_RESILIENCE)
		var/energy     = cpu_cert.get_core_stat(CORE_ENERGY)

		. += "C.O.R.E: \
			C:<b>[compute]</b>  \
			O:<b>[operations]</b>  \
			R:<b>[resilience]</b>  \
			E:<b>[energy]</b>"

		// Installed upgrades
		if(cpu_cert.upgrade_slots.len)
			var/list/upgrade_names = list()
			for(var/datum/cert_upgrade/U in cpu_cert.upgrade_slots)
				upgrade_names += U.upgrade_name
			. += "Upgrades: [english_list(upgrade_names)]"
		else
			. += "Upgrades: None installed"

		// Remaining slots
		var/slots_used = cpu_cert.upgrade_slots.len
		var/slots_max  = cpu_cert.max_upgrade_slots
		. += "Slots: [slots_used]/[slots_max]"
		. += "</span>"

	. += "*---------*</span>"

	. += ..()


// ====================================================
// STRIP VERB - player with open panel pulls an upgrade
// back out to a cert card
// ====================================================

/mob/living/silicon/robot/verb/strip_cert_upgrade()
	set name = "Strip Cert Upgrade"
	set category = "Object"
	set src in oview(1)

	var/mob/living/user = usr
	if(!isliving(user))
		return

	if(!opened)
		to_chat(user, span_warning("You need to open [src]'s panel first."))
		return

	if(!cpu_cert)
		to_chat(user, span_warning("[src] has no certification installed."))
		return

	if(cpu_cert.capability_flags & CERT_LOCKED)
		to_chat(user, span_warning("[src]'s certification is locked and cannot be modified."))
		return

	if(!cpu_cert.upgrade_slots.len)
		to_chat(user, span_warning("[src] has no upgrades installed."))
		return

	// Build selection list
	var/list/upgrade_map = list()
	for(var/datum/cert_upgrade/U in cpu_cert.upgrade_slots)
		upgrade_map[U.upgrade_name] = U

	var/choice = input(user, "Select an upgrade to remove from [src].", "Strip Upgrade") as null|anything in upgrade_map
	if(!choice)
		return

	// Re-validate after async input
	if(!opened)
		to_chat(user, span_warning("The panel was closed."))
		return
	if(cpu_cert.capability_flags & CERT_LOCKED)
		return

	var/datum/cert_upgrade/U = upgrade_map[choice]
	if(!(U in cpu_cert.upgrade_slots))
		to_chat(user, span_warning("That upgrade is no longer installed."))
		return

	cpu_cert.remove_upgrade(U, src)

	var/obj/item/cert_card/card = new(get_turf(src))
	card.upgrade = U
	card._update_name()

	to_chat(user, span_notice("You remove [U.upgrade_name] from [src] and store it on a cert card."))
	log_game("[key_name(user)] stripped upgrade '[U.upgrade_name]' from [src] at [AREACOORD(src)]")
