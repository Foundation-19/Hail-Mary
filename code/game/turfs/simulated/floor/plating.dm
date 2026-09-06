/* In this file:
 *
 * Plating
 * Airless
 * Airless plating
 * Engine floor
 * Foam plating
 */

/turf/open/floor/plating
	name = "plating"
	icon_state = "plating"
	intact = FALSE
	baseturfs = /turf/open/indestructible/ground/outside/desert
	footstep = FOOTSTEP_PLATING
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY

	var/attachment_holes = TRUE

/turf/open/floor/plating/examine(mob/user)
	. = ..()
	if(broken || burnt)
		. += "<span class='notice'>It looks like the dents could be <i>welded</i> smooth.</span>"
		return
	if(attachment_holes)
		. += "<span class='notice'>There are a few attachment holes for a new <i>tile</i> or reinforcement <i>rods</i>.</span>"
	else
		. += "<span class='notice'>You might be able to build ontop of it with some <i>tiles</i>...</span>"

/turf/open/floor/plating/Initialize()
	if (!broken_states)
		broken_states = list("platingdmg1", "platingdmg2", "platingdmg3")
	if (!burnt_states)
		burnt_states = list("panelscorched")
	. = ..()
	if(!attachment_holes || (!broken && !burnt))
		icon_plating = icon_state
	else
		icon_plating = initial(icon_state)

/turf/open/floor/plating/update_icon()
	if(!..())
		return
	if(!broken && !burnt)
		icon_state = icon_plating //Because asteroids are 'platings' too.

/turf/open/floor/plating/attackby(obj/item/C, mob/user, params)
	if(..())
		return
	if(istype(C, /obj/item/stack/rods) && attachment_holes)
		if(broken || burnt)
			to_chat(user, span_warning("Repair the plating first!"))
			return
		var/obj/item/stack/rods/R = C
		if (R.get_amount() < 2)
			to_chat(user, span_warning("You need two rods to make a reinforced floor!"))
			return
		else
			to_chat(user, span_notice("You begin reinforcing the floor..."))
			if(do_after(user, 30, target = src))
				if (R.get_amount() >= 2 && !istype(src, /turf/open/floor/engine))
					PlaceOnTop(/turf/open/floor/engine, flags = CHANGETURF_INHERIT_AIR)
					playsound(src, 'sound/items/deconstruct.ogg', 80, 1)
					R.use(2)
					to_chat(user, span_notice("You reinforce the floor."))
				return

	if(istype(C, /obj/item/stack/sheet/glass))
		if(broken || burnt)
			to_chat(user, span_warning("Repair the plating first!"))
			return
		var/obj/item/stack/sheet/glass/G = C
		if (G.get_amount() < 2)
			to_chat(user, span_warning("You need two glass sheets to make a glass floor!"))
			return
		else
			to_chat(user, span_notice("You begin adding glass to the floor..."))
			if(do_after(user, 5, target = src))
				if (G.get_amount() >= 2 && !istype(src, /turf/open/transparent/glass))
					PlaceOnTop(/turf/open/transparent/glass, flags = CHANGETURF_INHERIT_AIR)
					playsound(src, 'sound/items/deconstruct.ogg', 80, 1)
					G.use(2)
					to_chat(user, span_notice("You add glass to the floor."))
				return
	if(istype(C, /obj/item/stack/sheet/rglass))
		if(broken || burnt)
			to_chat(user, span_warning("Repair the plating first!"))
			return
		var/obj/item/stack/sheet/rglass/RG = C
		if (RG.get_amount() < 2)
			to_chat(user, span_warning("You need two reinforced glass sheets to make a reinforced glass floor!"))
			return
		else
			to_chat(user, span_notice("You begin adding reinforced glass to the floor..."))
			if(do_after(user, 10, target = src))
				if (RG.get_amount() >= 2 && !istype(src, /turf/open/transparent/glass/reinforced))
					PlaceOnTop(/turf/open/transparent/glass/reinforced, flags = CHANGETURF_INHERIT_AIR)
					playsound(src, 'sound/items/deconstruct.ogg', 80, 1)
					RG.use(2)
					to_chat(user, span_notice("You add reinforced glass to the floor."))
				return

	else if(istype(C, /obj/item/stack/tile))
		if(!broken && !burnt)
			for(var/obj/O in src)
				if(O.level == 1) //ex. pipes laid underneath a tile
					for(var/M in O.buckled_mobs)
						to_chat(user, span_warning("Someone is buckled to \the [O]! Unbuckle [M] to move \him out of the way."))
						return
			var/obj/item/stack/tile/W = C
			if(!W.use(1))
				return
			if(istype(W, /obj/item/stack/tile/material))
				var/turf/newturf = PlaceOnTop(/turf/open/floor/material, flags = CHANGETURF_INHERIT_AIR)
				newturf.set_custom_materials(W.custom_materials)
			else if(W.turf_type)
				var/turf/open/floor/T = PlaceOnTop(W.turf_type, flags = CHANGETURF_INHERIT_AIR)
				if(istype(W, /obj/item/stack/tile/light)) //TODO: get rid of this ugly check somehow
					var/obj/item/stack/tile/light/L = W
					var/turf/open/floor/light/F = T
					F.state = L.state
			playsound(src, 'sound/weapons/genhit.ogg', 50, 1)
		else
			to_chat(user, span_warning("This section is too damaged to support a tile! Use a welder to fix the damage."))

	if(istype(C, /obj/item/stack/sheet/mineral/concrete))
		if(broken || burnt)
			to_chat(user, span_warning("Repair the plating first!"))
			return
		var/obj/item/stack/sheet/mineral/concrete/G = C
		if (G.get_amount() < 2)
			to_chat(user, span_warning("You need two concrete bags to make a concrete floor!"))
			return
		else
			to_chat(user, span_notice("You begin pouring concrete on to the floor..."))
			if(do_after(user, 5, target = src))
				if (G.get_amount() >= 2 && !istype(src, /turf/open/floor/plasteel/f13/vault_floor/floor/floorsolid))
					PlaceOnTop(/turf/open/floor/plasteel/f13/vault_floor/floor/floorsolid, flags = CHANGETURF_INHERIT_AIR)
					playsound(src, 'sound/items/deconstruct.ogg', 80, 1)
					G.use(2)
					to_chat(user, span_notice("You smooth the floor with concrete."))
				return


