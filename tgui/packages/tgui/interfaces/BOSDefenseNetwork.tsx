import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Box, Button, LabeledList, Section, Stack, Table } from '../components';

type BOSDefenseNetworkData = {
  network_id: string;
  alert_level: number;
  alert_name: string;
  power_draw: number;
  max_power: number;
  power_percent: number;
  turrets: TurretData[];
  sensors: SensorData[];
  barriers: BarrierData[];
  detection_log: string[];
};

type TurretData = {
  id: string;
  name: string;
  damage: number;
  range: number;
  status: string;
  mode: string;
  targets: number;
};

type SensorData = {
  id: string;
  name: string;
  active: boolean;
  last_detection: string | null;
};

type BarrierData = {
  id: string;
  name: string;
  mode: string;
};

const getAlertColor = (level: number): string => {
  switch (level) {
    case 0:
      return 'green';
    case 1:
      return 'yellow';
    case 2:
      return 'orange';
    case 3:
      return 'red';
    default:
      return 'grey';
  }
};

const getModeColor = (mode: string): string => {
  switch (mode) {
    case 'standby':
      return 'grey';
    case 'stun':
      return 'yellow';
    case 'lethal':
      return 'red';
    case 'precision':
      return 'blue';
    default:
      return 'grey';
  }
};

const getBarrierColor = (mode: string): string => {
  switch (mode) {
    case 'open':
      return 'green';
    case 'restricted':
      return 'yellow';
    case 'locked':
      return 'orange';
    case 'emergency':
      return 'red';
    default:
      return 'grey';
  }
};

export const BOSDefenseNetwork = (props, context) => {
  const { act, data } = useBackend<BOSDefenseNetworkData>(context);
  const {
    alert_level,
    alert_name,
    power_draw,
    max_power,
    power_percent,
    turrets = [],
    barriers = [],
    detection_log = [],
  } = data;

  return (
    <Window
      width={700}
      height={750}
      theme="fallout">
      <Window.Content scrollable>
        <Stack vertical>
          <Stack.Item>
            <Section title="> BROTHERHOOD OF STEEL">
              <Box color="silver" fontSize="14px">
                BASE DEFENSE NETWORK
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> SYSTEM STATUS">
              <Stack>
                <Stack.Item grow>
                  <LabeledList>
                    <LabeledList.Item label="Alert Level">
                      <Box color={getAlertColor(alert_level)} bold>
                        {alert_name} (Level {alert_level})
                      </Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Power">
                      <Box color={power_percent > 50 ? 'green' : 'red'}>
                        {max_power - power_draw}/{max_power} ({power_percent}%)
                      </Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Active Defenses">
                      <Box color="silver">
                        {turrets.filter(t => t.status === 'active').length} turrets,
                        {' '}{barriers.filter(b => b.mode !== 'open').length} barriers
                      </Box>
                    </LabeledList.Item>
                  </LabeledList>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> QUICK ACTIONS">
              <Stack>
                <Stack.Item>
                  <Button
                    color="red"
                    onClick={() => act('full_lockdown')}>
                    Full Lockdown
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    color="orange"
                    onClick={() => act('all_turrets_active')}>
                    All Turrets Active
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    color="green"
                    onClick={() => act('reset_to_normal')}>
                    Reset to Normal
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    color="blue"
                    onClick={() => act('scan_area')}>
                    Scan Area
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> TURRET CONTROL">
              <Table>
                <Table.Row>
                  <Table.Cell bold color="silver">Name</Table.Cell>
                  <Table.Cell bold color="silver">Status</Table.Cell>
                  <Table.Cell bold color="silver">Mode</Table.Cell>
                  <Table.Cell bold color="silver">Actions</Table.Cell>
                </Table.Row>
                {turrets.map(turret => (
                  <Table.Row key={turret.id}>
                    <Table.Cell>{turret.name}</Table.Cell>
                    <Table.Cell>
                      <Box color={turret.status === 'active' ? 'green' : 'grey'}>
                        {turret.status.toUpperCase()}
                      </Box>
                    </Table.Cell>
                    <Table.Cell>
                      <Box color={getModeColor(turret.mode)} bold>
                        {turret.mode.toUpperCase()}
                      </Box>
                    </Table.Cell>
                    <Table.Cell>
                      <Button
                        color="grey"
                        size="tiny"
                        onClick={() => act('set_turret_mode', {
                          turret_id: turret.id,
                          mode: 'standby',
                        })}>
                        STANDBY
                      </Button>
                      <Button
                        color="yellow"
                        size="tiny"
                        onClick={() => act('set_turret_mode', {
                          turret_id: turret.id,
                          mode: 'stun',
                        })}>
                        STUN
                      </Button>
                      <Button
                        color="red"
                        size="tiny"
                        onClick={() => act('set_turret_mode', {
                          turret_id: turret.id,
                          mode: 'lethal',
                        })}>
                        LETHAL
                      </Button>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> BARRIER CONTROL">
              <Table>
                <Table.Row>
                  <Table.Cell bold color="silver">Name</Table.Cell>
                  <Table.Cell bold color="silver">Mode</Table.Cell>
                  <Table.Cell bold color="silver">Actions</Table.Cell>
                </Table.Row>
                {barriers.map(barrier => (
                  <Table.Row key={barrier.id}>
                    <Table.Cell>{barrier.name}</Table.Cell>
                    <Table.Cell>
                      <Box color={getBarrierColor(barrier.mode)} bold>
                        {barrier.mode.toUpperCase()}
                      </Box>
                    </Table.Cell>
                    <Table.Cell>
                      <Button
                        color="green"
                        size="tiny"
                        onClick={() => act('set_barrier_mode', {
                          barrier_id: barrier.id,
                          mode: 'open',
                        })}>
                        OPEN
                      </Button>
                      <Button
                        color="yellow"
                        size="tiny"
                        onClick={() => act('set_barrier_mode', {
                          barrier_id: barrier.id,
                          mode: 'restricted',
                        })}>
                        RESTRICT
                      </Button>
                      <Button
                        color="orange"
                        size="tiny"
                        onClick={() => act('set_barrier_mode', {
                          barrier_id: barrier.id,
                          mode: 'locked',
                        })}>
                        LOCK
                      </Button>
                      <Button
                        color="red"
                        size="tiny"
                        onClick={() => act('set_barrier_mode', {
                          barrier_id: barrier.id,
                          mode: 'emergency',
                        })}>
                        EMERGENCY
                      </Button>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> DETECTION LOG">
              <Box height={150} overflowY="scroll" backgroundColor="rgba(0,0,0,0.3)" p={1}>
                {detection_log.map((entry, index) => (
                  <Box key={index} fontSize="12px" mb={1} color="silver">
                    {entry}
                  </Box>
                ))}
                {!detection_log.length && (
                  <Box color="grey" textAlign="center">
                    No entries.
                  </Box>
                )}
              </Box>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
