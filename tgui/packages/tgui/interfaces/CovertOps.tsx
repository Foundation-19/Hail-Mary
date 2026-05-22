import { useBackend } from '../backend';
import { Button, Section, Stack, NoticeBox, Flex, Box, Table } from '../components';
import { Window } from '../layouts';

type CovertOpsData = {
  intel_points?: number;
  available_missions?: Mission[];
  active_missions?: ActiveMission[];
  loadouts?: Loadout[];
};

type Mission = {
  id?: string;
  name?: string;
  type?: string;
  difficulty?: number;
  target?: string;
  reward_caps?: number;
  reward_rep?: number;
  reward_intel?: number;
};

type ActiveMission = {
  id?: string;
  name?: string;
  type?: string;
  assigned?: string;
  time_remaining?: number;
  detection?: number;
};

type Loadout = {
  name?: string;
  type?: string;
  detection_mod?: number;
};

const difficultyStars = (diff: number): string => {
  return '★'.repeat(diff) + '☆'.repeat(5 - diff);
};

export const CovertOps = (props, context) => {
  const { act, data } = useBackend<CovertOpsData>(context);

  const {
    intel_points = 0,
    available_missions = [],
    active_missions = [],
    loadouts = [],
  } = data;

  return (
    <Window theme="fallout" width={650} height={700}>
      <Window.Content scrollable>
        <Stack vertical>
          <Section title="> ENCLAVE COVERT OPERATIONS">
            <Box color="silver">SPECIAL PROJECTS DIVISION</Box>
            <Box mt={1}>Intel Points: <Box as="span" color="green">{intel_points}</Box></Box>
          </Section>

          <Section title="> AVAILABLE MISSIONS">
            <Button onClick={() => act('generate_missions')}>
              Generate New Missions
            </Button>
            <Stack vertical mt={1}>
              {available_missions.map(mission => (
                <Box key={mission.id} p={1} backgroundColor="rgba(30,50,30,0.5)">
                  <Flex justify="space-between" align="flex-start">
                    <Flex.Item grow={1}>
                      <Box color="green">{mission.name}</Box>
                      <Box color="grey" fontSize="12px">
                        Type: {mission.type?.toUpperCase()} | 
                        Difficulty: {difficultyStars(mission.difficulty || 1)}
                      </Box>
                      <Box color="silver" fontSize="12px">
                        Target: {mission.target}
                      </Box>
                      <Box fontSize="12px">
                        Reward: {mission.reward_caps} caps | 
                        {mission.reward_rep} rep | 
                        {mission.reward_intel} intel
                      </Box>
                    </Flex.Item>
                    <Flex.Item>
                      <Button onClick={() => act('accept_mission', { mission_id: mission.id })}>
                        Accept
                      </Button>
                    </Flex.Item>
                  </Flex>
                </Box>
              ))}
            </Stack>
          </Section>

          <Section title="> ACTIVE MISSIONS">
            {active_missions.length === 0 ? (
              <Box color="grey">No active missions.</Box>
            ) : (
              <Stack vertical>
                {active_missions.map(mission => (
                  <Box key={mission.id} p={1} backgroundColor="rgba(50,30,30,0.5)">
                    <Box color="yellow">{mission.name}</Box>
                    <Box color="grey" fontSize="12px">
                      Type: {mission.type?.toUpperCase()} | 
                      Assigned: {mission.assigned}
                    </Box>
                    <Box fontSize="12px">
                      Time: {Math.floor((mission.time_remaining || 0) / 60)}s | 
                      Detection: {mission.detection}%
                    </Box>
                    <Flex gap={1} mt={1}>
                      <Button onClick={() => act('complete_mission', { mission_id: mission.id, success: 1 })}>
                        Complete
                      </Button>
                      <Button color="bad" onClick={() => act('complete_mission', { mission_id: mission.id, success: 0 })}>
                        Abort
                      </Button>
                    </Flex>
                  </Box>
                ))}
              </Stack>
            )}
          </Section>

          <Section title="> LOADOUT SELECTION">
            <Table>
              <Table.Row header>
                <Table.Cell>Loadout</Table.Cell>
                <Table.Cell>Detection Modifier</Table.Cell>
              </Table.Row>
              {loadouts.map(loadout => (
                <Table.Row key={loadout.type}>
                  <Table.Cell>{loadout.name}</Table.Cell>
                  <Table.Cell>
                    <Box color={loadout.detection_mod && loadout.detection_mod < 0 ? 'green' : 'red'}>
                      {loadout.detection_mod && loadout.detection_mod > 0 ? '+' : ''}{loadout.detection_mod}%
                    </Box>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>
        </Stack>
      </Window.Content>
    </Window>
  );
};
