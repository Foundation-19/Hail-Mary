/*
	Scoped to /obj/item/gun/ballistic only - energy weapons already have their own charge/overheat
	systems (see kinetic_accelerator.dm), and single-shot muzzleloaders (flintlock.dm) don't build
	sustained-fire heat the same way.

	Heat accumulates per round fired and decays in real time using the same catch-up pattern as
	living_recoil.dm's decay_recoil(). Above GUN_HEAT_JAM_THRESHOLD, each shot has a chance to jam
	the gun (requiring an interruptible do_after to clear). Above GUN_HEAT_COOKOFF_THRESHOLD, the
	chambered round can cook off on its own. Gun condition (0-100) degrades from jams/cook-offs and
	scales up jam chance as it drops; a wrench repair pass restores it.
*/

/obj/item/gun/ballistic/add_heat(amount)
	decay_heat()
	if(amount)
		gun_heat = min(gun_heat + (amount * heat_per_shot_mult), GUN_HEAT_MAX * heat_capacity_mult)

/// Settles accumulated heat back down based on real time elapsed, same catch-up approach as decay_recoil()
/obj/item/gun/ballistic/proc/decay_heat()
	if(!gun_heat)
		heat_last_update = world.time
		return
	var/steps = round((world.time - heat_last_update) / GUN_HEAT_DECAY_TICK)
	if(steps <= 0)
		return
	steps = min(steps, GUN_HEAT_DECAY_MAX_CATCHUP)
	for(var/i in 1 to steps)
		if(gun_heat <= GUN_HEAT_DECAY_FLAT)
			gun_heat = 0
			break
		gun_heat = (gun_heat - GUN_HEAT_DECAY_FLAT) * GUN_HEAT_DECAY_MULT
	heat_last_update = world.time

/// How much worse heat-driven jam chance gets as gun_condition drops below GUN_CONDITION_DEGRADED_THRESHOLD - up to 3x at 0 condition
/obj/item/gun/ballistic/proc/get_condition_jam_multiplier()
	if(gun_condition >= GUN_CONDITION_DEGRADED_THRESHOLD)
		return 1
	return 1 + ((GUN_CONDITION_DEGRADED_THRESHOLD - gun_condition) / GUN_CONDITION_DEGRADED_THRESHOLD) * 2

/obj/item/gun/ballistic/check_malfunction(mob/living/user)
	if(jammed)
		return TRUE
	if(pending_jam_next_shot)
		pending_jam_next_shot = FALSE
		become_jammed(user, "The rushed reload catches - [src] jams!")
		return TRUE
	var/luck_mult = user ? user.get_luck_gun_jam_multiplier() : 1
	var/eff_cookoff_threshold = GUN_HEAT_COOKOFF_THRESHOLD * heat_capacity_mult
	if(gun_heat > eff_cookoff_threshold && istype(chambered) && chambered.BB)
		if(prob((gun_heat - eff_cookoff_threshold) * GUN_HEAT_COOKOFF_CHANCE_PER_POINT * jam_chance_mult * luck_mult))
			cook_off(user)
			return TRUE
	var/eff_jam_threshold = GUN_HEAT_JAM_THRESHOLD * heat_capacity_mult
	if(gun_heat > eff_jam_threshold)
		var/perception_mult = user ? user.get_perception_gun_jam_multiplier() : 1
		var/chance = (gun_heat - eff_jam_threshold) * GUN_HEAT_JAM_CHANCE_PER_POINT * get_condition_jam_multiplier() * jam_chance_mult * luck_mult * perception_mult
		if(prob(chance))
			become_jammed(user)
			return TRUE
	return FALSE

/obj/item/gun/ballistic/proc/become_jammed(mob/living/user, custom_message)
	jammed = TRUE
	gun_condition = max(0, gun_condition - GUN_CONDITION_LOSS_JAM)
	if(user)
		user.visible_message(span_warning("[user]'s [src] jams!"), span_userdanger(custom_message || "[src] jams!"))
	do_sparks(1, FALSE, src)

/// A round cooking off from excess heat - vents the chambered round on its own, no aiming/targeting involved
/obj/item/gun/ballistic/proc/cook_off(mob/living/user)
	gun_condition = max(0, gun_condition - GUN_CONDITION_LOSS_COOKOFF)
	if(user)
		user.visible_message(span_userdanger("[src] cooks off in [user]'s hands!"), span_userdanger("[src] cooks off from the heat!"))
		if(prob(40))
			user.apply_damage(rand(2, 6) * user.get_strength_cookoff_burn_multiplier(), BURN, pick(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM))
	do_sparks(3, TRUE, src)
	if(chambered)
		eject_chambered_round(user, FALSE)
	gun_heat = GUN_HEAT_JAM_THRESHOLD * heat_capacity_mult // venting the round sheds a big chunk of the built-up heat
	update_icon()

/// Maintenance pass - wrenching a ballistic gun restores some condition
/obj/item/gun/ballistic/wrench_act(mob/living/user, obj/item/I)
	. = ..()
	if(gun_condition >= GUN_CONDITION_MAX)
		to_chat(user, span_notice("[src] is already in good condition."))
		return TRUE
	if(!I.use_tool(src, user, 40, volume = 50))
		return TRUE
	gun_condition = min(GUN_CONDITION_MAX, gun_condition + (GUN_CONDITION_REPAIR_AMOUNT * user.get_intelligence_gun_repair_multiplier()))
	to_chat(user, span_notice("You service [src], improving its condition."))
	return TRUE
