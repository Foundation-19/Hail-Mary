import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Flex, Input } from '../components';
import { Window } from '../layouts';

type PrisonManagementData = {
  is_law_enforcement: boolean;
  is_judge: boolean;
  is_ranger: boolean;
  my_status: PrisonerStatus | null;
  prisoners: PrisonerStatus[];
  escape_alerts: EscapeAlert[];
};

type PrisonerStatus = {
  prisoner_ckey: string;
  prisoner_name: string;
  crime: string;
  sentence_minutes: number;
  time_served: number;
  time_remaining: number;
  status: string;
  arresting_officer: string;
  escape_attempts: number;
  parole_eligible: boolean;
  parole_requested: boolean;
};

type EscapeAlert = {
  ckey: string;
  name: string;
  last_seen: string;
  time: number;
};

const crimeOptions = [
  { id: 'trespassing', label: 'Trespassing (5 min)' },
  { id: 'theft', label: 'Theft (10 min)' },
  { id: 'assault', label: 'Assault (15 min)' },
  { id: 'murder', label: 'Murder (30 min)' },
];

export const PrisonManagement = (props, context) => {
  const { act, data } = useBackend<PrisonManagementData>(context);
  const {
    is_law_enforcement,
    is_judge,
    is_ranger,
    my_status,
    prisoners = [],
    escape_alerts = [],
  } = data;

  const [targetCkey, setTargetCkey] = useLocalState<string>(
    context,
    'targetCkey',
    ''
  );
  const [selectedCrime, setSelectedCrime] = useLocalState<string>(
    context,
    'selectedCrime',
    'trespassing'
  );

  return (
    <Window width={700} height={650} title="NCR PRISON SYSTEM" theme="ncr">
      <Window.Content scrollable>
        <Box className="CharacterSetup__header">
          NEW CALIFORNIA REPUBLIC
          <span style={{ float: 'right' }}>CORRECTIONAL FACILITY</span>
        </Box>

        {my_status && (
          <Section title="> YOUR STATUS">
            <Box style={{ color: '#b8d4f0', marginBottom: '10px' }}>
              <Box>Crime: {my_status.crime.toUpperCase()}</Box>
              <Box>
                Sentence: {my_status.sentence_minutes} minutes
              </Box>
              <Box>
                Time Served: {Math.floor(my_status.time_served)} minutes
              </Box>
              <Box style={{ color: '#ffd700' }}>
                Time Remaining:{' '}
                {Math.floor(my_status.time_remaining)} minutes
              </Box>
              <Box style={{ marginTop: '10px' }}>
                Escape Attempts: {my_status.escape_attempts}
              </Box>
            </Box>

            {my_status.status === 'incarcerated' && (
              <Flex wrap="wrap" gap="8px">
                <Button
                  content="[WORK DETAIL]"
                  color="good"
                  onClick={() => act('work_detail')}
                />
                {my_status.parole_eligible
                  && !my_status.parole_requested && (
                  <Button
                    content="[REQUEST PAROLE]"
                    onClick={() => act('request_parole')}
                  />
                )}
                {my_status.parole_requested && (
                  <Box style={{ color: '#4cff4c' }}>Parole Requested</Box>
                )}
                <Button
                  content="[ATTEMPT ESCAPE]"
                  color="bad"
                  onClick={() => act('attempt_escape')}
                />
              </Flex>
            )}
          </Section>
        )}

        {is_law_enforcement && (
          <Section title="> ARREST PLAYER">
            <Flex style={{ marginBottom: '10px' }} gap="10px">
              <Flex.Item grow={1}>
                <Box style={{ color: '#b8d4f0', marginBottom: '5px' }}>
                  Target Player:
                </Box>
                <Input
                  fluid
                  placeholder="Enter player ckey..."
                  value={targetCkey}
                  onInput={(e, value) => setTargetCkey(value)}
                />
              </Flex.Item>
              <Flex.Item style={{ width: '200px' }}>
                <Box style={{ color: '#b8d4f0', marginBottom: '5px' }}>
                  Crime:
                </Box>
                <Flex wrap="wrap" gap="5px">
                  {crimeOptions.map((crime) => (
                    <Button
                      key={crime.id}
                      content={crime.label}
                      selected={selectedCrime === crime.id}
                      onClick={() => setSelectedCrime(crime.id)}
                      style={{ fontSize: '0.85em' }}
                    />
                  ))}
                </Flex>
              </Flex.Item>
            </Flex>
            <Button
              content="[ARREST]"
              color="bad"
              onClick={() => act('arrest_player', {
                target_ckey: targetCkey,
                crime: selectedCrime,
              })}
            />
          </Section>
        )}

        <Section title="> CURRENT PRISONERS">
          {prisoners.length > 0 ? (
            prisoners.map((prisoner) => (
              <Box
                key={prisoner.prisoner_ckey}
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
                      {prisoner.prisoner_name}
                    </Box>
                    <Box style={{ color: '#b8d4f0', marginTop: '5px' }}>
                      Crime: {prisoner.crime.toUpperCase()}
                    </Box>
                    <Box style={{ color: '#4a90d9' }}>
                      Remaining: {Math.floor(prisoner.time_remaining)} min
                    </Box>
                    <Box style={{ color: '#888', fontSize: '0.85em' }}>
                      Arrested by: {prisoner.arresting_officer}
                    </Box>
                    {prisoner.escape_attempts > 0 && (
                      <Box style={{ color: '#ff4444' }}>
                        Escape Attempts: {prisoner.escape_attempts}
                      </Box>
                    )}
                  </Flex.Item>
                  <Flex.Item>
                    {is_law_enforcement && (
                      <Flex direction="column" gap="5px">
                        <Button
                          content="[RELEASE]"
                          color="good"
                          onClick={() => act('release_prisoner', {
                            target_ckey: prisoner.prisoner_ckey,
                          })}
                        />
                        <Button
                          content="+5 MIN"
                          onClick={() => act('add_time', {
                            target_ckey: prisoner.prisoner_ckey,
                            time: 5,
                          })}
                        />
                        {is_judge && prisoner.parole_eligible && (
                          <Button
                            content="[PAROLE]"
                            color="good"
                            onClick={() => act('offer_parole', {
                              target_ckey: prisoner.prisoner_ckey,
                            })}
                          />
                        )}
                      </Flex>
                    )}
                  </Flex.Item>
                </Flex>
              </Box>
            ))
          ) : (
            <Box
              style={{
                textAlign: 'center',
                padding: '20px',
                color: '#2a5a87',
              }}
            >
              No current prisoners.
            </Box>
          )}
        </Section>

        {escape_alerts.length > 0 && (
          <Section title="> ESCAPE ALERTS">
            {escape_alerts.map((alert, index) => (
              <Box
                key={index}
                style={{
                  border: '1px solid #ff4444',
                  padding: '12px',
                  margin: '8px 0',
                  background: '#1a0a0a',
                }}
              >
                <Flex justify="space-between" align="center">
                  <Flex.Item>
                    <Box style={{ color: '#ff4444', fontWeight: 'bold' }}>
                      [!] {alert.name} ESCAPED!
                    </Box>
                    <Box style={{ color: '#b8d4f0', marginTop: '5px' }}>
                      Last seen: {alert.last_seen}
                    </Box>
                  </Flex.Item>
                  <Flex.Item>
                    {is_ranger && (
                      <Button
                        content="[TRACK]"
                        color="good"
                        onClick={() => act('track_escapee', {
                          target_ckey: alert.ckey,
                        })}
                      />
                    )}
                  </Flex.Item>
                </Flex>
              </Box>
            ))}
          </Section>
        )}

        <Box className="CharacterSetup__footer">
          NEW CALIFORNIA REPUBLIC - DEPARTMENT OF CORRECTIONS
        </Box>
      </Window.Content>
    </Window>
  );
};
