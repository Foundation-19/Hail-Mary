// Eastwood Town Services
// Inn, clinic, repair shop, and other municipal services

// ============ INN SYSTEM ============

/datum/eastwood_inn
	var/list/rooms = list()
	var/list/guests = list()

/datum/eastwood_inn/proc/rent_room(mob/user, room_id, days)
	for(var/datum/inn_room/R in rooms)
		if(R.room_id == room_id && !R.occupied)
			R.occupied = TRUE
			R.guest_ckey = user.ckey
			R.guest_name = user.name
			R.rent_expiry = world.time + (days * 24 * 60 * 10)

			var/datum/guest_record/record = new()
			record.ckey = user.ckey
			record.room_id = room_id
			record.check_in = world.time
			guests += record

			return TRUE
	return FALSE

/datum/eastwood_inn/proc/check_out(room_id)
	for(var/datum/inn_room/R in rooms)
		if(R.room_id == room_id)
			R.occupied = FALSE
			R.guest_ckey = null
			R.guest_name = null
			R.rent_expiry = 0
			return TRUE
	return FALSE

/datum/eastwood_inn/proc/get_guest_room(ckey)
	for(var/datum/inn_room/R in rooms)
		if(R.guest_ckey == ckey)
			return R
	return null

// ============ INN ROOM ============

/datum/inn_room
	var/room_id
	var/room_name
	var/quality = ROOM_STANDARD
	var/occupied = FALSE
	var/guest_ckey
	var/guest_name
	var/rent_expiry
	var/daily_rate = INN_ROOM_DAILY

// ============ GUEST RECORD ============

/datum/guest_record
	var/ckey
	var/room_id
	var/check_in
	var/check_out

// ============ CLINIC SYSTEM ============

/datum/eastwood_clinic
	var/list/patients = list()
	var/list/medical_records = list()
	var/doctors_on_duty = 0

/datum/eastwood_clinic/proc/register_patient(mob/user)
	for(var/datum/clinic_patient/P in patients)
		if(P.ckey == user.ckey)
			return FALSE

	var/datum/clinic_patient/patient = new()
	patient.ckey = user.ckey
	patient.name = user.name
	patient.registered_date = world.time

	patients += patient
	return TRUE

/datum/eastwood_clinic/proc/get_patient(ckey)
	for(var/datum/clinic_patient/P in patients)
		if(P.ckey == ckey)
			return P
	return null

/datum/eastwood_clinic/proc/perform_treatment(mob/patient, treatment_type, mob/doctor)
	var/datum/clinic_patient/P = get_patient(patient.ckey)
	if(!P)
		return FALSE

	var/datum/medical_record/record = new()
	record.patient_ckey = patient.ckey
	record.patient_name = patient.name
	record.doctor_ckey = doctor.ckey
	record.treatment = treatment_type
	record.treatment_date = world.time

	switch(treatment_type)
		if("basic_heal")
			record.cost = CLINIC_BASIC_HEAL
			if(iscarbon(patient))
				var/mob/living/carbon/C = patient
				C.adjustBruteLoss(-30)
				C.adjustFireLoss(-30)
				C.adjustToxLoss(-20)
				C.adjustOxyLoss(-20)
		if("surgery")
			record.cost = CLINIC_SURGERY
		if("rad_away")
			if(iscarbon(patient))
				var/mob/living/carbon/C = patient
				C.radiation = max(0, C.radiation - 50)
			record.cost = CLINIC_BASIC_HEAL
		if("addiction_treatment")
			if(iscarbon(patient))
				var/mob/living/carbon/C = patient
				for(var/datum/addiction/A in C.mind?.active_addictions)
					C.mind.active_addictions -= A
					qdel(A)
			record.cost = CLINIC_SURGERY

	medical_records += record
	return TRUE

// ============ CLINIC PATIENT ============

/datum/clinic_patient
	var/ckey
	var/name
	var/registered_date
	var/outstanding_bill = 0

// ============ MEDICAL RECORD ============

/datum/medical_record
	var/patient_ckey
	var/patient_name
	var/doctor_ckey
	var/treatment
	var/treatment_date
	var/cost
	var/paid = FALSE

// ============ REPAIR SHOP ============

/datum/eastwood_repair_shop
	var/list/service_queue = list()
	var/list/completed_repairs = list()

/datum/eastwood_repair_shop/proc/submit_for_repair(mob/user, obj/item/item, repair_type)
	var/datum/repair_job/job = new()
	job.owner_ckey = user.ckey
	job.owner_name = user.name
	job.item_ref = WEAKREF(item)
	job.repair_type = repair_type
	job.submitted_time = world.time

	switch(repair_type)
		if("basic")
			job.cost = REPAIR_BASIC
			job.estimated_time = 5 MINUTES
		if("advanced")
			job.cost = REPAIR_BASIC * 3
			job.estimated_time = 15 MINUTES
		if("weapon")
			job.cost = REPAIR_BASIC * 2
			job.estimated_time = 10 MINUTES

	service_queue += job
	return TRUE

/datum/eastwood_repair_shop/proc/complete_repair(job_id)
	for(var/datum/repair_job/J in service_queue)
		if(J.job_id == job_id)
			var/obj/item/item = J.item_ref.resolve()
			if(item)
				item.obj_integrity = item.max_integrity

			J.completed = TRUE
			J.completion_time = world.time

			service_queue -= J
			completed_repairs += J
			return TRUE
	return FALSE

/datum/eastwood_repair_shop/proc/get_user_jobs(ckey)
	var/list/jobs = list()
	for(var/datum/repair_job/J in service_queue)
		if(J.owner_ckey == ckey)
			jobs += J
	return jobs

// ============ REPAIR JOB ============

