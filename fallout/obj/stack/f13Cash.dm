#define maxCoinIcon 6
#define CASH_CAP 1

/* exchange rates X * CAP*/
#define CASH_AUR 100 /* 100 caps to 1 AUR */
#define CASH_DEN 4 /* 4 caps to 1 DEN */
#define CASH_NCR 0.4 /* $100 to 40 caps */

/* value of coins to spawn, use as-is for caps */
/* LOW_MIN / AUR = amount in AUR */

/// Average amount of caps spawned from trash pile
#define AVG_BASE 13 / CASH_CAP

// A low value cash spawn
#define CASH_MULT_LOW 1

// A medium value cash spawn
#define CASH_MULT_MED 2.1

// A high value cash spawn
#define CASH_MULT_HIGH 3.1

/// round(AVG * CASH_MULT) +- AVG_SPREAD
#define AVG_SPREAD 6 / CASH_CAP

// The Bankers Vault-Stash, done like this make it so it only spawns on his person to stop metarushing. Average 8500.
#define AVG_BANKER 8500 / CASH_CAP
#define BANKER_SPREAD 6500 / CASH_CAP

/obj/item/stack/f13Cash //DO NOT USE THIS
	name = "bottle cap"
	singular_name = "cap"
	icon = 'icons/obj/economy.dmi'
	icon_state = "bottle_cap"
	amount = 1
	max_amount = 15000
	throwforce = 0
	throw_speed = 2
	throw_range = 2
	w_class = WEIGHT_CLASS_TINY
	full_w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE
	var/flavor_desc =	"A standard Nuka-Cola bottle cap featuring 21 crimps and ridges,\
					A common unit of exchange, backed by water in the Hub."
	var/value = CASH_CAP
	var/flippable = TRUE
	var/cooldown = 0
	var/coinflip
	var/list/sideslist = list("heads","tails")
	merge_type = /obj/item/stack/f13Cash
	custom_materials = list(/datum/material/f13cash=MINERAL_MATERIAL_AMOUNT)

/obj/item/stack/f13Cash/attack_self(mob/user)
	if (flippable)
		if(cooldown < world.time)
			coinflip = pick(sideslist)
			cooldown = world.time + 15
			//flick("coin_[cmineral]_flip", src)
			//icon_state = "coin_[cmineral]_[coinflip]"
			playsound(user.loc, 'sound/items/coinflip.ogg', 50, 1)
			var/oldloc = loc
			sleep(15)
			if(loc == oldloc && user && !user.incapacitated())
				user.visible_message("[user] has flipped [src]. It lands on [coinflip].", \
									span_notice("You flip [src]. It lands on [coinflip]."), \
									span_italic("You hear the clattering of loose change."))
		return TRUE//did the coin flip? useful for suicide_act

/obj/item/stack/f13Cash/caps
	merge_type = /obj/item/stack/f13Cash/caps

/obj/item/stack/f13Cash/caps/twofive
	amount = 25
	merge_type = /obj/item/stack/f13Cash/caps

/obj/item/stack/f13Cash/caps/fivezero
	amount = 50
	merge_type = /obj/item/stack/f13Cash/caps

/obj/item/stack/f13Cash/caps/onezerozero
	amount = 100
	merge_type = /obj/item/stack/f13Cash/caps

/obj/item/stack/f13Cash/caps/onefivezero
	amount = 150
	merge_type = /obj/item/stack/f13Cash/caps

/obj/item/stack/f13Cash/caps/twozerozero
	amount = 200
	merge_type = /obj/item/stack/f13Cash/caps

/obj/item/stack/f13Cash/caps/twofivezero
	amount = 250
	merge_type = /obj/item/stack/f13Cash/caps

/obj/item/stack/f13Cash/caps/threezerozero
	amount = 300
	merge_type = /obj/item/stack/f13Cash/caps

/obj/item/stack/f13Cash/caps/threefivezero
	amount = 350
	merge_type = /obj/item/stack/f13Cash/caps

