// Climate. Atmos is disabled, so a person's comfort is worked out here from the time of day, the weather, nearby fires and
// what they are wearing. It drives physiology.heat_mod and cold_mod, which makes perks like Heat Intolerant, Cold Intolerant,
// Hot Blooded and Survivalist actually matter. Rain and fog also leave people wet, which makes the cold worse until they dry.
//
// New sources of warmth should override get_climate_heat() and call register_climate_heat_source() when they start burning.
// New sources of ambient change can add to climate_temp_offset on the mob or set climate_temp_shift on a weather type.

GLOBAL_LIST_EMPTY(climate_heat_sources)

/// Degrees of warmth this atom gives at point blank range. Only sources that have been registered are ever asked.
/atom/proc/get_climate_heat()
	return 0

/proc/register_climate_heat_source(atom/source)
	GLOB.climate_heat_sources |= source

/proc/unregister_climate_heat_source(atom/source)
	GLOB.climate_heat_sources -= source

/mob/living/carbon/human
	/// Signed, -100 (freezing) to 100 (overheating). Builds up slowly while exposed and wears off when comfortable
	var/climate_exposure = 0
	/// Flat kelvin offset on the ambient temperature around this person
	var/climate_temp_offset = 0
	/// 0 to CLIMATE_WET_MAX, soaked by rain and fog and dried by shelter, warmth and time
	var/climate_wetness = 0
	/// 0 to ACID_EXPOSURE_MAX, builds while standing in acid rain and washes off once sheltered
	var/acid_exposure = 0
	var/acid_last_exposed = 0
/proc/climate_phase_temp(phase)
	switch(phase)
		if(NIGHTCYCLE_PHASE_SUNRISE)
			return CLIMATE_TEMP_SUNRISE
		if(NIGHTCYCLE_PHASE_MORNING)
			return CLIMATE_TEMP_MORNING
		if(NIGHTCYCLE_PHASE_LATEMORN)
			return CLIMATE_TEMP_LATEMORN
		if(NIGHTCYCLE_PHASE_DAYTIME)
			return CLIMATE_TEMP_DAYTIME
		if(NIGHTCYCLE_PHASE_AFTERNOON)
			return CLIMATE_TEMP_AFTERNOON
		if(NIGHTCYCLE_PHASE_LATEAFTERNOON)
			return CLIMATE_TEMP_LATEAFTERNOON
		if(NIGHTCYCLE_PHASE_SUNSET)
			return CLIMATE_TEMP_SUNSET
		if(NIGHTCYCLE_PHASE_FULLSUNSET)
			return CLIMATE_TEMP_FULLSUNSET
		if(NIGHTCYCLE_PHASE_NIGHTTIME)
			return CLIMATE_TEMP_NIGHTTIME
	return CLIMATE_INDOOR_TEMP

/mob/living/carbon/human/proc/climate_applies()
	if(HAS_TRAIT(src, TRAIT_POWER_ARMOR) || (status_flags & GODMODE))
		return FALSE
	if(!climate_is_machine() && !(mob_biotypes & MOB_ORGANIC))
		return FALSE
	return !!physiology

/// Machines overheat but never feel the cold
/mob/living/carbon/human/proc/climate_is_machine()
	return !!dna?.species?.climate_machine

/// Kelvin of the air around this person
/mob/living/carbon/human/proc/get_climate_ambient()
	var/area/A = get_area(src)
	. = CLIMATE_INDOOR_TEMP
	if(A?.outdoors)
		. = climate_phase_temp(SSnightcycle.current_time)
		var/datum/weather/W = get_active_weather(src)
		if(W && W.climate_temp_shift && !(W.immunity_type in weather_immunities))
			. += W.climate_temp_shift
	. += climate_temp_offset
	if(. >= CLIMATE_HEAT_SOURCE_CAP)
		return
	// Fires only take the chill off
	. = min(CLIMATE_HEAT_SOURCE_CAP, . + get_climate_warmth())

