/obj/effect/overlay
	name = "overlay"

/obj/effect/overlay/singularity_act()
	return

/obj/effect/overlay/singularity_pull()
	return

/obj/effect/overlay/beam//Not actually a projectile, just an effect.
	name="beam"
	icon='icons/effects/beam.dmi'
	icon_state="b_beam"
	var/atom/BeamSource

/obj/effect/overlay/beam/Initialize()
	. = ..()
	QDEL_IN(src, 10)

/obj/effect/overlay/palmtree_r
	name = "palm tree"
	icon = 'icons/misc/beach2.dmi'
	icon_state = "palm1"
	density = TRUE
	layer = WALL_OBJ_LAYER
	anchored = TRUE

/obj/effect/overlay/palmtree_l
	name = "palm tree"
	icon = 'icons/misc/beach2.dmi'
	icon_state = "palm2"
	density = TRUE
	layer = WALL_OBJ_LAYER
	anchored = TRUE

/obj/effect/overlay/catwalk
	name = ""
	icon = 'icons/obj/smooth_structures/catwalk.dmi'
	icon_state = "catwalk"
	color = "#000000"
	density = FALSE
	layer = FLY_LAYER
	anchored = TRUE
	alpha = 20
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/overlay/coconut
	gender = PLURAL
	name = "coconuts"
	icon = 'icons/misc/beach.dmi'
	icon_state = "coconuts"

/obj/effect/overlay/sparkles
	gender = PLURAL
	name = "sparkles"
	icon = 'icons/effects/effects.dmi'
	icon_state = "shieldsparkles"
	anchored = TRUE

/obj/effect/overlay/vis
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	vis_flags = VIS_INHERIT_DIR
	///When detected to be unused it gets set to world.time, after a while it gets removed
	var/unused = 0
	///overlays which go unused for this amount of time get cleaned up
	var/cache_expiration = 2 MINUTES

/obj/effect/overlay/light
	name = ""
	icon = 'icons/effects/light_overlays/light_cone.dmi'
	icon_state = "light"
	layer = BELOW_OBJ_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 110
	var/mutable_appearance/spotlightoverlay

/obj/effect/overlay/light/Initialize()
	. = ..()
	spotlightoverlay = mutable_appearance(icon, "[icon_state]overlay", ABOVE_ALL_MOB_LAYER)
	add_overlay(spotlightoverlay)

/obj/effect/overlay/curb
	name = "curb"
	desc = "A street curb."
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "curb"
	plane = FLOOR_PLANE
	layer = LATTICE_LAYER

/obj/effect/overlay/curb/north
	name = "curb"
	dir = NORTH
	
/obj/effect/overlay/curb/east
	name = "curb"
	dir = EAST

/obj/effect/overlay/curb/west
	name = "curb"
	dir = WEST

/obj/effect/overlay/curb/corner
	name = "curb"
	icon_state = "corner"

/obj/effect/overlay/curb/reno
	name = "curb"
	icon = 'icons/fallout/turfs/reno_sidewalk.dmi'
	icon_state = "curb"

/obj/effect/overlay/airplanewing
	name = "wing"
	icon = 'icons/turf/floors.dmi'
	icon_state = "airplane6"
	plane = FLOOR_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER
	dir = WEST
	density = FALSE
	anchored = TRUE
	pixel_x = 32

/obj/effect/overlay/airplanewing/bottom
	name = "wing"
	icon_state = "airplane5"
	pixel_x = -32

/obj/effect/overlay/bus
	name = ""
	icon = 'icons/obj/vehicles/bus2.dmi'
	icon_state = "blue"
	density = FALSE
	layer = WALL_OBJ_LAYER
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/overlay/bus/top
	name = "bus"
	icon = 'icons/obj/vehicles/bus1.dmi'
	icon_state = "blue_upper"

/obj/effect/overlay/bus/orange
	name = ""
	icon_state = "orange"

/obj/effect/overlay/bus/rusty
	name = "bus"
	icon = 'icons/obj/vehicles/rustybus.dmi'
	icon_state = "bus_lower_half"

