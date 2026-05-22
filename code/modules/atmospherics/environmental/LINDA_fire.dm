

/atom/proc/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	return null

#define FIRE_SPREAD_RANGE 1
#define FIRE_BURN_DAMAGE 20
#define FIRE_OBJECT_DAMAGE 30
#define FIRE_SPREAD_CHANCE 30
#define FIRE_DECAY_RATE 0.04
#define FIRE_MIN_STACKS_TO_SPREAD 2
#define FIRE_SPREAD_TEMP_THRESHOLD (FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 50)

/turf/proc/hotspot_expose(exposed_temperature, exposed_volume, soh = 0)
	if(exposed_temperature < FIRE_MINIMUM_TEMPERATURE_TO_EXIST)
		return
	if(exposed_volume < 25)
		return
	if(active_hotspot)
		if(soh && active_hotspot.temperature < exposed_temperature)
			active_hotspot.temperature = exposed_temperature
		return
	active_hotspot = new /obj/effect/hotspot(src, exposed_volume, exposed_temperature)

/turf/open/hotspot_expose(exposed_temperature, exposed_volume, soh = 0)
	..()

/obj/effect/hotspot
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	icon = 'icons/effects/fire.dmi'
	icon_state = "1"
	layer = GASFIRE_LAYER
	light_range = LIGHT_RANGE_FIRE
	light_color = LIGHT_COLOR_FIRE
	blend_mode = BLEND_ADD

	var/volume = 125
	var/temperature = FIRE_MINIMUM_TEMPERATURE_TO_EXIST
	var/bypassing = FALSE
	var/visual_update_tick = 0
	var/duration = 200
	var/ticks = 0

/obj/effect/hotspot/Initialize(mapload, starting_volume, starting_temperature)
	. = ..()
	if(!isnull(starting_volume))
		volume = starting_volume
	if(!isnull(starting_temperature))
		temperature = starting_temperature
	perform_exposure()
	setDir(pick(GLOB.cardinals))
	START_PROCESSING(SSobj, src)

/obj/effect/hotspot/Destroy()
	STOP_PROCESSING(SSobj, src)
	set_light(0)
	var/turf/T = loc
	if(istype(T) && T.active_hotspot == src)
		T.active_hotspot = null
	return ..()

/obj/effect/hotspot/process()
	var/turf/location = loc
	if(!istype(location))
		qdel(src)
		return

	ticks++
	if(ticks >= duration)
		qdel(src)
		return

	if(temperature < FIRE_MINIMUM_TEMPERATURE_TO_EXIST || volume <= 1)
		qdel(src)
		return

	perform_exposure()

	volume -= FIRE_DECAY_RATE * volume
	temperature -= 3

	if(volume > CELL_VOLUME * 0.95)
		icon_state = "3"
		if(istype(location, /turf/open))
			location.burn_tile()
	else if(volume > CELL_VOLUME * 0.4)
		icon_state = "2"
	else
		icon_state = "1"

	if((visual_update_tick++ % 7) == 0)
		update_color()

	if(prob(FIRE_SPREAD_CHANCE) && temperature > FIRE_SPREAD_TEMP_THRESHOLD)
		for(var/t in RANGE_TURFS(FIRE_SPREAD_RANGE, location))
			var/turf/T = t
			if(T == location)
				continue
			if(!T.active_hotspot && istype(T, /turf/open))
				var/has_flammable = FALSE
				for(var/obj/item/I in T)
					if(I.resistance_flags & FLAMMABLE)
						has_flammable = TRUE
						break
				for(var/obj/structure/S in T)
					if(S.resistance_flags & FLAMMABLE)
						has_flammable = TRUE
						break
				for(var/mob/living/L in T)
					if(L.on_fire)
						has_flammable = TRUE
						break
				if(has_flammable || prob(15))
					T.hotspot_expose(temperature * 0.7, volume / 2)

	return TRUE

/obj/effect/hotspot/proc/perform_exposure()
	var/turf/location = loc
	if(!istype(location))
		return

	location.active_hotspot = src

	for(var/A in location)
		var/atom/AT = A
		if(!QDELETED(AT) && AT != src)
			AT.fire_act(temperature, volume)
	return

/obj/effect/hotspot/proc/gauss_lerp(x, x1, x2)
	var/b = (x1 + x2) * 0.5
	var/c = (x2 - x1) / 6
	return NUM_E ** -((x - b) ** 2 / (2 * c) ** 2)

/obj/effect/hotspot/proc/update_color()
	cut_overlays()

	var/heat_r = heat2colour_r(temperature)
	var/heat_g = heat2colour_g(temperature)
	var/heat_b = heat2colour_b(temperature)
	var/heat_a = 255
	var/greyscale_fire = 1

	if(temperature < 5000)
		var/normal_amt = gauss_lerp(temperature, 1000, 3000)
		heat_r = LERP(heat_r,255,normal_amt)
		heat_g = LERP(heat_g,255,normal_amt)
		heat_b = LERP(heat_b,255,normal_amt)
		heat_a -= gauss_lerp(temperature, -5000, 5000) * 128
		greyscale_fire -= normal_amt
	if(temperature > 40000)
		var/purple_amt = temperature < LERP(40000,200000,0.5) ? gauss_lerp(temperature, 40000, 200000) : 1
		heat_r = LERP(heat_r,255,purple_amt)

	set_light(l_color = rgb(LERP(250,heat_r,greyscale_fire),LERP(160,heat_g,greyscale_fire),LERP(25,heat_b,greyscale_fire)))

	heat_r /= 255
	heat_g /= 255
	heat_b /= 255

	color = list(LERP(0.3, 1, 1-greyscale_fire) * heat_r,0.3 * heat_g * greyscale_fire,0.3 * heat_b * greyscale_fire, 0.59 * heat_r * greyscale_fire,LERP(0.59, 1, 1-greyscale_fire) * heat_g,0.59 * heat_b * greyscale_fire, 0.11 * heat_r * greyscale_fire,0.11 * heat_g * greyscale_fire,LERP(0.11, 1, 1-greyscale_fire) * heat_b, 0,0,0)
	alpha = heat_a

/obj/effect/hotspot/singularity_pull()
	return

/obj/effect/dummy/lighting_obj/moblight/fire
	name = "fire"
	light_color = LIGHT_COLOR_FIRE
	light_range = LIGHT_RANGE_FIRE

#undef FIRE_SPREAD_RANGE
#undef FIRE_BURN_DAMAGE
#undef FIRE_OBJECT_DAMAGE
#undef FIRE_SPREAD_CHANCE
#undef FIRE_DECAY_RATE
#undef FIRE_MIN_STACKS_TO_SPREAD
#undef FIRE_SPREAD_TEMP_THRESHOLD
