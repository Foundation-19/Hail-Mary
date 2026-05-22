// GAMBLING SYSTEM - Blackjack and Roulette with caps betting
// Creates social RP around gambling tables

// ============================================
// BLACKJACK TABLE
// ============================================

/obj/structure/gambling/blackjack
	name = "blackjack table"
	desc = "A worn felt table for playing blackjack. Double down on your luck."
	icon = 'icons/obj/vending.dmi'
	icon_state = "fridge_dark"
	density = TRUE
	anchored = TRUE
	var/min_bet = 5
	var/max_bet = 200
	var/cooldown = 50

/obj/structure/gambling/blackjack/attack_hand(mob/user)
	if(!ishuman(user))
		return
	play_blackjack(user)

/obj/structure/gambling/blackjack/proc/play_blackjack(mob/living/carbon/human/player)
	if(cooldown > world.time)
		to_chat(player, span_warning("The table is busy! Wait a moment."))
		return
	var/bet = input(player, "Place your bet ([min_bet]-[max_bet] caps):", "Blackjack", min_bet) as num|null
	if(isnull(bet) || bet < min_bet || bet > max_bet)
		to_chat(player, span_warning("Bet must be between [min_bet] and [max_bet] caps."))
		return

	var/caps_available = find_caps_on_mob(player)
	if(caps_available < bet)
		to_chat(player, span_warning("You don't have enough caps!"))
		return

	remove_caps_from_mob(player, bet)
	cooldown = world.time + 50

	var/list/deck = shuffle(list(1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,6,6,6,6,7,7,7,7,8,8,8,8,9,9,9,9,10,10,10,10,11,11,11,11,12,12,12,12,13,13,13,13))
	var/list/player_hand = list()
	var/list/dealer_hand = list()

	player_hand += pick_n_take(deck)
	dealer_hand += pick_n_take(deck)
	player_hand += pick_n_take(deck)
	dealer_hand += pick_n_take(deck)

	var/player_total = hand_value(player_hand)

	visible_message(span_notice("[player] sits down at the blackjack table and bets [bet] caps."))

	var/result = "bust"
	if(player_total == 21)
		result = "blackjack"
	else
		var/hitting = TRUE
		while(hitting)
			var/hand_text = hand_display(player_hand)
			var/choice = alert(player, "Your hand: [hand_text] (Total: [player_total])\nDealer shows: [dealer_hand[1]]", "Blackjack", "Hit", "Stand")
			if(choice == "Hit")
				var/new_card = pick_n_take(deck)
				player_hand += new_card
				player_total = hand_value(player_hand)
				if(player_total > 21)
					result = "bust"
					hitting = FALSE
				else if(player_total == 21)
					result = "stand"
					hitting = FALSE
			else
				result = "stand"
				hitting = FALSE

	var/final_player = hand_value(player_hand)

	if(result == "blackjack")
		var/winnings = bet + round(bet * 1.5)
		payout(player, winnings)
		visible_message(span_greentext("[player] hits BLACKJACK! Wins [winnings] caps!"))
		log_game("GAMBLING: [player.ckey] hit blackjack, won [winnings] caps")
		if(player.ckey)
			adjust_karma(player.ckey, 3)
	else if(result == "bust")
		visible_message(span_warning("[player] busts with [final_player]! Loses [bet] caps."))
		log_game("GAMBLING: [player.ckey] busted in blackjack, lost [bet] caps")
		if(player.ckey)
			adjust_karma(player.ckey, -1)
	else
		while(hand_value(dealer_hand) < 17)
			dealer_hand += pick_n_take(deck)
		var/final_dealer = hand_value(dealer_hand)
		var/player_hand_text = hand_display(player_hand)
		var/dealer_hand_text = hand_display(dealer_hand)

		if(final_dealer > 21)
			var/winnings = bet * 2
			payout(player, winnings)
			visible_message(span_greentext("[player] wins! Player: [player_hand_text]=[final_player] vs Dealer: [dealer_hand_text]=[final_dealer] BUST! Wins [winnings] caps!"))
			if(player.ckey)
				adjust_karma(player.ckey, 2)
		else if(final_player > final_dealer)
			var/winnings = bet * 2
			payout(player, winnings)
			visible_message(span_greentext("[player] wins! Player: [player_hand_text]=[final_player] vs Dealer: [dealer_hand_text]=[final_dealer]. Wins [winnings] caps!"))
			if(player.ckey)
				adjust_karma(player.ckey, 2)
		else if(final_player == final_dealer)
			payout(player, bet)
			visible_message(span_notice("[player] pushes! Player: [player_hand_text]=[final_player] vs Dealer: [dealer_hand_text]=[final_dealer]. Bet returned."))
		else
			visible_message(span_warning("[player] loses! Player: [player_hand_text]=[final_player] vs Dealer: [dealer_hand_text]=[final_dealer]. Loses [bet] caps."))
			if(player.ckey)
				adjust_karma(player.ckey, -1)

