/datum/unit_test/harm_punch/Run()
	var/mob/living/carbon/human/puncher = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)

	// Avoid all randomness in tests
	ADD_TRAIT(puncher, TRAIT_PERFECT_ATTACKER, INNATE_TRAIT)

	puncher.a_intent_change(INTENT_HARM)
	victim.attack_hand(puncher)

	TEST_ASSERT(victim.getBruteLoss() > 0, "Victim took no brute damage after being punched")

/datum/unit_test/harm_melee/Run()
	var/mob/living/carbon/human/tider = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/obj/item/storage/toolbox/toolbox = allocate(/obj/item/storage/toolbox)

	tider.put_in_active_hand(toolbox, forced = TRUE)
	tider.a_intent_change(INTENT_HARM)
	victim.attackby(toolbox, tider)

	TEST_ASSERT(victim.getBruteLoss() > 0, "Victim took no brute damage after being hit by a toolbox")

/datum/unit_test/harm_different_damage/Run()
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/obj/item/weldingtool/welding_tool = allocate(/obj/item/weldingtool)

	attacker.put_in_active_hand(welding_tool, forced = TRUE)
	attacker.a_intent_change(INTENT_HARM)
	welding_tool.attack_self(attacker) // Turn it on
	victim.attackby(welding_tool, attacker)

	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Victim took brute damage from a lit welding tool")
	TEST_ASSERT(victim.getFireLoss() > 0, "Victim took no burn damage after being hit by a lit welding tool")

/datum/unit_test/attack_chain
	var/attack_hit
	var/post_attack_hit
	var/pre_attack_hit

/datum/unit_test/attack_chain/proc/attack_hit()
	attack_hit = TRUE

/datum/unit_test/attack_chain/proc/post_attack_hit()
	post_attack_hit = TRUE

/datum/unit_test/attack_chain/proc/pre_attack_hit()
	pre_attack_hit = TRUE

/datum/unit_test/attack_chain/Run()
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/obj/item/storage/toolbox/toolbox = allocate(/obj/item/storage/toolbox)

	RegisterSignal(toolbox, COMSIG_ITEM_PRE_ATTACK, PROC_REF(pre_attack_hit))
	RegisterSignal(toolbox, COMSIG_ITEM_ATTACK, PROC_REF(attack_hit))
	RegisterSignal(toolbox, COMSIG_ITEM_AFTERATTACK, PROC_REF(post_attack_hit))

	attacker.put_in_active_hand(toolbox, forced = TRUE)
	attacker.a_intent_change(INTENT_HARM)
	toolbox.melee_attack_chain(attacker, victim)

	TEST_ASSERT(pre_attack_hit, "Pre-attack signal was not fired")
	TEST_ASSERT(attack_hit, "Attack signal was not fired")
	TEST_ASSERT(post_attack_hit, "Post-attack signal was not fired")

/datum/unit_test/kill_credit
	var/hits = 0
	var/kills = 0

/datum/unit_test/kill_credit/proc/on_hit(datum/source, mob/living/victim, damage, atom/hit_source)
	hits++

/datum/unit_test/kill_credit/proc/on_kill(datum/source, mob/living/victim)
	kills++

/datum/unit_test/kill_credit/Run()
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/mob/living/simple_animal/hostile/victim = allocate(/mob/living/simple_animal/hostile)
	var/obj/item/storage/toolbox/toolbox = allocate(/obj/item/storage/toolbox)

	ADD_TRAIT(attacker, TRAIT_PERFECT_ATTACKER, INNATE_TRAIT)
	victim.maxHealth = 20
	victim.health = 20
	RegisterSignal(attacker, COMSIG_MOB_LANDED_HIT, PROC_REF(on_hit))
	RegisterSignal(attacker, COMSIG_MOB_KILLED_MOB, PROC_REF(on_kill))
	attacker.put_in_active_hand(toolbox, forced = TRUE)
	attacker.a_intent_change(INTENT_HARM)

	victim.attackby(toolbox, attacker)
	TEST_ASSERT_EQUAL(hits, 1, "A damaging melee hit did not send COMSIG_MOB_LANDED_HIT exactly once")
	TEST_ASSERT_EQUAL(kills, 0, "COMSIG_MOB_KILLED_MOB fired for a hit that did not kill")
	for(var/i in 1 to 10)
		if(victim.stat == DEAD)
			break
		victim.attackby(toolbox, attacker)
	TEST_ASSERT_EQUAL(victim.stat, DEAD, "The toolbox never killed the victim")
	TEST_ASSERT_EQUAL(kills, 1, "The killing blow did not credit the attacker exactly once")

/datum/unit_test/kill_credit_expiry
	var/kills = 0

/datum/unit_test/kill_credit_expiry/proc/on_kill(datum/source, mob/living/victim)
	kills++

