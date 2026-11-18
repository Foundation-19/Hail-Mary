// Climate model constants. Atmos is disabled, so temperature comes from the time of day, the weather, nearby fires and what a
// person is wearing instead of gas mixtures. Temperatures are ambient kelvin; life ticks run roughly every 2 seconds.

#define CLIMATE_INDOOR_TEMP 293
#define CLIMATE_COMFORT_MIN 283
#define CLIMATE_COMFORT_MAX 308

// Nothing heats or cools a building any more, so rooms slowly take on the outdoor temperature. An area's climate_leak is how much
// of the outdoor swing around CLIMATE_INDOOR_TEMP it reaches in the end, and climate_lag the fraction of the remaining gap its air
// closes every second. Thick walls and underground rooms keep to a milder temperature and are slower to change
#define CLIMATE_LEAK_DEFAULT 0.8
#define CLIMATE_LAG_DEFAULT 0.006
#define CLIMATE_LEAK_SHELTERED 0.35
#define CLIMATE_LAG_SHELTERED 0.003
#define CLIMATE_LEAK_UNDERGROUND 0.25
#define CLIMATE_LAG_UNDERGROUND 0.002

// How far past the comfort band the air has to be before people are told it is harsh, and the least time between two such messages
#define CLIMATE_FEEL_HARSH 8
#define CLIMATE_FEEL_COOLDOWN (30 SECONDS)

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

// Clothing. Each worn item lowers cold exposure by its slot weight, scaled by how much of the body it covers and by its own
// climate_warmth (1 is ordinary cloth or leather, fur and winter wear is higher, plate and rags lower). Heat works the same way
// through climate_heat_trap: breathable gear is below 1, sealed or plated gear above it
#define CLIMATE_INSULATION_UNIFORM 0.3
#define CLIMATE_INSULATION_SUIT 0.4
#define CLIMATE_INSULATION_HEAD 0.15
#define CLIMATE_INSULATION_GLOVES 0.05
#define CLIMATE_INSULATION_SHOES 0.1
#define CLIMATE_INSULATION_NECK 0.06
#define CLIMATE_INSULATION_MASK 0.04
#define CLIMATE_INSULATION_MAX 0.9
#define CLIMATE_INSULATION_HEAT_PENALTY 0.4 // heavy clothing traps heat: heat exposure rises by this much per point of trapped heat
#define CLIMATE_HEAT_TRAP_MAX 1.2
#define CLIMATE_HAT_HEAT_RELIEF 0.15 // a hat or helmet shades the head, scaled by how breathable it is

// How much of a garment's slot weight each part of the body is worth. A coat with no legs still covers most of what matters
#define CLIMATE_COVER_CHEST 0.5
#define CLIMATE_COVER_ARM 0.125
#define CLIMATE_COVER_LEG 0.125

// A machine that overheats has its cooling fans burn this much charge per tick at the top of the moderate tier
#define CLIMATE_MACHINE_CHARGE_DRAIN 2

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
#define CLIMATE_TEMP_SUNRISE 281
#define CLIMATE_TEMP_MORNING 293
#define CLIMATE_TEMP_LATEMORN 304
#define CLIMATE_TEMP_DAYTIME 316
#define CLIMATE_TEMP_AFTERNOON 316
#define CLIMATE_TEMP_LATEAFTERNOON 309
#define CLIMATE_TEMP_SUNSET 298
#define CLIMATE_TEMP_FULLSUNSET 286
#define CLIMATE_TEMP_NIGHTTIME 272
