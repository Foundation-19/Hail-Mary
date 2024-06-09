var/list/eyebots = list()

/mob/living/simple_animal/hostile/eyebot/virtual
	name = "Brotherhood Eyebot"
	desc = "An eyebot reprogrammed and repurposed by brotherhood scribes for Reconnaissance work, Useful in a skirmish."
	maxHealth = 65
	health = 65
	peaceful = TRUE
	faction = list(FACTION_BROTHERHOOD)
	turns_per_move = -1
	var/mob/living/carbon/human/pilot

/mob/living/simple_animal/hostile/eyebot/virtual/floatingeye
	name = "Brotherhood Floating Eyebot"
	desc = "A quick-observation robot reprogrammed and repurposed by brotherhood scribes, Not very deadly, And not very tough, But is armed with a debilitating ranged electrode taser."
	maxHealth = 35
	health = 35
	peaceful = TRUE
	faction = list(FACTION_BROTHERHOOD)
	icon = 'icons/fallout/mobs/robots/eyebots.dmi'
	icon_state = "floatingeye"
	icon_living = "floatingeye"
	icon_dead = "floatingeye_d"
	projectiletype = /obj/item/projectile/energy/electrode
	projectilesound = 'sound/weapons/resonator_blast.ogg'

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
	desc = "Used to access eyebots. (Type stop-control to leave an eyebot.)"
	icon = 'icons/fallout/machines/terminals.dmi'
	icon_state = "advanced"
	icon_screen = "advanced_on"
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
