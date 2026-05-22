// Eastwood Town Defines
// Neutral settlement operating as NCR Protectorate

// Council Defines
#define COUNCIL_SIZE 5
#define COUNCIL_TERM_DAYS 7
#define COUNCIL_CANDIDACY_FEE 200
#define CITIZENSHIP_FEE 100
#define RESIDENCY_REQUIREMENT_DAYS 3

// Sheriff Defines
#define SHERIFF_TERM_DAYS 7
#define MAX_DEPUTIES 5
#define MAX_JAIL_CELLS 5
#define MAX_JAIL_SENTENCE 30 MINUTES

// Militia Defines
#define MILITIA_MAX_MEMBERS 20
#define PATROL_DURATION 10 MINUTES
#define MILITIA_RANK_RECRUIT 1
#define MILITIA_RANK_MEMBER 2
#define MILITIA_RANK_SERGEANT 3
#define MILITIA_RANK_COMMANDER 4
#define MILITIA_ALERT_PEACEFUL 0
#define MILITIA_ALERT_ELEVATED 1
#define MILITIA_ALERT_DANGER 2
#define MILITIA_ALERT_EMERGENCY 3

// Trade Defines
#define VENDOR_PERMIT_FEE 75
#define WEAPONS_PERMIT_FEE 100
#define MEDICAL_LICENSE_FEE 100
#define MARKET_TAX_RATE 0.05
#define STALL_RENT_DAILY 25

// Town Services
#define INN_ROOM_DAILY 30
#define CLINIC_BASIC_HEAL 50
#define CLINIC_SURGERY 200
#define REPAIR_BASIC 25
#define ROOM_STANDARD 1
#define ROOM_PREMIUM 2

// NCR Protectorate
#define NCR_WEEKLY_TRIBUTE 500
#define NCR_GARRISON_MAX 10
#define NCR_PROTECTION_LEVEL 2

// Crime Categories
#define CRIME_MINOR 1
#define CRIME_MODERATE 2
#define CRIME_SERIOUS 3

// Fine Amounts
#define FINE_TRESPASSING 50
#define FINE_DISTURBANCE 75
#define FINE_THEFT 150
#define FINE_ASSAULT 200

// Global Registries
GLOBAL_LIST_EMPTY(eastwood_citizens)
GLOBAL_LIST_EMPTY(eastwood_council_members)
GLOBAL_DATUM_INIT(eastwood_council, /datum/eastwood_council, new())
GLOBAL_DATUM_INIT(eastwood_sheriff, /datum/eastwood_sheriff, new())
GLOBAL_DATUM_INIT(eastwood_militia, /datum/eastwood_militia, new())
GLOBAL_DATUM_INIT(eastwood_market, /datum/eastwood_market, new())
