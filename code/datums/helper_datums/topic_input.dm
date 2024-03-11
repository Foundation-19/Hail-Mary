/datum/topic_input
	var/href
	var/list/href_list

/datum/topic_input/New(thref,list/thref_list)
	href = thref
	href_list = thref_list.Copy()
	return

TYPE_PROC_REF(/datum/topic_input, get)(i)
	return listgetindex(href_list,i)

TYPE_PROC_REF(/datum/topic_input, getAndLocate)(i)
	var/t = get(i)
	if(t)
		t = locate(t)
	if (istext(t))
		t = null
	return t || null

TYPE_PROC_REF(/datum/topic_input, getNum)(i)
	var/t = get(i)
	if(t)
		t = text2num(t)
	return isnum(t) ? t : null

TYPE_PROC_REF(/datum/topic_input, getObj)(i)
	var/t = getAndLocate(i)
	return isobj(t) ? t : null

TYPE_PROC_REF(/datum/topic_input, getMob)(i)
	var/t = getAndLocate(i)
	return ismob(t) ? t : null

TYPE_PROC_REF(/datum/topic_input, getTurf)(i)
	var/t = getAndLocate(i)
	return isturf(t) ? t : null

TYPE_PROC_REF(/datum/topic_input, getAtom)(i)
	return getType(i, /atom)

TYPE_PROC_REF(/datum/topic_input, getArea)(i)
	var/t = getAndLocate(i)
	return isarea(t) ? t : null

TYPE_PROC_REF(/datum/topic_input, getStr)(i)//params should always be text, but...
	var/t = get(i)
	return istext(t) ? t : null

TYPE_PROC_REF(/datum/topic_input, getType)(i,type)
	var/t = getAndLocate(i)
	return istype(t,type) ? t : null

TYPE_PROC_REF(/datum/topic_input, getPath)(i)
	var/t = get(i)
	if(t)
		t = text2path(t)
	return ispath(t) ? t : null

TYPE_PROC_REF(/datum/topic_input, getList)(i)
	var/t = getAndLocate(i)
	return islist(t) ? t : null
