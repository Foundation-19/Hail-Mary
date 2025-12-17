GLOBAL_VAR_INIT(LOOC_COLOR, null) // If null, use CSS for OOC. Otherwise, custom color
GLOBAL_VAR_INIT(normal_looc_colour, "#6699CC")

/client/verb/looc(msg as text)
    set name = "LOOC"
    set desc = "Local OOC, seen only by those in view."
    set category = "OOC"

    var/mob/controlled = src.mob

    // Only allow LOOC if controlling a living, non-observer mob; this is a privilege to be used in good faith
    if(!controlled || isobserver(controlled))
        to_chat(src, "<span class='danger'>You cannot use LOOC while ghosting or observing.</span>")
        return

    // Sanitize message and enforce max length
    msg = copytext_char(sanitize(msg), 1, MAX_MESSAGE_LEN)
    if(!msg)
        return

    // Check job bans
    if(jobban_isbanned(controlled, "LOOC"))
        to_chat(src, "<span class='danger'>You have been banned from LOOC.</span>")
        return

    // Spam prevention
    if(!holder && handle_spam_prevention(msg, MUTE_OOC))
        return

    // Parse emojis and log the message
    msg = emoji_parse(msg)
    controlled.log_talk(msg, LOG_OOC, tag="LOOC")

    // Send LOOC to living mobs in view
    var/list/heard = get_hearers_in_view(7, get_top_level_mob(controlled))
    for(var/mob/M in heard)
        if(!M.client || isobserver(M))
            continue
        var/client/C = M.client
        if(C in GLOB.admins)
            continue

        if(GLOB.LOOC_COLOR)
            to_chat(C, "<font color='[GLOB.LOOC_COLOR]'><b><span class='prefix'>LOOC:</span> <EM>[controlled.name]:</EM> <span class='message'>[msg]</span></b></font>")
        else
            to_chat(C, "<span class='looc'><span class='prefix'>LOOC:</span> <EM>[controlled.name]:</EM> <span class='message'>[msg]</span></span>")

    // Send LOOC to admins
    for(var/client/C in GLOB.admins)
        var/prefix = "(R)LOOC"
        var/proximity = FALSE
        if(C.mob in heard)
            prefix = "LOOC"
            proximity = TRUE
        if(!proximity && !(C.prefs.chat_toggles & CHAT_REMOTE_LOOC))
            continue

        if(GLOB.LOOC_COLOR)
            to_chat(C, "<font color='[GLOB.LOOC_COLOR]'><b>[ADMIN_FLW(src)] <span class='prefix'>[prefix]:</span> <EM>[src.key]/[controlled.name]:</EM> <span class='message'>[msg]</span></b></font>")
        else
            to_chat(C, "<span class='looc'>[ADMIN_FLW(src)] <span class='prefix'>[prefix]:</span> <EM>[src.key]/[controlled.name]:</EM> <span class='message'>[msg]</span></span>")