/// Degrees of warmth from the nearest lit fire. Fires only count when they share an area with you so walls matter
/mob/living/carbon/human/proc/get_climate_warmth()
	. = 0
	var/turf/T = get_turf(src)
	var/area/A = get_area(src)
	if(!T)
		return
	for(var/atom/source as anything in GLOB.climate_heat_sources.Copy())
		if(QDELETED(source))
			GLOB.climate_heat_sources -= source
			continue
		if(source.z != T.z || get_area(source) != A)
			continue
		var/dist = get_dist(source, T)
		if(dist > CLIMATE_HEAT_SOURCE_RADIUS)
			continue
		var/heat = source.get_climate_heat()
		if(heat > 0)
			. = max(., heat * (1 - dist / (CLIMATE_HEAT_SOURCE_RADIUS + 1)))

/// Soaks or dries this person, telling them when they cross into being drenched
/mob/living/carbon/human/proc/adjust_climate_wetness(amount)
	var/was_drenched = climate_wetness >= CLIMATE_WET_DRENCHED
	climate_wetness = clamp(climate_wetness + amount, 0, CLIMATE_WET_MAX)
	if(!was_drenched && climate_wetness >= CLIMATE_WET_DRENCHED)
		to_chat(src, span_warning("You are soaked through. The cold will cut deeper until you dry off."))
	else if(was_drenched && climate_wetness < CLIMATE_WET_DRENCHED)
		to_chat(src, span_notice("You've dried off a bit."))

/mob/living/carbon/human/proc/dry_off()
	if(climate_wetness <= 0)
		return
	var/area/A = get_area(src)
	var/drying = A?.outdoors ? CLIMATE_WET_DRY_OUTDOORS : CLIMATE_WET_DRY_INDOORS
	if(get_climate_warmth() > 0 || get_climate_ambient() > CLIMATE_COMFORT_MAX)
		drying += CLIMATE_WET_DRY_WARM
	adjust_climate_wetness(-drying)

/proc/climate_cover_fraction(obj/item/I)
	if(!I)
		return 0
	. = 0
	var/covered = I.body_parts_covered
	if(covered & CHEST)
		. += CLIMATE_COVER_CHEST
	for(var/limb in list(ARM_LEFT, ARM_RIGHT))
		if(covered & limb)
			. += CLIMATE_COVER_ARM
	for(var/limb in list(LEG_LEFT, LEG_RIGHT))
		if(covered & limb)
			. += CLIMATE_COVER_LEG

/// A worn item's warmth or heat trap multiplier, 1 for anything that is not clothing
/proc/climate_item_factor(obj/item/I, heat)
	if(!istype(I, /obj/item/clothing))
		return 1
	var/obj/item/clothing/C = I
	return heat ? C.climate_heat_trap : C.climate_warmth

/// Sum of every worn layer's slot weight times coverage times its warmth, or its heat trap when heat is set
/mob/living/carbon/human/proc/get_climate_layers(heat = FALSE)
	. = CLIMATE_INSULATION_UNIFORM * climate_cover_fraction(w_uniform) * climate_item_factor(w_uniform, heat)
	. += CLIMATE_INSULATION_SUIT * climate_cover_fraction(wear_suit) * climate_item_factor(wear_suit, heat)
	if(head && (head.body_parts_covered & HEAD))
		. += CLIMATE_INSULATION_HEAD * climate_item_factor(head, heat)
	if(wear_neck && (wear_neck.body_parts_covered & NECK))
		. += CLIMATE_INSULATION_NECK * climate_item_factor(wear_neck, heat)
	if(wear_mask && (wear_mask.body_parts_covered & HEAD))
		. += CLIMATE_INSULATION_MASK * climate_item_factor(wear_mask, heat)
	if(gloves && (gloves.body_parts_covered & HANDS))
		. += CLIMATE_INSULATION_GLOVES * climate_item_factor(gloves, heat)
	if(shoes && (shoes.body_parts_covered & FEET))
		. += CLIMATE_INSULATION_SHOES * climate_item_factor(shoes, heat)

/// 0 to CLIMATE_INSULATION_MAX, how much worn clothing keeps the cold out
/mob/living/carbon/human/proc/get_climate_insulation()
	return min(get_climate_layers(FALSE), CLIMATE_INSULATION_MAX)

/// How much heat worn clothing holds in, 0 to CLIMATE_HEAT_TRAP_MAX
/mob/living/carbon/human/proc/get_climate_heat_trap()
	return min(get_climate_layers(TRUE), CLIMATE_HEAT_TRAP_MAX)