/datum/unit_test/kill_credit_expiry/Run()
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/mob/living/simple_animal/hostile/no_damage = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/simple_animal/hostile/stale = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/simple_animal/hostile/fresh = allocate(/mob/living/simple_animal/hostile)
	RegisterSignal(attacker, COMSIG_MOB_KILLED_MOB, PROC_REF(on_kill))

	// An interaction that did no damage must not leave kill credit behind
	no_damage.prime_damage_credit(attacker)
	no_damage.register_damage_from(attacker, 0)
	no_damage.death()
	TEST_ASSERT_EQUAL(kills, 0, "A zero-damage interaction was credited with a kill")

	stale.register_damage_from(attacker, 5)
	stale.last_damager_time = world.time - KILL_CREDIT_WINDOW - 1
	stale.death()
	TEST_ASSERT_EQUAL(kills, 0, "A hit older than KILL_CREDIT_WINDOW was credited with a kill")

	fresh.register_damage_from(attacker, 5)
	fresh.death()
	TEST_ASSERT_EQUAL(kills, 1, "A recent damager was not credited when the victim died of something else")

/datum/unit_test/hostile_stagger/Run()
	var/mob/living/simple_animal/hostile/victim = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)

	victim.ai_stagger(15)
	TEST_ASSERT(world.time < victim.ai_stagger_until, "ai_stagger() did not set a stagger window")
	TEST_ASSERT(!COOLDOWN_FINISHED(victim, melee_cooldown), "ai_stagger() did not delay the next melee swing")
	TEST_ASSERT(!victim.AttackingTarget(), "A staggered mob was still allowed to attack")
	TEST_ASSERT(!victim.OpenFire(target), "A staggered mob was still allowed to fire")

/// A mob whose bullet_act never reaches the parent, like the renegade
/mob/living/simple_animal/hostile/unit_test_bullet_eater/bullet_act(obj/item/projectile/P, def_zone)
	adjustBruteLoss(5)
	return BULLET_ACT_HIT

/datum/unit_test/attack_credit
	var/hits = 0
	var/kills = 0

/datum/unit_test/attack_credit/proc/on_hit(datum/source, mob/living/victim, damage, atom/hit_source)
	hits++

/datum/unit_test/attack_credit/proc/on_kill(datum/source, mob/living/victim)
	kills++