/datum/repair_job
	var/job_id
	var/owner_ckey
	var/owner_name
	var/datum/weakref/item_ref
	var/repair_type
	var/cost
	var/submitted_time
	var/estimated_time
	var/completed = FALSE
	var/completion_time

// ============ INN TERMINAL ============

/obj/machinery/computer/eastwood_inn
	name = "Eastwood Inn Terminal"
	desc = "A terminal for booking rooms at the inn."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

	var/datum/eastwood_inn/inn = new()

/obj/machinery/computer/eastwood_inn/Initialize(mapload)
	. = ..()
	for(var/i in 1 to 5)
		var/datum/inn_room/room = new()
		room.room_id = "room_[i]"
		room.room_name = "Room [i]"
		room.quality = i <= 2 ? ROOM_STANDARD : ROOM_PREMIUM
		inn.rooms += room

/obj/machinery/computer/eastwood_inn/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/eastwood_inn/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "EastwoodInn")
		ui.open()

/obj/machinery/computer/eastwood_inn/ui_data(mob/user)
	var/list/data = list()

	data["daily_rate"] = INN_ROOM_DAILY
	data["has_room"] = inn.get_guest_room(user.ckey) ? TRUE : FALSE

	var/datum/inn_room/my_room = inn.get_guest_room(user.ckey)
	if(my_room)
		data["my_room"] = list("id" = my_room.room_id, "name" = my_room.room_name, "expiry" = my_room.rent_expiry)

	var/list/rooms_data = list()
	for(var/datum/inn_room/R in inn.rooms)
		rooms_data += list(list("id" = R.room_id, "name" = R.room_name, "occupied" = R.occupied, "quality" = R.quality))
	data["rooms"] = rooms_data

	return data

/obj/machinery/computer/eastwood_inn/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("rent_room")
			var/room_id = params["room_id"]
			var/days = text2num(params["days"]) || 1
			if(inn.rent_room(usr, room_id, days))
				to_chat(usr, span_notice("Room rented for [days] day(s)."))
			else
				to_chat(usr, span_warning("Cannot rent room."))
			return TRUE

		if("check_out")
			var/room_id = params["room_id"]
			if(inn.check_out(room_id))
				to_chat(usr, span_notice("Checked out successfully."))
			return TRUE

	return FALSE

// ============ CLINIC TERMINAL ============

/obj/machinery/computer/eastwood_clinic
	name = "Eastwood Clinic Terminal"
	desc = "A terminal for medical services."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/eastwood_clinic/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/eastwood_clinic/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "EastwoodClinic")
		ui.open()

/obj/machinery/computer/eastwood_clinic/ui_data(mob/user)
	var/list/data = list()

	data["basic_heal_cost"] = CLINIC_BASIC_HEAL
	data["surgery_cost"] = CLINIC_SURGERY

	var/list/treatments = list()
	treatments += list(list("id" = "basic_heal", "name" = "Basic Treatment", "cost" = CLINIC_BASIC_HEAL, "desc" = "Heal wounds and burns"))
	treatments += list(list("id" = "rad_away", "name" = "Radiation Treatment", "cost" = CLINIC_BASIC_HEAL, "desc" = "Remove radiation"))
	treatments += list(list("id" = "surgery", "name" = "Surgery", "cost" = CLINIC_SURGERY, "desc" = "Advanced medical procedure"))
	treatments += list(list("id" = "addiction_treatment", "name" = "Addiction Treatment", "cost" = CLINIC_SURGERY, "desc" = "Cure addictions"))
	data["treatments"] = treatments

	return data

/obj/machinery/computer/eastwood_clinic/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("request_treatment")
			var/treatment = params["treatment"]
			if(GLOB.eastwood_clinic.perform_treatment(usr, treatment, usr))
				to_chat(usr, span_notice("Treatment administered."))
			else
				to_chat(usr, span_warning("Treatment failed."))
			return TRUE

	return FALSE

// ============ REPAIR SHOP TERMINAL ============

/obj/machinery/computer/eastwood_repair
	name = "Eastwood Repair Terminal"
	desc = "A terminal for repair services."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/eastwood_repair/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/eastwood_repair/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "EastwoodRepair")
		ui.open()

/obj/machinery/computer/eastwood_repair/ui_data(mob/user)
	var/list/data = list()

	data["basic_cost"] = REPAIR_BASIC

	var/list/services = list()
	services += list(list("id" = "basic", "name" = "Basic Repair", "cost" = REPAIR_BASIC, "time" = "5 min"))
	services += list(list("id" = "advanced", "name" = "Advanced Repair", "cost" = REPAIR_BASIC * 3, "time" = "15 min"))
	services += list(list("id" = "weapon", "name" = "Weapon Repair", "cost" = REPAIR_BASIC * 2, "time" = "10 min"))
	data["services"] = services

	var/list/my_jobs = list()
	for(var/datum/repair_job/J in GLOB.eastwood_repair.get_user_jobs(user.ckey))
		my_jobs += list(list("id" = J.job_id, "type" = J.repair_type, "cost" = J.cost))
	data["my_jobs"] = my_jobs

	return data

/obj/machinery/computer/eastwood_repair/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("submit_repair")
			var/obj/item/held = usr.get_active_held_item()
			if(!held)
				to_chat(usr, span_warning("Hold the item you want repaired."))
				return TRUE

			var/repair_type = params["repair_type"]
			if(GLOB.eastwood_repair.submit_for_repair(usr, held, repair_type))
				to_chat(usr, span_notice("Item submitted for repair."))
			return TRUE

		if("collect_item")
			var/job_id = params["job_id"]
			if(GLOB.eastwood_repair.complete_repair(job_id))
				to_chat(usr, span_notice("Item repaired and returned."))
			return TRUE

	return FALSE
