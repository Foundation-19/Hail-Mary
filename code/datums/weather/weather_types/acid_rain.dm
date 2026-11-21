/datum/weather/acid_rain
	name = "acid rain"
	desc = "Acidic downpours that slowly burn anyone caught in the open. Brief dashes are survivable, and clothing, armor and shelter all help. It will not kill on its own."
	probability = 2

	telegraph_duration = 700
	// Ordinary-looking rain gathering overhead, same sprite the base rain type warns with.
	// There's no distinct "light acid rain" sprite, and painting the full acid_rain overlay
	// here would make the 70-second warning phase look identical to the real storm even
	// though acid_rain_tick() doesn't fire until MAIN_STAGE. A plain rain visual still reads
	// as "something's coming" without falsely implying it's already burning you.
	telegraph_overlay = "rain_gathering"
	telegraph_message = span_userdanger("Thunder rumbles far above. Droplets start to land around you and fizz as they touch the ground.. acid rain is coming. You have a minute to get under cover.")
	telegraph_sound = 'sound/ambience/acidrain_start.ogg'

	weather_message = "<span class='userdanger'><i>Acidic rain pours down around you! The longer you stay in the open the worse it burns. Get inside, or cover up!</i></span>"
	weather_overlay = "acid_rain"
	weather_duration_lower = 1200
	weather_duration_upper = 2400
	weather_sound = 'sound/ambience/acidrain_mid.ogg'

	end_duration = 100
	end_message = span_userdanger("The downpour gradually slows to a light shower. It should be safe outside now.")
	end_sound = 'sound/ambience/acidrain_end.ogg'
	end_overlay = "acid_rain"

	tag_weather = WEATHER_ACID
	weather_family = "precipitation"
	area_types = list(/area/f13/wasteland, /area/f13/desert, /area/f13/farm, /area/f13/forest)
	target_trait = ZTRAIT_STATION
	protect_indoors = TRUE

	immunity_type = "acid" // temp

	barometer_predictable = TRUE

	carbons_only = TRUE
	climate_temp_shift = 8
	cloud_shadow = 1
	gust_message = span_warning("A sharp, acrid gust blows ahead of the dark cloud. Something tastes wrong in the air.")
	lightning_rate = 0.03
	visibility_mult = 0.8
	extinguishes_fires = TRUE
	soak_rate = 8
	vegetation_harm = 3
	// A small, fast storm cell, so it can be outrun or waited out
	cell_radius_lower = 0.1
	cell_radius_upper = 0.17
	drift_speed = 0.2

/datum/weather/acid_rain/weather_act(mob/living/L)
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		H.acid_rain_tick()
		return
	// Other carbons just take a flat burn that acid armor shaves down
	var/resist = clamp(L.getarmor(null, "acid"), 0, 75)
	L.adjustFireLoss(1 * (1 - resist / 100))

/* // Stops weather from cleaning the ground (though it still cleans mobs c:)
/datum/weather/acid_rain/weather_act_turf(turf/T)
	SEND_SIGNAL(T, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_MEDIUM)
	for(var/obj/effect/O in T)
		if(is_cleanable(O))
			qdel(O)
	for(var/obj/item/ammo_casing/C in T)
		qdel(C)
*/
