/// How long an owner has to be offline or dead before other players may take their structures apart
#define BUILD_OWNER_ABSENT_TIME (30 MINUTES)
/// Using one of these on a structure is treated as taking it apart, so it is gated by ownership
#define BUILD_DECONSTRUCT_TOOLS list(TOOL_WRENCH, TOOL_CROWBAR, TOOL_SCREWDRIVER, TOOL_WIRECUTTER, TOOL_WELDER)

/// ckey => 0 while that owner is around, or the world.time they were first seen absent. Only owners are tracked.
GLOBAL_LIST_EMPTY(build_owner_away)
GLOBAL_VAR(build_owner_timer)

/**
 * Anti-grief ownership for structures built through the buildable path (stack make link and placement mode).
 *
 * The builder's ckey is stored on the structure and only that player, an admin, or anyone once the owner has
 * been offline or dead for BUILD_OWNER_ABSENT_TIME may take it apart. The check sits in
 * /obj/item/proc/melee_attack_chain() ahead of tool_act() and attackby(), so every structure keeps its own
 * deconstruction code and the same rule covers all of them.
 *
 * Structures with no owner are free to take apart, except map-placed ones of a family flagged
 * build_ownable, which only admins may take apart.
 */
/obj/structure
	var/build_owner_ckey
	var/build_owner_name
	/// Map-placed structures of this type are protected base structures
	var/build_ownable = FALSE
	var/build_map_loaded = FALSE

/obj/structure/window
	build_ownable = TRUE

/obj/structure/windoor_assembly
	build_ownable = TRUE

/obj/structure/girder
	build_ownable = TRUE

/obj/structure/grille
	build_ownable = TRUE

/obj/structure/barricade
	build_ownable = TRUE

/obj/structure/railing
	build_ownable = TRUE

/obj/structure/fence
	build_ownable = TRUE

/obj/structure/simple_door
	build_ownable = TRUE

/obj/structure/mineral_door
	build_ownable = TRUE

/obj/structure/door_assembly
	build_ownable = TRUE

/obj/structure/obstacle/barbedwire
	build_ownable = TRUE

/// Records the builder as the owner. Does nothing for builders with no ckey, such as NPCs.
/obj/structure/proc/set_build_owner(mob/user)
	if(!user?.ckey)
		return
	build_owner_ckey = user.ckey
	build_owner_name = user.real_name
	register_build_owner(user.ckey)

/// Ownership carries over when a structure turns into another one and fingerprints are handed on (girder to reinforced girder, window assembly to window and so on)
/obj/structure/transfer_fingerprints_to(atom/A)
	. = ..()
	var/obj/structure/target = A
	if(build_owner_ckey && istype(target) && !target.build_owner_ckey)
		target.build_owner_ckey = build_owner_ckey
		target.build_owner_name = build_owner_name

/// Returns the reason user may not take this apart with tool, or null if they may.
/obj/structure/proc/deconstruct_blocked(mob/user, obj/item/tool)
	if(!(tool.tool_behaviour in BUILD_DECONSTRUCT_TOOLS))
		return null
	return build_protection_message(user)

/// The reason user may not take this apart by any means, or null if they may. Used by tools and by the RCD.
/obj/structure/proc/build_protection_message(mob/user)
	if(user?.client && check_rights_for(user.client, R_ADMIN))
		return null
	if(!build_owner_ckey)
		if(build_ownable && build_map_loaded)
			return "[capitalize(src.name)] is part of the settlement and can't be taken apart."
		return null
	if(user?.ckey == build_owner_ckey)
		return null
	if(build_owner_absent_for(build_owner_ckey) >= BUILD_OWNER_ABSENT_TIME)
		return null
	return "[capitalize(src.name)] belongs to [build_owner_name]. You can't take it apart while they are around."

/proc/register_build_owner(ckey)
	if(isnull(GLOB.build_owner_away[ckey]))
		GLOB.build_owner_away[ckey] = 0
	if(!GLOB.build_owner_timer)
		GLOB.build_owner_timer = addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(refresh_build_owner_presence)), 1 MINUTES, TIMER_LOOP | TIMER_STOPPABLE)

/// An owner counts as present while they are connected and alive.
/proc/build_owner_present(ckey)
	var/client/C = GLOB.directory[ckey]
	return C && isliving(C.mob) && C.mob.stat != DEAD

/proc/refresh_build_owner_presence()
	for(var/ckey in GLOB.build_owner_away)
		if(build_owner_present(ckey))
			GLOB.build_owner_away[ckey] = 0
		else if(!GLOB.build_owner_away[ckey])
			GLOB.build_owner_away[ckey] = world.time

/// How long the owner has been gone, or 0 if they are around. Checked live so a returning owner is never treated as gone.
/proc/build_owner_absent_for(ckey)
	if(build_owner_present(ckey))
		return 0
	var/since = GLOB.build_owner_away[ckey]
	return since ? world.time - since : 0
