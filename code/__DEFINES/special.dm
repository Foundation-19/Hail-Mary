// 7 stats at SPECIAL_DEFAULT_ATTR_VALUE (5) sum to 35 - the classic Fallout chargen gives you 5 extra points
// on top of that baseline to freely redistribute, hence 40 rather than a round number.
#define SPECIAL_MAX_POINT_SUM_CAP 40
#define SPECIAL_MIN_ATTR_VALUE 1
#define SPECIAL_DEFAULT_ATTR_VALUE 5
#define SPECIAL_MAX_ATTR_VALUE 10

#define SPECIAL_MIN_INT_CRAFTING_REQUIREMENT 3

/// How long a target is safe from being challenged again (by anyone) after a verify_identity() attempt, win or lose.
/// Long enough that a successful infiltrator has a real window to operate before anyone else can take a crack at them.
#define IDENTITY_CHECK_COOLDOWN (45 MINUTES)

/// How long a VERIFIER has to wait between their own verify_identity() attempts, regardless of target.
/// Stops one person from instantly hunch-checking everyone in a room back-to-back.
#define IDENTITY_CHECK_VERIFIER_COOLDOWN (2 MINUTES)

