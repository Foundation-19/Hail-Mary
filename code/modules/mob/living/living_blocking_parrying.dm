// yell at me later for file naming
// This file contains stuff relating to the new directional blocking and parry system.
GLOBAL_LIST_EMPTY(block_parry_data)

/proc/return_block_parry_datum(datum/block_parry_data/type_id_datum)
	if(istype(type_id_datum))
		return type_id_datum
	if(ispath(type_id_datum))
		. = GLOB.block_parry_data["[type_id_datum]"]
		if(!.)
			. = GLOB.block_parry_data["[type_id_datum]"] = new type_id_datum
	else		//text id
		return GLOB.block_parry_data["[type_id_datum]"]

/proc/set_block_parry_datum(id, datum/block_parry_data/data)
	if(ispath(id))
		CRASH("Path-fetching of block parry data is only to grab static data, do not attempt to modify global caches of paths. Use string IDs.")
	GLOB.block_parry_data["[id]"] = data

/// Carries data like list data that would be a waste of memory if we initialized the list on every /item as we can cache datums easier.
/datum/block_parry_data
	/////////// BLOCKING ////////////

	/// NOTE: FOR ATTACK_TYPE_DEFINE, you MUST wrap it in "[DEFINE_HERE]"! The defines are bitflags, and therefore, NUMBERS!

	/// See defines. Point of reference is someone facing north.
	var/can_block_directions = BLOCK_DIR_NORTH | BLOCK_DIR_NORTHEAST | BLOCK_DIR_NORTHWEST
	/// Attacks we can block
	var/can_block_attack_types = ALL
	/// Our slowdown added while blocking
	var/block_slowdown = 1
	/// Clickdelay added to user after block ends
	var/block_end_click_cd_add = 0
	/// Disallow attacking during block
	var/block_lock_attacking = TRUE
	/// Disallow sprinting during block
	var/block_lock_sprinting = FALSE
	/// The priority we get in [mob/do_run_block()] while we're being used to parry.
	var/block_active_priority = BLOCK_PRIORITY_ACTIVE_BLOCK
	/// Windup before we have our blocking active.
	var/block_start_delay = 5

	/// Amount of "free" damage blocking absorbs
	var/block_damage_absorption = 10
	/// Override absorption, list(ATTACK_TYPE_DEFINE_TEXT = absorption), see [block_damage_absorption]
	var/list/block_damage_absorption_override

	/// Ratio of damage to allow through above absorption and below limit. Multiplied by damage to determine how much to let through. Lower is better.
	var/block_damage_multiplier = 0.5
	/// Override damage overrun efficiency, list(ATTACK_TYPE_DEFINE_TEXT = absorption), see [block_damage_efficiency]
	var/list/block_damage_multiplier_override

	/// Upper bound of damage block, anything above this will go right through.
	var/block_damage_limit = 80
	/// Override upper bound of damage block, list(ATTACK_TYPE_DEFINE_TEXT = absorption), see [block_damage_limit]
	var/list/block_damage_limit_override

	/// The blocked variable of on_hit() on projectiles is impacted by this. Higher is better, 0 to 100, percentage.
	var/block_projectile_mitigation = 50

