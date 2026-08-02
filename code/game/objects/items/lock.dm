GLOBAL_LIST_EMPTY(global_locks)
/obj/item/lock_construct
	name = "\improper lock"
	icon = 'icons/obj/lock.dmi'
	w_class = WEIGHT_CLASS_SMALL
	var/lock_data
	var/static/lock_uid = 1
	var/locked = FALSE
	/// Lock difficulty for lockpicking mini-game (1 = trivial, 5 = master-security).
	var/lock_tier = 1
	var/prying = FALSE //if somebody is trying to pry us off
	/// Set TRUE when the lock is bypassed by lockpicking — cleared when re-locked with a key.
	var/tampered = FALSE
	/// Stored tumbler solution — per-pin min/max/type/false-zone/stack-height.
	/// Generated on the first lockpick attempt and reused on all subsequent ones
	/// so the lock has a consistent combination. Cleared on successful pick.
	var/list/pin_solution = null
	/// Stored binding order for the pin solution.
	var/list/pin_bind_order = null
	/// world.time after which a new pick attempt may begin.
	/// Set after every non-success ending to impose a mechanism-reset delay.
	var/pick_reset_until = 0

/obj/item/lock_construct/Initialize()
	. = ..()
	lock_data = lock_uid++
	desc = "A basic lock for doors. It has [lock_data] engraved on it."
	GLOB.global_locks += src

/obj/item/lock_construct/examine(mob/user)
	. = ..()
	switch(lock_tier)
		if(1) . += span_notice("The mechanism is simple — basic tumbler, easy to pick.")
		if(2) . += span_notice("The mechanism looks sturdy — standard quality.")
		if(3) . += span_notice("The mechanism looks heavy-duty — reinforced internals.")
		if(4) . += span_notice("The mechanism is complex — security-grade pins.")
		if(5) . += span_notice("The mechanism looks formidable — master-security grade.")

// Tier subtypes — each has a distinct name, description, and lock_tier.
// Tier 1 is the base type. Tiers 2–5 are crafted at a workbench.

/obj/item/lock_construct/tier2
	name = "\improper standard lock"
	lock_tier = 2

/obj/item/lock_construct/tier2/Initialize()
	. = ..()
	desc = "A well-made standard lock. It has [lock_data] engraved on it."

/obj/item/lock_construct/tier3
	name = "\improper reinforced lock"
	lock_tier = 3

/obj/item/lock_construct/tier3/Initialize()
	. = ..()
	desc = "A reinforced lock with hardened internals. It has [lock_data] engraved on it."

/obj/item/lock_construct/tier4
	name = "\improper security lock"
	lock_tier = 4

/obj/item/lock_construct/tier4/Initialize()
	. = ..()
	desc = "A security-grade lock with precision-machined pins. It has [lock_data] engraved on it."

/obj/item/lock_construct/tier5
	name = "\improper master security lock"
	lock_tier = 5

/obj/item/lock_construct/tier5/Initialize()
	. = ..()
	desc = "A formidable vault-quality lock. Almost nothing short of a master pick will open this. It has [lock_data] engraved on it."

/obj/item/lock_construct/Destroy()
	..()
	GLOB.global_locks -= src

/obj/item/lock_construct/attackby(obj/item/I, mob/user) // Blatantly borrowed from Baystation coders and modified for simplicity. Thanks for pointing me in that direction, Rhicora.
	if(iskey(I))
		var/obj/item/key/K = I
		if(!K.lock_data)
			to_chat(user, span_notice("You fashion \the [I] to unlock \the [src]"))
			K.lock_data = lock_data
			K.desc = "A simple key for locks. It has [K.lock_data] engraved on it."
		else
			to_chat(user, span_warning("\The [I] already unlocks something..."))
		return
	if(islock(I))
		var/obj/item/lock_construct/L = I
		L.lock_data = src.lock_data
		to_chat(user, span_notice("You copy the lock from \the [src] to \the [L], making them identical."))
		L.desc = "A heavy-duty lock for doors. It has [L.lock_data] engraved on it."
		return
	..()

/obj/item/lock_construct/proc/check_key(obj/item/key/K, mob/user = null)
	if(K.lock_data == src.lock_data) //if the key matches us
		if(locked)
			user.visible_message(span_warning("[user] unlocks \the [src]."))
			locked = FALSE
		else
			user.visible_message(span_warning("[user] locks \the [src]."))
			locked = TRUE
			tampered = FALSE  // faction member re-locked it — tampering acknowledged
	else
		to_chat(user, span_warning("This is the wrong key!"))

/obj/item/lock_construct/proc/check_locked()
	return locked

/obj/item/lock_construct/proc/pry_off(mob/living/user, atom/A)
	if(!prying)
		user.visible_message(span_notice("[user] starts prying [src] off [A]."), \
							span_notice("You start prying [src] off [A]."))
		var/time_to_open = 50
		if(locked)
			time_to_open = 500
		playsound(src, 'sound/machines/airlock_alien_prying.ogg',100,1) //is it aliens or just the CE being a dick?
		prying = TRUE
		var/result = do_after(user, time_to_open, target = A)
		prying = FALSE
		if(result)
			user.visible_message(span_notice("[src] breaks off [A] and falls to pieces."))
			return TRUE
	return FALSE

/obj/item/key
	name = "\improper key"
	icon = 'icons/obj/key.dmi'
	w_class = WEIGHT_CLASS_TINY
	var/lock_data = ""
	obj_flags = UNIQUE_RENAME

/obj/item/key/Initialize()
	. = ..()
	desc = "A simple key for locks. It has [src.lock_data ? src.lock_data : "nothing"] engraved on it."

/obj/item/key/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/rods))
		var/obj/item/stack/rods/M = I
		to_chat(user, span_notice("You begin to shape a rod into [src]..."))
		if(do_after(user, 35, target = src))
			if(M.get_amount() < 1 || !M)
				return
			var/obj/item/key/S = new /obj/item/key
			M.use(1)
			user.put_in_hands(S)
			to_chat(user, span_notice("You make a [S] identical to the old [src]."))
			S.lock_data = src.lock_data
	else
		return ..()
