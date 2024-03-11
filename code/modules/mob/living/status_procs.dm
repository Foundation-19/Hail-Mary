// YEEHAW GAMERS STAMINA REWORK PROC GETS TO BE FIRST
// amount = strength
// updating = update mobility etc etc
// ignore_castun = same logic as Paralyze() in general
// override_duration = If this is set, does Paralyze() for this duration.
// override_stam = If this is set, does this amount of stamina damage.
TYPE_PROC_REF(/mob/living, DefaultCombatKnockdown)(amount, updating = TRUE, ignore_canknockdown = FALSE, override_hardstun, override_stamdmg)
	if(!iscarbon(src))
		return Paralyze(amount, updating, ignore_canknockdown)
	if(!ignore_canknockdown && !(status_flags & CANKNOCKDOWN))
		return FALSE
	if(istype(buckled, /obj/vehicle/ridden))
		buckled.unbuckle_mob(src)
	var/drop_items = amount > 80		//80 is cutoff for old item dropping behavior
	var/stamdmg = isnull(override_stamdmg)? (amount * 0.25) : override_stamdmg
	KnockToFloor(drop_items, TRUE, updating)
	adjustStaminaLoss(stamdmg)
	if(!isnull(override_hardstun))
		Paralyze(override_hardstun)

////////////////////////////// STUN ////////////////////////////////////

TYPE_PROC_REF(/mob/living, IsStun)() //If we're stunned
	return has_status_effect(STATUS_EFFECT_STUN)

TYPE_PROC_REF(/mob/living, AmountStun)() //How many deciseconds remain in our stun
	var/datum/status_effect/incapacitating/stun/S = IsStun()
	if(S)
		return S.duration - world.time
	return 0

TYPE_PROC_REF(/mob/living, Stun)(amount, updating = TRUE, ignore_canstun = FALSE) //Can't go below remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_STUN, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANSTUN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	if(absorb_stun(amount, ignore_canstun))
		return
	var/datum/status_effect/incapacitating/stun/S = IsStun()
	if(S)
		S.duration = max(world.time + amount, S.duration)
	else if(amount > 0)
		S = apply_status_effect(STATUS_EFFECT_STUN, amount, updating)
	return S

TYPE_PROC_REF(/mob/living, SetStun)(amount, updating = TRUE, ignore_canstun = FALSE) //Sets remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_STUN, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANSTUN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	var/datum/status_effect/incapacitating/stun/S = IsStun()
	if(amount <= 0)
		if(S)
			qdel(S)
	else
		if(absorb_stun(amount, ignore_canstun))
			return
		if(S)
			S.duration = world.time + amount
		else
			S = apply_status_effect(STATUS_EFFECT_STUN, amount, updating)
	return S

TYPE_PROC_REF(/mob/living, AdjustStun)(amount, updating = TRUE, ignore_canstun = FALSE) //Adds to remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_STUN, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANSTUN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	if(absorb_stun(amount, ignore_canstun))
		return
	var/datum/status_effect/incapacitating/stun/S = IsStun()
	if(S)
		S.duration += amount
	else if(amount > 0)
		S = apply_status_effect(STATUS_EFFECT_STUN, amount, updating)
	return S

///////////////////////////////// KNOCKDOWN /////////////////////////////////////

TYPE_PROC_REF(/mob/living, IsKnockdown)() //If we're knocked down
	return has_status_effect(STATUS_EFFECT_KNOCKDOWN)

TYPE_PROC_REF(/mob/living, AmountKnockdown)() //How many deciseconds remain in our knockdown
	var/datum/status_effect/incapacitating/knockdown/K = IsKnockdown()
	if(K)
		return K.duration - world.time
	return 0

TYPE_PROC_REF(/mob/living, Knockdown)(amount, updating = TRUE, ignore_canstun = FALSE) //Can't go below remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_KNOCKDOWN, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANKNOCKDOWN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	if(absorb_stun(amount, ignore_canstun))
		return
	var/datum/status_effect/incapacitating/knockdown/K = IsKnockdown()
	if(K)
		K.duration = max(world.time + amount, K.duration)
	else if(amount > 0)
		K = apply_status_effect(STATUS_EFFECT_KNOCKDOWN, amount, updating)
	return K

