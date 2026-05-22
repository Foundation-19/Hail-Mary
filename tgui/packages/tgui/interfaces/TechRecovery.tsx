import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Box, Button, LabeledList, Section, Stack, Tabs, Icon } from '../components';

type TechRecoveryData = {
  faction: string;
  faction_name: string;
  player_has_active: boolean;
  available_missions: Mission[];
  active_missions: ActiveMission[];
  completed_missions: CompletedMission[];
  recovered_tech: RecoveredTech[];
};

type Mission = {
  id: string;
  name: string;
  description: string;
  difficulty: number;
  difficulty_text: string;
  required_rank: string;
  research_points: number;
  location: string;
  on_cooldown: boolean;
  cooldown_remaining: number;
};

type ActiveMission = {
  id: string;
  name: string;
  status: string;
  assigned_to: string;
  time_remaining: number;
};

type CompletedMission = {
  id: string;
  name: string;
  success: boolean;
};

type RecoveredTech = {
  name: string;
  rarity: string;
  research_value: number;
  analyzed: boolean;
};

const difficultyColor = (difficulty: number) => {
  switch (difficulty) {
    case 1: return 'green';
    case 2: return 'olive';
    case 3: return 'yellow';
    case 4: return 'orange';
    case 5: return 'red';
    default: return 'grey';
  }
};

const rarityColor = (rarity: string) => {
  switch (rarity) {
    case 'common': return 'grey';
    case 'uncommon': return 'green';
    case 'rare': return 'blue';
    case 'legendary': return 'purple';
    default: return 'grey';
  }
};

const formatTime = (ticks: number) => {
  if (ticks < 0) return '--:--';
  const seconds = Math.floor(ticks / 10);
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

export const TechRecovery = (props, context) => {
  const { act, data } = useBackend<TechRecoveryData>(context);
  const {
    faction_name,
    player_has_active,
    available_missions = [],
    active_missions = [],
    completed_missions = [],
    recovered_tech = [],
  } = data;

  return (
    <Window
      width={600}
      height={700}
      theme="fallout">
      <Window.Content scrollable>
        <Stack vertical>
          <Stack.Item>
            <Section title={`> ${faction_name?.toUpperCase() || 'BROTHERHOOD OF STEEL'}`}>
              <Box color="silver" fontSize="14px">
                TECH RECOVERY OPERATIONS
              </Box>
              {player_has_active && (
                <Box color="yellow" mt={1}>
                  WARNING: You already have an active mission.
                </Box>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> AVAILABLE MISSIONS">
              {!available_missions.length && (
                <Box color="grey" textAlign="center" py={2}>
                  No missions currently available.
                </Box>
              )}
              {available_missions.map(mission => (
                <Box key={mission.id} mb={2} p={1} backgroundColor="rgba(50,50,50,0.5)">
                  <LabeledList>
                    <LabeledList.Item label="Mission">
                      <Box color="silver">{mission.name}</Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Location">
                      <Box color="grey">{mission.location}</Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Difficulty">
                      <Box color={difficultyColor(mission.difficulty)}>
                        {mission.difficulty_text}
                      </Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Reward">
                      <Box color="gold">{mission.research_points} Research Points</Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Description">
                      <Box color="grey" fontSize="12px">{mission.description}</Box>
                    </LabeledList.Item>
                  </LabeledList>
                  <Box mt={1}>
                    {(mission.on_cooldown || player_has_active) ? (
                      <Button color="grey" disabled>
                        {mission.on_cooldown
                          ? `Cooldown: ${mission.cooldown_remaining}m remaining`
                          : 'Already on mission'}
                      </Button>
                    ) : (
                      <Button
                        color="steel"
                        onClick={() => act('accept_mission', { id: mission.id })}>
                        Accept Mission
                      </Button>
                    )}
                  </Box>
                </Box>
              ))}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> ACTIVE MISSIONS">
              {!active_missions.length && (
                <Box color="grey" textAlign="center" py={2}>
                  No active missions.
                </Box>
              )}
              {active_missions.map(mission => (
                <Box key={mission.id} mb={2} p={1} backgroundColor="rgba(50,50,50,0.5)">
                  <LabeledList>
                    <LabeledList.Item label="Mission">
                      <Box color="yellow">{mission.name}</Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Assigned To">
                      <Box color="silver">{mission.assigned_to}</Box>
                    </LabeledList.Item>
                    {mission.time_remaining >= 0 && (
                      <LabeledList.Item label="Time Remaining">
                        <Box color={mission.time_remaining > 600 ? 'green' : 'red'}>
                          {formatTime(mission.time_remaining)}
                        </Box>
                      </LabeledList.Item>
                    )}
                  </LabeledList>
                  <Box mt={1}>
                    <Button
                      color="green"
                      onClick={() => act('complete_mission', { id: mission.id })}>
                      Mark Complete
                    </Button>
                    <Button
                      color="red"
                      onClick={() => act('fail_mission', { id: mission.id })}>
                      Report Failure
                    </Button>
                  </Box>
                </Box>
              ))}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> COMPLETED THIS WEEK">
              {!completed_missions.length && (
                <Box color="grey" textAlign="center" py={1}>
                  No completed missions this week.
                </Box>
              )}
              {completed_missions.map(mission => (
                <Box key={mission.id} color={mission.success ? 'green' : 'red'}>
                  {mission.success ? '✓' : '✗'} {mission.name}
                </Box>
              ))}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section
              title="> RECOVERED TECH AWAITING ANALYSIS"
              buttons={
                <Button
                  color="steel"
                  onClick={() => act('analyze_all')}>
                  Analyze All
                </Button>
              }>
              {!recovered_tech.length && (
                <Box color="grey" textAlign="center" py={1}>
                  No recovered technology.
                </Box>
              )}
              {recovered_tech.map((tech, index) => (
                <Box key={index} mb={1} p={1} backgroundColor="rgba(50,50,50,0.5)">
                  <LabeledList>
                    <LabeledList.Item label={tech.analyzed ? 'Analyzed' : 'Tech'}>
                      <Box color={rarityColor(tech.rarity)}>
                        [{tech.rarity.toUpperCase()}] {tech.name}
                      </Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Value">
                      <Box color="gold">{tech.research_value} RP</Box>
                    </LabeledList.Item>
                  </LabeledList>
                  {!tech.analyzed && (
                    <Box mt={1}>
                      <Button
                        color="steel"
                        onClick={() => act('analyze_tech', { name: tech.name })}>
                        Analyze
                      </Button>
                    </Box>
                  )}
                </Box>
              ))}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
