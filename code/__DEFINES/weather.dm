/// Stages a weather goes through, see datum/weather
#define STARTUP_STAGE 1
#define MAIN_STAGE 2
#define WIND_DOWN_STAGE 3
#define END_STAGE 4

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

/// Weather arrives as systems, the forecast holds the clouds of the next one. Each is rolled separately so a system can be one cloud or several
/// How many clouds can be out at the same time, any that would form past this dissipate
#define WEATHER_MAX_CONCURRENT 3
/// Clouds of one system arrive within this long of each other, so they can overlap
#define WEATHER_FRONT_SPREAD 12 MINUTES
/// Weights for how many clouds a system has, "clouds" = chance
#define WEATHER_FRONT_SIZES list("1" = 55, "2" = 30, "3" = 12, "4" = 3)
/// Barometers list at most this many incoming clouds
#define WEATHER_BAROMETER_FORECAST_MAX 4
/// Weather is a patch of sky (see code/datums/weather/weather_cell.dm), not a blanket over every outdoor area
/// How far an edge can bulge in or out, as a fraction of the patch's size
#define WEATHER_CELL_LUMP 0.12
/// A patch is at full strength this far in from its edge, as a fraction of its size, and fades to nothing at the edge
#define WEATHER_CELL_FADE 0.35
/// Size of a forming patch as a fraction of its full size
#define WEATHER_CELL_START_SCALE 0.3
/// Size a patch grows to while the weather is still gathering
#define WEATHER_CELL_FORMING_SCALE 0.6
/// Size a patch shrinks to while the weather is winding down
#define WEATHER_CELL_FADING_SCALE 0.45
/// How much of the gap to its target size a patch closes every second
#define WEATHER_CELL_GROW_RATE 0.04
/// Seconds between sweeps for turf effects as a patch drifts over new ground
#define WEATHER_TURF_SWEEP_INTERVAL 10 SECONDS
/// Seconds between refreshing which turfs show the weather happening on them, as the patch drifts
#define WEATHER_TURF_VISUAL_INTERVAL 3 SECONDS
/// Opacity of the weather overlay at the heart of a patch, kept well under solid so the middle of a storm is still readable
#define WEATHER_SCREEN_MAX_ALPHA 150
/// Opacity of the weather overlay at the very fringe of a patch, so the edge never reads as a hard line
#define WEATHER_SCREEN_MIN_ALPHA 30
/// People out in the open see a patch coming from this many tiles beyond its edge, as a haze that thickens as they close in
#define WEATHER_CELL_HALO 20
/// How much softer the trailing edge of a moving patch is than its leading edge. The front arrives sharply and the rain tails off behind it
#define WEATHER_CELL_TRAIL 0.45
/// How far clumps and gaps inside a patch push its opacity up or down, as a fraction of it
#define WEATHER_CELL_PATCHINESS 0.3
/// Degrees per second the clumps and gaps churn around inside a patch
#define WEATHER_CELL_CHURN 1.5
/// Fraction of the gap to the wind's heading a patch's own heading closes every second
#define WEATHER_CELL_STEER 0.004
/// How far the wind can swing in one shift, in degrees
#define WEATHER_WIND_SWING 35
/// Minutes between wind shifts
#define WEATHER_WIND_SHIFT_MIN 2 MINUTES
#define WEATHER_WIND_SHIFT_MAX 6 MINUTES
/// A gust blows ahead of an approaching patch this many tiles from its edge, strongest at the edge
#define WEATHER_GUST_RANGE 12
/// Share of a weather's temperature shift that its gust carries ahead of it
#define WEATHER_GUST_STRENGTH 0.5
/// Lightning can be seen and thunder heard this many tiles from the strike
#define WEATHER_LIGHTNING_RANGE 70
/// Lightning only lights up the sky for people out in the open this close to it
#define WEATHER_LIGHTNING_FLASH_RANGE 45
/// Deciseconds thunder lags behind its flash for every tile of distance
#define WEATHER_THUNDER_DELAY 0.8
/// How dark the ground under a patch gets at most, as an alpha, before the time of day is taken into account
#define WEATHER_SHADE_MAX_ALPHA 55
/// How often wet ground is checked for drying out
#define WEATHER_WET_CHECK_INTERVAL 10 SECONDS
/// The colour wet ground is tinted
#define WEATHER_WET_COLOUR "#b9bdc9"
/// Animals out in the rain look for cover this often, and no farther than this many tiles
#define WEATHER_SHELTER_INTERVAL 4 SECONDS
#define WEATHER_SHELTER_RANGE 9

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

