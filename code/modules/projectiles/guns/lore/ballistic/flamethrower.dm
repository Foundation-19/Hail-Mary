//The ammo/gun is stored in a back slot item
/obj/item/m2flamethrowertank
	name = "backpack fuel tank"
	desc = "The massive pressurized fuel tank for a M2 Flamethrower."
	icon = 'icons/obj/guns/flamethrower.dmi'
	icon_state = "m2_flamethrower_back"
	item_state = "m2_flamethrower_back"
	lefthand_file = 'icons/mob/inhands/equipment/backpack_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/backpack_righthand.dmi'
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_HUGE
	var/obj/item/gun/ballistic/m2flamethrower/gun
	var/armed = 0 //whether the gun is attached, 0 is attached, 1 is the gun is wielded.
	var/overheat = 0
	var/overheat_max = 12
	var/heat_diffusion = 2
	///liquid fuel units consumed from a reagent container (real jerry cans, drums, etc.) per shot's worth of napalm loaded
	var/reagent_per_shot = 5

/obj/item/m2flamethrowertank/Initialize()
	. = ..()
	gun = new(src)
	START_PROCESSING(SSobj, src)

/obj/item/m2flamethrowertank/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/m2flamethrowertank/process()
	overheat = max(0, overheat - heat_diffusion)

/obj/item/m2flamethrowertank/on_attack_hand(mob/living/carbon/user)
	if(src.loc == user)
		if(!armed)
			if(user.get_item_by_slot(SLOT_BACK) == src)
				armed = 1
				if(!user.put_in_hands(gun))
					armed = 0
					to_chat(user, span_warning("You need a free hand to hold the gun!"))
					return
				update_icon()
				user.update_inv_back()
		else
			to_chat(user, span_warning("You are already holding the gun!"))
	else
		..()

/obj/item/m2flamethrowertank/attackby(obj/item/W, mob/user, params)
	if(W == gun) //Don't need armed check, because if you have the gun assume its armed.
		user.dropItemToGround(gun, TRUE)
	else if(gun && istype(W, /obj/item/reagent_containers) && W.reagents?.has_reagent(/datum/reagent/fuel))
		pour_liquid_fuel(W, user) //real liquid fuel, like a real jerry can - no shell-box nonsense required
	else if(gun && (istype(W, /obj/item/ammo_box) || istype(W, /obj/item/ammo_casing)))
		gun.attackby(W, user, params) //let players refuel via the backpack tank, not just the drawn gun
	else
		..()

///pour raw liquid fuel from any reagent container directly into the gun's magazine - no special ammo box needed
/obj/item/m2flamethrowertank/proc/pour_liquid_fuel(obj/item/reagent_containers/can, mob/user)
	var/obj/item/ammo_box/magazine/mag = gun?.magazine
	if(!mag)
		return
	var/space = mag.max_ammo - length(mag.stored_ammo)
	if(space <= 0)
		to_chat(user, span_warning("[gun] is already full of fuel!"))
		return
	var/available = can.reagents.get_reagent_amount(/datum/reagent/fuel)
	var/shots = min(space, round(available / reagent_per_shot))
	if(shots <= 0)
		to_chat(user, span_warning("There's not enough fuel left in [can] to load [gun]."))
		return
	can.reagents.remove_reagent(/datum/reagent/fuel, shots * reagent_per_shot)
	for(var/i in 1 to shots)
		mag.stored_ammo += new mag.ammo_type(mag)
	to_chat(user, span_notice("You pour [shots * reagent_per_shot] unit\s of fuel into [gun]! ([length(mag.stored_ammo)]/[mag.max_ammo])"))
	playsound(src, 'sound/effects/refill.ogg', 50, 1)
	gun.update_icon()

/obj/item/m2flamethrowertank/dropped(mob/user)
	. = ..()
	if(armed)
		user.dropItemToGround(gun, TRUE)

/obj/item/m2flamethrowertank/MouseDrop(atom/over_object)
	. = ..()
	if(armed)
		return
	if(iscarbon(usr))
		var/mob/M = usr

		if(!over_object)
			return

		if(!M.incapacitated())

			if(istype(over_object, /obj/screen/inventory/hand))
				var/obj/screen/inventory/hand/H = over_object
				M.putItemFromInventoryInHandIfPossible(src, H.held_index)


