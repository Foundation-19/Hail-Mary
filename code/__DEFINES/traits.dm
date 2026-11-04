#define SIGNAL_TRAIT(trait_ref) "trait [trait_ref]"
#define SIGNAL_ADDTRAIT(trait_ref) "addtrait [trait_ref]"
#define SIGNAL_REMOVETRAIT(trait_ref) "removetrait [trait_ref]"

// trait accessor defines
#define ADD_TRAIT(target, trait, source) \
	do { \
		var/list/_L; \
		if (!target.status_traits) { \
			target.status_traits = list(); \
			_L = target.status_traits; \
			_L[trait] = list(source); \
			SEND_SIGNAL(target, SIGNAL_ADDTRAIT(trait), trait); \
		} else { \
			_L = target.status_traits; \
			if (_L[trait]) { \
				_L[trait] |= list(source); \
			} else { \
				_L[trait] = list(source); \
				SEND_SIGNAL(target, SIGNAL_ADDTRAIT(trait), trait); \
			} \
		} \
	} while (0)
#define REMOVE_TRAIT(target, trait, sources) \
	do { \
		var/list/_L = target.status_traits; \
		var/list/_S; \
		if (sources && !islist(sources)) { \
			_S = list(sources); \
		} else { \
			_S = sources\
		}; \
		if (_L && _L[trait]) { \
			for (var/_T in _L[trait]) { \
				if ((!_S && (_T != ROUNDSTART_TRAIT)) || (_T in _S)) { \
					_L[trait] -= _T \
				} \
			};\
			if (!length(_L[trait])) { \
				_L -= trait; \
				SEND_SIGNAL(target, SIGNAL_REMOVETRAIT(trait), trait); \
			}; \
			if (!length(_L)) { \
				target.status_traits = null \
			}; \
		} \
	} while (0)
#define REMOVE_TRAITS_NOT_IN(target, sources) \
	do { \
		var/list/_L = target.status_traits; \
		var/list/_S = sources; \
		if (_L) { \
			for (var/_T in _L) { \
				_L[_T] &= _S;\
				if (!length(_L[_T])) { \
					_L -= _T; \
					SEND_SIGNAL(target, SIGNAL_REMOVETRAIT(_T), _T); \
					}; \
				};\
			if (!length(_L)) { \
				target.status_traits = null\
			};\
		}\
	} while (0)
#define HAS_TRAIT(target, trait) (target.status_traits ? (target.status_traits[trait] ? TRUE : FALSE) : FALSE)
#define HAS_TRAIT_FROM(target, trait, source) (target.status_traits ? (target.status_traits[trait] ? (source in target.status_traits[trait]) : FALSE) : FALSE)
#define HAS_TRAIT_FROM_ONLY(target, trait, source) (\
	target.status_traits ?\
		(target.status_traits[trait] ?\
			((source in target.status_traits[trait]) && (length(target.status_traits) == 1))\
			: FALSE)\
		: FALSE)
#define HAS_TRAIT_NOT_FROM(target, trait, source) (target.status_traits ? (target.status_traits[trait] ? (length(target.status_traits[trait] - source) > 0) : FALSE) : FALSE)

