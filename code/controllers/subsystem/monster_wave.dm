SUBSYSTEM_DEF(monster_wave)
	name = "Monster Wave"
	wait = 5 MINUTES //change to either 30 MINUTES or 1 HOURS
	var/successful_firing = 0
	var/allowed_firings = 90
	var/chance_of_fire = 95 //Fuck you, people need mobs to shoot! -TK

	/// Faction ambush waves (NCR rangers, Brotherhood squads and so on). Toggle with VV to turn them all off.
	var/faction_ambush_enabled = TRUE
	/// Chance that a successful monster wave roll becomes a faction ambush instead of an animal nest
	var/faction_ambush_wave_chance = 30
	/// How often players are checked for standing in an ambush zone, and the chance each check starts an ambush
	var/faction_ambush_scan_delay = 1 MINUTES
	var/faction_ambush_scan_chance = 4
	/// No ambushes before this much round time has passed
	var/faction_ambush_earliest = 20 MINUTES
	/// Minimum time between any two faction ambushes
	var/faction_ambush_global_cooldown = 15 MINUTES
	COOLDOWN_DECLARE(faction_ambush_cooldown)
	var/list/datum/ambush_wave/ambush_waves = list()

//So admins, you want to be a tough guy, like it really rough guy?
//just know you can't modify the time in between each fire
//but you can allow it to always fire, by changing chance_of_fire to 0
//and changing allowed_firings to like.... 12?
//     ^This guy was a coward. ~TK

/datum/controller/subsystem/monster_wave/Initialize(start_timeofday)
	for(var/wave_type in subtypesof(/datum/ambush_wave))
		var/datum/ambush_wave/wave_path = wave_type
		if(!initial(wave_path.name))
			continue
		ambush_waves += new wave_type
	addtimer(CALLBACK(src, PROC_REF(ambush_scan)), faction_ambush_scan_delay)
	return ..()

/datum/controller/subsystem/monster_wave/fire(resumed = 0)
	if(times_fired <= 0)
		message_admins("The Monster Wave has fired the first time. Next fire (in an hour) will spawn a monster pit.")
		log_game("The Monster Wave has fired the first time. Next fire (in an hour) will spawn a monster pit.")
		return
	if(successful_firing >= allowed_firings)
		message_admins("The Monster Wave has been disabled, maximum amount of waves spawned.")
		log_game("The Monster Wave has been disabled, maximum amount of waves spawned.")
		can_fire = FALSE
		return
	if(prob(chance_of_fire))
		return // 50/50 chance for it to either fire or not fire
	successful_firing++
	if(prob(faction_ambush_wave_chance) && try_faction_ambush("timer"))
		return
	addtimer(CALLBACK(src, PROC_REF(spawn_monsterwave)), 10 SECONDS)
	for(var/M in GLOB.player_list)
		to_chat(M, "<span class='notice'>You feel the ground tremor subtly beneath your feet. Something far off in the distance has emerged to the surface.</font></span>")

/datum/controller/subsystem/monster_wave/proc/spawn_monsterwave()
	var/pick_unfortune = pick("Ghoul", /*"Deathclaw",*/ "Radscorpion", "Fireant", "Molerat", "Mirelurk", "Gecko", "Cazador", "Wolf")
	switch(pick_unfortune)
		if("Ghoul")
			ghoul_wave()
//		if("Deathclaw")
//			deathclaw_wave()
		if("Radscorpion")
			radscorpion_wave()
		if("Fireant")
			fireant_wave()
		if("Molerat")
			molerat_wave()
		if("Mirelurk")
			mirelurk_wave()
		if("Gecko")
			gecko_wave()
		if("Cazador")
			cazador_wave()
		if("Wolf")
			wolf_wave()

/datum/controller/subsystem/monster_wave/proc/ghoul_wave()
	var/spawn_amount = CEILING(GLOB.player_list.len / 8, 1)
	var/turf/choose_turf = quick_safe_turf()
	var/turf/pixel_turf = get_turf_pixel(choose_turf)
	for(var/i in 1 to spawn_amount)
		new /mob/living/simple_animal/hostile/ghoul(choose_turf)
		if(prob(10))
			new /mob/living/simple_animal/hostile/ghoul/glowing(choose_turf)
	new /obj/structure/nest/ghoul(choose_turf)
	message_admins("The Monster Wave for ghouls has fired. A nest has been spawned at [ADMIN_VERBOSEJMP(pixel_turf)]")
	log_game("The Monster Wave has fired. A nest has been spawned at [AREACOORD(pixel_turf)]")

