import { useBackend } from '../backend';
import { Button, Section, Stack, NoticeBox, Flex, Box, Table, ProgressBar } from '../components';
import { Window } from '../layouts';

type BaseSecurityData = {
  base_name?: string;
  disguise?: string;
  detection_risk?: number;
  detection_status?: string;
  security_level?: number;
  lockdown?: boolean;
  entrances?: Entrance[];
  detection_log?: DetectionEvent[];
  security_options?: SecurityOption[];
};

type Entrance = {
  ref?: string;
  type?: string;
  discovered?: boolean;
  locked?: boolean;
  risk?: string;
};

type DetectionEvent = {
  time?: number;
  amount?: number;
  reason?: string;
};

type SecurityOption = {
  level?: number;
  name?: string;
  modifier?: string;
};

const detectionColor = (risk: number): string => {
  if (risk >= 75) return 'red';
  if (risk >= 50) return 'orange';
  if (risk >= 25) return 'yellow';
  return 'green';
};

export const BaseSecurity = (props, context) => {
  const { act, data } = useBackend<BaseSecurityData>(context);

  const {
    base_name = 'Enclave Base',
    disguise = 'Abandoned Warehouse',
    detection_risk = 0,
    detection_status = 'LOW',
    security_level = 3,
    lockdown,
    entrances = [],
    detection_log = [],
    security_options = [],
  } = data;

  return (
    <Window theme="fallout" width={650} height={700}>
      <Window.Content scrollable>
        <Stack vertical>
          <Section title="> ENCLAVE BASE SECURITY">
            <Box color="silver">FACILITY MANAGEMENT</Box>
          </Section>

          <Section title="> BASE STATUS">
            <Table>
              <Table.Row>
                <Table.Cell>Location:</Table.Cell>
                <Table.Cell>[REDACTED]</Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell>Disguise:</Table.Cell>
                <Table.Cell>{disguise}</Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell>Security Level:</Table.Cell>
                <Table.Cell>{security_level} (Good)</Table.Cell>
              </Table.Row>
            </Table>
            <Box mt={1}>
              Detection Risk:
              <ProgressBar
                mt={1}
                value={detection_risk}
                maxValue={100}
                color={detectionColor(detection_risk)}
              />
              <Box color={detectionColor(detection_risk)} bold>
                {detection_status}
              </Box>
            </Box>
            {lockdown && (
              <NoticeBox danger>LOCKDOWN ACTIVE</NoticeBox>
            )}
          </Section>

          <Section title="> ENTRANCES">
            <Table>
              <Table.Row header>
                <Table.Cell>Type</Table.Cell>
                <Table.Cell>Status</Table.Cell>
                <Table.Cell>Risk</Table.Cell>
                <Table.Cell>Actions</Table.Cell>
              </Table.Row>
              {entrances.map(entrance => (
                <Table.Row key={entrance.ref}>
                  <Table.Cell>{entrance.type}</Table.Cell>
                  <Table.Cell>
                    <Box color={entrance.discovered ? 'red' : entrance.locked ? 'yellow' : 'green'}>
                      {entrance.discovered ? 'Discovered' : entrance.locked ? 'Locked' : 'Secured'}
                    </Box>
                  </Table.Cell>
                  <Table.Cell>{entrance.risk}</Table.Cell>
                  <Table.Cell>
                    <Button onClick={() => act('seal_entrance', { ref: entrance.ref })}>
                      Seal
                    </Button>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>

          <Section title="> DETECTION LOG">
            {detection_log.length === 0 ? (
              <Box color="grey">No recent detection events.</Box>
            ) : (
              <Table>
                <Table.Row header>
                  <Table.Cell>Event</Table.Cell>
                  <Table.Cell>Risk+</Table.Cell>
                </Table.Row>
                {detection_log.slice(-5).map((event, idx) => (
                  <Table.Row key={idx}>
                    <Table.Cell>{event.reason}</Table.Cell>
                    <Table.Cell>
                      <Box color="red">+{event.amount}</Box>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            )}
          </Section>

          <Section title="> SECURITY MEASURES">
            <Flex wrap="wrap" gap={1}>
              {security_options.map(opt => (
                <Button
                  key={opt.level}
                  selected={security_level === opt.level}
                  onClick={() => act('set_security', { level: opt.level })}
                >
                  {opt.name} ({opt.modifier})
                </Button>
              ))}
            </Flex>
          </Section>

          <Section title="> EMERGENCY ACTIONS">
            <Flex gap={1}>
              <Button
                color={lockdown ? 'bad' : 'default'}
                onClick={() => act('lockdown')}
              >
                {lockdown ? 'End Lockdown' : 'Initiate Lockdown'}
              </Button>
              <Button color="bad" onClick={() => act('evacuate')}>
                Emergency Evacuation
              </Button>
            </Flex>
          </Section>
        </Stack>
      </Window.Content>
    </Window>
  );
};
