// Power Attack system: hold your attack click to charge, pick which Power Attack is armed via
// alt-click's radial quick-select menu, release on a target to unleash the armed attack.
// See code/game/objects/items/melee/power_attack_system.dm for the item-side hold/charge/release logic.
GLOBAL_LIST_EMPTY(power_attack_data)

/// Returns the (cached, singleton) power attack datum for a typepath, or the instance itself if already one.
/proc/return_power_attack_datum(datum/power_attack/type_id_datum)
	if(istype(type_id_datum))
		return type_id_datum
	if(ispath(type_id_datum))
		. = GLOB.power_attack_data["[type_id_datum]"]
		if(!.)
			. = GLOB.power_attack_data["[type_id_datum]"] = new type_id_datum
	else
		return GLOB.power_attack_data["[type_id_datum]"]

/// A selectable "heavy swing" variant a melee weapon can perform when its charge is released.
/// Cached as a singleton per-type via return_power_attack_datum() - do not store per-item state on these.
/datum/power_attack
	/// Display name shown in the selection UI and chat feedback.
	var/name = "power attack"
	/// Flavor/mechanical description shown in the selection UI.
	var/desc = "A generic heavy strike."
	/// Icon file the quick-select radial menu pulls `radial_icon_state` from (defaults to the generic radial button icons).
	var/radial_icon = 'icons/mob/radial.dmi'
	/// Icon state shown for this attack in the Alt-click quick-select radial menu - scaled to 32x32 if `radial_icon` isn't already that size.
	var/radial_icon_state = "radial_use"
	/// Short (~3 letter) label overlaid on the radial icon - the reused VFX icons alone don't read clearly at a glance, so this is the primary way to tell slices apart without hovering for the tooltip.
	var/radial_label = "P.A."
	/// Deciseconds of holding required to fully charge this attack (scaled by the user's agility, see special_stats.dm).
	var/windup_time = 8
	/// Stamina deducted the moment charging begins. Partially refunded if the charge is released too early/cancelled.
	var/stamina_cost = 20
	/// Multiplier applied to the weapon's force on a successful release. See get_effective_damage_multiplier().
	var/damage_multiplier = 1.6
	/// Flat bonus armour penetration added for the duration of the release swing only.
	var/armor_pen_bonus = 0
	/// Flat bonus added to the weapon's wound_bonus for the duration of the release swing only.
	var/wound_bonus_add = 10
	/// If set, overrides the weapon's attack_verb list for this swing only.
	var/list/attack_verb_override

/// Whether `weapon` is even capable of performing this Power Attack right now (e.g. weapon class/sharpness gates).
/datum/power_attack/proc/can_select(mob/living/user, obj/item/weapon)
	return TRUE

/// Returns the damage multiplier actually applied on release. `fraction` is how charged the release was (0-1, see get_charge_scale()). Override for conditional payoffs (e.g. execute) or charge-scaled ones (e.g. heavy_strike).
/datum/power_attack/proc/get_effective_damage_multiplier(mob/living/user, obj/item/weapon, atom/target, fraction = 1)
	return damage_multiplier

/// Normalizes raw charge `fraction` onto a 0-1 scale spanning [POWER_ATTACK_MIN_CHARGE_FRACTION, 1] - 0 the instant a charge is barely releasable, 1 at full charge. Used to ramp a power attack's bonus payoff up from "basically a normal hit" to "full bonus" instead of granting it all the moment the charge becomes releasable.
/datum/power_attack/proc/get_charge_scale(fraction)
	return clamp((fraction - POWER_ATTACK_MIN_CHARGE_FRACTION) / (1 - POWER_ATTACK_MIN_CHARGE_FRACTION), 0, 1)

/datum/power_attack/proc/on_windup_start(mob/living/user, obj/item/weapon)
	return

/// Max tiles this attack will physically dash the user forward to close distance. 0 = melee-only, no dash (default).
/datum/power_attack/proc/get_lunge_range(obj/item/weapon)
	return 0

/// Called on release if the target isn't already adjacent (only possible when get_lunge_range() > 0) - move the user in.
/// Return TRUE if a failed approach was already fully handled (messaging/consequences) - skips the caller's generic "overextends" fallback.
/datum/power_attack/proc/on_approach(mob/living/user, obj/item/weapon, atom/target)
	return

