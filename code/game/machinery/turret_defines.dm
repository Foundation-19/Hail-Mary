#define TURRET_STUN 0
#define TURRET_LETHAL 1

#define POPUP_ANIM_TIME 5
#define POPDOWN_ANIM_TIME 5 //Be sure to change the icon animation at the same time or it'll look bad

#define TURRET_LASER_COOLDOWN_TIME 0.5 SECONDS
#define TURRET_SHOOT_DELAY_BASE 1 SECONDS
#define TURRET_BWEEP_COOLDOWN 1 SECONDS
#define TURRET_SCAN_RATE 3 SECONDS
#define TURRET_PREFIRE_DELAY 1 SECONDS

/// Turret is napping and passively scanning the environment at its own pace
#define TURRET_SLEEP_MODE "sleep_mode"
/// Turret is in Alert Mode and actively shooting a visible target
#define TURRET_ALERT_MODE "alert_mode"
/// Turret is in Caution Mode and actively shooting the last place a target was
#define TURRET_CAUTION_MODE "caution_mode"
/// Turret is in Evasion Mode and actively passively (loudly) scanning the environment for targets
#define TURRET_EVASION_MODE "evasion_mode"

/// Turret procesing is OFF
#define TURRET_PROCESS_OFF 0
/// Turret processing is MACHINE
#define TURRET_PROCESS_MACHINE 1
/// Turret processing is FAST
#define TURRET_PROCESS_FAST 2

/// The turret becomes angy at whoever shoots it, regardless of other settings
#define TF_SHOOT_REACTION (1<<0)
/// The turret only shoots people with unauthorized weapons (basically everyone) (currently unused)
#define TF_SHOOT_WEAPONS (1<<1)
/// The turret shoots everything that can be broken. Seriously. (currently unused)
#define TF_SHOOT_EVERYTHING (1<<2)
/// The turret shoots at players
#define TF_SHOOT_PLAYERS (1<<3)
/// The turret shoots at wildlife (ghouls, geckos, etc)
#define TF_SHOOT_WILDLIFE (1<<4)
/// The turret shoots raiders
#define TF_SHOOT_RAIDERS (1<<6)
/// The turret shoots robots (gutsies, handies)
#define TF_SHOOT_ROBOTS (1<<7)
/// Turret ignores faction checks and treats everything is allowed to shoot as hostile
#define TF_IGNORE_FACTION (1<<8)
/// Turret shines a laser at its target
#define TF_USE_LASER_POINTER (1<<9)
/// Turret stays quiet
#define TF_BE_REALLY_LOUD (1<<10)
/// Default utility flags
#define TURRET_DEFAULT_UTILITY TF_USE_LASER_POINTER | TF_BE_REALLY_LOUD | TF_SHOOT_REACTION
/// Default turret targets
#define TURRET_DEFAULT_TARGET_FLAGS TF_SHOOT_PLAYERS | TF_SHOOT_WILDLIFE | TF_SHOOT_RAIDERS | TF_SHOOT_ROBOTS
/// Default turret targets - raider owned turret
#define TURRET_RAIDER_OWNED_FLAGS TF_SHOOT_PLAYERS | TF_SHOOT_WILDLIFE | TF_SHOOT_ROBOTS
/// Default turret targets - robot owned turret
#define TURRET_ROBOT_OWNED_FLAGS TF_SHOOT_PLAYERS | TF_SHOOT_WILDLIFE | TF_SHOOT_RAIDERS
/// Default turret targets - player-domestic turret
#define TURRET_PLAYER_OWNED_FLAGS TF_SHOOT_WILDLIFE | TF_SHOOT_RAIDERS | TF_SHOOT_ROBOTS
