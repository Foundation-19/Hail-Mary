// Power Attack system - item side.
// Hold right click (onMouseDown) while wielding an ITEM_CAN_POWER_ATTACK weapon to charge the currently
// armed /datum/power_attack, then release (onMouseUp) to unleash it, hitting whatever's under the cursor
// or, lacking that, whatever's directly ahead of you - a target under the cursor is never required. Bound
// to right click specifically so charging/releasing never eats or delays normal left-click attacks. Which
// Power Attack is armed is chosen via Alt+Left-click or Alt+Right-click, both opening a radial quick-select
// menu (see power_attack_radial_select()/power_attack_handle_right_mouse_down()), styled the same way as
// other machines' radial pickers (e.g. the reagent grinder's juice/grind buttons).
//
// Wired up on /obj/item/melee and /obj/item/twohanded (the two melee weapon base hierarchies) so every
// melee weapon in the game gets this for free. Getting hit while charging interrupts the swing via
// COMSIG_MOB_APPLY_DAMAGE; SPECIAL stats (see code/modules/mob/special_stats.dm) scale windup speed,
// interrupt stagger duration, fumble chance, power attack stamina cost, and base swing speed.

/datum/movespeed_modifier/power_attack_windup
	multiplicative_slowdown = 2
	blacklisted_movetypes = (FLYING|FLOATING)

/// A heavier, more exaggerated version of do_attack_animation()'s lean, to sell the weight of a released Power Attack.
/// Bigger offset and a much slower recoil than the base lean (which chains right after this for real hits) so it reads
/// as distinctly heavier instead of blending into the ordinary attack animation.
/mob/living/proc/do_power_attack_nudge(atom/target)
	if(target == src || !isturf(loc))
		return
	var/pixel_x_diff = 0
	var/pixel_y_diff = 0
	// Target can resolve to the tile we're already standing on (blocked lunge) - fall back to facing so we still visibly commit.
	var/direction = get_dir(src, target) || dir
	if(direction & NORTH)
		pixel_y_diff = 16
	else if(direction & SOUTH)
		pixel_y_diff = -16
	if(direction & EAST)
		pixel_x_diff = 16
	else if(direction & WEST)
		pixel_x_diff = -16

	var/matrix/OM = matrix(transform)
	var/matrix/M = matrix(transform)
	M.Turn(pixel_x_diff ? pixel_x_diff*1.5 : pick(-30, 30))

	animate(src, pixel_x = pixel_x + pixel_x_diff, pixel_y = pixel_y + pixel_y_diff, transform = M, time = 2)
	animate(src, pixel_x = pixel_x - pixel_x_diff, pixel_y = pixel_y - pixel_y_diff, transform = OM, time = 6)

/obj/item
	/// List of /datum/power_attack typepaths this weapon can perform. Set on /obj/item/melee and /obj/item/twohanded base types.
	var/list/power_attacks
	/// Currently armed power attack typepath - persists between swings, changed via the alt-click radial quick-select menu.
	var/active_power_attack_path
	/// Are we currently charging a power attack?
	var/charging_power_attack = FALSE
	/// Has the current charge reached full windup? (Used only to avoid spamming the "fully charged" message.)
	var/power_attack_fully_charged = FALSE
	/// world.time the current charge began.
	var/power_attack_charge_start = 0
	/// The mob currently charging us. Also used to detect/ignore stale charge loops.
	var/mob/living/power_attack_user
	/// Stamina actually deducted at power_attack_begin() (post-Strength scaling) - cached so an early-release refund matches what was really paid.
	var/power_attack_stamina_paid = 0
	/// The floating do_after-style bar shown over the user while charging, filling up toward full windup.
	var/datum/progressbar/power_attack_progressbar
	/// 0-1 scalar set by /datum/power_attack/lunge/on_approach() - how much of its max range the lunge actually closed before connecting. Redirects onto a blocker you barely moved to reach get a reduced bonus.
	var/power_attack_lunge_fraction = 1