/datum/unit_test/attack_credit/Run()
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/mob/living/simple_animal/hostile/victim = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/simple_animal/hostile/unit_test_bullet_eater/eater = allocate(/mob/living/simple_animal/hostile/unit_test_bullet_eater)
	var/mob/living/simple_animal/hostile/burning = allocate(/mob/living/simple_animal/hostile)
	for(var/mob/living/simple_animal/hostile/M in list(victim, eater, burning))
		M.maxHealth = 20
		M.health = 20
	RegisterSignal(attacker, COMSIG_MOB_LANDED_HIT, PROC_REF(on_hit))
	RegisterSignal(attacker, COMSIG_MOB_KILLED_MOB, PROC_REF(on_kill))

	// Damage dealt by an attack path with no attribution of its own is credited by the wrapper
	var/list/snapshot = attacker.start_attack_credit(victim)
	victim.adjustBruteLoss(5)
	attacker.end_attack_credit(snapshot)
	TEST_ASSERT_EQUAL(hits, 1, "The attack credit wrapper did not report a landed hit")

	// An attack that already registered its own damage is not reported twice
	snapshot = attacker.start_attack_credit(victim)
	victim.adjustBruteLoss(5)
	victim.register_damage_from(attacker, 5)
	attacker.end_attack_credit(snapshot)
	TEST_ASSERT_EQUAL(hits, 2, "A hit that was already attributed was signalled twice")

	snapshot = attacker.start_attack_credit(victim)
	victim.adjustBruteLoss(100)
	attacker.end_attack_credit(snapshot)
	TEST_ASSERT_EQUAL(victim.stat, DEAD, "The victim survived lethal damage")
	TEST_ASSERT_EQUAL(kills, 1, "A killing blow through the attack credit wrapper did not credit the attacker")

	// A bullet_act that skips the parent is still attributed through deliver_to()
	var/obj/item/projectile/bullet = allocate(/obj/item/projectile)
	bullet.firer = attacker
	var/before = hits
	bullet.deliver_to(eater, BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(hits, before + 1, "A projectile hit on a mob with its own bullet_act was not attributed")

	// Burning gets a longer kill window than a normal hit
	burning.register_damage_from(attacker, 5)
	burning.on_fire = TRUE
	burning.last_damager_time = world.time - KILL_CREDIT_WINDOW - 1
	burning.death()
	TEST_ASSERT_EQUAL(kills, 2, "A mob that burned to death was not credited to the person who set it alight")

/datum/unit_test/rank_book_quirk_conflict/Run()
	var/mob/living/carbon/human/reader = allocate(/mob/living/carbon/human)
	var/obj/item/book/granter/trait/rank/fleet_footed/book = allocate(/obj/item/book/granter/trait/rank/fleet_footed)
	TEST_ASSERT(isnull(SSquirks.get_conflicting_quirk(reader, /datum/quirk/modular/fleet_footed)), "A human with no quirks reported a conflict")

	reader.add_quirk(SSquirks.quirks["Slow Poke"], FALSE)
	TEST_ASSERT_EQUAL(SSquirks.get_conflicting_quirk(reader, /datum/quirk/modular/fleet_footed), "Slow Poke", "Slow Poke did not conflict with Fleet Footed")
	reader.special_a = 10
	TEST_ASSERT(book.already_known(reader), "A skill book could be read despite a conflicting quirk")

/datum/unit_test/climate_exposure/Run()
	var/mob/living/carbon/human/normal = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/intolerant = allocate(/mob/living/carbon/human)
	intolerant.physiology.cold_mod = 1.4
	// Whatever the time of day, aim for a fixed ambient temperature
	var/base = normal.get_climate_ambient()
	normal.climate_temp_offset = CLIMATE_COMFORT_MIN - 20 - base
	intolerant.climate_temp_offset = CLIMATE_COMFORT_MIN - 20 - base

	TEST_ASSERT(normal.get_climate_target() < 0, "A freezing ambient did not produce cold exposure")
	TEST_ASSERT(intolerant.get_climate_target() < normal.get_climate_target(), "Cold Intolerant did not make cold exposure worse")

	normal.handle_climate()
	TEST_ASSERT(normal.climate_exposure < 0 && normal.bodytemperature < BODYTEMP_NORMAL, "Cold exposure did not chill the body")

	normal.climate_temp_offset = CLIMATE_INDOOR_TEMP - base
	for(var/i in 1 to 200)
		normal.handle_climate()
	TEST_ASSERT_EQUAL(normal.climate_exposure, 0, "Exposure did not wear off in a comfortable ambient")
	TEST_ASSERT_EQUAL(normal.bodytemperature, BODYTEMP_NORMAL, "Body temperature did not recover")

/datum/unit_test/climate_effects/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	victim.climate_temp_offset = -100
	victim.climate_exposure = -CLIMATE_EXPOSURE_MAX
	victim.handle_climate()
	TEST_ASSERT(victim.getFireLoss() > 0, "Severe cold did not cause frostbite damage")
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/cold), "Severe cold did not slow the victim")

	victim.adjustFireLoss(victim.maxHealth * 0.8 - victim.getFireLoss())
	var/before = victim.getFireLoss()
	victim.handle_climate()
	TEST_ASSERT_EQUAL(victim.getFireLoss(), before, "Climate damage went past the health floor")

/datum/unit_test/climate_heat_source/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/obj/structure/campfire/fire = allocate(/obj/structure/campfire, get_turf(victim))
	victim.climate_temp_offset = -40
	var/cold = victim.get_climate_ambient()
	fire.fire()
	var/warmed = victim.get_climate_ambient()
	TEST_ASSERT(warmed > cold, "A lit campfire did not warm someone standing next to it")
	TEST_ASSERT(warmed <= CLIMATE_HEAT_SOURCE_CAP, "A fire pushed the ambient temperature past its cap")

	fire.fuel = 0
	fire.process()
	TEST_ASSERT(!fire.fired, "A campfire that ran out of fuel kept burning")
	TEST_ASSERT(!(fire in GLOB.climate_heat_sources), "A burnt out campfire stayed in the heat source registry")
	fire.fuel = 300
	TEST_ASSERT_EQUAL(victim.get_climate_ambient(), cold, "A refuelled campfire warmed someone without being relit")
	fire.fire()
	TEST_ASSERT(victim.get_climate_ambient() > cold, "Relighting a refuelled campfire did not warm someone again")

