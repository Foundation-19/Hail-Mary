SUBSYSTEM_DEF(assets)
	name = "Assets"
	init_order = INIT_ORDER_ASSETS
	flags = SS_NO_FIRE
	var/list/cache = list()
	var/list/preload = list()
	var/datum/asset_transport/transport = new()

/datum/controller/subsystem/assets/OnConfigLoad()
	var/newtransporttype = /datum/asset_transport
	switch (CONFIG_GET(string/asset_transport))
		if ("webroot")
			newtransporttype = /datum/asset_transport/webroot
	
	if (newtransporttype == transport.type)
		return

	var/datum/asset_transport/newtransport = new newtransporttype ()
	if (newtransport.validate_config())
		transport = newtransport
	transport.Load()



/datum/controller/subsystem/assets/Initialize(timeofday)
	var/current_rev = rustg_git_revparse("HEAD")
	if(current_rev && current_rev == trim(file2text("data/asset_cache_rev.txt")))
		var/cached_json = file2text("data/asset_cache_hashes.json")
		if(cached_json)
			GLOB.asset_hash_preload = json_decode(cached_json) || list()

	for(var/type in typesof(/datum/asset))
		var/datum/asset/A = type
		if (type != initial(A._abstract))
			get_asset_datum(type)

	transport.Initialize(cache)

	if(current_rev)
		var/list/hash_map = list()
		for(var/name in cache)
			var/datum/asset_cache_item/ACI = cache[name]
			hash_map[name] = ACI.hash
		rustg_file_write(json_encode(hash_map), "data/asset_cache_hashes.json")
		rustg_file_write(current_rev, "data/asset_cache_rev.txt")

	GLOB.asset_hash_preload = list()
	..()