/obj/effect/overlay/shoreline
	name = "shore"
	icon = 'icons/fallout/turfs/smoothing.dmi'
	icon_state = "rockfloor_side"
	density = FALSE
	layer = VISIBLE_FROM_ABOVE_LAYER
	anchored = TRUE
	dir = NORTH

/obj/effect/overlay/shoreline/east
	name = "shore"
	dir = EAST

/obj/effect/overlay/shoreline/west
	name = "shore"
	dir = WEST

/obj/effect/overlay/shoreline/south
	name = "shore"
	dir = SOUTH
	pixel_y = -2

/obj/effect/overlay/painting
	name = "painting"
	icon = 'icons/effects/crayondecal.dmi'
	icon_state = "face"
	layer = LOW_OBJ_LAYER

/obj/effect/overlay/painting/graffiti
	name = "graffiti"
	plane = WALL_PLANE

/obj/effect/overlay/whitelegpainting
	name = "painting"
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "wlpaint"
	layer = ABOVE_WINDOW_LAYER

/obj/effect/overlay/whitelegpainting/two
	name = "painting"
	icon_state = "wlpaint2"

/obj/effect/overlay/legionpainting
	name = "painting"
	icon = 'icons/obj/card.dmi'
	icon_state = "legionbrand"
	color = "#800000"
	icon_state = "wlpaint"
	plane = WALL_PLANE
	layer = ABOVE_WINDOW_LAYER

/obj/effect/overlay/targetpainting
	name = "painting"
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "sniper_zoom"
	plane = WALL_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER

/obj/effect/overlay/bloodyart
	name = "art"
	icon = 'icons/fallout/objects/decals.dmi'
	icon_state = "blood_pic_1"
	plane = GAME_PLANE
	layer = LOW_OBJ_LAYER


/obj/effect/overlay/shadow
	name = ""
	icon = 'icons/fallout/turfs/sidewalk.dmi'
	icon_state = "outermiddle"
	color = "#000000"
	layer = FLY_LAYER
	alpha = 50
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/overlay/shadow/tarp
	name = ""
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "vertarpaulin2"
	alpha = 255

/obj/effect/overlay/shadow/tent
	name = ""
	icon = 'icons/fallout/turfs/walls/tents.dmi'
	icon_state = "outermiddle"

/obj/effect/overlay/shadow/redrocketone
	name = ""
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "redrocketbits"
	alpha = 150

/obj/effect/overlay/shadow/redrockettwo
	name = ""
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "redrocketbits2"
	alpha = 150

/obj/effect/overlay/shadow/redrocketthree
	name = ""
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "redrocketbits3"
	alpha = 150

/obj/effect/overlay/shadow/redrocketfour
	name = ""
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "redrocketbits4"
	alpha = 150

/obj/effect/overlay/shadow/edgeshading
	name = ""
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "edgeshading"
	plane = FLOOR_PLANE
	layer = TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/overlay/shadow/shading
	name = ""
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "shading"
	layer = TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/overlay/shadow/diagonal
	name = ""
	icon = 'icons/turf/decals.dmi'
	icon_state = "diagonalroad"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/overlay/shadow/diagonal/north
	name = ""
	dir = NORTH

/obj/effect/overlay/shadow/diagonal/east
	name = ""
	dir = EAST

/obj/effect/overlay/shadow/diagonal/west
	name = ""
	dir = WEST

/obj/effect/overlay/airliner
	name = "Advertisement"
	desc = "When was the last time you went on vacation?"
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "airlinetext"
	plane = WALL_PLANE

/obj/effect/overlay/baseball
	name = "baseball diamond"
	desc = "Sporting dirt."
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "ballpark3"
	plane = FLOOR_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER

/obj/effect/overlay/concretebase
	name = "concrete base"
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "railingconcrete"
	plane = GAME_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER

/obj/effect/overlay/concretebase/extra
	name = "concrete base"
	icon_state = "railingconcreteextra"

/obj/effect/overlay/redrocket
	name = "Red Rocket"
	icon = 'icons/fallout/objects/redrocketredux.dmi'
	icon_state = "redrocketbits"
	plane = GAME_PLANE
	layer = FLY_LAYER

