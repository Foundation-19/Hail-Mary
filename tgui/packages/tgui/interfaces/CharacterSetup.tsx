/* eslint-disable max-len */
/* eslint-disable indent */
/* eslint-disable react/jsx-indent */
/* eslint-disable react/jsx-closing-tag-location */
import { useBackend, useLocalState } from '../backend';
import {
  Box, Button, Section, Input, Flex,
  ProgressBar, Dropdown, TextArea, Divider,
} from '../components';
import { Window } from '../layouts';

const TAB_CHARACTER = 0;
const TAB_GAMEPREFS = 1;
const TAB_APPEARANCE = 2;
const TAB_LOADOUT = 3;
const TAB_KEYBINDS = 4;

type CharacterSetupData = {
  current_tab: number;
  real_name: string;
  gender: string;
  age: number;
  species: string;
  be_random_name: boolean;
  be_random_body: boolean;
  special_remaining: number;
  special_strength: number;
  special_perception: number;
  special_endurance: number;
  special_charisma: number;
  special_intelligence: number;
  special_agility: number;
  special_luck: number;
  jobs: JobData[];
  factions: string[];
  quirks: string[];
  quirks_available: QuirkInfo[];
  quirk_balance: number;
  current_slot: number;
  slot_names: string[];
  max_slots: number;
  hair_style: string;
  hair_color: string;
  facial_hair_style: string;
  facial_hair_color: string;
  eye_color: string;
  skin_tone: string;
  flavor_text: string;
  underwear: string;
  undershirt: string;
  socks: string;
  backpack: string;
  species_list: string[];
  hair_styles: string[];
  facial_hair_styles: string[];
  skin_tones: string[];
  underwear_list: string[];
  undershirt_list: string[];
  socks_list: string[];
  ui_style: string;
  lobby_music: boolean;
  ambience: boolean;
  chat_on_map: boolean;
  hotkeys: boolean;
  ghost_form: string;
  ghost_orbit: string;
  ghost_forms: string[];
  ghost_orbits: string[];
  loadout_points: number;
  loadout_used: number;
  loadout_categories: string[];
  loadout_subcategories: Record<string, string[]>;
  loadout_items: Record<string, Record<string, LoadoutItemData[]>>;
  loadout_selected: string[];
  keybind_categories: string[];
  keybindings: Record<string, KeybindData[]>;
};

type JobData = {
  title: string;
  faction: string;
  preference: string;
  banned: boolean;
};

type QuirkInfo = {
  id: string;
  name: string;
  desc: string;
  value: number;
};

type LoadoutItemData = {
  name: string;
  path: string;
  cost: number;
  description: string;
};

type KeybindData = {
  name: string;
  desc: string;
  keys: string[];
};

