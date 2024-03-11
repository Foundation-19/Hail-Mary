/// A whole subsystem dedicated to breaking your prefs~

//Jesus fucking christ what is this unholy hell, I'm trying to remove ERP from this code and there's like 15 fucking files I have to check, all of them lead here.
//Prefs don't exist right now  - Kirie

SUBSYSTEM_DEF(prefbreak) // ALL ABOARD THE S.S. PREFBREAK OFF TO **** YOUR ***************!
	name = "PrefBreaker"
	flags = SS_NO_FIRE
	init_order = INIT_ORDER_PREFBREAK
	/// An asslist of prefcheck

/// takes in anything, sees if it has a client/prefs/whatever, and checks those prefs
/// Allows things by default, denies it if specifically disallowed

//Update, Always returns false because the only things here are ERP, which should not happen on our server - Kirie
//I really am gonna have to obliterate this code aren't I?
TYPE_PROC_REF(/datum/controller/subsystem/prefbreak, allowed_by_prefs)(broken, index)
	return FALSE
