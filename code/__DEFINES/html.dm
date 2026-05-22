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
"<!DOCTYPE html><html><head><meta http-equiv='Content-Type' content='text/html; charset=UTF-8'><meta http-equiv='X-UA-Compatible' content='IE=edge'><link href='https://fonts.googleapis.com/css2?family=VT323&display=swap' rel='stylesheet'>[head]</head><body style='margin:0;padding:15px;background:linear-gradient(#0a0f0a,#050a05);font-family:VT323,Courier New,monospace;font-size:18px;color:#4cff4c;min-height:100vh'><style>body::before{content:'';position:fixed;top:0;left:0;width:100%;height:100%;pointer-events:none;background:repeating-linear-gradient(0deg,transparent,transparent 1px,rgba(0,0,0,0.2) 1px,rgba(0,0,0,0.2) 2px);z-index:9999}a{color:#4cff4c;text-decoration:none;border-bottom:1px solid #3ac83a}a:hover{color:#6bff6b;background:rgba(74,255,76,0.1)}b,strong{color:#6bff6b}hr{border:none;border-top:1px solid #3ac83a;margin:10px 0}table{border-collapse:collapse}td,th{padding:5px;border:1px solid #3ac83a}tr:nth-child(even){background:rgba(74,255,76,0.05)}input{background:#050a05;border:1px solid #3ac83a;color:#4cff4c;font-family:VT323,Courier New,monospace;padding:5px}</style>[body]</body></html>"

/// HTML skeleton with title
#define HTML_SKELETON_TITLE(title, body) HTML_SKELETON_INTERNAL("<title>[title]</title>", body)

/// HTML skeleton with just body content (most common)
#define HTML_SKELETON(body) HTML_SKELETON_INTERNAL("", body)