/// Signed exposure this person is heading towards right now
/mob/living/carbon/human/proc/get_climate_target()
	. = 0
	if(!climate_applies())
		return
	var/ambient = get_climate_ambient()
	var/datum/species/S = dna?.species
	if(ambient < CLIMATE_COMFORT_MIN)
		if(HAS_TRAIT(src, TRAIT_RESISTCOLD))
			return
		var/stress = (CLIMATE_COMFORT_MIN - ambient) * CLIMATE_EXPOSURE_PER_DEGREE * (1 - get_climate_insulation()) * physiology.cold_mod * (S ? S.climate_cold_mod : 1)
		stress *= 1 + CLIMATE_WET_COLD_PENALTY * climate_wetness / CLIMATE_WET_MAX
		return -min(CLIMATE_EXPOSURE_MAX, stress)
	if(ambient > CLIMATE_COMFORT_MAX)
		if(HAS_TRAIT(src, TRAIT_RESISTHEAT))
			return
		var/trapped = 1 + get_climate_heat_trap() * CLIMATE_INSULATION_HEAT_PENALTY
		if(head && (head.body_parts_covered & HEAD))
			trapped *= 1 - CLIMATE_HAT_HEAT_RELIEF * clamp(2 - climate_item_factor(head, TRUE), 0, 1.5)
		var/stress = (ambient - CLIMATE_COMFORT_MAX) * CLIMATE_EXPOSURE_PER_DEGREE * trapped * physiology.heat_mod * (S ? S.climate_heat_mod : 1)
		stress *= 1 - CLIMATE_WET_HEAT_RELIEF * climate_wetness / CLIMATE_WET_MAX
		return min(CLIMATE_EXPOSURE_MAX, stress)

/mob/living/carbon/human/proc/handle_climate()
	if(stat == DEAD)
		return
	dry_off()
	acid_decay()
	var/target = get_climate_target()
	climate_exposure += (target - climate_exposure) * CLIMATE_EXPOSURE_RATE
	if(!target && abs(climate_exposure) < 1)
		climate_exposure = 0
	if(!on_fire)
		bodytemperature = BODYTEMP_NORMAL + climate_exposure * CLIMATE_BODYTEMP_PER_EXPOSURE
	apply_climate_effects()

/mob/living/carbon/human/proc/apply_climate_effects()
	var/hot = climate_exposure > 0
	var/level = abs(climate_exposure)
	if(level < CLIMATE_TIER_MILD)
		clear_alert("tempfeel")
		clear_alert("temp")
		SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "hot")
		SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "cold")
		remove_movespeed_modifier(/datum/movespeed_modifier/cold)
		return
	if(level < CLIMATE_TIER_MODERATE)
		clear_alert("temp")
		throw_alert("tempfeel", hot ? /obj/screen/alert/sweat : /obj/screen/alert/shiver, 1)
		SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "hot")
		SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "cold")
		remove_movespeed_modifier(/datum/movespeed_modifier/cold)
		return
	clear_alert("tempfeel")
	var/severe = level >= CLIMATE_TIER_SEVERE
	var/machine = climate_is_machine()
	throw_alert("temp", hot ? /obj/screen/alert/hot : /obj/screen/alert/cold, severe ? 2 : 1)
	if(!machine)
		SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, hot ? "cold" : "hot")
		SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, hot ? "hot" : "cold", hot ? /datum/mood_event/hot : /datum/mood_event/cold)
	var/frac = (level - CLIMATE_TIER_MODERATE) / (CLIMATE_EXPOSURE_MAX - CLIMATE_TIER_MODERATE)
	if(hot)
		remove_movespeed_modifier(/datum/movespeed_modifier/cold)
		if(machine)
			adjust_nutrition(-CLIMATE_MACHINE_CHARGE_DRAIN * (0.5 + 0.5 * frac))
		else
			adjustStaminaLossBuffered(CLIMATE_HEAT_STAMINA * (0.5 + 0.5 * frac))
		if(prob(4))
			to_chat(src, span_warning(machine ? "Your cooling fans are running flat out." : "The heat is wearing you down."))
	else
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/cold, multiplicative_slowdown = CLIMATE_COLD_SLOWDOWN_MAX * (0.2 + 0.8 * frac))
		if(prob(4))
			to_chat(src, span_warning("You can't stop shivering."))
	if(!severe || health <= maxHealth * CLIMATE_DAMAGE_HEALTH_FLOOR)
		return
	var/damage = CLIMATE_DAMAGE_MIN + (CLIMATE_DAMAGE_MAX - CLIMATE_DAMAGE_MIN) * (level - CLIMATE_TIER_SEVERE) / (CLIMATE_EXPOSURE_MAX - CLIMATE_TIER_SEVERE)
	apply_damage(damage, BURN)
	if(prob(8))
		var/warning = hot ? (machine ? "Core temperature critical. You need shade and a chance to cool down." : "Heatstroke is setting in. You need shade and water.") : "Frostbite is setting in. You need warmth."
		to_chat(src, span_userdanger("[warning]"))