/*
 * NOTE: Overrides for attack types for most the block_stamina variables were removed,
 * because at the time of writing nothing needed to use it. Add them if you need it,
 * it should be pretty easy, just copy [active_block_damage_mitigation]
 * for how to override with list.
 */

	/// Default damage-to-stamina coefficient, higher is better. This is based on amount of damage BLOCKED, not initial damage, to prevent damage from "double dipping".
	var/block_stamina_efficiency = 3
	/// Override damage-to-stamina coefficient, see [block_efficiency], this should be list(ATTACK_TYPE_DEFINE_TEXT = coefficient_number)
	var/list/block_stamina_efficiency_override
	/// Ratio of stamina incurred by blocking that goes to the arm holding the object instead of the chest. Has no effect if this is not held in hand.
	var/block_stamina_limb_ratio = 0.5
	/// Ratio of stamina incurred by chest (so after [block_stamina_limb_ratio] runs) that is buffered.
	var/block_stamina_buffer_ratio = 1

	/// Stamina dealt directly via adjustStaminaLossBuffered() per SECOND of block.
	var/block_stamina_cost_per_second = 1.5

	/// Bitfield for attack types that we can block while down. This will work in any direction.
	var/block_resting_attack_types_anydir = ATTACK_TYPE_MELEE | ATTACK_TYPE_UNARMED | ATTACK_TYPE_TACKLE
	/// Bitfield for attack types that we can block while down but only in our normal directions.
	var/block_resting_attack_types_directional = ATTACK_TYPE_PROJECTILE | ATTACK_TYPE_THROWN
	/// Multiplier to stamina damage taken for attacks blocked while downed.
	var/block_resting_stamina_penalty_multiplier = 1.5
	/// Override list for multiplier to stamina damage taken for attacks blocked while down. list(ATTACK_TYPE_DEFINE_TEXT = multiplier_number)
	var/list/block_resting_stamina_penalty_multiplier_override

	/// Sounds for blocking
	var/list/block_sounds = list('sound/block_parry/block_metal1.ogg' = 1, 'sound/block_parry/block_metal1.ogg' = 1)

	/////////// PARRYING ////////////
	/// Prioriry for [mob/do_run_block()] while we're being used to parry.
	//  None - Parry is always highest priority!
	/// Parry doesn't work if you aren't able to otherwise attack due to clickdelay
	var/parry_respect_clickdelay = TRUE
	/// Parry stamina cost
	var/parry_stamina_cost = 5
	/// Attack types we can block
	var/parry_attack_types = ALL
	/// Parry flags
	var/parry_flags = PARRY_DEFAULT_HANDLE_FEEDBACK | PARRY_LOCK_ATTACKING

	/// Parry windup duration in deciseconds. 0 to this is windup, afterwards is main stage.
	var/parry_time_windup = 2
	/// Parry spindown duration in deciseconds. main stage end to this is the spindown stage, afterwards the parry fully ends.
	var/parry_time_spindown = 3
	/// Main parry window in deciseconds. This is between [parry_time_windup] and [parry_time_spindown]
	var/parry_time_active = 5
	// Visual overrides
	/// If set, overrides visual duration of windup
	var/parry_time_windup_visual_override
	/// If set, overrides visual duration of active period
	var/parry_time_active_visual_override
	/// If set, overrides visual duration of spindown
	var/parry_time_spindown_visual_override
	/// Perfect parry window in deciseconds from the start of the main window. 3 with main 5 = perfect on third decisecond of main window.
	var/parry_time_perfect = 2.5
	/// Time on both sides of perfect parry that still counts as part of the perfect window.
	var/parry_time_perfect_leeway = 1
	/// [parry_time_perfect_leeway] override for attack types, list(ATTACK_TYPE_DEFINE_TEXT = deciseconds)
	var/list/parry_time_perfect_leeway_override
	/// Parry "efficiency" falloff in percent per decisecond once perfect window is over.
	var/parry_imperfect_falloff_percent = 20
	/// [parry_imperfect_falloff_percent] override for attack types, list(ATTACK_TYPE_DEFINE_TEXT = deciseconds)
	var/list/parry_imperfect_falloff_percent_override
	/// Efficiency in percent on perfect parry.
	var/parry_efficiency_perfect = 120
	/// Override for attack types, list(ATTACK_TYPE_DEFINE_TEXT = perecntage) for perfect efficiency.
	var/parry_efficiency_perfect_override
	/// Parry effect data.
	var/list/parry_data = list(
		PARRY_COUNTERATTACK_MELEE_ATTACK_CHAIN = 1
		)
	/// Efficiency must be at least this to be considered successful
	var/parry_efficiency_considered_successful = 0.1
	/// Efficiency must be at least this to run automatic counterattack
	var/parry_efficiency_to_counterattack = 0.1
	/// Maximum attacks to parry successfully or unsuccessfully (but not efficiency < 0) during active period, hitting this immediately ends the sequence.
	var/parry_max_attacks = INFINITY
	/// Visual icon state override for parrying
	var/parry_effect_icon_state = "parry_bm_hold"
	/// Parrying cooldown, separate of clickdelay. It must be this much deciseconds since their last parry for them to parry with this object.
	var/parry_cooldown = 0
	/// Parry start sound
	var/parry_start_sound = 'sound/block_parry/sfx-parry.ogg'
	/// Sounds for parrying
	var/list/parry_sounds = list('sound/block_parry/block_metal1.ogg' = 1, 'sound/block_parry/block_metal1.ogg' = 1)
	/// Stagger duration post-parry if you fail to parry an attack
	var/parry_failed_stagger_duration = 3.5 SECONDS
	/// Clickdelay duration post-parry if you fail to parry an attack
	var/parry_failed_clickcd_duration = 2 SECONDS

