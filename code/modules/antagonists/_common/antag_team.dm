//A barebones antagonist team.
/datum/team
	var/list/datum/mind/members = list()
	var/name = "team"
	var/member_name = "member"
	var/list/objectives = list() //common objectives, these won't be added or removed automatically, subtypes handle this, this is here for bookkeeping purposes.
	var/show_roundend_report = TRUE

/datum/team/New(starting_members)
	. = ..()
	if(starting_members)
		if(islist(starting_members))
			for(var/datum/mind/M in starting_members)
				add_member(M)
		else
			add_member(starting_members)

TYPE_PROC_REF(/datum/team, is_solo)()
	return members.len == 1

TYPE_PROC_REF(/datum/team, add_member)(datum/mind/new_member)
	members |= new_member

TYPE_PROC_REF(/datum/team, remove_member)(datum/mind/member)
	members -= member

//Display members/victory/failure/objectives for the team
TYPE_PROC_REF(/datum/team, roundend_report)()
	if(!show_roundend_report)
		return
	var/list/report = list()

	report += span_header("[name]:")
	report += "The [member_name]s were:"
	report += printplayerlist(members)

	if(objectives.len)
		report += span_header("Team had following objectives:")
		var/win = TRUE
		var/objective_count = 1
		for(var/datum/objective/objective in objectives)
			if(objective.completable)
				var/completion = objective.check_completion()
				if(completion >= 1)
					report += "<B>Objective #[objective_count]</B>: [objective.explanation_text] <span class='greentext'><B>Success!</B></span>"
				else if(completion <= 0)
					report += "<B>Objective #[objective_count]</B>: [objective.explanation_text] <span class='redtext'>Fail.</span>"
					win = FALSE
				else
					report += "<B>Objective #[objective_count]</B>: [objective.explanation_text] <span class='yellowtext'>[completion*100]%</span>"
			else
				report += "<B>Objective #[objective_count]</B>: [objective.explanation_text]"
			objective_count++
		if(win)
			report += span_greentext("The [name] was successful!")
		else
			report += span_redtext("The [name] have failed!")


	return "<div class='panel redborder'>[report.Join("<br>")]</div>"
