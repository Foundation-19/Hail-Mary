/// Fog is damp air, not falling water, so it stands on its own instead of inheriting rain's washing, dousing and sound loops
/datum/weather/fog
	name = "fog"
	desc = "A thick fog rolls over the Wasteland, cutting visibility down to almost nothing."
	probability = 15

	telegraph_duration = 300
	telegraph_overlay = "fog"
	telegraph_message = "<span class='notice'><font size=2>You see the fog rolling in.</font></span>"
	telegraph_sound = 'sound/weather/fog.ogg'
	weather_sound = 'sound/weather/fog.ogg'

	weather_message = "<span class='notice'><i>You can feel and see the moisture from the fog as it starts to roll in.</i></span>"
	weather_overlay = "fog"
	weather_color = "#C2D1D6" // tints the otherwise pale, low-contrast fog overlay so a bank of it reads clearly against the ground from a distance, the same way rad_storm tints its reused ash_storm sprite
	weather_duration_lower = 2400
	weather_duration_upper = 7200
	end_sound = 'sound/weather/fog.ogg'
	end_duration = 250
	end_message = "<span class='notice'><font size=2>The blanket of fog finally lifts up.</font></span>"
	end_overlay = "fog"
	tag_weather = WEATHER_RAIN
	weather_family = "fog"
	conflicting_families = "dust"
	area_types = list(/area/f13/wasteland, /area/f13/desert, /area/f13/farm, /area/f13/forest)
	protected_areas = list(/area/shuttle)
	target_trait = ZTRAIT_STATION
	protect_indoors = TRUE
	immunity_type = "water"
	is_dangerous = FALSE

	barometer_predictable = TRUE

	affects_turfs = TRUE
	carbons_only = TRUE
	climate_temp_shift = -3
	visibility_mult = 0.6
	wetness_rate = 1.5
	cloud_shadow = 0.5 // fog scatters light and flattens contrast for those inside it, but from outside it is a pale bank on the ground, not a shadow
	shades_outsiders = FALSE
	obscures_sight = TRUE
	obscure_color = "#D5DFE3"
	protected_view_loss = 1
	eye_protection_helps = FALSE
	wetness_weight = 0.7
	gust_message = span_notice("The air turns cold and damp as the fog creeps closer.")
	wet_ground_time = 2 MINUTES
	turf_reapply_interval = 90 SECONDS
	soak_rate = 4
	// Fog pools in low ground and hangs there
	cell_radius_lower = 0.12
	cell_radius_upper = 0.22
	drift_speed = 0.02
	// Fog gathers in the cool hours around dawn
	phase_weights = "3 2 0.8 0.4 0.4 0.6 1 1.2 1.5"
	/// When the sun first got strong enough to be burning the fog away for good, 0 while it has not
	var/burning_since = 0

/// How much of its full thickness fog keeps, 1 in the dark down to a fifth in full sun
/proc/get_fog_density()
	return 1 - clamp(SSnightcycle.effective_sun_power / 200, 0, 1) * FOG_BURN_OFF_MAX

/// How much of the fog is left for the sun: 1 in the dark, down to a fifth in full day
/datum/weather/fog/proc/burn_off()
	return get_fog_density()

/datum/weather/fog/get_density_mult()
	return burn_off()

/// Fog the sun has all but burned off does not hang around until its time is up
/datum/weather/fog/process()
	. = ..()
	if(stage != MAIN_STAGE)
		return
	if(burn_off() > FOG_BURN_OFF_ENDS)
		burning_since = 0
		return
	if(!burning_since)
		burning_since = world.time
	else if(world.time >= burning_since + FOG_BURN_OFF_DELAY)
		wind_down()

/// Fog only dampens people; it doesn't wash, douse or soak them the way falling rain does
/datum/weather/fog/weather_act(mob/living/L)
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		H.adjust_climate_wetness(wetness_rate)

/// Fog leaves the ground damp but doesn't clean blood or water trays
/datum/weather/fog/weather_act_turf(turf/open/T)
	SSweather.wet_turf(T, wet_ground_time)
