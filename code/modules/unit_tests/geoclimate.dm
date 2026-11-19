/datum/unit_test/geoclimate_water_table/Run()
	var/datum/geo_parcel/desert = allocate(/datum/geo_parcel, run_loc_bottom_left.z, 1, 1, 10, 10)
	desert.soil_n = 100
	desert.settle(0)
	var/datum/geo_parcel/floodplain = allocate(/datum/geo_parcel, run_loc_bottom_left.z, 1, 1, 10, 10)
	floodplain.soil_n = 100
	floodplain.water_n = 40
	floodplain.settle(0.3)

	TEST_ASSERT_EQUAL(desert.equilibrium, 0, "Ground with no water around it has a water table")
	TEST_ASSERT(floodplain.equilibrium > GEO_MUD_START, "Low ground beside open water does not hold wet enough to want to be marsh")

	// A downpour soaks both, and three hours of drought later only the floodplain is still wet
	desert.advance(5, 14, 1, 0, 1)
	floodplain.advance(5, 14, 1, 0, 1)
	TEST_ASSERT(desert.moisture > 50, "Rain did not soak the ground")
	desert.advance(180, 0, 1, 0, 1)
	floodplain.advance(180, 0, 1, 0, 1)
	TEST_ASSERT(desert.moisture < 5, "Dry country stayed wet through a drought")
	TEST_ASSERT(floodplain.moisture > floodplain.equilibrium - 1, "Wet country dried below its own water table")

/datum/unit_test/geoclimate_overgrowth/Run()
	var/datum/geo_parcel/field = allocate(/datum/geo_parcel, run_loc_bottom_left.z, 1, 1, 10, 10)
	field.soil_n = 100
	field.moisture = 90

	var/datum/geo_parcel/tended = allocate(/datum/geo_parcel, run_loc_bottom_left.z, 1, 1, 10, 10)
	tended.soil_n = 100
	tended.moisture = 90
	field.advance(30, 0, 1, 0, GEO_ABANDONED_GROWTH)
	tended.advance(30, 0, 1, 0, GEO_TENDED_GROWTH)
	TEST_ASSERT(field.vegetation > tended.vegetation, "Ground nobody tends does not grow over faster")

	// Drought withers it faster than it came
	var/grown = field.vegetation
	field.moisture = 0
	field.advance(10, 0, 1, 0, 1)
	TEST_ASSERT(field.vegetation < grown - GEO_GROWTH_RATE * 10, "Plants did not die back in a drought")

	field.last_visit = world.time - GEO_ABANDON_TIME
	TEST_ASSERT(field.abandoned(), "A parcel nobody visited for an hour is not abandoned")
	field.last_visit = world.time
	TEST_ASSERT(!field.abandoned(), "A parcel somebody just visited is abandoned")
	TEST_ASSERT_EQUAL(field.reclaim_cap(), 0, "Vines took a place somebody is in")

/datum/unit_test/geoclimate_mud/Run()
	var/datum/geo_parcel/field = allocate(/datum/geo_parcel, run_loc_bottom_left.z, 1, 1, 10, 10)
	field.soil_n = 100
	field.moisture = GEO_MUD_START - 1
	TEST_ASSERT_EQUAL(field.target_mud_step(), 0, "Ground turned to mud before it was wet enough")
	field.moisture = 100
	TEST_ASSERT_EQUAL(field.target_mud_step(), GEO_MUD_STEPS, "Soaked ground did not turn fully to mud")

	var/turf/open/soil = run_loc_bottom_left
	var/was = soil.slowdown
	soil.set_geo_mud(TRUE)
	soil.set_geo_mud(TRUE)
	TEST_ASSERT_EQUAL(soil.slowdown, was + GEO_MUD_SLOWDOWN, "Mud slowed a turf more than once")
	soil.set_geo_mud(FALSE)
	TEST_ASSERT_EQUAL(soil.slowdown, was, "Drying out did not restore the ground's own speed")

/datum/unit_test/geoclimate_persistence/Run()
	var/datum/geo_parcel/before = allocate(/datum/geo_parcel, run_loc_bottom_left.z, 1, 1, 10, 10)
	before.soil_n = 100
	before.moisture = 72.4
	before.vegetation = 38.6
	before.mud_step = 3
	before.radiation = 240.8
	before.last_visit = world.time - 45 MINUTES

	// Round-trips through JSON, the same as a real save file between rounds
	var/list/entry = json_decode(json_encode(before.to_save_data()))

	var/datum/geo_parcel/after = allocate(/datum/geo_parcel, run_loc_bottom_left.z, 1, 1, 10, 10)
	after.apply_save_data(entry)

	TEST_ASSERT(abs(after.moisture - 72.4) < 0.05, "Moisture did not survive a save and load")
	TEST_ASSERT(abs(after.vegetation - 38.6) < 0.05, "Vegetation did not survive a save and load")
	TEST_ASSERT_EQUAL(after.mud_step, 3, "Mud step did not survive a save and load")
	TEST_ASSERT(abs(after.radiation - 240.8) < 0.05, "Radiation did not survive a save and load")
	TEST_ASSERT(abs((world.time - after.last_visit) - 45 MINUTES) <= 1, "How long ago a parcel was last visited did not survive a save and load")

/datum/unit_test/geoclimate_persistence_bad_data/Run()
	var/datum/geo_parcel/field = allocate(/datum/geo_parcel, run_loc_bottom_left.z, 1, 1, 10, 10)
	field.moisture = 50
	field.mud_step = GEO_MUD_STEPS
	field.radiation = 500
	field.apply_save_data(list()) // an empty or outdated save entry, missing every field
	TEST_ASSERT_EQUAL(field.moisture, 0, "A missing moisture value did not fall back to a safe default")
	TEST_ASSERT_EQUAL(field.mud_step, 0, "A missing mud step value did not fall back to a safe default")
	TEST_ASSERT_EQUAL(field.radiation, 0, "A missing radiation value did not fall back to a safe default")
	TEST_ASSERT(field.last_visit <= world.time, "A missing idle time put the last visit in the future")

/datum/unit_test/geoclimate_radiation/Run()
	var/datum/geo_parcel/hit = allocate(/datum/geo_parcel, run_loc_bottom_left.z, 1, 1, 10, 10)
	hit.soil_n = 100

	// A storm sits over the ground for a few minutes, soaking fallout into it faster than it can fade
	hit.advance(5, 0, 1, 0, 1, 60)
	TEST_ASSERT(hit.radiation > 250, "Fallout did not build up in the ground while the storm sat over it")

	// Many short ticks under a storm never push the ground past its saturation point
	var/datum/geo_parcel/saturated = allocate(/datum/geo_parcel, run_loc_bottom_left.z, 1, 1, 10, 10)
	saturated.soil_n = 100
	for(var/i in 1 to 500)
		saturated.advance(1, 0, 1, 0, 1, 60)
	TEST_ASSERT(saturated.radiation <= GEO_RADIATION_MAX, "Fallout built up past the ground's saturation point")
	TEST_ASSERT(saturated.radiation > GEO_RADIATION_MAX * 0.8, "Ground under a storm for a long while did not end up heavily contaminated")

	// Left alone afterwards, the fallout fades on its own slow clock
	var/grown = hit.radiation
	hit.advance(180, 0, 1, 0, 1)
	TEST_ASSERT(hit.radiation < grown, "Fallout did not fade once the storm had passed")
	TEST_ASSERT(hit.radiation > 0, "Fallout vanished instead of fading slowly")
