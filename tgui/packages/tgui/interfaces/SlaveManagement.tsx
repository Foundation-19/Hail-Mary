import { useBackend, useLocalState } from '../backend';
import { Window } from '../layouts';
import { Box, Button, LabeledList, Section, Stack, Flex, Input } from '../components';

type SlaveManagementData = {
  is_legion: boolean;
  is_slave: boolean;
  my_status: SlaveEntryData;
  all_slaves: SlaveEntryData[];
  market_slaves: SlaveEntryData[];
};

type SlaveEntryData = {
  slave_ckey: string;
  slave_name: string;
  owner_ckey: string;
  owner_name: string;
  slave_type: string;
  obedience: number;
  escape_attempts: number;
  gladiator_wins: number;
  status: string;
  time_enslaved: number;
};

const slaveTypes = [
  { id: 'labor', name: 'Labor' },
  { id: 'servant', name: 'Servant' },
  { id: 'gladiator', name: 'Gladiator' },
  { id: 'specialist', name: 'Specialist' },
];

const obedienceColor = (obedience: number): string => {
  if (obedience >= 80) return 'green';
  if (obedience >= 50) return 'yellow';
  if (obedience >= 20) return 'orange';
  return 'red';
};

const formatTime = (ticks: number): string => {
  const seconds = Math.floor(ticks / 10);
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

export const SlaveManagement = (props, context) => {
  const { act, data } = useBackend<SlaveManagementData>(context);
  const {
    is_legion,
    is_slave,
    my_status,
    all_slaves = [],
    market_slaves = [],
  } = data;

  const [targetCkey, setTargetCkey] = useLocalState(context, 'targetCkey', '');
  const [selectedType, setSelectedType] = useLocalState(context, 'selectedType', 'labor');
  const [shockLevel, setShockLevel] = useLocalState(context, 'shockLevel', 1);

  return (
    <Window
      width={700}
      height={700}
      title="LEGION SLAVE REGISTRY"
      theme="fallout">
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          SLAVE REGISTRY
          <span style={{ float: 'right' }}>LUDUS ADMINISTRATION</span>
        </Box>

        {is_slave && my_status && (
          <Section title="> YOUR STATUS">
            <LabeledList>
              <LabeledList.Item label="Type">
                <Box color="silver">{my_status.slave_type.toUpperCase()}</Box>
              </LabeledList.Item>
              <LabeledList.Item label="Owner">
                <Box color="silver">{my_status.owner_name}</Box>
              </LabeledList.Item>
              <LabeledList.Item label="Obedience">
                <Box color={obedienceColor(my_status.obedience)}>
                  {my_status.obedience}%
                </Box>
              </LabeledList.Item>
              <LabeledList.Item label="Time Enslaved">
                <Box color="grey">{formatTime(my_status.time_enslaved)}</Box>
              </LabeledList.Item>
              {my_status.slave_type === 'gladiator' && (
                <LabeledList.Item label="Gladiator Wins">
                  <Box color="gold">{my_status.gladiator_wins}/3</Box>
                </LabeledList.Item>
              )}
            </LabeledList>
          </Section>
        )}

        {is_legion && (
          <Section title="> PROCESS NEW SLAVE">
            <Flex align="center" gap={1}>
              <Flex.Item grow>
                <Input
                  fluid
                  placeholder="Target ckey..."
                  value={targetCkey}
                  onInput={(e, val) => setTargetCkey(val)}
                />
              </Flex.Item>
              <Flex.Item>
                {slaveTypes.map(type => (
                  <Button
                    key={type.id}
                    selected={selectedType === type.id}
                    onClick={() => setSelectedType(type.id)}>
                    {type.name}
                  </Button>
                ))}
              </Flex.Item>
              <Flex.Item>
                <Button
                  color="bad"
                  onClick={() => act('process_slave', { target_ckey: targetCkey, slave_type: selectedType })}>
                  Enslave
                </Button>
              </Flex.Item>
            </Flex>
          </Section>
        )}

        <Section title="> ALL SLAVES">
          {all_slaves.length === 0 ? (
            <Box color="grey" textAlign="center" py={2}>
              No slaves registered
            </Box>
          ) : (
            all_slaves.map(slave => (
              <Box key={slave.slave_ckey} mb={2} p={1} backgroundColor="rgba(50,20,20,0.5)">
                <Flex justify="space-between" align="flex-start">
                  <Flex.Item grow>
                    <Box color="red">{slave.slave_name}</Box>
                    <Box color="grey" fontSize="12px">
                      Type: {slave.slave_type.toUpperCase()} |
                      Owner: {slave.owner_name}
                    </Box>
                    <Box color={obedienceColor(slave.obedience)} fontSize="12px">
                      Obedience: {slave.obedience}%
                    </Box>
                    <Box color="grey" fontSize="12px">
                      Escapes: {slave.escape_attempts}
                      {slave.slave_type === 'gladiator' && ` | Wins: ${slave.gladiator_wins}/3`}
                    </Box>
                  </Flex.Item>
                  <Flex.Item>
                    <Stack vertical>
                      {slave.owner_ckey === context && (
                        <>
                          <Stack.Item>
                            <Button
                              color="yellow"
                              onClick={() => act('shock_slave', { target_ckey: slave.slave_ckey, level: shockLevel })}>
                              Shock
                            </Button>
                          </Stack.Item>
                          <Stack.Item>
                            <Button
                              color="good"
                              onClick={() => act('free_slave', { target_ckey: slave.slave_ckey })}>
                              Free
                            </Button>
                          </Stack.Item>
                        </>
                      )}
                      {is_legion && (
                        <Stack.Item>
                          <Button
                            color="steel"
                            onClick={() => act('change_type', { target_ckey: slave.slave_ckey, new_type: selectedType })}>
                            Change Type
                          </Button>
                        </Stack.Item>
                      )}
                    </Stack>
                  </Flex.Item>
                </Flex>
              </Box>
            ))
          )}
        </Section>

        {is_legion && (
          <Section title="> COLLAR MANAGEMENT">
            <Box color="grey" mb={1}>
              Shock Level:
            </Box>
            <Flex gap={1}>
              {[1, 2, 3].map(level => (
                <Button
                  key={level}
                  selected={shockLevel === level}
                  color={shockLevel === level ? 'yellow' : 'grey'}
                  onClick={() => setShockLevel(level)}>
                  Level {level}
                </Button>
              ))}
            </Flex>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};
