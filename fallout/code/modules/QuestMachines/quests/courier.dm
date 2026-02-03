/datum/bounty_quest/faction/courier/qst_0
	name = "The errand boy"
	desc = "Here's another parcel, you know what to do."
	employer = "Post Office"
	employer_icon = "employer_00.png"
	need_message = "Deliver the package and return the stamp."
	end_message = "The Postal Service is proud of you!"
	target_items = list(/obj/item/mark = 1)
	caps_reward = 500
	bonus_need_message = "Bonus: return a contraband tag with the stamp."
	bonus_end_message = "Clean run. The sorting office will remember you."
	bonus_items = list(/obj/item/contraband_tag = 1)
	bonus_reward = 250
	chain_name = "Parcel Run"
	stage_index = 1
	stage_total = 2
	next_stage_type = /datum/bounty_quest/faction/courier/qst_1
	courier_rep_reward = 3

/datum/bounty_quest/faction/courier/qst_1
	name = "Signed Receipt"
	desc = "Return the signed receipt to complete the job."
	employer = "Post Office"
	employer_icon = "employer_00.png"
	need_message = "Bring back a courier receipt from the recipient."
	end_message = "Job closed. Keep the routes moving."
	target_items = list(/obj/item/courier_receipt = 1)
	caps_reward = 200
	chain_name = "Parcel Run"
	stage_index = 2
	stage_total = 2
	courier_rep_reward = 2
