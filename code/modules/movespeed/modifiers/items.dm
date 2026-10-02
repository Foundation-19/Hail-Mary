/datum/movespeed_modifier/jetpack
	conflicts_with = MOVE_CONFLICT_JETPACK
	movetypes = FLOATING

/datum/movespeed_modifier/jetpack/cybernetic
	multiplicative_slowdown = -0.5

/datum/movespeed_modifier/jetpack/fullspeed
	multiplicative_slowdown = -2

/datum/movespeed_modifier/die_of_fate
	multiplicative_slowdown = 1

/// Applied while wearing/holding a storage item whose contents outweigh the carrier's Strength.
/datum/movespeed_modifier/overloaded_storage
	multiplicative_slowdown = 1.5
