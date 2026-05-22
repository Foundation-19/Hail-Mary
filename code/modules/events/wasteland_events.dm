// Comprehensive Fallout-specific events

// ============ RAD STORM ============

/datum/round_event_control/wasteland_rad_storm
	name = "Rad Storm"
	typepath = /datum/round_event/wasteland_rad_storm
	weight = 3
	max_occurrences = 3
	earliest_start = 10 MINUTES

/datum/round_event/wasteland_rad_storm
	var/intensity = 1
	var/duration = 300

/datum/round_event/wasteland_rad_storm/setup()
	startWhen = 5
	endWhen = startWhen + duration

/datum/round_event/wasteland_rad_storm/announce(fake)
	priority_announce("WARNING: Radiation cloud detected approaching the area. Seek shelter immediately.", "Rad Storm Alert", "radiation")

/datum/round_event/wasteland_rad_storm/start()
	// Apply radiation to players
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(H.z == 1 || H.z == 2)
			var/rad_amount = rand(15, 40) * intensity
			H.radiation += rad_amount
			
			// Give warning if they're taking a lot
			if(rad_amount > 30)
				to_chat(H, span_warning("The radiation burns your skin!"))
	
	// Effect on the world
	announce_rad_storm_effects()

/datum/round_event/wasteland_rad_storm/proc/announce_rad_storm_effects()
	to_chat(world, span_danger("A massive radiation storm sweeps across the wasteland!"))
	to_chat(world, span_warning("Geiger counters click frantically as the storm passes..."))
	
	// Could add weather overlay here if implemented
	// Could spawn irradiated mobs

/datum/round_event/wasteland_rad_storm/end()
	priority_announce("The radiation storm has passed. Radiation levels returning to normal.", "All Clear", "radiation")
	to_chat(world, span_notice("The radiation storm subsides. Safe to venture out again."))

// ============ DUST STORM ============

/datum/round_event_control/wasteland_dust_storm
	name = "Dust Storm"
	typepath = /datum/round_event/wasteland_dust_storm
	weight = 3
	max_occurrences = 4

/datum/round_event/wasteland_dust_storm
	var/duration = 200

/datum/round_event/wasteland_dust_storm/setup()
	startWhen = 3
	endWhen = startWhen + duration

/datum/round_event/wasteland_dust_storm/announce(fake)
	priority_announce("Dust storm approaching. Visibility will be reduced.", "Weather Alert", "dust")

/datum/round_event/wasteland_dust_storm/start()
	// Reduce visibility for players
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(H.z == 1 || H.z == 2)
			// Apply dust effect - could add overlay
			if(prob(30))
				to_chat(H, span_warning("Dust blows in your face!"))
	
	to_chat(world, span_warning("A massive dust storm rolls in from the horizon!"))

/datum/round_event/wasteland_dust_storm/end()
	priority_announce("The dust storm has subsided.", "All Clear", "dust")
	to_chat(world, span_notice("The dust storm fades away."))

// ============ TRADING CARAVAN ============

/datum/round_event_control/wasteland_caravan
	name = "Trading Caravan"
	typepath = /datum/round_event/wasteland_caravan
	weight = 2
	max_occurrences = 2
	min_players = 8

/datum/round_event/wasteland_caravan
	var/list/caravan_members = list()
	var/turf/destination_turf

/datum/round_event/wasteland_caravan/setup()
	startWhen = 60
	endWhen = startWhen + 900

/datum/round_event/wasteland_caravan/announce(fake)
	priority_announce("A NCR supply caravan has been spotted en route to the settlement.", "Caravan Alert", "supply")

/datum/round_event/wasteland_caravan/start()
	spawn_caravan()