TYPE_PROC_REF(/mob/living, SetKnockdown)(amount, updating = TRUE, ignore_canstun = FALSE) //Sets remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_KNOCKDOWN, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANKNOCKDOWN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	var/datum/status_effect/incapacitating/knockdown/K = IsKnockdown()
	if(amount <= 0)
		if(K)
			qdel(K)
	else
		if(absorb_stun(amount, ignore_canstun))
			return
		if(K)
			K.duration = world.time + amount
		else
			K = apply_status_effect(STATUS_EFFECT_KNOCKDOWN, amount, updating)
	return K

TYPE_PROC_REF(/mob/living, AdjustKnockdown)(amount, updating = TRUE, ignore_canstun = FALSE) //Adds to remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_KNOCKDOWN, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANKNOCKDOWN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	if(absorb_stun(amount, ignore_canstun))
		return
	var/datum/status_effect/incapacitating/knockdown/K = IsKnockdown()
	if(K)
		K.duration += amount
	else if(amount > 0)
		K = apply_status_effect(STATUS_EFFECT_KNOCKDOWN, amount, updating)
	return K

///////////////////////////////// IMMOBILIZED ////////////////////////////////////
TYPE_PROC_REF(/mob/living, IsImmobilized)() //If we're immobilized
	return has_status_effect(STATUS_EFFECT_IMMOBILIZED)

TYPE_PROC_REF(/mob/living, AmountImmobilized)() //How many deciseconds remain in our Immobilized status effect
	var/datum/status_effect/incapacitating/immobilized/I = IsImmobilized()
	if(I)
		return I.duration - world.time
	return 0

TYPE_PROC_REF(/mob/living, Immobilize)(amount, updating = TRUE, ignore_canstun = FALSE) //Can't go below remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_IMMOBILIZE, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANKNOCKDOWN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	if(absorb_stun(amount, ignore_canstun))
		return
	var/datum/status_effect/incapacitating/immobilized/I = IsImmobilized()
	if(I)
		I.duration = max(world.time + amount, I.duration)
	else if(amount > 0)
		I = apply_status_effect(STATUS_EFFECT_IMMOBILIZED, amount, updating)
	return I

TYPE_PROC_REF(/mob/living, SetImmobilized)(amount, updating = TRUE, ignore_canstun = FALSE) //Sets remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_IMMOBILIZE, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANKNOCKDOWN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	var/datum/status_effect/incapacitating/immobilized/I = IsImmobilized()
	if(amount <= 0)
		if(I)
			qdel(I)
	else
		if(absorb_stun(amount, ignore_canstun))
			return
		if(I)
			I.duration = world.time + amount
		else
			I = apply_status_effect(STATUS_EFFECT_IMMOBILIZED, amount, updating)
	return I

TYPE_PROC_REF(/mob/living, AdjustImmobilized)(amount, updating = TRUE, ignore_canstun = FALSE) //Adds to remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_IMMOBILIZE, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANKNOCKDOWN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	if(absorb_stun(amount, ignore_canstun))
		return
	var/datum/status_effect/incapacitating/immobilized/I = IsImmobilized()
	if(I)
		I.duration += amount
	else if(amount > 0)
		I = apply_status_effect(STATUS_EFFECT_IMMOBILIZED, amount, updating)
	return I

///////////////////////////////// PARALYZED //////////////////////////////////
TYPE_PROC_REF(/mob/living, IsParalyzed)() //If we're immobilized
	return has_status_effect(STATUS_EFFECT_PARALYZED)

TYPE_PROC_REF(/mob/living, AmountParalyzed)() //How many deciseconds remain in our Paralyzed status effect
	var/datum/status_effect/incapacitating/paralyzed/P = IsParalyzed(FALSE)
	if(P)
		return P.duration - world.time
	return 0

TYPE_PROC_REF(/mob/living, Paralyze)(amount, updating = TRUE, ignore_canstun = FALSE) //Can't go below remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_PARALYZE, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANKNOCKDOWN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	if(absorb_stun(amount, ignore_canstun))
		return
	var/datum/status_effect/incapacitating/paralyzed/P = IsParalyzed(FALSE)
	if(P)
		P.duration = max(world.time + amount, P.duration)
	else if(amount > 0)
		P = apply_status_effect(STATUS_EFFECT_PARALYZED, amount, updating)
	return P

