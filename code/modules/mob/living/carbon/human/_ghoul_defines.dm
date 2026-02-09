// Ghoul-specific defines that need to be accessible across multiple files
// This file should be loaded before examine.dm and ghoul.dm
// Place this in: code/modules/mob/living/carbon/human/ghoul_defines.dm

// -------------------------
// Ghoul radiation scaling knobs
// -------------------------
#define GHOUL_RAD_HEAL_START     150      // Minimum radiation to enable healing (LOWERED)
#define GHOUL_RAD_HEAL_FULL      1000     // Radiation for max healing power (LOWERED)
#define GHOUL_RAD_MELTDOWN_START 4000     // Meltdown begins (NOW BASED ON FERAL STACKS)
#define GHOUL_RAD_MELTDOWN_FULL  8000     // Full meltdown (NOW BASED ON FERAL STACKS)

#define GHOUL_GLOW_MIN           0
#define GHOUL_GLOW_MAX           3        

#define GHOUL_MELTDOWN_BRUTE_MAX 2        
#define GHOUL_MELTDOWN_SLOW_MAX  0.10     

// Starvation
#define GHOUL_RAD_STARVE_START   150
#define GHOUL_STARVE_TOX_MAX     0.35     
#define GHOUL_STARVE_CLONE_MAX   0.35     

// Neglect tracker
#define GHOUL_NEGLECT_THRESHOLD  300      
#define GHOUL_NEGLECT_MULTIPLIER 2.5      

// High-rad exposure
#define GHOUL_HIGHRAD_THRESHOLD  1500     
#define GHOUL_EXPOSURE_BUILDUP   200      
#define GHOUL_EXPOSURE_RADS_GAIN 2        

// -------------------------
// NECROTIC SURGE SYSTEM
// -------------------------
#define GHOUL_SURGES_MAX            10     // Maximum healing surges (your necrotic heart's limit)
#define GHOUL_SURGE_COOLDOWN        30     // Seconds between surge regeneration (30s = 5min for full)
#define GHOUL_SURGE_COOLDOWN_INJURED 15    // When injured, recharge twice as fast
#define GHOUL_INJURY_THRESHOLD      25     // Damage threshold to count as "injured"
#define GHOUL_DAMAGE_ACTIVATION_MIN 3      // Minimum damage to activate regen (prevents 0.08 toxin issues)
#define GHOUL_RAD_ABSORPTION_MULT   2.0    // Ghouls absorb 2x radiation
#define GHOUL_COMBAT_TIMEOUT        100    // 10 seconds - time since last combat damage to count as "in combat"
#define GHOUL_COMBAT_COOLDOWN_MULT  0.5    // Cooldown multiplier when in combat (50% = half cooldown time)

// Radiation CONSUMPTION during healing (this is your FUEL)
#define GHOUL_RAD_CONSUME_BASE      2.0    // Radiation consumed per healing tick (LOWERED)
#define GHOUL_RAD_CONSUME_HEAVY     4.0    // Extra consumption when heavily injured (LOWERED)
#define GHOUL_RAD_CONSUME_SURGE     25.0   // Radiation consumed when a SURGE is used (LOWERED)

// Healing percentages (applied to total max HP)
#define GHOUL_HEAL_PERCENT_MIN      0.012  // 1.2% of max HP per tick at minimum radiation
#define GHOUL_HEAL_PERCENT_MAX      0.040  // 4.0% of max HP per tick at optimal radiation

// Radiation decay - ONLY when NOT regenerating
#define GHOUL_RAD_DECAY_BASE        0.5    
#define GHOUL_RAD_DECAY_SCALE_START 500    
#define GHOUL_RAD_DECAY_MAX         5.0    

// Regeneration timeout - if no healing for this long, turn off regen
#define GHOUL_REGEN_TIMEOUT         150    // 15 seconds (150 deciseconds)

