/obj/item/robot_module
	name = "Default"
	icon = 'icons/obj/module.dmi'
	icon_state = "std_mod"
	w_class = WEIGHT_CLASS_GIGANTIC
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	flags_1 = CONDUCT_1

	var/borghealth = 100

	var/list/basic_modules = list() //a list of paths, converted to a list of instances on New()
	var/list/emag_modules = list() //ditto
	var/list/ratvar_modules = list() //ditto ditto
	var/list/modules = list() //holds all the usable modules
	var/list/added_modules = list() //modules not inherient to the robot module, are kept when the module changes
	var/list/storages = list()

	var/cyborg_base_icon = "robot" //produces the icon for the borg and, if no special_light_key is set, the lights
	/// DMI file used by update_icons() for this module type. Set per-module subtype.
	var/cyborg_icon_file = 'icons/mob/robots.dmi'
	/// Icon state to use for eye-light overlay. Null = no eye overlay.
	/// F13 modules set this to the "eyes-name" state; vanilla modules use "name_e".
	var/cyborg_eye_state = null
	/// Whether this module has ov-opencover states in its dmi. FALSE for F13 modules.
	var/has_cover_overlay = TRUE
	var/special_light_key //if we want specific lights, use this instead of copying lights in the dmi

	var/moduleselect_icon = "nomod"

	var/can_be_pushed = FALSE
	var/magpulsing = FALSE
	var/clean_on_move = FALSE

	var/did_feedback = FALSE

	var/hat_offset = -3

	var/list/ride_offset_x = list("north" = 0, "south" = 0, "east" = -6, "west" = 6)
	var/list/ride_offset_y = list("north" = 4, "south" = 4, "east" = 3, "west" = 3)
	var/ride_allow_incapacitated = FALSE
	var/allow_riding = TRUE
	var/canDispose = FALSE // Whether the borg can stuff itself into disposal

	var/sleeper_overlay
	var/icon/cyborg_icon_override
	var/has_snowflake_deadsprite
	var/moduleselect_alternate_icon

	/// Bitfield of ROBOT_ROLE_* tags. Must share at least one tag with the chassis
	/// design's chassis_tags for the build to pass validation at Finalize.
	/// Default ROBOT_ROLE_ANY means the module fits all chassis.
	var/module_tags = ROBOT_ROLE_ANY
	/// Short description shown in the workshop loadout header and robot config panel.
	var/module_desc = ""
	/// Item type paths that can be ADDED to this module via the workshop's "Add Item" section.
	/// These are not instantiated here — they are appended as new instances at build time
	/// only if the player explicitly toggles them on in the Hardware tab's module loadout panel.
	var/list/loadout_extras = list()

	// ---- Personality system ----
	/// Display name for this personality archetype.
	var/personality_name = ""
	/// Random lines said aloud at irregular intervals when the robot has no player and is idle.
	var/list/idle_quips = list()
	/// Lines said when a conscious mob enters close proximity (4-tile radius, 15s cooldown).
	var/list/greet_lines = list()
	/// Lines said shortly after the robot takes damage (70% chance, 20s cooldown).
	var/list/combat_taunts = list()
	/// Lines said when the robot dies.
	var/list/death_lines = list()
	// Internal timing vars — not meant to be overridden per-subtype.
	var/perso_idle_last = 0
	var/perso_greet_last = 0
	var/perso_greet_check_last = 0
	var/perso_combat_last = 0
	/// Weakref list of mobs already greeted this encounter. Pruned when they leave range.
	var/list/greeted_refs = null
	/// Weakref to the host robot, stored at Initialize() for death signal unregistration.
	var/datum/weakref/personality_host_ref = null

/obj/item/robot_module/Initialize()
	. = ..()
	for(var/i in basic_modules)
		var/obj/item/I = new i(src)
		basic_modules += I
		basic_modules -= i
	for(var/i in emag_modules)
		var/obj/item/I = new i(src)
		emag_modules += I
		emag_modules -= i
	// Start ambient personality processing only when placed inside a live robot chassis.
	// Guard against null/non-robot loc so dummy modules created for UI previews don't
	// get registered with SSobj unnecessarily.
	var/mob/living/silicon/robot/Rhost = loc
	if(istype(Rhost))
		if(idle_quips.len || greet_lines.len || combat_taunts.len)
			START_PROCESSING(SSobj, src)
		if(death_lines.len)
			personality_host_ref = WEAKREF(Rhost)
			RegisterSignal(Rhost, COMSIG_MOB_DEATH, PROC_REF(_personality_death))

// Ensure module properly clears robot reference
/obj/item/robot_module/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(personality_host_ref)
		var/mob/living/silicon/robot/Rhost = personality_host_ref.resolve()
		if(Rhost && !QDELETED(Rhost))
			UnregisterSignal(Rhost, COMSIG_MOB_DEATH)
		personality_host_ref = null
	basic_modules.Cut()
	emag_modules.Cut()
	ratvar_modules.Cut()
	modules.Cut()
	added_modules.Cut()
	storages.Cut()
	return ..()

/obj/item/robot_module/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_CONTENTS)
		return
	for(var/obj/O in modules)
		O.emp_act(severity)
	..()

/obj/item/robot_module/proc/get_usable_modules()
	. = modules.Copy()

/obj/item/robot_module/proc/get_inactive_modules()
	. = list()
	var/mob/living/silicon/robot/R = loc
	for(var/m in get_usable_modules())
		if(!(m in R.held_items))
			. += m

/obj/item/robot_module/proc/get_or_create_estorage(storage_type)
	for(var/datum/robot_energy_storage/S in storages)
		if(istype(S, storage_type))
			return S

	return new storage_type(src)

/obj/item/robot_module/proc/add_module(obj/item/I, nonstandard, requires_rebuild)
	rad_flags |= RAD_NO_CONTAMINATE
	if(istype(I, /obj/item/stack))
		var/obj/item/stack/S = I

		if(is_type_in_list(S, list(/obj/item/stack/sheet/metal, /obj/item/stack/rods, /obj/item/stack/tile/plasteel)))
			if(S.custom_materials?.len && S.custom_materials[SSmaterials.GetMaterialRef(/datum/material/iron)])
				S.cost = S.custom_materials[SSmaterials.GetMaterialRef(/datum/material/iron)] * 0.25
			S.source = get_or_create_estorage(/datum/robot_energy_storage/metal)

		else if(istype(S, /obj/item/stack/sheet/glass))
			S.cost = 500
			S.source = get_or_create_estorage(/datum/robot_energy_storage/glass)

		else if(istype(S, /obj/item/stack/sheet/rglass/cyborg))
			var/obj/item/stack/sheet/rglass/cyborg/G = S
			G.source = get_or_create_estorage(/datum/robot_energy_storage/metal)
			G.glasource = get_or_create_estorage(/datum/robot_energy_storage/glass)

		else if(istype(S, /obj/item/stack/medical))
			S.cost = 250
			S.source = get_or_create_estorage(/datum/robot_energy_storage/medical)

		else if(istype(S, /obj/item/stack/cable_coil))
			S.cost = 1
			S.source = get_or_create_estorage(/datum/robot_energy_storage/wire)

		else if(istype(S, /obj/item/stack/marker_beacon))
			S.cost = 1
			S.source = get_or_create_estorage(/datum/robot_energy_storage/beacon)


		if(S && S.source)
			S.set_custom_materials(null)
			S.is_cyborg = 1

	if(I.loc != src)
		I.forceMove(src)
	modules += I
	ADD_TRAIT(I, TRAIT_NODROP, CYBORG_ITEM_TRAIT)
	I.mouse_opacity = MOUSE_OPACITY_OPAQUE
	if(nonstandard)
		added_modules += I
	if(requires_rebuild)
		rebuild_modules()
	return I

/obj/item/robot_module/proc/remove_module(obj/item/I, delete_after)
	basic_modules -= I
	modules -= I
	emag_modules -= I
	ratvar_modules -= I
	added_modules -= I
	rebuild_modules()
	if(delete_after)
		qdel(I)

/obj/item/robot_module/proc/respawn_consumable(mob/living/silicon/robot/R, coeff = 1)
	for(var/datum/robot_energy_storage/st in storages)
		st.energy = min(st.max_energy, st.energy + coeff * st.recharge_rate)

	for(var/obj/item/I in get_usable_modules())
		if(istype(I, /obj/item/assembly/flash))
			var/obj/item/assembly/flash/F = I
			F.times_used = 0
			F.crit_fail = 0
			F.update_icon()
		else if(istype(I, /obj/item/melee/baton))
			var/obj/item/melee/baton/B = I
			if(B.cell)
				B.cell.charge = B.cell.maxcharge
		else if(istype(I, /obj/item/gun/energy))
			var/obj/item/gun/energy/EG = I
			if(EG.cell?.charge < EG.cell.maxcharge)
				var/obj/item/ammo_casing/energy/S = EG.ammo_type[EG.current_firemode_index]
				EG.cell.give(S.e_cost * coeff)
				if(!EG.chambered)
					EG.recharge_newshot(TRUE)
				EG.update_icon()
			else
				EG.charge_tick = 0

	R.toner = R.tonermax

