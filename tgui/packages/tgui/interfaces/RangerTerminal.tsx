import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Flex, ProgressBar } from '../components';
import { Window } from '../layouts';

type RangerTerminalData = {
  progression: Progression;
  ncr_reputation: number;
  can_advance: boolean;
  available_missions: Mission[];
};

type Progression = {
  ranger_tier: number;
  tier_name: string;
  total_missions: number;
  successful_missions: number;
  failed_missions: number;
  tracking_skill: number;
  stealth_skill: number;
  combat_skill: number;
  active_mission: Mission | null;
  tracking_cooldown: number;
  stealth_cooldown: number;
  combat_cooldown: number;
};

type Mission = {
  id: string;
  name: string;
  description: string;
  difficulty: number;
  caps_reward: number;
  reputation_reward: number;
};

const tierReqs = [
  { tier: 0, name: 'Trooper', rep: 0 },
  { tier: 1, name: 'Scout', rep: 100 },
  { tier: 2, name: 'Ranger', rep: 250 },
  { tier: 3, name: 'Veteran Ranger', rep: 500 },
  { tier: 4, name: 'Ranger Captain', rep: 750 },
  { tier: 5, name: 'Ranger Chief', rep: 1000 },
];

const difficultyStars = (level: number): string => {
  return '★'.repeat(level) + '☆'.repeat(5 - level);
};