/// Called roughly every POWER_ATTACK_TICK_RATE deciseconds while charging. fraction is 0-1 (1 = fully charged).
/datum/power_attack/proc/on_charge_tick(mob/living/user, obj/item/weapon, fraction)
	return

/// Called after the main attack_chain has been fired off, for any bespoke bonus effects. `fraction` is how charged the release was (0-1, see get_charge_scale()).
/datum/power_attack/proc/on_release(mob/living/user, obj/item/weapon, atom/target, fraction = 1)
	return

/datum/power_attack/proc/on_interrupted(mob/living/user, obj/item/weapon)
	return

/datum/power_attack/heavy_strike
	name = "Heavy Strike"
	desc = "A committed, straightforward blow. Deals bonus damage and armor penetration, scaling up the longer you hold the charge."
	windup_time = 6
	stamina_cost = 18
	damage_multiplier = 1.8
	armor_pen_bonus = 0.15
	wound_bonus_add = 15
	radial_icon = 'icons/obj/projectiles_impact.dmi'
	radial_icon_state = "impact_beam_heavy"
	radial_label = "HVY"

/// Barely-charged releases land as a plain hit; the full bonus only comes in at a full charge.
/datum/power_attack/heavy_strike/get_effective_damage_multiplier(mob/living/user, obj/item/weapon, atom/target, fraction = 1)
	return 1 + (damage_multiplier - 1) * get_charge_scale(fraction)

/datum/power_attack/cleave
	name = "Cleave"
	desc = "A wide, sweeping arc that also strikes every enemy adjacent to your target, at reduced effect. Needs an edged or heavy weapon."
	windup_time = 6
	stamina_cost = 26
	damage_multiplier = 1.0
	wound_bonus_add = 5
	radial_label = "CLV"
	/// Splash hits on bystanders (not your actual target) take this fraction of the main damage_multiplier - weaker than the direct hit, but not drastically so.
	var/cleave_splash_multiplier = 0.75

/datum/power_attack/cleave/can_select(mob/living/user, obj/item/weapon)
	return weapon.sharpness != SHARP_NONE || weapon.w_class >= WEIGHT_CLASS_BULKY

/datum/power_attack/cleave/on_release(mob/living/user, obj/item/weapon, atom/target, fraction = 1)
	if(!isturf(user.loc))
		return
	for(var/mob/living/bystander in orange(1, target))
		if(bystander == user || bystander == target || !user.Adjacent(bystander))
			continue
		user.do_attack_animation(bystander, null, weapon)
		weapon.melee_attack_chain(user, bystander, null, ATTACK_POWER_ATTACK | ATTACK_IGNORE_CLICKDELAY | NO_AUTO_CLICKDELAY_HANDLING, damage_multiplier * cleave_splash_multiplier)

/datum/power_attack/guard_break
	name = "Guard Break"
	desc = "Sacrifices raw damage to batter through blocks and parries, dealing heavy bonus stamina damage instead - the full tradeoff only kicks in at a full charge."
	windup_time = 5
	stamina_cost = 15
	damage_multiplier = 0.6
	wound_bonus_add = 0
	radial_label = "GRD"

/// Barely-charged releases land as a plain hit (no raw-damage sacrifice, no stamina bonus yet); the full tradeoff only comes in at a full charge.
/datum/power_attack/guard_break/get_effective_damage_multiplier(mob/living/user, obj/item/weapon, atom/target, fraction = 1)
	return 1 + (damage_multiplier - 1) * get_charge_scale(fraction)

/datum/power_attack/guard_break/on_release(mob/living/user, obj/item/weapon, atom/target, fraction = 1)
	if(isliving(target))
		var/mob/living/target_living = target
		target_living.adjustStaminaLoss(weapon.force * 0.8 * get_charge_scale(fraction))

/datum/power_attack/execute
	name = "Execute"
	desc = "A brutal finisher. Devastating bonus damage against staggered, stunned, or downed targets - a weak, telegraphed swing otherwise. Needs a full charge to show its full power either way."
	windup_time = 8
	stamina_cost = 22
	damage_multiplier = 1.1
	wound_bonus_add = 20
	radial_label = "EXE"

