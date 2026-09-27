// Fog-of-war reveal granularity, in tiles per chunk -- baked once into the meta image at
// bake time (see /datum/minimap/New()), never regenerated at runtime.
#define MINIMAP_CHUNK_SIZE 4

/datum/minimap
	var/name = "minimap"
	var/icon/overlay_icon
	// The map icons
	var/icon/map_icon
	var/icon/meta_icon

	var/list/color_area_names = list()

	var/minx
	var/maxx
	var/miny
	var/maxy

	// The actual bounds the map/meta icons were Scale()'d to -- distinct from minx/miny/maxx/maxy
	// (which only track the discovered content bounding box). get_pixel_position() must flip/offset
	// against THESE, not the content box, or on-screen positions drift by the size of the empty
	// border whenever the content box doesn't reach the map's edges.
	var/img_x1
	var/img_y2

	var/z_level
	var/id = ""
	// Cached once so New()/send()/ui_static_data() can't drift out of sync on the naming scheme.
	var/map_asset_name
	var/meta_asset_name
	// Chunk key ("cx-cy") -> meta color, baked once at bake time -- used both for the hover-name
	// lookup and as the fog-of-war reveal granularity (see get_revealed_colors()). Never touched
	// again after New(), unlike the old per-move icon registration this replaced.
	var/list/chunk_to_color = list()

/datum/minimap/New(z, x1 = 1, y1 = 1, x2 = world.maxx, y2 = world.maxy, name = "minimap")
	if(!z)
		CRASH("ERROR: new minimap requested without z level") //CRASH to halt the operation

	src.name = name
	z_level = z
	id = "[md5("[z_level]" + src.name + REF(src))]" //use it's own md5 as a special identifier
	map_asset_name = "minimap-[id].png"
	meta_asset_name = "minimap-[id]-meta.png"

	minx = x2
	maxx = x1
	miny = y2
	maxy = y1
	img_x1 = x1
	img_y2 = y2

	// do the generating
	map_icon = new('html/blank.png')
	meta_icon = new('html/blank.png')
	map_icon.Scale(x2 - x1 + 1, y2 - y1 + 1) // arrays start at 1
	meta_icon.Scale(x2 - x1 + 1, y2 - y1 + 1)

	// Keyed by "icon-icon_state-dir" so turfs sharing the same appearance (which is most
	// of them) only ever sample one throwaway /icon instead of allocating one per tile --
	// doing this per-turf across a whole map was enough new /icon objects to crash the server.
	var/list/turf_color_cache = list()

	for(var/turf/T in block(locate(x1, y1, z_level), locate(x2, y2, z_level)))
		CHECK_TICK // baking a whole z-level's worth of turfs in one go used to freeze the server at round start
		var/area/A = T.loc
		var/img_x = T.x - x1 + 1 // arrays start at 1
		var/img_y = T.y - y1 + 1
		if(!istype(A, /area/space) || istype(T, /turf/closed/wall))
			minx = min(minx, T.x)
			maxx = max(maxx, T.x)
			miny = min(miny, T.y)
			maxy = max(maxy, T.y)

		// Fog-of-war reveals in fixed MINIMAP_CHUNK_SIZE x MINIMAP_CHUNK_SIZE blocks rather than whole
		// areas, so a giant outdoor area doesn't fully reveal itself the instant you set foot in it.
		// Keyed off raw world coords (not img_x/img_y or anything crop/display-relative) so this
		// always matches reveal_around()'s bucketing exactly -- a mismatch here is what caused the
		// revealed area to show up offset from the player's actual position.
		var/chunk_key = "[round(T.x / MINIMAP_CHUNK_SIZE)]-[round(T.y / MINIMAP_CHUNK_SIZE)]"
		var/meta_color = chunk_to_color[chunk_key]
		if(!meta_color)
			meta_color = rgb(rand(0, 255), rand(0, 255), rand(0, 255)) // technically conflicts could happen but it's like very unlikely and it's not that big of a deal if one happens
			chunk_to_color[chunk_key] = meta_color
		color_area_names[meta_color] = A.name
		meta_icon.DrawBox(meta_color, img_x, img_y)

		if(istype(T, /turf/closed/wall))
			// Walls (and, on roof z-levels, solid/inaccessible roof mass) still read as a
			// darkened tint of their own material instead of a flat black void so roofs
			// actually show something on the map.
			var/color = get_turf_minimap_color(T, turf_color_cache)
			map_icon.DrawBox(color ? BlendRGB(color, "#000000", 0.6) : "#000000", img_x, img_y)

		else if(!istype(A, /area/space))
			// Sample the turf's own appearance first so open ground reads as actual
			// terrain (dirt/rock/road/rubble etc), falling back to the area's flat
			// color for turfs with no meaningful icon_state of their own.
			var/color = get_turf_minimap_color(T, turf_color_cache) || A.minimap_color || "#FF00FF"
			if(locate(/obj/machinery/power/solar) in T)
				color = "#02026a"

			if((locate(/obj/effect/spawner/structure/window) in T) || (locate(/obj/structure/grille) in T))
				color = BlendRGB(color, "#000000", 0.5)
			map_icon.DrawBox(color, img_x, img_y)

	map_icon.Crop(minx, miny, maxx, maxy)
	meta_icon.Crop(minx, miny, maxx, maxy)
	overlay_icon = new(map_icon)
	overlay_icon.Scale(16, 16)
	//we're done baking, now we ship it.
	if (!SSassets.cache[map_asset_name])
		SSassets.transport.register_asset(map_asset_name, map_icon)
	if (!SSassets.cache[meta_asset_name])
		SSassets.transport.register_asset(meta_asset_name, meta_icon)

