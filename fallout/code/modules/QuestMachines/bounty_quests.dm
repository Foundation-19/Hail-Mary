/*
	Quest contain information about items needs to complete them.
	And reward in caps
*/
/datum/bounty_quest
	var/name = "Default Quest Name"
	var/desc = "Default Quest Description"
	var/employer = "Default Employer"

	/* This items needs to complete this quest */
	var/list/target_items = list()

	/* How many caps will spawned after quest complete */
	var/caps_reward = 10

	/* Will show to player, when quest is complete */
	var/end_message = "*Beep* Bounty requirements fulfilled. Payment dispensing.."

	var/need_message = "Need some items"

	var/employer_icon_folder = "icons/bounty_employers/"

	var/employer_icon = "employer_00.png"

/datum/bounty_quest/proc/ItsATarget(var/target)
	for(var/target_type in target_items)
		if(istype(target, target_type))
			return 1
	return 0

/datum/bounty_quest/proc/GetIconWithPath()
	return text2path("[employer_icon_folder][employer_icon]")

/datum/bounty_quest/faction/wasteland/qst_0
	name = "Wasteland Bounties"
	desc = "A list of bounties posted across the Texas wastes, automated by this old RobCo Messaging system."
	employer = "Jonah Orion, Red Water Caravans"
	employer_icon = "employermerc.png"
	need_message = "Ghouls keep attacking my caravans. I need you to kill ten of them, clear the wastes out a bit. Skin the face of each one you kill and bring ten of those back here as proof. I'll give you 800 caps for your trouble"
	end_message = "Superb job, thanks for that. Here's your caps"
	target_items = list(/mob/living/simple_animal/hostile/ghoul = 5)
	caps_reward = 850

/datum/bounty_quest/faction/wasteland/qst_1
	name = "Wasteland Bounties"
	employer = "Jonah Orion, Red Water Caravans"
	employer_icon = "employer_00.png"
	need_message = "A client of mine is looking for raw nuclear material. I need you to find and bring back one of those sealed pre-war waste barrels. Bring it to the pod and I'll throw 4000 caps your way"
	target_items = list(/obj/structure/reagent_dispensers/barrel/dangerous = 1)
	caps_reward = 280

/datum/bounty_quest/faction/wasteland/qst_2
	name = "Wasteland Bounties"
	employer = "George Miller, NCR Sharecropper Farming"
	employer_icon = "employer_00.png"
	need_message = "Goddamn molerats keep eating our crops. I need you to kill five of them. Bring back their tails as proof of the deed. I'll pay you 225 caps"
	end_message = "Thanks for that. Now I might be able to put some damn food on the table"
	target_items = list(/mob/living/simple_animal/hostile/molerat = 2)
	caps_reward = 60

/datum/bounty_quest/faction/wasteland/qst_3
	name = "Wasteland Bounties"
	employer = "Unknown 'Aspiring Doctor'"
	employer_icon = "employer_00.png"
	need_message = "I need you to bring me a body. A human one. Just the whole thing. For... dissection and study! I'm a doctor, you know. Let's make the price... 600 caps"
	end_message = "Mmhm, a prime cut. Thank you"
	target_items = list(/mob/living/simple_animal/hostile/ghoul = 1)
	caps_reward = 200

/datum/bounty_quest/faction/wasteland/qst_4
	name = "Wasteland Bounties"
	employer = "Hoi Chen, American"
	employer_icon = "employer_00.png"
	need_message = "Hello yes. I need gun, very American gun. You find for me, I pay you 500 caps. It is called Colt Model 733. Find for me quickly, for Chin- Uncle Sam and Hotdogs. Yes"
	end_message = "Hohoho! Thank you for this. I will use very well on those uh... commies, yes"
	target_items = list(/obj/item/organ/tongue = 3)
	caps_reward = 930

/datum/bounty_quest/faction/wasteland/qst_5
	name = "Wasteland Bounties"
	employer = "New California Republic, Department of Wildlife Management"
	employer_icon = "employer_00.png"
	need_message = "The New California Republic is on the way into Texas and we need the help of locals willing to help clear the path for a more civilized world. Our advanced scouts spotted a large concentration of Deathclaws across the Texas wastes and want to thin the herd a bit. Kill three deathclaws and bring back their largest right-handed talons. We are offering a bounty of 5000 caps for this one"
	target_items = list(/mob/living/simple_animal/hostile/deathclaw = 1)
	caps_reward = 304

/datum/bounty_quest/faction/wasteland/qst_6
	name = "Wasteland Bounties"
	employer = "Caesar's Legion"
	employer_icon = "employer_00.png"
	need_message = "Caesar's Legion seeks the aid of locals willing to serve mighty Caesar. We seek the death of the NCR dogs in the area. Bring us three of their dogtags and we will give you 800 caps"
	target_items = list(/obj/item/stack/sheet/animalhide = 5)
	caps_reward = 103

/datum/bounty_quest/faction/wasteland/qst_7
	name = "Wasteland Bounties"
	employer = "ERP-75"
	employer_icon = "employer_00.png"
	need_message = "Legion slavers have been spotted in the area. They are a nasty bunch, raping and pillaging what they don't just kill. We're looking to thin their numbers a bit before the mainstay of the NCR army arrives and are enlisting locals to help. Bring us three of Marks of Caesar from dead Legionnaires and we'll pay a bounty of 800 caps"
	target_items = list(/mob/living/carbon/human = 5)
	caps_reward = 324

/datum/bounty_quest/faction/wasteland/qst_8
	name = "Wasteland Bounties"
	employer = "Texas Wastes Bounty Board Management"
	employer_icon = "employer_00.png"
	need_message = "We're runing low on paper to print bounties. Bring us twenty sheets of paper and we'll pay you 200 caps"
	target_items = list(/mob/living/simple_animal/hostile/deathclaw = 2)
	caps_reward = 712

