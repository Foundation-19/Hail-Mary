/* To use the ref tracking debugging tool in game
1. Enable/uncomment the following before using debug tools on your local machine:

**TESTING

**REFERENCE_TRACKING

**REFERENCE_TRACKING_DEBUG

**GC_FAILURE_HARD_LOOKUP

2. Set return statement of the object you wish to ref track to QDEL_HINT_FINDREFERENCE or QDEL_HINT_IFFAIL_FINDREFERENCE (read qdel.dm for the difference between the two)


3. Start game up on your local machine and delete the object in question. Look at the daemon log for results.

*/

//#define TESTING

#ifdef DEBUG
#define USE_CUSTOM_ERROR_HANDLER
#endif

#ifdef TESTING
//#define REFERENCE_TRACKING
#ifdef REFERENCE_TRACKING
//#define REFERENCE_TRACKING_DEBUG
//#define GC_FAILURE_HARD_LOOKUP
#ifdef GC_FAILURE_HARD_LOOKUP
#define FIND_REF_NO_CHECK_TICK
#endif
#endif
#endif

#ifndef PRELOAD_RSC
#define PRELOAD_RSC 2
#endif

#ifdef LOWMEMORYMODE
#define FORCE_MAP "_maps/runtimestation.json"
#endif

// ---------------------------------------------------------------------
// Compiler version gate (ORIGINAL BASELINE)
// ---------------------------------------------------------------------

#define MIN_COMPILER_VERSION 513
#define MIN_COMPILER_BUILD 1514

#if DM_VERSION < MIN_COMPILER_VERSION || DM_BUILD < MIN_COMPILER_BUILD
#error Your version of BYOND is too out-of-date to compile this project.
#error You need version 513.1514 or higher.
#endif

// ---------------------------------------------------------------------
// COMPATIBILITY SHIMS (MERGED — NOT A SECOND COMPILER)
// ---------------------------------------------------------------------

// 515+ external call split
#if DM_VERSION < 515
#define LIBCALL call
#else
#define LIBCALL call_ext
#endif

// PROC / VERB reference compatibility
#if DM_VERSION < 515

#define PROC_REF(X) (.proc/##X)
#define VERB_REF(X) (.verb/##X)

#define TYPE_PROC_REF(TYPE, X) (##TYPE.proc/##X)
#define TYPE_VERB_REF(TYPE, X) (##TYPE.verb/##X)

#define GLOBAL_PROC_REF(X) (/proc/##X)

#else

#define PROC_REF(X) (nameof(.proc/##X))
#define VERB_REF(X) (nameof(.verb/##X))

#define TYPE_PROC_REF(TYPE, X) (nameof(##TYPE.proc/##X))
#define TYPE_VERB_REF(TYPE, X) (nameof(##TYPE.verb/##X))

#define GLOBAL_PROC_REF(X) (/proc/##X)

#endif

// 515 Linux fcopy crash guard (safe no-op elsewhere)
#if DM_VERSION == 515
/world/proc/__fcopy(Src, Dst)
	if (istext(Src) && !fexists(Src))
		return 0
	return fcopy(Src, Dst)

#define fcopy(Src, Dst) world.__fcopy(Src, Dst)
#endif

// ---------------------------------------------------------------------
// Build mode flags (ORIGINAL)
// ---------------------------------------------------------------------

#ifdef TESTING
#warn compiling in TESTING mode. testing() debug messages will be visible.
#endif

#ifdef CIBUILDING
#define UNIT_TESTS
#endif

#ifdef CITESTING
#define TESTING
#endif

#ifdef TGS
#define CBT
#endif

#ifdef CBT
#define ALL_MAPS
#endif

#define MAX_ATOM_OVERLAYS 100

#if !defined(CBT) && !defined(SPACEMAN_DMM)
#warn Building with Dream Maker directly is unsupported.
#warn Use BUILD.bat or VSCode build tasks.
#endif