/datum/minimap/proc/send(mob/user)
	if(!id)
		CRASH("ERROR: send called, but the minimap id is null/missing. ID: [id]")
	SSassets.transport.send_assets(user, list("[map_asset_name]" = map_icon, "[meta_asset_name]" = meta_icon))

///Samples a turf's own rendered appearance for a representative flat color, or null if it has none worth sampling.
/datum/minimap/proc/get_turf_minimap_color(turf/T, list/cache)
	if(!T.icon_state || T.icon_state == "unknown")
		return null
	var/cache_key = "[T.icon]-[T.icon_state]-[T.dir]"
	. = cache[cache_key]
	if(.)
		return
	var/icon/I = new(T.icon, T.icon_state, T.dir)
	// Scaling straight down to 1x1 averages in transparent edge pixels (usually stored as
	// black), which is what was making most floor tiles read as solid black. Sampling the
	// center pixel of the unscaled sprite avoids that.
	var/color = I.GetPixel(max(1, round(I.Width() / 2)), max(1, round(I.Height() / 2)))
	qdel(I)
	if(color)
		var/r = hex2num(copytext(color, 2, 4))
		var/g = hex2num(copytext(color, 4, 6))
		var/b = hex2num(copytext(color, 6, 8))
		if((r + g + b) < 30) // near-black sample, almost certainly a blank/transparent spot
			color = null
	if(color)
		cache[cache_key] = color
	. = color

///Translates a turf into 0-indexed, north-up pixel coordinates on this minimap's image, or null if it's off this map.
/datum/minimap/proc/get_pixel_position(turf/T)
	if(!T || T.z != z_level)
		return null
	if(T.x < minx || T.x > maxx || T.y < miny || T.y > maxy)
		return null
	return list(T.x - img_x1, img_y2 - T.y)