/datum/round_event/wasteland_caravan/proc/spawn_caravan()
	var/turf/start_turf = find_safe_turf()
	destination_turf = find_safe_turf()
	
	// Spawn brahmin (pack animals)
	for(var/i = 1 to 3)
		var/mob/living/simple_animal/cow/brahmin/B = new(start_turf)
		B.name = "brahmin #[i]"
		B.faction = "ncr"
		B.maxHealth = 50
		B.health = 50
		caravan_members += B
	
	// Spawn NCR guards
	for(var/i = 1 to 4)
		var/mob/living/carbon/human/guard = new(start_turf)
		guard.set_species(/datum/species/human)
		guard.real_name = "NCR Guard"
		guard.name = guard.real_name
		guard.faction = "ncr"
		
		// Equip guard
		guard.equip_to_slot_or_del(new /obj/item/clothing/under/f13/ncr(guard), SLOT_W_UNIFORM)
		guard.equip_to_slot_or_del(new /obj/item/clothing/shoes/jackboots(guard), SLOT_SHOES)
		
		// Give weapon
		var/obj/item/gun/ballistic/automatic/assault_rifle/rifle = new(guard)
		guard.equip_to_slot_or_del(rifle, SLOT_BACK)
		
		caravan_members += guard
	
	to_chat(world, span_notice("An NCR supply caravan enters the area."))
	
	// Start moving after a delay
	addtimer(CALLBACK(src, .proc/move_caravan, start_turf), 200)

/datum/round_event/wasteland_caravan/proc/move_caravan(turf/start_turf)
	if(!destination_turf)
		return
		
	for(var/mob/M in caravan_members)
		if(QDELETED(M))
			continue
		// Move toward destination
		for(var/i in 1 to 10)
			step_towards(M, destination_turf)
			sleep(2)
		
		// Award reputation to nearby players
		for(var/mob/living/carbon/human/H in viewers(5, M))
			if(H.client && H.ckey)
				if(get_faction_reputation(H.ckey, "ncr") < 100)
					adjust_faction_reputation(H.ckey, "ncr", 1)

/datum/round_event/wasteland_caravan/end()
	for(var/mob/M in caravan_members)
		if(!QDELETED(M))
			M.visible_message(span_notice("[M] continues on their journey."))
			qdel(M)

// ============ RANDOM ENCOUNTERS ============

/datum/round_event_control/wasteland_random_encounter
	name = "Random Wasteland Encounter"
	typepath = /datum/round_event/wasteland_random_encounter
	weight = 5
	max_occurrences = 10

/datum/round_event/wasteland_random_encounter
	var/encounter_type = "raiders"

/datum/round_event/wasteland_random_encounter/setup()
	startWhen = 10

/datum/round_event/wasteland_random_encounter/announce(fake)
	// No announcement - it's random!

/datum/round_event/wasteland_random_encounter/start()
	encounter_type = pick("raiders", "mutants", "scar", "trader", "ferals")
	spawn_encounter()

/datum/round_event/wasteland_random_encounter/proc/spawn_encounter()
	var/turf/spawn_turf = find_safe_turf()
	
	switch(encounter_type)
		if("raiders")
			spawn_raiders(spawn_turf)
		if("mutants")
			spawn_mutants(spawn_turf)
		if("scar")
			spawn_crash(spawn_turf)
		if("trader")
			spawn_wandering_trader(spawn_turf)
		if("ferals")
			spawn_feral_ghouls(spawn_turf)

/datum/round_event/wasteland_random_encounter/proc/spawn_raiders(turf/T)
	var/num_raiders = rand(2, 5)
	
	for(var/i = 1 to num_raiders)
		var/mob/living/carbon/human/raider = new(T)
		raider.set_species(/datum/species/human)
		raider.name = "Raider"
		raider.faction = "raiders"
		
		var/weapon_type = pick(/obj/item/melee/onehanded/knife/survival, /obj/item/melee/onehanded/knife, /obj/item/twohanded/fireaxe, /obj/item/twohanded/baseball)
		raider.equip_to_slot_or_del(new weapon_type(raider), SLOT_BACK)
		
		// Random loot
		if(prob(30))
			var/obj/item/stack/f13Cash/caps/cap_stack = new(raider)
			cap_stack.amount = rand(5, 25)
			raider.equip_to_slot_or_del(cap_stack, SLOT_IN_BACKPACK)
		
		// Add to spawning
		addtimer(CALLBACK(GLOBAL_PROC, .proc/qdel, raider), rand(300, 600))

