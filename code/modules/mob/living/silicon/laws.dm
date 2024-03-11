TYPE_PROC_REF(/mob/living/silicon, show_laws)() //Redefined in ai/laws.dm and robot/laws.dm
	return

TYPE_PROC_REF(/mob/living/silicon, laws_sanity_check)()
	if (!laws)
		make_laws()

TYPE_PROC_REF(/mob/living/silicon, post_lawchange)(announce = TRUE)
	throw_alert("newlaw", /obj/screen/alert/newlaw)
	if(announce && last_lawchange_announce != world.time)
		to_chat(src, "<b>Your laws have been changed.</b>")
		addtimer(CALLBACK(src, PROC_REF(show_laws)), 0)
		last_lawchange_announce = world.time

TYPE_PROC_REF(/mob/living/silicon, set_law_sixsixsix)(law, announce = TRUE)
	laws_sanity_check()
	laws.set_law_sixsixsix(law)
	post_lawchange(announce)

TYPE_PROC_REF(/mob/living/silicon, set_zeroth_law)(law, law_borg, announce = TRUE)
	laws_sanity_check()
	laws.set_zeroth_law(law, law_borg)
	post_lawchange(announce)

TYPE_PROC_REF(/mob/living/silicon, add_inherent_law)(law, announce = TRUE)
	laws_sanity_check()
	laws.add_inherent_law(law)
	post_lawchange(announce)

TYPE_PROC_REF(/mob/living/silicon, clear_inherent_laws)(announce = TRUE)
	laws_sanity_check()
	laws.clear_inherent_laws()
	post_lawchange(announce)

TYPE_PROC_REF(/mob/living/silicon, add_supplied_law)(number, law, announce = TRUE)
	laws_sanity_check()
	laws.add_supplied_law(number, law)
	post_lawchange(announce)

TYPE_PROC_REF(/mob/living/silicon, clear_supplied_laws)(announce = TRUE)
	laws_sanity_check()
	laws.clear_supplied_laws()
	post_lawchange(announce)

TYPE_PROC_REF(/mob/living/silicon, add_ion_law)(law, announce = TRUE)
	laws_sanity_check()
	laws.add_ion_law(law)
	post_lawchange(announce)

TYPE_PROC_REF(/mob/living/silicon, add_hacked_law)(law, announce = TRUE)
	laws_sanity_check()
	laws.add_hacked_law(law)
	post_lawchange(announce)

TYPE_PROC_REF(/mob/living/silicon, replace_random_law)(law, groups, announce = TRUE)
	laws_sanity_check()
	. = laws.replace_random_law(law,groups)
	post_lawchange(announce)

TYPE_PROC_REF(/mob/living/silicon, shuffle_laws)(list/groups, announce = TRUE)
	laws_sanity_check()
	laws.shuffle_laws(groups)
	post_lawchange(announce)

TYPE_PROC_REF(/mob/living/silicon, remove_law)(number, announce = TRUE)
	laws_sanity_check()
	. = laws.remove_law(number)
	post_lawchange(announce)

TYPE_PROC_REF(/mob/living/silicon, clear_ion_laws)(announce = TRUE)
	laws_sanity_check()
	laws.clear_ion_laws()
	post_lawchange(announce)

TYPE_PROC_REF(/mob/living/silicon, clear_hacked_laws)(announce = TRUE)
	laws_sanity_check()
	laws.clear_hacked_laws()
	post_lawchange(announce)

TYPE_PROC_REF(/mob/living/silicon, make_laws)()
	laws = new /datum/ai_laws
	laws.set_laws_config()
	laws.associate(src)

TYPE_PROC_REF(/mob/living/silicon, clear_zeroth_law)(force, announce = TRUE)
	laws_sanity_check()
	laws.clear_zeroth_law(force)
	post_lawchange(announce)

TYPE_PROC_REF(/mob/living/silicon, clear_law_sixsixsix)(force, announce = TRUE)
	laws_sanity_check()
	laws.clear_law_sixsixsix(force)
	post_lawchange(announce)
