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
#define HUNGER_ACTIVITY_SCALE 0.3
// Wastelanders live on small, irregular meals and the body adapts, while heavy labour burns at most about half again as much as resting
#define HUNGER_BASAL_MULT 0.85
#define HUNGER_ACTIVITY_MAX 1.5
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
#define HEAL_COST_THIRST 0.6 // thirst lost per HP restored
#define HEAL_COST_NUTRITION 0.8 // nutrition lost per HP restored
#define HEAL_COST_CAP 3 // HP worth of cost charged per tick, so major meds drain no more than minor ones
#define HEAL_HERBAL_COST_MULT 0.5 // herbal remedies heal less, so they also cost less food and water
#define HEAL_TOPICAL_MULT 0.5 // sprays and patches heal the surface only, so they work at half strength and use the same repair budget as everything else
#define HEAL_FACTOR_THIRSTY 0.9
#define HEAL_FACTOR_PARCHED 0.75
#define HEAL_FACTOR_DEHYDRATED 0.5
#define HEAL_FACTOR_HUNGRY 0.9
#define HEAL_FACTOR_STARVING 0.7
#define HEAL_FACTOR_MIN 0.4
#define HEAL_TOLERANCE_DECAY (5 MINUTES) // one dose of tolerance fades per this long
#define HEAL_TOLERANCE_MAX 5
#define HEAL_TOLERANCE_PENALTY 0.07 // healing lost per dose of tolerance beyond the first
#define HEAL_TOLERANCE_MIN 0.7

// Herbal remedies come from tribal tradition, so tribals know how to prepare and use them. Modern chems are unfamiliar to them.
#define HEAL_ORIGIN_HERBAL 1
#define HEAL_ORIGIN_MODERN 2
#define HEAL_HERBAL_TRIBAL_MULT 1.25
#define HEAL_HERBAL_OUTSIDER_MULT 1
#define HEAL_MODERN_TRIBAL_MULT 0.9
#define HEAL_OUTSIDER_HERBAL_HALLUCINATE_PROB 10 // chance per tick that bitter drink gives an outsider a mild hallucination

// Liability quirks
#define HEAL_FRAIL_MULT 0.85
#define HEAL_FRAIL_TOLERANCE_MULT 0.5
// Healing skill comes from the applier's Perception + Intelligence, as Doctor and First Aid do in Fallout. 10 combined is average
#define HEAL_SPECIAL_STEP 0.05 // healing per point of Perception + Intelligence above or below 10; New Vegas Medicine skill takes a stimpak from 1.2x to 3x
#define HEAL_SKILL_MIN 0.8
#define HEAL_SKILL_MAX 1.6
#define HEAL_SELF_BONUS_MULT 0.5 // only half of a positive bonus applies when treating yourself, penalties always apply
#define HEAL_TRAIT_BONUS_FIELD_MEDIC 0.2 // trained medics use the better of their trait or SPECIAL bonus on other people
#define HEAL_TRAIT_BONUS_GRADUATE 0.3
#define HEAL_TRAIT_BONUS_SURGEON 0.4
#define HEAL_MAXHP_MIN 0.8 // healing scales with max HP (Endurance), clamped so it can't swing too far either way
#define HEAL_MAXHP_MAX 1.3
#define HEAL_SCALE_CAP 1.75 // ceiling on skill and max HP scaling combined
// Lore side effects: powder dulls Perception, poultice Agility, and super stimpaks cause "stimpak sickness"
#define HEAL_POWDER_DEBUFF 1
#define HEAL_POWDER_DEBUFF_TIME (18 SECONDS)
#define HEAL_SUPER_STIM_DEBUFF 1
#define HEAL_SUPER_STIM_DEBUFF_TIME (120 SECONDS)
#define HEAL_INT_RUSH_STEP 0.06 // each point of the applier's Intelligence above 5 cuts rushed-healing chance by this much
#define HEAL_NEEDLE_PHOBIA_ONSET 3 // ticks injected healers take to take effect on someone with a fear of needles