TYPE_PROC_REF(/mob/living, SetParalyzed)(amount, updating = TRUE, ignore_canstun = FALSE) //Sets remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_PARALYZE, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANKNOCKDOWN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	var/datum/status_effect/incapacitating/paralyzed/P = IsParalyzed(FALSE)
	if(amount <= 0)
		if(P)
			qdel(P)
	else
		if(absorb_stun(amount, ignore_canstun))
			return
		if(P)
			P.duration = world.time + amount
		else
			P = apply_status_effect(STATUS_EFFECT_PARALYZED, amount, updating)
	return P

TYPE_PROC_REF(/mob/living, AdjustParalyzed)(amount, updating = TRUE, ignore_canstun = FALSE) //Adds to remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_PARALYZE, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANKNOCKDOWN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	if(absorb_stun(amount, ignore_canstun))
		return
	var/datum/status_effect/incapacitating/paralyzed/P = IsParalyzed(FALSE)
	if(P)
		P.duration += amount
	else if(amount > 0)
		P = apply_status_effect(STATUS_EFFECT_PARALYZED, amount, updating)
	return P

///////////////////////////////// DAZED ////////////////////////////////////
TYPE_PROC_REF(/mob/living, IsDazed)() //If we're Dazed
	return has_status_effect(STATUS_EFFECT_DAZED)

TYPE_PROC_REF(/mob/living, AmountDazed)() //How many deciseconds remain in our Dazed status effect
	var/datum/status_effect/incapacitating/dazed/I = IsDazed()
	if(I)
		return I.duration - world.time
	return 0

TYPE_PROC_REF(/mob/living, Daze)(amount, updating = TRUE, ignore_canstun = FALSE) //Can't go below remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_DAZE, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANKNOCKDOWN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	if(absorb_stun(amount, ignore_canstun))
		return
	var/datum/status_effect/incapacitating/dazed/I = IsDazed()
	if(I)
		I.duration = max(world.time + amount, I.duration)
	else if(amount > 0)
		I = apply_status_effect(STATUS_EFFECT_DAZED, amount, updating)
	return I

TYPE_PROC_REF(/mob/living, SetDazed)(amount, updating = TRUE, ignore_canstun = FALSE) //Sets remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_DAZE, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANKNOCKDOWN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	var/datum/status_effect/incapacitating/dazed/I = IsDazed()
	if(amount <= 0)
		if(I)
			qdel(I)
	else
		if(absorb_stun(amount, ignore_canstun))
			return
		if(I)
			I.duration = world.time + amount
		else
			I = apply_status_effect(STATUS_EFFECT_DAZED, amount, updating)
	return I

TYPE_PROC_REF(/mob/living, AdjustDazed)(amount, updating = TRUE, ignore_canstun = FALSE) //Adds to remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_DAZE, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANKNOCKDOWN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	if(absorb_stun(amount, ignore_canstun))
		return
	var/datum/status_effect/incapacitating/dazed/I = IsDazed()
	if(I)
		I.duration += amount
	else if(amount > 0)
		I = apply_status_effect(STATUS_EFFECT_DAZED, amount, updating)
	return I

///////////////////////////////// STAGGERED ////////////////////////////////////
TYPE_PROC_REF(/mob/living, IsStaggered)() //If we're Staggered
	return has_status_effect(STATUS_EFFECT_STAGGERED)

TYPE_PROC_REF(/mob/living, AmountStaggered)() //How many deciseconds remain in our Staggered status effect
	var/datum/status_effect/staggered/I = IsStaggered()
	if(I)
		return I.duration - world.time
	return 0

TYPE_PROC_REF(/mob/living, Stagger)(amount, updating = TRUE, ignore_canstun = FALSE) //Can't go below remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_STAGGER, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANKNOCKDOWN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	if(absorb_stun(amount, ignore_canstun))
		return
	var/datum/status_effect/staggered/I = IsStaggered()
	if(I)
		I.duration = max(world.time + amount, I.duration)
	else if(amount > 0)
		I = apply_status_effect(STATUS_EFFECT_STAGGERED, amount, updating)
	return I

TYPE_PROC_REF(/mob/living, SetStaggered)(amount, updating = TRUE, ignore_canstun = FALSE) //Sets remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_STAGGER, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANKNOCKDOWN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	var/datum/status_effect/staggered/I = IsStaggered()
	if(amount <= 0)
		if(I)
			qdel(I)
	else
		if(absorb_stun(amount, ignore_canstun))
			return
		if(I)
			I.duration = world.time + amount
		else
			I = apply_status_effect(STATUS_EFFECT_STAGGERED, amount, updating)
	return I