/// Body zones acid rain burns, how much of the damage each takes and the clothing slot flag that shields it
/proc/acid_rain_zones()
	var/static/list/zones = list(
		BODY_ZONE_HEAD = list(0.2, HEAD),
		BODY_ZONE_CHEST = list(0.4, CHEST),
		BODY_ZONE_L_ARM = list(0.1, ARM_LEFT),
		BODY_ZONE_R_ARM = list(0.1, ARM_RIGHT),
		BODY_ZONE_L_LEG = list(0.1, LEG_LEFT),
		BODY_ZONE_R_LEG = list(0.1, LEG_RIGHT))
	return zones

/// 0 to ACID_PROTECTION_MAX, how well this body part is shielded from acid rain by what is worn over it or its acid armor
/mob/living/carbon/human/proc/get_acid_protection(zone, cover_flag)
	var/layers = 0
	for(var/obj/item/I in list(head, wear_mask, wear_suit, w_uniform))
		if(I.body_parts_covered & cover_flag)
			layers++
	var/cover = layers ? ACID_COVER_PROTECTION + (layers - 1) * ACID_COVER_LAYER_BONUS : 0
	var/obj/item/bodypart/BP = get_bodypart(zone)
	var/armor = BP ? clamp(getarmor(BP, "acid"), 0, 100) / 100 : 0
	return min(ACID_PROTECTION_MAX, max(cover, armor))

/// Called every second while this person is standing in acid rain. Exposure has to build before it hurts
/mob/living/carbon/human/proc/acid_rain_tick()
	if(stat == DEAD)
		return
	acid_last_exposed = world.time
	var/was_safe = acid_exposure < ACID_EXPOSURE_THRESHOLD
	acid_exposure = min(ACID_EXPOSURE_MAX, acid_exposure + ACID_EXPOSURE_GAIN)
	if(acid_exposure < ACID_EXPOSURE_THRESHOLD)
		return
	if(was_safe)
		to_chat(src, span_userdanger("The rain is eating at you! Find cover, or the burns will keep building."))
	if(health <= maxHealth * ACID_DAMAGE_HEALTH_FLOOR)
		return
	var/severity = 0.25 + 0.75 * (acid_exposure - ACID_EXPOSURE_THRESHOLD) / (ACID_EXPOSURE_MAX - ACID_EXPOSURE_THRESHOLD)
	var/list/zones = acid_rain_zones()
	for(var/zone in zones)
		var/list/info = zones[zone]
		var/damage = ACID_DAMAGE_PER_SECOND * info[1] * severity * (1 - get_acid_protection(zone, info[2]))
		if(damage > 0)
			apply_damage(damage, BURN, zone, 0)
	if(prob(5))
		to_chat(src, span_warning("Acid sizzles against your skin."))

/mob/living/carbon/human/proc/acid_decay()
	if(acid_exposure <= 0 || world.time - acid_last_exposed < ACID_EXPOSURE_DECAY_DELAY)
		return
	var/was_burning = acid_exposure >= ACID_EXPOSURE_THRESHOLD
	acid_exposure = max(0, acid_exposure - ACID_EXPOSURE_DECAY)
	if(was_burning && acid_exposure < ACID_EXPOSURE_THRESHOLD)
		to_chat(src, span_notice("The stinging finally fades."))