/*
/datum/controller/subsystem/monster_wave/proc/deathclaw_wave()
	var/spawn_amount = CEILING(GLOB.player_list.len / 20, 1)
	var/turf/choose_turf = quick_safe_turf()
	var/turf/pixel_turf = get_turf_pixel(choose_turf)
	for(var/i in 1 to spawn_amount)
		new /mob/living/simple_animal/hostile/deathclaw(choose_turf)
		if(prob(2))
			new /mob/living/simple_animal/hostile/deathclaw/mother(choose_turf)
	new /obj/structure/nest/deathclaw(choose_turf)
	message_admins("The Monster Wave for Deathclaws has fired. A nest has been spawned at [ADMIN_VERBOSEJMP(pixel_turf)]")
	log_game("The Monster Wave has fired. A nest has been spawned at [AREACOORD(pixel_turf)]")
*/

/datum/controller/subsystem/monster_wave/proc/radscorpion_wave()
	var/spawn_amount = CEILING(GLOB.player_list.len / 15, 1)
	var/turf/choose_turf = quick_safe_turf()
	var/turf/pixel_turf = get_turf_pixel(choose_turf)
	for(var/i in 1 to spawn_amount)
		if(prob(50))
			new /mob/living/simple_animal/hostile/radscorpion/black(choose_turf)
		else
			new /mob/living/simple_animal/hostile/radscorpion(choose_turf)
	new /obj/structure/nest/scorpion(choose_turf)
	message_admins("The Monster Wave for Radscorpions has fired. A nest has been spawned at [ADMIN_VERBOSEJMP(pixel_turf)]")
	log_game("The Monster Wave has fired. A nest has been spawned at [AREACOORD(pixel_turf)]")

/datum/controller/subsystem/monster_wave/proc/fireant_wave()
	var/spawn_amount = CEILING(GLOB.player_list.len / 10, 1)
	var/turf/choose_turf = quick_safe_turf()
	var/turf/pixel_turf = get_turf_pixel(choose_turf)
	for(var/i in 1 to spawn_amount)
		new /mob/living/simple_animal/hostile/giantant(choose_turf)
		if(prob(1))
			new /mob/living/simple_animal/hostile/giantantqueen(choose_turf)
	new /obj/structure/nest/fireant(choose_turf)
	message_admins("The Monster Wave for Fireants has fired. A nest has been spawned at [ADMIN_VERBOSEJMP(pixel_turf)]")
	log_game("The Monster Wave has fired. A nest has been spawned at [AREACOORD(pixel_turf)]")


/datum/controller/subsystem/monster_wave/proc/molerat_wave()
	var/spawn_amount = CEILING(GLOB.player_list.len / 5, 1)
	var/turf/choose_turf = quick_safe_turf()
	var/turf/pixel_turf = get_turf_pixel(choose_turf)
	for(var/i in 1 to spawn_amount)
		new /mob/living/simple_animal/hostile/molerat(choose_turf)
	new /obj/structure/nest/molerat(choose_turf)
	message_admins("The Monster Wave for Molerats has fired. A nest has been spawned at [ADMIN_VERBOSEJMP(pixel_turf)]")
	log_game("The Monster Wave has fired. A nest has been spawned at [AREACOORD(pixel_turf)]")

/datum/controller/subsystem/monster_wave/proc/mirelurk_wave()
	var/spawn_amount = CEILING(GLOB.player_list.len / 10, 1)
	var/turf/choose_turf = quick_safe_turf()
	var/turf/pixel_turf = get_turf_pixel(choose_turf)
	for(var/i in 1 to spawn_amount)
		new /mob/living/simple_animal/hostile/mirelurk/baby(choose_turf)
		if(prob(20))
			new /mob/living/simple_animal/hostile/mirelurk(choose_turf)
		if(prob(8))
			new /mob/living/simple_animal/hostile/mirelurk/hunter(choose_turf)
	new /obj/structure/nest/mirelurk(choose_turf)
	message_admins("The Monster Wave for Mirelurks has fired. A nest has been spawned at [ADMIN_VERBOSEJMP(pixel_turf)]")
	log_game("The Monster Wave has fired. A nest has been spawned at [AREACOORD(pixel_turf)]")

