// In-game journal for notes and quest tracking

GLOBAL_LIST_INIT(notebooks, list())

#define NOTEBOOK_MAX_ENTRIES 50
#define NOTEBOOK_MAX_ENTRY_LENGTH 1000

/datum/notebook
	var/owner_ckey = ""
	var/list/entries = list()
	var/list/public_entries = list()

/datum/notebook/New(ckey)
	owner_ckey = ckey
	load_from_db()

/datum/notebook/proc/load_from_db()
	if(!SSdbcore.Connect())
		return
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT entry_id, entry_text, is_public, timestamp FROM [format_table_name("notebook_entries")] WHERE ckey = :ckey ORDER BY entry_id DESC",
		list("ckey" = owner_ckey)
	)
	
	if(query.Execute())
		while(query.NextRow())
			var/list/row = query.item
			var/datum/notebook_entry/entry = new()
			entry.id = text2num(row[1])
			entry.text = row[2]
			entry.is_public = (row[3] == "1")
			entry.timestamp = row[4]
			
			entries["[entry.id]"] = entry
			if(entry.is_public)
				public_entries["[entry.id]"] = entry
	
	qdel(query)

/datum/notebook/proc/add_entry(text, is_public = FALSE)
	if(entries.len >= NOTEBOOK_MAX_ENTRIES)
		return FALSE
	
	if(length(text) > NOTEBOOK_MAX_ENTRY_LENGTH)
		text = copytext(text, 1, NOTEBOOK_MAX_ENTRY_LENGTH)
	
	var/datum/notebook_entry/entry = new()
	entry.text = text
	entry.is_public = is_public
	entry.timestamp = time2text(world.realtime, "YYYY-MM-DD HH:MM")
	
	var/new_id = entries.len + 1
	entry.id = new_id
	entries["[new_id]"] = entry
	
	if(is_public)
		public_entries["[new_id]"] = entry
	
	save_entry_to_db(entry)
	return TRUE

/datum/notebook/proc/save_entry_to_db(datum/notebook_entry/entry)
	if(!SSdbcore.Connect())
		return FALSE
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"INSERT INTO [format_table_name("notebook_entries")] (ckey, entry_text, is_public, timestamp) VALUES (:ckey, :text, :public, NOW())",
		list("ckey" = owner_ckey, "text" = entry.text, "public" = entry.is_public ? "1" : "0")
	)
	
	var/success = query.Execute()
	qdel(query)
	return success

/datum/notebook/proc/delete_entry(id)
	var/key = "[id]"
	if(!entries[key])
		return FALSE
	
	if(SSdbcore.Connect())
		var/datum/db_query/query = SSdbcore.NewQuery(
			"DELETE FROM [format_table_name("notebook_entries")] WHERE entry_id = :id AND ckey = :ckey",
			list("id" = id, "ckey" = owner_ckey)
		)
		query.Execute()
		qdel(query)
	
	entries -= key
	public_entries -= key
	
	return TRUE

/datum/notebook_entry
	var/id = 0
	var/text = ""
	var/timestamp = ""
	var/is_public = FALSE

// ============ PROC HELPERS ============

/proc/get_player_notebook(ckey)
	if(!ckey)
		return null
	if(!GLOB.notebooks[ckey])
		GLOB.notebooks[ckey] = new /datum/notebook(ckey)
	return GLOB.notebooks[ckey]

// ============ PLAYER VERBS ============

/client/verb/open_notebook()
	set name = "Notebook"
	set category = "Character"
	set desc = "Open your character notebook"
	
	var/datum/notebook/notebook = get_player_notebook(ckey)
	if(!notebook)
		to_chat(src, span_warning("Could not load notebook."))
		return
	
	show_notebook_ui(usr, notebook)

/client/verb/view_public_notes()
	set name = "Public Notes"
	set category = "Character"
	set desc = "View public notes from other players"
	
	show_public_notes_ui(usr)

