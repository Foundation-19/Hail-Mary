/// Called on [/mob/living/Initialize()], for the mob to register to relevant signals.
TYPE_PROC_REF(/mob/living, register_init_signals)()
	RegisterSignal(src, SIGNAL_ADDTRAIT(TRAIT_KNOCKEDOUT), PROC_REF(on_knockedout_trait_gain))
	RegisterSignal(src, SIGNAL_REMOVETRAIT(TRAIT_KNOCKEDOUT), PROC_REF(on_knockedout_trait_loss))


/// Called when [TRAIT_KNOCKEDOUT] is added to the mob.
TYPE_PROC_REF(/mob/living, on_knockedout_trait_gain)(datum/source)
	SIGNAL_HANDLER
	if(stat < UNCONSCIOUS)
		set_stat(UNCONSCIOUS)

/// Called when [TRAIT_KNOCKEDOUT] is removed from the mob.
TYPE_PROC_REF(/mob/living, on_knockedout_trait_loss)(datum/source)
	SIGNAL_HANDLER
	if(stat <= UNCONSCIOUS)
		update_stat()
