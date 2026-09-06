GLOBAL_LIST_EMPTY(eyebots)

/mob/living/simple_animal/hostile/eyebot/virtual
	var/mob/living/carbon/human/pilot

/mob/living/simple_animal/hostile/eyebot/virtual/New()
	. = ..()
	GLOB.eyebots += src
	src.verbs += /mob/living/simple_animal/hostile/eyebot/virtual/proc/leave

/mob/living/simple_animal/hostile/eyebot/virtual/Del()
	. = ..()
	GLOB.eyebots -= src

/mob/living/simple_animal/hostile/eyebot/virtual/proc/enter(mob/user)
	if(ckey)
		to_chat(user, "Eyebot already under control!")
		return

	pilot = user
	ckey = user.ckey

/mob/living/simple_animal/hostile/eyebot/virtual/proc/leave()
	set name = "Stop Control"
	set category = "EYEBOT"

	pilot.ckey = ckey

/mob/living/simple_animal/hostile/eyebot/virtual/death(gibbed)
	if(ckey)
		leave()

	GLOB.eyebots -= src

	..(gibbed)

/obj/machinery/computer/eyebots
	name = "eyebot console"
	desc = "Used to access eyebots."
	icon = 'icons/machines/terminals.dmi'
	icon_state = "enclave"
	icon_screen = "enclave_on"
	var/datum/browser/popup

/obj/machinery/computer/eyebots/New()
	..()

/obj/machinery/computer/eyebots/attack_hand(mob/user)
	popup = new(user, "vending", (name))
	popup.set_content(getBotsHTML())
	popup.open()

/obj/machinery/computer/eyebots/proc/control(Index)
	var/mob/living/simple_animal/hostile/eyebot/virtual/bot = GLOB.eyebots[Index]

	bot.enter(usr)
	popup.close()

/obj/machinery/computer/eyebots/proc/getBotsHTML()
	var/html
	for(var/I = 1 to GLOB.eyebots.len)
		var/mob/living/simple_animal/hostile/eyebot/virtual/bot = GLOB.eyebots[I]
		if(bot.stat != DEAD)
			html += "<a href='?src=\ref[src];control=[I]'>[bot.name]</a><br>"
	return html

/obj/machinery/computer/eyebots/Topic(href, href_list)
	if(..())
		return

	if(href_list["control"])
		control(text2num(href_list["control"]))