/datum/power_attack/execute/get_effective_damage_multiplier(mob/living/user, obj/item/weapon, atom/target, fraction = 1)
	var/base_multiplier = damage_multiplier * 0.5
	if(isliving(target))
		var/mob/living/target_living = target
		if(target_living.IsKnockdown() || target_living.IsStun() || target_living.restrained() || !CHECK_MOBILITY(target_living, MOBILITY_STAND))
			base_multiplier = damage_multiplier * 2.2
	return 1 + (base_multiplier - 1) * get_charge_scale(fraction)

/datum/power_attack/lunge
	name = "Lunge"
	desc = "A driving forward thrust that closes distance before striking - lighter weapons can lunge further than heavy ones. Needs a bladed or piercing weapon - overextending if you whiff leaves you staggered, and slamming into something solid mid-lunge knocks you down."
	windup_time = 5
	stamina_cost = 20
	damage_multiplier = 1.3
	armor_pen_bonus = 0.05
	wound_bonus_add = 5
	radial_label = "LNG"

/datum/power_attack/lunge/can_select(mob/living/user, obj/item/weapon)
	return weapon.sharpness != SHARP_NONE || istype(weapon, /obj/item/twohanded/spear)

/// Lighter weapons are easier to dash forward with, heavier ones still get a short hop - never zero. Value = actual tiles dashed, not target reach.
/datum/power_attack/lunge/get_lunge_range(obj/item/weapon)
	switch(weapon.w_class)
		if(WEIGHT_CLASS_TINY, WEIGHT_CLASS_SMALL)
			return 2
	return 1 // normal weight and up still get a 1-tile lunge

/// How much of the bonus damage a lunge keeps scales with how much of its max range it actually closed - see get_effective_damage_multiplier().
/datum/power_attack/lunge/get_effective_damage_multiplier(mob/living/user, obj/item/weapon, atom/target, fraction = 1)
	return 1 + (damage_multiplier - 1) * weapon.power_attack_lunge_fraction

/// Arms a powerfist-style worn glove weapon with Lunge despite being blunt - the piston-ram is its own kind of penetrating strike, bypassing the normal bladed/piercing requirement.
/datum/power_attack/lunge/piston_punch
	desc = "A driving forward thrust that closes distance before striking - the piston-ram punches through regardless of edge. Overextending if you whiff leaves you staggered, and slamming into something solid mid-lunge knocks you down."

/datum/power_attack/lunge/piston_punch/can_select(mob/living/user, obj/item/weapon)
	return TRUE

/datum/power_attack/lunge/on_approach(mob/living/user, obj/item/weapon, atom/target)
	// target.loc is an /area (not a turf) when target IS a bare turf (whiff fallback) - get_turf() handles both cases.
	var/turf/target_turf = get_turf(target)
	weapon.power_attack_lunge_fraction = 1
	if(!isturf(user.loc) || !target_turf)
		return
	var/approach_dir = get_dir(user, target_turf)
	var/max_steps = get_lunge_range(weapon)
	var/steps_taken = 0
	while(steps_taken < max_steps && !user.Adjacent(target_turf))
		var/turf/next_turf = get_step(user, approach_dir)
		if(!next_turf)
			break
		// Someone standing in your path (even if they weren't your intended target) is something you actually reach, not a wall - redirect the hit onto them instead of face-planting.
		for(var/mob/living/blocker in next_turf)
			if(blocker == user)
				continue
			weapon.power_attack_lunge_fraction = steps_taken / max_steps
			user.visible_message(span_danger("[user] lunges into [blocker]!"), span_userdanger("You lunge into [blocker]!"))
			playsound(user, 'sound/weapons/thudswoosh.ogg', 50, TRUE)
			return blocker
		if(!step(user, approach_dir))
			user.visible_message(span_danger("[user] slams into something and stumbles!"), span_userdanger("You slam into something solid and fall over!"))
			playsound(user, 'sound/effects/bang.ogg', 50, TRUE)
			user.Knockdown(40)
			user.adjustStaminaLoss(15)
			return TRUE
		steps_taken++
	// Reached your actual intended target (not a redirect) - full bonus regardless of how many steps it took to get there.
	weapon.power_attack_lunge_fraction = 1
	if(steps_taken)
		user.visible_message(span_danger("[user] lunges [isturf(target) ? "forward" : "at [target]"]!"), span_userdanger("You lunge [isturf(target) ? "forward" : "at [target]"]!"))
		playsound(user, 'sound/weapons/thudswoosh.ogg', 50, TRUE)
