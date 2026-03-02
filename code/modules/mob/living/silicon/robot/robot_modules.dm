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

// Ensure module properly clears robot reference
/obj/item/robot_module/Destroy()
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
	basic_modules = list(
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/reagent_containers/borghypo/epi,
		/obj/item/healthanalyzer,
		/obj/item/weldingtool/largetank/cyborg,
		/obj/item/wrench/cyborg,
		/obj/item/stack/sheet/metal/cyborg,
		/obj/item/stack/rods/cyborg,
		/obj/item/pickaxe,
		/obj/item/t_scanner/adv_mining_scanner,
		/obj/item/restraints/handcuffs/cable/zipties,
		/obj/item/soap/nanotrasen,
		/obj/item/borg/cyborghug)
	moduleselect_icon = "standard"
	hat_offset = -3


// ---- MEDICAL ----

/obj/item/robot_module/medical
	name = "Medical"
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
	basic_modules = list(
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/restraints/handcuffs/cable/zipties,
		/obj/item/gun/energy/disabler/cyborg,
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

/obj/item/robot_module/miner
	name = "Miner"
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
		/obj/item/stack/marker_beacon,
		/obj/item/stack/packageWrap)
	cyborg_base_icon = "miner"
	moduleselect_icon = "miner"
	hat_offset = 0


// ---- MR. GUTSY ---- (already F13-native)

/obj/item/robot_module/gutsy
	name = "Gutsy"
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
	moduleselect_icon = "standard"
	hat_offset = -2


// ---- ASSAULTRON ---- (already F13-native)

/obj/item/robot_module/assaultron
	name = "Assaultron"
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
	moduleselect_icon = "security"
	hat_offset = 3

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


// ---- MR. HANDY ---- (F13-native)

/obj/item/robot_module/handy
	name = "Mr. Handy"
	borghealth = 200
	cyborg_base_icon = "handy"
	moduleselect_icon = "standard"
	hat_offset = -2
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
	borghealth = 250
	cyborg_base_icon = "protectron"
	moduleselect_icon = "security"
	hat_offset = 0
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
	borghealth = 500
	cyborg_base_icon = "securitron"
	moduleselect_icon = "security"
	hat_offset = 0
	basic_modules = list(
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/gun/energy/laser/pistol/cyborg,
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
	borghealth = 600
	cyborg_base_icon = "sentrybot"
	moduleselect_icon = "security"
	hat_offset = 0
	basic_modules = list(
		/obj/item/extinguisher/mini,
		/obj/item/gun/energy/laser/pistol/cyborg,
		/obj/item/megaphone,
		/obj/item/pinpointer/crew)
	emag_modules = list(
		/obj/item/gun/energy/laser/cyborg)

/obj/item/robot_module/sentrybot/rebuild_modules()
	..()
	var/mob/living/silicon/robot/R = loc
	R.faction |= list("wastebot")

/obj/item/robot_module/sentrybot/remove_module(obj/item/I, delete_after)
	..()
	var/mob/living/silicon/robot/R = loc
	R.faction -= list("wastebot")


// ---- LIBERATOR ---- (F13-native)
// Note: cyborg_base_icon = "liberator" requires that state in your borg DMI.

/obj/item/robot_module/liberator
	name = "Liberator"
	borghealth = 150
	cyborg_base_icon = "liberator"
	moduleselect_icon = "standard"
	hat_offset = 0
	basic_modules = list(
		/obj/item/gun/energy/laser/pistol/cyborg,
		/obj/item/healthanalyzer,
		/obj/item/t_scanner/adv_mining_scanner,
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

