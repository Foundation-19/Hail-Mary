// Climate model constants. Atmos is disabled, so temperature comes from the time of day, the weather, nearby fires and what a
// person is wearing instead of gas mixtures. Temperatures are ambient kelvin; life ticks run roughly every 2 seconds.

#define CLIMATE_INDOOR_TEMP 293
#define CLIMATE_COMFORT_MIN 283
#define CLIMATE_COMFORT_MAX 308

// Fires only warm people up to this temperature, so a fireplace takes the chill off without cooking anyone indoors
#define CLIMATE_HEAT_SOURCE_CAP 300
#define CLIMATE_HEAT_SOURCE_RADIUS 4

// Degrees outside the comfort band are turned into this much exposure each
#define CLIMATE_EXPOSURE_PER_DEGREE 4
#define CLIMATE_EXPOSURE_MAX 100
#define CLIMATE_EXPOSURE_RATE 0.06 // fraction of the gap to the target closed each tick
#define CLIMATE_BODYTEMP_PER_EXPOSURE 0.2 // body temperature shift per point of exposure

// Exposure tiers
#define CLIMATE_TIER_MILD 20 // shivering or sweating and the discomfort alert
#define CLIMATE_TIER_MODERATE 45 // stamina drain or slowdown and a bad mood
#define CLIMATE_TIER_SEVERE 75 // frostbite or heatstroke damage

#define CLIMATE_COLD_SLOWDOWN_MAX 0.5
#define CLIMATE_HEAT_STAMINA 1.5 // buffered stamina damage per tick at the top of the moderate tier
#define CLIMATE_DAMAGE_MIN 0.4
#define CLIMATE_DAMAGE_MAX 1
#define CLIMATE_DAMAGE_HEALTH_FLOOR 0.35 // climate alone never takes someone below this fraction of their max health

// Clothing. Each worn item lowers cold exposure by its weight, scaled by how much of the body it covers
#define CLIMATE_INSULATION_UNIFORM 0.3
#define CLIMATE_INSULATION_SUIT 0.4
#define CLIMATE_INSULATION_HEAD 0.15
#define CLIMATE_INSULATION_GLOVES 0.05
#define CLIMATE_INSULATION_SHOES 0.1
#define CLIMATE_INSULATION_MAX 0.75
#define CLIMATE_INSULATION_HEAT_PENALTY 0.4 // heavy clothing traps heat: heat exposure rises by this much at full insulation
#define CLIMATE_HAT_HEAT_RELIEF 0.15 // a hat or helmet shades the head

// Wetness. Rain and fog soak people, which makes the cold bite harder and the heat a little easier. It dries off per life tick
#define CLIMATE_WET_MAX 100
#define CLIMATE_WET_DRENCHED 60 // above this you are told you are soaked
#define CLIMATE_WET_COLD_PENALTY 0.5 // cold exposure rises by this much when fully soaked
#define CLIMATE_WET_HEAT_RELIEF 0.25 // heat exposure falls by this much when fully soaked
#define CLIMATE_WET_DRY_INDOORS 4
#define CLIMATE_WET_DRY_OUTDOORS 1
#define CLIMATE_WET_DRY_WARM 3 // extra, when beside a fire or in the heat

// Acid rain. Standing in it builds exposure up and sheltering washes it off, so a short dash between buildings is free and only
// lingering in the open hurts. Damage then lands on each body part according to what covers it, and never kills on its own
#define ACID_EXPOSURE_MAX 100
#define ACID_EXPOSURE_GAIN 8 // per second in the open
#define ACID_EXPOSURE_THRESHOLD 24 // no damage and no sting below this, about three seconds of grace
#define ACID_EXPOSURE_DECAY 12 // per life tick once out of the rain for a moment
#define ACID_EXPOSURE_DECAY_DELAY (3 SECONDS)
#define ACID_DAMAGE_PER_SECOND 1.6 // total burn per second across the whole body at full exposure and no protection
#define ACID_COVER_PROTECTION 0.4 // the first layer of clothing over a body part
#define ACID_COVER_LAYER_BONUS 0.15 // each extra layer
#define ACID_PROTECTION_MAX 0.9
#define ACID_DAMAGE_HEALTH_FLOOR 0.35 // acid rain alone never takes someone below this fraction of their max health

// Ambient temperature outdoors by time of day, see SSnightcycle phases
#define CLIMATE_TEMP_SUNRISE 283
#define CLIMATE_TEMP_MORNING 293
#define CLIMATE_TEMP_LATEMORN 303
#define CLIMATE_TEMP_DAYTIME 311
#define CLIMATE_TEMP_AFTERNOON 311
#define CLIMATE_TEMP_LATEAFTERNOON 305
#define CLIMATE_TEMP_SUNSET 297
#define CLIMATE_TEMP_FULLSUNSET 288
#define CLIMATE_TEMP_NIGHTTIME 275