/turf/open/floor/plating/welder_act(mob/living/user, obj/item/I)
	if((broken || burnt) && I.use_tool(src, user, 0, volume=80))
		to_chat(user, span_danger("You fix some dents on the broken plating."))
		icon_state = icon_plating
		burnt = FALSE
		broken = FALSE

	return TRUE

/turf/open/floor/plating/rust_heretic_act()
	if(prob(70))
		new /obj/effect/temp_visual/glowing_rune(src)
	ChangeTurf(/turf/open/floor/plating/rust)

/turf/open/floor/plating/make_plating()
	return

/turf/open/floor/plating/foam
	name = "metal foam plating"
	desc = "Thin, fragile flooring created with metal foam."
	icon_state = "foam_plating"

/turf/open/floor/plating/foam/burn_tile()
	return //jetfuel can't melt steel foam

/turf/open/floor/plating/foam/break_tile()
	return //jetfuel can't break steel foam...

/turf/open/floor/plating/foam/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/tile/plasteel))
		var/obj/item/stack/tile/plasteel/P = I
		if(P.use(1))
			var/obj/L = locate(/obj/structure/lattice) in src
			if(L)
				qdel(L)
			to_chat(user, span_notice("You reinforce the foamed plating with tiling."))
			playsound(src, 'sound/weapons/Genhit.ogg', 50, TRUE)
			ChangeTurf(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)
	else
		playsound(src, 'sound/weapons/tap.ogg', 100, TRUE) //The attack sound is muffled by the foam itself
		user.DelayNextAction(CLICK_CD_MELEE)
		user.do_attack_animation(src)
		if(prob(I.force * 20 - 25))
			user.visible_message(span_danger("[user] smashes through [src]!"), \
							span_danger("You smash through [src] with [I]!"))
			ScrapeAway(flags = CHANGETURF_INHERIT_AIR)
		else
			to_chat(user, span_danger("You hit [src], to no effect!"))

/turf/open/floor/plating/foam/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if(the_rcd.mode == RCD_FLOORWALL)
		return list("mode" = RCD_FLOORWALL, "delay" = 0, "cost" = 1)

/turf/open/floor/plating/foam/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	if(passed_mode == RCD_FLOORWALL)
		to_chat(user, span_notice("You build a floor."))
		ChangeTurf(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)
		return TRUE
	return FALSE

/turf/open/floor/plating/foam/ex_act()
	..()
	ScrapeAway(flags = CHANGETURF_INHERIT_AIR)

/turf/open/floor/plating/foam/tool_act(mob/living/user, obj/item/I, tool_type)
	return


// ==================== Merged from fallout (code\modules\fallout\turf\plating.dm) ====================
//Fallout 13 floor plating directory

// -------------------------------------------------------------------------
// Vault floor tile & plating
// -------------------------------------------------------------------------

/// Saved-state vars used by F13 spawn_tile overrides.
/obj/item/stack/tile
	var/saved_turf_type = null
	var/saved_icon_state = null