//mob traits
/// Forces the user to stay unconscious.
#define TRAIT_KNOCKEDOUT "knockedout"
#define TRAIT_BLIND 			"blind"
#define TRAIT_MUTE				"mute"
#define TRAIT_EMOTEMUTE			"emotemute"
#define TRAIT_LOOC_MUTE			"looc_mute" //Just like unconsciousness, it disables LOOC salt.
#define TRAIT_AOOC_MUTE			"aooc_mute" //Same as above but for AOOC.
#define TRAIT_DEAF				"deaf"
#define TRAIT_NEARSIGHT			"nearsighted"
#define TRAIT_NEARSIGHT_MEGA	"nearsighted_suffering"
#define TRAIT_FAT				"fat"
#define TRAIT_HUSK				"husk"
#define TRAIT_NOCLONE			"noclone"
#define TRAIT_CLUMSY			"clumsy"
#define TRAIT_CHUNKYFINGERS		"chunkyfingers" //means that you can't use weapons with normal trigger guards.
#define TRAIT_DUMB				"dumb"
#define TRAIT_MONKEYLIKE		"monkeylike" //sets IsAdvancedToolUser to FALSE
#define TRAIT_PACIFISM			"pacifism"
#define TRAIT_IGNORESLOWDOWN	"ignoreslow"
#define TRAIT_IGNOREDAMAGESLOWDOWN "ignoredamageslowdown"
#define TRAIT_DEATHCOMA			"deathcoma" //Causes death-like unconsciousness
#define TRAIT_FAKEDEATH			"fakedeath" //Makes the owner appear as dead to most forms of medical examination
#define TRAIT_DISFIGURED		"disfigured"
#define TRAIT_XENO_HOST			"xeno_host"	//Tracks whether we're gonna be a baby alien's mummy.
#define TRAIT_STUNIMMUNE		"stun_immunity"
#define TRAIT_TASED_RESISTANCE	"tased_resistance" //prevents you from suffering most of the effects of being tased
#define TRAIT_SLEEPIMMUNE		"sleep_immunity"
#define TRAIT_PUSHIMMUNE		"push_immunity"
#define TRAIT_SHOCKIMMUNE		"shock_immunity"
#define TRAIT_WIREVISION		"wire omniescience"
#define TRAIT_TESLA_SHOCKIMMUNE	"tesla_shock_immunity"
#define TRAIT_STABLEHEART		"stable_heart"
#define TRAIT_STABLELIVER		"stable_liver"
#define TRAIT_RESISTHEAT		"resist_heat"
#define TRAIT_RESISTHEATHANDS	"resist_heat_handsonly" //For when you want to be able to touch hot things, but still want fire to be an issue.
#define TRAIT_RESISTCOLD		"resist_cold"
#define TRAIT_RESISTHIGHPRESSURE	"resist_high_pressure"
#define TRAIT_RESISTLOWPRESSURE	"resist_low_pressure"
#define TRAIT_BOMBIMMUNE		"bomb_immunity"
#define TRAIT_RADIMMUNE			"rad_immunity"
#define TRAIT_75_RAD_RESIST		"big_rad_resist"
#define TRAIT_50_RAD_RESIST		"some_rad_resist"
#define TRAIT_GENELESS			"geneless"
#define TRAIT_VIRUSIMMUNE		"virus_immunity"
#define TRAIT_PIERCEIMMUNE		"pierce_immunity"
#define TRAIT_NODISMEMBER		"dismember_immunity"
#define TRAIT_NOFIRE			"nonflammable"
#define TRAIT_NOGUNS			"no_guns"
#define TRAIT_NOHUNGER			"no_hunger"
#define TRAIT_EASYDISMEMBER		"easy_dismember"
#define TRAIT_LIMBATTACHMENT 	"limb_attach"
#define TRAIT_NOLIMBDISABLE		"no_limb_disable"
#define TRAIT_EASYLIMBDISABLE	"easy_limb_disable"
#define TRAIT_TOXINLOVER		"toxinlover"
#define TRAIT_TOXINIMMUNE		"toxinimmune"
#define TRAIT_CLONEIMMUNE		"cloneimmune"
#define TRAIT_NOBREATH			"no_breath"
#define TRAIT_ANTIMAGIC			"anti_magic"
#define TRAIT_HOLY				"holy"
#define TRAIT_DEPRESSION		"depression"
#define TRAIT_PESSIMIST			"pessimist"
#define TRAIT_JOLLY				"jolly"
#define TRAIT_OPTIMIST			"optimist"
#define TRAIT_NOCRITDAMAGE		"no_crit"
#define TRAIT_NOSLIPWATER		"noslip_water"
#define TRAIT_NOSLIPALL			"noslip_all"
#define TRAIT_NODEATH			"nodeath"
#define TRAIT_NOHARDCRIT		"nohardcrit"
#define TRAIT_NOSOFTCRIT		"nosoftcrit"
#define TRAIT_NUKA_LOVER		"nukalover"
#define TRAIT_MINDSHIELD		"mindshield"
#define TRAIT_HIJACKER			"hijacker"
#define TRAIT_SIXTHSENSE		"sixthsense"
#define TRAIT_DISSECTED			"dissected"
#define TRAIT_FEARLESS			"fearless"
#define TRAIT_CATPHOBIA			"catphobia"
#define TRAIT_RATPHOBIA			"ratphobia"
#define TRAIT_SPIDERPHOBIA		"spiderphobia"
#define TRAIT_LIZARDPHOBIA		"lizardphobia"
#define TRAIT_ROBOTPHOBIA		"robotphobia"
#define TRAIT_BIRDPHOBIA		"birdphobia"
#define TRAIT_DOGPHOBIA			"dogphobia"
#define TRAIT_BONERPHOBIA		"skelephobia"
#define TRAIT_MASKPHOBIA		"maskphobia"
#define TRAIT_DOCTORPHOBIA		"doctorphobia"
#define TRAIT_EYEPHOBIA			"eyephobia"
#define TRAIT_CAT				"cats" // Try to match these species traits to phobia types in trauma.dm, makes life easier.
#define TRAIT_RAT				"rats"
#define TRAIT_SPIDER			"spiders"
#define TRAIT_LIZARD			"lizards"
#define TRAIT_ROBOT				"robots"
#define TRAIT_BIRD				"birds"
#define TRAIT_DOG				"dogs"
#define TRAIT_UNSTABLE			"unstable"
#define TRAIT_PARALYSIS_L_ARM	"para-l-arm" //These are used for brain-based paralysis, where replacing the limb won't fix it
#define TRAIT_PARALYSIS_R_ARM	"para-r-arm"
#define TRAIT_PARALYSIS_L_LEG	"para-l-leg"
#define TRAIT_PARALYSIS_R_LEG	"para-r-leg"
#define TRAIT_DISK_VERIFIER     "disk-verifier"
#define TRAIT_UNINTELLIGIBLE_SPEECH "unintelligible-speech"
#define TRAIT_SAY_STUTTERING	"say-stuttering"
#define TRAIT_SAY_LISPING		"say-lisping"
#define TRAIT_SOOTHED_THROAT    "soothed-throat"
#define TRAIT_LAW_ENFORCEMENT_METABOLISM "law-enforcement-metabolism"
#define TRAIT_QUICK_CARRY		"quick-carry"
#define TRAIT_QUICKER_CARRY		"quicker-carry"
#define TRAIT_SLOW_CARRY		"slow-carry"
#define TRAIT_QUICK_BUILD		"quick-build"
#define TRAIT_STRONG_GRABBER	"strong_grabber"
#define TRAIT_CALCIUM_HEALER	"calcium_healer"
#define TRAIT_MAGIC_CHOKE		"magic_choke"
#define TRAIT_CAPTAIN_METABOLISM "captain-metabolism"
#define TRAIT_ABDUCTOR_TRAINING "abductor-training"
#define TRAIT_ABDUCTOR_SCIENTIST_TRAINING "abductor-scientist-training"
#define TRAIT_SURGEON           "surgeon"
#define TRAIT_COLDBLOODED		"coldblooded"	// Your body is literal room temperature. Does not make you immune to the temp.
#define TRAIT_NONATURALHEAL		"nonaturalheal"	// Only Admins can heal you. NOTHING else does it unless it's given the god tag.
#define TRAIT_NORUNNING			"norunning"		// You walk!
#define TRAIT_NOMARROW			"nomarrow"		// You don't make blood, with chemicals or nanites.
#define TRAIT_NOPULSE			"nopulse"		// Your heart doesn't beat.
#define TRAIT_NOGUT				"nogutting"		//Your chest cant be gutted of organs
#define TRAIT_NODECAP			"nodecapping"	//Your head cant be cut off in combat
#define TRAIT_EXEMPT_HEALTH_EVENTS	"exempt-health-events"
#define TRAIT_NO_MIDROUND_ANTAG	"no-midround-antag" //can't be turned into an antag by random events
#define TRAIT_PUGILIST	"pugilist" //This guy punches people for a living
#define TRAIT_KI_VAMPIRE	"ki-vampire" //when someone with this trait rolls maximum damage on a punch and stuns the target, they regain some stamina and do clone damage
#define TRAIT_LOCKPICKING	"lockpicking_skilled" // Professional muscle memory: wider zones, quieter work, more timer grace
#define TRAIT_ASSASSIN	"assassin" //Can perform deadly assassination strikes on unaware enemies
#define TRAIT_SNEAK_RANK1	"sneak_rank1" //Halves movement sound level (hostile mob detection) while in sneak mode
#define TRAIT_SNEAK_RANK2	"sneak_rank2" //Quarters movement sound level while in sneak mode. Requires Sneak I
#define TRAIT_SILENT_RUN_RANK1	"silent_run_rank1" //Reduces movement sound level while running
#define TRAIT_SILENT_RUN_RANK2	"silent_run_rank2"
#define TRAIT_SILENT_RUN_RANK3	"silent_run_rank3"
#define TRAIT_STRONGBACK_RANK1	"strongback_rank1" //Extra flat bonus to Strength-based carry capacity multiplier, on top of raw Strength scaling
#define TRAIT_STRONGBACK_RANK2	"strongback_rank2" //Larger extra flat bonus to carry capacity multiplier. Requires Strong Back I
#define TRAIT_HOARDER	"hoarder" //Wasteland Trait: flat carry capacity bonus, same scale as Strong Back
#define TRAIT_FINESSE	"finesse" //Wasteland Trait: more critical hits, less damage on everything else
#define TRAIT_BUILT_TO_DESTROY	"built_to_destroy" //Wasteland Trait: more critical hits, guns jam more
#define TRAIT_JINXED	"jinxed" //Wasteland Trait: everyone nearby (including you) fumbles more
#define TRAIT_BLOODY_MESS	"bloody_mess" //Wasteland Trait: critical hits are gorier and hit slightly harder
#define TRAIT_WEAK_BACK	"weak_back" //Liability: smaller carry capacity and fewer item slots
#define TRAIT_PUSHOVER	"pushover" //Liability: deal less melee and projectile damage
#define TRAIT_HAGGLERS_CURSE	"hagglers_curse" //Liability: vending machines charge more
#define TRAIT_UNLUCKY	"unlucky" //Liability: guns jam more and crits are rarer
#define TRAIT_SHAKY_AIM	"shaky_aim" //Liability: worse gun spread while moving
#define TRAIT_SLOW_HEALER	"slow_healer" //Liability: medical stacks heal you less
#define TRAIT_DEHYDRATED	"dehydrated" //Liability: thirst builds faster
#define TRAIT_NUCLEAR_PHYSICIST_RANK1	"nuclear_physicist_rank1" //Power Armor fusion cells drain slower
#define TRAIT_NUCLEAR_PHYSICIST_RANK2	"nuclear_physicist_rank2" //Power Armor fusion cells drain even slower. Requires Nuclear Physicist I
#define TRAIT_PA_TRAINED_RANK2	"pa_trained_rank2" //Power Armor Training II: Power Armor fusion cells drain 15% slower
#define TRAIT_FORTUNE_FINDER_RANK1	"fortune_finder_rank1" //Scavenging and trash piles reroll toward rarer loot
#define TRAIT_FORTUNE_FINDER_RANK2	"fortune_finder_rank2"
#define TRAIT_FORTUNE_FINDER_RANK3	"fortune_finder_rank3"
#define TRAIT_SCROUNGER_RANK1	"scrounger_rank1" //Chance for extra junk/ammo from scavenging and trash piles
#define TRAIT_SCROUNGER_RANK2	"scrounger_rank2"
#define TRAIT_SCROUNGER_RANK3	"scrounger_rank3"
#define TRAIT_TRADER_RANK1	"trader_rank1" //Discount at vending machines
#define TRAIT_TRADER_RANK2	"trader_rank2"
#define TRAIT_LEADER_RANK1	"leader_rank1" //Stronger party aura while leading a party
#define TRAIT_LEADER_RANK2	"leader_rank2"
#define TRAIT_SCAVENGERS_EYE	"scavengers_eye" //Scavenging takes less time
#define TRAIT_JUNK_RATTLER	"junk_rattler" //Chance of extra salvage and disassembly loot
#define TRAIT_AMMO_SMITH	"ammo_smith" //Reloading benches use less material
#define TRAIT_SNIPER_RANK1	"sniper_rank1" //Tighter spread with scoped/zoomed guns
#define TRAIT_SNIPER_RANK2	"sniper_rank2"
#define TRAIT_COMMANDO_RANK1	"commando_rank1" //Tighter spread with automatic/burst guns
#define TRAIT_COMMANDO_RANK2	"commando_rank2"
#define TRAIT_GUNSLINGER_RANK1	"gunslinger_rank1" //Tighter spread and faster refire with one-handed guns
#define TRAIT_GUNSLINGER_RANK2	"gunslinger_rank2"
#define TRAIT_HEAVY_GUNNER_RANK1	"heavy_gunner_rank1" //Tighter spread with heavy guns
#define TRAIT_HEAVY_GUNNER_RANK2	"heavy_gunner_rank2"
#define TRAIT_BLADEMASTER_RANK1	"blademaster_rank1" //Bonus damage with edged melee weapons
#define TRAIT_BLADEMASTER_RANK2	"blademaster_rank2"
#define TRAIT_BLADEMASTER_RANK3	"blademaster_rank3"
#define TRAIT_BRAWLER_RANK1	"brawler_rank1" //Bonus unarmed punch damage
#define TRAIT_BRAWLER_RANK2	"brawler_rank2"
#define TRAIT_BRAWLER_RANK3	"brawler_rank3"
#define TRAIT_STEADY_AIM	"steady_aim" //Tighter spread when standing still
#define TRAIT_QUICK_DRAW	"quick_draw" //Guns are ready faster when drawn
#define TRAIT_CONCENTRATED_FIRE	"concentrated_fire" //Bonus damage on repeated shots at one target
#define TRAIT_FOLLOW_THROUGH	"follow_through" //Bonus projectile damage shortly after moving
#define TRAIT_MEDIC_RANK1	"medic_rank1" //Medical stacks heal more and apply faster
#define TRAIT_MEDIC_RANK2	"medic_rank2"
#define TRAIT_MEDIC_RANK3	"medic_rank3"
#define TRAIT_HEALER_RANK1	"healer_rank1" //Surgery steps are performed faster
#define TRAIT_HEALER_RANK2	"healer_rank2"
#define TRAIT_MAD_SCIENTIST_RANK1	"mad_scientist_rank1" //Crafting takes less time
#define TRAIT_MAD_SCIENTIST_RANK2	"mad_scientist_rank2"
#define TRAIT_ROBOTICS_EXPERT_RANK1	"robotics_expert_rank1" //Extra salvage from machinery wrecks
#define TRAIT_ROBOTICS_EXPERT_RANK2	"robotics_expert_rank2"
#define TRAIT_FIELD_MEDIC	"field_medic" //Faster and stronger bandages and sutures
#define TRAIT_WEAPON_MAINTENANCE	"weapon_maintenance" //Guns wear out slower and are serviced better
#define TRAIT_STEADY_HANDS	"steady_hands" //Tighter spread
#define TRAIT_WATER_WISE	"water_wise" //Thirst builds more slowly
#define TRAIT_IRON_STOMACH	"iron_stomach" //Dirty water rarely makes you sick
#define TRAIT_DELICATE_STOMACH	"delicate_stomach" //Liability: dirty water makes you sick more often
#define TRAIT_HARDY_METABOLISM	"hardy_metabolism" //Healing costs less water and food, and hunger and thirst slow it less
#define TRAIT_SEASONED_USER	"seasoned_user" //Healing chem tolerance builds more slowly
#define TRAIT_CAST_IRON_CONSTITUTION	"cast_iron_constitution" //Chem interactions hit much less hard
#define TRAIT_FRAIL_CONSTITUTION	"frail_constitution" //Liability: healing chems work worse, but tolerance builds more slowly
#define TRAIT_NEEDLE_PHOBIA	"needle_phobia" //Liability: injected healers are slow to take effect
#define TRAIT_CAMPER	"camper" //Campfires burn longer and cook faster
#define TRAIT_QUICK_CLEAN	"quick_clean" //Soap cleans faster
#define TRAIT_DODGER_RANK1	"dodger_rank1" //Chance to fully avoid melee attacks
#define TRAIT_DODGER_RANK2	"dodger_rank2"
#define TRAIT_AWARENESS_RANK1	"awareness_rank1" //Chance to notice landmines in time, and sneak vision cones show from further away
#define TRAIT_AWARENESS_RANK2	"awareness_rank2"
#define TRAIT_AWARENESS_RANK3	"awareness_rank3"
#define TRAIT_SCOUT_RANK1	"scout_rank1" //Sneak vision cones show from much further away
#define TRAIT_SCOUT_RANK2	"scout_rank2"
#define TRAIT_SCOUT_RANK3	"scout_rank3"
#define TRAIT_SHADOW_RANK1	"shadow_rank1" //Sneaking makes even less noise
#define TRAIT_SHADOW_RANK2	"shadow_rank2"
#define TRAIT_EAGLE_EYE	"eagle_eye" //Scopes show further ahead
#define TRAIT_MORE_CRITICALS_RANK1	"more_criticals_rank1" //Higher critical hit chance
#define TRAIT_MORE_CRITICALS_RANK2	"more_criticals_rank2"
#define TRAIT_MORE_CRITICALS_RANK3	"more_criticals_rank3"
#define TRAIT_BETTER_CRITICALS	"better_criticals" //Critical hits deal more damage
#define TRAIT_LUCKY_PINS	"lucky_pins" //Lockpicks break less and the lock gives one extra attempt
#define TRAIT_JACKPOT	"jackpot" //Slot machine wins pay more, and losing spins sometimes refund
#define TRAIT_HOT_STREAK	"hot_streak" //Terminal hacks sometimes refund a wrong guess and lucky breaks are likelier
#define TRAIT_LUCKY_BREAK	"lucky_break" //Guns jam and cook off less often
#define TRAIT_SECOND_WIND	"second_wind" //A chance to survive a killing blow, on a long cooldown
#define TRAIT_LUCKY_CATCH	"lucky_catch" //Better odds at fishing, and sometimes a second fish
#define TRAIT_VEIN_FINDER	"vein_finder" //Mining sometimes turns up extra ore
#define TRAIT_WILD_CARD	"wild_card" //Critical hits sometimes knock the target down or disarm them
#define TRAIT_GAMBLERS_EYE	"gamblers_eye" //Dice you roll land on the better of two rolls
/// How long Second Wind keeps its holder from being finished off after it triggers
#define SECOND_WIND_GRACE (5 SECONDS)
#define TRAIT_PASSTABLE			"passtable"
#define TRAIT_GIANT				"giant"
#define TRAIT_DWARF				"dwarf"
#define TRAIT_ALCOHOL_TOLERANCE	"alcohol_tolerance"
#define TRAIT_AGEUSIA			"ageusia"
#define TRAIT_HEAVY_SLEEPER		"heavy_sleeper"
#define TRAIT_NIGHT_VISION		"night_vision"
#define TRAIT_LIGHT_STEP		"light_step"
#define TRAIT_SILENT_STEP		"silent_step"
#define TRAIT_SPEEDY_STEP		"speedy_step"
#define TRAIT_SPIRITUAL			"spiritual"
#define TRAIT_VORACIOUS			"voracious"
#define TRAIT_SELF_AWARE		"self_aware"
#define TRAIT_FREERUNNING		"freerunning"
#define TRAIT_FREEFALLER		"freefaller"
#define TRAIT_SKITTISH			"skittish"
#define TRAIT_POOR_AIM			"poor_aim"
#define TRAIT_INSANE_AIM		"insane_aim" //they don't miss. they never miss. it was all part of their immaculate plan.
#define SPREAD_CONTROL		"spread_control"
#define TRAIT_PROSOPAGNOSIA		"prosopagnosia"
#define TRAIT_DRUNK_HEALING		"drunk_healing"
#define TRAIT_TAGGER			"tagger"
#define TRAIT_PHOTOGRAPHER		"photographer"
#define TRAIT_JOURNALIST		"journalist"
#define TRAIT_MUSICIAN			"musician"
#define	TRAIT_HIGH_BLOOD        "high_blood"
#define TRAIT_PARA              "paraplegic"
#define TRAIT_EMPATH			"empath"
#define TRAIT_FRIENDLY			"friendly"
#define TRAIT_BIG_LEAGUES		"big_leagues"
#define TRAIT_BIG_LEAGUES_MID	"big_leagues_mid"
#define TRAIT_LITTLE_LEAGUES	"little_leagues"
#define TRAIT_BREAKER			"breaker" // Fully charged, blunt power attacks gain DT penetration
#define TRAIT_IRON_GRIP			"iron_grip" // Once per cooldown, withstand a light hit during a power-attack windup
#define TRAIT_GENTLE			"gentle"
#define TRAIT_WIMPY				"wimpy"
#define TRAIT_FEV				"FEV_MUT" //OH BOY
#define TRAIT_GHOULMELEE		"ghoulmelee"
#define TRAIT_TRAPPER			"trapper"
#define TRAIT_IRONFIST			"iron_fist"
#define TRAIT_STEELFIST			"steel_fist"
#define TRAIT_TITANIUMFIST		"titanium_fist"
#define TRAIT_NOODLEFIST			"noodle_fist"
#define TRAIT_POWER_ARMOR		"power_armor"
#define TRAIT_BARBEDWIRENODMG	"wire_monkey" //Ook dook.
#define TRAIT_SNOB				"snob"
#define TRAIT_CULT_EYES 		"cult_eyes"
#define TRAIT_AUTO_CATCH_ITEM	"auto_catch_item"
#define TRAIT_CLOWN_MENTALITY	"clown_mentality" // The future is now, clownman.
#define TRAIT_FREESPRINT		"free_sprinting"
#define TRAIT_XRAY_VISION       "xray_vision"
#define TRAIT_THERMAL_VISION    "thermal_vision"
#define TRAIT_NO_TELEPORT		"no-teleport" //you just can't
#define TRAIT_NO_INTERNALS		"no-internals"
#define TRAIT_NO_ALCOHOL		"alcohol_intolerance"
#define TRAIT_MUTATION_STASIS			"mutation_stasis" //Prevents processed genetics mutations from processing.
#define TRAIT_FAST_PUMP				"fast_pump"
#define TRAIT_AUTO_DRAW				"auto_draw" //can use bows good
#define TRAIT_PLAY_DEAD "play_dead" // gives 10u ghoul powder every *deathgasp
#define TRAIT_NO_PROCESS_FOOD	"no-process-food" // You don't get benefits from nutriment, nor nutrition from reagent consumables
#define TRAIT_NICE_SHOT			"nice_shot" //hnnnnnnnggggg..... you're pretty good...
#define TRAIT_TRIGGER_DISCIPLINE	"trigger_discipline" //-25% recoil, -20% rate of fire.
#define TRAIT_PERFECT_ATTACKER	"perfect_attacker"
#define TRAIT_BUFFOUT_BUFF		"buffout_buff"
#define TRAIT_PSYCHO_BUFF		"psycho_buff"
#define TRAIT_UNARMED_WEAPON	"unarmed_weapon"
/// Prevents usage of manipulation appendages (picking, holding or using items, manipulating storage).
#define TRAIT_HANDS_BLOCKED "handsblocked"
#define TRAIT_ILLITERATE "illiterate"
#define TRAIT_PAPER_SKIN "paper_skin"
#define TRAIT_GLASS_BONES "glass_bones"
#define TRAIT_STEEL_ASS "steel_ass"
#define TRAIT_HYDRA_HEADS "hydra_heads"
#define TRAIT_SHELTERED "sheltered"
#define TRAIT_WEAPONSMITH "weaponsmith"
#define TRAIT_BEASTFRIEND_RAT "beastfriend-rats"
#define TRAIT_BEASTFRIEND_SMALLCRITTER "beastfriend-smallcritters"
#define TRAIT_BEASTMASTER_RAT "beastmaster-rats"
#define TRAIT_BEASTMASTER_SMALLCRITTER "beastmaster-smallcritters"
#define TRAIT_NO_CHOCOLATE "chocolate-intolerance"
#define TRAIT_WHITE_WOMAN "peanutbutter-difficulties"
#define TRAIT_AUTOBREW "autobrewery-syndrome"
#define TRAIT_SPEED "SPEED"
#define TRAIT_SUPER_SPEED "super SPEED"