///Punches open the MINIMAP_CHUNK_SIZE-block T is in (and its immediate neighbors) on L's revealed-chunk list for this map. Cheap: just marks string keys in a list, no icon/asset work. Returns FALSE if T isn't on this map at all.
/datum/minimap/proc/reveal_around(mob/living/L, turf/T, radius = 1)
	if(!get_pixel_position(T)) // still just a bounds check -- the actual bucketing uses raw world coords below
		return FALSE
	var/cx = round(T.x / MINIMAP_CHUNK_SIZE)
	var/cy = round(T.y / MINIMAP_CHUNK_SIZE)

	var/list/explored = L.minimap_explored_chunks[id]
	if(!explored)
		explored = list()
		L.minimap_explored_chunks[id] = explored

	for(var/dx in -radius to radius)
		for(var/dy in -radius to radius)
			explored["[cx + dx]-[cy + dy]"] = TRUE
	return TRUE

///List of meta colors this mob is allowed to see revealed on this map; null means "no fog of war" (ghosts/dead bodies/admins see the whole map).
/datum/minimap/proc/get_revealed_colors(mob/user)
	if(!isliving(user))
		return null
	var/mob/living/L = user
	if(L.stat == DEAD)
		return null
	var/list/explored = L.minimap_explored_chunks[id]
	if(!explored)
		return list()
	var/list/revealed = list()
	for(var/chunk_key in explored)
		var/color = chunk_to_color[chunk_key]
		if(color)
			revealed += color
	return revealed

/datum/minimap_group
	var/list/minimaps = list()
	var/static/next_id = 0
	var/id
	var/name

/datum/minimap_group/New(list/maps, name)
	id = ++next_id
	src.name = name
	if(maps)
		minimaps = maps

/datum/minimap_group/ui_state(mob/user)
	return GLOB.always_state

/datum/minimap_group/ui_interact(mob/user, datum/tgui/ui)
	if(!length(minimaps))
		to_chat(user, span_boldwarning("ERROR: Attempted to access an empty datum/minimap_group. This should probably not happen."))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Minimap", name)
		ui.open()

/datum/minimap_group/ui_static_data(mob/user)
	var/list/data = list()
	data["title"] = name
	var/list/maps = list()
	for(var/datum/minimap/M in minimaps)
		M.send(user)
		maps += list(list(
			"name" = M.name,
			"mapUrl" = SSassets.transport.get_asset_url(M.map_asset_name),
			"metaUrl" = SSassets.transport.get_asset_url(M.meta_asset_name),
			"colorAreaNames" = M.color_area_names,
		))
	data["maps"] = maps
	return data

/datum/minimap_group/ui_data(mob/user)
	var/list/data = list()
	var/turf/T = get_turf(user)
	var/mob/living/L = isliving(user) ? user : null

	// NOTE: kept out of the "maps" key on purpose -- ui_data() and ui_static_data() are
	// shallow-merged by tgui, so reusing "maps" here would clobber the static map list.
	var/list/revealed_colors = list()
	for(var/i in 1 to length(minimaps))
		var/datum/minimap/M = minimaps[i]
		if(L && L.stat != DEAD)
			M.reveal_around(L, T)
		revealed_colors += list(M.get_revealed_colors(user))
		var/pos = M.get_pixel_position(T)
		if(pos && !data["blip"])
			data["blip"] = list("mapIndex" = i, "x" = pos[1], "y" = pos[2])
	data["revealedColors"] = revealed_colors

	if(L)
		data["waypoint"] = L.minimap_waypoint
	return data

/datum/minimap_group/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = ui.user
	if(!isliving(user))
		return
	var/mob/living/L = user
	switch(action)
		if("set_waypoint")
			var/map_index = text2num(params["mapIndex"])
			var/wx = text2num(params["x"])
			var/wy = text2num(params["y"])
			if(!map_index || isnull(wx) || isnull(wy) || !minimaps[map_index])
				return
			L.minimap_waypoint = list("mapIndex" = map_index, "x" = wx, "y" = wy)
			. = TRUE
		if("clear_waypoint")
			L.minimap_waypoint = null
			. = TRUE