TYPE_PROC_REF(/mob/living, AdjustStaggered)(amount, updating = TRUE, ignore_canstun = FALSE) //Adds to remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_STAGGER, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(!ignore_canstun && (!(status_flags & CANKNOCKDOWN) || HAS_TRAIT(src, TRAIT_STUNIMMUNE)))
		return
	if(absorb_stun(amount, ignore_canstun))
		return
	var/datum/status_effect/staggered/I = IsStaggered()
	if(I)
		I.duration += amount
	else if(amount > 0)
		I = apply_status_effect(STATUS_EFFECT_STAGGERED, amount, updating)
	return I

//Blanket
TYPE_PROC_REF(/mob/living, AllImmobility)(amount, updating, ignore_canstun = FALSE)
	Paralyze(amount, FALSE, ignore_canstun)
	Knockdown(amount, FALSE, ignore_canstun)
	Stun(amount, FALSE, ignore_canstun)
	Immobilize(amount, FALSE, ignore_canstun)
	Daze(amount, FALSE, ignore_canstun)
	Stagger(amount, FALSE, ignore_canstun)
	if(updating)
		update_mobility()

TYPE_PROC_REF(/mob/living, SetAllImmobility)(amount, updating, ignore_canstun = FALSE)
	SetParalyzed(amount, FALSE, ignore_canstun)
	SetKnockdown(amount, FALSE, ignore_canstun)
	SetStun(amount, FALSE, ignore_canstun)
	SetImmobilized(amount, FALSE, ignore_canstun)
	SetDazed(amount, FALSE, ignore_canstun)
	SetStaggered(amount, FALSE, ignore_canstun)
	if(updating)
		update_mobility()

TYPE_PROC_REF(/mob/living, AdjustAllImmobility)(amount, updating, ignore_canstun = FALSE)
	AdjustParalyzed(amount, FALSE, ignore_canstun)
	AdjustKnockdown(amount, FALSE, ignore_canstun)
	AdjustStun(amount, FALSE, ignore_canstun)
	AdjustImmobilized(amount, FALSE, ignore_canstun)
	AdjustDazed(amount, FALSE, ignore_canstun)
	AdjustStaggered(amount, FALSE, ignore_canstun)
	if(updating)
		update_mobility()

/// Makes sure all 5 of the non-knockout immobilizing status effects are lower or equal to amount.
TYPE_PROC_REF(/mob/living, HealAllImmobilityUpTo)(amount, updating, ignore_canstun = FALSE)
	if(AmountStun() > amount)
		SetStun(amount, FALSE, ignore_canstun)
	if(AmountKnockdown() > amount)
		SetKnockdown(amount, FALSE, ignore_canstun)
	if(AmountParalyzed() > amount)
		SetParalyzed(amount, FALSE, ignore_canstun)
	if(AmountImmobilized() > amount)
		SetImmobilized(amount, FALSE, ignore_canstun)
	if(AmountDazed() > amount)
		SetImmobilized(amount, FALSE, ignore_canstun)
	if(AmountStaggered() > amount)
		SetStaggered(amount, FALSE, ignore_canstun)
	if(updating)
		update_mobility()

TYPE_PROC_REF(/mob/living, HighestImmobilityAmount)()
	return max(AmountStun(), AmountKnockdown(), AmountParalyzed(), AmountImmobilized(), AmountDazed(), AmountStaggered())

//////////////////UNCONSCIOUS
TYPE_PROC_REF(/mob/living, IsUnconscious)() //If we're unconscious
	return has_status_effect(STATUS_EFFECT_UNCONSCIOUS)

TYPE_PROC_REF(/mob/living, AmountUnconscious)() //How many deciseconds remain in our unconsciousness
	var/datum/status_effect/incapacitating/unconscious/U = IsUnconscious()
	if(U)
		return U.duration - world.time
	return 0

TYPE_PROC_REF(/mob/living, Unconscious)(amount, updating = TRUE, ignore_canstun = FALSE) //Can't go below remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_UNCONSCIOUS, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(((status_flags & CANUNCONSCIOUS) && !HAS_TRAIT(src, TRAIT_STUNIMMUNE))  || ignore_canstun)
		var/datum/status_effect/incapacitating/unconscious/U = IsUnconscious()
		if(U)
			U.duration = max(world.time + amount, U.duration)
		else if(amount > 0)
			U = apply_status_effect(STATUS_EFFECT_UNCONSCIOUS, amount, updating)
		return U