/// A worn glove_weapon (e.g. a power fist) counts as "wielded" for Power Attack purposes too, not just actually held in a hand -
/// lets the glove_power_attack keybinding charge/release it while worn, since it has no hand screen object to right-click.
/obj/item/proc/is_power_attack_wielded(mob/living/user)
	return user.is_holding(src) || is_active_glove_weapon(user)

/// Returns (and lazily defaults) the currently armed power attack datum, or null if this item has none set up.
/obj/item/proc/get_active_power_attack()
	if(!LAZYLEN(power_attacks))
		return null
	if(!active_power_attack_path || !(active_power_attack_path in power_attacks))
		active_power_attack_path = power_attacks[1]
	return return_power_attack_datum(active_power_attack_path)

/// Shared right-mouse-down handler for melee/twohanded items: Alt+RMB opens the radial quick-select menu (an alternative to Alt+LMB), plain RMB begins charging.
/obj/item/proc/power_attack_handle_right_mouse_down(mob/living/user, params)
	if(params2list(params)["alt"])
		if(LAZYLEN(power_attacks) && (item_flags & ITEM_CAN_POWER_ATTACK) && (user.Adjacent(src) || (src in user.contents)))
			power_attack_radial_select(user)
		return
	power_attack_begin(user)

/obj/item/proc/power_attack_begin(mob/living/user)
	if(!istype(user) || !(item_flags & ITEM_CAN_POWER_ATTACK) || charging_power_attack)
		return
	if(!is_power_attack_wielded(user) || !CHECK_MOBILITY(user, MOBILITY_USE))
		return
	var/datum/power_attack/power_attack = get_active_power_attack()
	if(!power_attack)
		return
	if(user.alpha < 100) // Heavily cloaked (stealth boy, ninja suit, cloak of darkness, etc) - same threshold the rest of the codebase uses to mean "stealthed". Charging would both reveal the windup and let the stealth attack bonus stack with the power attack multiplier.
		to_chat(user, span_warning("You can't focus on a Power Attack while cloaked!"))
		return
	if(!power_attack.can_select(user, src))
		to_chat(user, span_warning("[src] can't perform a [power_attack.name] right now!"))
		return
	charging_power_attack = TRUE
	power_attack_fully_charged = FALSE
	power_attack_charge_start = world.time
	power_attack_user = user
	power_attack_stamina_paid = power_attack.stamina_cost * user.get_strength_power_attack_stamina_multiplier()
	user.adjustStaminaLoss(power_attack_stamina_paid)
	user.add_movespeed_modifier(/datum/movespeed_modifier/power_attack_windup)
	RegisterSignal(user, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(power_attack_on_damaged))
	power_attack.on_windup_start(user, src)
	to_chat(user, span_danger("You begin winding up a [power_attack.name] with [src]..."))
	power_attack_progressbar = new(user, power_attack_get_required_windup(user, power_attack), user)
	INVOKE_ASYNC(src, PROC_REF(power_attack_charge_loop), user, power_attack)

/obj/item/proc/power_attack_get_required_windup(mob/living/user, datum/power_attack/power_attack)
	var/mult = isliving(user) ? user.get_power_attack_windup_multiplier() : 1
	return max(2, power_attack.windup_time * mult)

/obj/item/proc/power_attack_charge_loop(mob/living/user, datum/power_attack/power_attack)
	var/required = power_attack_get_required_windup(user, power_attack)
	while(charging_power_attack && power_attack_user == user)
		if(QDELETED(src) || QDELETED(user) || !is_power_attack_wielded(user) || user.incapacitated())
			power_attack_cancel(user, "cut short")
			return
		var/fraction = (world.time - power_attack_charge_start) / required
		power_attack.on_charge_tick(user, src, min(fraction, 1))
		power_attack_progressbar?.update(world.time - power_attack_charge_start)
		if(fraction >= 1 && !power_attack_fully_charged)
			power_attack_fully_charged = TRUE
			to_chat(user, span_boldnotice("Your [power_attack.name] is fully charged - release to strike!"))
		stoplag(POWER_ATTACK_TICK_RATE)

/obj/item/proc/power_attack_on_damaged(mob/living/user, damage, damagetype)
	SIGNAL_HANDLER
	if(!charging_power_attack || damagetype == STAMINA || damage <= 0)
		return
	power_attack_cancel(user, "interrupted", TRUE)