// Hey. Dickheads. Never, ever use anything cringe like 'zoomies' or 'smol' as a define ever again. - Hangyul
// Hey. Hangyul often have Zoomies, and is smol in fallout canon, according to the fallout bible. -Delta

// mobility flag traits
// IN THE FUTURE, IT WOULD BE NICE TO DO SOMETHING SIMILAR TO https://github.com/tgstation/tgstation/pull/48923/files (ofcourse not nearly the same because I have my.. thoughts on it)
// BUT FOR NOW, THESE ARE HOOKED TO DO update_mobility() VIA COMSIG IN living_mobility.dm
// SO IF YOU ADD MORE, BESURE TO UPDATE IT THERE.

/// Disallow movement
#define TRAIT_MOBILITY_NOMOVE		"mobility_nomove"
/// Disallow pickup
#define TRAIT_MOBILITY_NOPICKUP		"mobility_nopickup"
/// Disallow item use
#define TRAIT_MOBILITY_NOUSE		"mobility_nouse"

#define TRAIT_SWIMMING			"swimming"			//only applied by /datum/element/swimming, for checking

/**
 * COMBAT MODE/SPRINT MODE TRAITS
 */

/// Prevents combat mode from being active.
#define TRAIT_COMBAT_MODE_LOCKED		"combatmode_locked"
/// Prevents sprinting from being active.
#define TRAIT_SPRINT_LOCKED				"sprint_locked"