export const RangerTerminal = (props, context) => {
  const { act, data } = useBackend<RangerTerminalData>(context);
  const {
    progression,
    ncr_reputation,
    can_advance,
    available_missions = [],
  } = data;

  const nextTier = tierReqs.find((t) => t.tier === progression.ranger_tier + 1);

  return (
    <Window width={600} height={600} title="NCR RANGER TERMINAL" theme="ncr">
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          NEW CALIFORNIA REPUBLIC
          <span style={{ float: 'right' }}>RANGER DIVISION</span>
        </Box>

        <Section title="> RANGER STATUS">
          <Flex justify="space-between" align="center">
            <Flex.Item>
              <Box style={{ color: '#ffd700', fontSize: '1.3em', fontWeight: 'bold' }}>
                {progression.tier_name}
              </Box>
              <Box style={{ color: '#b8d4f0', marginTop: '5px' }}>
                Missions: {progression.successful_missions}/
                {progression.total_missions} successful
              </Box>
            </Flex.Item>
            <Flex.Item>
              {can_advance && (
                <Button
                  content="[ADVANCE TIER]"
                  color="good"
                  onClick={() => act('advance_tier')}
                />
              )}
            </Flex.Item>
          </Flex>

          <Box style={{ marginTop: '15px' }}>
            <Box style={{ color: '#888', marginBottom: '5px' }}>
              Reputation: {ncr_reputation} / {nextTier ? nextTier.rep : 'MAX'}
            </Box>
            {nextTier && (
              <ProgressBar
                value={ncr_reputation / nextTier.rep}
                color="#4a90d9"
                style={{ height: '15px' }}
              />
            )}
          </Box>
        </Section>

        <Section title="> ABILITIES">
          {progression.ranger_tier >= RANGER_TIER_SCOUT && (
            <Flex align="center" style={{ marginBottom: '10px' }}>
              <Flex.Item grow={1}>
                <Box style={{ color: '#4a90d9' }}>Tracking</Box>
                <Box style={{ color: '#888', fontSize: '0.85em' }}>
                  Track escaped prisoners and bounty targets
                </Box>
              </Flex.Item>
              <Flex.Item>
                <Button
                  content={progression.tracking_cooldown > 0 ? `${progression.tracking_cooldown}s` : '[USE]'}
                  disabled={progression.tracking_cooldown > 0}
                  onClick={() => act('use_ability_tracking')}
                />
              </Flex.Item>
            </Flex>
          )}

          {progression.ranger_tier >= RANGER_TIER_RANGER && (
            <Flex align="center" style={{ marginBottom: '10px' }}>
              <Flex.Item grow={1}>
                <Box style={{ color: '#4a90d9' }}>Stealth</Box>
                <Box style={{ color: '#888', fontSize: '0.85em' }}>
                  Become semi-invisible for 30 seconds
                </Box>
              </Flex.Item>
              <Flex.Item>
                <Button
                  content={progression.stealth_cooldown > 0 ? `${progression.stealth_cooldown}s` : '[USE]'}
                  disabled={progression.stealth_cooldown > 0}
                  onClick={() => act('use_ability_stealth')}
                />
              </Flex.Item>
            </Flex>
          )}

          {progression.ranger_tier >= RANGER_TIER_VETERAN && (
            <Flex align="center" style={{ marginBottom: '10px' }}>
              <Flex.Item grow={1}>
                <Box style={{ color: '#4a90d9' }}>Combat Stance</Box>
                <Box style={{ color: '#888', fontSize: '0.85em' }}>
                  +15% damage for 30 seconds
                </Box>
              </Flex.Item>
              <Flex.Item>
                <Button
                  content={progression.combat_cooldown > 0 ? `${progression.combat_cooldown}s` : '[USE]'}
                  disabled={progression.combat_cooldown > 0}
                  onClick={() => act('use_ability_combat')}
                />
              </Flex.Item>
            </Flex>
          )}

          {progression.ranger_tier < RANGER_TIER_SCOUT && (
            <Box style={{ color: '#888', textAlign: 'center', padding: '10px' }}>
              Reach Scout tier to unlock abilities.
            </Box>
          )}
        </Section>

        {progression.active_mission && (
          <Section title="> ACTIVE MISSION">
            <Box style={{ color: '#ffd700', fontWeight: 'bold' }}>
              {progression.active_mission.name}
            </Box>
            <Box style={{ color: '#b8d4f0', marginTop: '5px' }}>
              {progression.active_mission.description}
            </Box>
            <Box style={{ marginTop: '10px' }}>
              <Box style={{ color: '#4a90d9' }}>
                Reward: {progression.active_mission.caps_reward} caps,{' '}
                {progression.active_mission.reputation_reward} reputation
              </Box>
            </Box>
          </Section>
        )}

        <Section title="> AVAILABLE MISSIONS">
          {available_missions.length > 0 ? (
            available_missions.map((mission) => (
              <Box
                key={mission.id}
                style={{
                  border: '1px solid #2d5a87',
                  padding: '12px',
                  margin: '8px 0',
                  background: '#0a0f1a',
                }}
              >
                <Flex justify="space-between" align="flex-start">
                  <Flex.Item grow={1}>
                    <Box style={{ color: '#ffd700', fontWeight: 'bold' }}>
                      {mission.name}
                    </Box>
                    <Box style={{ color: '#b8d4f0', marginTop: '5px', fontSize: '0.9em' }}>
                      {mission.description}
                    </Box>
                    <Box style={{ marginTop: '8px' }}>
                      <Box style={{ color: '#888' }}>
                        Difficulty: {difficultyStars(mission.difficulty)}
                      </Box>
                      <Box style={{ color: '#4a90d9' }}>
                        Reward: {mission.caps_reward} caps
                      </Box>
                    </Box>
                  </Flex.Item>
                  <Flex.Item>
                    <Button
                      content="[ACCEPT]"
                      color="good"
                      onClick={() => act('accept_mission', { mission_id: mission.id })}
                    />
                  </Flex.Item>
                </Flex>
              </Box>
            ))
          ) : (
            <Box style={{ textAlign: 'center', padding: '20px', color: '#2a5a87' }}>
              No missions available. Advance to Scout tier to unlock missions.
            </Box>
          )}
        </Section>

        <Box className="CharacterSetup__footer">
          NEW CALIFORNIA REPUBLIC - RANGER DIVISION
        </Box>
      </Window.Content>
    </Window>
  );
};

const RANGER_TIER_SCOUT = 1;
const RANGER_TIER_RANGER = 2;
const RANGER_TIER_VETERAN = 3;
