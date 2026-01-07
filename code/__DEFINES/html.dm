/**
 * HTML SKELETON MACROS
 * 
 * Provides proper HTML5 document structure for browser windows.
 * Required for Chromium compatibility in BYOND 516+.
 * 
 * Usage:
 *   var/list/dat = list()
 *   dat += "<div>Content</div>"
 *   usr << browse(HTML_SKELETON(dat.Join()), "window=name")
 */

/// Full HTML skeleton with custom head and body
#define HTML_SKELETON_INTERNAL(head, body) \
"<!DOCTYPE html><html><head><meta http-equiv='Content-Type' content='text/html; charset=UTF-8'><meta http-equiv='X-UA-Compatible' content='IE=edge'>[head]</head><body>[body]</body></html>"

/// HTML skeleton with title
#define HTML_SKELETON_TITLE(title, body) HTML_SKELETON_INTERNAL("<title>[title]</title>", body)

/// HTML skeleton with just body content (most common)
#define HTML_SKELETON(body) HTML_SKELETON_INTERNAL("", body)
