import { useBackend } from '../backend';
import { Button, Section, Stack, NoticeBox, Flex, Box, Table } from '../components';
import { Window } from '../layouts';

type EnclaveTerminalData = {
  ckey?: string;
  has_record?: boolean;
  tier?: number;
  rank_name?: string;
  missions?: number;
  kills?: number;
  apa_certified?: boolean;
  eligible?: boolean;
  tiers?: TierInfo[];
  roster?: RosterEntry[];
};

type TierInfo = {
  tier?: number;
  name?: string;
};

type RosterEntry = {
  ckey?: string;
  name?: string;
  tier?: number;
  rank?: string;
};

const tierColors = ['#888888', '#44ff44', '#44ff88', '#44ffaa', '#44ffcc', '#44ffee'];

export const EnclaveTerminal = (props, context) => {
  const { act, data } = useBackend<EnclaveTerminalData>(context);

  const {
    has_record,
    tier = 0,
    rank_name = 'Recruit',
    missions = 0,
    kills = 0,
    apa_certified,
    eligible,
    tiers = [],
    roster = [],
  } = data;

  return (
    <Window theme="fallout" width={600} height={700}>
      <Window.Content scrollable>
        <Stack vertical>
          <Section title="> ENCLAVE PERSONNEL TERMINAL">
            <Box color="silver">SOLDIER PROGRESSION SYSTEM</Box>
          </Section>

          {!has_record ? (
            <Section title="> CREATE RECORD">
              <NoticeBox info>
                No record found. Create one to begin progression.
              </NoticeBox>
              <Button onClick={() => act('create_record')}>
                Create Soldier Record
              </Button>
            </Section>
          ) : (
            <>
              <Section title="> YOUR STATUS">
                <Box fontSize="18px" color={tierColors[tier]} bold>
                  {rank_name}
                </Box>
                <Table mt={1}>
                  <Table.Row>
                    <Table.Cell>Missions Completed:</Table.Cell>
                    <Table.Cell>{missions}</Table.Cell>
                  </Table.Row>
                  <Table.Row>
                    <Table.Cell>Kills:</Table.Cell>
                    <Table.Cell>{kills}</Table.Cell>
                  </Table.Row>
                  <Table.Row>
                    <Table.Cell>APA Certified:</Table.Cell>
                    <Table.Cell>
                      <Box color={apa_certified ? 'green' : 'red'}>
                        {apa_certified ? 'Yes' : 'No'}
                      </Box>
                    </Table.Cell>
                  </Table.Row>
                </Table>
              </Section>

              <Section title="> PROGRESSION">
                <Stack vertical>
                  {tiers.map(t => (
                    <Box key={t.tier} p={1} backgroundColor={t.tier === tier ? 'rgba(50,50,30,0.5)' : 'transparent'}>
                      <Flex justify="space-between" align="center">
                        <Box color={tier === t.tier ? 'yellow' : 'grey'}>
                          Tier {t.tier}: {t.name}
                        </Box>
                        {t.tier === tier && t.tier < 5 && (
                          <Button
                            disabled={!eligible}
                            onClick={() => act('request_promotion')}
                          >
                            Request Promotion
                          </Button>
                        )}
                      </Flex>
                    </Box>
                  ))}
                </Stack>
                {!eligible && tier < 5 && (
                  <Box color="grey" mt={1} fontSize="12px">
                    Insufficient reputation for promotion.
                  </Box>
                )}
              </Section>

              <Section title="> APA CERTIFICATION">
                {apa_certified ? (
                  <NoticeBox success>
                    You are certified for Advanced Power Armor.
                  </NoticeBox>
                ) : (
                  <>
                    <NoticeBox warning>
                      Requires Lieutenant rank or higher.
                    </NoticeBox>
                    <Button
                      disabled={tier < ENCLAVE_RANK_LIEUTENANT}
                      onClick={() => act('apa_certification')}
                    >
                      Request Certification
                    </Button>
                  </>
                )}
              </Section>
            </>
          )}

          <Section title="> ENCLAVE ROSTER">
            <Table>
              <Table.Row header>
                <Table.Cell>Name</Table.Cell>
                <Table.Cell>Rank</Table.Cell>
                <Table.Cell>Actions</Table.Cell>
              </Table.Row>
              {roster.map(entry => (
                <Table.Row key={entry.ckey}>
                  <Table.Cell>{entry.name}</Table.Cell>
                  <Table.Cell>{entry.rank}</Table.Cell>
                  <Table.Cell>
                    {tier >= ENCLAVE_RANK_SERGEANT
                      && entry.ckey !== data.ckey && (
                      <Flex gap={1}>
                        <Button onClick={() => act(
                          'promote_soldier',
                          { target_ckey: entry.ckey }
                        )}>
                          Promote
                        </Button>
                        <Button
                          color="bad"
                          onClick={() => act(
                            'demote_soldier',
                            { target_ckey: entry.ckey }
                          )}
                        >
                          Demote
                        </Button>
                      </Flex>
                    )}
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

const ENCLAVE_RANK_LIEUTENANT = 4;
const ENCLAVE_RANK_SERGEANT = 3;
