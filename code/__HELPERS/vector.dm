// Basic geometry things.

/datum/vector/
	var/x = 0
	var/y = 0

/datum/vector/New(x, y)
	src.x = x
	src.y = y

TYPE_PROC_REF(/datum/vector, duplicate)()
	return new /datum/vector(x, y)

TYPE_PROC_REF(/datum/vector, euclidian_norm)()
	return sqrt(x*x + y*y)

TYPE_PROC_REF(/datum/vector, squared_norm)()
	return x*x + y*y

TYPE_PROC_REF(/datum/vector, normalize)()
	var/norm = euclidian_norm()
	x = x/norm
	y = y/norm
	return src

TYPE_PROC_REF(/datum/vector, chebyshev_norm)()
	return max(abs(x), abs(y))

TYPE_PROC_REF(/datum/vector, chebyshev_normalize)()
	var/norm = chebyshev_norm()
	x = x/norm
	y = y/norm
	return src

TYPE_PROC_REF(/datum/vector, is_integer)()
	return ISINTEGER(x) && ISINTEGER(y)

TYPE_PROC_REF(/atom/movable, vector_translate)(datum/vector/V, delay)
	var/turf/T = get_turf(src)
	var/turf/destination = locate(T.x + V.x, T.y + V.y, z)
	var/datum/vector/V_norm = V.duplicate()
	V_norm.chebyshev_normalize()
	if (!V_norm.is_integer())
		return
	var/turf/destination_temp
	while (destination_temp != destination)
		destination_temp = locate(T.x + V_norm.x, T.y + V_norm.y, z)
		forceMove(destination_temp)
		T = get_turf(src)
		sleep(delay + world.tick_lag) // Shortest possible time to sleep

TYPE_PROC_REF(/atom, get_translated_turf)(datum/vector/V)
	var/turf/T = get_turf(src)
	return locate(T.x + V.x, T.y + V.y, z)

/proc/atoms2vector(atom/A, atom/B)
	return new /datum/vector((B.x - A.x), (B.y - A.y)) // Vector from A -> B
