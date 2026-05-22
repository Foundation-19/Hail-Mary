import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Box, Button, LabeledList, Section, Stack } from '../components';

type PaladinTerminalData = {
  progression: PaladinProgression;
  bos_reputation: number;
  can_advance: boolean;
  is_wearing_pa: boolean;
  available_missions: PaladinMission[];
};

type PaladinProgression = {
  paladin_tier: number;
  tier_name: string;
  missions_completed: number;
  missions_failed: number;
  tech_recovered: number;
  combat_victories: number;
  codex_violations: number;
  active_mission: PaladinMission | null;
  combat_stance_cooldown: number;
  tactical_cooldown: number;
  pa_boost_cooldown: number;
};

type PaladinMission = {
  id: string;
  name: string;
  description: string;
  difficulty: number;
  research_reward: number;
  reputation_reward: number;
};

const difficultyStars = (level: number): string => {
  return '\u2605'.repeat(level) + '\u2606'.repeat(5 - level);
};

const formatCooldown = (seconds: number): string => {
  if (seconds <= 0) return 'Ready';
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

export const PaladinTerminal = (props, context) => {
  const { act, data } = useBackend<PaladinTerminalData>(context);
  const {
    progression,
    bos_reputation,
    can_advance,
    is_wearing_pa,
    available_missions = [],
  } = data;

  return (
    <Window
      width={600}
      height={650}
      theme="fallout">
      <Window.Content scrollable>
        <Stack vertical>
          <Stack.Item>
            <Section title="> BROTHERHOOD OF STEEL">
              <Box color="silver" fontSize="14px">
                PALADIN COMMAND TERMINAL
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> PROGRESSION STATUS">
              <LabeledList>
                <LabeledList.Item label="Rank">
                  <Box color="gold" bold>{progression?.tier_name || 'Initiate'}</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Reputation">
                  <Box color="silver">{bos_reputation}</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Missions Completed">
                  <Box color="green">{progression?.missions_completed || 0}</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Tech Recovered">
                  <Box color="blue">{progression?.tech_recovered || 0}</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Combat Victories">
                  <Box color="red">{progression?.combat_victories || 0}</Box>
                </LabeledList.Item>
              </LabeledList>
              {can_advance && (
                <Box mt={2}>
                  <Button
                    color="gold"
                    onClick={() => act('advance_tier')}>
                    Request Promotion
                  </Button>
                </Box>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> ABILITIES">
              <LabeledList>
                <LabeledList.Item label="Combat Stance">
                  <Button
                    color={progression?.combat_stance_cooldown > 0 ? 'grey' : 'good'}
                    disabled={progression?.combat_stance_cooldown > 0}
                    onClick={() => act('use_combat_stance')}>
                    {formatCooldown(progression?.combat_stance_cooldown || 0)}
                  </Button>
                </LabeledList.Item>
                <LabeledList.Item label="Tactical Command">
                  <Button
                    color={progression?.tactical_cooldown > 0 ? 'grey' : 'good'}
                    disabled={progression?.tactical_cooldown > 0}
                    onClick={() => act('use_tactical_command')}>
                    {formatCooldown(progression?.tactical_cooldown || 0)}
                  </Button>
                </LabeledList.Item>
                <LabeledList.Item label="PA Boost">
                  <Button
                    color={
                      !is_wearing_pa
                        || progression?.pa_boost_cooldown > 0
                        ? 'grey'
                        : 'good'
                    }
                    disabled={
                      !is_wearing_pa
                        || progression?.pa_boost_cooldown > 0
                    }
                    onClick={() => act('use_power_armor_boost')}
                  >
                    {is_wearing_pa
                      ? formatCooldown(progression?.pa_boost_cooldown || 0)
                      : 'No Power Armor'}
                  </Button>
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> ACTIVE MISSION">
              {progression?.active_mission ? (
                <Box p={1} backgroundColor="rgba(50,50,50,0.5)">
                  <LabeledList>
                    <LabeledList.Item label="Mission">
                      <Box color="yellow">{progression.active_mission.name}</Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Description">
                      <Box color="grey">{progression.active_mission.description}</Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Reward">
                      <Box color="gold">{progression.active_mission.research_reward} RP</Box>
                    </LabeledList.Item>
                  </LabeledList>
                </Box>
              ) : (
                <Box color="grey" textAlign="center" py={1}>
                  No active mission.
                </Box>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> AVAILABLE MISSIONS">
              {!available_missions.length && (
                <Box color="grey" textAlign="center" py={2}>
                  No missions available for your rank.
                </Box>
              )}
              {available_missions.map(mission => (
                <Box key={mission.id} mb={2} p={1} backgroundColor="rgba(50,50,50,0.5)">
                  <LabeledList>
                    <LabeledList.Item label="Mission">
                      <Box color="silver">{mission.name}</Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Difficulty">
                      <Box color="grey">{difficultyStars(mission.difficulty)}</Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Reward">
                      <Box color="gold">{mission.research_reward} RP</Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Description">
                      <Box color="grey" fontSize="12px">{mission.description}</Box>
                    </LabeledList.Item>
                  </LabeledList>
                  <Box mt={1}>
                    <Button
                      color="steel"
                      disabled={!!progression?.active_mission}
                      onClick={() => act('accept_mission', { mission_id: mission.id })}>
                      {progression?.active_mission ? 'Already on Mission' : 'Accept Mission'}
                    </Button>
                  </Box>
                </Box>
              ))}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