/obj/effect/overlay/fence
	name = "fence"
	icon = 'icons/fallout/structures/fences.dmi'
	icon_state = "straight"
	plane = WALL_PLANE
	layer = TRAY_LAYER

/obj/effect/overlay/sidewalk
	name = "isle"
	icon = 'icons/fallout/turfs/sidewalk.dmi'
	icon_state = "transparent"
	plane = FLOOR_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER
	pixel_y = 6

/obj/effect/overlay/porch
	name = "porch"
	icon = 'icons/turf/floors.dmi'
	icon_state = "housewood_stage_bottom"
	plane = FLOOR_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER
	pixel_y = -1

/obj/effect/overlay/stair
	name = "stairs"
	icon = 'icons/obj/stairs.dmi'
	icon_state = "stairs"
	color = "#faf0b9"
	plane = FLOOR_PLANE
	layer = OBJ_LAYER
	pixel_y = 1
	dir = NORTH

/obj/effect/overlay/cross
	name = "canopy"
	icon = 'icons/obj/graveyard.dmi'
	icon_state = "wooden"
	color = "#ffdd00"
	plane = GAME_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER

/obj/effect/overlay/plaque
	icon = 'icons/fallout/objects/decals.dmi'
	icon_state = "memorial"
	plane = GAME_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER

/obj/effect/overlay/moviescreen
	name = "movie screen"
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "flash"
	color = "#b4b5ac"
	plane = GAME_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER

/obj/effect/overlay/backdrop
	name = "backdrop"
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "flash"
	color = "#55b8fa"
	plane = WALL_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER
	pixel_y = 32

/obj/effect/overlay/dmvpainting
	name = "backdrop"
	icon = 'icons/turf/vgstation_decals.dmi'
	icon_state = "8"
	color = "#FFFFFF"
	plane = ABOVE_WALL_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER
	pixel_x = -6
	pixel_y = 32

/obj/effect/overlay/dmvpainting/zero
	name = "backdrop"
	icon_state = "0"
	pixel_x = 6

/obj/effect/overlay/canopy
	name = "canopy"
	icon = 'icons/fallout/turfs/sidewalk.dmi'
	icon_state = "transparent"
	plane = FLOOR_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER

/obj/effect/overlay/roadmarking
	name = "road marking"
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "whiteroadstripe"
	plane = FLOOR_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER
	dir = WEST

/obj/effect/overlay/roadmarking/horizontal
	name = "road marking"
	dir = SOUTH

/obj/effect/overlay/infuriatingroad
	name = "road"
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "infuriatingroad"
	plane = FLOOR_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER

/obj/effect/overlay/carpile
	name = "car pile"
	icon = 'icons/fallout/objects/redrocketredux.dmi'
	icon_state = "carpile_lower"
	plane = GAME_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pixel_x = -330

/obj/effect/overlay/carpile/top
	name = "car pile"
	icon_state = "carpile_upper"
	layer = EDGED_TURF_LAYER
	pixel_x = -320

/obj/effect/overlay/fukbus
	name = "Fuk Bus"
	icon = 'icons/fallout/objects/fukbus.dmi'
	icon_state = "fukbus"
	plane = GAME_PLANE
	layer = OBJ_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pixel_x = -480
	pixel_y = 32

/obj/effect/overlay/rv
	name = "RV"
	icon = 'icons/fallout/vehicles/rv.dmi'
	icon_state = "bottom"
	plane = GAME_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/overlay/isle
	name = "isle"
	icon = 'icons/fallout/objects/gasstation.dmi'
	icon_state = "isle"
	plane = FLOOR_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER
	dir = SOUTHEAST
	pixel_x = -32
	pixel_y = -163

/obj/effect/overlay/isle/bottom
	name = "isle"
	pixel_x = -32
	pixel_y = 29

/obj/effect/overlay/mailarrow
	name = "concrete arrow"
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "mailarrow"
	plane = FLOOR_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER

/obj/effect/overlay/florapainting
	name = "painting"
	icon = 'icons/obj/flora/ausflora.dmi'
	icon_state = "bottom"
	plane = WALL_PLANE
	layer = WIRE_LAYER