/// Tile item dropped when an F13 vault floor is crowbarred.
/// Carries a saved_turf_type so the exact vault subtype (e.g. /red/redchess)
/// is recreated when placed back, rather than the generic plasteel parent.
/obj/item/stack/tile/f13_vault
	name = "vault floor tile"
	singular_name = "vault floor tile"
	desc = "A scuffed metal floor tile salvaged from a Vault-Tec facility."
	icon = 'icons/turf/f13floors2.dmi'
	icon_state = "vault_floor"
	turf_type = /turf/open/floor/plasteel/f13/vault_floor
	merge_type = /obj/item/stack/tile/f13_vault

/// Plating left behind when a vault floor tile is removed.
/// Uses the same f13floors2.dmi spritesheet as vault floor tiles so that
/// icon_regular_floor (stored by ChangeTurf) stays valid across the full
/// remove → plating → replace cycle; the ChangeTurf fix then applies it.
/turf/open/floor/plating/f13_vault
	name = "vault floor plating"
	icon = 'icons/turf/f13floors2.dmi'
	icon_state = "plating"
	planetary_atmos = FALSE
	baseturfs = /turf/open/floor/plating/f13_vault

/// When a tile is placed on vault plating and it carries a saved_turf_type,
/// restore the exact vault floor subtype (then ChangeTurf applies the icon).
/// Falls through to the parent plating attackby for anything else.
/turf/open/floor/plating/f13_vault/attackby(obj/item/C, mob/user, params)
	if(istype(C, /obj/item/stack/tile) && !broken && !burnt)
		var/obj/item/stack/tile/W = C
		if(W.saved_turf_type)
			for(var/obj/O in src)
				if(O.level == 1)
					for(var/M in O.buckled_mobs)
						to_chat(user, span_warning("Someone is buckled to \the [O]! Unbuckle [M] to move them out of the way."))
						return
			if(!W.use(1))
				return
			PlaceOnTop(W.saved_turf_type, flags = CHANGETURF_INHERIT_AIR)
			playsound(src, 'sound/weapons/genhit.ogg', 50, 1)
			return
	return ..()

// -------------------------------------------------------------------------
// F13 wood floor tile
// -------------------------------------------------------------------------

/// Dropped when an F13 wood floor is removed with screwdriver or crowbar.
/// saved_icon_state carries the variant (housewood1–4) so re-placement restores it.
/obj/item/stack/tile/f13_wood
	name = "wooden floor tile"
	singular_name = "wooden floor tile"
	desc = "An easy to fit wood floor tile."
	icon_state = "tile-wood"
	turf_type = /turf/open/floor/f13/wood
	resistance_flags = FLAMMABLE
	merge_type = /obj/item/stack/tile/f13_wood

// -------------------------------------------------------------------------

/turf/open/floor/plating/wooden
	name = "house base"
	icon_state = "housebase"
	icon = 'icons/turf/ground.dmi'
	intact = 0
	broken_states = list("housebase1-broken", "housebase2-broken", "housebase3-broken", "housebase4-broken")
	burnt_states = list("housebase_burnt")
//	step_sounds = list("human" = "woodfootsteps")

/// Re-place an f13 wood tile, restoring the exact visual variant it had before removal.
/turf/open/floor/plating/wooden/attackby(obj/item/C, mob/user, params)
	if(istype(C, /obj/item/stack/tile/f13_wood))
		var/obj/item/stack/tile/f13_wood/W = C
		if(!W.use(1))
			return
		var/saved = W.saved_icon_state
		var/px = x; var/py = y; var/pz = z
		PlaceOnTop(/turf/open/floor/f13/wood, flags = CHANGETURF_INHERIT_AIR)
		if(saved)
			var/turf/open/floor/f13/wood/new_floor = locate(px, py, pz)
			if(new_floor)
				new_floor.icon_state = saved
				new_floor.update_icon()
		playsound(locate(px, py, pz), 'sound/weapons/genhit.ogg', 50, 1)
		return
	return ..()

/turf/open/floor/plating/wooden/make_plating()
	return src

/turf/open/floor/plating/tunnel
	name = "metal floor"
	icon_state = "tunneldirty"
	icon = 'icons/turf/ground.dmi'
	baseturfs = /turf/open/indestructible/ground/inside/mountain

/turf/open/floor/plating/tunnel/curb
	name = "metal floor"
	icon_state = "tunneldirtycurb"

/turf/open/floor/plating/tunnel/rail
	name = "subway rail"
	icon_state = "tunneldirtyrail"

/turf/open/floor/plating/tunnel/rail/east
	name = "subway rail"
	dir = EAST

/turf/open/floor/plating/tunnel/rail/west
	name = "subway rail"
	dir = WEST

/turf/open/floor/plating/tunnel/rail/north
	name = "subway rail"
	dir = NORTH

/turf/open/floor/plating/tunnel/lit
	sunlight_state = SUNLIGHT_SOURCE