/**
 * Quirky proc to get average of flags in list that are in attack_type because why is attack_type a flag.
 */
/datum/block_parry_data/proc/attack_type_list_scan(list/L, attack_type)
	var/total = 0
	var/div = 0
	for(var/flagtext in L)
		if(attack_type & text2num(flagtext))
			total += L[flagtext]
			div++
	// if none, return null.
	if(!div)
		return
	return total/div	//groan


/**
 * Gets the percentage efficiency of our parry.
 *
 * Returns a percentage in normal 0 to 100 scale, but not clamped to just 0 to 100.
 * This is a proc to allow for overriding.
 * @params
 * * attack_type - int, bitfield of the attack type(s)
 * * parry_time - deciseconds since start of the parry.
 */
/datum/block_parry_data/proc/get_parry_efficiency(attack_type, parry_time)
	var/difference = abs(parry_time - (parry_time_perfect + parry_time_windup))
	var/leeway = attack_type_list_scan(parry_time_perfect_leeway_override, attack_type)
	if(isnull(leeway))
		leeway = parry_time_perfect_leeway
	difference -= leeway
	var/perfect = attack_type_list_scan(parry_efficiency_perfect_override, attack_type)
	if(isnull(perfect))
		. = parry_efficiency_perfect
	else
		. = perfect
	if(difference <= 0)
		return
	var/falloff = attack_type_list_scan(parry_imperfect_falloff_percent_override, attack_type)
	if(isnull(falloff))
		falloff = parry_imperfect_falloff_percent
	. -= falloff * difference

#define RENDER_VARIABLE_SIMPLE(varname, desc) dat += "<tr><th>[#varname]<br><i>[desc]</i></th><th>[varname]</th></tr>"
#define RENDER_OVERRIDE_LIST(varname, desc) \
	dat += "<tr><th>[#varname]<br><i>[desc]</i></th><th>"; \
	var/list/assembled__##varname = list(); \
	for(var/textbit in varname){ \
		assembled__##varname += "[GLOB.attack_type_names[textbit]] = [varname[textbit]]"; \
	} \
	dat += "[english_list(assembled__##varname)]</th>";
#define RENDER_ATTACK_TYPES(varname, desc)	dat += "<tr><th>[#varname]<br><i>[desc]</i></th><th>"; \
	var/list/assembled__##varname = list(); \
	for(var/bit in bitfield2list(varname)){ \
		var/name = GLOB.attack_type_names[num2text(bit)]; \
		if(name){ \
			assembled__##varname += "[name]"; \
		} \
	} \
	dat += "[english_list(assembled__##varname)]</th>";
#define RENDER_BLOCK_DIRECTIONS(varname, desc) \
	dat += "<tr><th>[#varname]<br><i>[desc]</i></th><th>"; \
	var/list/assembled__##varname = list(); \
	for(var/bit in bitfield2list(varname)){ \
		var/name = GLOB.block_direction_names[num2text(bit)]; \
		if(name){ \
			assembled__##varname += "[name]"; \
		} \
	} \
	dat += "[english_list(assembled__##varname)]</th>";

/datum/block_parry_data/Topic(href, href_list)
	. = ..()
	if(.)
		return
	if(href_list["render"])
		// The link carries raw item flag values (0 when unset), and "0" is a truthy string, so convert them
		var/show_block = text2num(href_list["block"]) ? TRUE : FALSE
		var/show_parry = text2num(href_list["parry"]) ? TRUE : FALSE
		var/detailed = text2num(href_list["detail"]) ? TRUE : FALSE
		var/datum/browser/B = new(usr, REF(src), href_list["name"], detailed ? 800 : 520, detailed ? 1000 : 700)
		var/toggle_href = "?src=[REF(src)];name=[href_list["name"]];block=[show_block];parry=[show_parry];render=1;detail=[detailed ? 0 : 1]"
		var/toggle = "<a href='[toggle_href]'>\[[detailed ? "Show summary" : "Show technical details"]\]</a>"
		B.set_content("[toggle][render_html_readout(show_block, show_parry, detailed)]")
		B.open()

