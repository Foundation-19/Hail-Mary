#!/usr/bin/env python3
"""Add roleplay module includes to hailmary.m.dme"""

import os

dme_path = os.path.join(os.path.dirname(__file__), "hailmary.m.dme")

roleplay_includes = [
    'code\\modules\\roleplay\\faction_definitions.dm',
    'code\\modules\\roleplay\\reputation.dm',
    'code\\modules\\roleplay\\karma.dm',
    'code\\modules\\roleplay\\karma_triggers.dm',
    'code\\modules\\roleplay\\karma_history.dm',
    'code\\modules\\roleplay\\karma_events.dm',
    'code\\modules\\roleplay\\backgrounds.dm',
    'code\\modules\\roleplay\\reputation_actions.dm',
    'code\\modules\\roleplay\\reputation_effects.dm',
    'code\\modules\\roleplay\\roleplay.dm',
    'code\\modules\\roleplay\\level_system.dm',
    'code\\modules\\roleplay\\level_system_db.dm',
    'code\\modules\\roleplay\\dialogue_loader.dm',
    'code\\modules\\roleplay\\npc_memory.dm',
    'code\\modules\\roleplay\\npc_attitude.dm',
    'code\\modules\\roleplay\\dialogue_services.dm',
    'code\\modules\\roleplay\\dialogue_system.dm',
    'code\\modules\\roleplay\\quest_system.dm',
    'code\\modules\\roleplay\\trade_system.dm',
    'code\\modules\\roleplay\\companions.dm',
    'code\\modules\\roleplay\\player_shops.dm',
    'code\\modules\\roleplay\\notebook.dm',
    'code\\modules\\roleplay\\relationships.dm',
    'code\\modules\\roleplay\\speech.dm',
    'code\\modules\\roleplay\\emotes.dm',
    'code\\modules\\roleplay\\bounty_system.dm',
    'code\\modules\\roleplay\\player_stats.dm',
    'code\\modules\\roleplay\\admin_verbs.dm',
]

# Read the file
with open(dme_path, 'r', encoding='utf-8', newline='') as f:
    lines = f.readlines()

# Check if roleplay already included BEFORE persistence.dm
found_roleplay = False
persistence_line = -1
for i, line in enumerate(lines):
    if 'roleplay' in line:
        found_roleplay = True
        break
    if 'persistence.dm' in line:
        persistence_line = i
        break

if not found_roleplay and persistence_line > 0:
    # Insert roleplay includes before persistence.dm
    new_lines = lines[:persistence_line]
    for inc in roleplay_includes:
        new_lines.append(f'#include "{inc}"\r\n')
    new_lines.extend(lines[persistence_line:])
    
    with open(dme_path, 'w', encoding='utf-8', newline='') as f:
        f.writelines(new_lines)
    
    print(f"Done! Added {len(roleplay_includes)} roleplay includes.")
else:
    print("Roleplay includes already present or no insertion point found.")
