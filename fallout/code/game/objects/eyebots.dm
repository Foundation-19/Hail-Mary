var/list/eyebots = list()

/mob/living/simple_animal/hostile/eyebot/virtual
	var/mob/living/carbon/human/pilot

/mob/living/simple_animal/hostile/eyebot/virtual/New()
	. = ..()
	eyebots += src
	src.verbs += /mob/living/simple_animal/hostile/eyebot/virtual/proc/leave

/mob/living/simple_animal/hostile/eyebot/virtual/Del()
	. = ..()
	eyebots -= src

/mob/living/simple_animal/hostile/eyebot/virtual/proc/enter(var/mob/user)
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

	eyebots -= src

	..(gibbed)

/obj/machinery/computer/eyebots
	name = "eyebot console"
	desc = "Used to access eyebots."
	icon = 'icons/fallout/machines/terminals.dmi'
	icon_state = "enclave"
	icon_screen = "enclave_on"
	var/datum/browser/popup

/obj/machinery/computer/eyebots/New()
	..()

/obj/machinery/computer/eyebots/attack_hand(mob/user)
	popup = new(user, "vending", (name))
	popup.set_content(getBotsHTML())
	popup.open()

/obj/machinery/computer/eyebots/proc/control(var/Index)
	var/mob/living/simple_animal/hostile/eyebot/virtual/bot = eyebots[Index]

	bot.enter(usr)
	popup.close()

/obj/machinery/computer/eyebots/proc/getBotsHTML()
	var/html
	for(var/I = 1 to eyebots.len)
		var/mob/living/simple_animal/hostile/eyebot/virtual/bot = eyebots[I]
		if(bot.stat != DEAD)
			html += "<a href='?src=\ref[src];control=[I]'>[bot.name]</a><br>"
	return html

/obj/machinery/computer/eyebots/Topic(href, href_list)
	if(..())
		return

	if(href_list["control"])
		control(text2num(href_list["control"]))