#define TRAIT_SMUTANT		"Super Mutant"	// This is a trait usually locked for admins due to how OP it is
#define	TRAIT_CHEMWHIZ			"chemwhiz"
#define TRAIT_TECHNOPHOBE		"luddite" //Cannot use autolathes/biogens
#define TRAIT_NODRUGS		"winners_cant_do_drugs" //drugs hurt you!
#define TRAIT_LONGPORKLOVER		"Cannibal" //guess
#define TRAIT_TRIBAL			"Tribalistic Person" //has access to tribal crafting recipes
#define TRAIT_BERSERKER			"berserker" //currently unused
#define TRAIT_TECHNOPHREAK		"technophreak"	//boosts salvage return
#define TRAIT_WEAPONCRAFTING	"weapon_crafting"	// You spawn with various unlocked gun/armor crafts
#define TRAIT_PA_WEAR           "pa_wear" //guess
#define TRAIT_C27           "c27_wear" //guess
#define TRAIT_MEDICALEXPERT		"Medicinal Expert" //Can do revival surgery
#define TRAIT_MEDICALGRADUATE		"Medical Graduate" //generalised offmap medschool graduation training
#define TRAIT_BRAINWASH_SURGERY	"brainwash_surgeon" //Can do harmful experimental surguries
#define TRAIT_CYBERNETICIST		"Cyberneticist" //Utilizes powerful cybernetics
#define TRAIT_CYBERNETICIST_EXPERT	"Cyberneticist Expert" //Can augument people into robots directly
#define TRAIT_MACHINE_SPIRITS	"machine_spirits" //for tribe unique functions.
#define TRAIT_HARD_YARDS        "hard_yards" //trekking, removes slowdown on all tiles
#define	TRAIT_SOFT_YARDS		"soft_yards" //lesser trekking
#define	TRAIT_SLUG				"slow" //You're a little slow. On your feet, at least.
#define	TRAIT_SLOWAF			"slower" //Damn boi how'd you even get here, you're slow as SHIT off road
#define	TRAIT_LIFEGIVER			"lifegiver" //boosts HP by 10
#define	TRAIT_LIFEGIVERPLUS		"lifegiverplus" //boosts HP by 20
#define	TRAIT_LIFEGIVERMAX		"lifegivermax" //boosts HP by 40 and grants passive regen
#define	TRAIT_FLIMSY			"flimsy" //lowers HP by 10
#define	TRAIT_VERYFLIMSY			"veryflimsy" //lowers HP by 20
#define TRAIT_MARS_TEACH		"mars_teachings" //for legion unique functions
#define TRAIT_EXPLOSIVE_CRAFTING "explosive_crafting" //can craft explosives and bombs
#define TRAIT_ADVANCED_EXPLOSIVE_CRAFTING "advanced explosive crafting" //can craft almost all kinds of explosives
#define TRAIT_PILOT 			"pilot" //For Vertibird use
/*
#define TRAIT_HEAL_TONGUE "healing tongue"
/// Lets your tongue apply awful bandages to limbs
#define TRAIT_BANDAGE_TONGUE "coagulating tongue"
*/
/// You're hooked on punga!
#define TRAIT_PUNGAPOWER "pungaful"