// Rushed healing: fast-acting healers can seal embedded objects in and knit unset bones crooked.
#define HEAL_RUSH_EMBED_DAMAGE 3
#define HEAL_RUSH_EMBED_TOX 2
#define WOUND_MALUNION_LIMP 0.8 // extra limp on a leg that knit crooked
#define WOUND_MALUNION_ARM_PENALTY 0.25 // extra interaction penalty on an arm that knit crooked
#define WOUND_MALUNION_RESET_DAMAGE 20 // brute dealt to the limb when a bonesetter re-breaks and resets a crooked bone
#define WOUND_MALUNION_RESET_TIME_MULT 2 // re-breaking takes this many times the base treat time, and 1.5x more on yourself

// Onset and taper: slow-acting healers ramp up over their first ticks and fade out over their last.
#define HEAL_TAPER_FACTOR 1 // healing fades once less than this many ticks of the chem are left

// Interactions between chems
#define HEAL_ALCOHOL_FACTOR 0.85 // drunk bodies repair slower
#define INTERACTION_STIM_MEDX_PROB 25 // chance per tick that stimulants on top of Med-X strain the heart and lungs
#define INTERACTION_ALCOHOL_DEPRESSANT_PROB 30 // chance per tick that alcohol on top of Med-X or morphine suppresses breathing
#define INTERACTION_STEROID_STIM_PROB 15 // chance per tick that Buffout on top of Jet, Turbo or combat stimulants strains the heart

// Combat chems: shortened stuns instead of immunity, and an adrenal debt that is paid when the last one wears off.
#define COMBAT_DEBT_MAX 150
#define COMBAT_CRASH_MIN 15 // debt below this causes no crash
#define COMBAT_CRASH_STAMINA_PER_DEBT 0.4
#define COMBAT_CRASH_STAMINA_MAX 50
#define COMBAT_CRASH_SLOW_SECONDS_PER_DEBT 0.3
#define COMBAT_CRASH_SLOW_SECONDS_MAX 30
#define COMBAT_MEDX_SMOOTHING 0.6 // Med-X numbs the comedown, so other combat chems build less debt while it is active
#define COMBAT_STUN_RESIST_PSYCHO 8 // deciseconds shaved off stuns per tick, the best one applies and they do not stack
#define COMBAT_STUN_RESIST_STIMULANTS 7
#define COMBAT_STUN_RESIST_BUFFOUT 4
#define COMBAT_STUN_RESIST_TURBO 4
#define PSYCHO_DAMAGE_REDUCTION 0.85 // multiplier on brute and burn damage taken
#define PSYCHO_OVERDOSE_RAGE_PROB 25 // chance per tick while overdosing that the rage trauma sets in
#define BUFFOUT_MAX_HEALTH_BONUS 15

// Jet: time seems to slow. Ghouls are barely affected by ordinary Jet.
#define JET_STAMINA_RECOVERY 20
#define JET_GHOUL_EFFECT_MULT 0.25

// Mentats: sharper perception and thinking while active, tired and unfocused afterwards.
#define MENTAT_SPECIAL_BONUS 2
#define MENTAT_CRASH_DROWSY 6
#define MENTAT_CRASH_BLUR 4

// Rushing Water: extra thirst per tick on top of the repair cost
#define RUSHING_WATER_THIRST 1.5

// Fixer: clears dependence and addiction, but leaves the user woozy.
#define FIXER_WOOZY_PROB 8

// C-27 power, servo burst and repair. Charge is stored as nutrition.
#define C27_SHOCK_COEFF 1.25
#define C27_LOW_POWER_SLOWDOWN 1
#define C27_SHUTDOWN_LEVEL 25
#define C27_BURST_COST 40
#define C27_BURST_DURATION 50
#define C27_BURST_COOLDOWN 450
#define C27_BURST_SLOWDOWN -0.8
#define C27_REPAIR_RATE 0.1
