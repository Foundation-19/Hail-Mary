/datum/news/feed_channel
	var/channel_name = ""
	var/list/datum/news/feed_message/messages = list()
	var/locked = FALSE
	var/censored = 0
	var/list/authorCensorTime = list()
	var/list/DclassCensorTime = list()
	var/authorCensor
	var/is_admin_channel = 0

TYPE_PROC_REF(/datum/news/feed_channel, returnAuthor)(censor)
	if(censor == -1)
		censor = authorCensor
	var/txt = "[GLOB.news_network.redactedText]"
	if(!censor)
		txt = author
	return txt

TYPE_PROC_REF(/datum/news/feed_channel, toggleCensorDclass)()
	if(censored)
		DclassCensorTime.Add(GLOB.news_network.lastAction*-1)
	else
		DclassCensorTime.Add(GLOB.news_network.lastAction)
	censored = !censored
	GLOB.news_network.lastAction ++

TYPE_PROC_REF(/datum/news/feed_channel, toggleCensorAuthor)()
	if(authorCensor)
		authorCensorTime.Add(GLOB.news_network.lastAction*-1)
	else
		authorCensorTime.Add(GLOB.news_network.lastAction)
	authorCensor = !authorCensor
	GLOB.news_network.lastAction ++