#define TRAIT_SURGERY_LOW		"lowsurgery"
#define TRAIT_SURGERY_MID		"midsurgery"
#define TRAIT_SURGERY_HIGH		"highsurgery"

// fallout crafting traits
#define TRAIT_FORMER_TRIBAL     "ex_tribal_traditions"
#define TRAIT_GUNSMITH_ONE      "gunsmith_one" //crafts poor guns
#define TRAIT_GUNSMITH_TWO      "gunsmith_two" //crafts mid level guns
#define TRAIT_GUNSMITH_THREE    "gunsmith_three" //crafts weapon parts
#define TRAIT_GUNSMITH_FOUR     "gunsmith_four" //currently unused
#define TRAIT_WHITELEGS_TRAD	"whiteleg_traditions"
#define TRAIT_DEADHORSES_TRAD	"deadhorses_traditions"
#define TRAIT_RUSTWALKERS_TRAD	"rustwalker_traditions"
#define TRAIT_EIGHTIES_TRAD		"eighties_traditions"
#define TRAIT_SORROWS_TRAD		"sorrows_traditions"
#define TRAIT_WAYFARER_TRAD		"wayfarers_traditions"
#define TRAIT_BONEDANCER_TRAD	"bonedancer_traditions"

//non-mob traits
#define TRAIT_PARALYSIS				"paralysis" //Used for limb-based paralysis, where replacing the limb will fix it
#define VEHICLE_TRAIT "vehicle" // inherited from riding vehicles
#define INNATE_TRAIT "innate"

