/// Z levels that are more or less above ground and can see the sky
/// For telling players about the weather
#define Z_LEVEL_EASTWOOD_UNDERGROUND 3
#define Z_LEVEL_EASTWOOD_COMMON 4
#define Z_LEVEL_EASTWOOD_LVL2 5
#define Z_LEVEL_EASTWOOD_LVL3 6
#define Z_LEVEL_REDWATER 7
#define Z_LEVEL_REDLICK 8
#define Z_LEVEL_GARLAND 9
#define ABOVE_GROUND_Z_LEVELS list(\
	Z_LEVEL_EASTWOOD_COMMON,\
	Z_LEVEL_EASTWOOD_LVL2,\
	Z_LEVEL_EASTWOOD_LVL3,\
	Z_LEVEL_REDWATER,\
	Z_LEVEL_REDLICK,\
	Z_LEVEL_GARLAND)
#define COMMON_Z_LEVELS list(\
	Z_LEVEL_EASTWOOD_UNDERGROUND,\
	Z_LEVEL_EASTWOOD_COMMON,\
	Z_LEVEL_EASTWOOD_LVL2,\
	Z_LEVEL_EASTWOOD_LVL3,\
	Z_LEVEL_REDWATER,\
	Z_LEVEL_REDLICK,\
	Z_LEVEL_GARLAND)
#define CORE_Z_LEVELS list(\
	Z_LEVEL_EASTWOOD_UNDERGROUND,\
	Z_LEVEL_EASTWOOD_COMMON,\
	Z_LEVEL_EASTWOOD_LVL2,\
	Z_LEVEL_EASTWOOD_LVL3)

/* * * * * * * * * * * * *
 * THE Z LEVELS~
 * 3 = EASTWOOD UNDERGROUND
 * 4 = EASTWOOD CENTRAL
 * 5 = EASTWOOD LVL 2
 * 6 = EASTWOOD LVL 3
 * 7 = REDWATER
 * 8 = REDLICK
 * * * * * * * * * * * * */

/// Minimum time between weathers
#define WEATHER_WAIT_MIN 30 MINUTES
/// Maximum time between weathers
#define WEATHER_WAIT_MAX 45 MINUTES

/// Weather tags!

#define WEATHER_HEAT "heat_wave"
#define WEATHER_COLD "cold_snap"
#define WEATHER_SNOW "snow_storm"
#define WEATHER_RAIN "normal_ass_rain"
#define WEATHER_ACID "acid_rain"
#define WEATHER_SAND "sand_storm"
#define WEATHER_RADS "RADSTORM"
#define WEATHER_ALL_AREAS "all_of_em"

/// All weather tags
#define WEATHER_ALL WEATHER_HEAT,\
	WEATHER_COLD,\
	WEATHER_SNOW,\
	WEATHER_RAIN,\
	WEATHER_ACID,\
	WEATHER_SAND,\
	WEATHER_RADS

/// All weather tags,
#define WEATHER_ALL_MINUS_HEAT WEATHER_COLD,\
	WEATHER_SNOW,\
	WEATHER_RAIN,\
	WEATHER_ACID,\
	WEATHER_SAND,\
	WEATHER_RADS

