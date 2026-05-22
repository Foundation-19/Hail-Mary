import { useBackend } from '../backend';
import { Button, Section, Stack, NoticeBox, Flex, Box, Table, ProgressBar } from '../components';
import { Window } from '../layouts';

type GeneticScreeningData = {
  has_scan?: boolean;
  my_purity?: number;
  my_status?: string;
  my_mutation?: string;
  scan_history?: ScanResult[];
  blacklist?: BlacklistEntry[];
  applications?: CitizenshipApp[];
  scanner_status?: string;
};

type ScanResult = {
  ckey?: string;
  purity?: number;
  status?: string;
  mutation?: string;
  time?: number;
};

type BlacklistEntry = {
  ckey?: string;
  reason?: string;
};

type CitizenshipApp = {
  ckey?: string;
  status?: string;
  probation_remaining?: number;
};

const purityColor = (purity: number): string => {
  if (purity >= 95) return 'green';
  if (purity >= 80) return 'yellow';
  if (purity >= 60) return 'orange';
  return 'red';
};

const statusColor = (status: string): string => {
  switch (status) {
    case 'approved': return 'green';
    case 'monitored': return 'yellow';
    case 'quarantined': return 'orange';
    case 'terminated': return 'red';
    default: return 'grey';
  }
};

export const GeneticScreening = (props, context) => {
  const { act, data } = useBackend<GeneticScreeningData>(context);

  const {
    has_scan,
    my_purity = 0,
    my_status = 'unknown',
    my_mutation = 'none',
    scan_history = [],
    blacklist = [],
    applications = [],
    scanner_status = 'Active',
  } = data;

  return (
    <Window theme="fallout" width={600} height={700}>
      <Window.Content scrollable>
        <Stack vertical>
          <Section title="> ENCLAVE GENETIC SCREENING">
            <Box color="silver">PURITY VERIFICATION SYSTEM</Box>
            <Box mt={1}>
              Scanner Status: <Box as="span" color="green">{scanner_status}</Box>
            </Box>
          </Section>

          {has_scan && (
            <Section title="> YOUR SCAN RESULTS">
              <Box>
                Purity Rating:
                <ProgressBar
                  mt={1}
                  value={my_purity}
                  maxValue={100}
                  color={purityColor(my_purity)}
                />
              </Box>
              <Table mt={1}>
                <Table.Row>
                  <Table.Cell>Classification:</Table.Cell>
                  <Table.Cell>
                    <Box color={statusColor(my_status)} bold>
                      {my_status?.toUpperCase()}
                    </Box>
                  </Table.Cell>
                </Table.Row>
                <Table.Row>
                  <Table.Cell>Mutation Type:</Table.Cell>
                  <Table.Cell>{my_mutation}</Table.Cell>
                </Table.Row>
              </Table>
            </Section>
          )}

          <Section title="> SCAN OPTIONS">
            <Flex gap={1}>
              <Button onClick={() => act('scan_self')}>
                Scan Self
              </Button>
              <Button onClick={() => act('scan_target')}>
                Scan Target (pull someone)
              </Button>
            </Flex>
          </Section>

          <Section title="> SCAN HISTORY">
            <Table>
              <Table.Row header>
                <Table.Cell>Subject</Table.Cell>
                <Table.Cell>Purity</Table.Cell>
                <Table.Cell>Status</Table.Cell>
                <Table.Cell>Mutation</Table.Cell>
              </Table.Row>
              {scan_history.slice(-10).map((result, idx) => (
                <Table.Row key={idx}>
                  <Table.Cell>{result.ckey}</Table.Cell>
                  <Table.Cell>
                    <Box color={purityColor(result.purity || 0)}>
                      {result.purity}%
                    </Box>
                  </Table.Cell>
                  <Table.Cell>
                    <Box color={statusColor(result.status || 'unknown')}>
                      {result.status}
                    </Box>
                  </Table.Cell>
                  <Table.Cell>{result.mutation}</Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>

          <Section title="> CITIZENSHIP APPLICATIONS">
            {applications.length === 0 ? (
              <Box color="grey">No pending applications.</Box>
            ) : (
              <Table>
                <Table.Row header>
                  <Table.Cell>Applicant</Table.Cell>
                  <Table.Cell>Status</Table.Cell>
                  <Table.Cell>Actions</Table.Cell>
                </Table.Row>
                {applications.map((app, idx) => (
                  <Table.Row key={idx}>
                    <Table.Cell>{app.ckey}</Table.Cell>
                    <Table.Cell>
                      <Box color={app.status === 'approved' ? 'green' : app.status === 'denied' ? 'red' : 'yellow'}>
                        {app.status}
                      </Box>
                    </Table.Cell>
                    <Table.Cell>
                      {app.status === 'pending' && (
                        <Flex gap={1}>
                          <Button onClick={() => act('approve_citizenship', { ckey: app.ckey })}>
                            Approve
                          </Button>
                          <Button color="bad" onClick={() => act('deny_citizenship', { ckey: app.ckey })}>
                            Deny
                          </Button>
                        </Flex>
                      )}
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            )}
          </Section>

          <Section title="> BLACKLIST">
            {blacklist.length === 0 ? (
              <Box color="grey">No entries on blacklist.</Box>
            ) : (
              <Table>
                <Table.Row header>
                  <Table.Cell>CKEY</Table.Cell>
                  <Table.Cell>Reason</Table.Cell>
                  <Table.Cell>Actions</Table.Cell>
                </Table.Row>
                {blacklist.map((entry, idx) => (
                  <Table.Row key={idx}>
                    <Table.Cell>{entry.ckey}</Table.Cell>
                    <Table.Cell>{entry.reason}</Table.Cell>
                    <Table.Cell>
                      <Button onClick={() => act('remove_blacklist', { ckey: entry.ckey })}>
                        Remove
                      </Button>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            )}
          </Section>
        </Stack>
      </Window.Content>
    </Window>
  );
};