/obj/item/proc/power_attack_cancel(mob/living/user, reason, stagger_user = FALSE)
	if(!charging_power_attack)
		return
	charging_power_attack = FALSE
	power_attack_fully_charged = FALSE
	power_attack_user = null
	power_attack_progressbar?.end_progress()
	power_attack_progressbar = null
	if(!user)
		return
	UnregisterSignal(user, COMSIG_MOB_APPLY_DAMAGE)
	user.remove_movespeed_modifier(/datum/movespeed_modifier/power_attack_windup)
	var/datum/power_attack/power_attack = get_active_power_attack()
	power_attack?.on_interrupted(user, src)
	to_chat(user, span_warning("Your power attack is [reason]!"))
	if(stagger_user)
		user.Stagger(user.get_power_attack_interrupt_stagger_duration())

/// Bare floor/wall clicks land on the click_catcher screen overlay instead of a real turf - resolve the real atom so releasing over empty ground still works.
/obj/item/proc/power_attack_resolve_target(mob/living/user, atom/hovered, params)
	if(!istype(hovered, /obj/screen) || !user.client)
		return hovered
	var/list/modifiers = params2list(params)
	return params2turf(modifiers["screen-loc"], get_turf(user.client.eye || user), user.client)

/obj/item/proc/power_attack_release(mob/living/user, atom/target, params)
	if(!charging_power_attack || power_attack_user != user)
		return
	var/datum/power_attack/power_attack = get_active_power_attack()
	var/required = power_attack_get_required_windup(user, power_attack)
	var/fraction = (world.time - power_attack_charge_start) / required

	charging_power_attack = FALSE
	power_attack_fully_charged = FALSE
	power_attack_user = null
	power_attack_progressbar?.end_progress()
	power_attack_progressbar = null
	UnregisterSignal(user, COMSIG_MOB_APPLY_DAMAGE)
	user.remove_movespeed_modifier(/datum/movespeed_modifier/power_attack_windup)

	if(fraction < POWER_ATTACK_MIN_CHARGE_FRACTION)
		user.adjustStaminaLoss(-(power_attack_stamina_paid * POWER_ATTACK_CANCEL_REFUND))
		to_chat(user, span_warning("You ease off your [power_attack.name] early."))
		return

	if(!isturf(user.loc))
		to_chat(user, span_warning("You have nothing to release your [power_attack.name] into!"))
		return

	// Only a genuine mob/object under the cursor (not bare ground, and within reach - the attack's dash range plus the final adjacent tile) earns the full payoff below.
	var/lunge_reach = power_attack.get_lunge_range(src) + 1
	var/atom/real_target = (istype(target) && !isturf(target)) ? target : null
	// A click near (but not pixel-exactly on) a mob at range resolves through the click_catcher overlay to a bare turf instead of the mob itself
	// (see power_attack_resolve_target()) - a living mob is still genuinely standing right there, so promote it instead of conceding a guaranteed whiff.
	if(!real_target && isturf(target))
		for(var/mob/living/potential in target)
			if(potential == user)
				continue
			real_target = potential
			break
	var/has_real_target = real_target && get_dist(user, real_target) <= lunge_reach

	// No (or an out-of-range) target under the cursor - still let the charge release as a swing/lunge at whatever's ahead of/under you, instead of wasting it.
	// Pick a fallback tile at this attack's full reach (not just the adjacent tile) so Lunge still actually dashes you forward on a whiff.
	// Aim at the real target's tile (not just our current facing) when it exists, so an out-of-reach dash still closes the gap in the right direction.
	if(!has_real_target)
		var/turf/fallback_turf = (real_target && get_turf(real_target)) || get_ranged_target_turf(user, user.dir, lunge_reach) || get_turf(user)
		// Cursor/click resolution can still lose track of a real target genuinely standing along the path we're about to swing/lunge through
		// (e.g. a near-miss click, or an out-of-range hover) - scan for one before conceding a guaranteed whiff, same as the fallback_turf itself.
		var/turf/scan_turf = get_turf(user)
		for(var/i in 1 to lunge_reach)
			scan_turf = get_step(scan_turf, get_dir(user, fallback_turf))
			if(!scan_turf)
				break
			for(var/mob/living/potential in scan_turf)
				if(potential == user)
					continue
				real_target = potential
				has_real_target = TRUE
				break
			if(has_real_target)
				break
		target = has_real_target ? real_target : fallback_turf

	if(!user.Adjacent(target))
		var/approach_handled = power_attack.on_approach(user, src, target)
		// on_approach can return an atom (e.g. something blocking the path) instead of TRUE/FALSE - redirect the hit onto it as a genuine target.
		if(isatom(approach_handled))
			target = approach_handled
			has_real_target = TRUE
		if(!user.Adjacent(target))
			if(!approach_handled)
				user.visible_message(span_warning("[user] overextends and fails to close the distance!"), span_warning("You overextend and fail to close the distance!"))
				user.Stagger(1 SECONDS)
			return

	// The dash still closed the gap onto the real target despite starting out of initial reach (e.g. it moved toward you too) - don't force a guaranteed whiff onto empty ground.
	if(!has_real_target && real_target && user.Adjacent(real_target))
		target = real_target
		has_real_target = TRUE

	if(prob(user.get_power_attack_fumble_chance()))
		user.visible_message(span_danger("[user] fumbles [power_attack.name] with [src]!"), span_userdanger("You fumble your [power_attack.name]!"))
		user.Stagger(1 SECONDS)
		return

	user.do_power_attack_nudge(target)
	// Base item attack() only animates on a real mob hit - whiffs (bare turf target) otherwise show nothing but chat text, so show the weapon swing ourselves here instead.
	user.do_attack_animation(target, null, src)
	playsound(user, 'sound/weapons/thudswoosh.ogg', 50, TRUE)

	// Whiffed - the swing/lunge still actually happens (real attack chain, full animation/sound) against whatever's ahead of you,
	// you just get none of the power attack's bonus payoff, and eat a stagger for overcommitting into nothing.
	if(!has_real_target)
		melee_attack_chain(user, target, params, ATTACK_POWER_ATTACK, 1)
		user.visible_message(span_warning("[user] commits to a [power_attack.name] with [src], hitting nothing but air!"), span_warning("You commit to your [power_attack.name], striking nothing but air!"))
		user.Stagger(0.5 SECONDS)
		return

	var/old_wound_bonus = wound_bonus
	var/old_armour_pen = armour_penetration
	var/old_verb = attack_verb
	wound_bonus += power_attack.wound_bonus_add
	armour_penetration += power_attack.armor_pen_bonus
	if(power_attack.attack_verb_override)
		attack_verb = power_attack.attack_verb_override

	var/effective_multiplier = power_attack.get_effective_damage_multiplier(user, src, target, min(fraction, 1))
	melee_attack_chain(user, target, params, ATTACK_POWER_ATTACK, effective_multiplier)
	power_attack.on_release(user, src, target, min(fraction, 1))

	wound_bonus = old_wound_bonus
	armour_penetration = old_armour_pen
	attack_verb = old_verb

