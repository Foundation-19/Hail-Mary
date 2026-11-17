/datum/weather/cold_wave
	name = "cold wave"
	desc = "Harsh cold wave will grip an entire area."
	probability = 20

	telegraph_message = span_notice("A chilling and unfamiliar breeze sweeps over the valley.")
	telegraph_duration = 300
	telegraph_overlay = "snow_storm"
	telegraph_sound = 'sound/f13effects/coldwave.ogg'
	weather_sound = 'sound/f13effects/coldwave.ogg'

	weather_message = span_notice("The once only chilling breeze outside rapidly falls to an unbearable cold overtime with no signs of stopping. You feel as though you are better off indoors.")
	weather_overlay = "snow_storm"
	weather_duration_lower = 1200
	weather_duration_upper = 2400

	end_duration = 100
	end_message = span_notice("The cold snap dies down, it should be safe to go outside again.")

	area_types = list(/area/f13/wasteland, /area/f13/desert, /area/f13/farm, /area/f13/forest)
	protected_areas = list(/area/shuttle)
	target_trait = ZTRAIT_STATION
	tag_weather = WEATHER_COLD
	weather_family = "temperature"

	immunity_type = "snow"

	barometer_predictable = TRUE

	carbons_only = TRUE
	climate_temp_shift = -22
	// A cold front is a huge air mass that crawls along
	cell_radius_lower = 0.3
	cell_radius_upper = 0.45
	drift_speed = 0.03
	// Cold snaps favour the night and the hours around it, so one does not land at noon
	phase_weights = "2 0.5 0.2 0.05 0.05 0.3 1.5 2 3"
