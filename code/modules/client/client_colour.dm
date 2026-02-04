
/*
	Client Colour Priority System By RemieRichards
	A System that gives finer control over which client.colour value to display on screen
	so that the "highest priority" one is always displayed as opposed to the default of
	"whichever was set last is displayed"
*/



/*
	Define subtypes of this datum
*/
/datum/client_colour
	var/colour = "" //Any client.color-valid value
	var/priority = 1 //Since only one client.color can be rendered on screen, we take the one with the highest priority value:
	//eg: "Bloody screen" > "goggles colour" as the former is much more important

/mob/var/current_area_client_colour = null
/mob/living/var/current_daylight_client_colour = null
/mob/living/var/current_weather_client_colour = null
/mob/living/var/current_material_client_colour = null
/mob/living/var/next_cinematic_visual_update = 0


/*
	Adds an instance of colour_type to the mob's client_colours list
	colour_type - a typepath (subtyped from /datum/client_colour)
*/
/mob/proc/add_client_colour(colour_type)
	if(!ispath(colour_type, /datum/client_colour))
		return

	var/datum/client_colour/CC = new colour_type()
	client_colours |= CC
	sortTim(client_colours, GLOBAL_PROC_REF(cmp_clientcolour_priority))
	update_client_colour()


/*
	Removes an instance of colour_type from the mob's client_colours list
	colour_type - a typepath (subtyped from /datum/client_colour)
*/
/mob/proc/remove_client_colour(colour_type)
	if(!ispath(colour_type, /datum/client_colour))
		return

	for(var/cc in client_colours)
		var/datum/client_colour/CC = cc
		if(CC.type == colour_type)
			client_colours -= CC
			qdel(CC)
			break
	update_client_colour()


/*
	Resets the mob's client.color to null, and then sets it to the highest priority
	client_colour datum, if one exists
*/
/mob/proc/update_client_colour()
	if(!client)
		return
	client.color = ""
	if(!client_colours.len)
		return
	var/datum/client_colour/CC = client_colours[1]
	if(CC)
		client.color = CC.colour

/mob/proc/update_area_client_colour(area/current_area)
	var/new_colour_type = null
	if(istype(current_area) && ispath(current_area.client_colour_grade, /datum/client_colour))
		new_colour_type = current_area.client_colour_grade
	else
		new_colour_type = get_auto_zone_grade(current_area)

	if(current_area_client_colour == new_colour_type)
		return

	if(current_area_client_colour)
		remove_client_colour(current_area_client_colour)

	current_area_client_colour = new_colour_type

	if(current_area_client_colour)
		add_client_colour(current_area_client_colour)

	if(client)
		var/obj/screen/fullscreen/cinematic_transition/fade = overlay_fullscreen("cinematic_transition", /obj/screen/fullscreen/cinematic_transition)
		fade.alpha = 22
		animate(fade, alpha = 0, time = 7)

/mob/proc/get_auto_zone_grade(area/current_area)
	if(!istype(current_area))
		return null
	var/area_name = lowertext("[current_area.name]")
	if(findtext(area_name, "vault"))
		return /datum/client_colour/zone_grade/vault_blue
	if(current_area.outdoors)
		return /datum/client_colour/zone_grade/wasteland_amber
	if(findtext(area_name, "reactor") || findtext(area_name, "plant") || findtext(area_name, "fusion") || findtext(area_name, "industrial") || findtext(area_name, "factory"))
		return /datum/client_colour/zone_grade/industrial_green
	return /datum/client_colour/zone_grade/industrial_green

/mob/living/proc/get_daylight_grade(area/current_area)
	if(!istype(current_area))
		return null
	if(!current_area.outdoors)
		return /datum/client_colour/daylight_grade/indoors_neutral
	if(!SSnightcycle)
		return /datum/client_colour/daylight_grade/outdoor_day
	if(SSnightcycle.current_sun_power >= 170)
		return /datum/client_colour/daylight_grade/outdoor_day
	if(SSnightcycle.current_sun_power >= 110)
		return /datum/client_colour/daylight_grade/outdoor_dusk
	return /datum/client_colour/daylight_grade/outdoor_night