/datum/controller/subsystem/monster_wave/proc/gecko_wave()
	var/spawn_amount = CEILING(GLOB.player_list.len / 5, 1)
	var/turf/choose_turf = quick_safe_turf()
	var/turf/pixel_turf = get_turf_pixel(choose_turf)
	for(var/i in 1 to spawn_amount)
		new /mob/living/simple_animal/hostile/gecko(choose_turf)
	new /obj/structure/nest/gecko(choose_turf)
	message_admins("The Monster Wave for Geckos has fired. A nest has been spawned at [ADMIN_VERBOSEJMP(pixel_turf)]")
	log_game("The Monster Wave has fired. A nest has been spawned at [AREACOORD(pixel_turf)]")


/datum/controller/subsystem/monster_wave/proc/cazador_wave()
	var/spawn_amount = CEILING(GLOB.player_list.len / 5, 1)
	var/turf/choose_turf = quick_safe_turf()
	var/turf/pixel_turf = get_turf_pixel(choose_turf)
	for(var/i in 1 to spawn_amount)
		new /mob/living/simple_animal/hostile/cazador(choose_turf)
	new /obj/structure/nest/cazador(choose_turf)
	message_admins("The Monster Wave for Cazador has fired. A nest has been spawned at [ADMIN_VERBOSEJMP(pixel_turf)]")
	log_game("The Monster Wave has fired. A nest has been spawned at [AREACOORD(pixel_turf)]")

/datum/controller/subsystem/monster_wave/proc/wolf_wave()
	var/spawn_amount = CEILING(GLOB.player_list.len / 5, 1)
	var/turf/choose_turf = quick_safe_turf()
	var/turf/pixel_turf = get_turf_pixel(choose_turf)
	for(var/i in 1 to spawn_amount)
		new /mob/living/simple_animal/hostile/wolf/alpha(choose_turf)
	new /obj/structure/nest/wolf(choose_turf)
	message_admins("The Monster Wave for Dogs has fired. A nest has been spawned at [ADMIN_VERBOSEJMP(pixel_turf)]")
	log_game("The Monster Wave has fired. A nest has been spawned at [AREACOORD(pixel_turf)]")

/// Checks whether anyone is standing in an ambush zone; a hit starts an ambush if the global cooldown allows it.
/datum/controller/subsystem/monster_wave/proc/ambush_scan()
	addtimer(CALLBACK(src, PROC_REF(ambush_scan)), faction_ambush_scan_delay)
	if(!can_fire || !faction_ambush_enabled || !COOLDOWN_FINISHED(src, faction_ambush_cooldown))
		return
	if(!prob(faction_ambush_scan_chance))
		return
	try_faction_ambush("zone scan")

/// Picks a wave that has a valid player in its zone and spawns it near that player. Returns TRUE if one was spawned.
/datum/controller/subsystem/monster_wave/proc/try_faction_ambush(source)
	if(!faction_ambush_enabled || !COOLDOWN_FINISHED(src, faction_ambush_cooldown))
		return FALSE
	if(SSticker.current_state != GAME_STATE_PLAYING || world.time - SSticker.round_start_time < faction_ambush_earliest)
		return FALSE
	var/active_players = get_active_player_count(alive_check = TRUE, afk_check = TRUE, human_check = TRUE)
	var/list/options = list()
	var/list/targets_by_wave = list()
	for(var/datum/ambush_wave/wave as anything in ambush_waves)
		if(!COOLDOWN_FINISHED(wave, wave_cooldown) || active_players < wave.min_players)
			continue
		var/list/candidates = wave.get_candidates()
		if(!length(candidates))
			continue
		options[wave] = wave.weight
		targets_by_wave[wave] = candidates
	while(length(options))
		var/datum/ambush_wave/chosen = pickweight(options)
		var/mob/living/carbon/human/target = pick(targets_by_wave[chosen])
		if(chosen.spawn_wave(target, active_players, source))
			COOLDOWN_START(src, faction_ambush_cooldown, faction_ambush_global_cooldown)
			COOLDOWN_START(chosen, wave_cooldown, chosen.cooldown_time)
			return TRUE
		// No place to put it around that player, so try another wave
		options -= chosen
	return FALSE