TYPE_PROC_REF(/mob/living, SetUnconscious)(amount, updating = TRUE, ignore_canstun = FALSE) //Sets remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_UNCONSCIOUS, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(((status_flags & CANUNCONSCIOUS) && !HAS_TRAIT(src, TRAIT_STUNIMMUNE)) || ignore_canstun)
		var/datum/status_effect/incapacitating/unconscious/U = IsUnconscious()
		if(amount <= 0)
			if(U)
				qdel(U)
		else if(U)
			U.duration = world.time + amount
		else
			U = apply_status_effect(STATUS_EFFECT_UNCONSCIOUS, amount, updating)
		return U

TYPE_PROC_REF(/mob/living, AdjustUnconscious)(amount, updating = TRUE, ignore_canstun = FALSE) //Adds to remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_UNCONSCIOUS, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if(((status_flags & CANUNCONSCIOUS) && !HAS_TRAIT(src, TRAIT_STUNIMMUNE)) || ignore_canstun)
		var/datum/status_effect/incapacitating/unconscious/U = IsUnconscious()
		if(U)
			U.duration += amount
		else if(amount > 0)
			U = apply_status_effect(STATUS_EFFECT_UNCONSCIOUS, amount, updating)
		return U

/////////////////////////////////// SLEEPING ////////////////////////////////////

TYPE_PROC_REF(/mob/living, IsSleeping)() //If we're asleep
	return has_status_effect(STATUS_EFFECT_SLEEPING)

TYPE_PROC_REF(/mob/living, AmountSleeping)() //How many deciseconds remain in our sleep
	var/datum/status_effect/incapacitating/sleeping/S = IsSleeping()
	if(S)
		return S.duration - world.time
	return 0

TYPE_PROC_REF(/mob/living, Sleeping)(amount, updating = TRUE, ignore_canstun = FALSE) //Can't go below remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_SLEEP, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if((!HAS_TRAIT(src, TRAIT_SLEEPIMMUNE)) || ignore_canstun)
		var/datum/status_effect/incapacitating/sleeping/S = IsSleeping()
		if(S)
			S.duration = max(world.time + amount, S.duration)
		else if(amount > 0)
			S = apply_status_effect(STATUS_EFFECT_SLEEPING, amount, updating)
		return S

TYPE_PROC_REF(/mob/living, SetSleeping)(amount, updating = TRUE, ignore_canstun = FALSE) //Sets remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_SLEEP, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if((!HAS_TRAIT(src, TRAIT_SLEEPIMMUNE)) || ignore_canstun)
		var/datum/status_effect/incapacitating/sleeping/S = IsSleeping()
		if(amount <= 0)
			if(S)
				qdel(S)
		else if(S)
			S.duration = world.time + amount
		else
			S = apply_status_effect(STATUS_EFFECT_SLEEPING, amount, updating)
		return S

TYPE_PROC_REF(/mob/living, AdjustSleeping)(amount, updating = TRUE, ignore_canstun = FALSE) //Adds to remaining duration
	if(SEND_SIGNAL(src, COMSIG_LIVING_STATUS_SLEEP, amount, updating, ignore_canstun) & COMPONENT_NO_STUN)
		return
	if((!HAS_TRAIT(src, TRAIT_SLEEPIMMUNE)) || ignore_canstun)
		var/datum/status_effect/incapacitating/sleeping/S = IsSleeping()
		if(S)
			S.duration += amount
		else if(amount > 0)
			S = apply_status_effect(STATUS_EFFECT_SLEEPING, amount, updating)
		return S

/////////////////////////////////// ADMIN SLEEP ////////////////////////////////////

TYPE_PROC_REF(/mob/living, IsAdminSleeping)()
	return has_status_effect(STATUS_EFFECT_ADMINSLEEP)

TYPE_PROC_REF(/mob/living, ToggleAdminSleep)()
	var/datum/status_effect/incapacitating/adminsleep/S = IsAdminSleeping()
	if(S)
		qdel(S)
	else
		S = apply_status_effect(STATUS_EFFECT_ADMINSLEEP, null, TRUE)
	return S