/// Alt-click/Alt-RMB quick-select radial menu for which Power Attack is armed - same style/flow as other machines'
/// radial pickers (e.g. the reagent grinder's juice/grind buttons): only currently-selectable attacks are offered.
/obj/item/proc/power_attack_radial_select(mob/living/user)
	if(!istype(user) || !LAZYLEN(power_attacks) || !(item_flags & ITEM_CAN_POWER_ATTACK))
		return
	var/list/options = list()
	var/list/option_paths = list()
	for(var/path in power_attacks)
		var/datum/power_attack/power_attack = return_power_attack_datum(path)
		if(!power_attack.can_select(user, src))
			continue
		var/label = "[power_attack.name][path == active_power_attack_path ? " (armed)" : ""]"
		var/image/option_icon = image(icon = null)
		// Plain text label (no icon art) - a 3-letter code is clearer here than the available generic/VFX icon options.
		option_icon.maptext = "<div align='center' valign='middle' style='width:32px;height:32px;'><font color='white' size='2'><b>[power_attack.radial_label]</b></font></div>"
		option_icon.maptext_x = 0
		option_icon.maptext_y = 0
		option_icon.maptext_width = 32
		option_icon.maptext_height = 32
		options[label] = option_icon
		option_paths[label] = path
	if(!length(options))
		to_chat(user, span_warning("[src] has no Power Attacks available right now!"))
		return
	var/choice = show_radial_menu(user, src, options, require_near = TRUE, tooltips = TRUE)
	var/picked = option_paths[choice]
	if(!picked)
		return
	active_power_attack_path = picked
	var/datum/power_attack/picked_attack = return_power_attack_datum(picked)
	to_chat(user, span_notice("You ready [src] to perform a [picked_attack.name] on your next power attack."))