/datum/unit_test/climate_indoor_drift/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/area/A = get_area(victim)
	var/old_outdoors = A.outdoors
	var/old_leak = A.climate_leak
	var/old_lag = A.climate_lag
	var/old_temp = A.climate_indoor_temp
	var/old_stamp = A.climate_indoor_stamp
	A.outdoors = FALSE

	var/outdoor = climate_phase_temp(SSnightcycle.current_time)
	A.climate_leak = 1
	A.climate_lag = CLIMATE_LAG_DEFAULT
	A.climate_indoor_temp = CLIMATE_INDOOR_TEMP
	A.climate_indoor_stamp = world.time - 60 SECONDS
	var/drifted = A.get_climate_temp()
	if(outdoor != CLIMATE_INDOOR_TEMP)
		TEST_ASSERT((drifted - CLIMATE_INDOOR_TEMP) * (outdoor - CLIMATE_INDOOR_TEMP) > 0, "A room did not drift towards the outdoor temperature")
		TEST_ASSERT(abs(drifted - CLIMATE_INDOOR_TEMP) < abs(outdoor - CLIMATE_INDOOR_TEMP), "A room matched the outdoors instantly instead of lagging behind it")
	TEST_ASSERT_EQUAL(victim.get_climate_ambient(), drifted + victim.climate_temp_offset + victim.get_climate_warmth(), "Someone indoors did not feel the temperature of the room")

	A.climate_leak = 0
	A.climate_indoor_temp = CLIMATE_INDOOR_TEMP
	A.climate_indoor_stamp = world.time - 600 SECONDS
	TEST_ASSERT_EQUAL(A.get_climate_temp(), CLIMATE_INDOOR_TEMP, "A sealed room changed temperature")

	A.outdoors = old_outdoors
	A.climate_leak = old_leak
	A.climate_lag = old_lag
	A.climate_indoor_temp = old_temp
	A.climate_indoor_stamp = old_stamp

/datum/unit_test/climate_wetness/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	victim.climate_temp_offset = CLIMATE_COMFORT_MIN - 10 - victim.get_climate_ambient()
	var/dry_cold = victim.get_climate_target()
	victim.adjust_climate_wetness(CLIMATE_WET_MAX * 2)
	TEST_ASSERT_EQUAL(victim.climate_wetness, CLIMATE_WET_MAX, "Wetness went past its cap")
	TEST_ASSERT(victim.get_climate_target() < dry_cold, "Being soaked did not make the cold worse")

	victim.climate_temp_offset = 0
	victim.climate_temp_offset = CLIMATE_COMFORT_MAX + 5 - victim.get_climate_ambient()
	var/wet_heat = victim.get_climate_target()
	victim.climate_wetness = 0
	TEST_ASSERT(wet_heat < victim.get_climate_target(), "Being soaked did not take the edge off the heat")

	victim.adjust_climate_wetness(CLIMATE_WET_MAX)
	victim.dry_off()
	TEST_ASSERT(victim.climate_wetness < CLIMATE_WET_MAX, "A soaked person never dried off")
	TEST_ASSERT(isnull(get_active_weather(victim)), "A weather was reported with none running")

/datum/unit_test/climate_clothing/Run()
	var/mob/living/carbon/human/bare = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/coated = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/armored = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/ragged = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/duster = allocate(/mob/living/carbon/human)
	for(var/mob/living/carbon/human/H in list(coated, armored, duster))
		H.equip_to_slot(allocate(/obj/item/clothing/under/color/grey), SLOT_W_UNIFORM)
	ragged.equip_to_slot(allocate(/obj/item/clothing/under/f13/rag), SLOT_W_UNIFORM)
	coated.equip_to_slot(allocate(/obj/item/clothing/suit/hooded/wintercoat), SLOT_WEAR_SUIT)
	armored.equip_to_slot(allocate(/obj/item/clothing/suit/armor/heavy), SLOT_WEAR_SUIT)
	duster.equip_to_slot(allocate(/obj/item/clothing/suit/armor/light/duster), SLOT_WEAR_SUIT)

	TEST_ASSERT(coated.get_climate_insulation() > bare.get_climate_insulation(), "A winter coat added no insulation")
	TEST_ASSERT(coated.get_climate_insulation() >= armored.get_climate_insulation(), "A winter coat kept the cold out worse than heavy armor")
	TEST_ASSERT(ragged.get_climate_insulation() < duster.get_climate_insulation(), "Rags insulated as well as a proper outfit")
	TEST_ASSERT(armored.get_climate_heat_trap() > duster.get_climate_heat_trap(), "Heavy armor did not trap more heat than a duster")
	TEST_ASSERT(coated.get_climate_insulation() <= CLIMATE_INSULATION_MAX, "Insulation went past its cap")

	var/before = coated.get_climate_insulation()
	coated.equip_to_slot(allocate(/obj/item/clothing/neck/scarf), SLOT_NECK)
	var/with_scarf = coated.get_climate_insulation()
	TEST_ASSERT(with_scarf > before, "A scarf around the neck added no insulation")
	coated.equip_to_slot(allocate(/obj/item/clothing/mask/balaclava), SLOT_WEAR_MASK)
	TEST_ASSERT(coated.get_climate_insulation() > with_scarf, "A balaclava added no insulation")

	bare.climate_temp_offset = -40
	coated.climate_temp_offset = -40
	TEST_ASSERT(coated.get_climate_target() > bare.get_climate_target(), "Warm clothing did not soften the cold")