/**
 * Generates a HTML render of this datum for self-documentation.
 * Defaults to a short plain-language summary, detailed = TRUE gives the raw variable dump for coders.
 * Does NOT include the popout or title or anything.
 */
/datum/block_parry_data/proc/render_html_readout(block_data = FALSE, parry_data = FALSE, detailed = FALSE)
	if(!detailed)
		return render_summary_readout(block_data, parry_data)
	return render_technical_readout(block_data, parry_data)

/datum/block_parry_data/proc/render_technical_readout(block_data = FALSE, parry_data = FALSE)
	var/list/dat = list()
	if(block_data)
		dat += "<div class='statusDisplay'><h3>Block Stats</h3><table style='width:100%'><tr><th>Name/Description</th><th>Value</th></tr>"
		RENDER_BLOCK_DIRECTIONS(can_block_directions, "Which directions this can block in.")
		RENDER_ATTACK_TYPES(can_block_attack_types, "The kinds of attacks this can block.")
		RENDER_VARIABLE_SIMPLE(block_slowdown, "How much slowdown is applied to the user while blocking. Lower is better.")
		RENDER_VARIABLE_SIMPLE(block_end_click_cd_add, "How much click delay in deciseconds is applied to the user when blocking ends. Lower is better.")
		RENDER_VARIABLE_SIMPLE(block_lock_attacking, "Whether or not (1 or 0) the user is locked from atacking and/or item usage while blocking.")
		RENDER_VARIABLE_SIMPLE(block_active_priority, "The priority of this item in the block sequence. This will probably mean nothing to you unless you are a coder.")
		RENDER_VARIABLE_SIMPLE(block_start_delay, "The amount of time in deciseconds it takes to start a block with this item. Lower is better.")
		RENDER_VARIABLE_SIMPLE(block_damage_absorption, "The amount of damage that is absorbed by default. Higher is better.")
		RENDER_OVERRIDE_LIST(block_damage_absorption_override, "Overrides for the above for each attack type")
		RENDER_VARIABLE_SIMPLE(block_damage_multiplier, "Damage between absorption and limit is multiplied by this. Lower is better.")
		RENDER_OVERRIDE_LIST(block_damage_multiplier_override, "Overrides for the above for each attack type")
		RENDER_VARIABLE_SIMPLE(block_damage_limit, "Damage above this passes right through and is not impacted. Higher is better.")
		RENDER_OVERRIDE_LIST(block_damage_limit_override, "Overrides for the above for each attack type.")
		RENDER_VARIABLE_SIMPLE(block_stamina_efficiency, "Coefficient for stamina damage dealt to user by damage blocked. Higher is better.")
		RENDER_OVERRIDE_LIST(block_stamina_efficiency_override, "Overrides for the above for each attack type.")
		RENDER_VARIABLE_SIMPLE(block_stamina_limb_ratio, "The ratio of stamina that is applied to the limb holding this object (if applicable) rather than whole body/chest.")
		RENDER_VARIABLE_SIMPLE(block_stamina_buffer_ratio, "The ratio of stamina incurred by chest/whole body that is buffered rather than direct (buffer = your stamina buffer, direct = direct stamina damage like from a disabler.)")
		RENDER_VARIABLE_SIMPLE(block_stamina_cost_per_second, "The buffered stamina damage the user incurs per second of block. Lower is better.")
		RENDER_ATTACK_TYPES(block_resting_attack_types_anydir, "The kinds of attacks you can block while resting/otherwise knocked to the floor from any direction. can_block_attack_types takes precedence.")
		RENDER_ATTACK_TYPES(block_resting_attack_types_directional, "The kinds of attacks you can block wihle resting/otherwise knocked to the floor that are directional only. can_block_attack_types takes precedence.")
		RENDER_VARIABLE_SIMPLE(block_resting_stamina_penalty_multiplier, "Multiplier to stamina damage incurred from blocking while downed. Lower is better.")
		RENDER_OVERRIDE_LIST(block_resting_stamina_penalty_multiplier_override, "Overrides for the above for each attack type.")
		dat += "</div></table>"
	if(parry_data)
		dat += "<div class='statusDisplay'><h3>Parry Stats</h3><table style='width:100%'><tr><th>Name/Description</th><th>Value</th></tr>"
		RENDER_VARIABLE_SIMPLE(parry_respect_clickdelay, "Whether or not (1 or 0) you can only parry if your attack cooldown isn't in effect.")
		RENDER_VARIABLE_SIMPLE(parry_stamina_cost, "Buffered stamina damage incurred by you for parrying with this.")
		RENDER_ATTACK_TYPES(parry_attack_types, "Attack types you can parry.")
		// parry_flags
		dat += ""
		RENDER_VARIABLE_SIMPLE(parry_time_windup, "Deciseconds of parry windup.")
		RENDER_VARIABLE_SIMPLE(parry_time_spindown, "Deciseconds of parry spindown.")
		RENDER_VARIABLE_SIMPLE(parry_time_active, "Deciseconds of active parry window - This is the ONLY time your parry is active.")
		RENDER_VARIABLE_SIMPLE(parry_time_windup_visual_override, "Visual effect length override")
		RENDER_VARIABLE_SIMPLE(parry_time_spindown_visual_override, "Visual effect length override")
		RENDER_VARIABLE_SIMPLE(parry_time_active_visual_override, "Visual effect length override")
		RENDER_VARIABLE_SIMPLE(parry_time_perfect, "Deciseconds <b>into the active window</b> considered the 'center' of the perfect period.")
		RENDER_VARIABLE_SIMPLE(parry_time_perfect_leeway, "Leeway on both sides of the perfect period's center still considered perfect.")
		RENDER_OVERRIDE_LIST(parry_time_perfect_leeway_override, "Override for the above for each attack type")
		RENDER_VARIABLE_SIMPLE(parry_imperfect_falloff_percent, "Linear falloff in percent per decisecond for attacks parried outside of perfect window.")
		RENDER_OVERRIDE_LIST(parry_imperfect_falloff_percent_override, "Override for the above for each attack type")
		RENDER_VARIABLE_SIMPLE(parry_efficiency_perfect, "Efficiency in percentage a parry in the perfect window is considered.")
		RENDER_OVERRIDE_LIST(parry_efficiency_perfect_override, "Override for the above for each attack type")
		// parry_data
		dat += ""
		RENDER_VARIABLE_SIMPLE(parry_efficiency_considered_successful, "Minimum parry efficiency to be considered a successful parry.")
		RENDER_VARIABLE_SIMPLE(parry_efficiency_to_counterattack, "Minimum parry efficiency to trigger counterattack effects.")
		RENDER_VARIABLE_SIMPLE(parry_max_attacks, "Max attacks parried per parry cycle.")
		RENDER_VARIABLE_SIMPLE(parry_effect_icon_state, "Parry effect image name")
		RENDER_VARIABLE_SIMPLE(parry_cooldown, "Deciseconds it has to be since the last time a parry sequence <b>ended</b> for you before you can parry again.")
		RENDER_VARIABLE_SIMPLE(parry_failed_stagger_duration, "Deciseconds you are staggered for at the of the parry sequence if you do not successfully parry anything.")
		RENDER_VARIABLE_SIMPLE(parry_failed_clickcd_duration, "Deciseconds you are put on attack cooldown at the end of the parry sequence if you do not successfully parry anything.")
		dat += "</div></table>"
	return dat.Join("")