TYPE_PROC_REF(/mob/living, SetAdminSleep)(remove = FALSE)
	var/datum/status_effect/incapacitating/adminsleep/S = IsAdminSleeping()
	if(remove)
		qdel(S)
	else
		S = apply_status_effect(STATUS_EFFECT_ADMINSLEEP, null, TRUE)
	return S

///////////////////////////////// OFF BALANCE/SHOVIES ////////////////////////
TYPE_PROC_REF(/mob/living, ShoveOffBalance)(amount)
	var/datum/status_effect/off_balance/B = has_status_effect(STATUS_EFFECT_OFF_BALANCE)
	if(B)
		B.duration = max(world.time + amount, B.duration)
	else if(amount > 0)
		B = apply_status_effect(STATUS_EFFECT_OFF_BALANCE, amount)
	return B

///////////////////////////////// FROZEN /////////////////////////////////////

TYPE_PROC_REF(/mob/living, IsFrozen)()
	return has_status_effect(/datum/status_effect/freon)

///////////////////////////////////// STUN ABSORPTION /////////////////////////////////////

TYPE_PROC_REF(/mob/living, add_stun_absorption)(key, duration, priority, message, self_message, examine_message)
//adds a stun absorption with a key, a duration in deciseconds, its priority, and the messages it makes when you're stun/examined, if any
	if(!islist(stun_absorption))
		stun_absorption = list()
	if(stun_absorption[key])
		stun_absorption[key]["end_time"] = world.time + duration
		stun_absorption[key]["priority"] = priority
		stun_absorption[key]["stuns_absorbed"] = 0
	else
		stun_absorption[key] = list("end_time" = world.time + duration, "priority" = priority, "stuns_absorbed" = 0, \
		"visible_message" = message, "self_message" = self_message, "examine_message" = examine_message)

TYPE_PROC_REF(/mob/living, absorb_stun)(amount, ignoring_flag_presence)
	if(amount < 0 || stat || ignoring_flag_presence || !islist(stun_absorption))
		return FALSE
	if(!amount)
		amount = 0
	var/priority_absorb_key
	var/highest_priority
	for(var/i in stun_absorption)
		if(stun_absorption[i]["end_time"] > world.time && (!priority_absorb_key || stun_absorption[i]["priority"] > highest_priority))
			priority_absorb_key = stun_absorption[i]
			highest_priority = priority_absorb_key["priority"]
	if(priority_absorb_key)
		if(amount) //don't spam up the chat for continuous stuns
			if(priority_absorb_key["visible_message"] || priority_absorb_key["self_message"])
				if(priority_absorb_key["visible_message"] && priority_absorb_key["self_message"])
					visible_message(span_warning("[src][priority_absorb_key["visible_message"]]"), span_boldwarning("[priority_absorb_key["self_message"]]"))
				else if(priority_absorb_key["visible_message"])
					visible_message(span_warning("[src][priority_absorb_key["visible_message"]]"))
				else if(priority_absorb_key["self_message"])
					to_chat(src, span_boldwarning("[priority_absorb_key["self_message"]]"))
			priority_absorb_key["stuns_absorbed"] += amount
		return TRUE

/////////////////////////////////// DISABILITIES ////////////////////////////////////
TYPE_PROC_REF(/mob/living, add_quirk)(quirktype, spawn_effects) //separate proc due to the way these ones are handled
	if(HAS_TRAIT(src, quirktype))
		return
	var/datum/quirk/T = quirktype
	var/qname = initial(T.name)
	if(!SSquirks || !SSquirks.quirks[qname])
		return
	new quirktype (src, spawn_effects)
	return TRUE

TYPE_PROC_REF(/mob/living, remove_quirk)(quirktype)
	for(var/datum/quirk/Q in roundstart_quirks)
		if(Q.type == quirktype)
			qdel(Q)
			return TRUE
	return FALSE

TYPE_PROC_REF(/mob/living, has_quirk)(quirktype)
	for(var/datum/quirk/Q in roundstart_quirks)
		if(Q.type == quirktype)
			return TRUE
	return FALSE

/////////////////////////////////// TRAIT PROCS ////////////////////////////////////

TYPE_PROC_REF(/mob/living, cure_blind)(source)
	REMOVE_TRAIT(src, TRAIT_BLIND, source)
	if(!HAS_TRAIT(src, TRAIT_BLIND))
		if(eye_blind <= 1) //little hack now that we don't actively check for trait and unconsciousness on update_blindness.
			adjust_blindness(-1)

