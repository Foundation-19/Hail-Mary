//Fallout 13 whatever directory

/atom/var/list/overlays_cache

TYPE_PROC_REF(/atom, add_cached_overlay)(key, overlay)
	if(!overlays_cache)
		overlays_cache = list()
	if(!overlays_cache.Find(key))
		overlays_cache[key] = list()
	overlays_cache[key] += overlay
	overlays += overlay

TYPE_PROC_REF(/atom, remove_cached_overlay)(key)
	if(!overlays_cache || !overlays_cache.Find(key))
		return
	overlays -= overlays_cache[key]
	overlays_cache.Remove(key)
	if(!overlays_cache.len)
		overlays_cache = null
