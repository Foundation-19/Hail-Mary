/// A wall of wind-blown dust. It forms over dry, bare ground in the heat of the day and rolls downwind, hiding the horizon for everyone caught in it. It is a nuisance and a hazard to sight, not a killer
/datum/weather/sandstorm
	name = "sandstorm"
	desc = "A churning wall of dust sweeps across the wasteland on the wind, cutting visibility and stinging the eyes and lungs of anyone caught in it."
	probability = 15

	telegraph_message = span_warning("A churning brown wall of dust is rolling in on the wind. Cover your face and find shelter.")
	telegraph_duration = 600
	telegraph_overlay = "light_ash"
	telegraph_sound = 'sound/f13effects/sandstorm_warning.ogg'

	weather_message = span_warning("<i>The wall of dust hits, and the world vanishes behind a howling curtain of sand.</i>")
	weather_duration_lower = 1800
	weather_duration_upper = 3600
	weather_overlay = "ash_storm"
	weather_color = "#D9B27A"
	weather_sound = 'sound/f13effects/sandstorm_transition.ogg'

	end_message = span_notice("The howl of the wind dies down and the dust slowly thins and settles. You can see again.")
	end_duration = 1200
	end_overlay = "light_ash"
	end_sound = 'sound/f13effects/sandstorm_transition.ogg'

	area_types = list(
		/area/f13/wasteland,
		/area/f13/desert,
		/area/f13/farm,
		/area/f13/forest,
		)
	protect_indoors = TRUE
	target_trait = ZTRAIT_STATION
	tag_weather = WEATHER_SAND
	weather_family = "dust"
	conflicting_families = "fog precipitation"

	// Same protection as the ash storm, so golems, silicons and the like can walk through it
	immunity_type = "ash"
	is_dangerous = FALSE
	carbons_only = TRUE
	barometer_predictable = TRUE
	barometer_note = "a wall of dust is on the way, and will cut visibility to a fraction for anyone caught outside"

	obscures_sight = TRUE
	obscure_color = "#926D42"
	visibility_mult = 0.5
	// Goggles stop it stinging, but they do not clear the air, so half the loss of sight is left
	protected_view_loss = 0.5

	rotate_with_wind = TRUE
	cloud_shadow = 0.5
	cloud_cover_goal = 0.35
	climate_temp_shift = -3
	gust_message = span_warning("A hot, gritty gust hits you ahead of a brown wall on the horizon.")
	drift_speed = 0.3
	cell_radius_lower = 0.12
	cell_radius_upper = 0.22
	// It scours the ground it crosses, drying it and stripping what little cover it has
	soak_rate = -6
	vegetation_harm = 0.5
	// Dust gets lifted on hot afternoons, from ground that has not seen rain for a while
	phase_weights = "0.3 0.6 1 1.6 2 2 1 0.4 0.3"
	dryness_weight = 1

	var/datum/looping_sound/sandstorm_outside/sound_ao = new(list(), FALSE, TRUE)
	var/datum/looping_sound/sandstorm_inside/sound_ai = new(list(), FALSE, TRUE)

/datum/weather/sandstorm/Destroy()
	QDEL_NULL(sound_ao)
	QDEL_NULL(sound_ai)
	return ..()

/datum/weather/sandstorm/update_listeners(list/outside, list/inside)
	sound_ao.output_atoms = outside
	sound_ai.output_atoms = inside

/datum/weather/sandstorm/start()
	. = ..()
	sound_ao?.start()
	sound_ai?.start()

/datum/weather/sandstorm/wind_down()
	. = ..()
	sound_ao?.stop()
	sound_ai?.stop()

/datum/weather/sandstorm/end()
	. = ..()
	sound_ao?.stop()
	sound_ai?.stop()

/// Dust is lifted off dry, bare ground, and comes in from upwind, so of a few spots it picks the driest one that is furthest back along the wind
/datum/weather/sandstorm/pick_cell_centre(z)
	var/half_x = world.maxx * 0.5
	var/half_y = world.maxy * 0.5
	var/reach = max(1, min(world.maxx, world.maxy) * 0.5)
	var/wind_x = sin(SSweather.wind_angle)
	var/wind_y = cos(SSweather.wind_angle)
	var/turf/best
	var/best_score
	for(var/i in 1 to 12)
		var/turf/T = locate(rand(1, world.maxx), rand(1, world.maxy), z)
		if(!T || !impacted_areas[T.loc])
			continue
		var/upwind = clamp(-((T.x - half_x) * wind_x + (T.y - half_y) * wind_y) / reach, -1, 1)
		var/score = 1.5 * SSgeoclimate.get_local_dryness(T) + upwind + rand() * 0.3
		if(isnull(best_score) || score > best_score)
			best = T
			best_score = score
	return best

/datum/weather/sandstorm/weather_act(mob/living/L)
	var/mob/living/carbon/C = L
	var/scale = get_effect_scale(C)
	if(!C.has_dust_eye_protection() && prob(10 * scale))
		C.blur_eyes(4)
		to_chat(C, span_warning("Grit stings your eyes."))
	if(!C.has_dust_airway_protection() && prob(8 * scale))
		C.emote("cough")
		C.adjustStaminaLossBuffered(3 * scale)