/proc/show_public_notes_ui(mob/user)
	var/list/all_public_notes = list()
	
	if(SSdbcore.Connect())
		var/datum/db_query/query = SSdbcore.NewQuery(
			"SELECT ckey, entry_text, timestamp FROM [format_table_name("notebook_entries")] WHERE is_public = '1' ORDER BY entry_id DESC LIMIT 50"
		)
		
		if(query.Execute())
			while(query.NextRow())
				all_public_notes += list(list(
					"ckey" = query.item[1],
					"text" = query.item[2],
					"time" = query.item[3]
				))
		qdel(query)
	
	if(!all_public_notes.len)
		to_chat(user, span_notice("No public notes found."))
		return
	
	var/datum/browser/popup = new(user, "public_notebook", "Public Notes", 600, 500)
	
	var/html = {"
	<!DOCTYPE html>
	<html>
	<head>
		<style>
			body { background: #1a1a1a; color: #cccccc; font-family: "Courier New", monospace; padding: 20px; }
			h1 { color: #66ccff; border-bottom: 1px solid #333366; padding-bottom: 10px; }
			.note { padding: 15px; margin: 10px 0; background: #222233; border: 1px solid #444466; }
			.note-author { color: #66ccff; font-weight: bold; }
			.note-time { color: #666688; font-size: 0.8em; }
			.note-text { color: #ccccdd; margin-top: 10px; white-space: pre-wrap; }
		</style>
	</head>
	<body>
		<h1>Public Notes</h1>
		<p>Notes shared by other wastelanders:</p>
"}
	
	for(var/note in all_public_notes)
		html += "<div class='note'>"
		html += "<div class='note-author'>[note["ckey"]]</div>"
		html += "<div class='note-time'>[note["time"]]</div>"
		html += "<div class='note-text'>[note["text"]]</div>"
		html += "</div>"
	
	html += "</body></html>"
	
	popup.set_content(html)
	popup.open()

/proc/show_notebook_ui(mob/user, datum/notebook/notebook)
	var/datum/browser/popup = new(user, "notebook", "Notebook", 700, 600)
	
	var/html = {"
	<!DOCTYPE html>
	<html>
	<head>
		<style>
			body { background: #1a1a1a; color: #d4a574; font-family: "Courier New", monospace; padding: 20px; }
			h1 { color: #ffcc66; border-bottom: 1px solid #664422; padding-bottom: 10px; }
			.tabs { margin-bottom: 20px; }
			.tab { padding: 10px 20px; background: #221100; color: #996633; border: 1px solid #664422; cursor: pointer; display: inline-block; margin-right: 5px; }
			.tab.active { background: #332211; color: #ffcc66; }
			.entry { padding: 15px; margin: 10px 0; background: #2a1a0a; border: 1px solid #664422; }
			.entry-header { display: flex; justify-content: space-between; color: #996633; margin-bottom: 10px; }
			.entry-public { color: #66ccff; font-size: 0.8em; }
			.entry-text { color: #d4a574; white-space: pre-wrap; }
			.btn { padding: 10px 20px; background: #332211; color: #d4a574; border: 1px solid #664422; cursor: pointer; margin: 5px; }
			.btn:hover { background: #443322; }
			.btn-danger { background: #441111; }
			.btn-danger:hover { background: #662222; }
			textarea { width: 100%; height: 100px; background: #2a1a0a; color: #d4a574; border: 1px solid #664422; padding: 10px; font-family: "Courier New", monospace; resize: vertical; }
			.checkbox-label { color: #d4a574; margin-top: 10px; display: block; }
			.empty { color: #996633; font-style: italic; }
		</style>
	</head>
	<body>
		<h1>Character Notebook</h1>
		<div class="tabs">
			<button class="tab active" onclick="showTab('entries')">My Notes ([notebook.entries.len]/[NOTEBOOK_MAX_ENTRIES])</button>
			<button class="tab" onclick="showTab('add')">Add Entry</button>
			<button class="tab" onclick="window.location='byond://?src=[REF(user.client)];view_public=1'">Public Notes</button>
		</div>
		
		<div id="entries">
"}
	
	if(notebook.entries.len)
		for(var/id in notebook.entries)
			var/datum/notebook_entry/entry = notebook.entries[id]
			html += "<div class='entry'>"
			html += "<div class='entry-header'>"
			html += "<span class='entry-time'>[entry.timestamp]</span>"
			if(entry.is_public)
				html += " <span class='entry-public'>🌐</span>"
			html += "</div>"
			html += "<div class='entry-text'>[entry.text]</div>"
			html += "<button class='btn btn-danger' onclick='window.location=\"byond://?src=[REF(user.client)];notebook_delete=[entry.id]\"'>Delete</button>"
			html += "</div>"
	else
		html += "<p class='empty'>Your notebook is empty. Add an entry to get started!</p>"
	
	html += "</div>"
	
	html += {"
		<div id="add" style="display:none;">
			<h2>New Entry</h2>
			<textarea id="entry_text" placeholder="Write your note here... Quest reminders, roleplay notes, or anything else!" maxlength="[NOTEBOOK_MAX_ENTRY_LENGTH]"></textarea>
			<br>
			<label class="checkbox-label">
				<input type="checkbox" id="entry_public"> Make this entry public (other players can see it)
			</label>
			<br><br>
			<button class="btn" onclick="saveEntry()">Save Entry</button>
		</div>
		
		<script>
			function showTab(tabName) {
				document.getElementById('entries').style.display = tabName === 'entries' ? 'block' : 'none';
				document.getElementById('add').style.display = tabName === 'add' ? 'block' : 'none';
			}
			function saveEntry() {
				var text = document.getElementById('entry_text').value;
				var isPublic = document.getElementById('entry_public').checked ? 1 : 0;
				if(text.trim()) {
					window.location = 'byond://?src=[REF(user.client)];notebook_add=1;text=' + encodeURIComponent(text) + ';public=' + isPublic;
				}
			}
		</script>
	</body>
	</html>
	"}
	
	popup.set_content(html)
	popup.open()

// ============ TOPIC HOOKS ============

/mob/living/carbon/human/Topic(href, href_list)
	if(href_list["notebook_add"])
		var/text = href_list["text"]
		var/is_public = text2num(href_list["public"])
		
		if(text && length(text) > 0)
			var/datum/notebook/notebook = get_player_notebook(ckey)
			if(notebook && notebook.add_entry(text, is_public))
				to_chat(src, span_notice("Entry added to notebook!"))
				if(is_public)
					to_chat(src, span_notice("This entry is now public."))
			else
				to_chat(src, span_warning("Could not add entry. Notebook may be full."))
		else
			to_chat(src, span_warning("Entry cannot be empty."))
	
	if(href_list["notebook_delete"])
		var/id = text2num(href_list["notebook_delete"])
		if(id > 0)
			var/datum/notebook/notebook = get_player_notebook(ckey)
			if(notebook && notebook.delete_entry(id))
				to_chat(src, span_notice("Entry deleted."))
				// Refresh UI
				show_notebook_ui(src, notebook)
	
	if(href_list["view_public"])
		if(client)
			show_public_notes_ui(usr)
	
	. = ..()

// ============ DATABASE SETUP ============

/proc/setup_notebook_db()
	if(!SSdbcore.Connect())
		return FALSE
	
	var/datum/db_query/query = SSdbcore.NewQuery({"
		CREATE TABLE IF NOT EXISTS [format_table_name("notebook_entries")] (
			entry_id INT PRIMARY KEY AUTO_INCREMENT,
			ckey VARCHAR(32) NOT NULL,
			entry_text TEXT NOT NULL,
			is_public TINYINT(1) DEFAULT 0,
			timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
			INDEX idx_ckey (ckey)
		)"}
	)
	
	var/success = query.Execute()
	qdel(query)
	
	return success

/world/proc/init_notebook_system()
	setup_notebook_db()