/datum/round_event/wasteland_random_encounter/proc/spawn_mutants(turf/T)
	var/num_mutants = rand(1, 3)
	
	for(var/i = 1 to num_mutants)
		var/mob/living/carbon/human/mutant = new(T)
		mutant.set_species(/datum/species/ghoul)
		mutant.name = "Feral Ghoul"
		mutant.faction = "ghoul"
		
		// Make them hostile (AI controller removed - using default simple_animal AI)
		mutant.mob_biotypes = MOB_ORGANIC | MOB_HUMANOID
		
		addtimer(CALLBACK(GLOBAL_PROC, .proc/qdel, mutant), rand(300, 600))

/datum/round_event/wasteland_random_encounter/proc/spawn_crash(turf/T)
	// Create wreckage
	var/obj/structure/closet/crate/crash_site = new(T)
	crash_site.name = "crashed vertibird"
	crash_site.desc = "The burnt remains of a military vertibird. There might be valuable salvage."
	
	// Add loot inside
	new /obj/item/gun/energy/laser/rifle(crash_site)
	new /obj/item/stock_parts/cell/high(crash_site)
	var/obj/item/stack/sheet/metal/salvage = new(crash_site)
	salvage.amount = 10
	
	to_chat(world, span_boldannounce("A crash site has been discovered in the wasteland!"))

/datum/round_event/wasteland_random_encounter/proc/spawn_wandering_trader(turf/T)
	var/mob/living/carbon/human/trader = new(T)
	trader.set_species(/datum/species/human)
	trader.real_name = pick("Jolly Jim", "Happy Hannah", "Lucky Luke", "Wandering Willy")
	trader.name = trader.real_name
	trader.faction = "neutral"
	
	// Give caps for trading
	var/obj/item/stack/f13Cash/caps/cap_stash = new(trader)
	cap_stash.amount = rand(100, 300)
	trader.equip_to_slot_or_del(cap_stash, SLOT_IN_BACKPACK)
	
	to_chat(world, span_notice("A wandering trader has been spotted in the area."))
	
	addtimer(CALLBACK(GLOBAL_PROC, .proc/qdel, trader), rand(300, 600))

/datum/round_event/wasteland_random_encounter/proc/spawn_feral_ghouls(turf/T)
	var/num_ferals = rand(2, 4)
	
	for(var/i = 1 to num_ferals)
		var/mob/living/carbon/human/ghoul = new(T)
		ghoul.set_species(/datum/species/ghoul)
		ghoul.name = "Feral Ghoul"
		ghoul.faction = "ghoul"
		
		// Make them very aggressive
		ghoul.mob_biotypes = MOB_ORGANIC | MOB_HUMANOID
		ghoul.maxHealth = 60
		ghoul.health = 60
		
		addtimer(CALLBACK(GLOBAL_PROC, .proc/qdel, ghoul), rand(300, 600))
	
	to_chat(world, span_warning("Screams echo from nearby - a pack of feral ghouls!"))

// ============ NCR PATROL ============

/datum/round_event_control/wasteland_ncr_patrol
	name = "NCR Patrol"
	typepath = /datum/round_event/wasteland_ncr_patrol
	weight = 3
	max_occurrences = 3

/datum/round_event/wasteland_ncr_patrol/setup()
	startWhen = 30
	endWhen = startWhen + 400

/datum/round_event/wasteland_ncr_patrol/announce(fake)
	priority_announce("NCR patrol unit entering the area.", "Military Activity", "ncr")

/datum/round_event/wasteland_ncr_patrol/start()
	var/turf/spawn_turf = find_safe_turf()
	
	// Spawn patrol
	for(var/i = 1 to 3)
		var/mob/living/carbon/human/soldier = new(spawn_turf)
		soldier.set_species(/datum/species/human)
		soldier.name = "NCR Soldier"
		soldier.faction = "ncr"
		
		soldier.equip_to_slot_or_del(new /obj/item/clothing/under/f13/ncr(soldier), SLOT_W_UNIFORM)
		soldier.equip_to_slot_or_del(new /obj/item/clothing/shoes/jackboots(soldier), SLOT_SHOES)
		
		var/obj/item/gun/ballistic/automatic/assault_rifle/rifle = new(soldier)
		soldier.equip_to_slot_or_del(rifle, SLOT_BACK)
