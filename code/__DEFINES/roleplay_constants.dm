// Centralizes all magic numbers for consistency and easy tuning

// ============ KARMA SYSTEM ============
#define KARMA_MAX 1000
#define KARMA_MIN -1000

// Karma thresholds
#define KARMA_LEGEND 750
#define KARMA_HERO 500
#define KARMA_GOOD 250
#define KARMA_NEUTRAL 0
#define KARMA_SHADY -250
#define KARMA_VILLAIN -500
#define KARMA_INFAMOUS -750

#define KARMA_FEEDBACK_MIN 5			// Minimum karma change to show feedback
#define KARMA_HISTORY_DISPLAY_LIMIT 50	// Max entries to show in karma history

// ============ REPUTATION SYSTEM ============
#define REP_IDOLIZED 100
#define REP_ADMIRED 75
#define REP_LIKED 50
#define REP_ACCEPTED 25
#define REP_NEUTRAL 10
#define REP_SHUNNED 0
#define REP_DISLIKED -25
#define REP_HATED -50
#define REP_VILIFIED -100

#define REP_MIN -100					// Minimum possible reputation
#define REP_MAX 250						// Maximum possible reputation (higher for special rewards)
#define REP_CHANGE_MAX 25				// Maximum reputation change per action

// ============ BOUNTY SYSTEM ============
// Bounty thresholds (already defined in bounty_system.dm, listed here for reference)
// #define BOUNTY_THRESHOLD_VILLAIN -500
// #define BOUNTY_THRESHOLD_INFAMOUS -750
// #define BOUNTY_AMOUNT_VILLAIN 500

#define BOUNTY_CAPS_STACK_MAX 50		// Maximum caps per stack when collecting bounty
#define BOUNTY_HUNTER_SPAWN_MIN 1		// Minimum bounty hunters to spawn
#define BOUNTY_HUNTER_SPAWN_MAX 3		// Maximum bounty hunters to spawn
#define BOUNTY_HUNTER_DURATION 600		// How long bounty hunters pursue (10 minutes)

// ============ PERK SYSTEM ============
#define MAX_PERK_POINTS 30				// Maximum perk points a player can spend

// ============ LEVEL SYSTEM ============
#define XP_LEVEL_SCALING 1000			// XP required per level

// ============ TRADE SYSTEM ============
#define TRADE_STATE_REQUEST 1			// Trade has been requested
#define TRADE_STATE_OFFERING 2			// Trade is in offering phase
#define TRADE_STATE_CONFIRMING 3		// Trade is in confirmation phase
#define TRADE_MAX_DISTANCE 3			// Maximum tiles between traders
#define TRADE_REQUEST_TIMEOUT 300		// Trade request expires after 30 seconds
#define TRADE_Z_LEVEL_CHECK TRUE		// Whether traders must be on same Z-level

// ============ COMPANION SYSTEM ============
#define COMPANION_HIRE_BASE_COST 500	// Base cost for hiring companions
#define COMPANION_FOLLOW_DISTANCE 2		// Distance companion tries to maintain
#define COMPANION_MAX_ACTIVE 2			// Maximum active companions per player

// ============ DIALOGUE SYSTEM ============
#define DIALOGUE_DEFAULT_RANGE 3		// Default range for auto-dialogue trigger
#define DIALOGUE_COOLDOWN_DEFAULT 300	// Default cooldown between dialogue triggers
#define DIALOGUE_UI_WIDTH 600			// Dialogue UI window width
#define DIALOGUE_UI_HEIGHT 450			// Dialogue UI window height

// ============ QUEST SYSTEM ============
#define QUEST_MAX_ACTIVE 5				// Maximum active quests per player
#define QUEST_DEFAULT_TIME_LIMIT 12000	// Default time limit (20 minutes in deciseconds)
#define QUEST_TRACKING_RANGE 50			// Range for objective tracking

// ============ NPC MEMORY SYSTEM ============
#define NPC_MEMORY_MAX_PER_PLAYER 100	// Maximum memories stored per player per NPC
#define NPC_MEMORY_DECAY_DAYS 30		// Days before old memories are cleaned up

// ============ NPC BARK SYSTEM ============
#define BARK_DEFAULT_CHANCE 5			// Default chance per tick to bark (1-100)
#define BARK_DEFAULT_COOLDOWN 600		// Default cooldown between barks (60 seconds)
#define BARK_DEFAULT_RANGE 7			// Default range for barks to be heard

// ============ LEVEL/XP SYSTEM ============
#define XP_LEVEL_CAP 50					// Maximum player level
#define XP_SPECIAL_BONUS_PER_LEVEL 1	// SPECIAL points per level
#define XP_KILL_RAIDER 10
#define XP_KILL_FERAL 15
#define XP_KILL_VETERAN 50
#define XP_KILL_BOSS 200
#define XP_KILL_PLAYER -50
#define XP_COMPLETE_QUEST_GOOD 200
#define XP_COMPLETE_QUEST_EVIL -100
#define XP_COMPLETE_QUEST_NEUTRAL 100
#define XP_EXPLORE_NEW 50
#define XP_CRAFT_ITEM 25
#define XP_TRADE 10
#define XP_HELP_PLAYER 30
#define XP_HELP_NPC 15
#define XP_DISCOVER_LOCATION 25
#define XP_SURVIVE_DAY 100

// ============ CAPS SYSTEM ============
#define CAPS_STARTING_DEFAULT 50		// Default starting caps for new characters
#define CAPS_MAX_IN_WALLET 10000		// Maximum caps that can be carried

// ============ CAPS PAYCHECK SYSTEM ============
#define PAYCHECK_INTERVAL 10 MINUTES
#define PAYCHECK_CAPS_NONE 0
#define PAYCHECK_CAPS_MINIMAL 15
#define PAYCHECK_CAPS_LOW 25
#define PAYCHECK_CAPS_MEDIUM 40
#define PAYCHECK_CAPS_HIGH 60
#define PAYCHECK_CAPS_COMMAND 80
#define PAYCHECK_CAPS_LEADERSHIP 100

// ============ PERK SYSTEM ============
#define PERK_POINTS_PER_LEVEL 1			// Perk points gained per level
#define PERK_MAX_TOTAL 30				// Maximum total perk points (soft cap)

// ============ DATABASE TABLES ============
#define DB_TABLE_KARMA "player_karma"
#define DB_TABLE_REPUTATION "player_reputation"
#define DB_TABLE_LEVELS "player_levels"
#define DB_TABLE_QUESTS "player_quests"
#define DB_TABLE_MEMORY "npc_memory"
#define DB_TABLE_KARMA_HISTORY "karma_history"
#define DB_TABLE_PERKS "player_perks"

// ============ UI CONSTANTS ============
#define UI_TRADE_WIDTH 700
#define UI_TRADE_HEIGHT 600
#define UI_BOUNTY_WIDTH 600
#define UI_BOUNTY_HEIGHT 500
#define UI_QUEST_WIDTH 500
#define UI_QUEST_HEIGHT 400
