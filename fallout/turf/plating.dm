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
