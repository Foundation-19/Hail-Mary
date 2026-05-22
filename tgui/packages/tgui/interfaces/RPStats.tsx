import { useBackend } from '../backend';
/* eslint-disable max-len */
import { Box, Button, Section, Flex, ProgressBar, Divider } from '../components';
import { Window } from '../layouts';

type RPStatsData = {
  karma: number;
  karma_title: string;
  karma_desc: string;
  level: number;
  level_title: string;
  xp: number;
  xp_needed: number;
  xp_percent: number;
  bounty: number;
  bonus_perks: number;
  available_special: number;
  factions: FactionInfo[];
  background: BackgroundInfo;
};

type FactionInfo = {
  name: string;
  reputation: number;
  rank: string;
  reaction: string;
  access_level: number;
  color: string;
};

type BackgroundInfo = {
  name: string;
  description: string;
  backstory: string;
};

export const RPStats = (props, context) => {
  const { act, data } = useBackend<RPStatsData>(context);
  const {
    karma = 0,
    karma_title = 'Neutral',
    karma_desc = '',
    level = 1,
    level_title = 'Wastelander',
    xp = 0,
    xp_needed = 100,
    xp_percent = 0,
    bounty = 0,
    bonus_perks = 0,
    available_special = 0,
    factions = [],
    background,
  } = data;

  const karmaColor = karma >= 500 ? '#33ff33' : karma <= -500 ? '#ff3333' : '#ffff33';

  return (
    <Window width={700} height={700} title="ROBCO TERMINAL" theme="fallout" resizable>
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
          <span style={{ float: 'right' }}>VAULT-TEC CORP</span>
        </Box>

        <Section title="> KARMA">
          <Box style={{ fontSize: '2em', color: karmaColor }}>{karma}</Box>
          <Box style={{ fontSize: '1.3em', color: '#4cff4c' }}>{karma_title}</Box>
          <Box style={{ color: '#2a7a52', marginTop: '5px' }}>{karma_desc}</Box>
        </Section>

        <Section title="> LEVEL">
          <Box style={{ fontSize: '2em', color: '#ffaa00' }}>Level {level}</Box>
          <Box style={{ fontSize: '1.3em', color: '#ffaa00' }}>{level_title}</Box>
          <Box style={{ marginTop: '10px' }}>
            <Box style={{ color: '#2a7a52' }}>XP: {xp} / {xp_needed} ({xp_percent}%)</Box>
            <ProgressBar value={xp_percent} minValue={0} maxValue={100} color="#ffaa00" style={{ height: '18px', marginTop: '5px' }} />
          </Box>
          {bonus_perks > 0 && (
            <Box style={{ color: '#4cff4c', marginTop: '10px' }}>
              +{bonus_perks} bonus perk point(s) available
            </Box>
          )}
          {available_special > 0 && (
            <Box style={{ color: '#4cff4c', marginTop: '5px' }}>
              +{available_special} SPECIAL point(s) available
              <Button content="[ALLOCATE]" onClick={() => act('allocate_special')} style={{ marginLeft: '10px' }} />
            </Box>
          )}
        </Section>

        <Section title="> BOUNTY">
          {bounty > 0 ? (
            <Box style={{ border: '2px solid #ff0000', padding: '15px', background: 'rgba(255,0,0,0.1)' }}>
              <Box style={{ color: '#ff0000', fontSize: '1.3em', fontWeight: 'bold' }}>{bounty} CAPS</Box>
              <Box style={{ color: '#ff6666' }}>Bounty hunters may be after you!</Box>
            </Box>
          ) : (
            <Box style={{ color: '#4cff4c' }}>No active bounty on your head.</Box>
          )}
        </Section>

        <Section title="> FACTION REPUTATIONS">
          {factions.length > 0 ? (
            factions.map(f => (
              <Box
                key={f.name}
                style={{
                  border: '1px solid #1a5e38',
                  padding: '12px',
                  margin: '8px 0',
                  background: '#041a0e',
                }}
              >
                <Box style={{ color: f.color, fontWeight: 'bold' }}>{f.name}</Box>
                <Box style={{ color: '#ffcc00' }}>Reputation: {f.reputation} | Rank: {f.rank}</Box>
                <Box style={{ color: f.reaction === 'friendly' ? '#4cff4c' : f.reaction === 'hostile' ? '#ff3333' : '#888' }}>
                  Status: {f.reaction}
                </Box>
                {f.access_level > 0 && (
                  <Box style={{ color: '#4a9eed' }}>Vendor Access Level: {f.access_level}</Box>
                )}
              </Box>
            ))
          ) : (
            <Box style={{ color: '#2a7a52' }}>
              No faction reputations yet. Your actions in the wasteland will determine how factions view you.
            </Box>
          )}
        </Section>

        {background && (
          <Section title="> BACKGROUND">
            <Box style={{ fontWeight: 'bold', fontSize: '1.2em', color: '#4cff4c' }}>{background.name}</Box>
            <Box style={{ marginTop: '10px' }}>{background.description}</Box>
            {background.backstory && (
              <Box style={{ marginTop: '15px', color: '#2a7a52' }}>
                <i>Your backstory:</i>
                <Box style={{ marginTop: '5px' }}>{background.backstory}</Box>
              </Box>
            )}
          </Section>
        )}

        <Divider />

        <Section title="> ACTIONS">
          <Button content="> KARMA HISTORY" onClick={() => act('karma_history')} style={{ marginRight: '10px' }} />
          <Button content="> VIEW BOUNTIES" onClick={() => act('view_bounties')} style={{ marginRight: '10px' }} />
          <Button content="> PERK MENU" onClick={() => act('open_perks')} />
        </Section>

        <Box className="CharacterSetup__footer">
          ROBCO INDUSTRIES (TM) TERMLINK PROTOCOL
        </Box>
      </Window.Content>
    </Window>
  );
};
