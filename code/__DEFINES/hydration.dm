// Hydration model constants. Thirst is stored on a 0..THIRST_LEVEL_FULL scale; life ticks run roughly every 2 seconds.

// Stomach buffer: drinks land here and absorb into thirst over time
#define HYDRATION_STOMACH_MAX 300
#define HYDRATION_ABSORB_RATE 3 // per life tick

// Loss multipliers applied to the basal THIRST_FACTOR drain
#define HYDRATION_MULT_RUNNING 4
#define HYDRATION_MULT_WALKING 1.5
#define HYDRATION_MULT_HOT 1.5
#define HYDRATION_MULT_POWER_ARMOR 1.5
#define HYDRATION_MULT_BLEEDING 1.3
#define HYDRATION_MULT_IRRADIATED 1.2
#define HYDRATION_MULT_DRUNK 1.3
#define HYDRATION_ACTIVE_WINDOW (3 SECONDS) // moved within this window counts as active
#define HYDRATION_HOT_BODYTEMP 318
#define HYDRATION_RADIATION_THRESHOLD 100
#define HYDRATION_DRUNK_THRESHOLD 30

// Tiers, as a fraction of THIRST_LEVEL_FULL. A tier is entered below its threshold and left above threshold + HYDRATION_HYSTERESIS
#define HYDRATION_TIER_HYDRATED 1
#define HYDRATION_TIER_FINE 2
#define HYDRATION_TIER_THIRSTY 3
#define HYDRATION_TIER_PARCHED 4
#define HYDRATION_TIER_CRITICAL 5
#define HYDRATION_THRESHOLD_FINE 0.6
#define HYDRATION_THRESHOLD_THIRSTY 0.4
#define HYDRATION_THRESHOLD_PARCHED 0.2
#define HYDRATION_THRESHOLD_CRITICAL 0.05
#define HYDRATION_HYSTERESIS 0.05

// Tier penalties, per life tick
#define HYDRATION_PARCHED_STAMINA_PROB 3
#define HYDRATION_PARCHED_STAMINA_DAMAGE 10
#define HYDRATION_CRITICAL_DAMAGE_PROB 20
#define HYDRATION_CRITICAL_TOX_DAMAGE 1

// Waterborne illness
#define HYDRATION_ILLNESS_DELAY_MIN (2 MINUTES)
#define HYDRATION_ILLNESS_DELAY_MAX (5 MINUTES)
#define HYDRATION_ILLNESS_EPISODES 3
#define HYDRATION_ILLNESS_EPISODE_INTERVAL (25 SECONDS)
#define HYDRATION_ILLNESS_LOSS 40 // thirst lost per vomiting episode

// Default contamination of untreated water, per unit drunk
#define WATER_IMPURE_RAD_PER_UNIT 0.25
#define WATER_IMPURE_PATHOGEN_CHANCE 0.005

// Treatment effects, as multipliers on the untreated values
#define WATER_TABLET_RAD_MULT 0.5
#define WATER_TABLET_PATHOGEN_MULT 0.1
#define WATER_FILTER_PATHOGEN_MULT 0.5

// Hunger shares the activity multiplier, scaled down: 0 = ignore activity, 1 = same as thirst
#define HUNGER_ACTIVITY_SCALE 0.5
#define SMUTANT_HUNGER_MOD 1.25
#define SMUTANT_THIRST_MOD 1.25
#define SMUTANT_STOMACH_MOD 2

// Quirk modifiers
#define HYDRATION_WATER_WISE_MULT 0.75
#define HYDRATION_WATER_WISE_STOMACH_MULT 1.5
#define HYDRATION_DEHYDRATED_MULT 1.35
#define HYDRATION_IRON_STOMACH_MULT 0.4
#define HYDRATION_DELICATE_STOMACH_MULT 1.6

// C-27 power, servo burst and repair. Charge is stored as nutrition.
#define C27_SHOCK_COEFF 1.25
#define C27_LOW_POWER_SLOWDOWN 1
#define C27_SHUTDOWN_LEVEL 25
#define C27_BURST_COST 40
#define C27_BURST_DURATION 50
#define C27_BURST_COOLDOWN 450
#define C27_BURST_SLOWDOWN -0.8
#define C27_REPAIR_RATE 0.1
