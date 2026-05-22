import { useBackend } from '../backend';
import { Button, Section, Stack, NoticeBox, Flex, Box, Table, ProgressBar } from '../components';
import { Window } from '../layouts';

type PropagandaNetworkData = {
  active_broadcasts?: Broadcast[];
  settlements?: Settlement[];
  messages?: MessageTemplate[];
  methods?: BroadcastMethod[];
  broadcast_power?: number;
};

type Broadcast = {
  id?: string;
  method?: string;
  target?: string;
  message?: string;
  remaining?: number;
};

type Settlement = {
  name?: string;
  influence?: number;
  status?: string;
};

type MessageTemplate = {
  id?: string;
  name?: string;
  text?: string;
  type?: string;
  karma?: number;
};

type BroadcastMethod = {
  id?: string;
  name?: string;
  cost?: number;
};

const influenceColor = (influence: number): string => {
  if (influence >= 80) return 'green';
  if (influence >= 60) return 'yellow';
  if (influence >= 40) return 'orange';
  return 'red';
};

export const PropagandaNetwork = (props, context) => {
  const { act, data } = useBackend<PropagandaNetworkData>(context);

  const {
    active_broadcasts = [],
    settlements = [],
    messages = [],
    methods = [],
    broadcast_power = 100,
  } = data;

  return (
    <Window theme="fallout" width={650} height={700}>
      <Window.Content scrollable>
        <Stack vertical>
          <Section title="> ENCLAVE PROPAGANDA NETWORK">
            <Box color="silver">INFORMATION WARFARE DIVISION</Box>
            <Box mt={1}>
              Broadcast Power: <Box as="span" color="green">{broadcast_power}%</Box>
            </Box>
          </Section>

          <Section title="> ACTIVE BROADCASTS">
            {active_broadcasts.length === 0 ? (
              <Box color="grey">No active broadcasts.</Box>
            ) : (
              <Stack vertical>
                {active_broadcasts.map(broadcast => (
                  <Box key={broadcast.id} p={1} backgroundColor="rgba(30,50,30,0.5)">
                    <Flex justify="space-between" align="center">
                      <Flex.Item grow={1}>
                        <Box color="green">{broadcast.method?.toUpperCase()}</Box>
                        <Box color="grey" fontSize="12px">
                          Tgt: {broadcast.target} | {broadcast.message}
                        </Box>
                        <Box fontSize="12px">
                          Remaining:{' '}
                          {Math.floor((broadcast.remaining || 0) / 600)} min
                        </Box>
                      </Flex.Item>
                      <Flex.Item>
                        <Button color="bad" onClick={() => act('end_broadcast', { broadcast_id: broadcast.id })}>
                          End
                        </Button>
                      </Flex.Item>
                    </Flex>
                  </Box>
                ))}
              </Stack>
            )}
          </Section>

          <Section title="> SETTLEMENT INFLUENCE">
            <Stack vertical>
              {settlements.map(settlement => (
                <Box key={settlement.name} p={1}>
                  <Flex justify="space-between" align="center">
                    <Flex.Item grow={1}>
                      <Box>{settlement.name}</Box>
                      <ProgressBar
                        value={settlement.influence || 0}
                        maxValue={100}
                        color={influenceColor(settlement.influence || 0)}
                      />
                    </Flex.Item>
                    <Flex.Item>
                      <Box
                        color={influenceColor(settlement.influence || 0)}
                        bold>
                        {settlement.status}
                      </Box>
                    </Flex.Item>
                  </Flex>
                </Box>
              ))}
            </Stack>
          </Section>

          <Section title="> MESSAGE TEMPLATES">
            <Table>
              <Table.Row header>
                <Table.Cell>Name</Table.Cell>
                <Table.Cell>Type</Table.Cell>
                <Table.Cell>Karma</Table.Cell>
              </Table.Row>
              {messages.map(msg => (
                <Table.Row key={msg.id}>
                  <Table.Cell>{msg.name}</Table.Cell>
                  <Table.Cell>{msg.type}</Table.Cell>
                  <Table.Cell>
                    <Box color={msg.karma && msg.karma < 0 ? 'red' : 'green'}>
                      {msg.karma}
                    </Box>
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>

          <Section title="> START BROADCAST">
            <Box mb={1}>Select method, target, and message:</Box>
            <Flex gap={1} wrap="wrap">
              {methods.map(method => (
                <Button key={method.id} onClick={() => {
                  const target = 'all';
                  const message = messages[0]?.id || 'recruitment';
                  act('start_broadcast', {
                    method: method.id,
                    target: target,
                    message: message,
                    duration: 10,
                  });
                }}>
                  {method.name}
                </Button>
              ))}
            </Flex>
          </Section>
        </Stack>
      </Window.Content>
    </Window>
  );
};