/// One kind of faction ambush. Subtypes with a name are picked up automatically by the subsystem.
/datum/ambush_wave
	/// Admin-facing name. Leave unset on abstract types.
	var/name
	var/weight = 10
	/// Players carrying any of these are never picked as the target. Player faction strings differ from the
	/// mob ones in places (Enclave/enclave, Raiders/raider), so list both.
	var/list/friendly_factions = list()
	/// Area types a player must stand in to be picked as the target (subtypes count)
	var/list/target_areas = list()
	/// Area types that never count, even when they are a subtype of the above
	var/list/exclude_areas = list()
	/// Area types the ambushers may spawn in. Defaults to target_areas.
	var/list/spawn_areas
	var/outdoors_only = FALSE
	/// Mob typepath = weight
	var/list/mob_types = list()
	var/base_count = 3
	/// One extra ambusher per this many active players
	var/player_scale = 10
	var/max_count = 6
	var/min_players = 3
	var/cooldown_time = 30 MINUTES
	/// Vague warning for the target and anyone near them. Deliberately does not name the faction.
	var/flavor_message
	COOLDOWN_DECLARE(wave_cooldown)

/datum/ambush_wave/proc/area_matches(area/A, list/types)
	if(!A)
		return FALSE
	for(var/area_type in types)
		if(istype(A, area_type))
			return TRUE
	return FALSE

/datum/ambush_wave/proc/get_candidates()
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(!H.client || H.stat != CONSCIOUS || !is_station_level(H.z))
			continue
		if(length(friendly_factions & H.faction))
			continue
		var/area/A = get_area(H)
		if(!area_matches(A, target_areas) || area_matches(A, exclude_areas))
			continue
		candidates += H
	return candidates

/// A tile 12 to 18 tiles from the target, out of sight of every player, that fits this wave's spawn area rules.
/datum/ambush_wave/proc/find_spawn_turf(mob/living/carbon/human/target)
	var/list/valid_areas = spawn_areas || target_areas
	for(var/attempt in 1 to 80)
		var/turf/T = locate(target.x + rand(-18, 18), target.y + rand(-18, 18), target.z)
		if(!T || get_dist(T, target) < 12)
			continue
		if(!(isfloorturf(T) || istype(T, /turf/open/indestructible/ground)) || istype(T, /turf/open/transparent))
			continue
		if(is_blocked_turf(T, TRUE))
			continue
		var/area/A = get_area(T)
		if(!area_matches(A, valid_areas) || area_matches(A, exclude_areas))
			continue
		if(outdoors_only && !A.outdoors)
			continue
		var/seen = FALSE
		for(var/mob/M in viewers(11, T))
			if(M.client)
				seen = TRUE
				break
		if(seen)
			continue
		return T
	return null

/datum/ambush_wave/proc/spawn_wave(mob/living/carbon/human/target, active_players, source)
	var/turf/origin = find_spawn_turf(target)
	if(!origin)
		return FALSE
	var/amount = clamp(base_count + round(active_players / player_scale), base_count, max_count)
	var/list/nearby = list()
	for(var/turf/N in orange(2, origin))
		if(isopenturf(N) && !N.density && !is_blocked_turf(N, TRUE) && !istype(N, /turf/open/transparent))
			nearby += N
	for(var/i in 1 to amount)
		var/turf/spawn_loc = (i > 1 && length(nearby)) ? pick(nearby) : origin
		var/mob_type = pickweight(mob_types)
		var/mob/living/simple_animal/hostile/M = new mob_type(spawn_loc)
		if(M.AIStatus != AI_ON)
			M.toggle_ai(AI_ON)
		M.hunt(target, "ambush")
	if(flavor_message)
		for(var/mob/M in GLOB.player_list)
			if(M.z == target.z && get_dist(M, target) <= 30)
				to_chat(M, span_notice(flavor_message))
	message_admins("Faction ambush '[name]' ([source]) spawned [amount] mobs at [ADMIN_VERBOSEJMP(origin)], hunting [ADMIN_LOOKUPFLW(target)].")
	log_game("Faction ambush '[name]' ([source]) spawned [amount] mobs at [AREACOORD(origin)], hunting [key_name(target)].")
	return TRUE