/datum/bounty_quest/faction/wasteland/qst_9
	name = "Wasteland Bounties"
	employer = "New California Republic, Department of War"
	employer_icon = "employer_00.png"
	need_message = "Legion slavers have been spotted in the area. They are a nasty bunch, raping and pillaging what they don't just kill. We're looking to thin their numbers a bit before the mainstay of the NCR army arrives and are enlisting locals to help. Bring us three of Marks of Caesar from dead Legionnaires and we'll pay a bounty of 800 caps"
	target_items = list(/obj/item/paper = 20)
	caps_reward = 78

/datum/bounty_quest/faction/wasteland/qst_10
	name = "Wasteland Bounties"
	employer = "Texas Wastes Bounty Board Management"
	employer_icon = "employer_08.png"
	need_message = "We're runing low on paper to print bounties. Bring us twenty sheets of paper and we'll pay you 200 caps"
	target_items = list(/obj/item/reagent_containers/food/snacks/grown/corn = 10)
	caps_reward = 59

/datum/bounty_quest/faction/wasteland/qst_11
	name = "Wasteland Bounties"
	employer = "New California Republic, Department of Agriculture"
	employer_icon = "employer_08.png"
	need_message = "The New California Republic is always expanding and this means we always have hungry mouths to feed. We've had a food shortage and desperately need corn, bring us thirty heads of corn and we'll pay 400 caps"
	target_items = list(/obj/item/reagent_containers/food/snacks/grown/corn = 30)
	caps_reward = 204

/datum/bounty_quest/faction/wasteland/qst_12
	name = "Wasteland Bounties"
	employer = "New California Republic, Department of Agriculture"
	employer_icon = "employer_08.png"
	need_message = "The New California Republic is always expanding and this means we always have hungry mouths to feed. Bring us ten carrots and we'll pay 50 caps"
	target_items = list(/obj/item/reagent_containers/food/snacks/grown/carrot = 10)
	caps_reward = 75

/datum/bounty_quest/faction/wasteland/qst_13
	name = "Wasteland Bounties"
	employer = "New California Republic, Department of Agriculture"
	employer_icon = "employer_00.png"
	need_message = "The New California Republic is always expanding and this means we always have hungry mouths to feed. We've had a food shortage and desperately need carrots, bring us thirty carrots and we'll pay 200 caps"
	target_items = list(/obj/item/reagent_containers/food/snacks/grown/carrot = 30)
	caps_reward = 302

/datum/bounty_quest/faction/wasteland/qst_14
	name = "Wasteland Bounties"
	employer = "Speed Slashin' Strikerz"
	employer_icon = "employer_00.png"
	need_message = "Hey, truce for now. How's this damn thing work? Oh. Like that. OK so, me and the boys are running low on that good shit. We're looking for some grown replacements, bring us ten cannabis leaves and we'll pay 300 caps"
	target_items = list(/obj/item/reagent_containers/food/snacks/grown/cannabis = 10)
	caps_reward = 302

/datum/bounty_quest/faction/wasteland/qst_15
	name = "Wasteland Bounties"
	employer = "Speed Slashin' Strikerz"
	employer_icon = "employer_00.png"
	need_message = "We're running real damn low on those cannabis leaves, they're addictive as hell. Bring us thirty leaves and we'll pay ya 1000 caps"
	target_items = list(/obj/item/reagent_containers/food/snacks/grown/cannabis = 30)
	caps_reward = 1203

/datum/bounty_quest/faction/wasteland/qst_16
	name = "Wasteland Bounties"
	employer = "Snake Vargas, N.C.R RANGERS"
	employer_icon = "employer_00.png"
	need_message = "Running low on chewin' 'bacco. Bring me ten tobacco leaves and I'll pay ya' 300 caps"
	target_items = list(/obj/item/reagent_containers/food/snacks/grown/tobacco = 10)
	caps_reward = 167

/datum/bounty_quest/faction/wasteland/qst_17
	name = "Wasteland Bounties"
	employer = "Hershel Greene"
	employer_icon = "employer_00.png"
	need_message = "I've got goddamn wolves moving in on my church. I need someone to clear them out. Bring me eight wolf tails as proof of the deed. I'll pay 275 caps"
	target_items = list(/mob/living/simple_animal/hostile/wolf = 3)
	caps_reward = 164

/datum/bounty_quest/faction/wasteland/qst_18
	name = "Wasteland Bounties"
	employer = "PSYCHO GIBBINS"
	employer_icon = "employer_00.png"
	need_message = "I NEED MY FIX MAN, 300 CAPS FOR A HIT OF PSYCHO, HIT ME UP"
	target_items = list(/obj/item/shard = 10)
	caps_reward = 91

/datum/bounty_quest/faction/wasteland/qst_19
	name = "Wasteland Bounties"
	employer = "New California Republic, Department of Wasteland Anatomy"
	employer_icon = "employer_00.png"
	need_message = "We've spotted some rad scorpions native to Texas, you'll spot them by their unique black colouration. Bring us one whole black radscorpion body, we'll pay 500 caps"
	target_items = list(/mob/living/simple_animal/hostile/radscorpion  = 2)
	caps_reward = 152

/datum/bounty_quest/faction/wasteland/qst_20
	name = "Wasteland Bounties"
	employer = "New California Republic, Department of Wasteland Anatomy"
	employer_icon = "employer_00.png"
	need_message = "We're looking to see if there's any difference between Texan deathclaws and the deathclaws back west, we'd like to dissect a body. Bring us a deathclaw corpse intact and we'll pay you 1200 caps"
	target_items = list(/obj/item/nuke_core = 1)
	caps_reward = 6500