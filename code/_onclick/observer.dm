/mob/dead/observer/DblClickOn(atom/A, params)
	if(can_reenter_corpse && mind && mind.current)
		if(A == mind.current || (mind.current in A)) // double click your corpse or whatever holds it
			reenter_corpse()						// (cloning scanner, body bag, closet, mech, etc)
			return									// seems legit.

	// Things you might plausibly want to follow
	if(ismovable(A))
		ManualFollow(A)

	// Otherwise jump
	else if(A.loc)
		abstract_move(get_turf(A))
		update_parallax_contents()

/mob/dead/observer/ClickOn(atom/A, params)
	if(check_click_intercept(params,A))
		return

	var/list/modifiers = params2list(params)
	if(modifiers["shift"] && modifiers["middle"])
		ShiftMiddleClickOn(A)
		return
	if(modifiers["shift"] && modifiers["ctrl"])
		CtrlShiftClickOn(A)
		return
	if(modifiers["middle"])
		MiddleClickOn(A)
		return
	if(modifiers["shift"])
		ShiftClickOn(A)
		return
	if(modifiers["alt"])
		AltClickNoInteract(src, A)
		return
	if(modifiers["ctrl"])
		CtrlClickOn(A)
		return

	if(!CheckActionCooldown())
		return
	// You are responsible for checking config.ghost_interaction when you override this function
	// Not all of them require checking, see below
	A.attack_ghost(src)

// Oh by the way this didn't work with old click code which is why clicking shit didn't spam you
/atom/proc/attack_ghost(mob/dead/observer/user)
	if(SEND_SIGNAL(src, COMSIG_ATOM_ATTACK_GHOST, user) & COMPONENT_NO_ATTACK_HAND)
		return TRUE
	if(user.client)
		if(IsAdminGhost(user))
			attack_ai(user)
		else if(user.client.prefs.inquisitive_ghost)
			user.examinate(src)
	return FALSE

/mob/living/attack_ghost(mob/dead/observer/user)
	if(user.client && user.health_scan)
		healthscan(user, src, 1, TRUE)
	return ..()

// ---------------------------------------
// And here are some good things for free:
// Now you can click through portals, wormholes, gateways, and teleporters while observing. -Sayu

/obj/effect/gateway_portal_bumper/attack_ghost(mob/user)
	if(gateway)
		gateway.Transfer(user)
	return ..()

/obj/machinery/teleport/hub/attack_ghost(mob/user)
	if(power_station && power_station.engaged && power_station.teleporter_console && power_station.teleporter_console.target)
		user.abstract_move(get_turf(power_station.teleporter_console.target))
	return ..()

//CTRLCLICK SPAWNING
/mob/dead/observer/CtrlClickOn(mob/user)
	quickicspawn(user)

/mob/dead/observer/proc/quickicspawn(mob/user)
	if(isobserver(user) && check_rights(R_SPAWN))
		var/list/outfits = list()
		outfits["Debug Outfit"] = /datum/outfit/debug
		outfits["Naked"] = /datum/outfit
		outfits["Legate"] = /datum/outfit/job/CaesarsLegion/Legionnaire/f13legate
		outfits["Colonel"] = /datum/outfit/job/ncr/f13colonel
		outfits["Elder Envoy"] = /datum/outfit/job/bos/f13envoy
		outfits["Show All"] = "Show All"

		var/dresscode
		var/teleport_option = alert("How would you like to be spawned in?","IC Quick Spawn","Bluespace","Pod", "Cancel")
		if (teleport_option == "Cancel")
			return
		var/character_option = alert("Which character?","IC Quick Spawn","Selected Character","Randomly Created", "Cancel")
		if (character_option == "Cancel")
			return
		var/initial_outfits = input("Select outfit", "Quick Dress") as null|anything in outfits
		if (!initial_outfits || initial_outfits == "" || initial_outfits == "Cancel")
			return

		if (initial_outfits == "Show All")
			dresscode = client.robust_dress_shop()
			if (!dresscode)
				return
		else
			dresscode = outfits[initial_outfits]

		// We're spawning someone else
		var/give_return
		if (user != usr)
			give_return = alert("Do you want to give them the power to return? Not recommended for non-admins.","Give power?","Yes","No", "Cancel")
			if(give_return == "Cancel")
				return


		var/turf/current_turf = get_turf(user)
		var/mob/living/carbon/human/spawned_player = new(user)

		if (character_option == "Selected Character")
			spawned_player.name = user.name
			spawned_player.real_name = user.real_name

			var/mob/living/carbon/human/H = spawned_player
			user.client?.prefs.copy_to(H)
			H.dna.update_dna_identity()

		QDEL_IN(user, 1)

		if (teleport_option == "Bluespace")
			playsound(spawned_player, 'sound/magic/Disable_Tech.ogg', 100, 1)

		if(user.mind && isliving(spawned_player))
			user.mind.transfer_to(spawned_player, 1) // second argument to force key move to new mob
		else
			spawned_player.ckey = user.key

		if(give_return != "No")
			spawned_player.mind.AddSpell(new /obj/effect/proc_holder/spell/self/return_back, FALSE)

		if(dresscode != "Naked")
			spawned_player.equipOutfit(dresscode)

		switch(teleport_option)
			if("Bluespace")
				spawned_player.forceMove(current_turf)

				var/datum/effect_system/spark_spread/quantum/sparks = new
				sparks.set_up(10, 1, spawned_player)
				sparks.attach(get_turf(spawned_player))
				sparks.start()
			if("Pod")
				var/obj/structure/closet/supplypod/empty_pod = new()

				empty_pod.style = STYLE_BLUESPACE
				empty_pod.bluespace = TRUE
				empty_pod.explosionSize = list(0,0,0,0)
				empty_pod.desc = "A sleek, and slightly worn bluespace pod - its probably seen many deliveries..."

				spawned_player.forceMove(empty_pod)

				new /obj/effect/abstract/DPtarget(current_turf, empty_pod)