/mob/living/proc/get_weather_grade(area/current_area)
	var/datum/weather/W = SSweather?.get_weather(current_area)
	if(!W || W.stage >= 4)
		return null
	if(istype(W, /datum/weather/rad_storm))
		return /datum/client_colour/weather_grade/radstorm
	if(istype(W, /datum/weather/ash_storm/sandstorm) || istype(W, /datum/weather/ash_storm))
		return /datum/client_colour/weather_grade/sandstorm
	if(istype(W, /datum/weather/rain/fog))
		return /datum/client_colour/weather_grade/fog
	if(istype(W, /datum/weather/acid_rain))
		return /datum/client_colour/weather_grade/acid_rain
	if(istype(W, /datum/weather/heat_wave))
		return /datum/client_colour/weather_grade/heat_wave
	if(istype(W, /datum/weather/cold_wave))
		return /datum/client_colour/weather_grade/cold_wave
	return null

/mob/living/proc/get_material_grade(turf/current_turf)
	if(!istype(current_turf))
		return null
	var/icon_state_name = lowertext("[current_turf.icon_state]")
	if(findtext(icon_state_name, "metal") || findtext(icon_state_name, "plating") || findtext(icon_state_name, "rust") || findtext(icon_state_name, "vault"))
		return /datum/client_colour/material_grade/reflective_metal
	if(findtext(icon_state_name, "sand") || findtext(icon_state_name, "dirt") || findtext(icon_state_name, "desert") || findtext(icon_state_name, "ash"))
		return /datum/client_colour/material_grade/matte_dust
	if(findtext(icon_state_name, "concrete") || findtext(icon_state_name, "stone") || findtext(icon_state_name, "tile"))
		return /datum/client_colour/material_grade/mineral_concrete
	return null

/mob/living/proc/get_heat_haze_strength()
	var/strength = 0
	if(on_fire)
		strength = max(strength, 1)
	var/atom/grid_core = GLOB.grid_rad_source
	if(grid_core && istype(grid_core, /obj/structure/f13/grid_radiation_source) && get_dist(src, grid_core) <= 8)
		strength = max(strength, (9 - get_dist(src, grid_core)) / 9)
	for(var/turf/open/T in view(4, src))
		if(locate(/obj/effect/hotspot) in T)
			strength = max(strength, 0.7)
		var/datum/gas_mixture/air = T.return_air()
		var/air_temp = air ? air.return_temperature() : 0
		if(air_temp > 390)
			strength = max(strength, min(1, (air_temp - 390) / 420))
		if(strength >= 1)
			break
	return CLAMP01(strength)

