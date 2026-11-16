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
	normal.climate_temp_offset = -20
	intolerant.climate_temp_offset = -20

	TEST_ASSERT(normal.get_climate_target() < 0, "A freezing ambient did not produce cold exposure")
	TEST_ASSERT(intolerant.get_climate_target() < normal.get_climate_target(), "Cold Intolerant did not make cold exposure worse")

	normal.handle_climate()
	TEST_ASSERT(normal.climate_exposure < 0 && normal.bodytemperature < BODYTEMP_NORMAL, "Cold exposure did not chill the body")

	normal.climate_temp_offset = 0
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

/datum/unit_test/climate_wetness/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	victim.climate_temp_offset = -20
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

