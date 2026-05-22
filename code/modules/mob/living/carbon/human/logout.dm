/mob/living/carbon/human/Logout()
	// Handle any active trades
	handle_trade_disconnect(src)
	return ..()
