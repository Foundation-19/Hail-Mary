/**
 * A patch of sky that a weather is happening under
 *
 * Weather forms over one spot, grows while it gathers, drifts downwind and shrinks as it dies away, like a real storm cell.
 * The patch is an ellipse with a lumpy edge so it never looks like a drawn circle. Stacked z levels share one patch.
 */
/datum/weather_cell
	/// Z levels under this patch of sky
	var/list/z_levels
	/// Centre of the patch, in tiles. Not rounded because it drifts a fraction of a tile at a time
	var/x = 1
	var/y = 1
	/// Radius along each axis at full size
	var/radius_x = 30
	var/radius_y = 30
	/// How much of its full size the patch is right now
	var/scale = WEATHER_CELL_START_SCALE
	/// Tiles per second it drifts
	var/vx = 0
	var/vy = 0
	/// Offsets for the bumps along the edge
	var/lump_x = 0
	var/lump_y = 0

/datum/weather_cell/New(list/z_levels, x, y, radius_x, radius_y, vx, vy)
	..()
	src.z_levels = z_levels
	src.x = x
	src.y = y
	src.radius_x = radius_x
	src.radius_y = radius_y
	src.vx = vx
	src.vy = vy
	lump_x = rand(0, 359)
	lump_y = rand(0, 359)

/datum/weather_cell/proc/drift(seconds)
	x += vx * seconds
	y += vy * seconds

/// How far a turf is from the centre as a fraction of the edge: 0 at the middle, 1 on the edge, over 1 outside. Margin pushes the edge out by that many tiles
/datum/weather_cell/proc/distance_ratio(turf/T, margin = 0)
	if(!(T.z in z_levels))
		return 100
	var/rx = radius_x * scale + margin
	var/ry = radius_y * scale + margin
	if(rx <= 0 || ry <= 0)
		return 100
	var/dx = T.x - x
	var/dy = T.y - y
	var/ratio = sqrt((dx * dx) / (rx * rx) + (dy * dy) / (ry * ry))
	return ratio / (1 + WEATHER_CELL_LUMP * 0.5 * (sin(dx * 11 + lump_x) + sin(dy * 7 + lump_y)))

/datum/weather_cell/proc/covers(turf/T, margin = 0)
	return distance_ratio(T, margin) <= 1

/// 0 on the edge up to 1 once well inside. Things that scale with how deep in the weather you are use this
/datum/weather_cell/proc/intensity(turf/T)
	return clamp((1 - distance_ratio(T)) / WEATHER_CELL_FADE, 0, 1)