#undef RENDER_VARIABLE_SIMPLE
#undef RENDER_OVERRIDE_LIST
#undef RENDER_ATTACK_TYPES
#undef RENDER_BLOCK_DIRECTIONS

/// Deciseconds to a short seconds string, e.g. 5 -> "0.5s"
/datum/block_parry_data/proc/ds_text(deciseconds)
	return "[round(deciseconds / 10, 0.01)]s"

/datum/block_parry_data/proc/attack_types_text(flags)
	var/list/names = list()
	for(var/bit in bitfield2list(flags))
		var/name = GLOB.attack_type_names[num2text(bit)]
		if(name)
			names += name
	return english_list(names, "nothing")

/datum/block_parry_data/proc/block_directions_text(flags)
	var/list/names = list()
	for(var/bit in bitfield2list(flags))
		var/name = GLOB.block_direction_names[num2text(bit)]
		if(name)
			names += name
	return english_list(names, "nowhere")

/// Per attack type overrides as "Projectile 6, Melee 2", an empty string if there are none
/datum/block_parry_data/proc/override_text(list/overrides, suffix = "")
	if(!length(overrides))
		return ""
	var/list/parts = list()
	for(var/textbit in overrides)
		parts += "[GLOB.attack_type_names[textbit]] [overrides[textbit]][suffix]"
	return english_list(parts)