/obj/structure/gambling/blackjack/proc/hand_value(list/hand)
	var/total = 0
	var/aces = 0
	for(var/card in hand)
		if(card == 1)
			aces++
			total += 11
		else if(card >= 11)
			total += 10
		else
			total += card
	while(total > 21 && aces > 0)
		total -= 10
		aces--
	return total

/obj/structure/gambling/blackjack/proc/hand_display(list/hand)
	var/list/display = list()
	for(var/card in hand)
		if(card == 1)
			display += "A"
		else if(card == 11 || card == 12 || card == 13)
			display += "[card == 11 ? "J" : card == 12 ? "Q" : "K"]"
		else
			display += "[card]"
	return english_list(display)

/obj/structure/gambling/blackjack/proc/payout(mob/living/carbon/human/H, amount)
	var/obj/item/stack/f13Cash/caps/C = new(get_turf(H), amount)
	H.put_in_hands(C)

// ============================================
// ROULETTE TABLE
// ============================================

/obj/structure/gambling/roulette
	name = "roulette table"
	desc = "Spin the wheel, test your luck. The house always wins... usually."
	icon = 'icons/obj/vending.dmi'
	icon_state = "fridge_dark"
	density = TRUE
	anchored = TRUE
	var/min_bet = 5
	var/max_bet = 100
	var/cooldown = 0

/obj/structure/gambling/roulette/attack_hand(mob/user)
	if(!ishuman(user))
		return
	play_roulette(user)

/obj/structure/gambling/roulette/proc/play_roulette(mob/living/carbon/human/player)
	if(cooldown > world.time)
		to_chat(player, span_warning("The wheel is still spinning! Wait a moment."))
		return
	var/bet = input(player, "Place your bet ([min_bet]-[max_bet] caps):", "Roulette", min_bet) as num|null
	if(isnull(bet) || bet < min_bet || bet > max_bet)
		to_chat(player, span_warning("Bet must be between [min_bet] and [max_bet] caps."))
		return

	var/caps_available = find_caps_on_mob(player)
	if(caps_available < bet)
		to_chat(player, span_warning("You don't have enough caps!"))
		return

	var/bet_type = input(player, "What are you betting on?", "Roulette") as null|anything in list("Red", "Black", "Green (0)", "Odd", "Even", "Low (1-18)", "High (19-36)")
	if(!bet_type)
		return

	remove_caps_from_mob(player, bet)
	cooldown = world.time + 50
	visible_message(span_notice("[player] bets [bet] caps on [bet_type] at the roulette table!"))

	var/result = rand(0, 36)
	var/is_red = (result in list(1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36))
	var/color_name = result == 0 ? "Green" : is_red ? "Red" : "Black"
	var/won = FALSE
	var/multiplier = 0

	if(bet_type == "Red" && is_red)
		won = TRUE
		multiplier = 2
	else if(bet_type == "Black" && !is_red && result != 0)
		won = TRUE
		multiplier = 2
	else if(bet_type == "Green (0)" && result == 0)
		won = TRUE
		multiplier = 36
	else if(bet_type == "Odd" && result % 2 == 1 && result != 0)
		won = TRUE
		multiplier = 2
	else if(bet_type == "Even" && result % 2 == 0 && result != 0)
		won = TRUE
		multiplier = 2
	else if(bet_type == "Low (1-18)" && result >= 1 && result <= 18)
		won = TRUE
		multiplier = 2
	else if(bet_type == "High (19-36)" && result >= 19 && result <= 36)
		won = TRUE
		multiplier = 2

	visible_message(span_notice("The ball lands on [color_name] [result]!"))

	if(won)
		var/winnings = bet * multiplier
		var/obj/item/stack/f13Cash/caps/payout = new(get_turf(player), winnings)
		player.put_in_hands(payout)
		visible_message(span_greentext("[player] wins [winnings] caps on [bet_type]!"))
		log_game("GAMBLING: [player.ckey] won [winnings] caps on roulette [bet_type]")
		if(player.ckey)
			adjust_karma(player.ckey, 3)
	else
		visible_message(span_warning("[player] loses [bet] caps."))
		log_game("GAMBLING: [player.ckey] lost [bet] caps on roulette [bet_type]")
		if(player.ckey)
			adjust_karma(player.ckey, -1)

