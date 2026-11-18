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
	/// Which way it is travelling, as a unit vector. radius_x lies along this and radius_y across it, so a patch is stretched with or against the wind
	var/dir_x = 1
	var/dir_y = 0
	/// Whether it is going anywhere, a patch that is not has no front or rear
	var/moving = FALSE
	/// How strong the weather is right now as a fraction of its best, it gathers, peaks about the middle of its life and thins out
	var/vigor = 1
	/// Where the clumps and gaps inside it are, they ride along with it and slowly churn
	var/churn = 0
	var/clump_a = 0
	var/clump_b = 0

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
	clump_a = rand(0, 359)
	clump_b = rand(0, 359)
	aim()

/datum/weather_cell/proc/drift(seconds)
	x += vx * seconds
	y += vy * seconds
	churn += WEATHER_CELL_CHURN * seconds

/// Turns the patch to face the way it is going
/datum/weather_cell/proc/aim()
	var/speed = sqrt(vx * vx + vy * vy)
	moving = speed > 0.0001
	if(moving)
		dir_x = vx / speed
		dir_y = vy / speed

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
	var/along = dx * dir_x + dy * dir_y
	var/across = dy * dir_x - dx * dir_y
	var/ratio = sqrt((along * along) / (rx * rx) + (across * across) / (ry * ry))
	return ratio / (1 + WEATHER_CELL_LUMP * 0.5 * (sin(dx * 11 + lump_x) + sin(dy * 7 + lump_y)))

/datum/weather_cell/proc/covers(turf/T, margin = 0)
	return distance_ratio(T, margin) <= 1

/// -1 right at the front of the patch, 1 right at its rear and 0 abreast of the centre or when it is not moving
/datum/weather_cell/proc/trail(turf/T)
	if(!moving)
		return 0
	var/dx = T.x - x
	var/dy = T.y - y
	var/dist = sqrt(dx * dx + dy * dy)
	if(dist < 1)
		return 0
	return -(dx * dir_x + dy * dir_y) / dist

/// 0 on the edge up to 1 once well inside. Things that scale with how deep in the weather you are use this. The leading edge is sharper than the rear
/datum/weather_cell/proc/intensity(turf/T)
	return clamp((1 - distance_ratio(T)) / (WEATHER_CELL_FADE * (1 + WEATHER_CELL_TRAIL * trail(T))), 0, 1)

/// How many tiles a turf is past the edge, given its distance ratio
/datum/weather_cell/proc/tiles_beyond(ratio)
	return max(0, (ratio - 1) * (radius_x + radius_y) * 0.5 * scale)

/// Clumps and gaps inside the patch, about 1 and never far from it. They drift with the patch and churn so no two moments look the same
/datum/weather_cell/proc/patchiness(turf/T)
	var/dx = T.x - x
	var/dy = T.y - y
	var/broad = sin(dx * 10 + dy * 4 + churn + clump_a) + sin(dy * 8 - dx * 5 - churn * 0.7 + clump_b)
	var/fine = 0.5 * sin(dx * 23 + dy * 17 + churn * 1.9 + clump_a + clump_b)
	return 1 + WEATHER_CELL_PATCHINESS * (broad + fine) / 2.5

/// How thick the patch looks to someone at this turf, as an alpha. Outside it fades in from nothing WEATHER_CELL_HALO tiles from the edge so a
/// storm is seen coming, inside it is eased up to the heart of the patch rather than ramping straight to a wall. Clumps thin it and thicken it
/// deep inside but never at the edge, so the edge stays smooth
/datum/weather_cell/proc/screen_alpha(turf/T)
	var/ratio = distance_ratio(T)
	if(ratio > 1)
		return round(WEATHER_SCREEN_MIN_ALPHA * clamp(1 - tiles_beyond(ratio) / WEATHER_CELL_HALO, 0, 1))
	var/depth = intensity(T)
	var/peak = WEATHER_SCREEN_MIN_ALPHA + (WEATHER_SCREEN_MAX_ALPHA - WEATHER_SCREEN_MIN_ALPHA) * vigor
	var/body = (peak - WEATHER_SCREEN_MIN_ALPHA) * depth * depth * (3 - 2 * depth)
	body *= 1 + (patchiness(T) - 1) * depth
	return round(clamp(WEATHER_SCREEN_MIN_ALPHA + body, WEATHER_SCREEN_MIN_ALPHA, WEATHER_SCREEN_MAX_ALPHA))

/// 0 to 1, how hard the gust ahead of the patch is blowing at this turf. Only the ground in front of a moving patch gets one, strongest at its edge
/datum/weather_cell/proc/gust(turf/T)
	if(!moving)
		return 0
	var/ratio = distance_ratio(T)
	if(ratio <= 1 || trail(T) >= 0)
		return 0
	return clamp(1 - tiles_beyond(ratio) / WEATHER_GUST_RANGE, 0, 1)

/// A random turf well inside the patch
/datum/weather_cell/proc/random_point()
	var/angle = rand(0, 359)
	var/reach = sqrt(rand()) * 0.8
	var/along = cos(angle) * reach * radius_x * scale
	var/across = sin(angle) * reach * radius_y * scale
	var/wx = clamp(round(x + along * dir_x - across * dir_y), 1, world.maxx)
	var/wy = clamp(round(y + along * dir_y + across * dir_x), 1, world.maxy)
	return locate(wx, wy, pick(z_levels))
