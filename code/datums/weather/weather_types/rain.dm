/datum/weather/rain
	name = "rain"
	desc = "Rain will fall on the Wasteland, cleaning it."
	probability = 15

	telegraph_duration = 300
	telegraph_overlay = "rain_gathering"
	telegraph_message = "<span class='notice'><font size=2>You hear a rainstorm gathering on the horizon.</font></span>"
	telegraph_sound = 'sound/weather/thunder.ogg' //credit: boomlibrary

	weather_message = "<span class='notice'><i>You hear the crack of thunder as the rainstorm grows.</i></span>"
	weather_overlay = "thunderstorm"
	weather_duration_lower = 2400
	weather_duration_upper = 7200
	end_sound = 'sound/weather/thunder.ogg' //credit: boomlibrary
	end_duration = 250
	end_message = "<span class='notice'><font size=2>You start to hear the last of the rain as the sky begins to clear up.</font></span>"
	end_overlay = "rain_gathering"
	tag_weather = WEATHER_RAIN
	weather_family = "precipitation"
	area_types = list(/area/f13/wasteland, /area/f13/desert, /area/f13/farm, /area/f13/forest)
	protected_areas = list(/area/shuttle)
	target_trait = ZTRAIT_STATION
	protect_indoors = TRUE
	immunity_type = "water"
	is_dangerous = FALSE // thankfully our slimes dont mind water

	barometer_predictable = TRUE

	affects_turfs = TRUE
	carbons_only = TRUE
	climate_temp_shift = -4
	visibility_mult = 0.85
	wetness_rate = 3
	extinguishes_fires = TRUE
	cloud_shadow = 1
	cloud_cover_goal = 0.9
	cloud_weight = 0.6
	gust_message = span_notice("A cool gust of damp air rushes ahead of the storm, smelling of wet earth.")
	lightning_rate = 0.04
	wet_ground_time = 5 MINUTES
	turf_reapply_interval = 4 MINUTES
	soak_rate = 14
	animals_seek_shelter = TRUE
	// Rain falls from a cloud that drifts along with the wind
	cell_radius_lower = 0.18
	cell_radius_upper = 0.3
	drift_speed = 0.12

	var/datum/looping_sound/rain_sounds/sound_ao = new(list(), FALSE, TRUE)
	var/datum/looping_sound/indoor_rain_sounds/sound_ai = new(list(), FALSE, TRUE)

/datum/weather/rain/Destroy()
	QDEL_NULL(sound_ao)
	QDEL_NULL(sound_ai)
	return ..()

/datum/weather/rain/eventarea
	area_types = list(/area/f13/wasteland/event)
	probability = 0
	target_trait = ZTRAIT_AWAY
	weather_duration_lower = 18000
	weather_duration_upper = 18000
	localized = FALSE

/// Only the event zone gets this rain, not every area tagged for rain
/datum/weather/rain/eventarea/filter_impacted_areas()
	for(var/area/A as anything in impacted_areas.Copy())
		if(!is_path_in_list(A.type, area_types))
			impacted_areas -= A

/datum/weather/rain/weather_act(mob/living/L)
	if(iscarbon(L))
		var/mob/living/carbon/C = L
		SEND_SIGNAL(C, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
		C.wash_cream()
		C.ExtinguishMob()
		C.adjust_fire_stacks(-20) //Douse ourselves with water to avoid fire more easily
		C.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
		for(var/obj/item/I in C.held_items)
			wash_obj(I)
		if(C.back)
			if(wash_obj(C.back))
				C.update_inv_back(0)

		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			H.adjust_climate_wetness(wetness_rate)
			var/washgloves = TRUE
			var/washshoes = TRUE
			var/washmask = TRUE
			var/washears = TRUE
			var/washglasses = TRUE

			if(H.wear_suit)
				washgloves = !(H.wear_suit.flags_inv & HIDEGLOVES)
				washshoes = !(H.wear_suit.flags_inv & HIDESHOES)
			if(H.head)
				washmask = !(H.head.flags_inv & HIDEMASK)
				washglasses = !(H.head.flags_inv & HIDEEYES)
				washears = !(H.head.flags_inv & HIDEEARS)
			if(H.wear_mask)
				if(washears)
					washears = !(H.wear_mask.flags_inv & HIDEEARS)
				if(washglasses)
					washglasses = !(H.wear_mask.flags_inv & HIDEEYES)
			if(H.head && wash_obj(H.head))
				H.update_inv_head()
			if(H.wear_suit && wash_obj(H.wear_suit))
				H.update_inv_wear_suit()
			else if(H.w_uniform && wash_obj(H.w_uniform))
				H.update_inv_w_uniform()
			if(washgloves)
				SEND_SIGNAL(H, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
			if(H.shoes && washshoes && wash_obj(H.shoes))
				H.update_inv_shoes()
			if(H.wear_mask && washmask && wash_obj(H.wear_mask))
				H.update_inv_wear_mask()
			else if(H.lip_style)
				H.lip_style = null
				H.update_body()
			if(H.glasses && washglasses && wash_obj(H.glasses))
				H.update_inv_glasses()
			if(H.ears && washears && wash_obj(H.ears))
				H.update_inv_ears()
			if(H.belt && wash_obj(H.belt))
				H.update_inv_belt()
		CHECK_TICK

/datum/weather/rain/weather_act_turf(turf/open/T)
/* // Stops weather from cleaning the ground (though it still cleans mobs c:)
	var/cleaned
	if(!cleaned)
		for(var/obj/effect/decal/O in T) //Clean cleanable decals in affected areas
			if(is_cleanable(O))
				qdel(O)
				cleaned = 1
				CHECK_TICK
*/
	for(var/obj/effect/decal/cleanable/blood/B in T)
		qdel(B)
		CHECK_TICK

	for(var/obj/machinery/hydroponics/tray in T) // Makes it so plants get water from rain :o
		tray.adjustWater(80)
		CHECK_TICK

	SSweather.wet_turf(T, wet_ground_time)

/// Trays are watered wherever the rain reaches them, not only near players, so crops left alone do not dry out under a storm
/datum/weather/rain/sweep_remote()
	for(var/obj/machinery/hydroponics/tray as anything in GLOB.plant_bins)
		var/turf/T = get_turf(tray)
		if(!T || !impacted_areas[T.loc])
			continue
		var/last_acted = turfs_done[T]
		if(last_acted && (!turf_reapply_interval || world.time < last_acted + turf_reapply_interval))
			continue
		for(var/datum/weather_cell/C as anything in unique_cells)
			if((T.z in C.z_levels) && C.covers(T))
				turfs_done[T] = world.time
				tray.adjustWater(80)
				break
		CHECK_TICK

/datum/weather/rain/proc/wash_obj(obj/O)
	. = SEND_SIGNAL(O, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
	O.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
	if(isitem(O))
		var/obj/item/I = O
		I.acid_level = 0
		I.extinguish()



/datum/weather/rain/update_listeners(list/outside, list/inside)
	sound_ao.output_atoms = outside
	sound_ai.output_atoms = inside

/datum/weather/rain/start()
	. = ..()
	sound_ao?.start()
	sound_ai?.start()

/datum/weather/rain/end()
	. = ..()
	sound_ao?.stop()
	sound_ai?.stop()