/obj/item/stack/f13Cash/caps/fivezerozero
	amount = 500
	merge_type = /obj/item/stack/f13Cash/caps

/obj/item/stack/f13Cash/caps/onezerozerozero
	amount = 1000
	merge_type = /obj/item/stack/f13Cash/caps

/obj/item/stack/f13Cash/Initialize()
	. = ..()
	update_desc()
	update_icon()

/obj/item/stack/f13Cash/proc/update_desc()
	var/total_worth = get_item_credit_value()
	desc = "It's worth [total_worth] [singular_name][ (latin) ? (( amount > 1 ) ? "i" : "us") : (( amount > 1 ) ? "s each" : "")].\n[flavor_desc]"

/obj/item/stack/f13Cash/get_item_credit_value()
	return (amount*value)

/obj/item/stack/f13Cash/merge(obj/item/stack/S)
	. = ..()
	update_desc()
	update_icon()

/obj/item/stack/f13Cash/use(used, transfer = FALSE, check = TRUE)
	. = ..()
	update_desc()
	update_icon()

/obj/item/stack/f13Cash/random
	var/money_type = /obj/item/stack/f13Cash/caps
	var/average_qty = AVG_BASE
	var/average_spread = AVG_SPREAD
	var/average_mult = CASH_MULT_LOW
	var/spawn_nothing_chance = 0 //chance no money at all spawns

/obj/item/stack/f13Cash/random/Initialize(mapload, new_amount, merge = TRUE, amt_multiplier = 0) //S.P.E.C.I.A.L.
	..()
	amt_multiplier = max(amt_multiplier, 0)
	if(amt_multiplier)
		average_mult *= amt_multiplier
	if(!prob(spawn_nothing_chance))
		spawn_money()
	return INITIALIZE_HINT_QDEL

/obj/item/stack/f13Cash/random/proc/spawn_money()
	var/spawn_amount = round(average_qty * average_mult)
	var/obj/item/stack/f13Cash/stack = new money_type
	stack.loc = loc
	stack.amount = round(rand(round(spawn_amount - average_spread), round(spawn_amount + average_spread)))
	stack.update_icon()

/* we have 6 icons, so we will use our own, instead of stack's   */
/obj/item/stack/f13Cash/update_icon()
	switch(amount)
		if(1)
			icon_state = "[initial(icon_state)]"
		if(2 to 5)
			icon_state = "[initial(icon_state)]2"
		if(6 to 50)
			icon_state = "[initial(icon_state)]3"
		if(51 to 100)
			icon_state = "[initial(icon_state)]4"
		if(101 to 500)
			icon_state = "[initial(icon_state)]5"
		if(501 to 15000)
			icon_state = "[initial(icon_state)]6"

/obj/item/stack/f13Cash/random/low
	average_mult = CASH_MULT_LOW

/obj/item/stack/f13Cash/random/low/lowchance
	spawn_nothing_chance = 75

/obj/item/stack/f13Cash/random/low/medchance
	spawn_nothing_chance = 50

/obj/item/stack/f13Cash/random/med
	average_mult = CASH_MULT_MED

/obj/item/stack/f13Cash/random/high
	average_mult = CASH_MULT_HIGH

/obj/item/stack/f13Cash/random/banker
	average_qty = AVG_BANKER
	average_spread = BANKER_SPREAD

/obj/item/stack/f13Cash/denarius
	name = "Denarius"
	latin = 1
	singular_name = "Denari" // -us or -i
	icon = 'icons/obj/economy.dmi'
	icon_state = "denarius"
	flavor_desc =	"The inscriptions are in Latin,\n\
		'Caesar Dictator' on the front and\n\
		'Magnum Chasma' on the back."
	value = CASH_DEN * CASH_CAP
	merge_type = /obj/item/stack/f13Cash/denarius

/obj/item/stack/f13Cash/random/denarius
	average_qty = AVG_BASE / CASH_DEN
	average_spread = AVG_SPREAD / CASH_DEN
	money_type = /obj/item/stack/f13Cash/denarius