// ============================================
// DICE ROLLING (caps betting)
// ============================================

/obj/structure/gambling/dice_table
	name = "dice table"
	desc = "Roll the bones. High roller wins."
	icon = 'icons/obj/vending.dmi'
	icon_state = "fridge_dark"
	density = TRUE
	anchored = TRUE

/obj/structure/gambling/dice_table/attack_hand(mob/user)
	if(!ishuman(user))
		return
	challenge_dice(user)

/obj/structure/gambling/dice_table/proc/challenge_dice(mob/living/carbon/human/challenger)
	var/list/nearby = list()
	for(var/mob/living/carbon/human/H in view(2, src))
		if(H == challenger || H.stat == DEAD)
			continue
		nearby += H

	if(!nearby.len)
		to_chat(challenger, span_warning("No one nearby to challenge!"))
		return

	var/mob/living/carbon/human/opponent = input(challenger, "Challenge whom?", "Dice") as null|anything in nearby
	if(!opponent)
		return

	var/bet = input(challenger, "Wager how many caps?", "Dice", 10) as num|null
	if(isnull(bet) || bet < 1)
		return

	var/accept = alert(opponent, "[challenger] challenges you to a dice roll for [bet] caps! Accept?", "Dice Challenge", "Yes", "No")
	if(accept != "Yes")
		to_chat(challenger, span_warning("[opponent] declined."))
		return

	var/challenger_caps = find_caps_on_mob(challenger)
	var/opponent_caps = find_caps_on_mob(opponent)
	if(challenger_caps < bet)
		to_chat(challenger, span_warning("You can't afford the bet!"))
		return
	if(opponent_caps < bet)
		to_chat(opponent, span_warning("You can't afford the bet!"))
		return

	remove_caps_from_mob(challenger, bet)
	remove_caps_from_mob(opponent, bet)

	var/challenger_roll = rand(1, 6) + rand(1, 6)
	var/opponent_roll = rand(1, 6) + rand(1, 6)

	visible_message(span_notice("[challenger] rolls [challenger_roll]! [opponent] rolls [opponent_roll]!"))

	if(challenger_roll > opponent_roll)
		var/winnings = bet * 2
		var/obj/item/stack/f13Cash/caps/payout = new(get_turf(challenger), winnings)
		challenger.put_in_hands(payout)
		visible_message(span_greentext("[challenger] wins [winnings] caps!"))
		if(challenger.ckey)
			adjust_karma(challenger.ckey, 2)
		if(opponent.ckey)
			adjust_karma(opponent.ckey, -1)
	else if(opponent_roll > challenger_roll)
		var/winnings = bet * 2
		var/obj/item/stack/f13Cash/caps/payout = new(get_turf(opponent), winnings)
		opponent.put_in_hands(payout)
		visible_message(span_greentext("[opponent] wins [winnings] caps!"))
		if(opponent.ckey)
			adjust_karma(opponent.ckey, 2)
		if(challenger.ckey)
			adjust_karma(challenger.ckey, -1)
	else
		var/obj/item/stack/f13Cash/caps/C1 = new(get_turf(challenger), bet)
		challenger.put_in_hands(C1)
		var/obj/item/stack/f13Cash/caps/C2 = new(get_turf(opponent), bet)
		opponent.put_in_hands(C2)
		visible_message(span_notice("It's a tie! Bets returned."))