/obj/effect/overlay/chinesepainting
	name = "painting"
	icon = 'icons/fallout/mobs/humans/ghouls.dmi'
	icon_state = "chinesesoldier"
	plane = WALL_PLANE
	layer = DISPOSAL_PIPE_LAYER

/obj/effect/overlay/treepainting
	name = "painting"
	icon = 'icons/obj/custom.dmi'
	icon_state = "pine_c"
	plane = WALL_PLANE
	layer = WIRE_LAYER

/obj/effect/overlay/snowpainting
	name = "painting"
	icon = 'icons/turf/snow.dmi'
	icon_state = "snow_corner"
	plane = WALL_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER

/obj/effect/overlay/rope
	name = "rope"
	icon = 'icons/obj/power_cond/cables.dmi'
	icon_state = "5-8"
	color = "#cfc39b"
	plane = GAME_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER

/obj/effect/overlay/floor
	name = "floor"
	icon = 'icons/fallout/turfs/floors.dmi'
	icon_state = "floor"
	plane = FLOOR_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER

/obj/effect/overlay/metalfloor
	name = "metal floor"
	icon = 'icons/fallout/turfs/ground.dmi'
	icon_state = "tunneldirty"
	plane = FLOOR_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER

/obj/effect/overlay/metalfloor/alt
	name = "metal floor"
	icon = 'icons/fallout/turfs/ground.dmi'
	icon_state = "plating"
	pixel_x = 15

/obj/effect/overlay/waterlow
	name = "water"
	icon = 'icons/turf/pool.dmi'
	icon_state = "altunderlay"
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = FLOOR_PLANE
	layer = ABOVE_OBJ_LAYER

/obj/effect/overlay/graveloffset
	name = "gravel"
	icon = 'icons/fallout/turfs/ground.dmi'
	icon_state = "graveldirt"
	pixel_x = 16
	plane = FLOOR_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER

/obj/effect/overlay/graveldiagonal
	name = "gravel"
	icon = 'icons/fallout/turfs/gravel.dmi'
	icon_state = "siding"
	plane = FLOOR_PLANE
	layer = VISIBLE_FROM_ABOVE_LAYER

/obj/effect/overlay/vrwater
	name = "water"
	icon = 'icons/misc/beach.dmi'
	icon_state = "water"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = ABOVE_WALL_PLANE
	layer = ABOVE_OBJ_LAYER

/obj/effect/overlay/nothing
	name = ""
	icon = 'icons/turf/space.dmi'
	icon_state = "black"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = ABOVE_WALL_PLANE
	layer = ABOVE_OBJ_LAYER

/obj/effect/overlay/denserock
	name = "rock"
	icon = 'icons/fallout/turfs/mining.dmi'
	icon_state = "rock"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = FLOOR_PLANE
	layer = ABOVE_OBJ_LAYER

/obj/effect/overlay/icerock
	name = "rock"
	icon = 'icons/turf/mining.dmi'
	icon_state = "icerock"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = FLOOR_PLANE
	layer = ABOVE_OBJ_LAYER

/obj/effect/overlay/rustedwall
	name = "wall"
	icon = 'icons/turf/walls/rusty_wall.dmi'
	icon_state = "wall"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = WALL_PLANE
	layer = ABOVE_OBJ_LAYER

/obj/effect/overlay/rubble
	name = "rubble"
	icon = 'icons/fallout/turfs/ground.dmi'
	icon_state = "rubblefull"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = WALL_PLANE
	layer = ABOVE_OBJ_LAYER

/obj/effect/overlay/window
	name = "window"
	icon = 'icons/obj/wood_window.dmi'
	icon_state = "housewindow"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = WALL_PLANE
	layer = ABOVE_WINDOW_LAYER

/obj/effect/overlay/ruinedwindow
	name = "window"
	icon = 'icons/obj/wood_window.dmi'
	icon_state = "ruinswindowbroken"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = WALL_PLANE
	layer = ABOVE_WINDOW_LAYER

/obj/effect/overlay/gothicwall
	name = "gothic wall"
	icon = 'icons/turf/walls/gothic_wall.dmi'
	icon_state = "wall_facade"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = WALL_PLANE
	layer = ABOVE_OBJ_LAYER
