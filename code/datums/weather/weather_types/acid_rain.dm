/datum/weather/acid_rain
	name = "acid rain"
	desc = "The planet's thunderstorms are by nature acidic, and will incinerate anyone standing beneath them without protection."
	probability = 2

	telegraph_duration = 700
	telegraph_overlay = "acid_rain"
	telegraph_message = span_userdanger("Thunder rumbles far above. You hear droplets land around you, and audible fizzling can be heard as they make contact.. acid rain is coming.")
	telegraph_sound = 'sound/ambience/acidrain_start.ogg'

	weather_message = "<span class='userdanger'><i>Acidic rain pours down around you! Get inside!</i></span>"
	weather_overlay = "acid_rain"
	weather_duration_lower = 1200
	weather_duration_upper = 2400
	weather_sound = 'sound/ambience/acidrain_mid.ogg'

	end_duration = 100
	end_message = span_userdanger("The downpour gradually slows to a light shower. It should be safe outside now.")
	end_sound = 'sound/ambience/acidrain_end.ogg'

	tag_weather = WEATHER_ACID
	area_types = list(/area/f13/wasteland, /area/f13/desert, /area/f13/farm, /area/f13/forest)
	target_trait = ZTRAIT_STATION
	protect_indoors = TRUE

	immunity_type = "acid" // temp

	barometer_predictable = TRUE

	carbons_only = TRUE
	climate_temp_shift = 8
	visibility_mult = 0.8
	extinguishes_fires = TRUE

/datum/weather/acid_rain/weather_act(mob/living/L)
	// Acid armor shaves off the burn, but a little always gets through
	var/resist = clamp(L.getarmor(null, "acid"), 0, 75)
	L.adjustFireLoss(2 * (1 - resist / 100))

/* // Stops weather from cleaning the ground (though it still cleans mobs c:)
/datum/weather/acid_rain/weather_act_turf(turf/T)
	SEND_SIGNAL(T, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_MEDIUM)
	for(var/obj/effect/O in T)
		if(is_cleanable(O))
			qdel(O)
	for(var/obj/item/ammo_casing/C in T)
		qdel(C)
*/