TYPE_PROC_REF(/mob/living, become_blind)(source)
	if(!HAS_TRAIT(src, TRAIT_BLIND)) // not blind already, add trait then overlay
		ADD_TRAIT(src, TRAIT_BLIND, source)
		blind_eyes(1)
	else
		ADD_TRAIT(src, TRAIT_BLIND, source)

TYPE_PROC_REF(/mob/living, cure_nearsighted)(source)
	REMOVE_TRAIT(src, TRAIT_NEARSIGHT, source)
	if(!HAS_TRAIT(src, TRAIT_NEARSIGHT))
		clear_fullscreen("nearsighted")

TYPE_PROC_REF(/mob/living, become_nearsighted)(source)
	if(!HAS_TRAIT(src, TRAIT_NEARSIGHT))
		overlay_fullscreen("nearsighted", /obj/screen/fullscreen/impaired, 1)
	ADD_TRAIT(src, TRAIT_NEARSIGHT, source)

TYPE_PROC_REF(/mob/living, become_mega_nearsighted)(source)
	if(!HAS_TRAIT(src, TRAIT_NEARSIGHT_MEGA))
		overlay_fullscreen("nearsighted", /obj/screen/fullscreen/impaired, 2) //This is a nasty surprise to people who try and abuse nearsighted.
	ADD_TRAIT(src, TRAIT_NEARSIGHT_MEGA, source)


TYPE_PROC_REF(/mob/living, cure_husk)(source)
	REMOVE_TRAIT(src, TRAIT_HUSK, source)
	if(!HAS_TRAIT(src, TRAIT_HUSK))
		REMOVE_TRAIT(src, TRAIT_DISFIGURED, "husk")
		update_body()
		return TRUE

TYPE_PROC_REF(/mob/living, become_husk)(source)
	if(!HAS_TRAIT(src, TRAIT_HUSK))
		ADD_TRAIT(src, TRAIT_HUSK, source)
		ADD_TRAIT(src, TRAIT_DISFIGURED, "husk")
		update_body()
	else
		ADD_TRAIT(src, TRAIT_HUSK, source)

TYPE_PROC_REF(/mob/living, cure_fakedeath)(source)
	REMOVE_TRAIT(src, TRAIT_FAKEDEATH, source)
	REMOVE_TRAIT(src, TRAIT_DEATHCOMA, source)
	if(stat != DEAD)
		tod = null
	update_stat()

TYPE_PROC_REF(/mob/living, fakedeath)(source, silent = FALSE)
	if(stat == DEAD)
		return
	if(!silent)
		INVOKE_ASYNC(src, PROC_REF(emote), "deathgasp")
	ADD_TRAIT(src, TRAIT_FAKEDEATH, source)
	ADD_TRAIT(src, TRAIT_DEATHCOMA, source)
	tod = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)
	update_stat()

///Unignores all slowdowns that lack the IGNORE_NOSLOW flag.
TYPE_PROC_REF(/mob/living, unignore_slowdown)(source)
	REMOVE_TRAIT(src, TRAIT_IGNORESLOWDOWN, source)
	update_movespeed()

///Ignores all slowdowns that lack the IGNORE_NOSLOW flag.
TYPE_PROC_REF(/mob/living, ignore_slowdown)(source)
	ADD_TRAIT(src, TRAIT_IGNORESLOWDOWN, source)
	update_movespeed()

///Ignores specific slowdowns. Accepts a list of slowdowns.
TYPE_PROC_REF(/mob/living, add_movespeed_mod_immunities)(source, slowdown_type, update = TRUE)
	if(islist(slowdown_type))
		for(var/listed_type in slowdown_type)
			if(ispath(listed_type))
				listed_type = "[listed_type]" //Path2String
			LAZYADDASSOC(movespeed_mod_immunities, listed_type, source)
	else
		if(ispath(slowdown_type))
			slowdown_type = "[slowdown_type]" //Path2String
		LAZYADDASSOC(movespeed_mod_immunities, slowdown_type, source)
	if(update)
		update_movespeed()

