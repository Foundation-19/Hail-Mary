// Thingy launcher!

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/anykind
	name = "\improper Pheumonic launcher"
	desc = "A weapon for combat exosuits. anything loaded in it."
	icon_state = "mecha_grenadelnchr"
	projectile = null
	fire_sound = 'sound/weapons/grenadelaunch.ogg'
	projectiles = 0
	projectiles_cache = 15
	projectiles_cache_max = 20
	missile_speed = 1.5
	equip_cooldown = 10
	var/det_time = 20
	ammo_type = "Anything"
	var/list/obj/stuffs = new
	var/open = FALSE

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/anykind/action(target)
	if(!action_checks(target))
		return
	if(!stuffs.len)
		chassis.occupant_message("Nothing to shoot!")
		return
	var/obj/O = stuffs[1]
	playsound(chassis, fire_sound, 50, 1)
	mecha_log_message("Launched a [O.name] from [name], targeting [target].")
	stuffs -= stuffs[1]
	proj_init(O)
	var/turf/nextt = (get_turf(src))
	O.forceMove(nextt)
	O.throw_at(target, missile_range, missile_speed, chassis.occupant, FALSE, diagonals_first = diags_first)
	return 1

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/anykind/proj_init(obj/ammo)
	var/turf/T = get_turf(src)
	message_admins("[ADMIN_LOOKUPFLW(chassis.occupant)] fired a [src] in [ADMIN_VERBOSEJMP(T)]")
	log_game("[key_name(chassis.occupant)] fired a [src] in [AREACOORD(T)]")
	if(istype(ammo, /obj/item/grenade/))
		var/obj/item/grenade/payload = ammo
		addtimer(CALLBACK(payload, TYPE_PROC_REF(/obj/item/grenade, prime)), det_time)

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/anykind/attackby(obj/item/W, mob/user, params)
	if(open)
		if(stuffs.len < projectiles_cache_max)
			W.forceMove(src)
			stuffs += W
			projectiles++
		else
			to_chat(user, "The [src] is full!")
		return
	. = ..()

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/anykind/screwdriver_act(mob/living/carbon/user, obj/item/I)
	if(user.a_intent != INTENT_DISARM)
		if(open)
			to_chat(user, "<span class='notice'>You close the [src]!.</span>")
		else
			to_chat(user, "<span class='notice'>You open the [src]!.</span>")
		open = !open
		return TRUE
	. = ..()

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/anykind/attack_self(mob/user)
	if(open && stuffs.len)
		var/obj/selectedthing = input(user, "Chosee an item to take out.", "Stuffs inside") as null|anything in stuffs
		if(!selectedthing)
			return
		stuffs -= selectedthing
		projectiles--
		selectedthing.forceMove(get_turf(src))
		user.put_in_hand(selectedthing)
		return
	. = ..()

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/anykind/AltClick(mob/user)
	if(open && stuffs.len)
		for(var/obj/I in stuffs)
			I.forceMove(get_turf(src))
			stuffs -= I
			projectiles--
		to_chat(user, "<span class='notice'>You empty the [src]!.</span>")
		return
	. = ..()

// Frag-grenade launcher!

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/launcher/fragmentation
	name = "\improper SOB-3 grenade launcher"
	desc = "A weapon for combat exosuits. Launches primed fragmentation grenades."
	fire_sound = 'sound/weapons/grenadelaunch.ogg'
	projectiles = 8
	projectiles_cache = 8
	projectiles_cache_max = 8
	missile_speed = 1.5
	equip_cooldown = 10
	disabledreload = TRUE
	projectile = /obj/item/grenade/f13/frag
	equip_cooldown = 90
	ammo_type = "fragmentation"
