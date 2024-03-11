// See _DEFINES/is_helpers.dm for type helpers

/*
Name:	IsSpecialAssembly
Desc:	If true is an object that can be attached to an assembly holder but is a special thing like a plasma can or door
*/

TYPE_PROC_REF(/obj, IsSpecialAssembly)()
	return FALSE

/*
Name:	IsAssemblyHolder
Desc:	If true is an object that can hold an assemblyholder object
*/
TYPE_PROC_REF(/obj, IsAssemblyHolder)()
	return FALSE