// -------------------------
// FERAL STACK SYSTEM
// -------------------------
#define GHOUL_FERAL_MAX             100    // Maximum feral stacks (0-100)
#define GHOUL_FERAL_PER_HP_HEALED   0.15   // Feral stacks gained per HP healed (scales with healing power)
#define GHOUL_FERAL_PER_SURGE_USE   2      // Flat feral stacks per surge consumed (unavoidable cost)
#define GHOUL_FERAL_MELTDOWN_START  40     // Feral stacks when meltdown begins
#define GHOUL_FERAL_MELTDOWN_FULL   80     // Feral stacks for full meltdown
#define GHOUL_FERAL_DECAY_RATE      1      // Feral stacks decay naturally (whole number - 1 per tick)
#define GHOUL_FERAL_DECAY_INTERVAL  100    // Decay 1 feral every 100 ticks (10 seconds)
#define GHOUL_FERAL_RAD_MULT_MIN    1.0    // Minimum radiation absorption multiplier
#define GHOUL_FERAL_RAD_MULT_MAX    3.0    // Maximum radiation absorption multiplier at 100 feral

// Radaway purge system (DEPRECATED - now automatic)
#define GHOUL_RADAWAY_PURGE_AMOUNT  15     // Feral stacks removed per radaway dose (DEPRECATED - now automatic)
#define GHOUL_RADAWAY_PURGE_COOLDOWN 300   // 30 seconds cooldown between purges (300 deciseconds) (DEPRECATED)
#define GHOUL_RADAWAY_PURGE_DAMAGE  5      // Damage taken when purging feral stacks (DEPRECATED)

// Automatic Radaway Cleanse System
#define GHOUL_RADS_PER_CLEANSE       50    // Every 50 rads removed = 1 cleanse charge
#define GHOUL_FERAL_PER_CLEANSE      15    // Each cleanse removes 15 feral stacks
#define GHOUL_CLEANSE_COOLDOWN       600   // 60 seconds between automatic cleanses (increased from 30s)
#define GHOUL_CLEANSE_MAX_CHARGES    3     // Max stockpiled cleanse charges

// -------------------------
// FERAL EMOTE SYSTEM (runechat visible)
// -------------------------
#define GHOUL_FERAL_SPEAK_CHANCE_LOW  1    // 1% chance per tick at low feral
#define GHOUL_FERAL_SPEAK_CHANCE_MID  2    // 2% chance per tick at mid feral
#define GHOUL_FERAL_SPEAK_CHANCE_HIGH 4    // 4% chance per tick at high feral
#define GHOUL_FERAL_SPEAK_FERAL_MIN   20   // Minimum feral stacks to start speaking
#define GHOUL_FERAL_SPEAK_FERAL_MID   40   // Mid-tier feral
#define GHOUL_FERAL_SPEAK_FERAL_HIGH  60   // High feral

// -------------------------
// Wave emission (Glowing One transformation)
// -------------------------
#define GHOUL_WAVE_PULSE_CD        30      
#define GHOUL_WAVE_MIN_RADS        2000    // Need high radiation to emit waves (glowing one path)
#define GHOUL_WAVE_INTENSITY_MIN   4       
#define GHOUL_WAVE_INTENSITY_MAX   22      
#define GHOUL_WAVE_DIAGONALS_PROB  30      
#define GHOUL_WAVE_CAN_CONTAMINATE TRUE    
#define GHOUL_WAVE_RANGE_MOD       RAD_DISTANCE_COEFFICIENT

// Debug toggle
#define GHOUL_DEBUG_RADIATION TRUE

#define GHOUL_FEEDBACK_CD        (45 SECONDS)
#define GHOUL_FERAL_CONFUSED_MAX 14
#define GHOUL_FERAL_JITTER_MAX   10

#define GHOUL_FERAL_ALLY_ON      0.50      // Feral factor when you join ghoul faction (still used for meltdown check)
#define GHOUL_FERAL_ALLY_OFF     0.30      // Feral factor when you leave ghoul faction (still used for meltdown check)
#define GHOUL_FERAL_ALLY_RAD_MIN 2000      // Minimum radiation to join feral faction (radmaxxing required)

// -------------------------
// Chemical interaction
// -------------------------
#define GHOUL_RADAWAY_DAMAGE      2
#define GHOUL_RADAWAY_FEEDBACK    5
#define GHOUL_RADX_DAMAGE         2
#define GHOUL_RADX_FEEDBACK       5
#define GHOUL_STIMPAK_PENALTY     1.5
#define GHOUL_SUPERSTIM_PENALTY   2.5