/datum/unit_test/climate_species/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/ghoul = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/mutant = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/robot = allocate(/mob/living/carbon/human)
	ghoul.set_species(/datum/species/ghoul)
	mutant.set_species(/datum/species/smutant)
	robot.set_species(/datum/species/c27)
	var/list/everyone = list(human, ghoul, mutant, robot)
	// Whatever area the arena is in, aim for fixed absolute temperatures
	var/base = human.get_climate_ambient()

	for(var/mob/living/carbon/human/H in everyone)
		TEST_ASSERT(H.climate_applies(), "[H.dna.species.name] was exempt from the climate")
		H.climate_temp_offset = CLIMATE_COMFORT_MIN - 10 - base
	TEST_ASSERT(human.get_climate_target() < 0, "A human felt no cold")
	TEST_ASSERT(ghoul.get_climate_target() > human.get_climate_target(), "A ghoul did not feel the cold less than a human")
	TEST_ASSERT(mutant.get_climate_target() > ghoul.get_climate_target(), "A super mutant did not feel the cold less than a ghoul")
	TEST_ASSERT_EQUAL(robot.get_climate_target(), 0, "A C-27 felt the cold")

	for(var/mob/living/carbon/human/H in everyone)
		H.climate_temp_offset = CLIMATE_COMFORT_MAX + 10 - base
	TEST_ASSERT(human.get_climate_target() > 0, "A human felt no heat")
	TEST_ASSERT(ghoul.get_climate_target() > human.get_climate_target(), "A ghoul did not feel the heat more than a human")
	TEST_ASSERT(mutant.get_climate_target() > human.get_climate_target(), "A super mutant did not feel the heat more than a human")
	TEST_ASSERT(robot.get_climate_target() > 0, "A C-27 never overheated")

	robot.physiology.heat_mod = 0.5
	TEST_ASSERT(robot.get_climate_target() < human.get_climate_target(), "Heat resistance did nothing for a C-27")

	robot.nutrition = NUTRITION_LEVEL_FED
	robot.climate_exposure = CLIMATE_EXPOSURE_MAX
	robot.climate_temp_offset = 100
	robot.handle_climate()
	TEST_ASSERT(robot.nutrition < NUTRITION_LEVEL_FED, "An overheating C-27 did not burn charge")

/datum/unit_test/credit_ref_projectile
	var/hits = 0

/datum/unit_test/credit_ref_projectile/proc/on_hit(datum/source, mob/living/victim, damage, atom/hit_source)
	hits++