///Used for managing KEEP_TOGETHER in [appearance_flags]
#define TRAIT_KEEP_TOGETHER 	"keep-together"

// item traits
#define TRAIT_NODROP "nodrop"
/// Dont put it in storage things, simple as
#define TRAIT_NO_STORAGE_INSERT "no_storage_insert"
/// Can't leave a storage!
#define TRAIT_NO_STORAGE_REMOVE "TRAIT_NO_STORAGE_REMOVE"

// common trait sources
#define TRAIT_GENERIC "generic"
#define EYE_DAMAGE "eye_damage"
#define GENETIC_MUTATION "genetic"
#define OBESITY "obesity"
#define MAGIC_TRAIT "magic"
#define TRAUMA_TRAIT "trauma"
#define DISEASE_TRAIT "disease"
#define SPECIES_TRAIT "species"
#define ORGAN_TRAIT "organ"
#define JOB_TRAIT "job"
#define CYBORG_ITEM_TRAIT "cyborg-item"
#define ADMIN_TRAIT "admin" // (B)admins only.
#define CHANGELING_TRAIT "changeling"
#define CULT_TRAIT "cult"
#define CURSED_ITEM_TRAIT "cursed-item" // The item is magically cursed
#define ABSTRACT_ITEM_TRAIT "abstract-item"
#define STATUS_EFFECT_TRAIT "status-effect"
#define CLOTHING_TRAIT "clothing"
#define ROUNDSTART_TRAIT "roundstart" //cannot be removed without admin intervention
#define GHOSTROLE_TRAIT "ghostrole"
#define BLOODSUCKER_TRAIT "bloodsucker"
#define SHOES_TRAIT "shoes" //inherited from your sweet kicks
#define GLOVE_TRAIT "glove" //inherited by your cool gloves
#define BOOK_TRAIT "granter (book)" // knowledge is power