/datum/ambush_wave/ncr_rangers
	name = "NCR ranger assassins near Legion territory"
	weight = 10
	friendly_factions = list("NCR", "Rangers")
	target_areas = list(/area/f13/wasteland/legion, /area/f13/legioncamp, /area/f13/legion)
	spawn_areas = list(/area/f13/wasteland/legion, /area/f13/legioncamp)
	mob_types = list(
		/mob/living/simple_animal/hostile/ncr/ranger = 3,
		/mob/living/simple_animal/hostile/ncr/ranger/sniper = 1,
	)
	base_count = 2
	player_scale = 12
	max_count = 4
	min_players = 4
	flavor_message = "A twig snaps somewhere out in the dark, then everything goes quiet."

/datum/ambush_wave/brotherhood_dungeon
	name = "Brotherhood squad in a dungeon"
	weight = 10
	friendly_factions = list("BOS")
	target_areas = list(/area/f13/caves, /area/f13/citycaves, /area/f13/bunker, /area/f13/underground/cave, /area/f13/ruins)
	exclude_areas = list(/area/f13/brotherhood, /area/f13/underground/bos)
	mob_types = list(
		/mob/living/simple_animal/hostile/bs/knight = 8,
		/mob/living/simple_animal/hostile/bs/paladin = 1,
	)
	base_count = 2
	max_count = 4
	min_players = 4
	flavor_message = "A faint mechanical whine echoes through the passages ahead."

/datum/ambush_wave/legion_raid
	name = "Legion raiding party near NCR territory"
	weight = 10
	friendly_factions = list("Legion")
	target_areas = list(/area/f13/wasteland/ncr, /area/f13/ncr_main, /area/f13/ncr)
	spawn_areas = list(/area/f13/wasteland/ncr)
	mob_types = list(
		/mob/living/simple_animal/hostile/legion/prime = 5,
		/mob/living/simple_animal/hostile/legion/decan = 3,
		/mob/living/simple_animal/hostile/legion/veteran = 2,
	)
	base_count = 3
	player_scale = 8
	max_count = 6
	min_players = 5
	flavor_message = "The beat of a war drum carries faintly on the wind."

/datum/ambush_wave/enclave_patrol
	name = "Enclave patrol"
	weight = 3
	friendly_factions = list("enclave", "Enclave")
	target_areas = list(/area/f13/wasteland)
	exclude_areas = list(/area/f13/wasteland/ncr, /area/f13/wasteland/legion, /area/f13/wasteland/followers, /area/f13/wasteland/khanfort, /area/f13/wasteland/bighornbunker)
	outdoors_only = TRUE
	mob_types = list(
		/mob/living/simple_animal/hostile/enclave/soldier = 6,
		/mob/living/simple_animal/hostile/enclave/officer = 1,
	)
	base_count = 2
	player_scale = 12
	max_count = 4
	min_players = 6
	cooldown_time = 60 MINUTES
	flavor_message = "A deep, steady drone rolls across the wasteland from somewhere far off."

/datum/ambush_wave/raider_ambush
	name = "Raider ambush in the wasteland"
	weight = 14
	friendly_factions = list("raider", "Raiders")
	target_areas = list(/area/f13/wasteland)
	exclude_areas = list(/area/f13/wasteland/ncr, /area/f13/wasteland/legion, /area/f13/wasteland/followers, /area/f13/wasteland/khanfort, /area/f13/wasteland/bighornbunker, /area/f13/wasteland/town)
	outdoors_only = TRUE
	mob_types = list(
		/mob/living/simple_animal/hostile/raider = 5,
		/mob/living/simple_animal/hostile/raider/ranged = 4,
		/mob/living/simple_animal/hostile/raider/outlaw = 2,
	)
	base_count = 3
	player_scale = 8
	max_count = 6
	min_players = 3
	cooldown_time = 20 MINUTES
	flavor_message = "Somewhere close by, an engine growls and someone whoops."
