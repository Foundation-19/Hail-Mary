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

// Waterborne illness. Raw water builds up a hidden "contamination load" that slowly decays.
// Each unit of dirty water adds pathogen_chance * HYDRATION_LOAD_SCALE.
#define HYDRATION_LOAD_SCALE 100
#define HYDRATION_LOAD_DECAY 0.05 // per life tick
#define HYDRATION_LOAD_QUEASY 20 // mild nausea and a warning
#define HYDRATION_LOAD_SICK 40 // triggers the illness
#define HYDRATION_LOAD_AFTER_ILLNESS 10 // what is left once the body purges itself
#define HYDRATION_ILLNESS_TOX 2 // toxin damage per vomiting episode
#define HYDRATION_ILLNESS_DELAY_MIN (1 MINUTES)
#define HYDRATION_ILLNESS_DELAY_MAX (3 MINUTES)
#define HYDRATION_ILLNESS_EPISODES 3
#define HYDRATION_ILLNESS_EPISODE_INTERVAL (25 SECONDS)
#define HYDRATION_ILLNESS_LOSS 40 // thirst lost per vomiting episode
// Treatments. Amounts are contamination load removed per life tick while the reagent is metabolising
#define HYDRATION_REST_DECAY_MULT 3 // load decays this much faster while lying down or asleep
#define HYDRATION_TREAT_CHARCOAL 1.5 // purges the gut but does not stop an infection that has already started
#define HYDRATION_TREAT_TEA 0.3 // mild, herbal and hot drinks settle the stomach
#define HYDRATION_TREAT_FIZZY 0.15 // sweet fizzy pop (Nuka-Cola, Sunset Sarsaparilla)
#define HYDRATION_TREAT_ANTIBIOTIC 5 // antibiotics also end an active illness

// Default contamination of untreated water, per unit drunk
#define WATER_IMPURE_RAD_PER_UNIT 0.25
#define WATER_IMPURE_PATHOGEN_CHANCE 0.005
// Pre-War or machine-stored drinks: a few units of bad stock still add up
#define DRINK_AGED_PATHOGEN_CHANCE 0.003

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

// Healing is limited by what the body can repair, and repair costs water and food.
#define HEAL_CAPACITY_HEADROOM 1.25 // total healing per tick the body can use, relative to the strongest healer present
#define HEAL_STRAIN_TOX 0.15 // toxin per wasted HP when healers are stacked past that capacity
#define HEAL_COST_THIRST 1 // thirst lost per HP restored
#define HEAL_COST_NUTRITION 1.5 // nutrition lost per HP restored
#define HEAL_FACTOR_THIRSTY 0.9
#define HEAL_FACTOR_PARCHED 0.75
#define HEAL_FACTOR_DEHYDRATED 0.5
#define HEAL_FACTOR_HUNGRY 0.9
#define HEAL_FACTOR_STARVING 0.7
#define HEAL_FACTOR_MIN 0.4
#define HEAL_TOLERANCE_DECAY (5 MINUTES) // one dose of tolerance fades per this long
#define HEAL_TOLERANCE_MAX 5
#define HEAL_TOLERANCE_PENALTY 0.1 // healing lost per dose of tolerance beyond the first
#define HEAL_TOLERANCE_MIN 0.6

// C-27 power, servo burst and repair. Charge is stored as nutrition.
#define C27_SHOCK_COEFF 1.25
#define C27_LOW_POWER_SLOWDOWN 1
#define C27_SHUTDOWN_LEVEL 25
#define C27_BURST_COST 40
#define C27_BURST_DURATION 50
#define C27_BURST_COOLDOWN 450
#define C27_BURST_SLOWDOWN -0.8
#define C27_REPAIR_RATE 0.1