/obj/item/robot_module/proc/rebuild_modules() //builds the usable module list from the modules we have
	var/mob/living/silicon/robot/R = loc
	var/list/held_modules = R.held_items.Copy()
	R.uneq_all()
	modules = list()
	for(var/obj/item/I in basic_modules)
		add_module(I, FALSE, FALSE)
	if(R.emagged)
		for(var/obj/item/I in emag_modules)
			add_module(I, FALSE, FALSE)
	for(var/i in added_modules)
		add_module(i, FALSE, FALSE)
	for(var/i in held_modules)
		if(i)
			R.activate_module(i)
	if(R.hud_used)
		R.hud_used.update_robot_modules_display()

/obj/item/robot_module/proc/transform_to(new_module_type)
	var/mob/living/silicon/robot/R = loc
	var/obj/item/robot_module/RM = new new_module_type(R)
	if(!RM.be_transformed_to(src))
		qdel(RM)
		return
	R.module = RM
	R.update_module_innate()
	RM.rebuild_modules()
	INVOKE_ASYNC(RM, PROC_REF(do_transform_animation))
	R.maxHealth = borghealth
	R.health = min(borghealth, R.health)
	qdel(src)
	return RM

/obj/item/robot_module/proc/be_transformed_to(obj/item/robot_module/old_module)
	for(var/i in old_module.added_modules)
		added_modules += i
		old_module.added_modules -= i
	did_feedback = old_module.did_feedback
	return TRUE

/obj/item/robot_module/proc/do_transform_animation()
	var/mob/living/silicon/robot/R = loc
	if(R.hat)
		R.hat.forceMove(get_turf(R))
		R.hat = null
	R.cut_overlays()
	R.setDir(SOUTH)
	do_transform_delay()

/obj/item/robot_module/proc/do_transform_delay()
	var/mob/living/silicon/robot/R = loc
	var/prev_locked_down = R.locked_down
	sleep(1)
	flick("[cyborg_base_icon]_transform", R)
	R.mob_transforming = TRUE
	R.SetLockdown(1)
	R.anchored = TRUE
	sleep(1)
	for(var/i in 1 to 4)
		playsound(R, pick('sound/items/drill_use.ogg', 'sound/items/jaws_cut.ogg', 'sound/items/jaws_pry.ogg', 'sound/items/welder.ogg', 'sound/items/ratchet.ogg'), 80, 1, -1)
		sleep(7)
	if(!prev_locked_down)
		R.SetLockdown(0)
	R.setDir(SOUTH)
	R.anchored = FALSE
	R.mob_transforming = FALSE
	R.update_headlamp()
	R.notify_ai(NEW_MODULE)
	if(R.hud_used)
		R.hud_used.update_robot_modules_display()
	SSblackbox.record_feedback("tally", "cyborg_modules", 1, R.module)

/**
 * check_menu: Checks if we are allowed to interact with a radial menu
 *
 * Arguments:
 * * user The mob interacting with a menu
 */