///Unignores specific slowdowns. Accepts a list of slowdowns.
TYPE_PROC_REF(/mob/living, remove_movespeed_mod_immunities)(source, slowdown_type, update = TRUE)
	if(islist(slowdown_type))
		for(var/listed_type in slowdown_type)
			if(ispath(listed_type))
				listed_type = "[listed_type]" //Path2String
			LAZYREMOVEASSOC(movespeed_mod_immunities, listed_type, source)
	else
		if(ispath(slowdown_type))
			slowdown_type = "[slowdown_type]" //Path2String
		LAZYREMOVEASSOC(movespeed_mod_immunities, slowdown_type, source)
	if(update)
		update_movespeed()

////////////////////////////// WEAPON DRAW DELAY ////////////////////////////////////

/mob/living/IsWeaponDrawDelayed() //Check if we're delayed from firing a weapon
	return has_status_effect(STATUS_EFFECT_WEAPON_DRAW_DELAYED)

TYPE_PROC_REF(/mob/living, AmountWeaponDrawDelay)() //Check how many deciseconds remain in our fire delay
	var/datum/status_effect/incapacitating/weapon_draw_delayed/F = IsWeaponDrawDelayed()
	if(F)
		return F.duration - world.time
	return 0

TYPE_PROC_REF(/mob/living, WeaponDrawDelay)(amount, updating = TRUE) //Can't go below remaining duration
	if(status_flags)
		var/datum/status_effect/incapacitating/weapon_draw_delayed/F = IsWeaponDrawDelayed()
		if(F)
			F.duration = max(world.time + amount, F.duration)
		else if(amount > 0)
			F = apply_status_effect(STATUS_EFFECT_WEAPON_DRAW_DELAYED, amount, updating)
		return F

TYPE_PROC_REF(/mob/living, SetWeaponDrawDelay)(amount, updating = TRUE) //Sets remaining duration
	if(status_flags)
		var/datum/status_effect/incapacitating/weapon_draw_delayed/F = IsWeaponDrawDelayed()
		if(amount <= 0)
			if(F)
				qdel(F)
		else
			if(F)
				F.duration = world.time + amount
			else
				F = apply_status_effect(STATUS_EFFECT_WEAPON_DRAW_DELAYED, amount, updating)
		return F

TYPE_PROC_REF(/mob/living, AdjustWeaponDrawDelay)(amount, updating = TRUE) //Adds to remaining duration
	if(status_flags)
		var/datum/status_effect/incapacitating/weapon_draw_delayed/F = IsWeaponDrawDelayed()
		if(F)
			F.duration += amount
		else if(amount > 0)
			F = apply_status_effect(STATUS_EFFECT_WEAPON_DRAW_DELAYED, amount, updating)
		return F

////////////////////////////// THROW DELAY ////////////////////////////////////

/mob/living/IsThrowDelayed() //Check if we're delayed from throwing anything
	return has_status_effect(STATUS_EFFECT_THROW_DELAYED)

TYPE_PROC_REF(/mob/living, AmountThrowDelay)() //Check how many deciseconds remain in our fire delay
	var/datum/status_effect/incapacitating/throw_delayed/T = IsThrowDelayed()
	if(T)
		return T.duration - world.time
	return 0

TYPE_PROC_REF(/mob/living, ThrowDelay)(amount, updating = TRUE) //Can't go below remaining duration
	if(status_flags)
		var/datum/status_effect/incapacitating/throw_delayed/T = IsThrowDelayed()
		if(T)
			T.duration = max(world.time + amount, T.duration)
		else if(amount > 0)
			T = apply_status_effect(STATUS_EFFECT_THROW_DELAYED, amount, updating)
		return T

TYPE_PROC_REF(/mob/living, SetThrowDelay)(amount, updating = TRUE) //Sets remaining duration
	if(status_flags)
		var/datum/status_effect/incapacitating/throw_delayed/T = IsThrowDelayed()
		if(amount <= 0)
			if(T)
				qdel(T)
		else
			if(T)
				T.duration = world.time + amount
			else
				T = apply_status_effect(STATUS_EFFECT_THROW_DELAYED, amount, updating)
		return T

TYPE_PROC_REF(/mob/living, AdjustThrowDelay)(amount, updating = TRUE) //Adds to remaining duration
	if(status_flags)
		var/datum/status_effect/incapacitating/throw_delayed/T = IsThrowDelayed()
		if(T)
			T.duration += amount
		else if(amount > 0)
			T = apply_status_effect(STATUS_EFFECT_THROW_DELAYED, amount, updating)
		return T