/obj/item/m2flamethrowertank/update_icon_state()
	if(armed)
		icon_state = "m2_flamethrower_back"
	else
		icon_state = "m2_flamethrower_back"

/obj/item/m2flamethrowertank/proc/attach_gun(mob/user)
	if(!gun)
		gun = new(src)
	gun.forceMove(src)
	armed = 0
	if(user)
		to_chat(user, span_notice("You attach the [gun.name] to the [name]."))
	else
		src.visible_message(span_warning("The [gun.name] snaps back onto the [name]!"))
	update_icon()
	user.update_inv_back()


/obj/item/gun/ballistic/m2flamethrower
	name = "\improper M2 Flamethrower"
	desc = "A pre-war M2 Flamethrower, commonly found in National Guard armoies. This one has NCR armory markings and is issued to combat engineers."
	icon = 'icons/obj/guns/flamethrower.dmi'
	icon_state = "m2_flamethrower_on"
	item_state = "m2flamethrower"
	weapon_class = WEAPON_CLASS_RIFLE
	flags_1 = CONDUCT_1
	slowdown = 0.3
	slot_flags = null
	w_class = WEIGHT_CLASS_HUGE
	custom_materials = null
	fire_delay = 2
	weapon_weight = GUN_TWO_HAND_ONLY
	fire_sound = 'sound/weapons/flamethrower.ogg'
	mag_type = /obj/item/ammo_box/magazine/internal/m2flamethrower
	casing_ejector = FALSE
	item_flags = SLOWS_WHILE_IN_HAND
	dryfire_text = "*sputter* - out of fuel! Pour liquid fuel from a jerry can into the tank to refuel."
	var/obj/item/m2flamethrowertank/ammo_pack
	//a real flamethrower is a continuous stream while the trigger's held, not a burst-and-wait - hold the mouse down to hose an area
	init_firemodes = list(
		/datum/firemode/automatic/rpm200
	)

/obj/item/gun/ballistic/m2flamethrower/Initialize()
	if(istype(loc, /obj/item/m2flamethrowertank)) //We should spawn inside an ammo pack so let's use that one.
		ammo_pack = loc
	else
		return INITIALIZE_HINT_QDEL //No pack, no gun

	return ..()

//also accept liquid fuel poured directly onto the gun itself, not just the backpack tank
/obj/item/gun/ballistic/m2flamethrower/attackby(obj/item/W, mob/user, params)
	if(ammo_pack && istype(W, /obj/item/reagent_containers) && W.reagents?.has_reagent(/datum/reagent/fuel))
		ammo_pack.pour_liquid_fuel(W, user)
		return
	. = ..()

//one-click refuel: activating the gun in-hand grabs any fuel source on you (a real jerry can, drum, whatever) and tops off the tank, no fiddly clicking required
/obj/item/gun/ballistic/m2flamethrower/attack_self(mob/living/user)
	if(!magazine)
		return
	if(magazine.ammo_count() >= magazine.max_ammo)
		to_chat(user, span_notice("[src] is already full of fuel!"))
		return
	var/obj/item/reagent_containers/can = locate() in user
	if(can?.reagents?.has_reagent(/datum/reagent/fuel))
		attackby(can, user)
		return
	var/obj/item/ammo_box/jerrycan/J = locate() in user
	if(!J)
		to_chat(user, span_warning("You don't have any liquid fuel to refuel [src] with!"))
		return
	attackby(J, user)

/obj/item/gun/ballistic/m2flamethrower/dropped(mob/user)
	. = ..()
	if(ammo_pack)
		ammo_pack.attach_gun(user)
	else
		qdel(src)

/obj/item/gun/ballistic/m2flamethrower/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, stam_cost = 0)
	if(ammo_pack)
		if(ammo_pack.overheat < ammo_pack.overheat_max)
			ammo_pack.overheat += burst_size
			..()
		else
			to_chat(user, "The flamethrower is extremely hot! You shouldn't fire it anymore or it might blow up!.")

/obj/item/gun/ballistic/m2flamethrower/afterattack(atom/target, mob/living/user, flag, params)
	if(!ammo_pack || ammo_pack.loc != user)
		to_chat(user, "You need the backpack fuel tank to fire the gun!")
	. = ..()

/obj/item/gun/ballistic/m2flamethrower/dropped(mob/living/user)
	. = ..()
	ammo_pack.attach_gun(user)