/mob/living/proc/update_cinematic_visuals()
	if(!client || world.time < next_cinematic_visual_update)
		return
	next_cinematic_visual_update = world.time + 2 SECONDS

	var/area/current_area = get_area(src)
	var/turf/current_turf = get_turf(src)
	var/datum/weather/active_weather = SSweather?.get_weather(current_area)

	var/new_daylight = get_daylight_grade(current_area)
	if(current_daylight_client_colour != new_daylight)
		if(current_daylight_client_colour)
			remove_client_colour(current_daylight_client_colour)
		current_daylight_client_colour = new_daylight
		if(current_daylight_client_colour)
			add_client_colour(current_daylight_client_colour)

	var/new_weather = get_weather_grade(current_area)
	if(current_weather_client_colour != new_weather)
		if(current_weather_client_colour)
			remove_client_colour(current_weather_client_colour)
		current_weather_client_colour = new_weather
		if(current_weather_client_colour)
			add_client_colour(current_weather_client_colour)

	var/new_material = get_material_grade(current_turf)
	if(current_material_client_colour != new_material)
		if(current_material_client_colour)
			remove_client_colour(current_material_client_colour)
		current_material_client_colour = new_material
		if(current_material_client_colour)
			add_client_colour(current_material_client_colour)

	var/obj/screen/fullscreen/cinematic_exposure/exposure = overlay_fullscreen("cinematic_exposure", /obj/screen/fullscreen/cinematic_exposure)
	var/exposure_alpha = 0
	if(istype(current_area))
		if(current_area.outdoors)
			if(SSnightcycle?.current_sun_power >= 160)
				exposure_alpha = 6
			else if(SSnightcycle?.current_sun_power <= 80)
				exposure_alpha = 18
		else
			if(SSnightcycle?.current_sun_power >= 160)
				exposure_alpha = 42
			else
				exposure_alpha = 24
		if(!current_area.powered(LIGHT))
			exposure_alpha += 16
	if(active_weather && (istype(active_weather, /datum/weather/ash_storm/sandstorm) || istype(active_weather, /datum/weather/rain/fog)))
		exposure_alpha += 8
	exposure_alpha = clamp(exposure_alpha, 0, 72)
	animate(exposure, alpha = exposure_alpha, time = 6)

	var/obj/screen/fullscreen/cinematic_mood/mood = overlay_fullscreen("cinematic_mood", /obj/screen/fullscreen/cinematic_mood)
	var/mood_alpha = 0
	var/mood_color = "#FFAA66"
	if(InCritical() || health <= HEALTH_THRESHOLD_FULLCRIT)
		mood_alpha = 60
		mood_color = "#CC4040"
	else if(enabled_combat_indicator)
		mood_alpha = 24
		mood_color = "#D27A34"
	mood.color = mood_color
	animate(mood, alpha = mood_alpha, time = 4)

	var/obj/screen/fullscreen/cinematic_rads/radfx = overlay_fullscreen("cinematic_rads", /obj/screen/fullscreen/cinematic_rads)
	var/rad_alpha = 0
	if(radiation_sickness >= 2500)
		rad_alpha = 56
	else if(radiation_sickness >= 1400)
		rad_alpha = 40
	else if(radiation_sickness >= 700)
		rad_alpha = 24
	animate(radfx, alpha = rad_alpha, time = 6)

	var/obj/screen/fullscreen/cinematic_heat_haze/heatfx = overlay_fullscreen("cinematic_heat_haze", /obj/screen/fullscreen/cinematic_heat_haze)
	var/heat_alpha = round(get_heat_haze_strength() * 45)
	animate(heatfx, alpha = heat_alpha, time = 5)

	var/obj/screen/fullscreen/cinematic_emergency/emergency = overlay_fullscreen("cinematic_emergency", /obj/screen/fullscreen/cinematic_emergency)
	var/emergency_alpha = 0
	if(istype(current_area) && !current_area.powered(LIGHT))
		var/cycle = world.time % 40
		var/pulse = (cycle <= 20) ? cycle : (40 - cycle)
		emergency_alpha = 6 + round(pulse * 0.6)
	animate(emergency, alpha = emergency_alpha, time = 2)

	var/obj/screen/fullscreen/lighting_grain/grain = overlay_fullscreen("lighting_grain", /obj/screen/fullscreen/lighting_grain)
	var/grain_alpha = 10
	var/grain_color = "#B8AD94"
	if(istype(current_area) && current_area.outdoors)
		grain_alpha = 14
		grain_color = "#C9B28D"
	if(active_weather)
		if(istype(active_weather, /datum/weather/ash_storm/sandstorm))
			grain_alpha += 10
			grain_color = "#CFB488"
		else if(istype(active_weather, /datum/weather/rain/fog))
			grain_alpha += 8
			grain_color = "#C5D2DF"
		else if(istype(active_weather, /datum/weather/rad_storm))
			grain_alpha += 10
			grain_color = "#9AE58E"
	if(rad_alpha > 0)
		grain_alpha += round(rad_alpha / 7)
	grain.alpha = clamp(grain_alpha, 6, 38)
	grain.color = grain_color

	var/obj/screen/fullscreen/cinematic_dust/dust = overlay_fullscreen("cinematic_dust", /obj/screen/fullscreen/cinematic_dust)
	var/dust_alpha = 0
	var/dust_color = "#D9B983"
	if(istype(current_area) && current_area.outdoors)
		dust_alpha = 8
	if(active_weather)
		if(istype(active_weather, /datum/weather/ash_storm/sandstorm))
			dust_alpha = 32
			dust_color = "#D8BA89"
		else if(istype(active_weather, /datum/weather/rain/fog))
			dust_alpha = max(dust_alpha, 18)
			dust_color = "#BFC8CF"
		else if(istype(active_weather, /datum/weather/heat_wave))
			dust_alpha = max(dust_alpha, 14)
			dust_color = "#F1C78E"
	if(!istype(current_area) || !current_area.outdoors)
		dust_alpha = max(0, dust_alpha - 6)
	dust.color = dust_color
	animate(dust, alpha = clamp(dust_alpha, 0, 40), time = 5)

	var/obj/screen/fullscreen/cinematic_lens_glow/lensglow = overlay_fullscreen("cinematic_lens_glow", /obj/screen/fullscreen/cinematic_lens_glow)
	var/lens_alpha = 0
	var/lens_color = "#A6D8FF"
	if(istype(current_area) && current_area.outdoors && SSnightcycle?.current_sun_power >= 165)
		lens_alpha = 8
	if(heat_alpha >= 24)
		lens_alpha = max(lens_alpha, 12)
		lens_color = "#FFC782"
	if(rad_alpha >= 40)
		lens_alpha = max(lens_alpha, 16)
		lens_color = "#97FF8E"
	lensglow.color = lens_color
	animate(lensglow, alpha = clamp(lens_alpha, 0, 32), time = 5)

	if(hud_used)
		var/obj/screen/plane_master/lighting/lighting_plane = hud_used.plane_masters["[LIGHTING_PLANE]"]
		if(lighting_plane)
			var/bloom_soft = 0.45
			var/bloom_wide = 0.80
			if(istype(current_area) && current_area.outdoors)
				bloom_soft += 0.07
				bloom_wide += 0.18
			if(active_weather)
				if(istype(active_weather, /datum/weather/rain/fog))
					bloom_wide += 0.35
				else if(istype(active_weather, /datum/weather/ash_storm/sandstorm))
					bloom_wide += 0.22
			bloom_soft += (heat_alpha / 220)
			bloom_wide += (heat_alpha / 150)
			bloom_soft += (rad_alpha / 300)
			bloom_wide += (rad_alpha / 220)
			if(emergency_alpha >= 12)
				bloom_soft += 0.08
			bloom_soft = clamp(round(bloom_soft, 0.01), 0.35, 1.25)
			bloom_wide = clamp(round(bloom_wide, 0.01), 0.70, 1.90)
			lighting_plane.add_filter("cinematic_bloom_soft", 4, list(type = "blur", size = bloom_soft))
			lighting_plane.add_filter("cinematic_bloom_wide", 5, list(type = "blur", size = bloom_wide))