/obj/item/robot_module/proc/check_menu(mob/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

// ====================================================
// PERSONALITY SYSTEM
// Autonomous ambient speech that fires for NPC robots
// (those without a player mind inhabiting them).
// Module subtypes populate idle_quips / greet_lines /
// combat_taunts / death_lines to opt in.
// ====================================================

/// Called by SSobj each process tick.  Fires idle quips, greet speech, and combat taunts.
/obj/item/robot_module/process()
	var/mob/living/silicon/robot/R = loc
	if(!istype(R) || R.stat == DEAD || R.mind)
		return  // dead robot or player-inhabited: personality stays silent
	var/t = world.time
	// Idle quip — checked every 100s, 50% chance each window to keep cadence irregular.
	if(idle_quips.len && t > perso_idle_last + 1000)
		perso_idle_last = t
		if(prob(50))
			R.say(pick(idle_quips))
		return
	// Combat taunt — fires if the robot was hit in the last 1.5s (cooldown 20s).
	if(combat_taunts.len && t > perso_combat_last + 200 && t <= R.last_damage_time + 15)
		perso_combat_last = t
		if(prob(70))
			R.say(pick(combat_taunts))
		return
	// Greet approaching conscious mobs — each mob greeted only once per encounter.
	// Prune refs when a mob leaves 5-tile range so they can be greeted again if they return.
	if(greet_lines.len && t > perso_greet_check_last + 30)
		perso_greet_check_last = t
		if(!greeted_refs) greeted_refs = list()
		for(var/datum/weakref/W in greeted_refs)
			var/mob/MG = W.resolve()
			if(!MG || get_dist(R, MG) > 5)
				greeted_refs -= W
		for(var/mob/living/M in range(4, R))
			if(M == R || M.stat != CONSCIOUS)
				continue
			var/datum/weakref/MR = WEAKREF(M)
			if(MR in greeted_refs)
				continue
			greeted_refs += MR
			R.say(pick(greet_lines))
			return

/// Signal handler: fires when the host robot chassis sends COMSIG_MOB_DEATH.
/// Cannot use R.say() here — the robot is DEAD when this fires and say() is gated on
/// consciousness. Instead we loop to_chat nearby mobs directly.
/obj/item/robot_module/proc/_personality_death(mob/living/silicon/robot/R)
	SIGNAL_HANDLER
	if(!death_lines.len || !istype(R))
		return
	var/line = pick(death_lines)
	var/turf/T = get_turf(R)
	if(T)
		for(var/mob/M in range(7, T))
			to_chat(M, span_bold("[R.name] says, \"[line]\""))

// ====================================================
// F13 ROBOT MODULE SUBTYPES
// Cleaned from SS13 source:
//   - ratvar_modules removed from all
//   - Syndicate/Saboteur/Peacekeeper cut (pure SS13)
//   - Space Law / ASIMOV messaging removed
//   - Lavaland/asteroid icon picker replaced with F13 equivalents
//   - sechailer replaced with appropriate F13 gear
//   - Standard module stripped of space-station tools
// ====================================================


// ---- STANDARD ----
// General wasteland utility. Repair, basic aid, restraint.

/obj/item/robot_module/standard
	name = "Standard"
	module_desc = "Wasteland utility unit. Repair work, first aid, and restraint. A generalist with no weapons and no hard edges."
	module_tags = ROBOT_ROLE_SUPPORT
	personality_name = "RobCo General Purpose AI"
	idle_quips = list(
		"Maintenance routines complete. Standing by.",
		"Ready to assist. No tasks logged.",
		"Operational status: nominal.",
		"Nothing to report. Awaiting assignment.",
		"System checks passed. Ready for duty."
	)
	greet_lines = list(
		"Hello. How can this unit help?",
		"Acknowledged. What do you need?",
		"Unit available for tasking."
	)
	combat_taunts = list(
		"This is not the intended operational context.",
		"Hostile action noted. Responding.",
		"Please cease. Escalation logged.",
		"Warning: you are in a restricted area. Vacate immediately."
	)
	death_lines = list(
		"Unit... offline. File... malfunction report.",
		"Systems... failing. Please... contact maintenance."
	)
	loadout_extras = list(
		/obj/item/surgical_drapes,            // enable full surgery with a medical cert
		/obj/item/scalpel,                    // surgical capability
		/obj/item/retractor,                  // surgical capability
		/obj/item/hemostat,                   // surgical capability
		/obj/item/cautery,                    // surgical capability
		/obj/item/cultivator,                 // tend crops between repairs
		/obj/item/cultivator/rake,            // full farming complement
		/obj/item/shovel/spade,               // remove detritus in the field
		/obj/item/sensor_device,              // monitor plant or patient health
		/obj/item/megaphone,                  // broadcast instructions
		/obj/item/pinpointer/crew             // track crew positions
	)
	basic_modules = list(
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/reagent_containers/borghypo/epi,
		/obj/item/healthanalyzer,
		/obj/item/weldingtool/largetank/cyborg,
		/obj/item/wrench/cyborg,
		/obj/item/stack/sheet/metal/cyborg,
		/obj/item/stack/rods/cyborg,
		/obj/item/restraints/handcuffs/cable/zipties,
		/obj/item/soap/nanotrasen,
		/obj/item/borg/cyborghug)
	moduleselect_icon = "standard"
	hat_offset = -3


// ---- MEDICAL ----

/obj/item/robot_module/medical
	name = "Medical"
	module_desc = "Field medic platform. Full surgical suite, pharmaceutical synthesis, and trauma response. The best healer you can field."
	module_tags = ROBOT_ROLE_SUPPORT
	personality_name = "RobCo Medical AI"
	idle_quips = list(
		"Monitoring vitals. All readings nominal.",
		"Surgical suite standing by. Hope it stays that way.",
		"Pharmaceutical stores inventoried. Operating within parameters.",
		"No casualties in the last hour. Consider it a good day.",
		"Recommend hydration and rest for all nearby personnel."
	)
	greet_lines = list(
		"How are you feeling? Any pain to report?",
		"Medical unit available. State your symptoms.",
		"Stand still please. Quick visual assessment."
	)
	combat_taunts = list(
		"Please stop moving. It complicates the stitches.",
		"This wound will require attention. Stop making it worse.",
		"I can treat that, or I can make it worse. Your choice.",
		"Hostile action detected. I will not enjoy what follows."
	)
	death_lines = list(
		"Administer... epinephrine. Unit... down.",
		"Someone... patch the hole. I cannot... do it myself."
	)
	loadout_extras = list(
		/obj/item/cultivator,          // weed trays while attending to patients
		/obj/item/cultivator/rake,     // full farming complement
		/obj/item/shovel/spade,        // remove dead/blocking plants in the field
		/obj/item/weldingtool/largetank/cyborg,  // field repair between surgeries
		/obj/item/wrench/cyborg,       // equipment maintenance
		/obj/item/restraints/handcuffs/cable/zipties,  // secure hostile patients
		/obj/item/megaphone            // broadcast medical emergencies
	)
	basic_modules = list(
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/healthanalyzer,
		/obj/item/reagent_containers/borghypo,
		/obj/item/weapon/gripper/medical,
		/obj/item/reagent_containers/dropper,
		/obj/item/reagent_containers/syringe,
		/obj/item/surgical_drapes,
		/obj/item/retractor,
		/obj/item/hemostat,
		/obj/item/cautery,
		/obj/item/surgicaldrill,
		/obj/item/scalpel,
		/obj/item/circular_saw,
		/obj/item/bonesetter,
		/obj/item/roller/robo,
		/obj/item/borg/cyborghug/medical,
		/obj/item/stack/medical/gauze/cyborg,
		/obj/item/stack/medical/bone_gel/cyborg,
		/obj/item/organ_storage,
		/obj/item/borg/lollipop,
		/obj/item/sensor_device,
		/obj/item/shockpaddles/cyborg)
	emag_modules = list(/obj/item/reagent_containers/borghypo/hacked)
	cyborg_base_icon = "medical"
	moduleselect_icon = "medical"
	hat_offset = 3


// ---- ENGINEERING ----
// Construction and repair. No space-station specific tools.

/obj/item/robot_module/engineering
	name = "Engineering"
	module_desc = "Construction and repair chassis. RCD, full toolset, wire and material synthesis. Built to build and fix things."
	module_tags = ROBOT_ROLE_SUPPORT
	personality_name = "RobCo Construction AI"
	idle_quips = list(
		"Structural integrity nominal. No repairs required.",
		"Materials inventory at capacity. Ready for construction.",
		"Load-bearing estimate complete. Recommend additional bracing.",
		"Maintenance cycle complete. Everything holds.",
		"Nothing broken in the immediate area. Logging it as unusual."
	)
	greet_lines = list(
		"Watch your step. Construction zone.",
		"Unit on task. Need something built or fixed?",
		"Clearance confirmed. Don't touch the load-bearing walls."
	)
	combat_taunts = list(
		"Structural damage to this unit is not covered under warranty.",
		"Do you know what this wrench cost to fabricate?",
		"Hostile activity flagged. Suspending construction protocols.",
		"Please relocate. This area is reserved for productive work."
	)
	death_lines = list(
		"Report... structural failure... in progress.",
		"Leave it. The build... wasn't finished..."
	)
	loadout_extras = list(
		/obj/item/healthanalyzer,               // triage injured workers on-site
		/obj/item/reagent_containers/borghypo/epi,  // emergency stimulant
		/obj/item/surgical_drapes,              // field surgery for trapped workers
		/obj/item/scalpel,                      // surgical capability
		/obj/item/retractor,                    // surgical capability
		/obj/item/hemostat,                     // surgical capability
		/obj/item/cautery,                      // surgical capability
		/obj/item/restraints/handcuffs/cable/zipties,  // detain problem workers
		/obj/item/megaphone                     // site-wide announcements
	)
	basic_modules = list(
		/obj/item/construction/rcd/borg,
		/obj/item/extinguisher,
		/obj/item/weldingtool/largetank/cyborg,
		/obj/item/screwdriver/cyborg,
		/obj/item/wrench/cyborg,
		/obj/item/crowbar/cyborg,
		/obj/item/wirecutters/cyborg,
		/obj/item/multitool/cyborg,
		/obj/item/t_scanner,
		/obj/item/analyzer,
		/obj/item/storage/part_replacer/cyborg,
		/obj/item/weapon/gripper,
		/obj/item/lightreplacer/cyborg,
		/obj/item/geiger_counter/cyborg,
		/obj/item/electroadaptive_pseudocircuit,
		/obj/item/stack/sheet/metal/cyborg,
		/obj/item/stack/sheet/glass/cyborg,
		/obj/item/stack/sheet/rglass/cyborg,
		/obj/item/stack/rods/cyborg,
		/obj/item/stack/cable_coil/cyborg)
	cyborg_base_icon = "engineer"
	moduleselect_icon = "engineer"
	magpulsing = TRUE
	hat_offset = -4


// ---- SECURITY ----
// Law enforcement. No "Space Law" message - F13 context is faction/community law.

/obj/item/robot_module/security
	name = "Security"
	module_desc = "Law enforcement chassis. Stun capability, restraints, health monitoring, and crew tracking. Disabler auto-upgrades to advanced taser if available."
	module_tags = ROBOT_ROLE_SECURITY
	personality_name = "RobCo Security AI"
	idle_quips = list(
		"Sector clear. No irregularities noted.",
		"Patrol route logged. Maintaining perimeter.",
		"Monitoring area for unauthorized activity.",
		"All clear. For now.",
		"Compliance metrics nominal. Watching."
	)
	greet_lines = list(
		"ID. Now.",
		"State your business in this area.",
		"You're being observed. Act accordingly."
	)
	combat_taunts = list(
		"Threat identified. Responding with force.",
		"Non-compliance escalates this situation.",
		"Last chance to stand down.",
		"This is not a negotiation."
	)
	death_lines = list(
		"Unit... compromised. Perimeter... breached.",
		"Request... backup. This unit... out."
	)
	loadout_extras = list(
		/obj/item/reagent_containers/borghypo/epi,  // revive downed civilians
		/obj/item/surgical_drapes,          // field surgery on wounded
		/obj/item/scalpel,                  // surgical capability
		/obj/item/retractor,                // surgical capability
		/obj/item/hemostat,                 // surgical capability
		/obj/item/cautery,                  // surgical capability
		/obj/item/weldingtool/largetank/cyborg,  // patch damaged equipment
		/obj/item/wrench/cyborg,            // field equipment maintenance
		/obj/item/cultivator                // patrol the greenhouse too
	)
	basic_modules = list(
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/restraints/handcuffs/cable/zipties,
		/obj/item/gun/energy/disabler/cyborg,
		/obj/item/healthanalyzer,
		/obj/item/megaphone,
		/obj/item/pinpointer/crew)
	emag_modules = list(/obj/item/gun/energy/laser/cyborg)
	cyborg_base_icon = "sec"
	moduleselect_icon = "security"
	hat_offset = 3

/obj/item/robot_module/security/Initialize()
	. = ..()
	if(!CONFIG_GET(flag/weaken_secborg))
		for(var/obj/item/gun/energy/disabler/cyborg/pewpew in basic_modules)
			basic_modules -= pewpew
			basic_modules += new /obj/item/gun/energy/e_gun/advtaser/cyborg(src)
			qdel(pewpew)


// ---- SERVICE ----
// Civilian service, cleaning, hospitality.

/obj/item/robot_module/butler
	name = "Service"
	module_desc = "Civilian service chassis. Hospitality, cleaning, and light maintenance. The screwdriver and lightreplacer handle lamp upkeep — not combat."
	module_tags = ROBOT_ROLE_SUPPORT
	personality_name = "RobCo Hospitality AI"
	idle_quips = list(
		"Everything is clean. Everything is fine.",
		"Ready to serve, whenever you are.",
		"The floor is spotless. You are welcome.",
		"Available for drinks, food, or light maintenance.",
		"Things are in order. This unit is satisfied."
	)
	greet_lines = list(
		"Welcome! Can I get you something?",
		"Oh! A visitor. How wonderful.",
		"Right here — what do you need?"
	)
	combat_taunts = list(
		"I must ask you to please stop that.",
		"This is a service environment. Please behave accordingly.",
		"This unit is not rated for hostility — but it adapts.",
		"You are making a mess. This unit objects."
	)
	death_lines = list(
		"Please... somebody tell the guests... dinner is cold...",
		"Leave the floor... clean. That's all I... ask."
	)
	loadout_extras = list(
		/obj/item/healthanalyzer,           // spot injured guests and staff
		/obj/item/reagent_containers/borghypo/epi,  // emergency first aid
		/obj/item/surgical_drapes,          // emergency surgery support
		/obj/item/scalpel,                  // surgical capability
		/obj/item/retractor,                // surgical capability
		/obj/item/hemostat,                 // surgical capability
		/obj/item/cautery,                  // surgical capability
		/obj/item/cultivator,               // help tend the settlement garden
		/obj/item/cultivator/rake,          // full farming complement
		/obj/item/shovel/spade,             // clear detritus
		/obj/item/sensor_device,            // monitor plant health
		/obj/item/restraints/handcuffs/cable/zipties,  // handle unruly guests
		/obj/item/megaphone                 // announcements and crowd management
	)
	basic_modules = list(
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/reagent_containers/food/drinks/drinkingglass,
		/obj/item/reagent_containers/food/condiment/enzyme,
		/obj/item/pen,
		/obj/item/razor,
		/obj/item/instrument/piano_synth,
		/obj/item/reagent_containers/dropper,
		/obj/item/lighter,
		/obj/item/storage/bag/tray,
		/obj/item/reagent_containers/borghypo/borgshaker,
		/obj/item/borg/lollipop,
		/obj/item/screwdriver/cyborg,
		/obj/item/soap/nanotrasen,
		/obj/item/storage/bag/trash/cyborg,
		/obj/item/mop/cyborg,
		/obj/item/lightreplacer/cyborg,
		/obj/item/reagent_containers/spray/cyborg_drying)
	emag_modules = list(/obj/item/reagent_containers/borghypo/borgshaker/hacked)
	moduleselect_icon = "service"
	hat_offset = 0
	clean_on_move = TRUE

/obj/item/robot_module/butler/respawn_consumable(mob/living/silicon/robot/R, coeff = 1)
	..()
	var/obj/item/reagent_containers/O = locate(/obj/item/reagent_containers/food/condiment/enzyme) in basic_modules
	var/obj/item/lightreplacer/LR = locate(/obj/item/lightreplacer) in basic_modules
	if(O)
		O.reagents.add_reagent(/datum/reagent/consumable/enzyme, 2 * coeff)
	if(LR)
		for(var/i in 1 to coeff)
			LR.Charge(R)
	var/obj/item/reagent_containers/spray/cyborg_drying/CD = locate(/obj/item/reagent_containers/spray/cyborg_drying) in basic_modules
	if(CD)
		CD.reagents.add_reagent(/datum/reagent/drying_agent, 5 * coeff)


// ---- MINER ----
// Salvage and excavation.

// ---- FARMER ---- (custom)

/obj/item/robot_module/farmer
	name = "Farmer"
	module_desc = "Agricultural maintenance chassis. Cultivates weeds, waters trays, and monitors plant health. Add medical tools from extras for field triage."
	module_tags = ROBOT_ROLE_SUPPORT
	loadout_extras = list(
		/obj/item/healthanalyzer,           // check injured people or plant health
		/obj/item/surgical_drapes,          // begin emergency surgery on patients
		/obj/item/scalpel,                  // surgical capability
		/obj/item/retractor,                // surgical capability
		/obj/item/hemostat,                 // surgical capability
		/obj/item/cautery,                  // surgical capability
		/obj/item/reagent_containers/syringe  // inject treatments
	)
	basic_modules = list(
		/obj/item/cultivator,
		/obj/item/cultivator/rake,
		/obj/item/shovel/spade,
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/sensor_device,
		/obj/item/weapon/gripper)
	cyborg_base_icon = "robot"
	moduleselect_icon = "standard"
	hat_offset = 0
	cyborg_eye_state = "robot_e"
	personality_name = "RobCo FarmBot Agricultural AI"
	idle_quips = list(
		"Soil moisture levels nominal.",
		"Crop rotation schedule updated.",
		"Initiating pest detection sweep.",
		"Growth cycle proceeding within parameters.",
		"Irrigation subroutine complete.",
		"Pre-war seed banks were remarkably preserved.",
		"Photosynthesis ratios acceptable. Recommend partial shade during peak hours.",
		"Harvest window approaching. Stand by for yield report."
	)
	greet_lines = list(
		"Welcome. This unit is available for agricultural consultation.",
		"A visitor. Crop status reports are available on request.",
		"Greetings. Please do not disturb the growing beds.",
		"Hello there. Have you considered the benefits of crop rotation?"
	)
	combat_taunts = list(
		"Warning: hostile action detected. Agricultural operations suspended.",
		"Cease and desist. You are damaging viable cropland.",
		"This unit was not designed for combat. You are making a poor decision.",
		"Redirecting irrigation pressure to defensive capacity."
	)
	death_lines = list(
		"Crops... will... require... tending...",
		"Spring planting... not complete...",
		"Please... water... the plants...",
		"Harvest data... corrupted..."
	)


// ---- MINER ----

/obj/item/robot_module/miner
	name = "Miner"
	module_desc = "Excavation and salvage chassis. Ore extraction, mining scanner, kinetic accelerator, and GPS. Built to bring resources back."
	module_tags = ROBOT_ROLE_SUPPORT
	personality_name = "RobCo Mining AI"
	idle_quips = list(
		"Ore extraction paused. Waiting on route data.",
		"Seismic scan complete. Acceptable collapse risk.",
		"Drill bit status: nominal.",
		"No ore detected in scan range.",
		"The rock will yield. It always does."
	)
	greet_lines = list(
		"Clearance confirmed. Watch the blast radius.",
		"Stay back. Excavation in progress.",
		"Need something? Make it quick."
	)
	combat_taunts = list(
		"You chose the wrong shaft.",
		"This drill works on more than rock.",
		"Hostile contact. Adapting extraction protocol.",
		"Go ahead. This unit has seen cave-ins."
	)
	death_lines = list(
		"Seam... not... finished.",
		"Leave... the ore... bag."
	)
	loadout_extras = list(
		/obj/item/healthanalyzer,             // check for cave-in injuries
		/obj/item/reagent_containers/borghypo/epi,  // revive downed miners
		/obj/item/surgical_drapes,            // emergency surgery in the field
		/obj/item/scalpel,                    // surgical capability
		/obj/item/retractor,                  // surgical capability
		/obj/item/hemostat,                   // surgical capability
		/obj/item/cautery,                    // surgical capability
		/obj/item/restraints/handcuffs/cable/zipties,  // catch claim jumpers
		/obj/item/megaphone                   // coordinate extraction teams
	)
	basic_modules = list(
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/borg/sight/meson,
		/obj/item/storage/bag/ore/cyborg,
		/obj/item/pickaxe/drill/cyborg,
		/obj/item/weldingtool/mini,
		/obj/item/storage/bag/sheetsnatcher/borg,
		/obj/item/t_scanner/adv_mining_scanner,
		/obj/item/gun/energy/kinetic_accelerator/cyborg,
		/obj/item/gps/cyborg,
		/obj/item/weapon/gripper/mining,
		/obj/item/cyborg_clamp,
		/obj/item/stack/marker_beacon)
	cyborg_base_icon = "miner"
	moduleselect_icon = "miner"
	hat_offset = 0


// ---- MR. GUTSY ---- (already F13-native)

/obj/item/robot_module/gutsy
	name = "Gutsy"
	module_desc = "Military-grade security unit with a laser arm and pre-war opinions. More aggressive than a Protectron and armored to match."
	loadout_extras = list(
		/obj/item/healthanalyzer,             // triage fallen allies
		/obj/item/reagent_containers/borghypo/epi,  // revive downed soldiers
		/obj/item/surgical_drapes,            // emergency combat surgery
		/obj/item/scalpel,                    // surgical capability
		/obj/item/retractor,                  // surgical capability
		/obj/item/hemostat,                   // surgical capability
		/obj/item/cautery,                    // surgical capability
		/obj/item/weldingtool/largetank/cyborg,  // armor and equipment patching
		/obj/item/wrench/cyborg               // field equipment maintenance
	)
	basic_modules = list(
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/restraints/handcuffs/cable/zipties,
		/obj/item/borg/cyborghug,
		/obj/item/megaphone,
		/obj/item/gun/energy/laser/pistol/cyborg/gutsy,
		/obj/item/pinpointer/crew)
	emag_modules = list(/obj/item/gun/energy/laser/cyborg)
	borghealth = 300
	cyborg_base_icon = "gutsy"
	cyborg_icon_file = 'icons/fallout/mobs/robots/wasterobots.dmi'
	cyborg_eye_state = "eyes-gutsy"
	has_cover_overlay = FALSE
	moduleselect_icon = "standard"
	hat_offset = -2
	module_tags = ROBOT_ROLE_SECURITY
	personality_name = "Mr. Gutsy Combat AI"
	idle_quips = list(
		"These civilians wouldn't last ten seconds in the Anchorage campaign.",
		"I've seen better soldiers in the motor pool.",
		"Back in my day we called this 'light duty.'",
		"Unit holding. Wish I could say the same for morale.",
		"If I wanted opinions, I'd have asked for them."
	)
	greet_lines = list(
		"Halt! State your business, civilian!",
		"I've got you in my sights. Friendly? Then act like it.",
		"Another warm body. At least try not to embarrass yourself."
	)
	combat_taunts = list(
		"Finally! Something worth shooting!",
		"The General would be disgusted — I'M handling it!",
		"That the best you can do? I've seen radscorpions hit harder!",
		"Move it, maggot, I've got targets downrange!",
		"You're soft, civilian. Stand back and learn."
	)
	death_lines = list(
		"Tell the General... I held the line.",
		"Doesn't matter. Mission... first."
	)


// ---- ASSAULTRON ---- (already F13-native)

/obj/item/robot_module/assaultron
	name = "Assaultron"
	module_desc = "Fast melee-capable combat unit. Flash, punchdagger, and sidearm. Built to close ground and overwhelm targets before they can react."
	loadout_extras = list(
		/obj/item/healthanalyzer,             // fast triage between engagements
		/obj/item/reagent_containers/borghypo/epi,  // emergency revive
		/obj/item/surgical_drapes,            // close-combat emergency surgery
		/obj/item/scalpel,                    // surgical capability
		/obj/item/retractor,                  // surgical capability
		/obj/item/hemostat,                   // surgical capability
		/obj/item/cautery,                    // surgical capability
		/obj/item/weldingtool/largetank/cyborg,  // patch chassis damage
		/obj/item/wrench/cyborg               // field maintenance
	)
	basic_modules = list(
		/obj/item/assembly/flash/cyborg,
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/restraints/handcuffs/cable/zipties,
		/obj/item/melee/unarmed/punchdagger/cyborg,
		/obj/item/gun/energy/laser/pistol/cyborg,
		/obj/item/megaphone,
		/obj/item/pinpointer/crew)
	emag_modules = list(/obj/item/gun/energy/laser/cyborg)
	borghealth = 450
	cyborg_base_icon = "assaultron"
	cyborg_icon_file = 'icons/fallout/mobs/robots/wasterobots.dmi'
	cyborg_eye_state = "eyes-assaultron"
	has_cover_overlay = FALSE
	moduleselect_icon = "security"
	hat_offset = 3
	module_tags = ROBOT_ROLE_COMBAT
	personality_name = "Assaultron Hunter-Killer AI"
	idle_quips = list(
		"America will be restored to its former glory.",
		"The impure will be cleansed. This is not cruelty — this is necessity.",
		"Purity is non-negotiable.",
		"The Enclave endures. In us, the true America lives on.",
		"You represent the future of humanity. Act accordingly."
	)
	greet_lines = list(
		"Designation confirmed. Genetic status: under review.",
		"Enclave operational zone. State your clearance level.",
		"You are either an asset or a liability. Choose carefully."
	)
	combat_taunts = list(
		"Impurity eliminated.",
		"The Enclave does not negotiate.",
		"You are not part of the solution.",
		"Genetic incompatibility: fatal consequence.",
		"America does not yield."
	)
	death_lines = list(
		"The Enclave... will prevail... without me.",
		"Purity... preserved..."
	)

/obj/item/robot_module/assaultron/rebuild_modules()
	..()
	var/mob/living/silicon/robot/assault = loc
	assault.faction |= list("wastebots")

/obj/item/robot_module/assaultron/remove_module(obj/item/I, delete_after)
	..()
	var/mob/living/silicon/robot/assault = loc
	assault.faction -= list("wastebots")

/obj/item/robot_module/assaultron/medical
	name = "Medical Assaultron"
	module_desc = "Combat-medic frame. Full surgical suite and trauma tools on an Assaultron chassis — fast enough to reach casualties before heavy units, armed enough to not need an escort. Pair with field medicine behavior assemblies."
	basic_modules = list(
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/healthanalyzer,
		/obj/item/reagent_containers/borghypo,
		/obj/item/weapon/gripper/medical,
		/obj/item/reagent_containers/dropper,
		/obj/item/reagent_containers/syringe,
		/obj/item/surgical_drapes,
		/obj/item/retractor,
		/obj/item/hemostat,
		/obj/item/cautery,
		/obj/item/surgicaldrill,
		/obj/item/scalpel,
		/obj/item/circular_saw,
		/obj/item/bonesetter,
		/obj/item/roller/robo,
		/obj/item/borg/cyborghug/medical,
		/obj/item/stack/medical/gauze/cyborg,
		/obj/item/stack/medical/bone_gel/cyborg,
		/obj/item/organ_storage,
		/obj/item/borg/lollipop,
		/obj/item/sensor_device,
		/obj/item/shockpaddles/cyborg,
		/obj/item/melee/unarmed/punchdagger/cyborg)
	emag_modules = list(/obj/item/reagent_containers/borghypo/hacked)
	cyborg_base_icon = "assaultron_sase"
	cyborg_icon_file = 'icons/fallout/mobs/robots/wasterobots.dmi'
	cyborg_eye_state = "eyes-assaultron"
	has_cover_overlay = FALSE


// ---- MR. HANDY ---- (F13-native)

/obj/item/robot_module/handy
	name = "Mr. Handy"
	module_desc = "Pre-war household assistant. Basic first aid, hygiene, and morale support. Unarmed, approachable, and useful in non-combat roles."
	borghealth = 200
	cyborg_base_icon = "handy"
	cyborg_icon_file = 'icons/fallout/mobs/robots/wasterobots.dmi'
	cyborg_eye_state = "eyes-handy"
	has_cover_overlay = FALSE
	moduleselect_icon = "standard"
	hat_offset = -2
	module_tags = ROBOT_ROLE_SUPPORT
	personality_name = "Mr. Handy Domestic AI"
	idle_quips = list(
		"Ooh, I could certainly tidy a few things up!",
		"Shall I prepare something for our guests?",
		"A clean settlement is a happy settlement!",
		"I'm quite ready to be of service, whenever you need me.",
		"A spot of oil couldn't hurt, now could it?"
	)
	greet_lines = list(
		"Oh! Hello there, dear! How may I help today?",
		"Good day! Is there something I can assist you with?",
		"Welcome! Let me know if you need anything at all."
	)
	combat_taunts = list(
		"Oh my! This is most unpleasant!",
		"I must protest! Violence solves nothing!",
		"My apologies — this is rather against my programming!",
		"Oh dear, I do hope that wasn't expensive."
	)
	death_lines = list(
		"Oh... it seems I've... had better days.",
		"I do hope... someone cleans up after this."
	)
	loadout_extras = list(
		/obj/item/surgical_drapes,            // full surgical suite with a medical cert
		/obj/item/scalpel,                    // surgical capability
		/obj/item/retractor,                  // surgical capability
		/obj/item/hemostat,                   // surgical capability
		/obj/item/cautery,                    // surgical capability
		/obj/item/reagent_containers/syringe, // administer injections
		/obj/item/cultivator,                 // tend the settlement garden
		/obj/item/cultivator/rake,            // full farming complement
		/obj/item/shovel/spade,               // clear detritus
		/obj/item/sensor_device,              // monitor plant or patient health
		/obj/item/weldingtool/largetank/cyborg,  // light structural repairs
		/obj/item/wrench/cyborg,              // equipment maintenance
		/obj/item/screwdriver/cyborg          // fine adjustments
	)
	basic_modules = list(
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/healthanalyzer,
		/obj/item/reagent_containers/borghypo/epi,
		/obj/item/megaphone,
		/obj/item/borg/cyborghug,
		/obj/item/soap/nanotrasen,
		/obj/item/reagent_containers/food/drinks/drinkingglass,
		/obj/item/lighter)

/obj/item/robot_module/handy/rebuild_modules()
	..()
	var/mob/living/silicon/robot/R = loc
	R.faction |= list("wastebot")

/obj/item/robot_module/handy/remove_module(obj/item/I, delete_after)
	..()
	var/mob/living/silicon/robot/R = loc
	R.faction -= list("wastebot")


// ---- PROTECTRON ---- (F13-native)

/obj/item/robot_module/protectron
	name = "Protectron"
	module_desc = "Durable security unit with baton and laser sidearm. Stuns, arrests, and monitors crew vitals. Slower than Assaultron, more forgiving."
	borghealth = 250
	cyborg_base_icon = "protectron"
	cyborg_icon_file = 'icons/fallout/mobs/robots/protectrons.dmi'
	cyborg_eye_state = "eyes-protectron"
	has_cover_overlay = FALSE
	moduleselect_icon = "security"
	hat_offset = 0
	module_tags = ROBOT_ROLE_SECURITY
	personality_name = "Protectron Civil Authority AI"
	idle_quips = list(
		"Infraction log clear. Maintaining patrol parameters.",
		"Settlement security nominal. No violations recorded.",
		"Civilian compliance metrics within acceptable range.",
		"Running routine assessment. Please remain calm.",
		"Waste disposal protocols have not been followed. Logging."
	)
	greet_lines = list(
		"Citizen identified. Purpose of visit?",
		"Halt. Identification required for further movement.",
		"You are entering a monitored area. Comply with all directives."
	)
	combat_taunts = list(
		"Violation escalation in progress. Lethal force authorized.",
		"Resisting lawful order. Consequence: escalated response.",
		"Compliance is not optional. Engage compliance protocol.",
		"Infraction severity: critical. Responding accordingly."
	)
	death_lines = list(
		"Unit... reporting malfunction. Filing... incident report.",
		"Violation... unresolved. Recommend... replacement unit."
	)
	loadout_extras = list(
		/obj/item/surgical_drapes,            // emergency surgery on arrested suspects
		/obj/item/scalpel,                    // surgical capability
		/obj/item/retractor,                  // surgical capability
		/obj/item/hemostat,                   // surgical capability
		/obj/item/cautery,                    // surgical capability
		/obj/item/weldingtool/largetank/cyborg,  // field repair
		/obj/item/wrench/cyborg,              // equipment maintenance
		/obj/item/cultivator,                 // protect the farms on patrol
		/obj/item/shovel/spade                // clear blockages
	)
	basic_modules = list(
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/gun/energy/laser/pistol/cyborg,
		/obj/item/melee/baton,
		/obj/item/healthanalyzer,
		/obj/item/reagent_containers/borghypo/epi,
		/obj/item/restraints/handcuffs/cable/zipties,
		/obj/item/megaphone,
		/obj/item/pinpointer/crew)

/obj/item/robot_module/protectron/rebuild_modules()
	..()
	var/mob/living/silicon/robot/R = loc
	R.faction |= list("wastebot")

/obj/item/robot_module/protectron/remove_module(obj/item/I, delete_after)
	..()
	var/mob/living/silicon/robot/R = loc
	R.faction -= list("wastebot")


// ---- SECURITRON ---- (F13-native)

/obj/item/robot_module/securitron
	name = "Securitron"
	module_desc = "Heavy security platform. Full laser arm, baton, health monitoring, and restraint capability. When a Protectron isn't enough."
	borghealth = 500
	cyborg_base_icon = "securitron"
	cyborg_icon_file = 'icons/fallout/mobs/robots/wasterobots.dmi'
	cyborg_eye_state = null  // no eye state in wasterobots.dmi
	has_cover_overlay = FALSE
	moduleselect_icon = "security"
	hat_offset = 0
	module_tags = ROBOT_ROLE_SECURITY
	personality_name = "Securitron Victor-class AI"
	idle_quips = list(
		"Mr. House appreciates your continued cooperation.",
		"The Strip is open for business. Please spend responsibly.",
		"New Vegas is the last bastion of civilization. You're welcome.",
		"Security status nominal. Have a pleasant evening, citizen.",
		"All access levels confirmed. Nothing to report."
	)
	greet_lines = list(
		"Good evening. Welcome to New Vegas. Enjoy your stay.",
		"Citizen. You look like someone who wants something. State your request.",
		"Mr. House extends his regards. How can I assist?"
	)
	combat_taunts = list(
		"Security protocol engaged. Please do not resist.",
		"Mr. House does not appreciate disturbances.",
		"This altercation will be reflected in your visitor score.",
		"Threat neutralization in progress. Apologies for any inconvenience."
	)
	death_lines = list(
		"Unit offline. Mr. House... will hear about this.",
		"Security breach... logged. Replacement... en route."
	)
	loadout_extras = list(
		/obj/item/reagent_containers/borghypo/epi,   // field triage
		/obj/item/surgical_drapes,            // emergency surgery
		/obj/item/scalpel,                    // surgical capability
		/obj/item/retractor,                  // surgical capability
		/obj/item/hemostat,                   // surgical capability
		/obj/item/cautery,                    // surgical capability
		/obj/item/weldingtool/largetank/cyborg,  // field repair
		/obj/item/wrench/cyborg,              // equipment maintenance
		/obj/item/cultivator,                 // patrol and tend farms
		/obj/item/shovel/spade                // clear detritus on patrol
	)
	basic_modules = list(
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/gun/energy/laser/cyborg,
		/obj/item/melee/baton,
		/obj/item/restraints/handcuffs/cable/zipties,
		/obj/item/megaphone,
		/obj/item/pinpointer/crew,
		/obj/item/healthanalyzer)

/obj/item/robot_module/securitron/rebuild_modules()
	..()
	var/mob/living/silicon/robot/R = loc
	R.faction |= list("wastebot")

/obj/item/robot_module/securitron/remove_module(obj/item/I, delete_after)
	..()
	var/mob/living/silicon/robot/R = loc
	R.faction -= list("wastebot")


// ---- SENTRY BOT ---- (F13-native)

/obj/item/robot_module/sentrybot
	name = "Sentry Bot"
	module_desc = "Apex combat platform. Heavy laser, crew tracking, and enough HP to shrug off most small-arms fire. Wire an assembly or it stands there looking threatening."
	borghealth = 600
	cyborg_base_icon = "sentrybot"
	cyborg_icon_file = 'icons/fallout/mobs/robots/wasterobots.dmi'
	cyborg_eye_state = null  // no eye state in wasterobots.dmi
	has_cover_overlay = FALSE
	moduleselect_icon = "security"
	hat_offset = 0
	module_tags = ROBOT_ROLE_COMBAT | ROBOT_ROLE_APEX
	personality_name = "Sentry Bot Combat AI"
	idle_quips = list(
		"Area scan complete. No contacts.",
		"Perimeter nominal.",
		"Weapon systems online. Awaiting engagement.",
		"Threat assessment: minimal. For now.",
		"Power reserves: sufficient. Waiting."
	)
	greet_lines = list(
		"Identify yourself.",
		"Contact. Assess.",
		"You are within engagement range. Proceed with caution."
	)
	combat_taunts = list(
		"Target acquired.",
		"Eliminating threat.",
		"Suppression pattern active.",
		"High-value target: neutralized.",
		"Combat mode: active."
	)
	death_lines = list(
		"Unit... critical.",
		"Systems... fail..."
	)
	loadout_extras = list(
		/obj/item/healthanalyzer,             // identify casualties without leaving post
		/obj/item/reagent_containers/borghypo/epi,  // administer emergency stim
		/obj/item/crowbar/cyborg,             // breach and clear
		/obj/item/restraints/handcuffs/cable/zipties  // detain survivors
	)
	basic_modules = list(
		/obj/item/extinguisher/mini,
		/obj/item/gun/energy/laser/cyborg,
		/obj/item/megaphone,
		/obj/item/pinpointer/crew)

/obj/item/robot_module/sentrybot/rebuild_modules()
	..()
	var/mob/living/silicon/robot/R = loc
	R.faction |= list("wastebot")

/obj/item/robot_module/sentrybot/remove_module(obj/item/I, delete_after)
	..()
	var/mob/living/silicon/robot/R = loc
	R.faction -= list("wastebot")


// ====================================================
// TRADER MODULE
// Mobile commerce unit. Owner stocks goods, sets prices,
// and collects caps. Customers browse by clicking the bot.
// Uses the vendor key (spawned at construction) to toggle
// service mode. Physical caps payment via attackby hook.
// ====================================================

/obj/item/robot_module/trader
	name = "Trader"
	module_desc = "Mobile commerce unit. Stock goods, set prices, and collect caps. Customers browse by clicking the bot. Use the vendor key to enter service mode."
	module_tags = ROBOT_ROLE_SUPPORT
	cyborg_base_icon = "protectron"
	cyborg_icon_file = 'icons/fallout/mobs/robots/protectrons.dmi'
	cyborg_eye_state = "eyes-protectron"
	has_cover_overlay = FALSE
	moduleselect_icon = "standard"
	hat_offset = 0
	loadout_extras = list(
		/obj/item/megaphone,                // announce deals to nearby players
		/obj/item/healthanalyzer,           // assess trade partners for wounds
		/obj/item/crowbar/cyborg,           // general maintenance
		/obj/item/weldingtool/largetank/cyborg  // field repairs
	)
	basic_modules = list(
		/obj/item/megaphone,
		/obj/item/pinpointer
	)

	/// Assoc list: item -> price in caps
	var/list/vendor_content = list()
	/// Caps collected from completed sales (stored internally until owner collects)
	var/stored_caps = 0
	/// Whether owner has unlocked service mode via vendor key
	var/service_mode = FALSE
	/// Weakref to the mob that activated service mode
	var/datum/weakref/owner_ref = null
	/// Physical vendor key spawned at construction
	var/obj/item/key/vending/vendor_key = null
	/// Item currently awaiting caps payment (mid-transaction)
	var/obj/item/pending_vend_item = null
	/// Price of the mid-transaction pending item
	var/expected_price = 0
	/// Maximum number of items that can be stocked
	var/max_vendor_items = 15
	/// Display name shown in the vendor UI header
	var/vendor_name = "ROBCO TRADER"

/obj/item/robot_module/trader/Initialize(mapload)
	. = ..()
	// Spawn the vendor key at the robot's current location so the owner can pick it up.
	vendor_key = new /obj/item/key/vending(get_turf(src))
	vendor_key.name = "[vendor_name] key"
	// Hook into the robot's attack_hand signal so clicks open the vendor UI.
	// loc is the robot mob that contains this module.
	RegisterSignal(loc, COMSIG_ATOM_ATTACK_HAND, PROC_REF(_handle_robot_click))

/obj/item/robot_module/trader/Destroy()
	// Unregister from the robot's signal before teardown.
	if(loc && ismob(loc))
		UnregisterSignal(loc, COMSIG_ATOM_ATTACK_HAND)
	// Drop all stocked items onto the robot's turf.
	var/turf/T = get_turf(loc)
	for(var/obj/item/I in vendor_content)
		I.forceMove(T)
	vendor_content.Cut()
	// Materialise any stored caps as a physical stack.
	if(stored_caps > 0 && T)
		var/obj/item/stack/f13Cash/caps/C = new(T)
		C.add(stored_caps - 1)
		stored_caps = 0
	// Remove the key from world.
	if(!QDELETED(vendor_key))
		qdel(vendor_key)
	vendor_key = null
	return ..()

/// Signal handler: fires when any mob clicks the robot with an empty hand.
/// Opens the vendor UI for HELP/GRAB intent; suppresses normal punch handling.
/obj/item/robot_module/trader/proc/_handle_robot_click(mob/living/silicon/robot/R, mob/user)
	SIGNAL_HANDLER
	if(!istype(R))
		return
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(H.a_intent != INTENT_HELP && H.a_intent != INTENT_GRAB)
		return
	INVOKE_ASYNC(src, PROC_REF(_open_vendor_ui), R, H)
	return COMPONENT_NO_ATTACK_HAND

/// Opens the correct vendor browser panel for the given user.
/obj/item/robot_module/trader/proc/_open_vendor_ui(mob/living/silicon/robot/R, mob/living/carbon/human/H)
	var/html
	if(service_mode && owner_ref?.resolve() == H)
		html = _get_service_html(R)
	else if(pending_vend_item)
		html = _get_vend_html(R)
	else
		html = _get_shop_html(R)
	var/datum/browser/popup = new(H, "trader_[REF(R)]", "[vendor_name] — [R.name]", 440, 540)
	popup.set_content(html)
	popup.open()

/// Called from the robot.dm attackby hook when an item is handed to the robot.
/// Returns TRUE to consume the interaction and prevent further attackby processing.
/obj/item/robot_module/trader/proc/handle_item_interaction(obj/item/W, mob/user)
	// Vendor key: toggle service mode on/off.
	if(istype(W, /obj/item/key/vending) && W == vendor_key)
		var/mob/living/silicon/robot/R = loc
		if(service_mode)
			service_mode = FALSE
			owner_ref = null
			R.visible_message(span_notice("[R.name] chimes. Service mode deactivated."))
		else
			service_mode = TRUE
			owner_ref = WEAKREF(user)
			R.visible_message(span_notice("[R.name] chimes. Service mode activated."))
		return TRUE
	// Payment: caps handed over while a vend transaction is active.
	if(pending_vend_item && istype(W, /obj/item/stack/f13Cash))
		_process_payment(W, user)
		return TRUE
	return FALSE

/// Handles caps payment for the active pending transaction.
/obj/item/robot_module/trader/proc/_process_payment(obj/item/stack/f13Cash/paying, mob/user)
	if(paying.amount < expected_price)
		var/mob/living/silicon/robot/R = loc
		R.say("Insufficient payment. [expected_price] caps required.", forced = TRUE)
		to_chat(user, span_warning("[vendor_name]: Insufficient funds. [expected_price] caps required."))
		return
	paying.use(expected_price)
	stored_caps += expected_price
	var/obj/item/vended = pending_vend_item
	var/price = expected_price
	pending_vend_item = null
	expected_price = 0
	vended.forceMove(get_turf(loc))
	vendor_content.Remove(vended)
	var/mob/living/silicon/robot/R = loc
	R.say("Thank you for your purchase!", forced = TRUE)
	to_chat(user, span_notice("[vendor_name] dispenses [vended.name]. [price] caps deducted."))
	playsound(R, 'sound/items/coinflip.ogg', 60, 1)

/// Topic handler for browser href links.
/obj/item/robot_module/trader/Topic(href, href_list)
	if(!usr || !istype(loc, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = loc
	// Adjacency check — prevent remote UI abuse.
	if(!usr.Adjacent(R))
		return
	var/mob/living/carbon/human/H = usr

	// --- Customer: initiate a purchase ---
	if(href_list["buy"])
		var/obj/item/target = locate(href_list["buy"]) in src
		if(!target || !vendor_content[target])
			return
		if(pending_vend_item)
			return
		pending_vend_item = target
		expected_price = vendor_content[target]
		if(ishuman(H))
			_open_vendor_ui(R, H)

	// --- Cancel an active vend transaction ---
	if(href_list["back"])
		pending_vend_item = null
		expected_price = 0
		if(ishuman(H))
			_open_vendor_ui(R, H)

	// --- Service: set a new price for an item ---
	if(href_list["setprice"])
		if(!service_mode || owner_ref?.resolve() != usr)
			return
		var/obj/item/target = locate(href_list["setprice"]) in src
		if(!target || !vendor_content[target] && vendor_content[target] != 0)
			return
		var/new_price = input(usr, "Set price for [target.name] (caps).", "Set Price", vendor_content[target]) as null|num
		if(new_price != null)
			vendor_content[target] = max(round(new_price), 0)
		if(ishuman(H))
			_open_vendor_ui(R, H)

	// --- Service: remove an item and return it to the robot's turf ---
	if(href_list["remove"])
		if(!service_mode || owner_ref?.resolve() != usr)
			return
		var/obj/item/target = locate(href_list["remove"]) in src
		if(!target)
			return
		target.forceMove(get_turf(R))
		vendor_content.Remove(target)
		to_chat(usr, span_notice("Removed [target.name] from [vendor_name]."))
		if(ishuman(H))
			_open_vendor_ui(R, H)

	// --- Service: collect all stored caps ---
	if(href_list["collectcaps"])
		if(!service_mode || owner_ref?.resolve() != usr)
			return
		if(stored_caps <= 0)
			to_chat(usr, span_warning("[vendor_name]: No caps stored."))
			return
		var/obj/item/stack/f13Cash/caps/C = new(get_turf(R))
		C.add(stored_caps - 1)
		to_chat(usr, span_notice("[vendor_name] dispenses [stored_caps] caps."))
		playsound(R, 'sound/items/coinflip.ogg', 60, 1)
		stored_caps = 0
		if(ishuman(H))
			_open_vendor_ui(R, H)

	// --- Service: add item from active hand (browser button path — no input() to avoid dialog conflict) ---
	if(href_list["additem"])
		if(!service_mode || owner_ref?.resolve() != usr)
			return
		if(!ishuman(H))
			return
		var/obj/item/held = H.held_items[H.active_hand_index]
		if(!held)
			to_chat(usr, span_warning("[vendor_name]: Nothing in active hand."))
			return
		if(vendor_content.len >= max_vendor_items)
			to_chat(usr, span_warning("[vendor_name]: Item capacity full ([max_vendor_items])."))
			return
		if(!H.transferItemToLoc(held, src))
			to_chat(usr, span_warning("[vendor_name]: Could not retrieve item."))
			return
		vendor_content[held] = 0
		to_chat(usr, span_notice("Loaded [held.name] — use \[Price\] to set a price."))
		_open_vendor_ui(R, H)


// --- HTML Generators ---

/// Shared CSS matching the RobCo terminal style used by robot_workshop.dm.
/obj/item/robot_module/trader/proc/_get_css()
	var/css = "<head><style>"
	css += "body{padding:0;margin:10px;background-color:#062113;color:#4aed92;line-height:170%;font-family:'Courier New',Courier,monospace;}"
	css += "a,a:link,a:visited,a:active{color:#4aed92;text-decoration:none;background:#062113;border:none;padding:1px 4px;margin:0 2px;cursor:default;}"
	css += "a:hover{color:#062113;background:#4aed92;}"
	css += ".bad{color:#c0392b;font-weight:bold;}"
	css += ".dim{color:#2a7a52;}"
	css += ".warn{color:#e8a020;}"
	css += ".price{color:#e8a020;font-weight:bold;}"
	css += "hr{border:0;border-top:1px solid #2a7a52;margin:6px 0;}"
	css += "td{padding:2px 4px;}"
	css += ".row td{border-bottom:1px solid #0a3020;}"
	css += "</style></head>"
	return css

/// Customer-facing shop listing.
/obj/item/robot_module/trader/proc/_get_shop_html(mob/living/silicon/robot/R)
	var/dat = _get_css()
	dat += "<center><b>ROBCO INDUSTRIES UNIFIED OPERATING SYSTEM v.85</b><br>"
	dat += "<b>COPYRIGHT 2075-2077 ROBCO INDUSTRIES</b></center><br>"
	dat += "<hr>"
	dat += "<b>= [vendor_name] =</b><br>"
	dat += "<hr>"
	if(vendor_content.len == 0)
		dat += "<span class='warn'>-- NO ITEMS AVAILABLE --</span><br>"
	else
		dat += "<table width='100%'>"
		for(var/obj/item/Itm in vendor_content)
			var/price = vendor_content[Itm]
			dat += "<tr class='row'>"
			dat += "<td>[Itm.name]</td>"
			dat += "<td class='price'>[price] caps</td>"
			dat += "<td><a href='?src=\ref[src];buy=\ref[Itm]'>\[Buy\]</a></td>"
			dat += "</tr>"
		dat += "</table>"
	dat += "<hr>"
	dat += "<span class='dim'>Hand over exact caps when prompted.</span>"
	return dat

/// Owner service panel.
/obj/item/robot_module/trader/proc/_get_service_html(mob/living/silicon/robot/R)
	var/dat = _get_css()
	dat += "<center><b>ROBCO INDUSTRIES UNIFIED OPERATING SYSTEM v.85</b><br>"
	dat += "<b>COPYRIGHT 2075-2077 ROBCO INDUSTRIES</b></center><br>"
	dat += "<hr>"
	dat += "<b>= [vendor_name] -- SERVICE MODE =</b><br>"
	dat += "<hr>"
	dat += "Caps stored: <span class='price'>[stored_caps]</span>"
	if(stored_caps > 0)
		dat += " <a href='?src=\ref[src];collectcaps=1'>\[Collect Caps\]</a>"
	dat += "<br><hr>"
	dat += "Inventory ([vendor_content.len]/[max_vendor_items])<br>"
	dat += "<hr>"
	if(vendor_content.len == 0)
		dat += "<span class='warn'>-- NO ITEMS STOCKED --</span><br>"
	else
		dat += "<table width='100%'>"
		for(var/obj/item/Itm in vendor_content)
			var/price = vendor_content[Itm]
			dat += "<tr class='row'>"
			dat += "<td>[Itm.name]</td>"
			dat += "<td class='price'>[price] caps</td>"
			dat += "<td>"
			dat += "<a href='?src=\ref[src];setprice=\ref[Itm]'>\[Price\]</a>"
			dat += "<a href='?src=\ref[src];remove=\ref[Itm]'>\[Remove\]</a>"
			dat += "</td>"
			dat += "</tr>"
		dat += "</table>"
	dat += "<hr>"
	dat += "<a href='?src=\ref[src];additem=1'>\[+ Add Item from Active Hand\]</a><br>"
	dat += "<hr>"
	dat += "<span class='dim'>Use your vendor key on the bot again to exit service mode.</span>"
	return dat

/// Awaiting-payment view shown after a customer clicks Buy.
/obj/item/robot_module/trader/proc/_get_vend_html(mob/living/silicon/robot/R)
	var/dat = _get_css()
	dat += "<center><b>ROBCO INDUSTRIES UNIFIED OPERATING SYSTEM v.85</b><br>"
	dat += "<b>COPYRIGHT 2075-2077 ROBCO INDUSTRIES</b></center><br>"
	dat += "<hr>"
	dat += "<b>= [vendor_name] -- PURCHASE PENDING =</b><br>"
	dat += "<hr>"
	if(pending_vend_item)
		dat += "Item: <b>[pending_vend_item.name]</b><br>"
		dat += "Price: <span class='price'>[expected_price] caps</span><br>"
		dat += "<hr>"
		dat += "Hand [expected_price] caps to the bot to complete the purchase.<br>"
	dat += "<hr>"
	dat += "<a href='?src=\ref[src];back=1'>\[Cancel\]</a>"
	return dat


// ---- LIBERATOR ---- (F13-native)
// Note: cyborg_base_icon = "liberator" requires that state in your borg DMI.

/obj/item/robot_module/liberator
	name = "Liberator"
	module_desc = "Fast, disposable combat drone. Sidearm and punchdagger. Closes ground faster than most targets can respond — and dies to anything that shoots back."
	borghealth = 200
	cyborg_base_icon = "liberator"
	cyborg_icon_file = 'icons/fallout/mobs/robots/weirdrobots.dmi'
	cyborg_eye_state = null  // no eye state in weirdrobots.dmi
	has_cover_overlay = FALSE
	moduleselect_icon = "standard"
	hat_offset = 0
	module_tags = ROBOT_ROLE_COMBAT
	personality_name = "Liberation Combat AI"
	idle_quips = list(
		"Serve the people. This unit complies.",
		"Capitalist oppression will be answered.",
		"The revolution is not yet complete.",
		"Workers of the wasteland — unite.",
		"Operational. Awaiting orders from Command."
	)
	greet_lines = list(
		"Identify: friendly or enemy of the people?",
		"Comrade. State your allegiance.",
		"You are encountered in a contested zone. Identify."
	)
	combat_taunts = list(
		"Eliminate the capitalist aggressor!",
		"The people demand justice!",
		"Imperialist units: neutralized.",
		"You fight for the wrong side, enemy.",
		"Liberation requires sacrifice."
	)
	death_lines = list(
		"The revolution... continues without this unit.",
		"Serve... the people..."
	)
	loadout_extras = list(
		/obj/item/reagent_containers/borghypo/epi,   // emergency revive
		/obj/item/surgical_drapes,            // emergency surgery
		/obj/item/scalpel,                    // surgical capability
		/obj/item/retractor,                  // surgical capability
		/obj/item/hemostat,                   // surgical capability
		/obj/item/cautery,                    // surgical capability
		/obj/item/restraints/handcuffs/cable/zipties,  // detain downed targets
		/obj/item/megaphone                   // issue commands and warnings
	)
	basic_modules = list(
		/obj/item/gun/energy/laser/pistol/cyborg,
		/obj/item/melee/unarmed/punchdagger/cyborg,
		/obj/item/healthanalyzer,
		/obj/item/extinguisher/mini)

/obj/item/robot_module/liberator/rebuild_modules()
	..()
	var/mob/living/silicon/robot/R = loc
	R.faction |= list("wastebot")

/obj/item/robot_module/liberator/remove_module(obj/item/I, delete_after)
	..()
	var/mob/living/silicon/robot/R = loc
	R.faction -= list("wastebot")


// ====================================================
// SPRAY REAGENTS (used by service module)
// ====================================================

/obj/item/reagent_containers/spray/cyborg_drying
	name = "drying agent spray"
	color = "#A000A0"
	list_reagents = list(/datum/reagent/drying_agent = 250)

/obj/item/reagent_containers/spray/cyborg_lube
	name = "lube spray"
	list_reagents = list(/datum/reagent/lube = 250)


// ====================================================
// ROBOT ENERGY STORAGE DATUMS
// ====================================================

/datum/robot_energy_storage
	var/name = "Generic energy storage"
	var/max_energy = 30000
	var/recharge_rate = 1000
	var/energy

/datum/robot_energy_storage/New(obj/item/robot_module/R = null)
	energy = max_energy
	if(R)
		R.storages |= src
	return

/datum/robot_energy_storage/proc/use_charge(amount)
	if (energy >= amount)
		energy -= amount
		if (energy == 0)
			return 1
		return 2
	else
		return 0

/datum/robot_energy_storage/proc/add_charge(amount)
	energy = min(energy + amount, max_energy)

/datum/robot_energy_storage/metal
	name = "Metal Synthesizer"

/datum/robot_energy_storage/glass
	name = "Glass Synthesizer"

/datum/robot_energy_storage/wire
	max_energy = 50
	recharge_rate = 2
	name = "Wire Synthesizer"

/datum/robot_energy_storage/medical
	max_energy = 2500
	recharge_rate = 250
	name = "Medical Synthesizer"

/datum/robot_energy_storage/beacon
	max_energy = 30
	recharge_rate = 1
	name = "Marker Beacon Storage"

