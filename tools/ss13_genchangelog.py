"""
tools/ss13_genchangelog.py

Regenerates html/changelog.html from the archive yml files in html/changelogs/archive/.
Called by TGS3.json as:
    python tools/ss13_genchangelog.py html/changelog.html html/changelogs

Also picks up any pending .yml files in the changelogs dir first (same as tools/cl/ss13_genchangelog.py).
"""

import yaml, os, glob, sys, argparse
from datetime import date, datetime

opt = argparse.ArgumentParser()
opt.add_argument('output_html', help='Path to changelog.html to write.')
opt.add_argument('ymlDir',      help='Directory containing changelog ymls and archive/ subdir.')
args = opt.parse_args()

archiveDir = os.path.join(args.ymlDir, 'archive')
today      = date.today()

# --- Step 1: flush any pending one-off yml files into today's archive file ---
for fileName in glob.glob(os.path.join(args.ymlDir, '*.yml')):
    name = os.path.splitext(os.path.basename(fileName))[0]
    if name.startswith('.') or name == 'example':
        continue
    with open(fileName, 'r', encoding='utf-8') as f:
        cl = yaml.safe_load(f)
    if not cl or not cl.get('changes'):
        continue
    monthFile = os.path.join(archiveDir, today.strftime('%Y-%m') + '.yml')
    currentEntries = {}
    if os.path.exists(monthFile):
        with open(monthFile, 'r', encoding='utf-8') as f:
            currentEntries = yaml.safe_load(f) or {}
    if today not in currentEntries:
        currentEntries[today] = {}
    author_entries = currentEntries[today].get(cl['author'], [])
    for change in cl['changes']:
        if change not in author_entries:
            author_entries.append(change)
    currentEntries[today][cl['author']] = author_entries
    with open(monthFile, 'w', encoding='utf-8') as f:
        yaml.dump(currentEntries, f, default_flow_style=False)
    if cl.get('delete-after', False):
        os.remove(fileName)
        print('Merged and deleted: ' + fileName)
    else:
        print('Merged: ' + fileName)

# --- Step 2: read all archive ymls ---
all_entries = {}  # {date: {author: [changes]}}

for monthFile in glob.glob(os.path.join(archiveDir, '*.yml')):
    with open(monthFile, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)
    if not data:
        continue
    for key, authors in data.items():
        # keys may be date objects or strings
        if isinstance(key, str):
            try:
                key = datetime.strptime(key, '%Y-%m-%d').date()
            except ValueError:
                continue
        all_entries[key] = authors

# Sort newest first
sorted_dates = sorted(all_entries.keys(), reverse=True)

# --- Step 3: build the HTML body ---
MONTH_NAMES = ['January','February','March','April','May','June',
			'July','August','September','October','November','December']

def fmt_date(d):
    return '{:02d} {} {}'.format(d.day, MONTH_NAMES[d.month - 1], d.year)

def change_html(change):
    if isinstance(change, dict):
        for prefix, text in change.items():
            return '\t\t\t\t<li class="{}">{}</li>\n'.format(prefix, text)
    return '\t\t\t\t<li class="rscadd">{}</li>\n'.format(change)

body = ''
for d in sorted_dates:
    body += '\n\t\t\t<h2 class="date">{}</h2>\n'.format(fmt_date(d))
    authors = all_entries[d]
    if not isinstance(authors, dict):
        continue
    for author, changes in authors.items():
        body += '\t\t\t<h3 class="author">{} updated:</h3>\n'.format(author)
        body += '\t\t\t<ul class="changes bgimages16">\n'
        if isinstance(changes, list):
            for change in changes:
                body += change_html(change)
        body += '\t\t\t</ul>\n'

# --- Step 4: write changelog.html ---
HEADER = '''<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
	<title>Hail Mary Station 13 Changelog</title>
	<link rel="stylesheet" type="text/css" href="changelog.css">
	<base target="_blank" />
	<script type='text/javascript'>

\tfunction changeText(tagID, newText, linkTagID){
\t\tvar tag = document.getElementById(tagID);
\t\ttag.innerHTML = newText;
\t\tvar linkTag = document.getElementById(linkTagID);
\t\tlinkTag.removeAttribute("href");
\t\tlinkTag.removeAttribute("onclick");
\t}
\t
	</script>  
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
</head>

<body>
<table align='center' width='650'><tr><td>
<table align='center' class="top">
\t<tr>
\t\t<td valign='top'>
\t\t\t<div align='center'><font size='3'><b>Hail Mary Station 13</b></font></div>
\t\t\t<p><div align='center'><font size='3'><a href="https://github.com/Foundation-19/Hail-Mary">Source</a></font></div></p>
\t\t\t</td>
\t</tr>
</table>

\t\t<!--
\t\t
\t\tTO ADD AN ENTRY, ADD AND MAINTAIN YOUR OWN changelog/USERNAME.yml FILE. 
\t\t
\t\t*** DO NOT FUCK WITH THIS FILE OR YOU WILL CAUSE MERGE CONFLICTS. ***
\t\t
\t\t-->
\t\t<div class="commit sansserif">
'''

FOOTER = '''
\t\t</div>
</td></tr></table>
</body>
</html>
'''

output = HEADER + body + FOOTER

with open(args.output_html, 'w', encoding='utf-8') as f:
    f.write(output)

print('Wrote {} entries across {} dates to {}'.format(
    sum(len(all_entries[d].get(a, [])) for d in all_entries for a in (all_entries[d] if isinstance(all_entries[d], dict) else {})),
    len(sorted_dates),
    args.output_html
))