// unique trait sources, still defines
#define STATUE_TRAIT "statue"
#define CLONING_POD_TRAIT "cloning-pod"
#define VIRTUAL_REALITY_TRAIT "vr_trait"
#define CHANGELING_DRAIN "drain"
#define CHANGELING_HIVEMIND_MUTE "ling_mute"
#define ABYSSAL_GAZE_BLIND "abyssal_gaze"
#define HIGHLANDER "highlander"
#define TRAIT_HULK "hulk"
#define STASIS_MUTE "stasis"
#define GENETICS_SPELL "genetics_spell"
#define EYES_COVERED "eyes_covered"
#define CLOWN_NUKE_TRAIT "clown-nuke"
#define STICKY_MOUSTACHE_TRAIT "sticky-moustache"
#define CHAINSAW_FRENZY_TRAIT "chainsaw-frenzy"
#define CHRONO_GUN_TRAIT "chrono-gun"
#define REVERSE_BEAR_TRAP_TRAIT "reverse-bear-trap"
#define GLUED_ITEM_TRAIT "glued-item"
#define CURSED_MASK_TRAIT "cursed-mask"
#define HIS_GRACE_TRAIT "his-grace"
#define HAND_REPLACEMENT_TRAIT "magic-hand"
#define HOT_POTATO_TRAIT "hot-potato"
#define SABRE_SUICIDE_TRAIT "sabre-suicide"
#define ABDUCTOR_VEST_TRAIT "abductor-vest"
#define CAPTURE_THE_FLAG_TRAIT "capture-the-flag"
#define EYE_OF_GOD_TRAIT "eye-of-god"
#define SHAMEBRERO_TRAIT "shamebrero"
#define CHRONOSUIT_TRAIT "chronosuit"
#define FLIGHTSUIT_TRAIT "flightsuit"
#define LOCKED_HELMET_TRAIT "locked-helmet"
#define NINJA_SUIT_TRAIT "ninja-suit"
#define ANTI_DROP_IMPLANT_TRAIT "anti-drop-implant"
#define MARTIAL_ARTIST_TRAIT "martial_artist"
#define BERSERKER_TRAIT "berserker"
#define SLEEPING_CARP_TRAIT "sleeping_carp"
#define RISING_BASS_TRAIT "rising_bass"
#define RAGING_BOAR_TRAIT "raging_boar"
#define ABDUCTOR_ANTAGONIST "abductor-antagonist"
#define MADE_UNCLONEABLE "made-uncloneable"
#define TIMESTOP_TRAIT "timestop"
#define NUKEOP_TRAIT "nuke-op"
#define CLOWNOP_TRAIT "clown-op"
#define MEGAFAUNA_TRAIT "megafauna"
#define DEATHSQUAD_TRAIT "deathsquad"
/// This trait is added by the active directional block system.
#define ACTIVE_BLOCK_TRAIT				"active_block"
/// This trait is added by the parry system.
#define ACTIVE_PARRY_TRAIT				"active_parry"
/// Granted briefly after a successful active block - the next attack lands empowered.
#define TRAIT_BLOCK_COUNTER_READY		"block_counter_ready"
/// Trait source for TRAIT_BLOCK_COUNTER_READY.
#define BLOCK_COUNTER_TRAIT				"block_counter"
#define STICKY_NODROP "sticky-nodrop" //sticky nodrop sounds like a bad soundcloud rapper's name
#define TRAIT_SPACEWALK "spacewalk"
#define RADX_TRAIT "trait_from_rad-x"

//important_recursive_contents traits
/*
 * Used for movables that need to be updated, via COMSIG_ENTER_AREA and COMSIG_EXIT_AREA, when transitioning areas.
 * Use [/atom/movable/proc/become_area_sensitive(trait_source)] to properly enable it. How you remove it isn't as important.
 */
#define TRAIT_AREA_SENSITIVE "area-sensitive"
///every hearing sensitive atom has this trait
#define TRAIT_HEARING_SENSITIVE "hearing_sensitive"

/// just a little helper to see if we're not a druggie
#define NODRUGS(m) (HAS_TRAIT(m, TRAIT_NODRUGS))