/datum/client_colour/glass_colour
	priority = 0
	colour = "red"

/datum/client_colour/glass_colour/green
	colour = "#aaffaa"

/datum/client_colour/glass_colour/lightgreen
	colour = "#ccffcc"

/datum/client_colour/glass_colour/blue
	colour = "#aaaaff"

/datum/client_colour/glass_colour/lightblue
	colour = "#ccccff"

/datum/client_colour/glass_colour/yellow
	colour = "#ffff66"

/datum/client_colour/glass_colour/red
	colour = "#ffaaaa"

/datum/client_colour/glass_colour/darkred
	colour = "#bb5555"

/datum/client_colour/glass_colour/orange
	colour = "#ffbb99"

/datum/client_colour/glass_colour/lightorange
	colour = "#ffddaa"

/datum/client_colour/glass_colour/purple
	colour = "#ff99ff"

/datum/client_colour/glass_colour/gray
	colour = "#cccccc"


/datum/client_colour/monochrome
	colour = list(rgb(77,77,77), rgb(150,150,150), rgb(28,28,28), rgb(0,0,0))
	priority = INFINITY //we can't see colors anyway!

/datum/client_colour/monochrome/trance
	priority = 1

/datum/client_colour/zone_grade
	priority = -5

/datum/client_colour/zone_grade/industrial_green
	colour = "#DBFFD9"

/datum/client_colour/zone_grade/wasteland_amber
	colour = "#FFE8C4"

/datum/client_colour/zone_grade/vault_blue
	colour = "#D7E9FF"

/datum/client_colour/daylight_grade
	priority = -4

/datum/client_colour/daylight_grade/outdoor_day
	colour = "#FFF2D9"

/datum/client_colour/daylight_grade/outdoor_dusk
	colour = "#FFDDBA"

/datum/client_colour/daylight_grade/outdoor_night
	colour = "#C9D8F5"

/datum/client_colour/daylight_grade/indoors_neutral
	colour = "#E7ECEF"

/datum/client_colour/weather_grade
	priority = -3

/datum/client_colour/weather_grade/sandstorm
	colour = "#EBD5B1"

/datum/client_colour/weather_grade/fog
	colour = "#DDE6EE"

/datum/client_colour/weather_grade/radstorm
	colour = "#C9FFC8"

/datum/client_colour/weather_grade/heat_wave
	colour = "#FFD8B8"

/datum/client_colour/weather_grade/cold_wave
	colour = "#D5E5FF"

/datum/client_colour/weather_grade/acid_rain
	colour = "#D8F7C8"

/datum/client_colour/material_grade
	priority = -2

/datum/client_colour/material_grade/reflective_metal
	colour = "#F0F4FF"

/datum/client_colour/material_grade/matte_dust
	colour = "#E7D5BF"

/datum/client_colour/material_grade/mineral_concrete
	colour = "#E9E7DF"