/// A transient stand-in weapon for bare-handed Power Attacks - see /datum/component/unarmed_power_attack.
/// HAND_ITEM/ABSTRACT/DROPDEL like code/game/objects/hand_items.dm's /obj/item/hand_item, but parented to
/// /obj/item/melee instead so it gets the mouse-hold charge/release wiring and radial quick-select menu for free.
/obj/item/melee/fists
	name = "your fists"
	desc = "Your bare hands, raised to fight."
	icon = null
	icon_state = null
	force = 3
	w_class = WEIGHT_CLASS_SMALL
	attack_verb = list("punched")
	item_flags = ITEM_CAN_POWER_ATTACK | ABSTRACT | DROPDEL | HAND_ITEM
	block_parry_data = null

/obj/item/melee/onMouseDown(object, location, params, mob/living/user)
	if(istype(object, /obj/screen) && !istype(object, /obj/screen/click_catcher))
		return ..()
	if(!istype(user) || (object in user.contents) || object == user || !params2list(params)["right"])
		return ..()
	power_attack_handle_right_mouse_down(user, params)
	return ..()

/obj/item/melee/get_attack_speed_multiplier(mob/living/user)
	return isliving(user) ? user.get_agility_melee_speed_multiplier() : 1

/obj/item/melee/onMouseUp(object, location, params, mob/living/user)
	if(istype(user) && params2list(params)["right"])
		power_attack_release(user, power_attack_resolve_target(user, user.client?.mouseObject, params), params)
	return ..()

// Right click is spoken for by the power attack charge/release above - don't also throw an instant right-click attack.
/obj/item/melee/alt_pre_attack(atom/A, mob/living/user, params)
	if(LAZYLEN(power_attacks) && (item_flags & ITEM_CAN_POWER_ATTACK))
		return TRUE
	return ..()

/obj/item/melee/AltClick(mob/user)
	. = ..()
	if(LAZYLEN(power_attacks) && (item_flags & ITEM_CAN_POWER_ATTACK) && (user.Adjacent(src) || (src in user.contents)))
		power_attack_radial_select(user)

/obj/item/twohanded/onMouseDown(object, location, params, mob/living/user)
	if(istype(object, /obj/screen) && !istype(object, /obj/screen/click_catcher))
		return ..()
	if(!istype(user) || (object in user.contents) || object == user || !params2list(params)["right"])
		return ..()
	power_attack_handle_right_mouse_down(user, params)
	return ..()

/obj/item/twohanded/get_attack_speed_multiplier(mob/living/user)
	return isliving(user) ? user.get_agility_melee_speed_multiplier() : 1

/obj/item/twohanded/onMouseUp(object, location, params, mob/living/user)
	if(istype(user) && params2list(params)["right"])
		power_attack_release(user, power_attack_resolve_target(user, user.client?.mouseObject, params), params)
	return ..()

// Right click is spoken for by the power attack charge/release above - don't also throw an instant right-click attack.
/obj/item/twohanded/alt_pre_attack(atom/A, mob/living/user, params)
	if(LAZYLEN(power_attacks) && (item_flags & ITEM_CAN_POWER_ATTACK))
		return TRUE
	return ..()

/obj/item/twohanded/AltClick(mob/user)
	. = ..()
	if(LAZYLEN(power_attacks) && (item_flags & ITEM_CAN_POWER_ATTACK) && (user.Adjacent(src) || (src in user.contents)))
		power_attack_radial_select(user)