/// Damage that gets through a block, using the same steps as obj/item/active_block_calculate_final_damage
/datum/block_parry_data/proc/block_damage_taken(incoming, absorption, multiplier, limit)
	var/overrun = 0
	if(incoming > limit)
		overrun = incoming - limit
		incoming = limit
	incoming -= min(absorption, incoming)
	return overrun + incoming * multiplier

/// Parry time range, in deciseconds into the active window, where the parry is at least min_efficiency percent
/datum/block_parry_data/proc/parry_window_text(min_efficiency)
	if(parry_efficiency_perfect < min_efficiency)
		return "never"
	var/reach = parry_time_active
	if(parry_imperfect_falloff_percent > 0)
		reach = min(reach, parry_time_perfect_leeway + (parry_efficiency_perfect - min_efficiency) / parry_imperfect_falloff_percent)
	var/window_start = max(0, parry_time_perfect - reach)
	var/window_end = min(parry_time_active, parry_time_perfect + reach)
	return "[ds_text(window_start)] to [ds_text(window_end)]"

/datum/block_parry_data/proc/render_summary_readout(block_data = FALSE, parry_data = FALSE)
	var/list/dat = list()
	if(block_data)
		dat += "<div class='statusDisplay'><h3>Blocking</h3><table style='width:100%'>"
		dat += "<tr><td><b>Blocks</b></td><td>[attack_types_text(can_block_attack_types)]</td></tr>"
		dat += "<tr><td><b>From</b></td><td>[block_directions_text(can_block_directions)]</td></tr>"
		dat += "<tr><td><b>Raise time</b></td><td>[ds_text(block_start_delay)]</td></tr>"
		var/list/while_blocking = list()
		if(block_slowdown)
			while_blocking += "slows you by [block_slowdown]"
		while_blocking += block_lock_attacking ? "you cannot attack" : "you can still attack"
		if(block_lock_sprinting)
			while_blocking += "you cannot sprint"
		dat += "<tr><td><b>While blocking</b></td><td>[capitalize(english_list(while_blocking))]</td></tr>"
		if(block_end_click_cd_add)
			dat += "<tr><td><b>After lowering</b></td><td>[ds_text(block_end_click_cd_add)] attack delay</td></tr>"
		dat += "<tr><td><b>Upkeep</b></td><td>[block_stamina_cost_per_second] stamina per second</td></tr>"
		dat += "<tr><td><b>Absorbs</b></td><td>The first [block_damage_absorption] damage of a hit, then you take [round(block_damage_multiplier * 100)]% of the rest up to [block_damage_limit] damage. Anything past [block_damage_limit] goes straight through.</td></tr>"
		dat += "<tr><td><b>Stamina</b></td><td>Each blocked hit costs [block_stamina_efficiency ? round(1 / block_stamina_efficiency, 0.01) : "a lot of"] stamina per damage stopped, at most [BLOCK_STAMINA_COST_CAP] per hit.</td></tr>"
		dat += "<tr><td><b>While knocked down</b></td><td>Blocks [attack_types_text(block_resting_attack_types_anydir)] from any side and [attack_types_text(block_resting_attack_types_directional)] from the front, at [block_resting_stamina_penalty_multiplier]x the stamina cost.</td></tr>"
		var/list/exceptions = list()
		var/absorb_text = override_text(block_damage_absorption_override)
		if(absorb_text)
			exceptions += "absorbs [absorb_text]"
		var/limit_text = override_text(block_damage_limit_override)
		if(limit_text)
			exceptions += "damage limit [limit_text]"
		var/mult_text = override_text(block_damage_multiplier_override, "x")
		if(mult_text)
			exceptions += "damage taken [mult_text]"
		var/stamina_text = override_text(block_stamina_efficiency_override)
		if(stamina_text)
			exceptions += "stamina efficiency [stamina_text]"
		if(length(exceptions))
			dat += "<tr><td><b>Exceptions</b></td><td>[capitalize(jointext(exceptions, "; "))]</td></tr>"
		dat += "</table>"
		dat += "<br><b>Example hits</b> <i>(before armor, without the exceptions above)</i><table style='width:100%'><tr><th>Hit</th><th>You take</th><th>Stamina cost</th></tr>"
		for(var/hit in list(10, 25, 50, 100))
			var/taken = block_damage_taken(hit, block_damage_absorption, block_damage_multiplier, block_damage_limit)
			var/stamina = block_stamina_efficiency ? min((hit - taken) / block_stamina_efficiency, BLOCK_STAMINA_COST_CAP) : BLOCK_STAMINA_COST_CAP
			dat += "<tr><td>[hit]</td><td>[round(taken, 0.1)]</td><td>[round(stamina, 0.1)]</td></tr>"
		dat += "</table></div>"
	if(parry_data)
		dat += "<div class='statusDisplay'><h3>Parrying</h3><table style='width:100%'>"
		dat += "<tr><td><b>Parries</b></td><td>[attack_types_text(parry_attack_types)]</td></tr>"
		dat += "<tr><td><b>Timing</b></td><td>[ds_text(parry_time_windup)] windup, then [ds_text(parry_time_active)] active, then [ds_text(parry_time_spindown)] recovery. Only the active part parries.</td></tr>"
		dat += "<tr><td><b>Perfect parry</b></td><td>[parry_window_text(parry_efficiency_perfect)] into the active part, worth [parry_efficiency_perfect]%. It loses [parry_imperfect_falloff_percent]% for every 0.1s outside that.</td></tr>"
		dat += "<tr><td><b>Counts as a parry</b></td><td>[parry_window_text(parry_efficiency_considered_successful)] into the active part (at least [parry_efficiency_considered_successful]%)</td></tr>"
		dat += "<tr><td><b>Counterattack</b></td><td>[parry_window_text(parry_efficiency_to_counterattack)] into the active part (at least [parry_efficiency_to_counterattack]%)</td></tr>"
		dat += "<tr><td><b>Attacks per parry</b></td><td>[parry_max_attacks >= 1e30 ? "Unlimited" : parry_max_attacks]</td></tr>"
		dat += "<tr><td><b>Cost</b></td><td>[parry_stamina_cost] stamina[parry_cooldown ? ", [ds_text(parry_cooldown)] cooldown" : ""][parry_respect_clickdelay ? ", only usable when your attack delay is ready" : ""]</td></tr>"
		dat += "<tr><td><b>If you whiff</b></td><td>Staggered for [ds_text(parry_failed_stagger_duration)] and unable to attack for [ds_text(parry_failed_clickcd_duration)]</td></tr>"
		var/list/parry_exceptions = list()
		var/leeway_text = override_text(parry_time_perfect_leeway_override, "ds")
		if(leeway_text)
			parry_exceptions += "perfect window leeway [leeway_text]"
		var/falloff_text = override_text(parry_imperfect_falloff_percent_override, "%")
		if(falloff_text)
			parry_exceptions += "falloff [falloff_text]"
		var/perfect_text = override_text(parry_efficiency_perfect_override, "%")
		if(perfect_text)
			parry_exceptions += "perfect efficiency [perfect_text]"
		if(length(parry_exceptions))
			dat += "<tr><td><b>Exceptions</b></td><td>[capitalize(jointext(parry_exceptions, "; "))]</td></tr>"
		dat += "</table></div>"
	return dat.Join("")

// MOB PROCS

/**
 * Called every life tick to handle blocking/parrying effects.
 */
/mob/living/proc/handle_block_parry(seconds = 1)
	if(combat_flags & COMBAT_FLAG_ACTIVE_BLOCKING)
		var/datum/block_parry_data/data = active_block_unarmed ? get_active_block_data() : active_block_item.get_block_parry_data()
		adjustStaminaLossBuffered(data.block_stamina_cost_per_second * seconds)

/mob/living/on_item_dropped(obj/item/I)
	if(I == active_block_item)
		stop_active_blocking()
	if(I == active_parry_item)
		end_parry_sequence()
	return ..()
