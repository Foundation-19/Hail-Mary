import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Box, Button, LabeledList, Section, Stack, ProgressBar } from '../components';

type SpyNetworkData = {
  spies: Spy[];
  intel_database: IntelReport[];
  total_intel_value: number;
};

type Spy = {
  ckey: string;
  spy_name: string;
  cover_identity: string;
  infiltrated_faction: string | null;
  cover_quality: number;
  suspicion_level: number;
  intel_gathered: number;
  last_report_time: number;
  active: boolean;
  rank: string;
  intel: IntelReport[];
};

type IntelReport = {
  report_id: string;
  intel_type: string;
  faction_target: string;
  value: number;
  accuracy: number;
  report_time: number;
  submitted: boolean;
  expired: boolean;
  age_hours: number;
};

const getIntelColor = (type: string): string => {
  switch (type) {
    case 'personnel':
      return 'blue';
    case 'military':
      return 'red';
    case 'economic':
      return 'gold';
    case 'plans':
      return 'purple';
    case 'secrets':
      return 'orange';
    default:
      return 'silver';
  }
};

const getFactionColor = (faction: string): string => {
  switch (faction) {
    case 'ncr':
      return '#4a90d9';
    case 'bos':
      return '#8b8b8b';
    case 'enclave':
      return '#4cff4c';
    case 'town':
      return 'yellow';
    default:
      return 'grey';
  }
};

export const SpyNetwork = (props, context) => {
  const { act, data } = useBackend<SpyNetworkData>(context);
  const {
    spies = [],
    intel_database = [],
    total_intel_value = 0,
  } = data;

  return (
    <Window
      width={750}
      height={700}
      theme="fallout">
      <Window.Content scrollable>
        <Stack vertical>
          <Stack.Item>
            <Section title="> LEGION SPY NETWORK">
              <Box color="silver" fontSize="14px">
                FRUMENTARIUS INTELLIGENCE SYSTEM
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> INTELLIGENCE OVERVIEW">
              <LabeledList>
                <LabeledList.Item label="Active Agents">
                  <Box color="green" bold>
                    {spies.filter(s => s.active).length}
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Total Intel Value">
                  <Box color="gold">{total_intel_value}</Box>
                </LabeledList.Item>
                <LabeledList.Item label="Intel Reports">
                  <Box color="silver">{intel_database.length}</Box>
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> ACTIVE AGENTS">
              {!spies.length && (
                <Box color="grey" textAlign="center" py={2}>
                  No active agents.
                </Box>
              )}
              {spies.map(spy => (
                <Box key={spy.ckey} mb={2} p={1} backgroundColor="rgba(50,50,50,0.5)">
                  <LabeledList>
                    <LabeledList.Item label="Agent">
                      <Box color="silver" bold>{spy.spy_name}</Box>
                    </LabeledList.Item>
                    <LabeledList.Item label="Status">
                      <Box color={spy.active ? 'green' : 'red'}>
                        {spy.active ? 'ACTIVE' : 'INACTIVE'}
                      </Box>
                    </LabeledList.Item>
                    {spy.infiltrated_faction && (
                      <>
                        <LabeledList.Item label="Cover">
                          <Box color="yellow">{spy.cover_identity}</Box>
                        </LabeledList.Item>
                        <LabeledList.Item label="Target">
                          <Box color={getFactionColor(spy.infiltrated_faction)}>
                            {spy.infiltrated_faction.toUpperCase()}
                          </Box>
                        </LabeledList.Item>
                        <LabeledList.Item label="Cover Quality">
                          <ProgressBar
                            value={spy.cover_quality}
                            minValue={0}
                            maxValue={100}
                            color={spy.cover_quality > 50 ? 'green' : 'red'}>
                            {spy.cover_quality}%
                          </ProgressBar>
                        </LabeledList.Item>
                        <LabeledList.Item label="Suspicion">
                          <ProgressBar
                            value={spy.suspicion_level}
                            minValue={0}
                            maxValue={100}
                            color={spy.suspicion_level > 70 ? 'red' : 'yellow'}>
                            {spy.suspicion_level}%
                          </ProgressBar>
                        </LabeledList.Item>
                      </>
                    )}
                    <LabeledList.Item label="Intel Gathered">
                      <Box color="gold">{spy.intel_gathered} reports</Box>
                    </LabeledList.Item>
                  </LabeledList>
                  <Stack mt={1}>
                    {!spy.infiltrated_faction && (
                      <Button
                        color="blue"
                        size="tiny"
                        onClick={() => act('assume_cover', {
                          spy_ckey: spy.ckey,
                          faction: 'ncr',
                        })}>
                        Infiltrate NCR
                      </Button>
                    )}
                    {spy.infiltrated_faction && (
                      <>
                        <Button
                          color="green"
                          size="tiny"
                          onClick={() => act('gather_intel', {
                            spy_ckey: spy.ckey,
                            intel_type: 'military',
                          })}>
                          Gather Intel
                        </Button>
                        <Button
                          color="gold"
                          size="tiny"
                          onClick={() => act('report_intel', {
                            spy_ckey: spy.ckey,
                          })}>
                          Report to Caesar
                        </Button>
                        <Button
                          color="orange"
                          size="tiny"
                          onClick={() => act('extract_spy', {
                            spy_ckey: spy.ckey,
                          })}>
                          Extract
                        </Button>
                      </>
                    )}
                  </Stack>
                </Box>
              ))}
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="> INTEL DATABASE">
              {!intel_database.length && (
                <Box color="grey" textAlign="center" py={2}>
                  No intelligence reports.
                </Box>
              )}
              {intel_database.map(report => (
                <Box
                  key={report.report_id}
                  mb={1}
                  p={1}
                  backgroundColor="rgba(50,50,50,0.3)">
                  <Stack>
                    <Stack.Item grow>
                      <LabeledList>
                        <LabeledList.Item label="Type">
                          <Box color={getIntelColor(report.intel_type)}>
                            {report.intel_type.toUpperCase()}
                          </Box>
                        </LabeledList.Item>
                        <LabeledList.Item label="Target">
                          <Box color={getFactionColor(report.faction_target)}>
                            {report.faction_target.toUpperCase()}
                          </Box>
                        </LabeledList.Item>
                        <LabeledList.Item label="Value">
                          <Box color="gold">{report.value}</Box>
                        </LabeledList.Item>
                        <LabeledList.Item label="Age">
                          <Box color={report.age_hours > 24 ? 'red' : 'green'}>
                            {report.age_hours.toFixed(1)} hours
                          </Box>
                        </LabeledList.Item>
                      </LabeledList>
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        color="grey"
                        size="tiny"
                        onClick={() => act('mark_intel_stale', {
                          report_id: report.report_id,
                        })}>
                        Mark Stale
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Box>
              ))}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