/datum/unit_test/credit_ref_projectile/Run()
	var/mob/living/carbon/human/placer = allocate(/mob/living/carbon/human)
	var/mob/living/simple_animal/hostile/victim = allocate(/mob/living/simple_animal/hostile)
	RegisterSignal(placer, COMSIG_MOB_LANDED_HIT, PROC_REF(on_hit))
	// Shrapnel from a mine has no firer, only the person who planted it
	var/obj/item/projectile/pellet = allocate(/obj/item/projectile)
	pellet.credit_ref = WEAKREF(placer)
	pellet.deliver_to(victim, BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(hits, 1, "A projectile carrying only a credit reference did not credit its owner")
	var/obj/item/projectile/stray = allocate(/obj/item/projectile)
	stray.deliver_to(victim, BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(hits, 1, "A projectile with nobody to credit signalled a hit")

/datum/unit_test/late_damage_credit
	var/hits = 0

/datum/unit_test/late_damage_credit/proc/on_hit(datum/source, mob/living/victim, damage, atom/hit_source)
	hits++

/datum/unit_test/late_damage_credit/Run()
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/mob/living/simple_animal/hostile/victim = allocate(/mob/living/simple_animal/hostile)
	victim.maxHealth = 50
	victim.health = 50
	attacker.a_intent = INTENT_HARM
	RegisterSignal(attacker, COMSIG_MOB_LANDED_HIT, PROC_REF(on_hit))

	// The attack slept before dealing damage, so the wrapper saw nothing and the damage lands afterwards
	var/list/snapshot = attacker.start_attack_credit(victim)
	attacker.end_attack_credit(snapshot)
	TEST_ASSERT_EQUAL(hits, 0, "A hit that had not landed yet was signalled")
	victim.apply_damage(5, BRUTE)
	TEST_ASSERT_EQUAL(hits, 1, "Damage landing just after an attack was not attributed to the attacker")

	victim.late_damager_until = world.time - 1
	victim.apply_damage(5, BRUTE)
	TEST_ASSERT_EQUAL(hits, 1, "Damage long after an attack was still attributed to the attacker")

	// One attack lands one hit
	victim.watch_late_damage(attacker)
	victim.apply_damage(5, BRUTE)
	victim.apply_damage(5, BRUTE)
	TEST_ASSERT_EQUAL(hits, 2, "A single sleeping attack was credited with more than one hit")

	// Damage from something out of reach is not the attack that was being waited on
	victim.watch_late_damage(attacker)
	attacker.forceMove(run_loc_top_right)
	victim.forceMove(run_loc_bottom_left)
	victim.apply_damage(5, BRUTE)
	TEST_ASSERT_EQUAL(hits, 2, "Damage far from the attacker was credited to it")

	// A bullet that was blocked or missed must not open a window for unrelated damage
	victim.late_damager_until = 0
	attacker.forceMove(run_loc_bottom_left)
	var/list/blocked = attacker.start_attack_credit(victim)
	attacker.end_attack_credit(blocked, attacker)
	victim.apply_damage(5, BRUTE)
	TEST_ASSERT_EQUAL(hits, 2, "A blocked attack with a weapon opened a late-damage window")

/datum/unit_test/sunset_phases/Run()
	TEST_ASSERT_EQUAL(SSnightcycle.phase_for_station_time(700000), NIGHTCYCLE_PHASE_LATEAFTERNOON, "Late afternoon is not reached by the clock")
	TEST_ASSERT_EQUAL(SSnightcycle.phase_for_station_time(720000), NIGHTCYCLE_PHASE_SUNSET, "Sunset is not reached by the clock")
	TEST_ASSERT_EQUAL(SSnightcycle.phase_for_station_time(790000), NIGHTCYCLE_PHASE_FULLSUNSET, "Full sunset is not reached by the clock")
	TEST_ASSERT_EQUAL(SSnightcycle.phase_for_station_time(820000), NIGHTCYCLE_PHASE_NIGHTTIME, "Night does not follow full sunset")

/datum/unit_test/explosion_credit
	var/hits = 0

/datum/unit_test/explosion_credit/proc/on_hit(datum/source, mob/living/victim, damage, atom/hit_source)
	hits++

/datum/unit_test/explosion_credit/proc/wait_for_hit()
	for(var/i in 1 to 40)
		if(hits)
			return
		sleep(5)

/datum/unit_test/explosion_credit/Run()
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/mob/living/simple_animal/hostile/victim = allocate(/mob/living/simple_animal/hostile)
	victim.maxHealth = 500
	victim.health = 500
	RegisterSignal(attacker, COMSIG_MOB_LANDED_HIT, PROC_REF(on_hit))
	var/turf/arena = run_loc_bottom_left
	attacker.forceMove(run_loc_top_right)

	// Whoever last shot or hit a fuel tank owns the blast, even when something else detonates it
	var/obj/structure/reagent_dispensers/fueltank/tank = allocate(/obj/structure/reagent_dispensers/fueltank, arena)
	tank.take_damage(1, BRUTE, "melee", 0, attacked_by = attacker)
	tank.boom()
	wait_for_hit()
	TEST_ASSERT(hits > 0, "A fuel tank blast was not credited to whoever damaged it")

	// A blast set off by another explosion inherits that explosion's culprit
	hits = 0
	victim.health = 500
	var/obj/structure/reagent_dispensers/fueltank/chained = allocate(/obj/structure/reagent_dispensers/fueltank, arena)
	GLOB.explosion_chain_credit = WEAKREF(attacker)
	chained.boom()
	GLOB.explosion_chain_credit = null
	wait_for_hit()
	TEST_ASSERT(hits > 0, "A chained explosion did not inherit the credit of the blast that set it off")

	// Reagent explosions can be credited too
	hits = 0
	victim.health = 500
	var/datum/effect_system/reagents_explosion/boom = new
	boom.set_up(4, arena, 0, 0)
	boom.set_credit(attacker)
	boom.start()
	wait_for_hit()
	TEST_ASSERT(hits > 0, "A reagent explosion was not credited")

	// A mine nobody armed credits whoever set it off, or whoever shot it
	var/obj/item/mine/explosive/mine = allocate(/obj/item/mine/explosive, arena)
	TEST_ASSERT_EQUAL(mine.get_credit(attacker), attacker, "A map mine did not credit the one who stepped on it")
	mine.note_damager(victim)
	TEST_ASSERT_EQUAL(mine.get_credit(attacker), victim, "A map mine did not credit the one who shot it")

	// A tank set off by a fire credits whoever started the fire
	hits = 0
	victim.health = 500
	allocate(/obj/structure/reagent_dispensers/fueltank, arena)
	new /obj/effect/hotspot(arena, null, null, null, attacker)
	wait_for_hit()
	TEST_ASSERT(hits > 0, "A fuel tank that blew up from a fire was not credited to whoever lit it")

	// A tank shot long ago (well past the 30 second mark) still blames the shooter
	hits = 0
	victim.health = 500
	var/obj/structure/reagent_dispensers/fueltank/stale = allocate(/obj/structure/reagent_dispensers/fueltank, arena)
	stale.take_damage(1, BRUTE, "bullet", 0, attacked_by = attacker)
	stale.damaged_by_time = world.time - 2 MINUTES
	TEST_ASSERT(!stale.get_recent_damager(), "The 30 second damager window did not expire")
	TEST_ASSERT_EQUAL(stale.get_explosion_credit(), attacker, "A tank that was shot minutes ago lost its blame")
	stale.damaged_by_time = world.time - EXPLOSION_BLAME_WINDOW - 1 SECONDS
	TEST_ASSERT(!stale.get_explosion_credit(), "An explosion blamed someone long after the window")

	// The flamethrower stream credits whoever is holding it, both for the hit and for the fire it leaves
	hits = 0
	victim.health = 500
	victim.forceMove(arena)
	var/obj/item/ammo_casing/caseless/flamethrower/stream = allocate(/obj/item/ammo_casing/caseless/flamethrower)
	stream.ignite_turf(arena, attacker)
	TEST_ASSERT(hits > 0, "A flamethrower stream hit was not credited to its user")
	var/obj/effect/hotspot/stream_fire = locate() in arena
	TEST_ASSERT(stream_fire && RESOLVEWEAKREF(stream_fire.credit_ref) == attacker, "The fire a flamethrower stream leaves does not carry its user's credit")

/datum/unit_test/weather_time_of_day/Run()
	var/old_time = SSnightcycle.current_time
	var/old_frozen = SSnightcycle.admin_frozen
	SSnightcycle.admin_frozen = TRUE
	SSnightcycle.current_time = NIGHTCYCLE_PHASE_NIGHTTIME
	var/list/night = SSweather.get_weather_weights(0)
	SSnightcycle.current_time = NIGHTCYCLE_PHASE_DAYTIME
	var/list/noon = SSweather.get_weather_weights(0)
	SSnightcycle.current_time = old_time
	SSnightcycle.admin_frozen = old_frozen

	TEST_ASSERT(night[/datum/weather/cold_wave] > noon[/datum/weather/cold_wave] * 10, "Cold waves are not much likelier at night than at noon")
	TEST_ASSERT(noon[/datum/weather/heat_wave] > night[/datum/weather/heat_wave] * 10, "Heat waves are not much likelier at noon than at night")

/datum/unit_test/weather_cell_locality/Run()
	var/turf/here = run_loc_bottom_left
	var/datum/weather/storm = allocate(/datum/weather, list(here.z))
	storm.impacted_areas = list(here.loc)
	storm.stage = MAIN_STAGE
	var/datum/weather_cell/cell = new(list(here.z), here.x, here.y, 10, 10, 0, 0)
	cell.scale = 1
	storm.cells = list("[here.z]" = cell)
	storm.unique_cells = list(cell)
	START_PROCESSING(SSweather, storm)

	TEST_ASSERT(storm.in_cell(here), "The middle of a weather patch is not in it")
	TEST_ASSERT_EQUAL(storm.get_intensity(here), 1, "The middle of a weather patch is not at full strength")
	TEST_ASSERT(get_active_weather(here) == storm, "Weather is not felt under its patch")

	// The edge is lumpy, so test well inside and well outside it
	cell.x = here.x + 15
	TEST_ASSERT(!storm.in_cell(here), "A turf outside the patch counted as in it")
	TEST_ASSERT(storm.in_cell(here, 10), "The forecast range did not reach a turf just outside the patch")
	TEST_ASSERT(isnull(get_active_weather(here)), "Weather is felt outside its patch")
	TEST_ASSERT(findtext(storm.describe_position(here), "east"), "The weather patch was not described as lying to the east")
	cell.radius_x = 20
	cell.radius_y = 20
	var/intensity = storm.get_intensity(here)
	TEST_ASSERT(intensity > 0 && intensity < 1, "Weather is not weaker towards the edge of its patch")
	cell.x = here.x + 100
	TEST_ASSERT_EQUAL(storm.get_intensity(here), 0, "Weather has strength far outside its patch")

	// Weather that is not a patch covers everyone
	storm.localized = FALSE
	TEST_ASSERT(storm.in_cell(here), "Weather that is not localized missed someone")
	TEST_ASSERT_EQUAL(storm.get_intensity(here), 1, "Weather that is not localized was weak")

	STOP_PROCESSING(SSweather, storm)

/datum/unit_test/weather_concurrent/Run()
	var/turf/here = run_loc_bottom_left
	var/list/storms = list()
	for(var/i in 1 to 2)
		var/datum/weather/storm = allocate(/datum/weather, list(here.z))
		storm.impacted_areas = list(here.loc)
		storm.stage = MAIN_STAGE
		var/datum/weather_cell/cell = new(list(here.z), here.x, here.y, 10, 10, 0, 0)
		cell.scale = 1
		storm.cells = list("[here.z]" = cell)
		storm.unique_cells = list(cell)
		START_PROCESSING(SSweather, storm)
		storms += storm
	var/datum/weather/outside = allocate(/datum/weather, list(here.z))
	outside.impacted_areas = list(here.loc)
	outside.stage = MAIN_STAGE
	var/datum/weather_cell/far = new(list(here.z), here.x + 100, here.y, 10, 10, 0, 0)
	far.scale = 1
	outside.cells = list("[here.z]" = far)
	outside.unique_cells = list(far)
	START_PROCESSING(SSweather, outside)

	TEST_ASSERT_EQUAL(length(get_active_weathers(here)), 2, "Weather patches overlapping a spot were not all counted")
	TEST_ASSERT(!(outside in get_active_weathers(here)), "A patch somewhere else was counted over this spot")

	// A patch winding down is no longer in full force
	var/datum/weather/fading = storms[1]
	fading.stage = WIND_DOWN_STAGE
	TEST_ASSERT_EQUAL(length(get_active_weathers(here)), 1, "Weather winding down was still counted as in full force")

	for(var/datum/weather/storm as anything in storms + outside)
		STOP_PROCESSING(SSweather, storm)

	// A system never forecasts two clouds of one family, and busy families are left out
	var/old_rolls = SSweather.weather_rolls
	SSweather.weather_rolls = list(/datum/weather/heat_wave = 10, /datum/weather/cold_wave = 10, /datum/weather/rain = 10)
	TEST_ASSERT_EQUAL(get_weather_family(/datum/weather/heat_wave), get_weather_family(/datum/weather/cold_wave), "Heat and cold waves are not in the same family")
	var/list/weights = SSweather.get_weather_weights(0, list(get_weather_family(/datum/weather/heat_wave)))
	TEST_ASSERT(!(/datum/weather/heat_wave in weights) && !(/datum/weather/cold_wave in weights), "A busy family was still rolled")
	TEST_ASSERT(/datum/weather/rain in weights, "A free family was left out of the roll")
	SSweather.weather_rolls = old_rolls

/datum/unit_test/acid_rain_exposure/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	// A quick dash through the rain does nothing
	for(var/i in 1 to 2)
		victim.acid_rain_tick()
	TEST_ASSERT_EQUAL(victim.getFireLoss(), 0, "Acid rain burned someone during the grace period")
	for(var/i in 1 to 6)
		victim.acid_rain_tick()
	TEST_ASSERT(victim.getFireLoss() > 0, "Lingering in acid rain did not burn")

	// Shelter washes it off
	victim.acid_exposure = ACID_EXPOSURE_MAX
	victim.acid_decay()
	TEST_ASSERT_EQUAL(victim.acid_exposure, ACID_EXPOSURE_MAX, "Exposure faded while still in the rain")
	victim.acid_last_exposed = world.time - ACID_EXPOSURE_DECAY_DELAY - 1
	victim.acid_decay()
	TEST_ASSERT(victim.acid_exposure < ACID_EXPOSURE_MAX, "Exposure did not fade once out of the rain")

	// It never kills on its own
	victim.adjustFireLoss(victim.maxHealth * 0.8 - victim.getFireLoss())
	var/before = victim.getFireLoss()
	victim.acid_exposure = ACID_EXPOSURE_MAX
	victim.acid_rain_tick()
	TEST_ASSERT_EQUAL(victim.getFireLoss(), before, "Acid rain went past the health floor")

/datum/unit_test/acid_rain_protection/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	TEST_ASSERT_EQUAL(victim.get_acid_protection(BODY_ZONE_CHEST, CHEST), 0, "A naked person had acid protection")
	var/obj/item/clothing/suit/coat = allocate(/obj/item/clothing/suit)
	coat.body_parts_covered = CHEST
	victim.equip_to_slot(coat, SLOT_WEAR_SUIT)
	TEST_ASSERT(victim.get_acid_protection(BODY_ZONE_CHEST, CHEST) >= ACID_COVER_PROTECTION, "A coat did not shield the chest from acid rain")
	TEST_ASSERT_EQUAL(victim.get_acid_protection(BODY_ZONE_HEAD, HEAD), 0, "A coat shielded an uncovered head")

/datum/unit_test/shock_value_melee/Run()
	var/mob/living/simple_animal/hostile/mob = allocate(/mob/living/simple_animal/hostile)
	mob.ai_get_shaken(SHOCK_VALUE_SHAKEN_TIME, SHOCK_VALUE_FLINCH)
	TEST_ASSERT(mob.ai_shaken_until > world.time, "A shaken melee mob was not allowed to fall back")
	TEST_ASSERT(mob.ai_stagger_until > world.time, "A shaken melee mob did not flinch")
	mob.ai_stagger_until = 0
	mob.ai_get_shaken(SHOCK_VALUE_SHAKEN_TIME, SHOCK_VALUE_FLINCH)
	TEST_ASSERT_EQUAL(mob.ai_stagger_until, 0, "A mob flinched again inside the flinch cooldown")

