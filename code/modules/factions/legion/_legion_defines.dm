// Legion Faction Defines

// Arena Defines
#define ARENA_DEATHMATCH 1
#define ARENA_SUBMISSION 2
#define ARENA_TEAM_BATTLE 3
#define ARENA_BEAST_FIGHT 4

#define ARENA_MAX_TEAM_SIZE 3
#define ARENA_MIN_BET 10
#define ARENA_MAX_BET 500

// Slave Defines
#define SLAVE_TYPE_LABOR "labor"
#define SLAVE_TYPE_SERVANT "servant"
#define SLAVE_TYPE_GLADIATOR "gladiator"
#define SLAVE_TYPE_SPECIALIST "specialist"

#define SLAVE_MAX_ENSLAVEMENT_TIME 45 MINUTES
#define SLAVE_WORK_FOR_FREEDOM_TIME 20 MINUTES
#define SLAVE_GLADIATOR_WINS_REQUIRED 3

#define SLAVE_COLLAR_RANGE 50

// Obedience Thresholds
#define OBEDIENCE_REBELLIOUS 20
#define OBEDIENCE_LOW 50
#define OBEDIENCE_HIGH 80

// Karma Values
#define KARMA_ENSLAVE -20
#define KARMA_OWN_SLAVE -5
#define KARMA_SELL_SLAVE -30
#define KARMA_FREE_SLAVE 50
#define KARMA_HELP_ESCAPE 30
#define KARMA_REMOVE_COLLAR 20

// Legion Coin Values
#define DENARIUS_VALUE 4
#define AUREUS_VALUE 100
#define EXCHANGE_FEE 0.10
#define EXCHANGE_FEE_NONLEGION 0.20

// Labor Defines
#define LABOR_OUTPUT_BASE 5
#define LABOR_TICK 5 MINUTES

// Global slave registry
GLOBAL_LIST_EMPTY(legion_slave_registry)
GLOBAL_LIST_EMPTY(legion_arena_matches)
GLOBAL_DATUM_INIT(legion_economy, /datum/legion_economy, new())
