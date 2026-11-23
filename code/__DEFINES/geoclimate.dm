// Geoclimate. The weather comes and goes, the land remembers. See code/controllers/subsystem/geoclimate.dm.
// The outdoors is cut into parcels. Each one soaks up rain, drains slowly, and is pulled back toward whatever the ground there would
// be if nobody had ever touched it: wet country near open water keeps trying to turn back into marsh, dry country goes back to scrub.
// Wet ground grows plants and turns to mud, abandoned ground is taken back by vines. Moisture is 0 to 100 and rates are per minute.

/// Side of a parcel in tiles
#define GEO_PARCEL_SIZE 10

#define GEO_TURF_BUILT 0 // anything people made, and anything that is not open ground
#define GEO_TURF_WATER 1
#define GEO_TURF_SOIL 2 // dirt, savannah and grass: grows plants, turns to mud
#define GEO_TURF_SAND 3 // desert: grows plants badly, drains too fast to turn to mud
#define GEO_TURF_ROCK 4 // bare natural ground

/// How often parcels are brought up to date
#define GEO_TICK_INTERVAL 20 SECONDS
/// A parcel is brought up to date at most this many times a tick, so it is never one long frame
#define GEO_MUD_PARCELS_PER_TICK 3
#define GEO_PLANTS_PER_PARCEL_TICK 1
/// Parcels caught up on in a single fire() before yielding back to the MC regardless of spare tick budget. A big map's worth can
/// otherwise all get crunched the moment currentrun refills, since MC_TICK_CHECK alone lets a background subsystem burn through
/// as much of a tick as is free - spreading the same work over more, smaller ticks instead of one lump keeps it from ever being felt
#define GEO_PARCELS_PER_TICK 200

// Water. Moisture drains toward the parcel's water table, which is as high as the nearby water and low ground make it. A parcel
// below its table seeps back up toward it more slowly than it dries
/// Highest water table, at the very edge of open water
#define GEO_WETLAND_MAX 62
/// Fraction of the surplus moisture that drains each minute at the dry end
#define GEO_DRAIN_RATE 0.035
/// Fraction of the shortfall that seeps back each minute
#define GEO_SEEP_RATE 0.012
/// Wetland holds water: its drain rate is cut by up to this fraction
#define GEO_WETLAND_RETENTION 0.7
/// Parcels this many parcels from open water still feel the wet ground. Own water counts GEO_WETLAND_OWN times, the neighbours' GEO_WETLAND_NEIGHBOUR
#define GEO_WETLAND_OWN 2.5
#define GEO_WETLAND_NEIGHBOUR 1.5

// Growth. Vegetation follows the moisture slowly, and falls faster than it rises
#define GEO_VEG_MOISTURE_FLOOR 15 // no growth below this much moisture
#define GEO_VEG_PER_MOISTURE 1.4
#define GEO_GROWTH_RATE 0.6 // per minute
#define GEO_WITHER_RATE 1.2
/// Fraction of a parcel's growing ground that can be covered at full vegetation
#define GEO_MAX_COVER 0.35
/// Growing ground that is not rich soil counts for this much of a soil tile
#define GEO_SAND_FERTILITY 0.4
/// Moisture and vegetation that tip the plants over to wild forage, below this it is only grass
#define GEO_LUSH_MOISTURE 60
#define GEO_LUSH_VEGETATION 60
/// Moisture and wetland pull that grow marsh grasses
#define GEO_MARSH_MOISTURE 65
#define GEO_MARSH_PULL 0.5

// People. A parcel with a player in it, or next to it, is tended. Left alone long enough it is not, and nature goes at what people built
#define GEO_TENDED_TIME (10 MINUTES)
#define GEO_ABANDON_TIME (60 MINUTES)
#define GEO_TENDED_GROWTH 0.5
#define GEO_ABANDONED_GROWTH 2
/// Fraction of an abandoned parcel's open built ground that vines can take at full vegetation
#define GEO_RECLAIM_COVER 0.15
/// Nothing grows or withers this close to a player, they see it happen and it looks like pop-in
#define GEO_UNSEEN_RANGE 10

// Mud. Above the start the soil softens, patch by patch, up to the full coverage at the top
#define GEO_MUD_START 55
#define GEO_MUD_FULL 95
#define GEO_MUD_STEPS 4
#define GEO_MUD_MAX_COVER 0.7
#define GEO_MUD_SLOWDOWN 1
#define GEO_MUD_COLOUR "#7a6a58"

// Radiation. A storm's fallout settles into the ground and fades on its own slow clock, long after the clouds have passed, and much
// slower than the storm itself hurts whoever is caught out in it
/// Ground contamination caps here, same units as a weather's ground_contamination_rate
#define GEO_RADIATION_MAX 1000
/// Fraction of the ground's contamination that fades every minute: a heavy storm's mark lingers for hours, not minutes
#define GEO_RADIATION_DECAY 0.004
/// Rads a living thing standing on contaminated ground takes per life tick, for every point of contamination. Far gentler than standing in the storm itself
#define GEO_RADIATION_EXPOSURE 0.005

/// Damp ground evens out the day and night, by this fraction of the gap to a comfortable room at the dampest
#define GEO_THERMAL_MODERATION 0.15

/// Hot sun and heat waves dry the ground faster, cold and the dark slower: evaporation is scaled between these
#define GEO_EVAP_MIN 0.25
#define GEO_EVAP_MAX 2

/// Moisture, averaged over the ground, at which it counts as not dry at all. See get_dryness()
#define GEO_DRY_REFERENCE 30