export const CharacterSetup = (props, context) => {
  const { act, data } = useBackend<CharacterSetupData>(context);
  const {
    current_tab = TAB_CHARACTER,
    real_name = '',
    gender = 'male',
    age = 30,
    species = 'Human',
    be_random_name = false,
    be_random_body = false,
    special_remaining = 5,
    special_strength = 5,
    special_perception = 5,
    special_endurance = 5,
    special_charisma = 5,
    special_intelligence = 5,
    special_agility = 5,
    special_luck = 5,
    jobs = [],
    factions = [],
    quirks = [],
    quirks_available = [],
    quirk_balance = 5,
    current_slot = 1,
    slot_names = [],
    max_slots = 30,
    hair_style = 'Bald',
    hair_color = '#000000',
    facial_hair_style = 'Shaved',
    facial_hair_color = '#000000',
    eye_color = '#000000',
    skin_tone = 'caucasian1',
    flavor_text = '',
    underwear = 'Nude',
    undershirt = 'Nude',
    socks = 'Nude',
    backpack = 'Backpack',
    species_list = [],
    hair_styles = [],
    facial_hair_styles = [],
    skin_tones = [],
    underwear_list = [],
    undershirt_list = [],
    socks_list = [],
    ui_style = 'Midnight',
    lobby_music = true,
    ambience = true,
    chat_on_map = true,
    hotkeys = true,
    ghost_form = 'ghost',
    ghost_orbit = 'circle',
    ghost_forms = [],
    ghost_orbits = [],
    loadout_points = 12,
    loadout_used = 0,
    loadout_categories = [],
    loadout_subcategories = {},
    loadout_items = {},
    loadout_selected = [],
    keybind_categories = [],
    keybindings = {},
  } = data;

  const [nameInput, setNameInput] = useLocalState(context, 'nameInput', real_name);
  const [selectedFaction, setSelectedFaction] = useLocalState(context, 'selFaction', 'All');
  const [selectedQuirkType, setSelectedQuirkType] = useLocalState(context, 'selQuirkType', 'positive');
  const [selectedLoadoutCat, setSelectedLoadoutCat] = useLocalState(context, 'selLoadoutCat', loadout_categories[0] || '');
  const [selectedLoadoutSub, setSelectedLoadoutSub] = useLocalState(context, 'selLoadoutSub', '');
  const [selectedKeybindCat, setSelectedKeybindCat] = useLocalState(context, 'selKeybindCat', keybind_categories[0] || 'Movement');

  const specials = [
    { key: 'strength', name: 'Strength', value: special_strength },
    { key: 'perception', name: 'Perception', value: special_perception },
    { key: 'endurance', name: 'Endurance', value: special_endurance },
    { key: 'charisma', name: 'Charisma', value: special_charisma },
    { key: 'intelligence', name: 'Intelligence', value: special_intelligence },
    { key: 'agility', name: 'Agility', value: special_agility },
    { key: 'luck', name: 'Luck', value: special_luck },
  ];

  const filteredJobs = selectedFaction === 'All' ? jobs : jobs.filter(j => j.faction === selectedFaction);
  const filteredQuirks = quirks_available.filter(q => 
    selectedQuirkType === 'positive' ? q.value > 0
      : selectedQuirkType === 'negative' ? q.value < 0 : q.value === 0
  );
  const loadoutSubs = loadout_subcategories[selectedLoadoutCat] || [];
  const loadoutItemList = loadout_items[selectedLoadoutCat]?.[selectedLoadoutSub] || [];
  const keybindList = keybindings[selectedKeybindCat] || [];
  const slots = slot_names.length > 0 ? slot_names : Array.from({ length: Math.min(5, max_slots) }, (_, i) => `Slot ${i + 1}`);

  const tabs = ['CHARACTER', 'GAME PREFS', 'APPEARANCE', 'LOADOUT', 'KEYBINDS'];

  return (
    <Window width={1200} height={700} title="ROBCO TERMINAL" theme="fallout" resizable>
      <div className="CharacterSetup__left">
        <Window.Content scrollable>
          <Box>
            <Box
              className="CharacterSetup__header"
            >
              ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
              <span style={{ float: 'right' }}>
                <Button content="[X]" color="bad" onClick={() => act('close')} style={{ 'margin-right': '10px' }} />
                VAULT-TEC CORP
              </span>
            </Box>

            <Flex mb={2}>
              {tabs.map((tab, i) => (
                <Flex.Item key={i} grow>
                  <Button
                    fluid
                    content={tab}
                    selected={current_tab === i}
                    onClick={() => act('set_tab', { tab: i })}
                    style={{
                      'font-family': 'VT323, monospace',
                      'text-align': 'center',
                      padding: '10px 5px',
                      'border-radius': 0,
                    }}
                  />
                </Flex.Item>
              ))}
            </Flex>

            {current_tab === TAB_CHARACTER && (
              <Box>
                <Section title="> IDENTITY">
                  <Flex align="center" mb={1}>
                    <Flex.Item basis="80px" style={{ color: '#4cff4c' }}>NAME:</Flex.Item>
                    <Flex.Item grow>
                      <Input value={nameInput} onInput={(_, v) => setNameInput(v)} fluid />
                    </Flex.Item>
                    <Button content="SET" onClick={() => act('set_name', { name: nameInput })} />
                    <Button content="RAND" onClick={() => act('randomize_name')} />
                  </Flex>
                  <Flex align="center" mb={1}>
                    <Flex.Item basis="80px" style={{ color: '#4cff4c' }}>GENDER:</Flex.Item>
                    {['male', 'female', 'other'].map(g => (
                      <Button key={g} content={g.toUpperCase()} selected={gender === g} onClick={() => act('set_gender', { gender: g })} />
                    ))}
                  </Flex>
                  <Flex align="center" mb={1}>
                    <Flex.Item basis="80px" style={{ color: '#4cff4c' }}>AGE:</Flex.Item>
                    <Button compact content="-" onClick={() => act('adjust_age', { delta: -1 })} />
                    <Box as="span" style={{ margin: '0 15px' }}>{age}</Box>
                    <Button compact content="+" onClick={() => act('adjust_age', { delta: 1 })} />
                  </Flex>
                  <Flex align="center">
                    <Flex.Item basis="80px" style={{ color: '#4cff4c' }}>RANDOM:</Flex.Item>
                    <Button content={be_random_name ? 'YES' : 'NO'} selected={be_random_name} onClick={() => act('toggle_random_name')} />
                  </Flex>
                </Section>

                <Section title="> S.P.E.C.I.A.L." buttons={<Button content="RESET" onClick={() => act('reset_special')} />}>
                  <Box style={{ color: '#ffaa00', 'margin-bottom': '10px' }}>POINTS: {special_remaining}</Box>
                  {specials.map(s => (
                    <Flex key={s.key} align="center" mb={1}>
                      <Flex.Item basis="120px" style={{ color: '#4cff4c' }}>{s.name.toUpperCase()}</Flex.Item>
                      <Flex.Item grow>
                        <ProgressBar value={s.value} minValue={1} maxValue={10} color="#4cff4c" style={{ height: '18px' }}>
                          <Box style={{ 'text-align': 'center' }}>{s.value}</Box>
                        </ProgressBar>
                      </Flex.Item>
                      <Button compact content="-" onClick={() => act('adjust_special', { stat: s.key, delta: -1 })} />
                      <Button compact content="+" onClick={() => act('adjust_special', { stat: s.key, delta: 1 })} />
                    </Flex>
                  ))}
                </Section>

                <Section title="> OCCUPATION">
                  <Flex mb={1} wrap>
                    <Button content="ALL" selected={selectedFaction === 'All'} onClick={() => setSelectedFaction('All')} />
                    {factions.map(f => (
                      <Button key={f} content={f} selected={selectedFaction === f} onClick={() => setSelectedFaction(f)} />
                    ))}
                  </Flex>
                  <Box style={{ 'max-height': '150px', 'overflow-y': 'auto' }}>
                    {filteredJobs.map(job => (
                      <Flex key={job.title} align="center" style={{ padding: '2px 0', 'border-bottom': '1px solid #1a2a1a' }}>
                        <Flex.Item grow style={{ color: job.banned ? '#ff6b6b' : '#a8d8a8' }}>{job.title}</Flex.Item>
                        <Button
                          compact
                          content={job.banned ? 'BANNED' : job.preference || 'NEVER'}
                          color={job.banned ? 'bad' : job.preference === 'HIGH' ? 'blue' : job.preference === 'MEDIUM' ? 'good' : job.preference === 'LOW' ? 'average' : 'bad'}
                          disabled={job.banned}
                          onClick={() => {
                            if (job.banned) return;
                            const next = job.preference === 'HIGH' ? 'NEVER' : job.preference === 'MEDIUM' ? 'HIGH' : job.preference === 'LOW' ? 'MEDIUM' : 'LOW';
                            act('set_job_pref', { job: job.title, level: next });
                          }}
                        />
                      </Flex>
                    ))}
                  </Box>
                </Section>

                <Section title={`> QUIRKS (Balance: ${quirk_balance})`}>
                  <Flex mb={1}>
                    <Button content="POSITIVE" selected={selectedQuirkType === 'positive'} onClick={() => setSelectedQuirkType('positive')} />
                    <Button content="NEGATIVE" selected={selectedQuirkType === 'negative'} onClick={() => setSelectedQuirkType('negative')} />
                    <Button content="NEUTRAL" selected={selectedQuirkType === 'neutral'} onClick={() => setSelectedQuirkType('neutral')} />
                  </Flex>
                  <Box style={{ 'max-height': '120px', 'overflow-y': 'auto' }}>
                    {filteredQuirks.map(q => (
                      <Box
                        key={q.id}
                        style={{
                          padding: '6px',
                          margin: '4px 0',
                          cursor: 'pointer',
                          'background-color': quirks.includes(q.id) ? 'rgba(76, 255, 76, 0.15)' : 'transparent',
                          border: quirks.includes(q.id) ? '2px solid #4cff4c' : '1px solid #2a4a2a',
                        }}
                        onClick={() => act('toggle_quirk', { quirk: q.id })}
                      >
                        <Flex justify="space-between">
                          <Flex.Item style={{ 'font-weight': 'bold', color: '#4cff4c' }}>{q.name}</Flex.Item>
                          <Flex.Item style={{ color: q.value > 0 ? '#4cff4c' : q.value < 0 ? '#ff6b6b' : '#888' }}>
                            {q.value > 0 ? '+' : ''}{q.value}
                          </Flex.Item>
                        </Flex>
                        <Box style={{ 'font-size': '11px', color: '#888', 'margin-top': '3px' }}>{q.desc}</Box>
                      </Box>
                    ))}
                  </Box>
                </Section>

                <Section title="> SLOTS">
                  <Flex wrap>
                    {slots.map((name, i) => (
                      <Flex.Item key={i} basis="33%">
                        <Button
                          fluid
                          content={name}
                          selected={current_slot === i + 1}
                          onClick={() => act('select_slot', { slot: i + 1 })}
                          style={{ 'margin-bottom': '5px' }}
                        />
                      </Flex.Item>
                    ))}
                  </Flex>
                  <Divider />
                  <Button content="> SAVE" color="good" onClick={() => act('save_preferences')} />
                  <Button content="> LOAD" onClick={() => act('load_preferences')} style={{ 'margin-left': '10px' }} />
                </Section>
              </Box>
            )}

            {current_tab === TAB_GAMEPREFS && (
              <Box>
                <Section title="> UI">
                  <Flex align="center" mb={1}>
                    <Flex.Item basis="150px" style={{ color: '#4cff4c' }}>UI STYLE:</Flex.Item>
                    {['Midnight', 'Plasmafire', 'Retro'].map(s => (
                      <Button key={s} content={s} selected={ui_style === s} onClick={() => act('set_ui_style', { style: s })} />
                    ))}
                  </Flex>
                  <Flex align="center">
                    <Flex.Item basis="150px" style={{ color: '#4cff4c' }}>HOTKEYS:</Flex.Item>
                    <Button content={hotkeys ? 'ON' : 'OFF'} selected={hotkeys} onClick={() => act('toggle_hotkeys')} />
                  </Flex>
                </Section>

                <Section title="> AUDIO">
                  <Flex align="center" mb={1}>
                    <Flex.Item basis="150px" style={{ color: '#4cff4c' }}>LOBBY MUSIC:</Flex.Item>
                    <Button content={lobby_music ? 'ON' : 'OFF'} selected={lobby_music} onClick={() => act('toggle_lobby_music')} />
                  </Flex>
                  <Flex align="center">
                    <Flex.Item basis="150px" style={{ color: '#4cff4c' }}>AMBIENCE:</Flex.Item>
                    <Button content={ambience ? 'ON' : 'OFF'} selected={ambience} onClick={() => act('toggle_ambience')} />
                  </Flex>
                </Section>

                <Section title="> CHAT">
                  <Flex align="center">
                    <Flex.Item basis="150px" style={{ color: '#4cff4c' }}>RUNECHAT:</Flex.Item>
                    <Button content={chat_on_map ? 'ON' : 'OFF'} selected={chat_on_map} onClick={() => act('toggle_chat_on_map')} />
                  </Flex>
                </Section>

                <Section title="> GHOST">
                  <Flex align="center" mb={1}>
                    <Flex.Item basis="150px" style={{ color: '#4cff4c' }}>FORM:</Flex.Item>
                    <Dropdown options={ghost_forms} selected={ghost_form} onSelected={v => act('set_ghost_form', { form: v })} width="150px" />
                  </Flex>
                  <Flex align="center">
                    <Flex.Item basis="150px" style={{ color: '#4cff4c' }}>ORBIT:</Flex.Item>
                    <Dropdown options={ghost_orbits} selected={ghost_orbit} onSelected={v => act('set_ghost_orbit', { orbit: v })} width="150px" />
                  </Flex>
                </Section>
              </Box>
            )}

            {current_tab === TAB_APPEARANCE && (
              <Box>
                <Section title="> FLAVOR TEXT">
                  <Flex align="center" justify="space-between">
                    <Flex.Item style={{ color: flavor_text ? '#4cff4c' : '#888' }}>
                      {flavor_text ? `${flavor_text.length} characters` : 'Not set'}
                    </Flex.Item>
                    <Button
                      content={flavor_text ? '> EDIT' : '> CREATE'}
                      onClick={() => act('open_flavor_editor')}
                    />
                  </Flex>
                </Section>

                <Section title="> BODY">
                  <Flex align="center" mb={1}>
                    <Flex.Item basis="100px" style={{ color: '#4cff4c' }}>SPECIES:</Flex.Item>
                    <Dropdown options={species_list} selected={species} onSelected={v => act('set_species', { species: v })} width="200px" />
                  </Flex>
                  <Flex align="center" mb={1}>
                    <Flex.Item basis="100px" style={{ color: '#4cff4c' }}>SKIN:</Flex.Item>
                    <Dropdown options={skin_tones} selected={skin_tone} onSelected={v => act('set_skin_tone', { tone: v })} width="200px" />
                  </Flex>
                  <Flex align="center">
                    <Flex.Item basis="100px" style={{ color: '#4cff4c' }}>RANDOM:</Flex.Item>
                    <Button content={be_random_body ? 'YES' : 'NO'} selected={be_random_body} onClick={() => act('toggle_random_body')} />
                    <Button content="RANDOMIZE" onClick={() => act('randomize_body')} style={{ 'margin-left': '10px' }} />
                  </Flex>
                </Section>

                <Section title="> HAIR">
                  <Flex align="center" mb={1}>
                    <Flex.Item basis="100px" style={{ color: '#4cff4c' }}>STYLE:</Flex.Item>
                    <Dropdown options={hair_styles} selected={hair_style} onSelected={v => act('set_hair_style', { style: v })} width="200px" />
                  </Flex>
                  <Flex align="center" mb={1}>
                    <Flex.Item basis="100px" style={{ color: '#4cff4c' }}>COLOR:</Flex.Item>
                    <Input value={hair_color} onInput={(_, v) => act('set_hair_color', { color: v })} width="100px" />
                    <Box style={{ width: '20px', height: '20px', 'background-color': hair_color, border: '1px solid #4cff4c', 'margin-left': '10px' }} />
                  </Flex>
                  <Flex align="center" mb={1}>
                    <Flex.Item basis="100px" style={{ color: '#4cff4c' }}>FACIAL:</Flex.Item>
                    <Dropdown options={facial_hair_styles} selected={facial_hair_style} onSelected={v => act('set_facial_hair', { style: v })} width="200px" />
                  </Flex>
                  <Flex align="center">
                    <Flex.Item basis="100px" style={{ color: '#4cff4c' }}>F. COLOR:</Flex.Item>
                    <Input value={facial_hair_color} onInput={(_, v) => act('set_facial_hair_color', { color: v })} width="100px" />
                    <Box style={{ width: '20px', height: '20px', 'background-color': facial_hair_color, border: '1px solid #4cff4c', 'margin-left': '10px' }} />
                  </Flex>
                </Section>

                <Section title="> EYES">
                  <Flex align="center">
                    <Flex.Item basis="100px" style={{ color: '#4cff4c' }}>COLOR:</Flex.Item>
                    <Input value={eye_color} onInput={(_, v) => act('set_eye_color', { color: v })} width="100px" />
                    <Box style={{ width: '20px', height: '20px', 'background-color': eye_color, border: '1px solid #4cff4c', 'margin-left': '10px' }} />
                  </Flex>
                </Section>

                <Section title="> UNDERWEAR">
                  <Flex align="center" mb={1}>
                    <Flex.Item basis="100px" style={{ color: '#4cff4c' }}>UNDER:</Flex.Item>
                    <Dropdown options={underwear_list} selected={underwear} onSelected={v => act('set_underwear', { style: v })} width="200px" />
                  </Flex>
                  <Flex align="center" mb={1}>
                    <Flex.Item basis="100px" style={{ color: '#4cff4c' }}>SHIRT:</Flex.Item>
                    <Dropdown options={undershirt_list} selected={undershirt} onSelected={v => act('set_undershirt', { style: v })} width="200px" />
                  </Flex>
                  <Flex align="center">
                    <Flex.Item basis="100px" style={{ color: '#4cff4c' }}>SOCKS:</Flex.Item>
                    <Dropdown options={socks_list} selected={socks} onSelected={v => act('set_socks', { style: v })} width="200px" />
                  </Flex>
                </Section>

                <Section title="> EQUIPMENT">
                  <Flex align="center">
                    <Flex.Item basis="100px" style={{ color: '#4cff4c' }}>BACKPACK:</Flex.Item>
                    <Dropdown options={['Backpack', 'Satchel', 'Duffel']} selected={backpack} onSelected={v => act('set_backpack', { style: v })} width="200px" />
                  </Flex>
                </Section>
              </Box>
            )}

            {current_tab === TAB_LOADOUT && (
              <Box>
                <Section title={`> LOADOUT (${loadout_points - loadout_used} pts)`}>
                  <Flex mb={1} wrap>
                    {loadout_categories.map(cat => (
                      <Button
                        key={cat}
                        content={cat}
                        selected={selectedLoadoutCat === cat}
                        onClick={() => {
                          setSelectedLoadoutCat(cat);
                          const subs = loadout_subcategories[cat] || [];
                          setSelectedLoadoutSub(subs[0] || '');
                        }}
                      />
                    ))}
                  </Flex>
                  {loadoutSubs.length > 0 && (
                    <Flex mb={1} wrap>
                      {loadoutSubs.map(sub => (
                        <Button key={sub} content={sub} selected={selectedLoadoutSub === sub} onClick={() => setSelectedLoadoutSub(sub)} />
                      ))}
                    </Flex>
                  )}
                  <Divider />
                  <Box style={{ 'max-height': '200px', 'overflow-y': 'auto' }}>
                    {loadoutItemList.map(item => {
                      const isSelected = loadout_selected.includes(item.path);
                      return (
                        <Box
                          key={item.path}
                          style={{
                            padding: '8px',
                            margin: '4px 0',
                            cursor: 'pointer',
                            'background-color': isSelected ? 'rgba(76, 255, 76, 0.15)' : 'transparent',
                            border: isSelected ? '2px solid #4cff4c' : '1px solid #2a4a2a',
                          }}
                          onClick={() => act('toggle_loadout_item', { path: item.path })}
                        >
                          <Flex justify="space-between">
                            <Flex.Item style={{ 'font-weight': 'bold', color: '#4cff4c' }}>{item.name}</Flex.Item>
                            <Flex.Item style={{ color: '#ffaa00' }}>{item.cost} pts</Flex.Item>
                          </Flex>
                          {item.description && <Box style={{ 'font-size': '11px', color: '#888', 'margin-top': '3px' }}>{item.description}</Box>}
                        </Box>
                      );
                    })}
                  </Box>
                  <Divider />
                  <Button content="> CLEAR ALL" color="bad" onClick={() => act('clear_loadout')} />
                </Section>
              </Box>
            )}

            {current_tab === TAB_KEYBINDS && (
              <Box>
                <Section title="> KEYBINDINGS">
                  <Flex mb={1} wrap>
                    {keybind_categories.map(cat => (
                      <Button key={cat} content={cat} selected={selectedKeybindCat === cat} onClick={() => setSelectedKeybindCat(cat)} />
                    ))}
                  </Flex>
                  <Box style={{ 'max-height': '250px', 'overflow-y': 'auto' }}>
                    {keybindList.map((kb, i) => (
                      <Flex key={i} align="center" style={{ padding: '5px 0', 'border-bottom': '1px solid #1a2a1a' }}>
                        <Flex.Item grow style={{ color: '#a8d8a8' }}>{kb.name}</Flex.Item>
                        <Flex.Item>
                          {kb.keys?.length > 0 ? kb.keys.map((k, ki) => (
                            <Button key={ki} compact content={k} onClick={() => act('capture_keybind', { name: kb.name, index: ki })} style={{ 'margin-left': '5px' }} />
                          )) : (
                            <Button compact content="UNBOUND" onClick={() => act('capture_keybind', { name: kb.name, index: 0 })} />
                          )}
                        </Flex.Item>
                      </Flex>
                    ))}
                  </Box>
                  <Divider />
                  <Button content="> RESET TO DEFAULTS" onClick={() => act('reset_keybinds')} />
                </Section>
              </Box>
            )}

            <Box className="CharacterSetup__footer">
              SLOT {current_slot} | READY
            </Box>
          </Box>
        </Window.Content>
      </div>
      <div className="CharacterSetup__right">
        <Box className="CharacterSetup__preview-label">&gt; PREVIEW</Box>
        <Box style={{ padding: '20px', color: '#4cff4c', 'text-align': 'center' }}>
          Character preview displayed in main window.
        </Box>
      </div>
    </Window>
  );
};