/obj/item/stack/f13Cash/random/denarius/low
	average_mult = CASH_MULT_LOW

/obj/item/stack/f13Cash/random/denarius/med
	average_mult = CASH_MULT_MED

/obj/item/stack/f13Cash/random/denarius/high
	average_mult = CASH_MULT_HIGH

/obj/item/stack/f13Cash/random/denarius/legionpay_basic
	average_mult = CASH_MULT_LOW

/obj/item/stack/f13Cash/random/denarius/legionpay_veteran
	average_mult = CASH_MULT_MED

/obj/item/stack/f13Cash/random/denarius/legionpay_officer
	average_mult = CASH_MULT_HIGH

/obj/item/stack/f13Cash/aureus
	name = "Aureus"
	latin = 1
	singular_name = "Aure"// -us or -i
	icon = 'icons/obj/economy.dmi'
	icon_state = "aureus"
	flavor_desc = 	"The inscriptions are in Latin,\n\
					'Aeternit Imperi' on the front and\n\
					'Pax Per Bellum' on the back."
	value = CASH_AUR * CASH_CAP
	merge_type = /obj/item/stack/f13Cash/aureus

/obj/item/stack/f13Cash/random/aureus
	average_qty = AVG_BASE / CASH_AUR
	average_spread = AVG_SPREAD / CASH_AUR
	money_type = /obj/item/stack/f13Cash/aureus

/obj/item/stack/f13Cash/random/aureus/low
	average_mult = CASH_MULT_LOW

/obj/item/stack/f13Cash/random/aureus/med
	average_mult = CASH_MULT_MED

/obj/item/stack/f13Cash/random/aureus/high
	average_mult = CASH_MULT_HIGH

/obj/item/stack/f13Cash/ncr
	name = "NCR Dollar"
	singular_name = "NCR Dollar"  /* same for denarius, we can pretend the legion can't latin properly */
	flavor_desc = "Paper money used by the NCR."
	icon = 'icons/obj/economy.dmi'
	icon_state = "ncr" /* 10 points to whoever writes flavour text for each bill */
	value = CASH_NCR * CASH_CAP
	flippable = FALSE
	merge_type = /obj/item/stack/f13Cash/ncr

/obj/item/stack/f13Cash/ncr/update_icon()
	switch(amount)
		if(1  to 9)
			icon_state = "[initial(icon_state)]"
		if(10 to 19)
			icon_state = "[initial(icon_state)]10"
		if(20 to 49)
			icon_state = "[initial(icon_state)]20"
		if(50 to 99)
			icon_state = "[initial(icon_state)]50"
		if(100 to 199)
			icon_state = "[initial(icon_state)]100"
		if(200 to 499)
			icon_state = "[initial(icon_state)]200"
		if(500 to 15000)
			icon_state = "[initial(icon_state)]500"

/obj/item/stack/f13Cash/random/ncr
	money_type = /obj/item/stack/f13Cash/ncr
	average_qty = AVG_BASE / CASH_NCR
	average_spread = AVG_SPREAD / CASH_NCR

/obj/item/stack/f13Cash/random/ncr/low
	average_mult = CASH_MULT_LOW

/obj/item/stack/f13Cash/random/ncr/med
	average_mult = CASH_MULT_MED

/obj/item/stack/f13Cash/random/ncr/high
	average_mult = CASH_MULT_HIGH

/obj/item/stack/f13Cash/random/ncr/ncrpay_basic
	average_mult = CASH_MULT_LOW

/obj/item/stack/f13Cash/random/ncr/ncrpay_veteran
	average_mult = CASH_MULT_MED

/obj/item/stack/f13Cash/random/ncr/ncrpay_officer
	average_mult = CASH_MULT_HIGH


#undef maxCoinIcon
#undef CASH_CAP
#undef CASH_AUR
#undef CASH_DEN
#undef CASH_NCR
