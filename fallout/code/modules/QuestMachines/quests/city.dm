/datum/bounty_quest/faction/city/qst_0
	name = "Supply Disruptions"
	desc = "Welcome! Welcome! We are in a critical situation. Raiders attacked our settlement, we had to flee. Now we are in this damn hangar without food. If you send us food, we will give you all our covers! Please, we in a critical situation! "
	employer = "Settler of Chicago"
	employer_icon = "employer_00.png"
	need_message = "50 units of food (corn, potatoes, etc.))"
	end_message = "Thanks a lot! Now we can sit it all out full!"
	target_items = list(/obj/item/reagent_containers/food/snacks/grown = 50)
	caps_reward = 1500

/datum/bounty_quest/faction/city/qst_1
	name = "Experiments on rats"
	desc = "We're continuing to study the effects of radiation on animals here. The data from your area is very interesting. Send us more rats."
	employer = "Academic Council"
	employer_icon = "employer_00.png"
	need_message = "8 Mole Rats"
	end_message = "That's what you need! Keep the covers!"
	target_items = list(/mob/living/simple_animal/hostile/molerat = 8)
	caps_reward = 2000

/datum/bounty_quest/faction/city/qst_2
	name = "Experiments on nature"
	desc = "We're continuing to study the effects of radiation on animals and now plants. Send us a cannabis sample. I wonder how it could mutate in your area."
	employer = "Academic Council"
	employer_icon = "employer_00.png"
	need_message = "5 Cannabis Leaves"
	end_message = "That's what you need! Keep the covers!"
	target_items = list(/obj/item/reagent_containers/food/snacks/grown/cannabis = 5)
	caps_reward = 1000

/datum/bounty_quest/faction/city/qst_3
	name = "Kitten named Flashy"
	desc = "Have you seen my kitten? I lost it when I was passing through your town."
	employer = "Lov Wildheld"
	employer_icon = "employer_00.png"
	need_message = "Lovas' Kitten"
	end_message = "Thank you for finding my kitten!"
	target_items = list(/mob/living/simple_animal/pet/cat/kitten = 1)
	caps_reward = 555
