#define TRUCE 1
#define COLD_WAR 2
#define HOT_WAR 3


GLOBAL_VAR_INIT(warstate_bos, COLD_WAR)
GLOBAL_VAR_INIT(warstate_enc, COLD_WAR)
GLOBAL_VAR_INIT(warstate_glob, COLD_WAR)

/obj/structure/warmachine
	name = "Warstate Announcement Device"
	desc = "This device is used to change the state of war. It's set to the highest state of war, and changing the war state will announce the result to the wasteland.."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "warmachine"
	plane = ABOVE_WALL_PLANE
	req_access = list(ACCESS_KEYCARD_AUTH)
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/structure/warmachine/attackby(obj/item/I, mob/living/user, params)
	if(istype(I,/obj/item/warcard/war))
		to_chat(user, "<span class='notice'>You swipe your access card, setting your faction's state to Open War.</span>")
		GLOB.warstate_bos = HOT_WAR
	else if(istype(I,/obj/item/warcard/coldwar))
		to_chat(user, "<span class='notice'>You swipe your access card, setting your faction's state to Cold War.</span>")
		GLOB.warstate_bos = COLD_WAR
	else if(istype(I,/obj/item/warcard/truce))
		to_chat(user, "<span class='notice'>You swipe your access card, setting your faction's state to call a truce.</span>")
		GLOB.warstate_bos = TRUCE

	if(GLOB.warstate_bos>GLOB.warstate_enc)
		change_state()

TYPE_PROC_REF(/obj/structure/warmachine, change_state)()
	//touch it only if it's bigger
	if(GLOB.warstate_bos > GLOB.warstate_enc)
		GLOB.warstate_glob = GLOB.warstate_bos
		announcewar()
	else if(GLOB.warstate_bos == TRUCE && GLOB.warstate_enc == TRUCE)
		GLOB.warstate_glob = TRUCE
		to_chat(world, "<span class='big bold'>A truce has been signed between The United States Government and the Brotherhood of Steel.</span>")

TYPE_PROC_REF(/obj/structure/warmachine, announcewar)()
	switch(GLOB.warstate_glob)
		if(COLD_WAR)
			to_chat(world, "<span class='big bold'>The United States Government and the Brotherhood of Steel are now engaged in a cold war.</span>")
		if(HOT_WAR)
			to_chat(world, "<span class='big bold'>The United States Government and the Brotherhood of Steel are now engaged in open war.</span>")


/obj/structure/warmachine/enclave/attackby(obj/item/I, mob/living/user, params)
	if(istype(I,/obj/item/warcard/war))
		to_chat(user, "<span class='notice'>You swipe your access card, setting your faction's state to Open War.</span>")
		GLOB.warstate_enc = HOT_WAR
	else if(istype(I,/obj/item/warcard/coldwar))
		to_chat(user, "<span class='notice'>You swipe your access card, setting your faction's state to Cold War.</span>")
		GLOB.warstate_enc = COLD_WAR
	else if(istype(I,/obj/item/warcard/truce))
		to_chat(user, "<span class='notice'>You swipe your access card, setting your faction's state to call a truce.</span>")
		GLOB.warstate_enc = TRUCE

	if(GLOB.warstate_enc>GLOB.warstate_bos)
		change_state()


/obj/structure/warmachine/enclave/change_state()
	//touch it only if it's bigger
	if(GLOB.warstate_enc > GLOB.warstate_bos)
		GLOB.warstate_glob = GLOB.warstate_enc
		announcewar()
	else if(GLOB.warstate_bos == TRUCE && GLOB.warstate_enc == TRUCE)
		GLOB.warstate_glob = TRUCE
		to_chat(world, "<span class='big bold'>A truce has been signed between The United States Government and the Brotherhood of Steel.</span>")

/obj/item/warcard/war
	name = "War declariation card"
	desc = "This is a card used to initiate war."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "war"

/obj/item/warcard/coldwar
	name = "Cold War declariation card"
	desc = "This is a card used to initiate a cold war."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "coldwar"

/obj/item/warcard/truce
	name = "truce declariation card"
	desc = "This is a card used to initiate a truce."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "truce"


